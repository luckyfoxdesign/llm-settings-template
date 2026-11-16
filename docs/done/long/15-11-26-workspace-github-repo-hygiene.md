---
type: done_long
status: done
phase: completed
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
completion_validation: required
---

**Commits:**
- workspace `2f8a009` — "feat: add GitHub repository hygiene controls (#4)"


# Public Repository Hygiene: Branch Rules, Dependabot, CI Gate, Security Policy

**Status:** done
**Last checked:** 2026-11-16

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

- [x] `gh api …/rulesets --jq length` ≥ 1 and the ruleset blocks force-push and deletion of `main`. — Evidence: API returned 1; GET rules/branches/main confirms deletion, non_fast_forward, and required verify (GitHub Actions app 15368); active ruleset 27340997, refs/heads/main, no bypass actors.
- [x] `gh api -i …/vulnerability-alerts` returns HTTP 204 and `security_and_analysis.dependabot_security_updates.status` is `enabled`. — Evidence: 2026-11-16 GET vulnerability-alerts returned HTTP 204; GET repo security_and_analysis.dependabot_security_updates returned enabled.
- [x] The latest `verify.yml` run on `main` concluded `success`. — Evidence: https://github.com/luckyfoxdesign/llm-settings-template/actions/runs/43780164006 completed successfully on published main commit `2f8a009750e4a87efedb50f67c37b61ae2e15ac3`; exact latest-run acceptance command returned success.
- [x] `SECURITY.md` exists and GitHub shows the security policy on the repository. — Evidence: https://github.com/luckyfoxdesign/llm-settings-template/security/policy displays Supported scope, Reporting a vulnerability, the private advisory link, and response targets after merge.
- [x] `Verification` commands pass; the diff stays within `Change Budget`. — Evidence: bash scripts/verify.sh exit 0, 23 regression tests passed; 3 added and 1 modified approved implementation files; no dependencies/scripts/abstractions added; git diff --check exit 0. Lifecycle move excluded from implementation budget.
- [x] The final implementation snapshot has recorded review evidence. — Evidence: Review Evidence below identifies the four-file snapshot and NO_BLOCKING_FINDINGS for implementation.

## Related

- Review origin: security review 2026-11-15, step 6.
- Depends on nothing; `15-11-26-workspace-landing-template-deps-and-docker.md` relies on the Dependabot alerts added here.

## Implementation Evidence

2026-11-16: Initial API reads found no rulesets, disabled vulnerability alerts and security updates, and disabled private vulnerability reporting. The latter must be enabled for the private reporting link in SECURITY.md to work; no implementation paths or budget change.

### Created active main ruleset

```json
{
  "id": 27340997,
  "name": "Protect main",
  "target": "branch",
  "source_type": "Repository",
  "source": "luckyfoxdesign/llm-settings-template",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "exclude": [],
      "include": [
        "refs/heads/main"
      ]
    }
  },
  "rules": [
    {
      "type": "deletion"
    },
    {
      "type": "non_fast_forward"
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": true,
        "do_not_enforce_on_create": false,
        "required_status_checks": [
          {
            "context": "verify",
            "integration_id": 15368
          }
        ]
      }
    }
  ],
  "node_id": "RRS_lACqUmVwb3NpdG9yec5JfNrmzgGhMMU",
  "created_at": "2026-11-16T01:19:39.554+01:00",
  "updated_at": "2026-11-16T01:19:39.735+01:00",
  "bypass_actors": [],
  "current_user_can_bypass": "never",
  "_links": {
    "self": {
      "href": "https://api.github.com/repos/luckyfoxdesign/llm-settings-template/rulesets/27340997"
    },
    "html": {
      "href": "https://github.com/luckyfoxdesign/llm-settings-template/rules/27340997"
    }
  }
}
```

### Dependabot alerts enabled

```json
{
  "method": "PUT",
  "endpoint": "repos/luckyfoxdesign/llm-settings-template/vulnerability-alerts",
  "result": "success"
}
```

### Dependabot security updates enabled

```json
{
  "dependabot_security_updates": {
    "status": "enabled"
  },
  "secret_scanning": {
    "status": "enabled"
  },
  "secret_scanning_non_provider_patterns": {
    "status": "disabled"
  },
  "secret_scanning_push_protection": {
    "status": "enabled"
  },
  "secret_scanning_validity_checks": {
    "status": "disabled"
  }
}
```

### Private vulnerability reporting enabled

```json
{
  "enabled": true
}
```

## What Changed

- Added a read-only GitHub Actions `verify` workflow for pull requests and pushes to main, with per-ref concurrency and SHA-pinned checkout.
- Added weekly Dependabot updates for the landing npm template and GitHub Actions; npm minor and patch updates are grouped.
- Added SECURITY.md with supported scope, private advisory reporting, and response targets; documented repository setup for adopters in README.
- Enabled main protection (no force push or deletion, required GitHub Actions `verify`), Dependabot alerts/security updates, and private vulnerability reporting through the GitHub API.

## Verification Evidence

- Completion validation: `python3 scripts/check-task-contract.py --strict` passed before executing task commands.
- Completion gate: `bash scripts/verify.sh` passed on local main `252ba04f3199f48fc90fc81d43ccf34d1642e0d3`, including all 23 workflow regression tests.
- PR #4 merged after `verify` passed: https://github.com/luckyfoxdesign/llm-settings-template/pull/4
- Published main `2f8a009750e4a87efedb50f67c37b61ae2e15ac3`: https://github.com/luckyfoxdesign/llm-settings-template/actions/runs/43780164006 — completed / success. The exact published snapshot also passed the local gate with 15 tests; five unrelated local commits, including newer gate tests, were intentionally not published.
- Exact additional acceptance commands were authorized by the user earlier in this conversation and rechecked during closure: rulesets count 1; vulnerability-alerts HTTP 204; latest workflow conclusion success. A branch-filtered run query independently confirms main success, since the latest unfiltered run may be a Dependabot PR.
- GET rules/branches/main confirms deletion, non_fast_forward, and required verify with GitHub Actions app 15368; GET repository security_and_analysis.dependabot_security_updates returns enabled. Ruleset 27340997 is active, matches refs/heads/main, and has no bypass actors.
- https://github.com/luckyfoxdesign/llm-settings-template/security/policy renders the supported scope, private advisory link, and response targets. Private vulnerability reporting GET returns enabled.
- `git diff-tree --no-commit-id --stat -r 2f8a009`: exactly 4 approved implementation files, 64 additions, no deletions. No dependencies, scripts, or abstraction layers added; .gitignore, gate, and lifecycle unchanged by the task.
- `git diff --check`: passed. `python3 scripts/check-task-contract.py --complete docs/done/long/15-11-26-workspace-github-repo-hygiene.md` passed before WIP deletion. After deleting WIP and regenerating both indexes, the finalized-record `bash scripts/verify.sh` passed, including all 23 regression tests; docs/code-index.md remained unchanged.
- Existing dependency vulnerabilities reported after enabling Dependabot belong to the separate `15-11-26-workspace-landing-template-deps-and-docker.md` task; this task supplies detection and update controls.

## Review Evidence

NO_BLOCKING_FINDINGS. Reused the recorded review because every approved file SHA-256 is unchanged at closure and `git diff --exit-code 1d5f0c3 HEAD -- <four task paths>` exits 0. There are no uncommitted implementation changes.

The original review checked the frozen contract against triggers, token permissions, concurrency, checkout, system Python and unchanged gate, Dependabot ecosystems/schedules/grouping, reporting scope and response targets, adopter instructions, and file budget. A focused review after switching to the older remote base confirmed identical new files and the same README insertion, with no blocker/high findings.

- Local original implementation commit: `1d5f0c3`.
- Reviewed publication commit: `ae903daef949e003c5af588fa78efb7f19c4c1ed`, based on `d610ebac6843f441759708a358bd34fc4724e6b7`.
- Published diff SHA-256: `936aabe2414943eca7bea36ce230a375d249c61aa7442e009e30eb27c462b694`.
- Main squash commit: `2f8a009750e4a87efedb50f67c37b61ae2e15ac3`; its four implementation files equal the reviewed publication commit (`git diff --exit-code ae903da 2f8a009 -- <four task paths>` exits 0).
- Local integration commit: `252ba04f3199f48fc90fc81d43ccf34d1642e0d3`; its task files equal the original reviewed fingerprints below. Unrelated local commits and untracked backlog tasks were preserved.

Reviewed local file fingerprints:

```json
{
  "base_commit": "9b9e8ee8684aa470e9ff0390f056dfb803a3b208",
  "tracked_diff_sha256": "d3626f35ce8572c9543215ec1d871ed1f448a91358238b47bd15e27c54f64fc8",
  "file_sha256": {
    ".github/workflows/verify.yml": "3801d2a74aeafff7fb212e6a91ef1776ecdc97c00dd0855bb877073b14e24d4f",
    ".github/dependabot.yml": "0382b6083e13b12508a7607b07cc8987b5aacdf755ffad8455b706c9dd729a2f",
    "SECURITY.md": "f7fa4f2ba9298bc11fb9fd461f5652a02d89396eec5a80610b7564976178a5e5",
    "README.md": "711056509b91d12bc11dd3993611c9f16652b71ddd3bd475305e6cf9142872ba"
  }
}
```

[Short summary](../short/15-11-26-workspace-github-repo-hygiene.md)
