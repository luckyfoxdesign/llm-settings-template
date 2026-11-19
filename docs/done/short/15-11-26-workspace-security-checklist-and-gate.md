---
type: done_short
status: done
phase: completed
project: workspace
created: 2026-11-19
area:
  - security
  - templates
  - quality-gates
related_docs:
  - docs/product/architecture/verification-contract.md
  - docs/runbook-prod.md
source:
  kind: observation
---

# Reusable Security Checklist And An Executable `check-security.sh`

**Commits:**
- workspace `a9b1e6f` — "feat: add reusable security checklist and optional gate"

## What Changed

- Added a Docker-backed security checker for npm/OSV advisories, runtime support, Dockerfiles, shell scripts, redacted Git history and published compose ports.
- Added a reusable checklist covering all 13 review steps without fixed dependency/runtime versions.
- Linked the optional security check from README, the workspace map and both repository templates; kept executable verification and CI unchanged.

## Verification Evidence

- All three frozen Verification commands passed; workspace gate ran 30 passing regressions and context budgets passed.
- Six-path staged scope guard passed. Unchanged snapshot review reused: `NO_BLOCKING_FINDINGS`.
- The default scanner reported dependency advisories, Node EOL and exposed ports; remediation was outside this task. Strict failure behavior and redacted history were verified with fixtures during implementation.

---
[Full plan](../long/15-11-26-workspace-security-checklist-and-gate.md)
