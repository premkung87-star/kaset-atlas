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

### 2026-04-29 — HEAD-only URL verification
**Approach:** `curl --head` only, no fallback. Any non-2xx/3xx HEAD response treated as URL failure.
**Why discarded:** False-negative rate too high. PMC blocks HEAD by policy (returns 405). Some Thai government PDF servers have broken HEAD handlers (return 404 to HEAD but 200 to GET). Anti-bot-gated commercial sites return concatenated status codes through redirect chains. First holy-basil pipeline run halted on 4 false-negatives across these classes.
**Replaced by:** Pattern Win 2026-04-29 (HEAD→GET fallback).

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

## 10. Open questions (revisit as we go)

- **Pagefind activation:** schedule = after first 3 categories have content.
- **Supabase Pro on this project:** schedule = V2, when corpus reaches ~30+ crops and we want a queryable source registry / RAG index.
- **Image strategy:** hero image generation/sourcing pipeline. Defer to V1.1 (after first 9-crop launch).
- **`/add-crop` slash command:** currently invoked via natural language to Claude Code; consider a real `.claude/commands/add-crop.md` slash-command file.
- **Public LEARNINGS.md vs internal WORKFLOW_KIT.md:** keep this internal-only for V1; consider a public version at V2.
- **Translation of WORKFLOW_KIT into Thai:** internal — stays English per Rule 1 (English-only prompts to Claude Code).

---

## 11. How to update this file

When a Pattern Win or Discarded entry is added:
1. Append to §4 or §5 with the schema in §9.
2. Update §10 if it changes any open-question status.
3. Bump "Last updated" line at top.
4. Commit as `docs(workflow-kit): record [pattern win | discarded] — [short title]`.

Do **not** rewrite past entries. The log is append-only for traceability. If a past Pattern Win is later discarded, add a new Discarded entry referencing it — both stay in place.

---

## Last Updated

2026-04-29 — Initial version. Phase A of post-launch workflow consolidation. Captures the holy-basil pipeline run learnings, AI-citable goal, free-tier audit convention.
