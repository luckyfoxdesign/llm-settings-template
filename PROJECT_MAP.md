# Workspace Project Map
<!-- Обновляй вручную или через скрипт при изменении структуры. -->
<!-- Читай перед задачами вместо сканирования всего workspace. -->

Aggregating map of the [project-name] workspace. Repo-local карты — источник правды для деталей конкретного репо; этот файл собирает обзор верхнего уровня.

## Workspace layout

```
dev/[project-name]/
├── AGENTS.md, CLAUDE.md, PROJECT_MAP.md
├── docs/                     — продуктовая документация (под git, кроме wip/)
├── .claude/commands/         — workspace-уровневые скиллы
│
├── app/                      — отдельный git repo (переименуй под свой стек)
└── nginx/                    — отдельный git repo
```

## Repos

| Репо | Карта | Status |
|------|-------|--------|
| app | `app/PROJECT_MAP.md` | — |
| nginx | `nginx/README.md` | — |

## app (`app/`)

См. `app/PROJECT_MAP.md` для актуального списка модулей и команд.

Ключевые команды:
```bash
cd app
docker compose up              # запуск
docker compose run --rm test   # тесты
docker compose run --rm lint   # линтер
```

## nginx (`nginx/`)

Prod nginx reverse proxy + SSL. См. `nginx/README.md`.

## Active tasks (`docs/wip/`)

<!-- Ссылки на docs/wip/ — обновляй вручную или скриптом -->

## Backlog (`docs/backlog/todo/`)

<!-- Ссылки на docs/backlog/todo/ — обновляй вручную или скриптом -->
