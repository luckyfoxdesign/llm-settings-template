# [project-name]-[repo-name]

Part of workspace `dev/[project-name]`. Product docs, backlog, and shared commands live in `../docs/`, `../AGENTS.md`, `../CLAUDE.md`, and `../.claude/commands/`.

This file is repo-local context only.

## Project Map

`PROJECT_MAP.md` indexes repo structure: entrypoints, key directories, configs, Docker services, package/build/test scripts, API/routes/jobs/models when relevant.

Read it before scanning the repo.

Protected blocks:

- `generated`: facts that scripts may rewrite;
- `manual`: short repo-local notes, conventions, sharp edges.

Long architecture decisions live in `../docs/product/architecture/`.

Update the map with `scripts/update-project-map.sh`. The script is repo-specific and updates only the generated block.

## Docker

Use Docker for all runtime, test, lint, and dependency work. Git runs locally.

- Config file: `compose.yml`.
- Use `docker compose run --rm <service>` or `docker compose up`.
- Do not use local venv, local pip, or local interpreters.
- After Docker builds, clean only dangling layers when needed:
  `docker image prune -f --filter "dangling=true"`.
- Do not run `docker system prune -a`, `docker volume prune`, or remove named volumes unless explicitly requested.

## Architecture

<!-- Describe key architecture decisions here. -->

## Code Quality

```bash
docker compose run --rm lint
docker compose run --rm test
```

## Deploy

<!-- Describe deploy process or reference ../docs/runbook-prod.md. -->
