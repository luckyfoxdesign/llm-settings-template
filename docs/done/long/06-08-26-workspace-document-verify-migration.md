---
type: done_long
status: done
phase: completed
project: workspace
created: 2026-08-06
area:
  - workflow
  - quality-gates
related_docs:
  - docs/product/architecture/verification-contract.md
  - docs/folder-rules.md
  - AGENTS.md
completion_validation: required
---

**Commits:**
- workspace `432ba2d` — "docs: explain verification gate migration for existing repos"


# Document Migrating Existing Repos To scripts/verify.sh

**Status:** done
**Last checked:** 2026-11-16

## Goal

Close the gap between `AGENTS.md`, which requires `<repo>/scripts/verify.sh` unconditionally, and repos that predate the verification contract and do not have it yet.

## Context

Routed here as a `medium` finding from the single review pass on
`04-08-26-workspace-verification-contract.md` (see `docs/done/long/`).

`_templates/sub-repo/scripts/verify.sh` ships with every **new** repo, but `docs/workflows/task-lifecycle.md` `/complete-task` verification names the script for **every** repo. In a workspace instantiated from this template, `app/`, `landing/`, and `nginx/` may already exist without it. Nothing currently tells the operator to add it, so the gate silently degrades into prose an agent can reinterpret — the exact failure the architecture doc warns about.

This template workspace has no code repos, so the fix is documentation, not migration. On 2026-10-05 the workflow owner and mandatory gate were updated after the workspace rules audit; no implementation work on this backlog task has started.

## Non-goals

- Do not add `verify.sh` to any code repo from here; those repos do not exist in this workspace.
- Do not change `_templates/sub-repo/scripts/verify.sh` — it is already correct for new repos.
- Do not weaken the unconditional wording in the canonical completion verification procedure.
- Do not add a migration script.

## Invariants

- `AGENTS.md` stays within 180 lines / 8192 bytes; `CLAUDE.md` within 60 lines / 3072 bytes.
- `docs/workflows/task-lifecycle.md` remains the single source of task procedures; `AGENTS.md` routes to it.
- Standalone validators remain warning-only by default; the workspace gate uses strict checks.

## Change Budget

- At most 2 workspace files modified, 0 new.
- No new dependencies.
- No new scripts.

## Verification

```bash
bash scripts/verify.sh
```

## Task Paths

- `README.md`
- `docs/folder-rules.md`

## Implementation Steps

1. Add a short migration note to `README.md` or `docs/folder-rules.md`: when adopting this template in a workspace with existing repos, copy `_templates/sub-repo/scripts/verify.sh` into each repo, fill in the gate table in `<repo>/AGENTS.md`, and list the script in `<repo>/PROJECT_MAP.md` under `Commands`.
2. Prefer `README.md` if `docs/folder-rules.md` already covers the layout adequately; pick one, not both.
3. Run the verification commands and record the output.

## Done When

- [x] The verification commands pass with no new warnings. — Evidence: `bash scripts/verify.sh` exited 0 on 2026-11-16; strict context, ownership, frontmatter, contract checks and 23 workflow regression tests passed. The optional memory-not-found notice is informational; no new warnings.
- [x] A reader adopting the template knows what to do about pre-existing repos. — Evidence: `README.md` → `Existing Repos Without A Verification Gate` describes copying the gate, configuring real Docker commands, adding/filling the AGENTS gate table, listing the map command, and passing the gate before task closure.
- [x] The diff stays within `Change Budget`. — Evidence: `git diff --numstat -- README.md docs/folder-rules.md` reports only README.md, 12 insertions and 0 deletions; no new implementation files, dependencies, or scripts. The backlog-to-WIP move and this local evidence are lifecycle bookkeeping.
- [x] The final implementation snapshot has recorded review evidence. — Evidence: `Review Evidence` below identifies the final approved-path diff and records `NO_BLOCKING_FINDINGS`.

## Related

- Architecture: `docs/product/architecture/verification-contract.md`
- Origin: `docs/done/long/04-08-26-workspace-verification-contract.md`
- Docs rules: `docs/folder-rules.md`


## What Changed

- Added the existing-repo migration note to README.md: copy and configure the verification gate, document its commands in AGENTS.md and PROJECT_MAP.md, and pass it before task closure.
- Implementation commit: workspace `432ba2d` (README.md only, 12 insertions).

## Verification Evidence

- 2026-11-16: `bash scripts/verify.sh` exited 0: all workspace gates passed; 23 workflow regression tests passed. No new warnings.
- `git diff --check` exited 0.
- Implementation is limited to README.md (12 added lines); docs/folder-rules.md and all invariant/procedure/template files are unchanged.

## Review Evidence

- Outcome: `NO_BLOCKING_FINDINGS`. Reviewed once against the frozen goal, non-goals, invariants, budget, task paths, and acceptance criteria. No non-blocking findings.
- Workspace HEAD: `87663aff5aaa0b4d689220a1bea662082ef8bc10`.
- Uncommitted implementation snapshot: SHA-256 `9c6a9081a73ca38704236335373a415b30c5b0c8088a8742832e569c91772e05` of the bytes from `git diff --binary HEAD -- README.md docs/folder-rules.md`. WIP evidence prose is excluded.
- Compared the README migration steps with `_templates/sub-repo/scripts/verify.sh`, `_templates/sub-repo/AGENTS.md`, and the repo-map rules in `docs/folder-rules.md`: copy destination, Docker gate configuration, AGENTS table, map Commands entry, and required successful execution agree with the current contract.
- Completion reused the unchanged review: pre-commit HEAD and approved-path diff hash matched the recorded snapshot. Implementation commit `432ba2d` contains that exact README change; no implementation behavior changed after review.
- Completion reran `bash scripts/verify.sh`: exit 0, all workspace gates and 23 workflow regression tests passed; no new warnings. `python3 scripts/check-task-contract.py --strict` and the task-scoped staged-path guard passed.
- Unrelated pre-existing untracked backlog files were left unchanged.

[Short summary](../short/06-08-26-workspace-document-verify-migration.md)
