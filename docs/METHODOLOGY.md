# Methodology — Kaset Atlas

> How we research, write, and verify agricultural content.

---

## 1. Per-Crop Workflow

### Step 1: Define the Crop
- Confirm Thai name and all common variants
- Confirm scientific name (genus species)
- Confirm category from the 10-category taxonomy
- Search for alternative/local names

### Step 2: Source Discovery
Cast wide net first, then filter:

**Thai sources (priority):**
- กรมวิชาการเกษตร (doa.go.th)
- กรมส่งเสริมการเกษตร (doae.go.th)
- กรมพัฒนาที่ดิน (ldd.go.th)
- มหาวิทยาลัยเกษตรศาสตร์, แม่โจ้, เชียงใหม่ extension materials
- สวก. (อาร์ดี — สำนักงานพัฒนาการวิจัยการเกษตร)

**International sources:**
- FAO publications (fao.org/publications)
- Wageningen University, UC Davis, Cornell extension
- CABI Crop Protection Compendium
- Open-access journals (DOAJ, ScienceDirect open access)

**Tools:**
- Google Scholar (filter to recent + cited)
- DOAJ (Directory of Open Access Journals)
- BASE (Bielefeld Academic Search Engine)
- Claude (for source discovery and synthesis — never as a source itself)

### Step 3: Source Triage
- Eliminate seller sites with promotional content
- Eliminate undated forum posts
- Mark each source with confidence level (see SOURCE_POLICY.md)
- Add source to `src/content/sources/` registry with all required metadata

### Step 4: Fact Categorization
Organize raw notes into the 12-section template:

1. Quick Summary
2. Can grow in Thailand?
3. Climate requirements
4. Soil requirements
5. Water and irrigation
6. Planting method
7. Care and management
8. Pests and diseases
9. Harvesting
10. Economics and risk
11. Thailand-specific notes
12. International knowledge notes

### Step 5: Translation + Localization
For foreign sources:
- Summarize in Thai (do not copy-paste)
- Add Thailand applicability rating per claim
- Flag claims that may not transfer:
  - Temperate climate → tropical mismatch
  - Different soil pH baseline
  - Different pest pressure
  - Different cultivars

### Step 6: Confidence Labeling
For each section, assign:
- 🟢 High — multiple high-confidence sources agree
- 🟡 Medium — single high-confidence source OR multiple medium sources
- 🟠 Low — only low-confidence sources OR significant disagreement
- ⚪ Uncertain — no good source found yet

### Step 7: Safety Pass
Walk the entire profile against `SAFETY_POLICY.md`:
- Remove specific chemical dosages
- Add warning boxes where required
- Replace "you should" with "research suggests" where evidence is weak
- Add "consult expert" prompts for risk areas

### Step 8: Source Table
Build the source table at the bottom:

```md
| Section | Source | Type | Date | Confidence |
|---------|--------|------|------|------------|
| Climate | [DOA Basil Guide] | Thai Gov | 2024-03 | High |
| Soil    | [FAO Spice Manual] | Int'l Org | 2019 | High |
```

### Step 9: Frontmatter Completion
Fill all required fields per `src/content/config.ts`:
- `lastUpdated` — today's date
- `publishedAt` — first publication date
- `confidenceOverall` — weakest-link rating
- `contributor` — who wrote it
- `reviewer` — if peer-reviewed by another person

### Step 10: Publish
- Open PR
- Self-review against this checklist
- Merge to main
- Vercel auto-deploys

---

## 2. Update Cadence

- **No minimum cadence required** — quality over quantity
- **Aim for substantive update if 12+ months pass** without revision
- **Immediate update if** a high-confidence source contradicts existing content

---

## 3. Translation Standards

### Tone
- Friendly, like a teacher
- Clear, like extension material
- Cautious, like a scientist
- Not bureaucratic, not informal

### Vocabulary
- Use common Thai agricultural terms
- Define technical terms in glossary on first use
- Provide English/scientific name in parentheses for technical terms
- Avoid loanwords when good Thai equivalents exist

### Quoting
- Direct quotes only for legally significant or precisely worded claims
- Always under 30 words per quote
- Always with citation immediately following
- Never more than one quote per source per page

---

## 4. Use of AI

AI assistants (including Claude) may be used for:

✅ Allowed:
- Source discovery (then verify each source manually)
- Initial summarization (then verify against original)
- Translation drafts (then refine for Thai readability)
- Structuring outlines
- Glossary explanations
- Comparing multiple source claims
- Finding contradictions between sources

❌ Not allowed:
- Publishing AI output without human verification
- Citing AI as a source
- Using AI for chemical/dosage/medical recommendations
- Using AI to "fill in" missing information

Rule: **AI can assist, but sources decide.**

---

## 5. Quality Checks

Before publishing, every page must pass:

- [ ] Every section has at least one source OR is labeled uncertain
- [ ] All foreign sources have Thailand applicability notes
- [ ] No sections trigger Safety Policy refusals
- [ ] Source table is complete
- [ ] `lastUpdated` is today
- [ ] No copy-pasted paragraphs from sources
- [ ] Mobile-readable (test on phone before publishing)
- [ ] Thai prose flows naturally (read aloud test)

---

## 6. Correction Workflow

When a reader reports an error:

1. Acknowledge in GitHub Issue within 7 days
2. Verify the correction against sources
3. If confirmed: update content, increment `lastUpdated`, log in `AUDIT_LOG.md`
4. If disputed: open public discussion in issue
5. Credit reporter unless they request anonymity

---

## Last Updated

2026-04-29 — Initial version
