# ผังไฟล์ทั้งหมดของ pes-app (พร้อมหน้าที่ของแต่ละไฟล์)

> ไม่รวม `node_modules/`, `.nuxt/`, `package-lock.json` (ไฟล์ล็อกเวอร์ชัน ไม่ต้องอ่าน)
> ดูรายละเอียดเชิงลึกเพิ่มที่ [STRUCTURE.md](STRUCTURE.md), [apidoc.md](apidoc.md), [frontend.md](frontend.md)

```
pes-app/
├── README.md                          → คำแนะนำเริ่มต้นโปรเจกต์ (วิธีติดตั้ง/รัน)
├── STRUCTURE.md                       → เอกสารอธิบายโครงสร้างระบบทั้งหมด + data flow
├── apidoc.md                          → เอกสาร API แบบเต็ม มีตัวอย่าง request/response ทุก endpoint
├── frontend.md                        → เอกสารอธิบาย element/attribute ที่ใช้จริงในหน้าเว็บ (v-btn, v-card ฯลฯ)
├── docker-compose.yml                 → นิยาม 4 service (db, api, frontend, phpmyadmin) รันพร้อมกันด้วยคำสั่งเดียว
├── schema.sql                         → คำสั่งสร้างตารางฐานข้อมูลเริ่มต้น (8 ตาราง) + seed ข้อมูลทดสอบ
│
├── .claude/
│   └── launch.json                    → ตั้งค่า dev server ให้ preview ในเครื่องมือ Claude Code
│
├── backend/                           → Node.js + Express + Knex (เซิร์ฟเวอร์ API)
│   ├── server.js                      → จุดสตาร์ท เปิดเซิร์ฟเวอร์ที่ port 7000
│   ├── app.js                         → ประกอบร่าง Express: ต่อ middleware ทุกตัว + ผูกทุก route เข้าด้วยกัน
│   ├── db.js                          → ตัวเชื่อมฐานข้อมูล MySQL ผ่าน knex (import ใช้ในทุก controller)
│   ├── apidoc.json                    → เอกสาร API แบบย่อ (เปิดดูสดที่ /api ตอนรันจริง)
│   ├── package.json                   → รายชื่อ library ที่ใช้ + คำสั่ง start/dev
│   ├── Dockerfile                     → สูตรสร้าง container ของ backend
│   ├── .dockerignore                  → ไฟล์/โฟลเดอร์ที่ไม่คัดลอกเข้า container ตอน build (เช่น node_modules)
│   ├── .env                           → ค่าลับ/ตั้งค่า (รหัสเชื่อม DB, JWT secret) — ไม่ขึ้น git
│   │
│   ├── controllers/                   → สมองจริง: อ่าน/เขียนฐานข้อมูล คำนวณ ตรวจเงื่อนไข คืนผล
│   │   ├── auth.controller.js         → เข้าสู่ระบบ (ตรวจรหัสผ่าน+ออก JWT), สมัครสมาชิก
│   │   ├── users.controller.js        → CRUD ผู้ใช้ (เฉพาะ admin), แก้ข้อมูลตนเอง, เปลี่ยนรหัสผ่าน (ทุก role)
│   │   ├── assignments.controller.js  → มอบหมายกรรมการให้ผู้รับการประเมิน, ปลดล็อกใบประเมินที่ล็อกแล้ว
│   │   ├── evidences.controller.js    → ผู้รับการประเมินกรอกแบบประเมินตนเอง + แนบไฟล์หลักฐาน
│   │   ├── reviews.controller.js      → กรรมการให้คะแนน+เขียน feedback+ส่งผล, ผู้รับการประเมินดู feedback
│   │   ├── tracking.controller.js     → สรุปสถานะความคืบหน้า (ใครยังไม่ประเมิน/ยังไม่ให้คะแนน)
│   │   ├── report.controller.js       → คำนวณคะแนนเฉลี่ยถ่วงน้ำหนัก, ข้อมูลสถิติสำหรับกราฟ dashboard
│   │   ├── backup.controller.js       → สำรอง/กู้คืน/ลบไฟล์ snapshot ฐานข้อมูล
│   │   └── indicatorTemplate.controller.js → อัปโหลด/ลบไฟล์แม่แบบที่แนบไปกับตัวชี้วัดแต่ละข้อ
│   │
│   ├── routes/                        → "URL ไหนเรียกฟังก์ชันไหน" + ใครมีสิทธิ์เข้าถึง
│   │   ├── auth.routes.js             → /api/auth/*        (login, register)
│   │   ├── users.routes.js            → /api/users/*        (จัดการผู้ใช้, /me, /me/password)
│   │   ├── assignments.routes.js      → /api/assignments/*  (มอบหมายกรรมการ, unlock)
│   │   ├── evidences.routes.js        → /api/evidences/*    (กรอกแบบประเมินตนเอง+ไฟล์แนบ)
│   │   ├── reviews.routes.js          → /api/reviews/*       (กรรมการให้คะแนน+ส่งผล)
│   │   ├── tracking.routes.js         → /api/tracking/*      (ติดตามสถานะ)
│   │   ├── report.routes.js           → /api/stats, /api/summary/:id (สถิติ, รายงานรายบุคคล)
│   │   ├── backup.routes.js           → /api/backup*, /api/restore/* (สำรอง/กู้คืนข้อมูล)
│   │   └── indicatorTemplate.routes.js → /api/indicators/:id/template (ไฟล์แม่แบบ)
│   │   (หมายเหตุ: topics/indicators/periods ไม่มีไฟล์ route แยก ใช้ mountCrud() ต่อตรงใน app.js)
│   │
│   ├── middlewares/                   → ด่านตรวจก่อนถึง controller (ทำงานทุก/บาง request)
│   │   ├── auth.js                    → ตรวจ JWT + จำกัดบทบาท เช่น auth("admin") ต้องเป็น admin เท่านั้น
│   │   ├── sanitize.js                → ตัดแท็ก HTML/script ออกจาก body กัน stored XSS (ทำงานทุก request)
│   │   ├── upload.js                  → ตั้งค่ารับไฟล์ด้วย Multer (จำกัดชนิด/ขนาด, รองรับชื่อไฟล์ไทย)
│   │   └── error.js                   → จับ error รวมศูนย์จุดเดียว แปลงเป็น JSON + รหัส HTTP ที่ถูกต้อง
│   │
│   ├── utils/                         → เครื่องมือใช้ซ้ำ ไม่ผูกกับ route ไหนโดยเฉพาะ
│   │   ├── crud.js                    → โรงงานสร้างฟังก์ชัน CRUD (list/get/create/update/remove) ให้ 1 ตาราง
│   │   ├── mountCrud.js               → ห่อ crud() ให้กลายเป็น router พร้อมกำหนดสิทธิ์ read/write
│   │   ├── activePeriod.js            → หารอบประเมินที่ควรใช้เมื่อ request ไม่ได้ระบุ period_id มา
│   │   └── assertPeriodOpen.js        → เช็คว่ารอบยังไม่ปิด ก่อนยอมให้บันทึก/ให้คะแนน
│   │
│   ├── backups/                       → (ว่าง) พื้นที่เก็บไฟล์ backup ที่ backup.controller.js สร้างตอน runtime
│   └── uploads/                       → ไฟล์ที่ผู้ใช้อัปโหลดจริง (หลักฐาน/ลายเซ็น) — สร้าง/โตขึ้นตอนใช้งาน
│
└── frontend/                          → Nuxt 3 + Vue 3 + Vuetify 3 (หน้าเว็บ)
    ├── app.vue                        → ไฟล์รากครอบทุกหน้า + วาง snackbar แจ้งเตือนกลางไว้ที่นี่
    ├── nuxt.config.ts                 → ตั้งค่า Nuxt (โหลดปลั๊กอิน Vuetify, กำหนด URL ของ backend)
    ├── package.json                   → รายชื่อ library ที่ใช้ + คำสั่ง dev/build
    ├── Dockerfile                     → สูตรสร้าง container ของ frontend
    ├── .dockerignore                  → ไฟล์/โฟลเดอร์ที่ไม่คัดลอกเข้า container ตอน build
    │
    ├── components/                    → ชิ้นส่วน UI ที่หลายหน้าหยิบไปใช้ซ้ำ
    │   ├── CrudTable.vue               → ตาราง CRUD สำเร็จรูป (list+add+edit+delete) ใช้ซ้ำได้ทุกหน้าที่ต้องจัดการข้อมูล
    │   └── EvaluationReport.vue        → การ์ดสรุปผลคะแนนประเมิน ใช้ทั้งฝั่ง admin ดูรายงาน และฝั่งผู้รับการประเมินดูผลตนเอง
    │
    ├── composables/                   → ฟังก์ชัน logic ใช้ซ้ำได้ทุกหน้า (Nuxt auto-import ให้อัตโนมัติ)
    │   ├── useApi.js                   → ตัวเรียก HTTP กลาง แนบ JWT token ให้อัตโนมัติ + ดักจับ error
    │   ├── useAuth.js                  → จัดการสถานะผู้ใช้ที่ login อยู่ (อ่าน/เขียน localStorage + state กลาง)
    │   └── useSnackbar.js              → สถานะข้อความแจ้งเตือนกลาง (ให้ app.vue เอาไปแสดงเป็น v-snackbar)
    │
    ├── middleware/
    │   └── auth.global.js              → ทำงานก่อนเข้าทุกหน้า เช็คว่า login แล้วหรือยัง ยังไม่ login เด้งไป /login
    │
    ├── plugins/                       → โค้ดที่รันครั้งเดียวตอนแอปเริ่มทำงาน
    │   ├── errorHandler.js             → ดักจับ error จาก API ทั่วทั้งแอป แล้วเด้ง snackbar แจ้งผู้ใช้อัตโนมัติ
    │   └── vuetify.js                  → ติดตั้ง Vuetify (ชุด UI component) ให้ Nuxt ใช้งานได้ทุกหน้า
    │
    ├── layouts/                       → โครงหน้าที่ครอบเนื้อหาแต่ละหน้าอีกที
    │   ├── dashboard.vue               → โครงหน้าที่มีเมนู/แถบด้านข้าง (ใช้กับหน้าที่ต้อง login แล้วทุกหน้า)
    │   └── default.vue                 → โครงหน้าเปล่า ไม่มีเมนู (ใช้กับหน้า login, register, redirect)
    │
    └── pages/                         → แต่ละไฟล์ = 1 หน้า/1 URL (Nuxt สร้าง route ให้อัตโนมัติจากชื่อไฟล์)
        ├── index.vue                   → หน้าแรกสุด (/) เช็ค token แล้วเด้งไปหน้าแรกตาม role อัตโนมัติ
        ├── login.vue                   → หน้าเข้าสู่ระบบ (กรอก email/password → รับ JWT)
        ├── register.vue                → หน้าสมัครสมาชิก (สมัครได้เฉพาะบทบาทผู้รับการประเมิน)
        ├── account.vue                 → โปรไฟล์ตนเอง (แก้ชื่อ) + เปลี่ยนรหัสผ่าน — ใช้ร่วมกันทุก role
        │
        ├── admin/                      → หน้าเฉพาะบทบาทงานบุคคล (admin)
        │   ├── index.vue                → dashboard กราฟสรุปคะแนนเฉลี่ยรายหัวข้อ/รายรอบ
        │   ├── setup.vue                → ตั้งค่าระบบ: จัดการ topics/indicators/periods (ใช้ CrudTable)
        │   ├── users.vue                → จัดการผู้ใช้ทั้งหมดในระบบ (ใช้ CrudTable)
        │   ├── tracking.vue             → ติดตามสถานะภาพรวม (ใครยังไม่ประเมิน/ยังไม่ให้คะแนน)
        │   └── report/
        │       └── [id].vue             → รายงานผลคะแนนรายบุคคล มุมมอง admin (id = user id)
        │
        ├── eval/                       → หน้าเฉพาะบทบาทกรรมการ (evaluator)
        │   ├── index.vue                → รายชื่อผู้รับการประเมินที่ตนเองต้องให้คะแนน
        │   └── [id].vue                 → หน้าให้คะแนนผู้รับการประเมินรายคน (id = assignment/user id)
        │
        └── me/                         → หน้าเฉพาะบทบาทผู้รับการประเมิน (evaluatee)
            ├── index.vue                → หน้าแรกของผู้รับการประเมิน แสดงรายการรอบประเมินที่มีสิทธิ์เข้า
            ├── period/
            │   └── [id].vue             → กรอกแบบประเมินตนเอง + แนบหลักฐานในรอบนั้น (id = period id)
            └── report/
                ├── index.vue            → รายการรอบที่มีผลคะแนนออกแล้ว ให้เลือกดู
                └── [id].vue             → ดูผลคะแนน/feedback ของตนเองในรอบนั้น (id = period id)
```
