# Codex Review Report — Capture Template (Plugin Mode v1)

> Claude Code uses this template **after** a `/codex:*` slash command
> finishes, to capture the verbatim Codex stdout and the senior
> engineer's adversarial review of it. Codex itself does not author
> this file.
>
> The structure is fixed because the maintainer's keep-or-kill
> decision on the trial depends on being able to scan these reports
> mechanically.

Copy the block below for every report. File naming:
`.ai/codex/reports/<YYYY-MM-DD>-<slug>.md` where `<slug>` matches the
invocation brief's slug.

---

## Codex review report: `<task-slug>`

**Status:** `<one of: complete | partial | blocked | rejected | quota-hit | cancelled>`
**Invocation brief:** `.ai/codex/tasks/<YYYY-MM-DD>-<slug>.md`
**Slash command run:** `<the exact command, e.g. "/codex:review --background --scope working-tree">`
**Started at:** `<UTC ISO>`
**Finished at:** `<UTC ISO>`
**codex-cli version:** `<from /codex:setup --json output, e.g. "0.128.0">`
**ChatGPT auth account:** `<from setup, e.g. "premkung87@gmail.com">`
**Job id:** `<from /codex:status if backgrounded; "n/a" if foreground>`

---

### 1. Verbatim Codex stdout

> Required. The raw, unmodified output of the slash command — no
> paraphrasing, summarising, or editorial trimming. If the output is
> too large to inline comfortably, paste the full verbatim stdout
> into a sibling file
> `.ai/codex/reports/<slug>.codex-stdout.txt` and link to it from
> inside this section. The report may also include Codex's executive
> summary inline as a courtesy, but **the summary never replaces the
> verbatim capture** — full stdout must always be preserved
> somewhere reachable from this section.

```
<paste verbatim stdout here>
```

---

### 2. Senior-engineer adversarial review (Claude Code)

> Required. Claude Code re-reads every file Codex referenced and
> independently verifies. Mirror of Content Verifier Step 9.5
> self-consistency check (`WORKFLOW_KIT.md §4` 2026-04-30).

For each finding Codex surfaced:

| Finding ID (Codex) | Finding summary | Cited file:line | Re-read result | Adoption decision |
|---|---|---|---|---|
| `<id or "F1">` | `<one-line restatement>` | `<path:lines>` | `<verified | not-found | misquoted | partial>` | `<accept-as-text | reject | rewrite-and-apply | defer>` |

Adoption decisions:
- `accept-as-text` — finding is correct; Claude Code records it but
  takes no production action (e.g., it was an observation, not a
  defect).
- `reject` — finding does not survive re-read (hallucination,
  misquote, scope error).
- `rewrite-and-apply` — finding has merit but Claude Code re-types
  the fix from scratch; zero copy-paste of Codex's suggested patch.
- `defer` — valid finding, will be addressed in a future scoped
  change; logged in `docs/AUDIT_LOG.md` if material.

---

### 3. Self-consistency check on Codex output

> Required. Same posture as the Content Verifier. Claude Code (not
> Codex) ticks each box.

- [ ] Every file path Codex cited exists in the repo at that path.
- [ ] Every line range cited is bracketed by the file's actual line
      count.
- [ ] Every verbatim quote in §1 can be grep'd from the cited file.
- [ ] No finding proposes a fix that touches forbidden paths
      (RULES.md §B1–§B4).
- [ ] Codex did not modify any file (review-only mode) OR every
      modified file is inside `.ai/codex/` and matches the
      pre-approved scope (rescue mode, §B13).

`Result: <pass | fail — with reason>`

If `fail`, the report status above must reflect it (`partial`,
`blocked`, or `cancelled`) and the offending findings must be
explicitly rejected in the §2 adoption decisions.

---

### 4. Boundary attestation

> Required. One short paragraph from Claude Code stating which
> RULES.md §B prohibitions were tempted by the Codex output and were
> declined. If the output triggered no boundary pressure, write "no
> boundary pressure on this invocation".

`<paragraph>`

---

### 5. Quota / cost surface

- Plus-quota warnings observed during the run: `<yes/no, with text>`
- Estimated input tokens to OpenAI: `<rough>`
- Estimated output tokens: `<rough>`
- Did this invocation push the maintainer-day count toward the §3
  hard ceiling (≤ 5 invocations/day per INTERN_ONBOARDING.md)?
  `<remaining count>`

---

### 6. Outcome and TRIAL_LOG.md line

The single-line entry Claude Code appends to TRIAL_LOG.md after this
report is filed:

```
- <UTC ISO> | <task-slug> | <use-case-#> | <outcome> | <one-sentence note>
```

`outcome` must be one of the values defined in TRIAL_LOG.md.

---

## Worked example (review-onboarding-pack)

```
## Codex review report: review-onboarding-pack

**Status:** complete
**Invocation brief:** .ai/codex/tasks/2026-05-01-review-onboarding-pack.md
**Slash command run:** /codex:review --wait --scope working-tree
**Started at:** 2026-05-01T17:01:00Z
**Finished at:** 2026-05-01T17:04:18Z
**codex-cli version:** 0.128.0
**ChatGPT auth account:** premkung87@gmail.com
**Job id:** n/a (foreground)

### 1. Verbatim Codex stdout
<inlined or linked>

### 2. Senior review

| Finding | Summary | Cited | Re-read | Decision |
|---|---|---|---|---|
| F1 | "B17 contradicts B13's allowance for `.ai/codex/` writes" | RULES.md:215 | verified | rewrite-and-apply (clarify §B13 §4 path) |
| F2 | "INTERN_ONBOARDING.md §11 missing `--enable-review-gate` row" | INTERN_ONBOARDING.md:170 | not-found (already present) | reject |
| F3 | "TASK_TEMPLATE §6 should require commit SHA of approval" | TASK_TEMPLATE.md:50 | verified | defer (low priority) |

### 3. Self-consistency
Result: pass — F2 was a Codex misquote; rejected. F1 and F3 verified
against repo state.

### 4. Boundary attestation
No boundary pressure: review-only invocation, no edits proposed.
F1 adoption is a rewrite-and-apply by Claude Code, not a Codex patch.

### 5. Quota
- Plus warnings: no
- Input tokens (est): ~28000
- Output tokens (est): ~1800
- Day count: 1 of 5

### 6. TRIAL_LOG.md line
- 2026-05-01T17:04:18Z | review-onboarding-pack | review-default | accepted | F1 surfaced real precedence-rule contradiction; F2 hallucinated; F3 deferred.
```

---

**Last updated:** 2026-05-01 (plugin-mode v1).
