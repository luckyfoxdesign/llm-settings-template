# [project-name] Codex Instructions

This file mirrors the local Claude Code setup. Codex must follow these
project rules before making changes.

## Source Of Truth

- Read `PROJECT_MAP.md` before implementation tasks. It is the current generated
  index of modules, routes, tasks, models, and "start here" pointers.
- Read `CLAUDE.md` for project architecture and local workflow rules.
- For task lifecycle rules, read `docs/folder-rules.md`.
- Do not scan the whole repo first when `PROJECT_MAP.md` gives the right entry
  point.

## Docker

All work runs through Docker. The only exception is git — all git commands run
locally on the host.

- Compose file is `compose.yml` (not `docker-compose.yml`).
- Run services, tests, and linters only via `docker compose run --rm <service>`
  or `docker compose up`.
- Never use a local virtualenv, local pip, or local interpreter.

## Architecture Rules

<!-- Add project-specific architecture rules here -->

## Testing

<!-- Add test commands here -->

## Code Quality

<!-- Add linter/formatter commands here -->

## Local Permissions Policy

- Do not read `.env` or other `.env.*` files.
- `.env.example` may be read and edited.
- Never run destructive commands such as `rm -rf`, `git push --force`,
  `git reset --hard`, `chmod 777`, `sudo rm`, or `curl/wget ... | bash`.

## `/start-task` Equivalent

When the user asks to start a task, follow the Claude command behavior:

1. If the user gave a task name or number, find a matching file in
   `docs/backlog/todo/` by partial filename or title match.
2. If no task was specified, list files in `docs/backlog/todo/` ordered by the
   numeric priority in the filename, then ask which task to take.
3. Move the selected file from `docs/backlog/todo/` to `docs/wip/`, preserving
   the filename.
4. Confirm with exactly:

```text
Задача перенесена: docs/wip/<filename>
```

5. Read in order:
   - `PROJECT_MAP.md`
   - `CLAUDE.md`
   - `docs/wip/<filename>`
6. Present a short 3-7 item plan and wait for user confirmation before
   implementation.
7. Implement according to the plan and the architecture rules above.
8. When done, tell the user:

```text
Готово. Можно закрыть задачу командой `/complete-task`.
```

## `/complete-task` Equivalent

When the user asks to complete a task, follow the Claude command behavior:

1. Determine which file in `docs/wip/` is the active task from conversation
   context. If unclear, list `docs/wip/` and ask the user.
2. Derive `slug.md` from the task filename:
   - `dd-mm-yy-NN-slug.md` -> `slug.md`
   - `dd-mm-yy-slug.md` -> `slug.md`
3. Read the task file from `docs/wip/`.
4. Check `git status`.
5. If there are uncommitted non-doc changes:
   - Show the user which files will be committed.
   - Create a commit message in `feat: ...` style based on the code changes.
   - Commit only the relevant non-doc files.
   - Do not commit `.env`, `docs/`, or `.claude/`.
   - Record the commit hash for the completion docs.
6. If there are no relevant uncommitted changes, use the latest commit hash from
   `git log -1 --oneline`.
7. Create `docs/done/long/slug.md` from the task file content with this field at
   the top:

```markdown
**Commit:** `abc1234` — "feat: description"
```

8. Add this link to the end of the long document:

```markdown
[Краткое резюме](../short/slug.md)
```

9. Create `docs/done/short/slug.md`:

```markdown
# Task title

**Commit:** `abc1234` — "feat: description"

## Что сделано

- Item 1
- Item 2

---
[Полный план](../long/slug.md)
Closes #N
```

Remove `Closes #N` when there is no linked GitHub issue.

10. Delete the original file from `docs/wip/`.
11. Report the created files, removed file, and commit hash.

## Documentation Rules

- `docs/` is local working documentation and is gitignored.
- Active tasks live in `docs/wip/`.
- Ready tasks live in `docs/backlog/todo/`.
- Bugs before work live in `docs/backlog/bugs/`.
- Completed full task plans live in `docs/done/long/`.
- Completed summaries live in `docs/done/short/`.
- Do not put secrets, `.env` values, tokens, duplicate code facts, or temporary
  debug notes into `docs/`.
