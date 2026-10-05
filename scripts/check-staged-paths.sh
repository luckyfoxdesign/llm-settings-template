#!/usr/bin/env bash
# Check private filenames and explicit task scope without reading staged contents.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec python3 -B "$SCRIPT_DIR/check-staged-paths.py" "$@"
