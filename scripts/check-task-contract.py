#!/usr/bin/env python3
"""Report task files that are missing verification-contract sections.

Contract shape: docs/product/architecture/verification-contract.md -> Task contract.
Runs on the host with system Python 3.9+. Warning-only: always exits 0.
"""

import re
import sys
from pathlib import Path
from typing import List, Set, Tuple

ROOT = Path(__file__).parent.parent

SCAN_DIRS = [
    ROOT / "docs" / "wip",
    ROOT / "docs" / "backlog" / "todo",
]

# Marker that opts a file out of the check, for shape examples and stubs.
# Only counts inside an HTML comment, so a task may discuss the marker in prose.
SKIP_MARKER = "TEMPLATE-EXAMPLE"
HTML_COMMENT = re.compile(r"<!--.*?-->", re.DOTALL)

REQUIRED_SECTIONS = [
    "Goal",
    "Context",
    "Non-goals",
    "Invariants",
    "Change Budget",
    "Verification",
    "Done When",
]


def is_template_example(text: str) -> bool:
    return any(SKIP_MARKER in c for c in HTML_COMMENT.findall(text))


def headings(text: str) -> Set[str]:
    found: Set[str] = set()
    for line in text.splitlines():
        if line.startswith("## "):
            found.add(line[3:].strip().lower())
    return found


def missing_sections(text: str) -> List[str]:
    present = headings(text)
    return [s for s in REQUIRED_SECTIONS if s.lower() not in present]


def main() -> int:
    incomplete: List[Tuple[str, List[str]]] = []
    checked = 0

    for directory in SCAN_DIRS:
        if not directory.exists():
            continue
        for md in sorted(directory.glob("*.md")):
            text = md.read_text(encoding="utf-8")
            if is_template_example(text):
                continue
            checked += 1
            missing = missing_sections(text)
            if missing:
                incomplete.append((str(md.relative_to(ROOT)), missing))

    print("")
    print("=== Task contract check ===")
    print("")

    if checked == 0:
        print("No task files to check.")
        return 0

    if incomplete:
        print("Missing contract sections — {0} file(s):".format(len(incomplete)))
        for rel, missing in incomplete:
            print("  {0}: {1}".format(rel, ", ".join(missing)))
        print("")
        print("Freeze these sections before implementation, not after.")
    else:
        print("OK — {0} task file(s) carry a full contract.".format(checked))

    print("")
    return 0


if __name__ == "__main__":
    sys.exit(main())
