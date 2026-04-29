# Source Policy — Kaset Atlas

> **No source, no merge.**

This document defines what counts as an acceptable source on Kaset Atlas, how to label confidence, and how to cite.

---

## 1. Core Rule

Every important agricultural claim on Kaset Atlas must be **either**:

- (a) Backed by a verifiable source, **or**
- (b) Explicitly labeled as uncertain, anecdotal, or under review

Unsupported claims that are presented as fact will be **removed**, regardless of who wrote them.

---

## 2. Confidence Levels

### 🟢 High Confidence

Use when claim is supported by:

- Thai government agricultural agencies (กรมวิชาการเกษตร, กรมส่งเสริมการเกษตร, กรมพัฒนาที่ดิน, สวก.)
- Thai public universities with agriculture programs (เกษตรศาสตร์, แม่โจ้, เชียงใหม่, ขอนแก่น, สงขลานครินทร์)
- FAO, CGIAR, World Bank, IRRI agricultural publications
- Peer-reviewed open-access research papers
- Established international university extension services (UC Davis, Cornell, Wageningen, etc.)

### 🟡 Medium Confidence

Use when claim is supported by:

- Reputable agricultural media (เทคโนโลยีชาวบ้าน, รักบ้านเกิด — when sourcing experts)
- Books or manuals from named, credentialed experts
- University agricultural blogs
- Extension YouTube channels with verified expert credentials
- Documented farmer organization publications

### 🟠 Low Confidence

Use sparingly, with explicit labeling:

- Reputable forum discussions with multiple corroborating posts
- Single-source farmer testimonials with practical detail
- Trade publications without clear methodology
- Manufacturer documentation (acceptable for product specs only, not claims)

### ⚪ Uncertain / Anecdotal

Use only to surface questions, not as proof:

- Anonymous forum posts
- Social media claims
- Unverified blog posts
- AI-generated content (without human verification)
- Personal anecdotes without documentation
- Seller or vendor claims

---

## 3. Required Citation Metadata

Every source in `src/content/sources/` must include:

| Field | Required | Notes |
|---|---|---|
| `id` | ✓ | Stable, unique identifier |
| `title` | ✓ | Full title of source |
| `sourceType` | ✓ | From SourceType enum |
| `confidence` | ✓ | Confidence level |
| `accessDate` | ✓ | When you read it |
| `url` | When available | Direct link to source |
| `publicationDate` | When available | Source publication date |
| `language` | ✓ | th / en / zh / etc. |
| `appliesToThailand` | ✓ | directly / partially / with-caveats / unclear |
| `thailandNote` | When applicable | Why it does/doesn't apply |

---

## 4. Source Hierarchy by Topic

### For Climate / Soil Data
1. Thai Meteorological Department (กรมอุตุนิยมวิทยา)
2. Land Development Department (กรมพัฒนาที่ดิน)
3. FAO climate datasets

### For Crop Cultivation
1. กรมวิชาการเกษตร / กรมส่งเสริมการเกษตร
2. Thai universities with extension programs (แม่โจ้, เกษตรศาสตร์)
3. International university extension (with Thailand applicability note)

### For Pests & Diseases
1. กรมวิชาการเกษตร (สำนักวิจัยพัฒนาการอารักขาพืช)
2. CABI / EPPO international databases
3. Peer-reviewed research papers

### For Market & Economics
1. สำนักงานเศรษฐกิจการเกษตร (สศก.)
2. Bank of Thailand agricultural reports
3. FAO market data

---

## 5. International Source Translation Rules

When translating foreign sources into Thai:

✅ **DO:**
- Summarize in your own Thai words
- Cite the original source clearly
- Quote sparingly (under 30 words per quote)
- Add a Thailand applicability note for every translated claim
- Link to original

❌ **DON'T:**
- Copy-paste full paragraphs (copyright violation)
- Translate entire articles verbatim
- Present temperate-climate advice as directly applicable to Thailand
- Hide the original language of the source

---

## 6. Update Triggers

A crop profile should be re-reviewed when:

- A new high-confidence source is published on the topic
- A reader submits a corroborated correction via GitHub Issues
- More than 12 months have passed since `lastUpdated`
- A safety policy change affects the content

---

## 7. Source Removal

A source can be removed from the registry when:

- It is found to be retracted, debunked, or fabricated
- The publishing organization is found to have undisclosed conflicts
- A higher-confidence source supersedes it

Removal events are logged in `docs/AUDIT_LOG.md`.

---

## Last Updated

2026-04-29 — Initial version
