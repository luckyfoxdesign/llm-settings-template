---
type: done_short
status: done
phase: completed
project: workspace
created: 2026-11-16
area:
  - workflow
  - quality-gates
related_docs:
  - docs/product/architecture/verification-contract.md
  - docs/folder-rules.md
  - AGENTS.md
---

# Document Migrating Existing Repos To scripts/verify.sh

**Commits:**
- workspace `432ba2d` — "docs: explain verification gate migration for existing repos"

## What Changed

- Documented verification-gate migration for existing repos in README.md: script setup, real Docker gates, AGENTS table, PROJECT_MAP command, and a passing gate before task closure.

## Verification Evidence

- `bash scripts/verify.sh`: passed, including 23 workflow regression tests; no new warnings.
- Scope: README.md only, 12 added lines; staged-path guard passed.
- Reused unchanged snapshot review: `NO_BLOCKING_FINDINGS`; see the full record for the snapshot hash.

---
[Full plan](../long/06-08-26-workspace-document-verify-migration.md)
