#!/bin/bash
# ============================================================
# Kaset Atlas — Source-Table Integrity Verifier
# ============================================================
#
# Purpose
#   Deterministic structural check on a crop MDX file's "## ... แหล่งข้อมูล"
#   table. Catches drafter / verifier failures where the source table is
#   malformed (missing columns, broken Markdown links, duplicate URLs,
#   stray URLs in body prose) before publication. Companion to
#   verify-urls.sh (which checks URL liveness) and check-mdx-safety.sh
#   (which checks JSX-parser footguns).
#
# Scope (this script)
#   STRUCTURAL checks only. URL liveness, soft-200 detection, and
#   content fidelity are OUT OF SCOPE — they belong to verify-urls.sh
#   and the (future) verify-claim-grounding.sh.
#
# Format reality (verified against sweet-basil/holy-basil/cassava/mango,
# 2026-04-30):
#   - Heading: "## <number?> แหล่งข้อมูล" at H2 level
#   - Real crops: 4 data columns
#       | ส่วน | แหล่งที่มา | ประเภท | ความน่าเชื่อถือ |   (or ระดับความเชื่อถือ)
#   - Template: 5 data columns (adds a "วันที่" column)
#   - The "แหล่งที่มา" cell contains a Markdown link: [title](url)
#   - Confidence cell: 🟢/🟡/🟠/⚪ (Thai) or High/Medium/Low/Uncertain
#   - All URLs in the file appear inside the source-table section
#     (zero body-level URLs in any of the 4 real crops as of 2026-04-30)
#
# Note on body↔row coverage: the current MDX format has NO source-IDs in
# body prose; citation lives in the table only. So the bidirectional
# "every row is referenced" check is not applicable today. We instead
# verify "every URL in the file appears inside the source-table section"
# which catches stray body URLs that escape the citation discipline.
#
# Note on reasoning-sidecar cross-check: the sidecar uses internal source
# IDs (e.g. "doa-hort-mango-db") that are NOT present in the MDX table.
# Cross-checking sidecar IDs against table URLs requires a URL↔ID join
# that today's schema does not provide. DEFERRED to claim-grounding work.
#
# Usage
#   scripts/verify-source-table.sh [--min-sources <N>] [--allow-template] <path-to-mdx>
#
# Flags
#   --min-sources <N>    Minimum data-row count (default: 9, per SOURCE_POLICY:
#                        6 Thai + 3 international)
#   --allow-template     Skip the minimum-row check (for _template.mdx etc.)
#   -h|--help            Print this header
#
# Exits
#   0  all checks passed
#   1  one or more issues found
#   2  argument or file error
#
# Output: JSON report on stdout. No log file written (this is a pure check;
# the dispatch log is verifier-output's job).

set -uo pipefail

FILE=""
MIN_SOURCES=9
ALLOW_TEMPLATE=0

usage() {
  sed -n '2,46p' "$0" >&2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --min-sources)     MIN_SOURCES="$2"; shift 2 ;;
    --allow-template)  ALLOW_TEMPLATE=1; shift ;;
    -h|--help)         usage; exit 0 ;;
    -*)                echo "{\"status\":\"error\",\"message\":\"unknown flag: $1\"}"; exit 2 ;;
    *)                 FILE="$1"; shift ;;
  esac
done

if [ -z "$FILE" ]; then
  echo '{"status":"error","message":"path to MDX file required"}'
  exit 2
fi
if [ ! -f "$FILE" ]; then
  echo "{\"status\":\"error\",\"message\":\"file not found: $FILE\"}"
  exit 2
fi

ISSUES=()
add_issue() { ISSUES+=("$1"); }

# Extract the source-table section: from "## ... แหล่งข้อมูล" up to the
# next "---" horizontal rule (or EOF). Use a tmp file so we can scan it
# multiple times without re-running awk.
SECTION=$(mktemp)
trap 'rm -f "$SECTION"' EXIT

awk '
  /^## .*แหล่งข้อมูล/ { flag=1; next }
  flag && /^---$/      { flag=0 }
  flag                  { print }
' "$FILE" > "$SECTION"

if [ ! -s "$SECTION" ]; then
  printf '{"status":"fail","file":"%s","issues":[{"type":"missing_source_table_heading","detail":"no \\u0023\\u0023 ... \\u0e41\\u0e2b\\u0e25\\u0e48\\u0e07\\u0e02\\u0e49\\u0e2d\\u0e21\\u0e39\\u0e25 heading found"}]}\n' "$FILE"
  exit 1
fi

# Find the header row (first line starting with "| " inside the section).
HEADER=$(awk '/^\| / { print; exit }' "$SECTION")
if [ -z "$HEADER" ]; then
  add_issue "no_table_header_row"
fi

# Header column count: pipes minus 1 = column count (leading and trailing pipes).
HDR_PIPES=$(printf '%s' "$HEADER" | tr -cd '|' | wc -c | tr -d ' ')
HDR_COLS=$((HDR_PIPES - 1))
if [ "$HDR_COLS" -lt 4 ]; then
  add_issue "header_column_count_too_low(cols=${HDR_COLS},min=4)"
fi

# Separator row should immediately follow the header. Real format is
# "|---|---|---|---|" (no leading space), so match any line starting with
# "|" and pick the second such line in the section.
SEP=$(awk '/^\|/ { c++; if (c==2) { print; exit } }' "$SECTION")
if ! printf '%s' "$SEP" | grep -qE '^\|[ -]*\|([ -]*\|)+$'; then
  add_issue "missing_or_malformed_separator_row"
fi

# Extract data rows (every "| " line after the separator), keeping track
# of original line numbers from the file for error reporting.
DATA_LINES=$(grep -n '^| ' "$FILE" | awk -F: '{print $1}' )

# Get the line numbers that are inside the section so we can filter.
SECTION_START=$(awk '/^## .*แหล่งข้อมูล/{print NR; exit}' "$FILE")
SECTION_END=$(awk -v start="$SECTION_START" '
  NR > start && /^---$/ { print NR; found=1; exit }
  END { if (!found) print NR }
' "$FILE")
[ -z "$SECTION_END" ] && SECTION_END=$(wc -l < "$FILE" | tr -d ' ')

ROW_COUNT=0
URLS=()
# Parallel indexed arrays for first-seen-URL tracking (bash 3.2 has no
# associative arrays).
SEEN_URLS=()
SEEN_LINES=()
DUPLICATES=()

CONFIDENCE_RE='🟢|🟡|🟠|⚪|High|Medium|Low|Uncertain'

# Iterate data rows by line number.
while IFS= read -r LN; do
  [ -z "$LN" ] && continue
  if [ "$LN" -le "$SECTION_START" ] || [ "$LN" -ge "$SECTION_END" ]; then
    continue
  fi
  ROW=$(sed -n "${LN}p" "$FILE")

  # Skip header and separator
  if [ "$ROW" = "$HEADER" ]; then continue; fi
  if printf '%s' "$ROW" | grep -qE '^\|[ -]*\|([ -]*\|)+$'; then continue; fi

  ROW_COUNT=$((ROW_COUNT+1))

  # Column count check
  ROW_PIPES=$(printf '%s' "$ROW" | tr -cd '|' | wc -c | tr -d ' ')
  ROW_COLS=$((ROW_PIPES - 1))
  if [ "$ROW_COLS" -ne "$HDR_COLS" ]; then
    add_issue "row_column_count_mismatch(line=${LN},row_cols=${ROW_COLS},header_cols=${HDR_COLS})"
    continue
  fi

  # Cell extraction. With leading and trailing pipes, awk -F'|' produces
  # NF = HDR_COLS+2 fields; field 1 and field NF are the empty strings
  # before/after the outer pipes. Cells are fields 2..NF-1.
  CELL1=$(printf '%s' "$ROW" | awk -F'|' '{ s=$2; sub(/^ +/,"",s); sub(/ +$/,"",s); print s }')
  CELL2=$(printf '%s' "$ROW" | awk -F'|' '{ s=$3; sub(/^ +/,"",s); sub(/ +$/,"",s); print s }')
  CELL3=$(printf '%s' "$ROW" | awk -F'|' '{ s=$4; sub(/^ +/,"",s); sub(/ +$/,"",s); print s }')
  CELL_LAST=$(printf '%s' "$ROW" | awk -F'|' -v n="$HDR_COLS" '{ s=$(n+1); sub(/^ +/,"",s); sub(/ +$/,"",s); print s }')

  # Cell 1 (ส่วน) non-empty
  if [ -z "$CELL1" ]; then
    add_issue "empty_section_cell(line=${LN})"
  fi

  # Cell 2 (แหล่งที่มา) must contain a Markdown link [title](url)
  TITLE=$(printf '%s' "$CELL2" | sed -nE 's/.*\[([^]]+)\]\(([^)[:space:]]+)\).*/\1/p')
  URL=$(printf '%s' "$CELL2" | sed -nE 's/.*\[([^]]+)\]\(([^)[:space:]]+)\).*/\2/p')
  if [ -z "$TITLE" ] || [ -z "$URL" ]; then
    add_issue "malformed_or_missing_markdown_link(line=${LN},cell2=${CELL2:0:80})"
  else
    # URL well-formedness
    case "$URL" in
      http://*|https://*) ;;
      *) add_issue "url_not_http(line=${LN},url=${URL})" ;;
    esac
    # No spaces (already enforced by regex character class), no obvious
    # truncation patterns
    if printf '%s' "$URL" | grep -qE '[[:space:]]'; then
      add_issue "url_contains_whitespace(line=${LN},url=${URL})"
    fi
    # Duplicate detection (linear scan; row counts are small)
    DUP_FIRST_LINE=""
    if [ "${#SEEN_URLS[@]}" -gt 0 ]; then
      for k in "${!SEEN_URLS[@]}"; do
        if [ "${SEEN_URLS[$k]}" = "$URL" ]; then
          DUP_FIRST_LINE="${SEEN_LINES[$k]}"
          break
        fi
      done
    fi
    if [ -n "$DUP_FIRST_LINE" ]; then
      DUPLICATES+=("first_line=${DUP_FIRST_LINE},dup_line=${LN},url=${URL}")
    else
      SEEN_URLS+=("$URL")
      SEEN_LINES+=("$LN")
    fi
    URLS+=("$URL")
  fi

  # Cell 3 (ประเภท) non-empty
  if [ -z "$CELL3" ]; then
    add_issue "empty_type_cell(line=${LN})"
  fi

  # Last cell (confidence): must contain one of the allowed indicators
  if ! printf '%s' "$CELL_LAST" | grep -qE "$CONFIDENCE_RE"; then
    add_issue "missing_or_unrecognized_confidence(line=${LN},cell=${CELL_LAST:0:60})"
  fi
done <<< "$DATA_LINES"

# Duplicate URLs
if [ "${#DUPLICATES[@]}" -gt 0 ]; then
  for d in "${DUPLICATES[@]}"; do
    add_issue "duplicate_url(${d})"
  done
fi

# Minimum row count
if [ "$ALLOW_TEMPLATE" -eq 0 ] && [ "$ROW_COUNT" -lt "$MIN_SOURCES" ]; then
  add_issue "row_count_below_minimum(rows=${ROW_COUNT},min=${MIN_SOURCES})"
fi

# Coverage: every URL anywhere in the file should be inside the section.
ALL_URLS=$(grep -oE 'https?://[^[:space:]"<>)]+' "$FILE" | sort -u)
SECTION_URLS=$(grep -oE 'https?://[^[:space:]"<>)]+' "$SECTION" | sort -u)

# Trim trailing punctuation that grep may pick up from prose context.
normalize() { sed -E 's/[\.,;:!]+$//' ; }
ALL_URLS_N=$(printf '%s\n' "$ALL_URLS" | normalize | sort -u)
SECTION_URLS_N=$(printf '%s\n' "$SECTION_URLS" | normalize | sort -u)

STRAY=$(comm -23 <(printf '%s\n' "$ALL_URLS_N") <(printf '%s\n' "$SECTION_URLS_N"))
if [ -n "$STRAY" ]; then
  while IFS= read -r url; do
    [ -z "$url" ] && continue
    add_issue "url_in_body_outside_source_table(${url})"
  done <<< "$STRAY"
fi

# Build JSON report
TOTAL_ISSUES=${#ISSUES[@]}
STATUS="pass"
EXIT=0
[ "$TOTAL_ISSUES" -gt 0 ] && STATUS="fail" && EXIT=1

# JSON-escape each issue (handle backslash and double-quote)
ISSUES_JSON=""
SEP=""
if [ "${#ISSUES[@]}" -gt 0 ]; then
  for i in "${ISSUES[@]}"; do
    ESC=$(printf '%s' "$i" | sed 's/\\/\\\\/g; s/"/\\"/g')
    ISSUES_JSON+="${SEP}\"$ESC\""
    SEP=","
  done
fi

cat <<EOF
{
  "file": "$FILE",
  "verifier_version": "v1-source-table",
  "header_columns": ${HDR_COLS:-0},
  "data_rows": $ROW_COUNT,
  "min_required": $MIN_SOURCES,
  "allow_template": $([ "$ALLOW_TEMPLATE" -eq 1 ] && echo "true" || echo "false"),
  "unique_urls_in_table": ${#URLS[@]},
  "issues_found": $TOTAL_ISSUES,
  "issues": [$ISSUES_JSON],
  "verification_status": "$STATUS"
}
EOF

exit $EXIT
