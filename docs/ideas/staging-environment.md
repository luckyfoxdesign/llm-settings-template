---
type: idea
status: draft
created: 2026-07-11
area:
  - security
  - deploy
related_docs:
  - docs/runbook-prod.md
---

# Staging Environment For Pre-Deploy Rehearsal

## Summary

Add a staging setup to the template so agents can rehearse a full deploy before touching prod. A `compose.staging.yml` (locally or on the VPS under a separate path/port) would run the prod build against a staging `.env`, letting agents build, start, migrate, and hit healthchecks end-to-end. Today the pre-deploy checks in `docs/runbook-prod.md` cover tests, lint, prod build, and compose validation, but nothing actually runs the prod stack before deploy.

## Open Questions

- Where does staging live: local-only, or a second compose project on the same VPS (separate ports, separate `.env.staging`)?
- Does staging get its own database with seed data, or a sanitized copy of prod?
- Should `/complete-task` (or the deploy flow) require a staging pass for tasks touching migrations, auth, or nginx config?
- Does nginx need a staging server block, or is staging accessed by port / local hosts entry only?
- What is the teardown rule so staging containers/volumes do not accumulate on the VPS?
