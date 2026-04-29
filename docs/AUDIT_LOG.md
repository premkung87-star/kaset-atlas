# Audit Log — Kaset Atlas

> Architectural decisions, source policy changes, content removal/correction events, and major refactors.

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
