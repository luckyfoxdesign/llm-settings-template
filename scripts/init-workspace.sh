#!/usr/bin/env bash
# Creates the standard docs folder structure for a new workspace.
# Run once from workspace root: bash scripts/init-workspace.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

dirs=(
  docs/backlog/todo
  docs/backlog/bugs
  docs/wip
  docs/done/long
  docs/done/short
  docs/ideas
  docs/product/vision
  docs/product/architecture
  scripts
)

for d in "${dirs[@]}"; do
  mkdir -p "$ROOT/$d"
  if [ ! -f "$ROOT/$d/.gitkeep" ] && [ -z "$(ls -A "$ROOT/$d" 2>/dev/null)" ]; then
    touch "$ROOT/$d/.gitkeep"
  fi
done

echo "Workspace structure initialized at: $ROOT"
