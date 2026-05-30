# [project-name]-[repo-name] — Codex Instructions

Этот репо — часть workspace `dev/[project-name]/`. Продуктовая документация, backlog, правила задач — на уровне workspace (`../docs/`, `../AGENTS.md`, `../CLAUDE.md`). Этот файл описывает только [repo-name]-специфику.

## Source Of Truth

- Workspace `../AGENTS.md` и `../CLAUDE.md` — общие правила и multi-repo рутины (`/start-task`, `/complete-task`, формат коммитов).
- Workspace `../docs/folder-rules.md` — правила ведения задач.
- Локальный `PROJECT_MAP.md` — текущий индекс репо (модули, роуты, задачи, модели, сервисы).
- Этот файл — [repo-name]-локальные правила (архитектура, тесты, линт).

Не сканируй весь репо, если `PROJECT_MAP.md` даёт точку входа.

## `/start-task` and `/complete-task` Equivalent

Полный алгоритм — в workspace `../AGENTS.md`, разделы `#start-task-equivalent` и `#complete-task-equivalent`.

## Architecture Rules

<!-- Add repo-specific architecture rules here -->

## Testing

<!-- Add test commands here -->

## Code Quality

<!-- Add linter/formatter commands here -->

## Dependencies

Всегда устанавливай **последние стабильные версии** пакетов. При добавлении или обновлении зависимости:

1. Проверь актуальную версию на PyPI/npm/pkg.go.dev.
2. Ставь нижнюю границу = текущая версия на момент добавления (`>=X.Y.Z`).
3. Убедись в совместимости между пакетами (особенно: фреймворк ↔ плагины, ORM ↔ адаптер БД).
4. При мажорном апгрейде зависимости — проверь breaking changes в changelog перед использованием.

## Local Permissions Policy

- Do not read `.env` or other `.env.*` files.
- `.env.example` may be read and edited.
- Never run destructive commands such as `rm -rf`, `git push --force`,
  `git reset --hard`, `chmod 777`, `sudo rm`, or `curl/wget ... | bash`.
- Docker commands are expected for local verification.
- After Docker builds, clean dangling `<none>` images/layers with
  `docker image prune -f --filter "dangling=true"` when they are left behind.
- Do not run `docker system prune -a`, `docker volume prune`, or remove named
  volumes unless explicitly requested.
