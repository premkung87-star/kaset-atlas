# pawee/ — Earned Wisdom Extensions

## Purpose
Extensions to the Karpathy baseline (`../karpathy/`) derived from shipping production projects. Every rule traces back to a specific incident or AUDIT_LOG entry from the source project that taught the lesson.

## Subfolders
- **`extensions/`** — Numbered rules §5+ that extend Karpathy §1-§4. Each file uses Strategy B format: verbatim source text + Generic Pattern abstraction with stack-specific manifestations.
- **`audit-patterns/`** — Patterns for writing effective AUDIT_LOG entries (Phase 1.4b).
- **`tags/`** — Documentation of the tag taxonomy and stack-profile routing (Phase 1.4b).
- **`opus-4-7-guidance.md`** — Anthropic official Opus 4.7 prompting guidance (Phase 1.4b).

## Extension File Format (Strategy B)

Every file in `extensions/` has three parts:

1. **Frontmatter** — Machine-readable metadata (number, title, tags, applies_to, universal flag, source, incident_refs)
2. **Verbatim from Source** — Original text from the source project, byte-faithful. This is the "case study" — the concrete incident that taught the lesson.
3. **Generic Pattern (Strategy B Abstraction)** — Stack-agnostic principle that can be applied to any project, plus stack-specific manifestations. This is what makes the rule reusable.

## Tag Taxonomy

| Tag | Meaning |
|---|---|
| UNIVERSAL | Applies to all stacks |
| NEXTJS | Specific to Next.js |
| VERCEL | Specific to Vercel deployment |
| EDGE_RUNTIME | Edge runtime environments |
| CDN | About CDN behavior |
| ASYNC | About async/await discipline |
| OBSERVABILITY | Logging, monitoring, error tracking |
| GIT_DISCIPLINE | Commit hygiene, PR scope |
| FRAMEWORK_VERSION | Framework version verification |
| BROWSER_E2E | Browser-based end-to-end verification |
| OPUS_4_7 | Opus 4.7 specific behavioral tuning |
| CODE_REVIEW | Code review process |
| INVESTIGATION | Read before answering |
| SIMPLICITY | Avoid overengineering |
| SAFETY | Reversibility and destructive action discipline |

## Stack Profiles (applies_to)

| Profile | Description |
|---|---|
| generic | Any project, any stack |
| nextjs-vercel-supabase | Next.js + Vercel + Supabase (NWL CLUB, prempawee, etc.) |
| iot-multi-repo | Multi-repo IoT/firmware (VerdeX) |

## How Bootstrap Uses This Folder

`bootstrap/bootstrap.sh` reads the `applies_to` frontmatter field of each extension and includes only the rules matching the chosen project's stack profile. A `generic` project gets all rules tagged for `generic`. A `nextjs-vercel-supabase` project gets `generic` rules plus all rules with `nextjs-vercel-supabase` in their `applies_to` list.

## Adding a New Extension

1. Choose the next sequential number (do not reuse §5-§14).
2. Identify the source incident — what AUDIT_LOG entry or production failure taught this lesson?
3. Copy the source rule verbatim into "Verbatim from Source" section.
4. Write the Generic Pattern abstraction.
5. Apply correct frontmatter using the taxonomy above.
6. Update `../KARPATHY.md`-equivalent meta-summary if the kit ever ships one.
