#!/usr/bin/env python3
"""Check active task contracts; --complete validates a filled done record."""
import argparse
import re
import subprocess
import sys
from pathlib import Path
from workspace_rules import extract_frontmatter, markdown_files, private_path, sections

ROOT = Path(__file__).resolve().parent.parent
REQUIRED_SECTIONS = ['Goal', 'Context', 'Non-goals', 'Invariants', 'Change Budget', 'Verification', 'Done When']


def is_template_example(text):
    return any('TEMPLATE-EXAMPLE' in comment for comment in re.findall(r'<!--.*?-->', text, re.S))


def contract_errors(text, complete=False):
    try:
        content = sections(text)
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
    verification = content.get('verification', '')
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
