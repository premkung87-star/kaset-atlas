#!/bin/bash
# Kaset Atlas — URL Verifier (Fixed v2)
# - Uses GET with byte-range instead of HEAD
# - Realistic browser User-Agent
# - Captures only final status code

set -uo pipefail

FILE="${1:-}"
[ -z "$FILE" ] && { echo "Usage: $0 <path-to-mdx>"; exit 2; }
[ ! -f "$FILE" ] && { echo "ERROR: File not found: $FILE"; exit 2; }

UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

URLS=$(grep -oE 'https?://[^[:space:]"<>)]+' "$FILE" | sort -u)
[ -z "$URLS" ] && { echo '{"status":"error","message":"No URLs found"}'; exit 2; }

TOTAL=0; PASSED=0; FAILED=0
FAILED_URLS=()

while IFS= read -r url; do
  TOTAL=$((TOTAL + 1))
  url_clean="${url%[\.,\)\]\>]}"

  # Try byte-range GET first (lightweight, more compatible than HEAD)
  status=$(curl -o /dev/null -s -w "%{http_code}" \
    -L --max-time 15 -r 0-1 \
    --user-agent "$UA" \
    "$url_clean" 2>/dev/null)
  [ -z "$status" ] && status="000"

  case "$status" in
    200|206|301|302|304)
      PASSED=$((PASSED + 1))
      ;;
    *)
      # Fallback: full GET (some servers reject Range header)
      status_retry=$(curl -o /dev/null -s -w "%{http_code}" \
        -L --max-time 15 \
        --user-agent "$UA" \
        "$url_clean" 2>/dev/null)
      case "$status_retry" in
        200|206|301|302|304)
          PASSED=$((PASSED + 1))
          ;;
        *)
          FAILED=$((FAILED + 1))
          FAILED_URLS+=("${status_retry:-$status}|$url_clean")
          ;;
      esac
      ;;
  esac
done <<< "$URLS"

echo "{"
echo "  \"file\": \"$FILE\","
echo "  \"total_urls\": $TOTAL,"
echo "  \"passed\": $PASSED,"
echo "  \"failed\": $FAILED,"
echo "  \"failed_urls\": ["
if [ ${#FAILED_URLS[@]} -gt 0 ]; then
  for i in "${!FAILED_URLS[@]}"; do
    IFS='|' read -r code url <<< "${FAILED_URLS[$i]}"
    if [ "$i" -lt "$((${#FAILED_URLS[@]} - 1))" ]; then
      echo "    {\"status\": \"$code\", \"url\": \"$url\"},"
    else
      echo "    {\"status\": \"$code\", \"url\": \"$url\"}"
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
