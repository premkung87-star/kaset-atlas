# Kaset Atlas — เกษตรแอตลาส

> ความรู้เกษตรโลก เพื่อเกษตรกรไทย
>
> Bridging global agricultural knowledge into Thai, for Thai farmers.

แพลตฟอร์มความรู้เกษตรแบบเปิด (open-source) ที่ช่วยให้เกษตรกรไทย นักเรียน นักศึกษา และผู้ที่สนใจปลูกพืช เข้าถึงความรู้เกษตรจากแหล่งที่เชื่อถือได้ทั้งในไทยและทั่วโลก แปล สรุป และปรับให้เข้ากับบริบทไทย

## หลักการ (Non-Negotiables)

1. **เปิดและฟรี** — เนื้อหาเข้าถึงได้ฟรีสำหรับทุกคน
2. **ตรวจสอบแหล่งที่มาได้** — ทุก claim สำคัญต้องมี source
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

**Long-term vision: 500 entries** — เริ่มจาก 9 ชิ้นแรก (1 จากแต่ละหมวดพืช)

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

## โครงสร้างโปรเจกต์

```
kaset-atlas/
├── src/
│   ├── content/
│   │   ├── crops/          # crop profiles (MDX)
│   │   ├── categories/     # category metadata
│   │   └── sources/        # source registry
│   ├── components/         # Astro/React components
│   ├── layouts/            # page layouts
│   ├── pages/              # routes
│   └── styles/             # global CSS + design tokens
├── public/                 # static assets
├── docs/
│   ├── METHODOLOGY.md      # how content is researched
│   ├── SOURCE_POLICY.md    # source reliability rules
│   ├── SAFETY_POLICY.md    # what we don't publish
│   └── CONTRIBUTING.md     # how to contribute
└── README.md
```

## License

- **Code:** MIT License (see `LICENSE`)
- **Content:** Creative Commons Attribution 4.0 International (see `CONTENT_LICENSE`)

## Contributing

เปิดรับทุกการช่วยเหลือ — แก้คำผิด, เพิ่ม source, แปลเนื้อหา, รีวิวข้อมูล

อ่าน `docs/CONTRIBUTING.md` ก่อน และจำกฎข้อสำคัญ:

> **No source, no merge.**

## Maintainer

[Prem Pawee](https://prempawee.com) — Solo maintainer, open to collaborators.
