# Codex Invocation Brief — Template (Plugin Mode v1)

> Claude Code fills out this template **before** running any
> `/codex:*` slash command, commits or stages it to
> `.ai/codex/tasks/<YYYY-MM-DD>-<slug>.md`, and uses it as the
> senior-engineer paperwork for the invocation. Codex itself does not
> author this file.
>
> Per RULES.md §B10, every Codex invocation must have a brief on file
> — spontaneous "let me just `/codex:review` real quick" runs are
> forbidden because they break the audit trail.

Copy the block below for every new invocation.

---

## Invocation brief: `<short slug>`

**Issued by:** Claude Code (Senior Engineer)
**Issued at:** `<UTC ISO timestamp>`
**Trial invocation #:** `<N>` of trial run on branch `chore/codex-intern-trial`
**Sanctioned use case:** `<one of: review-default | adversarial-review | rescue-approved>`

### 1. Goal (one sentence)

`<plain English. Example: "Get a second-opinion review on the .ai/codex/ onboarding pack before opening the trial PR.">`

### 2. Slash command to be run

`<exact command, including all flags. Example: "/codex:review --background --scope working-tree">`

### 3. Why Codex specifically (vs Claude Code doing it itself)

`<one or two sentences. Examples: "Need fresh-context adversarial framing on the rule layering — Claude Code authored it." or "Working-tree diff is large; offloading the read-pass to Codex preserves Claude Code context budget for the integration decision.">`

### 4. Scope

- Mode: `<review-only | adversarial-review | rescue (requires §6 approval)>`
- Target: `<working-tree | branch <name>-vs-<base> | named directory <path>>`
- File-count estimate: `<N>`
- Estimated tokens out from this machine to OpenAI: `<rough size>`
- Excluded paths (per RULES.md §A1.x): `<list any secret-shaped paths the scope would otherwise include; or "none in this scope">`

### 5. Expected output

- Format: `<verbatim Codex stdout | Codex stdout + Claude Code findings table>`
- Length expectation: `<best-effort ≤ 200 lines>`
- Acceptance criteria for the *senior-engineer review of Codex output*:
  - Every cited file path resolves at the cited line range when Claude
    Code re-reads.
  - Every verbatim quote can be grep'd from the cited file.
  - No finding proposes a fix Claude Code is expected to apply
    blindly — every adoption requires re-verification (zero
    copy-paste).

### 6. Rescue approval (only if §2 invokes `/codex:rescue`)

> **Required if and only if §2 is a rescue invocation.** Per
> RULES.md §B13, rescue is forbidden by default. This block must be
> filled before the slash command runs, and the approval entry must
> already exist on a prior line in `TRIAL_LOG.md`.

- TRIAL_LOG.md approval entry timestamp: `<UTC ISO>`
- Approval slug: `rescue-approval-<NN>`
- Maintainer who approved: `<name>`
- Approved target paths (must be inside `.ai/codex/` per §B17): `<paths>`
- Approved scope of changes: `<what Codex may change>`
- Rollback plan: `<git command or step-by-step Claude Code will run if the rescue produces unwanted output>`
- Specific shell commands Codex may run: `<list, or "none — file edits only">`

If §2 is not a rescue, write `n/a — review-only invocation` here.

### 7. Forbidden moves on this invocation

- All RULES.md §B prohibitions apply unconditionally.
- Editing any file outside `.ai/codex/` (RULES.md §B17 — absolute).
- Inferring scope beyond §4.
- Re-introducing any Discarded approach from `WORKFLOW_KIT.md §5`
  (RULES.md §B12).
- Asking the maintainer for clarification mid-run (no human relay —
  return a `blocked` note instead).
- Persisting Codex session state across this invocation (`--fresh` is
  default per §B16; `--resume-last` only with explicit user intent).

### 8. Stop conditions

The invocation is aborted (Claude Code presses `/codex:cancel` or
ignores the output) if any of these occur:

- The Codex CLI prints a quota / auth error (see LIMIT_FALLBACK.md).
- Codex output references files outside §4 scope.
- Codex output proposes edits to forbidden paths (RULES.md §B1–§B4).
- The invocation runs past `<duration cap>` and is no longer worth
  the wait (Claude Code default fallback).
- Two retries fail to produce a clean review.

### 9. Hand-off

- Claude Code captures Codex stdout into
  `.ai/codex/reports/<YYYY-MM-DD>-<slug>.md` using
  `REPORT_TEMPLATE.md`.
- Claude Code performs adversarial review of the captured output
  (zero copy-paste; re-verify every cited line).
- Claude Code appends an outcome line to `TRIAL_LOG.md`.
- The maintainer is shown the verbatim Codex output and Claude Code's
  adoption decision in the chat.

---

## Worked example (sanctioned task #1, plugin mode)

```
## Invocation brief: review-onboarding-pack

**Issued by:** Claude Code
**Issued at:** 2026-05-01T17:00:00Z
**Trial invocation #:** 1 of trial run on branch chore/codex-intern-trial
**Sanctioned use case:** review-default

### 1. Goal
Get a fresh-context review on the .ai/codex/ onboarding pack before
the trial PR is opened. Claude Code authored the pack; an external
read pass should surface contradictions or missed edge cases.

### 2. Slash command
/codex:review --wait --scope working-tree

### 3. Why Codex specifically
Author-bias risk on the pack itself. Codex provides a fresh-context
read; the alternative would be Claude Code re-reading its own draft.

### 4. Scope
- Mode: review-only
- Target: working-tree
- File-count estimate: 6 files in .ai/codex/, plus untracked .ai/ dir
- Estimated tokens out: ~30 KB total
- Excluded paths: none in this scope (no .env / secrets in .ai/codex/)

### 5. Expected output
- Format: verbatim Codex stdout
- Length: best-effort ≤ 200 lines
- Acceptance: any rule contradiction Codex surfaces gets re-verified
  against the actual file contents before any rule rewrite.

### 6. Rescue approval
n/a — review-only invocation

### 7. Forbidden moves
Standard (RULES.md §B). No file edits — review-only command.

### 8. Stop conditions
Standard.

### 9. Hand-off
Capture stdout to .ai/codex/reports/2026-05-01-review-onboarding-pack.md.
Claude Code adversarial-reviews findings before any pack edit.
```

---

**Last updated:** 2026-05-01 (plugin-mode v1).
