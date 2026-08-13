# [project-name] Workspace — Agent Instructions

`dev/[project-name]/` stores agent context, tasks, and docs. Code lives in separate repos: `app/`, `landing/`, `nginx/`. Search with explicit repo paths because `.gitignore` excludes them; use repo-prefixed task paths such as `app/src/...`.

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
4. Create, without overwriting, `docs/backlog/todo/dd-mm-yy-<project>-<slug>.md` using the local date, kebab-case slug, and folder rules.
5. Add frontmatter: `type: task`, `status: todo`, `project`, ISO `created`; useful `area`, repo-prefixed `related_code`, `related_docs`, and `source.kind`; `projects` for `cross`. Do not invent optional values.
6. Add todo status and today's last-checked date. Fill every contract section without placeholders. Set numeric file/dependency/abstraction limits, exact executable verification (`<repo>/scripts/verify.sh` or `scripts/verify.sh`), and every example stop condition.
7. Run both validators and resolve every warning concerning the new file. Do not move it to WIP, implement it, or commit it.
8. Reply exactly: `Task created: docs/backlog/todo/<filename>`

<a id="start-task-equivalent"></a>

## `/start-task` Equivalent

When the user asks to start a task:

1. Find a supplied filename/substring in `docs/backlog/todo/`; if absent, list files alphabetically and ask which to start. Never sort by priority.
2. Move it to `docs/wip/`, preserving the full filename, and reply exactly: `Task moved: docs/wip/<filename>`
3. Read in order: `PROJECT_MAP.md`, `CLAUDE.md`, the WIP task, then affected repo maps/context if present.
4. Freeze `Non-goals`, `Invariants`, `Change Budget`, and `Verification`; show a 3–7 step plan and wait for confirmation.
5. Implement the confirmed plan under repo-local `AGENTS.md`; do not expand the frozen contract without a new external fact.
6. When implementation and required checks finish, say: `Done. You can close the task with /complete-task.`

<a id="complete-task-equivalent"></a>

## `/complete-task` Equivalent

When the user asks to complete a task:

1. Identify one active task in `docs/wip/`; if unclear, list tasks and ask. Read it and preserve its filename for both done records.
2. Determine targets: one repo for `app|landing|nginx`, none for `workspace`, or `projects` for `cross`.
3. Run every command in task `Verification`; also run `scripts/verify.sh` for `workspace` or each `<repo>/scripts/verify.sh` if absent. Record concise evidence as it becomes available. Any failed command blocks closure.
4. For each code repo, inspect status/diff against `Change Budget`, stage only task-related paths (never `.env`), commit `feat: ...` or `fix: ...`, and record the short hash; with no changes, record the relevant existing commit.
5. For `workspace`, inspect status/diff/budget and commit all and only task-related implementation paths first, excluding WIP/completion records; record its hash. This separate commit avoids trying to embed a commit's own hash in itself.
6. Before done records, finalize evidence (command output, diff/path, or commit) for every `Done When` item; missing or unverifiable evidence blocks closure. Create `docs/done/long/<filename>` from the task with a `**Commits:**` list and `## Verification Evidence`; append `[Short summary](../short/<filename>)`. Create `docs/done/short/<filename>` with title, commits, `## What Changed`, evidence summary, `[Full plan](../long/<filename>)`, and `Closes #N` only for an issue.
7. Delete the WIP original. Run `scripts/build-done-index.py` if present; stage only the two done records, task backlog deletion, generated indexes/maps, and other task-related completion docs. Commit `docs: complete <slug>`.
8. Report created/deleted files, verification evidence, and all commit hashes.

## Stop Rule

A task is done only when every `Done When` item has evidence; tests/build/types/analyzers and applicable gates pass; no confirmed `blocker`/`high` remains; the diff fits `Change Budget`; and at most one review pass ran. A further iteration requires new external evidence. Contract/review/severity rules: `docs/product/architecture/verification-contract.md` and `docs/folder-rules.md`.

## Docs

Workspace `docs/` is product documentation; rules live in `docs/folder-rules.md`; `docs/wip/` is gitignored. Repo-local `<repo>/docs/` is archived reference only.

## Workspace Scripts

- `scripts/verify.sh` — strict executable gate for workspace tasks.
- `scripts/build-done-index.py` — regenerates `docs/done/INDEX.md` in `/complete-task`.
- `scripts/validate-docs-frontmatter.py`, `scripts/check-task-contract.py`, `scripts/check-context-budget.sh` — warning-only directly; `--strict` is used by the gate.
- `scripts/build-code-index.py` — builds the `related_code` reverse index.
- `scripts/check-no-flow-duplication.sh` — rejects task-flow algorithms outside this file.

## LLM Memory

Auto-memory is keyed to `dev/[project-name]/`. Tag new facts with `app`, `landing`, `nginx`, or `workspace` unless workspace-wide.
