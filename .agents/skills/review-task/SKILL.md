---
name: review-task
description: Review the active workspace task against its frozen contract in a single evidence-only pass. Use when a user asks to review, check, audit, or sanity-check an implementation already in docs/wip before completion. Do not use to create, start, or complete a task, to run a second review round, or to refactor code the contract does not cover.
---

# Review Task

Run one evidence-only review pass over the active task. The default answer is that nothing needs to change.

1. Locate the workspace root containing `AGENTS.md` and `docs/wip/`.
2. Read and follow the complete algorithm in `AGENTS.md`, section `/review-task` Equivalent (`AGENTS.md#review-task-equivalent`), and the policy it points to in `docs/product/architecture/verification-contract.md` → Review policy. Treat those as the source of truth if this skill and the workspace disagree.
3. Decide **whether to intervene at all** as a separate first step, before deciding what to change.
4. Judge only against the frozen contract. Taste, hypothetical future needs, and anything you cannot demonstrate by running something are not defects.
5. Never rewrite working code and never emit a new full version of a file. Propose the minimal fix for admissible findings only.

With no admissible `blocker` or `high`, reply exactly `NO_BLOCKING_FINDINGS` and change nothing. Run once; a further pass requires new external evidence.
