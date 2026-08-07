---
type: task
status: todo
project: workspace
created: 2026-08-07
area:
  - workflow
  - quality-gates
related_docs:
  - docs/product/architecture/verification-contract.md
  - docs/folder-rules.md
  - AGENTS.md
---

# Give The Workspace Its Own Executable Gate

**Status:** todo, not started
**Last checked:** 2026-08-07

## Goal

Make `project: workspace` tasks stop on an exit code instead of on someone reading script output, and close the `/complete-task` step that does not stage workspace changes.

## Context

`docs/product/architecture/verification-contract.md` states that workspace tasks use the workspace scripts as their gate. Those scripts cannot fail:

| Command | Can it fail? |
|---|---|
| `scripts/check-context-budget.sh` | no — `always exits 0` |
| `scripts/validate-docs-frontmatter.py` | no — `return 0` |
| `scripts/check-task-contract.py` | no — warning-only by contract |
| `scripts/check-no-flow-duplication.sh` | yes — `exit 1` |

So code repos got a real gate in `<repo>/scripts/verify.sh` while the workspace kept prose. This is the failure the architecture doc names directly: described in text, a gate can be reinterpreted; as an exit code, it cannot.

Evidence from `docs/done/long/04-08-26-workspace-verification-contract.md`: `check-task-contract.py` shipped with a defect that silently skipped every task file mentioning `TEMPLATE-EXAMPLE` in prose. All five verification commands returned success. A human noticed the file count looked wrong.

Second, smaller gap found by running the flow: `AGENTS.md` step 10 stages `docs/done/`, `docs/backlog/`, and `PROJECT_MAP.md`. For a workspace task the real changes sit in `AGENTS.md`, `CLAUDE.md`, `scripts/`, `_templates/`, and `.claude/`. Followed literally, the commit records the write-up but not the work.

Both gaps are the workspace failing the contract it prescribes to others, so they belong in one task.

## Non-goals

- Do not make the existing workspace scripts exit non-zero by default — they stay warning-only and safe to run anytime.
- Do not add `verify.sh` to code repos; they do not exist in this workspace.
- Do not rewrite the task-flow algorithm; extend `/complete-task` step 10 only.
- Do not restate the protocol; `AGENTS.md` keeps a pointer to the architecture doc.
- Do not add a second reviewer, backtracking, or any new flow stage.

## Invariants

- Running any existing workspace script directly still exits 0.
- `AGENTS.md` remains the single source of the task-flow algorithm; `scripts/check-no-flow-duplication.sh` still passes.
- `AGENTS.md` stays within 180 lines / 7168 bytes. It is at 128 lines / 6904 bytes, so **264 bytes of headroom** — the binding constraint of this task.
- `CLAUDE.md` stays within 60 lines / 3072 bytes; it is at 57 lines.
- Existing files in `docs/done/` are not retrofitted.
- No secrets, env values, or server hostnames enter any touched file.

## Change Budget

- At most 4 workspace files: 1 new, 3 modified.
- No new dependencies; bash and the existing scripts only.
- `scripts/verify.sh` stays a single flat file with no helper modules.
- No new directories.

## Verification

```bash
bash scripts/verify.sh
bash scripts/check-context-budget.sh
bash scripts/check-no-flow-duplication.sh
python3 scripts/validate-docs-frontmatter.py
python3 scripts/check-task-contract.py
```

The first command must exit 0 on a clean tree. The rest must still exit 0 when run directly, proving the wrapper did not change them.

Passing is not sufficient here: this task is about a gate that can fail, so the negative tests in `Done When` are the real evidence.

## Implementation Steps

1. Add `scripts/verify.sh`: `set -euo pipefail`, runs the four checks in order, exits non-zero on the first real violation, and names the check that failed. Mirror the shape of `_templates/sub-repo/scripts/verify.sh`.
2. Decide how the wrapper detects a violation and record the choice in the task: either grep each script's output for its warning markers, or add an opt-in `--strict` flag to each script that keeps the default exit 0. Output parsing is fragile; a flag touches more files. Pick one and say why.
3. Extend `AGENTS.md` `/complete-task` step 10 so a `project: workspace` task stages the workspace files it actually changed, not only `docs/`. Stay inside the 264-byte headroom.
4. Add `scripts/verify.sh` to the workspace scripts list in `AGENTS.md`.
5. Note the workspace gate in `docs/folder-rules.md` next to the existing `verify.sh` description, so both levels are documented in one place.
6. Run the negative tests below, restoring the workspace after each.
7. Run the verification commands and record the output in this file.

## Done When

- [ ] `bash scripts/verify.sh` exits 0 on a clean tree.
- [ ] It exits non-zero, naming the failed check, for each of: hot-context budget breach, flow duplication outside `AGENTS.md`, a task file missing contract sections, a docs file with invalid frontmatter. Each demonstrated and the output recorded.
- [ ] Each existing workspace script still exits 0 when run directly.
- [ ] `AGENTS.md` is within 180 lines / 7168 bytes.
- [ ] A `project: workspace` task committed through step 10 stages the changed workspace files.
- [ ] The diff stays within `Change Budget`.
- [ ] At most one reviewer pass has run.

## Related

- Architecture: `docs/product/architecture/verification-contract.md`
- Origin: `docs/done/long/04-08-26-workspace-verification-contract.md`
- Docs rules: `docs/folder-rules.md`
- Flow: `AGENTS.md`
