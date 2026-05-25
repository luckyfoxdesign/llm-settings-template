# [project-name]-[repo-name]

Часть workspace `dev/[project-name]/`. Продуктовая документация, backlog, общие скиллы — на уровне workspace (`../docs/`, `../AGENTS.md`, `../CLAUDE.md`, `../.claude/commands/`). Этот файл — [repo-name]-локальная справка.

## Карта проекта

`PROJECT_MAP.md` — актуальный индекс модулей, роутов, задач, моделей. Читай перед задачами вместо сканирования всего проекта.

## Docker

Вся работа ведётся через Docker. Исключение — git: все git-команды выполняются локально.

- Конфигурация — `compose.yml` (не `docker-compose.yml`)
- Запускать сервисы, тесты, линтер только через `docker compose run --rm <service>` или `docker compose up`
- Не использовать локальный venv, локальный pip, локальные интерпретаторы

## Архитектура

<!-- Describe key architecture decisions here -->

## Качество кода

```bash
docker compose run --rm lint   # линтер
docker compose run --rm test   # тесты
```

## Деплой

<!-- Describe deploy process or reference runbook-prod.md -->
