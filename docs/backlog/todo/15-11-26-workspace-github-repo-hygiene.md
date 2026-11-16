---
type: task
status: todo
project: workspace
created: 2026-11-15
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

**Status:** todo, not started
**Last checked:** 2026-11-15

## Goal

Give the public template repository the controls a reusable template needs: `main` cannot be force-pushed or deleted, vulnerable dependencies raise alerts automatically, the workspace gate runs on every pull request, and there is a documented way to report a vulnerability.

## Context

Finding from the security review on 2026-11-15 (severity `medium`). Read-only `gh api` queries on 2026-11-15: no branch protection on `main` (404), no rulesets, Dependabot alerts and security updates disabled, no `.github/` directory (no CI, no `dependabot.yml`, no `SECURITY.md`, no `CODEOWNERS`), forking allowed, commits unsigned, 0 deploy keys, one collaborator (owner). Secret scanning and push protection are enabled. Without CI, `scripts/verify.sh` runs only on the author's machine, so a pull request can change `scripts/` or `docs/workflows/task-lifecycle.md` without any automated check.

Assumptions recorded instead of asked:

- Solo-maintainer setup: the ruleset forbids force-push and deletion of `main` and requires the CI status check, but does not require a second reviewer.
- The workflow triggers on `pull_request` and `push` to `main` only, never `pull_request_target`; `permissions: contents: read`; it runs `bash scripts/verify.sh` on `ubuntu-latest` with system Python 3 (no Docker needed for workspace gates).
- Dependabot is scoped to `_templates/landing` (npm) and `.github/workflows` (github-actions), weekly, security updates on. This is the mechanism that replaces remembering version numbers.
- Repository settings are applied through `gh api` and recorded as evidence; they are not stored in the repo.

## Non-goals

- Do not require signed commits (would block the current local flow).
- Do not add Docker-based gates to CI.
- Do not change `scripts/verify.sh` or the task lifecycle.
- Do not disable forking or the wiki.

## Invariants

- `bash scripts/verify.sh` keeps exit 0 on `main`, locally and in CI, with no workflow-only special cases.
- `scripts/validate-docs-frontmatter.py` continues to ignore `.github/` (it scans `docs/` only).
- `.gitignore` is unchanged; `.github/` is tracked.

## Change Budget

- At most 4 workspace files: 3 new, 1 modified.
- No new dependencies.
- No new scripts; no new abstraction layers.

## Task Paths

- `.github/workflows/verify.yml`
- `.github/dependabot.yml`
- `SECURITY.md`
- `README.md`

## Implementation Steps

1. Add `.github/workflows/verify.yml`: checkout, `python3 --version`, `bash scripts/verify.sh`; minimal permissions; concurrency group per ref.
2. Add `.github/dependabot.yml` for `/_templates/landing` (npm, weekly, grouped minor+patch) and `/` (github-actions).
3. Add `SECURITY.md`: supported scope (template and its `_templates/`), private reporting via GitHub security advisories, response expectation.
4. Via `gh api`: create a ruleset on `main` (non-fast-forward and deletion blocked, required status check `verify`), enable Dependabot alerts and security updates; paste the resulting JSON into the task evidence.
5. Add a `README.md` note under "Start Here" telling template adopters to repeat step 4 for their own repositories.

## Verification

```bash
bash scripts/verify.sh
```

## Additional Acceptance Checks

These commands are outside the Verification allowlist. Review them and obtain
explicit user authorization before running them; do not execute them automatically
as part of task completion. They remain required acceptance checks for this task.

```bash
gh api repos/luckyfoxdesign/llm-settings-template/rulesets --jq 'length'
gh api -i repos/luckyfoxdesign/llm-settings-template/vulnerability-alerts
gh run list --workflow verify.yml --limit 1 --json conclusion --jq '.[0].conclusion'
```

## Done When

- [ ] `gh api …/rulesets --jq length` ≥ 1 and the ruleset blocks force-push and deletion of `main`.
- [ ] `gh api -i …/vulnerability-alerts` returns HTTP 204 and `security_and_analysis.dependabot_security_updates.status` is `enabled`.
- [ ] The latest `verify.yml` run on `main` concluded `success`.
- [ ] `SECURITY.md` exists and GitHub shows the security policy on the repository.
- [ ] `Verification` commands pass; the diff stays within `Change Budget`.
- [ ] The final implementation snapshot has recorded review evidence.

## Related

- Review origin: security review 2026-11-15, step 6.
- Depends on nothing; `15-11-26-workspace-landing-template-deps-and-docker.md` relies on the Dependabot alerts added here.
