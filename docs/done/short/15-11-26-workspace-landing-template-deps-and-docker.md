---
type: done_short
status: done
phase: completed
project: workspace
created: 2026-11-19
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

**Commits:**
- workspace `cf19681` — "fix: harden landing template dependencies and Docker"

## What Changed

- Updated existing Astro ecosystem dependencies and patched the adapter's routing dependency with a scoped override; Tailwind versions remain unchanged.
- Hardened Docker with a supported LTS base, non-root execution, disabled telemetry/install scripts and localhost bindings; renamed the service to astro-preview.
- Added strict CSP, preserved existing headers and enabled token generation before the fresh-template check.

## Verification Evidence

- Workspace gate passed, including all 30 regression tests; both hadolint checks, Compose validation and the staged-path guard passed.
- Audit passed at high severity: zero high/critical, two documented moderate findings in the Typography chain.
- Fresh-copy build and token generation/check passed; sharp works and preview returns HTTP 200 as UID 1000. Built HTML contains no inline script/style content.
- Review: NO_BLOCKING_FINDINGS, reused unchanged snapshot; implementation commit cf19681.

---
[Full plan](../long/15-11-26-workspace-landing-template-deps-and-docker.md)
