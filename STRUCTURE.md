# โครงสร้างระบบประเมินบุคลากร (PES) — เอกสารประกอบการสอน

เอกสารนี้อธิบายว่าเว็บทั้งระบบประกอบด้วยอะไรบ้าง แต่ละส่วนทำหน้าที่อะไร และข้อมูลวิ่งจากจุดหนึ่งไปอีกจุดหนึ่งอย่างไร
เขียนให้ผู้เริ่มต้น (ปวช.) อ่านตามได้ทีละชั้น

---

## 1. ภาพรวม: เว็บนี้มี 3 กล่องคุยกัน

```
   ┌─────────────┐        ┌─────────────┐        ┌─────────────┐
   │  FRONTEND   │  HTTP  │   BACKEND   │  SQL   │  DATABASE   │
   │  (หน้าเว็บ)  │ ─────▶ │ (เซิร์ฟเวอร์) │ ─────▶ │ (ฐานข้อมูล)  │
   │   Nuxt/Vue  │ ◀───── │   Express   │ ◀───── │   MySQL     │
   │  port 3000  │  JSON  │  port 7000  │  แถว   │  port 3306  │
   └─────────────┘        └─────────────┘        └─────────────┘
        │                       │                       │
   สิ่งที่ผู้ใช้เห็น         ตัวกลาง+กฎเกณฑ์          ที่เก็บข้อมูลถาวร
   กดปุ่ม กรอกฟอร์ม        ตรวจสิทธิ์ คำนวณ          ตาราง 8 ตาราง
```

**หลักที่ต้องจำ:** หน้าเว็บ (frontend) **ไม่เคย** คุยกับฐานข้อมูลตรงๆ ต้องผ่าน backend เสมอ
เพราะ backend เป็นด่านตรวจสอบสิทธิ์ + กฎเกณฑ์ (เช่น "หมดเขตแล้วห้ามแก้", "ไม่ใช่ admin ห้ามลบ")

ทั้ง 3 กล่องรันด้วย **Docker** พร้อมกันด้วยคำสั่งเดียว: `docker compose up -d`
(มีกล่องที่ 4 คือ phpMyAdmin ที่ port 8081 ไว้เปิดดูฐานข้อมูลด้วยตา — ไม่เกี่ยวกับการทำงานของแอป)

---

## 2. ผู้ใช้ 3 บทบาท (Role)

ทั้งระบบหมุนรอบ 3 บทบาทนี้ เห็นเมนู/ทำอะไรได้ต่างกัน:

| บทบาท (role) | ภาษาไทย | ทำอะไรได้ |
|---|---|---|
| `admin` | งานบุคลากร | ตั้งค่าทุกอย่าง: รอบประเมิน หัวข้อ ตัวชี้วัด มอบหมายกรรมการ ดูรายงาน สำรองข้อมูล |
| `evaluator` | กรรมการ | ให้คะแนนผู้รับการประเมินที่ถูกมอบหมาย + เซ็นชื่อส่งผล |
| `evaluatee` | ผู้รับการประเมิน | กรอกข้อมูล/หลักฐานของตนเอง ประเมินตนเอง ดูผล/ส่งออก PDF |

---

## 3. ฐานข้อมูล (Database) — 8 ตาราง

ไฟล์ทั้งหมดอยู่ที่ [`schema.sql`](schema.sql) (สร้างตาราง + ใส่ข้อมูลตัวอย่างในไฟล์เดียว)

```
users ──────┐ (1 คนเป็นได้หลายอย่าง)
            ├──< assignments >── evaluatee ─┐
periods ─┬──┤        │                      │
         │  │        └──< reviews            │
         │  └──< evidences ──< evidence_files│
         └──< topics ──< indicators ────────┘
```

**คำอธิบายทีละตาราง:**

| ตาราง | เก็บอะไร | ผูกกับใคร (FK) |
|---|---|---|
| `users` | ผู้ใช้ทุกคน (อีเมล, รหัสผ่านที่เข้ารหัส, ชื่อ, บทบาท) | — |
| `periods` | รอบการประเมิน (ชื่อรอบ, วันเริ่ม-สิ้นสุด, เปิด/ปิด) | — |
| `topics` | หัวข้อการประเมิน | `period_id` → periods |
| `indicators` | ตัวชี้วัดในแต่ละหัวข้อ (น้ำหนัก, ชนิดคะแนน, ไฟล์แม่แบบ) | `topic_id` → topics |
| `assignments` | ใบมอบหมาย = กรรมการ 1 คน ประเมินผู้รับ 1 คน ในรอบ 1 รอบ | `period_id`, `evaluator_id`, `evaluatee_id` |
| `evidences` | ข้อมูล+คะแนนตนเอง ที่ผู้รับการประเมินกรอก (1 แถว/1 ตัวชี้วัด) | `evaluatee_id`, `indicator_id`, `period_id` |
| `evidence_files` | ไฟล์หลักฐานแนบ (แนบได้หลายไฟล์ต่อ 1 ตัวชี้วัด) | `evidence_id` → evidences |
| `reviews` | คะแนนที่กรรมการให้ (1 แถว/1 ตัวชี้วัด/1 ใบประเมิน) | `assignment_id`, `indicator_id` |

**จุดสำคัญที่ควรสอน:**
- **ความสัมพันธ์แบบลูกโซ่:** `periods → topics → indicators` — ลบรอบ หัวข้อกับตัวชี้วัดหายตามหมด (`ON DELETE CASCADE`)
- **ชนิดตัวชี้วัด (`type`) มี 2 แบบ:** `score_1_4` (ให้คะแนน 1-4 มีน้ำหนัก) กับ `yes_no` (มี/ไม่มี ไม่คิดคะแนน)
- **`UNIQUE KEY`** กันข้อมูลซ้ำ เช่น กรรมการคนเดิมให้คะแนนตัวชี้วัดเดิมซ้ำไม่ได้ (จะเป็นการแก้ของเดิมแทน)

---

## 4. Backend (เซิร์ฟเวอร์) — โฟลเดอร์ `backend/`

ใช้ **Node.js + Express** (เว็บเซิร์ฟเวอร์) + **Knex** (ตัวช่วยเขียน SQL) + **MySQL**

### 4.1 ผังโฟลเดอร์ทั้งหมดของ backend

จัดกลุ่มโค้ดตามหน้าที่ (แยก route / logic / ด่านตรวจ / เครื่องมือ ออกจากกัน) — ทั้งหมด 4 โฟลเดอร์หลัก + ไฟล์ตั้งค่า:

```
backend/
├── server.js       → จุดสตาร์ท เปิดเซิร์ฟเวอร์ port 7000
├── app.js          → ประกอบร่าง Express: ต่อ middleware + ผูกทุก route  [ดูข้อ 4.2]
├── db.js           → ตัวเชื่อมฐานข้อมูล MySQL (import ไปใช้ทุก controller)
│
├── routes/         → "URL ไหน ไปฟังก์ชันไหน" + ใครมีสิทธิ์เข้า           [ดูข้อ 4.4]
├── controllers/    → สมองจริง: อ่าน/เขียน DB คำนวณ คืนผล                [ดูข้อ 4.5]
├── middlewares/    → ด่านตรวจกลางทาง (token, กรอง XSS, รับไฟล์, จับ error) [ดูข้อ 4.6]
├── utils/          → เครื่องมือใช้ซ้ำ (โรงงาน CRUD, ตัวช่วยเรื่องรอบ)      [ดูข้อ 4.7]
│
├── apidoc.json     → เอกสาร API (เปิดดูที่ /api)
├── .env            → ค่าลับ/ตั้งค่า (รหัส DB, JWT secret) — ไม่ขึ้น git
├── package.json    → รายชื่อ library ที่ใช้ + คำสั่ง (start/dev/test)
├── Dockerfile      → สูตรสร้าง container ของ backend
├── test/           → ชุดทดสอบ (เช่น ทดสอบสูตรคำนวณคะแนน)
├── uploads/        → ไฟล์ที่ผู้ใช้อัปโหลด (หลักฐาน, ลายเซ็น, แม่แบบ) — สร้างอัตโนมัติ
└── backups/        → ไฟล์สำรองข้อมูล (snapshot) — สร้างอัตโนมัติ
```

> **หลักที่ควรสอน:** การแยกโฟลเดอร์แบบนี้เรียกว่า "แยกตามหน้าที่" (separation of concerns)
> route ไม่คำนวณเอง / controller ไม่ตรวจสิทธิ์เอง — แต่ละส่วนทำงานเดียว ทำให้หาโค้ด/แก้บั๊กง่าย

### 4.2 ไฟล์เริ่มต้น (จุดที่โปรแกรมเริ่มทำงาน)

| ไฟล์ | หน้าที่ |
|---|---|
| [`server.js`](backend/server.js) | จุดสตาร์ท — เปิดเซิร์ฟเวอร์ที่ port 7000 |
| [`app.js`](backend/app.js) | ประกอบร่าง Express: ต่อ middleware + ผูกทุกเส้นทาง (route) |
| [`db.js`](backend/db.js) | ตัวเชื่อมฐานข้อมูล MySQL (import ไปใช้ทุก controller) |

### 4.3 โครงสร้าง 3 ชั้นของ backend (สำคัญที่สุด)

ทุก request วิ่งผ่าน 3 ชั้นนี้เสมอ:

```
  request เข้ามา
      │
      ▼
  ┌──────────────┐  routes/   → "URL ไหน ไปฟังก์ชันไหน" + ใครมีสิทธิ์เข้า
  │  ROUTE       │
  └──────┬───────┘
      │
      ▼
  ┌──────────────┐  middlewares/ → ด่านตรวจก่อนถึงปลายทาง (ตรวจ token, กรอง XSS)
  │  MIDDLEWARE  │
  └──────┬───────┘
      │
      ▼
  ┌──────────────┐  controllers/ → สมองจริง: อ่าน/เขียนฐานข้อมูล คำนวณ คืนผล
  │  CONTROLLER  │
  └──────────────┘
```

### 4.4 routes/ — แผนที่เส้นทาง ( URL → ฟังก์ชัน)

| ไฟล์ route | ดูแล URL | ตัวอย่าง |
|---|---|---|
| [`auth.routes.js`](backend/routes/auth.routes.js) | `/api/auth/*` | login, register |
| [`users.routes.js`](backend/routes/users.routes.js) | `/api/users/*` | จัดการผู้ใช้, เปลี่ยนรหัสผ่าน |
| [`evidences.routes.js`](backend/routes/evidences.routes.js) | `/api/evidences/*` | ผู้รับการประเมินกรอกข้อมูล+อัปโหลดไฟล์ |
| [`reviews.routes.js`](backend/routes/reviews.routes.js) | `/api/reviews/*` | กรรมการให้คะแนน+ส่งผล |
| [`assignments.routes.js`](backend/routes/assignments.routes.js) | `/api/assignments/*` | มอบหมายกรรมการ, ปลดล็อกใบประเมิน |
| [`tracking.routes.js`](backend/routes/tracking.routes.js) | `/api/tracking/*` | ติดตามสถานะการประเมิน |
| [`report.routes.js`](backend/routes/report.routes.js) | `/api/stats`, `/api/summary/:id` | สถิติ dashboard, รายงานรายบุคคล |
| [`backup.routes.js`](backend/routes/backup.routes.js) | `/api/backup*`, `/api/restore/*` | สำรอง/กู้คืนข้อมูล |
| [`indicatorTemplate.routes.js`](backend/routes/indicatorTemplate.routes.js) | `/api/indicators/:id/template` | อัปโหลดไฟล์แม่แบบ |

> **หมายเหตุ:** ตาราง `topics`, `indicators`, `periods` ไม่มีไฟล์ route แยก — ใช้ตัวสร้าง CRUD กลาง (ดูข้อ 4.7)

### 4.5 controllers/ — สมองของแต่ละงาน

ไฟล์ในนี้คือที่ที่ "ทำงานจริง" — อ่าน/เขียนฐานข้อมูล คำนวณ ตรวจเงื่อนไข
1 route จะเรียก 1 ฟังก์ชันใน controller (เช่น `auth.controller.js` มีฟังก์ชัน `login`, `register`)

| controller | รับผิดชอบ |
|---|---|
| [`auth.controller.js`](backend/controllers/auth.controller.js) | เข้าสู่ระบบ (ออก JWT), สมัครสมาชิก |
| [`users.controller.js`](backend/controllers/users.controller.js) | CRUD ผู้ใช้, แก้ข้อมูลตนเอง, เปลี่ยนรหัสผ่าน |
| [`evidences.controller.js`](backend/controllers/evidences.controller.js) | ผู้รับการประเมินกรอกข้อมูล+ประเมินตนเอง+ไฟล์ |
| [`reviews.controller.js`](backend/controllers/reviews.controller.js) | กรรมการให้คะแนน+ส่งผล, ผู้รับดู feedback |
| [`assignments.controller.js`](backend/controllers/assignments.controller.js) | มอบหมายกรรมการ, ปลดล็อกใบประเมิน |
| [`tracking.controller.js`](backend/controllers/tracking.controller.js) | สรุปสถานะกรรมการ/ผู้รับการประเมิน |
| [`report.controller.js`](backend/controllers/report.controller.js) | คำนวณคะแนนเฉลี่ยถ่วงน้ำหนัก, สถิติ dashboard |
| [`backup.controller.js`](backend/controllers/backup.controller.js) | สำรอง/กู้คืน/ลบ snapshot |
| [`indicatorTemplate.controller.js`](backend/controllers/indicatorTemplate.controller.js) | อัปโหลด/ลบไฟล์แม่แบบของตัวชี้วัด |

### 4.6 middlewares/ — ด่านกลางทาง

| ไฟล์ | หน้าที่ |
|---|---|
| [`auth.js`](backend/middlewares/auth.js) | ตรวจ JWT + จำกัดบทบาท เช่น `auth("admin")` = ต้องเป็น admin เท่านั้น |
| [`sanitize.js`](backend/middlewares/sanitize.js) | ตัดแท็ก HTML/script ออกจากข้อมูล กัน XSS (ทำงานทุก request) |
| [`upload.js`](backend/middlewares/upload.js) | ตั้งค่ารับไฟล์ (Multer) — จำกัดชนิด/ขนาด, รองรับชื่อไฟล์ภาษาไทย |
| [`error.js`](backend/middlewares/error.js) | จับ error รวมศูนย์ แปลงเป็นข้อความไทย + รหัส HTTP ที่ถูกต้อง |

### 4.7 utils/ — เครื่องมือใช้ซ้ำ

| ไฟล์ | หน้าที่ |
|---|---|
| [`crud.js`](backend/utils/crud.js) | **โรงงานสร้าง CRUD** — เขียนครั้งเดียว ใช้กับ topics/indicators/periods ได้หมด (list/get/create/update/delete) |
| [`mountCrud.js`](backend/utils/mountCrud.js) | สร้าง router มาตรฐานจาก crud() พร้อมกำหนดสิทธิ์ read/write |
| [`activePeriod.js`](backend/utils/activePeriod.js) | หารอบที่ควรใช้เมื่อไม่ได้ระบุ (ใช้รอบที่เปิดอยู่ก่อน) |
| [`assertPeriodOpen.js`](backend/utils/assertPeriodOpen.js) | เช็คว่ารอบยังไม่หมดเขต ก่อนยอมให้บันทึก/ให้คะแนน |

> **แนวคิด DRY ที่ควรสอน:** `crud.js` + `mountCrud.js` คือการ "เขียนครั้งเดียว ใช้ซ้ำ" — แทนที่จะเขียนโค้ด
> เพิ่ม/ลบ/แก้ ซ้ำๆ ให้ทุกตาราง เขียนสูตรกลางไว้ตัวเดียว ตารางไหนใช้ pattern เดียวกันก็เรียกใช้ได้เลย

---

## 5. Frontend (หน้าเว็บ) — โฟลเดอร์ `frontend/`

ใช้ **Nuxt 3 + Vue 3** (โครงหน้าเว็บ) + **Vuetify 3** (ชุด UI สำเร็จรูป) + **axios** (เรียก API)

### 5.1 ผังโฟลเดอร์ทั้งหมดของ frontend

Nuxt กำหนดว่าแต่ละโฟลเดอร์มีหน้าที่ตายตัว (วางไฟล์ผิดที่จะไม่ทำงาน) — ทั้งหมดมี 6 โฟลเดอร์ + 2 ไฟล์ตั้งค่า:

```
frontend/
├── pages/          → แต่ละไฟล์ = 1 หน้า/1 URL (Nuxt สร้าง route ให้อัตโนมัติ)  [ดูข้อ 5.2]
├── components/     → ชิ้นส่วน UI ที่หลายหน้าหยิบไปใช้ซ้ำ (ตาราง, การ์ดรายงาน)   [ดูข้อ 5.3]
├── composables/    → ฟังก์ชัน logic ใช้ซ้ำ (เรียก API, จัดการ login, แจ้งเตือน)  [ดูข้อ 5.3]
├── layouts/        → โครงหน้าที่ครอบทุกหน้า (มีเมนู / เปล่ากลางจอ)              [ดูข้อ 5.3]
├── middleware/     → ด่านตรวจ "ก่อนเข้าหน้า" (ไม่ล็อกอิน เด้งไป /login)          [ดูข้อ 5.3]
├── plugins/        → ตั้งค่าตอนแอปเริ่ม (โหลด Vuetify, ตัวจับ error)             [ดูข้อ 5.3]
├── app.vue         → ไฟล์ราก ครอบทุกอย่าง (วางกล่องแจ้งเตือน snackbar ไว้ที่นี่)
└── nuxt.config.ts  → ไฟล์ตั้งค่า Nuxt (โหลด Vuetify, กำหนด URL ของ backend)
```

> เทียบกับ backend: `pages/` ≈ routes+หน้าจอ, `composables/` ≈ utils, `middleware/` ≈ middlewares
> แนวคิดเดียวกัน แค่คนละฝั่ง

### 5.2 pages/ — แต่ละหน้า = แต่ละไฟล์ (Nuxt สร้าง URL ให้อัตโนมัติจากชื่อไฟล์)

```
pages/
├── index.vue              /            → หน้าแรก เด้งไปตามบทบาท
├── login.vue              /login       → เข้าสู่ระบบ
├── register.vue           /register    → สมัคร (ผู้รับการประเมิน)
├── account.vue            /account     → บัญชีผู้ใช้ (แก้ชื่อ, เปลี่ยนรหัสผ่าน) — ทุกบทบาท
│
├── admin/                 [ งานบุคลากร ]
│   ├── index.vue          /admin              → ภาพรวม/สถิติ + สำรองข้อมูล
│   ├── setup.vue          /admin/setup        → ตั้งรอบ/หัวข้อ/ตัวชี้วัด/มอบหมายกรรมการ (3 แท็บ)
│   ├── users.vue          /admin/users        → จัดการผู้ใช้ 3 บทบาท
│   ├── tracking.vue       /admin/tracking     → ติดตามสถานะการประเมิน
│   └── report/[id].vue    /admin/report/5     → รายงานรายบุคคล (:id = คนไหน)
│
├── eval/                  [ กรรมการ ]
│   ├── index.vue          /eval               → รายชื่อที่ต้องประเมิน
│   └── [id].vue           /eval/12            → หน้าให้คะแนน+เซ็นส่ง (:id = ใบไหน)
│
└── me/                    [ ผู้รับการประเมิน ]
    ├── index.vue          /me                 → แบบประเมินของฉัน (เลือกรอบ)
    ├── period/[id].vue    /me/period/2        → กรอกข้อมูล+ประเมินตนเอง (:id = รอบไหน)
    └── report/
        ├── index.vue      /me/report          → เลือกรอบดูรายงาน
        └── [id].vue       /me/report/2        → รายงานของฉัน + ส่งออก PDF
```

> `[id].vue` คือหน้าที่ URL มีตัวแปร เช่น `/eval/12` → ค่า `12` อ่านได้จาก `useRoute().params.id`

### 5.3 โฟลเดอร์ที่เหลือ (ส่วนที่ใช้ร่วมกันทุกหน้า)

**components/** — ชิ้นส่วน UI ใช้ซ้ำ

| ไฟล์ | หน้าที่ |
|---|---|
| [`CrudTable.vue`](frontend/components/CrudTable.vue) | ตารางเพิ่ม/แก้/ลบ + ค้นหา + แบ่งหน้า ใช้ซ้ำหลายหน้า (users, setup) |
| [`EvaluationReport.vue`](frontend/components/EvaluationReport.vue) | หน้าตารายงานผลประเมิน ใช้ทั้งฝั่ง admin และผู้รับการประเมิน |

**composables/** — ฟังก์ชัน logic ใช้ซ้ำ (คล้าย utils ของ backend)

| ไฟล์ | หน้าที่ |
|---|---|
| [`useApi.js`](frontend/composables/useApi.js) | ตัวเรียก API กลาง (แนบ token อัตโนมัติ + แจ้ง error) |
| [`useAuth.js`](frontend/composables/useAuth.js) | จัดการ login/logout + เก็บผู้ใช้ที่ล็อกอิน |
| [`useSnackbar.js`](frontend/composables/useSnackbar.js) | ข้อความแจ้งเตือนเด้งมุมจอ |

**layouts/** — โครงหน้าที่ครอบเนื้อหา

| ไฟล์ | หน้าที่ |
|---|---|
| [`dashboard.vue`](frontend/layouts/dashboard.vue) | โครงหน้ามีเมนูซ้าย (เมนูเปลี่ยนตามบทบาท) — ใช้กับหน้าหลังล็อกอิน |
| [`default.vue`](frontend/layouts/default.vue) | โครงหน้าเปล่ากลางจอ — ใช้กับ login/register |

**middleware/** — ด่านตรวจก่อนเข้าหน้า

| ไฟล์ | หน้าที่ |
|---|---|
| [`auth.global.js`](frontend/middleware/auth.global.js) | ทำงานก่อนเปิดทุกหน้า — ไม่มี token เด้งไป /login (`.global` = ใช้กับทุกหน้าอัตโนมัติ) |

**plugins/** — ตั้งค่าตอนแอปเริ่มทำงาน

| ไฟล์ | หน้าที่ |
|---|---|
| [`vuetify.js`](frontend/plugins/vuetify.js) | ลงทะเบียนชุด UI Vuetify ให้ทุกหน้าใช้ได้ |
| [`errorHandler.js`](frontend/plugins/errorHandler.js) | จับ error ฝั่งหน้าเว็บ ไม่ให้ขึ้นแดงรก Console |

> **composable กับ middleware ต่างกันตรงไหน:**
> - **composable** = ฟังก์ชันที่ "หน้าเรียกใช้เอง" เมื่ออยากได้ (เช่น อยากเรียก API ก็เรียก `useApi()`)
> - **middleware** = ด่านที่ Nuxt "เรียกให้อัตโนมัติ" ก่อนเข้าหน้า (หน้าไม่ต้องสั่งเอง)

---

## 6. เดินตามข้อมูล 1 รอบเต็ม (ตัวอย่าง: "เข้าสู่ระบบ")

ตัวอย่างนี้ดีที่สุดสำหรับสอนครั้งแรก เพราะแตะครบทุกชั้น:

```
1. ผู้ใช้พิมพ์อีเมล+รหัสผ่าน กดปุ่ม           [ frontend/pages/login.vue ]
              │
2. เรียกฟังก์ชัน login()                      [ frontend/composables/useAuth.js ]
              │  axios ยิง POST /api/auth/login  { email, password }
              ▼
3. Express รับที่ route                        [ backend/routes/auth.routes.js ]
              │  ส่งต่อไปฟังก์ชัน login
              ▼
4. controller ทำงาน                            [ backend/controllers/auth.controller.js ]
              │  - หา user จากอีเมล            [ ถาม database ตาราง users ]
              │  - เทียบรหัสผ่านกับ hash (bcrypt)
              │  - สร้าง JWT (บัตรผ่าน)
              ▼
5. คืน JSON { accessToken, user } กลับไป frontend
              │
6. เก็บ token ลง localStorage                  [ useAuth.js ]
              │
7. เด้งไปหน้าแรกตามบทบาท                        [ pages/index.vue ]
```

หลังจากนี้ ทุกครั้งที่เรียก API ตัว `useApi.js` จะแนบ token ไปด้วยอัตโนมัติ
backend จึงรู้ว่า "คนนี้คือใคร บทบาทอะไร" โดยไม่ต้อง login ซ้ำ

> **ข้อดีของโปรเจกต์นี้สำหรับสอน:** ทุกฟังก์ชันในโค้ดมี comment บอก data flow กำกับไว้แล้ว
> (มาจากไหน → ทำอะไร → ไปไหน) ให้เด็กอ่าน comment แล้วไล่ตามโค้ดได้เลย

---

## 7. เทคโนโลยีที่ใช้ (สรุป)

| ชั้น | เทคโนโลยี | ทำหน้าที่ |
|---|---|---|
| ฐานข้อมูล | MySQL 8 | เก็บข้อมูลถาวรเป็นตาราง |
| Backend | Node.js + Express | เว็บเซิร์ฟเวอร์ รับ request คืน JSON |
| | Knex | เขียน SQL แบบ JavaScript (กัน SQL injection) |
| | JWT | บัตรผ่านยืนยันตัวตน |
| | bcrypt | เข้ารหัสรหัสผ่าน (เก็บแบบถอดกลับไม่ได้) |
| | Multer | จัดการไฟล์อัปโหลด |
| Frontend | Nuxt 3 + Vue 3 | โครงหน้าเว็บ + ระบบ reactive |
| | Vuetify 3 | ชุด UI สำเร็จรูป (ปุ่ม ตาราง ฟอร์ม) |
| | axios | เรียก API |
| | jsPDF + html2canvas | ส่งออกรายงานเป็น PDF |
| รวมทุกอย่าง | Docker Compose | รันทั้ง 4 กล่องพร้อมกันด้วยคำสั่งเดียว |

---

## 8. วิธีรันระบบ

```bash
# รันทั้งหมด (ครั้งแรกจะ build ให้เอง)
docker compose up -d --build

# เปิดเว็บ
#   หน้าเว็บผู้ใช้     → http://localhost:3000
#   API (เอกสาร)     → http://localhost:7000/api
#   phpMyAdmin ดู DB → http://localhost:8081

# บัญชีทดสอบ (รหัสผ่านทุกคน = 123456)
#   admin@pes.ac.th      → งานบุคลากร
#   eval1@pes.ac.th      → กรรมการ
#   teacher1@pes.ac.th   → ผู้รับการประเมิน

# หยุดทั้งหมด
docker compose down
```

**แก้โค้ดแล้วต้อง build ใหม่:**
```bash
docker compose up -d --build frontend   # แก้หน้าเว็บ
docker compose up -d --build api        # แก้เซิร์ฟเวอร์
```

---

## 9. ลำดับแนะนำสำหรับผู้เริ่มอ่านโค้ด

อ่านไล่ตามนี้จะเข้าใจเร็วที่สุด (ไล่ตามฟีเจอร์ "เข้าสู่ระบบ" ก่อน แล้วค่อยขยาย):

1. `schema.sql` — เข้าใจว่ามีข้อมูลอะไรบ้าง (ตาราง users ก่อน)
2. `backend/app.js` — เห็นภาพรวมว่ามีเส้นทางอะไรบ้าง
3. **ฟีเจอร์ login** ครบวงจร: `login.vue` → `useAuth.js` → `auth.routes.js` → `auth.controller.js`
4. `middlewares/auth.js` — เข้าใจว่า token ถูกตรวจยังไง
5. **ฟีเจอร์ CRUD** ครบวงจร: `admin/users.vue` → `CrudTable.vue` → `users.routes.js` → `users.controller.js`
6. จากนั้นฟีเจอร์อื่นจะเข้าใจเองเพราะใช้ pattern เดียวกันหมด
