---
type: done_long
status: done
phase: completed
project: workspace
created: 2026-11-15
area:
  - security
  - templates
  - docker
related_docs:
  - _templates/landing/AGENTS.md
  - docs/product/architecture/verification-contract.md
source:
  kind: observation
completion_validation: required
---

**Commits:**
- workspace `cf19681` — "fix: harden landing template dependencies and Docker"


# Landing Template: Patch Dependencies, Harden Docker, Add CSP

**Status:** done
**Last checked:** 2026-11-19

## Goal

Bring `_templates/landing/` to a state where the dependency audit reports no high or critical findings, the containers run on a supported Node line as a non-root user bound to localhost, the "prod" service is not misrepresented, and the deployed site ships a Content-Security-Policy.

## Context

Finding from the security review on 2026-11-15 (severity `high`). `npm audit` over the template lockfile: 1 critical, 12 high, 6 moderate; osv-scanner: 54 fixable advisories. For the pinned `astro` the fix is a **minor** release (`fixAvailable.isSemVerMajor: false`); `@astrojs/sitemap` also has a minor fix; `@astrojs/vercel` needs a major; the suggested "fix" for `@tailwindcss/typography` is a downgrade and is rejected. Advisories reachable in this template: dev-server local file read and error-page XSS, Vite serving files outside `server.fs.allow`, template-rendering XSS (`define:vars`, spread attributes, slot names) and build-time RCE in image optimisation (sharp/libvips). The dev server is reachable from the LAN because `compose.yml` publishes `3000:3000` on all interfaces and `astro.config.mjs` sets `host: true`. The base image `node:20-bookworm-slim` is end-of-life (endoflife.date, cycle 20); both Dockerfiles run as root; the `astro-prod` service runs `astro preview` while its comment promises "nginx + static files". A throwaway build showed `dist/` contains no inline `<script>` or `<style>`, so a strict CSP needs no exceptions. Telemetry is not disabled in containers.

Design constraint from the user: do not pin "current" version numbers in prose. Acceptance is expressed as audit results and support status computed at verification time, not as version literals; Dependabot (separate task) is the reminder mechanism.

Assumptions recorded instead of asked:

- Original same-major assumption superseded on 2026-11-19: audit after the same-major refresh found 6 high and 1 critical, requiring Astro and adapter major upgrades. User explicitly authorized those upgrades; no high/critical residual is accepted.
- The base image moves to the newest Node line in `lts` status per `https://endoflife.date/api/nodejs.json`, slim Debian variant.
- `astro-prod` is renamed `astro-preview` with an honest comment; a real static server is out of scope.
- `tokens/` holds only `.gitkeep` in the template, so `tokens:generate` runs before `tokens:check` in verification.

## Non-goals

- Do not change `tailwindcss`, `@tailwindcss/vite`, or `@tailwindcss/typography` versions; `generate-tokens.mjs` control values depend on them.
- Do not add a linter, test framework, or nginx image.
- Do not change `src/` or the token pipeline scripts.
- Do not edit `.claude/` files.

## Invariants

- `docker compose run --rm astro-dev npm run build` and `tokens:check` (after `tokens:generate`) pass from a fresh copy of the template.
- `EXPECTED` control values in `scripts/generate-tokens.mjs` are unchanged.
- `vercel.json` keeps every existing header; CSP is added, nothing weakened.
- No `privileged`, no host network, no new published ports.

## Change Budget

- At most 11 workspace files modified, 0 new.
- No new dependencies; version updates only for existing direct dependencies. User authorized major upgrades for Astro and @astrojs/vercel on 2026-11-19 after audit proved the original same-major constraint insufficient. Tailwind package versions remain frozen. A scoped override of routing-utils → path-to-regexp to a patched same-major release is permitted: registry metadata shows even the latest routing-utils pins vulnerable path-to-regexp exactly, so normal lockfile updates cannot repair it.
- No new scripts; no new abstraction layers.

## Task Paths

- `_templates/landing/package.json`
- `_templates/landing/package-lock.json`
- `_templates/landing/compose.yml`
- `_templates/landing/docker-files/Dockerfile.dev`
- `_templates/landing/docker-files/Dockerfile.prod`
- `_templates/landing/vercel.json`
- `_templates/landing/astro.config.mjs`
- `_templates/landing/AGENTS.md`
- `_templates/landing/CLAUDE.md`
- `_templates/landing/PROJECT_MAP.md`
- `_templates/landing/scripts/verify.sh`

## Implementation Steps

1. In Docker, update Astro and the Vercel adapter to patched compatible releases (major upgrades authorized), and sitemap within its major; regenerate the lockfile, rerun audit, and document moderate residuals with reasons.
2. Dockerfiles: base image = newest LTS Node per endoflife.date, `USER node` after dependency install, `ENV ASTRO_TELEMETRY_DISABLED=1`; evaluate `npm ci --ignore-scripts` (keep only if `sharp` still resolves its prebuilt binaries).
3. `compose.yml`: bind `127.0.0.1:3000:3000` and `127.0.0.1:8080:3000`; rename `astro-prod` → `astro-preview` with a comment that production is Vercel static output; mirror in `CLAUDE.md`, `PROJECT_MAP.md`, `scripts/verify.sh`.
4. `vercel.json`: add `Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; object-src 'none'; base-uri 'self'; frame-ancestors 'self'`; `astro.config.mjs`: comment that `host: true` is safe only with the localhost port binding.
5. Add the dev-server exposure and CSP rules to `_templates/landing/AGENTS.md` → Security.

## Verification

```bash
bash scripts/verify.sh
```

## Additional Acceptance Checks

These commands are outside the Verification allowlist. Review them and obtain
explicit user authorization before running them; do not execute them automatically
as part of task completion. They remain required acceptance checks for this task.

```bash
docker run --rm -v "$PWD/_templates/landing:/src:ro" -w /tmp/a node:lts-bookworm-slim sh -c 'mkdir -p /tmp/a && cp /src/package.json /src/package-lock.json . && npm audit --audit-level=high'
docker run --rm -i hadolint/hadolint hadolint - < _templates/landing/docker-files/Dockerfile.dev
docker run --rm -i hadolint/hadolint hadolint - < _templates/landing/docker-files/Dockerfile.prod
docker compose -f _templates/landing/compose.yml config --quiet
```

## Done When

- [x] `npm audit --audit-level=high` over the template lockfile exits 0; remaining moderate findings are listed with reasons in `_templates/landing/AGENTS.md`. — Evidence: Authorized audit command exited 0 on 2026-11-19: 0 high/critical, 2 moderate (typography and its postcss-selector-parser dependency), documented in AGENTS.md → Security update constraints.
- [x] The base image major reported by `grep FROM _templates/landing/docker-files/*` is in `lts` status with a future `eol` in `https://endoflife.date/api/nodejs/<major>.json` on the completion date. — Evidence: Both FROM declarations use the newest LTS cycle returned by the API; https://endoflife.date/api/nodejs/26.json returned lts=2026-10-28 and eol=2029-04-30; downloaded image reported v26.13.1.
- [x] Both Dockerfiles end with a non-root `USER`; `docker compose config` shows every published port bound to `127.0.0.1`; no service is named or described as production. — Evidence: Both Dockerfiles finish their stages as USER 1000:1000; dev and preview runtime probes reported UID 1000. compose.yml has only 127.0.0.1 bindings on the two existing ports; config --quiet exited 0. Service names are astro-dev and astro-preview.
- [x] From a fresh copy of the template, `docker compose run --rm astro-dev npm run build`, `tokens:generate`, then `tokens:check` all exit 0; `grep -c "<script" dist/index.html` is 0, so the added CSP holds without exceptions. — Evidence: Fresh tracked-file copy: COMPOSE_PROJECT_NAME=landing-template-check bash scripts/verify.sh exited 0. Build succeeded; token generation/check reported 242 scale tokens, 95 out of sRGB, 9 semantic tokens. HTML parser and string checks found 0 script/style tags and no inline styles/events; local stylesheet exists and Vercel static HTML matches dist.
- [x] `Verification` commands pass; the diff stays within `Change Budget`. — Evidence: bash scripts/verify.sh exited 0: strict validators and all 30 workflow regression tests passed. Both exact hadolint acceptance commands and compose config --quiet exited 0. git diff --check passed; 11 implementation files modified, 0 added; lifecycle move recorded separately.
- [x] The final implementation snapshot has recorded review evidence. — Evidence: NO_BLOCKING_FINDINGS; see Review Evidence below for the exact commit/diff identity and executable evidence.

## Related

- Review origin: security review 2026-11-15, steps 4, 5, 11.
- Reminder mechanism: `15-11-26-workspace-github-repo-hygiene.md` (Dependabot).
- Source of the template: `docs/done/long/05-09-26-workspace-landing-template-tokens.md`.

## What Changed

- Upgraded the existing Astro, Vercel adapter and sitemap dependencies; refreshed the lockfile and scoped a patched same-major routing dependency override. Tailwind versions and token control values are unchanged.
- Moved Docker stages to a supported LTS base, disabled telemetry, installed with scripts disabled, and verified sharp works as non-root. Bound existing ports to localhost and renamed the local preview service.
- Added strict CSP while preserving every existing response header. Updated template guidance and made the template token gate generate its initially absent artifacts before checking them.

## Verification Evidence

- User authorized the plan and all four Additional Acceptance Checks, then explicitly authorized major upgrades of Astro and the adapter after the same-major audit failed.
- All dependency operations and runtime checks ran in Docker. The fresh copy contained only tracked template files; no symlinks or secret-like paths were copied. Generated tokens and build output stayed outside the workspace.
- Completion rerun on 2026-11-19: `bash scripts/verify.sh` — exit 0, all 30 regression tests pass. Both hadolint commands, Compose config --quiet and the authorized audit command also exited 0; the audit still reports only two moderate findings. Task staging guard passed for exactly 11 approved paths.
- Fresh-copy gate: `COMPOSE_PROJECT_NAME=landing-template-check bash scripts/verify.sh` — exit 0 (build, then tokens:generate and tokens:check). The token gate keeps its existing array/fail-fast behavior.
- All four authorized Additional Acceptance Checks — exit 0. Audit reports two moderate entries for one Typography dependency chain, documented with advisory and reachability rationale in AGENTS.md.
- `docker compose -p landing-template-check build` from the fresh copy — both images built successfully. Sharp generated a 97-byte PNG under UID 1000 after `npm ci --ignore-scripts`; a route regex compiled and matched through the adapter's scoped dependency.
- Preview image — HTTP 200 with expected page content, UID 1000. It emits a harmless missing source-pages warning because the image intentionally contains only built output and runtime packages.
- CSP output check — zero script/style tags, no inline style/event attributes, same-origin stylesheet exists. Generated Vercel static HTML equals dist/index.html. Every pre-existing vercel.json header remains byte-for-byte equivalent as a JSON value.
- Environmental workarounds: Docker's automatic address pool was exhausted, so an isolated task network used an explicitly non-overlapping private subnet. Host port 8080 was already occupied; preview was tested through `docker compose run` without publishing ports and HTTP fetch inside the container. Existing networks, containers and port owners were untouched. Static Compose inspection plus config --quiet confirms the configured localhost bindings.
- Official migration guides reviewed: https://docs.astro.build/en/guides/upgrade-to/v6/ and https://docs.astro.build/en/guides/upgrade-to/v7/ ; adapter peer dependency matches the upgraded Astro major. No template source changes were needed.

## Review Evidence

- Workspace base commit: `62557c1c4500b61147bffa8eeef8dc5239e32c1a`.
- Implementation snapshot: SHA-256 `e48cf6bcfeec0633943c9aa4d6e3e90932fbf6797a5e76d55acf4ea952f22305` of `git diff --binary HEAD -- <sorted Task Paths>` (11 changed implementation paths; WIP/lifecycle prose excluded).
- Result: NO_BLOCKING_FINDINGS. Reviewed approved paths against the amended contract, audit result, non-root runtime, fresh-copy gate, preserved headers, strict CSP output, and unchanged Tailwind/source/token-script invariants. No blocker/high remains; the documented moderate residual stays within the stated acceptance threshold.
- Scope: 11 modified implementation files, zero new implementation files, no new direct dependencies or scripts; only the authorized major upgrades and the externally justified scoped same-major transitive override extend the original dependency assumptions.
- Implementation committed as `cf19681` — "fix: harden landing template dependencies and Docker". Its approved-path diff against the recorded base has the identical SHA-256 above; the existing NO_BLOCKING_FINDINGS review is reused.

[Short summary](../short/15-11-26-workspace-landing-template-deps-and-docker.md)
