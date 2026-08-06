---
type: task
status: todo
project: app
created: 0000-00-00
area:
  - example
related_code:
  - app/src/...
---

# Example Task

<!-- TEMPLATE-EXAMPLE: sample task format, not a real task.
     Filename: dd-mm-yy-<project>-<slug>.md.
     Frontmatter is required. project: app|landing|nginx|workspace|cross.
     For cross-repo tasks, add `projects: [a, b]`.
     Sections below are the task contract: docs/product/architecture/verification-contract.md.
     Freeze Non-goals, Invariants, Change Budget, and Verification before writing code.
     Delete this file once the format is clear. -->

**Status:** todo, not started
**Last checked:** 0000-00-00

## Goal

Expected outcome and why it matters. One or two sentences.

## Context

Where the task came from, what is known, and relevant constraints.

## Non-goals

What must not change. Be specific — this is what stops scope drift.

- Do not change the public API of `app/src/...`.
- Do not refactor adjacent components.
- Do not touch other repos.

## Invariants

What must still hold when the work is done.

- Existing clients keep working without changes.
- Storage format is unchanged.
- No secrets in logs or in the diff.

## Change Budget

An engineering fuse, not a universal threshold. Its value comes from being fixed before implementation.

- At most 5 production files.
- No new dependencies.
- No new abstraction layers without a test that requires them.

## Verification

The exact commands that produce the pass/fail signal.

```bash
bash app/scripts/verify.sh
```

## Implementation Steps

1. First step.
2. Second step.

## Done When

- [ ] `Verification` commands pass.
- [ ] No confirmed `blocker`/`high` findings from one `/review-task` pass.
- [ ] The diff stays within `Change Budget`.
- [ ] At most one reviewer pass has run.

## Related

- Architecture: `docs/product/architecture/<slug>.md`
- Related tasks: ...
