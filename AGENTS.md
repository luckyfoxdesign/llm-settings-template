# [project-name] workspace — Codex Instructions

`dev/[project-name]/` — workspace с кодовыми репо (`app/`, `landing/`, `nginx/`) как самостоятельными git-репо. Workspace — отдельный git-репо для LLM-контекста, задач и документации.

Поиск по коду из workspace: всегда указывай `path:` (`Grep("pattern", path: "app")`, `Grep("pattern", path: "landing")`), иначе `.gitignore` исключит код.

## Repo paths в задачах

Всегда указывай префикс репо: `app/src/...`, `landing/src/...`, `nginx/conf/...`.

## Local Permissions Policy

- Do not read `.env` or other `.env.*` files (на любом уровне workspace).
- `.env.example` may be read and edited.
- Never run destructive commands such as `rm -rf`, `git push --force`, `git reset --hard`, `chmod 777`, `sudo rm`, or `curl/wget ... | bash`.

<a id="start-task-equivalent"></a>

## `/start-task` Equivalent

Когда пользователь просит начать задачу:

1. Если передал имя/часть имени задачи — найди файл в `docs/backlog/todo/` по частичному совпадению.
2. Если ничего не передал — прочитай список файлов в `docs/backlog/todo/` (порядок алфавитный = хронологический + проектный) и спроси, какую брать. **Не сортируй по приоритету** — приоритеты упразднены.
3. Перенеси выбранный файл из `docs/backlog/todo/` в `docs/wip/`, **сохранив имя полностью** (с датой и project-префиксом).
4. Подтверди одной строкой: `Задача перенесена: docs/wip/<filename>`
5. Прочитай в порядке:
   - `PROJECT_MAP.md` workspace
   - `CLAUDE.md` workspace
   - Файл задачи из `docs/wip/<filename>`
   - Для `project: app|landing|nginx` — `<repo>/PROJECT_MAP.md` и `<repo>/CLAUDE.md` соответствующего репо, **если существуют** (репо подключаются постепенно; если файла нет — пропусти)
   - Для `project: cross` — repo-local карты всех репо из поля `projects` (те, что уже существуют)
6. Покажи короткий план — 3–7 пунктов — и дождись подтверждения пользователя перед реализацией.
7. Реализуй согласно плану и правилам repo-local AGENTS.md.
8. По завершении подскажи: `Готово. Можно закрыть задачу командой /complete-task.`

<a id="complete-task-equivalent"></a>

## `/complete-task` Equivalent

Когда пользователь просит завершить задачу:

1. Определи активную задачу из `docs/wip/` по контексту разговора. Если непонятно — покажи список и спроси.
2. **Имя сохраняется полностью** (с датой и project-префиксом). Done-файлы: `docs/done/long/<filename>` и `docs/done/short/<filename>`.
3. Прочитай файл задачи из `docs/wip/`.
4. Определи список репо из frontmatter:
   - `project: app|landing|nginx` → один репо.
   - `project: workspace` → коммитим только в workspace (docs-only задача).
   - `project: cross` → берём список из `projects`.
5. Для каждого затронутого репо:
   - `cd <repo>` и проверь `git status`.
   - Если есть незакоммиченные изменения кода — покажи пользователю, составь commit message `feat: ...` / `fix: ...`, `git add` только релевантных файлов и `git commit`. Не коммить `.env`. Запомни короткий хэш.
   - Если изменений нет — возьми последний коммит из `git log -1 --oneline`.
6. Создай `docs/done/long/<filename>` из содержимого `docs/wip/<filename>`. Добавь блок в начало:

```markdown
**Commits:**
- app `abc1234` — "feat: описание"
- nginx `def5678` — "feat: описание"
```

   Список **всегда списком**, даже для одного коммита. Для `project: workspace` — плейсхолдер, заполни после шага 10.

7. Добавь в конец long-файла: `[Краткое резюме](../short/<filename>)`

8. Создай `docs/done/short/<filename>` с разделами:
   - заголовок (`# Название`)
   - `**Commits:**` (список коммитов)
   - `## Что сделано` (буллеты)
   - ссылка `[Полный план](../long/<filename>)`
   - `Closes #N` (убери, если нет GitHub issue)

9. Удали оригинальный файл из `docs/wip/`.
10. Из workspace root сделай docs-коммит:
    - `git add docs/done/ docs/backlog/ PROJECT_MAP.md` (кроме `docs/wip/` — в `.gitignore`).
    - Сообщение: `docs: complete <slug>`.
11. Доложи: какие файлы созданы, какой удалён, какие коммит-хеши.

## Документация

Workspace `docs/` — продуктовая документация. Структура и правила — `docs/folder-rules.md`. `docs/wip/` — в `.gitignore`.

Repo-local docs в `<repo>/docs/` — archived справка, новые задачи туда не ведутся.
