---
type: done_long
status: done
project: workspace
created: 2026-09-05
area:
  - templates
  - design-tokens
  - figma
related_docs:
  - docs/folder-rules.md
  - docs/product/architecture/verification-contract.md
---

**Commits:**
- workspace `c0fc4c0` — "feat: add landing sub-repo template with design-token pipeline"


# `_templates/landing/` — Astro + Tailwind sub-repo template with the design-token pipeline

**Status:** done
**Last checked:** 2026-09-06

## Goal

Add a second sub-repo template, `_templates/landing/`, that scaffolds a working
Astro 5 + Tailwind v4 landing repo already carrying the design-token pipeline
(generator, drift linter, Figma dev plugin, `@theme` token layer, Docker gate).
Copying it must yield a repo that builds and passes `tokens:check` with no
edits. The generic `_templates/sub-repo/` is unchanged and stays the default for
non-landing repos.

## Context

Task 1 of a 5-task sequence to make Figma/token work a repeatable part of a
workspace spun from this template. Later tasks: canonical `@theme` slot contract
+ conventions doc (2), `docs/runbook-design-tokens.md` + README/PROJECT_MAP
wiring (3), `scripts/new-landing.sh` spin-up script (4), Figma MCP read path in
the template's `AGENTS.md` (5).

The pipeline being ported already exists and was verified in another workspace:
`dev/luckyfox-workspace/landing/` — `scripts/generate-tokens.mjs` (reads the
installed `tailwindcss`, oklch→sRGB, writes DTCG; `--check` asserts control
values), `scripts/check-tokens.mjs` (`tokens:lint`, read-only drift linter with
`scripts/fixtures/*.json`), `figma-plugin/` (`manifest.json`, `code.js`,
`ui.html`; dev-mode, closed `networkAccess`, fixed `id`), and the `@theme`
block in `src/styles/global.css`. Its four completion records are
`dev/luckyfox-workspace/docs/done/short/04-09-26-landing-design-tokens-{a,a2,b,c}-*.md`
and the round-trip runbook is
`dev/luckyfox-workspace/docs/runbook-design-tokens.md`.

Assumptions recorded here rather than asked:

- Template pins the same exact dependency versions as the source
  (`astro 5.13.10`, `tailwindcss 4.1.13`, `@tailwindcss/vite 4.1.13`,
  `@astrojs/vercel 8.2.8`, `@astrojs/sitemap 3.7.0`,
  `@tailwindcss/typography 0.5.19`) and ships its `package-lock.json`, because
  `generate-tokens.mjs` control values (`242` scale tokens, `95` out-of-sRGB)
  are properties of Tailwind `4.1.13`'s palette. A later per-landing bump is an
  intended drift signal, covered by the runbook in task 3.
- `@astrojs/sitemap` and `@tailwindcss/typography` ship pinned but unconfigured
  on purpose: only `tailwindcss` fixes the control values, and regenerating the
  lock to drop two packages costs more risk than it removes. They are pre-pinned
  slots for the sitemap wiring (task 3) and prose content, not cruft.
- The template's `package.json` `name` is a static, valid placeholder-free
  string (e.g. `landing-template`); `new-landing.sh` (task 4) renames it. The
  copied `package-lock.json` carries that same name in both its root `name` and
  `packages[""].name`, so `npm ci` starts clean and the first install in a
  spun-up repo does not rewrite the lock.
- The template ships a minimal but real `@theme` layer; the canonical slot-name
  set and the conventions doc are task 2.
- `project: workspace` — `_templates/` is workspace scaffolding, and this
  workspace has no code repos.

## Non-goals

- Do not modify `_templates/sub-repo/` — it stays the generic stub for
  non-landing repos.
- Do not wire the new template into `README.md`, root `PROJECT_MAP.md`,
  `docs/`, or any spin-up script — discoverability and `new-landing.sh` are
  tasks 3 and 4.
- Do not finalize the canonical `@theme` slot-name set or write the token
  conventions doc — task 2.
- Do not port `luckyfox.design`-specific content: no i18n, content collections,
  middleware, SEO/analytics/password-gate/Tableau components, portfolio or
  project pages, `TZ_service_SEO.md`, `SECURITY.md`.
- Do not add a linter, formatter, or test framework to the template
  (`tokens:lint` is the ported drift linter, not a new tool).
- Do not change anything under `dev/luckyfox-workspace/` (the source).
- Do not change the Figma plugin beyond copying its three files verbatim: no
  `manifest.json` `id` change, no `networkAccess` opening, no publish config.
- Do not introduce TypeScript in template source beyond the one minimal
  `tsconfig.json` Astro needs; `.astro` frontmatter and `.mjs`/`.js` stay plain
  JS.
- Do not add `.npmrc`, `.env`, `.vercel/`, or key material to the template.
- Do not ship `.claude/` in the landing template. Settings and slash commands
  stay in `_templates/sub-repo/.claude/`; composing them into a new landing repo
  belongs to `new-landing.sh` (task 4), like the rest of the spin-up wiring.
  This keeps the file budget below and avoids two copies of the command set.

## Invariants

- After `cp -R _templates/landing/. <dir>/` into an empty directory,
  `docker compose run --rm --build astro-dev sh -c "npm ci && npm run build"`
  exits 0 and produces `<dir>/dist/`.
- In that copy, `npm run tokens:generate` writes
  `tokens/tailwind-colors.generated.json` and `tokens/semantic.generated.json`,
  and `npm run tokens:check` exits 0 immediately afterward.
- `EXPECTED.semanticTokens` in the ported `generate-tokens.mjs` equals the
  number of `--color-*` declarations in the template's `@theme` block; the
  Tailwind palette control values (`242`, `95`) are unchanged from the source.
- `figma-plugin/` never appears in `dist/`; `.vercelignore` excludes
  `/figma-plugin` and `/scripts`.
- `figma-plugin/manifest.json` is valid JSON, keeps a fixed non-empty `id`, and
  declares `networkAccess` with no allowed domains.
- `node --check` passes on `scripts/generate-tokens.mjs`,
  `scripts/check-tokens.mjs`, and `figma-plugin/code.js`.
- `_templates/sub-repo/` is byte-identical to its pre-task state; no file
  outside `_templates/landing/` is added or modified.
- This repo's hot-context files (`CLAUDE.md`, `AGENTS.md`, `PROJECT_MAP.md`)
  stay within the `docs/folder-rules.md` budgets (unchanged by this task).
- `_templates/landing/{CLAUDE,AGENTS,PROJECT_MAP}.md` use the same
  `[project-name]` / `[repo-name]` placeholder convention as
  `_templates/sub-repo/`.
- `_templates/landing/.claude/` does not exist.
- The template's `.gitignore` and `.vercelignore` carry no entry naming a file
  the template does not ship (`SECURITY.md`, `TZ_service_SEO.md`, `/drafts`,
  `.svelte-kit/`).

## Change Budget

- At most 30 new files, all under `_templates/landing/`.
- Zero files modified or deleted outside `_templates/landing/`.
- Zero new dependencies in this workspace repo. The template's own
  `package.json` mirrors the source repo's pinned set exactly and adds nothing.
- No new workspace scripts, validators, or abstraction layers.

## Verification

```bash
# 1. workspace gate — strict validators (frontmatter, contract, budgets, flow)
bash scripts/verify.sh

# 2. static checks on the ported files
node --check _templates/landing/scripts/generate-tokens.mjs
node --check _templates/landing/scripts/check-tokens.mjs
node --check _templates/landing/figma-plugin/code.js
python3 -c "import json; json.load(open('_templates/landing/figma-plugin/manifest.json'))"

# 3. nothing outside the new directory changed
git status --porcelain | grep -v '^?? _templates/landing/' | grep . && echo "FAIL: changes outside _templates/landing/" && exit 1 || echo "OK: additive only"
git diff --exit-code -- _templates/sub-repo

# 4. smoke: instantiate to a scratch dir and run the real repo gate in Docker
# scratch dir via mktemp; `rm -rf` is denied in this workspace, so cleanup is `rm -r`
SMOKE="$(mktemp -d /tmp/landing-tmpl-smoke.XXXXXX)"
cp -R _templates/landing/. "$SMOKE/"
(cd "$SMOKE" && docker compose run --rm --build astro-dev sh -c "npm ci && npm run tokens:generate && npm run tokens:check && npm run build")
test -f "$SMOKE/tokens/semantic.generated.json"
test -f "$SMOKE/tokens/tailwind-colors.generated.json"
test ! -e "$SMOKE/dist/figma-plugin"
(cd "$SMOKE" && docker compose run --rm astro-dev sh -c "npm run tokens:lint"; test $? -eq 0 -o $? -eq 1)
rm -r "$SMOKE"
docker image prune -f --filter "dangling=true"

# 5. no secret-like files shipped, no agent scaffolding duplicated
test -z "$(find _templates/landing -name '.npmrc' -o -name '.env' -o -name '*.pem' -o -name '*.key')" && echo "OK: no secret-like files"
test ! -e _templates/landing/.claude && echo "OK: no .claude in landing template"
grep -nE 'SECURITY\.md|TZ_service_SEO\.md|/drafts|\.svelte-kit' _templates/landing/.gitignore _templates/landing/.vercelignore && echo "FAIL: stale source-specific ignore entry" && exit 1 || echo "OK: ignores trimmed"
```

## Implementation Steps

1. Create `_templates/landing/` and copy the Astro shell from
   `dev/luckyfox-workspace/landing/`: `package.json` (static `name`, keep exact
   dep pins), `package-lock.json`, `tsconfig.json`, `compose.yml`,
   `docker-files/Dockerfile.dev`, `docker-files/Dockerfile.prod`,
   `.dockerignore`, `.gitignore`, `.vercelignore`. Do not copy `.npmrc`; the
   lock resolves everything from `registry.npmjs.org`, so `npm ci` needs no
   registry config.
2. Rename the package in both files, not just one: set `package.json` `name`,
   and the same string in `package-lock.json` at the root `name` and at
   `packages[""].name`. A lock still naming the source package makes the first
   `npm install` in a spun-up repo rewrite it.
3. Trim the copied ignore files to what the template actually ships. Drop
   `SECURITY.md`, `TZ_service_SEO.md`, `/drafts` from `.gitignore`, and those
   plus `.svelte-kit/` from `.vercelignore`. Keep `/figma-plugin`, `/scripts`,
   `AGENTS.md`, `PROJECT_MAP.md`, and the build/env entries.
4. Trim `astro.config.mjs` to the essentials: static output, Vercel static
   adapter, Tailwind vite plugin, dev server `host: true` port `3000`. Drop the
   sitemap frontmatter filter, i18n, and `site:`-specific config; add a
   `[project-name]` placeholder comment where the real `site` URL goes. Trim
   `vercel.json` to a minimal static config.
5. Port `scripts/generate-tokens.mjs`, `scripts/check-tokens.mjs`,
   `scripts/fixtures/tokens-clean.json`, `scripts/fixtures/tokens-drift.json`
   verbatim; set `EXPECTED.semanticTokens` to the template `@theme` count; keep
   the `242` / `95` Tailwind control values.
6. Port `figma-plugin/manifest.json`, `figma-plugin/code.js`,
   `figma-plugin/ui.html` verbatim.
7. Write `src/styles/global.css` with a Tailwind entry and a minimal documented
   `@theme` (the three 90s link colors as literals + a small semantic set, each
   with a `/* layout source -> Tailwind name -- meaning */` comment, matching
   the source A2 style). Write `src/layouts/BaseLayout.astro` and
   `src/pages/index.astro` that reference at least two `@theme` tokens so the
   build exercises them.
8. Write `_templates/landing/{CLAUDE,AGENTS,PROJECT_MAP}.md` from the
   `_templates/sub-repo/` versions plus Astro/token specifics: fill the
   `AGENTS.md` verify-gate table (build required; `tokens:check` as an extra
   required gate), document `tokens/`, `figma-plugin/`, and the `tokens:*`
   scripts in `PROJECT_MAP.md`, keep `[project-name]` / `[repo-name]`
   placeholders, stay within the hot-context budgets. Note in `CLAUDE.md` that
   `.claude/` comes from the spin-up script, not from this template.
9. Write `scripts/verify.sh` (gates: `build` required via
   `docker compose run --rm astro-dev npm run build`, then `tokens:check`
   required) and a `scripts/update-project-map.sh` stub with explicit TODOs.
10. Add `tokens/.gitkeep`.
11. Run every command in `Verification`; record output.

## Done When

- [x] Every command in `Verification` passes; the smoke build and
      `tokens:check` exit 0 in the instantiated copy.
- [x] A fresh `cp -R _templates/landing/. <dir>/` yields a repo that builds in
      Docker with no edits.
- [x] `EXPECTED.semanticTokens` matches the `@theme` `--color-*` count;
      `242` / `95` control values unchanged.
- [x] `figma-plugin/` is absent from `dist/`; `manifest.json` is valid JSON
      with a fixed `id` and closed `networkAccess`; `node --check` passes on the
      two `.mjs` files and `code.js`.
- [x] `git diff --exit-code -- _templates/sub-repo` is clean; no files touched
      outside `_templates/landing/`.
- [x] No `.npmrc` / `.env` / key material among the new files; no
      `_templates/landing/.claude/`.
- [x] `package.json` and `package-lock.json` agree on the package name; the
      ignore files name no file the template does not ship.
- [x] The diff stays within `Change Budget`.
- [x] No confirmed `blocker`/`high` findings from one `/review-task` pass.
- [x] At most one reviewer pass has run.

## Related

- Sequence: task 1 of 5. Next — `@theme` slot contract + conventions doc (2),
  runbook + README/PROJECT_MAP wiring (3), `scripts/new-landing.sh` (4), Figma
  MCP read path in template `AGENTS.md` (5).
- Source pipeline: `dev/luckyfox-workspace/landing/` and its four records
  `dev/luckyfox-workspace/docs/done/short/04-09-26-landing-design-tokens-{a,a2,b,c}-*.md`.
- Source runbook: `dev/luckyfox-workspace/docs/runbook-design-tokens.md`.
- Template convention: `_templates/sub-repo/`, `docs/folder-rules.md` → Project
  Maps.
- Contract shape: `docs/product/architecture/verification-contract.md`.

## Verification Evidence

All commands run on 2026-09-06 from the workspace root. Node runs only in
containers — there is no host Node — so `node --check` ran in
`node:20-bookworm-slim` instead of on the host. Same check, containerised.

**1. Workspace gate**

```text
bash scripts/verify.sh
→ context-budget OK, flow-duplication OK (11 rules), docs-frontmatter OK,
  task-contract OK (2 task files) → "OK: all workspace gates passed"
```

**2. Static checks on the ported files**

```text
docker run --rm -v "$PWD/_templates/landing:/w:ro" -w /w node:20-bookworm-slim
  node --check scripts/generate-tokens.mjs   → OK
  node --check scripts/check-tokens.mjs      → OK
  node --check figma-plugin/code.js          → OK
python3 -c "json.load(open('.../figma-plugin/manifest.json'))"
  → OK: valid JSON; id='luckyfox-design-tokens';
    networkAccess={'allowedDomains': ['none']}
```

**3. Additive only**

```text
git status --porcelain | grep -v '^?? _templates/landing/' | grep .
  → no output → "OK: additive only"
git diff --exit-code -- _templates/sub-repo   → clean
```

**4. Docker smoke on an instantiated copy**

```text
SMOKE=$(mktemp -d /tmp/landing-tmpl-smoke.XXXXXX); cp -R _templates/landing/. "$SMOKE/"
docker compose run --rm --build astro-dev sh -c \
  "npm ci && npm run tokens:generate && npm run tokens:check && npm run build"
  → npm ci: added 381 packages
  → tokens:generate — tailwind 4.1.13
      tokens/tailwind-colors.generated.json: 242 scale tokens + black/white,
      out of sRGB — 95
      tokens/semantic.generated.json: 9 semantic tokens
  → tokens:check — ok (tailwind 4.1.13, 242 scale, 95 out of sRGB, 9 semantic)
  → astro build: output "static", adapter @astrojs/vercel,
      1 page built in 766ms → dist/{index.html,_astro} → exit 0

test -f "$SMOKE/tokens/semantic.generated.json"         → OK
test -f "$SMOKE/tokens/tailwind-colors.generated.json"  → OK
test ! -e "$SMOKE/dist/figma-plugin"                    → OK
npm run tokens:lint (no colors.used.json present)       → exit 0 (admissible)
```

Fixtures exercised separately, since `Verification` only runs the bare linter:

```text
tokens:lint --fixture scripts/fixtures/tokens-clean.json → exit 0 (expected 0)
tokens:lint --fixture scripts/fixtures/tokens-drift.json → exit 1 (expected 1)
```

**5. No secret-like files, no duplicated scaffolding, ignores trimmed**

```text
find _templates/landing -name '.npmrc' -o -name '.env' -o -name '*.pem' -o -name '*.key'
  → empty → "OK: no secret-like files"
test ! -e _templates/landing/.claude → OK
grep -nE 'SECURITY\.md|TZ_service_SEO\.md|/drafts|\.svelte-kit' .gitignore .vercelignore
  → no match → "OK: ignores trimmed"
```

**Change Budget**

27 files, all under `_templates/landing/`; budget is 30. Zero files modified or
deleted outside the directory. Zero new workspace dependencies; the template's
`package.json` mirrors the source pins exactly.

**Template doc budgets**

```text
CLAUDE.md       51/60 lines,  2289/3072 bytes
AGENTS.md      132/180 lines, 6634/8192 bytes
PROJECT_MAP.md 109/200 lines, 4815/7168 bytes
```

**`@theme` comment accuracy**

Each `/* hex -> Tailwind name */` comment was checked against the generated
palette rather than assumed: `#404040→neutral-700`, `#737373→neutral-500`,
`#fafafa→neutral-50`, `#e5e5e5→neutral-200`, `#ffffff→white`, `#000000→black`.
All six correct. (`zinc-50` is byte-identical to `neutral-50` in Tailwind
4.1.13; `neutral` is the right family per the source convention that pure greys
use the family with no undertone.)

## Deviations From The Implementation Steps

The frozen sections were not touched. These are choices inside the non-frozen
`Implementation Steps`:

1. `node --check` ran in a container, not on the host — Docker-first policy,
   no host Node exists.
2. `scripts/fixtures/tokens-clean.json` — one entry adapted:
   `semantic/surface-projects` → `semantic/surface-raised`, alias
   `tailwind/yellow/50` → `tailwind/neutral/50`, value `#fefce8` → `#fafafa`.
   A verbatim copy would reference a token the template's `@theme` does not
   declare, so the "clean" fixture would have exited 1 and stopped being a
   clean fixture. `tokens-drift.json` is byte-verbatim and still exits 1.
3. `vercel.json` dropped `installCommand: npm install`, and `.vercelignore` no
   longer excludes `package-lock.json`, so Vercel installs from the lock.
   The source did the opposite; reproducible installs matter more in a template.
4. The DTCG extension namespace `design.luckyfox.tokens` was kept verbatim in
   both scripts. It cannot be renamed here: the frozen non-goal forbids editing
   the Figma plugin, and `figma-plugin/code.js` writes exactly that key, so
   renaming it only in the scripts would break the round trip. A consistent
   rename across all three files belongs to task 2 or 4.
5. Dropped the `image.service` block from `astro.config.mjs` and the legacy
   `@tailwind base/components/utilities` lines from `global.css`; the build
   confirms Tailwind v4 does not need them alongside `@import "tailwindcss"`.

## Review Pass

One pass, evidence-only, against the frozen contract: `NO_BLOCKING_FINDINGS`.
No code was changed by the review.

One `medium` finding, routed out of this task rather than fixed in it: a freshly
copied template fails `npm run tokens:check` (exit 1) until `tokens:generate`
has run once, because `tokens/` ships empty apart from `.gitkeep`. By extension
the template's own `scripts/verify.sh` fails its `tokens` gate on a fresh copy.
Verified directly:

```text
cp -R _templates/landing/. "$FRESH/" && npm ci && npm run tokens:check
→ generate-tokens: control values did not match:
  - /app/tokens/*.generated.json diverges from generation — run npm run tokens:generate
→ exit 1
```

This violates no invariant — invariant 2 scopes `tokens:check` to *after*
`tokens:generate`, and that passes — and the error names its own fix. Closing it
means either shipping pre-generated tokens (stale on the first Tailwind bump) or
running `tokens:generate` during spin-up, which is task 4's `new-landing.sh`,
with the round trip documented by task 3's runbook. Both are explicit non-goals
here. Recorded as an input to tasks 3 and 4.

[Short summary](../short/05-09-26-workspace-landing-template-tokens.md)
