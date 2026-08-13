---
type: done_short
status: done
project: workspace
created: 2026-08-13
area:
  - workflow
  - quality-gates
---

# Give The Workspace Its Own Executable Gate

**Commits:**
- workspace `7d4139b` — "feat: add strict workspace verification gate"

## What Changed

- Added root `scripts/verify.sh`, a fail-fast gate for workspace tasks.
- Added opt-in `--strict` exits to context-budget, frontmatter, and task-contract
  checks while preserving their warning-only default behavior.
- Made `/complete-task` run exact task verification, require evidence for every
  DoD item, and refuse closure on failed, missing, or unverifiable evidence.
- Replaced the impossible self-referential workspace commit placeholder with a
  task implementation commit followed by a completion-docs commit.
- Scoped staging to task-related paths so unrelated dirty work is preserved.

## Verification Evidence

- The real workspace gate and every direct/strict validator passed.
- Four isolated negative cases each returned 1 and named the failing gate.
- Direct warning-only checks returned 0 on the same invalid fixtures; strict
  invocations returned 1.
- `AGENTS.md` ended at 80 lines / 6823 bytes; `git diff --check` passed.
- One contract review returned `NO_BLOCKING_FINDINGS`.

---
[Full plan](../long/07-08-26-workspace-verify-gate.md)
