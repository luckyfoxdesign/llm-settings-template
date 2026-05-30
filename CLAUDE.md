# [project-name] workspace

Workspace продукта [project-name] — общий LLM-контекст, единый backlog, продуктовая документация.
Кодовые репо (`app/`, `landing/`, `nginx/`) — самостоятельные git-репо, gitignored из workspace.
На прод не выкатывается — workspace только локальная организация.

## Source of truth

| Тема | Файл |
|------|------|
| Обзор workspace, команды репо | `PROJECT_MAP.md` |
| Задачи, правила docs | `docs/folder-rules.md` |
| Скиллы /start-task, /complete-task | `AGENTS.md` |
| Прод-деплой, rollback | `docs/runbook-prod.md` |
| Локальная разработка | `docs/runbook-local.md` |
| App: архитектура, окружение | `app/CLAUDE.md`, `app/AGENTS.md` |
| Landing: frontend | `landing/package.json`, `landing/compose.yml` |
| Nginx: конфиг | `nginx/README.md` |
| Завершённые задачи | `docs/done/short/` |

## Rules

**Docker-only** — все команды (тесты, линтер, зависимости) только через Docker, локалку не трогать.

**Code search from workspace** — кодовые директории в `.gitignore`; всегда указывай `path:`:
```
Grep("pattern", path: "app")
Grep("pattern", path: "landing")
Grep("pattern", path: "nginx")
```

**Local Permissions**:
- Do not read `.env` or `.env.*` files (any level).
- `.env.example` may be read and edited.
- Never run: `rm -rf`, `git push --force`, `git reset --hard`, `chmod 777`, `sudo rm`, `curl/wget ... | bash`.

## SSH

```bash
ssh [your-server-alias]   # пользователь [user]
```

Деплой, rollback → `docs/runbook-prod.md`. Локальная разработка → `docs/runbook-local.md`.
