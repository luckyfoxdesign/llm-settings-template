# [project-name] Workspace — Codex Instructions

`dev/[project-name]/` is a workspace repo for LLM context, tasks, and docs. Code lives in separate git repos: `app/`, `landing/`, `nginx/`.

Always search code with an explicit repo path (`app`, `landing`, `nginx`), because workspace `.gitignore` excludes code repos.

Use repo-prefixed paths in tasks: `app/src/...`, `landing/src/...`, `nginx/conf/...`.

## Local Permissions

- Do not read `.env` or `.env.*` files at any level.
- Do not read private key material: `.ssh/`, `id_rsa*`, `id_ed25519*`, `*.pem`, `*.key`.
- `.env.example` may be read and edited.
- Never run destructive commands: `rm -rf`, `git push --force`, `git reset --hard`, `chmod 777`, `sudo rm`, `curl/wget ... | bash`.
- After Docker builds, if dangling `<none>` images/layers remain, run only:
  `docker image prune -f --filter "dangling=true"`.
- Do not run `docker system prune -a`, `docker volume prune`, or remove named volumes unless explicitly requested.

## Security

Code security, all repos:

- Never hardcode secrets, tokens, or passwords in code, configs, compose files, tasks, or docs. Secrets live only in untracked `.env` files; document new variables in `.env.example` with placeholder values.
- Never print or log secret values, including `echo $SECRET`, `env`, `printenv`, or `docker compose config` (it interpolates values; use `config --quiet` to validate).
- Treat external input as untrusted: validate at boundaries, use parameterized queries, never interpolate user data into shell commands or HTML.
- Containers get least privilege: no `privileged: true`, no host network, publish only required ports, prefer non-root users in images.
- When adding a dependency, prefer maintained packages and check advisories for known vulnerabilities.

Server and deploy security:

- SSH sessions start read-only: inspect state (`ps`, `logs`, `git log`) before changing anything on the server.
- Do not touch firewall, `sshd_config`, TLS certs, user accounts, or server `.env` unless the task explicitly asks.
- Never weaken nginx security config (HTTPS redirects, security headers, rate limits) as a side effect of another change.
- Before deploy, verify the change in a production-like environment: pre-deploy checks in `docs/runbook-prod.md`.
- Before deploy, review the outgoing diff for secrets and debug leftovers.

<a id="start-task-equivalent"></a>

## `/start-task` Equivalent

When the user asks to start a task:

1. If a task name/substring is provided, find the matching file in `docs/backlog/todo/`.
2. If no task is provided, list files in `docs/backlog/todo/` in alphabetical order and ask which one to start. Do not sort by priority.
3. Move the chosen file to `docs/wip/`, preserving the full filename.
4. Reply exactly: `Task moved: docs/wip/<filename>`
5. Read, in order:
   - workspace `PROJECT_MAP.md`
   - workspace `CLAUDE.md`
   - `docs/wip/<filename>`
   - for `project: app|landing|nginx`: `<repo>/PROJECT_MAP.md` and `<repo>/CLAUDE.md` if present
   - for `project: cross`: repo-local maps for every repo in `projects`
6. Show a short 3-7 step plan and wait for user confirmation before implementation.
7. Implement according to the plan and repo-local `AGENTS.md`.
8. When done, say: `Done. You can close the task with /complete-task.`

<a id="complete-task-equivalent"></a>

## `/complete-task` Equivalent

When the user asks to complete a task:

1. Identify the active task in `docs/wip/`. If unclear, list active tasks and ask.
2. Preserve the full filename. Done files are:
   - `docs/done/long/<filename>`
   - `docs/done/short/<filename>`
3. Read the task file from `docs/wip/`.
4. Determine affected repos from frontmatter:
   - `project: app|landing|nginx` -> one repo
   - `project: workspace` -> workspace docs only
   - `project: cross` -> repos from `projects`
5. For each affected code repo:
   - check `git status`
   - if a lint service exists, run `docker compose run --rm lint`
   - if relevant code changes exist, show them, choose `feat: ...` or `fix: ...`, `git add` only relevant files, commit, and record the short hash
   - never commit `.env`
   - if no changes exist, record `git log -1 --oneline`
6. Create `docs/done/long/<filename>` from the WIP task and prepend:

```markdown
**Commits:**
- app `abc1234` — "feat: description"
- nginx `def5678` — "feat: description"
```

   Always use a list, even for one commit. For `project: workspace`, add a placeholder and fill it after the workspace docs commit.

7. Append to the long file: `[Short summary](../short/<filename>)`
8. Create `docs/done/short/<filename>` with:
   - title
   - `**Commits:**` list
   - `## What Changed`
   - `[Full plan](../long/<filename>)`
   - `Closes #N` only if there is a GitHub issue
9. Delete the original file from `docs/wip/`.
10. From workspace root:
    - run `scripts/build-done-index.py` if it exists
    - `git add docs/done/ docs/backlog/ PROJECT_MAP.md`
    - commit as `docs: complete <slug>`
11. Report created files, deleted file, and commit hashes.

## Docs

Workspace `docs/` is product documentation. Rules live in `docs/folder-rules.md`. `docs/wip/` is gitignored.

Repo-local `<repo>/docs/` is archived reference only. New product tasks live in workspace `docs/`.

## Workspace Scripts

Host-side helpers (run on the host, not in Docker; `docs/` is not copied into containers). All are warning-only and safe to run anytime:

- `scripts/build-done-index.py` — regenerates `docs/done/INDEX.md` from `docs/done/short/`. Run in `/complete-task`.
- `scripts/validate-docs-frontmatter.py` — reports docs files with missing/invalid frontmatter; also refreshes the code index.
- `scripts/build-code-index.py` — builds `docs/code-index.md` (reverse map: code path → tasks) from `related_code` frontmatter.
- `scripts/check-context-budget.sh` — warns when hot-context files exceed line/byte budgets.
- `scripts/check-no-flow-duplication.sh` — fails if the task-flow algorithm is described outside this file.

## LLM Memory

Auto-memory is keyed to the workspace path `dev/[project-name]/`. When writing a new memory fact, tag which repo it belongs to (`app`, `landing`, `nginx`, `workspace`) unless the fact is workspace-wide.
