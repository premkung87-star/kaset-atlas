---
number: 21
title: "Junior LLM Helper Pattern (Senior/Junior Contract)"
tags: [UNIVERSAL, CODE_REVIEW, SAFETY]
applies_to: [generic]
universal: true
source: kaset-atlas docs/AUDIT_LOG.md 2026-05-01 entry "Codex intern integration via codex-plugin-cc (trial v1)"; .ai/codex/ onboarding pack and trial run on chore/codex-intern-trial branch
incident_refs: [kaset-atlas commit 43f3ecc, kaset-atlas commit 0109005, kaset-atlas commit e9dce42, kaset-atlas commit 404a190, kaset-atlas commit 0b540a1]
added_in_kit: 1.0.2
---

# 21. Junior LLM Helper Pattern (Senior/Junior Contract)

## Verbatim from Source

**Source:** kaset-atlas `chore/codex-intern-trial` branch, `.ai/codex/INTERN_ONBOARDING.md` §0 (commit `43f3ecc`):

> You are an **Intern / Junior Helper** to Claude Code on the Kaset Atlas project. Claude Code is the Senior Engineer and the workflow owner; you take small, bounded tasks invoked through the `/codex:*` slash commands, return your output, and stop. **You do not own any part of the pipeline. You are not the senior reviewer of Claude Code's work — you are a second opinion the senior chooses when to consult.**

The Kaset Atlas project added Codex (OpenAI's `codex-cli` 0.128.0, accessed via the `codex-plugin-cc` plugin) to an existing Claude Code workflow as a gated, review-only, second-opinion service. The integration was scoped to a dedicated trial branch with an explicit Senior/Junior contract codified in `.ai/codex/RULES.md`. Across three review rounds (one bootstrap self-audit of the contract itself, plus two first-real-task reviews on `docs/AUDIT_LOG.md` and `docs/WORKFLOW_KIT.md`), the integration produced six verified-and-adopted contract findings with zero production-code modification, zero unauthorized write actions, and zero escalations to rescue-mode authority. The trial directory remains expendable: a one-commit cleanup deletes `.ai/codex/` and uninstalls the plugin with no functional loss to the project.

## Generic Pattern (Strategy B Abstraction)

**Principle:** Adding a second LLM ("Junior") to an existing single-LLM workflow ("Senior") on a small or solo-maintainer project is cheapest, safest, and most reversible when constrained by an explicit Senior/Junior contract: the Junior gets read-only review surface by default, write-capable surface stays gated behind explicit per-invocation approval that names bounded target paths, an isolation mechanism, and a rollback plan, every invocation is logged with a brief and a verbatim-capture report, the Senior adversarially verifies every Junior finding with zero copy-paste, the Junior is never a required gate (failures fall back to "continue without"), and the entire integration is expendable in one cleanup commit.

**When to apply:** Any single-maintainer or small-team project where (a) the primary work is already running on one LLM-driven workflow, (b) a second LLM is being considered to add fresh-context review or specialized capability, and (c) the project cannot afford the operational overhead of a full multi-tool integration. The pattern matches scenarios where the second tool's value is "second opinion" rather than "additional engineer". It does NOT match scenarios where two tools must coordinate on shared writeable state — that requires a heavier coordination layer than this contract provides.

**Why it works:**
- **Fresh-context review catches author-bias.** A second LLM with no shared memory of the Senior's drafts surfaces contradictions and missing edge cases the original author cannot see. Same mechanism that justifies adversarial peer review in human engineering.
- **Default-forbid write authority preserves single-author discipline.** Most "AI did it" failure modes trace to a junior tool taking unauthorized write actions. Defaulting all write paths to forbidden, requiring explicit per-invocation approval that names bounded target paths and an isolation mechanism appropriate to the task's risk, makes unauthorized writes structurally impossible.
- **Audit-trail paperwork keeps the trial reviewable.** Every invocation produces a brief, a verbatim-capture report, and a trial-log line. Future maintainers can reconstruct the full integration history from these artifacts alone — no chat scrollback required.
- **Expendable scope keeps reversibility cheap.** One cleanup commit (delete the trial directory + uninstall the tool) returns the project to its prior state with zero functional loss. This makes "try it for one cycle" a low-risk experiment rather than a commitment.

**How to apply (stack-agnostic):**
1. **Codify the Senior/Junior contract in writing** at a single isolated directory (`.ai/<tool>/` or equivalent). The Senior is the primary workflow owner; the Junior is an optional helper. State explicitly that the Junior does not own any part of the pipeline.
2. **Default-allowed Junior surface = read-only review commands.** These should be user-triggerable only (not auto-invoked by the Senior model) and should stream output back without modifying files. The vendor's "review my diff" command is usually the right primitive.
3. **Default-forbidden Junior surface = write-capable rescue/task commands.** Forbid these by default, even when the tool's vendor markets them as the primary use case and even when the tool's CLI defaults to a `--write` flag. Approval requires a per-invocation entry in a trial log naming the target paths, scope, and rollback plan.
4. **Approved-write isolation, scaled to risk.** When approval extends write authority, the trial-log entry must name (a) the bounded target paths the Junior may modify, (b) the specific commands or edit patterns it may use, (c) an isolation mechanism appropriate to the task — for example a documentation-only directory (most conservative; near-zero blast radius), a feature branch the Senior reviews before merge, a git worktree, a scope-restricted subdirectory, or a sandbox VM (highest-flexibility) — and (d) a rollback plan. The Senior re-reads every modified file post-invocation; nothing is silently accepted. Pick the isolation mechanism by risk: documentation-only writes are the easiest rollback; production-path writes on the main branch demand the tightest scope-naming and the most thorough post-invocation re-read.
5. **Hard per-invocation budget** to bound cost. Set explicit ceilings on input file count, total input size, output length, and invocations per maintainer-day. The Junior must refuse anything that exceeds these.
6. **Audit-trail paperwork.** Every invocation requires a brief on file before the command runs, a verbatim-capture report after, and a single line appended to a trial log. Spontaneous "let me just review real quick" runs are forbidden — they break the audit trail the trial depends on.
7. **Adversarial verification by Senior.** The Senior re-reads every cited file:line in the Junior's output, classifies each finding (Critical / Important / Optional / Noise), and decides per-finding adoption: accept-as-text, reject, rewrite-and-apply (zero copy-paste of Junior wording into authored content), or defer.
8. **Plugin/CLI transport, never human relay.** If the Junior cannot be reached without the human maintainer copy-pasting messages between two chat windows, the integration is structurally unsustainable. Require a transport (plugin, CLI, MCP server, etc.) that lets the Senior invoke the Junior directly.
9. **Continue-without-Junior fallback.** If the Junior is unavailable (quota cap, auth failure, hang, crash), the Senior performs the same task in its own context. The workflow never blocks on Junior availability. State this explicitly so neither the Senior nor the maintainer waits for quota reset.
10. **Trial expiry plan documented up front.** The integration's deletion path is one cleanup commit (delete the trial directory + uninstall the tool). State this explicitly in the trial documents themselves so the trial is structurally low-risk and the future "kill" decision is well-defined.

**Stack-specific manifestations:**

- **generic:** Any LLM-collab integration. The Junior could be a vendor CLI (Codex, Aider, Continue, GitHub Copilot CLI, Cursor CLI), a hosted agent (Devin, Cursor agent), or another instance of the same model on a separate account. The Senior is whichever LLM owns the primary workflow (Claude Code, Cursor IDE, custom agent harness). The contract works the same: explicit roles, gated authority, adversarial verification, expendable scope.

- **kaset-atlas trial v1 (concrete example of step 4 isolation choice):** The Kaset Atlas project chose the most conservative isolation in step 4: write authority restricted to one isolated documentation directory (`.ai/codex/`), with production code, scripts, agent prompts, policy docs, CI files, and the constitutional doc unmodifiable by the Junior even with approval. This was appropriate for a review-only trial scope on a single-maintainer content site. Projects that want the Junior for actual implementation work — refactors, test scaffolds, real bug fixes — should pick a less restrictive isolation per step 4 (feature branch, worktree, scope-restricted directory, sandbox VM) and accept the corresponding tighter scope-naming and review burden. The kaset-atlas pack lives at `.ai/codex/` with the contract at `INTERN_ONBOARDING.md` + `RULES.md` and per-task paperwork at `tasks/` + `reports/` + `TRIAL_LOG.md`.

**Anti-patterns to reject:**

- Treating the Junior as "another engineer who can ship" rather than "a reviewer the Senior consults". Once the Junior commits to the project's main branch, the senior/junior asymmetry collapses and the gating discipline erodes.
- Allowing the Junior to use auto-trigger features (e.g., "review on every save" or "review on every stop" hooks). Auto-invocation multiplies cost, creates an automatic dependency on Junior availability, and removes the user from the consent loop.
- Letting the human maintainer become the message relay between Senior and Junior. If transport requires copy-pasting messages by hand, the integration is unsustainable; switch transports or abandon.
- Allowing the Junior write authority over policy, constitutional, or audit documents, even with approval. Those are the rules the Junior must follow; allowing it to edit them is a circular dependency that erodes trust in the rules themselves.
- Capturing only an executive summary of the Junior's output. The verbatim raw output is the audit-trail evidence; a summary alone makes hallucination undetectable on later review.
- Copy-pasting Junior wording into authored content (commits, policy docs, audit prose). The Senior re-types every adopted finding from scratch — this preserves the Senior's authorial voice and forces a verification pass that catches subtle hallucinations.
- Encoding a project-specific isolation choice (e.g., "docs-only write authority") as a universal contract requirement. The contract specifies that bounded paths + isolation + rollback are required for any approved write task; the *specific* isolation mechanism is a per-project trade-off between safety and feasibility, not a universal mandate. Generalizing one project's conservative choice into the abstraction prevents future projects from using the rule for legitimate write-capable use cases.
