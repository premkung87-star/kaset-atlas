#!/bin/bash
# ============================================
# Kaset Atlas — MDX Safety Check
# Detects bare <digit / <lowercase patterns that break MDX parsing.
# ============================================
#
# Usage:
#   ./scripts/check-mdx-safety.sh src/content/crops/holy-basil.mdx
#
# Exits 0 if file is safe (no unsafe patterns).
# Exits 1 if file has unsafe patterns.
# Exits 2 on argument/file error.
#
# Pattern: [<>][a-z0-9] — JSX components are PascalCase, so any < or >
# followed by lowercase letter or digit is suspicious.

set -uo pipefail

FILE="${1:-}"

if [ -z "$FILE" ]; then
  echo '{"status":"error","message":"Usage: $0 <path-to-mdx-file>"}'
  exit 2
fi

if [ ! -f "$FILE" ]; then
  printf '{"status":"error","message":"File not found: %s"}\n' "$FILE"
  exit 2
fi

MATCHES=$(grep -nE '[<>][a-z0-9]' "$FILE" || true)

if [ -z "$MATCHES" ]; then
  printf '{"status":"pass","file":"%s","unsafe_patterns":0}\n' "$FILE"
  exit 0
else
  COUNT=$(printf '%s\n' "$MATCHES" | wc -l | tr -d ' ')
  echo "{"
  printf '  "status":"fail",\n'
  printf '  "file":"%s",\n' "$FILE"
  printf '  "unsafe_patterns":%d,\n' "$COUNT"
  echo '  "matches":['
  FIRST=1
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    LINENO=$(echo "$line" | cut -d: -f1)
    TEXT=$(echo "$line" | cut -d: -f2- | sed 's/\\/\\\\/g; s/"/\\"/g')
    if [ "$FIRST" -eq 1 ]; then
      FIRST=0
    else
      echo ","
    fi
    printf '    {"line":%s,"text":"%s"}' "$LINENO" "$TEXT"
  done <<< "$MATCHES"
  echo ""
  echo "  ]"
  echo "}"
  exit 1
fi
