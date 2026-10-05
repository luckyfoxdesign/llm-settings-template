"""Private-path boundaries and a dependency-free, limited YAML reader."""
import ast
import os
import re
from pathlib import Path


def private_path(path):
    parts = Path(path).parts
    for index, part in enumerate(parts):
        name = part.lower()
        if name == '.env.example' and index == len(parts) - 1:
            continue
        if (name.startswith('.env') or name.endswith(('.pem', '.key'))
                or name.startswith(('id_rsa', 'id_ed25519'))
                or name in {'.ssh', '.aws', '.kube', '.gnupg', '.npmrc', '.netrc', 'auth.json'}
                or 'secret' in name or 'credential' in name
                or re.search(r'(?:^|[._-])(?:oauth|auth|access|refresh|api|session|bearer)[._-]?tokens?(?:[._-]|$)', name)
                or name in {'token', 'token.txt', 'token.json', 'tokens.json', 'token.md'}):
            return True
    return False


def markdown_files(directory):
    directory = Path(directory)
    if directory.is_symlink() or any(p.is_symlink() for p in directory.parents) or private_path(directory) or not directory.exists():
        return
    for parent, dirs, files in os.walk(directory, followlinks=False):
        dirs[:] = sorted(d for d in dirs if d not in {'.git', 'node_modules', '__pycache__'}
                         and not private_path(Path(parent) / d)
                         and not (Path(parent) / d).is_symlink())
        for name in sorted(files):
            path = Path(parent) / name
            if path.suffix == '.md' and not path.is_symlink() and not private_path(path):
                yield path


def scalar(value):
    value = value.strip()
    if not value:
        return ''
    if value.startswith('['):
        if not value.endswith(']'):
            raise ValueError('unterminated inline list')
        inside = value[1:-1].strip()
        if not inside:
            return []
        pieces = re.split(r',(?=(?:[^\"\']|\"[^\"]*\"|\'[^\']*\')*$)', inside)
        result = [scalar(piece) for piece in pieces]
        if any(not isinstance(x, str) or not x for x in result):
            raise ValueError('inline lists must contain nonempty scalars')
        return result
    if value.startswith(('"', "'")):
        if value.startswith("'") and value.endswith("'"):
            return value[1:-1].replace("''", "'")
        try:
            parsed = ast.literal_eval(value)
        except (SyntaxError, ValueError):
            raise ValueError('invalid quoted scalar') from None
        if not isinstance(parsed, str):
            raise ValueError('expected quoted string')
        return parsed
    if value[0] in '{}&*!|>' or ': ' in value or ' #' in value:
        raise ValueError('unsupported YAML scalar; quote the value')
    return value


def extract_frontmatter(text):
    lines = text.splitlines()
    if not lines or lines[0] != '---':
        return None
    try:
        end = lines.index('---', 1)
    except ValueError:
        raise ValueError('unclosed frontmatter') from None
    rows = []
    for line in lines[1:end]:
        if not line.strip() or line.lstrip().startswith('#'):
            continue
        if '\t' in line:
            raise ValueError('tabs are unsupported in frontmatter')
        rows.append((len(line) - len(line.lstrip()), line.strip()))

    def block(index, indent):
        is_list = rows[index][1].startswith('- ')
        result = [] if is_list else {}
        while index < len(rows) and rows[index][0] == indent:
            content = rows[index][1]
            if is_list:
                if not content.startswith('- '):
                    raise ValueError('mixed list and mapping')
                result.append(scalar(content[2:]))
                index += 1
            else:
                match = re.fullmatch(r'([A-Za-z_][A-Za-z0-9_.-]*):(?:\s+(.*))?', content)
                if not match:
                    raise ValueError('invalid mapping entry')
                key, value = match.groups()
                if key in result:
                    raise ValueError('duplicate frontmatter key')
                index += 1
                if value is not None:
                    result[key] = scalar(value)
                elif index < len(rows) and rows[index][0] > indent:
                    result[key], index = block(index, rows[index][0])
                else:
                    result[key] = []
            if index < len(rows) and rows[index][0] > indent:
                raise ValueError('unsupported nested value')
        return result, index

    if not rows:
        return {}
    if rows[0][0] != 0:
        raise ValueError('frontmatter must start at column one')
    result, consumed = block(0, 0)
    if consumed != len(rows) or not isinstance(result, dict):
        raise ValueError('frontmatter must be a mapping')
    return result


def sections(text):
    result = {}
    current = None
    fence = None
    for line in re.sub(r'<!--.*?-->', '', text, flags=re.S).splitlines():
        marker = re.match(r'^\s*(`{3,}|~{3,})', line)
        if marker:
            char = marker[1][0]
            fence = None if fence == char else char if fence is None else fence
        if fence is None and line.startswith('## '):
            current = line[3:].strip().lower()
            if current in result:
                raise ValueError('duplicate document section: ' + current)
            result[current] = []
        elif current:
            result[current].append(line)
    return {key: '\n'.join(value).strip() for key, value in result.items()}
