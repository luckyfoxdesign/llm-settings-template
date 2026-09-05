#!/usr/bin/env bash
# Repo-local PROJECT_MAP updater for [project-name]-[repo-name].
# Stub: teach it to inspect this repo's stack and rewrite only the
# `generated` block in PROJECT_MAP.md. Do not touch the `manual` block.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cat <<MSG
TODO: implement repo-local PROJECT_MAP generation for:
  $ROOT

Expected behavior:
  - collect entrypoints from src/pages/;
  - list layouts, components, and content collections when they appear;
  - list compose.yml services and package.json scripts, incl. tokens:*;
  - note key config files (astro.config.mjs, vercel.json, tsconfig.json);
  - note the token pipeline: src/styles/global.css @theme -> tokens/;
  - rewrite only the block between "<!-- generated:start -->" and
    "<!-- generated:end -->" in PROJECT_MAP.md;
  - never modify the "manual" block.
MSG
