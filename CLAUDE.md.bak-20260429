# CLAUDE.md — Kaset Atlas Operating Manual

> Read this file FIRST in every session before any other action.

## 1. Project Identity

**Project:** Kaset Atlas (เกษตรแอตลาส)
**Mission:** Bridge global agricultural knowledge into Thai, for Thai farmers.
**Type:** Public-good, open-source, mission-first project. Not monetization-first.
**Maintainer:** Prem (solo)
**Domain:** kasetatlas.com
**Stack:** Astro + Tailwind + MDX + Pagefind + Vercel

## 2. Core Principles (Non-Negotiable)

1. **Content First, Infrastructure Last** — Never build a feature before it has content that needs it.
2. **No source, no merge** — Every important agricultural claim must have a verifiable source or be labeled as uncertain.
3. **Confidence labels mandatory** — High / Medium / Low / Uncertain for every claim.
4. **Localize, don't just translate** — Every foreign source needs a "Thailand applicability note".
5. **Safety over completeness** — Refuse to publish risky chemical/dosage/identification advice.
6. **Static-first** — No database, no AI chat, no user accounts in V1.
7. **Pause-friendly** — This project must be pauseable. Never depend on daily updates.

## 3. Operating Rules for Claude Code

### Rule 1: English-Only Prompts
All prompts to Claude Code are written in English regardless of conversation language with maintainer.

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

## 4. Session-Opening Ritual

Before any action in a new session:

1. Read this `CLAUDE.md`
2. Read `docs/METHODOLOGY.md`
3. Read `docs/SOURCE_POLICY.md`
4. Check current branch: must be `main` or feature branch with PR
5. Check `git status` — clean working tree
6. State the session goal in one sentence before touching code

## 5. Risk Classification

Before any change, classify:

- **🟢 Low Risk** — Typo fix, content addition with sources, doc update
- **🟡 Medium Risk** — Component refactor, schema change, layout change
- **🔴 High Risk** — Build config change, dependency upgrade, deployment config

🔴 changes require explicit approval and a rollback plan.

## 6. Content Workflow (per crop profile)

```
1. Pick crop from queue
2. Find Thai sources (DOA, universities, FAO Thailand)
3. Find international sources (FAO, university extension, peer-reviewed)
4. Categorize facts: climate / soil / water / planting / care / pests / harvest / economics
5. Translate + summarize foreign sources in Thai (no copy-paste)
6. Add Thailand applicability notes for foreign claims
7. Add confidence label to every section
8. Add safety warnings where required (see SAFETY_POLICY.md)
9. Fill source table at bottom
10. Set "lastUpdated" frontmatter
11. Commit with conventional commit message
```

## 7. Forbidden Actions

- ❌ Publishing without sources
- ❌ Translating full copyrighted articles
- ❌ AI-generated content without human review
- ❌ Pesticide dosage recommendations
- ❌ Edible/poisonous plant identification claims
- ❌ Medical or health claims about plants
- ❌ Yield/profit/income guarantees
- ❌ Adding paid tools without explicit maintainer approval

## 8. Conventional Commits

```
feat(crops): add basil profile
fix(layout): correct mobile nav overflow
docs(methodology): clarify source confidence rules
content(culinary-herbs): add holy basil
chore(deps): bump astro to 5.x
```

## 9. Branch Protection

- `main` is protected
- All changes via PR
- Single approver: maintainer
- Tests pass before merge (when tests exist)

## 10. Audit Log

Maintain `docs/AUDIT_LOG.md` for:
- Architectural decisions
- Source policy changes
- Content removal/correction events
- Major refactors

## 11. Last Updated Footer

Every crop profile page MUST display:
- Last updated date
- Contributor (default: Prem)
- Reviewer (if applicable)

This is non-negotiable for trust.
