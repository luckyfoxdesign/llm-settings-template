# [repo-name] Project Map
<!-- Repo-local map is the source of truth for this repo internals. -->
<!-- Workspace ../PROJECT_MAP.md aggregates repo maps and should not duplicate this detail. -->

Astro 5 + Tailwind v4 static landing with a design-token pipeline.

## Map contract

- Keep generated facts inside `generated` block.
- Keep short repo-local notes inside `manual` block.
- Store long architecture decisions in workspace `../docs/product/architecture/`.
- Update this map when repo structure, entrypoints, commands, or configs change.
- Keep the repo-local update script at `scripts/update-project-map.sh`.

<!-- generated:start -->
## Generated Structure

```text
[repo-name]/
├── AGENTS.md
├── CLAUDE.md
├── PROJECT_MAP.md
├── astro.config.mjs
├── compose.yml
├── vercel.json
├── docker-files/
│   ├── Dockerfile.dev
│   └── Dockerfile.prod
├── figma-plugin/            # dev-mode Figma plugin, reads tokens/
│   ├── manifest.json
│   ├── code.js
│   └── ui.html
├── scripts/
│   ├── generate-tokens.mjs
│   ├── check-tokens.mjs
│   ├── fixtures/            # tokens-clean.json, tokens-drift.json
│   ├── update-project-map.sh
│   └── verify.sh
├── src/
│   ├── layouts/BaseLayout.astro
│   ├── pages/index.astro
│   └── styles/global.css    # @theme — source of truth for semantic colors
└── tokens/                  # generated DTCG token files
```

## Commands

```bash
bash scripts/verify.sh                                       # single gate: build, then tokens:check
docker compose up astro-dev                                  # dev server on :3000
docker compose run --rm astro-dev npm run build              # static build to dist/
docker compose run --rm astro-dev npm run tokens:generate    # rebuild tokens/
docker compose run --rm astro-dev npm run tokens:check       # control values + drift vs generated
docker compose run --rm astro-dev npm run tokens:lint        # design-vs-code drift, read-only
```

## Entrypoints

- `src/pages/index.astro` — `/`.
- `src/layouts/BaseLayout.astro` — shared document shell.

## Config Files

- `astro.config.mjs` — static output, Vercel adapter, Tailwind vite plugin, dev server on port 3000. Set `site` before the first deploy.
- `vercel.json` — response headers for the deployed site.
- `tsconfig.json` — editor support only; source stays plain JS.
- `compose.yml` — Docker services.
- `.vercelignore` — keeps `/scripts` and `/figma-plugin` out of the deploy.
- `scripts/verify.sh` — single executable gate; exits non-zero on the first failing gate.
- `scripts/update-project-map.sh` — updates this map's generated block.

## Docker Services

- `astro-dev` — `docker-files/Dockerfile.dev`, port 3000, source bind-mounted.
- `astro-prod` — `docker-files/Dockerfile.prod`, static build served on port 8080.

## Package Scripts

- `dev`, `build`, `preview`, `astro` — standard Astro scripts.
- `tokens:generate` — `node scripts/generate-tokens.mjs`.
- `tokens:check` — `node scripts/generate-tokens.mjs --check`.
- `tokens:lint` — `node scripts/check-tokens.mjs`.

## Notable Directories

- `src/styles/` — `global.css` holds the `@theme` block; everything else derives from it.
- `tokens/` — generated DTCG files: `tailwind-colors.generated.json` (palette primitives), `semantic.generated.json` (the `@theme` layer). Never hand-edited.
- `figma-plugin/` — dev-mode plugin, fixed `id`, closed `networkAccess`, excluded from the deploy.
- `scripts/fixtures/` — linter fixtures: `tokens-clean.json` (exit 0), `tokens-drift.json` (exit 1).
<!-- generated:end -->

<!-- manual:start -->
## Architecture Notes

- Token flow is one-directional: `@theme` in `global.css` → `tokens/*.generated.json` → Figma. The design file is a consumer, never a source.
- `tokens:check` is a real gate, not a formality: it re-derives both files and compares them, so a stale `tokens/` fails the build.

## Conventions

- Semantic colors as literal hex in `@theme`, one declaration per line.
- Every `--color-*` carries a `/* design source -> Tailwind name -- meaning */` comment.
- Changing the token count means updating `EXPECTED.semanticTokens` in `scripts/generate-tokens.mjs`.

## Known Sharp Edges

- The Tailwind control values in `scripts/generate-tokens.mjs` are tied to the pinned `tailwindcss`. A version bump moves them; confirm new numbers before updating.
- `compose.yml` mounts an anonymous volume over `/app/node_modules`, so a dependency change needs `docker compose run --rm --build astro-dev ...` to take effect.
- `tokens:lint` exits 0 when `tokens/colors.used.json` is missing — an unmarked design file looks clean.
<!-- manual:end -->
