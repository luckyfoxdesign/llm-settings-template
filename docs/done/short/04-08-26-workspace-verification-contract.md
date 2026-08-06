---
type: done_short
status: done
project: workspace
created: 2026-08-06
area:
  - workflow
  - quality-gates
---

# Wire The Verification Contract Into The Workspace Template

**Commits:**
- workspace `a297a02` — "docs: complete workspace-verification-contract"

## What Changed

- `_templates/sub-repo/scripts/verify.sh` — one executable gate per repo: runs lint, test, type check, and build in order, exits non-zero on the first failure. Ships with TODO stubs that fail on purpose until filled in.
- `_templates/sub-repo/AGENTS.md` — `Verification Gates` table and a default repo `Change Budget`; points at the architecture doc instead of restating the protocol.
- `_templates/sub-repo/PROJECT_MAP.md`, `_templates/sub-repo/CLAUDE.md` — `verify.sh` listed under `Commands` and `Code Quality`.
- `.claude/commands/review-task.md` and its mirror in `_templates/sub-repo/` — evidence-only reviewer: one pass, five admissibility criteria, `NO_BLOCKING_FINDINGS` when nothing is evidenced.
- `scripts/check-task-contract.py` — warns when a task file is missing contract sections. Warning-only, exits 0, skips files carrying `TEMPLATE-EXAMPLE` inside an HTML comment.
- `docs/backlog/todo/00-00-00-app-example-task.md` — rewritten to the contract shape; `Definition Of Done` replaced by `Done When`.
- `docs/folder-rules.md` — required contract sections, `verify.sh` in the mandatory repo layout, and severity routing.
- `AGENTS.md` — `Stop Rule`, contract freeze in `/start-task` step 6, `verify.sh` plus budget check in `/complete-task` step 5, new script listed. Ended at 128/180 lines and 6904/7168 bytes.
- `CLAUDE.md` — `Verification contract` row added; four lines reclaimed by inlining the SSH code fence, ending at 57/60 lines.
- `docs/product/architecture/verification-contract.md` — `status: draft` to `done`.

Budget held exactly: 4 new files, 7 modified. One review pass, `NO_BLOCKING_FINDINGS`; one `medium` finding routed to `docs/backlog/todo/06-08-26-workspace-document-verify-migration.md`.

---
[Full plan](../long/04-08-26-workspace-verification-contract.md)
