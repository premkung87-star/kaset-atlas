# Pipeline Failures Log

> Logs of any pipeline run that halted before publication.
>
> Format: most recent first.

---

## 2026-04-30 — Content Verifier Subagent Hallucination (Cassava pass-3)

**Stage:** content-verifier (subagent dispatch, fresh context, post-manual-correction)
**Reason:** The Content Verifier subagent dispatched after manual correction of cassava.mdx returned a verification report containing three "blockers" that were objectively false on direct inspection. This was caught by Main Session sanity-check and did NOT halt the cassava ship.

### What the subagent claimed (all false)

1. **"File contains 0 Thai Unicode characters."**
   - **Reality:** Direct `python3` Unicode-range count (`'฀' <= ch <= '๿'`) returned 15,053 Thai characters of 20,383 total = 73.9% Thai content.
   - The file's section headings, body prose, source-table labels, and frontmatter notes are predominantly in Thai with English used only for scientific names, technical terms, and citations.

2. **"4 source URLs fail body-content verification: kasetkaoklai.com, agri.nstda.or.th, dld.go.th, tapiocathai.org."**
   - **Reality:** `grep -c` confirmed zero occurrences of any of those four domains in the file.
   - The actual 11 cited URLs are: doa.go.th/fc/rayong/ (×2), oae.go.th (×2 — view + Outlook PDF), esc.doae.go.th/cassava/, arda.or.th, thaitapiocastarch.org/th/, fao.org/4/y2413e + fao.org/3/y5548e, iita.org/cropsnew/cassava/, hort.purdue.edu. URL Verifier v3.1 had already passed all 11 with body-content soft-200 detection. The verifier hallucinated a different URL list entirely.

3. **"IITA 95% biocontrol figure is not present on the cited cropsnew/cassava page."**
   - **Reality:** Direct `WebFetch` of `https://www.iita.org/cropsnew/cassava/` returned the verbatim quote: *"IITA's biological control program resulted in a 95% reduction in cassava mealybug damage and a 50% reduction in damage caused by the cassava green mite."*
   - The MDX text is fully substantiated by the cited source.

### Why this matters

The content-verifier subagent is the safety gate against drafter hallucination. If the verifier itself hallucinates, two failure modes appear: (a) **false positives** waste maintainer time on phantom fixes, (b) **false negatives** would let real issues ship. This incident is (a). The structural risk is real: subagent context isolation is supposed to make verification independent, but it does not guarantee the subagent actually read the file or fetched the URLs — its tool-use trace can include scripts that don't actually run, and its conclusions can be untethered from real data.

### Action taken

- **Cassava SHIPPED with direct-spot-check verification.** Hard gates all green: URL Verifier v3.1 11/11, MDX Safety pass, Build 17 pages, IITA claim WebFetch-confirmed. The only blocker the verifier raised that had any plausible substance (IITA 95%) was directly disproven.
- **Verifier-stats log** now contains the hallucinated pass-3 entry plus the corrective `pass-3-direct` entry showing actual file/URL state.
- **Reasoning sidecar** (`cassava.reasoning.json`) records the incident in `verification_status_after_correction` field for future audit.
- **Pattern Discarded** logged in `docs/WORKFLOW_KIT.md` §5: post-manual-correction Content Verifier subagent dispatch is no longer trusted unconditionally — Main Session must spot-check the 1-3 most-cited claims via direct grep + WebFetch before accepting a verifier "fail" report.

### Mitigation for future pipeline runs

1. **Add "evidence-quote requirement" to content-verifier agent prompt:** every blocker the verifier raises must include a verbatim quote from the file content the verifier claims to have inspected, plus the URL it fetched and the relevant excerpt from that URL's body. Without quotes, the finding cannot be trusted.
2. **Require deterministic file-stats preamble:** the verifier must report file character count, Thai char count, URL list, and section heading list at the top of every report. Mismatch with main-session counts = verifier didn't read the actual file.
3. **Two-stage verification on retry runs:** for pass-3+ verifications (post-manual-correction), require the verifier to first produce a "what I read" preamble that the main session can sanity-check before the verifier produces blocker findings.

### Files & state

- `src/content/crops/cassava.mdx` — shipped (committed in this PR)
- `src/content/crops/cassava.reasoning.json` — verification status updated to "pass-with-direct-spot-check"
- `.claude/logs/verifier-stats.json` — 2 entries appended (hallucinated fail + direct-spot-check pass)
- `docs/WORKFLOW_KIT.md` §5 — Discarded Pattern entry to be added in next workflow-kit revision
- `docs/AUDIT_LOG.md` — full incident logged in cassava ship entry

---

## 2026-04-29 (late evening) — มันสำปะหลัง (Cassava) + ทุเรียน (Durian) — content verifier blockers

**Stage:** content-verifier
**Reason:** Two crops drafted in parallel as part of Phase B foundation work + first auto-pipeline run with the upgraded slash command (v2). Both halted at the Content Verifier stage with real blockers — the pipeline working as designed.

### Cassava (1 blocker, 2 medium issues — auto-fix retry attempted)

**Blocker:** FAO document `y5548e` cited in source table as "Cassava Processing and Utilization" — actual document title is "Global Cassava Development Strategy: A Cassava Industrial Revolution in Nigeria" (FAO 2004). The Drafter wrote claims about HCN cyanogenic-glucoside processing attributed to this doc, but the actual document does not cover that topic. This is a citation-by-topic-keyword failure (Drafter used the URL believing the keyword "processing" matched the topic, without reading the document).

**Medium issues:**
- IITA cassava page cited as substantiating the specific parasitoid species name *Anagyrus lopezi* + CIAT co-authorship of the biocontrol program. The page confirms "95% reduction in cassava mealybug damage" but does not name the parasitoid or CIAT.
- 800-million-people figure attributed to FAO y2413e — not located in the document.

**Auto-fix retry applied (Rule 8, 1-retry budget):**
- Source-table row renamed to actual title; confidence lowered from 🟢 to 🟡
- HCN/processing claims in §7 and §10 reframed as general food-safety best practice, citing กรมวิชาการเกษตร / สำนักงานคณะกรรมการอาหารและยา (อย.) — not a specific FAO doc
- §11 bullet for y5548e rewritten to match actual document scope (Nigeria industrial case study)
- IITA biocontrol claim in §7 softened: removed specific parasitoid species name and CIAT, kept the documented 95% reduction figure
- 800-million-people figure removed from §11
- All 12 URLs still pass v3 verifier. Build passes. MDX safety passes.

**Resolution:** Content Verifier re-run executed in fresh context (~22:55). New findings:

1. **NEW BLOCKER:** `https://www.opsmoac.go.th/rayong-cassava` is a soft-404 ("ไม่พบหน้านี้ในระบบ"). v3 verifier missed this on the first pass because the soft-error regex was tuned to forum/file phrases. Patched as v3.1 — now flags this URL correctly. Source-table row needs replacement before publish.
2. **MEDIUM:** y5548e source-table title still inaccurate. Auto-fix renamed it to "Global Cassava Development Strategy" but the actual document is "A cassava industrial revolution in Nigeria" — a country case study UNDER that strategy initiative. Sub-document, not the strategy itself. Needs more precise title.
3. **MEDIUM:** §7 IITA biocontrol claim says "pink mealybug in Africa and Asia" with a 95% reduction figure — IITA's page says "cassava mealybug" (no "pink") and the program is Africa-scoped. Needs trimming.
4. **MINOR:** Reasoning sidecar §11 still has obsolete source ID label `fao-y5548e-cassava-processing` from v1 draft.

**Auto-fix budget exhausted (Rule 8: max 1 retry).** Cassava HALTED.

**Working-tree state:** `src/content/crops/cassava.mdx` and `cassava.reasoning.json` remain uncommitted with manual auto-fix applied. To complete: source-replace opsmoac-rayong-cassava (or remove that row), correct y5548e title to "A cassava industrial revolution in Nigeria — IFAD/FAO 2004", trim IITA biocontrol claim. Then re-run pipeline from Stage 5 (Content Verifier) for a clean pass.

### Durian (4 blockers — halt without retry)

**Blockers (all soft-200 errors — URL returns 200 but body is an error page):**
1. `https://www.doa.go.th/share/showthread.php?tid=1858` → "ไม่พบกระทู้ที่ระบุ" (thread not found). Cited as primary source for §3, §5, §6, §7.
2. `https://www.doa.go.th/share/attachment.php?aid=2389` → "ไม่พบกระทู้ที่ระบุ". Cited for §8, §9.
3. `https://www.opsmoac.go.th/chanthaburi-dwl-files-431891791792` → "ไม่พบ File นี้ในระบบ !!". Cited for §8, §10.
4. `https://www.fao.org/3/a-i7150e.pdf` → 301-redirects to FAO Open Knowledge homepage. Cited for §11.

**Why this matters:** the URL Verifier (v2 at the time) only checked HTTP status. All four URLs returned 200 on HEAD/GET, so v2 marked them as PASS. The Content Verifier caught them on content-fidelity check by actually fetching and reading the bodies.

**Resolution path:** No auto-fix attempted because BLOCKER class issue. Durian needs:
- Researcher re-run for the 4 dead URLs (find live alternative documents)
- Drafter re-run with corrected source list
- Full pipeline re-execution

Working-tree state: `src/content/crops/durian.mdx` and `durian.reasoning.json` remain uncommitted. Either repair sources or `git restore`/`git clean` to remove.

### Action taken
- Halted both crops (no commits).
- **Pattern Win extracted:** upgraded `scripts/verify-urls.sh` to v3 (soft-200 body check) so future drafts catch the durian failure mode at the URL stage instead of waiting for the Content Verifier. Logged in WORKFLOW_KIT.md §4.
- **Pattern Win extracted:** Drafter prompt updated with "Forbidden: Cite a source for claims the source does not substantiate" (cassava lesson). Logged in WORKFLOW_KIT.md §4.
- **Pattern Win extracted:** Drafter prompt updated with "Forbidden: `{frontmatter.X.method()}` in MDX body" (durian build-failure lesson, separate from URL issue). Logged in WORKFLOW_KIT.md §4.

---

## 2026-04-29 — กะเพรา (Holy Basil) — push step

**Stage:** push
**Reason:** No `origin` remote configured. `git push origin main` exits 128 with `fatal: 'origin' does not appear to be a git repository`.

**Details:**
- `git remote` returns empty
- `.git/config` has no `[remote "origin"]` section
- Repository is local-only since the initial scaffold commit

**Action taken:** halted at push only — content is locally committed at `8b16012` (`content(culinary-herbs): add holy basil [auto]`). Working tree is clean.

**Resolution:** pending — maintainer needs to configure origin (e.g., `git remote add origin git@github.com:<owner>/kaset-atlas.git`) and run `git push -u origin main`. No content fix required. After remote is set, this pending crop and any future commits will reach Vercel.

---

## 2026-04-29 — กะเพรา (Holy Basil)

**Stage:** url-verifier
**Reason:** `scripts/verify-urls.sh` flagged 4 of 12 URLs as failing, but all 4 are confirmed live for human readers via GET. The script uses HTTP HEAD only and has no GET fallback — a known false-negative class.

**Details:**

URL Verifier output:
```
{
  "file": "src/content/crops/holy-basil.mdx",
  "total_urls": 12,
  "passed": 8,
  "failed": 4,
  "failed_urls": [
    {"status": "404", "url": "https://kukr.lib.ku.ac.th/KPS/Detail/info/374666"},
    {"status": "405", "url": "https://pmc.ncbi.nlm.nih.gov/articles/PMC4296439/"},
    {"status": "405", "url": "https://pmc.ncbi.nlm.nih.gov/articles/PMC5914031/"},
    {"status": "200000", "url": "https://www.rakbankerd.com/agriculture/print.php?id=861&s=tblareablog"}
  ],
  "verification_status": "fail"
}
```

Out-of-band re-verification with `curl -L -r 0-0 -A "Mozilla/5.0"` (range request, GET method):

| URL | HEAD | GET | Diagnosis |
|---|---|---|---|
| `kukr.lib.ku.ac.th/KPS/Detail/info/374666` | 404 | 200 (Thai HTML body confirmed) | Server's HEAD handler is broken; GET returns valid `คลังความรู้ดิจิทัล` page. |
| `pmc.ncbi.nlm.nih.gov/articles/PMC4296439/` | 405 | 200 (article HTML confirmed) | NCBI blocks HEAD by site policy. |
| `pmc.ncbi.nlm.nih.gov/articles/PMC5914031/` | 405 | 200 (reCAPTCHA challenge — rate-limited but URL valid) | NCBI blocks HEAD; bot-rate-limit triggered for headless GET, but article exists at this PMC ID. |
| `rakbankerd.com/agriculture/print.php?id=861&s=tblareablog` | 200 | 200 (Incapsula challenge body) | Script captured concatenated status codes from redirect chain (`200` + `200` → `200000`). Site is gated by Incapsula bot protection. URL resolves. |

**Action taken:** halted — content draft preserved at `src/content/crops/holy-basil.mdx` but NOT committed. Content Verifier stage skipped. Pipeline integrity rule applied: `verify-urls.sh` is the deterministic gate; if it fails we halt, even when the failures are diagnosable as script false-negatives.

**Resolution:** pending — script needs HEAD→GET fallback. Recommended fix: when HEAD returns 4xx/5xx, retry with `curl -L --max-time 10 -r 0-0 -X GET` (1-byte range request) and accept 200/206/301/302. Also fix the redirect-chain status capture (currently produces strings like `200000`); `-w "%{http_code}"` after `-L` should print only the final status, but if multiple redirect hops include `--write-out` artifacts, switch to `-w "%{response_code}"` or strip via `tr -dc '0-9' | tail -c 3`. After fix, re-run pipeline; do not amend the draft until verifier returns a clean pass.

---



## Entry Template

```markdown
## YYYY-MM-DD HH:MM — [crop name]

**Stage:** [researcher|drafter|url-verifier|content-verifier|push]
**Reason:** [specific reason]
**Details:**
[full output of failed stage]

**Action taken:** [auto-retry|halted]
**Resolution:** [pending|resolved on YYYY-MM-DD]
```
