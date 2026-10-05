# [project-name] Workspace — Agent Instructions

`dev/[project-name]/` stores agent context/tasks/docs. Code repos `app/`, `landing/`, and `nginx/` are gitignored; search explicit repo paths and use task paths like `app/src/...`.

## Local Permissions

- Skip private paths entirely: `.env*`, key material, credential/token files, `.ssh/`, `.aws/`, `.kube/`, `.gnupg/`, `.npmrc`, `.netrc`, and auth files. Only `.env.example` containing placeholders is exempt. Do not follow symlinks while scanning.
- Never run `rm -rf`, `git push --force`, `git reset --hard`, `chmod 777`, `sudo rm`, or `curl/wget ... | bash`.
- For dangling Docker layers use only `docker image prune -f --filter "dangling=true"`; never prune systems/volumes or remove named volumes unless explicitly requested.

## Security

- Never hardcode, print, or log secrets. Keep them only in untracked `.env`; document placeholders in `.env.example`. Never use `echo $SECRET`, `env`, `printenv`, or `docker compose config`; validate with `config --quiet`.
- Validate external input at boundaries; use parameterized queries; never interpolate user data into shell commands or HTML.
- Use least-privilege containers: no privileged/host network, publish only required ports, prefer non-root images and maintained dependencies.
- Start SSH read-only (`ps`, logs, `git log`). Firewall, `sshd_config`, TLS, users, and server `.env` require explicit scope. Never weaken nginx HTTPS/security/rate limits as a side effect.
- Before deploy, run `docs/runbook-prod.md` checks and inspect the outgoing diff for secrets/debug leftovers.

## Task Workflows

Use only the workflow requested by the user. Ordinary fixes do not require creating a backlog task.

<a id="create-task-equivalent"></a>

- `/create-task` / `$create-task`: read [the create procedure](docs/workflows/task-lifecycle.md#create-task-equivalent).

<a id="start-task-equivalent"></a>

- `/start-task` / `$start-task`: read [the start procedure](docs/workflows/task-lifecycle.md#start-task-equivalent).

<a id="review-task-equivalent"></a>

- `/review-task` / `$review-task`: read [the review procedure](docs/workflows/task-lifecycle.md#review-task-equivalent).

<a id="complete-task-equivalent"></a>

- `/complete-task` / `$complete-task`: read [the complete procedure](docs/workflows/task-lifecycle.md#complete-task-equivalent).

## Stop Rule

A task is done only when every `Done When` item has evidence; tests/build/types/analyzers and applicable gates pass; no confirmed `blocker`/`high` remains; the diff fits `Change Budget`; and the final implementation snapshot has a recorded review. Reuse unchanged review evidence; changed behavior or external evidence permits a focused follow-up.

## Docs

Workspace `docs/` is product documentation; rules live in `docs/folder-rules.md`; `docs/wip/` is gitignored. Repo-local `<repo>/docs/` is archived reference only.

## Workspace Scripts

- `scripts/verify.sh` — strict executable gate for workspace tasks.
- `scripts/new-task.sh`, `scripts/task-branch.sh`, `scripts/check-staged-paths.sh`, `scripts/new-done-record.sh` — deterministic lifecycle mechanics used above.
- `scripts/build-done-index.py`, `scripts/build-code-index.py` — generated done/code indexes.
- Validators warn where supported; the gate is strict. `scripts/check-no-flow-duplication.sh` checks workflow ownership in instruction files only.

## Context

Read `PROJECT_MAP.md` before scanning. Code runtime, dependency work, and repo gates run in Docker; workspace Python/shell helpers and Git run on the host. Respect the user's current scope and existing authorization.

## LLM Memory

Auto-memory is keyed to `dev/[project-name]/`. Tag new facts with `app`, `landing`, `nginx`, or `workspace` unless workspace-wide.
