#!/usr/bin/env bash
# Single executable gate for this repo.
# Runs the gates in order and exits non-zero on the first failure.
# A task in this repo stops on this exit code, not on a judgement about the code.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# TODO: fill in this repo's real commands. Docker-only, per CLAUDE.md.
# Required gates must be set; optional gates may stay empty and are skipped.
LINT_CMD=()       # required, e.g. (docker compose run --rm lint)
TEST_CMD=()       # required, e.g. (docker compose run --rm test)
TYPECHECK_CMD=()  # optional, e.g. (docker compose run --rm typecheck)
BUILD_CMD=()      # optional, e.g. (docker compose run --rm build)

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
run_gate lint required ${LINT_CMD[@]+"${LINT_CMD[@]}"}
run_gate test required ${TEST_CMD[@]+"${TEST_CMD[@]}"}
run_gate typecheck optional ${TYPECHECK_CMD[@]+"${TYPECHECK_CMD[@]}"}
run_gate build optional ${BUILD_CMD[@]+"${BUILD_CMD[@]}"}

echo "OK: all configured gates passed"
