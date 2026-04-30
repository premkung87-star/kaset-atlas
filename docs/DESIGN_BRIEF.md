# Kaset Atlas — Frontend Design Brief

> **Hand this entire document to Claude Design (or any UI/UX designer).** It is self-contained — you do not need to have seen the codebase to do this work.

> **Last updated:** 2026-04-30
> **Maintainer:** Prem (solo)
> **Live site:** https://kasetatlas.com/
> **Repo:** https://github.com/premkung87-star/kaset-atlas

---

## 1. The Project in One Paragraph

**Kaset Atlas (เกษตรแอตลาส)** is a public-good, open-source Thai-language agricultural reference. The mission is to **bridge global agricultural knowledge into Thai**, for Thai farmers and the general public. Every crop profile is researched from primary Thai-government and international sources, drafted by an AI pipeline, verified for content fidelity, and shipped under CC BY-SA 4.0. The site is built to be **machine-citable** so AI search engines (Perplexity, ChatGPT, Claude, Gemini, Google AI Overviews) can quote it accurately. Long-term target: **500 crop profiles across 10 categories**.

### The current site is a v0 launch UI

The first-run UI was scaffolded to ship content. It works but is plain. **Your job is to design the production-grade replacement** — a design that respects Thai typography, serves Thai farmers on entry-level mobile devices, and renders well to AI crawlers as semantic HTML.

---

## 2. Audience Personas

Design for these four readers, in priority order:

### Persona 1: Thai farmer (primary)
- Smallphone, often Android entry-level, frequently on 4G
- Reads Thai natively; English is secondary
- Wants practical answers fast: "Can I grow this in my soil?", "When do I plant?", "What pests should I watch for?"
- Trust matters — they need to see *who* says this and *where it's from*
- Often referred via LINE shares from a friend or government extension officer

### Persona 2: Urban Thai consumer / curious reader
- Desktop or mobile, faster connection
- Reads about crops out of curiosity, food culture, or home-garden interest
- Lower stakes than farmer but appreciates depth and good design

### Persona 3: Journalist / researcher / extension officer
- Needs to cite the page in articles, reports, training materials
- Wants source traceability (where did this claim come from?)
- Wants stable URLs and clear publication dates

### Persona 4: AI crawler (GPTBot, ClaudeBot, PerplexityBot, Google-Extended, Applebot)
- Reads HTML, JSON-LD, llms.txt
- Quotes content with attribution back to the page
- Needs **semantic HTML**, **structured headings**, **schema.org markup**, **canonical URLs**, **clear authorship**
- **Treat AI crawlers as a real audience, not an afterthought.** Half the traffic to the site over the next 5 years will likely be AI-mediated, not human-direct.

---

## 3. Brand Identity

### Voice & Personality
*"ครูเกษตรที่ใจดี แต่ตรวจแหล่งที่มาทุกครั้ง"*
"The kind agriculture teacher who always checks sources."

- **Authoritative but not academic.** Uses primary sources, not opinions.
- **Practical, not sales-y.** No yield guarantees, no "earn 100,000 baht/month" claims.
- **Honest about uncertainty.** Confidence levels are visible to the reader.
- **Open and free.** No paywall, no donation guilt, no popup overlays.

### Anti-aesthetic — what to AVOID
- ❌ Generic SaaS green-and-white tech-dashboard look
- ❌ "AI startup" gradient blobs and 3D illustrations
- ❌ Stock photos of generic farms (especially Western farms)
- ❌ Heavy iconography that competes with content
- ❌ Carousels, popup modals, marketing CTAs
- ❌ Dark mode as a flex (it's fine if added but not the primary aesthetic)

### Aesthetic — what to PURSUE
- ✅ Earth tones, warm and grounded
- ✅ Reference Thai textile/printing traditions where appropriate
- ✅ Editorial / reference-book feeling — closer to *National Geographic* or a quality field guide than to a tech blog
- ✅ Typography-first design (let words breathe)
- ✅ Calm color use — most pages should look mostly like ink-on-paper, with color for confidence badges, warnings, and accents only

### Color Tokens (already codified in `tailwind.config.ts` — keep these or evolve thoughtfully)

| Token | Hex | Use |
|---|---|---|
| Kaset Green | `#2F6B3F` | Primary brand, headings, link emphasis |
| Soil Brown | `#8A5A33` | Earth/source/citation accents |
| Sun Orange | `#F59E42` | Highlights, warnings, hover states |
| Water Blue | `#3B82A0` | Info, water-topic icons |
| Rice Cream | `#F7F1E3` | Background, paper feel |
| Charcoal | `#26312A` | Body text |

You may evolve this palette but keep the earth-tone family. Justify any new tokens.

### Confidence Color Codes (functional, not aesthetic — already in use)
- 🟢 **High confidence** — green accent, multiple high-confidence sources agree
- 🟡 **Medium confidence** — yellow/amber, fewer sources or expert disagreement
- 🔴 **Low confidence / Uncertain** — red, single source or conflicting evidence

---

## 4. Logo Brief

### Required deliverable: full logo system

1. **Wordmark** — "Kaset Atlas" in Latin + "เกษตรแอตลาส" in Thai
   - Both scripts must visually balance — Thai is taller than Latin and has diacritics; the design must accommodate
2. **Symbol/mark** — a small icon that works alone (favicon, app icon, social avatar)
3. **Lockups** — horizontal, vertical, mark-only
4. **Monochrome variants** — black, white, single-color
5. **Favicon set** — 16x16, 32x32, 48x48, 180x180 (Apple), 512x512 (PWA)
6. **Open Graph image** — 1200x630 for social sharing
7. **Logo guidelines** — minimum size, clear-space rules, do/don't examples

### Concept direction

Think **map + plant + grain**. The word "Atlas" implies geography, navigation, authority. "Kaset" (เกษตร) means agriculture. The logo should suggest:
- A reference / book / atlas (authoritative, comprehensive)
- A growing thing (plant, seedling, leaf)
- Thailand specifically — without being kitsch

Avoid: generic leaves, generic globes, generic pins, generic tractors. **Pursue something that could only be Kaset Atlas.**

### Anti-suggestions
- ❌ Garuda or any royal/official Thai government iconography (we are NOT a government site)
- ❌ Thai temple silhouettes
- ❌ Map of Thailand outline (cliché)
- ❌ Realistic farm imagery
- ❌ Anything that looks like a Thai agricultural ministry logo

---

## 5. Typography

### Thai-first typography rules

Latin-only designers often get Thai typography wrong. **Thai script has specific needs:**

1. **Diacritics extend vertically** — Thai vowels and tone marks sit above and below the baseline, sometimes both. **Line-height must be looser than Latin equivalent** — recommend `1.7-1.8` for body, `1.4-1.5` for headings.
2. **No word spacing** — Thai prose has no spaces between words; the browser uses dictionary lookup for line-breaking. Don't fake-justify Thai text. **Use `text-align: left` (or `start`)** with looser tracking, not `justify`.
3. **Thin strokes are problematic on low-DPI screens** — avoid font weights below 400 for body Thai text. 400-500 is the readable range.
4. **Font fallback chain matters** — many Thai readers' devices may not have webfonts loaded; the system fallback must also be readable.

### Recommended fonts (open-source, free, usable on Vercel via `@fontsource`)

#### Body / paragraph (Thai)
- **Noto Sans Thai** (Google Fonts) — extremely well-tested, neutral, works at all sizes, broad weight range
- Alternative: **IBM Plex Sans Thai** (more editorial feeling)

#### Body / paragraph (Latin)
- **Inter** or **IBM Plex Sans** — pairs well with the above

#### Display / headings
- **Sarabun** or **Kanit** for Thai display — both are widely-used, modern Thai sans-serif
- Pair with **Bricolage Grotesque** or **IBM Plex Sans** for Latin display
- Optional: a serif for occasional editorial flourish (e.g., **Sarabun** body + **IBM Plex Serif Thai** for pull-quotes)

#### Final pick is yours
Pick **one Thai display + one Thai body + one Latin body**, document your rationale, and provide:
- Google Fonts / @fontsource links
- A typographic scale (sizes, line-heights, weights)
- A pairing rationale

### Type scale starting point

| Level | Size (mobile) | Size (desktop) | Weight | Line-height |
|---|---|---|---|---|
| H1 | 28-32px | 40-48px | 600 | 1.3 |
| H2 | 22-24px | 30-32px | 600 | 1.35 |
| H3 | 18-20px | 22-24px | 600 | 1.4 |
| Body | 16-17px | 17-18px | 400 | 1.7 |
| Small | 14-15px | 14-15px | 400 | 1.6 |
| Caption | 13px | 13px | 400 | 1.55 |

Thai readers tend to need slightly larger body text than Latin equivalents. Don't go below 16px on mobile body.

---

## 6. Information Architecture

The site has these page types (already in code, but visual design is yours):

### 6.1 Homepage `/`
- Project mission (1-2 sentences in Thai, fallback in English)
- Search bar (Pagefind — currently displays "ระบบค้นหาพร้อมใช้งานเมื่อ deploy production" placeholder)
- Categories grid (10 cards, one per category)
- Recently added crops (3-6 crop cards)
- Footer with: license, contributor model, GitHub link, sitemap

### 6.2 Categories index `/categories`
- All 10 categories as a list/grid
- Each category shows count of crops + brief description
- Visual distinction between categories with content (active) and empty (coming soon)

### 6.3 Single category `/categories/{slug}` (e.g. `/categories/food-crops`)
- Category title + description
- List of crops in that category (alphabetical or by recency)
- Filter/sort controls (later)

### 6.4 Single crop `/crops/{slug}` (the highest-traffic page type — design this carefully)
- Title (Thai + scientific name)
- Hero summary (1-2 sentences)
- **12 numbered sections** (this is the core content — see structure below)
- Inline confidence badges (🟢🟡🔴)
- Inline `<SourceBox>`, `<ThailandBox>`, `<WarningBox>` components
- Source table at the bottom (11+ rows typical)
- "Last updated" + "Contributor: AI Pipeline (auto)" footer
- Share / cite buttons (later)

#### The 12 sections (universal across all crops)
1. ปลูกในไทยได้หรือไม่ (Can it grow in Thailand?)
2. ภูมิอากาศที่เหมาะสม (Suitable climate)
3. ดินและการเตรียมดิน (Soil and preparation)
4. การให้น้ำ (Watering)
5. วิธีการปลูก (Planting method)
6. การดูแลรักษา (Care)
7. โรคและแมลงศัตรูพืช (Pests and diseases) — usually contains a `<WarningBox>`
8. การเก็บเกี่ยว (Harvest)
9. ต้นทุนและความเสี่ยงทางเศรษฐกิจ (Economics and risk)
10. หมายเหตุเฉพาะประเทศไทย (Thailand-specific notes) — usually contains a `<ThailandBox>`
11. ความรู้จากต่างประเทศ (Foreign knowledge applicability)
12. แหล่งข้อมูล (Sources table)

### 6.5 About `/about`
- Project mission, license, funding, contact
- AI-generated content disclosure (transparency)
- Methodology link
- Maintainer info

### 6.6 404 / not-found
- Friendly Thai message
- Search bar
- Top categories link

---

## 7. Component Library

These components already exist in code (in `src/components/`). **Your design should specify their visual treatment.**

### `<SourceBox>` — citation block
Shows a single source with title, URL, type (gov / university / international), confidence level. Used inline in crop content to anchor specific claims to specific sources.

### `<ThailandBox>` — Thailand applicability note
Pulls foreign source claims into Thai context. Visual treatment should signal "this is the localized angle." Subtle, not loud.

### `<WarningBox>` — safety warning
Used in pest/disease sections, food-safety warnings, and similar. Three severity levels:
- `info` — neutral info
- `caution` — yellow accent
- `danger` — red accent (rare, used for HCN cassava etc.)

### `<ConfidenceBadge>` — section confidence indicator
Small chip showing 🟢 High / 🟡 Medium / 🔴 Low at the start of each major section.

### Card components needed
- **CategoryCard** — for homepage + categories index
- **CropCard** — for category pages + recently-added on home
- **SourceTableRow** — for the §12 source table (already markdown table; consider whether to enhance)

### Navigation
- Top nav: logo + breadcrumb-style location + search trigger
- No sticky bar required (let content breathe), but consider for crop pages
- Mobile: hamburger menu or bottom-tab navigation

### Search UI (Pagefind integration — currently scaffold only)
Pagefind is a static-site search engine. UI components needed:
- Search input (in nav or as overlay)
- Results dropdown / page
- Result cards with crop title + matched snippet + category
- Empty state ("No results — try [popular searches]")
- Recent searches (localStorage)

---

## 8. Mobile-First Specifications

**Most Thai users will read this on a phone.** Design mobile-first, then enhance for desktop.

### Breakpoints
- Mobile: 360-640px (most Thai Android phones)
- Tablet: 640-1024px
- Desktop: 1024px+

### Mobile must-haves
- Tap targets ≥ 44x44px
- Thumb-reachable primary actions (bottom of screen, not top)
- Crop page must be readable scrolling continuously without horizontal swipe
- Sections collapsible? Or all-open? **My recommendation: all-open by default, with sticky table-of-contents on desktop.**
- Source table on mobile: card-stack format, not horizontal-scroll table
- Images: lazy-loaded, WebP, max-width 100% (Vercel image optimization handles this if you use `<Image>`)

### Performance budget
- LCP < 2.5s on 4G
- CLS < 0.1
- INP < 200ms
- Total page weight < 200KB for typical crop page (excluding lazy-loaded images)

These are firm. Thai farmers on 4G must not wait.

---

## 9. Accessibility Requirements

### WCAG 2.1 AA minimum

- **Color contrast** — body text ≥ 4.5:1 against background; large text ≥ 3:1
- **Focus indicators** — visible, high-contrast outlines on all interactive elements
- **Keyboard navigation** — all functionality accessible without mouse
- **Skip-to-content link** at top of every page
- **ARIA labels** — in Thai for Thai-language pages, English for fallback
- **Heading hierarchy** — H1 once per page, H2 for sections, no skipped levels
- **Form labels** — explicit `<label for="...">` for any input (search, etc.)
- **Reduced motion** — respect `prefers-reduced-motion` media query (no auto-playing animations for users who set this)
- **Screen reader** — Thai screen readers (NVDA-Thai, VoiceOver Thai voice) must read content correctly; use `lang="th"` and proper semantic HTML

### Keyboard shortcuts (optional but appreciated)
- `/` to focus search
- `Esc` to close modals/menus

---

## 10. AI-Citability Requirements

This is **first-class**, not an afterthought.

### Semantic HTML
- Use `<article>` for crop content
- Use `<section>` for each of the 12 numbered sections, with proper heading
- Use `<header>` for page titles + metadata
- Use `<footer>` for last-updated + contributor
- Use `<aside>` for source tables, callouts, related-crops

### Schema.org JSON-LD (already implemented; verify your design preserves it)
- `Article` for crop pages with author = "AI Pipeline (auto)"
- `WebSite` + `Organization` on homepage
- `BreadcrumbList` for category navigation
- `ItemList` for category pages

### Open Graph + Twitter cards
- Title, description, image (the OG image you design at 1200x630)
- `og:locale="th_TH"` for Thai content

### Citation-friendly headings
Every numbered section heading must be **uniquely identifiable as a URL fragment** (e.g. `#1-thailand-applicability`) so an AI can cite a specific section.

### Link to canonical URL prominently
A small "อ้างอิงหน้านี้" (Cite this page) button near the page title that copies a citation-formatted string (URL + title + date + license) to clipboard.

### llms.txt
Already at `/llms.txt`. Your design doesn't need to change this, but be aware AI crawlers will read it.

---

## 11. Specific Design Challenges

These are non-obvious problems unique to this project. Solve them in the design.

### Challenge A: Confidence badges without visual clutter
Every section has a confidence rating, AND many claims have inline source citations. If everything is highlighted, nothing is. Find a treatment that surfaces the data without making the page feel like a Wikipedia disclaimer-fest.

### Challenge B: 11-source table on mobile
The §12 sources table has 4 columns (topic, source name, type, confidence) and 11+ rows. On mobile this is unreadable as a table. Design a card-stack alternative.

### Challenge C: Thai/English code-switching
Scientific names are always Latin (e.g. *Manihot esculenta*). Source titles are sometimes English, sometimes Thai. Some bilingual readers want both. Find a typographic treatment that handles mixed-script gracefully without italic-fatigue.

### Challenge D: AI-generated transparency without paranoia
Every page must disclose "AI Pipeline (auto)" as contributor. This is a trust feature, not a shame badge. Find a treatment that says "we are transparent about this, here is how it works" rather than "AI slop, beware."

### Challenge E: Empty categories
Several of the 10 categories have zero crops. Their landing pages need a "coming soon" treatment that's hopeful, not broken-feeling.

### Challenge F: Kaset Green is hard for some Thai users
The brand green (`#2F6B3F`) approaches the color of unhealthy plants in some contexts. Make sure the brand green never appears on plant imagery or backgrounds where it could be misread.

---

## 12. Deliverables Expected

Please return:

### Phase A — Strategy (text + 2-3 inspiration boards)
1. Brand strategy summary (300-500 words) — your interpretation of the voice + aesthetic + audience
2. Two visual mood boards: (a) typography references, (b) color/illustration references
3. Justification of any palette evolution from the existing tokens

### Phase B — Logo (4-6 directions, then 1 final)
4. 4-6 logo concept sketches
5. After review: 1 final logo system (per Section 4 above)

### Phase C — Design System (Figma file or equivalent)
6. Color tokens (primary, secondary, semantic, neutrals — exact hex values)
7. Typography scale (with font picks + reasoning)
8. Spacing scale (4-or-8-point grid recommended)
9. Component library (all components from Section 7, with desktop + mobile states)
10. Iconography style (if needed — keep minimal)

### Phase D — Page Designs (Figma)
11. Homepage — desktop + mobile
12. Crop page (use cassava as the test case — most complex layout) — desktop + mobile
13. Category page — desktop + mobile
14. Categories index, About, 404 — at least mobile views
15. Search results state (with Pagefind integration in mind)

### Phase E — Handoff
16. Design tokens exported as JSON or CSS variables (so devs can apply directly to `tailwind.config.ts`)
17. Logo files: SVG, PNG @1x, PNG @2x, monochrome variants
18. Favicon set (per Section 4)
19. Open Graph default image (1200x630 SVG/PNG)
20. Brief design-rationale document (1-2 pages) explaining major choices

---

## 13. Out of Scope

These are explicitly **not** part of this design brief:

- ❌ Marketing landing pages
- ❌ Blog / news / changelog UI (use GitHub commits + AUDIT_LOG instead)
- ❌ User accounts / login UI (no auth in V1)
- ❌ Comments / community features
- ❌ Donation / subscription flows (project is non-profit, no donations accepted in V1)
- ❌ Email signup forms
- ❌ Animations beyond subtle hover states (project is content-first, not interaction-first)
- ❌ Dark mode (can be added later; not a V1 requirement)
- ❌ Designs for `prempawee.com` or other separate maintainer projects

---

## 14. Constraints to Honor

- **Build target:** Astro + Tailwind v3 + MDX. Designs must be implementable with utility classes.
- **No JavaScript framework dependencies** beyond what Astro ships (some React islands are OK; avoid heavy libraries).
- **Free and open-source fonts only** (no paid type licenses).
- **All assets must be CC BY-SA 4.0 compatible** (logos, illustrations, icons).
- **No external CSS frameworks** beyond Tailwind v3 and `@fontsource`.
- **Design must work without JS** (progressive enhancement) — JS is for search, not for content rendering.

---

## 15. Reference URLs

Look at these for context:

- **Live site (current state):** https://kasetatlas.com/
- **Cassava page (most complex content):** https://kasetatlas.com/crops/cassava/
- **GitHub repo:** https://github.com/premkung87-star/kaset-atlas
- **Methodology document:** https://github.com/premkung87-star/kaset-atlas/blob/main/docs/METHODOLOGY.md
- **Source policy:** https://github.com/premkung87-star/kaset-atlas/blob/main/docs/SOURCE_POLICY.md
- **CLAUDE.md (operating manual):** https://github.com/premkung87-star/kaset-atlas/blob/main/CLAUDE.md

### Inspiration to study (not to copy)
- **National Geographic** — typography, photo-text balance, editorial authority
- **The Pudding** — long-form data storytelling
- **Our World in Data** — content density without overwhelm, citation discipline
- **Stripe Press** — book-like reading experience, type discipline
- **Ferd Christianson's** Thai design work (search "ผู้ออกแบบไทย editorial") — Thai typography that doesn't try to be Latin

### Anti-references (do not study these)
- Most Thai government websites — design is dated, hierarchy is buried
- Generic crop-encyclopedia sites — visual hierarchy fails, source-citation invisible
- Tech-startup landing pages — wrong tone for a public-good reference

---

## 16. Maintainer Context

The maintainer (Prem) is a solo operator. There is no design committee. Make confident choices, justify them, and present them as decisions, not options. If you must offer alternatives, offer at most A/B (not A/B/C). The maintainer values:
- Decision over hesitation
- Specificity over abstraction
- Thai-first authenticity over Western-influenced polish
- Long-term simplicity over short-term cleverness

---

## 17. Success Criteria

This design succeeds if:

1. A Thai farmer can read a crop page on a 360px-wide Android phone in direct sunlight and find the answer they need in under 30 seconds.
2. An AI search engine quotes a passage and gets the citation back to the source URL right.
3. A journalist links to the page in an article without hesitation about source quality.
4. The maintainer can ship 50 more crop profiles without re-touching any visual layout.
5. Six months from now, when 50+ crops are live, the design still feels right — not dated, not in need of a redesign.

If the design only looks good but fails any of the above, it is not yet done.

---

**End of brief. Ask the maintainer for clarifications before starting if anything is ambiguous.**
