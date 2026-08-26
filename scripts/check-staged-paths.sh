#!/usr/bin/env bash
# Reject staged secret-shaped paths without reading file contents.
set -euo pipefail

if [[ "$#" -ne 1 ]]; then
  echo "Usage: $0 <repo>" >&2
  exit 2
fi

if ! REPO_ROOT="$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)"; then
  echo "ERROR: not a git repository: $1" >&2
  exit 1
fi

blocked=0
checked=0
STAGED_LIST="$(mktemp "${TMPDIR:-/tmp}/check-staged-paths.XXXXXX")"
trap 'rm -f "$STAGED_LIST"' EXIT
if ! git -C "$REPO_ROOT" diff --cached --name-only --no-renames --diff-filter=ACMRDTUXB -z > "$STAGED_LIST"; then
  echo "ERROR: could not inspect staged paths in $REPO_ROOT" >&2
  exit 1
fi

shopt -s nocasematch
while IFS= read -r -d '' staged_path; do
  checked=$((checked + 1))
  base_name="${staged_path##*/}"
  secret_shaped=0

  if [[ "$base_name" == .env* && "$base_name" != ".env.example" ]]; then
    secret_shaped=1
  elif [[ "$base_name" == *.pem || "$base_name" == *.key ]]; then
    secret_shaped=1
  elif [[ "$base_name" == id_rsa* || "$base_name" == id_ed25519* ]]; then
    secret_shaped=1
  elif [[ "/$staged_path/" == */.ssh/* ]]; then
    secret_shaped=1
  fi

  if [[ "$secret_shaped" -eq 1 ]]; then
    printf 'BLOCKED: secret-shaped staged path: %q\n' "$staged_path" >&2
    blocked=1
  fi
done < "$STAGED_LIST"
shopt -u nocasematch

if [[ "$blocked" -eq 1 ]]; then
  echo "ERROR: unstage secret-shaped paths before committing" >&2
  exit 1
fi

rm -f "$STAGED_LIST"
trap - EXIT
echo "OK: checked $checked staged path(s) in $REPO_ROOT"
