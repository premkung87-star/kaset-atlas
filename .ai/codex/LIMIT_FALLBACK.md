# ChatGPT Plus Limit Fallback (Plugin Mode v1)

> What happens when Codex hits a quota cap during a `/codex:*`
> invocation. Designed so the Kaset Atlas workflow continues without
> Codex if needed.

---

## 1. Why this file exists

Codex runs locally on the maintainer's machine via `codex-cli`,
authenticated against a **ChatGPT Plus** account
(`premkung87@gmail.com` per `/codex:setup --json` at trial open). Plus
has caps:

- Per-window message caps that reset on a rolling basis.
- Per-day reasoning / Codex turn caps that reset daily.
- Background-task concurrency limits.

The exact numbers move; the operating posture does not. The workflow
is designed around the assumption that **any single Codex invocation
might fail or be the last one until reset**.

---

## 2. Failure surfaces (plugin mode)

The plugin can fail in several distinguishable ways; Claude Code
treats most of them identically.

| Surface | What it looks like | Codex stdout / exit |
|---|---|---|
| Quota exceeded | "rate limited" / "usage cap reached" message in stdout | typically non-zero exit |
| Auth failure | "ChatGPT login required" or token expired | non-zero exit; `/codex:setup` would show `loggedIn: false` |
| Background task hang | `/codex:status` reports running past expected duration | use `/codex:cancel` |
| Codex returns hallucinated finding | exit 0 but content fails Claude Code's adversarial review | captured in REPORT_TEMPLATE.md §2 as `reject` decisions |
| `codex-cli` crash / segfault | non-zero exit with stack trace | rare; treat as quota-equivalent |

In all of the failure cases, Claude Code's response is the same:
**continue without Codex.**

---

## 3. Codex's behaviour when it hits a quota cap mid-run

If Codex CLI surfaces a quota / rate-limit message during execution:

1. **Stop.** Do not retry inside the same invocation. The plugin's
   `codex-companion.mjs` will surface the error in stdout; Claude
   Code captures whatever was produced before the cap hit.
2. **Surface the cap clearly.** The CLI's error text is part of the
   stdout that Claude Code captures verbatim into REPORT_TEMPLATE.md
   §1; Claude Code marks the report status `quota-hit`.
3. **Do not silently downgrade.** If the CLI offers a "continue with
   smaller model" path, Codex must not take it without the
   invocation brief explicitly authorising a model change. Different
   model = different review posture; not an automatic equivalent.

---

## 4. Claude Code's behaviour when Codex returns `quota-hit`

Claude Code treats Codex availability as **unreliable by design**. The
fallback path is:

1. Read the partial output. Apply the standard adversarial review on
   whatever findings did make it out (REPORT_TEMPLATE.md §2).
2. Decide one of three things:
   - **Adopt the partial.** If the partial findings are useful,
     accept them, log it in TRIAL_LOG.md as `accepted-partial`, and
     proceed with the senior-engineer work that originally needed the
     review.
   - **Re-dispatch later.** If reset is hours away and the work is
     not blocking, schedule a single re-run later in the day. Log the
     intent in TRIAL_LOG.md.
   - **Do it without Codex.** Default. Claude Code performs the same
     review in its own context and ships. The trial never blocks the
     senior agent on Codex availability.
3. **Never** ask the maintainer to "wait for ChatGPT to reset". That
   inverts the no-relay rule from INTERN_ONBOARDING.md §5.

---

## 5. Permanent Codex unavailability

If Codex becomes structurally unavailable (account suspended,
ChatGPT outage, plugin breakage, codex-cli deprecated, Plus
cancelled), the workflow continues with Claude Code alone with **no
functional loss**.

If unavailability lasts beyond the trial window, Claude Code:

1. Logs a final entry in TRIAL_LOG.md noting unavailability.
2. Stops drafting Codex invocation briefs.
3. Optionally proposes deletion of the entire `.ai/codex/` directory
   AND uninstall of `codex-plugin-cc` in one cleanup pass — subject
   to maintainer signoff (deleting docs is 🟡 per CLAUDE.md §6).

---

## 6. Things Codex must NOT do under quota pressure

- **Switch models silently** to keep working. The codex-cli rescue
  agent definition leaves model unset by default; Codex must not
  override that on the way to satisfying a brief.
- **Continue past the cap with a stale session.** `--resume-last`
  after a quota hit can produce inconsistent context; per RULES.md
  §B16 each new invocation defaults to `--fresh`.
- **Persist partial findings into a future invocation** without
  Claude Code re-issuing the brief. No memory bleed.
- **Ask the human for more turns.** The maintainer is not the relay.

---

## 7. Cost / quota hygiene (preventive)

To keep Plus headroom across the trial:

- Default invocations to `--background` for anything not clearly tiny
  (review.md guidance). Background runs let Claude Code keep working
  while Codex thinks.
- Scope reviews tightly — `--scope working-tree` or
  `--scope branch <name>` rather than ambient repo crawls.
- Do not run Codex against branches whose only delta is in
  `docs/` unless the change touches policy logic; doc-only diffs
  rarely benefit from a code-review pass.
- Honor INTERN_ONBOARDING.md §3 hard budget: ≤ 5 invocations per
  maintainer-day during the trial.
- Skip Codex entirely on chores Claude Code handles well in-context
  (small edits, single-file refactors, doc tweaks).

---

**Last updated:** 2026-05-01 (plugin-mode v1).
