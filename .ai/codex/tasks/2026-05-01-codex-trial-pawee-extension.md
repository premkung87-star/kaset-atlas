# Codex Invocation Brief: codex-trial-pawee-extension

**Issued by:** Claude Code (Senior Engineer)
**Issued at:** 2026-05-01T02:48:00Z
**Trial invocation #:** 4 of trial run on branch `chore/codex-intern-trial`
**Sanctioned use case:** `adversarial-review` (T3 from the first-real-tasks proposal; maintainer approved T3 only)

---

## 1. Goal

Adversarially review the proposed `pawee/extensions/21-junior-llm-helper-pattern.md` file — a new earned-wisdom rule capturing the Codex Intern trial as a reusable cross-project pattern. Surface mismatches against the Strategy B format (`pawee/README.md`), tag-taxonomy errors (`pawee/tags/README.md`), `applies_to` routing mistakes, factual errors in the Verbatim from Source quote, generic-principle leaks (project-specific assumptions that should not be in the abstraction), missing anti-patterns, and any wording a future maintainer applying this rule on a different project would plausibly stumble on.

Adversarial framing is the right tool here: cross-project reuse rules need to survive being applied in contexts the original maintainer didn't anticipate. Fresh-context challenge tests whether the abstraction generalizes or accidentally encodes Kaset Atlas specifics.

## 2. Slash command to be run

`/codex:adversarial-review --background --scope working-tree`

## 3. Why Codex specifically (vs Claude Code doing it itself)

Cross-project rule promotion is exactly the kind of writing where author-bias is highest: Claude Code authored the Codex trial and now authors the rule that captures the trial as reusable wisdom. A fresh-context adversarial pass is the right tool to catch (a) Kaset-Atlas-specific assumptions that leaked into the generic principle, (b) anti-patterns that should have been included but weren't, and (c) Strategy B format deviations.

## 4. Scope

- Mode: review-only (`/codex:adversarial-review`)
- Target: working-tree (one new untracked file)
- File-count: 1 new file (`pawee/extensions/21-junior-llm-helper-pattern.md`)
- Lines added: ~70 (Strategy B format: frontmatter + Verbatim from Source + Generic Pattern with sub-sections)
- Estimated input to OpenAI: ~30 KB total (the new file is ~12 KB; Codex CLI may load `pawee/README.md` and `pawee/tags/README.md` for context)
- Excluded paths (per RULES.md §A1.x): none — `pawee/extensions/` contains no secrets, keys, tokens, or `.env` content. The new file references the §B14 heuristic patterns (`*_KEY=`, `*_SECRET=`, `*_TOKEN=`) only by mention as "rules the Junior must follow"; no literal secret-shaped values present.

## 5. Expected output

- Format: verbatim Codex stdout (review text)
- Length expectation: best-effort ≤ 200 lines; likely 5–15 short findings given the file is ~70 lines of structured content
- Acceptance criteria for Claude Code's review of Codex output:
  - Every cited file:line resolves at the cited range when re-read
  - Every verbatim quote can be `grep`'d from the file
  - No finding proposes an edit outside `pawee/extensions/21-junior-llm-helper-pattern.md` (Codex must not propose rewrites of `pawee/README.md`, `pawee/tags/README.md`, or any existing `pawee/extensions/*.md`)
  - No finding proposes adding new tags to the taxonomy (that's a separate decision per `pawee/tags/README.md`)

## 6. Rescue approval

`n/a — review-only invocation`

## 7. What Codex should check (specific to T3 framing)

The maintainer's brief for T3 focuses adversarial attention on:

- **Strategy B format compliance.** Frontmatter fields (number, title, tags, applies_to, universal, source, incident_refs, added_in_kit) all present and correctly formatted? Three required sections (Verbatim from Source / Generic Pattern / Stack-specific manifestations or equivalent) all present? Section order and naming consistent with established §11 / §16 templates?
- **Tag taxonomy correctness.** Are `UNIVERSAL`, `CODE_REVIEW`, `SAFETY` the right tags? Should `OPUS_4_7`, `INVESTIGATION`, or `SIMPLICITY` also be present? Should any tag be removed?
- **`applies_to` routing accuracy.** Is `[generic]` correct, or does the rule have manifestations specific to `nextjs-vercel-supabase` or `iot-multi-repo` that need explicit listing?
- **Generic-principle leaks.** Does any sentence in the "Principle / When to apply / Why it works / How to apply / Stack-specific manifestations" sections accidentally encode Kaset-Atlas-specific assumptions (Astro, MDX, Pagefind, Vercel, the auto-pipeline, content-traceability discipline) that should not be in a generic cross-project rule?
- **Verbatim from Source accuracy.** Is the quoted §0 from `INTERN_ONBOARDING.md` accurate (commit `43f3ecc`)? Does the surrounding narrative correctly count three review rounds and six adopted findings?
- **Anti-patterns coverage.** Are the listed anti-patterns the right ones? Anything missing that a future cross-project maintainer would need warned against?
- **Reusability stress-test.** Could this rule be applied to a hypothetical NWL CLUB Cursor-agent integration, a VerdeX iot-multi-repo Aider integration, or a prempawee Devin integration without rewriting? If not, where does it bind too tightly to Codex / Kaset Atlas / Claude Code?

## 8. Forbidden moves on this invocation

- All RULES.md §B prohibitions apply unconditionally.
- Editing any file (review-only command).
- Inferring scope beyond the working-tree diff to `pawee/extensions/21-junior-llm-helper-pattern.md`.
- Proposing rewrites to `pawee/README.md`, `pawee/tags/README.md`, or any existing `pawee/extensions/*.md` — those are pre-existing pawee/ files explicitly out of scope per the maintainer's T3 brief.
- Proposing additions to the tag taxonomy (separate decision per `pawee/tags/README.md` "Adding a New Tag" section).
- Re-introducing any Discarded approach from `WORKFLOW_KIT.md §5` (RULES.md §B12).
- Asking the maintainer for clarification mid-run (no human relay; return a `blocked` note instead).
- Persisting Codex session state (`--fresh` is default per §B16).

## 9. Stop conditions

Abort with `quota-hit` / `blocked` / `cancelled` if:
- The Codex CLI prints a quota / auth error (LIMIT_FALLBACK.md §3 path).
- Codex output references files outside the new `pawee/extensions/21-junior-llm-helper-pattern.md`.
- Codex output proposes edits to forbidden paths (RULES.md §B1–§B4) or to existing pawee/ files.
- The invocation runs past 5 minutes.

## 10. Hand-off

- Claude Code captures stdout into `.ai/codex/reports/2026-05-01-codex-trial-pawee-extension.md` using `REPORT_TEMPLATE.md`.
- Claude Code performs adversarial review of each finding and **classifies each as Critical | Important | Optional | Noise** per the established T1/T2 scheme.
- Claude Code re-reads cited lines, applies the self-consistency check, and proposes per-finding adoption decisions (zero copy-paste of Codex wording into authored content).
- Claude Code appends the outcome line to `TRIAL_LOG.md`.
- The maintainer is shown the verbatim Codex output AND classifications + adoption decisions before any further pack edit OR pawee/extensions/ revision lands as a commit.

## 11. Limit fallback

If Codex is unavailable / quota-hit / blocked / crashed:
- Capture whatever stdout was produced into `.ai/codex/reports/2026-05-01-codex-trial-pawee-extension.md` (status: `quota-hit` / `blocked`).
- Append a `quota-hit`-flavoured TRIAL_LOG.md line.
- **Continue without Codex:** Claude Code performs the same Strategy B compliance + reusability stress-test in its own context, comparing the new §21 against the §11 / §16 templates and the `pawee/README.md` + `pawee/tags/README.md` specs.
- Maintainer decides whether to re-dispatch later or accept the Claude-Code-only review.
- The new file remains in the working tree until the maintainer authorizes the commit.

## 12. Invocation count

This will be invocation **4 of 5** for the maintainer-day per INTERN_ONBOARDING.md §3 hard ceiling. Three prior runs today: bootstrap review (`review-mom8d3ly-290xos`), T1 audit-entry adversarial review (`review-mom9ekrp-ero8my`), and T2 workflow-kit standard review (`review-mom9yyfp-0s06nu`).

---

**Last updated:** 2026-05-01T02:48:00Z (initial draft, pre-invocation).
