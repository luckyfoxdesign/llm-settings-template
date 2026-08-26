#!/usr/bin/env bash
# Scaffold linked long/short done records from one WIP task.
set -euo pipefail

usage() {
  echo "Usage: $0 [--root <workspace>] <wip-task> <repo> <hash> <subject> [<repo> <hash> <subject> ...]" >&2
  exit 2
}

WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ "${1:-}" == "--root" ]]; then
  [[ "$#" -ge 6 ]] || usage
  WORKSPACE_ROOT="$2"
  shift 2
fi
[[ "$#" -ge 4 ]] || usage

TASK_ARG="$1"
shift
if [[ $(( $# % 3 )) -ne 0 ]]; then
  usage
fi
if ! WORKSPACE_ROOT="$(cd "$WORKSPACE_ROOT" 2>/dev/null && pwd)"; then
  echo "ERROR: workspace root does not exist" >&2
  exit 1
fi

case "$TASK_ARG" in
  /*) TASK_PATH="$TASK_ARG" ;;
  *) TASK_PATH="$WORKSPACE_ROOT/$TASK_ARG" ;;
esac
if [[ ! -f "$TASK_PATH" ]]; then
  echo "ERROR: WIP task does not exist: $TASK_ARG" >&2
  exit 1
fi
TASK_DIR="$(cd "$(dirname "$TASK_PATH")" && pwd)"
if [[ "$TASK_DIR" != "$WORKSPACE_ROOT/docs/wip" ]]; then
  echo "ERROR: task must be directly inside docs/wip" >&2
  exit 1
fi

TASK_FILE="$(basename "$TASK_PATH")"
if [[ ! "$TASK_FILE" =~ ^[0-9]{2}-[0-9]{2}-[0-9]{2}-(app|landing|nginx|workspace|cross)-[a-z0-9]+(-[a-z0-9]+)*\.md$ ]]; then
  echo "ERROR: invalid task filename: $TASK_FILE" >&2
  exit 1
fi

COMMIT_REPOS=()
COMMIT_HASHES=()
COMMIT_SUBJECTS=()
while [[ "$#" -gt 0 ]]; do
  commit_repo="$1"
  commit_hash="$2"
  commit_subject="$3"
  shift 3
  case "$commit_repo" in app|landing|nginx|workspace) ;; *) echo "ERROR: invalid commit repo: $commit_repo" >&2; exit 1 ;; esac
  [[ "$commit_hash" =~ ^[0-9a-f]{7,40}$ ]] || { echo "ERROR: invalid commit hash: $commit_hash" >&2; exit 1; }
  [[ -n "$commit_subject" && "$commit_subject" != *$'\n'* ]] || { echo "ERROR: invalid commit subject" >&2; exit 1; }
  COMMIT_REPOS+=("$commit_repo")
  COMMIT_HASHES+=("$commit_hash")
  COMMIT_SUBJECTS+=("$commit_subject")
done

TASK_LINES=()
while IFS= read -r task_line || [[ -n "$task_line" ]]; do
  TASK_LINES+=("$task_line")
done < "$TASK_PATH"
if [[ "${TASK_LINES[0]:-}" != "---" ]]; then
  echo "ERROR: task has no YAML frontmatter" >&2
  exit 1
fi

FM_END=-1
TYPE_FOUND=0
STATUS_FOUND=0
PROJECT=""
for ((i = 1; i < ${#TASK_LINES[@]}; i++)); do
  line="${TASK_LINES[$i]}"
  if [[ "$line" == "---" ]]; then
    FM_END="$i"
    break
  elif [[ "$line" == type:* ]]; then
    TYPE_FOUND=1
  elif [[ "$line" == status:* ]]; then
    STATUS_FOUND=1
  elif [[ "$line" == project:* ]]; then
    PROJECT="${line#project: }"
  fi
done
if [[ "$FM_END" -lt 1 || "$TYPE_FOUND" -ne 1 || "$STATUS_FOUND" -ne 1 || -z "$PROJECT" ]]; then
  echo "ERROR: task frontmatter must contain type, status, and project" >&2
  exit 1
fi

TITLE=""
HAS_TITLE=0
HAS_EVIDENCE=0
for ((i = FM_END + 1; i < ${#TASK_LINES[@]}; i++)); do
  line="${TASK_LINES[$i]}"
  if [[ -z "$TITLE" && "$line" == \#\ * ]]; then
    TITLE="${line#\# }"
    HAS_TITLE=1
  fi
  [[ "$line" == "## Verification Evidence" ]] && HAS_EVIDENCE=1
done
if [[ -z "$TITLE" ]]; then
  stem="${TASK_FILE%.md}"
  slug="${stem#??-??-??-$PROJECT-}"
  TITLE="$(awk '{ for (i = 1; i <= NF; i++) { $i = toupper(substr($i, 1, 1)) substr($i, 2) } print }' <<< "${slug//-/ }")"
fi

LONG_DIR="$WORKSPACE_ROOT/docs/done/long"
SHORT_DIR="$WORKSPACE_ROOT/docs/done/short"
LONG_PATH="$LONG_DIR/$TASK_FILE"
SHORT_PATH="$SHORT_DIR/$TASK_FILE"
mkdir -p "$LONG_DIR" "$SHORT_DIR"
if [[ -e "$LONG_PATH" || -e "$SHORT_PATH" ]]; then
  echo "ERROR: done record already exists for $TASK_FILE" >&2
  exit 1
fi

TODAY="$(date +%Y-%m-%d)"
TMP_LONG="$(mktemp "$LONG_DIR/.$TASK_FILE.XXXXXX")"
TMP_SHORT="$(mktemp "$SHORT_DIR/.$TASK_FILE.XXXXXX")"
LONG_CREATED=0
cleanup() {
  [[ -n "${TMP_LONG:-}" && -e "$TMP_LONG" ]] && rm -f "$TMP_LONG"
  [[ -n "${TMP_SHORT:-}" && -e "$TMP_SHORT" ]] && rm -f "$TMP_SHORT"
  if [[ "$LONG_CREATED" -eq 1 && ! -e "$SHORT_PATH" ]]; then
    rm -f "$LONG_PATH"
  fi
}
trap cleanup EXIT

write_frontmatter() {
  local record_type="$1"
  local short_record="$2"
  printf '%s\n' '---'
  for ((i = 1; i < FM_END; i++)); do
    line="${TASK_LINES[$i]}"
    if [[ "$line" == type:* ]]; then
      printf 'type: %s\n' "$record_type"
    elif [[ "$line" == status:* ]]; then
      printf '%s\n' 'status: done'
    elif [[ "$short_record" -eq 1 && "$line" == created:* ]]; then
      printf 'created: %s\n' "$TODAY"
    else
      printf '%s\n' "$line"
    fi
  done
  printf '%s\n' '---'
}

write_commits() {
  printf '%s\n' '**Commits:**'
  for ((i = 0; i < ${#COMMIT_REPOS[@]}; i++)); do
    escaped_subject="${COMMIT_SUBJECTS[$i]//\\/\\\\}"
    escaped_subject="${escaped_subject//\"/\\\"}"
    printf -- '- %s `%s` — "%s"\n' "${COMMIT_REPOS[$i]}" "${COMMIT_HASHES[$i]}" "$escaped_subject"
  done
}

{
  write_frontmatter done_long 0
  printf '\n'
  write_commits
  printf '\n'
  if [[ "$HAS_TITLE" -eq 0 ]]; then
    printf '# %s\n\n' "$TITLE"
  fi
  for ((i = FM_END + 1; i < ${#TASK_LINES[@]}; i++)); do
    line="${TASK_LINES[$i]}"
    if [[ "$line" == "**Status:**"* ]]; then
      printf '%s\n' '**Status:** done'
    elif [[ "$line" == "**Last checked:**"* ]]; then
      printf '**Last checked:** %s\n' "$TODAY"
    else
      printf '%s\n' "$line"
    fi
  done
  if [[ "$HAS_EVIDENCE" -eq 0 ]]; then
    printf '\n## Verification Evidence\n\n<!-- Fill with command, diff/path, or commit evidence for every Done When item. -->\n'
  fi
  printf '\n[Short summary](../short/%s)\n' "$TASK_FILE"
} > "$TMP_LONG"

{
  write_frontmatter done_short 1
  printf '\n# %s\n\n' "$TITLE"
  write_commits
  printf '\n## What Changed\n\n<!-- Fill with concise implementation bullets. -->\n'
  printf '\n## Verification Evidence\n\n<!-- Fill with concise verification evidence. -->\n'
  printf '\n---\n[Full plan](../long/%s)\n' "$TASK_FILE"
} > "$TMP_SHORT"

if ! ln "$TMP_LONG" "$LONG_PATH"; then
  echo "ERROR: long done record already exists: $TASK_FILE" >&2
  exit 1
fi
LONG_CREATED=1
if ! ln "$TMP_SHORT" "$SHORT_PATH"; then
  echo "ERROR: short done record already exists: $TASK_FILE" >&2
  exit 1
fi
rm -f "$TMP_LONG" "$TMP_SHORT"
TMP_LONG=""
TMP_SHORT=""
LONG_CREATED=0
trap - EXIT

echo "Created: docs/done/long/$TASK_FILE"
echo "Created: docs/done/short/$TASK_FILE"
