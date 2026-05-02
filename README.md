# Kaset Atlas — เกษตรแอตลาส

> ความรู้เกษตรโลก เพื่อเกษตรกรไทย
>
> Bridging global agricultural knowledge into Thai, for Thai farmers.

แพลตฟอร์มความรู้เกษตรแบบเปิด (open-source) ที่ช่วยให้เกษตรกรไทย นักเรียน นักศึกษา และผู้ที่สนใจปลูกพืช เข้าถึงความรู้เกษตรจากแหล่งที่เชื่อถือได้ทั้งในไทยและทั่วโลก แปล สรุป และปรับให้เข้ากับบริบทไทย

---

## 📢 ประกาศเรื่องการสร้างเนื้อหา (Content Generation Notice)

**ภาษาไทย:**

เนื้อหาใน Kaset Atlas สร้างและตรวจสอบโดย AI agents โดยไม่มีการรีวิวจากมนุษย์รายชิ้น เราใช้ระบบ multi-agent pipeline (Researcher → Drafter → URL Verifier → Content Verifier → Decision) ที่ตรวจสอบแหล่งที่มาและความสอดคล้องกับนโยบายของเว็บไซต์โดยอัตโนมัติ

**ผู้อ่านควรทราบ:**

- ทุกข้อมูลในเว็บไซต์เป็นจุดเริ่มต้น ไม่ใช่คำแนะนำสุดท้าย
- ก่อนตัดสินใจลงทุนหรือเปลี่ยนวิธีปลูกพืช ควรปรึกษาเจ้าหน้าที่กรมส่งเสริมการเกษตรในพื้นที่
- หากพบข้อผิดพลาด กรุณารายงานผ่าน [GitHub Issues](https://github.com/premkung87-star/kaset-atlas/issues)
- ข้อผิดพลาดที่ตรวจสอบแล้วจะถูกแก้ไขและบันทึกใน `docs/AUDIT_LOG.md`

**English:**

Kaset Atlas content is generated and verified by AI agents without per-piece human review. We use a multi-agent pipeline (Researcher → Drafter → URL Verifier → Content Verifier → Decision) with automatic source-traceability and policy compliance checks.

**Readers should:**

- Treat all information as a starting point, not final advice
- Consult local agricultural extension officers (กรมส่งเสริมการเกษตร) before making significant farming decisions
- Report errors via [GitHub Issues](https://github.com/premkung87-star/kaset-atlas/issues)

This approach prioritizes content velocity over per-piece human review. See `docs/AUDIT_LOG.md` (entry: 2026-04-29 — Policy Override) for full risk acceptance documentation.

---

## หลักการ (Non-Negotiables)

1. **เปิดและฟรี** — เนื้อหาเข้าถึงได้ฟรีสำหรับทุกคน
2. **ตรวจสอบแหล่งที่มาได้** — ทุก claim สำคัญต้องมี source (auto-verified)
3. **เป็นภาษาไทย** — แปลและสรุปจากแหล่งทั่วโลก
4. **Localize ไม่ใช่แค่แปล** — ต้องมี Thailand applicability note
5. **Open source** — โค้ดและเนื้อหาเปิดให้ตรวจสอบและแก้ไข
6. **ไม่อวดรู้ ไม่ขายฝัน** — ระบุ confidence level ทุก claim

## หมวดพืช (10 Categories)

| หมวด | ภาษาไทย | จำนวนเป้าหมาย |
|---|---|---|
| Food Crops | พืชอาหาร | 50 |
| Fruit Trees | ไม้ผล | 50 |
| Culinary Herbs & Spices | สมุนไพรปรุงอาหารและเครื่องเทศ | 50 |
| Medicinal Plants | พืชสมุนไพร | 50 |
| Beverage Crops | พืชเครื่องดื่ม | 50 |
| Industrial Crops | พืชอุตสาหกรรม | 50 |
| Ornamental | พืชประดับ | 50 |
| Forage/Fodder | พืชอาหารสัตว์ | 50 |
| Cover Crops / Green Manure | พืชคลุมดินและปุ๋ยพืชสด | 50 |
| Mushrooms | เห็ด | 50 |

**Long-term vision: 500 entries**

## เริ่มใช้งาน (Development)

```bash
# ติดตั้ง dependencies
npm install

# รัน dev server
npm run dev

# build production
npm run build

# preview build
npm run preview
```

## เพิ่ม Crop ใหม่ผ่าน Claude Code

```bash
# เปิด Claude Code ใน project root
claude

# ใช้ slash command
/add-crop กะเพรา

# Pipeline จะ:
# 1. Research แหล่งข้อมูล
# 2. Draft MDX
# 3. Verify URLs
# 4. Verify content vs sources
# 5. Auto-commit + push
```

ดู `docs/AUTOMATION_PIPELINE.md` สำหรับรายละเอียด

## โครงสร้างโปรเจกต์

```
kaset-atlas/
├── .claude/
│   ├── agents/             # Agent definitions
│   ├── commands/           # Slash commands
│   ├── queue/              # Crop queue (Phase 8)
│   └── runs/               # Per-run artifacts (gitignored)
├── src/
│   ├── content/
│   │   ├── crops/          # crop profiles (MDX)
│   │   ├── categories/     # category metadata
│   │   └── sources/        # source registry
│   ├── components/
│   ├── layouts/
│   ├── pages/
│   └── styles/
├── wiki/                   # Source-Verified Knowledge Layer (Phase 8)
│   ├── SCHEMA.md
│   ├── sources/<topic>/    # source cards
│   └── topics/             # topic pages with claim cards
├── scripts/
│   ├── verify-urls.sh      # Pre-publish URL HTTP check
│   └── verify-wiki.sh      # Wiki schema + cross-reference check
├── public/
├── docs/
│   ├── METHODOLOGY.md
│   ├── SOURCE_POLICY.md
│   ├── SAFETY_POLICY.md
│   ├── AUTOMATION_PIPELINE.md
│   ├── AUTONOMY_LANES.md   # Green/yellow/red lane policy (Phase 8)
│   ├── HANDOFF_FORMAT.md   # Per-run handoff template (Phase 8)
│   └── AUDIT_LOG.md
└── README.md
```

## Source-Verified Knowledge Layer (Phase 8)

The `wiki/` tree is the structured knowledge layer that sits underneath the rendered crop profiles. Source cards (`wiki/sources/<topic>/<id>.md`) and topic pages (`wiki/topics/<slug>.md`) carry claim-level citations with confidence rules verified by `scripts/verify-wiki.sh`. See `wiki/README.md` and `wiki/SCHEMA.md`.

The autonomy lane policy in `docs/AUTONOMY_LANES.md` and the per-run handoff format in `docs/HANDOFF_FORMAT.md` together codify the green / yellow / red decision rules that let `/add-crop` run end-to-end without mid-run human intervention.

## License

- **Code:** MIT License (see `LICENSE`)
- **Content:** Creative Commons Attribution 4.0 International (see `CONTENT_LICENSE.md`)

## Contributing

เปิดรับทุกการช่วยเหลือ — แก้คำผิด, เพิ่ม source, แปลเนื้อหา, รีวิวข้อมูล

อ่าน `docs/CONTRIBUTING.md` ก่อน และจำกฎข้อสำคัญ:

> **No source, no merge.**

## Maintainer

[Prem Pawee](https://prempawee.com) — Solo maintainer, open to collaborators.
