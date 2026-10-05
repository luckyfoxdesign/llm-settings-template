---
name: create-task
description: Create an implementation-ready backlog task in this workspace from a request, idea, or issue. Use for task drafting and backlog additions; do not start implementation or close a task.
---

# Create Task

Create one implementation-ready task without starting it.

1. Resolve this `SKILL.md` path, including symlinks, to locate its owning workspace with `AGENTS.md` and `docs/workflows/task-lifecycle.md`. If these are absent, report missing workspace setup.
2. Read and follow the complete algorithm in `docs/workflows/task-lifecycle.md`, section `/create-task` Equivalent (`docs/workflows/task-lifecycle.md#create-task-equivalent`). Resolve these paths from the workspace root, not from the skill folder. The linked procedure owns lifecycle details.
3. Use the user's request and any supplied issue, idea, observation, paths, or acceptance criteria as inputs. Inspect only the project context required by the algorithm.
4. Ask only for information whose absence would materially change the task contract. Record safe assumptions in `Context` when they do not require a user decision.
5. Stop after creating and validating the backlog file. Do not move it to `docs/wip/`, implement it, or commit it.

Finish with the exact result line required by the workspace algorithm.
