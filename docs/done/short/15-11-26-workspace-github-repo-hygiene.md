---
type: done_short
status: done
phase: completed
project: workspace
created: 2026-11-16
area:
  - security
  - repository
related_docs:
  - README.md
  - docs/product/architecture/verification-contract.md
source:
  kind: observation
---

# Public Repository Hygiene: Branch Rules, Dependabot, CI Gate, Security Policy

**Commits:**
- workspace `2f8a009` — "feat: add GitHub repository hygiene controls (#4)"

## What Changed

- Added a read-only GitHub Actions `verify` workflow for pull requests and pushes to main, with per-ref concurrency and SHA-pinned checkout.
- Added weekly Dependabot updates for the landing npm template and GitHub Actions; npm minor and patch updates are grouped.
- Added SECURITY.md with supported scope, private advisory reporting, and response targets; documented repository setup for adopters in README.
- Enabled main protection (no force push or deletion, required GitHub Actions `verify`), Dependabot alerts/security updates, and private vulnerability reporting through the GitHub API.

## Verification Evidence

`bash scripts/verify.sh` passed (23 regression tests). Main CI succeeded at `2f8a009`; GitHub settings and policy visibility confirmed. Review: NO_BLOCKING_FINDINGS; unchanged reviewed snapshot reused.

[PR #4](https://github.com/luckyfoxdesign/llm-settings-template/pull/4) · [Main CI](https://github.com/luckyfoxdesign/llm-settings-template/actions/runs/43780164006)

---
[Full plan](../long/15-11-26-workspace-github-repo-hygiene.md)
