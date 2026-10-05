---
name: review-task
description: Review an existing docs/wip implementation against its frozen contract and current snapshot. Use for a requested task review; do not repeat unchanged reviews or edit implementation code.
---

# Review Task

Review the active task using its contract and current implementation snapshot.

1. Resolve this `SKILL.md` path, including symlinks, to locate its owning workspace with `AGENTS.md` and `docs/workflows/task-lifecycle.md`. If these are absent, report missing workspace setup.
2. Read and follow the complete algorithm in `docs/workflows/task-lifecycle.md`, section `/review-task` Equivalent (`docs/workflows/task-lifecycle.md#review-task-equivalent`), and the policy it points to in `docs/product/architecture/verification-contract.md` → Review policy. Resolve these paths from the workspace root. The linked procedure and policy own lifecycle details.
3. Decide **whether to intervene at all** as a separate first step, before deciding what to change.
4. Judge only against the frozen contract. Taste, hypothetical future needs, and claims without reproducible scenario, test, or tool evidence are not defects.
5. Never rewrite working code and never emit a new full version of a file. Propose the minimal fix for admissible findings only.

Reuse an unchanged recorded review. Report the blocking outcome, any non-blocking findings, and snapshot evidence as the linked procedure requires; do not edit implementation code during standalone review.
