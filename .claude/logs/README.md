# Pipeline Logs

This directory holds **append-only logs** from auto-pipeline runs.

## Files

- `verifier-stats.json` — JSON-lines log written by the Content Verifier after every run. One line per run with structure:
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

## Convention

- Logs ARE committed to git (kept for the trail of pipeline behavior over time).
- New entries always appended to the file end (no truncation, no rewriting past entries).
- Use these to spot pipeline drift (rising blocker rate, falling source count, etc.) per WORKFLOW_KIT.md A/B testing convention.
