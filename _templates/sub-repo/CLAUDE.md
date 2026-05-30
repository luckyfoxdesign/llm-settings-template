# [project-name]-[repo-name]

Часть workspace `dev/[project-name]/`. Продуктовая документация, backlog, общие скиллы — на уровне workspace (`../docs/`, `../AGENTS.md`, `../CLAUDE.md`, `../.claude/commands/`). Этот файл — [repo-name]-локальная справка.

## Карта проекта

`PROJECT_MAP.md` — актуальный индекс модулей, роутов, задач, моделей. Читай перед задачами вместо сканирования всего проекта.

## Docker

Вся работа ведётся через Docker. Исключение — git: все git-команды выполняются локально.

- Конфигурация — `compose.yml` (не `docker-compose.yml`)
- Запускать сервисы, тесты, линтер только через `docker compose run --rm <service>` или `docker compose up`
- Не использовать локальный venv, локальный pip, локальные интерпретаторы
- После Docker build, если остаются dangling `<none>` images/layers, чистить только их:
  `docker image prune -f --filter "dangling=true"`.
- Не запускать `docker system prune -a`, `docker volume prune` и не удалять named volumes без явного запроса пользователя.

## Архитектура

<!-- Describe key architecture decisions here -->

## Качество кода

```bash
docker compose run --rm lint   # линтер
docker compose run --rm test   # тесты
```

## Деплой

<!-- Describe deploy process or reference runbook-prod.md -->
