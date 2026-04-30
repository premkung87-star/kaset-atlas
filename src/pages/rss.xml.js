import rss from '@astrojs/rss';
import { getCollection } from 'astro:content';

export async function GET(context) {
  const crops = await getCollection('crops', ({ data }) => data.draft !== true);

  const sortedCrops = crops.sort(
    (a, b) =>
      new Date(b.data.publishedAt ?? b.data.lastUpdated).getTime() -
      new Date(a.data.publishedAt ?? a.data.lastUpdated).getTime()
  );

  return rss({
    title: 'Kaset Atlas — เกษตรแอตลาส',
    description:
      'พืชใหม่และการอัปเดตล่าสุดจาก Kaset Atlas — ความรู้เกษตรของโลก เพื่อเกษตรกรไทย',
    site: context.site,
    items: sortedCrops.map((crop) => ({
      title: `${crop.data.title}${crop.data.titleEn ? ` (${crop.data.titleEn})` : ''}`,
      description: crop.data.summary || crop.data.seoDescription || '',
      pubDate: new Date(crop.data.publishedAt ?? crop.data.lastUpdated),
      link: `/crops/${crop.slug}/`,
      categories: [crop.data.category, ...(crop.data.aliases ?? [])].filter(Boolean),
      author: 'AI Pipeline (auto) — Kaset Atlas',
      customData: crop.data.scientificName
        ? `<scientificName>${crop.data.scientificName}</scientificName>`
        : undefined,
    })),
    customData: `<language>th-TH</language>
<copyright>เนื้อหาเผยแพร่ภายใต้ CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0/</copyright>
<atom:link href="${context.site}rss.xml" rel="self" type="application/rss+xml" />`,
    xmlns: {
      atom: 'http://www.w3.org/2005/Atom',
    },
    stylesheet: false,
  });
}
