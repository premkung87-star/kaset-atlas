# Codex Invocation Brief: codex-trial-audit-entry

**Issued by:** Claude Code (Senior Engineer)
**Issued at:** 2026-05-01T01:55:00Z
**Trial invocation #:** 2 of trial run on branch `chore/codex-intern-trial`
**Sanctioned use case:** `adversarial-review` (T1 from the first-real-tasks proposal; maintainer approved T1 only)

---

## 1. Goal

Adversarially review the proposed `docs/AUDIT_LOG.md` append-only entry that records the Codex trial integration decision. Surface contradictions with prior audit entries, schema mismatches against the file's own template, factually unsupported claims, neutrality issues, and any wording a future maintainer could plausibly dispute.

## 2. Slash command to be run

`/codex:adversarial-review --background --scope working-tree`

## 3. Why Codex specifically (vs Claude Code doing it itself)

Author-bias risk: Claude Code drafted both the integration decision AND this audit entry recording it. A fresh-context adversarial pass is the right tool to catch self-serving framing, omitted constraints, or premature conclusions. The audit log is append-only forever; getting the entry right before commit matters.

## 4. Scope

- Mode: review-only (`/codex:adversarial-review`)
- Target: working-tree (the new entry sits as uncommitted change in `docs/AUDIT_LOG.md`)
- File-count: 1 modified file (`docs/AUDIT_LOG.md`)
- Lines changed: +30 / -0 (strictly append-only; 0 prior-entry rewrites verified via `git diff --stat`)
- Estimated input to OpenAI: ~30 KB total (full file is ~30 KB; only the diff hunk is the focus, but Codex CLI may load surrounding context)
- Excluded paths (per RULES.md §A1.x): none — `docs/AUDIT_LOG.md` contains no secrets, keys, tokens, or `.env` content. Verified.

## 5. Expected output

- Format: verbatim Codex stdout (review text)
- Length expectation: best-effort ≤ 200 lines; likely 5–15 short findings given the entry is ~50 lines
- Acceptance criteria for Claude Code's review of Codex output:
  - Every cited file:line resolves at the cited range when re-read
  - Every verbatim quote can be `grep`'d from the file
  - No finding proposes an edit outside `docs/AUDIT_LOG.md`
  - No finding requires modifying the prior cilantro audit entry or any earlier entry (append-only discipline)

## 6. Rescue approval

`n/a — review-only invocation`

## 7. Forbidden moves on this invocation

- All RULES.md §B prohibitions apply unconditionally.
- Editing any file (review-only command).
- Inferring scope beyond §4 — Codex must focus on the diff to `docs/AUDIT_LOG.md`.
- Re-introducing any Discarded approach from `WORKFLOW_KIT.md §5` (RULES.md §B12).
- Asking the maintainer for clarification mid-run (no human relay; return a `blocked` note instead).
- Persisting Codex session state (`--fresh` is default per §B16).

## 8. Stop conditions

Abort with `quota-hit` / `blocked` / `cancelled` if:
- The Codex CLI prints a quota / auth error (LIMIT_FALLBACK.md §3 path).
- Codex output references files outside `docs/AUDIT_LOG.md`.
- Codex output proposes edits to forbidden paths (RULES.md §B1–§B4).
- The invocation runs past 5 minutes.

## 9. Hand-off

- Claude Code captures stdout into `.ai/codex/reports/2026-05-01-codex-trial-audit-entry.md` using `REPORT_TEMPLATE.md`.
- Claude Code performs adversarial review of each finding and **classifies each as Critical | Important | Optional | Noise** per the maintainer's instruction.
- Claude Code re-reads cited lines, applies the self-consistency check, and proposes per-finding adoption decisions.
- Claude Code appends the outcome line to `TRIAL_LOG.md`.
- The maintainer is shown the verbatim Codex output AND classifications + adoption decisions before any audit-log edit lands as a commit.

## 10. Limit fallback

If Codex is unavailable / quota-hit / blocked / crashed:
- Capture whatever stdout was produced into `.ai/codex/reports/2026-05-01-codex-trial-audit-entry.md` (status: `quota-hit` / `blocked`).
- Append a `quota-hit`-flavoured TRIAL_LOG.md line.
- **Continue without Codex:** Claude Code performs the same adversarial review against `docs/AUDIT_LOG.md` in its own context (re-read schema template, re-read prior entries, surface drift candidates).
- Maintainer decides whether to re-dispatch later or accept the Claude-Code-only review.
- The audit-log entry remains in the working tree until the maintainer authorizes the commit.

---

**Last updated:** 2026-05-01T01:55:00Z (initial draft, pre-invocation).
