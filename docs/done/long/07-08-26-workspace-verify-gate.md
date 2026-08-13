---
type: done_long
status: done
project: workspace
created: 2026-08-07
area:
  - workflow
  - quality-gates
related_docs:
  - docs/product/architecture/verification-contract.md
  - docs/folder-rules.md
  - AGENTS.md
---

**Commits:**
- workspace `7d4139b` — "feat: add strict workspace verification gate"

# Give The Workspace Its Own Executable Gate

**Status:** done
**Last checked:** 2026-08-13

## Goal

Make `project: workspace` tasks stop on an exit code instead of on someone
reading script output. Make `/complete-task` refuse closure until every command
in `Verification` passes and every `Done When` item has recorded evidence, then
stage every task-related workspace change without staging unrelated work.

## Context

`docs/product/architecture/verification-contract.md` states that workspace tasks use the workspace scripts as their gate. Those scripts cannot fail:

| Command | Can it fail? |
|---|---|
| `scripts/check-context-budget.sh` | no — `always exits 0` |
| `scripts/validate-docs-frontmatter.py` | no — `return 0` |
| `scripts/check-task-contract.py` | no — warning-only by contract |
| `scripts/check-no-flow-duplication.sh` | yes — `exit 1` |

So code repos got a real gate in `<repo>/scripts/verify.sh` while the workspace kept prose. This is the failure the architecture doc names directly: described in text, a gate can be reinterpreted; as an exit code, it cannot.

Evidence from `docs/done/long/04-08-26-workspace-verification-contract.md`: `check-task-contract.py` shipped with a defect that silently skipped every task file mentioning `TEMPLATE-EXAMPLE` in prose. All five verification commands returned success. A human noticed the file count looked wrong.

Second, smaller gap found by running the flow: `AGENTS.md` step 10 stages `docs/done/`, `docs/backlog/`, and `PROJECT_MAP.md`. For a workspace task the real changes sit in `AGENTS.md`, `CLAUDE.md`, `scripts/`, `_templates/`, and `.claude/`. Followed literally, the commit records the write-up but not the work.

Both gaps are the workspace failing the contract it prescribes to others, so they belong in one task.

After commit `d8b1e1e`, `AGENTS.md` is 94 lines / 7041 bytes, leaving only 127
bytes under the 7168-byte limit. Compacting existing wording without changing
its meaning is therefore required to add the completion rules.

The gate design is frozen: the three warning-only checks gain an opt-in
`--strict` mode, while their default invocation remains warning-only.
`scripts/verify.sh` invokes strict modes and the already-failing flow lint.
This avoids parsing human-readable output, whose wording is not an API.

Confirmed architectural constraint found during implementation: a Git commit
cannot contain its own final hash because changing the recorded hash changes
the commit hash again. Therefore a workspace task uses two commits when it has
uncommitted implementation changes: first the task-related workspace changes,
then completion records that reference the first commit. This replaces the
impossible placeholder-and-fill-later instruction.

## Non-goals

- Do not make the existing workspace scripts exit non-zero by default — they stay warning-only and safe to run anytime.
- Do not add `verify.sh` to code repos; they do not exist in this workspace.
- Do not add a new lifecycle stage. Compact existing `AGENTS.md` wording only
  as needed to add the verification/evidence and staging requirements.
- Do not restate the protocol; `AGENTS.md` keeps a pointer to the architecture doc.
- Do not add a second reviewer, backtracking, or any new flow stage.

## Invariants

- Running any existing workspace script directly still exits 0.
- `AGENTS.md` remains the single source of the task-flow algorithm; `scripts/check-no-flow-duplication.sh` still passes.
- `AGENTS.md` stays within 180 lines / 7168 bytes. Its current baseline is 94
  lines / 7041 bytes, so the byte limit is the binding constraint.
- `CLAUDE.md` stays within 60 lines / 3072 bytes; it is at 57 lines.
- Existing files in `docs/done/` are not retrofitted.
- No secrets, env values, or server hostnames enter any touched file.

## Change Budget

- At most 7 workspace files: 1 new, 6 modified.
- New: `scripts/verify.sh` only.
- Modified: `AGENTS.md`, `docs/folder-rules.md`,
  `docs/product/architecture/verification-contract.md`,
  `scripts/check-context-budget.sh`,
  `scripts/validate-docs-frontmatter.py`, and
  `scripts/check-task-contract.py`.
- No new dependencies; bash and the existing scripts only.
- `scripts/verify.sh` stays a single flat file with no helper modules.
- No new directories.

## Verification

```bash
bash scripts/verify.sh
bash scripts/check-context-budget.sh
bash scripts/check-no-flow-duplication.sh
python3 scripts/validate-docs-frontmatter.py
python3 scripts/check-task-contract.py
git diff --check
```

The first command must exit 0 on a clean tree. The rest must still exit 0 when run directly, proving the wrapper did not change them.

Passing is not sufficient here: this task is about a gate that can fail, so the negative tests in `Done When` are the real evidence.

## Implementation Steps

1. Add opt-in `--strict` handling to the three warning-only scripts. Preserve
   their current output and zero exit code when invoked without the flag.
2. Add flat `scripts/verify.sh`: `set -euo pipefail`, invoke each strict check
   and flow lint in a fixed order, name the current check, and stop on its
   non-zero exit code.
3. Extend `/complete-task` so it runs every command in the active task's
   `Verification`, runs the repo or workspace gate, and records a concise
   pass/fail evidence entry for every `Done When` item. Missing, failed, or
   unverifiable evidence blocks done files and commits.
4. Replace the fixed workspace staging list with two explicit stages: commit
   all and only task-related implementation paths and record its hash; then
   stage completion records, the backlog deletion, and generated indexes in a
   separate `docs: complete` commit. Never stage the whole dirty tree or
   secret-like files.
5. Document the strict workspace gate and DoD evidence rule in
   `docs/folder-rules.md` and the architecture contract without duplicating
   the step-by-step lifecycle algorithm.
6. Compact `AGENTS.md` without dropping create/start/complete, security,
   stop-rule, or exact-result semantics; add `scripts/verify.sh` to its helper
   list.
7. Demonstrate all positive and negative cases below in an isolated temporary
   copy, then run the real-tree verification commands and record the evidence.

## Done When

- [x] `bash scripts/verify.sh` exits 0 on a clean tree.
- [x] It exits non-zero, naming the failed check, for each of: hot-context budget breach, flow duplication outside `AGENTS.md`, a task file missing contract sections, a docs file with invalid frontmatter. Each demonstrated and the output recorded.
- [x] Each existing workspace script still exits 0 when run directly.
- [x] Each of the three warning-only scripts exits non-zero under `--strict`
      for its own violation, while `scripts/verify.sh` stops and names that
      check.
- [x] `AGENTS.md` is within 180 lines / 7168 bytes.
- [x] `/complete-task` explicitly executes task `Verification`, the applicable
      gate, and records evidence for every `Done When` item before closure.
- [x] A `project: workspace` task records a non-circular implementation hash:
      task-related workspace paths (including changes outside `docs/`) are
      committed first, then completion records are committed separately.
- [x] The diff stays within `Change Budget`.
- [x] At most one reviewer pass has run.

## Verification Evidence

- Real tree: `bash scripts/verify.sh` returned 0 and ended with
  `OK: all workspace gates passed`.
- Isolated negative copies under
  `/private/tmp/llm-settings-template-gates.SWJG9O/` each returned 1 and named
  the correct gate: `context-budget`, `flow-duplication`,
  `docs-frontmatter`, and `task-contract`.
- On their respective invalid fixtures, direct context/frontmatter/contract
  commands returned 0; the same commands with `--strict` returned 1.
- `AGENTS.md` is 80 lines / 6823 bytes. Its completion algorithm at lines
  55–59 requires exact Verification commands, applicable gates, evidence for
  every DoD item, a separate workspace implementation commit, and scoped
  completion staging.
- Implementation scope is exactly one new file and six modified files. The
  tracked backlog deletion is the expected lifecycle move to gitignored WIP.
- Implementation commit: workspace `7d4139b` contains exactly those seven
  implementation files; completion records are intentionally separate.
- `git diff --check`, shell syntax, Python compile checks, direct validators,
  strict validators, and the root gate pass.
- One contract-only review ran and returned `NO_BLOCKING_FINDINGS`; no further
  review iteration ran.

## Related

- Architecture: `docs/product/architecture/verification-contract.md`
- Origin: `docs/done/long/04-08-26-workspace-verification-contract.md`
- Docs rules: `docs/folder-rules.md`
- Flow: `AGENTS.md`

[Short summary](../short/07-08-26-workspace-verify-gate.md)
