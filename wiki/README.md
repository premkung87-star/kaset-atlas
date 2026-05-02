# Kaset Atlas Wiki — Source-Verified Knowledge Layer

> Status: **Foundation v1** (Phase 8, 2026-05-02). Schema-only + one backfilled sample (mango). Not wired into the runtime crop pipeline yet.

The wiki is the **knowledge layer** that sits underneath `src/content/crops/`. It stores source cards and topic pages with claim-level citations, separate from the rendered Astro site. The site is the warm surface; the wiki is the cold storage.

---

## What lives here

```
wiki/
├── README.md           — this file
├── SCHEMA.md           — source card + topic page + claim card schemas
├── _template/
│   ├── source.md       — copy this when adding a new source card
│   └── topic.md        — copy this when adding a new topic page
├── sources/
│   └── <topic-or-crop>/
│       └── <source-id>.md
└── topics/
    └── <topic-slug>.md
```

- **Source cards** = one Markdown file per real-world reference (a DOA paper, a CTAHR extension page, a FAO compendium chapter). Each card has a stable `id`, the canonical URL, last URL-check status, license class, and a short bilingual summary.
- **Topic pages** = one Markdown file per agricultural topic (a crop, a practice, a pest, a soil family). Each page contains an ordered list of **claim cards**: a single agricultural statement with `supporting_source_ids`, a `confidence` rating, and a Thailand-applicability note.

Source IDs are referenced by `id`. A claim cites sources by `id`, not by URL.

---

## Why a separate wiki layer

1. **Source reuse.** The same DOA mango database is cited by mango, by mango-export, and (eventually) by Anacardiaceae family pages. One canonical card, many citations.
2. **Claim-level traceability.** Every claim in the wiki points to ≥1 source card. Reviewers can audit a single claim without reading the whole crop profile.
3. **Verification independence.** Source URLs can be re-verified, retired, or migrated without touching the rendered MDX.
4. **AI-citability.** Stable `id`s plus structured frontmatter make the wiki a good substrate for future RAG retrieval. V1 is static markdown — no infra.
5. **Cross-language summaries.** Each card carries Thai + English summaries so foreign sources can be located by Thai readers and Thai sources can be referenced by international agents.

---

## Relationship to `/add-crop`

| Layer | Today (Phase 8 V1) | Future (Phase 9+) |
|---|---|---|
| `src/content/crops/<slug>.mdx` | Rendered crop profile, owns the source table | Crop MDX cites claim IDs from `wiki/topics/<slug>.md`, the source table becomes a render of cited cards |
| `src/content/crops/<slug>.reasoning.json` | Per-section confidence + supporting source IDs | Migrates into the wiki topic page as claim cards |
| `wiki/sources/` | Backfilled for mango only; manually authored | Populated by Researcher; reused across crops |
| `wiki/topics/` | Backfilled for mango only | Populated by Drafter alongside the MDX |
| `scripts/verify-wiki.sh` | Stand-alone validator | Wired into `/add-crop` after wiki source-of-truth migration |

**The runtime crop pipeline is unchanged in Phase 8.** No agent prompt, no slash command, no verifier script that `/add-crop` depends on has been modified.

---

## How a source card is built

1. Find a real, reachable source (HTTP 200 with browser User-Agent).
2. Copy `wiki/_template/source.md` to `wiki/sources/<topic>/<id>.md`.
3. Fill the frontmatter (see `SCHEMA.md` §2).
4. Write a 1–2 sentence Thai summary, then a 1–2 sentence English summary in the body. **Do not translate full passages** — Source Policy quote-length rules apply (see `docs/SOURCE_POLICY.md`).
5. Run `scripts/verify-wiki.sh` and confirm `verification_status: pass`.

## How a topic page is built

1. Identify the topic (a crop slug, a practice, a pest).
2. Copy `wiki/_template/topic.md` to `wiki/topics/<slug>.md`.
3. List claim cards (`SCHEMA.md` §3). Every claim must reference ≥1 `supporting_source_id` that already exists under `wiki/sources/`.
4. Confidence rules are codified — see `SCHEMA.md` §5.
5. Run `scripts/verify-wiki.sh`.

---

## Out of scope (V1)

- No build-time rendering of wiki pages onto kasetatlas.com.
- No automatic ingestion from existing `src/content/crops/*.reasoning.json`.
- No vector index, no RAG runtime, no chatbot, no DB.
- No Drafter changes — the Drafter still writes the MDX source table directly.

---

## Last updated

2026-05-02 — Phase 8 foundation. See `docs/AUDIT_LOG.md` for the full entry.
