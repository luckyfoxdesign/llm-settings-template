---
type: done_long
status: done
project: workspace
created: 2026-08-20
area:
  - task-flow
  - git-workflow
  - automation
related_docs:
  - AGENTS.md
  - docs/folder-rules.md
  - docs/product/architecture/verification-contract.md
source:
  kind: discussion
---

**Commits:**
- workspace `937fa17` — "feat: automate task lifecycle mechanics"

# Git Branch Per Task

**Status:** done
**Last checked:** 2026-08-26

## Goal

Extend the `/start-task` and `/complete-task` equivalents in `AGENTS.md` with a per-task git branch in the target repo (created at start, merged locally into `main` at completion), and, across the whole `/create-task` → `/start-task` → `/complete-task` flow, replace every mechanical step that is currently a free-form LLM judgment call with a deterministic script — wherever a script can fully reproduce today's outcome without reducing correctness or flexibility.

## Context

- Today `/start-task` moves the task file to `docs/wip/` and starts implementation without creating a branch; `/complete-task` commits directly on whichever branch is currently checked out in the target repo (`AGENTS.md` start-task/complete-task equivalents).
- User decisions from clarification on 2026-08-20 (first round): branch-per-task applies only to code repos `app`, `landing`, `nginx` (not the workspace repo itself); a task branch closes via a local `git merge` into the repo's `main`, never a push or PR.
- User decisions from clarification on 2026-08-20 (second round, this amendment):
  - Automation scope is the whole task-flow, not just branching — but only "where possible, without making things worse" (`по возможности заменить, но не ухудшить`). A step is in scope only if a script can reproduce it exactly; steps that inherently need product/semantic judgment stay with the agent.
  - Depth: design **and implement** the scripts in this task, not just document where automation could go.
- `scripts/check-no-flow-duplication.sh` enforces that the create/start/complete task-flow algorithm lives only in workspace `AGENTS.md`; new steps must reference scripts from there, not duplicate the algorithm into `app/AGENTS.md`, `landing/AGENTS.md`, or `nginx/AGENTS.md`.
- `AGENTS.md` is already over its Hot Context Budget: `bash scripts/check-context-budget.sh --strict` currently reports `AGENTS.md` at 7.5 KB against a 7.0 KB budget (line count 81/180 is fine). Replacing multi-line prose instructions with single script-invocation lines should net reduce size, but the task must still land at or under budget, trimming further if needed.
- Per `docs/product/architecture/verification-contract.md`, the review pass, the plan-confirmation gate, and the authored content of `Goal`/`Context`/`Non-goals`/`Invariants` are the parts of this workflow that are deliberately kept as model judgment (evidence-based reasoning, human-in-the-loop approval, product meaning) — automating those away would be a regression, not an improvement, so they are excluded by design, not by oversight.
- Reviewed each step of the three algorithms in `AGENTS.md` to classify mechanical (scriptable) vs. semantic (must stay LLM) work; the scriptable set selected for this task, chosen for being fully deterministic and low-risk:
  - create-task: computing today's date, the `dd-mm-yy-<project>-<slug>.md` filename, and the mandatory frontmatter keys, and refusing to overwrite an existing file.
  - start-task / complete-task (new): deriving the branch name from the task slug, creating/checking out the branch from up-to-date `main`, and — at completion — merging it locally into `main` and deleting it, stopping non-zero on a conflict instead of guessing a resolution.
  - complete-task: guarding `git add`/staged paths against `.env*` (except `.env.example`) and private-key-shaped filenames before commit, in any repo (including the workspace commit step) — a deterministic backstop for the existing "Local Permissions" rule, not a replacement for choosing which task-related files to stage.
  - complete-task: scaffolding `docs/done/long/<filename>` and `docs/done/short/<filename>` with correct frontmatter, the commit block, and the cross-links between them, leaving the `## What Changed` bullets and evidence prose for the agent to fill in.

## Non-goals

- No git hooks (pre-commit, pre-push, etc.) — scripts are invoked explicitly by the agent from the documented `AGENTS.md` steps, never triggered automatically.
- No push, remote tracking branch, or `gh pr create` / GitHub PR flow for task branches.
- No change to the workspace repo's own branch workflow: workspace-only and `docs/`-only work keeps committing straight to `main`.
- No automation of the review pass, the plan-confirmation gate, or the authored prose content of any task-contract section — these stay explicit LLM/user judgment per `verification-contract.md`.
- No change to `docs/folder-rules.md` task-contract sections, `docs/product/architecture/verification-contract.md`, or the task frontmatter schema itself (scripts conform to the existing schema, they do not redefine it).
- No change to `app/AGENTS.md`, `landing/AGENTS.md`, `nginx/AGENTS.md`, or other repo-local docs — the algorithm stays solely in workspace `AGENTS.md`.
- No new third-party dependencies; new scripts are bash (`set -euo pipefail`, matching `scripts/verify.sh`) or Python 3.9+ stdlib (matching `scripts/validate-docs-frontmatter.py`), run on the host, not in Docker.
- No automation of picking which task to start when several exist, or of resolving a merge conflict — both remain explicit stop-and-ask points for the agent/user.

## Invariants

- `bash scripts/check-no-flow-duplication.sh` continues to pass — no step-by-step task-flow algorithm text appears outside `AGENTS.md`.
- `bash scripts/check-context-budget.sh --strict` passes for `AGENTS.md` (<=180 lines, <=7.0 KB) after the edit.
- Existing start-task/complete-task steps that stay manual (task file move ask, contract freeze, plan confirmation, implementation, verification run, review pass, done-record prose, `Done Commit Block` format) are preserved for every project type; scripts only replace steps that were already mechanical.
- The branch name is deterministic and derived from the task filename/slug (e.g. `task/<slug>`), so the same task always maps to the same branch name.
- No new script ever force-pushes, runs `git reset --hard`, or auto-resolves a merge conflict; every script exits non-zero and leaves the working tree in a diagnosable state on any ambiguity, consistent with `CLAUDE.md` / `AGENTS.md` "Local Permissions".
- No new script reads, prints, or logs the contents of a secret-shaped file; the staged-path guard checks filenames/patterns only, per the global secrets policy.
- For `project: cross`, the branch script runs independently per repo listed in `projects`.
- Every new script is idempotent to re-run after a failure (e.g. re-running the branch-start script on an already-created branch does not corrupt state) and prints which repo/task it acted on.

## Change Budget

- At most 5 production files:
  1. `AGENTS.md` (wire the steps below to the new scripts).
  2. `scripts/new-task.sh` — scaffolds a `docs/backlog/todo/` file: computes the date/filename, writes the mandatory frontmatter keys, refuses to overwrite.
  3. `scripts/task-branch.sh` — `start <repo> <slug>` and `finish <repo> <slug>` subcommands for the per-task branch.
  4. `scripts/check-staged-paths.sh` — fails if staged paths in a given repo include `.env*` (except `.env.example`) or private-key-shaped filenames.
  5. `scripts/new-done-record.sh` — scaffolds `docs/done/long/<filename>` and `docs/done/short/<filename>` with frontmatter, commit block, and cross-links.
- No new files beyond this list, no new dependencies, no git hooks.

## Verification

```bash
bash scripts/verify.sh
```

Plus a smoke test per new script against a disposable fixture (a `mktemp -d`, `git init`d scratch repo for `task-branch.sh` and `check-staged-paths.sh`; a scratch `docs/` copy or `--dry-run`-style temp target for `new-task.sh` and `new-done-record.sh`) — never run destructive smoke tests against the real `app`, `landing`, or `nginx` working trees.

## Implementation Steps

1. Re-read the three algorithms in `AGENTS.md` end to end and confirm the mechanical/semantic split in `Context` still holds before writing code.
2. Implement `scripts/new-task.sh`, `scripts/task-branch.sh`, `scripts/check-staged-paths.sh`, `scripts/new-done-record.sh`; each prints what it did/would do and exits non-zero on any precondition failure (dirty tree, existing file, conflict, secret-shaped path).
3. Update `AGENTS.md`'s create-task equivalent to call `scripts/new-task.sh` for file/frontmatter scaffolding, keeping content authoring (Goal/Context/.../Verification/Done When) as agent work.
4. Update `AGENTS.md`'s start-task equivalent to call `scripts/task-branch.sh start` for `project: app|landing|nginx` (and per repo in `projects` for `cross`) before implementation begins.
5. Update `AGENTS.md`'s complete-task equivalent to call `scripts/check-staged-paths.sh` before every commit (repo and workspace), `scripts/task-branch.sh finish` after verification passes, and `scripts/new-done-record.sh` to scaffold the two done records before filling their prose.
6. Trim redundant or now-superseded prose in `AGENTS.md` so it lands at or under the context budget.
7. Smoke-test each script against a disposable fixture; run `bash scripts/check-context-budget.sh` and `bash scripts/verify.sh`; iterate until green.

## Done When

- [x] `AGENTS.md`'s create-task equivalent documents and uses `scripts/new-task.sh` for file/frontmatter scaffolding.
- [x] `AGENTS.md`'s start-task equivalent documents creating/checking out a per-task branch via `scripts/task-branch.sh start` for the target repo(s).
- [x] `AGENTS.md`'s complete-task equivalent documents the staged-path guard, `scripts/task-branch.sh finish`, and `scripts/new-done-record.sh` at their respective steps.
- [x] Each of the four new scripts has a passing smoke-test run against a disposable fixture, with evidence (command + output) recorded.
- [x] `bash scripts/verify.sh` exits 0, including the `context-budget` and `flow-duplication` gates.
- [x] `AGENTS.md` is at or under 180 lines and 7.0 KB per `bash scripts/check-context-budget.sh` output.
- [x] The diff stays within `Change Budget` (at most the 5 listed files).
- [x] At most one reviewer pass has run, with no confirmed `blocker`/`high` findings.

## Related

- `AGENTS.md`
- `docs/folder-rules.md`
- `docs/product/architecture/verification-contract.md`
- `scripts/check-no-flow-duplication.sh`
- `scripts/check-context-budget.sh`
- `scripts/validate-docs-frontmatter.py`, `scripts/check-task-contract.py` (existing scripted gates this task follows the style of)

## Verification Evidence

- `AGENTS.md` create-task step 4 calls `scripts/new-task.sh`; start-task step 5 calls `scripts/task-branch.sh start`; complete-task steps 5–8 call the staged-path guard, branch finish, and done-record generator.
- `bash scripts/verify.sh` exited 0 and ended with `OK: all workspace gates passed`; its output included passing `context-budget` and `flow-duplication` gates.
- Completion smoke fixture `/private/tmp/task-flow-complete-smoke.LMbgkF/` exercised all four scripts. Both generators created their expected files and refused overwrite, the guard accepted two safe paths and rejected `.env.smoke`, and task-branch start was idempotent before finish merged locally and deleted the branch.
- Additional disposable fixtures proved remote refresh and conflict behavior: `task/remote-current` started at refreshed `origin/main`; the conflict case exited non-zero while retaining `MERGE_HEAD` and the task branch for diagnosis.
- `bash scripts/check-context-budget.sh --strict` passed with `AGENTS.md` at 80 lines / 7107 bytes, below both frozen limits.
- The staged implementation diff contained exactly the five allowed production paths. Workspace commit `937fa17` records 489 insertions and 17 deletions across those files, with no new dependency or hook.
- Exactly one contract-only evidence review ran after verification and returned `NO_BLOCKING_FINDINGS`; no second review ran.

[Short summary](../short/20-08-26-workspace-git-branch-per-task.md)
