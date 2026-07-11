#!/usr/bin/env bash
# Ensures the start-task/complete-task flow algorithm is described only in AGENTS.md.
# Detects step-by-step algorithm descriptions outside the canonical file.
PATTERNS=(
  "Move the chosen file to .*docs/wip"
  "Move the selected file from.*docs/backlog/todo"
  "Identify the active task in .*docs/wip"
)

ALLOWED="./AGENTS.md"
FOUND=0

for pattern in "${PATTERNS[@]}"; do
  while IFS= read -r line; do
    file="${line%%:*}"
    file="${file#./}"
    if [[ "./$file" != "$ALLOWED" ]]; then
      echo "DUPLICATE FLOW: $line"
      FOUND=1
    fi
  done < <(grep -rn --include="*.md" -E "$pattern" . --exclude-dir=wip)
done

if [[ $FOUND -eq 1 ]]; then
  echo "Flow duplication detected. Move algorithm to AGENTS.md and replace with a pointer."
  exit 1
fi

echo "OK: no flow duplication outside AGENTS.md"
