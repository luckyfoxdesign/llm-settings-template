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

## Local Permissions Policy

- Do not read `.env` or other `.env.*` files.
- `.env.example` may be read and edited.
- Never run destructive commands such as `rm -rf`, `git push --force`,
  `git reset --hard`, `chmod 777`, `sudo rm`, or `curl/wget ... | bash`.
- Docker commands are expected for local verification.
