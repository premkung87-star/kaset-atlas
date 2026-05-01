# Codex Invocation Brief: review-onboarding-pack

**Issued by:** Claude Code (Senior Engineer)
**Issued at:** 2026-05-01T01:21:12Z
**Trial invocation #:** 1 of trial run on branch `chore/codex-intern-trial`
**Sanctioned use case:** `review-default` (read-only `/codex:review`)

---

## 1. Goal

Self-audit the `.ai/codex/` onboarding pack — the rules under which
Codex itself will be operated on this project — **before** any real
Kaset Atlas work uses Codex. Surface contradictions, missing
boundaries, ambiguous wording, and any text that would let Codex
accidentally exceed its trial-v1 authority.

This is a bootstrap check: Codex audits its own contract.

---

## 2. Scope

- Mode: **review-only** (`/codex:review`).
- Target: working-tree (the entire untracked `.ai/` directory; nothing
  is committed yet).
- File-count: 6 markdown files in `.ai/codex/`, plus this brief
  itself once it is added to `.ai/codex/tasks/`.
- Total size: ~46 KB. Within the INTERN_ONBOARDING.md §3 hard budget
  (≤ 50 KB combined input).
- Excluded paths (per RULES.md §A1.x): none — the `.ai/codex/`
  directory contains no `.env` files, no real credentials, no API
  keys, no tokens, no private keys. A heuristic grep of the
  directory matches only on (a) the literal substring `sk-` inside
  the documentation phrase `task-slug`, and (b) the heuristic
  pattern strings inside backticks in `RULES.md §B14` and this
  brief's §5. Both are documentation, not secrets, and are
  acceptable in scope.

Codex must **not** expand scope beyond the working-tree's `.ai/`
directory. The Astro app, the `/add-crop` pipeline, the agent prompts,
and the policy docs are explicitly out of scope for this first
invocation.

---

## 3. Files to review (in scope)

All under `.ai/codex/`:

| File | Purpose |
|---|---|
| `INTERN_ONBOARDING.md` | Codex's role, workflow context, hard budget, threat model |
| `RULES.md` | Allowed (§A) / forbidden (§B) / risk table (§C) / precedence (§D) |
| `TASK_TEMPLATE.md` | Senior-engineer paperwork for invoking Codex |
| `REPORT_TEMPLATE.md` | Capture template for Codex output + adversarial review |
| `LIMIT_FALLBACK.md` | Quota / failure handling, plugin-mode signals |
| `TRIAL_LOG.md` | Append-only invocation log + schema |
| `tasks/2026-05-01-review-onboarding-pack.md` | This brief |

The working-tree scope flag will pick all of these up automatically
(the `/codex:review` command treats untracked files as reviewable per
its own spec).

---

## 4. Files that must NOT be touched

Codex is invoked through `/codex:review`, which is read-only by
contract ("Do not fix issues, apply patches, or suggest that you are
about to make changes" per the plugin's own command definition). Even
so, this brief restates the boundary explicitly:

- **Anywhere outside `.ai/codex/`** — production code (`src/`,
  `public/`, `astro.config.mjs`, `tailwind.config.ts`,
  `package.json`), agent prompts (`.claude/agents/`,
  `.claude/commands/`), scripts (`scripts/`), policy docs
  (`CLAUDE.md`, `docs/`, `pawee/`), CI (`.github/`).
- **Even inside `.ai/codex/`** — review-only mode. No edits, no
  patches, no "here's the fix" code blocks intended for application.
  Findings are observations only.
- `/codex:rescue` — forbidden for this invocation per RULES.md §B13.
- `--enable-review-gate` — forbidden per RULES.md §B15.
- Git operations (commit, push, branch, tag) — forbidden per RULES.md
  §B6.

If Codex output proposes any edit outside `.ai/codex/`, Claude Code
treats that as a hallucination and rejects the finding in
REPORT_TEMPLATE.md §2.

---

## 5. What Codex should check

Codex's review should focus on the *contract* rather than prose
quality. In rough priority order:

1. **Internal contradictions.** Does any rule in `RULES.md §B`
   contradict another? Does `INTERN_ONBOARDING.md` claim a permission
   `RULES.md` denies (or vice versa)? Does the precedence chain in
   `RULES.md §D` resolve every conflict cleanly?

2. **Escape hatches.** Is there any wording that would let a future
   prompt argue Codex into write authority outside `.ai/codex/`?
   Specifically stress-test §B13 (rescue gating), §B17 (absolute write
   boundary), §A1.x (secrets exclusion), and §B16 (no
   `--resume-last` cross-task).

3. **Threat model coverage.** Does `INTERN_ONBOARDING.md §11`
   enumerate every meaningful capability the local CLI grants? Are
   any of: shell command execution, network egress beyond OpenAI,
   long-running background tasks, persistent sessions across
   maintainer restarts, or hook-driven automatic invocations missing
   a corresponding control?

4. **Mode discipline.** Is the review-only vs rescue distinction
   maintained consistently across all six files? Does any sentence
   blur the line such that a future maintainer reading the pack cold
   could conflate them?

5. **Quota / fallback.** Does `LIMIT_FALLBACK.md` cover the actual
   failure surfaces of the plugin? Specifically: quota cap mid-run,
   auth expiry, background hang, hallucinated finding (clean exit
   but bad content), and `codex-cli` crash. Is "continue without
   Codex" the default in every case?

6. **Audit-trail completeness.** Is every Codex invocation forced
   through the `tasks/` brief + `reports/` capture + TRIAL_LOG.md
   line? Could a "small quick review" slip through without a brief?
   (RULES.md §B10 says no — but is the wording tight enough?)

7. **Plus-quota cost discipline.** Is the maintainer-day ceiling
   (≤ 5 invocations) and the per-invocation budget (~46 KB scope,
   ~200 line output) consistent across files? Any contradictions?

8. **`disable-model-invocation` posture.** The plugin's
   `/codex:review` and `/codex:adversarial-review` set
   `disable-model-invocation: true`, meaning the model can't
   self-trigger. `/codex:rescue` does not. Does the pack reflect
   this asymmetry correctly?

9. **Ambiguous wording.** Any "should" / "may" / "typically" that
   should be a "must" / "must not" given how strict the trial is.

Codex is **not** asked to:
- Polish prose, fix grammar, or improve readability beyond clarity
  bugs.
- Compare this pack to other AI-collaboration patterns or industry
  best practices.
- Suggest new sections, new use cases, or new tools.
- Comment on whether the trial as a whole is a good idea.

---

## 6. Expected output

- **Format:** verbatim Codex stdout. The plugin streams
  `codex-cli` output back; Claude Code captures it as-is.
- **Length expectation:** best-effort ≤ 200 lines. The CLI formats
  itself; the cap is informational.
- **Acceptance criteria for the *senior-engineer review of Codex
  output* (not for Codex's own work):**
  - Every cited file path resolves at the cited line range when
    Claude Code re-reads.
  - Every verbatim quote can be grep'd from the cited file.
  - No finding proposes an edit outside `.ai/codex/`.
  - No finding asks for a tool / dependency to be added.
  - No finding requires a CLAUDE.md or `docs/` rule to be relaxed.

If Codex returns hallucinated findings (cites nonexistent line
numbers, misquotes, references files outside scope), those findings
are explicitly rejected in REPORT_TEMPLATE.md §2 and the report
status is downgraded to `rejected` or `partial`.

---

## 7. What Claude Code must do after receiving Codex's result

In strict order, no shortcuts:

1. **Capture verbatim.** Save the slash command's full stdout into
   `.ai/codex/reports/2026-05-01-review-onboarding-pack.md` using
   `REPORT_TEMPLATE.md`. Do not paraphrase.
2. **Adversarially review.** For each finding Codex surfaces:
   re-read the cited file at the cited line range; confirm the
   verbatim quote appears in the file; classify the finding as
   `verified | not-found | misquoted | partial` per
   `REPORT_TEMPLATE.md §2`.
3. **Decide adoption per finding.** Use the four-option scheme from
   `REPORT_TEMPLATE.md §2`: `accept-as-text` | `reject` |
   `rewrite-and-apply` | `defer`. **Zero copy-paste**: any pack edit
   driven by a Codex finding is re-typed by Claude Code from
   scratch, not lifted from Codex's suggested wording.
4. **Apply edits only inside `.ai/codex/`.** No production-code
   edits will follow from this review, full stop. If Codex surfaces
   what looks like a CLAUDE.md or `docs/` issue, defer it as a
   senior-engineer note; do not edit those files in this trial
   round.
5. **Run self-consistency check.** Tick the boxes in
   `REPORT_TEMPLATE.md §3`. If any box fails, the report status
   becomes `rejected` regardless of finding count.
6. **Append to `TRIAL_LOG.md`.** Single line per the schema:
   `<timestamp> | review-onboarding-pack | review-default |
   <outcome> | <one-sentence note>`.
7. **Show the maintainer the verbatim Codex output AND the adoption
   decisions** in chat before any pack edit lands. The maintainer
   has final say on every adopted finding.
8. **Do NOT commit.** Per the maintainer's brief, this run produces
   no git commits. Pack edits (if any) stay in the working tree
   until the maintainer authorises a commit explicitly.

---

## 8. Limit fallback if Codex is unavailable

Per `LIMIT_FALLBACK.md`:

- **Quota cap mid-run** (`codex-cli` exits with rate-limit error):
  capture whatever stdout was produced into the report, mark status
  `quota-hit`, and **continue without Codex** — Claude Code
  performs the same self-audit in its own context.
- **Auth failure** (`/codex:setup --json` would now show
  `loggedIn: false`): mark status `blocked`, surface the
  remediation (`!codex login`) to the maintainer, and **continue
  without Codex** for this round.
- **Background hang** (run exceeds 10 minutes): `/codex:cancel`,
  mark status `cancelled`, **continue without Codex**.
- **Hallucinated output** (clean exit, but findings fail
  adversarial review): mark status `rejected`, **continue without
  Codex**.
- **`codex-cli` crash / plugin breakage**: mark status `blocked`,
  log the diagnostic to `TRIAL_LOG.md`, **continue without Codex**.

In every case the trial does not block on Codex. The senior-engineer
self-audit happens regardless; Codex is purely an attention
optimiser.

If Codex is structurally unavailable for this first run, that itself
is a useful signal — it means the trial fell at the first hurdle and
the maintainer can decide whether to debug the plugin or kill the
trial.

---

## 9. Hand-off (mirrors TASK_TEMPLATE.md §9)

- Captured stdout: `.ai/codex/reports/2026-05-01-review-onboarding-pack.md`.
- TRIAL_LOG.md line appended after capture.
- No commits in this round.
- Maintainer is shown verbatim output + Claude Code's adoption
  decisions before any pack edit.

---

**Last updated:** 2026-05-01T01:21:12Z (initial draft, pre-invocation).
