#!/usr/bin/env bash
# Scaffold a task filename and mandatory frontmatter without overwriting files.
set -euo pipefail

usage() {
  echo "Usage: $0 [--root <workspace>] <project> <slug> [cross-project ...]" >&2
  exit 2
}

WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ "${1:-}" == "--root" ]]; then
  [[ "$#" -ge 3 ]] || usage
  WORKSPACE_ROOT="$2"
  shift 2
fi

[[ "$#" -ge 2 ]] || usage
PROJECT="$1"
SLUG="$2"
shift 2

if ! WORKSPACE_ROOT="$(cd "$WORKSPACE_ROOT" 2>/dev/null && pwd)"; then
  echo "ERROR: workspace root does not exist" >&2
  exit 1
fi

case "$PROJECT" in
  app|landing|nginx|workspace|cross) ;;
  *) echo "ERROR: project must be app, landing, nginx, workspace, or cross" >&2; exit 1 ;;
esac

if [[ ! "$SLUG" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "ERROR: slug must be lowercase kebab-case" >&2
  exit 1
fi

CROSS_PROJECTS=()
if [[ "$PROJECT" == "cross" ]]; then
  [[ "$#" -gt 0 ]] || { echo "ERROR: cross tasks require at least one project" >&2; exit 1; }
  seen=","
  for cross_project in "$@"; do
    case "$cross_project" in
      app|landing|nginx|workspace) ;;
      *) echo "ERROR: invalid cross project: $cross_project" >&2; exit 1 ;;
    esac
    if [[ "$seen" == *",$cross_project,"* ]]; then
      echo "ERROR: duplicate cross project: $cross_project" >&2
      exit 1
    fi
    seen="${seen}${cross_project},"
    CROSS_PROJECTS+=("$cross_project")
  done
elif [[ "$#" -ne 0 ]]; then
  echo "ERROR: project lists are valid only for project: cross" >&2
  exit 1
fi

FILE_DATE="$(date +%d-%m-%y)"
ISO_DATE="$(date +%Y-%m-%d)"
TASK_DIR="$WORKSPACE_ROOT/docs/backlog/todo"
TASK_FILE="$FILE_DATE-$PROJECT-$SLUG.md"
TASK_PATH="$TASK_DIR/$TASK_FILE"

mkdir -p "$TASK_DIR"
if [[ -e "$TASK_PATH" ]]; then
  echo "ERROR: task already exists: docs/backlog/todo/$TASK_FILE" >&2
  exit 1
fi

TMP_TASK="$(mktemp "$TASK_DIR/.$TASK_FILE.XXXXXX")"
trap 'rm -f "$TMP_TASK"' EXIT
{
  printf '%s\n' '---'
  printf '%s\n' 'type: task' 'status: todo' "project: $PROJECT"
  if [[ "$PROJECT" == "cross" ]]; then
    printf '%s\n' 'projects:'
    for cross_project in "${CROSS_PROJECTS[@]}"; do
      printf '  - %s\n' "$cross_project"
    done
  fi
  printf '%s\n' "created: $ISO_DATE" '---' ''
} > "$TMP_TASK"
if ! ln "$TMP_TASK" "$TASK_PATH"; then
  echo "ERROR: task already exists: docs/backlog/todo/$TASK_FILE" >&2
  exit 1
fi
rm -f "$TMP_TASK"
trap - EXIT

echo "Created: docs/backlog/todo/$TASK_FILE"
