#!/usr/bin/env bash
# Check hot-context files against token budget limits.
# Default is warning-only; --strict exits non-zero when a limit is exceeded.

set -euo pipefail

STRICT=0
if [[ "$#" -gt 1 ]]; then
  echo "Usage: $0 [--strict]" >&2
  exit 2
fi
case "${1:-}" in
  "") ;;
  --strict) STRICT=1 ;;
  *) echo "Usage: $0 [--strict]" >&2; exit 2 ;;
esac

WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_KEY=$(echo "$WORKSPACE_ROOT" | tr '/' '-')
MEMORY_MD="$HOME/.claude/projects/${PROJECT_KEY}/memory/MEMORY.md"

# file path : line limit : byte limit (0 = no byte limit)
declare -a FILES=(
  "CLAUDE.md:60:3072"
  "AGENTS.md:180:7168"
  "PROJECT_MAP.md:200:7168"
)

RED='\033[0;31m'
YLW='\033[0;33m'
GRN='\033[0;32m'
RST='\033[0m'

WARN=0

pad() { printf "%-40s" "$1"; }

print_row() {
  local file="$1" lines="$2" lim_lines="$3" bytes="$4" lim_bytes="$5"
  local status="${GRN}OK${RST}"

  if [[ "$lines" -gt "$lim_lines" ]] || { [[ "$lim_bytes" -gt 0 ]] && [[ "$bytes" -gt "$lim_bytes" ]]; }; then
    status="${YLW}WARN${RST}"
    WARN=1
  fi

  local kb
  kb=$(awk "BEGIN { printf \"%.1f\", $bytes/1024 }")

  if [[ "$lim_bytes" -gt 0 ]]; then
    local lim_kb
    lim_kb=$(awk "BEGIN { printf \"%.1f\", $lim_bytes/1024 }")
    printf "$(pad "$file")  lines: %4d/%-4d  size: %5s KB/%-5s KB  %b\n" \
      "$lines" "$lim_lines" "$kb" "${lim_kb} KB" "$status"
  else
    printf "$(pad "$file")  lines: %4d/%-4d  size: %5s KB/%-5s      %b\n" \
      "$lines" "$lim_lines" "$kb" "—" "$status"
  fi
}

echo ""
echo "=== Hot-context budget check ==="
echo ""

for entry in "${FILES[@]}"; do
  IFS=':' read -r rel lim_lines lim_bytes <<< "$entry"
  abs="$WORKSPACE_ROOT/$rel"
  if [[ ! -f "$abs" ]]; then
    printf "$(pad "$rel")  ${RED}NOT FOUND${RST}\n"
    WARN=1
    continue
  fi
  lines=$(wc -l < "$abs")
  bytes=$(wc -c < "$abs")
  print_row "$rel" "$lines" "$lim_lines" "$bytes" "$lim_bytes"
done

# MEMORY.md — lines-only limit
MEM_LABEL="~/.claude/.../MEMORY.md"
if [[ -f "$MEMORY_MD" ]]; then
  mem_lines=$(wc -l < "$MEMORY_MD")
  mem_bytes=$(wc -c < "$MEMORY_MD")
  print_row "$MEM_LABEL" "$mem_lines" 30 "$mem_bytes" 0
else
  printf "$(pad "$MEM_LABEL")  ${YLW}not found (ok if no memory yet)${RST}\n"
fi

echo ""
if [[ "$WARN" -eq 1 ]]; then
  echo -e "${YLW}Warning: one or more files exceed budget. Trim or split before they grow further.${RST}"
else
  echo -e "${GRN}All files within budget.${RST}"
fi
echo ""

if [[ "$STRICT" -eq 1 && "$WARN" -eq 1 ]]; then
  exit 1
fi
