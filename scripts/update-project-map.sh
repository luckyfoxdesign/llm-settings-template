#!/usr/bin/env bash
# Workspace-level PROJECT_MAP updater.
# This script is project-specific: teach it how to read repo-local maps and
# update only generated workspace sections.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cat <<MSG
TODO: implement workspace PROJECT_MAP aggregation for:
  $ROOT

Expected behavior:
  - read repo-local <repo>/PROJECT_MAP.md files;
  - update only generated workspace sections;
  - do not duplicate repo internals;
  - do not modify manual sections.
MSG
