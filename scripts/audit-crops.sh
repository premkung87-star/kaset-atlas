#!/bin/bash
# ============================================================
# Kaset Atlas — Crop Audit Harness (Day-3 baseline benchmark)
# ============================================================
#
# Purpose
#   Run the deterministic forward-looking reliability gates against
#   every crop in src/content/crops/ and produce a baseline pass/fail
#   matrix. Lets the maintainer detect drift over time without running
#   each gate manually per crop.
#
# Default gates (no network, no build)
#   - check-mdx-safety.sh        (JSX-parser footgun detection)
#   - verify-source-table.sh     (table structure, body↔table coverage)
#   - verify-claim-grounding.sh  (sidecar contract, with --with-mdx
#                                 cross-check when sidecar exists)
#
# Opt-in gates
#   --with-urls    Run verify-urls.sh on each crop (NETWORK calls)
#   --with-build   Run verify-build.sh once globally (heavy: npm build)
#
# Output
#   Default: human-readable summary on stdout
#   --json:  machine-readable JSON on stdout
#
# Known exceptions
#   The script ships with an explicit list of historical exceptions
#   (e.g. mango sidecar↔MDX desync). These are surfaced in the report,
#   never silently normalized, and excluded from the failure count for
#   exit-code purposes. New failures (i.e. failures not in the known
#   list) cause exit 1.
#
#   Edit KNOWN_EXCEPTIONS below — do not hide failures by adding
#   entries casually. Each entry MUST include a documented reason.
#
# Exits
#   0  all forward-looking gates pass (known exceptions are exempt)
#   1  at least one new (unknown) gate failure
#   2  argument or environment error
#
# Network / state
#   Default: no network. With --with-urls: HTTP HEAD/GET via curl.
#   No log files written. No state mutation. Read-only against the
#   working tree (does not modify any crop file).

set -uo pipefail

# -------------------- known historical exceptions --------------------
# Format: "<crop_slug>::<gate>::<documented reason>"
# Adding to this list requires a documented reason. Do not silence
# new failures here — the right path is to fix the underlying issue
# in the crop or the gate.
KNOWN_EXCEPTIONS=(
  "mango::verify-claim-grounding::Sidecar references 12 unique source IDs while MDX source table has 11 URLs. The 12th ID is doaenews-mango-seed-weevil, documented in mango.reasoning.json production_note as identified during research but intentionally not added to the source table to keep it at 11 entries. Mango shipped 2026-04-30 before this gate existed; resolution deferred to a future maintainer-led sidecar trim or MDX row addition."
)

# -------------------- arg parsing --------------------
WITH_URLS=0
WITH_BUILD=0
JSON_OUT=0

usage() {
  sed -n '2,42p' "$0" >&2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --with-urls)    WITH_URLS=1; shift ;;
    --with-build)   WITH_BUILD=1; shift ;;
    --json)         JSON_OUT=1; shift ;;
    -h|--help)      usage; exit 0 ;;
    -*)             echo "unknown flag: $1" >&2; exit 2 ;;
    *)              echo "unexpected arg: $1" >&2; exit 2 ;;
  esac
done

# -------------------- helpers --------------------
is_known_exception() {
  # Args: crop, gate. Bash 3.2-safe: guard empty-array iteration under set -u.
  local crop="$1" gate="$2" entry
  [ "${#KNOWN_EXCEPTIONS[@]}" -eq 0 ] && return 1
  for entry in "${KNOWN_EXCEPTIONS[@]}"; do
    case "$entry" in
      "$crop::$gate::"*) return 0 ;;
    esac
  done
  return 1
}

known_exception_reason() {
  local crop="$1" gate="$2" entry
  [ "${#KNOWN_EXCEPTIONS[@]}" -eq 0 ] && return 1
  for entry in "${KNOWN_EXCEPTIONS[@]}"; do
    case "$entry" in
      "$crop::$gate::"*)
        printf '%s' "${entry#"$crop::$gate::"}"
        return 0
        ;;
    esac
  done
  return 1
}

# Run a gate, return only "pass" or "fail" on stdout. Exit code is
# captured but the function itself always exits 0 so set -u doesn't
# cascade.
run_gate() {
  if "$@" >/dev/null 2>&1; then
    printf 'pass'
  else
    printf 'fail'
  fi
}

json_escape() {
  # Escape backslashes and double-quotes for JSON inclusion.
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# -------------------- discover crops --------------------
CROPS=()
for f in src/content/crops/*.mdx; do
  [ -f "$f" ] || continue
  base=$(basename "$f" .mdx)
  [ "$base" = "_template" ] && continue
  CROPS+=("$base")
done

if [ "${#CROPS[@]}" -eq 0 ]; then
  echo "no crops found in src/content/crops/" >&2
  exit 2
fi

# -------------------- gate list --------------------
GATES=("check-mdx-safety" "verify-source-table" "verify-claim-grounding")
[ "$WITH_URLS" -eq 1 ] && GATES+=("verify-urls")

AUDITED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# -------------------- per-crop iteration --------------------
# Parallel arrays for results: same index → same (crop, gate) pair.
R_CROPS=()
R_GATES=()
R_STATUS=()  # pass | fail | skipped | known_exception

for crop in "${CROPS[@]}"; do
  mdx="src/content/crops/$crop.mdx"
  sidecar="src/content/crops/$crop.reasoning.json"

  # check-mdx-safety
  s=$(run_gate ./scripts/check-mdx-safety.sh "$mdx")
  R_CROPS+=("$crop"); R_GATES+=("check-mdx-safety"); R_STATUS+=("$s")

  # verify-source-table
  s=$(run_gate ./scripts/verify-source-table.sh "$mdx")
  R_CROPS+=("$crop"); R_GATES+=("verify-source-table"); R_STATUS+=("$s")

  # verify-claim-grounding — only when sidecar exists
  if [ -f "$sidecar" ]; then
    s=$(run_gate ./scripts/verify-claim-grounding.sh --with-mdx "$mdx" "$sidecar")
  else
    s="skipped"
  fi
  # Known-exception conversion: if status is fail and (crop, gate) is known
  if [ "$s" = "fail" ] && is_known_exception "$crop" "verify-claim-grounding"; then
    s="known_exception"
  fi
  R_CROPS+=("$crop"); R_GATES+=("verify-claim-grounding"); R_STATUS+=("$s")

  # verify-urls (opt-in)
  if [ "$WITH_URLS" -eq 1 ]; then
    s=$(run_gate ./scripts/verify-urls.sh "$mdx")
    R_CROPS+=("$crop"); R_GATES+=("verify-urls"); R_STATUS+=("$s")
  fi
done

# -------------------- global build gate (opt-in, runs once) --------------------
BUILD_STATUS=""
if [ "$WITH_BUILD" -eq 1 ]; then
  BUILD_STATUS=$(run_gate ./scripts/verify-build.sh)
fi

# -------------------- aggregation --------------------
PASS_COUNT=0
FAIL_COUNT=0
EXCEPTION_COUNT=0
SKIPPED_COUNT=0

for s in "${R_STATUS[@]}"; do
  case "$s" in
    pass)             PASS_COUNT=$((PASS_COUNT+1)) ;;
    fail)             FAIL_COUNT=$((FAIL_COUNT+1)) ;;
    known_exception)  EXCEPTION_COUNT=$((EXCEPTION_COUNT+1)) ;;
    skipped)          SKIPPED_COUNT=$((SKIPPED_COUNT+1)) ;;
  esac
done

# Exit code reflects new (unknown) failures only.
if [ "$BUILD_STATUS" = "fail" ]; then
  FAIL_COUNT=$((FAIL_COUNT+1))
fi

OVERALL="pass"
[ "$FAIL_COUNT" -gt 0 ] && OVERALL="fail"

# -------------------- output --------------------
if [ "$JSON_OUT" -eq 1 ]; then
  # JSON output
  printf '{\n'
  printf '  "audit_version": "v1",\n'
  printf '  "audited_at": "%s",\n' "$AUDITED_AT"
  printf '  "crops_audited": %d,\n' "${#CROPS[@]}"
  printf '  "gates_run": ['
  sep=""
  for g in "${GATES[@]}"; do printf '%s"%s"' "$sep" "$g"; sep=","; done
  printf '],\n'
  printf '  "with_build": %s,\n' "$([ "$WITH_BUILD" -eq 1 ] && echo true || echo false)"
  printf '  "with_urls":  %s,\n' "$([ "$WITH_URLS" -eq 1 ] && echo true || echo false)"
  printf '  "build_status": "%s",\n' "$BUILD_STATUS"
  printf '  "results": [\n'
  N=${#R_CROPS[@]}
  for i in $(seq 0 $((N-1))); do
    last_comma=","
    [ "$i" -eq $((N-1)) ] && last_comma=""
    printf '    {"crop": "%s", "gate": "%s", "status": "%s"}%s\n' \
      "${R_CROPS[$i]}" "${R_GATES[$i]}" "${R_STATUS[$i]}" "$last_comma"
  done
  printf '  ],\n'
  printf '  "summary": {\n'
  printf '    "pass": %d,\n' "$PASS_COUNT"
  printf '    "fail": %d,\n' "$FAIL_COUNT"
  printf '    "known_exceptions": %d,\n' "$EXCEPTION_COUNT"
  printf '    "skipped": %d\n' "$SKIPPED_COUNT"
  printf '  },\n'
  printf '  "known_exceptions": [\n'
  EN=${#KNOWN_EXCEPTIONS[@]}
  for i in $(seq 0 $((EN-1))); do
    [ "$EN" -eq 0 ] && break
    entry="${KNOWN_EXCEPTIONS[$i]}"
    crop="${entry%%::*}"
    rest="${entry#*::}"
    gate="${rest%%::*}"
    reason="${rest#*::}"
    last_comma=","
    [ "$i" -eq $((EN-1)) ] && last_comma=""
    printf '    {"crop": "%s", "gate": "%s", "reason": "%s"}%s\n' \
      "$crop" "$gate" "$(json_escape "$reason")" "$last_comma"
  done
  printf '  ],\n'
  printf '  "verification_status": "%s"\n' "$OVERALL"
  printf '}\n'
else
  # Human-readable output
  echo ""
  echo "Kaset Atlas Crop Audit ($AUDITED_AT)"
  echo "-----------------------------------------------------------"
  printf 'Gates run:'
  for g in "${GATES[@]}"; do printf ' %s' "$g"; done
  [ "$WITH_BUILD" -eq 1 ] && printf ' verify-build(global)'
  echo ""
  echo ""
  echo "Per-crop results:"
  for crop in "${CROPS[@]}"; do
    crop_pass=0; crop_fail=0; crop_exc=0; crop_skip=0
    crop_notes=""
    N=${#R_CROPS[@]}
    for i in $(seq 0 $((N-1))); do
      [ "${R_CROPS[$i]}" = "$crop" ] || continue
      case "${R_STATUS[$i]}" in
        pass)            crop_pass=$((crop_pass+1)) ;;
        fail)            crop_fail=$((crop_fail+1)); crop_notes="$crop_notes ${R_GATES[$i]}=fail" ;;
        known_exception) crop_exc=$((crop_exc+1));   crop_notes="$crop_notes ${R_GATES[$i]}=known_exception" ;;
        skipped)         crop_skip=$((crop_skip+1)); crop_notes="$crop_notes ${R_GATES[$i]}=skipped" ;;
      esac
    done
    total_gates=$((crop_pass+crop_fail+crop_exc+crop_skip))
    if [ "$crop_fail" -gt 0 ]; then
      icon="✗"; label="FAIL"
    elif [ "$crop_exc" -gt 0 ]; then
      icon="⚠"; label="pass-with-known-exception"
    else
      icon="✓"; label="pass"
    fi
    printf '  %s %-20s %s [%d/%d gates]%s\n' \
      "$icon" "$crop" "$label" "$crop_pass" "$total_gates" "${crop_notes:+ —$crop_notes}"
  done
  echo ""

  echo "Per-gate pass rate:"
  for g in "${GATES[@]}"; do
    p=0; f=0; e=0; s=0; total=0
    N=${#R_CROPS[@]}
    for i in $(seq 0 $((N-1))); do
      [ "${R_GATES[$i]}" = "$g" ] || continue
      total=$((total+1))
      case "${R_STATUS[$i]}" in
        pass)            p=$((p+1)) ;;
        fail)            f=$((f+1)) ;;
        known_exception) e=$((e+1)) ;;
        skipped)         s=$((s+1)) ;;
      esac
    done
    pct="n/a"
    [ "$total" -gt 0 ] && pct="$((p*100/total))%"
    line="  $g: $p/$total ($pct)"
    [ "$f" -gt 0 ] && line="$line — $f new fails"
    [ "$e" -gt 0 ] && line="$line — $e known exceptions"
    [ "$s" -gt 0 ] && line="$line — $s skipped"
    echo "$line"
  done
  if [ "$WITH_BUILD" -eq 1 ]; then
    echo "  verify-build (global): $BUILD_STATUS"
  fi
  echo ""

  echo "Summary:"
  echo "  Total crops audited:    ${#CROPS[@]}"
  echo "  Result rows pass:       $PASS_COUNT"
  echo "  Result rows fail (new): $FAIL_COUNT"
  echo "  Result rows known-exc:  $EXCEPTION_COUNT"
  echo "  Result rows skipped:    $SKIPPED_COUNT"
  echo "  Audit status:           $(echo "$OVERALL" | tr '[:lower:]' '[:upper:]')"
  echo ""

  if [ "${#KNOWN_EXCEPTIONS[@]}" -gt 0 ]; then
    echo "Known exceptions (acknowledged historical issues, not silently normalized):"
    for entry in "${KNOWN_EXCEPTIONS[@]}"; do
      crop="${entry%%::*}"
      rest="${entry#*::}"
      gate="${rest%%::*}"
      reason="${rest#*::}"
      echo "  ⚠ $crop / $gate"
      printf '      %s\n' "$reason" | fold -s -w 70 | sed '2,$s/^/      /'
    done
  else
    echo "(No known exceptions registered.)"
  fi
fi

[ "$OVERALL" = "pass" ] && exit 0 || exit 1
