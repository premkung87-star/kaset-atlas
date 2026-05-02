---
id: mango
title_th: "มะม่วง"
title_en: "Mango"
scope_in:
  - "Cultivation of Mangifera indica in Thailand across the four-region geography"
  - "Cultivar facts for Nam Dok Mai Si Thong, Mahachanok, Khiao Sawoei, Ok Rong, Chok Anan, Kaeo"
  - "Off-season induction principles (named compounds only, no dosages)"
  - "Mango export pathway including the Japan VHT requirement"
  - "Pest and disease overview at a Thai-context level"
scope_out:
  - "Specific paclobutrazol / thiourea / KNO3 dosages or concentrations"
  - "Pesticide product recommendations or rates"
  - "Mango pulp processing economics and downstream supply chain"
  - "Per-farm yield or profit guarantees"
last_updated: 2026-05-02
last_audited: 2026-05-02
related_topics: []
---

## Overview

This topic page restates the per-section confidence findings from `src/content/crops/mango.mdx` (and its companion `mango.reasoning.json`) as Phase 8 v1 wiki claim cards. The claim cards reference the source cards under `wiki/sources/mango/`. The intent is to prove the schema round-trips with a real, already-published crop.

## Claims

```yaml
claims:
  - claim_id: mango-thailand-applicability
    section_ref: "1_thailand_applicability"
    statement_th: "มะม่วงปลูกได้ทั่วทุกภาคของไทย โดยภาคใต้เป็นกรณีที่จำกัดเนื่องจากฝนชุกและขาดฤดูแล้งที่ชัดเจน"
    statement_en: "Mango can be grown across all four Thai regions; the South is the constrained case because heavy rainfall and the absence of a clear dry-flowering window make natural induction unreliable."
    supporting_source_ids:
      - doa-hort-mango-db
      - doae-mango-export-3-2565
      - aujt-thai-mango-export
    confidence: high
    thailand_applicability: native
    last_verified: 2026-04-30
    notes: ""

  - claim_id: mango-climate
    section_ref: "2_climate"
    statement_th: "มะม่วงต้องการช่วงแล้ง 2-3 เดือนก่อนออกดอก แสงแดดเต็มวัน และอากาศเย็นในช่วงสะสมตาดอก"
    statement_en: "Mango requires a clear 2–3 month dry period before flowering, full-sun exposure, and a cool-period stimulus to set buds; conditions found across northern and northeastern Thailand in winter."
    supporting_source_ids:
      - purdue-newcrop-morton-mango
      - doa-hort-mango-db
      - doae-esc-mango-off-season
    confidence: high
    thailand_applicability: native
    last_verified: 2026-04-30
    notes: ""

  - claim_id: mango-soil
    section_ref: "3_soil"
    statement_th: "มะม่วงเหมาะกับดินร่วน ดินร่วนปนทราย หรือดินร่วนปนดินเหนียวที่ระบายน้ำดี ไม่ควรปลูกในพื้นที่น้ำขังหรือดินที่มีชั้นดานแข็ง"
    statement_en: "Mango performs best in well-drained loam, sandy loam, or clay-loam soils; waterlogged sites or soils with hardpan layers must be avoided to prevent root rot."
    supporting_source_ids:
      - doa-share-mango-cultivation
      - doa-hort-mango-db
    confidence: high
    thailand_applicability: native
    last_verified: 2026-04-30
    notes: ""

  - claim_id: mango-water
    section_ref: "4_water"
    statement_th: "มะม่วงทนแล้งได้ปานกลางหลังตั้งตัว แต่ต้องการน้ำสม่ำเสมอในระยะต้นกล้าและระยะติดผล การงดน้ำ 1-2 เดือนก่อนชักนำการออกดอกเป็นเทคนิคสำคัญ"
    statement_en: "Mature mango trees tolerate moderate drought, but require consistent water during establishment and fruit development. A 1–2 month dry-down before induction is a core practice in commercial Thai cultivation."
    supporting_source_ids:
      - doa-share-mango-cultivation
      - doae-esc-mango-off-season
      - purdue-newcrop-morton-mango
    confidence: high
    thailand_applicability: native
    last_verified: 2026-04-30
    notes: ""

  - claim_id: mango-planting-and-cultivars
    section_ref: "5_planting"
    statement_th: "การขยายพันธุ์เชิงพาณิชย์ใช้ทาบกิ่งหรือต่อกิ่ง พันธุ์ที่นิยมในไทยได้แก่ น้ำดอกไม้สีทอง เขียวเสวย อกร่อง มหาชนก โชคอนันต์ และแก้ว มหาชนกเป็นพันธุ์ลูกผสมของ Sunset × นางกลางวันที่พัฒนาในเชียงใหม่"
    statement_en: "Commercial propagation is by grafting (not seed). Common Thai cultivars include Nam Dok Mai Si Thong, Khiao Sawoei, Ok Rong, Mahachanok, Chok Anan, and Kaeo. Mahachanok is a Sunset × Nang Klanwan hybrid developed in Chiang Mai."
    supporting_source_ids:
      - doa-hort-mango-db
      - doa-share-mango-cultivation
      - wikipedia-mahachanok
      - ufifas-mango-mahachanok-phenology
    confidence: high
    thailand_applicability: native
    last_verified: 2026-04-30
    notes: "Mahachanok cultivar history is corroborated across Wikipedia and UF/IFAS Mango Science. The 'named in 1992 by King Bhumibol' claim was deliberately not asserted because the supporting Wikipedia text could not be re-verified."

  - claim_id: mango-care-and-off-season
    section_ref: "6_care"
    statement_th: "การดูแลรักษามะม่วงรวมถึงการใส่ปุ๋ยตามระยะเจริญเติบโต การตัดแต่งกิ่งหลังเก็บเกี่ยว และการชักนำการออกดอกนอกฤดู ซึ่งใช้พาโคลบิวทราโซลและไทโอยูเรียภายใต้คำแนะนำเจ้าหน้าที่"
    statement_en: "Care includes growth-stage fertilization, post-harvest pruning to open the canopy, and off-season induction using paclobutrazol and thiourea. Compound names are stated; rates and concentrations require local extension officer guidance and product-label compliance."
    supporting_source_ids:
      - doa-share-mango-cultivation
      - doa-share-mango-quality
      - doae-esc-mango-off-season
      - doae-mango-export-3-2565
    confidence: high
    thailand_applicability: native
    last_verified: 2026-04-30
    notes: "SAFETY_POLICY: no chemical dosages stated. Compound names only."

  - claim_id: mango-pests-and-diseases
    section_ref: "7_pests_diseases"
    statement_th: "ศัตรูพืชสำคัญได้แก่ เพลี้ยจักจั่นมะม่วง แมลงวันผลไม้ ด้วงงวงเจาะเมล็ดมะม่วง โรคหลักได้แก่ แอนแทรคโนสและราแป้ง การห่อผลและการตัดแต่งกิ่งช่วยลดความเสียหายได้"
    statement_en: "Priority pests are mango leafhopper, fruit fly, and mango seed weevil. Priority diseases are anthracnose and powdery mildew. Cultural controls — bagging, pruning, sanitation — substantially reduce damage in Thai orchards."
    supporting_source_ids:
      - doa-hort-mango-db
      - purdue-newcrop-morton-mango
    confidence: high
    thailand_applicability: native
    last_verified: 2026-04-30
    notes: "A DOAE news source on mango seed weevil was identified during research but not promoted into the MDX source table; the claim is supported by DOA HRI and Purdue."

  - claim_id: mango-harvest-and-postharvest
    section_ref: "8_harvest"
    statement_th: "มะม่วงทาบกิ่งเริ่มให้ผลผลิตใน 3-5 ปีหลังปลูก การเก็บเกี่ยวด้วยมือและตัดขั้วยาวพอ มะม่วงส่งออกตลาดญี่ปุ่นต้องผ่านการอบไอน้ำ (vapour heat treatment)"
    statement_en: "Grafted mango trees begin fruiting in years 3–5. Harvest is by hand with stalks left long enough to prevent latex staining. Export-grade fruit destined for Japan must undergo vapour heat treatment (VHT) for fruit-fly disinfestation."
    supporting_source_ids:
      - purdue-newcrop-morton-mango
      - doa-share-mango-quality
      - doae-mango-export-3-2565
      - aujt-thai-mango-export
    confidence: high
    thailand_applicability: native
    last_verified: 2026-04-30
    notes: ""

  - claim_id: mango-economics
    section_ref: "9_economics"
    statement_th: "มะม่วงเป็นการลงทุนระยะยาว เกษตรกรไทยส่วนใหญ่ขายในประเทศ สัดส่วนเพื่อการส่งออกยังจำกัด ความเสี่ยงรวมถึงราคาตกในฤดูปกติ ต้นทุนแรงงาน และข้อกำหนดสุขอนามัยพืชของประเทศผู้นำเข้า"
    statement_en: "Mango is a long-horizon investment. Most Thai output is consumed domestically; the export share is the minority. Risks include in-season price collapse, labour cost (especially for bagging), and shifting phytosanitary rules in destination markets."
    supporting_source_ids:
      - doae-mango-export-3-2565
      - aujt-thai-mango-export
      - fao-major-tropical-fruits-2018
    confidence: medium
    thailand_applicability: native
    last_verified: 2026-04-30
    notes: "No specific cost-of-production figures cited (project policy: no profit/yield guarantees)."

  - claim_id: mango-thailand-regional-notes
    section_ref: "10_thailand_notes"
    statement_th: "ภาคเหนือมีอากาศเย็นในฤดูหนาวเอื้อต่อการชักนำการออกดอกและเป็นถิ่นกำเนิดของมหาชนก ภาคกลางเป็นแหล่งผลิตเพื่อการส่งออก ภาคอีสานมีดินทรายต้องปรับปรุงดิน ภาคใต้ฝนชุกจึงนิยมพันธุ์ที่ออกผลหลายรุ่น"
    statement_en: "Northern Thailand's cool winter favours induction and is the origin of Mahachanok. Central Thailand is the export-production hub. The Northeast has sandy soils requiring amendment. The South — heavy rainfall, no clear dry season — favours multi-flush cultivars such as Chok Anan."
    supporting_source_ids:
      - doa-hort-mango-db
      - doa-share-mango-cultivation
      - wikipedia-mahachanok
    confidence: high
    thailand_applicability: native
    last_verified: 2026-04-30
    notes: ""

  - claim_id: mango-foreign-knowledge
    section_ref: "11_foreign_knowledge"
    statement_th: "แหล่งต่างประเทศ (Purdue, UF/IFAS, FAO) ให้หลักการพื้นฐานที่ใช้ได้ในไทย แต่ภูมิอากาศฟลอริดา พันธุ์ที่นิยม และกฎระเบียบการส่งออกแตกต่างจากไทย"
    statement_en: "International sources (Purdue NewCROP, UF/IFAS, FAO) provide universally applicable agronomic principles, but Florida's climate, cultivar palette (Tommy Atkins, Haden, Kent) and regulatory environment differ from Thailand and require explicit applicability flags."
    supporting_source_ids:
      - purdue-newcrop-morton-mango
      - ufifas-mango-florida-mg216
      - ufifas-mango-mahachanok-phenology
      - fao-major-tropical-fruits-2018
    confidence: medium
    thailand_applicability: foreign-with-caveats
    last_verified: 2026-04-30
    notes: "All four sources are foreign; downgraded to medium because Thai-context cultivar and regulatory specifics are not directly addressed by these references."
```
