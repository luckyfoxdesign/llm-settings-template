---
type: done_short
status: done
project: workspace
created: 2026-09-06
area:
  - templates
  - design-tokens
  - figma
related_docs:
  - docs/folder-rules.md
  - docs/product/architecture/verification-contract.md
---

# `_templates/landing/` — Astro + Tailwind sub-repo template with the design-token pipeline

**Commits:**
- workspace `c0fc4c0` — "feat: add landing sub-repo template with design-token pipeline"

## What Changed

Added `_templates/landing/` — 27 files, a second sub-repo template alongside the
generic `_templates/sub-repo/`, which is untouched and stays the default for
non-landing repos.

- **Ported verbatim** from `dev/luckyfox-workspace/landing/`:
  `scripts/check-tokens.mjs`, `scripts/fixtures/tokens-drift.json`, the three
  `figma-plugin/` files, `tsconfig.json`, `compose.yml`, both
  `docker-files/Dockerfile.*`.
- **Ported with edits:** `package.json` + `package-lock.json` renamed to
  `landing-template` in both files, including `packages[""].name`, so the first
  install in a spun-up repo does not rewrite the lock;
  `scripts/generate-tokens.mjs` with `EXPECTED.semanticTokens: 9` and the
  Tailwind control values `242` / `95` unchanged; `.gitignore`, `.vercelignore`,
  `.dockerignore` trimmed of entries naming files the template does not ship;
  `astro.config.mjs` and `vercel.json` reduced to a minimal static config.
- **Written for the template:** `src/styles/global.css` with a documented
  `@theme` of 9 semantic colors (three 90s link colors plus `page`, `ink`,
  `ink-heading`, `ink-muted`, `surface-raised`, `edge`), each carrying a
  `/* design source -> Tailwind name -- meaning */` comment;
  `BaseLayout.astro` and `index.astro`, which exercise six of those tokens at
  build time; `CLAUDE.md`, `AGENTS.md`, `PROJECT_MAP.md` with
  `[project-name]` / `[repo-name]` placeholders and the verify-gate table filled
  in; `scripts/verify.sh` with `build` and `tokens` as required gates; a
  `scripts/update-project-map.sh` TODO stub; `tokens/.gitkeep`.
- **Deliberately excluded:** `.claude/` — settings and slash commands stay in
  `_templates/sub-repo/.claude/` and are composed in by the spin-up script
  (task 4), which keeps the file budget honest and avoids a second copy of the
  command set.

## Verification Evidence

- `bash scripts/verify.sh` → `OK: all workspace gates passed`.
- Docker smoke on a `mktemp -d` copy:
  `npm ci && tokens:generate && tokens:check && build` → exit 0.
  `tokens:generate` reported 242 scale tokens, 95 out of sRGB, 9 semantic;
  `tokens:check — ok`; `astro build` produced 1 page in `dist/`.
- `node --check` passed on both `.mjs` files and `figma-plugin/code.js` (run in
  `node:20-bookworm-slim`; there is no host Node). `manifest.json` is valid JSON
  with `id: luckyfox-design-tokens` and `networkAccess.allowedDomains: ["none"]`.
- `dist/figma-plugin` absent; `tokens:lint` exit 0 with no export present;
  fixtures exit 0 (clean) and 1 (drift).
- `git diff --exit-code -- _templates/sub-repo` clean; `git status --porcelain`
  showed only `?? _templates/landing/`.
- No `.npmrc` / `.env` / key material; no `_templates/landing/.claude/`.
- Change Budget: 27 files of 30, zero outside the directory, zero new workspace
  dependencies.
- Review pass: one, evidence-only → `NO_BLOCKING_FINDINGS`.

Known sharp edge, routed to tasks 3 and 4 rather than fixed here: a freshly
copied template fails `tokens:check` until `tokens:generate` has run once,
because `tokens/` ships empty. No invariant covers it and the error message
names its own fix; wiring spin-up and writing the runbook are explicit non-goals
of this task. Full detail in the long record.

---
[Full plan](../long/05-09-26-workspace-landing-template-tokens.md)
