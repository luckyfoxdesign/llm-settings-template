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
  - docs/workflows/task-lifecycle.md
  - docs/product/architecture/verification-contract.md
  - docs/folder-rules.md
source:
  kind: observation
---

# Gate Commands That Reach The Host From Markdown And Task Branches

**Commits:**
- workspace `4f22a96` — "fix: restrict task verification commands and guard script changes"

## What Changed

- Enforce a fenced command allowlist in strict and completion validation, including rejection of shell syntax and HTML-comment concealment.
- Stop task-branch finish before running branch-modified scripts unless explicitly authorized with --allow-scripts-change.
- Run template gates through Bash arrays, preserving Bash 3 compatibility, gate order, required failures and optional skips.
- Document command display and validation requirements; retain out-of-allowlist checks in three existing tasks as separately authorized acceptance checks.
- Add regressions covering command rejection, completion validation, script-change authorization and template gate behavior.

## Verification Evidence

All three Verification commands passed; 23 regressions passed; strict task contracts: 9 checked, 0 invalid. Review reused for the identical implementation snapshot: NO_BLOCKING_FINDINGS. Finalized records are checked by scripts/verify.sh.

---
[Full plan](../long/15-11-26-workspace-gate-markdown-commands.md)
