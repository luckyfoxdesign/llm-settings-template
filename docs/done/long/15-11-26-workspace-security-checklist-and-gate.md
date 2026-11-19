---
type: done_long
status: done
phase: completed
project: workspace
created: 2026-11-15
area:
  - security
  - templates
  - quality-gates
related_docs:
  - docs/product/architecture/verification-contract.md
  - docs/runbook-prod.md
source:
  kind: observation
completion_validation: required
---

**Commits:**
- workspace `a9b1e6f` — "feat: add reusable security checklist and optional gate"


# Reusable Security Checklist And An Executable `check-security.sh`

**Status:** done
**Last checked:** 2026-11-19

## What Changed

- Added a Docker-backed security checker for npm/OSV advisories, runtime support, Dockerfiles, shell scripts, redacted Git history and published compose ports.
- Added a reusable checklist covering all 13 review steps without fixed dependency/runtime versions.
- Linked the optional security check from README, the workspace map and both repository templates; kept executable verification and CI unchanged.

## Goal

Turn the 2026-11-15 security review into a reusable artefact for every project created from this template: a checklist document that names no version numbers, and one host-side script that computes the facts it depends on (dependency advisories, base-image support status, Dockerfile and shell lint) with Docker-run tools.

## Context

User decision from the review on 2026-11-15: do not hard-code versions in docs, because they will not be kept current; checks must compute currency at run time. The review already exercised the tool set in throwaway containers: `npm audit` and `osv-scanner` on a lockfile, `hadolint` on Dockerfiles, `shellcheck` on scripts, `gitleaks` on history, `https://endoflife.date/api/nodejs/<major>.json` for support status. Each run is read-only with `:ro` mounts and needs no host toolchain, which matches the Docker-only rule.

Assumptions recorded instead of asked:

- `scripts/check-security.sh <repo-path>` autodetects what is present (`package-lock.json`, `Dockerfile*`, `*.sh`, `compose*.yml`) and skips absent inputs with a visible `SKIP`; it is warning-only by default and strict with `--strict`, mirroring the other validators.
- It is not added to the workspace `scripts/verify.sh` (network-dependent); the sub-repo and landing `AGENTS.md` gate tables list it as an optional gate that a repo may promote to required.
- The checklist lives in `docs/product/architecture/security-checklist.md` and references the script instead of restating commands.
- The permission canary procedure (manual, from `harden-agent-permissions`) is recorded in the checklist as a manual step.

## Non-goals

- Do not implement fixes found by the script; findings route through the normal task flow.
- Do not add the script to `scripts/verify.sh` or to `.github/workflows` (separate task).
- Do not change `_templates/*/scripts/verify.sh` (the `gate-markdown-commands` task edits them).

## Invariants

- The script never prints secret values: gitleaks runs with `--redact`; no `env`, `printenv`, or `docker compose config` without `--quiet`.
- All Docker invocations mount the target read-only and run no `privileged` or host-network containers.
- Without Docker the script exits with a clear message and non-zero only in `--strict` mode.
- Hot-context budgets hold for `README.md`-linked files (`PROJECT_MAP.md` ≤ 200 lines / 7 KB).

## Change Budget

- At most 6 workspace files: 2 new, 4 modified.
- No new host dependencies; tools run only as Docker images.
- At most 1 new script; no new abstraction layers.

## Task Paths

- `docs/product/architecture/security-checklist.md`
- `scripts/check-security.sh`
- `README.md`
- `PROJECT_MAP.md`
- `_templates/sub-repo/AGENTS.md`
- `_templates/landing/AGENTS.md`

## Implementation Steps

1. Write `scripts/check-security.sh`: sections `deps` (npm audit + osv-scanner on the lockfile), `images` (parse `FROM` lines, query endoflife.date for the detected runtime major, report `SUPPORTED`/`EOL`), `dockerfiles` (hadolint), `shell` (shellcheck), `history` (gitleaks `--redact`), `ports` (flag published ports not bound to `127.0.0.1` in compose files); `--strict` fails on high/critical advisories, EOL images, hadolint errors, gitleaks findings.
2. Write the checklist: one section per review step (permissions, markdown-executed commands, leak detection, dependencies, containers, repository settings, agent instructions, external MCP, host scripts, plugins, headers, information disclosure, runbook defaults), each with risk, how-to-check (script section or manual step), and pass criterion expressed without version literals.
3. Reference the script in `README.md` → Workspace Scripts and `PROJECT_MAP.md`; add an optional `security` gate row to both template `AGENTS.md` gate tables.

## Verification

```bash
bash scripts/verify.sh
bash scripts/check-security.sh _templates/landing
bash scripts/check-context-budget.sh --strict
```

## Done When

- [x] `bash scripts/check-security.sh _templates/landing` runs every applicable section, prints `SKIP` for absent inputs, and never prints a secret value or an unredacted gitleaks line. — Evidence: Default landing invocation exited 0; deps, images, dockerfiles, shell and ports executed; history printed SKIP. Tool diagnostics suppressed. Clean and synthetic-finding Git fixtures additionally verified history and redaction.
- [x] `grep -nE '[0-9]+\.[0-9]+\.[0-9]+' docs/product/architecture/security-checklist.md` returns no dependency or runtime version literals (dates and advisory IDs are allowed). — Evidence: Version-literal grep exited 1 with no matches on the checklist.
- [x] The checklist covers all 13 review steps with a pass criterion each. — Evidence: Checklist has 13 numbered review steps and 13 explicit Pass criteria (counted from Markdown).
- [x] `Verification` commands pass; context budgets hold; the diff stays within `Change Budget`. — Evidence: All three Verification commands exited 0; workspace gate ran 30 passing regressions. PROJECT_MAP.md is 91 lines / 2,970 bytes; six implementation files, two new and four modified; no host dependencies or abstraction layers added.
- [x] The final implementation snapshot has recorded review evidence. — Evidence: Review Evidence below records NO_BLOCKING_FINDINGS and the final approved-path implementation diff hash.

## Related

- Review origin: security review 2026-11-15 (all steps).
- Related tasks: `15-11-26-workspace-landing-template-deps-and-docker.md`, `15-11-26-workspace-github-repo-hygiene.md`.

## Verification Evidence

- Closure recheck on 2026-11-19: strict contract validation, all three frozen Verification commands and the staged-path task guard passed. Workspace regressions: 30 passing tests. The default security scan again reported 13 high/critical advisories (19 total), OSV findings, Node cycle 20 EOL, two published-port warnings and history SKIP; these pre-existing findings are outside the remediation scope.

- `bash scripts/verify.sh`: exit 0; strict docs/contracts/context/ownership checks and 30 regression tests passed.
- `bash scripts/check-security.sh _templates/landing`: exit 0; npm reported 13 high/critical and 19 total advisories, OSV findings, both Dockerfiles and both shell scripts passed, Node cycle 20 reported EOL, two non-loopback published ports warned, history SKIP (template has no standalone Git directory). Existing target findings were not remediated under this contract.
- `bash scripts/check-context-budget.sh --strict`: exit 0; all hot-context files within limits.
- Additional strict landing invocation: exit 1 on advisories/EOL as intended; this is an acceptance check of failure behavior, not a failed Verification command.
- Docker ShellCheck of `scripts/check-security.sh` with `--norc`: exit 0. Bash syntax and `git diff --check`: exit 0.
- Temporary host fixture runner `python3 /tmp/workspace-security-regression.py`: 22 passing scenarios covering clean/low/high advisories, OSV findings, linter findings, leaks, EOL, tool errors, missing Docker, absent inputs, port warnings and unresolved bases; both exit modes, private/symlink exclusions and read-only mount flags asserted. Scanner stderr canary never appeared in output. Fixture helper is outside the implementation and not committed.
- Live disposable Git fixtures: clean history exited 0; a generated non-secret API-key-shaped canary committed in a fixture exited 1 with `history: FAIL`; canary value absent from stdout/stderr. Only these synthetic histories were scanned for this acceptance check.
- No dependency/runtime version literals in the checklist; all 13 review sections have risk, check and pass criteria.

## Review Evidence

- Closure reused the recorded review after verifying the pre-staging diff hash matched exactly. No implementation changes since the reviewed snapshot; outcome remains `NO_BLOCKING_FINDINGS`.

- Contract review outcome: `NO_BLOCKING_FINDINGS`; no non-blocking findings identified against the frozen contract.
- Repository HEAD: `e137059339c9bb0fc5a1665269df8dd23b32a393`.
- Final implementation snapshot SHA-256: `358854961dfd89692d4e779b56cf051f787c4b5d9a30b2e7b0618dca184b5558`. Reconstruct the pre-staging diff with `git diff --binary e137059339c9bb0fc5a1665269df8dd23b32a393 a9b1e6f -- README.md PROJECT_MAP.md _templates/sub-repo/AGENTS.md _templates/landing/AGENTS.md`, append the stdout of `git diff --no-index --binary -- /dev/null <path>` for the new checklist then the new security script, and SHA-256 the concatenated bytes.
- Approved six-file content manifest SHA-256: `5ec55546f3895a5d05d0054bda8da1da36f3b90c8eb38e493449bb90984c931a` (Task Paths order above; append each UTF-8 path, NUL, file bytes, NUL). WIP evidence prose excluded.
- Reviewed default/strict error routing, private-path and symlink exclusions, selected-input snapshots, read-only Docker mounts, disabled networking for offline analyzers, refreshed tool tags, advisory/support requests, history redaction, port warning coverage and all integration links. Live fixtures and the assertions above supply execution evidence.
- Budget: exactly the six approved implementation paths; two additions, four modifications, one new script, no new host dependencies. Workspace/repo verify scripts and CI unchanged. Implementation committed as `a9b1e6f`; completion is recorded separately. The reviewed six-file contents are unchanged by the commit.

[Short summary](../short/15-11-26-workspace-security-checklist-and-gate.md)
