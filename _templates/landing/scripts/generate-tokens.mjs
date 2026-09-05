#!/usr/bin/env node
// Генератор токенов дизайн-системы.
//
// Собирает два файла в tokens/:
//   tailwind-colors.generated.json — примитивы палитры из установленного tailwindcss
//   semantic.generated.json        — смысловой слой из блока @theme в global.css
//
// Оба выведены из того, чем сайт реально рендерится, поэтому разойтись с кодом
// не могут. Формат — DTCG ($value / $type / $description / $extensions).
//
// Использование:
//   node scripts/generate-tokens.mjs            записать файлы
//   node scripts/generate-tokens.mjs --check    сверить контрольные значения

import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import tailwindColors from "tailwindcss/colors";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const GLOBAL_CSS = join(ROOT, "src/styles/global.css");
const PALETTE_FILE = join(ROOT, "tokens/tailwind-colors.generated.json");
const SEMANTIC_FILE = join(ROOT, "tokens/semantic.generated.json");
const TAILWIND_PKG = join(ROOT, "node_modules/tailwindcss/package.json");

// В Figma эти ключи нельзя привязать как цвет — они не значения, а поведение.
const NOT_A_COLOR = ["inherit", "current", "transparent"];

// Пространство имён для нестандартных полей DTCG.
const EXT = "design.luckyfox.tokens";

// Контрольные значения. Расхождение означает, что поехал конвертер или палитра,
// и это должно останавливать сборку, а не тихо переписывать файлы.
const EXPECTED = {
  scaleTokens: 242,
  outOfSrgb: 95,
  semanticTokens: 9,
  samples: {
    "blue-500": "#2b7fff",
    "red-500": "#fb2c36",
    "green-500": "#00c950",
    "slate-50": "#f8fafc",
  },
};

// Допуск на арифметику с плавающей точкой при проверке выхода за sRGB.
const EPSILON = 1e-6;

const OKLCH = /^oklch\(\s*(-?[\d.]+)%\s+(-?[\d.]+)\s+(-?[\d.]+)\s*\)$/;
const HEX = /^#(?:[0-9a-f]{3}|[0-9a-f]{6})$/i;
const THEME_DECL = /^--color-([a-z0-9]+(?:-[a-z0-9]+)*)\s*:\s*([^;]+);$/;

function fail(message) {
  console.error(`generate-tokens: ${message}`);
  process.exit(1);
}

// --- цвет -------------------------------------------------------------------

function parseOklch(value) {
  const match = OKLCH.exec(value);
  if (!match) throw new Error(`не разобран oklch: ${value}`);
  return {
    l: Number(match[1]) / 100,
    c: Number(match[2]),
    h: Number(match[3]),
  };
}

// sRGB transfer function; знак сохраняется, чтобы выход за гамму был виден
// до усечения, а не превращался в NaN.
function encodeGamma(x) {
  const sign = x < 0 ? -1 : 1;
  const abs = Math.abs(x);
  if (abs <= 0.0031308) return 12.92 * x;
  return sign * (1.055 * abs ** (1 / 2.4) - 0.055);
}

function toHexChannel(x) {
  const clamped = Math.min(1, Math.max(0, x));
  return Math.round(clamped * 255)
    .toString(16)
    .padStart(2, "0");
}

// OKLCh → OKLab → LMS → linear sRGB → sRGB.
function oklchToSrgb(oklch) {
  const hueRad = (oklch.h * Math.PI) / 180;
  const a = oklch.c * Math.cos(hueRad);
  const b = oklch.c * Math.sin(hueRad);

  const long = (oklch.l + 0.3963377774 * a + 0.2158037573 * b) ** 3;
  const medium = (oklch.l - 0.1055613458 * a - 0.0638541728 * b) ** 3;
  const short = (oklch.l - 0.0894841775 * a - 1.291485548 * b) ** 3;

  const channels = [
    4.0767416621 * long - 3.3077115913 * medium + 0.2309699292 * short,
    -1.2684380046 * long + 2.6097574011 * medium - 0.3413193965 * short,
    -0.0041960863 * long - 0.7034186147 * medium + 1.707614701 * short,
  ].map(encodeGamma);

  return {
    hex: `#${channels.map(toHexChannel).join("")}`,
    outOfSrgb: channels.some((v) => v < -EPSILON || v > 1 + EPSILON),
  };
}

function expandHex(value) {
  if (!HEX.test(value)) throw new Error(`не разобран hex: ${value}`);
  if (value.length === 7) return value.toLowerCase();
  const [, r, g, b] = value.toLowerCase();
  return `#${r}${r}${g}${g}${b}${b}`;
}

// --- сборка палитры ---------------------------------------------------------

function readTailwindVersion() {
  const pkg = JSON.parse(readFileSync(TAILWIND_PKG, "utf8"));
  if (!pkg.version) throw new Error("в tailwindcss/package.json нет version");
  return pkg.version;
}

function buildPalette(version) {
  const color = {};
  const flat = new Map();
  let scaleTokens = 0;
  let outOfSrgb = 0;

  for (const [family, value] of Object.entries(tailwindColors)) {
    if (NOT_A_COLOR.includes(family)) continue;

    // black и white заданы сразу в hex и шкалы не образуют.
    if (typeof value === "string") {
      const hex = expandHex(value);
      color[family] = {
        $value: hex,
        $type: "color",
        $description: `Tailwind ${version} — ${family}`,
        $extensions: { [EXT]: { source: value, outOfSrgb: false } },
      };
      flat.set(family, hex);
      continue;
    }

    if (value === null || typeof value !== "object") {
      throw new Error(`неизвестная форма записи палитры: ${family}`);
    }

    const shades = {};
    for (const [shade, raw] of Object.entries(value)) {
      if (typeof raw !== "string") {
        throw new Error(`неизвестная форма оттенка: ${family}-${shade}`);
      }
      const converted = oklchToSrgb(parseOklch(raw));
      shades[shade] = {
        $value: converted.hex,
        $type: "color",
        $description: `Tailwind ${version} — ${family}-${shade}`,
        // Исходный oklch держим рядом: перевод в sRGB необратим для цветов вне
        // гаммы, и без него потеря насыщенности была бы окончательной.
        $extensions: {
          [EXT]: { source: raw, outOfSrgb: converted.outOfSrgb },
        },
      };
      flat.set(`${family}-${shade}`, converted.hex);
      scaleTokens += 1;
      if (converted.outOfSrgb) outOfSrgb += 1;
    }
    color[family] = shades;
  }

  const document = {
    $description:
      `Примитивы палитры, выведенные из установленного tailwindcss ${version}. ` +
      "Файл генерируется, руками не редактируется: правится только бампом версии.",
    $extensions: {
      [EXT]: {
        tailwindVersion: version,
        scaleTokens,
        outOfSrgb,
        note:
          "Figma хранит переменные в sRGB. Цвета с outOfSrgb: true в макете " +
          "тусклее, чем в браузере на P3-экране; исходный oklch — в source.",
      },
    },
    color,
  };

  return { document, flat, scaleTokens, outOfSrgb };
}

// --- сборка смыслового слоя -------------------------------------------------

// Разбирается только первый блок @theme и только однострочные объявления
// --color-*. На всём остальном падаем: тихий пропуск развёл бы токены с кодом.
function parseThemeBlock(css) {
  const at = css.indexOf("@theme");
  if (at === -1) throw new Error(`в ${GLOBAL_CSS} нет блока @theme`);

  const open = css.indexOf("{", at);
  if (open === -1) throw new Error("у блока @theme нет тела");

  let depth = 0;
  let close = -1;
  for (let i = open; i < css.length; i += 1) {
    if (css[i] === "{") depth += 1;
    else if (css[i] === "}") {
      depth -= 1;
      if (depth === 0) {
        close = i;
        break;
      }
    }
  }
  if (close === -1) throw new Error("блок @theme не закрыт");

  const declarations = new Map();
  for (const rawLine of css.slice(open + 1, close).split("\n")) {
    const line = rawLine.trim();
    if (line === "") continue;
    if (line.startsWith("/*") && line.endsWith("*/")) continue;

    const match = THEME_DECL.exec(line);
    if (!match) {
      throw new Error(
        `строка блока @theme не разобрана, ожидается однострочное ` +
          `объявление --color-*: ${line}`,
      );
    }
    if (declarations.has(match[1])) {
      throw new Error(`токен --color-${match[1]} объявлен дважды`);
    }
    declarations.set(match[1], match[2].trim());
  }

  if (declarations.size === 0) throw new Error("блок @theme пуст");
  return declarations;
}

function buildSemantic(declarations) {
  const color = {};
  for (const [name, value] of declarations) {
    color[name] = {
      $value: expandHex(value),
      $type: "color",
      $description: `Смысловой токен --color-${name} из @theme`,
      $extensions: { [EXT]: { source: value, cssVariable: `--color-${name}` } },
    };
  }

  return {
    $description:
      "Смысловые токены из блока @theme в src/styles/global.css. Источник " +
      "истины — сам @theme: сайт рендерится ровно из этих переменных.",
    $extensions: { [EXT]: { semanticTokens: declarations.size } },
    color,
  };
}

// --- проверки ---------------------------------------------------------------

function checkExpectations(palette, semantic) {
  const problems = [];

  if (palette.scaleTokens !== EXPECTED.scaleTokens) {
    problems.push(
      `токенов шкал ${palette.scaleTokens}, ожидалось ${EXPECTED.scaleTokens}`,
    );
  }
  if (palette.outOfSrgb !== EXPECTED.outOfSrgb) {
    problems.push(
      `цветов вне sRGB ${palette.outOfSrgb}, ожидалось ${EXPECTED.outOfSrgb}`,
    );
  }
  for (const [name, expected] of Object.entries(EXPECTED.samples)) {
    const actual = palette.flat.get(name);
    if (actual !== expected) {
      problems.push(`${name} → ${actual ?? "нет токена"}, ожидалось ${expected}`);
    }
  }
  for (const key of NOT_A_COLOR) {
    if (key in palette.document.color) problems.push(`${key} попал в палитру`);
  }
  for (const key of ["black", "white"]) {
    if (!(key in palette.document.color)) problems.push(`${key} отсутствует`);
  }

  const semanticCount = Object.keys(semantic.color).length;
  if (semanticCount !== EXPECTED.semanticTokens) {
    problems.push(
      `смысловых токенов ${semanticCount}, ожидалось ${EXPECTED.semanticTokens}`,
    );
  }

  return problems;
}

// --- ввод-вывод -------------------------------------------------------------

function serialize(document) {
  return `${JSON.stringify(document, null, 2)}\n`;
}

function readIfExists(file) {
  try {
    return readFileSync(file, "utf8");
  } catch {
    return null;
  }
}

function main() {
  const check = process.argv.includes("--check");

  let version;
  let palette;
  let semantic;
  try {
    version = readTailwindVersion();
    palette = buildPalette(version);
    semantic = buildSemantic(parseThemeBlock(readFileSync(GLOBAL_CSS, "utf8")));
  } catch (error) {
    fail(error.message);
  }

  const files = [
    [PALETTE_FILE, serialize(palette.document)],
    [SEMANTIC_FILE, serialize(semantic)],
  ];

  if (check) {
    const problems = checkExpectations(palette, semantic);
    for (const [file, content] of files) {
      if (readIfExists(file) !== content) {
        problems.push(
          `${file} расходится с генерацией — запустите npm run tokens:generate`,
        );
      }
    }
    if (problems.length > 0) {
      fail(`контрольные значения не совпали:\n  - ${problems.join("\n  - ")}`);
    }
    console.log(
      `tokens:check — ok (tailwind ${version}, ${palette.scaleTokens} токенов ` +
        `шкал, ${palette.outOfSrgb} вне sRGB, ` +
        `${Object.keys(semantic.color).length} смысловых)`,
    );
    return;
  }

  for (const [file, content] of files) writeFileSync(file, content);

  console.log(`tokens:generate — tailwind ${version}`);
  console.log(
    `  tokens/tailwind-colors.generated.json: ${palette.scaleTokens} токенов ` +
      `шкал + black и white, вне sRGB — ${palette.outOfSrgb}`,
  );
  console.log(
    `  tokens/semantic.generated.json: ` +
      `${Object.keys(semantic.color).length} смысловых токенов`,
  );
}

main();
