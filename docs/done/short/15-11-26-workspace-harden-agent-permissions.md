---
type: done_short
status: done
project: workspace
created: 2026-11-19
area:
  - security
  - agent-permissions
related_docs:
  - AGENTS.md
  - docs/folder-rules.md
source:
  kind: observation
---

# Harden Claude Code Permission Rules And Add A Bash Guard Hook

**Commits:**
- workspace `7670274` — "fix: enforce agent guards and deny private reads outside workspace"
- workspace `cb5554a` — "fix: preserve placeholder access with native file-tool guards"

## What Changed

- Enforce private-path checks on Bash and native file tools, including symlinks; synchronize workspace/template settings and destructive-command denies.
- Preserve `.env.example` using relative native exceptions and exact global hook checks compatible with Claude Code 2.1.285.
- Require confirmation for SSH, interpreted commands and internal directory searches; block private paths/globs and external directory searches.

## Verification Evidence

- All three task Verification commands passed; 29 regressions, strict docs/context gates and six-file aggregate scope passed.
- Actual default-permission Claude Code 2.1.285 canary: Read/Grep/cat/Python on the synthetic private path blocked; internal and external `.env.example` Reads allowed.
- Final reviewed snapshot: `cb5554a`, `NO_BLOCKING_FINDINGS`. Native tool transcript is preserved in the long record.

---
[Full plan](../long/15-11-26-workspace-harden-agent-permissions.md)
