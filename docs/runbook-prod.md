# Production runbook

<!-- TEMPLATE: заполни [плейсхолдеры] под свой проект и удали этот комментарий.
     Это операционная шпаргалка на случай деплоя/инцидента — пиши команды так,
     чтобы их можно было скопировать и выполнить без додумывания. -->

Operational reference для деплоя [project-name]. Все команды выполняются на хосте `[your-server-alias]` (пользователь `[user]`). Код на VPS лежит по пути `[~/project-path]`.

## Переменные окружения

`.env` лежит на сервере в `[~/project-path]/.env` и не коммитится. Минимально необходимый набор:

```
# [сгруппируй по сервисам: БД, внешние API, секреты приложения]
DATABASE_URL=
# SECRET_KEY=<strong-random>
# THIRD_PARTY_API_KEY=
LOG_LEVEL=info
```

<!-- Отметь переменные, без которых compose.prod.yml не стартует (если используешь `:?`). -->

## SSH

```bash
ssh [your-server-alias]   # пользователь [user]
```

## Деплой

```bash
ssh [your-server-alias] "cd [~/project-path] && bash scripts/deploy.sh"
```

`scripts/deploy.sh` должен делать: `git pull` → `docker compose -f compose.prod.yml build` → `[миграции, если есть]` → `docker compose -f compose.prod.yml up -d`.

<!-- Опиши порядок шагов: применяются ли миграции до старта новых контейнеров и т.п. -->

## Rollback

1. Узнать предыдущую версию: `git log --oneline -n 5`
2. На VPS:
   ```bash
   ssh [your-server-alias]
   cd [~/project-path]
   git checkout <prev-sha>
   docker compose -f compose.prod.yml build
   docker compose -f compose.prod.yml up -d
   ```
3. <!-- Если есть БД-миграции: опиши, как откатывать несовместимую миграцию (downgrade или restore из бэкапа) ДО переключения кода. -->

После rollback вернуть HEAD на main: `git checkout main && bash scripts/deploy.sh`.

## Бэкап / Restore

<!-- Если есть БД — опиши команды бэкапа и восстановления. Пример для Postgres через docker exec:

ssh [your-server-alias]
cd [~/project-path]
set -a; . ./.env; set +a
docker compose -f compose.prod.yml exec -T postgres \
  pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --format=custom --no-owner \
  > "backups/[project]-$(date -u +%Y%m%dT%H%M%SZ).dump"

Restore:
docker compose -f compose.prod.yml exec -T postgres \
  pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists --no-owner \
  < backups/[project]-<timestamp>.dump

Важно: бэкапы нужно унести с VPS (scp/rsync на другую машину или offsite-хранилище). -->

## Health и observability

| Сервис | Стратегия |
|--------|-----------|
| `[service]` | <!-- Docker healthcheck / restart policy / Sentry / логи --> |

## Полезные команды

```bash
docker compose -f compose.prod.yml ps                       # статус
docker compose -f compose.prod.yml logs --tail 200 [service]  # логи
```
