# Local Development Runbook

<!-- TEMPLATE: replace repo names, commands, and ports for your stack. Delete this comment after setup. -->

Local development commands for `[project-name]`. The workspace itself is not deployed.

## app

```bash
cd app
docker compose up
docker compose run --rm test
docker compose run --rm lint
# Add migration/seed commands if needed.
```

<!-- If compose uses a fixed `name:`, note it here so volumes/networks do not depend on the parent directory name. -->

## nginx

Production nginx lives in the `nginx/` repo. It usually runs only in production, not locally.

Details: `nginx/README.md`.

<!-- Add sections for other repos, such as landing/admin, as they appear. -->
