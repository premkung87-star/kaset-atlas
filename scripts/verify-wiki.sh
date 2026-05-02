#!/bin/bash
# ============================================================
# Kaset Atlas — Wiki Verifier (v1)
# ============================================================
#
# Purpose
#   Read-only structural check of the wiki/ knowledge layer.
#   Validates source-card frontmatter, topic-page claim cards,
#   cross-references, confidence rules, and orphan-card detection.
#
#   Mirrors the patterns in scripts/verify-source-table.sh:
#   - Pure bash + sed + awk (no jq, no node deps)
#   - JSON report on stdout, exit 0 = pass, 1 = errors, 2 = arg/file error
#   - Warnings do not fail the run; errors do
#
# Scope (v1)
#   - Source-card frontmatter required keys + enum values
#   - Source-card id uniqueness
#   - Topic-page frontmatter required keys
#   - Claim cards: supporting_source_ids resolve to existing cards
#   - Confidence rules (high requires ≥2 distinct publishers OR ≥1
#     gov-th source with confidence_default=high)
#   - Orphan source cards (must be referenced by ≥1 claim card OR
#     have url appear in any src/content/crops/*.mdx)
#   - URL is http(s) (liveness is verify-urls.sh's job)
#
# NOT in v1
#   - URL liveness (warns if url_checked_at older than 90 days)
#   - Body content checks (translation length, etc. — separate gate)
#   - JSON-Schema validation (schema is informal v1)
#
# Usage
#   scripts/verify-wiki.sh [--root <path>]
#
# Defaults
#   --root  ./wiki      (containing sources/ and topics/)

set -uo pipefail

ROOT="./wiki"
CROPS_DIR="./src/content/crops"
STALE_DAYS=90

while [ $# -gt 0 ]; do
  case "$1" in
    --root)   ROOT="$2"; shift 2 ;;
    --crops)  CROPS_DIR="$2"; shift 2 ;;
    --stale-days) STALE_DAYS="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,40p' "$0" >&2
      exit 0
      ;;
    *) echo "{\"status\":\"error\",\"message\":\"unknown flag: $1\"}"; exit 2 ;;
  esac
done

if [ ! -d "$ROOT" ]; then
  echo "{\"status\":\"error\",\"message\":\"wiki root not found: $ROOT\"}"
  exit 2
fi

ERRORS=()
WARNINGS=()
add_err()  { ERRORS+=("$1"); }
add_warn() { WARNINGS+=("$1"); }

# Allowed enum values
SOURCE_TYPES_RE='^(gov-th|uni-th|gov-int|uni-int|fao|ngo|journal|encyclopedia|other)$'
LICENSE_RE='^(cc|gov-public|copyrighted|unknown)$'
URL_STATUS_RE='^(ok|redirect|dead|unknown)$'
CONFIDENCE_RE='^(high|medium|low|uncertain)$'
APPLIC_RE='^(native|foreign-direct|foreign-with-caveats)$'

REQ_SOURCE_KEYS=(id title publisher url url_status url_checked_at type language access license_class accessed_at topics confidence_default)
REQ_TOPIC_KEYS=(id title_th title_en scope_in scope_out last_updated last_audited)

# Temporary state stored in plain files — works on bash 3.2 (macOS default).
TMPDIR_RUN=$(mktemp -d 2>/dev/null || mktemp -d -t verify-wiki)
trap 'rm -rf "$TMPDIR_RUN"' EXIT

SOURCE_INDEX="$TMPDIR_RUN/sources.tsv"        # id<TAB>publisher<TAB>type<TAB>conf<TAB>url<TAB>file
> "$SOURCE_INDEX"
SEEN_IDS="$TMPDIR_RUN/seen-ids.txt"
> "$SEEN_IDS"
REFERENCED_IDS="$TMPDIR_RUN/referenced-ids.txt"
> "$REFERENCED_IDS"

# ------------------------------------------------------------
# Frontmatter helpers
# ------------------------------------------------------------

# Extract frontmatter block (between first two `---` lines) to a temp file.
extract_frontmatter() {
  local file="$1" out="$2"
  awk '
    BEGIN { state=0 }
    /^---$/ { state++; next }
    state==1 { print }
    state>=2 { exit }
  ' "$file" > "$out"
}

# Get a scalar value for a top-level YAML key.
fm_get() {
  local fm="$1" key="$2"
  awk -v k="^$key:" '
    $0 ~ k {
      sub(/^[^:]+:[[:space:]]*/, "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "$fm"
}

# Check a top-level key exists in frontmatter (scalar OR list).
fm_has_key() {
  local fm="$1" key="$2"
  grep -qE "^${key}:" "$fm"
}

# Days between today and an ISO-8601 date (YYYY-MM-DD or full timestamp).
days_since() {
  local iso="$1"
  iso="${iso%%T*}"   # strip time
  if [ -z "$iso" ]; then echo -1; return; fi
  local ts now
  if date -j -f "%Y-%m-%d" "$iso" +%s >/dev/null 2>&1; then
    ts=$(date -j -f "%Y-%m-%d" "$iso" +%s 2>/dev/null)
  else
    ts=$(date -d "$iso" +%s 2>/dev/null || echo 0)
  fi
  now=$(date +%s)
  if [ "${ts:-0}" -le 0 ]; then echo -1; return; fi
  echo $(( (now - ts) / 86400 ))
}

# ------------------------------------------------------------
# Pass 1 — source cards
# ------------------------------------------------------------

if [ -d "$ROOT/sources" ]; then
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    FM="$TMPDIR_RUN/fm.tmp"
    extract_frontmatter "$f" "$FM"
    if [ ! -s "$FM" ]; then
      add_err "source_card_no_frontmatter(file=$f)"
      continue
    fi

    # Required keys
    for k in "${REQ_SOURCE_KEYS[@]}"; do
      if ! fm_has_key "$FM" "$k"; then
        add_err "source_card_missing_key(file=$f,key=$k)"
      fi
    done

    ID=$(fm_get "$FM" id)
    PUB=$(fm_get "$FM" publisher)
    URL=$(fm_get "$FM" url)
    USTATUS=$(fm_get "$FM" url_status)
    UCHECKED=$(fm_get "$FM" url_checked_at)
    STYPE=$(fm_get "$FM" type)
    LIC=$(fm_get "$FM" license_class)
    CDEF=$(fm_get "$FM" confidence_default)

    # ID
    if [ -z "$ID" ]; then
      add_err "source_card_empty_id(file=$f)"
      continue
    fi
    if ! printf '%s' "$ID" | grep -qE '^[a-z0-9][a-z0-9-]{0,79}$'; then
      add_err "source_card_id_not_kebab_case(file=$f,id=$ID)"
    fi
    if grep -Fxq "$ID" "$SEEN_IDS"; then
      add_err "source_card_duplicate_id(id=$ID,file=$f)"
    else
      printf '%s\n' "$ID" >> "$SEEN_IDS"
    fi

    # URL
    case "$URL" in
      http://*|https://*) ;;
      *) add_err "source_card_url_not_http(file=$f,url=${URL:-<empty>})" ;;
    esac

    # Enums
    if ! printf '%s' "$USTATUS" | grep -qE "$URL_STATUS_RE"; then
      add_err "source_card_url_status_invalid(file=$f,value=${USTATUS:-<empty>})"
    fi
    if ! printf '%s' "$STYPE" | grep -qE "$SOURCE_TYPES_RE"; then
      add_err "source_card_type_invalid(file=$f,value=${STYPE:-<empty>})"
    fi
    if ! printf '%s' "$LIC" | grep -qE "$LICENSE_RE"; then
      add_err "source_card_license_class_invalid(file=$f,value=${LIC:-<empty>})"
    fi
    if ! printf '%s' "$CDEF" | grep -qE "$CONFIDENCE_RE"; then
      add_err "source_card_confidence_default_invalid(file=$f,value=${CDEF:-<empty>})"
    fi

    # url_checked_at staleness
    if [ -n "$UCHECKED" ]; then
      D=$(days_since "$UCHECKED")
      if [ "$D" -gt "$STALE_DAYS" ] 2>/dev/null; then
        add_warn "source_card_url_checked_at_stale(file=$f,id=$ID,age_days=$D,threshold=$STALE_DAYS)"
      fi
    fi

    # Topics required (≥1 entry)
    if ! grep -qE '^topics:' "$FM"; then
      :
    else
      TOPICS_INLINE=$(awk '/^topics:/ { sub(/^topics:[[:space:]]*/, ""); print; exit }' "$FM")
      TOPICS_BLOCK_COUNT=$(awk '
        /^topics:/ { f=1; next }
        f && /^[[:space:]]*-[[:space:]]/ { c++; next }
        f && NF { exit }
        END { print c+0 }
      ' "$FM")
      if [ "$TOPICS_INLINE" = "[]" ] || { [ -z "$TOPICS_INLINE" ] && [ "${TOPICS_BLOCK_COUNT:-0}" -eq 0 ]; }; then
        add_err "source_card_topics_empty(file=$f,id=$ID)"
      fi
    fi

    # Index
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$ID" "$PUB" "$STYPE" "$CDEF" "$URL" "$f" >> "$SOURCE_INDEX"
  done < <(find "$ROOT/sources" -type f -name '*.md' 2>/dev/null | sort)
fi

# ------------------------------------------------------------
# Pass 2 — topic pages and claim cards
# ------------------------------------------------------------

# Look up source publisher/type/conf by id, returns: pub<TAB>type<TAB>conf<TAB>file
lookup_source() {
  local id="$1"
  awk -F'\t' -v id="$id" '$1==id { print $2"\t"$3"\t"$4"\t"$6; exit }' "$SOURCE_INDEX"
}

if [ -d "$ROOT/topics" ]; then
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    FM="$TMPDIR_RUN/topic-fm.tmp"
    extract_frontmatter "$f" "$FM"
    if [ ! -s "$FM" ]; then
      add_err "topic_no_frontmatter(file=$f)"
      continue
    fi
    for k in "${REQ_TOPIC_KEYS[@]}"; do
      if ! fm_has_key "$FM" "$k"; then
        add_err "topic_missing_key(file=$f,key=$k)"
      fi
    done

    # Walk claim cards in body. Each begins with "  - claim_id: ..."
    BODY="$TMPDIR_RUN/topic-body.tmp"
    awk '
      BEGIN { state=0 }
      /^---$/ { state++; next }
      state>=2 { print }
    ' "$f" > "$BODY"

    # Iterate claim_id markers
    CLAIM_LINES=$(grep -nE '^[[:space:]]*-[[:space:]]+claim_id:' "$BODY" | awk -F: '{print $1}')
    if [ -z "$CLAIM_LINES" ]; then
      add_warn "topic_has_no_claims(file=$f)"
    fi

    PREV_LN=""
    while IFS= read -r LN; do
      [ -z "$LN" ] && continue
      # Determine end of this claim block: line before the next claim_id marker, or EOF
      NEXT_LN=$(grep -nE '^[[:space:]]*-[[:space:]]+claim_id:' "$BODY" | awk -F: -v cur="$LN" '$1>cur { print $1; exit }')
      if [ -z "$NEXT_LN" ]; then
        END_LN=$(wc -l < "$BODY" | tr -d ' ')
      else
        END_LN=$((NEXT_LN-1))
      fi

      BLOCK="$TMPDIR_RUN/claim-block.tmp"
      sed -n "${LN},${END_LN}p" "$BODY" > "$BLOCK"

      CID=$(awk '/claim_id:/ { sub(/.*claim_id:[[:space:]]*/, ""); gsub(/^"|"$/, ""); print; exit }' "$BLOCK")
      CCONF=$(awk '/^[[:space:]]+confidence:/ { sub(/.*confidence:[[:space:]]*/, ""); print; exit }' "$BLOCK")
      CAPPL=$(awk '/^[[:space:]]+thailand_applicability:/ { sub(/.*thailand_applicability:[[:space:]]*/, ""); print; exit }' "$BLOCK")
      CNOTES=$(awk '/^[[:space:]]+notes:/ { sub(/.*notes:[[:space:]]*"?/, ""); sub(/"[[:space:]]*$/, ""); print; exit }' "$BLOCK")

      if [ -z "$CID" ]; then
        add_err "claim_missing_claim_id(file=$f,line=$LN)"
        continue
      fi
      if ! printf '%s' "$CCONF" | grep -qE "$CONFIDENCE_RE"; then
        add_err "claim_confidence_invalid(file=$f,claim=$CID,value=${CCONF:-<empty>})"
      fi
      if ! printf '%s' "$CAPPL" | grep -qE "$APPLIC_RE"; then
        add_err "claim_thailand_applicability_invalid(file=$f,claim=$CID,value=${CAPPL:-<empty>})"
      fi

      # Supporting source ids: list items between supporting_source_ids: and next non-list-item
      SIDS=$(awk '
        /supporting_source_ids:/ { f=1; next }
        f && /^[[:space:]]+-[[:space:]]+/ {
          sub(/^[[:space:]]+-[[:space:]]+/, "")
          gsub(/^"|"$/, "")
          print
          next
        }
        f && /^[[:space:]]+[^[:space:]-]/ { exit }
      ' "$BLOCK")

      if [ -z "$SIDS" ]; then
        add_err "claim_no_supporting_sources(file=$f,claim=$CID)"
        continue
      fi

      DISTINCT_PUBS="$TMPDIR_RUN/pubs.$$"
      > "$DISTINCT_PUBS"
      HAS_GOVTH_HIGH=0
      RESOLVED=0

      while IFS= read -r SID; do
        [ -z "$SID" ] && continue
        ROW=$(lookup_source "$SID")
        if [ -z "$ROW" ]; then
          add_err "claim_unknown_source_id(file=$f,claim=$CID,source_id=$SID)"
          continue
        fi
        RESOLVED=$((RESOLVED+1))
        PUB=$(printf '%s' "$ROW" | awk -F'\t' '{print $1}')
        STYP=$(printf '%s' "$ROW" | awk -F'\t' '{print $2}')
        SCONF=$(printf '%s' "$ROW" | awk -F'\t' '{print $3}')
        printf '%s\n' "$PUB" >> "$DISTINCT_PUBS"
        if [ "$STYP" = "gov-th" ] && [ "$SCONF" = "high" ]; then
          HAS_GOVTH_HIGH=1
        fi
        printf '%s\n' "$SID" >> "$REFERENCED_IDS"
      done <<< "$SIDS"

      DISTINCT_PUB_COUNT=$(sort -u "$DISTINCT_PUBS" | wc -l | tr -d ' ')

      # Confidence rule enforcement
      case "$CCONF" in
        high)
          if [ "$DISTINCT_PUB_COUNT" -lt 2 ] && [ "$HAS_GOVTH_HIGH" -eq 0 ]; then
            add_err "claim_high_confidence_unsupported(file=$f,claim=$CID,distinct_publishers=$DISTINCT_PUB_COUNT,gov_th_high=$HAS_GOVTH_HIGH)"
          fi
          ;;
        medium)
          if [ "$RESOLVED" -lt 1 ]; then
            add_err "claim_medium_confidence_no_sources(file=$f,claim=$CID)"
          elif [ "$RESOLVED" -eq 1 ] && [ "$DISTINCT_PUB_COUNT" -le 1 ]; then
            add_warn "claim_medium_confidence_single_source(file=$f,claim=$CID)"
          fi
          ;;
        low)
          if [ "$RESOLVED" -lt 1 ]; then
            add_err "claim_low_confidence_no_sources(file=$f,claim=$CID)"
          fi
          ;;
        uncertain)
          if [ -z "$CNOTES" ]; then
            add_err "claim_uncertain_without_notes(file=$f,claim=$CID)"
          fi
          ;;
      esac

      rm -f "$DISTINCT_PUBS"
    done <<< "$CLAIM_LINES"

  done < <(find "$ROOT/topics" -type f -name '*.md' 2>/dev/null | sort)
fi

# ------------------------------------------------------------
# Pass 3 — orphan source cards
# ------------------------------------------------------------

# A card is non-orphan if its id appears in REFERENCED_IDS, OR its url
# appears in any src/content/crops/*.mdx file.

CROP_URL_INDEX="$TMPDIR_RUN/crop-urls.txt"
> "$CROP_URL_INDEX"
if [ -d "$CROPS_DIR" ]; then
  grep -hoE 'https?://[^[:space:]"<>)]+' "$CROPS_DIR"/*.mdx 2>/dev/null \
    | sed -E 's/[\.,;:!]+$//' | sort -u > "$CROP_URL_INDEX"
fi

while IFS=$'\t' read -r ID PUB STYP CDEF URL FILE; do
  [ -z "$ID" ] && continue
  REFERENCED=0
  if grep -Fxq "$ID" "$REFERENCED_IDS"; then
    REFERENCED=1
  fi
  if [ "$REFERENCED" -eq 0 ] && [ -n "$URL" ] && [ -s "$CROP_URL_INDEX" ]; then
    if grep -Fxq "$URL" "$CROP_URL_INDEX"; then
      REFERENCED=1
    fi
  fi
  if [ "$REFERENCED" -eq 0 ]; then
    add_warn "orphan_source_card(id=$ID,file=$FILE)"
  fi
done < "$SOURCE_INDEX"

# ------------------------------------------------------------
# Output
# ------------------------------------------------------------

ERR_COUNT=${#ERRORS[@]}
WARN_COUNT=${#WARNINGS[@]}
SOURCE_COUNT=$(wc -l < "$SOURCE_INDEX" | tr -d ' ')
[ -z "$SOURCE_COUNT" ] && SOURCE_COUNT=0
TOPIC_COUNT=$(find "$ROOT/topics" -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
[ -z "$TOPIC_COUNT" ] && TOPIC_COUNT=0

STATUS="pass"
EXIT=0
[ "$ERR_COUNT" -gt 0 ] && STATUS="fail" && EXIT=1

# JSON-escape helper
jesc() { sed 's/\\/\\\\/g; s/"/\\"/g' ; }

ERR_JSON=""
SEP=""
for e in "${ERRORS[@]:-}"; do
  [ -z "$e" ] && continue
  ESC=$(printf '%s' "$e" | jesc)
  ERR_JSON+="${SEP}\"$ESC\""
  SEP=","
done

WARN_JSON=""
SEP=""
for w in "${WARNINGS[@]:-}"; do
  [ -z "$w" ] && continue
  ESC=$(printf '%s' "$w" | jesc)
  WARN_JSON+="${SEP}\"$ESC\""
  SEP=","
done

cat <<EOF
{
  "verifier_version": "v1-wiki",
  "wiki_root": "$ROOT",
  "source_cards_seen": $SOURCE_COUNT,
  "topic_pages_seen": $TOPIC_COUNT,
  "stale_threshold_days": $STALE_DAYS,
  "errors": [$ERR_JSON],
  "warnings": [$WARN_JSON],
  "error_count": $ERR_COUNT,
  "warning_count": $WARN_COUNT,
  "verification_status": "$STATUS"
}
EOF

exit $EXIT
