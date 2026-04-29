# Audit Log — Kaset Atlas

> Architectural decisions, source policy changes, content removal/correction events, and major refactors.

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
