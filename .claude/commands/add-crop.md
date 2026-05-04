---
description: Add a new crop profile via the full auto pipeline (Researcher → Drafter → URL Verifier → Build Verifier → Content Verifier → Auto-commit). Hardened version with build gate, state checkpoint, verifier stats logging, existing-crops awareness, and confidence reasoning sidecar.
argument-hint: <crop name in Thai or English>
---

# /add-crop — Full Auto Pipeline (v2)

**Crop input:** $1
**Today:** capture from `date +%Y-%m-%d` for use in audit log + frontmatter.

## Operating principle: Read-then-dispatch (Tier 1.1)

Every subagent dispatch MUST read its canonical prompt fresh from disk at dispatch time. Do NOT embed stale copies of agent prompts into dispatch messages.

```
view .claude/agents/<name>.md
# Use the file's contents as the subagent system prompt
```

This ensures any update to the on-disk prompt takes effect on the next pipeline run without needing to retain prompt copies elsewhere.

## Operating principle: General-purpose dispatch only (Tier 1.4 — added 2026-04-30)

Every subagent dispatch in this pipeline MUST use `subagent_type: general-purpose` and embed the role's prompt text in the message. Do NOT use the dedicated `subagent_type: researcher` / `drafter` / `content-verifier` agent types.

**Why:** Four documented incidents on this project (durian, mango researcher, mango drafter, mango Content Verifier ×2, tomato resume #2) have shown the dedicated subagent paths producing Category A *tool-execution failures* — the agent renders `<function_calls>` blocks as plain text inside its assistant content without invoking the harness, so `tool_use` count is 0 across the whole dispatch despite a long, plausible-looking response. The 2026-04-30 tomato Option 1 controlled diagnostic confirmed `general-purpose` dispatch executes tool calls correctly with the same role prompts (researcher: 38 tool_use, drafter: 29 tool_use, content-verifier: 26 tool_use). See `docs/PIPELINE_FAILURES.md` and `docs/AUDIT_LOG.md` 2026-04-30 tomato entry.

**How to read the canonical prompt and embed it:** the read-then-dispatch principle (Tier 1.1) still applies — `view .claude/agents/<name>.md` first, then pass the file contents as part of the message text to a `general-purpose` subagent. The general-purpose agent has access to all tools the dedicated types had (Read, WebFetch, WebSearch, Bash, Edit, Write).

## Pre-flight (mandatory; halt on any failure)

1. Read `CLAUDE.md` (operating manual) — confirm operating mode is Definition B.
2. Read `docs/METHODOLOGY.md`.
3. Read `docs/SOURCE_POLICY.md`.
4. Read `docs/SAFETY_POLICY.md`.
5. Read `docs/AUTOMATION_PIPELINE.md`.
6. Read `docs/WORKFLOW_KIT.md` (current operational layer + active patterns).
7. `git status --porcelain` → must be empty (working tree clean).
8. `git branch --show-current` → must be `main`.
9. `test -f .claude/HALT` → must NOT exist.
10. Confirm crop "$1" not already drafted (`ls src/content/crops/`).
11. **Capture run identifiers (Day-1 instrumentation):**
    ```bash
    RUN_ID=$(uuidgen 2>/dev/null | tr '[:upper:]' '[:lower:]' || echo "run-$(date +%s)")
    RUN_STARTED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    ```
    `RUN_ID` joins per-stage `subagent-dispatch.json` rows to the per-crop
    `verifier-stats.json` row. `RUN_STARTED_AT` is the lower bound for any
    file mtime check (a subagent that writes a file should write it
    *after* the dispatch began).
12. Build "existing crops manifest" for the Drafter (Tier 2.8):
    ```bash
    for f in src/content/crops/*.mdx; do
      [ "$(basename "$f")" = "_template.mdx" ] && continue
      slug=$(basename "$f" .mdx)
      thai=$(grep -m1 '^title:' "$f" | sed 's/title: *//; s/"//g; s/^ *//; s/ *$//')
      en=$(grep -m1 '^titleEn:' "$f" | sed 's/titleEn: *//; s/"//g; s/^ *//; s/ *$//')
      echo "{\"slug\":\"$slug\",\"thai\":\"$thai\",\"english\":\"$en\"}"
    done
    ```
    Pass this manifest to the Drafter so it can reference shared sources by ID.

If any pre-flight check fails: halt, log to `docs/PIPELINE_FAILURES.md`, report and exit.

## State checkpoint (Tier 2.7)

After every successful stage, write `.claude/state/pipeline-current.json`:

```json
{
  "crop_input": "$1",
  "started_at": "<ISO timestamp>",
  "stage_completed": "<latest completed stage>",
  "researcher_output": { ... },
  "drafter_output": { ... },
  "url_verifier_output": { ... },
  "build_verifier_output": { ... },
  "content_verifier_output": { ... },
  "commit_sha": "..."
}
```

On halt mid-pipeline, leave the checkpoint in place. On resume (`/add-crop` re-invoked with same crop name), read the checkpoint and skip completed stages.

After successful push, delete the checkpoint file (clean state for next run).

## Halt protocol (Phase 9.1 — added 2026-05-03)

Every halt point in this orchestrator (pre-flight, Stage 1–5, Content
Verifier blockers, subagent-output-verify failures, safety-limit
trips) MUST write a red-path handoff to
`.claude/runs/<RUN_ID>/handoff.md` per `docs/HANDOFF_FORMAT.md`
**before** writing to `docs/PIPELINE_FAILURES.md` and exiting. This
contract retroactively governs every existing halt point listed
below.

The handoff is a **per-run snapshot**; `PIPELINE_FAILURES.md` keeps
its **cumulative** role. Both are written. Phase 9.1 only emits red
and green handoffs — yellow logic ships in Phase 9.2.

`RUN_ID` may be unset if a pre-flight step before step 11 (run-id
capture) is the failing step; the helper handles that by minting a
synthetic id so the handoff still writes.

```bash
# Reusable red-path handoff writer.
# Caller signature: write_red_handoff <crop_input> <stage> <reason> <suggested_fix>
# - <crop_input>     the original $1 of /add-crop (Thai or English crop name)
# - <stage>          short stage label (e.g. "Pre-flight step 10")
# - <reason>         one-line failure reason
# - <suggested_fix>  one concrete next action for the maintainer
write_red_handoff() {
  local crop="$1" stage="$2" reason="$3" suggested_fix="$4"
  : "${RUN_ID:=halt-$(date +%s)}"
  : "${RUN_STARTED_AT:=$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
  local run_ended_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local run_dir=".claude/runs/$RUN_ID"
  mkdir -p "$run_dir"
  cat > "$run_dir/handoff.md" <<EOF
# Handoff for ${crop:-<crop>} — run $RUN_ID

**Status:** red
**Crop input:** ${crop:-<unknown>}
**Lane decided at:** $stage
**Started at:** $RUN_STARTED_AT
**Ended at:** $run_ended_at

## Stage outcomes

| Stage | Outcome | Detail |
|---|---|---|
| $stage | red | $reason |

## Auto-decisions applied (yellow only)

(none — Phase 9.1 has no yellow logic)

## Decisions needed (red only)

1. $reason — $suggested_fix

## Files changed

(none — pipeline halted before commit)

## Suggested next action

$suggested_fix

## Run telemetry

- run_id: $RUN_ID
- See \`docs/PIPELINE_FAILURES.md\` for the cumulative failure log entry.
EOF
}
```

After writing, the orchestrator emits one line to `Stage 8: Report`
with the `.claude/runs/<RUN_ID>/handoff.md` path and exits non-zero.

## Lane state accumulator (Phase 9.2 — added 2026-05-04)

Yellow lane support: certain non-perfect conditions are codified in
`docs/AUTONOMY_LANES.md` as "continue with note" rather than halt.
The orchestrator accumulates yellow notes per run, surfaces them in
the Stage 6.5 handoff, and gates Stage 7 push for non-green runs.
If ≥3 unrelated yellow notes accumulate in a single run, the
pipeline escalates to a red halt before commit ("Yellow accumulation
rule").

```bash
# Per-run yellow notes file. One JSON line per yellow condition.
# Stored under .claude/runs/<RUN_ID>/lane-notes.jsonl (gitignored).
LANE_NOTES_FILE=".claude/runs/$RUN_ID/lane-notes.jsonl"

# Append a yellow note. Args: <stage> <code> <description>
add_yellow_note() {
  local stage="$1" code="$2" description="$3"
  : "${RUN_ID:=halt-$(date +%s)}"
  mkdir -p ".claude/runs/$RUN_ID"
  local ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '{"ts":"%s","stage":"%s","code":"%s","description":"%s"}\n' \
    "$ts" "$stage" "$code" "$description" \
    >> "$LANE_NOTES_FILE"
}

# Count accumulated yellow notes. Empty/missing file → 0.
accumulated_yellow_count() {
  [ -f "$LANE_NOTES_FILE" ] || { echo 0; return; }
  wc -l < "$LANE_NOTES_FILE" | tr -d ' '
}

# Lane status: green if zero notes, yellow otherwise.
# Red is decided independently by halt points (Halt protocol).
current_lane_status() {
  if [ "$(accumulated_yellow_count)" -gt 0 ]; then
    echo "yellow"
  else
    echo "green"
  fi
}

# If ≥3 yellow notes accumulated, escalate to red and halt.
# Caller passes the original $1 of /add-crop.
escalate_if_yellow_threshold_hit() {
  local crop_input="$1"
  local count
  count="$(accumulated_yellow_count)"
  if [ "$count" -ge 3 ]; then
    local notes
    notes=$(tr '\n' ';' < "$LANE_NOTES_FILE" | sed 's/;$//')
    write_red_handoff \
      "$crop_input" \
      "lane-escalation" \
      "yellow accumulation threshold hit: $count notes — $notes" \
      "Each yellow note is individually safe per docs/AUTONOMY_LANES.md, but the cluster suggests a systemic issue. Review .claude/runs/$RUN_ID/lane-notes.jsonl, fix the root cause, then re-run /add-crop."
    echo "halt: yellow accumulation ≥ 3 — red handoff written"
    exit 1
  fi
}
```

## Stage 1: Researcher

```
view .claude/agents/researcher.md
```

Dispatch a `subagent_type: general-purpose` subagent (per Tier 1.4 above — do NOT use `subagent_type: researcher`, that path has produced Category A tool-execution failures with `tool_use: 0`):
- System prompt = full text of `.claude/agents/researcher.md` (read-then-dispatch per Tier 1.1)
- Crop input = $1

Wait for JSON. Validate per `docs/AUTOMATION_PIPELINE.md`:
- `minimum_sources_met: true`
- `thai_sources_count >= 6`
- `international_sources_count >= 3`
- `high_confidence_count >= 4`
- All URLs have `url_verified: true`

On fail: log to `PIPELINE_FAILURES.md` (stage=researcher), halt.
On pass: update state checkpoint with `stage_completed=researcher`.

**Yellow-lane detection (Phase 9.2):** when validation passes,
inspect just-met thresholds and accumulate yellow notes per
`docs/AUTONOMY_LANES.md`:

```bash
[ "$thai_sources_count"    -eq 6 ] && add_yellow_note researcher just-met-thai            "thai_sources_count exactly 6 (project minimum per AUTONOMY_LANES.md)"
[ "$high_confidence_count" -eq 4 ] && add_yellow_note researcher just-met-high-confidence "high_confidence_count exactly 4 (project minimum per AUTONOMY_LANES.md)"
```

These are continue-with-note conditions, not halt conditions.

## Stage 2: Drafter

```
view .claude/agents/drafter.md
```

Dispatch a NEW `subagent_type: general-purpose` subagent (per Tier 1.4 above — do NOT use `subagent_type: drafter`, that path has produced Category A tool-execution failures with `tool_use: 0`):
- System prompt = full text of `.claude/agents/drafter.md` (read-then-dispatch per Tier 1.1)
- Researcher's full JSON output
- Existing crops manifest (built in pre-flight step 11)
- Today's date

Wait for JSON. Validate:
- `status: "draft_complete"`
- `self_validation_passed: true`
- File exists at returned `file_path`
- Reasoning sidecar exists: `src/content/crops/<slug>.reasoning.json` (Tier 2.9)
- MDX safety check passes: `./scripts/check-mdx-safety.sh src/content/crops/<slug>.mdx`
- **Subagent output verification (Day-1 instrumentation):**
  ```bash
  ./scripts/subagent-output-verify.sh \
    --run-id "$RUN_ID" \
    --stage drafter \
    --agent drafter \
    --mtime-after "$RUN_STARTED_AT" \
    --tool-calls-claimed <count from drafter response, or omit> \
    src/content/crops/<slug>.mdx \
    src/content/crops/<slug>.reasoning.json
  ```
  Accept on `verification_status: pass`. On `fail`, halt with
  `failure_type: tool-execution` (Category A — drafter claimed file writes
  the harness did not actually execute). Do NOT retry blindly — log and
  await maintainer review.
- **Source-table integrity check (Day-2 instrumentation):**
  ```bash
  ./scripts/verify-source-table.sh src/content/crops/<slug>.mdx
  ```
  Accept on `verification_status: pass`. On `fail`, halt with
  `failure_type: generation-contract` (Category C — drafter produced a
  malformed source table: missing rows, duplicate URLs, malformed
  Markdown links, stray body URLs, or below the SOURCE_POLICY minimum
  of 9 sources). This is a deterministic structural gate that runs
  before URL Verifier so a broken table doesn't waste network calls.

  **Yellow-lane detection (Phase 9.2):** parse `data_rows` and
  `min_required` from the verifier JSON. If equal, the source table
  just meets the project minimum — continue-with-note per
  `docs/AUTONOMY_LANES.md`:

  ```bash
  vst_json=$(./scripts/verify-source-table.sh src/content/crops/<slug>.mdx)
  data_rows=$(printf '%s' "$vst_json"     | sed -nE 's/.*"data_rows": *([0-9]+).*/\1/p'    | head -1)
  min_required=$(printf '%s' "$vst_json"  | sed -nE 's/.*"min_required": *([0-9]+).*/\1/p' | head -1)
  if [ "${data_rows:-0}" -eq "${min_required:-9}" ]; then
    add_yellow_note drafter just-met-source-table-min \
      "source table at exactly $data_rows rows (project minimum per AUTONOMY_LANES.md)"
  fi
  ```
- **Claim-grounding sidecar check (Day-2 instrumentation, v1):**
  ```bash
  ./scripts/verify-claim-grounding.sh \
    --with-mdx src/content/crops/<slug>.mdx \
    src/content/crops/<slug>.reasoning.json
  ```
  Accept on `verification_status: pass`. On `fail`, halt with
  `failure_type: generation-contract` (Category C — sidecar contract
  violated: malformed JSON, missing required fields, fewer than 11
  sections, invalid rating, rationale below 25 chars, high-confidence
  section with a single supporting source, duplicate source IDs within
  a section, filename↔crop_slug mismatch, or sidecar referencing more
  unique source IDs than the MDX source table contains). The
  `coverage_assessment` block in the report describes which sections
  use the legacy `supporting_source_types` schema (e.g. retroactive
  sweet-basil sidecar) — those are warnings, not failures.

  v1 of this script does NOT verify content fidelity (verbatim quotes
  appearing in source bodies). That requires the v2 schema migration
  documented in the script header — out of scope for this gate.

On fail: log, halt.
On pass: update checkpoint with `stage_completed=drafter`.

## Stage 3: URL Verifier

```bash
./scripts/verify-urls.sh src/content/crops/<slug>.mdx
```

Parse JSON. Accept on `verification_status: pass`.

On fail: log, halt.
On pass: update checkpoint.

## Stage 4: Build Verifier (Tier 1.2 — NEW)

```bash
./scripts/verify-build.sh
```

Parse JSON. Accept on `build_status: pass`.

On fail:
- Read the build log at `log_path` from JSON
- Identify the error class (frontmatter schema, broken MDX import, missing component, etc.)
- Log full error to `PIPELINE_FAILURES.md` with stage=build-verifier
- Halt

On pass: update checkpoint.

## Stage 5: Content Verifier (FRESH CONTEXT — critical isolation)

```
view .claude/agents/content-verifier.md
```

Dispatch a NEW `subagent_type: general-purpose` subagent (per Tier 1.4 above — do NOT use `subagent_type: content-verifier`, that path has produced Category A tool-execution failures with `tool_use: 0`; the dispatch must also be a fresh subagent — not a continuation of the drafter agent — to preserve fresh-context isolation):
- System prompt = full text of `.claude/agents/content-verifier.md` (read-then-dispatch per Tier 1.1)
- Path to the drafted MDX file
- Path to the reasoning sidecar (so verifier can check confidence claims)
- Today's date

The content-verifier MUST log to `.claude/logs/verifier-stats.json` per its prompt (Tier 2.6).

Decision matrix from verifier output:

| Verifier Status | Action |
|---|---|
| `ready_for_publish: true`, blockers: 0 | Proceed to commit |
| `blockers: 1+` | Halt, log all blockers, exit |
| `medium_issues: 1-3`, `auto_fixes_applied` | Re-run URL Verifier + Build Verifier + Content Verifier (1 retry max). If still pass, **continue as YELLOW** (Phase 9.2) |
| `medium_issues: 4+` | Halt, log, escalate |

**Yellow-lane detection (Phase 9.2):** the `medium_issues 1-3` retry
path is a yellow-lane condition. After the retry passes, accumulate
notes per `docs/AUTONOMY_LANES.md`:

```bash
# medium-with-autofix yellow note
if [ "${medium_issues:-0}" -ge 1 ] && [ "${medium_issues:-0}" -le 3 ] && [ "${auto_fixes_applied:-0}" -gt 0 ]; then
  add_yellow_note content-verifier auto-fix-applied \
    "verifier reported $medium_issues medium issues; $auto_fixes_applied auto-fix(es) applied successfully"
fi

# Non-trivial diff yellow note (>10 lines per AUTONOMY_LANES.md)
diff_lines=$(git diff --shortstat src/content/crops/<slug>.mdx 2>/dev/null \
              | grep -oE '[0-9]+ insertion|[0-9]+ deletion' \
              | grep -oE '[0-9]+' \
              | awk '{s+=$1} END {print s+0}')
if [ "${diff_lines:-0}" -gt 10 ]; then
  add_yellow_note content-verifier auto-fix-non-trivial-diff \
    "verifier auto-fix changed $diff_lines lines (>10 line threshold per AUTONOMY_LANES.md)"
fi
```

**Subagent output verification (Day-1 instrumentation):**

```bash
./scripts/subagent-output-verify.sh \
  --run-id "$RUN_ID" \
  --stage content-verifier \
  --agent content-verifier \
  --tool-calls-claimed <count from verifier response, or omit> \
  src/content/crops/<slug>.mdx \
  src/content/crops/<slug>.reasoning.json \
  .claude/logs/verifier-stats.json
```

Why these three files:
- `<slug>.mdx` and `<slug>.reasoning.json` should still exist after the
  verifier finishes — disappearance/truncation indicates a faulty edit.
- `.claude/logs/verifier-stats.json` should exist and be non-empty
  (the verifier's Step 10 mandates appending a line).

If the verifier reported `auto_fixes_applied > 0`, additionally pass
`--mtime-after "$RUN_STARTED_AT"` so the script confirms the mdx file's
mtime advanced *after* the verifier dispatch began. A fix-claim with
unchanged mtime is the exact failure mode observed in the 2026-04-30
mango Content Verifier incident.

On `verification_status: fail`, halt with `failure_type: tool-execution`.
Do NOT mark the run as published until the verifier discrepancy is
investigated by the maintainer. Log the run_id so the failure can be
joined to its dispatch entry in `.claude/logs/subagent-dispatch.json`.

After verifier passes: update checkpoint with `stage_completed=content-verifier`.

**Yellow accumulation gate (Phase 9.2):** before proceeding to
audit-log + handoff + commit, check whether yellow notes have
crossed the threshold. ≥3 unrelated yellows → red halt.

```bash
escalate_if_yellow_threshold_hit "$1"
# If accumulated yellow count ≥ 3, this writes a red handoff and
# exits non-zero. Otherwise, control returns and we proceed to
# Stage 6.
```

## Stage 6: Audit log entry

Append to top of `docs/AUDIT_LOG.md`:

```markdown
## YYYY-MM-DD — Auto Pipeline: Added <Thai> (<English>)

**Type:** Content Addition (auto)
**Crop:** <Thai> (<English>) — `<slug>`
**Category:** <category>
**Scientific:** *<scientific name>*

**Pipeline run:**
- Researcher: <N> sources (<X> Thai + <Y> international, <Z> high-confidence)
- Drafter: 13 sections written
- URL Verifier: <N>/<N> passed
- Build Verifier: pass (<page count>)
- Content Verifier (fresh context): pass — <blockers> blockers, <medium> medium, <minor> minor
- Auto-fixes applied: <count or "none">

**Files changed:**
- `src/content/crops/<slug>.mdx`
- `src/content/crops/<slug>.reasoning.json`
- `docs/AUDIT_LOG.md`
- `.claude/logs/verifier-stats.json`
```

## Stage 6.5: Write run handoff (Phase 9.1, lane-aware in Phase 9.2)

After the audit log entry, write the per-run handoff artifact to
`.claude/runs/$RUN_ID/` per `docs/HANDOFF_FORMAT.md`. This is the
single artifact the maintainer reads per crop. Phase 9.1 introduced
the writer; Phase 9.2 makes it lane-aware (green vs yellow); the
Halt protocol still emits red handoffs at every halt point.

Auto-push at Stage 7 happens for **green** runs only (Phase 9.2).
Yellow runs commit but stop before push — Phase 9.3 will remove
auto-push entirely.

```bash
RUN_DIR=".claude/runs/$RUN_ID"
mkdir -p "$RUN_DIR"
RUN_ENDED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Lane status comes from the accumulator (Phase 9.2).
LANE="$(current_lane_status)"

# Format yellow notes for the handoff body.
if [ "$(accumulated_yellow_count)" -gt 0 ]; then
  YELLOW_DECISIONS=$(
    while IFS= read -r line; do
      yn_stage=$(printf '%s' "$line" | sed -nE 's/.*"stage":"([^"]*)".*/\1/p')
      yn_code=$(printf '%s'  "$line" | sed -nE 's/.*"code":"([^"]*)".*/\1/p')
      yn_desc=$(printf '%s'  "$line" | sed -nE 's/.*"description":"([^"]*)".*/\1/p')
      printf -- "- [%s] %s — %s (auth: docs/AUTONOMY_LANES.md)\n" "$yn_stage" "$yn_code" "$yn_desc"
    done < "$LANE_NOTES_FILE"
  )
  SUGGESTED_NEXT_ACTION="YELLOW lane — human review required before push. Read this handoff, run \\\`git show HEAD\\\` to inspect the local commit, then either \\\`git push origin main\\\` (approve) or \\\`git reset --hard HEAD~1\\\` (reject)."
else
  YELLOW_DECISIONS="(none — clean green run, no yellow conditions detected)"
  SUGGESTED_NEXT_ACTION="Pipeline auto-pushed in Phase 9.2 green-lane mode. Verify the production URL once the Vercel deploy completes: \\\`https://kasetatlas.com/crops/<slug>\\\`. Phase 9.3 will remove auto-push entirely."
fi

# Substitute the bracketed placeholders with values resolved during
# the run (slug, Thai name, English name, source counts, etc.).
cat > "$RUN_DIR/handoff.md" <<EOF
# Handoff for <Thai> (<English>) — run $RUN_ID

**Status:** $LANE
**Crop slug:** <slug>
**Lane decided at:** end-of-run
**Started at:** $RUN_STARTED_AT
**Ended at:** $RUN_ENDED_AT

## Stage outcomes

| Stage | Outcome | Detail |
|---|---|---|
| Pre-flight | green | clean tree, on main, no HALT |
| Researcher | green | <N> sources (<X> Thai + <Y> intl, <Z> high-confidence) |
| Drafter | green | 13 sections, sidecar pass, source-table pass |
| URL Verifier | green | <n>/<n> URLs alive |
| Build Verifier | green | <pages> pages built |
| Content Verifier | green | 0 blockers, <m> medium, <μ> minor |
| Subagent-output-verify | green | per-stage pass |

## Auto-decisions applied (yellow only)

$YELLOW_DECISIONS

## Decisions needed (red only)

(none)

## Files changed

- src/content/crops/<slug>.mdx
- src/content/crops/<slug>.reasoning.json
- docs/AUDIT_LOG.md
- .claude/logs/verifier-stats.json

## Suggested next action

$SUGGESTED_NEXT_ACTION

## Run telemetry

- run_id: $RUN_ID
- yellow_notes_count: $(accumulated_yellow_count)
- See \`.claude/logs/verifier-stats.json\` for the trailing-window pass-rate.
EOF

# Companion machine-readable manifest (consumed by future tooling).
cat > "$RUN_DIR/manifest.json" <<EOF
{
  "run_id": "$RUN_ID",
  "crop_input": "$1",
  "slug": "<slug>",
  "lane": "$LANE",
  "yellow_notes_count": $(accumulated_yellow_count),
  "started_at": "$RUN_STARTED_AT",
  "ended_at": "$RUN_ENDED_AT",
  "stage_outcomes": {
    "preflight": "green",
    "researcher": "green",
    "drafter": "green",
    "url_verifier": "green",
    "build_verifier": "green",
    "content_verifier": "green",
    "subagent_output_verify": "green"
  },
  "files_changed": [
    "src/content/crops/<slug>.mdx",
    "src/content/crops/<slug>.reasoning.json",
    "docs/AUDIT_LOG.md",
    ".claude/logs/verifier-stats.json"
  ]
}
EOF
```

## Stage 7: Commit + push

```bash
git add \
  src/content/crops/<slug>.mdx \
  src/content/crops/<slug>.reasoning.json \
  docs/AUDIT_LOG.md \
  .claude/logs/verifier-stats.json

git commit -m "$(cat <<'EOF'
content(<category>): add <crop name> [auto]

- Sources: <N Thai + M international>
- High confidence: <count>
- URL verifier: pass (<N/N>)
- Build verifier: pass
- Content verifier: pass
- Auto-fixes: <count>

Generated by AI Pipeline (Researcher → Drafter → URL Verifier → Build Verifier → Content Verifier).
See docs/AUDIT_LOG.md for run details.
EOF
)"

# Phase 9.2 yellow-lane push guard.
# Yellow runs commit (so the maintainer can review with `git show
# HEAD`) but must NOT auto-push. Green runs push as before.
# AUTONOMY_LANES.md authorizes auto-push for green-lane runs only;
# Phase 9.3 will remove auto-push for green too and require the
# maintainer's explicit push.
if [ "$(current_lane_status)" = "yellow" ]; then
  echo "=============================================================="
  echo "YELLOW lane complete — human review required before push."
  echo ""
  echo "See .claude/runs/$RUN_ID/handoff.md"
  echo ""
  echo "Local commit was made ($(git rev-parse --short HEAD)). To publish:"
  echo "  1. Review the handoff and the commit:  git show HEAD"
  echo "  2. Approve and push:                   git push origin main"
  echo "  3. Reject and discard:                 git reset --hard HEAD~1"
  echo "=============================================================="
  exit 0
fi

git push origin main
```

After successful push:
- Delete `.claude/state/pipeline-current.json` (clean state)
- Update `docs/WORKFLOW_KIT.md` if any new pattern emerged from this run

## Stage 8: Report

Print summary:
- **Status:** published | halted
- **Handoff:** `.claude/runs/<RUN_ID>/handoff.md` (read this — single artifact per run, Phase 9.1)
- **Crop:** <Thai> (<English>) — `<slug>`
- **Category:** <category>
- **Sources:** <N> total, <Z> high-confidence
- **Verifier:** <blockers> blockers, <medium> medium, <minor> minor
- **Build:** pass — <page count> pages, Pagefind indexed <N> languages
- **Commit:** <SHA>
- **Production URL:** https://kasetatlas.com/crops/<slug>
- **Verifier stats (last 5 runs):** read from `.claude/logs/verifier-stats.json`

## Forbidden (per CLAUDE.md §10 + WORKFLOW_KIT)

- Skipping any stage
- Committing without all 5 verifier stages passing
- Auto-fixing 🔴 BLOCKER issues
- Pushing during HALT signal
- Suppressing failure logs
- Inventing URLs (all URLs must come from Researcher's verified output)
- Using `contributor: "Prem Pawee"` — must be `"AI Pipeline (auto)"`
- Skipping the Build Verifier (Stage 4) — non-negotiable
- Using `subagent_type: researcher` / `drafter` / `content-verifier` instead of `general-purpose` (Tier 1.4). Five documented Category A `tool-execution` failures across durian, mango ×3, and tomato resume #2 vs zero on `general-purpose` — the dedicated paths render `<function_calls>` blocks as text without invoking the harness, producing `tool_use: 0` despite long plausible-looking responses. The 2026-04-30 tomato Option 1 controlled diagnostic confirmed `general-purpose` dispatch executes tool calls correctly with the same role prompts.
- Skipping Stage 6.5 (handoff write) — non-negotiable per Phase 9.1. Every successful run writes a green handoff; every halt point writes a red handoff per the Halt protocol above.
- Skipping yellow-note accumulation — non-negotiable per Phase 9.2. Every codified yellow condition in `docs/AUTONOMY_LANES.md` must be detected and accumulated; lane status drives the Stage 7 push guard.
- Auto-pushing yellow-lane runs — non-negotiable per Phase 9.2. Yellow runs commit (so the maintainer can review with `git show HEAD`) but must NOT auto-push. Green runs continue to auto-push until Phase 9.3 removes that behavior entirely.

## Safety limits

- Max 1 auto-fix retry per crop
- Max 5 pipeline runs per hour (rate limit; not enforced programmatically yet)
- Max 50 crops per day
- Build gate (Stage 4) MUST pass — no exceptions

If any safety limit is hit, write `.claude/HALT` automatically and exit.

## Telemetry (Day-1 instrumentation, 2026-04-30)

Two log files capture pipeline reliability:

- `.claude/logs/verifier-stats.json` — one line per *crop run* (existing).
  v2 entries SHOULD include `run_id`, `manual_intervention_required`,
  `intervention_type`, and `failure_type`. See `.claude/logs/README.md`.
- `.claude/logs/subagent-dispatch.json` — one line per *subagent dispatch
  verification* (new). Written by `scripts/subagent-output-verify.sh`.
  Schema documented in `.claude/logs/README.md`.

Both share `run_id` so a Category A (tool execution failure) seen in
`subagent-dispatch.json` can be joined to the crop run in
`verifier-stats.json`.

**Failure type taxonomy (use these strings exactly when populating
`failure_type` in either log):**

- `none` — clean run
- `tool-execution` — Category A; subagent claimed file work that disk
  reality contradicts (caught by `subagent-output-verify.sh`)
- `retrieval` — Category B; researcher returned hallucinated/dead URLs
- `generation-contract` — Category C; drafter cited unsupported claims
  or emitted unsafe MDX
- `verification` — Category D; content-verifier produced inconsistent
  findings (false positive or false negative)
- `publish` — Category E; commit/push step failed

**Intervention type taxonomy:**

- `none` — pipeline ran end-to-end without main-session edits
- `script-patch` — main session patched a verifier script mid-run
- `content-edit` — main session manually edited the mdx/sidecar
- `stage-substitution` — main session ran the stage's work directly
  instead of dispatching the subagent

These taxonomies are descriptive only in v1; future iterations may
make them enforced enums in a JSON schema.
