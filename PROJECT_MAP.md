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
├── _templates/sub-repo/      — шаблон для новых суб-репо (см. ниже)
│
├── app/                      — отдельный git repo (переименуй под свой стек)
├── landing/                  — frontend/landing repo (опционально)
└── nginx/                    — отдельный git repo
```

## Добавление нового суб-репо

При создании нового суб-репо (`git init <repo-name>`) скопируй в него шаблон:

```bash
cp -r _templates/sub-repo/. <repo-name>/
```

Затем замени плейсхолдеры `[project-name]` и `[repo-name]` в `CLAUDE.md` и `AGENTS.md`, и заполни секции архитектуры/тестов/деплоя.

## Repos

| Репо | Карта | Status |
|------|-------|--------|
| app | `app/PROJECT_MAP.md` | — |
| landing | `landing/package.json` | — |
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

## landing (`landing/`)

Frontend/landing repo. См. `landing/package.json` и repo-local README/CLAUDE.md, если существуют.

Ключевые команды:
```bash
cd landing
docker compose up              # запуск
docker compose run --rm build  # сборка
```

## nginx (`nginx/`)

Prod nginx reverse proxy + SSL. См. `nginx/README.md`.

## Active tasks (`docs/wip/`)

<!-- Ссылки на docs/wip/ — обновляй вручную или скриптом -->

## Backlog (`docs/backlog/todo/`)

<!-- Ссылки на docs/backlog/todo/ — обновляй вручную или скриптом -->
