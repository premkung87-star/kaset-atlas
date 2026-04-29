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
11. Build "existing crops manifest" for the Drafter (Tier 2.8):
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

## Stage 1: Researcher

```
view .claude/agents/researcher.md
```

Dispatch a `general-purpose` subagent:
- System prompt = full text of `.claude/agents/researcher.md`
- Crop input = $1

Wait for JSON. Validate per `docs/AUTOMATION_PIPELINE.md`:
- `minimum_sources_met: true`
- `thai_sources_count >= 6`
- `international_sources_count >= 3`
- `high_confidence_count >= 4`
- All URLs have `url_verified: true`

On fail: log to `PIPELINE_FAILURES.md` (stage=researcher), halt.
On pass: update state checkpoint with `stage_completed=researcher`.

## Stage 2: Drafter

```
view .claude/agents/drafter.md
```

Dispatch a NEW `general-purpose` subagent:
- System prompt = full text of `.claude/agents/drafter.md`
- Researcher's full JSON output
- Existing crops manifest (built in pre-flight step 11)
- Today's date

Wait for JSON. Validate:
- `status: "draft_complete"`
- `self_validation_passed: true`
- File exists at returned `file_path`
- Reasoning sidecar exists: `src/content/crops/<slug>.reasoning.json` (Tier 2.9)
- MDX safety check passes: `./scripts/check-mdx-safety.sh src/content/crops/<slug>.mdx`

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

Dispatch a NEW `general-purpose` subagent (NOT continuing the drafter agent):
- System prompt = full text of `.claude/agents/content-verifier.md`
- Path to the drafted MDX file
- Path to the reasoning sidecar (so verifier can check confidence claims)
- Today's date

The content-verifier MUST log to `.claude/logs/verifier-stats.json` per its prompt (Tier 2.6).

Decision matrix from verifier output:

| Verifier Status | Action |
|---|---|
| `ready_for_publish: true`, blockers: 0 | Proceed to commit |
| `blockers: 1+` | Halt, log all blockers, exit |
| `medium_issues: 1-3`, `auto_fixes_applied` | Re-run URL Verifier + Build Verifier + Content Verifier (1 retry max). If still pass, proceed |
| `medium_issues: 4+` | Halt, log, escalate |

After verifier passes: update checkpoint with `stage_completed=content-verifier`.

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

git push origin main
```

After successful push:
- Delete `.claude/state/pipeline-current.json` (clean state)
- Update `docs/WORKFLOW_KIT.md` if any new pattern emerged from this run

## Stage 8: Report

Print summary:
- **Status:** published | halted
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

## Safety limits

- Max 1 auto-fix retry per crop
- Max 5 pipeline runs per hour (rate limit; not enforced programmatically yet)
- Max 50 crops per day
- Build gate (Stage 4) MUST pass — no exceptions

If any safety limit is hit, write `.claude/HALT` automatically and exit.
