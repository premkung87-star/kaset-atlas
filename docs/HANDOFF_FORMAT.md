# Exception Handoff Format

> Phase 8 v1, 2026-05-02. The single human-readable artifact a `/add-crop` run produces at the end. Replaces the old "screenshot the live transcript and decide" loop.

---

## Where it lives

`.claude/runs/<run_id>/handoff.md`

The directory is gitignored (`.gitignore` includes `.claude/runs/*` except `.gitkeep`). Per-run artifacts are local-only by default; promotion to a published audit entry is the Decision Agent's job and lands in `docs/AUDIT_LOG.md`.

---

## Required structure

```markdown
# Handoff for <Thai name> (<English name>) — run <run_id>

**Status:** green | yellow | red
**Crop slug:** <slug>
**Lane decided at:** <stage where the lane was determined>
**Started at:** <ISO timestamp>
**Ended at:** <ISO timestamp>

## Stage outcomes

| Stage | Outcome | Detail |
|---|---|---|
| Researcher | green/yellow/red | one-line summary |
| Drafter | green/yellow/red | one-line summary |
| URL Verifier | green/yellow/red | n/m URLs alive |
| Build Verifier | green/yellow/red | n pages built |
| Content Verifier | green/yellow/red | b blockers, m medium, μ minor |
| Subagent-output-verify | green/yellow/red | per-stage verdict |

## Auto-decisions applied (yellow only)

- <decision> — <rule from AUTONOMY_LANES.md that authorized it>
- ...

(empty for green and red runs)

## Decisions needed (red only)

1. <issue> — <suggested resolution>
2. ...

(empty for green and yellow runs)

## Files changed

- src/content/crops/<slug>.mdx
- src/content/crops/<slug>.reasoning.json
- docs/AUDIT_LOG.md
- .claude/logs/verifier-stats.json

## Suggested next action

<ONE concrete suggestion, e.g., "Run `git push origin main`." or "Patch <file> at line <N> per finding 1, then re-run /add-crop with same crop name (resumes from checkpoint).">

## Run telemetry

- Tool-use counts: researcher=<N>, drafter=<N>, verifier=<N>
- Auto-fixes applied: <N>
- Yellow conditions accumulated: <N>
- Verifier pass-rate (last 20 runs): <X>%
```

---

## Reading discipline

The handoff is the **only** artifact the maintainer needs to read for a routine green-lane crop.

- 🟢 Green handoff: glance at "Suggested next action", run `git push`.
- 🟡 Yellow handoff: read "Auto-decisions applied", confirm none surprise. If all are routine, run `git push`.
- 🔴 Red handoff: read "Decisions needed", resolve, then re-run `/add-crop <slug>` (resumes from checkpoint).

If a green or yellow handoff would take more than 60 seconds to review, the format has failed its purpose — file a `docs/PIPELINE_FAILURES.md` entry and tighten the schema.

---

## What the handoff replaces

1. The old "live transcript screenshot pasted to ChatGPT" loop.
2. The old "step through five verifier outputs by hand" check.
3. The old "guess at what auto-fix changed and whether it was OK" diff inspection.

By design, the handoff is the only thing a human reads per run.

---

## What the handoff does NOT contain

- Full agent transcripts. Those live in tool-result logs and `.claude/logs/subagent-dispatch.json`.
- Full source content of cited references.
- Per-claim verifier reasoning beyond what fits in a one-line summary.
- Recommendations the maintainer didn't authorize. (No "you should also …" — the suggested next action is one concrete step.)

---

## When the handoff is written

- Green-lane: at the end of the run, after Content Verifier passes.
- Yellow-lane: incrementally — each stage that exits yellow appends its auto-decisions; the final summary header is filled in at end-of-run.
- Red-lane: at the moment of halt. The pipeline writes the handoff and exits.

---

## Cross-references

- Lane definitions: `docs/AUTONOMY_LANES.md`
- Pipeline orchestration: `.claude/commands/add-crop.md`
- Failure log (cumulative across runs): `docs/PIPELINE_FAILURES.md`
- Permanent audit log: `docs/AUDIT_LOG.md`

---

## Last updated

2026-05-02 — Phase 8 v1.
