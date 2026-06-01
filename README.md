# LLM Settings Workspace Template

Template for a local LLM-friendly workspace that keeps product docs, task flow, and shared agent context separate from code repos.

Code repos live as independent git repos inside this workspace, for example:

```text
dev/[project-name]/
├── app/
├── landing/
├── nginx/
└── docs/
```

This workspace repo is not deployed. It exists to organize context, tasks, docs, and repeatable agent workflows.

## Start Here

After cloning:

1. Replace `[project-name]` placeholders in root docs.
2. Run:

```bash
bash scripts/init-workspace.sh
```

3. For each code repo, create or clone it under the workspace.
4. Copy the repo template into each code repo:

```bash
cp -r _templates/sub-repo/. app/
```

5. Fill each repo's `AGENTS.md`, `CLAUDE.md`, `PROJECT_MAP.md`, and `scripts/update-project-map.sh`.
6. Keep workspace `PROJECT_MAP.md` as an aggregator only. Repo internals belong in `<repo>/PROJECT_MAP.md`.

## Files To Read

For humans:

- `README.md` — entrypoint and setup.
- `docs/folder-rules.md` — docs, backlog, done, and project-map rules.
- `PROJECT_MAP.md` — current workspace map.

For coding agents:

- `AGENTS.md` — required behavior, permissions, `/start-task`, `/complete-task`.
- `CLAUDE.md` — compact workspace context.
- `<repo>/AGENTS.md` and `<repo>/CLAUDE.md` — repo-local rules.
- `<repo>/PROJECT_MAP.md` — repo-local structure map.

## Task Flow

Tasks live in workspace `docs/`, not inside code repos.

```text
docs/backlog/todo/  ->  docs/wip/  ->  docs/done/long/
                                      ->  docs/done/short/
```

Use:

- `/start-task` to move a task into WIP, read context, and plan.
- `/complete-task` to write done docs, collect commits, and close the task.

The full algorithms are in `AGENTS.md`.

## Project Maps

Project maps prevent agents from scanning the whole repo.

- Root `PROJECT_MAP.md` aggregates workspace-level facts.
- `<repo>/PROJECT_MAP.md` describes one code repo.
- `generated` blocks may be rewritten by scripts.
- `manual` blocks are protected.
- Map scripts are project-specific:
  - `scripts/update-project-map.sh`
  - `<repo>/scripts/update-project-map.sh`

## Safety Defaults

- Do not read `.env` or `.env.*`.
- `.env.example` may be read and edited.
- Code work is Docker-only.
- Do not run destructive commands unless explicitly requested.
- Never commit secrets.

See `AGENTS.md` for the exact policy.
