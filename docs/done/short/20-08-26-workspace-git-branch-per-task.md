---
type: done_short
status: done
project: workspace
created: 2026-08-26
area:
  - task-flow
  - git-workflow
  - automation
related_docs:
  - AGENTS.md
  - docs/folder-rules.md
  - docs/product/architecture/verification-contract.md
source:
  kind: discussion
---

# Git Branch Per Task

**Commits:**
- workspace `937fa17` — "feat: automate task lifecycle mechanics"

## What Changed

- Added an overwrite-safe task scaffold for deterministic dates, filenames, and mandatory frontmatter.
- Added per-task code-repo branches that refresh `main`, merge locally, stop on conflicts, and never create workspace task branches.
- Added a filename-only staged-path guard for `.env*`, private-key-shaped paths, and merge commits.
- Added atomic linked long/short done-record scaffolding with validated commit blocks.
- Wired all four scripts into the canonical create/start/complete workflow while preserving human confirmation, evidence, and review gates.

## Verification Evidence

- `bash scripts/verify.sh` passed every strict workspace gate.
- All four scripts passed disposable-fixture smoke tests; overwrite and secret-path negative cases failed closed as intended.
- `AGENTS.md` finished at 80 lines / 7107 bytes, and the implementation commit contains exactly the five budgeted files.
- One contract-only review returned `NO_BLOCKING_FINDINGS`.

---
[Full plan](../long/20-08-26-workspace-git-branch-per-task.md)
