---
type: done_short
status: done
phase: completed
project: workspace
created: 2026-11-19
area:
  - security
  - quality-gates
related_docs:
  - docs/folder-rules.md
  - AGENTS.md
source:
  kind: observation
---

# Widen Leak Detection Before Commit: Filename Corpus And Optional Content Scan

**Commits:**
- workspace `cb0e2bb` — "fix: widen staged leak detection and add optional content scan"

## What Changed

- Expand private filename detection with the 25-name credential corpus, key-store suffixes, service-account files, SSH key stems and token filename forms, preserving documented safe counterexamples.
- Add opt-in `--content-scan`: gitleaks runs in Docker with read-only repository access, disabled networking, redaction and suppressed diagnostics. Findings and scan errors fail; unavailable Docker produces an explicit skip.
- Document optional scanning and GitHub non-provider pattern configuration; keep normal gates independent of Docker.

## Verification Evidence

- `bash scripts/verify.sh`: exit 0, all strict workspace gates and 30 workflow tests passed.
- `python3 -B scripts/test-workflow.py`: exit 0, 30 tests passed.
- `bash scripts/check-staged-paths.sh . --secrets-only --content-scan`: exit 0 with all six implementation files staged; real gitleaks scan completed without a skip.
- Task-scoped staged guard and diff checks passed; exactly six approved existing files changed.
- Real Docker synthetic acceptance: clean staging passed; an unstaged synthetic token was ignored; staging it caused rejection without exposing its value.
- Unchanged reviewed implementation committed as `cb0e2bb`; `NO_BLOCKING_FINDINGS` reused by matching the recorded diff SHA-256.

---
[Full plan](../long/15-11-26-workspace-leak-detection-coverage.md)
