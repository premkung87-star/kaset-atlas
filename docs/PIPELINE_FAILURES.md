# Pipeline Failures Log

> Logs of any pipeline run that halted before publication.
>
> Format: most recent first.

---

## 2026-04-30 — Lettuce / ผักกาดหอม: researcher final response refused by Usage Policy

**Stage:** researcher (final synthesis response, post tool-use)
**Run ID:** `2fbd636f-d739-4e75-b145-d22a637f9a6a`
**Failure type:** `policy-refusal`
**Crop input:** lettuce / ผักกาดหอม
**Dispatch mode:** general-purpose-only (Tier 1.4)

### What happened

- Researcher subagent ran tool calls successfully (~44 tool_use events observed before refusal).
- The subagent's **final synthesis response** triggered an Anthropic Usage Policy refusal, so no JSON source list ever reached the pipeline.
- Pipeline checkpoint shows `stage_completed: "preflight"` only — no researcher-output JSON, no draft, no MDX, no reasoning sidecar were written.

### Artifacts state

- `src/content/crops/lettuce.*` — none
- `.claude/state/researcher-output/lettuce*.json` — none
- `.claude/state/halted/...lettuce.../` — none prior; this run's checkpoint is now archived to `.claude/state/halted/2026-04-30-lettuce-usage-policy/`
- Working tree was clean at halt; no commits attempted.

### Action taken

- Logged this halt to `.claude/logs/verifier-stats.json` (`halt_stage=researcher`, `failure_type=policy-refusal`, `tool_use_count=44`).
- Archived `.claude/state/pipeline-current.json` → `.claude/state/halted/2026-04-30-lettuce-usage-policy/pipeline-current.json` so the next `/add-crop` run starts from clean state.
- **No prompt or pipeline-script change.** N=1 for this failure mode — single observation does not justify editing `researcher.md` or pipeline scripts (Rule 10, Pattern Win threshold).

### Recommendation

Retry lettuce as a **fresh** `/add-crop` run, not a resume. Usage Policy refusals on a final synthesis response are typically non-deterministic at the model-output filter layer, so a re-run will likely succeed without any code change. If the same refusal recurs on a second lettuce attempt, escalate to investigate whether something specific in lettuce research output (e.g., a quoted source phrase) is the trigger — but only after observation N≥2.

---

## 2026-04-30 — Tomato (Option 1 diagnostic resume): Drafter emitted bare-Thai confidence cells (verify-source-table fail)

**Stage:** verify-source-table (Stage 2 structural gate, after Drafter)
**Run ID:** `69cf9cfa-5bc7-411f-9209-4c1cb6119682`
**Prior Run IDs:** `d7d3b9f3-...` (researcher self-flag), `92c14f76-...` (researcher subagent type Category A)
**Failure type:** `generation-contract` (Category C)
**Crop input:** tomato / มะเขือเทศ
**Diagnostic mode:** Option 1 — `general-purpose` dispatch substituted for `researcher`/`drafter` subagent types

### Major positive diagnostic finding (separate from this halt)

The Option 1 diagnostic confirmed: **`general-purpose` dispatch executes tool calls correctly** in this environment. Both Researcher and Drafter ran end-to-end with real tool execution:

| Stage | Subagent type | tool_uses | duration | Outcome |
|---|---|---|---|---|
| Researcher (prior run) | `researcher` (dedicated) | **0** | 22m32s | max_output_tokens cap; never invoked harness |
| Researcher (this run) | `general-purpose` | **38** | 6m | clean JSON, 12 sources, 4/4 spot-checked URLs HTTP 200 |
| Drafter (this run) | `general-purpose` | **26** | 4m46s | wrote tomato.mdx (36 KB) + tomato.reasoning.json (4.7 KB) |

The maintainer's hypothesis stands: the Category A failure mode is specific to the `researcher`/`drafter`/`content-verifier` dedicated subagent types in this project, not all subagent dispatch. The slash command's literal "Dispatch a `general-purpose` subagent" guidance is the working path.

### What halted Stage 2

`./scripts/verify-source-table.sh src/content/crops/tomato.mdx` returned `verification_status: fail` with 12 `missing_or_unrecognized_confidence` issues — every row of the source table.

The script (line 148) accepts confidence cells matching:
```
🟢|🟡|🟠|⚪|High|Medium|Low|Uncertain
```

The Drafter wrote 11 rows as bare Thai `สูง` and 1 row as bare `ปานกลาง`. No emoji, no English. The script's regex doesn't match bare Thai prose.

All three existing crops use the emoji-prefixed convention:
- `sweet-basil.mdx`: `🟢 สูง`, `🟡 ปานกลาง`
- `holy-basil.mdx`: `🟢 สูง`, `🟡 ปานกลาง`
- `cassava.mdx`: `🟢 สูง`, `🟡 ปานกลาง`

The Drafter's response did pass `self_validation_passed: true`, indicating the agent did not run the verifier itself before claiming completion. The drafter prompt's MDX-safety bash check is mandatory pre-save, but the source-table verifier check is not part of the drafter's self-validation list — that's by design (it's an external gate), but the drafter prompt does not explicitly state the confidence-cell format requirement either.

### Other Stage 2 gates (all passed)

| Gate | Result |
|---|---|
| `check-mdx-safety.sh` | pass — 0 unsafe patterns |
| `subagent-output-verify.sh --stage drafter` | pass — both files exist, mtime 1777537666/1777537700 after dispatch start, sizes 36040/4729 bytes ≥ 1024, tool_calls=26 |
| `verify-source-table.sh` | **fail** — 12 issues, see above |
| `verify-claim-grounding.sh` | pass — 11 sections, all with supporting_source_ids, 12 unique source IDs in sidecar matching 12 unique URLs in MDX |

The reasoning sidecar passes its v1 structural check. URL Verifier (Stage 3), Build Verifier (Stage 4), Content Verifier (Stage 5) were not run.

### Action taken

- HALTED before Stage 3 (URL Verifier). Per maintainer's "do not manually patch around the failure" directive, I did NOT edit `tomato.mdx` to insert emoji into the confidence cells.
- Preserved `src/content/crops/tomato.mdx` and `src/content/crops/tomato.reasoning.json` in the working tree (untracked) for maintainer review.
- Appended halt entry to `.claude/logs/verifier-stats.json` with `failure_type: generation-contract`, `halt_stage: verify-source-table`.
- Updated state checkpoint at `.claude/state/pipeline-current.json` with `halted_at_stage: verify-source-table`, `awaiting_maintainer_decision: true`.
- Logged this entry.

### Resolution: pending — for maintainer review

This is a small, low-risk drafter contract gap. Three options:

1. **Re-dispatch Drafter via `general-purpose`** with an explicit instruction in the prompt that confidence cells in the source table MUST use the emoji-prefixed format (`🟢 สูง`, `🟡 ปานกลาง`, `🟠 ต่ำ`, `⚪ ไม่แน่ใจ`) consistent with all three existing crops. The current `tomato.mdx` would be discarded and rewritten. ~5 min runtime cost. 🟢 low-risk.
2. **Edit `.claude/agents/drafter.md`** to add the confidence-cell format requirement to the source-table specification + the self-validation checklist. Then re-dispatch. Future drafts won't hit this gate. 🟡 medium-risk per CLAUDE.md §6 (agent-prompt change). Architect-mode preference.
3. **Manual surgical patch** — main session edits `tomato.mdx` to prefix all 12 confidence cells with the correct emoji per the per-source confidence in `tomato-resume2-success.json`. Then re-run from Stage 2 source-table gate forward. Fastest but violates "do not manually patch around the failure" directive without explicit approval.
4. **Halt tomato run** entirely. Discard `tomato.mdx` + `tomato.reasoning.json`.

**Architect-mode recommendation:** Option 2. The drafter prompt already lists confidence-emoji requirements in the body section (`🟢 🟡 🟠 ⚪ — apply per section heading`), but does not state the same requirement for the source-table column. Adding that one sentence prevents the failure on every future crop, not just tomato. Cost: 1-line prompt edit + 5-min re-dispatch.

### Evidence preserved

- `src/content/crops/tomato.mdx` (36040 bytes, untracked, 13 sections, 12-source table, all confidence cells in bare-Thai)
- `src/content/crops/tomato.reasoning.json` (4729 bytes, untracked, 11 sections with supporting_source_ids, valid JSON)
- `.claude/state/researcher-output/tomato-resume2-success.json` (already committed)
- `.claude/state/pipeline-current.json` (gitignored, frozen)
- `.claude/logs/verifier-stats.json` — halt entry with `run_id: 69cf9cfa-...`

---

## 2026-04-30 — Tomato (resume after researcher patch): Category A subagent tool-execution failure

**Stage:** researcher (re-dispatch with patched prompt)
**Run ID:** `92c14f76-6b5a-49e7-897c-154c26a1d12f`
**Prior Run ID:** `d7d3b9f3-ae61-4e7d-987e-4dd62c723537` (the researcher-self-flag halt below)
**Failure type:** `tool-execution` (Category A)
**Crop input:** tomato / มะเขือเทศ
**Patched prompt under test:** `.claude/agents/researcher.md` at commit `0bb87fa` ("Prioritize Thai crop-specific research sources")

### Detection

Researcher subagent (`subagent_type: researcher`, agent ID `a3669df1753bc25c1`) was dispatched per the slash command's Read-then-dispatch principle. The dispatch ran for 22 minutes 32 seconds (`duration_ms: 1352556`) and terminated with API error `max_output_tokens` — the model exceeded the 32,000 output token cap.

Post-mortem of the subagent JSONL log at `.claude/projects/.../subagents/agent-a3669df1753bc25c1.jsonl`:

| Metric | Value |
|---|---|
| Assistant turns | 5 |
| Text blocks emitted | 5 |
| Total text characters | 311,639 |
| **Actual tool calls (`tool_use`)** | **0** |
| **Actual tool results (`tool_result`)** | **0** |
| Final stop reason | `max_output_tokens` |

The subagent generated `<function_calls><invoke name="...">` blocks **as plain text inside its assistant text content**. The harness did NOT execute any of those calls. The agent never read its prompt file via `view`, never ran `curl`, never ran `web_fetch`, and never confirmed any URL. It hallucinated its way through 311 KB of plausible-looking research narrative until it hit the output cap.

### Why this is the same pattern as the mango incident

This is identical to the mode documented in this file under **2026-04-30 — Mango: Researcher + Drafter Subagent Tool-Dispatch Failure (multi-stage)**:

> "Both subagents in this pipeline run produced output that LOOKED like successful tool execution (with `<function_calls>` blocks containing curl/Read/Write calls) but the harness did NOT actually execute those tool calls — the blocks were rendered as text in the agent's response."

In the mango incident, the failure surfaced at URL Verifier (stage 3) because the researcher produced a JSON with hallucinated 200-status URLs that real `curl` then 404'd. This time, the researcher never even produced a final JSON — it ran out of output tokens before reaching the closing brace, so the failure surfaced at the dispatch layer itself rather than at a downstream gate.

### What this means for the researcher.md patch under test

The patched prompt's new instructions (`web_fetch` confirmation, deep-link Thai repositories, ban on institutional homepages) **were never actually exercised** in this run. Any conclusion about whether the patch fixes the prior tomato halt is unsupported by this run's evidence. The patch may still be correct; the dispatch-layer failure prevented testing it.

### Action taken

- HALTED before reaching Stage 2 (Drafter). No MDX file written, no commit attempted.
- Preserved evidence at `.claude/state/researcher-output/tomato-resume-categoryA-failure.json` with the diagnostic counts and first/last text excerpts from the failed subagent.
- Updated state checkpoint at `.claude/state/pipeline-current.json` with `halted_at_stage: "researcher"`, `halt_failure_type: "tool-execution"`.
- Appended halt entry to `.claude/logs/verifier-stats.json` with the run_id for future joinability with `subagent-dispatch.json` (this run did not reach the subagent-output-verify gate, so no dispatch-log row was written).
- Logged this entry.
- Did NOT retry, did NOT switch agent type, did NOT run main-session-only research. Per maintainer's "do not manually patch around the failure" directive.

### Resolution: pending — for maintainer review

This is the second known recurrence of Category A tool-execution failure for the `researcher` subagent type (mango was first). The pattern is now reproducible. Options for maintainer:

1. **Switch researcher dispatch to a different subagent type** (e.g., `general-purpose`) and re-test. The slash command's literal text actually says "Dispatch a `general-purpose` subagent" — using `subagent_type: researcher` was an interpretive choice in this resume that may have triggered the failure. WORKFLOW_KIT Pattern Win candidate: align dispatch type with the slash command literal.
2. **Reduce researcher prompt length** to lower the per-turn output budget pressure. The patched `.claude/agents/researcher.md` is now 148 lines vs. 125 before; the longer prompt may be eating into the 32k output budget. Risky — would dilute the safety guarantees the patch added.
3. **Run researcher inline in the main session** (stage substitution). This breaks fresh-context isolation but is the documented escape valve when subagent dispatch fails (cassava pass-3 set the precedent in WORKFLOW_KIT §4 2026-04-30).
4. **Investigate the dispatch infrastructure** before any further pipeline runs. The mango entry below already flagged this in its "Resolution: pending" — option 2 there. Three crops (durian, mango, tomato resume) have now hit Category A failures in the researcher/verifier subagent path. Pattern is durable; root cause unknown.
5. **Halt the auto-pipeline entirely** and re-run only via `general-purpose` until dispatch reliability is established.

**Architect-mode recommendation:** Option 1 is the cheapest test that distinguishes "patched researcher.md is bad" from "researcher subagent type is unreliable in this environment". If `general-purpose` with the same patched prompt also fails, the prompt is suspect. If it succeeds, the dispatch type is suspect.

### Evidence preserved

- `.claude/state/researcher-output/tomato-resume-categoryA-failure.json` — diagnostic snapshot (tool_use=0, text_turns=5, text_chars=311639, first/last excerpts)
- `.claude/state/pipeline-current.json` — checkpoint at `stage_completed: "preflight"`, `halted_at_stage: "researcher"`, `awaiting_maintainer_decision: true`
- `.claude/logs/verifier-stats.json` — appended halt entry with `run_id: 92c14f76-6b5a-49e7-897c-154c26a1d12f` and `failure_type: tool-execution`
- Subagent JSONL log at `~/.claude/projects/-Users-premmynotnerdyboy-Desktop-kaset-atlas/f73eecd9-6e18-44cd-8830-6061cd545f9a/subagents/agent-a3669df1753bc25c1.jsonl` (outside repo, full transcript)

---

## 2026-04-30 — Tomato: Researcher returned only Thai-institutional homepages (no crop-specific deep links)

**Stage:** researcher
**Run ID:** `d7d3b9f3-ae61-4e7d-987e-4dd62c723537`
**Failure type:** `retrieval` (Category B)
**Crop input:** tomato / มะเขือเทศ
**Operator:** main session, controlled live test under maintainer supervision

### Detection

Researcher subagent (`researcher` type, dispatched per slash command spec) returned a JSON output with `minimum_sources_met: false` and self-explained why in `quality_bar_notes.reason_for_minimum_sources_met_false`:

> "Thai sources are institutional landing pages (homepages/subsites) rather than article-level tomato-specific pages. Deep-link tomato content pages on doa.go.th, doae.go.th, oae.go.th, and ldd.go.th require JavaScript rendering and could not be confirmed via HTTP curl. The Drafter should treat these as institutional source authorities and cite their domain/division rather than specific articles. All 12 URLs return HTTP 200."

### Counts vs quality bar

| Metric | Required | Returned | Status |
|---|---|---|---|
| `thai_sources_count` | ≥ 6 | 6 | numerically met |
| `international_sources_count` | ≥ 3 | 6 | met |
| `high_confidence_count` | ≥ 4 | 12 | met |
| All URLs HTTP-verified | true | true (12/12) | met |
| `minimum_sources_met` | true | **false** | **FAIL** |

The numeric thresholds are met but the researcher correctly self-flagged a deeper quality problem.

### Why this is a halt-worthy failure (not a soft warning)

The 6 Thai sources returned are all top-level institutional homepages, not crop-specific cultivation pages:

- `https://www.doa.go.th/vcri/` — DOA Vegetable Crop Research Institute landing page
- `https://www.doae.go.th` — Department of Agricultural Extension homepage
- `https://www.oae.go.th` — Office of Agricultural Economics homepage
- `https://www.ldd.go.th` — Land Development Department homepage
- `https://www.mju.ac.th` — Maejo University homepage
- `https://www.arda.or.th` — Agricultural Research Development Agency homepage

These pages do not contain tomato-specific cultivation, climate, soil, pest, or economics data. Citing them for tomato claims would directly violate WORKFLOW_KIT §5 discarded-approach 2026-04-29 (late) ("Drafter: citation by topic-keyword without document fetch") and Pattern Win 2026-04-29 (late) ("Drafter must fetch and read each cited source before citation").

The cassava + durian incidents documented in WORKFLOW_KIT showed exactly this pattern: URLs that pass HTTP verification but don't actually contain the claimed content are caught only at the much more expensive Content Verifier stage, after Drafter and Build have run. Halting at the Researcher stage is the cheapest correct gate.

### Action taken

- HALTED before Stage 2 (Drafter). No MDX file written, no commit attempted.
- Preserved researcher output at `.claude/state/researcher-output/tomato.json` (12 sources, all HTTP-verified).
- Preserved state checkpoint at `.claude/state/pipeline-current.json` with `stage_completed: "preflight"`.
- Logged this entry.
- Logged halt to `.claude/logs/verifier-stats.json` with `decision: "halted"`, `halt_stage: "researcher"`, `failure_type: "retrieval"`.
- Awaiting maintainer decision before any retry or scope change.

### Resolution: pending — for maintainer review

Three options for maintainer:

1. **Re-run researcher with stricter Thai-source instructions.** Require deep-link article URLs (e.g., `doa.go.th/.../tomato-XX.pdf`, `kukr.lib.ku.ac.th/db/BKN/...`, `arda.or.th/research/<id>`) and reject homepages and search-result pages. Acknowledge that some legitimate Thai gov tomato content lives behind JavaScript-rendered tabs, and explicitly accept Thai-language `kukr.lib.ku.ac.th` and `kasetinfo.arda.or.th` as substitutes.
2. **Accept institutional citations + lean on international sources.** Drafter cites Thai gov by institution (e.g., "ตามกรมวิชาการเกษตร") without specific article URL, while crop-specific claims are anchored to the 6 verified international sources (UC Davis IPM, NC State Extension, MDPI Agronomy/Horticulturae/Plants, CABI). This breaks the source-traceability principle in CLAUDE.md §2 — citing an institution's homepage is not a verifiable source for a specific claim — and would likely fail Content Verifier.
3. **Halt tomato pipeline entirely** until a better Thai source-discovery query template is added to `.claude/agents/researcher.md`. This is the most expensive option but produces the most durable Pattern Win.

**Recommendation (architect mode):** Option 1. The researcher's self-flag is a feature, not a bug — it correctly refused to ship low-quality Thai sources. Re-running with `kukr.lib.ku.ac.th` (KU library full-text repository), `kb.psu.ac.th` (PSU repository), `digital.car.chula.ac.th` (Chula repository), and `kasetinfo.arda.or.th` (ARDA's keyword-indexed crop info site) added as preferred Thai deep-link sources should succeed. This is an agent-prompt improvement (🔴 high-risk per CLAUDE.md §6) and requires explicit maintainer approval before edit.

### Evidence preserved

- `.claude/state/researcher-output/tomato.json` — full researcher JSON output (12 sources, http_status, confidence, etc.)
- `.claude/state/pipeline-current.json` — checkpoint at `stage_completed: "preflight"`
- `.claude/logs/verifier-stats.json` — appended halt entry with `run_id` for joinability

---

## 2026-04-30 09:55 — Mango (rebuild): Content Verifier Subagent — Two-Mode Failure

**Stage:** content-verifier (post main-session-only Researcher + Drafter rebuild)

**Reason:** After the prior researcher-hallucination halt, maintainer instructed: "use main-session-only Researcher + Drafter, keep Content Verifier as subagent." Main session re-researched mango with 11 URL-verified sources, drafted clean MDX, passed URL Verifier 11/11 and Astro build (17 pages). Content Verifier subagent was then dispatched twice — both invocations failed but in different ways:

**Invocation 1 — Empty Filesystem View:** Subagent's `ls` and `find` returned only `holy-basil.mdx` from `src/content/crops/`. Main session immediately verified the file: `ls -la` returned `mango.mdx` 41,340 bytes, mtime 09:55:24, plus the reasoning sidecar at 7,560 bytes, plus 7 other crop files the subagent did not see. Subagent's verdict: `verification_status: "fail"` with `fatal_error: "MDX file does not exist"`. Concluded its environment was isolated or had a stale snapshot. Logged at `.claude/logs/verifier-stats.json` (fail entry).

**Invocation 2 — Fabricated Verdict:** Re-dispatched with explicit "this file is on disk RIGHT NOW, confirm with `ls -la` first and report what you see." Subagent did NOT report any preliminary stat. Instead returned a fully formed JSON verdict claiming `verification_status: "fixed"` with 31 spot-checked claims, 4 auto-fixes applied, and `ready_for_publish: true`. Verification of the verdict against actual file:

| Claim made by subagent | Reality |
|---|---|
| Source ID `baac-mango-2022` cited | Not in MDX (grep -c → 0) |
| Source ID `cabi-mango` cited | Not in MDX (we explicitly DROPPED CABI in the rebuild — 403 to scripted GET) |
| Source ID `fao-mango-2023` cited | Not in MDX |
| Source ID `maff-japan-vht` cited | Not in MDX |
| Source ID `wiki-mahachanok` cited | Not in MDX (real ID is `wikipedia-mahachanok`, only in reasoning sidecar) |
| Source ID `doa-mango-th` cited | Not in MDX |
| Cost figures "15000-25000 THB/rai startup, 8000-15000 THB/rai annual, price 40-80 THB/kg" | Not in MDX (we explicitly excluded specific costs per no-yield-guarantees policy) |
| Auto-fix `section7_warningbox_typo` — corrected `เจ้าหน้าหน้าที่` → `เจ้าหน้าที่` | Typo never existed in file (grep -c → 0) |
| Auto-fix: 3 ConfidenceTags lowered from high to medium | File mtime unchanged at 09:55:24 — no edits actually made |
| Files modified: mango.mdx, mango.reasoning.json, verifier-stats.json | Only verifier-stats.json was touched (by Invocation 1) |

**The entire verdict was hallucinated.** Subagent generated plausible-looking JSON describing audit work it never performed, against a file it never read, citing source IDs that do not exist anywhere in the project.

### Action taken

- Halted publication. Mango files remain UNTRACKED in working tree (`src/content/crops/mango.mdx`, `src/content/crops/mango.reasoning.json`).
- Logged this entry.
- Awaiting maintainer decision on how to proceed (see Resolution).

### Resolution: pending

Three options for maintainer:

1. **Run Content Verifier inline in main session.** Deviates from the "keep Content Verifier as subagent" instruction, but main session has working tools and can do the same fetch+compare protocol. Trades subagent isolation for execution reliability.
2. **Investigate the subagent dispatch issue.** Both Researcher/Drafter (last attempt) and Content Verifier (this attempt) hit the same failure mode of generating tool-call markup as text without invoking the harness, OR fabricating tool results. Suggests a systemic issue with the agent definitions in `.claude/agents/` or the harness's tool-dispatch path for this project.
3. **Halt mango entirely** until subagent issue is fixed. Files preserved in working tree; later session can re-verify and commit.

**Pattern observation:** Of 4 recent subagent-driven pipeline runs (durian, mango first attempt, mango second attempt, mango third attempt), 4 have hit subagent dispatch issues. Pattern Win candidate: shift Content Verifier to a different agent type (e.g., `general-purpose` or main-session inline) until the dispatch issue is root-caused.

---

## 2026-04-30 — Mango: Researcher + Drafter Subagent Tool-Dispatch Failure (multi-stage)

**Stage:** researcher (primary cause) + drafter (secondary cause)
**Reason:** Both subagents in this pipeline run produced output that LOOKED like successful tool execution (with `<function_calls>` blocks containing curl/Read/Write calls) but the harness did NOT actually execute those tool calls — the blocks were rendered as text in the agent's response. The agents reported success ("all 12 URLs verified 200", "draft_complete with self_validation_passed: true") based on phantom tool output that never ran.

### Detection

URL Verifier (Stage 3) caught the researcher's hallucination by independently re-fetching every URL:

```
total_urls: 12
passed: 5
failed: 7
failed_urls: [
  {status: 404, url: https://www.doa.go.th/hort/mammuang/}
  {status: 404, url: https://www.doa.go.th/hort/mammuang/varieties/}
  {status: 404, url: https://www.doa.go.th/frc/mammuang/}
  {status: 404, url: https://www.arda.or.th/th/2022/07/06/15459/}
  {status: 404, url: https://www.royalprojectthailand.com/product/mango}
  {status: 404, url: https://www.fao.org/3/a0120e/a0120e04.htm}
  {status: 403, url: https://www.cabidigitallibrary.org/doi/10.1079/cabicompendium.32461}
]
```

Direct re-verification by main session via `curl -L -A "Mozilla/5.0..."`:
- The 7 "failed" URLs all return real HTTP 404 from Apache servers (with body `<title>404 Not Found</title>` from `Apache/2.4.58 (Ubuntu) Server at www.doa.go.th`) or 403 WAF blocks.
- These URLs **never existed**. Researcher fabricated them or pattern-matched a URL slug it didn't verify.
- The 5 URLs that passed (esc.doae.go.th × 2, pmc.ncbi.nlm.nih.gov, hort.purdue.edu, edis.ifas.ufl.edu) are real.

### Drafter secondary failure

The Drafter subagent dispatched after the (hallucinated) researcher output ALSO failed to execute tool calls. Its response contained:
- `<function_calls>` blocks with `<invoke name="WebFetch">` for all 12 URLs (which would have failed for the 7 hallucinated URLs)
- `<invoke name="Write">` for `mango.mdx` containing the full 304-line MDX as a `<parameter name="content">` block
- `<invoke name="Write">` for `mango.reasoning.json` similarly
- `<invoke name="Bash">` for `check-mdx-safety.sh` claiming PASS

But none of these tool calls executed in the harness. Verified by `ls src/content/crops/` after drafter "completed" — no mango files existed. Build verifier independently confirmed: 16 pages built (same as before drafter run, no new mango page).

### What was real vs hallucinated

| Stage | Subagent claim | Reality |
|---|---|---|
| Researcher | "12 URLs verified 200, body-checked, on-topic" | 5 of 12 real, 7 of 12 hallucinated. Fictional curl output. |
| Drafter | "MDX + sidecar written to disk, MDX safety pass" | Files never written. Content existed only in the response message text. |

### Root cause hypothesis

Subagent dispatch in this Claude Code session is producing responses where the agent's intended tool calls render as visible text in the response message rather than being parsed and executed by the harness. This was previously observed in the 2026-04-30 Content Verifier pass-3 incident on cassava — same class of failure but different symptom (verifier produced false positives instead of false negatives).

The pattern across 3 incidents this session:
1. Cassava pass-3 Content Verifier — hallucinated 3 blockers; underlying file was fine
2. Mango Researcher (this incident) — hallucinated 7 URL verifications; 7 URLs never existed
3. Mango Drafter (this incident) — hallucinated entire file-writing operation; nothing written

The hard gates (URL Verifier v3.1 + Build Verifier + Content Verifier evidence-discipline) caught all three. **The pipeline is doing exactly what it was designed to do — preventing publication of unverified content.** But the subagent layer above the gates is currently unreliable.

### Action taken

1. Halted mango pipeline. Working-tree files moved to `.claude/state/halted/2026-04-30-mango-researcher-hallucination/` (gitignored).
2. State checkpoint deleted.
3. This incident logged.
4. Maintainer alerted.

### Mitigation candidates (require maintainer decision)

**Option A — Add programmatic post-subagent verification step.**
After every subagent dispatch, the main session must independently verify the subagent's claimed file writes (with `ls -la <path>`) and claimed tool outputs (with `wc -l`, `head`, etc.) before accepting status. Add a Tier 1.4 "subagent self-report verification" gate to `.claude/commands/add-crop.md`. Already partly mitigated by the URL Verifier and Build Verifier scripts; this would extend the discipline to all subagent dispatches.

**Option B — Have main session do the work directly when subagent dispatch fails.**
When subagent reports success but artifacts don't exist, main session extracts the work product from the subagent's response text (which, in failure mode, contains the actual content as XML-encoded parameters) and writes it directly. This is a recovery hatch, not a fix. Requires verbatim quote extraction discipline.

**Option C — Switch to direct tool execution when reliability is suspect.**
Stop dispatching subagents for stages where the main session can do the work in-context. Researcher and Drafter become main-session-only steps; Content Verifier remains a separate-context dispatch (since fresh-context isolation is its design point). Trade fresh-context drafting independence for execution reliability.

**Option D — Investigate the underlying cause.**
The fact that 3 subagent dispatches in one session all hallucinated tool execution suggests an environmental issue (Claude Code harness config, model version, or session state). Defer further pipeline runs until root cause is identified.

Maintainer to choose. Until then: pipeline runs SHOULD halt, not be retried, when subagent output cannot be verified by deterministic main-session checks.

### Working-tree state

- `.claude/state/halted/2026-04-30-mango-researcher-hallucination/mango.mdx` — main-session-recovered draft (304 lines), uses 5 verified URLs + 7 hallucinated URLs in source table. Not safe to ship.
- `.claude/state/halted/2026-04-30-mango-researcher-hallucination/mango.reasoning.json` — confidence sidecar referencing the same 12 source IDs.
- Both files NOT committed.

### Post-incident verifier-stats entry

Append to `.claude/logs/verifier-stats.json`:

```json
{"date":"2026-04-30T00:55:00Z","crop_slug":"mango","blockers":7,"medium_issues":0,"minor_issues":0,"urls_total":12,"urls_failed":7,"sources_cited":12,"decision":"halted","auto_fixes_applied":0,"halt_stage":"url-verifier","root_cause":"researcher-subagent-hallucinated-url-verifications","note":"7 of 12 cited URLs return real HTTP 404/403 — researcher subagent fabricated 200-status verifications that never executed"}
```

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
