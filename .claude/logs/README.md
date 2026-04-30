# Pipeline Logs

This directory holds **append-only logs** from auto-pipeline runs.

## Files

### `verifier-stats.json` — per-crop pipeline outcomes

JSON-lines log written by the Content Verifier after every pipeline run.
One line per run.

Original (v1) schema:

```json
{
  "date": "YYYY-MM-DDTHH:mm:ssZ",
  "crop_slug": "...",
  "blockers": <int>,
  "medium_issues": <int>,
  "minor_issues": <int>,
  "urls_total": <int>,
  "urls_failed": <int>,
  "sources_cited": <int>,
  "decision": "pass" | "fail" | "fixed",
  "auto_fixes_applied": <int>
}
```

Optional fields seen in real entries:
`halt_stage`, `root_cause`, `note`, `verification_pass`.

**v2 (Day-1 reliability instrumentation, 2026-04-30):**
new entries SHOULD also include:

- `run_id` — uuid joining this entry to per-stage `subagent-dispatch.json` rows
- `manual_intervention_required` — boolean
- `intervention_type` — one of `none | script-patch | content-edit | stage-substitution`
- `failure_type` — one of `none | tool-execution | retrieval | generation-contract | verification | publish`

The new fields are additive. Old entries are still valid; readers should
treat missing fields as the v1 default (no run_id, no intervention info).

### `subagent-dispatch.json` — per-dispatch verification (Day 1, NEW)

JSON-lines log written by `scripts/subagent-output-verify.sh` after every
subagent dispatch that claims to write files. Each line records what the
subagent claimed vs. what is actually on disk.

Schema (`schema_version: "v2-day1"`):

```json
{
  "schema_version": "v2-day1",
  "date": "YYYY-MM-DDTHH:mm:ssZ",
  "run_id": "<uuid joining to verifier-stats.json>",
  "stage": "drafter | content-verifier | researcher | ...",
  "agent": "drafter | content-verifier | ...",
  "files_claimed_written": <int>,
  "files_verified_existing": <int>,
  "files_failed": <int>,
  "tool_calls_claimed": <int, optional>,
  "verification_status": "pass | fail",
  "failure_type": "subagent-dispatch-failure",   // only when status=fail
  "failure_detail": "<path>=<reason>; ..."        // only when status=fail
}
```

**Why this exists.** Between 2026-04-29 and 2026-04-30, four documented
incidents (cassava pass-3 verifier, mango researcher, mango drafter, mango
verifier x2) showed subagents reporting successful tool calls when no files
were actually written or modified. That is Category A in
`docs/PIPELINE_FAILURES.md` — *tool execution failure*. This log makes the
discrepancy machine-detectable: the orchestrator runs
`scripts/subagent-output-verify.sh` after every dispatch and the script
records the outcome here.

**How to read it.**

- Filter by `stage` to see per-stage reliability:
  `grep '"stage":"drafter"' subagent-dispatch.json | wc -l`
- Filter by `verification_status:"fail"` to count Category A incidents:
  `grep '"verification_status":"fail"' subagent-dispatch.json`
- Join to `verifier-stats.json` via `run_id` to link a dispatch failure
  back to the crop run that triggered it.

## Convention

- Logs ARE committed to git (kept for the trail of pipeline behavior over time).
- New entries always appended to the file end (no truncation, no rewriting past entries).
- Use these to spot pipeline drift (rising blocker rate, falling source count,
  rising subagent dispatch failures, etc.) per `docs/WORKFLOW_KIT.md`
  A/B testing convention.
- Do not edit historical lines — corrections go into a new line with a
  `note` field referencing the prior line's `run_id` or timestamp.
