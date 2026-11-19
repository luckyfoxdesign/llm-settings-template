# [project-name]-[repo-name] — Agent Instructions

Astro + Tailwind v4 landing in workspace `dev/[project-name]`. Product docs, backlog, and task flow live in `../docs/`, `../AGENTS.md`, and `../CLAUDE.md`. Before work, explicitly read `../AGENTS.md` and `../CLAUDE.md`; parent workspace discovery is not guaranteed across Git roots. This file contains repo-local rules.

## Source Of Truth

- Workspace `../AGENTS.md` and `../CLAUDE.md`: shared rules and multi-repo task flow.
- Workspace `../docs/folder-rules.md`: docs and task rules.
- Local `PROJECT_MAP.md`: repo structure, entrypoints, commands, configs.
- This file: repo-local architecture, verification, dependency rules.

Do not scan the whole repo when `PROJECT_MAP.md` gives a clear entrypoint.

## Project Map Contract

`PROJECT_MAP.md` is the source of truth for this repo internals. Workspace `../PROJECT_MAP.md` only aggregates repo maps.

Repo-local map should include:

- entrypoints under `src/pages/`;
- key directories;
- configs;
- Docker services;
- package scripts, including `tokens:*`;
- the token pipeline: `@theme` → `tokens/` → `figma-plugin/`.

Use protected blocks:

```markdown
<!-- generated:start -->
... generated facts ...
<!-- generated:end -->

<!-- manual:start -->
... short notes ...
<!-- manual:end -->
```

Scripts may edit only the `generated` block. Long architecture decisions live in `../docs/product/architecture/`.

`scripts/update-project-map.sh` is repo-specific. It updates only this repo's `PROJECT_MAP.md`. Until implemented, it stays an explicit TODO stub.

## Task Lifecycle

Use `/create-task`, `/start-task`, `/review-task`, and `/complete-task` through the procedures in workspace `../docs/workflows/task-lifecycle.md`.

## Architecture Rules

- Static output only. No SSR, no server endpoints, no runtime data fetching.
- No TypeScript in source: `.astro` frontmatter and `.mjs`/`.js` stay plain JS. `tsconfig.json` exists for editor support only.
- Semantic colors are declared once, in the `@theme` block of `src/styles/global.css`, as literal hex. Never `var()` inside `@theme`: the generator copies the raw string into DTCG and a variable reference breaks the Figma import.
- One `--color-*` declaration per line. The generator fails on multi-line or nested declarations rather than silently skipping them.
- Name link tokens `--color-link-default`, not `--color-link`: Tailwind turns every `--color-*` into a utility, and a `text-link` utility would land in `@layer utilities` and override `a:visited` / `a:hover` from `@layer base`.
- Files under `tokens/` are generated. Never hand-edit them; regenerate instead.
- `figma-plugin/` is dev-mode only: fixed `id`, `networkAccess` with no allowed domains, excluded from the deploy via `.vercelignore`.

## Design Token Pipeline

```bash
docker compose run --rm astro-dev npm run tokens:generate  # @theme + tailwindcss -> tokens/
docker compose run --rm astro-dev npm run tokens:check     # control values + drift vs generated files
docker compose run --rm astro-dev npm run tokens:lint      # design-vs-code drift, read-only
```

- `tokens:generate` writes `tokens/tailwind-colors.generated.json` (palette primitives from the installed `tailwindcss`) and `tokens/semantic.generated.json` (the `@theme` layer).
- `tokens:check` asserts the control values in `scripts/generate-tokens.mjs` and that the committed files match a fresh generation. Changing the `@theme` token count without updating `EXPECTED.semanticTokens` fails here, by design.
- The Tailwind control values (`scaleTokens`, `outOfSrgb`) are properties of the pinned `tailwindcss` version. A dependency bump moving them is a real signal, not noise: confirm the new numbers before updating them.
- `tokens:lint` compares `@theme` against `tokens/colors.used.json` exported by the Figma plugin. Exit 0 when the export is absent or the sets agree; exit 1 when the design uses a token the code does not declare. Fixtures in `scripts/fixtures/` cover both cases.

## Testing

No test framework. The build is the test: `docker compose run --rm astro-dev npm run build`.

## Code Quality

No linter or formatter configured. Do not add one as a side effect of an unrelated task.

## Verification Gates

`scripts/verify.sh` is this repo's single gate. It runs the gates below in order and exits non-zero on the first failure. A task stops on that exit code, not on a judgement about the code.

| Gate | Command | Required |
|---|---|---|
| build | `docker compose run --rm astro-dev npm run build` | yes |
| tokens | `docker compose run --rm astro-dev sh -c "npm run tokens:generate && npm run tokens:check"` | yes (fresh template) |
| lint | — | no |
| test | — | no |
| typecheck | — | no |

Optional gate (outside `scripts/verify.sh`; promote explicitly if required):

| Gate | Command | Required |
|---|---|---|
| security | `bash ../scripts/check-security.sh . --strict` | no |

Protocol: workspace `../docs/product/architecture/verification-contract.md`. Do not restate it here.

## Change Budget

Default fuse for a task in this repo, unless the task file sets its own:

- at most 5 production files;
- no new dependencies;
- new abstractions only when needed by the task, within its explicit budget.

Fix the budget before implementation, not after.

## Dependencies

Dependencies are pinned to exact versions, not ranges: the `tokens:check` control values depend on the installed `tailwindcss`. When adding or updating a dependency:

1. Check the current version on the official registry.
2. Pin the exact version and commit the updated `package-lock.json`.
3. Check compatibility between Astro, adapters, and Tailwind plugins.
4. For major upgrades, review breaking changes first.
5. Re-run `tokens:check` and confirm any changed control values before updating them.

### Security update constraints

- Astro and the Vercel adapter are upgraded together; check the adapter's Astro peer range and the official migration guides before a major upgrade.
- The scoped `@vercel/routing-utils` override uses patched `path-to-regexp` within the same major: the upstream package pins a vulnerable release exactly. Keep the override until the upstream dependency is patched, then re-run the audit before removing it. Advisory: [GHSA-9wv6-86v2-598j](https://github.com/advisories/GHSA-9wv6-86v2-598j).
- Moderate residual: typography depends on vulnerable `postcss-selector-parser` ([GHSA-rj75-hqrm-r3gf](https://github.com/advisories/GHSA-rj75-hqrm-r3gf), CPU exhaustion on crafted selectors). This template processes trusted CSS at build time; typography stays pinned to preserve the token pipeline. The audit's suggested downgrade is rejected. The high-severity audit gate remains required.

## Security

Full policy: workspace `../AGENTS.md` → Security. Repo-local baseline:

- Never hardcode secrets in code, configs, or compose files; new env variables go to `.env.example` with placeholder values.
- Never print or log secret values (`echo $SECRET`, `env`, `docker compose config` without `--quiet`).
- Escape or validate any external data rendered into HTML; never interpolate it into inline scripts.
- Keep every response header in `vercel.json`, including the strict Content-Security-Policy; avoid inline scripts/styles and external resources that it blocks.
- Keep the Figma plugin's `networkAccess` closed; opening it needs an explicit task.
- Containers: run as non-root, disable Astro telemetry, no `privileged: true`, no host network, publish only required ports bound to `127.0.0.1`.
- `host: true` is needed inside Docker; dev and preview servers must remain localhost-only on the host. Never expose them to the LAN.
- `astro-preview` is for local inspection; production serves static output through Vercel.

## Local Permissions

- Do not read `.env` or `.env.*`.
- Do not read private key material: `.ssh/`, `id_rsa*`, `*.pem`, `*.key`.
- `.env.example` may be read and edited.
- Never run `rm -rf`, `git push --force`, `git reset --hard`, `chmod 777`, `sudo rm`, or `curl/wget ... | bash`.
- Use Docker for local verification.
- After Docker builds, clean only dangling layers when needed:
  `docker image prune -f --filter "dangling=true"`.
- Do not run `docker system prune -a`, `docker volume prune`, or remove named volumes unless explicitly requested.
