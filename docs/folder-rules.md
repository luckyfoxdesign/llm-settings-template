# Docs Rules

`docs/` is workspace-level product documentation for all repos. Code repos (`app/`, `landing/`, `nginx`) do not keep their own product backlog.

`docs/wip/` is local and gitignored.

## Layout

```text
docs/
├── wip/                  # active local tasks
├── backlog/
│   ├── todo/             # ready tasks
│   └── bugs/             # bug reports before implementation
├── ideas/                # raw ideas
├── done/
│   ├── long/             # full completed task records
│   └── short/            # concise completion summaries
├── product/
│   ├── architecture/     # stable architecture decisions
│   └── vision/           # product vision
└── folder-rules.md
```

## Project Maps

Maps have two levels.

Workspace `PROJECT_MAP.md` is only an aggregator:

- lists repos;
- links to `<repo>/PROJECT_MAP.md`;
- keeps shared commands and top-level structure;
- does not duplicate repo modules, routes, models, services, or internals.

Every code repo must include:

```text
<repo>/
├── AGENTS.md
├── CLAUDE.md
├── PROJECT_MAP.md
├── scripts/
│   ├── update-project-map.sh
│   └── verify.sh
└── ...
```

`scripts/verify.sh` is the repo's single executable gate: it runs lint, test, type check, and build in order and exits non-zero on the first failure. A task in that repo stops on this exit code. New repos get it from `_templates/sub-repo/` with TODO stubs that fail until filled in.

Repo-local `PROJECT_MAP.md` is the source of truth for repo structure: entrypoints, key directories, configs, Docker services, package scripts, API/routes/jobs/models when relevant.

Recommended repo map shape:

```markdown
# <repo> Project Map

<!-- generated:start -->
## Generated Structure
## Commands
## Entrypoints
## Config Files
## Notable Directories
<!-- generated:end -->

<!-- manual:start -->
## Architecture Notes
## Conventions
## Known Sharp Edges
<!-- manual:end -->
```

Rules:

- Scripts may rewrite only `generated` blocks.
- `manual` blocks are edited intentionally by a human or agent.
- Long architecture decisions live in `docs/product/architecture/`.
- New repos are created from `_templates/sub-repo/.`.
- Repo structure changes must update the repo-local map.
- Workspace map composition is done by `scripts/update-project-map.sh`.
- Repo-local map generation is done by `<repo>/scripts/update-project-map.sh`.
- If a map script is not implemented yet, add a stub with explicit TODOs.
- `scripts/verify.sh` is listed in the repo map `Commands` block, and its gates are tabulated in `<repo>/AGENTS.md`.

## Task Names

Task filename format: `dd-mm-yy-<project>-<slug>.md`.

| Project | Filename prefix | Frontmatter |
|---|---|---|
| app | `dd-mm-yy-app-...` | `project: app` |
| landing | `dd-mm-yy-landing-...` | `project: landing` |
| nginx | `dd-mm-yy-nginx-...` | `project: nginx` |
| workspace | `dd-mm-yy-workspace-...` | `project: workspace` |
| cross-repo | `dd-mm-yy-cross-<a>-<b>-...` | `project: cross`, `projects: [...]` |

`workspace` tasks change only workspace rules, scripts, or docs.

## Task Contract

Every task file in `docs/backlog/todo/` and `docs/wip/` carries these sections. Shape example: `docs/backlog/todo/00-00-00-app-example-task.md`. Rationale: `docs/product/architecture/verification-contract.md`.

| Section | Purpose |
|---|---|
| `Goal` | Expected outcome, one or two sentences |
| `Context` | Origin, known facts, constraints |
| `Non-goals` | What must not change |
| `Invariants` | What must still hold |
| `Change Budget` | Max production files, dependency and abstraction limits |
| `Verification` | The exact commands that produce the pass/fail signal |
| `Done When` | Stop conditions |

`Implementation Steps` and `Related` are conventional but not part of the contract.

`Non-goals`, `Invariants`, `Change Budget`, and `Verification` are frozen before implementation and changed only on a new external fact: a contradicting test, a user requirement, API documentation, a production incident, or a confirmed architectural constraint.

For `project: app|landing|nginx`, `Verification` is `bash <repo>/scripts/verify.sh`. For `project: workspace`, it is the relevant workspace scripts.

Check:

```bash
python3 scripts/check-task-contract.py
```

Warning-only, always exits 0. Files carrying `TEMPLATE-EXAMPLE` inside an HTML comment are skipped.

### Severity Routing

After a review pass, findings that are not blocking go to their folder rather than into the current task:

| Severity | Destination |
|---|---|
| `blocker`, `high` | fix in the current task |
| `medium` | `docs/backlog/todo/` |
| `speculative` | `docs/ideas/` |
| cosmetic | dropped |

## Task Lifecycle

1. Create ready tasks in `docs/backlog/todo/`.
2. Create bug reports in `docs/backlog/bugs/`.
3. Keep raw ideas in `docs/ideas/`.
4. When work starts, move the file to `docs/wip/` and preserve the filename.
5. Keep `docs/wip/` small: only active work.
6. If a task is split, use suffixes in the slug: `...-a-models.md`, `...-b-api.md`.
7. When complete:
   - create `docs/done/long/<filename>`;
   - create `docs/done/short/<filename>`;
   - link the two files;
   - delete the original `docs/wip/<filename>`.

## Done Commit Block

Always use a list:

```markdown
**Commits:**
- app `abc1234` — "feat: description"
- nginx `def5678` — "fix: description"
```

Short summary format:

```markdown
# Task Title

**Commits:**
- app `abc1234` — "feat: description"

## What Changed

- Item 1
- Item 2

---
[Full plan](../long/<filename>)
Closes #N
```

Remove `Closes #N` when there is no GitHub issue.

## Frontmatter

All new docs files, except technical references like `folder-rules.md`, should start with YAML frontmatter.

Task:

```yaml
---
type: task
status: todo
project: app
created: 2026-05-16
---
```

Cross-repo task:

```yaml
---
type: task
status: todo
project: cross
projects:
  - app
  - nginx
created: 2026-05-16
---
```

Idea:

```yaml
---
type: idea
status: draft
created: 2026-05-16
---
```

Required fields:

- `type`, `status` for every file with frontmatter;
- `project` for `type: task` and `type: bug` in backlog or WIP;
- `projects` when `project: cross`.

Allowed `type`: `task`, `bug`, `idea`, `vision`, `architecture`, `decision`, `done_long`, `done_short`, `research`.

Allowed `status`: `todo`, `wip`, `done`, `draft`, `blocked`.

Allowed `project`: `app`, `landing`, `nginx`, `workspace`, `cross`.

Optional fields:

- `created`: `YYYY-MM-DD`
- `area`: topic list
- `related_code`: repo-prefixed code paths, e.g. `app/src/...`. Recommended: `scripts/build-code-index.py` builds a reverse `code -> tasks` index (`docs/code-index.md`) from this field.
- `related_docs`: docs paths
- `source.kind`: `discussion`, `issue`, `observation`

Rules:

- Frontmatter complements folder structure; it does not replace it.
- `priority` is not used.
- Do not store secrets, env values, or temporary debug notes.
- Existing archived `done/` files without frontmatter do not need forced migration.

Validate:

```bash
python3 scripts/validate-docs-frontmatter.py
```

Runs on the host (not Docker; `docs/` is not copied into containers), needs only system Python 3.9+, and always exits 0 — it reports, it does not block.

## Done Index

`docs/done/INDEX.md` is generated from `docs/done/short/` by `scripts/build-done-index.py`, grouped by project and sorted newest-first. Regenerate it in `/complete-task`; do not edit it by hand.

## Hot Context Budget

| File | Lines | Bytes |
|---|---:|---:|
| `CLAUDE.md` | <= 60 | <= 3 KB |
| `AGENTS.md` | <= 180 | <= 7 KB |
| `PROJECT_MAP.md` | <= 200 | <= 7 KB |
| `~/.claude/.../MEMORY.md` | <= 30 | — |

Check manually:

```bash
bash scripts/check-context-budget.sh
```

The script should warn only and exit 0.

## Do Not Store

- Secrets, `.env` values, tokens.
- Facts already available in code or repo-local `CLAUDE.md`.
- Temporary debug notes without durable context.
