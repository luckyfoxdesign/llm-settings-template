---
type: done_long
status: done
phase: completed
project: workspace
created: 2026-11-15
area:
  - security
  - templates
  - docs
related_docs:
  - docs/runbook-prod.md
  - AGENTS.md
  - _templates/landing/AGENTS.md
source:
  kind: observation
completion_validation: required
---

**Commits:**
- workspace `75215f9` — "fix: clean workspace template identifiers and security defaults"


# Template Hygiene: Placeholders, Private Paths, Runbook Defaults, Plugin Origin Check

**Status:** done
**Last checked:** 2026-11-19

## Goal

Remove low-severity residue found in the security review: personal identifiers and private workspace paths in public files, unsafe-by-default patterns in the production runbook, missing data-minimisation wording for external research, and the missing origin check in the Figma plugin UI.

## Context

A security review on 2026-11-15 found project-specific identifiers in the
Figma plugin and token scripts, nine private source-workspace paths in two
historical token records, shell sourcing of `.env` in the backup example,
optional server baseline checks, and no read-only deploy-key prerequisite.
The plugin UI lacked an incoming origin guard. Workspace research instructions
omitted data minimisation, and the landing instructions omitted HSTS preload
implications. The implementation uses neutral `[project-name]` placeholders;
the token checker discovers extension metadata without a project constant.

### Confirmed contract corrections (2026-11-19)

The authorized tracked-file scan contradicted the original zero-match
assumption: 13 matches were valid `luckyfoxdesign/llm-settings-template`
references in `SECURITY.md` and GitHub hygiene records (security reporting,
CI/PR evidence, and API commands). The invariant and first acceptance criterion
exclude that exact repository reference. Preserve these functional links;
no additional implementation paths or budget were needed. The 13-match count
was measured before adding these completion records.

The two historical token records contained standalone brand/domain/namespace
identifiers in addition to private paths. Those were anonymised too; other
content was preserved. This archived contract omits the original personal
identifier and private path literals to avoid reintroducing the removed data.

## Non-goals

- Do not change plugin behaviour beyond the origin check; `networkAccess` stays `none`.
- Do not change deploy or rollback steps in the runbook, only the defaults and prerequisites it states.
- Do not touch `vercel.json` headers (CSP is in `landing-template-deps-and-docker`).
- Do not rename fixtures in `_templates/landing/scripts/fixtures/`.

## Invariants

- `tokens:generate` followed by `tokens:check` and `tokens:lint --fixture scripts/fixtures/tokens-clean.json` / `tokens-drift.json` keep their exit codes (0 / 0 / 1).
- `AGENTS.md` stays within 180 lines / 8192 bytes.
- `scripts/check-no-flow-duplication.sh` passes (done records and templates are not instruction owners).
- Tracked non-private files contain no legacy brand identifiers or private source-workspace paths; the exact public repository reference `luckyfoxdesign/llm-settings-template` is exempt, based on the contradicting acceptance output recorded above.

## Change Budget

- At most 10 workspace files modified, 0 new.
- No new dependencies.
- No new scripts; no new abstraction layers.

## Task Paths

- `_templates/landing/figma-plugin/manifest.json`
- `_templates/landing/figma-plugin/code.js`
- `_templates/landing/figma-plugin/ui.html`
- `_templates/landing/scripts/generate-tokens.mjs`
- `_templates/landing/scripts/check-tokens.mjs`
- `_templates/landing/AGENTS.md`
- `docs/done/long/05-09-26-workspace-landing-template-tokens.md`
- `docs/done/short/05-09-26-workspace-landing-template-tokens.md`
- `docs/runbook-prod.md`
- `AGENTS.md`

## Implementation Steps

1. Replace the brand identifiers with placeholders in the plugin and token scripts; regenerate nothing in the template (`tokens/` holds only `.gitkeep`), but verify the pipeline in a fresh copy.
2. Add `if (event.origin !== "https://www.figma.com" && event.origin !== "null") return;`-style guard per current Figma plugin guidance in `ui.html`.
3. Runbook: require a read-only deploy key for the server checkout, replace `set -a; . ./.env` with `docker compose --env-file`/`exec -e` forms, make the Server Security Baseline table a prerequisite ("fill before the first deploy").
4. Replace private workspace paths in the two done records with a neutral phrase.
5. Add one line to `AGENTS.md` → Optional External Research on data minimisation; add the HSTS `preload` note to `_templates/landing/AGENTS.md` → Security.

## Verification

```bash
bash scripts/verify.sh
bash scripts/check-context-budget.sh --strict
```

## Additional Acceptance Checks

The user explicitly authorized the additional tracked-file identifier scan
with the implementation plan. It ran against regular, non-private tracked paths
without following symlinks. Observed results and the narrowly scoped public
repository exception are recorded below; no further approval is required.

## Done When

- [x] Tracked non-private files contain no legacy identifiers/private source paths, except the exact public repository reference recorded above. — Evidence: authorized legacy-identifier scan (`git grep -n` with approved safe paths) returned 13 matches; an assertion verified every match contains only `luckyfoxdesign/llm-settings-template`, with no other legacy occurrence.
- [x] In a fresh copy of the template, `tokens:generate`, `tokens:check`, and both fixture lint runs keep exit codes 0 / 0 / 0 / 1. — Evidence: Docker acceptance harness in `template-hygiene-low-check` asserted all four expected exits, observed 0 / 0 / 0 / 1.
- [x] The runbook states the read-only deploy key, the `--env-file` form, and the baseline prerequisite; `ui.html` ignores messages from unexpected origins. — Evidence: `docs/runbook-prod.md` prerequisites/backup diff; Docker Node VM harness rejected four unexpected origins before payload access and preserved error/import/export for `https://www.figma.com` and `null`.
- [x] `Verification` commands pass; `AGENTS.md` within budget; the diff stays within `Change Budget`. — Evidence: both required commands exited 0; 30 workflow tests passed; `AGENTS.md` is 67 lines / 4397 bytes; 10 approved implementation files, zero new files/dependencies/abstractions. The backlog-to-WIP lifecycle move is separate from the implementation budget.
- [x] The final implementation snapshot has recorded review evidence. — Evidence: `Review Evidence` below identifies the approved implementation diff and records `NO_BLOCKING_FINDINGS`.

## Related

- Review origin: security review 2026-11-15, steps 8, 10, 12, 13.
- Related tasks: `15-11-26-workspace-landing-template-deps-and-docker.md`.

## What Changed

- Replaced project-specific plugin IDs, storage keys and token namespaces with
  neutral placeholders; the checker discovers extension metadata dynamically.
- Added an incoming message origin allowlist while preserving plugin network
  restrictions and allowed message handling.
- Made the server baseline and repository-scoped read-only deploy key explicit
  prerequisites; backup/restore use Compose `--env-file` and expand PostgreSQL
  variables inside the container instead of sourcing `.env` on the host.
- Anonymised historical source paths and identifiers; added external-research
  data minimisation and an HSTS preload/removal explanation.
- Preserved Vercel headers, fixture names, dependencies and deploy/rollback steps.

## Verification Evidence

- Closure rerun of `bash scripts/verify.sh`: exit 0; all strict workspace gates and 30 regression tests pass.
- `bash scripts/check-context-budget.sh --strict`: exit 0; root AGENTS 67 lines / 4397 bytes.
- `git diff --check`: exit 0.
- Fresh copy contains only tracked non-private template files, with no symlinks;
  `tokens/` initially contains only `.gitkeep`. No template-generated assets were changed.
- `docker build -f docker-files/Dockerfile.dev -t template-hygiene-low-check .`
  in the scratch copy: exit 0, pinned dependencies installed from the existing lock.
- `docker run --rm --network none -i template-hygiene-low-check node --input-type=commonjs`
  with an inline acceptance harness: exit 0. It uses `spawnSync('npm', args)`
  and asserts the status of `run tokens:generate` (0), `run tokens:check` (0),
  `run tokens:lint -- --fixture scripts/fixtures/tokens-clean.json` (0), and
  `run tokens:lint -- --fixture scripts/fixtures/tokens-drift.json` (1).
- The same harness extracts the inline UI script into Node `vm` with DOM stubs.
  Origins `https://unexpected.example`, `http://www.figma.com`,
  `https://www.figma.com.evil.example`, and the empty string return before a
  throwing `event.data` getter is accessed. Both allowed origins process error,
  import-report and export-result messages; exactly two downloads occur.
  `node --check figma-plugin/code.js` and manifest `allowedDomains: ["none"]` pass.
- Initial Compose attempt could not create a network because Docker's address
  pools are exhausted. The successful acceptance run uses `--network none`;
  no existing networks, containers or volumes were changed or removed.
- Authorized grep was restricted to regular tracked non-private paths, without
  following symlinks. Its 13 remaining results are functional public repository
  references; the contract correction above records this observed exception.
- Official references: Figma UI messaging/origin context at
  https://developers.figma.com/docs/plugins/creating-ui/ and preload/removal at
  https://hstspreload.org/contact/. The origin allowlist implements the task's
  specified policy; no live Figma integration session was used.

## Review Evidence

- Snapshot: workspace HEAD `11a14aea349c0043bc8f526378c950f5bc3eab57`; SHA-256 of `git diff --binary HEAD -- <the 10 Task Paths>`: `c18d3ab052be8426ec965d6dd695a670e13e4400678ace26d4a89173264fb09d`.
- Outcome: `NO_BLOCKING_FINDINGS`. One evidence-only review of the final
  implementation against the corrected frozen contract; no review code edits.
- Checked namespace consistency across generator/plugin/checker, origin-guard
  placement before payload access, unchanged plugin network access and fixtures,
  in-container expansion of PostgreSQL variables without sourcing server `.env`,
  unchanged deploy/rollback commands and Vercel headers, narrow historical
  anonymisation, data-minimisation wording, and the approved ten-file budget.
- No confirmed blocker/high or actionable non-blocking findings remain.
- Closure reuses this unchanged implementation review; commit `75215f9` contains exactly the reviewed ten-file diff. No code-repo merge applies to this workspace task.

[Short summary](../short/15-11-26-workspace-template-hygiene-low.md)

- Closure evidence: implementation commit `75215f9`; task-scoped staged-path guard passed for all 10 approved files. Completion records were validated before WIP deletion, then indexes regenerated and the final workspace gate rerun.
