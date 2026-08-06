# [repo-name] Project Map
<!-- Repo-local map is the source of truth for this repo internals. -->
<!-- Workspace ../PROJECT_MAP.md aggregates repo maps and should not duplicate this detail. -->

## Map contract

- Keep generated facts inside `generated` block.
- Keep short repo-local notes inside `manual` block.
- Store long architecture decisions in workspace `../docs/product/architecture/`.
- Update this map when repo structure, entrypoints, commands, routes, jobs, models, or configs change.
- Keep the repo-local update script at `scripts/update-project-map.sh`.

<!-- generated:start -->
## Generated Structure

```text
[repo-name]/
├── AGENTS.md
├── CLAUDE.md
├── PROJECT_MAP.md
├── scripts/
│   ├── update-project-map.sh
│   └── verify.sh
└── ...
```

## Commands

```bash
bash scripts/verify.sh
docker compose up
docker compose run --rm lint
docker compose run --rm test
```

## Entrypoints

- TODO: add application entrypoints.

## Config Files

- `compose.yml` — Docker services.
- `scripts/update-project-map.sh` — updates this repo map generated block.
- `scripts/verify.sh` — single executable gate; exits non-zero on the first failing gate.

## Notable Directories

- TODO: add important directories.
<!-- generated:end -->

<!-- manual:start -->
## Architecture Notes

- TODO: add short repo-local architecture notes.

## Conventions

- TODO: add repo-local conventions.

## Known Sharp Edges

- TODO: add important caveats.
<!-- manual:end -->
