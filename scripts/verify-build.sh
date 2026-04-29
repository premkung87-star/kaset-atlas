#!/bin/bash
# ============================================
# Kaset Atlas — Build Verifier
# Runs `npm run build` as the final pre-commit gate in the auto pipeline.
# ============================================
#
# Usage:
#   ./scripts/verify-build.sh
#
# Exits 0 if build succeeds, 1 if build fails.
# JSON report on stdout. Build log streamed to stderr on failure (last 30 lines).

set -uo pipefail

LOG=/tmp/kaset-atlas-build.log

echo "Running: npm run build" >&2

npm run build > "$LOG" 2>&1
EXIT_CODE=$?

if [ "$EXIT_CODE" -eq 0 ]; then
  PAGES=$(grep -oE '[0-9]+ page\(s\) built' "$LOG" | head -1 || echo "build complete")
  PAGEFIND=$(grep -c "Indexed [0-9]* pages" "$LOG" || echo 0)
  printf '{"build_status":"pass","summary":"%s","pagefind_indexed":%d,"log_path":"%s"}\n' \
    "$PAGES" "$PAGEFIND" "$LOG"
  exit 0
else
  printf '{"build_status":"fail","exit_code":%d,"log_path":"%s"}\n' "$EXIT_CODE" "$LOG"
  echo "" >&2
  echo "=== Last 30 lines of build log ===" >&2
  tail -30 "$LOG" >&2
  exit 1
fi
