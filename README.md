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

Models propose changes. The stop criteria live outside the model: a task contract frozen before implementation, deterministic gates (`scripts/verify.sh`), a bounded diff, and at most one evidence-only review pass. Chaining more models adds opinion, not proof.

The reasoning, evidence, and rejected alternatives are in `docs/product/architecture/verification-contract.md`.

## Cross-Model By Design

The task lifecycle is written once and consumed by any agent:

- `.agents/skills/` — shared, model-neutral skill definitions.
- `.claude/skills/` — symlinks into `.agents/skills/`.
- `.claude/commands/` — Claude Code slash-command adapters.
- `AGENTS.md` — the same algorithms in prose, for agents without skill support.

`scripts/check-no-flow-duplication.sh` keeps `AGENTS.md` the single canonical copy.

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

5. Fill each repo's `AGENTS.md`, `CLAUDE.md`, `PROJECT_MAP.md`, `scripts/update-project-map.sh`, and `scripts/verify.sh`.
6. Keep workspace `PROJECT_MAP.md` as an aggregator only. Repo internals belong in `<repo>/PROJECT_MAP.md`.

The template ships `<repo>/scripts/verify.sh` as a TODO stub that **fails until you fill it in**. That is deliberate: a repo with no real gate should not be able to close tasks.

## Files To Read

For humans:

- `README.md` — entrypoint and setup.
- `docs/product/architecture/verification-contract.md` — why the flow is shaped this way.
- `docs/folder-rules.md` — docs, backlog, done, and project-map rules.
- `PROJECT_MAP.md` — current workspace map.

For coding agents:

- `AGENTS.md` — required behavior, permissions, and the complete task lifecycle commands.
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
- `/review-task` to run the evidence-only pass on demand. `/complete-task` runs the same pass anyway, so this is for checking early, not an extra round.
- `/complete-task` to run the gates, review, commit, merge the task branch, write done docs, and close the task.

Each step is backed by a script so the mechanics are deterministic rather than re-derived by the model: `new-task.sh` for frontmatter, `task-branch.sh` for branch start/finish, `check-staged-paths.sh` for staging discipline, `new-done-record.sh` for done records.

`/complete-task` is fail-closed: it blocks on any failed verification command, any unchecked `Done When` item, and any confirmed `blocker`/`high` finding.

The full algorithms are in `AGENTS.md`.

## Verification

Three layers, each owned by exactly one place, nothing duplicated:

| Layer | Owner | Contents |
|---|---|---|
| Protocol | `AGENTS.md` + `verification-contract.md` | Contract shape, review policy, stop rule, severity routing |
| Gates | `scripts/verify.sh`, `<repo>/scripts/verify.sh` | Concrete pass/fail commands |
| Contract | The task file in `docs/wip/` | Per-task goal, non-goals, invariants, budget, verification |

The protocol is written once. Gates are repo-specific, because only `app/`, `landing/`, and `nginx/` know their own test, lint, type-check, and build commands. Each repo exposes exactly one entrypoint that runs its gates in order and exits non-zero on the first failure:

```bash
bash <repo>/scripts/verify.sh    # code repos — runs in Docker
bash scripts/verify.sh           # workspace tasks — runs workspace validators, strict
```

A single exit code matters more than any prose rule: prose can be reinterpreted, an exit code cannot.

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

- `verify.sh` — the executable gate for workspace tasks. Runs the four validators below in strict mode.

Lifecycle mechanics — deterministic steps used by the task commands:

- `new-task.sh` — create a task file with dates and mandatory frontmatter, never overwriting.
- `task-branch.sh` — `start` / `finish` a per-repo task branch; guards, merges locally, deletes the merged branch, stops on conflict.
- `check-staged-paths.sh` — block a commit that stages paths outside the task.
- `new-done-record.sh` — generate the long and short done records from the WIP task.

Validators — warning-only standalone, strict under `verify.sh`:

- `check-context-budget.sh` — flag hot-context files over their budgets.
- `check-no-flow-duplication.sh` — keep the task-flow algorithm only in `AGENTS.md`.
- `validate-docs-frontmatter.py` — flag docs with missing or invalid frontmatter.
- `check-task-contract.py` — flag tasks with an incomplete contract.

Setup and generated indexes:

- `init-workspace.sh` — create the docs folder structure (run once after cloning).
- `build-done-index.py` — regenerate `docs/done/INDEX.md` from done summaries.
- `build-code-index.py` — build `docs/code-index.md` from `related_code` frontmatter.
- `update-project-map.sh` — refresh generated blocks in `PROJECT_MAP.md`.

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
