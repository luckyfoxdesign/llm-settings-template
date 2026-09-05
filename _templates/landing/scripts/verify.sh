#!/usr/bin/env bash
# Single executable gate for [project-name]-[repo-name].
# Runs the gates in order and exits non-zero on the first failure.
# A task in this repo stops on this exit code, not on a judgement about the code.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Docker-only, per CLAUDE.md. Required gates must pass; empty optional gates skip.
BUILD_CMD="docker compose run --rm astro-dev npm run build"        # required
TOKENS_CMD="docker compose run --rm astro-dev npm run tokens:check" # required
LINT_CMD=""        # optional — no linter configured
TEST_CMD=""        # optional — no test suite (static site)
TYPECHECK_CMD=""   # optional — template rule: no TypeScript in source

run_gate() {
  local name="$1" cmd="$2" required="$3"

  if [[ -z "$cmd" ]]; then
    if [[ "$required" == "required" ]]; then
      echo "FAIL: gate '$name' is not configured in scripts/verify.sh" >&2
      exit 1
    fi
    echo "SKIP: $name (not configured)"
    return 0
  fi

  echo "=== $name ==="
  if ! eval "$cmd"; then
    echo "FAIL: gate '$name' failed: $cmd" >&2
    exit 1
  fi
}

run_gate build     "$BUILD_CMD"     required
run_gate tokens    "$TOKENS_CMD"    required
run_gate lint      "$LINT_CMD"      optional
run_gate test      "$TEST_CMD"      optional
run_gate typecheck "$TYPECHECK_CMD" optional

echo "OK: all configured gates passed"
