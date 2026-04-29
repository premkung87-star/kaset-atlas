# Pipeline State

This directory holds **transient pipeline state** between auto-pipeline stages.

## Files

- `pipeline-current.json` — checkpoint for an in-progress `/add-crop` run. Written after each successful stage; deleted after a successful push.

## Convention

- State files are **not committed** (see `.gitignore`).
- Only `README.md` is committed (this file).
- If a `pipeline-current.json` exists when a new `/add-crop` is invoked, treat it as a resume candidate: read it, skip completed stages, continue from the next.
