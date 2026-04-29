#!/bin/bash
# ============================================
# Kaset Atlas — URL Verifier
# Script-based (not AI) for maximum reliability
# ============================================
#
# Usage:
#   ./scripts/verify-urls.sh src/content/crops/holy-basil.mdx
#
# Exits 0 if all URLs return HTTP 200
# Exits 1 if any URL fails
# Output: JSON report to stdout

set -uo pipefail

FILE="${1:-}"

if [ -z "$FILE" ]; then
  echo "Usage: $0 <path-to-mdx-file>"
  exit 2
fi

if [ ! -f "$FILE" ]; then
  echo "ERROR: File not found: $FILE"
  exit 2
fi

# Extract all URLs from the MDX file
# Match URLs in markdown links [text](url) and bare URLs
URLS=$(grep -oE 'https?://[^[:space:]"<>)]+' "$FILE" | sort -u)

if [ -z "$URLS" ]; then
  echo '{"status": "error", "message": "No URLs found in file", "file": "'"$FILE"'"}'
  exit 2
fi

TOTAL=0
PASSED=0
FAILED=0
FAILED_URLS=()

while IFS= read -r url; do
  TOTAL=$((TOTAL + 1))

  # Strip trailing punctuation that may have been captured
  url_clean="${url%[\.,\)\]\>]}"

  # HTTP HEAD request with follow-redirect, 10 second timeout
  status=$(curl -o /dev/null -s -w "%{http_code}" \
    -L --max-time 10 \
    --user-agent "Kaset-Atlas-URL-Verifier/1.0" \
    --head "$url_clean" 2>/dev/null || echo "000")

  if [ "$status" = "200" ] || [ "$status" = "301" ] || [ "$status" = "302" ]; then
    PASSED=$((PASSED + 1))
  else
    FAILED=$((FAILED + 1))
    FAILED_URLS+=("$status|$url_clean")
  fi
done <<< "$URLS"

# Build JSON output
echo "{"
echo "  \"file\": \"$FILE\","
echo "  \"total_urls\": $TOTAL,"
echo "  \"passed\": $PASSED,"
echo "  \"failed\": $FAILED,"
echo "  \"failed_urls\": ["

if [ ${#FAILED_URLS[@]} -gt 0 ]; then
  for i in "${!FAILED_URLS[@]}"; do
    IFS='|' read -r status_code url <<< "${FAILED_URLS[$i]}"
    if [ "$i" -lt "$((${#FAILED_URLS[@]} - 1))" ]; then
      echo "    {\"status\": \"$status_code\", \"url\": \"$url\"},"
    else
      echo "    {\"status\": \"$status_code\", \"url\": \"$url\"}"
    fi
  done
fi

echo "  ],"
if [ "$FAILED" -eq 0 ]; then
  echo "  \"verification_status\": \"pass\""
  echo "}"
  exit 0
else
  echo "  \"verification_status\": \"fail\""
  echo "}"
  exit 1
fi
