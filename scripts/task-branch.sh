#!/usr/bin/env bash
# Create a task branch from current main or merge it locally back into main.
set -euo pipefail

usage() {
  echo "Usage: $0 <start|finish> <repo> <slug>" >&2
  exit 2
}

[[ "$#" -eq 3 ]] || usage
ACTION="$1"
REPO_ARG="$2"
SLUG="$3"
case "$ACTION" in start|finish) ;; *) usage ;; esac

if [[ ! "$SLUG" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "ERROR: slug must be lowercase kebab-case" >&2
  exit 1
fi
if ! REPO_ROOT="$(git -C "$REPO_ARG" rev-parse --show-toplevel 2>/dev/null)"; then
  echo "ERROR: not a git repository: $REPO_ARG" >&2
  exit 1
fi
WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ "$REPO_ROOT" == "$WORKSPACE_ROOT" ]]; then
  echo "ERROR: workspace tasks do not use per-task branches" >&2
  exit 1
fi
if ! git -C "$REPO_ROOT" show-ref --verify --quiet refs/heads/main; then
  echo "ERROR: repository has no local main branch: $REPO_ROOT" >&2
  exit 1
fi
if [[ -n "$(git -C "$REPO_ROOT" status --porcelain)" ]]; then
  echo "ERROR: repository must have a clean working tree: $REPO_ROOT" >&2
  exit 1
fi
if ! CURRENT_BRANCH="$(git -C "$REPO_ROOT" symbolic-ref --quiet --short HEAD)"; then
  echo "ERROR: detached HEAD is not supported: $REPO_ROOT" >&2
  exit 1
fi

BRANCH="task/$SLUG"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

update_main() {
  local has_origin=0
  local remote
  while IFS= read -r remote; do
    [[ "$remote" == "origin" ]] && has_origin=1
  done < <(git -C "$REPO_ROOT" remote)

  if [[ "$has_origin" -eq 1 ]]; then
    if ! GIT_TERMINAL_PROMPT=0 git -C "$REPO_ROOT" fetch --quiet origin main >/dev/null 2>&1; then
      echo "ERROR: could not refresh origin/main; main was not changed" >&2
      exit 1
    fi
    if ! git -C "$REPO_ROOT" merge --ff-only refs/remotes/origin/main; then
      echo "ERROR: local main cannot fast-forward to origin/main" >&2
      exit 1
    fi
  fi
}

branch_exists() {
  git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$BRANCH"
}

if [[ "$ACTION" == "start" ]]; then
  if branch_exists; then
    if [[ "$CURRENT_BRANCH" != "$BRANCH" ]]; then
      if [[ "$CURRENT_BRANCH" != "main" ]]; then
        echo "ERROR: switch to main or $BRANCH before retrying" >&2
        exit 1
      fi
      git -C "$REPO_ROOT" switch "$BRANCH"
    fi
    echo "Branch ready: $BRANCH in $REPO_ROOT (existing)"
    exit 0
  fi

  if [[ "$CURRENT_BRANCH" != "main" ]]; then
    echo "ERROR: new task branches must start from main" >&2
    exit 1
  fi
  update_main
  git -C "$REPO_ROOT" switch -c "$BRANCH" main
  echo "Branch ready: $BRANCH in $REPO_ROOT (created from main)"
  exit 0
fi

if ! branch_exists; then
  echo "ERROR: task branch does not exist: $BRANCH" >&2
  exit 1
fi
if [[ "$CURRENT_BRANCH" != "$BRANCH" && "$CURRENT_BRANCH" != "main" ]]; then
  echo "ERROR: switch to main or $BRANCH before finishing" >&2
  exit 1
fi
if [[ "$CURRENT_BRANCH" != "main" ]]; then
  git -C "$REPO_ROOT" switch main
fi
update_main

if git -C "$REPO_ROOT" merge-base --is-ancestor "$BRANCH" main; then
  git -C "$REPO_ROOT" branch -d "$BRANCH"
  echo "Branch finished: $BRANCH was already merged into main in $REPO_ROOT"
  exit 0
fi

if ! git -C "$REPO_ROOT" merge --no-ff --no-commit "$BRANCH"; then
  echo "ERROR: merge conflict; resolve or abort the merge manually" >&2
  exit 1
fi
bash "$SCRIPT_DIR/check-staged-paths.sh" "$REPO_ROOT"
git -C "$REPO_ROOT" commit -m "Merge $BRANCH"
git -C "$REPO_ROOT" branch -d "$BRANCH"
echo "Branch finished: merged $BRANCH into main and deleted it in $REPO_ROOT"
