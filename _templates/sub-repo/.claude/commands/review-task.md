Review the active task against its contract. Evidence only, one pass.

Full policy and rationale: workspace `../docs/product/architecture/verification-contract.md` → Review policy.

First decide **whether to intervene at all**, as a separate step. If there is no evidenced `blocker` or `high`, reply exactly `NO_BLOCKING_FINDINGS` and change nothing.

A finding is admissible only if it carries all five:

1. the violated contract item (`Non-goals`, `Invariants`, `Change Budget`, `Verification`, or `Done When`);
2. the exact file and code region;
3. a reproducible scenario, failing test, or tool output — for this repo, run `scripts/verify.sh`;
4. a minimal fix;
5. severity: `blocker`, `high`, `medium`, or `speculative`.

Not defects: "I would do it differently", "may be needed later", "the architecture could be improved", style preferences, and anything you cannot demonstrate by running something.

Do not rewrite working code and do not emit a new full version of any file. Propose the minimal fix for admissible findings only.

After the pass: `medium` findings go to workspace `../docs/backlog/todo/`, `speculative` to `../docs/ideas/`, cosmetic remarks are dropped.

Run once. A further pass requires new external evidence.
