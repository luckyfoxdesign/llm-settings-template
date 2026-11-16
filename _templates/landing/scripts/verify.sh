#!/usr/bin/env bash
# Single executable gate for [project-name]-[repo-name].
# Runs the gates in order and exits non-zero on the first failure.
# A task in this repo stops on this exit code, not on a judgement about the code.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Docker-only, per CLAUDE.md. Required gates must pass; empty optional gates skip.
BUILD_CMD=(docker compose run --rm astro-dev npm run build)        # required
TOKENS_CMD=(docker compose run --rm astro-dev npm run tokens:check) # required
LINT_CMD=()        # optional — no linter configured
TEST_CMD=()        # optional — no test suite (static site)
TYPECHECK_CMD=()   # optional — template rule: no TypeScript in source

run_gate() {
  local name="$1" required="$2"
  shift 2

  if [[ "$#" -eq 0 ]]; then
    if [[ "$required" == "required" ]]; then
      echo "FAIL: gate '$name' is not configured in scripts/verify.sh" >&2
      exit 1
    fi
    echo "SKIP: $name (not configured)"
    return 0
  fi

  echo "=== $name ==="
  if ! "$@"; then
    echo "FAIL: gate '$name' failed: $*" >&2
    exit 1
  fi
}

# The + expansion preserves empty arrays under Bash 3 with nounset enabled.
run_gate build required ${BUILD_CMD[@]+"${BUILD_CMD[@]}"}
run_gate tokens required ${TOKENS_CMD[@]+"${TOKENS_CMD[@]}"}
run_gate lint optional ${LINT_CMD[@]+"${LINT_CMD[@]}"}
run_gate test optional ${TEST_CMD[@]+"${TEST_CMD[@]}"}
run_gate typecheck optional ${TYPECHECK_CMD[@]+"${TYPECHECK_CMD[@]}"}

echo "OK: all configured gates passed"
