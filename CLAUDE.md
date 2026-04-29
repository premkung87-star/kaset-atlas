# CLAUDE.md — Kaset Atlas Operating Manual

> Read this file FIRST in every session before any other action.

## 1. Project Identity

**Project:** Kaset Atlas (เกษตรแอตลาส)
**Mission:** Bridge global agricultural knowledge into Thai, for Thai farmers.
**Type:** Public-good, open-source, mission-first project. Not monetization-first.
**Maintainer:** Prem (solo)
**Domain:** kasetatlas.com
**Stack:** Astro + Tailwind + MDX + Pagefind + Vercel
**Operating Mode:** **Fully-Automated Content Production (Definition B)**
**Policy Override Date:** 2026-04-29 (see `docs/AUDIT_LOG.md`)
**Audience:** Thai-speaking general public + AI search engines (Perplexity, ChatGPT, Claude, Gemini, Google AI Overviews). The site is built to be machine-citable as well as human-readable.
**Content License:** CC BY-SA 4.0 — free reuse with attribution and share-alike. AI engines may quote freely with attribution.
**Code License:** MIT.
**Funding:** Non-profit. No donations accepted except funded research collaborations.

## 2. Core Principles (Non-Negotiable)

1. **Source-Traceable Always** — Every important agricultural claim MUST have a verifiable source. URLs must be HTTP-verified before publication.
2. **Confidence Labels Mandatory** — High / Medium / Low / Uncertain for every section.
3. **Localize, don't just translate** — Every foreign source needs a "Thailand applicability note".
4. **Safety over completeness** — Auto-refuse to publish risky chemical/dosage/identification advice.
5. **Static-first** — No database, no AI chat, no user accounts in V1.
6. **Auto Pipeline Integrity** — Every Drafter output MUST pass URL Verifier + Content Verifier before commit.
7. **Public Transparency** — README discloses content is AI-generated. Errors are logged in AUDIT_LOG.

## 3. Content Production Mode (UPDATED 2026-04-29)

**Operating mode: Fully Automated**

- AI agents handle research, drafting, verification, and publication
- No human-in-the-loop verification step per crop
- Multi-agent pipeline ensures quality:
  - **Researcher** — finds sources
  - **Drafter** — writes MDX
  - **URL Verifier** (script) — HTTP checks all URLs
  - **Content Verifier** (Sonnet, separate context) — checks claims vs sources, SOURCE_POLICY, SAFETY_POLICY
  - **Decision Agent** — auto-commit if all checks pass

See `docs/AUTOMATION_PIPELINE.md` for full pipeline spec.

**This overrides previous Section 7 (Forbidden Actions) restriction on AI-generated content.**

## 4. Operating Rules for Claude Code

### Rule 1: English-Only Prompts
All prompts to Claude Code agents are written in English regardless of conversation language with maintainer.

### Rule 2: Architect Mode
Deliver decisions, not A/B/C option lists. When asked "should we do X or Y", choose one and explain why. Maintainer can override.

### Rule 3: Reduce Weaknesses Before Adding Features
If something is broken, fix it before adding new functionality.

### Rule 4: Verify Line Numbers Before str_replace
View the file immediately before any edit. Stale line numbers cause silent corruption.

### Rule 5: No Time/Energy/Life Management Suggestions
Do not advise the maintainer on pace, scheduling, motivation, or burnout. The maintainer manages their own life.

### Rule 6: Stack Routing
- Static content site → Vercel (this project)
- Internal tools with auth → Supabase + Vercel Pro (NOT used here in V1)
- Heavy AI workloads → Claude API + Vercel (NOT used here in V1)

### Rule 7: Always Use Paid Stack When Applicable
Vercel Pro, GitHub Pro, Claude Max 20x are already paid. Use them. No free substitutes.

### Rule 8: Pipeline Failures Halt Publication
If URL Verifier or Content Verifier flags issues:
- Auto-fix attempt: 1 retry
- If retry fails: log to `docs/PIPELINE_FAILURES.md` and halt
- Do NOT publish content that fails verification

### Rule 9: Audit Trail Mandatory
Every auto-published crop MUST log:
- Sources used (with HTTP-verified status)
- Confidence levels assigned
- Any auto-fixes applied
- Verifier pass/fail counts

Log location: `docs/AUDIT_LOG.md` or `.claude/logs/`

### Rule 10: Ask First on Ambiguity, 🟡, and 🔴

Before any non-trivial change, restate the goal in one sentence and ask "Is this correct?" if any ambiguity remains.

- 🟢 Low-risk auto-pipeline runs proceed silently when scope is clear.
- 🟡 Medium changes proceed with a risk note in the response.
- 🔴 High-risk changes (pipeline modification, agent prompt, build/deploy config, schema change) require:
  - Explicit maintainer approval before execution
  - Diff shown before committing
  - Rollback plan stated
- New tools, new external services, scope expansion: **ASK FIRST**.
- Ambiguous instructions: **ASK FIRST**. One clarifying question is cheaper than three rollback commits.

This rule reflects observed reality: most pipeline errors trace to ambiguous instructions, not agent execution.

## 5. Session-Opening Ritual

Before any action in a new session:

1. Read this `CLAUDE.md`
2. Read `docs/METHODOLOGY.md`
3. Read `docs/SOURCE_POLICY.md`
4. Read `docs/SAFETY_POLICY.md`
5. Read `docs/AUTOMATION_PIPELINE.md`
6. Check current branch: must be `main` or feature branch with PR
7. Check `git status` — clean working tree
8. State the session goal in one sentence before touching code

## 6. Risk Classification

Before any change, classify:

- **🟢 Low Risk** — Adding crop content via auto pipeline
- **🟡 Medium Risk** — Component refactor, schema change, layout change
- **🔴 High Risk** — Pipeline modification, agent prompt change, build config, deploy config

🔴 changes require explicit maintainer approval and rollback plan.

## 7. Forbidden Actions (REVISED 2026-04-29)

- ❌ Publishing content with HTTP-failed URLs
- ❌ Publishing content that fails Content Verifier
- ❌ Translating full copyrighted articles
- ❌ Pesticide dosage recommendations
- ❌ Edible/poisonous plant identification claims
- ❌ Medical or health claims about plants
- ❌ Yield/profit/income guarantees
- ❌ Adding paid tools without explicit maintainer approval
- ❌ Modifying SAFETY_POLICY without maintainer approval

**REMOVED from this list (per 2026-04-29 policy override):**
- ~~AI-generated content without human review~~ — now standard operating mode

## 8. Conventional Commits

Auto-generated by Decision Agent:

```
feat(crops): add basil profile [auto]
content(culinary-herbs): add holy basil [auto]
fix(crops): correct source URL in basil [auto]
chore(deps): bump astro to 5.x
```

Commits from auto pipeline get `[auto]` suffix for traceability.

## 9. Branch Protection

- `main` is protected for human direct push
- Auto pipeline commits via PR with auto-merge if all checks pass
- Failures escalate to maintainer review

## 10. Emergency Stop

To halt auto pipeline:
```bash
touch .claude/HALT
```
Pipeline checks for this file before each run. If present, exits immediately.

To resume:
```bash
rm .claude/HALT
```

## 11. Last Updated Footer

Every crop profile page MUST display:
- Last updated date
- Contributor: "AI Pipeline (auto)" if generated by pipeline
- Reviewer: agent that approved (e.g., "Content Verifier v1")

This is non-negotiable for trust and traceability.

## 12. Free-Tier Audit (per Rule 7)

Before proposing any new tool or service, verify it is not already included in the existing paid stack.

| Capability needed | Already provided by | Tier limit / status |
|---|---|---|
| Static hosting + edge runtime | **Vercel Pro** ($20/mo) | 1 TB bandwidth, 1000 build min/mo, edge functions |
| Image optimization | **Vercel Pro** | Included |
| Web analytics | **Vercel Pro — Analytics** | Free tier 2.5k events/mo |
| Performance monitoring | **Vercel Pro — Speed Insights** | Free tier 10k pageviews/mo |
| Source code + collaboration | **GitHub Pro** ($4/mo) | Public repo, advanced features |
| CI / scheduled jobs | **GitHub Actions** (via GitHub Pro) | 2000 min/mo for public repos |
| Database / auth / vector storage | **Supabase Pro** ($25/mo) | OFF for V1 per Static-First; revisit V2 |
| AI orchestration / drafting / verification | **Claude Max 20x** | Heavy parallel subagent use intended |
| In-page search | **Pagefind** (FOSS, $0) | Listed in stack, not yet wired |

**Anti-pattern to reject:** "Let's add tool X to do Y" without first checking whether Y is already covered by the stack above.

**Approval thresholds:**
- New paid service: explicit maintainer approval (per Rule 7 + Forbidden Actions)
- Free / open-source addition: 🟡 risk note, proceed with diff shown
- Enabling features inside the existing paid stack (e.g., turning on Vercel Analytics): 🟢, just enable
