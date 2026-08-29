# [project-name] Workspace — Agent Instructions

`dev/[project-name]/` stores agent context/tasks/docs. Code repos `app/`, `landing/`, and `nginx/` are gitignored; search explicit repo paths and use task paths like `app/src/...`.

## Local Permissions

- Never read `.env`, `.env.*`, `.ssh/`, `id_rsa*`, `id_ed25519*`, `*.pem`, or `*.key`; `.env.example` may be read and edited.
- Never run `rm -rf`, `git push --force`, `git reset --hard`, `chmod 777`, `sudo rm`, or `curl/wget ... | bash`.
- For dangling Docker layers use only `docker image prune -f --filter "dangling=true"`; never prune systems/volumes or remove named volumes unless explicitly requested.

## Security

- Never hardcode, print, or log secrets. Keep them only in untracked `.env`; document placeholders in `.env.example`. Never use `echo $SECRET`, `env`, `printenv`, or `docker compose config`; validate with `config --quiet`.
- Validate external input at boundaries; use parameterized queries; never interpolate user data into shell commands or HTML.
- Use least-privilege containers: no privileged/host network, publish only required ports, prefer non-root images and maintained dependencies.
- Start SSH read-only (`ps`, logs, `git log`). Firewall, `sshd_config`, TLS, users, and server `.env` require explicit scope. Never weaken nginx HTTPS/security/rate limits as a side effect.
- Before deploy, run `docs/runbook-prod.md` checks and inspect the outgoing diff for secrets/debug leftovers.

<a id="create-task-equivalent"></a>

## `/create-task` Equivalent

When asked to create, draft, or formalize a task:

1. Read `PROJECT_MAP.md`, `CLAUDE.md`, `docs/folder-rules.md`, and `docs/product/architecture/verification-contract.md`.
2. Choose `project: app|landing|nginx|workspace|cross`; list `projects` for `cross`. Read affected repo maps/context if present, then only relevant code/docs. Never read secret-like files.
3. Define outcome, boundaries, invariants, paths, and acceptance behavior. Ask only when missing information materially changes scope; otherwise record assumptions in `Context`.
4. Run `bash scripts/new-task.sh <project> <slug> [cross-project ...]` for dates/name and mandatory frontmatter without overwrite. Add only useful optional metadata.
5. Add todo status/last-checked date and fill every contract section without placeholders. Set numeric file/dependency/abstraction limits, exact verification (`<repo>/scripts/verify.sh` or `scripts/verify.sh`), and every example stop condition.
6. Run both validators and resolve every warning for the new file. Do not start, implement, or commit it.
7. Reply exactly: `Task created: docs/backlog/todo/<filename>`

<a id="start-task-equivalent"></a>

## `/start-task` Equivalent

When the user asks to start a task:

1. Find a supplied filename/substring in `docs/backlog/todo/`; if absent, list files alphabetically and ask which to start. Never sort by priority.
2. Move it to `docs/wip/`, preserving the full filename, and reply exactly: `Task moved: docs/wip/<filename>`
3. Read in order: `PROJECT_MAP.md`, `CLAUDE.md`, the WIP task, then affected repo maps/context if present.
4. Freeze `Non-goals`, `Invariants`, `Change Budget`, and `Verification`; show a 3–7 step plan and wait for confirmation.
5. After confirmation, run `bash scripts/task-branch.sh start <repo> <slug>` for `app|landing|nginx`, once per code repo in `projects` for `cross`, and not for `workspace`; `<slug>` is the filename tail after date/project and before `.md`.
6. Implement under repo-local `AGENTS.md`; expand the frozen contract only for a new external fact.
7. When implementation and required checks finish, say: `Done. You can close the task with /complete-task.`

<a id="complete-task-equivalent"></a>

## `/complete-task` Equivalent

When the user asks to complete a task:

1. Identify one active task in `docs/wip/`; if unclear, list tasks and ask. Read it and preserve its filename for both done records.
2. Determine targets: one repo for `app|landing|nginx`, none for `workspace`, or `projects` for `cross`.
3. Run every command in task `Verification`; also run `scripts/verify.sh` for `workspace` or each `<repo>/scripts/verify.sh` if absent. Record concise evidence. Any failed command blocks closure.
4. Run the mandatory review pass per [`/review-task`](#review-task-equivalent); then make only minimal fixes for admissible findings and re-run affected verification.
5. In each code repo, inspect status/diff/budget, stage only task paths, run `bash scripts/check-staged-paths.sh <repo>`, commit `feat: ...` or `fix: ...`, record its short hash (or a relevant existing commit if unchanged), then run `bash scripts/task-branch.sh finish <repo> <slug>`; it guards, merges locally, stops on conflict, and deletes the branch.
6. For workspace implementation changes, stage only task paths excluding WIP/completion records, run `bash scripts/check-staged-paths.sh .`, commit, and record its hash. This separate commit avoids a self-referential hash.
7. Finalize reproducible evidence for every `Done When` item; missing/unverifiable evidence blocks closure. Run `bash scripts/new-done-record.sh docs/wip/<filename> <repo> <hash> "<subject>" [...]`, then check evidenced items, fill `What Changed`/evidence prose, and add `Closes #N` only for an issue.
8. Delete the WIP original; run `scripts/build-done-index.py` if present. Stage only completion records, backlog deletion, generated indexes/maps, and related completion docs; run `bash scripts/check-staged-paths.sh .`, then commit `docs: complete <slug>`.
9. Report created/deleted files, verification evidence, review-pass outcome, and all commit hashes.

<a id="review-task-equivalent"></a>

## `/review-task` Equivalent

One evidence-only pass over the active `docs/wip/` task, standalone or as completion step 4.

Follow `docs/product/architecture/verification-contract.md` → Review policy in full: decide whether to intervene as a separate first step; admit only findings carrying all five required parts; judge against the frozen contract, never taste; never rewrite working code or emit a new full version of a file. Without an admissible `blocker`/`high`, reply exactly `NO_BLOCKING_FINDINGS` and change nothing. Route the rest per `docs/folder-rules.md` → Severity Routing. Run once.

## Stop Rule

A task is done only when every `Done When` item has evidence; tests/build/types/analyzers and applicable gates pass; no confirmed `blocker`/`high` remains; the diff fits `Change Budget`; and the review pass ran exactly once. Another iteration requires new external evidence.

## Docs

Workspace `docs/` is product documentation; rules live in `docs/folder-rules.md`; `docs/wip/` is gitignored. Repo-local `<repo>/docs/` is archived reference only.

## Workspace Scripts

- `scripts/verify.sh` — strict executable gate for workspace tasks.
- `scripts/new-task.sh`, `scripts/task-branch.sh`, `scripts/check-staged-paths.sh`, `scripts/new-done-record.sh` — deterministic lifecycle mechanics used above.
- `scripts/build-done-index.py`, `scripts/build-code-index.py` — generated done/code indexes.
- Validators warn where supported; the gate is strict. `scripts/check-no-flow-duplication.sh` keeps this file canonical.

## LLM Memory

Auto-memory is keyed to `dev/[project-name]/`. Tag new facts with `app`, `landing`, `nginx`, or `workspace` unless workspace-wide.
