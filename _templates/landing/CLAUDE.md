# [project-name]-[repo-name]

Astro 5 + Tailwind v4 landing, part of workspace `dev/[project-name]`. Product docs, backlog, shared skills, and commands live in `../docs/`, `../AGENTS.md`, `../CLAUDE.md`, `../.agents/skills/`, and `../.claude/commands/`.

This file is repo-local context only. `.claude/` is not part of this template: settings and slash commands come from the workspace spin-up, not from here.

## Project Map

`PROJECT_MAP.md` indexes repo structure: entrypoints, key directories, configs, Docker services, package scripts. Read it before scanning the repo.

Protected blocks:

- `generated`: facts that scripts may rewrite;
- `manual`: short repo-local notes, conventions, sharp edges.

Long architecture decisions live in `../docs/product/architecture/`.

Update the map with `scripts/update-project-map.sh`; it updates only the generated block.

## Docker

Use Docker for all runtime, build, and dependency work. Git runs locally.

- Config file: `compose.yml`; services `astro-dev` and `astro-prod`.
- Use `docker compose run --rm <service>` or `docker compose up`.
- Do not install Node or npm on the host.
- After Docker builds, clean only dangling layers when needed:
  `docker image prune -f --filter "dangling=true"`.
- Do not run `docker system prune -a`, `docker volume prune`, or remove named volumes unless explicitly requested.

## Design Tokens

`src/styles/global.css` → `@theme` is the source of truth for semantic colors. `tokens/` is generated from it and from the installed `tailwindcss`; never hand-edit generated files.

Adding or removing a `--color-*` declaration means updating `EXPECTED.semanticTokens` in `scripts/generate-tokens.mjs`, or `tokens:check` fails on purpose.

`figma-plugin/` is a dev-mode Figma plugin that reads `tokens/`. It is never built by Astro and never deployed.

## Code Quality

```bash
bash scripts/verify.sh          # single gate: build, then tokens:check
docker compose run --rm astro-dev npm run build
docker compose run --rm astro-dev npm run tokens:generate
docker compose run --rm astro-dev npm run tokens:check
docker compose run --rm astro-dev npm run tokens:lint
```

## Deploy

Static output to Vercel. Set `site` in `astro.config.mjs` before the first deploy. Pre-deploy checks: `../docs/runbook-prod.md`.
