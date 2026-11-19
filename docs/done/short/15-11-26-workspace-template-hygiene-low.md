---
type: done_short
status: done
phase: completed
project: workspace
created: 2026-11-19
area:
  - security
  - templates
  - docs
related_docs:
  - docs/runbook-prod.md
  - AGENTS.md
  - _templates/landing/AGENTS.md
source:
  kind: observation
---

# Template Hygiene: Placeholders, Private Paths, Runbook Defaults, Plugin Origin Check

**Commits:**
- workspace `75215f9` — "fix: clean workspace template identifiers and security defaults"

## What Changed

- Replaced template-specific plugin/token identifiers and historical private paths with neutral placeholders.
- Added plugin message origin validation and external-research data minimisation.
- Required server baseline checks and read-only deploy keys; replaced shell sourcing in backup/restore with Compose `--env-file` and container-side variable expansion.
- Documented HSTS preload implications; preserved headers, fixtures and dependencies.

## Verification Evidence

- Both required verification commands passed; 30 workflow regressions passed.
- Fresh Docker copy: token generation/check/clean fixture/drift fixture exits `0 / 0 / 0 / 1`.
- Docker UI harness verified blocked origins and allowed error/import/export handling.
- `AGENTS.md`: 67 lines / 4397 bytes; 10 approved implementation files.
- Reused matching snapshot review: `NO_BLOCKING_FINDINGS`.
- Preserved functional public GitHub repository references; the contract records the observed exception to the original zero-match assumption.

---
[Full plan](../long/15-11-26-workspace-template-hygiene-low.md)
