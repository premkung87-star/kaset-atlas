#!/bin/bash
# ============================================================
# Kaset Atlas — Claim-Grounding Verifier (v1: schema-only)
# ============================================================
#
# Purpose
#   Deterministic structural check on a crop's reasoning sidecar
#   (`<slug>.reasoning.json`). Validates the contract that section
#   confidence claims are tied to supporting sources, with rationales
#   long enough to be substantive. Companion to verify-source-table.sh
#   (which validates the MDX source table) and the future
#   verify-claim-grounding.sh v2 (which will validate that every cited
#   claim has a verbatim evidence quote present in the source body).
#
# Why v1 only today
#   Current sidecar schema (verified 2026-04-30 across sweet-basil,
#   holy-basil, cassava, mango) does NOT carry per-claim
#   `evidence_quote` or `source_url` fields. The closest signal is
#   `section_confidence[<key>].supporting_source_ids` (or the legacy
#   `supporting_source_types` for sweet-basil). So v1 validates the
#   contract that EXISTS today and clearly reports the v2 schema gap
#   in the coverage_assessment block.
#
# Schema accepted (v1)
#   {
#     "crop_slug": "<slug>",
#     "section_confidence": {
#       "<N>_<topic>": {
#         "rating": "high|medium|low|uncertain",
#         "rationale": "<≥25 chars>",
#         "supporting_source_ids":   [...non-empty...]    // current
#         "supporting_source_types": [...non-empty...]    // legacy (sweet-basil)
#       },
#       ... (≥11 entries)
#     },
#     "overall_confidence": "high|medium|low",
#     "overall_rationale": "<≥25 chars>"
#   }
#
# Future schema (v2 — flagged in coverage_assessment but NOT enforced today)
#   Each section gains a `claims` array, each claim with
#   `{text, source_id, source_url, evidence_quote}`. When v2 schema
#   appears in a sidecar, this script will exercise stricter checks.
#   Drafter prompt change to emit v2 schema is OUT OF SCOPE for this
#   script — that's a Day 3+ ask requiring maintainer approval.
#
# Network: NONE. The script does not fetch any URL. Content fidelity
# (quote-in-source-body) is deferred to a separate cached-fetch
# implementation; this script only validates what is already on disk.
#
# Usage
#   scripts/verify-claim-grounding.sh \
#       [--with-mdx <path-to-mdx>] \
#       [--min-rationale <int>] \
#       <path-to-reasoning.json>
#
# Flags
#   --with-mdx <path>     Optional. Cross-checks that the MDX source
#                         table has at least as many unique URLs as
#                         the sidecar references unique source IDs.
#   --min-rationale <N>   Minimum rationale length (default: 25)
#   -h|--help             Print this header
#
# Exits
#   0  all checks passed
#   1  contract violation found
#   2  argument or file error
#
# Output: JSON report on stdout. No log file written.

set -uo pipefail

SIDECAR=""
MDX=""
MIN_RATIONALE=25

usage() {
  sed -n '2,55p' "$0" >&2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --with-mdx)        MDX="$2"; shift 2 ;;
    --min-rationale)   MIN_RATIONALE="$2"; shift 2 ;;
    -h|--help)         usage; exit 0 ;;
    -*)                echo "{\"status\":\"error\",\"message\":\"unknown flag: $1\"}"; exit 2 ;;
    *)                 SIDECAR="$1"; shift ;;
  esac
done

if [ -z "$SIDECAR" ]; then
  echo '{"status":"error","message":"path to reasoning.json required"}'
  exit 2
fi
if [ ! -f "$SIDECAR" ]; then
  echo "{\"status\":\"error\",\"message\":\"sidecar not found: $SIDECAR\"}"
  exit 2
fi
if [ -n "$MDX" ] && [ ! -f "$MDX" ]; then
  echo "{\"status\":\"error\",\"message\":\"mdx not found: $MDX\"}"
  exit 2
fi

# Hand off to python3 — JSON parsing in pure bash is fragile, and python3
# is already used elsewhere in the project (content-verifier prompt's
# Step 0 preamble uses python3 for Thai char counting).
python3 - "$SIDECAR" "${MDX:-}" "$MIN_RATIONALE" <<'PYEOF'
import json
import os
import re
import sys

sidecar_path = sys.argv[1]
mdx_path = sys.argv[2] if len(sys.argv) > 2 else ""
min_rationale = int(sys.argv[3]) if len(sys.argv) > 3 else 25

issues = []
warnings = []

# --- Load and parse sidecar ---
try:
    with open(sidecar_path, encoding="utf-8") as f:
        data = json.load(f)
except json.JSONDecodeError as e:
    print(json.dumps({
        "sidecar": sidecar_path,
        "verifier_version": "v1-claim-grounding",
        "verification_status": "fail",
        "issues": [f"json_parse_error: line {e.lineno} col {e.colno}: {e.msg}"],
    }, indent=2, ensure_ascii=False))
    sys.exit(1)

# --- Top-level required fields ---
REQUIRED_TOP = ["crop_slug", "section_confidence", "overall_confidence", "overall_rationale"]
for k in REQUIRED_TOP:
    if k not in data:
        issues.append(f"missing_top_level_field({k})")

# Filename ↔ crop_slug consistency
expected_slug = os.path.basename(sidecar_path).replace(".reasoning.json", "")
if data.get("crop_slug") and data["crop_slug"] != expected_slug:
    issues.append(
        f"crop_slug_mismatch(filename={expected_slug},field={data['crop_slug']})"
    )

# overall_confidence sanity
ALLOWED_OVERALL = {"high", "medium", "low"}
if data.get("overall_confidence") not in ALLOWED_OVERALL:
    issues.append(f"invalid_overall_confidence({data.get('overall_confidence')})")

overall_rationale = data.get("overall_rationale", "") or ""
if len(overall_rationale.strip()) < min_rationale:
    issues.append(
        f"overall_rationale_too_short(len={len(overall_rationale.strip())},min={min_rationale})"
    )

# --- section_confidence iteration ---
sc = data.get("section_confidence", {})
if not isinstance(sc, dict):
    issues.append("section_confidence_not_object")
    sc = {}

if len(sc) < 11:
    issues.append(f"section_count_below_minimum(got={len(sc)},min=11)")

ALLOWED_RATINGS = {"high", "medium", "low", "uncertain"}

ids_sections = 0
types_sections = 0
claims_sections = 0
evidence_quote_count = 0
unique_source_ids = set()

for skey in sorted(sc.keys()):
    sval = sc[skey]
    if not isinstance(sval, dict):
        issues.append(f"section_not_object(key={skey})")
        continue

    rating = sval.get("rating")
    if rating not in ALLOWED_RATINGS:
        issues.append(f"invalid_rating(section={skey},rating={rating})")

    rationale = sval.get("rationale", "") or ""
    if len(rationale.strip()) < min_rationale:
        issues.append(
            f"rationale_too_short(section={skey},len={len(rationale.strip())},min={min_rationale})"
        )

    ids = sval.get("supporting_source_ids")
    types_ = sval.get("supporting_source_types")
    has_ids = isinstance(ids, list) and len(ids) > 0
    has_types = isinstance(types_, list) and len(types_) > 0

    if not has_ids and not has_types:
        issues.append(f"no_supporting_sources(section={skey})")
    elif has_ids:
        ids_sections += 1
        # Per content-verifier Step 11: high → ≥2 supporting source IDs
        if rating == "high" and len(ids) < 2:
            issues.append(
                f"high_confidence_with_single_source(section={skey},sources={ids})"
            )
        # Within-section duplicates
        if len(set(ids)) < len(ids):
            issues.append(f"duplicate_source_ids_in_section(section={skey})")
        # Each ID must be a non-empty string
        for sid in ids:
            if not isinstance(sid, str) or not sid.strip():
                issues.append(f"empty_or_non_string_source_id(section={skey})")
        unique_source_ids.update(s for s in ids if isinstance(s, str))
    else:
        # has_types only (legacy schema, e.g. sweet-basil)
        types_sections += 1

    # v2 schema detection (descriptive, not enforced today)
    if "claims" in sval:
        claims_sections += 1
        claims = sval.get("claims", [])
        if isinstance(claims, list):
            for cl in claims:
                if isinstance(cl, dict):
                    eq = cl.get("evidence_quote", "")
                    if isinstance(eq, str) and eq.strip():
                        evidence_quote_count += 1

# --- v2 schema mode determination ---
if claims_sections == 0:
    schema_mode = "v1-structural"
    coverage_gap = (
        "No section has a `claims` array yet. Per-claim evidence_quote "
        "grounding is not enforceable today. v2 schema migration would "
        "add `claims: [{text, source_id, source_url, evidence_quote}]` "
        "per section, enabling deterministic quote-in-source-body checks."
    )
elif claims_sections < len(sc):
    schema_mode = "v2-partial"
    issues.append(
        f"partial_v2_migration(claims_sections={claims_sections},total={len(sc)})"
    )
    coverage_gap = (
        "Partial v2 migration: some sections have a `claims` array, others "
        "do not. This is contract drift — v2 must be all-or-nothing."
    )
else:
    schema_mode = "v2-full"
    if evidence_quote_count == 0:
        issues.append("v2_schema_present_but_zero_evidence_quotes")
        coverage_gap = "v2 schema is present but no evidence_quote values exist."
    else:
        coverage_gap = ""

# Legacy-schema warning
if types_sections > 0:
    warnings.append(
        f"legacy_schema_supporting_source_types(sections={types_sections})"
    )

# --- Optional MDX cross-check (coarse: count comparison only) ---
mdx_check = None
if mdx_path:
    with open(mdx_path, encoding="utf-8") as f:
        mdx_content = f.read()
    urls = re.findall(r"https?://[^\s\"<>)]+", mdx_content)
    unique_urls = set(urls)
    mdx_check = {
        "mdx_unique_urls": len(unique_urls),
        "sidecar_unique_source_ids": len(unique_source_ids),
    }
    # The sidecar should not reference more unique IDs than the MDX has URLs.
    # No URL↔ID join is possible until v2 schema lands; this is a coarse
    # capacity check only.
    if len(unique_source_ids) > len(unique_urls):
        issues.append(
            f"sidecar_references_more_sources_than_mdx_lists("
            f"sidecar_unique_ids={len(unique_source_ids)},"
            f"mdx_unique_urls={len(unique_urls)})"
        )

# --- Report ---
status = "pass" if not issues else "fail"
report = {
    "sidecar": sidecar_path,
    "verifier_version": "v1-claim-grounding",
    "schema_mode": schema_mode,
    "coverage_assessment": {
        "total_sections": len(sc),
        "sections_with_supporting_source_ids": ids_sections,
        "sections_with_supporting_source_types_legacy": types_sections,
        "sections_with_claims_array": claims_sections,
        "evidence_quotes_present": evidence_quote_count,
        "unique_source_ids_referenced": len(unique_source_ids),
        "coverage_gap": coverage_gap,
    },
    "mdx_cross_check": mdx_check,
    "issues_found": len(issues),
    "issues": issues,
    "warnings_found": len(warnings),
    "warnings": warnings,
    "verification_status": status,
}

print(json.dumps(report, indent=2, ensure_ascii=False))
sys.exit(0 if status == "pass" else 1)
PYEOF
exit $?
