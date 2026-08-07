# PES — ระบบประเมินบุคลากร (ฉบับเฉลย/ต้นแบบสำหรับซ้อมแข่ง)

ต้นแบบสำหรับ **การแข่งขันทักษะ รายการที่ 57 (ปวช.)** — เน้นโค้ดสั้น pattern ซ้ำ ให้เด็กจำและทำเสร็จใน ~5 ชม.
Stack: **Express + Knex + MySQL** (backend) และ **Nuxt 3 + Vuetify (SPA)** (frontend) ตาม Template ที่กรรมการแจก

> แผนวิเคราะห์โจทย์และกลยุทธ์เก็บคะแนนอยู่ที่ [`../PES/IMPLEMENTATION_PLAN.md`](../PES/IMPLEMENTATION_PLAN.md)

## วิธีรัน

ทุกอย่าง (db + phpMyAdmin + backend + frontend) รันผ่าน Docker ตัวเดียว:

```bash
docker compose up -d --build
#    Frontend:  http://localhost:3000
#    API:       http://localhost:7000   (เอกสาร API: http://localhost:7000/api)
#    phpMyAdmin: http://localhost:8081   (root / rootpassword)
```

> ถ้าเคยรัน docker ของโฟลเดอร์ PES เดิมค้างอยู่ ให้ `docker compose down` ในโฟลเดอร์นั้นก่อน
> (พอร์ต 7000/3000 จะได้ไม่ชนกัน) — ต้นฉบับนี้ตั้ง phpMyAdmin เป็นพอร์ต 8081 ไว้เผื่อชน 8080

แก้โค้ดแล้วต้อง build ใหม่ (ไม่มี live-reload ข้าม container):
```bash
docker compose up -d --build api        # แก้ backend
docker compose up -d --build frontend   # แก้ frontend
```

หรือจะรัน backend/frontend นอก Docker แบบเดิม (มี live-reload) ก็ยังได้ — แค่ `docker compose up -d db phpmyadmin` แล้ว `cd backend && npm run dev` / `cd frontend && npm run dev` ตามปกติ (`.env` เดิมมี `DB_HOST=127.0.0.1` รองรับกรณีนี้อยู่แล้ว).

## บัญชีทดสอบ (รหัสผ่านทุกคน = `123456`)

| อีเมล | บทบาท | ใช้ทำอะไร |
|---|---|---|
| admin@pes.ac.th | งานบุคลากร (admin) | หัวข้อ/ตัวชี้วัด, ผู้ใช้, มอบหมายกรรมการ, สถิติ, สำรอง/กู้คืน |
| eval1@pes.ac.th / eval2@pes.ac.th | กรรมการ (evaluator) | ให้คะแนน + ลายเซ็น + ส่งผล |
| teacher1@pes.ac.th | ผู้รับการประเมิน (evaluatee) | กรอกข้อมูล/แนบไฟล์/ประเมินตนเอง/ส่งออก PDF |

(มีครูทดสอบ `t01@pes.ac.th`–`t30@pes.ac.th` อีก 30 คนไว้สาธิต Pagination/Search)

## โครงสร้างโค้ด (หัวใจ = "pattern เดียวใช้ซ้ำ")

```
backend/
  db.js                    เชื่อม MySQL ด้วย Knex (ที่เดียว)
  app.js                   รวม route ทั้งหมด
  middlewares/
    auth.js                ตรวจ JWT + จำกัดบทบาท (RBAC)  → auth('admin')
    upload.js              multer: จำกัดชนิด/ขนาดไฟล์ (โจทย์พิเศษ 8.3)
    error.js               จัดการ error รวมศูนย์
  utils/
    crud.js                *** โรงงาน CRUD 1 ตาราง — เขียนครั้งเดียว ใช้ทุก resource ***
    mountCrud.js           สร้าง router มาตรฐานจาก crud()
  controllers/             เฉพาะ logic พิเศษ (auth, users, evidences, reviews, report, backup)
  routes/                  ผูก path → controller

frontend/
  composables/
    useApi.js              *** axios instance เดียว: แนบ token + ดัก error → snackbar ***
    useAuth.js             login/logout (เก็บใน localStorage)
    useSnackbar.js         แจ้งเตือนรวมศูนย์
  components/
    CrudTable.vue          *** ตารางใช้ซ้ำ: pagination+search+sort+hover+ฟอร์มเพิ่ม/แก้/ลบ ***
  layouts/dashboard.vue    เมนูตามบทบาท
  pages/                   login, register, admin/*, me/*, eval/*
```

**แนวคิดโค้ดสั้น:** ตารางฝั่ง admin ทุกหน้า (หัวข้อ/ตัวชี้วัด/ผู้ใช้/ช่วงเวลา/มอบหมาย) ใช้ `<CrudTable>` ตัวเดียว
เปลี่ยนแค่ `endpoint`, `headers`, `fields` — ส่วน backend ก็ใช้ `crud({table,...})` ตัวเดียวเช่นกัน

## แผนที่คะแนน → โค้ด (ดูเต็มใน IMPLEMENTATION_PLAN.md)

| เกณฑ์ | ทำที่ไหน |
|---|---|
| 6.1–6.10 Backend API | `controllers/*`, `utils/crud.js`, `middlewares/auth.js`, `apidoc.json` (คำอธิบาย+parameter) |
| 5.1 งานบุคลากร | `pages/admin/*` |
| 5.1.1-5.1.4 หัวข้อ/ตัวชี้วัดผูกกับรอบประเมิน | `topics.period_id` FK (schema.sql) — `admin/setup.vue` มีตัวเลือกรอบด้านบนแท็บ "หัวข้อ/ตัวชี้วัด" คนละรอบ ตั้งหัวข้อของตัวเองได้ ไม่ปนกัน (ทดสอบ isolation แล้ว) |
| 5.1.3 หลักฐานที่ใช้แนบ (แม่แบบจาก HR) | `admin/setup.vue` (อัปโหลด PDF/รูปภาพ หรือใส่ลิงก์ URL ต่อตัวชี้วัด) → `controllers/indicatorTemplate.controller.js` → แสดงให้ผู้รับการประเมินเห็นในหน้ากรอกแบบประเมิน |
| หลายรอบประเมินเปิดพร้อมกันได้ | `periods.is_active` เปิดได้หลายรอบพร้อมกัน (เช่น ประเมินการสอน + ประเมิน PA คนละหัวข้อ) — `pages/me/index.vue` และ `pages/me/report.vue` เป็นหน้ารายการเลือกรอบก่อน แล้วกดเข้าไปกรอก/ดูรายงานทีละรอบที่ `me/period/[id].vue` และ `me/report/[id].vue`; `admin/tracking.vue` มีตัวเลือกรอบเช่นกัน; `eval/index.vue` โชว์คอลัมน์รอบให้กรรมการแยกงานที่ทับซ้อนกันออกจากกัน |
| 5.2.2 แก้ข้อมูลส่วนตัว | `pages/me/profile.vue` → `PUT /api/users/me` (แก้ได้เฉพาะชื่อ/อีเมล/รหัสผ่านของตนเอง) |
| 5.2 ผู้รับการประเมิน | `pages/me/period/[id].vue` (กรอก/แนบไฟล์/ประเมินตนเอง/ความคืบหน้า/ดูความเห็น) + `me/report/[id].vue` |
| 5.2.7 ส่งออกไฟล์ PDF จริง | `me/report/[id].vue`: `html2canvas` capture รายงาน → `jsPDF` ประกอบเป็นไฟล์ (รองรับหลายหน้า) + ใส่รหัสผ่านล็อกไฟล์จริงด้วย `jsPDF({encryption})` แล้วดาวน์โหลดผ่าน `pdf.save()` — ไม่ใช่ window.print() อีกต่อไป |
| 5.3 กรรมการ | `pages/eval/[id].vue` (ให้คะแนน+ลายเซ็น canvas+ส่งผล) |
| 7.5 ทดสอบฟังก์ชันคำนวณ | `backend/test/calc.test.js` (`npm test`) |
| 8.1 Pagination | `v-data-table-server` + `crud.list` (LIMIT/OFFSET) |
| 8.2 Validate/กัน SQLi/XSS | `express-validator` + Knex parameterized query |
| 8.3 Upload หลายไฟล์+progress | `me/index.vue` (`onUploadProgress`) + `middlewares/upload.js` |
| 8.4 Backup/Restore | `controllers/backup.controller.js` + `pages/admin/index.vue` |
| 8.5 แผนภูมิ + PDF ตั้งรหัสผ่าน | `admin/index.vue` (SVG) + `me/report/[id].vue` (`jsPDF({encryption})` ล็อกรหัสผ่านจริงในไฟล์ PDF) |
| 8.6 Global search/debounce/loading/hover/แจ้ง error | `CrudTable.vue` + `useApi.js` interceptor |

## ทดสอบ Backend เร็ว ๆ

```bash
cd backend && npm test           # unit test ฟังก์ชันคำนวณคะแนน
# หรือยิง API ด้วย Thunder Client / curl:
curl -X POST http://localhost:7000/api/auth/login -H "Content-Type: application/json" \
  -d '{"email":"admin@pes.ac.th","password":"123456"}'
```

## หมายเหตุสำหรับสภาพแวดล้อมแข่งจริง
- ใช้ library ตรงกับ Template PES ที่กรรมการแจกเป็นหลัก (ดูตารางเทียบด้านล่าง) — ยกเว้น **jsPDF + html2canvas** (ส่งออก PDF จริง 5.2.7) ที่ตั้งใจเพิ่มเข้ามา เพราะเกณฑ์ไม่ได้ระบุ library บังคับ และ template เดิมไม่มีตัวสร้างไฟล์ PDF ให้เลย — **ถ้าห้องแข่งจริงไม่มีอินเทอร์เน็ต ต้องเช็คว่ามี 2 package นี้ใน cache/registry ภายในก่อน ไม่งั้นใช้ทางเลือกสำรอง `window.print()` (ผ่าน `@media print`) แทนได้** เพราะ scoring แค่ต้องมี PDF + รหัสผ่านตั้งไว้ก่อน export
- Frontend เลือกใช้แค่ Vuetify + axios (ตัด tailwindcss/daisyui/pinia ที่ template แถมมา) — เป็นการ "ใช้น้อยลง" ไม่ใช่เพิ่มใหม่ จึงปลอดภัยแม้ npm offline
- ตั้ง Nuxt เป็น `ssr: false` เพื่อความง่าย (ไม่ต้องกังวล hydration/localStorage) — ถ้าโจทย์บังคับ SSR ค่อยปรับ

### เทียบ library กับที่ระบุใน PDF (ข้อ 3.4.2.9 / 3.4.2.10) และ Template PES จริง
| ที่ระบุ | Backend | Frontend |
|---|---|---|
| **ใช้ตรงตาม template** | express, cors, dotenv, jsonwebtoken, express-validator, multer, **bcrypt**, knex, mysql2, morgan | nuxt, vue, vuetify, vite-plugin-vuetify, @mdi/font, axios, sass |
| **template มีแต่เราไม่ใช้** (ตัดเพื่อโค้ดสั้น) | express-fileupload (ใช้ multer แทน), swagger (ใช้ apidoc.json ย่อแทน) | pinia (ใช้ composable+localStorage แทน), tailwindcss, daisyui, vee-validate, yup, jwt-decode |

> knex / mysql2 / bcrypt ไม่อยู่ในลิสต์สั้นของ PDF แต่ **มีติดตั้งใน Template PES จริง** (ตรวจจาก backend/package.json ของ PES) จึงใช้ได้แน่นอน
- ระดับชาติ: กติกาเปลี่ยนเป็น **Responsive** (ไม่ต้องทำ Mobile App แยก) — โครงนี้ทำ responsive ด้วย Vuetify ไว้แล้ว
  ทดสอบที่จอ 375px: เมนูยุบเป็น hamburger, ตารางเลื่อนในกรอบตัวเอง, ไม่มี horizontal overflow (ผ่านเกณฑ์ 7.8)
