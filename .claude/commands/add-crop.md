---
description: Add a new crop profile to Kaset Atlas via full auto pipeline (Researcher → Drafter → URL Verifier → Content Verifier → Auto-commit)
argument-hint: <crop name in Thai or English>
---

# Add Crop — Full Auto Pipeline

Crop name: $1

## Pre-flight

Read these files in order before doing anything else:
1. `CLAUDE.md`
2. `docs/METHODOLOGY.md`
3. `docs/SOURCE_POLICY.md`
4. `docs/SAFETY_POLICY.md`
5. `docs/AUTOMATION_PIPELINE.md`

Confirm:
- Working tree is clean (`git status`)
- On `main` branch
- No HALT signal at `.claude/HALT`
- Crop "$1" does not already exist (`ls src/content/crops/`)

If any pre-flight fails: report and exit.

## Execute Pipeline

Use the **decision** subagent to orchestrate the full pipeline for crop: $1

The decision agent will:
1. Invoke researcher subagent
2. Invoke drafter subagent
3. Run scripts/verify-urls.sh
4. Invoke content-verifier subagent (in fresh context)
5. Auto-commit if all pass
6. Push to origin
7. Update docs/AUDIT_LOG.md

## Report

After pipeline completes, summarize for the user:
- Status (published / halted)
- Crop slug
- Number of sources used
- Verifier findings
- Commit SHA (if published)
- URL on production site
- Failure reason (if halted)
