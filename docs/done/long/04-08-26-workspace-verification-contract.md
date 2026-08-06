---
type: done_long
status: done
project: workspace
created: 2026-08-04
area:
  - workflow
  - quality-gates
related_docs:
  - docs/product/architecture/verification-contract.md
  - docs/folder-rules.md
---

**Commits:**
- workspace `PENDING` — "docs: complete workspace-verification-contract"

# Wire The Verification Contract Into The Workspace Template

**Status:** done
**Last checked:** 2026-08-06

## Goal

Make the decision in `docs/product/architecture/verification-contract.md` operational: every task carries a frozen contract, every repo exposes one executable gate, and a task stops on external evidence rather than on model judgement.

## Context

The decision is recorded but nothing enforces it. Three layers need wiring, each in exactly one place:

- **Protocol** — workspace `AGENTS.md`, pointing at the architecture doc for detail.
- **Gates** — `_templates/sub-repo/`, so every new repo ships `scripts/verify.sh`.
- **Contract** — the task template and `docs/folder-rules.md`.

Hot-context budgets are the binding constraint. Current sizes: `AGENTS.md` 120/180 lines and 6223/7168 bytes (~945 bytes headroom), `CLAUDE.md` 60/60 lines. Protocol detail therefore stays in the architecture doc; `AGENTS.md` gets a pointer and the stop rule only.

This task is also the first example of the contract format below.

## Non-goals

- Do not restate the protocol in `app/`, `landing/`, or `nginx/` — repo files carry gates only, never the protocol.
- Do not touch code repos; this task changes workspace files and `_templates/` only.
- Do not add frontmatter fields for change budget or verification — body sections are the contract.
- Do not implement backtracking, tree search, or multi-reviewer flows.
- Do not rewrite the existing task-flow algorithm; extend it at two points only.

## Invariants

- `AGENTS.md` remains the single source of the task-flow algorithm; `scripts/check-no-flow-duplication.sh` still passes.
- Existing workspace scripts stay warning-only and exit 0.
- `AGENTS.md` stays within 180 lines / 7168 bytes; `CLAUDE.md` within 60 lines / 3072 bytes.
- Existing tasks in `docs/done/` are not retrofitted.
- No secrets, env values, or server hostnames enter any touched file.

## Change Budget

- At most 11 workspace files: 4 new, 7 modified.
- No new dependencies; `check-task-contract.py` uses system Python 3.9+ and stdlib only.
- No new directories beyond what `_templates/sub-repo/` already implies.
- No new abstraction layers in scripts — each script stays a single flat file.

## Verification

```bash
bash scripts/check-context-budget.sh
bash scripts/check-no-flow-duplication.sh
python3 scripts/validate-docs-frontmatter.py
python3 scripts/check-task-contract.py
bash -n _templates/sub-repo/scripts/verify.sh
```

## Implementation Steps

1. Add `_templates/sub-repo/scripts/verify.sh`: runs the repo gates in order (`lint`, `test`, then type check and build when present), `set -euo pipefail`, exits non-zero on the first failure, echoes which gate failed. Ships with TODO stubs a new repo fills in.
2. Add `## Verification Gates` and `## Change Budget` to `_templates/sub-repo/AGENTS.md`: a table of the repo's concrete pass/fail commands plus its default budget. Point to the architecture doc for the protocol; do not repeat it.
3. List `scripts/verify.sh` in `_templates/sub-repo/PROJECT_MAP.md` under `## Commands` (generated block) and in `_templates/sub-repo/CLAUDE.md` under `## Code Quality`.
4. Rewrite `docs/backlog/todo/00-00-00-app-example-task.md` to the contract shape: `Goal`, `Context`, `Non-goals`, `Invariants`, `Change Budget`, `Verification`, `Implementation Steps`, `Done When`, `Related`. Replace `Definition Of Done` with `Done When`.
5. Update `docs/folder-rules.md`: list the required contract sections, add `scripts/verify.sh` to the mandatory repo layout, and record severity routing — `medium` findings to `docs/backlog/todo/`, `speculative` to `docs/ideas/`.
6. Update workspace `AGENTS.md`, staying inside the byte budget:
   - a `## Stop Rule` section with the five conditions and a link to the architecture doc;
   - `/start-task` step 6: freeze the contract — fill `Non-goals`, `Invariants`, `Change Budget`, `Verification` and confirm with the user before writing code;
   - `/complete-task` step 5: run `<repo>/scripts/verify.sh` instead of lint alone, show its output as evidence, and check the diff against `Change Budget`;
   - add `scripts/check-task-contract.py` to the scripts list.
7. Add `.claude/commands/review-task.md` and mirror it at `_templates/sub-repo/.claude/commands/review-task.md`: evidence-only reviewer, one pass, admissibility rules, `NO_BLOCKING_FINDINGS` when no evidenced blocker/high. Both files point at the architecture doc rather than restating the rubric.
8. Add `scripts/check-task-contract.py`: warns when a file in `docs/wip/` or `docs/backlog/todo/` is missing contract sections. Warning-only, always exits 0, skips files marked `TEMPLATE-EXAMPLE`.
9. Add a `Verification contract` row to the `CLAUDE.md` source-of-truth table **only if** a line can be reclaimed elsewhere; `CLAUDE.md` is at its 60-line limit. Otherwise skip and note it here.
10. Run the verification commands above and record the output.

## Verification Output

Run 2026-08-06 from the workspace root.

```text
bash scripts/check-context-budget.sh              exit=0
bash scripts/check-no-flow-duplication.sh         exit=0   OK: no flow duplication outside AGENTS.md
python3 scripts/validate-docs-frontmatter.py      exit=0   OK — all docs files have valid frontmatter
python3 scripts/check-task-contract.py            exit=0   OK — 1 task file(s) carry a full contract
bash -n _templates/sub-repo/scripts/verify.sh     exit=0

CLAUDE.md        lines:  57/60    size: 2.2 KB/3.0 KB   OK
AGENTS.md        lines: 128/180   size: 6.7 KB/7.0 KB   OK
PROJECT_MAP.md   lines:  82/200   size: 2.3 KB/7.0 KB   OK
```

`verify.sh` behaviour, tested beyond `bash -n`:

```text
unconfigured stubs   -> FAIL: gate 'lint' is not configured   exit=1
lint + test filled   -> both ran, typecheck/build SKIP        exit=0
test returns false   -> stopped at test, build never ran      exit=1
fresh copy of _templates/sub-repo -> FAIL on lint             exit=1
```

Final file count: 4 new, 7 modified.

## Notes

Two contract items collided: `Change Budget` allows 7 modified files and `Done When` requires a status flip in `verification-contract.md`, which would be the eighth. Resolved by counting the status flip as completion bookkeeping, like moving the task file to `docs/done/`, rather than as a production change. Budget held at 4 new / 7 modified as written. Decision confirmed with the user before the last two files were touched.

Step 9 was executed rather than skipped: four lines were reclaimed in `CLAUDE.md` by inlining the SSH code fence, which left room for the `Verification contract` row at 57/60 lines.

`check-task-contract.py` initially skipped every file that merely mentioned `TEMPLATE-EXAMPLE` in prose — including this task file, which describes the marker in step 8. The marker now counts only inside an HTML comment.

## Done When

- [x] All five verification commands pass with no new warnings.
- [x] `docs/product/architecture/verification-contract.md` moves to `status: done`.
- [x] A new repo created from `_templates/sub-repo/` has a runnable `scripts/verify.sh` with explicit TODOs.
- [x] No confirmed blocker/high findings from one `/review-task` pass.
- [x] The diff stays within the change budget above.
- [x] At most one reviewer pass has run.

Review pass 2026-08-06: `NO_BLOCKING_FINDINGS`. One `medium` finding routed to
`docs/backlog/todo/06-08-26-workspace-document-verify-migration.md` — `AGENTS.md`
now names `<repo>/scripts/verify.sh` unconditionally, but existing `app/`,
`landing/`, and `nginx/` have not been migrated, since `Non-goals` forbids
touching code repos.

## Related

- Architecture: `docs/product/architecture/verification-contract.md`
- Docs rules: `docs/folder-rules.md`
- Flow: `AGENTS.md`
- Follow-up: `docs/backlog/todo/06-08-26-workspace-document-verify-migration.md`

[Short summary](../short/04-08-26-workspace-verification-contract.md)
