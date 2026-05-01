# Codex Invocation Brief: jsonld-component-review

**Issued by:** Claude Code (Senior Engineer)
**Issued at:** 2026-05-01T13:09:10Z
**Trial invocation #:** 5 of trial-day 2026-05-01 (post-trial-merge; first production-code review)
**Sanctioned use case:** `review-default` (Phase 6 of the Codex Intern integration plan; maintainer approved this candidate)

---

## 1. Goal

Standard-mode review of `src/components/JsonLd.astro` against the JSON-LD spec, schema.org type expectations, and Astro / TypeScript correctness. Verify the component handles single-object and array inputs safely, serializes JSON correctly without XSS surface, emits valid `<script type="application/ld+json">` blocks, and uses `set:html` + `is:inline` correctly per Astro's escape-handling semantics.

## 2. Slash command to be run

`/codex:review --background --scope working-tree`

## 3. Why Codex specifically (vs Claude Code doing it itself)

JsonLd.astro is the load-bearing surface for the project's machine-citable goal (CLAUDE.md §1). It's small enough that author-bias on a self-review is high — Claude Code wrote it during Phase 1 polish without external schema-compliance verification. A fresh-context standard review is the cheapest path to confirming spec compliance OR surfacing real defects before the next crop ships and consumes the same JSON-LD pipeline.

## 4. Scope

- Mode: review-only (`/codex:review`, standard framing)
- Target: working-tree
- File-count: 1 production file (`src/components/JsonLd.astro`, 24 lines pre-edit, 26 lines post-edit) + 1 untracked task brief (this file)
- Lines changed in working tree: a 2-line documentation comment added at the end of the frontmatter comment block — pulls the file into review scope without polluting review attention
- Estimated input to OpenAI: ~5 KB total (file is small; surrounding context loaded by Codex CLI is bounded)
- Excluded paths (per RULES.md §A1.x): none — JsonLd.astro contains no secrets, keys, tokens, or `.env` content. Verified.

## 5. Expected output

- Format: verbatim Codex stdout (review text)
- Length expectation: best-effort ≤ 200 lines; likely 3–8 short findings given the file is 26 lines
- Acceptance criteria for Claude Code's review of Codex output:
  - Every cited file:line resolves at the cited range when re-read
  - Every verbatim quote can be `grep`'d from the file
  - No finding proposes an edit outside `src/components/JsonLd.astro` (Codex must not propose rewrites of BaseLayout.astro, schema generators in pages, or any other file)
  - No finding proposes adding a new dependency, changing build config, or restructuring the component import surface
  - No finding triggers RULES.md §B14 secret detection (none expected; documented carve-out applies if any heuristic substring appears)

## 6. Rescue approval

`n/a — review-only invocation`

## 7. Forbidden moves on this invocation

- All RULES.md §B prohibitions apply unconditionally.
- Editing any file (review-only command).
- Inferring scope beyond `src/components/JsonLd.astro`.
- Proposing rewrites of BaseLayout.astro, page templates, or any other consumer of JsonLd.astro — those are pre-existing production files explicitly out of scope.
- Proposing new packages or schema-generator libraries.
- Re-introducing any Discarded approach from `WORKFLOW_KIT.md §5` (RULES.md §B12).
- Asking the maintainer for clarification mid-run (no human relay; return a `blocked` note instead).
- Persisting Codex session state (`--fresh` is default per §B16).

## 8. Stop conditions

Abort with `quota-hit` / `blocked` / `cancelled` if:
- The Codex CLI prints a quota / auth error (LIMIT_FALLBACK.md §3 path).
- Codex output references files outside `src/components/JsonLd.astro`.
- Codex output proposes edits to forbidden paths (RULES.md §B1–§B4).
- The invocation runs past 5 minutes.

## 9. Hand-off

- Claude Code captures stdout into `.ai/codex/reports/2026-05-01-jsonld-component-review.md` using `REPORT_TEMPLATE.md`.
- Claude Code performs adversarial review of each finding and **classifies each as Critical | Important | Optional | Noise** per the established T1–T3 scheme.
- Claude Code re-reads cited lines, applies the self-consistency check, and proposes per-finding adoption decisions (zero copy-paste of Codex wording into authored content).
- Claude Code appends the outcome line to `TRIAL_LOG.md`.
- The maintainer is shown the verbatim Codex output AND classifications + adoption decisions before any production-code edit OR rollback of the working-tree comment lands as a commit.

## 10. Limit fallback

If Codex is unavailable / quota-hit / blocked / crashed:
- Capture whatever stdout was produced into `.ai/codex/reports/2026-05-01-jsonld-component-review.md` (status: `quota-hit` / `blocked`).
- Append a `quota-hit`-flavoured TRIAL_LOG.md line.
- **Continue without Codex:** Claude Code performs the same JSON-LD spec compliance + Astro correctness check in its own context, comparing JsonLd.astro against schema.org / Astro escape-handling docs.
- Maintainer decides whether to re-dispatch later or accept the Claude-Code-only review.
- The 2-line working-tree edit remains until the maintainer authorizes a commit (or instructs `git restore`).

## 11. Invocation count and daily-budget context

This will be **invocation 5 of 5** for the maintainer-day per INTERN_ONBOARDING.md §3 hard ceiling. Four prior runs today: bootstrap review (`review-mom8d3ly-290xos`), T1 audit-entry adversarial review (`review-mom9ekrp-ero8my`), T2 workflow-kit standard review (`review-mom9yyfp-0s06nu`), T3 pawee-extension adversarial review (session `019de15b`). After this invocation: **0 invocations remaining for 2026-05-01.**

---

**Last updated:** 2026-05-01T13:09:10Z (initial draft, pre-invocation).
