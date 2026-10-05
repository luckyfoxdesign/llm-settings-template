#!/usr/bin/env python3
"""Check staged names against task paths or the paths contributed by a merge."""
import argparse
import re
import subprocess
import sys
from pathlib import Path, PurePosixPath
from workspace_rules import private_path, sections


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('repo')
    scope = parser.add_mutually_exclusive_group(required=True)
    scope.add_argument('--allow', action='append', metavar='PATH')
    scope.add_argument('--allow-diff', nargs=2, metavar=('BASE', 'HEAD'))
    scope.add_argument('--secrets-only', action='store_true', help='filename-only diagnostic, not a task scope check')
    scope.add_argument('--task', type=Path, help='WIP contract with Task Paths and numeric file limit')
    parser.add_argument('--base', help='also count committed task changes since this base')
    args = parser.parse_args()
    for ref in (args.allow_diff or []) + ([args.base] if args.base else []):
        if ref.startswith('-') or not re.fullmatch(r'[A-Za-z0-9_./-]+', ref):
            parser.error('base/head must be a branch, tag, or commit identifier')

    def names(*options):
        result = subprocess.run(['git', '-C', args.repo, 'diff', '--name-only', '--no-renames', '-z', *options], capture_output=True)
        if result.returncode:
            raise ValueError('cannot inspect Git paths')
        return set(result.stdout.decode('utf-8', 'surrogateescape').rstrip('\0').split('\0')) - {''}

    allowed = args.allow or []
    maximum = None
    if args.task:
        task = args.task.absolute()
        if private_path(task) or task.is_symlink() or any(p.is_symlink() for p in task.parents):
            parser.error('task must be a regular non-private file')
        try:
            content = sections(task.read_text())
            allowed = re.findall(r'^- `([^`]+)`\s*$', content.get('task paths', ''), re.M)
            budget = re.search(r'\b(\d+)\b[^\n]*\bfiles?\b', content.get('change budget', ''), re.I)
            if not allowed or not budget:
                parser.error('task needs Task Paths and a numeric file limit')
            maximum = int(budget[1])
            repo = subprocess.run(['git', '-C', args.repo, 'rev-parse', '--show-toplevel'], capture_output=True, text=True, check=True)
            repo_path = Path(repo.stdout.strip())
            workspace = Path(__file__).resolve().parent.parent
            if repo_path != workspace:
                prefix = repo_path.relative_to(workspace).as_posix() + '/'
                allowed = [path[len(prefix):] for path in allowed if path.startswith(prefix)]
            if not allowed:
                parser.error('no approved paths for this repo')
        except (OSError, ValueError, subprocess.CalledProcessError):
            parser.error('cannot load task scope for this repo')
    for path in allowed:
        if not path or path.startswith('/') or '..' in PurePosixPath(path).parts or path.startswith('-') or '\\' in path:
            parser.error('allowed paths must be explicit repo-relative paths; directories end in /')
    try:
        merge_paths = names(*[args.allow_diff[0] + '...' + args.allow_diff[1]]) if args.allow_diff else set()
        staged = names('--cached', '--diff-filter=ACMRDTUXB')
        task_changes = staged | (names(args.base + '...HEAD') if args.base else set())
    except ValueError as error:
        print('ERROR:', error, file=sys.stderr)
        return 1
    blocked = []
    for path in sorted(task_changes):
        if private_path(path):
            blocked.append((path, 'private path'))
        elif not args.secrets_only and path not in merge_paths and not any(
                path == target or (target.endswith('/') and path.startswith(target)) for target in allowed):
            blocked.append((path, 'outside task scope'))
    for path, reason in blocked:
        print('BLOCKED:', repr(path), '(' + reason + ')', file=sys.stderr)
    if maximum is not None and len(task_changes) > maximum:
        print('BLOCKED: changed-file budget exceeded: {} > {}'.format(len(task_changes), maximum), file=sys.stderr)
        return 1
    if blocked:
        return 1
    print('OK: checked {} staged path(s), scope={}'.format(len(staged), 'diagnostic' if args.secrets_only else 'task'))
    return 0


if __name__ == '__main__':
    sys.exit(main())
