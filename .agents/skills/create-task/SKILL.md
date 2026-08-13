---
name: create-task
description: Create a ready-to-start project task with complete frontmatter, a frozen implementation contract, bounded scope, and executable verification. Use when a user asks to create, draft, formalize, plan, or add a task to the backlog from a request, idea, issue, observation, or code context. Do not use to start, implement, review, or complete an existing task.
---

# Create Task

Create one implementation-ready task without starting it.

1. Locate the workspace root containing `AGENTS.md` and `docs/backlog/todo/`.
2. Read and follow the complete algorithm in `AGENTS.md`, section `/create-task` Equivalent (`AGENTS.md#create-task-equivalent`). Treat that section as the source of truth if this skill and the workspace disagree.
3. Use the user's request and any supplied issue, idea, observation, paths, or acceptance criteria as inputs. Inspect only the project context required by the algorithm.
4. Ask only for information whose absence would materially change the task contract. Record safe assumptions in `Context` when they do not require a user decision.
5. Stop after creating and validating the backlog file. Do not move it to `docs/wip/`, implement it, or commit it.

Finish with the exact result line required by the workspace algorithm.
