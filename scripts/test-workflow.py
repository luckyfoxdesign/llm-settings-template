#!/usr/bin/env python3
"""Behavioral regressions for workspace gates, using disposable Git repositories."""
import fnmatch
import importlib.util
import json
import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path
from workspace_rules import extract_frontmatter, markdown_files, private_path

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('task_contract', ROOT / 'scripts/check-task-contract.py')
contract = importlib.util.module_from_spec(spec)
spec.loader.exec_module(contract)

VALID_TASK = '''---
type: task
status: wip
project: workspace
created: 2026-10-05
---
# Fixture
## Goal
Ensure the fixture is accepted.
## Context
Disposable regression fixture.
## Non-goals
No external changes.
## Invariants
No network or private files.
## Change Budget
- At most 1 workspace file.
- No new dependencies.
- No new abstraction layers.
## Task Paths
- `a.txt`
## Verification
```bash
bash scripts/verify.sh
```
## Done When
- [ ] The gate passes.
'''


def run(args, cwd, check=False):
    result = subprocess.run(args, cwd=cwd, capture_output=True, text=True)
    if check and result.returncode:
        raise AssertionError(result.stdout + result.stderr)
    return result


class Documents(unittest.TestCase):
    def test_lists_and_nested_metadata(self):
        for value in ['[app, nginx]', '\n  - app\n  - nginx']:
            parsed = extract_frontmatter('---\nprojects: ' + value + '\nsource:\n  kind: issue\n---\n')
            self.assertEqual(parsed['projects'], ['app', 'nginx'])
            self.assertEqual(parsed['source'], {'kind': 'issue'})
        self.assertEqual(extract_frontmatter('---\narea: ["one, two", three]\n---')['area'], ['one, two', 'three'])

    def test_malformed_yaml_rejected(self):
        for body in ['projects: [app, nginx', 'project: app\nproject: nginx', 'source: &shared value', 'source:\n bad-indent: value\n  another: value']:
            with self.assertRaises(ValueError):
                extract_frontmatter('---\n' + body + '\n---\n')

    def test_empty_contract_rejected(self):
        text = '\n'.join('## ' + name for name in contract.REQUIRED_SECTIONS)
        self.assertTrue(contract.contract_errors(text))
        self.assertFalse(contract.contract_errors(VALID_TASK))
        text = VALID_TASK.replace('bash scripts/verify.sh', 'true')
        self.assertTrue(contract.contract_errors(text))

    def test_completion_requires_checked_evidence(self):
        text = VALID_TASK.replace('type: task', 'type: done_long').replace('status: wip', 'status: done')
        self.assertTrue(contract.contract_errors(text, complete=True))
        text = text.replace('- [ ] The gate passes.', '- [x] The gate passes. — Evidence: bash scripts/verify.sh exited 0.')
        text += '\n## Verification Evidence\nGate exited 0.\n## Review Evidence\nWorkspace commit abcdef0; NO_BLOCKING_FINDINGS.\n'
        self.assertFalse(contract.contract_errors(text, complete=True))

    def test_private_paths_and_symlinks_are_not_opened(self):
        for name in ['.env', 'dir/.env.local', '.ssh/file', '.npmrc', 'auth.json', 'credentials.md', 'access-token.md', 'file.key']:
            self.assertTrue(private_path(name))
        self.assertFalse(private_path('.env.example'))
        self.assertFalse(private_path('landing/scripts/generate-tokens.mjs'))
        self.assertFalse(private_path('landing/tokens/semantic.generated.json'))
        with tempfile.TemporaryDirectory(prefix='workspace-doc-test-') as tmp:
            folder = Path(tmp).resolve()
            (folder / 'safe.md').write_text('# Safe\n')
            (folder / 'alias.md').symlink_to('/nonexistent/private-file')
            (folder / 'alias-dir').symlink_to('/nonexistent/private-dir', target_is_directory=True)
            self.assertEqual([path.name for path in markdown_files(folder)], ['safe.md'])

    def test_permission_patterns_preserve_only_placeholder_exception(self):
        for settings in ['.claude/settings.json', '_templates/sub-repo/.claude/settings.json']:
            data = json.loads((ROOT / settings).read_text())['permissions']
            self.assertNotIn('Bash(docker*)', data['allow'])
            patterns = [rule[len('Read(**/'):-1] for rule in data['deny'] if rule.startswith('Read(**/.env')]
            self.assertFalse(any(fnmatch.fnmatchcase('.env.example', pattern) for pattern in patterns))
            for name in ['.env', '.env.', '.env.e', '.env.exam', '.env.production', '.env.test', '.env.example.bak', '.environment']:
                self.assertTrue(any(fnmatch.fnmatchcase(name, pattern) for pattern in patterns), name)

    def test_skill_entrypoints_and_workflow_anchors(self):
        workflow = (ROOT / 'docs/workflows/task-lifecycle.md').read_text()
        for name in ['create-task', 'start-task', 'review-task', 'complete-task']:
            text = (ROOT / '.agents/skills' / name / 'SKILL.md').read_text()
            metadata = extract_frontmatter(text)
            self.assertEqual(metadata['name'], name)
            self.assertLessEqual(len(metadata['description']), 1024)
            self.assertIn('docs/workflows/task-lifecycle.md#' + name + '-equivalent', text)
            self.assertIn('id="' + name + '-equivalent"', workflow)


class Fixtures(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='workspace-flow-test-')
        self.workspace = Path(self.temp.name).resolve() / 'workspace'
        self.workspace.mkdir()
        scripts = self.workspace / 'scripts'
        scripts.mkdir()
        for name in ['workspace_rules.py', 'check-staged-paths.py', 'check-staged-paths.sh', 'task-branch.sh', 'link-workspace-skills.sh', 'validate-docs-frontmatter.py', 'build-code-index.py', 'check-no-flow-duplication.sh', 'check-task-contract.py', 'new-done-record.sh']:
            shutil.copy2(ROOT / 'scripts' / name, scripts / name)
        self.repo = self.workspace / 'app'
        self.repo.mkdir()
        self.git('init', '-q', '-b', 'main')
        self.git('config', 'user.name', 'Workflow Fixture')
        self.git('config', 'user.email', 'fixture@example.invalid')

    def tearDown(self):
        self.temp.cleanup()

    def git(self, *args):
        return run(['git', *args], self.repo, check=True)

    def helper(self, name, *args):
        return run(['bash', str(self.workspace / 'scripts' / name), *map(str, args)], self.workspace)

    def test_staging_scope_and_file_budget(self):
        (self.repo / 'a.txt').write_text('A\n')
        (self.repo / 'other.txt').write_text('B\n')
        self.git('add', 'a.txt', 'other.txt')
        self.assertNotEqual(self.helper('check-staged-paths.sh', self.repo, '--allow', 'a.txt').returncode, 0)
        self.assertEqual(self.helper('check-staged-paths.sh', self.repo, '--allow', 'a.txt', '--allow', 'other.txt').returncode, 0)
        task = self.workspace / 'task.md'
        task.write_text(VALID_TASK.replace('`a.txt`', '`app/a.txt`\n- `app/other.txt`'))
        self.assertNotEqual(self.helper('check-staged-paths.sh', self.repo, '--task', task).returncode, 0)
        task.write_text(task.read_text().replace('At most 1 workspace file', 'At most 2 workspace files'))
        self.assertEqual(self.helper('check-staged-paths.sh', self.repo, '--task', task).returncode, 0)

    def prepare_merge(self, conflicting_result):
        for name in ['a.txt', 'b.txt']:
            (self.repo / name).write_text('1\n')
        gate = self.repo / 'scripts/verify.sh'
        gate.parent.mkdir()
        gate.write_text('#!/bin/bash\nset -euo pipefail\ncd "$(dirname "$0")/.."\na=$(cat a.txt)\nb=$(cat b.txt)\n(( a + b <= 3 ))\n')
        self.git('add', 'a.txt', 'b.txt', 'scripts/verify.sh')
        self.git('commit', '-qm', 'Base')
        self.git('switch', '-qc', 'task/test')
        (self.repo / 'a.txt').write_text('2\n')
        self.git('add', 'a.txt')
        self.git('commit', '-qm', 'Task')
        self.assertEqual(run(['bash', 'scripts/verify.sh'], self.repo).returncode, 0)
        self.git('switch', '-q', 'main')
        if conflicting_result:
            (self.repo / 'b.txt').write_text('2\n')
            self.git('add', 'b.txt')
            self.git('commit', '-qm', 'Independent main change')
        self.assertEqual(run(['bash', 'scripts/verify.sh'], self.repo).returncode, 0)
        self.git('switch', '-q', 'task/test')

    def test_failed_merged_gate_retains_branch_and_pending_merge(self):
        self.prepare_merge(True)
        result = self.helper('task-branch.sh', 'finish', self.repo, 'test')
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(self.git('branch', '--list', 'task/test').stdout.strip())
        self.assertTrue((self.repo / '.git/MERGE_HEAD').is_file())

    def test_successful_merge_checks_gate_and_removes_branch(self):
        self.prepare_merge(False)
        result = self.helper('task-branch.sh', 'finish', self.repo, 'test')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse(self.git('branch', '--list', 'task/test').stdout.strip())
        self.assertEqual(run(['bash', 'scripts/verify.sh'], self.repo).returncode, 0)

    def test_frontmatter_validation_is_read_only_and_rejects_bad_projects(self):
        docs = self.workspace / 'docs/backlog/todo'
        docs.mkdir(parents=True)
        index = self.workspace / 'docs/code-index.md'
        index.write_text('Index must not change.\n')
        task = docs / 'task.md'
        task.write_text(VALID_TASK.replace('status: wip', 'status: todo').replace('project: workspace', 'project: cross\nprojects: [app, invalid-repo]'))
        result = run(['python3', '-B', 'scripts/validate-docs-frontmatter.py', '--strict'], self.workspace)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(index.read_text(), 'Index must not change.\n')
        task.write_text(task.read_text().replace('[app, invalid-repo]', '[app, nginx]'))
        self.assertEqual(run(['python3', '-B', 'scripts/validate-docs-frontmatter.py', '--strict'], self.workspace).returncode, 0)

    def test_code_index_includes_completed_records(self):
        docs = self.workspace / 'docs/done/long'
        docs.mkdir(parents=True)
        (docs / 'done.md').write_text('---\ntype: done_long\nstatus: done\nrelated_code: [app/a.txt]\n---\n# Finished\n')
        result = run(['python3', '-B', 'scripts/build-code-index.py'], self.workspace)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('app/a.txt', (self.workspace / 'docs/code-index.md').read_text())

    def test_done_scaffold_blocks_gate_until_evidence_and_commit_are_valid(self):
        wip = self.workspace / 'docs/wip'
        wip.mkdir(parents=True)
        filename = '05-10-26-workspace-evidence-case.md'
        (wip / filename).write_text(VALID_TASK)
        run(['git', 'init', '-q', '-b', 'main'], self.workspace, check=True)
        run(['git', 'config', 'user.name', 'Workflow Fixture'], self.workspace, check=True)
        run(['git', 'config', 'user.email', 'fixture@example.invalid'], self.workspace, check=True)
        (self.workspace / 'a.txt').write_text('A\n')
        run(['git', 'add', 'a.txt'], self.workspace, check=True)
        run(['git', 'commit', '-qm', 'Implementation fixture'], self.workspace, check=True)
        commit = run(['git', 'rev-parse', '--short', 'HEAD'], self.workspace, check=True).stdout.strip()
        result = self.helper('new-done-record.sh', 'docs/wip/' + filename, 'workspace', commit, 'Implementation fixture')
        self.assertEqual(result.returncode, 0, result.stderr)
        result = run(['python3', '-B', 'scripts/check-task-contract.py', '--strict'], self.workspace)
        self.assertNotEqual(result.returncode, 0)
        record = self.workspace / 'docs/done/long' / filename
        text = record.read_text().replace('- [ ] The gate passes.', '- [x] The gate passes. — Evidence: bash scripts/verify.sh exited 0.')
        text += '\n## Review Evidence\nWorkspace commit ' + commit + '; NO_BLOCKING_FINDINGS.\n'
        text = text.replace('<!-- Fill with command, diff/path, or commit evidence for every Done When item. -->', 'bash scripts/verify.sh exited 0.')
        record.write_text(text)
        result = run(['python3', '-B', 'scripts/check-task-contract.py', '--complete', str(record)], self.workspace)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        record.write_text(text.replace('`' + commit + '`', '`0000000`'))
        result = run(['python3', '-B', 'scripts/check-task-contract.py', '--complete', str(record)], self.workspace)
        self.assertNotEqual(result.returncode, 0)

    def test_linking_skills_is_idempotent_without_overwrite(self):
        for name in ['create-task', 'start-task', 'review-task', 'complete-task']:
            skill = self.workspace / '.agents/skills' / name
            skill.mkdir(parents=True)
            (skill / 'SKILL.md').write_text('---\nname: ' + name + '\ndescription: Fixture\n---\n')
        for _ in range(2):
            result = self.helper('link-workspace-skills.sh', self.repo)
            self.assertEqual(result.returncode, 0, result.stderr)
        linked = self.repo / '.agents/skills/create-task'
        self.assertTrue(linked.is_symlink())
        linked.unlink()
        linked.mkdir()
        result = self.helper('link-workspace-skills.sh', self.repo)
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(linked.is_dir())

    def test_instruction_scan_excludes_code_repos(self):
        for name in ['AGENTS.md', 'CLAUDE.md', '.agents/skills/create-task/SKILL.md', '.claude/commands/create-task.md', '_templates/sub-repo/AGENTS.md', '_templates/sub-repo/CLAUDE.md', '_templates/landing/AGENTS.md', '_templates/landing/CLAUDE.md', 'docs/workflows/task-lifecycle.md']:
            path = self.workspace / name
            path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / name, path)
        (self.repo / 'README.md').write_text('## `/create-task` Equivalent\nDo not scan me.\n')
        self.assertEqual(self.helper('check-no-flow-duplication.sh').returncode, 0)
        (self.workspace / 'CLAUDE.md').write_text('## `/create-task` Equivalent\nCopied procedure.\n')
        self.assertNotEqual(self.helper('check-no-flow-duplication.sh').returncode, 0)


if __name__ == '__main__':
    unittest.main(verbosity=1)
