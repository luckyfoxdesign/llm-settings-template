---
type: done_short
status: done
phase: completed
project: workspace
created: 2026-11-16
area:
  - security
  - quality-gates
related_docs:
  - docs/folder-rules.md
source:
  kind: observation
---

# Remove Quadratic Parsing From The Frontmatter Reader

**Commits:**
- workspace `bd23a38` — "fix: parse frontmatter inline lists in linear time"

## What Changed

- Replaced the quadratic inline-list regex with a quote-aware linear scanner, preserving quoted commas and escapes.
- Enforced a 1 024-character frontmatter line limit with a clear validation error; documented the limit.
- Added performance, quoting, line-boundary and validator integration regressions within the three-file implementation budget.

## Verification Evidence

- `bash scripts/verify.sh`: exit 0, all workspace gates passed; 19 tests passed.
- `python3 -B scripts/test-workflow.py`: exit 0, 19 tests passed.
- 16 000 commas parsed in 0.017677 s (< 0.5 s); over-long lines rejected with `frontmatter line too long`.
- Review: `NO_BLOCKING_FINDINGS`; implementation commit `bd23a38` matches the recorded reviewed file hashes.

---
[Full plan](../long/15-11-26-workspace-frontmatter-redos.md)
