#!/usr/bin/env python3
"""Report docs/ files with missing or invalid YAML frontmatter.

Runs on the host with system Python 3.9+. Warning-only unless --strict is used.
"""

import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from workspace_rules import extract_frontmatter, markdown_files

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


def main() -> int:
    args = sys.argv[1:]
    if args not in ([], ["--strict"]):
        print("Usage: validate-docs-frontmatter.py [--strict]", file=sys.stderr)
        return 2
    strict = args == ["--strict"]

    if not DOCS_ROOT.exists():
        print("No docs/ directory — nothing to validate.")
        return 0

    missing: List[str] = []
    invalid: List[Tuple[str, List[str]]] = []

    for md in sorted(markdown_files(DOCS_ROOT)):
        if md.name in SKIP:
            continue
        rel = str(md.relative_to(DOCS_ROOT.parent))
        try:
            fm = extract_frontmatter(md.read_text(encoding="utf-8"))
        except ValueError as error:
            invalid.append((rel, [str(error)]))
            continue

        if fm is None:
            missing.append(rel)
            continue

        errs: List[str] = []

        t = fm.get("type")
        if t is None:
            errs.append("missing 'type'")
        elif not isinstance(t, str) or t not in VALID_TYPES:
            errs.append("invalid type")

        s = fm.get("status")
        if s is None:
            errs.append("missing 'status'")
        elif not isinstance(s, str) or s not in VALID_STATUSES:
            errs.append("invalid status")

        if isinstance(t, str) and t in TYPES_REQUIRING_PROJECT:
            p = fm.get("project")
            if p is None:
                errs.append("missing 'project' for type '{0}'".format(t))
            elif not isinstance(p, str) or p not in VALID_PROJECTS:
                errs.append("invalid project")
            elif p == "cross":
                projects = fm.get("projects")
                if not isinstance(projects, list) or not projects:
                    errs.append("project: cross requires non-empty 'projects' list")
                elif isinstance(projects, list):
                    unknown = [
                        x for x in projects if not isinstance(x, str) or x not in VALID_PROJECTS or x == "cross"
                    ]
                    if unknown:
                        errs.append("invalid project in projects list")
                    elif len(set(projects)) != len(projects):
                        errs.append("duplicate projects")

        if t in ("task", "bug"):
            expected = "wip" if "wip" in md.relative_to(DOCS_ROOT).parts else "todo" if md.parent.name == "todo" else None
            if expected and s not in (expected, "blocked"):
                errs.append("status must match task folder")

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

    return 1 if strict and (missing or invalid) else 0


if __name__ == "__main__":
    sys.exit(main())
