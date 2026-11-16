---
type: task
status: todo
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
---

# Landing Template: Patch Dependencies, Harden Docker, Add CSP

**Status:** todo, not started
**Last checked:** 2026-11-15

## Goal

Bring `_templates/landing/` to a state where the dependency audit reports no high or critical findings, the containers run on a supported Node line as a non-root user bound to localhost, the "prod" service is not misrepresented, and the deployed site ships a Content-Security-Policy.

## Context

Finding from the security review on 2026-11-15 (severity `high`). `npm audit` over the template lockfile: 1 critical, 12 high, 6 moderate; osv-scanner: 54 fixable advisories. For the pinned `astro` the fix is a **minor** release (`fixAvailable.isSemVerMajor: false`); `@astrojs/sitemap` also has a minor fix; `@astrojs/vercel` needs a major; the suggested "fix" for `@tailwindcss/typography` is a downgrade and is rejected. Advisories reachable in this template: dev-server local file read and error-page XSS, Vite serving files outside `server.fs.allow`, template-rendering XSS (`define:vars`, spread attributes, slot names) and build-time RCE in image optimisation (sharp/libvips). The dev server is reachable from the LAN because `compose.yml` publishes `3000:3000` on all interfaces and `astro.config.mjs` sets `host: true`. The base image `node:20-bookworm-slim` is end-of-life (endoflife.date, cycle 20); both Dockerfiles run as root; the `astro-prod` service runs `astro preview` while its comment promises "nginx + static files". A throwaway build showed `dist/` contains no inline `<script>` or `<style>`, so a strict CSP needs no exceptions. Telemetry is not disabled in containers.

Design constraint from the user: do not pin "current" version numbers in prose. Acceptance is expressed as audit results and support status computed at verification time, not as version literals; Dependabot (separate task) is the reminder mechanism.

Assumptions recorded instead of asked:

- `astro` and `@astrojs/sitemap` are bumped within their current major; `@astrojs/vercel` stays and is listed as an accepted residual with its advisory noted in `AGENTS.md` → Dependencies until a major upgrade task exists.
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
- No new dependencies; version updates only for existing direct dependencies within their current major.
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

1. In Docker, update `astro` and `@astrojs/sitemap` to the latest release within their majors, regenerate `package-lock.json`, re-run audit; record residuals (`@astrojs/vercel`, `@tailwindcss/typography`) in `AGENTS.md` → Dependencies.
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

- [ ] `npm audit --audit-level=high` over the template lockfile exits 0; remaining moderate findings are listed with reasons in `_templates/landing/AGENTS.md`.
- [ ] The base image major reported by `grep FROM _templates/landing/docker-files/*` is in `lts` status with a future `eol` in `https://endoflife.date/api/nodejs/<major>.json` on the completion date.
- [ ] Both Dockerfiles end with a non-root `USER`; `docker compose config` shows every published port bound to `127.0.0.1`; no service is named or described as production.
- [ ] From a fresh copy of the template, `docker compose run --rm astro-dev npm run build`, `tokens:generate`, then `tokens:check` all exit 0; `grep -c "<script" dist/index.html` is 0, so the added CSP holds without exceptions.
- [ ] `Verification` commands pass; the diff stays within `Change Budget`.
- [ ] The final implementation snapshot has recorded review evidence.

## Related

- Review origin: security review 2026-11-15, steps 4, 5, 11.
- Reminder mechanism: `15-11-26-workspace-github-repo-hygiene.md` (Dependabot).
- Source of the template: `docs/done/long/05-09-26-workspace-landing-template-tokens.md`.
