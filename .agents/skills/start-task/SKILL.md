---
name: start-task
description: Start or resume implementation of an existing workspace task in docs/backlog/todo or docs/wip, including a partial filename. Do not create a new task or close the lifecycle.
---

# Start Task

Start one existing backlog task and follow it through implementation.

1. Resolve this `SKILL.md` path, including symlinks, to locate its owning workspace with `AGENTS.md` and `docs/workflows/task-lifecycle.md`. If these are absent, report missing workspace setup.
2. Read and follow the complete algorithm in `docs/workflows/task-lifecycle.md`, section `/start-task` Equivalent (`docs/workflows/task-lifecycle.md#start-task-equivalent`). Resolve these paths from the workspace root, not from the skill folder. The linked procedure owns lifecycle details.
3. Use the user's arguments as a task filename or substring. Let the workspace algorithm handle a missing or ambiguous selection.
4. Present the frozen contract and plan. Reuse authorization already supplied in this conversation; otherwise follow the plan confirmation boundary in the procedure.
5. Continue following the workspace algorithm after approval. Do not skip verification, expand the frozen contract without external evidence, or complete the task lifecycle on the user's behalf.

Finish with the exact result text required by the workspace algorithm.
