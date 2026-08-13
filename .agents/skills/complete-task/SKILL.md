---
name: complete-task
description: Verify, document, commit, and close an active project task through the workspace completion workflow. Use when a user asks to complete, close, finish, archive, or finalize a task already in docs/wip after implementation. Do not use to create or start a task, perform an extra review pass, or declare unfinished work complete.
---

# Complete Task

Close one active task only after its contract is satisfied.

1. Locate the workspace root containing `AGENTS.md` and `docs/wip/`.
2. Read and follow the complete algorithm in `AGENTS.md`, section `/complete-task` Equivalent (`AGENTS.md#complete-task-equivalent`). Treat that section as the source of truth if this skill and the workspace disagree.
3. Use the user's arguments to identify the active task when supplied. Let the workspace algorithm handle a missing or ambiguous selection.
4. Enforce the stop rule and executable gates. Do not bypass failures, omit required evidence, commit unrelated changes, or close an incomplete task.
5. Create the long and short completion records, task-related commits, and final report exactly as the workspace algorithm requires.

Finish only when every required completion step succeeds.
