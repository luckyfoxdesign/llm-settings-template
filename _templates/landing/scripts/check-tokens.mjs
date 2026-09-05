#!/usr/bin/env node
// Линтер расхождений между макетом и кодом.
//
// Сравнивает смысловые токены, объявленные в @theme (через
// tokens/semantic.generated.json), с токенами, реально привязанными к слоям
// макета (tokens/colors.used.json — выгрузка Figma-плагина из задачи B).
//
// Это проверка, а не синхронизация: источник истины — @theme, макет только
// потребитель. Скрипт ничего не пишет, только печатает отчёт.
//
// Отвечает на два вопроса:
//   - какие токены объявлены в @theme, но в макете не используются ни разу
//     (информация, код выхода 0);
//   - какие токены встречаются в макете, но в коде их нет — переименование
//     или устаревшая выгрузка (расхождение, ненулевой код выхода).
//
// Использование:
//   node scripts/check-tokens.mjs
//   node scripts/check-tokens.mjs --fixture scripts/fixtures/tokens-clean.json
//
// Коды выхода:
//   0  наборы совпали, либо выгрузки ещё нет (макет не размечен)
//   1  токен используется в макете, но не объявлен в коде
//   2  ошибка запуска: аргументы, чтение или разбор JSON

import { readFileSync } from "node:fs";
import { dirname, isAbsolute, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const SEMANTIC_FILE = join(ROOT, "tokens/semantic.generated.json");
const PALETTE_FILE = join(ROOT, "tokens/tailwind-colors.generated.json");
const USED_FILE = join(ROOT, "tokens/colors.used.json");

// Префиксы utility-классов, которые Tailwind v4 порождает из каждого --color-*.
// Список фиксирован и приклеивается к имени токена — ручной таблицы нет.
const CLASS_PREFIXES = ["text", "bg", "border"];

// Имя смыслового токена в выгрузке: коллекция "Semantic", путь semantic/<токен>.
const SEMANTIC_PREFIX = "semantic/";
const PALETTE_PREFIX = "tailwind/";

function die(code, message) {
  console.error(`check-tokens: ${message}`);
  process.exit(code);
}

function parseArgs(argv) {
  let fixture = null;
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--fixture") {
      fixture = argv[i + 1];
      i += 1;
    } else if (arg.startsWith("--fixture=")) {
      fixture = arg.slice("--fixture=".length);
    } else {
      die(2, `неизвестный аргумент: ${arg}`);
    }
    if (!fixture) die(2, "у --fixture нет значения");
  }
  return { fixture };
}

function readJson(file, { required }) {
  let text;
  try {
    text = readFileSync(file, "utf8");
  } catch (error) {
    if (!required && error.code === "ENOENT") return null;
    return die(2, `не прочитан ${file}: ${error.message}`);
  }
  try {
    return JSON.parse(text);
  } catch (error) {
    return die(2, `не разобран JSON ${file}: ${error.message}`);
  }
}

// tokens/semantic.generated.json → Map(имя → { cssVariable }).
function readDeclared() {
  const doc = readJson(SEMANTIC_FILE, { required: true });
  const color = doc && doc.color;
  if (!color || typeof color !== "object") {
    die(2, `в ${SEMANTIC_FILE} нет объекта color`);
  }
  const declared = new Map();
  for (const [name, node] of Object.entries(color)) {
    const ext =
      node && node.$extensions && node.$extensions["design.luckyfox.tokens"];
    declared.set(name, {
      cssVariable: (ext && ext.cssVariable) || `--color-${name}`,
    });
  }
  if (declared.size === 0) die(2, `в ${SEMANTIC_FILE} пустой color`);
  return declared;
}

// tokens/tailwind-colors.generated.json → Set("black", "orange-100", ...).
function readPaletteKeys() {
  const doc = readJson(PALETTE_FILE, { required: true });
  const color = doc && doc.color;
  if (!color || typeof color !== "object") {
    die(2, `в ${PALETTE_FILE} нет объекта color`);
  }
  const keys = new Set();
  const walk = (node, path) => {
    for (const [key, value] of Object.entries(node)) {
      if (key.startsWith("$")) continue;
      if (value && value.$type === "color") keys.add([...path, key].join("-"));
      else if (value && typeof value === "object") walk(value, [...path, key]);
    }
  };
  walk(color, []);
  return keys;
}

// Выгрузка использованных переменных → Map(имя токена → { value, aliasOf }).
// Берутся только записи коллекции "Semantic"; примитивы палитры игнорируются —
// палитра генерируется из Tailwind и всегда полна.
function readUsedSemantic(doc, sourceLabel) {
  if (!doc || !Array.isArray(doc.variables)) {
    die(2, `в ${sourceLabel} нет массива variables`);
  }
  const used = new Map();
  for (const entry of doc.variables) {
    if (!entry || typeof entry.name !== "string") continue;
    const isSemantic =
      entry.collection === "Semantic" || entry.name.startsWith(SEMANTIC_PREFIX);
    if (!isSemantic) continue;
    const token = entry.name.startsWith(SEMANTIC_PREFIX)
      ? entry.name.slice(SEMANTIC_PREFIX.length)
      : entry.name;
    if (used.has(token)) continue;
    used.set(token, {
      value: typeof entry.value === "string" ? entry.value : null,
      aliasOf: typeof entry.aliasOf === "string" ? entry.aliasOf : null,
    });
  }
  return used;
}

function utilityClasses(token) {
  return CLASS_PREFIXES.map((prefix) => `${prefix}-${token}`);
}

// tailwind/orange/100 → orange-100
function aliasToPaletteKey(aliasOf) {
  if (!aliasOf || !aliasOf.startsWith(PALETTE_PREFIX)) return null;
  return aliasOf.slice(PALETTE_PREFIX.length).split("/").join("-");
}

function main() {
  const { fixture } = parseArgs(process.argv.slice(2));

  const declared = readDeclared();
  const paletteKeys = readPaletteKeys();

  let usedDoc;
  let sourceLabel;
  if (fixture) {
    sourceLabel = fixture;
    const path = isAbsolute(fixture) ? fixture : resolve(process.cwd(), fixture);
    usedDoc = readJson(path, { required: true });
  } else {
    sourceLabel = "tokens/colors.used.json";
    usedDoc = readJson(USED_FILE, { required: false });
    if (usedDoc === null) {
      console.log(
        `check-tokens: ${sourceLabel} нет — макет ещё не размечен переменными.\n` +
          "Выгрузите использованные цвета Figma-плагином (задача B) и повторите.\n" +
          `Объявлено смысловых токенов в @theme: ${declared.size}. ` +
          "Расхождений не проверяю.",
      );
      process.exit(0);
    }
  }

  const used = readUsedSemantic(usedDoc, sourceLabel);

  const declaredNotUsed = [...declared.keys()]
    .filter((name) => !used.has(name))
    .sort();
  const usedNotDeclared = [...used.keys()]
    .filter((name) => !declared.has(name))
    .sort();

  // --- отчёт --------------------------------------------------------------
  console.log(`Источник выгрузки: ${sourceLabel}`);
  console.log(
    `Смысловых токенов: в @theme ${declared.size}, в макете ${used.size}.\n`,
  );

  console.log(`Используется в макете (${used.size}):`);
  if (used.size === 0) {
    console.log("  — ни одного");
  } else {
    for (const token of [...used.keys()].sort()) {
      const mark = declared.has(token) ? "" : "  ← в коде нет";
      console.log(`  ${token} → ${utilityClasses(token).join(", ")}${mark}`);
      const paletteKey = aliasToPaletteKey(used.get(token).aliasOf);
      if (paletteKey) {
        const missing = paletteKeys.has(paletteKey) ? "" : " (нет в палитре!)";
        console.log(`      алиас Tailwind: ${paletteKey}${missing}`);
      }
    }
  }
  console.log("");

  console.log(
    `Объявлено в @theme, но в макете не используется (${declaredNotUsed.length}):`,
  );
  if (declaredNotUsed.length === 0) console.log("  — нет");
  else for (const name of declaredNotUsed) console.log(`  ${name}`);
  console.log("");

  console.log(
    `Есть в макете, но не объявлено в @theme (${usedNotDeclared.length}):`,
  );
  if (usedNotDeclared.length === 0) {
    console.log("  — нет");
  } else {
    for (const name of usedNotDeclared) {
      console.log(`  ${name}  (переименование или устаревшая выгрузка)`);
    }
  }
  console.log("");

  if (usedNotDeclared.length > 0) {
    console.log(
      `check-tokens: расхождение — ${usedNotDeclared.length} ` +
        "токен(ов) из макета нет в коде.",
    );
    process.exit(1);
  }
  console.log("check-tokens: расхождений нет.");
}

main();
