---
name: start-task
description: Start and implement an existing ready task from the project backlog through the workspace planning and verification workflow. Use when a user asks to start, begin, pick up, or implement a task already stored in docs/backlog/todo, including explicit start-task requests or partial task filenames. Do not use to create a new task, review an implementation independently, or close a completed task.
---

# Start Task

Start one existing backlog task and follow it through implementation.

1. Locate the workspace root containing `AGENTS.md` and `docs/backlog/todo/`.
2. Read and follow the complete algorithm in `AGENTS.md`, section `/start-task` Equivalent (`AGENTS.md#start-task-equivalent`). Treat that section as the source of truth if this skill and the workspace disagree.
3. Use the user's arguments as a task filename or substring. Let the workspace algorithm handle a missing or ambiguous selection.
4. Preserve the confirmation boundary: present the frozen contract and plan, then wait for approval before implementation.
5. Continue following the workspace algorithm after approval. Do not skip verification, expand the frozen contract without external evidence, or complete the task lifecycle on the user's behalf.

Finish with the exact result text required by the workspace algorithm.
