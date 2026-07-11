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

Agent rules on the server: start read-only (`ps`, `logs`, `git log`); do not change firewall, `sshd_config`, TLS certs, user accounts, or `.env` unless the task explicitly asks.

## Server Security Baseline

<!-- Fill in what is actually configured on the VPS so agents and humans can verify it, e.g.:
     - firewall: ufw, only 22/80/443 open
     - ssh: key-only auth, root login disabled
     - fail2ban on sshd
     - TLS: certbot auto-renew (systemd timer)
     - docker: no containers with published ports besides nginx -->

| Control | Status / How to verify |
|---|---|
| Firewall | <!-- `sudo ufw status` --> |
| SSH hardening | <!-- key-only, no root login --> |
| TLS renewal | <!-- `systemctl list-timers | grep certbot` --> |
| Exposed ports | <!-- `docker ps --format '{{.Names}}\t{{.Ports}}'` --> |

## Pre-Deploy Checks

Run locally before every deploy:

```bash
cd app
docker compose run --rm test
docker compose run --rm lint
docker compose -f compose.prod.yml build
docker compose -f compose.prod.yml config --quiet  # validates compose + env interpolation without printing secrets
```

<!-- If the prod stack can run locally, add the commands to start it against a local .env
     and hit the healthcheck before deploying. -->

Then:

- Review the outgoing diff for hardcoded secrets, debug leftovers, and weakened security config: `git log -p origin/main..HEAD` or a security review of the branch.
- If the change adds env variables: document them in `.env.example` and add real values to the server `.env` before deploying code that requires them.
- If the change includes migrations: confirm a fresh backup exists (see Backup / Restore).

## Deploy

```bash
ssh [your-server-alias] "cd [~/project-path] && bash scripts/deploy.sh"
```

After deploy, verify:

```bash
ssh [your-server-alias] "cd [~/project-path] && docker compose -f compose.prod.yml ps"
curl -fsS https://[domain]/[healthcheck-path]
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
