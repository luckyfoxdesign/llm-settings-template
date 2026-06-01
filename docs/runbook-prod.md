# Production Runbook

<!-- TEMPLATE: fill placeholders for your project and delete this comment.
     This is an operational deploy/incident reference. Commands should be copy-pasteable. -->

Operational reference for deploying `[project-name]`.

All commands run on `[your-server-alias]` as `[user]`. VPS project path: `[~/project-path]`.

## Environment

`.env` lives on the server at `[~/project-path]/.env` and is not committed. Minimum required variables:

```text
# Group by service: database, external APIs, app secrets.
DATABASE_URL=
# SECRET_KEY=<strong-random>
# THIRD_PARTY_API_KEY=
LOG_LEVEL=info
```

<!-- Mark variables required by compose.prod.yml, especially those using `:?`. -->

## SSH

```bash
ssh [your-server-alias]
```

## Deploy

```bash
ssh [your-server-alias] "cd [~/project-path] && bash scripts/deploy.sh"
```

`scripts/deploy.sh` should run: `git pull`, `docker compose -f compose.prod.yml build`, migrations if needed, then `docker compose -f compose.prod.yml up -d`.

<!-- Describe ordering: whether migrations run before new containers, whether downtime is expected, etc. -->

## Rollback

1. Find a previous version: `git log --oneline -n 5`.
2. On the VPS:

```bash
ssh [your-server-alias]
cd [~/project-path]
git checkout <prev-sha>
docker compose -f compose.prod.yml build
docker compose -f compose.prod.yml up -d
```

3. If database migrations exist, document how to downgrade or restore before switching code.

After rollback, return HEAD to main: `git checkout main && bash scripts/deploy.sh`.

## Backup / Restore

<!-- If a database exists, document backup and restore commands. Example for Postgres:

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

Move backups off the VPS with scp/rsync or offsite storage. -->

## Health And Observability

| Service | Strategy |
|---|---|
| `[service]` | <!-- Docker healthcheck / restart policy / Sentry / logs --> |

## Useful Commands

```bash
docker compose -f compose.prod.yml ps
docker compose -f compose.prod.yml logs --tail 200 [service]
```
