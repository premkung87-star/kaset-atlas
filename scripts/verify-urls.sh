#!/bin/bash
# Kaset Atlas — URL Verifier (v3 — adds soft-200 body check)
#
# v1: HEAD only — too many false negatives
# v2: GET-with-byte-range fallback — fixed false negatives but missed soft-200 errors
# v3: GET + first-4KB body inspection — catches Thai gov "ไม่พบกระทู้" / "ไม่พบ File"
#     and other 200-status error pages that v2 missed
#
# Pattern Win recorded in docs/WORKFLOW_KIT.md §4 (2026-04-29 third entry).
#
# Usage:
#   ./scripts/verify-urls.sh src/content/crops/<slug>.mdx
#
# Exits 0 if all URLs return real 200/206/301/302/304 with no soft-error body.
# Exits 1 if any URL fails (HTTP error or soft-200 error page).
# JSON report on stdout.

set -uo pipefail

FILE="${1:-}"
[ -z "$FILE" ] && { echo '{"status":"error","message":"Usage: $0 <path-to-mdx>"}'; exit 2; }
[ ! -f "$FILE" ] && { echo "{\"status\":\"error\",\"message\":\"File not found: $FILE\"}"; exit 2; }

UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

# Soft-200 error markers (200 status but page body is actually an error)
# Tightened to specific error-page phrases to avoid false positives on
# legit pages that mention "ไม่พบ" (Thai "not found") in unrelated context.
# Patterns observed in real Thai-gov error pages:
#   - DOA Share forum: "ไม่พบกระทู้ที่ระบุ"
#   - opsmoac file system: "ไม่พบ File นี้ในระบบ"
SOFT_ERROR_PATTERNS='ไม่พบกระทู้ที่ระบุ|ไม่พบ File นี้|ไม่พบไฟล์นี้|ไม่พบไฟล์ที่ต้องการ|ไม่พบหน้าที่ระบุ|ไม่พบหน้านี้ในระบบ|ไม่พบบทความ|ไม่พบข้อมูลที่ระบุ|<title>[^<]*404[^<]*</title>|<title>[^<]*Page Not Found|<title>[^<]*ไม่พบกระทู้|<title>[^<]*ไม่พบ File|<title>[^<]*ไม่พบหน้า|>404 Not Found<|>Page not found<|<h1[^>]*>[^<]*404 Not Found'

URLS=$(grep -oE 'https?://[^[:space:]"<>)]+' "$FILE" | sort -u)
[ -z "$URLS" ] && { echo '{"status":"error","message":"No URLs found"}'; exit 2; }

TOTAL=0; PASSED=0; FAILED=0
FAILED_URLS=()

# Temp file for body capture
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

while IFS= read -r url; do
  TOTAL=$((TOTAL + 1))
  url_clean="${url%[\.,\)\]\>]}"

  # Single curl: fetch first 4KB, capture status + effective URL, write body to temp
  : > "$TMP"
  combined=$(curl -s -L --max-time 15 -r 0-4095 \
    --user-agent "$UA" \
    -w "%{http_code}|%{url_effective}" \
    -o "$TMP" \
    "$url_clean" 2>/dev/null)
  status="${combined%%|*}"
  [ -z "$status" ] && status="000"

  case "$status" in
    200|206|301|302|304)
      # HTTP status looks good — check body for soft-200 error markers
      if [ -s "$TMP" ] && grep -qiE "$SOFT_ERROR_PATTERNS" "$TMP" 2>/dev/null; then
        # Soft-200: server returned 200 but page body is an error
        FAILED=$((FAILED + 1))
        FAILED_URLS+=("soft-200|$url_clean")
      else
        PASSED=$((PASSED + 1))
      fi
      ;;
    *)
      # Retry with full GET (some servers reject Range header)
      : > "$TMP"
      combined_retry=$(curl -s -L --max-time 15 \
        --user-agent "$UA" \
        -w "%{http_code}" \
        -o "$TMP" \
        "$url_clean" 2>/dev/null)
      status_retry="${combined_retry:-000}"

      case "$status_retry" in
        200|206|301|302|304)
          # Same soft-200 check on retry
          if [ -s "$TMP" ] && grep -qiE "$SOFT_ERROR_PATTERNS" "$TMP" 2>/dev/null; then
            FAILED=$((FAILED + 1))
            FAILED_URLS+=("soft-200|$url_clean")
          else
            PASSED=$((PASSED + 1))
          fi
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
echo "  \"verifier_version\": \"v3-soft200-aware\","
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
