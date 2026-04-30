# Pawee Workflow Kit — Kaset Atlas Edition

> Living document. The kit evolves with the project. Update this file whenever a new pattern wins or an old approach is discarded.
>
> Last updated: 2026-04-29

---

## 1. Purpose

The Pawee Workflow Kit is the **operational layer** above CLAUDE.md.

- CLAUDE.md states the **principles** (what we believe).
- This file records **how those principles are applied today** and **what we have learned about applying them well** (what we do, and what we tried and discarded).

The kit is not static. Patterns that work get logged here. Patterns that fail get logged here. Old patterns get retired when better ones land. The goal is to converge over time on a workflow that produces near-zero pipeline errors with minimal maintainer intervention.

This is not Wikipedia. It is not a generic Claude Code tutorial. It is the *Kaset Atlas* edition of the kit — patterns specific to producing source-traceable, AI-citable Thai agricultural content.

---

## 2. Operating principles (recap)

From CLAUDE.md, with operational notes for this project:

| Principle | Operational expression |
|---|---|
| Source-Traceable Always | Every claim cites; URLs HTTP-verified at 3 stages (Researcher → URL Verifier script → Content Verifier re-fetch) |
| Confidence Labels Mandatory | 🟢 / 🟡 / 🟠 / ⚪ per body section |
| Localize, don't translate | Thailand applicability note for every foreign source |
| Safety over completeness | Auto-refuse risky chemical/dosage/identification advice |
| Static-first (V1) | No DB, no auth, no AI chat — Astro + MDX only |
| Auto-pipeline integrity | URL Verifier + Content Verifier MUST pass before commit |
| Public transparency | README discloses AI-generated; AUDIT_LOG records errors |
| Foundation first | Reduce weaknesses before adding strengths (Rule 3) |
| Ask first on ambiguity, 🟡, 🔴 | Rule 10 |
| Free-tier audit before new tools | Rule 7 + CLAUDE.md §12 |
| AI-citable | Bilingual structured data, llms.txt, open robots.txt, JSON-LD per crop |

---

## 3. A/B testing convention

### When to run an A/B
- Suspected drafter prompt improvement
- Researcher search-strategy change (new query template, new source category)
- Verifier strictness adjustment
- New body section pattern (e.g., adding an FAQ block)
- Significant policy interpretation change

### How to run an A/B
1. Pick **two candidate crops at similar complexity**, OR **one crop with two prompt variants**.
2. Run both pipelines independently. Each verifier runs in fresh context (the existing isolation rule still applies).
3. Compare verifier output: blocker count, medium issue count, sources cited, words written, fidelity-check pass rate, build-time MDX safety check pass.
4. Pick the winner. Log to **§4 Pattern Wins**.
5. Discard the loser. Log to **§5 Discarded approaches**.
6. Update the relevant agent prompt or policy doc to reflect the winning pattern.
7. Commit the prompt change as `chore(agents): adopt pattern X over Y [a-b-test 2026-XX-XX]`.

### Cadence
**Opportunistic, not scheduled.** Run an A/B when a likely improvement surfaces — a verifier near-miss, a recurring drafter pattern, a new source type. Do not run A/Bs reflexively on every crop; that wastes pipeline budget.

### Rollback
If an adopted pattern later fails on a new crop, log to §5 with the failure reason and revert the prompt. The kit is not append-only-permanent — patterns can graduate AND be retired.

---

## 4. Pattern Wins (chronological, append-only)

### 2026-04-30 — Content Verifier evidence-discipline (post-hallucination incident)
**Pattern:** Content Verifier prompt now mandates: (1) Step 0 deterministic file-stats preamble (Thai char count, URL list, section heading list) at top of every report; (2) verbatim quotes on every blocker (file evidence with line number + ≥10-word source excerpt + discrepancy statement); (3) Step 9.5 self-consistency check that auto-rejects findings referencing URLs/sections/content not in own preamble.
**Why it works:** A subagent that produces a hallucinated finding will simultaneously print a deterministic preamble showing the actual data, making the contradiction self-evident. Verbatim quote requirement makes hallucination impossible — a quote either exists in the file or it doesn't. Self-consistency check catches the verifier's own drift before the report is submitted.
**Replaced:** Trust-based verifier dispatch where the subagent's report was accepted at face value.
**Source:** Cassava pass-3 verifier hallucination 2026-04-30 (logged in `docs/PIPELINE_FAILURES.md`). `.claude/agents/content-verifier.md` updated in commit `4864314`.

### 2026-04-30 — Manual override path for verifier hallucination (direct spot-check)
**Pattern:** When the Content Verifier subagent produces findings that contradict deterministic data the main session can verify (file char counts, URL grep, WebFetch), the maintainer + main session may reject the verifier report and ship with `verification_status: "pass-with-direct-spot-check"` recorded in the reasoning sidecar.
**Why it works:** Subagent dispatch has a non-zero hallucination rate. Hard gates (URL Verifier v3.1, MDX Safety, Build Verifier) plus 1-3 direct spot-checks via WebFetch can substitute for verifier when verifier itself fails. The override is logged for audit and contributes to verifier-stats drift signal.
**Replaced:** Strict "verifier blocks publication unconditionally" rule.
**Source:** Cassava pass-3 (commit `d33e709`). The override is exceptional — Pattern Win 2026-04-30 (evidence-discipline) is the durable fix; this entry documents the escape valve when hallucination still slips through.

### 2026-04-30 — Phase 1 polish: Pagefind UI, Vercel Analytics, RSS feed (parallel to design)
**Pattern:** Site infrastructure (Pagefind UI integration, Vercel Analytics + Speed Insights enable, `@astrojs/rss` feed, Dependabot config) shipped in parallel with handing the design brief to Claude Design. Each component is independent: Pagefind UI consumes the existing build-time index; Vercel Analytics and Speed Insights are paid features already included in Vercel Pro just needing toggle; RSS reads the same content collection as sitemap.
**Why it works:** Phase 1 work is content-independent (it improves the production system) and design-independent (no visual treatment until Claude Design ships). Doing it now removes a backlog item without blocking either parallel track. Cost: $0 — all in the existing paid stack or FOSS.
**Replaced:** N/A — net new infrastructure.
**Source:** BACKEND_PLAN.md §2 + commits in this session.

### 2026-04-29 — Drafter MDX-safety bash check
**Pattern:** Drafter runs `grep -nE '[<>][a-z0-9]' src/content/crops/<slug>.mdx` before returning `draft_complete`. Empty output = pass; any output = halt and fix.
**Why it works:** JSX components in MDX are always PascalCase. A `<` immediately followed by lowercase or digit is therefore either (a) a bare comparison (`<6.0`) that breaks the parser, or (b) accidental raw HTML. The check catches both.
**Replaced:** No prior check existed. The holy-basil first run produced bare `<6.0` and `>8.0` patterns that needed manual `fix(content)` commits afterward (`badca21`, `3f37c80`).
**Source:** `.claude/agents/drafter.md` updated in commit `53900f2`.

### 2026-04-29 — URL Verifier HEAD→GET fallback
**Pattern:** `verify-urls.sh` tries HEAD first; if HEAD returns 4xx/5xx, retry with `curl -L --max-time 10 -r 0-0` (1-byte GET range request). Accept 200/206/301/302.
**Why it works:** Many real sources (PMC, government PDFs, Incapsula-gated commercial sites) reject HEAD by policy or have broken HEAD handlers. GET is universally supported.
**Replaced:** HEAD-only verification (see §5).
**Source:** `scripts/verify-urls.sh` updated in commit `07d4f3d`. PIPELINE_FAILURES.md 2026-04-29 url-verifier entry surfaced the gap.

### 2026-04-29 — Fresh-context Content Verifier
**Pattern:** Content Verifier dispatched as a separate subagent with no shared memory of Drafter. Re-reads policies and re-fetches sources independently.
**Why it works:** Prevents correlated hallucinations. Two agents reading the same source independently and agreeing is a real fidelity check. Two agents sharing context can converge on the same wrong answer.
**Replaced:** N/A — net new with the auto-pipeline.
**Source:** `docs/AUTOMATION_PIPELINE.md` design.

### 2026-04-29 (late) — URL Verifier v3: soft-200 body inspection
**Pattern:** `scripts/verify-urls.sh` v3 fetches the first 4KB of every URL's body in addition to HTTP status check. If body matches one of a small set of known soft-error markers (`ไม่พบกระทู้ที่ระบุ`, `ไม่พบ File นี้`, `ไม่พบหน้านี้ในระบบ`, `<title>... 404 ...</title>`, etc.), the URL is reported as `status: "soft-200"` regardless of actual HTTP code. Patterns are deliberately specific to error pages — broad matches like bare `ไม่พบ` are avoided because that phrase appears in legitimate content.
**Why it works:** Thai government CMS (DOA Share forum, opsmoac file system, etc.) commonly returns HTTP 200 with an error-page body when a thread/file/article goes missing. HTTP-only verification misses this; body inspection catches it. Caught durian's 3 dead-thread URLs and cassava's 1 dead-province URL — failures that would have shipped silently under v2.
**Replaced:** v2 HEAD+GET-status-only verification (see §5 discarded).
**Source:** `scripts/verify-urls.sh` v3 + v3.1 (soft-error pattern broadening) — landed 2026-04-29 (late). PIPELINE_FAILURES.md 2026-04-29 cassava+durian content-verifier halts surfaced this gap.

### 2026-04-29 (late) — Drafter: no `{frontmatter.X.method()}` in MDX body
**Pattern:** The crop layout (`src/pages/crops/[...slug].astro`) handles ALL frontmatter rendering using `crop.data.X` — Astro's Zod schema coerces these values to their proper types (e.g., `lastUpdated` becomes a `Date`). MDX body must NOT call `{frontmatter.X.toLocaleDateString()}` or any other method on a frontmatter value because at MDX render time `frontmatter.X` is a raw string, not the parsed type. The method call throws and breaks the build.
**Why it works:** The broken pattern lived in `_template.mdx` line 194 since project init; the durian drafter copied it. Build Verifier (Tier 1.2) caught the runtime failure. The fix: remove the broken footer block from `_template.mdx`, add a comment in its place explaining why, and add a new Forbidden item to drafter prompt.
**Replaced:** Implicit assumption that `frontmatter.X` works the same as `crop.data.X` (it doesn't — `crop.data.X` is the parsed object, `frontmatter.X` is the raw string).
**Source:** Durian initial build failure (2026-04-29 22:34). PIPELINE_FAILURES.md entry.

### 2026-04-29 (late) — Drafter: never cite a source for claims the source doesn't substantiate
**Pattern:** Before citing a source for any claim, the Drafter MUST actually fetch and read the document to confirm it covers that specific claim. Citation by topic-keyword (URL contains "processing" → cite for HCN-processing claims) is FORBIDDEN because URL slugs and document titles can lie. FAO y5548e is at `/3/y5548e/...` — slug gives no signal — and the document at that URL is "A cassava industrial revolution in Nigeria" (a country case study under the Global Cassava Development Strategy initiative), NOT the more generic "Cassava Processing and Utilization" the URL slug or surrounding navigation might suggest.
**Why it works:** Forces actual document inspection at draft time. Catches title/content mismatches before the Content Verifier has to. Saves a full pipeline halt.
**Replaced:** Citation by topic-keyword without document fetch.
**Source:** Cassava blocker (FAO y5548e misattribution, 2026-04-29 23:00 content-verifier first pass). PIPELINE_FAILURES.md cassava entry. Drafter prompt updated.

### 2026-04-29 — Atomic commit policy: separate agent vs content vs docs
**Pattern:** Agent prompt changes, content additions/fixes, and docs changes go in **separate commits**, each with the right conventional-commit prefix:
- `chore(agents): ...` — `.claude/agents/*.md` changes
- `content(<category>): ... [auto]` — auto-pipeline crop addition
- `fix(content): ... [retro]` — manual fix retroactively applying a new agent rule to old content
- `chore(audit): ...` — AUDIT_LOG / PIPELINE_FAILURES updates only
**Why it works:** Each commit is independently revertible. A failing agent prompt doesn't poison content history; a content fix doesn't drag in unrelated infra.
**Replaced:** N/A.
**Source:** Observed during the holy-basil run; codified after `53900f2` + `3f37c80`.

---

## 5. Discarded approaches (chronological)

### 2026-04-30 — Trust-based content-verifier subagent dispatch (no evidence preamble)
**Approach:** Dispatch Content Verifier subagent in fresh context, accept its JSON report at face value, halt publication on any blocker without independently checking the verifier's claims.
**Why discarded:** Subagent hallucination rate on retry passes is non-zero. Cassava pass-3 produced a confident report with three blockers, all of which were objectively false on deterministic check (claimed 0 Thai chars when file is 74% Thai; cited 4 URLs as failing that don't appear in the file; claimed IITA page lacked "95%" figure when the page literally states it verbatim). Trusting the report would have wasted hours of false-positive remediation OR — worse mode — accepted false-negatives that let real issues ship.
**Replaced by:** Pattern Win 2026-04-30 — Content Verifier evidence-discipline (Step 0 preamble + verbatim quotes + Step 9.5 self-consistency).

### 2026-04-29 — HEAD-only URL verification
**Approach:** `curl --head` only, no fallback. Any non-2xx/3xx HEAD response treated as URL failure.
**Why discarded:** False-negative rate too high. PMC blocks HEAD by policy (returns 405). Some Thai government PDF servers have broken HEAD handlers (return 404 to HEAD but 200 to GET). Anti-bot-gated commercial sites return concatenated status codes through redirect chains. First holy-basil pipeline run halted on 4 false-negatives across these classes.
**Replaced by:** Pattern Win 2026-04-29 (HEAD→GET fallback).

### 2026-04-29 (late) — URL Verifier v2 (HTTP-status-only after HEAD→GET fallback)
**Approach:** v2 checked only HTTP status (with HEAD→GET fallback for sites that don't support HEAD). Any 200/206/301/302/304 = pass, anything else = fail.
**Why discarded:** Thai government and other CMS commonly return HTTP 200 with an error-page body when the underlying content is missing. v2 marked these "soft-200" responses as PASS, letting them slip past URL verification. Caught only at the much more expensive Content Verifier stage. Durian's 3 dead-thread URLs and cassava's 1 dead-province URL all passed v2 but failed Content Verifier — wasting ~25 minutes of pipeline time per crop.
**Replaced by:** Pattern Win 2026-04-29 (late) — URL Verifier v3/v3.1 with soft-200 body inspection.

### 2026-04-29 (late) — Drafter: citation by topic-keyword
**Approach:** Drafter cites URL X for claims about topic Y if X's URL slug, breadcrumb, or visible page title contains Y, without actually fetching and reading the document.
**Why discarded:** URL slugs lie. FAO y5548e is hosted at `/3/y5548e/y5548e00.htm` — opaque slug. The document at that URL is "A cassava industrial revolution in Nigeria" — a country case study under the Global Cassava Development Strategy initiative — not a generic processing manual. Drafter cited it for HCN cyanogenic-glucoside processing claims it does not cover. Cassava blocker resulted.
**Replaced by:** Pattern Win 2026-04-29 (late) — Drafter must fetch and read each cited source before citation.

### 2026-04-29 (late) — `_template.mdx` footer with `{frontmatter.X.toLocaleDateString()}`
**Approach:** `_template.mdx` had a "ปรับปรุงล่าสุด" footer block calling `{frontmatter.lastUpdated.toLocaleDateString('th-TH')}` directly in MDX body.
**Why discarded:** At MDX render time `frontmatter.X` is the raw YAML string, not the Zod-coerced Date object that `crop.data.X` exposes via the page layout. Calling `.toLocaleDateString()` on a string throws and breaks the Astro build. Durian drafter copied this from the template; cassava drafter happened not to. Build Verifier (Tier 1.2) caught the runtime failure.
**Replaced by:** Pattern Win 2026-04-29 (late) — never call `{frontmatter.X.method()}` in MDX body. Crop layout already renders metadata using `crop.data.X`. Template footer block deleted; replaced with a comment explaining why.

---

## 6. Bilingual structured-data convention (AI-citable goal)

For every crop, the structured-data layer must surface both Thai and English so non-Thai AI queries can find and cite us.

| Field | Language |
|---|---|
| `<title>` (HTML) | Thai (primary) + English in parentheses (e.g., `กะเพรา (Holy Basil)`) |
| JSON-LD `name` | Thai |
| JSON-LD `alternateName` | Array of English common names + scientific name (e.g., `["Holy Basil", "Tulsi", "Ocimum tenuiflorum"]`) |
| JSON-LD `description` | Thai prose (matches frontmatter `summary`) |
| JSON-LD `keywords` | Thai + English mix (e.g., `["กะเพรา", "holy basil", "ocimum tenuiflorum", "tulsi", "Thai herb cultivation", "การปลูกกะเพรา"]`) |
| JSON-LD `inLanguage` | `th` |
| JSON-LD `license` | `https://creativecommons.org/licenses/by-sa/4.0/` |
| `llms.txt` entry | `## กะเพรา (Holy Basil) — /crops/holy-basil` |
| `<meta name="description">` | Thai (primary, matches frontmatter `seoDescription`) |
| Open Graph `og:title` | Thai + English |
| Open Graph `og:description` | Thai |

**Rationale:** The page is written for Thai readers — that stays Thai. The structured-data layer is for machine consumption, including English-language AI agents that need to map a query like "how to grow holy basil" to our Thai content.

---

## 7. AI engine priority order (V1)

`public/robots.txt` explicitly allows (in citation-likelihood order):

1. **GPTBot** (OpenAI / ChatGPT search) — broadest reach
2. **PerplexityBot** (Perplexity) — high citation density per query
3. **ClaudeBot** + **anthropic-ai** (Claude.ai)
4. **Google-Extended** (Google AI Overviews / Gemini grounding)
5. **CCBot** (Common Crawl, used by many AI training sets)
6. **Applebot-Extended** (Apple Intelligence)

Default `User-agent: *` also `Allow: /`. We block nothing.

If any of these crawlers cause traffic problems later, we reconsider individually. Default is **open**.

---

## 8. Content license

**CC BY-SA 4.0** — Creative Commons Attribution-ShareAlike 4.0 International.

- Anyone may quote, translate, redistribute.
- Must attribute Kaset Atlas with a link back to the source page.
- Derivative works must use the same license.

License notice in:
- `README.md` — license badge + summary
- Footer of every page (Astro layout)
- `LICENSE-CONTENT` file at repo root
- JSON-LD `license` field per crop
- `llms.txt` header

Code license (separate): **MIT** (`LICENSE` file at repo root).

---

## 9. Memory schema

Every entry in §4 / §5 follows a strict schema so future-me (and you) can scan quickly.

**Pattern Wins entry template:**
```
### YYYY-MM-DD — [Short Title]
**Pattern:** [the new pattern, one paragraph]
**Why it works:** [the mechanism in plain language]
**Replaced:** [the old pattern, or "N/A — net new"]
**Source:** [PIPELINE_FAILURES.md / AUDIT_LOG.md / commit SHA / conversation date]
```

**Discarded entry template:**
```
### YYYY-MM-DD — [Short Title]
**Approach:** [what was tried]
**Why discarded:** [the failure mode observed, with concrete example]
**Replaced by:** [link to Pattern Win entry, e.g., "Pattern Win 2026-XX-XX"]
```

---

## 10. Kaset Atlas-specific patterns (the "operational" layer below the principles)

These patterns are specific to the actual sources and content we deal with on this project. Generic ag knowledge sites would diverge; this is what works for Thai-language, Thai-government-anchored, AI-citable agricultural reference.

### KA-1. Thai government source HEAD-handler instability
Thai gov sites (`doa.go.th`, `kukr.lib.ku.ac.th`, `ldd.go.th`) frequently return 404 or non-2xx codes to HTTP HEAD even when GET works fine. Some endpoints have no HEAD handler at all. **`scripts/verify-urls.sh` always falls back to GET-with-1-byte-range** when HEAD fails. This is non-negotiable; reverting to HEAD-only would re-introduce the false-negatives we resolved in commit `07d4f3d`.

### KA-2. PMC anti-scrape behavior
PMC (`pmc.ncbi.nlm.nih.gov`) blocks HEAD by site policy (returns 405). It also rate-limits headless GETs without a real browser User-Agent — sometimes returning a reCAPTCHA challenge page even on the second access. **Always use a Mozilla User-Agent string for PMC URLs.** If still blocked, the URL Verifier accepts 200 from the bot challenge page as "URL exists" without parsing content; the Content Verifier may mark `verifier-unable-to-fetch` for content-fidelity check rather than blocking.

### KA-3. Thai cultivar nomenclature requires bilingual `aliases`
Many Thai herbs have multiple cultivars (กะเพราแดง vs กะเพราขาว, โหระพา vs โหระพาฝรั่ง). The drafter must:
- Cover both cultivars in the body where applicable
- List all common Thai names + English transliterations + scientific name in `aliases` frontmatter
- Mention specifically in §11 (foreign knowledge) if the foreign sources don't distinguish

This feeds into the AI-citable JSON-LD `alternateName` so non-Thai AI queries can find Thai cultivar info.

### KA-4. Temperate-source applicability mismatch
US extension sources (UC Davis, NC State, Cornell, UMN, Penn State) describe temperate-climate practices. Thailand is tropical/subtropical. **Always include §11 disclaimer** about applicability differences when citing them. Common mismatches:
- "Plant in spring" → "ปลูกได้ตลอดปีในไทย"
- Specific frost-date references → ignore for Thai context
- Specific lime/dolomite rates → adapt to Thai soil pH (often more acidic)
- Specific NPK ratios → defer to Thai stations

### KA-5. Royal projects (โครงการหลวง / RSPG) are 🟢 high confidence
The Royal Project Foundation and Plant Genetic Conservation Project (Royal Initiative) at `rspg.or.th` provide curated reference material for many Thai crops, especially highland and indigenous species. These are 🟢 high confidence and **should be checked before defaulting to international sources**.

### KA-6. SOURCE_POLICY §3 mapping for AI-citable JSON-LD
When we eventually wire the source registry (Tier 1.3, deferred), the registry's metadata fields map directly to AI-citable structured data:
- `source.title` → JSON-LD `Citation.name`
- `source.url` → JSON-LD `Citation.url`
- `source.publicationDate` → JSON-LD `Citation.datePublished`
- `source.organization` → JSON-LD `Citation.author.name`
- `source.confidence` → not exposed publicly; audit-internal

Until the registry is wired, sources stay inline in each crop's source table (rendered as Markdown).

### KA-7. Thai locale conventions
- Numerals: prefer Arabic (1, 2, 3) over Thai (๑, ๒, ๓) for SEO and AI-citation. Maintain Thai numerals only when quoting traditional sources.
- Dates: Buddhist Era (พ.ศ.) is acceptable in body prose but `lastUpdated` / `publishedAt` frontmatter MUST use ISO 8601 (CE / Gregorian) for content collection schema validation.
- Plant naming convention: Thai name first, English in parentheses on first use, scientific in italics. E.g., `กะเพรา (Holy Basil, *Ocimum tenuiflorum*)`.

### KA-8. Build-gate teaches us about MDX edge cases
Patterns observed that the MDX-safety regex catches (added to drafter prompt 2026-04-29):
- `<6.0`, `<5.5` (pH ranges) — broke build until escaped to `< 6.0`
- `<30°C` (temperature thresholds) — would break similarly; required `< 30°C`
- `>1,000 ม.` (elevation) — cosmetic but caught for symmetry

**Drafter is now hardened against this** via `scripts/check-mdx-safety.sh` mandatory check.

---

## 11. Foundation Completeness Map

What's done, what's pending, what's deferred. Updated 2026-04-29 (post-tonight's foundation work).

### 🟢 Foundation in place

| Item | Where | Status |
|---|---|---|
| Constitutional doc | `CLAUDE.md` | 12 sections, 10 rules, AI-citable goal codified |
| Methodology | `docs/METHODOLOGY.md` | Full per-crop workflow |
| Source policy | `docs/SOURCE_POLICY.md` | Confidence levels + citation rules |
| Safety policy | `docs/SAFETY_POLICY.md` | Refusal categories codified |
| Pipeline spec | `docs/AUTOMATION_PIPELINE.md` | 4-agent + script orchestrator |
| Pawee Workflow Kit | `docs/WORKFLOW_KIT.md` | This file. A/B convention + Pattern Wins log |
| Audit trail | `docs/AUDIT_LOG.md` | Append-only architectural decisions |
| Failure log | `docs/PIPELINE_FAILURES.md` | Append-only halt incidents |
| Researcher agent | `.claude/agents/researcher.md` | HTTP-verifies all URLs |
| Drafter agent | `.claude/agents/drafter.md` | MDX-safe, sees existing crops, writes reasoning sidecar |
| Content verifier agent | `.claude/agents/content-verifier.md` | Fresh-context, logs stats, cross-checks reasoning |
| Decision orchestrator | `.claude/commands/add-crop.md` (slash command) | v2 with build gate, state checkpoint, Read-then-dispatch |
| URL verifier script | `scripts/verify-urls.sh` | HEAD→GET fallback |
| Build verifier script | `scripts/verify-build.sh` | Wraps `npm run build`, JSON output |
| MDX safety script | `scripts/check-mdx-safety.sh` | Catches `[<>][a-z0-9]` patterns |
| AI-citable: robots | `public/robots.txt` | Open posture, all major AI crawlers allowed |
| AI-citable: llms.txt | `public/llms.txt` | Site map for AI digestion |
| AI-citable: JSON-LD | `src/components/JsonLd.astro` + `src/layouts/BaseLayout.astro` | Per-page structured data |
| AI-citable: Article schema | `src/pages/crops/[...slug].astro` | Bilingual alternateName, keywords, dateModified |
| AI-citable: WebSite + Org | `src/pages/index.astro` | Homepage structured data |
| AI-citable: sitemap | `astro.config.mjs` (default `@astrojs/sitemap`) | Auto-generated |
| AI-citable: license | `CONTENT_LICENSE.md` (CC BY-SA 4.0), footer, JSON-LD | Aligned across all surfaces |
| State checkpoint | `.claude/state/pipeline-current.json` (transient) | gitignored |
| Verifier stats log | `.claude/logs/verifier-stats.json` (committed NDJSON) | Drift signal |
| Reasoning sidecar | `src/content/crops/<slug>.reasoning.json` | Audit trail per crop |
| Build CI | `.github/workflows/build.yml` | Runs on push/PR |
| Weekly link-rot CI | `.github/workflows/link-check.yml` | Cron Sunday 00:00 UTC |
| Search | Pagefind in `npm run build` | Auto-indexed; 1367 words at 2 crops |
| Conventional commits | `CLAUDE.md §8` | `[auto]` suffix for pipeline; `[retro]` for retroactive |

### 🟡 Foundation pending (visible gaps)

| Item | Why pending | When |
|---|---|---|
| Vercel deploy | Requires maintainer auth; cannot be done by AI alone | When maintainer connects repo to Vercel project |
| Source registry (Tier 1.3) | High effort, lower urgency at 2 crops | When corpus reaches ~10+ crops |
| Hero images per crop | No image-generation pipeline yet | V1.1 |
| Category landing page descriptions (curated) | Currently auto-generated lists | When 3+ crops per category |
| `og-image.png` default at site root | Currently 404 (favicon.svg used as fallback in JSON-LD) | When hero image strategy lands |
| Public LEARNINGS.md (vs internal WORKFLOW_KIT) | Internal-only suffices for V1 | V2 |
| WORKFLOW_KIT in Thai | Internal — English per Rule 1 | Permanent (won't translate) |
| Branch protection on `main` | Documented in CLAUDE.md §9, not enforced on GitHub | When maintainer enables |
| Rate limit enforcement | Documented (5/hr, 50/day), no programmatic enforcement | When/if pipeline runs autonomously |

### 🔴 Foundation deferred (not in V1 scope)

| Item | Why deferred |
|---|---|
| Supabase Pro integration | Static-First V1; revisit V2 when corpus needs RAG |
| Real `/add-crop` execution from Claude Code's slash-command engine | The markdown file exists; whether Claude Code's harness picks it up depends on user environment |
| Image generation pipeline | V1.1 |
| Translation of foreign sources beyond English (e.g., Chinese, Japanese ag refs) | V2 |

---

## 12. Open questions (revisit as we go)

- **Pagefind activation:** ✅ already in stack (`npm run build` invokes it). 1367 words indexed at 2 crops. Search bar component exists; needs end-to-end test.
- **Drafter model selection:** A/B test Opus vs Sonnet on next crop pair (Tier 3 optimization).
- **Source registry implementation:** schedule = when corpus reaches ~10 crops or first cross-citation conflict surfaces, whichever first.
- **`og-image.png` strategy:** decide between (a) one shared brand OG image, (b) per-category OG image, (c) per-crop hero. Defer until image generation pipeline lands.
- **Branch protection rules:** maintainer to enable on GitHub when ready (auto-pipeline pushes via PR rather than direct commit).
- **Rate-limit enforcement:** add a `.claude/state/rate-limit-counters.json` if/when autonomous pipeline runs become routine. Not needed today (manual `/add-crop` only).
- **Vercel deploy auto-promotion:** when maintainer connects repo, decide whether to auto-promote on `main` push or require manual promote for content commits.

---

## 13. How to update this file

When a Pattern Win or Discarded entry is added:
1. Append to §4 or §5 with the schema in §9.
2. Update §10 if it changes any open-question status.
3. Bump "Last updated" line at top.
4. Commit as `docs(workflow-kit): record [pattern win | discarded] — [short title]`.

Do **not** rewrite past entries. The log is append-only for traceability. If a past Pattern Win is later discarded, add a new Discarded entry referencing it — both stay in place.

---

## Last Updated

2026-04-30 — Phase 1 polish session: Pagefind UI wired, Vercel Analytics + Speed Insights enabled, `@astrojs/rss` feed shipped, Dependabot config added, `pipeline-monitor` agent recruited (Phase 2 readiness). Pattern Win + Discarded entries logged for the Content Verifier hallucination incident. Live site at https://kasetatlas.com/ with 3 crops + custom-domain SSL.

2026-04-29 (late session) — Phase B added: §10 Kaset Atlas-specific patterns, §11 Foundation Completeness Map, §12 updated open questions. Foundation work pushed in commits `96cf6a4` (workflow tooling), `a4d757b` (AI-citable infra), `399c301` (license alignment), `2870ef6` (agent prompt upgrades).

2026-04-29 (initial) — Phase A: A/B convention, Pattern Wins (3 entries), Discarded (1 entry), bilingual structured-data convention, AI engine priority order, license language, memory schema, open questions.
