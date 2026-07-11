#!/usr/bin/env python3
"""Report docs/ files with missing or invalid YAML frontmatter.

Runs on the host with system Python 3.9+. Warning-only: always exits 0.
"""

import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple

DOCS_ROOT = Path(__file__).parent.parent / "docs"

SKIP = {
    "folder-rules.md",
    "runbook-local.md",
    "runbook-prod.md",
    "INDEX.md",
    "code-index.md",
    "README.md",
}

VALID_TYPES = {
    "task",
    "bug",
    "idea",
    "vision",
    "architecture",
    "decision",
    "done_long",
    "done_short",
    "research",
}
VALID_STATUSES = {"todo", "wip", "done", "draft", "blocked"}
VALID_PROJECTS = {"app", "landing", "nginx", "workspace", "cross"}

TYPES_REQUIRING_PROJECT = {"task", "bug"}


def extract_frontmatter(text: str) -> Optional[Dict]:
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---", 4)
    if end == -1:
        return None
    fm: Dict = {}
    current_list: Optional[str] = None
    for line in text[4:end].splitlines():
        if line.startswith("  - ") and current_list is not None:
            fm[current_list].append(line[4:].strip())
        elif ":" in line and not line.startswith(" "):
            key, _, val = line.partition(":")
            key = key.strip()
            val = val.strip()
            if val in ("", "[]"):
                fm[key] = []
                current_list = key if val == "" else None
            else:
                fm[key] = val.strip("'\"")
                current_list = None
        else:
            current_list = None
    return fm


def main() -> int:
    if not DOCS_ROOT.exists():
        print("No docs/ directory — nothing to validate.")
        return 0

    missing: List[str] = []
    invalid: List[Tuple[str, List[str]]] = []

    for md in sorted(DOCS_ROOT.rglob("*.md")):
        if md.name in SKIP:
            continue
        fm = extract_frontmatter(md.read_text(encoding="utf-8"))
        rel = str(md.relative_to(DOCS_ROOT.parent))

        if fm is None:
            missing.append(rel)
            continue

        errs: List[str] = []

        t = fm.get("type")
        if t is None:
            errs.append("missing 'type'")
        elif t not in VALID_TYPES:
            errs.append("unknown type '{0}'".format(t))

        s = fm.get("status")
        if s is None:
            errs.append("missing 'status'")
        elif s not in VALID_STATUSES:
            errs.append("unknown status '{0}'".format(s))

        if t in TYPES_REQUIRING_PROJECT:
            p = fm.get("project")
            if p is None:
                errs.append("missing 'project' for type '{0}'".format(t))
            elif p not in VALID_PROJECTS:
                errs.append("unknown project '{0}'".format(p))
            elif p == "cross":
                projects = fm.get("projects")
                if not projects:
                    errs.append("project: cross requires non-empty 'projects' list")
                elif isinstance(projects, list):
                    unknown = [
                        x for x in projects if x not in VALID_PROJECTS or x == "cross"
                    ]
                    if unknown:
                        errs.append("unknown projects in list: {0}".format(unknown))

        if errs:
            invalid.append((rel, errs))

    if missing:
        print("No frontmatter — {0} file(s):".format(len(missing)))
        for f in missing:
            print("  {0}".format(f))

    if invalid:
        if missing:
            print()
        print("Invalid frontmatter — {0} file(s):".format(len(invalid)))
        for f, errs in invalid:
            print("  {0}: {1}".format(f, ", ".join(errs)))

    if not missing and not invalid:
        print("OK — all docs files have valid frontmatter.")
    else:
        print("\nTotal: {0} file(s) need attention.".format(len(missing) + len(invalid)))

    build_index = Path(__file__).parent / "build-code-index.py"
    if build_index.exists():
        subprocess.run([sys.executable, str(build_index)], check=False)

    return 0


if __name__ == "__main__":
    sys.exit(main())
