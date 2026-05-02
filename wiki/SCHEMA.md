# Wiki Schema (v1)

> Phase 8, 2026-05-02. Markdown + YAML frontmatter. No build-time validation today; `scripts/verify-wiki.sh` is the read-only checker.

---

## 1. File-naming rules

- Source card path: `wiki/sources/<topic-or-crop-slug>/<source-id>.md`
- Topic page path: `wiki/topics/<topic-slug>.md`
- `source-id` and `topic-slug` are kebab-case, ASCII, max 80 chars.
- `source-id` must be **globally unique** across the entire wiki (the verifier enforces this).

---

## 2. Source card frontmatter

```yaml
---
id: doa-hort-mango-db                 # required, unique, kebab-case
title: "DB มะม่วง — สถาบันวิจัยพืชสวน กรมวิชาการเกษตร"  # required
publisher: "Department of Agriculture (Thailand) — Horticultural Research Institute"  # required
url: "https://www.doa.go.th/hort/?page_id=52837"  # required, http(s)
url_status: ok                         # required: ok | redirect | dead | unknown
url_status_code: 200                   # required when known; null otherwise
url_checked_at: 2026-04-30T00:00:00Z   # required ISO-8601 UTC
type: gov-th                           # required: see §2.1
language: th                           # required: bcp-47 (th, en, en-US, ja, ...)
access: open                           # required: open | paywalled | login-required
year: 2025                             # optional integer; null if undated
license_class: gov-public              # required: see §2.2
accessed_at: 2026-04-30                # required date the card was authored
topics: [mango]                        # required, ≥1 entry, kebab-case
crops: [mango]                         # optional, ≥0 crop slugs
confidence_default: high               # required: high | medium | low | uncertain
---
```

### 2.1 `type` enum

- `gov-th`     — Thai government primary (DOA, DOAE, RID, OPSMOAC, MOAC, ARDA)
- `uni-th`     — Thai university extension or research (KU, CMU, MJU, Mahidol)
- `gov-int`    — Foreign government primary (USDA, MAFF JP, etc.)
- `uni-int`    — Foreign university extension (UF/IFAS, CTAHR, Purdue, UC ANR, ...)
- `fao`        — FAO and other UN-system bodies
- `ngo`        — Non-government organizations (CABI, IRRI, CGIAR centers)
- `journal`    — Peer-reviewed journal article
- `encyclopedia` — Encyclopedic reference (Wikipedia and similar)
- `other`      — Industry, blog, news; lowest tier; explicit justification required

### 2.2 `license_class` enum

- `cc`            — Creative Commons or compatible open license
- `gov-public`    — Government work in the public domain (Thai government documents are typically gov-public under PR Act §7)
- `copyrighted`   — All rights reserved; quote rules apply (≤15 words per SOURCE_POLICY)
- `unknown`       — Treat as `copyrighted` for safety until clarified

### 2.3 Body

After the frontmatter close (`---`) the body holds:

- A 1–2 sentence Thai summary (`สรุปไทย`)
- A 1–2 sentence English summary (`English summary`)
- Optional bullet list of the source's strongest, citable facts. **Direct quotes are limited to 15 words each per SOURCE_POLICY.**

No long translations. No reproductions of figures. No images.

---

## 3. Topic page frontmatter

```yaml
---
id: mango                              # required, kebab-case, matches filename
title_th: "มะม่วง"                       # required
title_en: "Mango"                      # required
scope_in:                              # required, ≥1 entry, what this page covers
  - "Cultivation of Mangifera indica in Thailand"
  - "Mahachanok and Nam Dok Mai cultivar facts"
scope_out:                             # required, ≥0 entries, what is excluded
  - "Mango pulp processing economics"
  - "Detailed pesticide dosing"
last_updated: 2026-05-02               # required date
last_audited: 2026-05-02               # required date (verifier last-pass date)
related_topics: []                     # optional, slugs of sibling topic pages
---
```

---

## 4. Claim card schema (inside topic page body)

The body of a topic page is a YAML list of claim cards under a single `claims:` key, or — equivalently and preferred for diff readability — an H2 section per claim. The verifier accepts either form. The canonical form is YAML for machine parsing:

```yaml
claims:
  - claim_id: mango-thailand-applicability     # required, unique within file, kebab-case
    section_ref: "1_thailand_applicability"    # optional, links to crop MDX section ID
    statement_th: "มะม่วงปลูกได้ทั่วทุกภาคของไทย ยกเว้นภาคใต้ที่ฝนชุกขาดฤดูแล้ง"
    statement_en: "Mango can be grown across most of Thailand, except the rainfall-heavy South where the dry-flowering window is unreliable."
    supporting_source_ids:                      # required, ≥1 entry
      - doa-hort-mango-db
      - doae-mango-export-3-2565
      - aujt-thai-mango-export
    confidence: high                            # required: see §5
    thailand_applicability: native              # required: native | foreign-direct | foreign-with-caveats
    last_verified: 2026-05-02                   # required date
    notes: ""                                   # optional, ≤200 chars
```

### 4.1 `thailand_applicability` enum

- `native`              — claim sourced from Thai primary or describes Thai conditions directly
- `foreign-direct`      — foreign source, but claim is a universal agronomic principle that maps cleanly
- `foreign-with-caveats`— foreign source, but climate/cultivar/regulatory caveats apply (must be in `notes`)

---

## 5. Confidence rules (machine-checkable)

These rules are enforced by `scripts/verify-wiki.sh`. The verifier may **warn** but does not fail the build for warnings; it **fails** for errors.

| Confidence | Required evidence | Verifier behavior |
|---|---|---|
| `high` | ≥2 independent supporting sources, OR exactly 1 source if its `type` is `gov-th` and `confidence_default` ≥ high | error if violated |
| `medium` | ≥1 supporting source with at least one corroborating mention (the corroborating card may be `confidence_default: medium` or higher) | warn if single isolated source |
| `low` | ≥1 supporting source | accepted as-is |
| `uncertain` | ≥1 supporting source AND `notes` is non-empty | error if `notes` empty |

"Independent" = the two source cards must have **different `publisher` values**. Two DOA documents from the same publisher count as one for high-confidence.

---

## 6. Verification gates (what `verify-wiki.sh` checks)

1. Source-card frontmatter contains all required keys with correct types.
2. Source-card `id` is unique across the entire wiki.
3. Source-card `url` is HTTP(S), and `url_status` is one of {ok, redirect, dead, unknown}.
4. Source-card `type` and `license_class` are within the enums above.
5. Topic-page frontmatter contains all required keys.
6. Every `supporting_source_ids` entry resolves to an existing source card.
7. Confidence rules in §5 are satisfied.
8. No orphan source cards (every source card is referenced by at least one claim card OR by a crop MDX file in `src/content/crops/`).
9. URL liveness is **not** re-checked by `verify-wiki.sh` v1 — it relies on `url_checked_at` being recent (≤90 days) and warns if older. URL liveness is the job of `scripts/verify-urls.sh`.

---

## 7. Style conventions

- Thai quotation marks `"…"` for Thai text; ASCII straight quotes `"…"` for English.
- ISO-8601 dates everywhere (`YYYY-MM-DD` for date-only, `YYYY-MM-DDTHH:MM:SSZ` for timestamps).
- No trailing whitespace.
- One blank line between frontmatter and body.

---

## 8. What's deliberately not in v1

- Provenance graph (which claim cites which other claim). Defer to v2.
- Versioning of source content (cards are append-only; URL drift is handled by re-verifying and updating `url_checked_at`).
- Translation memory / paraphrase fingerprints. Defer to v2.
- Schema validation via JSON Schema or similar. v1 uses bash + sed in `verify-wiki.sh`. v2 may move to a TypeScript validator if and when complexity demands it.

---

## 9. Schema version

`v1` (Phase 8, 2026-05-02). Bumping the schema requires:

1. Update this file.
2. Update `scripts/verify-wiki.sh` accordingly.
3. Add a migration note in `docs/AUDIT_LOG.md`.
4. Run the verifier across every existing card and topic.
