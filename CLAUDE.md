# [project-name] Workspace

This repo stores shared LLM context, task docs, and product docs for `[project-name]`.

Code repos (`app/`, `landing/`, `nginx/`) are separate git repos and are ignored by the workspace repo. This workspace is local-only and is not deployed.

## Source Of Truth

| Topic | File |
|---|---|
| Workspace map and repo commands | `PROJECT_MAP.md` |
| Task and docs rules | `docs/folder-rules.md` |
| `/start-task`, `/complete-task` flow | `AGENTS.md` |
| Production deploy / rollback | `docs/runbook-prod.md` |
| Local development | `docs/runbook-local.md` |
| App context | `app/CLAUDE.md`, `app/AGENTS.md` |
| Landing context | `landing/CLAUDE.md`, `landing/AGENTS.md` |
| Nginx context | `nginx/CLAUDE.md`, `nginx/AGENTS.md` |
| Completed tasks | `docs/done/short/` |

## Rules

Docker-only for code work: tests, lint, dependency operations, and service commands run through Docker. Git runs locally.

After Docker builds, clean only dangling layers when needed:

```bash
docker image prune -f --filter "dangling=true"
```

Never run `docker system prune -a`, `docker volume prune`, or remove named volumes unless explicitly requested.

Always search code with an explicit repo path:

```text
Grep("pattern", path: "app")
Grep("pattern", path: "landing")
Grep("pattern", path: "nginx")
```

## Local Permissions

- Do not read `.env`, `.env.*`, or private key material (`.ssh/`, `id_rsa*`, `*.pem`, `*.key`).
- `.env.example` may be read and edited.
- Never run `rm -rf`, `git push --force`, `git reset --hard`, `chmod 777`, `sudo rm`, or `curl/wget ... | bash`.

## Security

- Never hardcode or log secrets; secrets live only in untracked `.env`, new variables go to `.env.example` as placeholders.
- Before deploy: run pre-deploy checks from `docs/runbook-prod.md` and review the outgoing diff for secrets and debug leftovers.
- On the server: inspect before modifying; do not touch firewall, sshd, TLS, or server `.env` unless the task explicitly asks.
- Full policy: `AGENTS.md` → Security.

## SSH

```bash
ssh [your-server-alias]
```

Deploy and rollback: `docs/runbook-prod.md`. Local setup: `docs/runbook-local.md`.
