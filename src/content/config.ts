import { defineCollection, z, reference } from 'astro:content';

/* ============================================
   Schema Definitions — Kaset Atlas Content
   ============================================ */

// Confidence levels for source reliability
const ConfidenceLevel = z.enum(['high', 'medium', 'low', 'uncertain']);

// Source type taxonomy
const SourceType = z.enum([
  'thai-government',      // กรมวิชาการเกษตร, กรมส่งเสริมการเกษตร, etc.
  'thai-university',      // มหาวิทยาลัยเกษตรศาสตร์, แม่โจ้, etc.
  'international-org',    // FAO, CGIAR, World Bank
  'university-extension', // US/EU/etc university extension
  'peer-reviewed',        // Open-access research papers
  'reputable-media',      // Established agricultural journalism
  'expert-author',        // Books/manuals by named experts
  'farmer-org',           // Farmer cooperative documents
  'manufacturer',         // Seed company, ag-tech vendors
  'forum-anecdote',       // Forum posts (low confidence)
  'other',
]);

// 10 categories of Kaset Atlas
const CategorySlug = z.enum([
  'food-crops',
  'fruit-trees',
  'culinary-herbs',
  'medicinal-plants',
  'beverage-crops',
  'industrial-crops',
  'ornamental',
  'forage-fodder',
  'cover-crops',
  'mushrooms',
]);

// Thai climate regions
const ThaiRegion = z.enum([
  'north',          // ภาคเหนือ
  'northeast',      // ภาคตะวันออกเฉียงเหนือ
  'central',        // ภาคกลาง
  'east',           // ภาคตะวันออก
  'west',           // ภาคตะวันตก
  'south',          // ภาคใต้
  'highland',       // ที่สูง (>800m)
  'all',            // ทุกภาค
]);

// Difficulty for growers
const DifficultyLevel = z.enum(['easy', 'moderate', 'hard', 'expert']);

/* ============================================
   Crops Collection
   ============================================ */

const crops = defineCollection({
  type: 'content',
  schema: z.object({
    // Identity
    title: z.string(),                    // ชื่อพืชภาษาไทย
    titleEn: z.string(),                  // English/common name
    scientificName: z.string(),           // Genus species
    aliases: z.array(z.string()).default([]), // ชื่อท้องถิ่น/ชื่ออื่น

    // Classification
    category: CategorySlug,
    family: z.string().optional(),        // Botanical family
    growthForm: z.enum([
      'herb', 'shrub', 'tree', 'vine',
      'grass', 'succulent', 'aquatic', 'fungus'
    ]).optional(),
    lifeCycle: z.enum(['annual', 'biennial', 'perennial']).optional(),

    // Quick reference
    summary: z.string().max(280),         // 1-2 sentence summary
    difficulty: DifficultyLevel,
    timeToHarvest: z.string(),            // "60-90 days" / "3-5 years"

    // Growing conditions (quick view)
    suitableRegions: z.array(ThaiRegion),
    waterNeed: z.enum(['low', 'medium', 'high']),
    sunNeed: z.enum(['shade', 'partial', 'full']),
    soilTypes: z.array(z.string()).default([]),

    // Risk & safety
    mainRisks: z.array(z.string()).default([]),
    bestFor: z.array(z.string()).default([]),
    notSuitableFor: z.array(z.string()).default([]),

    // Metadata
    contributor: z.string().default('Prem Pawee'),
    reviewer: z.string().optional(),
    lastUpdated: z.coerce.date(),
    publishedAt: z.coerce.date(),
    confidenceOverall: ConfidenceLevel,

    // Display
    heroImage: z.string().optional(),
    heroImageAlt: z.string().optional(),
    draft: z.boolean().default(false),

    // SEO
    seoTitle: z.string().optional(),
    seoDescription: z.string().max(160).optional(),
  }),
});

/* ============================================
   Categories Collection
   NOTE: 'slug' is reserved by Astro for type:'content' collections
   and is auto-derived from the filename. Do NOT include slug in schema.
   Access via: category.slug (auto) or category.id
   ============================================ */

const categories = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),                    // ภาษาไทย
    titleEn: z.string(),
    description: z.string(),
    icon: z.string().optional(),
    order: z.number(),                    // Display order
    targetCount: z.number().default(50),  // Long-term content goal
    color: z.string().optional(),         // Optional brand override
  }),
});

/* ============================================
   Sources Collection — central source registry
   ============================================ */

const sources = defineCollection({
  type: 'data',
  schema: z.object({
    id: z.string(),                       // Stable ID for citation
    title: z.string(),
    authors: z.array(z.string()).default([]),
    organization: z.string().optional(),
    sourceType: SourceType,
    confidence: ConfidenceLevel,
    url: z.string().url().optional(),
    accessDate: z.coerce.date(),
    publicationDate: z.coerce.date().optional(),
    language: z.enum(['th', 'en', 'zh', 'ja', 'other']).default('th'),

    // Thailand applicability
    appliesToThailand: z.enum(['directly', 'partially', 'with-caveats', 'unclear']),
    thailandNote: z.string().optional(),

    // Quality flags
    peerReviewed: z.boolean().default(false),
    openAccess: z.boolean().default(true),
    notes: z.string().optional(),
  }),
});

/* ============================================
   Export Collections
   ============================================ */

export const collections = {
  crops,
  categories,
  sources,
};
