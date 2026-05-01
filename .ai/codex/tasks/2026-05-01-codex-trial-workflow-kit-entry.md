# Codex Invocation Brief: codex-trial-workflow-kit-entry

**Issued by:** Claude Code (Senior Engineer)
**Issued at:** 2026-05-01T02:18:00Z
**Trial invocation #:** 3 of trial run on branch `chore/codex-intern-trial`
**Sanctioned use case:** `review-default` (T2 from the first-real-tasks proposal; maintainer approved T2 only)

---

## 1. Goal

Standard-mode review the proposed `docs/WORKFLOW_KIT.md` change that records the Codex trial integration as a §4 Pattern Win. Verify schema compliance against the §9 entry template, cross-reference accuracy (commit SHAs, file paths, rule numbers), neutrality, and consistency with the just-committed audit-log entry.

Standard `/codex:review` (not adversarial) because §9's Pattern Win schema is rigid and the value is checking schema fit and reference accuracy, not adversarial framing of the decision itself — the integration decision was already adversarially reviewed in T1.

## 2. Slash command to be run

`/codex:review --background --scope working-tree`

## 3. Why Codex specifically (vs Claude Code doing it itself)

The §4 entry is the operational-layer twin of the audit-log entry that just received Codex review in T1 and one applied fix (F1). Same author-bias risk applies. Fresh-context schema-compliance check is cheap and catches regressions like the one F1 surfaced (a contradiction between L23 and L24 of the audit entry that Claude Code missed on initial draft).

## 4. Scope

- Mode: review-only (`/codex:review`, standard framing)
- Target: working-tree (one modified file)
- File-count: 1 (`docs/WORKFLOW_KIT.md`)
- Lines changed: +9 / -1 (the -1 is the prescribed `Last updated` date bump per WORKFLOW_KIT.md §13; verified via `git diff` shows only that one prior-line deletion, no §4 / §5 / footer-log entries rewritten)
- Estimated input to OpenAI: WORKFLOW_KIT.md is ~30 KB; Codex CLI may load context. Within the §3 hard budget (≤ 50 KB).
- Excluded paths (per RULES.md §A1.x): none — `docs/WORKFLOW_KIT.md` contains no secrets, keys, tokens, `.env` content. The new entry references `RULES.md §B14` heuristic patterns (`*_KEY=`, `*_SECRET=`, `*_TOKEN=`) inside backticked prose, which is exactly the documentation carve-out E1 codified — does NOT trigger §B14 abort.

## 5. Expected output

- Format: verbatim Codex stdout (review text)
- Length expectation: best-effort ≤ 200 lines; likely 3–10 short findings
- Acceptance criteria for Claude Code's review of Codex output:
  - Every cited file:line resolves at the cited range when re-read
  - Every verbatim quote can be `grep`'d from the file
  - No finding proposes an edit outside `docs/WORKFLOW_KIT.md`
  - No finding proposes rewriting any prior §4 entry, prior §5 entry, prior footer-log entry, or any §10/§11/§12 content (append-only discipline; only the new §4 entry, the prescribed top "Last updated" date bump, and the new footer-log line are in scope for any proposed change)

## 6. Rescue approval

`n/a — review-only invocation`

## 7. Forbidden moves on this invocation

- All RULES.md §B prohibitions apply unconditionally.
- Editing any file (review-only command).
- Inferring scope beyond the working-tree diff to `docs/WORKFLOW_KIT.md`.
- Proposing rewrites of any pre-existing §4 entry, §5 entry, or footer-log entry — append-only discipline.
- Re-introducing any Discarded approach from `WORKFLOW_KIT.md §5` (RULES.md §B12).
- Asking the maintainer for clarification mid-run (no human relay; return a `blocked` note instead).
- Persisting Codex session state (`--fresh` is default per §B16; resume from prior T1 thread is forbidden).

## 8. Stop conditions

Abort with `quota-hit` / `blocked` / `cancelled` if:
- The Codex CLI prints a quota / auth error (LIMIT_FALLBACK.md §3 path).
- Codex output references files outside `docs/WORKFLOW_KIT.md`.
- Codex output proposes edits to forbidden paths (RULES.md §B1–§B4).
- The invocation runs past 5 minutes.

## 9. Hand-off

- Claude Code captures stdout into `.ai/codex/reports/2026-05-01-codex-trial-workflow-kit-entry.md` using `REPORT_TEMPLATE.md`.
- Claude Code performs adversarial review of each finding and **classifies each as Critical | Important | Optional | Noise** per the established T1 scheme.
- Claude Code re-reads cited lines, applies the self-consistency check, and proposes per-finding adoption decisions (zero copy-paste of Codex wording into authored content).
- Claude Code appends the outcome line to `TRIAL_LOG.md`.
- The maintainer is shown the verbatim Codex output AND classifications + adoption decisions before any further pack edit OR WORKFLOW_KIT revision lands as a commit.

## 10. Limit fallback

If Codex is unavailable / quota-hit / blocked / crashed:
- Capture whatever stdout was produced into `.ai/codex/reports/2026-05-01-codex-trial-workflow-kit-entry.md` (status: `quota-hit` / `blocked`).
- Append a `quota-hit`-flavoured TRIAL_LOG.md line.
- **Continue without Codex:** Claude Code performs the same schema-compliance pass against `docs/WORKFLOW_KIT.md §9` template and existing §4 entries in its own context.
- Maintainer decides whether to re-dispatch later or accept the Claude-Code-only review.
- The WORKFLOW_KIT.md edit remains in the working tree until the maintainer authorizes the commit.

## 11. Invocation count

This will be invocation **3 of 5** for the maintainer-day per INTERN_ONBOARDING.md §3 hard ceiling. Two prior runs today: bootstrap review (`review-mom8d3ly-290xos`) and T1 audit-entry adversarial review (`review-mom9ekrp-ero8my`).

---

**Last updated:** 2026-05-01T02:18:00Z (initial draft, pre-invocation).
