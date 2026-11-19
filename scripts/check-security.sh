#!/usr/bin/env bash
# Host orchestration only; analyzers and network requests run in Docker.
set -euo pipefail
exec python3 -B - "$@" <<'PY'
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

args = sys.argv[1:]
strict = '--strict' in args
args = [a for a in args if a != '--strict']
if len(args) != 1 or args[0].startswith('-'):
    print('Usage: bash scripts/check-security.sh <repo-path> [--strict]')
    sys.exit(2)
root = Path(os.path.abspath(args[0]))
# Refuse symlink targets, including symlinks in the supplied path's ancestors.
if not root.is_dir() or any(p.is_symlink() for p in (root, *root.parents)):
    print('ERROR: target must be a directory with no symlink components')
    sys.exit(2)
failed = False

def report(section, status, message):
    global failed
    print(f'{section}: {status} — {message}', flush=True)
    if status in ('FAIL', 'ERROR'):
        failed = True

def run(argv, data=None, timeout=240):
    try:
        return subprocess.run(argv, input=data, stdout=subprocess.PIPE,
                              stderr=subprocess.DEVNULL, timeout=timeout, check=False)
    except (OSError, subprocess.TimeoutExpired):
        return None

if not shutil.which('docker') or (probe := run(['docker', 'info'], timeout=20)) is None or probe.returncode:
    for section in ('deps', 'images', 'dockerfiles', 'shell', 'history', 'ports'):
        report(section, 'SKIP', 'Docker unavailable; check not performed')
    sys.exit(1 if strict else 0)

# Do not traverse private paths, symlinks, generated dependencies, or nested Git stores.
def private(name):
    name = name.lower()
    return (name.startswith('.env') or name in {
        '.ssh', '.aws', '.kube', '.gnupg', '.npmrc', '.netrc', '.codex',
        '.claude', '.git', '.hg', 'node_modules', 'vendor', '.venv', 'dist',
        'build', 'auth.json', 'credentials', 'secrets', 'browser-profiles',
    } or any(word in name for word in ('credential', 'secret', 'token', 'password',
                                      'keychain', 'id_rsa', 'id_ed25519'))
        or name.endswith(('.pem', '.key', '.p12', '.pfx')))

if any(private(p.name) for p in (root, *root.parents) if p.name):
    print('ERROR: private target paths are excluded')
    sys.exit(2)
files = []
for base, dirs, names in os.walk(root, followlinks=False):
    dirs[:] = sorted(d for d in dirs if not private(d) and not (Path(base) / d).is_symlink())
    for name in sorted(names):
        p = Path(base) / name
        if not private(name) and not p.is_symlink() and p.is_file():
            files.append(p)
locks = [p for p in files if p.name == 'package-lock.json']
dockerfiles = [p for p in files if p.name.startswith('Dockerfile')]
shells = [p for p in files if p.suffix == '.sh']
composes = [p for p in files if p.suffix in ('.yml', '.yaml') and
            (p.name.startswith('compose') or p.name.startswith('docker-compose'))]

# Only selected inputs enter the temporary snapshot. Never mount the worktree.
with tempfile.TemporaryDirectory(prefix='workspace-security-') as tmp:
    snapshot = Path(tmp)
    for p in set(locks + dockerfiles + shells + composes):
        dest = snapshot / p.relative_to(root)
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(p, dest)

    pulled = set()

    def docker(image, command, *, network=False, data=None, mounts=None):
        # Refresh moving tags once per run; a stale local tag is not tool currency.
        if image not in pulled:
            pull = run(['docker', 'pull', image])
            if pull is None or pull.returncode:
                return None
            pulled.add(image)
        argv = ['docker', 'run', '--rm', '-i', '--read-only', '--cap-drop=ALL',
                '--security-opt=no-new-privileges', '--tmpfs', '/tmp:rw,nosuid,nodev',
                '--workdir', '/scan', '-e', 'HOME=/tmp']
        if not network:
            argv += ['--network=none']
        for source, target in (mounts or [(snapshot, '/scan')]):
            argv += ['--mount', f'type=bind,source={source},target={target},readonly']
        return run(argv + [image] + command, data)

    def tool(section, label, image, command, *, network=False, data=None, mounts=None,
             finding_codes=(1,)):
        result = docker(image, command, network=network, data=data, mounts=mounts)
        if result is None or result.returncode not in (0, *finding_codes):
            report(section, 'ERROR', f'{label}: tool unavailable, timed out, or failed; diagnostics suppressed')
        elif result.returncode:
            report(section, 'FAIL', f'{label}: findings; diagnostics suppressed')
        else:
            report(section, 'PASS', f'{label}: completed')
        return result

    if not locks:
        report('deps', 'SKIP', 'no package-lock.json')
    for index, p in enumerate(locks, 1):
        rel = '/scan/' + p.relative_to(root).as_posix()
        # The npm container gets just this lockfile, no .npmrc or package scripts.
        result = docker('node:lts-alpine', ['npm', 'audit', '--package-lock-only',
                        '--ignore-scripts', '--json', '--cache=/tmp/npm',
                        '--prefix=' + str(Path(rel).parent)], network=True)
        try:
            if result is None or result.returncode not in (0, 1):
                raise ValueError()
            payload = json.loads(result.stdout)
            counts = payload['metadata']['vulnerabilities']
            high = int(counts['high']) + int(counts['critical'])
            total = int(counts['total'])
            report('deps', 'FAIL' if high else ('WARN' if total else 'PASS'),
                   f'npm lockfile {index}: {high} high/critical; {total} total advisories')
        except (ValueError, KeyError, TypeError):
            report('deps', 'ERROR', f'npm lockfile {index}: audit unavailable or invalid response')
        # Any OSV finding blocks strict mode: unclassified severity needs triage.
        tool('deps', f'OSV lockfile {index}', 'ghcr.io/google/osv-scanner:latest',
             ['scan', 'source', '--lockfile=' + rel, '--format=json'], network=True)

    if not dockerfiles:
        report('dockerfiles', 'SKIP', 'no Dockerfile inputs')
        report('images', 'SKIP', 'no Dockerfile inputs')
    runtimes = set()
    unresolved = 0
    for index, p in enumerate(dockerfiles, 1):
        rel = '/scan/' + p.relative_to(root).as_posix()
        tool('dockerfiles', f'Dockerfile {index}', 'hadolint/hadolint:latest',
             ['hadolint', '--failure-threshold', 'error',
              '--no-color', rel])
        stages = set()
        # Read logical FROM lines, including continuations and multi-stage aliases.
        text = (snapshot / p.relative_to(root)).read_text().replace('\\\n', ' ')
        for line in text.splitlines():
            match = re.match(r'^\s*FROM\s+(?:--platform=\S+\s+)?(\S+)(?:\s+AS\s+(\S+))?', line, re.I)
            if not match:
                continue
            image, alias = match.groups()
            if image.lower() not in stages and image.lower() != 'scratch':
                # Only official Node, Python, Alpine and nginx repository names.
                found = re.fullmatch(r'(?:(?:docker\.io/)?library/|docker\.io/)?(node|python|alpine|nginx):([0-9]+(?:\.[0-9]+)*)(?:[-@].*)?', image)
                if found:
                    runtime, version = found.groups()
                    parts = version.split('.')
                    cycle = parts[0] if runtime == 'node' else '.'.join(parts[:2])
                    if runtime != 'node' and len(parts) < 2:
                        unresolved += 1
                    else:
                        runtimes.add(({'node': 'nodejs'}.get(runtime, runtime), cycle))
                else:
                    unresolved += 1
            if alias:
                stages.add(alias.lower())
    if unresolved:
        report('images', 'ERROR', f'{unresolved} base references need manual support verification (dynamic, unversioned, or unsupported product)')
    if dockerfiles and not runtimes and not unresolved:
        report('images', 'SKIP', 'only scratch or local build stages')
    support_code = '''import datetime,json,sys,urllib.request
try:
 p,c=sys.argv[1:]
 with urllib.request.urlopen('https://endoflife.date/api/'+p+'/'+c+'.json',timeout=25) as r:
  info=json.load(r)
 e=info['eol']
 if e is False: print('SUPPORTED')
 elif e is True: print('EOL')
 else: print('EOL' if datetime.date.fromisoformat(e)<=datetime.date.today() else 'SUPPORTED')
except Exception: sys.exit(2)
'''
    for product, cycle in sorted(runtimes):
        result = docker('python:alpine', ['python', '-c', support_code, product, cycle], network=True)
        status = result.stdout.strip() if result is not None and result.returncode == 0 else b''
        if status in (b'EOL', b'SUPPORTED'):
            report('images', 'FAIL' if status == b'EOL' else 'PASS',
                   f'{product} cycle {cycle}: {status.decode()}')
        else:
            report('images', 'ERROR', f'{product} cycle {cycle}: support status unavailable')

    if not shells:
        report('shell', 'SKIP', 'no shell scripts')
    for index, p in enumerate(shells, 1):
        tool('shell', f'script {index}', 'koalaman/shellcheck-alpine:stable',
             ['shellcheck', '--norc', '--format=json', '/scan/' + p.relative_to(root).as_posix()])

    git_dir = root / '.git'
    if git_dir.is_dir() and not git_dir.is_symlink():
        # History only: no worktree, local gitleaks config, or .gitleaksignore.
        tool('history', 'gitleaks', 'ghcr.io/gitleaks/gitleaks:latest',
             ['git', '/scan', '--log-opts=--all --full-history --no-ext-diff --no-textconv', '--ignore-gitleaks-allow', '--redact=100', '--exit-code=10', '--no-banner'],
             mounts=[(git_dir, '/scan/.git')], finding_codes=(10,))
    else:
        report('history', 'SKIP', 'no standalone .git directory; worktrees need a separate history scan')

    if not composes:
        report('ports', 'SKIP', 'no compose YAML inputs')
    # Parse YAML in Docker, never resolve env_file, interpolation, includes or secrets.
    ports_code = '''require 'yaml'
begin
 doc=YAML.safe_load(File.read(ARGV[0]), aliases: true) || {}
 count=0
 (doc.fetch('services', {}) || {}).each_value do |service|
  (service.fetch('ports', []) || []).each do |port|
   safe=if port.is_a?(Hash)
    port['host_ip']=='127.0.0.1'
   else
    port.to_s.match?(/\\A127\\.0\\.0\\.1:[0-9]+(?:-[0-9]+)?:[0-9]+(?:-[0-9]+)?(?:\\/(?:tcp|udp))?\\z/)
   end
   count+=1 unless safe
  end
 end
 puts count
rescue Exception
 exit 2
end
'''
    for index, p in enumerate(composes, 1):
        result = docker('ruby:alpine', ['ruby', '-e', ports_code, '/scan/' + p.relative_to(root).as_posix()])
        try:
            if result is None or result.returncode:
                raise ValueError()
            count = int(result.stdout)
            report('ports', 'WARN' if count else 'PASS',
                   f'compose {index}: {count} published ports not explicitly bound to 127.0.0.1')
        except (ValueError, TypeError):
            report('ports', 'ERROR', f'compose {index}: invalid YAML or unsupported structure')

print('Summary: ' + ('blocking findings or incomplete checks' if failed else 'checks completed; inspect WARN/SKIP coverage'))
sys.exit(1 if strict and failed else 0)
PY
