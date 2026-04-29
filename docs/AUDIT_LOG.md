# Audit Log — Kaset Atlas

> Architectural decisions, source policy changes, content removal/correction events, and major refactors.

---

## 2026-04-30 — Auto Pipeline: Added มันสำปะหลัง (Cassava) + Pass-3 Content Verifier Hallucination Incident

**Type:** Content Addition (auto, manually-corrected) + Pipeline Anomaly

**Crop:** มันสำปะหลัง (Cassava) — `cassava`
**Category:** food-crops
**Scientific:** *Manihot esculenta*

**Pipeline run (cumulative across 3 passes):**
- **Pass 1** (2026-04-29 ~22:30): Researcher 12 sources, Drafter 13 sections, URL Verifier v3 12/12, Build Verifier pass, Content Verifier 1 blocker (FAO y5548e misattribution) + 2 medium issues. Auto-fix retry applied.
- **Pass 2** (2026-04-29 ~23:00): URL Verifier v3.1 caught opsmoac-rayong-cassava soft-404 (v3 had missed it); Content Verifier in fresh context found 1 new blocker + 2 residual medium + 1 minor. Auto-fix budget exhausted per Rule 8.
- **Pass 3** (2026-04-30, manual corrections this session): Maintainer authorized bounded manual fix (4 edits): drop opsmoac row, correct y5548e title to actual document name "A cassava industrial revolution in Nigeria — IFAD/FAO 2004", trim §7 IITA biocontrol claim to Africa-only + "cassava mealybug" phrasing, update reasoning sidecar source IDs.

**Pass-3 verification anomaly (logged as Pattern Discarded):**

After manual correction, dispatched Content Verifier subagent in fresh context for verification pass-3. **The subagent produced a hallucinated report** claiming three blockers that were objectively false:

1. Claim: "file contains 0 Thai Unicode characters." Reality: file is 73.9% Thai (15,053 of 20,383 chars).
2. Claim: "4 cited URLs (kasetkaoklai.com, agri.nstda.or.th, dld.go.th, tapiocathai.org) fail body-content verification." Reality: zero of those URLs appear in the file. The actual 11 cited URLs are doa.go.th, oae.go.th (×2), esc.doae.go.th, arda.or.th, thaitapiocastarch.org, fao.org (×2), iita.org, hort.purdue.edu — none of which the verifier flagged.
3. Claim: "IITA 95% biocontrol figure is not on the cited cropsnew/cassava page." Reality: direct WebFetch retrieval confirmed the IITA page literally states "IITA's biological control program resulted in a 95% reduction in cassava mealybug damage and a 50% reduction in damage caused by the cassava green mite."

**Resolution:** Maintainer + main session rejected the hallucinated report after direct sanity-check (Thai char count, URL grep, IITA page WebFetch). Cassava SHIPPED with verification status "pass-with-direct-spot-check" recorded in `cassava.reasoning.json`. The hard gates (URL Verifier v3.1: 11/11, MDX Safety: pass, Build Verifier: 17 pages) all passed; the only spot-checkable substantive verifier finding (IITA 95%) was confirmed substantiated by direct source fetch.

**Sources cited (all 11 verified live + on-topic):**
- กรมวิชาการเกษตร (DOA) — ศูนย์วิจัยพืชไร่ระยอง (×2)
- สำนักงานเศรษฐกิจการเกษตร (สศก./OAE) — สถานการณ์สินค้ามันสำปะหลัง + Outlook 2566 (×2)
- กรมส่งเสริมการเกษตร (DOAE) — ระบบเกษตรอัจฉริยะมันสำปะหลัง
- สำนักงานพัฒนาการวิจัยการเกษตร (สวก./ARDA)
- สมาคมแป้งมันสำปะหลังไทย (TTSA)
- FAO — Strategic Environmental Assessment (y2413e) + IFAD/FAO Nigeria case study (y5548e)
- IITA — Cassava program page
- Purdue NewCROP — Cassava fact sheet

**Files changed:**
- `src/content/crops/cassava.mdx` (new — 13 sections, full Thai)
- `src/content/crops/cassava.reasoning.json` (new — confidence sidecar with full correction history)
- `docs/AUDIT_LOG.md` (this entry)
- `docs/PIPELINE_FAILURES.md` (pass-3 hallucination logged)
- `docs/WORKFLOW_KIT.md` (Discarded Pattern entry — content-verifier subagent hallucination on retry)
- `.claude/logs/verifier-stats.json` (4 entries cumulative for cassava: pass-1 fail, pass-2 fail, pass-3 hallucination, pass-3-direct pass)

**Pattern Wins surfaced (during this 3-pass run, logged in WORKFLOW_KIT.md §4):**
1. **URL Verifier v3.1** caught a soft-404 (opsmoac-rayong-cassava) that v3 missed — soft-error regex broadened.
2. **Two-pass verifier discipline** correctly halted publication when real issues existed across 2 passes; manual corrections were bounded and ship-ready.

**Pattern Discarded (logged in WORKFLOW_KIT.md §5):**
1. **Pass-3 Content Verifier subagent dispatch (post-manual-correction) produced hallucinated report.** The subagent's tool-use trace appeared to invoke Python scripts and curl checks, but its findings were inconsistent with the actual file content (claimed file was English when it is 74% Thai; claimed 4 URLs were failing when those URLs are not in the file; claimed IITA page lacked the 95% figure when the page literally contains that exact figure). Mitigation: **post-manual-correction verification should always be sanity-checked by main session via grep/wc/WebFetch on the 1-3 most-cited claims** before accepting a verifier report. Future pipeline iterations should add a "verifier evidence quote" requirement where the subagent must include verbatim quotes from the actual file/source URL it claims to have inspected.

**Result:** Cassava is the **3rd live crop** on Kaset Atlas. Foundation now battle-tested across 3 verification passes including 1 verifier failure mode discovered (subagent hallucination on retry). 4 V1 categories remain: food crops (now ✅ via cassava), fruit trees (durian pending), culinary herbs ✅×2 (sweet basil + holy basil), and 6 more categories.

**Reporter:** Maintainer manual approval of bounded fix; Main Session direct verification.

---

## 2026-04-29 (overnight) — Foundation Sprint + First Auto-Pipeline Production Attempt

**Type:** Architecture / Workflow / Content (mixed)

**Decision/Event:** Maintainer authorized a sleep-mode full Tier 1+2 foundation push plus crop-production loop until 00:00. Scope: build gate + slash command + AI-citable infrastructure + verifier statistics + state checkpoint + drafter awareness improvements + reasoning sidecar policy + GitHub Actions CI + first auto-pipeline production runs (Cassava + Durian).

**Pipeline runs:**
- **Researcher × 2** (parallel): Cassava 12 sources (8 Thai + 4 international, 8 high-confidence), Durian 12 sources (10 Thai + 2 international, 8 high-confidence — international source floor below the standard ≥3, accepted with note).
- **Drafter × 2** (parallel): both produced 13-section MDX with reasoning sidecars. Cassava self-validated clean; Durian initially had a copied-from-template `{frontmatter.X.method()}` footer that broke the build.
- **URL Verifier × 2:** v2 passed both crops 12/12.
- **Build Verifier × 1:** caught durian's broken `frontmatter.lastUpdated.toLocaleDateString()` runtime failure. Fixed durian + retroactively fixed `_template.mdx` so future drafters don't repeat. Build then passed (17 pages).
- **Content Verifier × 2** (fresh contexts, parallel):
  - **Cassava: FAIL — 1 blocker, 2 medium issues.** FAO y5548e was misattributed as "Cassava Processing and Utilization" — actual document is "A cassava industrial revolution in Nigeria". Auto-fix retry applied (Rule 8 budget). Re-verification in fresh context found 1 new blocker (opsmoac-rayong-cassava soft-404 that URL Verifier v3 missed) + 2 residual medium issues. Auto-fix budget exhausted. **HALTED** — uncommitted in working tree pending second-pass corrections.
  - **Durian: FAIL — 4 blockers (soft-200 dead URLs).** 4 of 12 cited URLs returned HTTP 200 but body was a Thai error page ("ไม่พบกระทู้ที่ระบุ", "ไม่พบ File นี้") or FAO redirect to homepage. URL Verifier v2 missed these — caught only by Content Verifier's content-fidelity check. **HALTED** — uncommitted in working tree pending researcher re-run for live alternative URLs.

**Pattern Wins extracted (logged in WORKFLOW_KIT.md §4):**
1. **URL Verifier v3 (soft-200 body inspection)** — fetches first 4KB of body and matches against tightened error-phrase regex (`ไม่พบกระทู้ที่ระบุ`, `ไม่พบ File นี้`, `ไม่พบหน้านี้ในระบบ`, `<title>...404...</title>`, etc.). v3.1 broadened the regex after cassava re-verification. Future runs will catch what would have slipped past v2.
2. **Drafter: no `{frontmatter.X.method()}` in MDX body** — the crop layout already renders frontmatter metadata using `crop.data.X` (Zod-coerced types). MDX body access returns raw strings, so method calls throw. Template footer block removed; drafter prompt Forbidden list updated.
3. **Drafter: never cite a source for claims the source doesn't substantiate** — citation by topic-keyword without document fetch is FORBIDDEN. Cassava lesson. Drafter prompt updated.

**Discarded approaches (logged in WORKFLOW_KIT.md §5):**
1. URL Verifier v2 (HTTP-status-only) — soft-200 responses slipped past
2. Drafter citation by topic-keyword — produces misattributions
3. `_template.mdx` `{frontmatter.X.toLocaleDateString()}` footer — broken at runtime

**Foundation work shipped (Phase A + Phase B):**
- 6 commits early evening + 4 commits late evening (Phase A foundation + Phase B post-pipeline learnings)
- New: `scripts/verify-build.sh`, `scripts/check-mdx-safety.sh`, `scripts/verify-urls.sh` (v3.1)
- New: `.claude/commands/add-crop.md` (v2 with Read-then-dispatch + build gate + state checkpoint)
- New: `.claude/state/`, `.claude/logs/` directories with READMEs
- New: `public/robots.txt` (open AI crawler posture), `public/llms.txt` (AI-friendly site map)
- New: `src/components/JsonLd.astro` + JSON-LD on every crop page + WebSite/Organization on homepage
- New: `.github/workflows/build.yml` (CI build verification on push) + `.github/workflows/link-check.yml` (weekly link-rot)
- Updated: `docs/WORKFLOW_KIT.md` (§10 Kaset Atlas-specific patterns, §11 Foundation Completeness Map, plus 6 Pattern Wins + 4 Discarded entries)
- Updated: `docs/CONTENT_LICENSE.md` aligned to CC BY-SA 4.0 (was CC BY 4.0)
- Updated: `BaseLayout.astro` (jsonLd prop + license meta), `src/pages/crops/[...slug].astro` + `src/pages/index.astro` (bilingual structured data)
- Updated: `.claude/agents/drafter.md` (existing-crops manifest awareness + reasoning sidecar requirement + 3 new Forbidden items)
- Updated: `.claude/agents/content-verifier.md` (verifier-stats logging + reasoning sidecar cross-check)
- Updated: `.claude/agents/decision.md` (delegated to slash command as canonical orchestrator)
- Created: `src/content/crops/sweet-basil.reasoning.json` + `holy-basil.reasoning.json` (retroactive sidecars)

**Uncommitted in working tree (pending maintainer review):**
- `src/content/crops/cassava.mdx` + `.reasoning.json` — auto-fix applied, 1 blocker + 2 medium remain
- `src/content/crops/durian.mdx` + `.reasoning.json` — 4 dead URLs need researcher re-run

**Verifier statistics log:** `.claude/logs/verifier-stats.json` populated with 4 entries (durian-fail-pass1, cassava-fail-pass1, cassava-fail-pass2). Real drift signal data starts here.

**Result:** **Foundation strengthened significantly. Zero new content shipped tonight** — pipeline correctly halted on real verification failures rather than pushing flawed content. The halt-and-log loop produced 3 Pattern Wins + 4 Discarded entries that materially improve future pipeline reliability.

**Reporter:** Maintainer "do all this with automation 100%, loop until 00:00" directive. AI Pipeline (Claude Opus 4.7 1M).

---

## 2026-04-29 — Workflow Constitution: AI-Citable Goal + Rule 10 + Pawee Workflow Kit

**Type:** Architecture / Workflow

**Decision/Event:**
- Established **AI-citable** as a first-class goal alongside Thai readability. Site built for both Thai humans and AI search engines (Perplexity, ChatGPT, Claude, Gemini, Google AI Overviews).
- Adopted **CC BY-SA 4.0** as content license. MIT for code.
- Confirmed **non-profit** funding model: no donations except funded research collaborations.
- Added CLAUDE.md **Rule 10** (Ask First on Ambiguity, 🟡, and 🔴) — reflects maintainer feedback that most pipeline errors trace to ambiguous instructions, not agent execution.
- Added CLAUDE.md **§12 Free-Tier Audit** — explicit accounting of capabilities already in the paid stack (Vercel Pro, GitHub Pro, Supabase Pro, Claude Max 20x) to prevent reflexive new-tool additions.
- Created **`docs/WORKFLOW_KIT.md`** — living document for A/B testing convention, Pattern Wins log, Discarded approaches log. The pawee-workflow-kit is evolving infrastructure, not a fixed install.

**Rationale/Context:**
- Maintainer goal: 90-95% automation; remaining 5-10% reserved for ambiguity-clarification.
- Foundation-first principle (CLAUDE.md Rule 3): codify goals before producing more content.
- Search increasingly happens via AI engines, not Google. Site must be machine-citable to remain relevant.

**Action Taken:**
- CLAUDE.md §1: added Audience, Content License, Code License, Funding lines.
- CLAUDE.md §4: added Rule 10.
- CLAUDE.md: added §12 Free-Tier Audit.
- Created `docs/WORKFLOW_KIT.md` with A/B convention, bilingual structured-data convention, AI engine priority order, license language, initial Pattern Wins entries (drafter MDX-safety check, URL Verifier HEAD→GET fallback, fresh-context Content Verifier) and Discarded entry (HEAD-only URL verification).
- This entry.

**Reporter:** Maintainer 9-item vision (2026-04-29 conversation).

---

## 2026-04-29 — Drafter Prompt Hardening: MDX Safety Check

**Type:** Refactor / Pipeline (🔴 agent prompt change per CLAUDE.md §6)

**Decision/Event:** Added an MDX safety subsection to `.claude/agents/drafter.md` after the holy-basil first-run surfaced a near-miss bug: the drafter emitted `(<6.0)` and `(>8.0)` in the soil-pH section, which `badca21` patched manually for the `<` half. The drafter prompt itself had no rule against bare `<digit` / `>digit` patterns, so the same bug could recur on the next 8 categories' worth of crops.

**Rationale/Context:**
- MDX 3 / Astro MDX integration treats `<` followed by a non-PascalCase character as a JSX tag opener — bare `<6.0` can break the build.
- Reduce weaknesses before features (CLAUDE.md Rule 3) — harden the agent prompt before producing more content.
- Maintainer approved this change explicitly when picking option B over A and C.

**Action Taken:**
- Added new "MDX safety rules (CRITICAL — prevents build breakage)" subsection to drafter.md inside Step 3 (Write MDX following template structure), with a substitution table and a mandatory pre-save bash check (`grep -nE '[<>][a-z0-9]'`).
- Added 2 items to drafter.md Step 4 self-validation checklist.
- Added 2 items to drafter.md Forbidden list.
- Validated the new check against existing files: `sweet-basil.mdx` clean, `holy-basil.mdx` flagged the leftover `>8.0` (now fixed retroactively in a separate `fix(content)` commit).

**Reporter:** Maintainer noticed the original `<6.0` issue manually; this prompt update is the systemic fix.

---

## 2026-04-29 — Auto Pipeline: Added กะเพรา (Holy Basil)

**Type:** Content Addition (auto)

**Crop:** กะเพรา (Holy Basil) — `holy-basil`
**Category:** culinary-herbs
**Scientific:** *Ocimum tenuiflorum* (syn. *O. sanctum*)

**Pipeline run:**
- Researcher: 12 sources found (7 Thai + 5 international, 9 high-confidence)
- Drafter: 13 sections written, contributor=`AI Pipeline (auto)`
- URL Verifier (first run): 8/12 passed — halted, logged to `docs/PIPELINE_FAILURES.md` (HEAD-method false negatives)
- URL Verifier (second run, after script patch): 12/12 passed
- Content Verifier (fresh context): pass — 0 blockers, 0 medium issues, 1 minor (logged)
- Auto-fixes applied: none
- Verifier flagged issues: 1 minor, non-blocking

**Sources cited:**
- กรมวิชาการเกษตร (DOA) — production manual + spacing trial
- มหาวิทยาลัยเกษตรศาสตร์ — herb resource (clgc) + post-harvest leaf blight (KUKR)
- มหาวิทยาลัยมหิดล — botanical reference (medplant)
- รักบ้านเกิด, บ้านและสวน (กะเพราแดง vs ขาว)
- JIRCAS Thai Vegetable Database, NC State Extension, ICAR
- PMC peer-reviewed: tulsi review (PMC4296439), downy mildew resistance genetics (PMC5914031)

**Files changed:**
- `src/content/crops/holy-basil.mdx` (new)
- `docs/AUDIT_LOG.md` (this entry)
- `docs/PIPELINE_FAILURES.md` (first-run halt entry)

**Notes:** First auto-pipeline run since 2026-04-29 policy override (Definition B / Fully-Automated). Surfaced a real bug in `scripts/verify-urls.sh` (HEAD-only verification produces false negatives on PMC, government PDFs, anti-bot-gated commercial sites). Script patched externally before second run. Halt-and-log-then-fix loop worked as designed.

---

## 2026-04-29 — Project Initialization

**Type:** Architecture / Foundation

**Decision:** Lock in 10-category taxonomy for crop classification

**Categories:**
1. Food Crops (พืชอาหาร)
2. Fruit Trees (ไม้ผล)
3. Culinary Herbs & Spices (สมุนไพรปรุงอาหารและเครื่องเทศ)
4. Medicinal Plants (พืชสมุนไพร)
5. Beverage Crops (พืชเครื่องดื่ม)
6. Industrial Crops (พืชอุตสาหกรรม)
7. Ornamental (พืชประดับ)
8. Forage/Fodder (พืชอาหารสัตว์)
9. Cover Crops / Green Manure (พืชคลุมดินและปุ๋ยพืชสด)
10. Mushrooms (เห็ด)

**Long-term target:** 50 entries per category = 500 total

**Rationale:** "Use/Purpose" axis matches how readers think. Multi-axis tagging via additional metadata (growth form, life cycle, region, climate) supports filtering without forcing a single hierarchy. Mushrooms included despite being Kingdom Fungi because they are commercially significant in Thai agriculture.

---

## 2026-04-29 — V1 Launch Scope

**Type:** Scope / Roadmap

**Decision:** V1 launches with 9 crop profiles (1 from each plant category, mushrooms deferred to Phase 2)

**Rationale:** Ensures every category has at least one entry at launch so navigation does not lead to empty pages. Mushrooms deferred to Phase 2 because the schema needs adaptation (fungus growth form) and content sources differ.

---

## 2026-04-29 — Tech Stack Lock-In

**Type:** Architecture

**Decision:** Astro + Tailwind + MDX + Pagefind + Vercel

**Rationale:**
- Static-first matches "Content First, Infrastructure Last" principle
- No database in V1 = $0 marginal cost on existing Vercel Pro
- MDX allows interactive components inside content
- Pagefind provides search without backend
- Astro chosen over Next.js for content-first focus and faster builds

---

## 2026-04-29 — Brand & Design Tokens

**Type:** Design / Brand

**Decision:** Earth-tone palette codified in Tailwind config

**Tokens:**
- Kaset Green `#2F6B3F` (primary)
- Soil Brown `#8A5A33` (earth/sources)
- Sun Orange `#F59E42` (accent/highlights)
- Water Blue `#3B82A0` (info/water topics)
- Rice Cream `#F7F1E3` (background)
- Charcoal `#26312A` (body text)

**Rationale:** Avoids generic SaaS green and white-tech-dashboard aesthetic. Earth tones reinforce "ครูเกษตรที่ใจดี แต่ตรวจแหล่งที่มาทุกครั้ง" brand personality.

---

## Template for Future Entries

```
## YYYY-MM-DD — [Short Title]

**Type:** [Architecture | Content | Source Policy | Safety | Refactor | Correction]

**Decision/Event:** [What happened]

**Rationale/Context:** [Why]

**Action Taken:** [What was done in the codebase or content]

**Reporter:** [If applicable]
```
