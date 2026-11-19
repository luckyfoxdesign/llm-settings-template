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
  - docs/folder-rules.md
  - AGENTS.md
source:
  kind: observation
completion_validation: required
---

**Commits:**
- workspace `cb0e2bb` — "fix: widen staged leak detection and add optional content scan"


# Widen Leak Detection Before Commit: Filename Corpus And Optional Content Scan

**Status:** done
**Last checked:** 2026-11-19

## What Changed

- Expand private filename detection with the 25-name credential corpus, key-store suffixes, service-account files, SSH key stems and token filename forms, preserving documented safe counterexamples.
- Add opt-in `--content-scan`: gitleaks runs in Docker with read-only repository access, disabled networking, redaction and suppressed diagnostics. Findings and scan errors fail; unavailable Docker produces an explicit skip.
- Document optional scanning and GitHub non-provider pattern configuration; keep normal gates independent of Docker.

## Goal

Make the staging guard catch credential files it currently misses by name and offer a content-based scan, so a public template repository does not rely on a short filename heuristic alone.

## Context

Finding from the security review on 2026-11-15 (severity `high`). `private_path()` in `scripts/workspace_rules.py` is the only deterministic control before `git commit` (`check-staged-paths.sh`). Against a corpus of 25 credential-shaped names it missed 18: `.vault-token`, `github_token.txt`, `GITHUB_TOKEN`, `service-account.json`, `kubeconfig`, `.pgpass`, `.htpasswd`, `.pypirc`, `client.p12`, `keystore.jks`, `vpn.ovpn`, `terraform.tfstate`, `.docker/config.json`, `.boto`, `.s3cfg`, `wp-config.php`, `id_ecdsa`, plus any secret inside an innocently named file. A gitleaks run over all 27 commits found no leaks today; GitHub secret scanning with push protection is enabled, but only for provider patterns (non-provider patterns are disabled).

Assumptions recorded instead of asked:

- Name matching stays a filename heuristic; the content scan is a separate opt-in flag because it needs Docker and network for the first image pull.
- Content scan tool: gitleaks, run as `docker run --rm -v <repo>:/repo:ro ghcr.io/gitleaks/gitleaks:latest protect --staged --redact`; output is redacted so values never reach a terminal or an agent context.
- Enabling non-provider patterns is a GitHub setting; the task documents the step rather than scripting it.

## Non-goals

- Do not scan file contents on the host with ad-hoc regexes.
- Do not make the content scan mandatory in `scripts/verify.sh` (it would require Docker and network for workspace tasks).
- Do not change `.gitignore` or the permission rules (separate task `harden-agent-permissions`).

## Invariants

- `.env.example` is still the only exempt `.env*` name; `landing/scripts/generate-tokens.mjs` and `landing/tokens/semantic.generated.json` remain non-private (existing test).
- `check-staged-paths.sh` without the new flag behaves exactly as today and still runs without Docker.
- `scripts/check-staged-paths.py` keeps reading only filenames, never staged contents.

## Change Budget

- At most 6 workspace files modified, 0 new.
- No new dependencies on the host; gitleaks only as a Docker image.
- No new scripts; no new abstraction layers.

## Task Paths

- `scripts/workspace_rules.py`
- `scripts/check-staged-paths.py`
- `scripts/check-staged-paths.sh`
- `scripts/test-workflow.py`
- `docs/folder-rules.md`
- `README.md`

## Implementation Steps

1. Extend `private_path()` with the missed names: `*-token`/`*_token*` suffix forms, `kubeconfig`, `.pgpass`, `.htpasswd`, `.pypirc`, `.boto`, `.s3cfg`, `.git-credentials`, `wp-config.php`, `service-account*.json`, `*.tfstate`, `.docker/config.json`, key-store suffixes (`.p12`, `.pfx`, `.jks`, `.keystore`, `.ovpn`, `.kdbx`, `.asc`, `.gpg`), and all `id_*` SSH key stems.
2. Add the 25-name corpus to `test_private_paths_and_symlinks_are_not_opened` with explicit non-private counterexamples (`tokens/colors.used.json`, `token-pipeline.md`).
3. Add `--content-scan` to `check-staged-paths.py`/`.sh`: runs the gitleaks container on the repo, fails on findings, prints only redacted output; prints a clear skip reason when Docker is unavailable.
4. Document the flag in `docs/folder-rules.md` (staged-path guard paragraph) and add a `README.md` line on enabling non-provider patterns in GitHub secret scanning.

## Verification

```bash
bash scripts/verify.sh
python3 -B scripts/test-workflow.py
```

## Done When

- [x] All 25 corpus names are classified private and the counterexamples non-private in the regression test. — Evidence: python3 -B scripts/test-workflow.py Documents.test_private_paths_and_symlinks_are_not_opened; covered by the passing 30-test suite, including the 25-name corpus and safe token paths.
- [x] `bash scripts/check-staged-paths.sh . --secrets-only --content-scan` runs the redacted gitleaks scan and exits 0 on this repository. — Evidence: Ran the exact command with all six implementation files staged on 2026-11-19; exit 0, checked 6 staged paths and reported redacted gitleaks content scan passed, without SKIP.
- [x] `Verification` commands pass. — Evidence: bash scripts/verify.sh exited 0 (all strict gates and 30 workflow tests); python3 -B scripts/test-workflow.py exited 0 (30 tests).
- [x] The diff stays within `Change Budget`. — Evidence: git diff HEAD --numstat lists exactly the six approved modified files, zero new implementation files; task-scoped staged guard exited 0 with 6 paths; no host dependencies, scripts or abstraction layers added.
- [x] The final implementation snapshot has recorded review evidence. — Evidence: Review Evidence below identifies HEAD plus the approved-path diff SHA-256; NO_BLOCKING_FINDINGS.

## Related

- Review origin: security review 2026-11-15, step 3.
- Related tasks: `15-11-26-workspace-harden-agent-permissions.md`.


## Verification Evidence

2026-11-19:

- `bash scripts/verify.sh`: exit 0, all workspace gates passed, 30 tests.
- `python3 -B scripts/test-workflow.py`: exit 0, 30 tests.
- `bash scripts/check-staged-paths.sh . --task docs/wip/15-11-26-workspace-leak-detection-coverage.md`: exit 0, six staged files satisfy scope and budget.
- `bash scripts/check-staged-paths.sh . --secrets-only --content-scan`: exit 0 on the six staged implementation files; real Docker scan completed, no skip.
- Real Docker acceptance in a disposable Git repository: commit a clean `sample.txt`, stage a clean edit, then change the working file to an `api_key` assignment with a deliberately nonfunctional synthetic SHA-256 value derived from the text `workspace leak detection synthetic fixture`. Scan accepted the clean staged edit (exit 0), accepted the same index with the synthetic value only in the working tree (exit 0), and rejected it after staging (exit 1 with a findings message). The synthetic value was absent from stdout/stderr. No actual credentials were used.
- `Fixtures.test_optional_content_scan` deterministically covers no Docker call without the flag, read-only/network-disabled/redacted invocation, findings, scanner failure, inaccessible daemon, missing Docker, suppressed diagnostics and filename rejection before scanning.
- `git diff HEAD --check`: exit 0. Exactly six approved implementation files changed; no new implementation files or dependencies.
- Implementation files were temporarily staged for acceptance checks; the initially empty index is restored afterward. During completion the six task files were staged again, scope-checked and scanned successfully, then committed as `cb0e2bb`.

## Review Evidence

Completion reused the unchanged review: the approved-path diff SHA-256 matched before commit. Final implementation commit: `cb0e2bbf73b43837bbfaa0c355eedb1d6a12626b`. Required Verification commands and the six-file staged content scan were rerun successfully before committing.

NO_BLOCKING_FINDINGS. Evidence-only review on 2026-11-19 against the frozen contract; no non-blocking findings recorded.

- Repository HEAD: `e97ddd198b6d7b33ff9e0a733bccd4ee8cc2a074`.
- Uncommitted implementation snapshot: SHA-256 `9ef784c1bd3ecf7dc97c8773c58f9210caa33cbd5bfcdad454c971e8ef9789d4` of `git diff HEAD -- scripts/workspace_rules.py scripts/check-staged-paths.py scripts/check-staged-paths.sh scripts/test-workflow.py docs/folder-rules.md README.md` (raw stdout bytes).
- Reviewed all six approved paths against invariants, scope, budget and executable results. The Python guard reads Git filenames and delegates content inspection to Docker; scanner stdout/stderr are discarded, and only static status messages are emitted. Existing filename/scope validation precedes Docker invocation; no flag means no Docker invocation.
- The 25-name corpus and non-private counterexamples pass. Mocked error paths and the real staged/unstaged synthetic acceptance confirm rejection and diagnostic suppression. Strict workspace gates pass; no permission rules, ignore rules or mandatory Docker gates changed.
- Contract unchanged. User confirmed the plan and container-only staged-content inspection in this conversation. Closure authorized by the user through `/complete-task`; implementation committed as `cb0e2bbf73b43837bbfaa0c355eedb1d6a12626b`.

[Short summary](../short/15-11-26-workspace-leak-detection-coverage.md)
