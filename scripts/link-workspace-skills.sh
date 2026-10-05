#!/usr/bin/env bash
# Expose shared skills inside an independent code repo without overwriting anything.
set -euo pipefail
[[ "$#" -eq 1 ]] || { echo "Usage: $0 <app|landing|nginx path>" >&2; exit 2; }
WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
REPO_ROOT="$(git -C "$1" rev-parse --show-toplevel)"
case "$REPO_ROOT" in
  "$WORKSPACE_ROOT/app"|"$WORKSPACE_ROOT/landing"|"$WORKSPACE_ROOT/nginx") ;;
  *) echo "ERROR: expected an independent app, landing, or nginx repo in this workspace" >&2; exit 1 ;;
esac
python3 -B - "$WORKSPACE_ROOT" "$REPO_ROOT" <<'PY'
import os
import sys
from pathlib import Path
workspace, repo = map(Path, sys.argv[1:])
for host in ('.agents', '.claude'):
    folder = repo / host / 'skills'
    if any(parent.is_symlink() for parent in (repo, repo / host, folder)):
        sys.exit('ERROR: refusing symlinked skill destination directory')
    folder.mkdir(parents=True, exist_ok=True)
    for name in ('create-task', 'start-task', 'review-task', 'complete-task'):
        source = workspace / '.agents/skills' / name
        if not (source / 'SKILL.md').is_file():
            sys.exit('ERROR: missing workspace skill ' + name)
        destination = folder / name
        if destination.is_symlink() and destination.resolve() == source.resolve():
            continue
        if destination.exists() or destination.is_symlink():
            sys.exit('ERROR: existing skill left unchanged: ' + str(destination))
        destination.symlink_to(os.path.relpath(source, folder), target_is_directory=True)
print('Linked workspace skills into', repo.name)
PY
