# [project-name] Workspace — Agent Instructions

`dev/[project-name]/` stores agent context, tasks, docs. Code lives in separate repos: `app/`, `landing/`, `nginx/`. Search with explicit repo paths because `.gitignore` excludes them. Use repo-prefixed task paths such as `app/src/...`.

## Local Permissions

- Never read `.env`, `.env.*`, `.ssh/`, `id_rsa*`, `id_ed25519*`, `*.pem`, or `*.key`; `.env.example` may be read and edited.
- Never run destructive commands: `rm -rf`, `git push --force`, `git reset --hard`, `chmod 777`, `sudo rm`, `curl/wget ... | bash`.
- For dangling Docker layers run only `docker image prune -f --filter "dangling=true"`; never run `docker system prune -a`, `docker volume prune`, or remove named volumes unless explicitly requested.

## Security

- Never hardcode, print, or log secrets. They live only in untracked `.env`; document new variables as placeholders in `.env.example`. Never use `echo $SECRET`, `env`, `printenv`, or `docker compose config`; validate with `config --quiet`.
- Treat external input as untrusted: validate at boundaries, use parameterized queries, never interpolate user data into shell commands or HTML.
- Use least-privilege containers: no privileged or host network; publish only required ports; prefer non-root images. Prefer maintained dependencies and check advisories.
- Start SSH read-only (`ps`, logs, `git log`). Firewall, `sshd_config`, TLS, users, and server `.env` are off-limits unless explicitly requested.
- Never weaken nginx HTTPS redirects, security headers, or rate limits as a side effect.
- Before deploy, run `docs/runbook-prod.md` checks and inspect the outgoing diff for secrets/debug leftovers.

<a id="create-task-equivalent"></a>

## `/create-task` Equivalent

When asked to create, draft, or formalize a task:

1. Read `PROJECT_MAP.md`, `CLAUDE.md`, `docs/folder-rules.md`, and `docs/product/architecture/verification-contract.md`.
2. Choose `project: app|landing|nginx|workspace|cross`; list `projects` for `cross`. Read affected repo maps/context if present, then only relevant code/docs. Never read secret-like files.
3. Define outcome, boundaries, invariants, paths, and acceptance behavior. Ask only when missing information materially changes scope; otherwise record assumptions in `Context`.
4. Create `docs/backlog/todo/dd-mm-yy-<project>-<slug>.md` with local date, kebab-case slug, and folder rules. On collision, use a more specific slug; never overwrite.
5. Add frontmatter: `type: task`, `status: todo`, `project`, ISO `created`; useful `area`, repo-prefixed `related_code`, `related_docs`, and `source.kind` when known; `projects` for `cross`. Do not invent optional values.
6. Add todo status and today's last-checked date. Fill every example section without placeholders. Set a numeric budget plus dependency/abstraction limits. Use `<repo>/scripts/verify.sh`, or relevant workspace scripts; retain all example stop conditions.
7. Do not move the task to `docs/wip/`, implement it, or commit it. Run `python3 scripts/validate-docs-frontmatter.py` and `python3 scripts/check-task-contract.py`; resolve every warning concerning the new file.
8. Reply exactly: `Task created: docs/backlog/todo/<filename>`

<a id="start-task-equivalent"></a>

## `/start-task` Equivalent

When the user asks to start a task:

1. If a task name/substring is provided, find the matching file in `docs/backlog/todo/`.
2. If no task is provided, list files in `docs/backlog/todo/` in alphabetical order and ask which one to start. Do not sort by priority.
3. Move the chosen file to `docs/wip/`, preserving the full filename.
4. Reply exactly: `Task moved: docs/wip/<filename>`
5. Read in order: `PROJECT_MAP.md`, `CLAUDE.md`, the WIP task, then affected repo maps/context if present.
6. Freeze the contract: fill `Non-goals`, `Invariants`, `Change Budget`, and `Verification` in the task file. Show a short 3-7 step plan and wait for user confirmation before implementation.
7. Implement according to the plan and repo-local `AGENTS.md`.
8. When done, say: `Done. You can close the task with /complete-task.`

<a id="complete-task-equivalent"></a>

## `/complete-task` Equivalent

When the user asks to complete a task:

1. Identify the active task in `docs/wip/`. If unclear, list active tasks and ask.
2. Preserve the full filename for `docs/done/long/<filename>` and `docs/done/short/<filename>`.
3. Read the task file from `docs/wip/`.
4. Determine affected repos from frontmatter: one for `app|landing|nginx`, none for `workspace`, or the `projects` list for `cross`.
5. For each affected code repo: check `git status`; show `<repo>/scripts/verify.sh` output; compare the diff to `Change Budget`; show and stage only relevant changes (never `.env`), commit as `feat: ...` or `fix: ...`, and record the short hash. With no changes, record `git log -1 --oneline`.
6. Create `docs/done/long/<filename>` from the WIP task and prepend a `**Commits:**` list (`- app \`abc1234\` — "feat: description"`). Always use a list, even for one commit. For `workspace`, add a placeholder and fill it after the workspace docs commit.

7. Append to the long file: `[Short summary](../short/<filename>)`
8. Create `docs/done/short/<filename>` with title, `**Commits:**` list, `## What Changed`, `[Full plan](../long/<filename>)`, and `Closes #N` only for a GitHub issue.
9. Delete the original file from `docs/wip/`.
10. From workspace root, run `scripts/build-done-index.py` if present, stage `docs/done/ docs/backlog/ PROJECT_MAP.md`, and commit as `docs: complete <slug>`.
11. Report created files, deleted file, and commit hashes.

## Stop Rule

A task is done when tests, build, types, and analyzers pass; no confirmed `blocker`/`high` remains; the diff fits `Change Budget`; at most one review pass ran.

A further iteration requires new external evidence. Contract shape, review policy, and severity routing: `docs/product/architecture/verification-contract.md` and `docs/folder-rules.md`.

## Docs

Workspace `docs/` is product documentation. Rules live in `docs/folder-rules.md`. `docs/wip/` is gitignored.

Repo-local `<repo>/docs/` is archived reference only. New product tasks live in workspace `docs/`.

## Workspace Scripts

Host-side helpers (not Docker; warning-only):

- `scripts/build-done-index.py` — regenerates `docs/done/INDEX.md`; run in `/complete-task`.
- `scripts/validate-docs-frontmatter.py` — checks frontmatter and refreshes the code index.
- `scripts/build-code-index.py` — builds the `related_code` reverse index.
- `scripts/check-context-budget.sh` — warns when hot-context files exceed line/byte budgets.
- `scripts/check-no-flow-duplication.sh` — fails if the task-flow algorithm is described outside this file.
- `scripts/check-task-contract.py` — warns when a task file is missing contract sections.

## LLM Memory

Auto-memory is keyed to the workspace path `dev/[project-name]/`. When writing a new memory fact, tag which repo it belongs to (`app`, `landing`, `nginx`, `workspace`) unless the fact is workspace-wide.
