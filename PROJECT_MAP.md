# Workspace Project Map
<!-- Aggregates repo maps. Repo internals live in <repo>/PROJECT_MAP.md. -->
<!-- Read this before scanning the workspace. -->

Top-level map for the `[project-name]` workspace.

## Map Contract

- Workspace `PROJECT_MAP.md` is an aggregator: repos, repo-map links, shared commands, active task pointers.
- Repo-local `<repo>/PROJECT_MAP.md` is the source of truth for repo internals: entrypoints, configs, Docker services, package scripts, key directories.
- Long architecture decisions live in `docs/product/architecture/`, not in generated map sections.
- Scripts may rewrite only generated sections; manual sections are protected.
- Map update scripts are project-specific:
  - workspace aggregator: `scripts/update-project-map.sh`
  - repo-local updater: `<repo>/scripts/update-project-map.sh`

## Workspace Layout

```text
dev/[project-name]/
├── AGENTS.md, CLAUDE.md, PROJECT_MAP.md
├── docs/                     # product docs; docs/wip is gitignored
├── scripts/                  # workspace scripts, including update-project-map.sh
├── .agents/skills/           # shared, model-neutral workspace skills
├── .claude/skills/           # Claude links to shared skills
├── .claude/commands/         # Claude command adapters
├── _templates/sub-repo/      # template for new code repos
├── app/PROJECT_MAP.md        # app repo, has its own update-project-map.sh
├── landing/PROJECT_MAP.md    # landing repo, has its own update-project-map.sh
└── nginx/PROJECT_MAP.md      # nginx repo, has its own update-project-map.sh
```

## Adding A Code Repo

After `git init <repo-name>`, copy the template:

```bash
cp -r _templates/sub-repo/. <repo-name>/
```

Then replace `[project-name]` and `[repo-name]`, fill `CLAUDE.md`, `AGENTS.md`, `PROJECT_MAP.md`, and implement or stub `<repo>/scripts/update-project-map.sh`.

## Repos

| Repo | Map | Status |
|---|---|---|
| app | `app/PROJECT_MAP.md` | — |
| landing | `landing/PROJECT_MAP.md` | — |
| nginx | `nginx/PROJECT_MAP.md` | — |

## app

See `app/PROJECT_MAP.md`.

```bash
cd app
docker compose up
docker compose run --rm test
docker compose run --rm lint
```

## landing

See `landing/PROJECT_MAP.md`.

```bash
cd landing
docker compose up
docker compose run --rm build
```

## nginx

See `nginx/PROJECT_MAP.md`.

## Active Tasks

<!-- generated:start active-tasks -->
<!-- generated:end active-tasks -->

## Backlog

<!-- generated:start backlog -->
<!-- generated:end backlog -->
