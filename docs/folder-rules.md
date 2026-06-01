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
│   └── update-project-map.sh
└── ...
```

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
- `related_code`: repo-prefixed code paths, e.g. `app/src/...`
- `related_docs`: docs paths
- `source.kind`: `discussion`, `issue`, `observation`

Rules:

- Frontmatter complements folder structure; it does not replace it.
- `priority` is not used.
- Do not store secrets, env values, or temporary debug notes.
- Existing archived `done/` files without frontmatter do not need forced migration.

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
