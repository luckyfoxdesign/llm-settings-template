---
type: task
status: todo
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
---

# Template Hygiene: Placeholders, Private Paths, Runbook Defaults, Plugin Origin Check

**Status:** todo, not started
**Last checked:** 2026-11-15

## Goal

Remove low-severity residue found in the security review: personal identifiers and private workspace paths in public files, unsafe-by-default patterns in the production runbook, missing data-minimisation wording for external research, and the missing origin check in the Figma plugin UI.

## Context

Findings from the security review on 2026-11-15 (severity `low`, grouped into one task). `git grep` on 2026-11-15: `luckyfox` appears in `_templates/landing/figma-plugin/manifest.json` (`name`, `id`), `code.js` (`PALETTE_INDEX_STORAGE_KEY`, extension namespace), `generate-tokens.mjs` (`EXT`), `check-tokens.mjs`; the private path `dev/luckyfox-workspace/…` appears 9 times in `docs/done/long|short/05-09-26-workspace-landing-template-tokens.md`. `docs/runbook-prod.md` shows `set -a; . ./.env; set +a` in the backup example, leaves the server baseline table optional, and does not require a read-only deploy key for the server-side `git pull`. `ui.html` handles `window.onmessage` without checking `event.origin`. `AGENTS.md` → Optional External Research does not state that private code, task text, or logs never go into Exa queries (the skill does). `vercel.json` sets HSTS `preload`, an irreversible commitment that template adopters are not warned about.

Assumptions recorded instead of asked:

- Identifiers become `[project-name]`-style placeholders consistent with the rest of the template (`[project-name]-design-tokens`, `design.[project-name].tokens`); `check-tokens.mjs` reads the namespace from the generated file's `$extensions` keys instead of a constant where that keeps the script simple.
- Historical done records are edited only to replace the private path with a neutral phrase ("the source workspace"); no other content changes.
- The HSTS note goes into `_templates/landing/AGENTS.md` → Security (JSON has no comments).
- The `AGENTS.md` addition is one line; the budget check is part of verification.

## Non-goals

- Do not change plugin behaviour beyond the origin check; `networkAccess` stays `none`.
- Do not change deploy or rollback steps in the runbook, only the defaults and prerequisites it states.
- Do not touch `vercel.json` headers (CSP is in `landing-template-deps-and-docker`).
- Do not rename fixtures in `_templates/landing/scripts/fixtures/`.

## Invariants

- `tokens:generate` followed by `tokens:check` and `tokens:lint --fixture scripts/fixtures/tokens-clean.json` / `tokens-drift.json` keep their exit codes (0 / 0 / 1).
- `AGENTS.md` stays within 180 lines / 8192 bytes.
- `scripts/check-no-flow-duplication.sh` passes (done records and templates are not instruction owners).
- `git grep -n 'luckyfox\|dev/luckyfox-workspace'` returns nothing outside git history.

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

These commands are outside the Verification allowlist. Review them and obtain
explicit user authorization before running them; do not execute them automatically
as part of task completion. They remain required acceptance checks for this task.

```bash
git grep -n 'luckyfox'
```

## Done When

- [ ] `git grep -n 'luckyfox'` returns no matches in tracked files.
- [ ] In a fresh copy of the template, `tokens:generate`, `tokens:check`, and both fixture lint runs keep exit codes 0 / 0 / 0 / 1.
- [ ] The runbook states the read-only deploy key, the `--env-file` form, and the baseline prerequisite; `ui.html` ignores messages from unexpected origins.
- [ ] `Verification` commands pass; `AGENTS.md` within budget; the diff stays within `Change Budget`.
- [ ] The final implementation snapshot has recorded review evidence.

## Related

- Review origin: security review 2026-11-15, steps 8, 10, 12, 13.
- Related tasks: `15-11-26-workspace-landing-template-deps-and-docker.md`.
