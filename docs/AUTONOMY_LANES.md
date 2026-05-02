# Autonomy Lanes — Kaset Atlas Crop Pipeline

> Phase 8 v1, 2026-05-02. Codified rules so `/add-crop` runs end-to-end with **0–1 human relay rounds** instead of 7–8.
>
> This document is the authoritative source of lane policy. The runtime pipeline (`.claude/commands/add-crop.md`, agent prompts, verifier scripts) has not been modified in Phase 8 — this document declares the policy that future pipeline updates will implement.

---

## Why this exists

Before Phase 8, every `/add-crop` run forced the maintainer to make 7–8 human screenshot-relay decisions:

1. Approve the Researcher's source list.
2. Approve the Drafter's MDX.
3. Approve the URL Verifier output.
4. Approve the Build Verifier output.
5. Approve the Content Verifier's findings.
6. Decide whether the auto-fix retry should run.
7. Decide commit message and whether to push.
8. Audit the final result.

That model does not scale to 500 crops. The bottleneck is not Claude Code — it is the maintainer being asked to make the *same kind of decision* repeatedly. Every one of those decisions is replaced here with a written rule.

---

## The three lanes

```
Researcher ──► Drafter ──► URL Verifier ──► Build Verifier ──► Content Verifier ──► Commit
     │            │              │                │                    │             │
     ▼            ▼              ▼                ▼                    ▼             ▼
   thresholds  schema      url liveness      build output         findings       handoff.md
     │            │              │                │                    │             │
     └────────────┴──────────────┴────────────────┴────────────────────┴─────────────┘
                                          │
                                          ▼
                              ┌──────────────────────┐
                              │  Lane decision tree  │
                              └──────────────────────┘
                                          │
                ┌─────────────────────────┼─────────────────────────┐
                ▼                         ▼                         ▼
            🟢 GREEN                  🟡 YELLOW                  🔴 RED
   continue silently to end   continue, log to handoff   halt at this stage
   write GREEN handoff        write YELLOW handoff       write RED handoff
   stop short of git push     stop short of git push     stop, do not retry
```

Every gate exit is one of `green`, `yellow`, or `red`. **Green and yellow both continue.** Only red halts.

---

## 🟢 Green Lane — Run end-to-end without asking the human

A run is green at a given stage if **every** condition for that stage is met.

### Researcher
- `minimum_sources_met: true`
- `thai_sources_count` ≥ 6
- `international_sources_count` ≥ 3
- `high_confidence_count` ≥ 4
- All URLs `url_verified: true`

### Drafter
- `status: "draft_complete"`
- `self_validation_passed: true`
- File exists at returned `file_path`
- `<slug>.reasoning.json` sidecar exists
- `scripts/check-mdx-safety.sh` → 0 unsafe patterns
- `scripts/verify-source-table.sh` → `verification_status: pass`
- `scripts/verify-claim-grounding.sh` → `verification_status: pass`
- `scripts/subagent-output-verify.sh` → `verification_status: pass`

### URL Verifier
- `verification_status: pass`, 100% URLs alive

### Build Verifier
- `build_status: pass`, expected page count

### Content Verifier
- `blockers: 0`
- `medium_issues: 0` or `medium_issues: 1` with `auto_fixes_applied: 0`
- `subagent-output-verify` pass

### End-of-run
- All previous stages green.
- Pipeline writes `handoff.md` containing `Status: green`, lists files changed, prints commit-ready message.
- **Pipeline stops short of `git push`.** The human runs `git push` after a 30-second glance at `handoff.md`.

(Auto-push is the Phase 9 question. Phase 8 keeps the human as the sole signer.)

---

## 🟡 Yellow Lane — Continue, collect into one handoff

A condition is yellow when something is not perfectly green but is **codified-machine-decidable** as safe to continue. Yellow conditions never halt the pipeline mid-run; they accumulate into `handoff.md`.

### Yellow conditions and the rule that authorizes auto-continuation

| Stage | Condition | Auto-decision |
|---|---|---|
| Researcher | Just-meets thresholds: `thai_sources_count == 6` exactly | continue; log "researcher just met Thai threshold" |
| Researcher | `high_confidence_count == 4` exactly | continue; log "researcher just met high-confidence threshold" |
| Drafter | Source table at exactly 9 (project minimum) instead of 12+ | continue; log table size |
| Drafter | A section that the reasoning sidecar rated `high` is downgraded to `medium` during inline checks | continue; log section + downgrade reason |
| Content Verifier | `medium_issues` 1–3 AND `auto_fixes_applied` succeeds on first try | continue; log diff summary |
| Content Verifier | Auto-fix succeeds with non-trivial diff (>10 lines changed) | continue; log full diff in handoff |
| Subagent-output-verify | Mtime check passes BUT tool-call count is below the agent's typical band | continue; log discrepancy as warning |

### Yellow accumulation rule

If **≥3 unrelated yellow conditions** accumulate in a single run, the pipeline escalates to red at the next stage boundary. Three yellows = "something systemic is going on, ask the human once".

### What yellow does not include

- Any error from a verifier script (those are red).
- Any safety-policy edge case (red — see §Red lane).
- Any source-policy edge case where translation length or quote length is uncertain (red).

---

## 🔴 Red Lane — Stop once with a complete handoff

Red conditions halt the pipeline at the offending stage. The pipeline:

1. Writes the failure to `docs/PIPELINE_FAILURES.md` with full diagnostic.
2. Writes `handoff.md` with `Status: red`, the stage, the issue, and a suggested resolution.
3. Leaves `.claude/state/pipeline-current.json` in place so the human can resume after fixing.
4. Exits non-zero. Does not retry.

### Red conditions

- `.claude/HALT` flag exists.
- Researcher fails any threshold check.
- Drafter `self_validation_passed: false`.
- Drafter schema cap exceeded (frontmatter array > schema-allowed length).
- Drafter MDX safety check finds any unsafe `[<>][a-z0-9]` JSX pattern.
- URL Verifier any URL `url_verified: false`.
- Build Verifier `build_status: fail`.
- Content Verifier `blockers ≥ 1`.
- Content Verifier `medium_issues ≥ 4`.
- Content Verifier auto-fix retry fails.
- Subagent-output-verify `verification_status: fail` (Category A tool-execution failure — never auto-retry).
- SOURCE_POLICY violation (long quote, unauthorized translation, paywalled-source uncited).
- SAFETY_POLICY violation (chemical dosage, identification claim, medical claim, yield/profit guarantee).
- Rate limit hit (max 5 runs/hour, max 50 crops/day).

### What red does not authorize

- Red **does not** authorize the pipeline to mutate the source MDX or sidecar to "fix" the issue. The pipeline halts; the human or a separate authorized retry resolves the issue.
- Red **does not** authorize automatic Codex consultation. Codex use is governed separately (`.ai/codex/RULES.md`).

---

## What Claude Code may continue without human input

- All-green stages.
- Yellow conditions explicitly listed in the table above.
- Yellow + green mixed within a run, until accumulation threshold (≥3 unrelated yellows triggers escalation).

## What Claude Code must stop on with a complete handoff

- Any red condition in §Red lane.
- ≥3 unrelated yellow conditions accumulated.
- Verifier script crashes (exit ≥ 2).
- Any state checkpoint write failure.

## What Claude Code may auto-commit / auto-push

**Phase 8 answer: nothing.** The pipeline writes `handoff.md` and stops. The human runs `git push` after one glance.

**Phase 9 future answer (not active today):** auto-commit + auto-push permitted only when:

1. Lane = green (no yellow entries in handoff).
2. Verifier pass-rate over the last 20 runs ≥ 95% (computed from `.claude/logs/verifier-stats.json`).
3. `.claude/state/auto-push.json` exists with `enabled: true` and `enabled_at` ≤ 7 days ago (auto-expires; explicit re-enable required).
4. `.claude/HALT` is absent.

Activating Phase 9 is its own decision — separate task, separate audit-log entry.

---

## Mapping back to the 7–8 relay rounds

| Old round | New behavior | Lane |
|---|---|---|
| 1. Approve Researcher | Threshold check codified above | green or red |
| 2. Approve Drafter MDX | check-mdx-safety + verify-source-table + verify-claim-grounding | green or red |
| 3. Approve URL Verifier | already deterministic | green or red |
| 4. Approve Build Verifier | already deterministic | green or red |
| 5. Approve Content Verifier | yellow rules above | green / yellow / red |
| 6. Decide auto-fix retry | "single try, succeed or escalate" rule | yellow if succeeds, red if not |
| 7. Decide commit/push | Phase 8: human reads handoff and runs `git push` | n/a |
| 8. Final audit | `handoff.md` is the single artifact | n/a |

Net effect after Phase 8: **0 mid-run relay rounds**, **1 end-of-run review** (read `handoff.md`, run `git push`).
After Phase 9 with auto-push: **0 rounds for green-lane crops**.

---

## Authority + scope

- This document is policy text. It does not modify the runtime pipeline.
- Pipeline updates that *implement* these lanes happen in a separate, explicit task with their own audit-log entry.
- Changes to this document are 🔴 risk per `CLAUDE.md` §6 (rule changes) and require explicit maintainer approval.

## Last updated

2026-05-02 — Phase 8 v1.
