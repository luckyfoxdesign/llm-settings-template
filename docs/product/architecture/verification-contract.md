---
type: architecture
status: done
created: 2026-08-04
area:
  - workflow
  - quality-gates
related_docs:
  - docs/folder-rules.md
  - AGENTS.md
---

# Verification Contract

## Decision

A task ends when **external, executable checks pass** — not when a model judges the code good enough.

Models propose changes. The stop criteria live outside the model: a frozen task contract, deterministic gates, a bounded diff, and at most one evidence-only review pass.

```text
frozen task contract
        ↓
one coding agent
        ↓
executable gates (verify.sh)
        ↓
one evidence-only reviewer
        ↓
minimal fixes → re-run gates
        ↓
STOP
```

## Problem

Handing a task between models does not converge. The next model may fix a defect, change nothing, or break working code. Prompts like "find the flaws" have no admissible answer `no flaws`, no cost for false positives, and no definition of a defect — so the model generates plausible criticism instead of testing a hypothesis.

Chaining `Sonnet → Opus → GPT → Opus → ...` increases the volume of opinion, not the number of independent proofs.

## Evidence

- Across 15 coding agents, structural degradation grew in 77% of trajectories and redundancy in 75.5%; agent-generated code ran ~2.3x more verbose than ordinary open-source code — while still passing tests.
- Reviews of self-correction work find reliable correction appears only with trustworthy external feedback: program output, a test, a tool, a knowledge base, or formal verification. Re-prompting another model showed no reliable self-correction.
- A controlled cross-model review study on 116 algorithmic tasks: in one model order pass rate rose 71.6% → 89.7%; in the reverse order the reviewer *dropped* it 91.4% → 82.8%, breaking more correct solutions than it fixed. There is no general rule that a second model improves the first.
- LLM judges carry position, style, and self-preference bias; stronger general capability does not reduce self-preference bias.
- Elaborate review prompts can make things worse: asking for detailed explanations and suggested fixes increased the rate of wrongly declaring a correct implementation incorrect.

Condensed from a research report on cross-model review, 2026-08-04. Figures come from that report's cited studies and are scoped to their benchmarks — treat them as direction, not as thresholds.

## Design

Three layers, each owned by exactly one place. Nothing is duplicated across repos.

| Layer | Owner | Contents |
|---|---|---|
| Protocol | Workspace `AGENTS.md` + this file | Contract shape, review policy, stop rule, severity routing |
| Gates | `scripts/verify.sh` and `<repo>/scripts/verify.sh` | Concrete pass/fail commands and change budgets |
| Contract | The task file in `docs/wip/` | Per-task goal, non-goals, invariants, budget, verification |

The protocol is universal and written once. Code gates are repo-specific because only `app/`, `landing/`, and `nginx/` know their test, lint, type-check, and build commands. Workspace tasks use root `scripts/verify.sh`, which runs workspace validators in strict mode instead of Docker.

### Executable gate

Each repo exposes one entrypoint:

```bash
<repo>/scripts/verify.sh
```

It runs that repo's gates in order and exits non-zero on the first failure. This matters more than any prose rule: while gates are described in text, a model can reinterpret them; as a single exit code, it cannot. The script is listed in the repo `PROJECT_MAP.md` `Commands` block.

The workspace exposes the same contract at `scripts/verify.sh`. Its component
scripts stay warning-only for exploratory use; the wrapper opts into strict
exit codes and stops on the first violation.

### Task contract

Frozen before implementation, changed only on new external fact — a contradicting test, a user requirement, API documentation, a production incident, or a confirmed architectural constraint.

| Section | Purpose |
|---|---|
| `Goal` | Expected outcome, one or two sentences |
| `Context` | Origin, known facts, constraints |
| `Non-goals` | What must not change — public API, adjacent components, general refactors |
| `Invariants` | What must still hold — existing clients, storage format, no secrets in logs |
| `Change Budget` | Max production files, no new dependencies, no new abstraction layers without a test that requires them |
| `Verification` | The exact commands that produce the pass/fail signal |
| `Done When` | The stop conditions below |

`Change Budget` is an engineering fuse, not a universal threshold. Objectivity comes from fixing it **before the model sees the implementation**, not from the number itself.

At completion, each `Done When` item must cite concise evidence: command output,
a diff/path, or a commit. An unchecked item and an item with no reproducible
evidence are both failures; prose confidence is not evidence.

### Review policy

One review pass, against the contract only. A finding is admissible only if it carries:

1. the violated contract item;
2. the exact file and code region;
3. a reproducible scenario, failing test, or tool output;
4. a minimal fix;
5. severity: `blocker`, `high`, `medium`, or `speculative`.

"I would do it differently", "may be needed later", and "the architecture could be improved" are not defects. With no evidenced `blocker`/`high`, the reviewer answers `NO_BLOCKING_FINDINGS` and changes nothing.

The reviewer decides **whether to intervene** as a separate step before deciding what to change. In the cross-model study, harmful reviews clustered where the reviewer was obliged to emit a new final program and therefore rewrote already-correct code.

### Stop rule

A task is done when all of the following hold at once:

- every `Done When` item has recorded evidence;
- required acceptance and regression tests pass;
- build, type check, and required analyzers pass;
- no confirmed `blocker`/`high` findings;
- the diff stays inside `Change Budget`;
- at most one reviewer pass has run.

After that: `medium` findings go to `docs/backlog/todo/`, `speculative` findings go to `docs/ideas/`, cosmetic remarks are dropped. A further iteration requires new external evidence.

## Rejected Alternatives

| Alternative | Why rejected |
|---|---|
| Cross-model ping-pong until agreement | Adds opinion, not proof; direction-dependent and can regress working code |
| Backtracking / tree search over variants | Answers "how to explore and roll back", not "which variant is correct"; still needs an external scoring function, and an LLM scorer just moves the uncertainty up a level. Expensive in tokens for this workspace's task sizes |
| Formal verification | Justified for money movement, permissions, cryptography, concurrency, safety-critical logic. Not worth the cost for typical tasks here |
| Richer review prompts | Measurably increases false "this is wrong" verdicts |

## Consequences

This does not guarantee the absence of defects. It guarantees something more practical: a pre-agreed set of checkable commitments was met.

The test suite is a partial specification, so verification must cover prior behavior, boundaries, errors, and compatibility — not only the happy path.

Human judgement stays narrow: confirm product meaning, approve irreversible architectural decisions, resolve requirement conflicts, accept residual risk. Not reading thousands of lines of agent reasoning.

Generators and critics will change. The durable principle is that completion criteria sit outside the model.

## Implementation

Implemented through workspace task lifecycle rules, strict root/repo
`scripts/verify.sh` entrypoints, and task-local `Verification` plus `Done When`.
