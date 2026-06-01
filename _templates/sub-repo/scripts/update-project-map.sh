#!/usr/bin/env bash
# Repo-local PROJECT_MAP updater.
# This script is project-specific: teach it how to inspect this repo's stack and
# update only the generated block in PROJECT_MAP.md.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cat <<MSG
TODO: implement repo-local PROJECT_MAP generation for:
  $ROOT

Expected behavior:
  - collect entrypoints, commands, config files, docker services, and notable directories;
  - include API/routes/jobs/models when applicable;
  - update only the generated block in PROJECT_MAP.md;
  - do not modify the manual block.
MSG
