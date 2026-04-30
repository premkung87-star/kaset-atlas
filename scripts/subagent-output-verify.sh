#!/bin/bash
# ============================================================
# Kaset Atlas — Subagent Output Verifier (Day-1 instrumentation)
# ============================================================
#
# Purpose
#   Detect Category A failures (subagent tool execution failure) at the moment
#   they happen by comparing the subagent's CLAIMED file outputs against disk
#   reality. Several incidents (cassava pass-3 verifier, mango researcher,
#   mango drafter, mango verifier x2) showed subagents reporting successful
#   tool calls when no files were actually written. This script makes that
#   discrepancy a hard, deterministic gate.
#
# Scope (Day 1 only)
#   - claimed file exists
#   - file size >= --min-size  (default 1024 bytes)
#   - file mtime >= --mtime-after if provided (run-window check)
#   - emits JSON report on stdout
#   - appends one NDJSON line to .claude/logs/subagent-dispatch.json
#
# Usage
#   scripts/subagent-output-verify.sh \
#       --run-id <uuid> --stage <stage> --agent <agent> \
#       [--mtime-after <iso8601>] [--min-size <bytes>] \
#       [--tool-calls-claimed <int>] \
#       <file1> [<file2> ...]
#
# Exits
#   0 — all files passed
#   1 — at least one file missing / undersized / pre-window
#   2 — argument error
#
# Designed to be reversible: this script does not modify any source file,
# does not run network calls, and writes only to .claude/logs/.

set -uo pipefail

RUN_ID=""
STAGE=""
AGENT=""
MTIME_AFTER=""
MIN_SIZE=1024
TOOL_CALLS_CLAIMED=""
FILES=()

usage() {
  sed -n '2,33p' "$0" >&2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --run-id)              RUN_ID="$2"; shift 2 ;;
    --stage)               STAGE="$2"; shift 2 ;;
    --agent)               AGENT="$2"; shift 2 ;;
    --mtime-after)         MTIME_AFTER="$2"; shift 2 ;;
    --min-size)            MIN_SIZE="$2"; shift 2 ;;
    --tool-calls-claimed)  TOOL_CALLS_CLAIMED="$2"; shift 2 ;;
    -h|--help)             usage; exit 0 ;;
    --)                    shift; while [ $# -gt 0 ]; do FILES+=("$1"); shift; done ;;
    -*)                    echo "{\"status\":\"error\",\"message\":\"unknown flag: $1\"}"; exit 2 ;;
    *)                     FILES+=("$1"); shift ;;
  esac
done

if [ -z "$STAGE" ]; then
  echo '{"status":"error","message":"--stage is required (e.g. drafter, content-verifier)"}'
  exit 2
fi
if [ -z "$AGENT" ]; then
  echo '{"status":"error","message":"--agent is required (e.g. drafter, content-verifier)"}'
  exit 2
fi
if [ "${#FILES[@]}" -eq 0 ]; then
  echo '{"status":"error","message":"no files to verify (pass at least one path)"}'
  exit 2
fi

# Default run_id when caller did not provide one. Keeps each invocation
# joinable in the log even if the orchestrator forgot to set it.
if [ -z "$RUN_ID" ]; then
  if command -v uuidgen >/dev/null 2>&1; then
    RUN_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
  else
    RUN_ID="run-$(date +%s)"
  fi
fi

# Convert --mtime-after to epoch. Try BSD date first (macOS), then GNU date.
MTIME_AFTER_EPOCH=0
if [ -n "$MTIME_AFTER" ]; then
  if date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$MTIME_AFTER" +%s >/dev/null 2>&1; then
    MTIME_AFTER_EPOCH=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$MTIME_AFTER" +%s)
  elif date -u -d "$MTIME_AFTER" +%s >/dev/null 2>&1; then
    MTIME_AFTER_EPOCH=$(date -u -d "$MTIME_AFTER" +%s)
  else
    echo "{\"status\":\"error\",\"message\":\"could not parse --mtime-after: $MTIME_AFTER (expect ISO 8601 like 2026-04-30T10:00:00Z)\"}"
    exit 2
  fi
fi

# Cross-platform stat helpers (BSD/macOS first, then GNU/Linux).
get_size()  { stat -f %z "$1" 2>/dev/null || stat -c %s "$1" 2>/dev/null || echo 0; }
get_mtime() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0; }

NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
PASS=0
FAIL=0
RESULTS=""
SEP=""
FAIL_DETAIL=""

for f in "${FILES[@]}"; do
  REASON=""
  SIZE=0
  MTIME=0

  if [ ! -f "$f" ]; then
    REASON="missing"
  else
    SIZE=$(get_size "$f")
    MTIME=$(get_mtime "$f")
    # Treat non-numeric stat output as 0.
    case "$SIZE" in (*[!0-9]*|"") SIZE=0 ;; esac
    case "$MTIME" in (*[!0-9]*|"") MTIME=0 ;; esac

    if [ "$SIZE" -lt "$MIN_SIZE" ]; then
      REASON="size_below_min(size=${SIZE},min=${MIN_SIZE})"
    elif [ "$MTIME_AFTER_EPOCH" -gt 0 ] && [ "$MTIME" -lt "$MTIME_AFTER_EPOCH" ]; then
      REASON="mtime_before_run_window(mtime=${MTIME},after=${MTIME_AFTER_EPOCH})"
    fi
  fi

  if [ -z "$REASON" ]; then
    PASS=$((PASS+1))
    RESULTS+="${SEP}{\"file\":\"$f\",\"status\":\"pass\",\"size\":${SIZE},\"mtime_epoch\":${MTIME}}"
  else
    FAIL=$((FAIL+1))
    RESULTS+="${SEP}{\"file\":\"$f\",\"status\":\"fail\",\"reason\":\"$REASON\",\"size\":${SIZE},\"mtime_epoch\":${MTIME}}"
    FAIL_DETAIL+="${f}=${REASON}; "
  fi
  SEP=","
done

OVERALL="pass"
[ "$FAIL" -gt 0 ] && OVERALL="fail"

# Optional fields render conditionally to keep the schema clean.
TOOL_CALLS_FIELD=""
if [ -n "$TOOL_CALLS_CLAIMED" ]; then
  TOOL_CALLS_FIELD="  \"tool_calls_claimed\": ${TOOL_CALLS_CLAIMED},
"
fi

# stdout report (pretty)
cat <<EOF
{
  "schema_version": "v2-day1",
  "date": "$NOW",
  "run_id": "$RUN_ID",
  "stage": "$STAGE",
  "agent": "$AGENT",
  "files_claimed_written": ${#FILES[@]},
  "files_verified_existing": $PASS,
  "files_failed": $FAIL,
${TOOL_CALLS_FIELD}  "min_size_bytes": $MIN_SIZE,
  "mtime_after": "$MTIME_AFTER",
  "results": [$RESULTS],
  "verification_status": "$OVERALL"
}
EOF

# Append one NDJSON line to the dispatch log (committed; trail of evidence).
LOG=".claude/logs/subagent-dispatch.json"
mkdir -p "$(dirname "$LOG")"

# Build the NDJSON line (compact form).
LINE="{\"schema_version\":\"v2-day1\""
LINE+=",\"date\":\"$NOW\""
LINE+=",\"run_id\":\"$RUN_ID\""
LINE+=",\"stage\":\"$STAGE\""
LINE+=",\"agent\":\"$AGENT\""
LINE+=",\"files_claimed_written\":${#FILES[@]}"
LINE+=",\"files_verified_existing\":$PASS"
LINE+=",\"files_failed\":$FAIL"
if [ -n "$TOOL_CALLS_CLAIMED" ]; then
  LINE+=",\"tool_calls_claimed\":${TOOL_CALLS_CLAIMED}"
fi
LINE+=",\"verification_status\":\"$OVERALL\""
if [ "$FAIL" -gt 0 ]; then
  ESC=$(printf '%s' "$FAIL_DETAIL" | sed 's/\\/\\\\/g; s/"/\\"/g')
  LINE+=",\"failure_type\":\"subagent-dispatch-failure\""
  LINE+=",\"failure_detail\":\"$ESC\""
fi
LINE+="}"
printf '%s\n' "$LINE" >> "$LOG"

if [ "$FAIL" -eq 0 ]; then
  exit 0
else
  exit 1
fi
