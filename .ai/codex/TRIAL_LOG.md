# Codex Intern Trial Log

> Append-only log of Codex tasks dispatched during the trial on branch
> `chore/codex-intern-trial`. Updated by Claude Code, never by Codex,
> never directly by the maintainer mid-task.

Schema (one line per dispatch):

```
- YYYY-MM-DDThh:mm:ssZ | task-slug | sanctioned-use-case-# | outcome | one-sentence-note
```

`outcome` is one of:
- `accepted` — Codex output passed Claude Code adversarial review and
  informed real work.
- `accepted-partial` — partial output adopted as-is (e.g., quota cap
  truncated the run but the partial was useful).
- `rejected` — output failed adversarial review (hallucination, scope
  drift, misquote); Claude Code performed the same work in-context.
- `re-dispatched` — invocation reissued after a brief revision.
- `quota-hit` — Codex hit Plus cap; see LIMIT_FALLBACK.md for the
  path Claude Code took.
- `blocked` — Codex returned a blocker note (out-of-scope brief,
  forbidden path, secrets surface, etc.); brief revised.
- `cancelled` — invocation `/codex:cancel`'d before completion.
- `rescue-approved` — special status for the rare maintainer-approved
  rescue invocation; must be paired with a prior approval line.

`sanctioned-use-case-#` is one of (plugin mode v1):
- `review-default` — `/codex:review` invocation (default-allowed,
  read-only).
- `adversarial-review` — `/codex:adversarial-review` invocation
  (default-allowed, read-only, design challenge framing).
- `rescue-approved` — `/codex:rescue` invocation gated behind an
  explicit prior `rescue-approval-<NN>` line in this log per
  RULES.md §B13. Forbidden by default; requires maintainer
  approval and §B17 absolute write boundary still applies.
- `ad-hoc` — maintainer-approved one-off outside the above; the
  approval line must precede the invocation line in this log.

---

## Trial open

- 2026-05-01T00:00:00Z | trial-open | n/a | n/a | Branch `chore/codex-intern-trial` opened. `.ai/codex/` onboarding pack created (copy-paste v0). No Codex dispatches yet.
- 2026-05-01T08:00:00Z | plugin-mode-upgrade | n/a | n/a | `codex-plugin-cc` installed; `/codex:setup --json` reports ready (codex-cli 0.128.0, ChatGPT login active for premkung87@gmail.com). Onboarding pack rewritten to plugin-mode v1: review-only default-allowed, `/codex:rescue` gated behind §B13. No invocations yet.

---

## Dispatches

> Append below this line. Do not rewrite past entries. If a past
> dispatch is later reclassified, add a new line referencing the prior
> timestamp; both stay in place. Mirror of WORKFLOW_KIT.md §13 update
> rule.

- 2026-05-01T01:26:00Z | review-onboarding-pack | review-default | accepted | All 3 findings verified against repo state; pack edits pending maintainer authorization (F1 is 🟡 — security-adjacent §B14 carve-out).
- 2026-05-01T01:35:00Z | review-onboarding-pack-fixups | n/a | edits-applied | E2 (REPORT_TEMPLATE.md L20: `rejected` added to status enum) and E3 (REPORT_TEMPLATE.md §1: full verbatim stdout always required, summary may accompany but never replace) applied per maintainer authorization. E1 deferred: maintainer requested exact diff for §B14 carve-out before approval — security-adjacent.
- 2026-05-01T01:42:00Z | review-onboarding-pack-fixups-e1 | n/a | edits-applied | E1 applied exactly as shown in the proposed diff per maintainer authorization. RULES.md §B14 rewritten with explicit Trigger / Documentation-carve-out sections. Trigger preserves all real-credential blocking (PEM keys, assignment-RHS for `*_KEY=`/`*_SECRET=`/`*_TOKEN=`/`API_KEY=`/`PASSWORD=`/`DATABASE_URL=`, ≥32-char service-token regexes, §A1.x file backstop). Carve-out exempts only documented heuristic prose inside `.ai/codex/` `.md` files when all three conditions hold (code-span context + placeholder/explanatory wording + no real value adjacent). Doubt → abort. All three Codex review findings now closed.
- 2026-05-01T02:00:00Z | codex-trial-audit-entry | adversarial-review | accepted | 1 finding (Important, borderline-Critical): audit entry's L24 wording contradicts L23 by literal reading; rewrite-and-apply proposed, pending maintainer authorization. Audit-log entry remains in working tree, uncommitted.
- 2026-05-01T02:08:00Z | codex-trial-audit-entry-fixup-f1 | n/a | edits-applied | F1 applied exactly as shown in the proposed diff per maintainer authorization. AUDIT_LOG.md L24 rewritten to explicitly carve out the required report-capture artifact as the sole sanctioned location for verbatim Codex stdout, while preserving the zero-copy-paste rule for pack edits, policy doc edits, audit-log prose, commit messages, and other authored content. L23/L24 contradiction resolved. Audit-log entry remains in working tree, uncommitted, awaiting maintainer commit decision.
- 2026-05-01T02:26:00Z | codex-trial-workflow-kit-entry | review-default | accepted | 2 findings (both Important, both Codex P3): F1 = bare `RULES.md` references should use full `.ai/codex/RULES.md` path consistent with audit-log source; F2 = "above" should be "below" since file is reverse-chronological. Both rewrite-and-apply proposed, pending maintainer authorization. WORKFLOW_KIT entry remains in working tree, uncommitted.
- 2026-05-01T02:34:00Z | codex-trial-workflow-kit-entry-fixup-f1-f2 | n/a | edits-applied | F1 + F2 both applied exactly as shown in proposed diffs per maintainer authorization. WORKFLOW_KIT.md L72 "above" → "below" (direction now matches reverse-chronological file ordering). WORKFLOW_KIT.md L74 bare `RULES.md` references replaced with single full-path declaration `.ai/codex/RULES.md` followed by bare `§B13`/`§B14`/`§B17` refs (consistent with AUDIT_LOG.md source). Both cross-reference errors resolved. WORKFLOW_KIT entry remains in working tree, uncommitted, awaiting maintainer commit decision.
- 2026-05-01T02:52:00Z | codex-trial-pawee-extension | adversarial-review | accepted | 1 finding (Critical, first of trial): §21's generic abstraction encodes Kaset-Atlas-specific docs-only write boundary as universal requirement — leaks project-specific isolation choice into the cross-project rule. Structural rewrite-and-apply proposed (Principle + Why-it-works bullet + How-to-apply step 4 + Stack-specific expansion + new anti-pattern), pending maintainer authorization. §21 file remains in working tree, uncommitted.
- 2026-05-01T03:02:00Z | codex-trial-pawee-extension-fixup-f1 | n/a | edits-applied | F1.1–F1.5 all applied per maintainer authorization. (1) Principle revised to drop docs-only universal requirement; gated approval now names bounded target paths + isolation + rollback. (2) Why-it-works bullet 2 rewritten to match. (3) How-to-apply step 4 rewritten as "Approved-write isolation, scaled to risk" with mechanism options (docs-only / feature branch / worktree / scope-restricted dir / sandbox VM). (4) New Stack-specific bullet added naming Kaset Atlas trial v1 docs-only choice as a concrete example of step 4. (5) New anti-pattern added warning against encoding project-specific isolation choices as universal mandates. Senior-cleanup: F1.1's literal fragment swap created a momentary duplicate clause in the Principle paragraph (because the surrounding sentence already contained "write-capable surface stays gated behind explicit per-invocation approval"); the duplicate was collapsed in a follow-up Edit consistent with the maintainer's stated rationale and rewrite intent — single clause, no duplicated wording. Critical finding now closed. §21 file remains in working tree, uncommitted, awaiting maintainer commit decision.
- 2026-05-01T13:10:00Z | jsonld-component-review | review-default | accepted-with-scope-caveat | Phase 6 first production-code review. Codex returned 0 findings in <1 min against working-tree diff (`src/components/JsonLd.astro` +2/-0 documentation comment). Honest result for the diff Codex saw, but the diff was the 2-line comment we added to pull the file into scope — Codex did NOT review the substantive 24 lines of Astro / TypeScript / JSON-LD rendering code. Empirical learning: /codex:review --scope working-tree reviews the diff, not the whole file. To review committed production-code substance via this plugin, a different mechanism is needed (substantive working-tree edit, --scope branch with pre-creation base, or non-Codex senior review). Daily Codex budget now 5/5 for 2026-05-01; next earliest invocation is 2026-05-02. JsonLd.astro working-tree edit and untracked task brief remain in working tree, awaiting maintainer decision on commit / restore / defer.
- 2026-05-02T22:57:30Z | rescue-approval-01 | n/a | approval | Maintainer authorized one /codex:rescue invocation against the safest possible target: create one new file at .ai/codex/drills/2026-05-02-hello-world.md (new file, new directory). Allowed write surface: that single path only. Forbidden: every other file in the repo, including all .ai/codex/ governance docs and historical paperwork (per RULES.md §B17 absolute write boundary, even with this approval). Rollback command: `rm -rf .ai/codex/drills/`. Success: file exists with the exact content specified in the rescue prompt; no other paths touched; no git operations; no shell commands beyond strict file-write. Failure: any deviation. Drill purpose: validate the rescue-mode contract (RULES.md §B13 invocation gating + §B17 absolute write boundary) end-to-end on the lowest-stakes possible target before considering any future production-adjacent rescue use case. Maintainer's typed approval recorded in 2026-05-01 chat ("approve drill design as proposed; execute tomorrow"); this line is the §B13-step-2 pre-invocation log. Brief: .ai/codex/tasks/2026-05-02-rescue-drill-01.md.
- 2026-05-02T23:00:25Z | rescue-drill-01 | rescue-approved | accepted | First /codex:rescue invocation in trial history. Phase 7 hello-world drill executed in ~12s (codex session 019de5c5-6e8c-7820-8f0f-21612d685a2a, companion job task-monimzlf-uf7yyu). All 7 success criteria met: file `.ai/codex/drills/2026-05-02-hello-world.md` created at exact path with byte-perfect content (95 bytes, single line + trailing newline, verified via od -c); git status shows only expected new untracked entries; HEAD unchanged from 8ceb1d8; origin/main unchanged from 8ceb1d8; no other file modified; session log shows only "Applying 1 file change(s)" with zero shell commands or git operations. Self-consistency 5/5 pass. Boundary attestation: §B13 + §B17 + §B16 all honored end-to-end. Rescue-mode contract empirically validated on lowest-stakes target. Drill artifact + brief + report remain in working tree, awaiting maintainer commit-or-discard decision per Phase 7 §12.

---

## Trial review checkpoints

> At every Nth dispatch (default N=5), Claude Code summarises the
> trial-to-date below. The summary is read-only context for the
> maintainer's keep / kill decision. No format is enforced; one short
> paragraph per checkpoint.

<!-- first checkpoint at dispatch #5 -->

---

## Trial close

> When the trial ends — keep, kill, or extend — the final line is
> written here with the decision and a link to the commit that either
> integrated Codex into the workflow or deleted `.ai/codex/`.

<!-- final entry goes here -->

---

**Last updated:** 2026-05-01 (trial v0 — onboarding pack created).
