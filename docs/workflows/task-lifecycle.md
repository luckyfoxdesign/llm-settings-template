---
type: architecture
status: done
created: 2026-10-05
---

# Task Lifecycle

Canonical task procedures for workspace skills and command adapters. Read only the section needed for the requested action.

<a id="create-task-equivalent"></a>

## `/create-task` Equivalent

When asked to create, draft, or formalize a task:

1. Read `PROJECT_MAP.md`, `CLAUDE.md`, `docs/folder-rules.md`, and `docs/product/architecture/verification-contract.md`.
2. Choose `project: app|landing|nginx|workspace|cross`; list `projects` for `cross`. Read affected repo maps/context if present, then only relevant code/docs. Never read secret-like files.
3. Define outcome, boundaries, invariants, paths, and acceptance behavior. Ask only when missing information materially changes scope; otherwise record assumptions in `Context`.
4. Run `bash scripts/new-task.sh <project> <slug> [cross-project ...]` for dates/name and mandatory frontmatter without overwrite. Add only useful optional metadata.
5. Add todo status/last-checked date and fill every contract section without placeholders. Set a numeric file limit and explicit dependency/abstraction limits, exact verification (`<repo>/scripts/verify.sh` or `scripts/verify.sh`), task-specific acceptance criteria, and applicable stop conditions. Record approved paths in `Task Paths` (workspace-prefixed for code repos).
6. Run `python3 scripts/validate-docs-frontmatter.py --strict` and `python3 scripts/check-task-contract.py --strict`; resolve every warning for the new file. Do not start, implement, or commit it.
7. Reply exactly: `Task created: docs/backlog/todo/<filename>`

<a id="start-task-equivalent"></a>

## `/start-task` Equivalent

When the user asks to start a task:

1. Find a supplied filename/substring in `docs/backlog/todo/` or an existing `docs/wip/` task; if selection is absent or ambiguous, list files alphabetically and ask which to start. Never sort by priority.
2. Reuse an existing WIP file when resuming; otherwise select the backlog file without moving it yet.
3. Read in order: `PROJECT_MAP.md`, `CLAUDE.md`, the selected task, then affected repo maps/context if present.
4. Freeze `Non-goals`, `Invariants`, `Change Budget`, and `Verification`; show a concise plan sized to the task. Request confirmation only if that plan has not already been authorized in this conversation. Freeze `Task Paths` as well. Before implementation, move the selected file to `docs/wip/` without overwriting, set frontmatter and prose status to `wip`, update last-checked date, and report `Task moved: docs/wip/<filename>`.
5. After confirmation, run `bash scripts/task-branch.sh start <repo> <slug>` for `app|landing|nginx`, once per code repo in `projects` for `cross`, and not for `workspace`; `<slug>` is the filename tail after date/project and before `.md`.
6. Implement under repo-local `AGENTS.md`; expand the frozen contract only for a new external fact.
7. When implementation and required checks finish, say: `Done. You can close the task with /complete-task.`

<a id="complete-task-equivalent"></a>

## `/complete-task` Equivalent

When the user asks to complete a task:

1. Identify one active task in `docs/wip/`; if unclear, list tasks and ask. Read it and preserve its filename for both done records.
2. Determine targets: one repo for `app|landing|nginx`, none for `workspace`, or `projects` for `cross`.
3. Run every command in task `Verification`; also run `scripts/verify.sh` for `workspace` or each `<repo>/scripts/verify.sh` if absent. Record concise evidence. Any failed command blocks closure.
4. Reuse a recorded review for the same implementation snapshot; otherwise run [`/review-task`](#review-task-equivalent). Make minimal fixes for evidenced blocking findings, rerun affected checks, and review changed regions when the fixes change behavior. Record the final snapshot and outcome in `Review Evidence`.
5. In each code repo, inspect status/diff/budget (aggregate the file count across all repos for cross tasks), stage only task paths, run `bash scripts/check-staged-paths.sh <repo> --task docs/wip/<filename> --base main`, commit `feat: ...` or `fix: ...`, record its short hash (or a relevant existing commit if unchanged), then run `bash scripts/task-branch.sh finish <repo> <slug>`; it checks staged scope and the merged repo gate before committing, stops on failure, and deletes the branch only after success. Re-run task-specific acceptance commands on the merged result before closure.
6. For workspace implementation changes, stage only task paths excluding WIP/completion records, run `bash scripts/check-staged-paths.sh . --task docs/wip/<filename>`, commit, and record its hash. This separate commit avoids a self-referential hash.
7. Finalize reproducible evidence for every `Done When` item; missing/unverifiable evidence blocks closure. Run `bash scripts/new-done-record.sh docs/wip/<filename> <repo> <hash> "<subject>" [...]`, then check evidenced items and append `— Evidence: <command/path/hash and observed result>` to each. Fill `What Changed`, `Verification Evidence`, and `Review Evidence`; add `Closes #N` only for an issue. Validate the long record with `python3 scripts/check-task-contract.py --complete docs/done/long/<filename>` before deleting WIP.
8. Delete the WIP original; run `python3 scripts/build-done-index.py` and `python3 scripts/build-code-index.py`. Run `bash scripts/verify.sh` again on the finalized records. Stage only completion records, backlog deletion, generated indexes/maps, and related completion docs; run `bash scripts/check-staged-paths.sh . --allow <workspace-task-path> [...]`, then commit `docs: complete <slug>`.
9. Report created/deleted files, verification evidence, review-pass outcome, and all commit hashes.

<a id="review-task-equivalent"></a>

## `/review-task` Equivalent

Review the active `docs/wip/` task against its implementation snapshot, standalone or as completion step 4.

Read `docs/product/architecture/verification-contract.md` → Review policy. Reuse an existing review only when the recorded snapshot is unchanged. Record repository commit IDs and, for uncommitted implementation files, `git diff` content hashes computed from approved non-private paths; a commit ID alone does not identify a dirty tree. Changes to review/completion prose do not invalidate a code review.

Report `NO_BLOCKING_FINDINGS` when no evidenced blocker/high remains, followed by any non-blocking findings and review evidence. Do not change implementation code during standalone review. Recording review evidence and routing findings to backlog/ideas are allowed; never expand current implementation scope with non-blocking findings. Review one unchanged snapshot once; new behavior, new requirements, or a changed merge base permits a focused follow-up.

## Resume After An Interrupted Step

- Keep the filename and completed evidence. Record `phase: awaiting-plan|implementing|verified|reviewed|merged|completed` in task frontmatter when useful.
- Reuse plan authorization for the unchanged contract. Do not ask again solely because a command failed or a session restarted.
- Retry branch start on an existing task branch. Preserve unrelated dirty work; never reset or stash it automatically.
- On merge or gate failure, retain WIP and the task branch. The merge script leaves the pending merge for diagnosis; resolve and verify it, or explicitly abort it, before retrying finish.
- For cross-project tasks, record each repo's branch, commit, and merge outcome. Resume only remaining steps, then verify the final combined state.
- If done scaffolds exist, finish their evidence and validation instead of regenerating or deleting them. Delete WIP only after all records and final checks pass.
