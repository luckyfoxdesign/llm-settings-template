---
name: complete-task
description: Verify, record, commit, and close an implemented task already in docs/wip. Use for task completion or closure; do not start implementation or close unfinished work.
---

# Complete Task

Close one active task only after its contract is satisfied.

1. Resolve this `SKILL.md` path, including symlinks, to locate its owning workspace with `AGENTS.md` and `docs/workflows/task-lifecycle.md`. If these are absent, report missing workspace setup.
2. Read and follow the complete algorithm in `docs/workflows/task-lifecycle.md`, section `/complete-task` Equivalent (`docs/workflows/task-lifecycle.md#complete-task-equivalent`). Resolve these paths from the workspace root, not from the skill folder. The linked procedure owns lifecycle details.
3. Use the user's arguments to identify the active task when supplied. Let the workspace algorithm handle a missing or ambiguous selection.
4. Enforce the stop rule and executable gates. Do not bypass failures, omit required evidence, commit unrelated changes, or close an incomplete task.
5. Create the long and short completion records, task-related commits, and final report exactly as the workspace algorithm requires.

Finish only when every required completion step succeeds.
