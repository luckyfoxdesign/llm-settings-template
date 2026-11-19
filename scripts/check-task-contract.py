#!/usr/bin/env python3
"""Check active task contracts; --complete validates a filled done record."""
import argparse
import re
import shlex
import subprocess
import sys
from pathlib import Path
from workspace_rules import extract_frontmatter, markdown_files, private_path, sections

ROOT = Path(__file__).resolve().parent.parent
REQUIRED_SECTIONS = ['Goal', 'Context', 'Non-goals', 'Invariants', 'Change Budget', 'Verification', 'Done When']


def is_template_example(text):
    return any('TEMPLATE-EXAMPLE' in comment for comment in re.findall(r'<!--.*?-->', text, re.S))


def verification_command_allowed(line):
    # Restrict raw shell syntax before tokenizing; quoted metacharacters are
    # rejected too, so validation never depends on how a shell evaluates them.
    if not re.fullmatch(r"[A-Za-z0-9_./:=,@%+\- '\"]+", line):
        return False
    if re.search(r'(?<![\w-])(curl|wget|ssh|sudo|rm|eval)(?![\w-])', line):
        return False
    try:
        args = shlex.split(line)
    except ValueError:
        return False
    if not args or any(re.search(r'(?<![\w-])(curl|wget|ssh|sudo|rm|eval)(?![\w-])', arg) for arg in args):
        return False
    # Reject traversal and private paths, including argument paths.
    if any(private_path(arg) or '..' in Path(arg).parts for arg in args):
        return False
    if args[0] == 'bash':
        return len(args) >= 2 and bool(re.fullmatch(
            r'(?:scripts/[A-Za-z0-9_-]+\.sh|(?:app|landing|nginx)/scripts/verify\.sh)', args[1]))
    if args[0] == 'python3':
        tail = args[1:]
        if tail and tail[0] == '-B':
            tail = tail[1:]
        return bool(tail and re.fullmatch(r'scripts/[A-Za-z0-9_-]+\.py', tail[0]))
    if args[:2] == ['docker', 'compose']:
        tail = args[2:]
        if tail[:1] == ['-f']:
            if len(tail) < 2 or not tail[1] or tail[1].startswith(('/', '-')):
                return False
            tail = tail[2:]
        return (len(tail) >= 3 and tail[:2] == ['run', '--rm']
                and bool(re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_-]*', tail[2])))
    return False


def verification_errors(body):
    errors = []
    fenced = False
    for raw in body.splitlines():
        line = raw.strip()
        if not line:
            continue
        if not fenced and line in {'```bash', '```sh', '```'}:
            fenced = True
        elif fenced and line == '```':
            fenced = False
        elif not fenced or not verification_command_allowed(line):
            errors.append('Verification command not allowed: ' + line)
    if fenced:
        errors.append('Verification has an unclosed command fence')
    return errors


def contract_errors(text, complete=False):
    try:
        content = sections(text)
        # Preserve HTML comments in executable text: the shared sections helper
        # strips them, which could otherwise hide shell syntax from validation.
        raw_content = sections(text.replace('<!--', '\x00'))
        fm = extract_frontmatter(text) or {}
    except ValueError as error:
        return [str(error)]
    errors = []
    for section in REQUIRED_SECTIONS:
        body = content.get(section.lower(), '')
        if not body or not re.sub(r'[`~\s-]', '', body):
            errors.append('missing or empty ' + section)
        elif re.search(r'\b(?:TODO|TBD|PLACEHOLDER)\b', body):
            errors.append('unfinished ' + section)
    budget = content.get('change budget', '')
    if not re.search(r'\b\d+\b[^\n]*\bfiles?\b', budget, re.I):
        errors.append('Change Budget needs a numeric file limit')
    if not re.search(r'(?:\b(?:no new|zero|\d+)\b[^\n]*\bdependenc(?:y|ies)\b|\bdependenc(?:y|ies)\b[^\n]*\b(?:none|zero|\d+)\b)', budget, re.I):
        errors.append('Change Budget needs a dependency limit')
    if not re.search(r'\b(?:no new|zero|\d+)\b[^\n]*\b(?:abstractions?|layers?|scripts?)\b', budget, re.I):
        errors.append('Change Budget needs an abstraction/script limit')
    project = fm.get('project')
    projects = fm.get('projects', []) if project == 'cross' else [project]
    if not isinstance(projects, list):
        errors.append('projects must be a list')
        projects = []
    verification = raw_content.get('verification', '').replace('\x00', '<!--')
    errors.extend(verification_errors(verification))
    for repo in projects:
        if not isinstance(repo, str) or repo not in {'app', 'landing', 'nginx', 'workspace'}:
            errors.append('invalid task project')
            continue
        gate = 'scripts/verify.sh' if repo == 'workspace' else repo + '/scripts/verify.sh'
        if not re.search(r'^\s*bash\s+' + re.escape(gate) + r'\s*$', verification, re.M):
            errors.append('Verification must include bash ' + gate)
    items = re.findall(r'^\s*- \[([ xX])\]\s+(.+)$', content.get('done when', ''), re.M)
    if not items:
        errors.append('Done When needs acceptance checkboxes')
    paths = re.findall(r'^- `([^`]+)`\s*$', content.get('task paths', ''), re.M)
    if not paths:
        errors.append('Task Paths needs explicit workspace-relative paths')
    elif any(private_path(path) or path.startswith('/') or '..' in Path(path).parts for path in paths):
        errors.append('Task Paths contains a private or invalid path')
    if complete:
        if fm.get('type') != 'done_long' or fm.get('status') != 'done':
            errors.append('completion record must have type: done_long and status: done')
        for state, item in items:
            if state == ' ':
                errors.append('unchecked Done When item')
            if not re.search(r'\bEvidence:\s*\S', item):
                errors.append('Done When item needs an Evidence: reference and observed result')
        for section in ['Verification Evidence', 'Review Evidence']:
            if not content.get(section.lower()):
                errors.append('completion needs ' + section)
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--strict', action='store_true')
    parser.add_argument('--complete', type=Path)
    args = parser.parse_args()
    if args.complete:
        path = args.complete.absolute()
        if private_path(path) or path.is_symlink() or any(p.is_symlink() for p in path.parents):
            parser.error('completion path must be a regular non-private file')
        paths = [path]
    else:
        paths = list(markdown_files(ROOT / 'docs/wip')) + list(markdown_files(ROOT / 'docs/backlog/todo'))
        for record in markdown_files(ROOT / 'docs/done/long'):
            try:
                metadata = extract_frontmatter(record.read_text()) or {}
            except ValueError:
                continue  # The frontmatter gate reports malformed metadata.
            if metadata.get('completion_validation') == 'required':
                paths.append(record)
    failed = 0
    checked = 0
    for path in paths:
        try:
            text = path.read_text(encoding='utf-8')
        except OSError:
            print('ERROR: cannot read completion record')
            return 1
        if not args.complete and path.name == '00-00-00-app-example-task.md' and is_template_example(text):
            continue
        checked += 1
        try:
            metadata = extract_frontmatter(text) or {}
        except ValueError:
            metadata = {}
        complete = bool(args.complete) or metadata.get('completion_validation') == 'required'
        errors = contract_errors(text, complete)
        if complete:
            commits = re.findall(r'^- (workspace|app|landing|nginx) `([0-9a-f]{7,40})`', text, re.M)
            if not commits:
                errors.append('completion needs a valid Commits block')
            targets = metadata.get('projects', []) if metadata.get('project') == 'cross' else [metadata.get('project')]
            if isinstance(targets, list) and any(target not in {repo for repo, _ in commits} for target in targets):
                errors.append('completion needs a commit for every task project')
            for repo, commit in commits:
                directory = ROOT if repo == 'workspace' else ROOT / repo
                result = subprocess.run(['git', '-C', str(directory), 'cat-file', '-e', commit + '^{commit}'], capture_output=True)
                if result.returncode:
                    errors.append('completion commit does not exist in ' + repo)
        if errors:
            failed += 1
            print(path.name, ':', '; '.join(errors))
    print('Task contracts: {} checked, {} invalid'.format(checked, failed))
    return 1 if failed and (args.strict or args.complete) else 0


if __name__ == '__main__':
    sys.exit(main())
