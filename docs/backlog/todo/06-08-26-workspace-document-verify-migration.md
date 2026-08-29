---
type: task
status: todo
project: workspace
created: 2026-08-06
area:
  - workflow
  - quality-gates
related_docs:
  - docs/product/architecture/verification-contract.md
  - docs/folder-rules.md
  - AGENTS.md
---

# Document Migrating Existing Repos To scripts/verify.sh

**Status:** todo, not started
**Last checked:** 2026-08-06

## Goal

Close the gap between `AGENTS.md`, which requires `<repo>/scripts/verify.sh` unconditionally, and repos that predate the verification contract and do not have it yet.

## Context

Routed here as a `medium` finding from the single review pass on
`04-08-26-workspace-verification-contract.md` (see `docs/done/long/`).

`_templates/sub-repo/scripts/verify.sh` ships with every **new** repo, but `AGENTS.md` `/complete-task` step 5 names the script for **every** repo. In a workspace instantiated from this template, `app/`, `landing/`, and `nginx/` may already exist without it. Nothing currently tells the operator to add it, so the gate silently degrades into prose an agent can reinterpret — the exact failure the architecture doc warns about.

This template workspace has no code repos, so the fix is documentation, not migration.

## Non-goals

- Do not add `verify.sh` to any code repo from here; those repos do not exist in this workspace.
- Do not change `_templates/sub-repo/scripts/verify.sh` — it is already correct for new repos.
- Do not weaken the unconditional wording in `AGENTS.md` step 5.
- Do not add a migration script.

## Invariants

- `AGENTS.md` stays within 180 lines / 8192 bytes; `CLAUDE.md` within 60 lines / 3072 bytes.
- `AGENTS.md` remains the single source of the task-flow algorithm.
- Existing workspace scripts stay warning-only and exit 0.

## Change Budget

- At most 2 workspace files modified, 0 new.
- No new dependencies.
- No new scripts.

## Verification

```bash
bash scripts/check-context-budget.sh
bash scripts/check-no-flow-duplication.sh
python3 scripts/validate-docs-frontmatter.py
python3 scripts/check-task-contract.py
```

## Implementation Steps

1. Add a short migration note to `README.md` or `docs/folder-rules.md`: when adopting this template in a workspace with existing repos, copy `_templates/sub-repo/scripts/verify.sh` into each repo, fill in the gate table in `<repo>/AGENTS.md`, and list the script in `<repo>/PROJECT_MAP.md` under `Commands`.
2. Prefer `README.md` if `docs/folder-rules.md` already covers the layout adequately; pick one, not both.
3. Run the verification commands and record the output.

## Done When

- [ ] The verification commands pass with no new warnings.
- [ ] A reader adopting the template knows what to do about pre-existing repos.
- [ ] The diff stays within `Change Budget`.
- [ ] At most one reviewer pass has run.

## Related

- Architecture: `docs/product/architecture/verification-contract.md`
- Origin: `docs/done/long/04-08-26-workspace-verification-contract.md`
- Docs rules: `docs/folder-rules.md`
