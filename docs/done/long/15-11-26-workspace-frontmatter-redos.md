---
type: done_long
status: done
phase: completed
project: workspace
created: 2026-11-15
area:
  - security
  - quality-gates
related_docs:
  - docs/folder-rules.md
source:
  kind: observation
completion_validation: required
---

**Commits:**
- workspace `bd23a38` — "fix: parse frontmatter inline lists in linear time"


# Remove Quadratic Parsing From The Frontmatter Reader

**Status:** done
**Last checked:** 2026-11-16

## Goal

Make `scalar()` in `scripts/workspace_rules.py` parse inline lists in linear time and cap frontmatter line length, so a single crafted task or doc file cannot stall `scripts/verify.sh`.

## Context

Finding from the security review on 2026-11-15 (severity `medium`). `scalar()` splits inline lists with `re.split(r',(?=(?:[^\"\']|\"[^\"]*\"|\'[^\']*\')*$)', inside)`; the lookahead rescans to the end of the value at every comma. Measured on 2026-11-15 with `python3 -B`: 4 000 commas → 0.58 s, 8 000 → 2.3 s, 16 000 → 9.3 s (quadratic). Every markdown file under `docs/` is parsed by `validate-docs-frontmatter.py`, `check-task-contract.py`, and the index builders, so one 32 KB frontmatter line in any task blocks the workspace gate for minutes. Unterminated-quote and escaped-quote inputs fail fast and are not affected.

Assumptions recorded instead of asked:

- Replace the regex split with a single-pass character scanner that tracks quote state; semantics for valid input (quoted commas preserved, `''` escape in single quotes, `ast.literal_eval` for double quotes) stay identical.
- Frontmatter line limit: 1 024 characters; longer lines raise `ValueError('frontmatter line too long')`, which the validators already report.

## Non-goals

- Do not widen the supported YAML subset.
- Do not change `extract_frontmatter()` output for any file currently in `docs/`.
- Do not touch the markdown `sections()` parser.

## Invariants

- All `Documents` tests in `scripts/test-workflow.py` keep passing unchanged.
- `python3 -B scripts/validate-docs-frontmatter.py --strict` reports the same result set for the current `docs/` tree before and after.
- No new runtime dependencies; Python 3.9 stdlib only.

## Change Budget

- At most 3 workspace files modified, 0 new.
- No new dependencies.
- No new scripts; no new abstraction layers.

## Task Paths

- `scripts/workspace_rules.py`
- `scripts/test-workflow.py`
- `docs/folder-rules.md`

## Implementation Steps

1. Implement `split_inline_list(inside)` as a quote-aware single pass; use it in `scalar()`.
2. Enforce the line-length cap in `extract_frontmatter()`.
3. Add a regression test: 16 000-comma inline list parses in under 0.5 s; a 2 000-character line is rejected; existing valid/invalid fixtures unchanged.
4. Note the limit in `docs/folder-rules.md` → Frontmatter.

## Verification

```bash
bash scripts/verify.sh
python3 -B scripts/test-workflow.py
```

## Done When

- [x] The timing regression test passes (16 000-element inline list < 0.5 s). — Evidence: `Documents.test_large_inline_list_parses_quickly` passes for 16 001 elements (16 000 commas); direct measurement 0.017677 s.
- [x] Over-long frontmatter lines are rejected with a clear error reported by `validate-docs-frontmatter.py --strict`. — Evidence: `Documents.test_frontmatter_line_length_boundary` accepts 1 024 and rejects 1 025/2 000+ characters, including comments/blank lines; `Fixtures.test_frontmatter_validator_reports_long_lines` asserts exit 1 and `docs/backlog/todo/task.md: frontmatter line too long`.
- [x] `Verification` commands pass; the diff stays within `Change Budget`. — Evidence: `bash scripts/verify.sh` exits 0 (19 tests); `python3 -B scripts/test-workflow.py` exits 0 (19 tests); `git diff --check` passes; exactly 3 approved implementation files modified, no new implementation files/dependencies/scripts/layers.
- [x] The final implementation snapshot has recorded review evidence. — Evidence: `Review Evidence` below identifies the reviewed HEAD and approved-path diff SHA-256; NO_BLOCKING_FINDINGS.

## Related

- Review origin: security review 2026-11-15, step 9.


## What Changed

- Replaced the quadratic inline-list regex with a quote-aware linear scanner, preserving quoted commas and escapes.
- Enforced a 1 024-character frontmatter line limit with a clear validation error; documented the limit.
- Added performance, quoting, line-boundary and validator integration regressions within the three-file implementation budget.

## Verification Evidence

- 2026-11-16: `bash scripts/verify.sh` exited 0; all workspace gates passed, 19 tests passed.
- `python3 -B scripts/test-workflow.py` exited 0; 19 tests passed. Existing Documents test methods remain unchanged.
- Strict frontmatter validator before and after implementation: exit 0, `OK — all docs files have valid frontmatter.`
- Metadata comparison: all 28 current Markdown docs parsed identically with the original HEAD parser and the final parser (task status/folder changes are intentional lifecycle bookkeeping).
- Performance measurement: 16 000 commas / 16 001 elements parsed in 0.017677 s.
- `git diff --check` exited 0. Approved implementation diff: 3 files, 80 insertions, 2 deletions. Saved Exa startup preference was separately user-authorized setup, outside implementation scope.

Reproduce metadata compatibility on the current docs tree from the workspace root:

```bash
python3 -B - <<'PYCODE'
import subprocess
import sys
from pathlib import Path
sys.path.insert(0, 'scripts')
import workspace_rules as current
original = {}
exec(subprocess.check_output(['git', 'show', '9a2d57f3075ed73793848c8e0200af137e308631:scripts/workspace_rules.py'], text=True), original)
paths = list(current.markdown_files(Path('docs')))
for path in paths:
    text = path.read_text()
    assert current.extract_frontmatter(text) == original['extract_frontmatter'](text), str(path)
print('Identical metadata:', len(paths), 'documents')
PYCODE
```

## Review Evidence

Completion reused the unchanged review. Implementation commit: `bd23a38`; the three committed file hashes match the reviewed snapshot. Both required Verification commands rerun successfully at closure (19 tests each).

2026-11-16 contract-focused review of the final implementation: **NO_BLOCKING_FINDINGS**. No non-blocking findings recorded.

- Workspace HEAD: `9a2d57f3075ed73793848c8e0200af137e308631`.
- SHA-256 of `git diff -- scripts/workspace_rules.py scripts/test-workflow.py docs/folder-rules.md`: `d4b5478c7e2425ecbe813bea42bc02ed1e56c70a83e2c2bdee7d8b74d5ed481d`.
- `scripts/workspace_rules.py` SHA-256: `4e96ce8602f0ace52e1ab6d6229e5dd70f3550cfb47aa42ffa7c66e232e0c734`.
- `scripts/test-workflow.py` SHA-256: `ba13b0c92a45c09391300a5afc17c40a1caaf862c6a7a67edb07d64206c9b89c`.
- `docs/folder-rules.md` SHA-256: `9ded30053e4bf8afeebfd2a31ca2341292ba54ef6dc72bff5a5decbe1f697283`.
- Examined the bounded diff against all frozen contract sections. Scanner advances monotonically, slices disjoint pieces, preserves quoted commas, doubled single quotes, double-quote escapes, and plain apostrophes. Boundary checks run before skipping comments/blank lines and only inside frontmatter. Existing scalar decoding and sections parser remain intact; no dependencies or abstraction layers added.
- Executable evidence covers performance, error reporting through the real validator, 1 024/1 025-character boundaries, malformed/quoted values, current-doc compatibility and all workspace gates.

[Short summary](../short/15-11-26-workspace-frontmatter-redos.md)
