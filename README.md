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

## Core Idea

A task ends when **external, executable checks pass** — not when a model judges its own work good enough.

Models propose changes. The stop criteria live outside the model: a task contract frozen before implementation, deterministic gates (`scripts/verify.sh`), a bounded diff, and one evidence-only review per implementation snapshot. Chaining more models adds opinion, not proof.

The reasoning, evidence, and rejected alternatives are in `docs/product/architecture/verification-contract.md`.

## Cross-Model By Design

The task lifecycle is written once and consumed by any agent:

- `.agents/skills/` — shared, model-neutral skill definitions.
- `.claude/skills/` — symlinks into `.agents/skills/`.
- `.claude/commands/` — Claude Code slash-command adapters.
- `AGENTS.md` — shared constraints and workflow links for every agent.
- `docs/workflows/task-lifecycle.md` — canonical procedures, loaded for the requested action.

`scripts/check-no-flow-duplication.sh` checks workflow ownership in known instruction files, without scanning code repos or private paths.

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

5. Run `bash scripts/link-workspace-skills.sh <repo>` for each code repo, then fill each repo's `AGENTS.md`, `CLAUDE.md`, `PROJECT_MAP.md`, `scripts/update-project-map.sh`, and `scripts/verify.sh`.
6. Keep workspace `PROJECT_MAP.md` as an aggregator only. Repo internals belong in `<repo>/PROJECT_MAP.md`.

The template ships `<repo>/scripts/verify.sh` as a TODO stub that **fails until you fill it in**. That is deliberate: a repo with no real gate should not be able to close tasks.

## Files To Read

For humans:

- `README.md` — entrypoint and setup.
- `docs/product/architecture/verification-contract.md` — why the flow is shaped this way.
- `docs/folder-rules.md` — docs, backlog, done, and project-map rules.
- `PROJECT_MAP.md` — current workspace map.

For coding agents:

- `AGENTS.md` — required behavior, permissions, and links to task lifecycle procedures.
- `CLAUDE.md` — compact workspace context.
- `<repo>/AGENTS.md` and `<repo>/CLAUDE.md` — repo-local rules.
- `<repo>/PROJECT_MAP.md` — repo-local structure map.

## Task Flow

Tasks live in workspace `docs/`, not inside code repos. Code repos keep no product backlog of their own.

```text
docs/
├── ideas/            # raw ideas
├── backlog/
│   ├── todo/         # ready tasks
│   └── bugs/         # bug reports before implementation
├── wip/              # active local tasks (gitignored)
├── done/
│   ├── long/         # full completed task records
│   └── short/        # concise completion summaries
└── product/
    ├── architecture/ # stable decisions
    └── vision/       # product vision
```

Task files are named `dd-mm-yy-<project>-<slug>.md`, where `<project>` is `app`, `landing`, `nginx`, `workspace`, or `cross`.

Use:

- `/create-task` to turn a request or idea into a ready task with a complete, frozen contract.
- `/start-task` to move a task into WIP, read context, plan, and open a task branch per code repo.
- `/review-task` to run the evidence-only pass on demand. `/complete-task` reuses it when the implementation snapshot is unchanged.
- `/complete-task` to run the gates, review, commit, merge the task branch, write done docs, and close the task.

Each step is backed by a script so the mechanics are deterministic rather than re-derived by the model: `new-task.sh` for frontmatter, `task-branch.sh` for branch start/finish, `check-staged-paths.sh` for staging discipline, `new-done-record.sh` for done scaffolds.

`/complete-task` is fail-closed: it blocks on any failed verification command, any unchecked `Done When` item, and any confirmed `blocker`/`high` finding.

The full algorithms are in `docs/workflows/task-lifecycle.md`.

## Verification

Three layers, each owned by exactly one place, nothing duplicated:

| Layer | Owner | Contents |
|---|---|---|
| Protocol | `docs/workflows/task-lifecycle.md` + `verification-contract.md` | Contract shape, review policy, stop rule, severity routing |
| Gates | `scripts/verify.sh`, `<repo>/scripts/verify.sh` | Concrete pass/fail commands |
| Contract | The task file in `docs/wip/` | Per-task goal, non-goals, invariants, budget, verification |

The protocol is written once. Gates are repo-specific, because only `app/`, `landing/`, and `nginx/` know their own test, lint, type-check, and build commands. Each repo exposes exactly one entrypoint that runs its gates in order and exits non-zero on the first failure:

```bash
bash <repo>/scripts/verify.sh    # code repos — runs in Docker
bash scripts/verify.sh           # workspace tasks — runs workspace validators, strict
```

The gate is reproducible, but its exit code proves only the checks it actually performs. Task-specific acceptance and review evidence remain required.

After the review pass, non-blocking findings leave the current task rather than expanding it:

| Severity | Destination |
|---|---|
| `blocker`, `high` | fix in the current task |
| `medium` | `docs/backlog/todo/` |
| `speculative` | `docs/ideas/` |
| cosmetic | dropped |

## Context Budget

Hot-context files are capped so agents keep reading them in full:

| File | Lines | Bytes |
|---|---:|---:|
| `CLAUDE.md` | <= 60 | <= 3 KB |
| `AGENTS.md` | <= 180 | <= 8 KB |
| `PROJECT_MAP.md` | <= 200 | <= 7 KB |

`scripts/check-context-budget.sh` reports usage; `scripts/verify.sh` enforces it.

## Project Maps

Project maps prevent agents from scanning the whole repo.

- Root `PROJECT_MAP.md` aggregates workspace-level facts: repos, links to repo maps, shared commands, active tasks.
- `<repo>/PROJECT_MAP.md` is the source of truth for one repo's internals: entrypoints, configs, Docker services, package scripts, key directories.
- Scripts may rewrite only `generated:start` / `generated:end` blocks; `manual` blocks are edited intentionally.
- Long architecture decisions live in `docs/product/architecture/`, not in generated blocks.
- Map scripts are project-specific:
  - `scripts/update-project-map.sh`
  - `<repo>/scripts/update-project-map.sh`

## Workspace Scripts

Host-side helpers in `scripts/` (run on the host, not in Docker).

Gate — strict, non-zero exit on the first violation:

- `verify.sh` — the executable gate for workspace tasks. Runs strict validators and workflow regression tests.

Lifecycle mechanics — deterministic steps used by the task commands:

- `new-task.sh` — create a task file with dates and mandatory frontmatter, never overwriting.
- `task-branch.sh` — `start` / `finish` a per-repo task branch; guards, merges locally, deletes the merged branch, stops on conflict.
- `check-staged-paths.sh` — enforce task paths and file budgets with `--task` (plus `--base main` for code repos); merge checks derive allowed paths from the task diff.
- `new-done-record.sh` — generate unfinished long and short done scaffolds from WIP; validate filled records before closure.

Validators — document/budget checks warn standalone; ownership checks always fail on a violation:

- `check-context-budget.sh` — flag hot-context files over their budgets.
- `check-no-flow-duplication.sh` — check workflow ownership only in known instruction files.
- `validate-docs-frontmatter.py` — flag docs with missing or invalid frontmatter.
- `check-task-contract.py` — reject incomplete task contracts; new done scaffolds remain blocked until acceptance evidence and existing project commits are recorded.

Setup and generated indexes:

- `init-workspace.sh` — create the docs folder structure (run once after cloning).
- `link-workspace-skills.sh` — add shared skill links to independent code repos, preserving existing files.
- `test-workflow.py` — run behavioral regressions in disposable repositories.
- `build-done-index.py` — regenerate `docs/done/INDEX.md` from done summaries.
- `build-code-index.py` — build `docs/code-index.md` from `related_code` frontmatter.
- `update-project-map.sh` — project-specific TODO stub for refreshing generated blocks in `PROJECT_MAP.md`.

## Safety Defaults

- Do not read `.env`, `.env.*`, or private key material (`.ssh/`, `*.pem`, `*.key`).
- `.env.example` may be read and edited.
- Code work is Docker-only.
- Do not run destructive commands unless explicitly requested.
- Never commit or log secrets.
- On the server: inspect before modifying; firewall, sshd, TLS, and server `.env` are off-limits unless the task explicitly asks.
- Before deploy: pre-deploy checks in `docs/runbook-prod.md` (tests, lint, prod build, diff review).

See `AGENTS.md` → Security for the exact policy.

## License

MIT — see `LICENSE`.

Workspace checks are read-only. Regenerate code/done indexes explicitly during completion. Frontmatter supports plain or quoted scalars, block lists, inline scalar lists, and nested mappings; unsupported YAML is rejected.
