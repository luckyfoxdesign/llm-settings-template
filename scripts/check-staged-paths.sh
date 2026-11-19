#!/usr/bin/env bash
# Filename/scope checks; --content-scan delegates staged content inspection to Docker.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec python3 -B "$SCRIPT_DIR/check-staged-paths.py" "$@"
