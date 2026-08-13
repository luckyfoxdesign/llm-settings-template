#!/usr/bin/env bash
# Strict executable gate for workspace tasks.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

run_gate() {
  local name="$1"
  shift
  echo "=== $name ==="
  if ! "$@"; then
    echo "FAIL: workspace gate '$name' failed" >&2
    return 1
  fi
}

run_gate context-budget bash scripts/check-context-budget.sh --strict
run_gate flow-duplication bash scripts/check-no-flow-duplication.sh
run_gate docs-frontmatter python3 scripts/validate-docs-frontmatter.py --strict
run_gate task-contract python3 scripts/check-task-contract.py --strict

echo "OK: all workspace gates passed"
