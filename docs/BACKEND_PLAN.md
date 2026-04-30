# Kaset Atlas — Backend Development Plan

> **Internal planning document.** Phased roadmap for the backend, from current state through long-term ambitions. Read alongside `CLAUDE.md`, `docs/METHODOLOGY.md`, `docs/AUTOMATION_PIPELINE.md`.

> **Last updated:** 2026-04-30
> **Operating principle:** **Static-first.** Every backend addition must justify its existence by a real user need, not speculative architecture.

---

## 0. What "backend" actually means for Kaset Atlas

Kaset Atlas is intentionally a static site. The hosting layer (Vercel edge) needs no backend. **The backend that already exists is the multi-agent content production pipeline** — Researcher, Drafter, URL Verifier, Build Verifier, Content Verifier, Decision Agent. That is 90% of the engineering complexity and is already running.

This document covers two backends:

- **Production Backend** — the static site + delivery infrastructure (Vercel, Cloudflare DNS, GH Actions). Mostly complete, ongoing hardening.
- **Content Production Backend** — the AI pipeline. Already operational, ongoing iteration.
- **Future Backend** — eventual database / RAG layer to power "Ask the Atlas" Q&A. **Earned by content depth, not chosen ahead of time.**

---

## 1. Current State (Phase 0 — shipped 2026-04-29 → 2026-04-30)

### 1.1 Production Backend — operational

| Component | State | Notes |
|---|---|---|
| Static hosting | ✅ Vercel Pro (paid) | Edge-rendered, anycast IP, auto-SSL |
| Custom domain | ✅ kasetatlas.com via Cloudflare Registrar | DNS-only mode (gray cloud), Let's Encrypt SSL valid Jul 28 2026 |
| Build pipeline | ✅ Astro + Tailwind + MDX + Pagefind | 17 pages, 3 crops live |
| CI | ✅ GitHub Actions: build verify on push + weekly link-check | `.github/workflows/build.yml` + `link-check.yml` |
| Content delivery | ✅ Vercel anycast edge | Global p50 < 100ms |
| AI-citable infra | ✅ JSON-LD on every page, robots.txt, llms.txt, sitemap-index.xml | All AI crawlers explicitly allowed |
| Brand assets | ⏳ pending | Awaiting Claude Design output (see DESIGN_BRIEF.md) |

### 1.2 Content Production Backend — operational

| Component | State | Notes |
|---|---|---|
| Researcher agent | ✅ `.claude/agents/researcher.md` | Finds Thai-gov + international sources, ranks by confidence |
| Drafter agent | ✅ `.claude/agents/drafter.md` | Hardened with MDX safety + citation discipline + reasoning sidecar |
| URL Verifier | ✅ `scripts/verify-urls.sh` v3.1 | HTTP status + soft-200 body inspection (catches Thai error pages) |
| Build Verifier | ✅ `scripts/verify-build.sh` | Catches MDX runtime errors before commit |
| MDX Safety check | ✅ `scripts/check-mdx-safety.sh` | Catches `<digit` / `>digit` patterns that break MDX parser |
| Content Verifier | ✅ `.claude/agents/content-verifier.md` (hardened 2026-04-30) | Evidence-discipline rules + self-consistency check + verbatim quote requirement |
| Decision Agent | ✅ `.claude/agents/decision.md` (delegated to slash command) | Auto-commit + push if all gates pass |
| Verifier stats log | ✅ `.claude/logs/verifier-stats.json` | NDJSON drift signal log |
| Pipeline failure log | ✅ `docs/PIPELINE_FAILURES.md` | Most recent first |
| Audit log | ✅ `docs/AUDIT_LOG.md` | Architectural decisions + content additions |

### 1.3 What's NOT yet wired (Phase 0 polish backlog)

| Item | Cost | Effort | Priority |
|---|---|---|---|
| Pagefind search UI | $0 (FOSS) | ~30 min | high (after design) |
| Vercel Analytics | $0 (Pro tier) | 5 min | medium |
| Vercel Speed Insights | $0 (Pro tier) | 5 min | medium |
| `@astrojs/rss` feed | $0 | ~15 min | low |
| Apex-as-primary domain flip | $0 | 2 clicks | low (polish) |
| Pagefind multilingual tuning | $0 | ~1 hr | wait until 10+ crops |

---

## 2. Phase 1 — Polish + Observability (target: ~10 crops live)

**Trigger:** When 10 crops are live OR within 2 weeks, whichever first.
**Goal:** Site feels production-grade, observable, indexed by search engines.

### 2.1 Tasks

| Task | Owner | Status |
|---|---|---|
| Wire Pagefind search UI per design system | dev | ⏳ blocked on DESIGN_BRIEF.md output |
| Enable Vercel Analytics + Speed Insights | dev | ⏳ |
| Add `@astrojs/rss` feed at `/rss.xml` | dev | ⏳ |
| Submit sitemap to Google Search Console | maintainer | ⏳ |
| Submit sitemap to Bing Webmaster Tools | maintainer | ⏳ |
| Apply final design system from Claude Design output | dev | ⏳ blocked on design |
| Replace v0 logo with final logo set | dev | ⏳ blocked on design |
| Update Open Graph default image | dev | ⏳ blocked on design |
| Verify all 12 crop sections render correctly with new design | dev | ⏳ |

### 2.2 Risk classification per CLAUDE.md §6

- 🟡 Design system rollout — visual change, reversible
- 🟢 Pagefind, RSS, Analytics — additive, free, low-risk
- 🟢 Search Console submissions — external service, no code change

### 2.3 Cost projection
$0 marginal. Everything is in the existing paid stack (Vercel Pro covers Analytics + Speed Insights; Pagefind is FOSS; @astrojs/rss is FOSS).

---

## 3. Phase 2 — Content Pipeline Hardening (target: ~30 crops live)

**Trigger:** When 30 crops are live OR Verifier stats show pattern drift.
**Goal:** The content pipeline becomes self-improving and statistically tunable.

### 3.1 Verifier evolution

| Task | Why | Effort |
|---|---|---|
| Add Drafter "evidence preamble" requirement | Mirror what Content Verifier now requires (post-2026-04-30 hallucination incident) | medium |
| Build verifier-stats analyzer | Read `verifier-stats.json` (will have 30+ entries by then), surface trends: rising blocker rate, falling URL pass rate, common failure modes | medium |
| Auto-promote Pattern Wins to drafter prompt | After 5+ instances of same fix in WORKFLOW_KIT.md §4, candidate for permanent drafter rule | high (judgment) |
| Auto-deprecate Discarded patterns | After 5+ instances in WORKFLOW_KIT.md §5, candidate for permanent forbidden-list entry | medium |
| Researcher source-quality scoring | Currently boolean (high/medium/low). Move to numerical score derived from: type (gov/uni/peer-reviewed/industry/blog) + recency + Thai-relevance | medium |

### 3.2 Source database (V2 candidate, not Phase 2 commit)

By 30 crops, the project will have ~300+ unique cited URLs. Question: do we need a source-database table to dedupe, track URL health over time, and detect link rot?

**Decision deferred to Phase 3.** Currently each crop's source list lives in its MDX. The weekly link-check workflow catches rot. Adding a source DB now is premature.

### 3.3 Risk classification
- 🔴 Drafter prompt evolution — agent prompt change, requires explicit maintainer approval
- 🟡 Verifier-stats analyzer — new tooling, no production risk
- 🟢 Documentation updates

---

## 4. Phase 3 — Database Layer (target: ~50 crops live)

**Trigger:** When the V1 launch milestone (9 crops, one per category except mushrooms) is complete AND the corpus reaches ~50 crops.
**Goal:** Add a database backend ONLY where it serves a user need that static can't satisfy.

### 4.1 What gets added — and what doesn't

| Add | Don't Add |
|---|---|
| Supabase Pro project (already paid) | User accounts / auth |
| `crops` table (mirror of MDX content) | Comments / community features |
| `sources` table (deduplicated) | Login / signup flows |
| `verifications` table (verifier-stats history) | Donation / payment flows |
| `pgvector` extension on Supabase | Live editing UI |

### 4.2 Why a database now — concrete user needs

By ~50 crops the corpus has enough density that **lexical search (Pagefind) starts to underperform**. Specifically:

- Users ask "what are pest-resistant rice varieties for Northeast Thailand?" — this is a multi-attribute query that Pagefind doesn't handle well
- AI crawlers want to fetch a structured JSON catalog (not just sitemap) for batch ingestion
- Maintainer wants to spot patterns: which crops have the most low-confidence sections? which sources are most cited? which sections fail verification most often?

A database enables all three.

### 4.3 Schema sketch

```sql
-- crops (one row per MDX file, hydrated at build time)
crops (
  slug TEXT PRIMARY KEY,
  title_th TEXT, title_en TEXT, scientific_name TEXT,
  category TEXT, family TEXT, growth_form TEXT, life_cycle TEXT,
  difficulty TEXT, time_to_harvest TEXT,
  suitable_regions TEXT[], water_need TEXT, sun_need TEXT,
  soil_types TEXT[], main_risks TEXT[], best_for TEXT[], not_suitable_for TEXT[],
  contributor TEXT, last_updated DATE, published_at DATE,
  confidence_overall TEXT,
  body_md TEXT,                -- raw MDX body for full-text + RAG
  embedding vector(1536),       -- OpenAI text-embedding-3-small or similar
  url TEXT GENERATED ALWAYS AS ('https://kasetatlas.com/crops/' || slug || '/') STORED
)

-- sources (deduplicated)
sources (
  id TEXT PRIMARY KEY,          -- e.g. 'fao-y2413e-cassava'
  url TEXT UNIQUE,
  title TEXT,
  type TEXT,                    -- 'thai-gov' | 'thai-uni' | 'international-uni' | 'peer-reviewed' | 'industry' | 'media'
  confidence TEXT,              -- 'high' | 'medium' | 'low'
  language TEXT,                -- 'th' | 'en' | 'mixed'
  last_verified TIMESTAMP,
  http_status INTEGER,
  body_topic_match BOOLEAN
)

-- crop_source (many-to-many)
crop_source (
  crop_slug TEXT REFERENCES crops,
  source_id TEXT REFERENCES sources,
  section INTEGER,              -- 1-12, which section it backs
  PRIMARY KEY (crop_slug, source_id, section)
)

-- verifications (history)
verifications (
  id BIGSERIAL PRIMARY KEY,
  crop_slug TEXT,
  date TIMESTAMP,
  verifier_pass INTEGER,
  blockers INTEGER, medium_issues INTEGER, minor_issues INTEGER,
  decision TEXT,
  raw_report JSONB
)
```

### 4.4 Sync strategy: build-time hydration

The MDX files remain the **source of truth** (they are git-versioned, human-readable, AI-pipeline-friendly). The database is a **read-only mirror** populated at build time.

```
on push to main:
  1. GitHub Actions runs `npm run build`
  2. Astro reads all MDX
  3. Custom build hook calls Supabase upsert for each crop
  4. Embeddings computed and stored
  5. Sitemap, RSS, etc. regenerated
```

This means:
- Database is never the canonical source — git is
- Schema changes require a migration + re-build, not data migration
- Read traffic to the DB never blocks content delivery
- Database can go down without breaking the static site

### 4.5 Risk classification
- 🔴 Adding Supabase to production stack — explicit maintainer approval required
- 🔴 Schema design — once committed, hard to migrate
- 🟡 Build-hook script — new code, but reversible

### 4.6 Cost projection
$0 marginal. Supabase Pro is already paid. Embedding cost: ~$0.02 per 50 crops at OpenAI text-embedding-3-small rates, billed at re-build time only.

---

## 5. Phase 4 — Ask the Atlas (target: ~75 crops live)

**Trigger:** When Phase 3 database is stable AND maintainer wants to enable Q&A.
**Goal:** Users can ask questions in Thai and get answers cited back to specific crop sections.

### 5.1 The feature

```
User types in Thai: "ปลูกอะไรดีในดินทรายภาคอีสาน?"
                    ("What's good to plant in sandy soil in the Northeast?")

System:
  1. Embed the question (text-embedding-3-small)
  2. pgvector similarity search → top-5 crop sections
  3. Send retrieved context + question to Claude API (anthropic-ai/sdk)
  4. Claude generates Thai-language answer WITH citations like:
     "มันสำปะหลังเหมาะกับดินทราย [1]. ถั่วลิสงก็ทนแล้งและดินทราย [2]..."
     [1] = link to /crops/cassava/#3-soil
     [2] = link to /crops/peanut/#3-soil
  5. Stream answer back to user

Constraint: Claude MUST cite. No-citation = fail. (System prompt enforces.)
```

### 5.2 Architecture

```
Browser
  └─ Vercel Edge Function (Node runtime, streaming response)
       ├─ Supabase RPC: vector_search(question_embedding) -> top-5 sections
       ├─ Anthropic API: claude-haiku-4-5 (fast, cheap, good enough for citation-grounded RAG)
       └─ Streams answer back via SSE
```

### 5.3 Why Haiku, not Opus or Sonnet
- Latency: Haiku ~5x faster than Opus for first-token-out
- Cost: Haiku ~10x cheaper at this query type
- Quality: For citation-grounded RAG with tight system prompt, Haiku is sufficient (the heavy lifting is retrieval, not reasoning)

### 5.4 Risk + cost
- 🔴 New external service in production path (Anthropic API)
- 🔴 First user-facing feature with non-deterministic output — risk of bad answers
- Cost: variable. ~$0.001 per query at Haiku rates. With 1000 queries/month, ~$1/mo. Negligible.

### 5.5 Safety constraints (hard requirements before ship)

- **Refuse off-topic questions** — system prompt enforces "agriculture only; refuse politics, medical, financial advice"
- **Refuse safety-critical questions** — pesticide dosages, edible/poisonous identification, medical claims must be refused with a "consult กรมวิชาการเกษตร" message
- **Always cite** — no answer without inline citations
- **Show confidence** — if retrieved sections have <70% similarity to question, prepend "ข้อมูลในระบบอาจไม่ตรงคำถามนี้พอดี — ลองถามต่างคำหรือดูหมวด..."
- **Rate limit per IP** — 10 queries/min, 100 queries/day (free, anonymous, no account)
- **Log all queries** — for offline review of failure modes

### 5.6 Pre-ship gates
- [ ] 100 manual test queries with maintainer review
- [ ] Refusal rate on safety-critical queries: 100%
- [ ] Citation rate on answered queries: 100%
- [ ] Average user-perceived latency: < 4s to first token
- [ ] Cost per query budget: < $0.01

---

## 6. Phase 5 — API + Maintainer Dashboard (target: 100+ crops, only if needed)

**Trigger:** A real third-party AI consumer (Perplexity, a research project, an academic) requests structured access AND maintainer wants a CMS-like view.

### 6.1 Public read API
- `GET /api/crops` — JSON list of all crops
- `GET /api/crops/{slug}` — full crop data
- `GET /api/sources` — all sources, deduplicated
- `GET /api/search?q=...` — Pagefind-equivalent JSON
- All read-only, no auth, rate-limited at edge (Cloudflare or Vercel)
- Response cached at edge for 1 hour

### 6.2 Maintainer dashboard (private)
- Pipeline health: verifier-stats trends, blocker rates, URL pass rates
- Content health: which crops have low-confidence sections, which sources are most cited, which sections fail verification most often
- Auto-suggested next crops (based on category gaps + Thai-government source availability)
- Auth: Supabase Auth, single-user (just maintainer), magic-link login

### 6.3 Risk
- 🔴 First auth surface in the project — Supabase Auth
- 🟡 Public API — needs rate limiting + observability

### 6.4 Cost
- Edge function calls included in Vercel Pro
- Auth: Supabase free tier handles single-user fine
- Marginal cost: $0

---

## 7. Phase 6 — Long-Horizon Possibilities (informal — not committed)

These are **not on the roadmap** but worth flagging if asked:

### 7.1 Community contribution model (V3+)
- GitHub-based: anyone files a PR with a new crop, maintainer reviews
- Currently informal; could formalize when 200+ crops + active community
- Contributor accounts via GitHub OAuth
- Issue templates, contribution guide, code-of-conduct
- **Defer until there's actual community demand.**

### 7.2 Mobile app
- PWA likely sufficient (already addable via manifest + service worker)
- Native iOS / Android: only if (a) 1M+ pageviews/month and (b) feature requirements that PWA can't meet
- **Currently NOT on roadmap.**

### 7.3 Multi-language expansion
- The mission is **Thai-language**. Expansion to Lao / Khmer / Burmese (regional ag knowledge gap is similar) is theoretically possible but a major scope expansion
- **Defer until 500-crop V1 target reached.**

### 7.4 Specialized verticals
- Mushroom-specific schema (different from plant)
- Aquaculture? Livestock?
- **Defer until plant kingdom is complete.**

---

## 8. Architectural Principles (non-negotiable)

These constrain every decision in this plan.

### 8.1 Static-first
The site renders to HTML at build time. The database (when added) hydrates the static build, not the runtime. **Read traffic must always work even if Supabase is down.**

### 8.2 Source-of-truth is git
MDX files are the canonical content. Database is derived. Database can be wiped and rebuilt from git in <5 minutes.

### 8.3 No backend feature without a real user need
Speculative features get rejected. "Phase 3" is not a roadmap commitment — it's a contingency that activates only if 50 crops + lexical-search inadequacy + observed user demand all converge.

### 8.4 Use the paid stack before adding new tools
Per CLAUDE.md §12: Vercel Pro, GitHub Pro, Supabase Pro, Claude Max 20x are paid. Use them. New paid tools require explicit approval.

### 8.5 Pipeline transparency over end-user features
The auto-pipeline is the project's primary differentiation. Investments in Verifier intelligence, drift signal, Pattern Win promotion, and Content Verifier discipline pay back across every crop. Investments in user-facing features (Q&A, dashboard, API) only pay back per-feature.

**When in doubt, harden the pipeline before building UX.**

### 8.6 Public good > monetization
No ads. No paywall. No "premium" tier. No data sale. License is CC BY-SA 4.0 forever. If money is needed, it comes from funded research collaborations only (per CLAUDE.md §1).

---

## 9. Decision Log Template

When adding any backend component, document via this template in `docs/AUDIT_LOG.md`:

```markdown
## YYYY-MM-DD — [Component name] introduced

**Phase:** [1-6 from this document]
**Type:** Architecture / Backend
**Decision:** What was added.
**Rationale:** Which user need this serves. Which alternative was rejected and why.
**Risk:** 🟢/🟡/🔴 per CLAUDE.md §6
**Cost:** Marginal cost vs existing paid stack.
**Rollback plan:** How to remove if it doesn't work.
**Reporter:** Maintainer + AI Pipeline (auto/manual).
```

---

## 10. Phase Triggers — Summary Table

| Phase | Trigger | Status |
|---|---|---|
| 0 — Static + Pipeline | Day zero | ✅ shipped |
| 1 — Polish + Observability | 10 crops live OR 2 weeks | ⏳ next |
| 2 — Pipeline Hardening | 30 crops live OR drift detected | ⏳ |
| 3 — Database Layer | 50 crops live + lexical-search inadequacy | ⏳ |
| 4 — Ask the Atlas (RAG) | 75 crops + Phase 3 stable + maintainer wants Q&A | ⏳ |
| 5 — API + Dashboard | 100+ crops + 3rd-party demand | ⏳ |
| 6 — Long-horizon | Each item has its own trigger | not committed |

---

## 11. What to do NEXT (architect-mode pick)

Per Rule 3 (reduce weaknesses before features) and the current state of the project:

**Sequence for the next 2 weeks:**

1. **Hand DESIGN_BRIEF.md to Claude Design.** Wait for Phase A-C output (strategy, logo, design system).
2. **Continue `/add-crop` runs** in parallel — design and content production are independent.
3. **Target: 6 more crops** (one per remaining V1 category) before applying new design system.
4. **When design lands:** apply design tokens to `tailwind.config.ts`, swap logo files, rebuild.
5. **After design-applied build is stable:** wire Pagefind UI, enable Vercel Analytics, submit sitemap to Google Search Console.

This sequence keeps content production unblocked while design happens in parallel. **No backend additions in the next 2 weeks** — Phase 1 is the right scope.

---

**End of plan. Maintainer reviews this document quarterly or when phase triggers fire.**
