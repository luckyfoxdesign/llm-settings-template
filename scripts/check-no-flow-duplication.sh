#!/usr/bin/env bash
# Check canonical workflow ownership only in known instruction locations.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
python3 -B - <<'PY'
import re
import sys
from pathlib import Path
sys.path.insert(0, str(Path('scripts').resolve()))
from workspace_rules import markdown_files, private_path

owner = Path('docs/workflows/task-lifecycle.md')
if owner.is_symlink() or any(p.is_symlink() for p in owner.parents) or not owner.is_file():
    sys.exit('FAIL: missing regular canonical workflow file')
canonical = owner.read_text()
names = ('create', 'start', 'review', 'complete')
for name in names:
    if f'id="{name}-task-equivalent"' not in canonical:
        sys.exit('FAIL: missing workflow anchor for ' + name)
steps = {line.strip() for line in canonical.splitlines()
         if re.match(r'^\d+\. ', line) and len(line) > 100}
paths = [Path('AGENTS.md'), Path('CLAUDE.md')]
for folder in ('.agents/skills', '.claude/commands'):
    paths.extend(markdown_files(folder))
for template in ('sub-repo', 'landing'):
    paths.extend(Path('_templates') / template / name for name in ('AGENTS.md', 'CLAUDE.md'))
    paths.extend(markdown_files(Path('_templates') / template / '.claude/commands'))
failed = False
for path in paths:
    if private_path(path) or path.is_symlink() or any(p.is_symlink() for p in path.parents):
        continue
    if not path.is_file():
        print('FAIL: missing instruction file', path)
        failed = True
        continue
    text = path.read_text()
    repeated = sum(line.strip() in steps for line in text.splitlines())
    if repeated >= 2 or re.search(r'^## `/\w+-task` Equivalent$', text, re.M):
        print('FAIL: lifecycle procedure duplicated in', path)
        failed = True
print('Workflow ownership: ' + ('FAIL' if failed else 'OK (instruction files only)'))
sys.exit(1 if failed else 0)
PY
