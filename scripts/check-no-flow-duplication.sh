#!/usr/bin/env bash
# Ensures each canonical algorithm and policy is stated in exactly one file.
# Detects verbatim restatements outside the owning file.
#
# Rule format: "<owner path>::<regex>". A match inside the owner is expected;
# a match anywhere else is duplication and must become a pointer instead.
#
# Every rule is also checked against its own owner. A pattern that no longer
# matches there is reported as STALE and fails the run: rules anchored to
# rewritten wording would otherwise keep passing while guarding nothing.
#
# docs/done/ is excluded: done records are historical evidence and must never
# be rewritten to satisfy this gate. docs/wip/ is local and gitignored.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

RULES=(
  # Task-flow algorithm — owned by AGENTS.md
  "AGENTS.md::bash scripts/new-task.sh"
  "AGENTS.md::Reply exactly: .Task created"
  "AGENTS.md::Move it to .docs/wip/., preserving the full filename"
  "AGENTS.md::reply exactly: .Task moved"
  "AGENTS.md::Identify one active task in .docs/wip/"
  "AGENTS.md::bash scripts/task-branch.sh"
  "AGENTS.md::bash scripts/check-staged-paths.sh"
  "AGENTS.md::bash scripts/new-done-record.sh"
  # Review policy — owned by the verification contract
  "docs/product/architecture/verification-contract.md::the violated contract item"
  "docs/product/architecture/verification-contract.md::a reproducible scenario, failing test, or tool output"
  "docs/product/architecture/verification-contract.md::severity: .blocker., .high., .medium., or .speculative"
)

FOUND=0
STALE=0

for rule in "${RULES[@]}"; do
  owner="${rule%%::*}"
  pattern="${rule#*::}"

  if ! grep -q -E "$pattern" "$owner" 2>/dev/null; then
    echo "STALE RULE: pattern no longer matches its owner $owner"
    echo "  $pattern"
    STALE=1
    continue
  fi

  while IFS= read -r line; do
    file="${line%%:*}"
    file="${file#./}"
    if [[ "$file" != "$owner" ]]; then
      echo "DUPLICATE: $file restates content owned by $owner"
      echo "  ${line#*:}"
      FOUND=1
    fi
  done < <(grep -rn --include="*.md" -E "$pattern" . \
    --exclude-dir=wip --exclude-dir=done --exclude-dir=.git 2>/dev/null)
done

if [[ $STALE -eq 1 ]]; then
  echo
  echo "Re-anchor stale rules to the owner's current wording, or drop them."
fi

if [[ $FOUND -eq 1 ]]; then
  echo
  echo "Duplication detected. Keep the text in its owner and leave a pointer here."
fi

if [[ $STALE -eq 1 || $FOUND -eq 1 ]]; then
  exit 1
fi

echo "OK: ${#RULES[@]} rules live, no duplication outside canonical owners"
