# API Documentation — ระบบประเมินบุคลากร (PES)

เอกสารออกแบบ API ทั้งระบบตามหลัก **RESTful** — ใช้ HTTP method สื่อความหมาย (GET อ่าน / POST สร้าง / PUT แก้ / DELETE ลบ), จัด endpoint เป็น resource, สื่อสารด้วย JSON

---

## ข้อมูลทั่วไป

| หัวข้อ | รายละเอียด |
|---|---|
| Base URL | `http://localhost:7000` |
| รูปแบบข้อมูล | JSON (ยกเว้นอัปโหลดไฟล์ = `multipart/form-data`) |
| การยืนยันตัวตน | JWT — ส่ง header `Authorization: Bearer <accessToken>` (ได้จาก `/api/auth/login`) |
| เอกสารในระบบ | `GET /api` (คืน JSON), `GET /health` (เช็คสถานะเซิร์ฟเวอร์) |

### บทบาทผู้ใช้ (Role)

| role | ความหมาย |
|---|---|
| `admin` | งานบุคลากร — ตั้งค่าระบบ ดูรายงาน สำรองข้อมูล |
| `evaluator` | กรรมการ — ให้คะแนนผู้รับการประเมิน |
| `evaluatee` | ผู้รับการประเมิน — กรอกข้อมูล/หลักฐานของตนเอง |

### รูปแบบ Response มาตรฐาน

```jsonc
// สำเร็จ (คืนข้อมูลรายการเดียว)
{ "success": true, "data": { ... } }

// สำเร็จ (คืนหลายรายการ + แบ่งหน้า)
{ "success": true, "items": [ ... ], "total": 42, "page": 1, "itemsPerPage": 10 }

// ผิดพลาด
{ "success": false, "message": "ข้อความอธิบายภาษาไทย" }
```

### HTTP Status Codes

| Code | ความหมาย |
|---|---|
| 200 | สำเร็จ |
| 201 | สร้างข้อมูลใหม่สำเร็จ |
| 400 | ข้อมูลไม่ครบ / ไม่ผ่าน validate / รอบหมดเขต |
| 401 | ยังไม่ล็อกอิน หรือ token ไม่ถูกต้อง/หมดอายุ |
| 403 | ล็อกอินแล้วแต่บทบาทไม่มีสิทธิ์ |
| 404 | ไม่พบข้อมูล |
| 409 | ข้อมูลซ้ำ (เช่น อีเมลซ้ำ) |
| 500 | ข้อผิดพลาดที่ไม่คาดคิดในเซิร์ฟเวอร์ |

### ตัวอย่าง Error Response แต่ละแบบ

```jsonc
// 400 — ข้อมูลไม่ครบ
{ "success": false, "message": "กรอกอีเมลและรหัสผ่าน" }
// 401 — ยังไม่ล็อกอิน / token หมดอายุ
{ "success": false, "message": "โทเค็นไม่ถูกต้องหรือหมดอายุ" }
// 403 — บทบาทไม่มีสิทธิ์
{ "success": false, "message": "ไม่มีสิทธิ์เข้าถึง" }
// 404 — ไม่พบข้อมูล
{ "success": false, "message": "ไม่พบข้อมูล" }
// 409 — ข้อมูลซ้ำ
{ "success": false, "message": "ข้อมูลซ้ำ (เช่น อีเมลนี้มีอยู่แล้ว)" }
```

### พารามิเตอร์มาตรฐานสำหรับ list (แบ่งหน้า/ค้นหา/เรียง)

endpoint ที่คืนรายการรองรับ query string: `?page=1&itemsPerPage=10&search=คำค้น&sortBy=id&sortDesc=false`

---

## 1. Authentication — `/api/auth`

### POST `/api/auth/login` · public
เข้าสู่ระบบ ออก JWT
```jsonc
// → request body
{ "email": "admin@pes.ac.th", "password": "123456" }
// ← 200
{
  "success": true,
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": { "id": 1, "name": "อรวรรณ ศรีสมบูรณ์", "email": "admin@pes.ac.th", "role": "admin" }
}
// ← 401 (รหัสผิด)
{ "success": false, "message": "อีเมลหรือรหัสผ่านไม่ถูกต้อง" }
```

### POST `/api/auth/register` · public
สมัครสมาชิก (ได้บทบาท evaluatee เท่านั้น) — validate: ชื่อไม่ว่าง, อีเมลถูกรูปแบบ, รหัสผ่าน ≥ 6 ตัว
```jsonc
// → request body
{ "name_th": "วิชัย ตั้งใจเรียน", "email": "wichai@pes.ac.th", "password": "123456" }
// ← 201
{ "success": true, "data": { "id": 17, "name_th": "วิชัย ตั้งใจเรียน", "email": "wichai@pes.ac.th", "role": "evaluatee" } }
// ← 400 (ไม่ผ่าน validate)
{ "success": false, "message": "รหัสผ่านอย่างน้อย 6 ตัวอักษร" }
```

---

## 2. Users — `/api/users`

### GET `/api/users/me` · ทุกบทบาท
ดูข้อมูลตนเอง
```jsonc
// ← 200
{ "success": true, "data": { "id": 7, "name_th": "สมชาย ใจดี", "email": "teacher1@pes.ac.th", "role": "evaluatee", "created_at": "2026-07-14 06:33:21" } }
```

### PUT `/api/users/me` · ทุกบทบาท
แก้ชื่อตนเอง (แก้ email/role/รหัสผ่านที่นี่ไม่ได้ — email/role ต้องให้ admin, รหัสผ่านใช้ endpoint ถัดไป)
```jsonc
// → request body
{ "name_th": "สมชาย ใจดีมาก" }
// ← 200
{ "success": true, "data": { "id": 7, "name_th": "สมชาย ใจดีมาก", "email": "teacher1@pes.ac.th", "role": "evaluatee", "created_at": "2026-07-14 06:33:21" } }
```

### PUT `/api/users/me/password` · ทุกบทบาท
เปลี่ยนรหัสผ่านตนเอง (ต้องยืนยันรหัสเดิม, ใหม่ ≥ 6 ตัว)
```jsonc
// → request body
{ "current_password": "123456", "new_password": "newpass99" }
// ← 200
{ "success": true, "message": "เปลี่ยนรหัสผ่านสำเร็จ" }
// ← 400 (รหัสเดิมผิด)
{ "success": false, "message": "รหัสผ่านเดิมไม่ถูกต้อง" }
```

### GET `/api/users` · admin, evaluator
รายการผู้ใช้ (แบ่งหน้า/ค้นหา/เรียง, กรอง `?role=`)
```jsonc
// → GET /api/users?role=evaluator&page=1&itemsPerPage=10
// ← 200
{
  "success": true,
  "items": [
    { "id": 2, "name_th": "สมพงษ์ วัฒนกิจ", "email": "eval1@pes.ac.th", "role": "evaluator", "created_at": "2026-07-14 06:33:21" },
    { "id": 3, "name_th": "วิภาดา รุ่งเรือง", "email": "eval2@pes.ac.th", "role": "evaluator", "created_at": "2026-07-14 06:33:21" }
  ],
  "total": 5, "page": 1, "itemsPerPage": 10
}
```

### POST `/api/users` · admin
เพิ่มผู้ใช้
```jsonc
// → request body
{ "name_th": "ประเสริฐ ทำงานดี", "email": "eval6@pes.ac.th", "password": "123456", "role": "evaluator" }
// ← 201
{ "success": true, "data": { "id": 18, "name_th": "ประเสริฐ ทำงานดี", "email": "eval6@pes.ac.th", "role": "evaluator", "created_at": "2026-07-15 09:12:00" } }
// ← 409 (อีเมลซ้ำ)
{ "success": false, "message": "ข้อมูลซ้ำ (เช่น อีเมลนี้มีอยู่แล้ว)" }
```

### PUT `/api/users/:id` · admin
แก้ไขผู้ใช้ (ส่งเฉพาะฟิลด์ที่จะแก้ — เว้น password = ไม่เปลี่ยน)
```jsonc
// → PUT /api/users/18   body:
{ "name_th": "ประเสริฐ ขยันมาก", "role": "evaluator" }
// ← 200
{ "success": true, "data": { "id": 18, "name_th": "ประเสริฐ ขยันมาก", "email": "eval6@pes.ac.th", "role": "evaluator", "created_at": "2026-07-15 09:12:00" } }
```

### DELETE `/api/users/:id` · admin
```jsonc
// → DELETE /api/users/18
// ← 200
{ "success": true }
// ← 404
{ "success": false, "message": "ไม่พบผู้ใช้" }
```

---

## 3. Periods (รอบการประเมิน) — `/api/periods`

CRUD มาตรฐาน — เปิดหลายรอบพร้อมกันได้ · body: `{ name_th, start_date, end_date, is_active }`

### GET `/api/periods` · ทุกบทบาท
```jsonc
// ← 200
{
  "success": true,
  "items": [
    { "id": 2, "name_th": "การประเมินครูประจำปี 2568 ภาคเรียนที่ 2", "start_date": "2026-04-01", "end_date": "2026-12-31", "is_active": 1 },
    { "id": 3, "name_th": "การประเมิน วPA ปีการศึกษา 2569", "start_date": "2026-07-01", "end_date": "2026-07-17", "is_active": 1 }
  ],
  "total": 3, "page": 1, "itemsPerPage": 10
}
```

### GET `/api/periods/:id` · ทุกบทบาท
```jsonc
// ← 200
{ "success": true, "data": { "id": 2, "name_th": "การประเมินครูประจำปี 2568 ภาคเรียนที่ 2", "start_date": "2026-04-01", "end_date": "2026-12-31", "is_active": 1 } }
```

### POST `/api/periods` · admin
```jsonc
// → request body
{ "name_th": "การประเมินภาคเรียนที่ 1/2569", "start_date": "2026-05-01", "end_date": "2026-10-31", "is_active": 1 }
// ← 201
{ "success": true, "data": { "id": 4, "name_th": "การประเมินภาคเรียนที่ 1/2569", "start_date": "2026-05-01", "end_date": "2026-10-31", "is_active": 1 } }
```

### PUT `/api/periods/:id` · admin
```jsonc
// → PUT /api/periods/4   body:
{ "is_active": 0 }
// ← 200
{ "success": true, "data": { "id": 4, "name_th": "การประเมินภาคเรียนที่ 1/2569", "start_date": "2026-05-01", "end_date": "2026-10-31", "is_active": 0 } }
```

### DELETE `/api/periods/:id` · admin
ลบรอบ (หัวข้อ/ตัวชี้วัดในรอบถูกลบตาม cascade)
```jsonc
// ← 200
{ "success": true }
```

---

## 4. Topics (หัวข้อ) — `/api/topics`

CRUD มาตรฐาน — หัวข้อผูกกับรอบ · body: `{ period_id, name_th, description }`

### GET `/api/topics?period_id=2` · ทุกบทบาท
```jsonc
// ← 200
{
  "success": true,
  "items": [
    { "id": 4, "period_id": 2, "name_th": "การจัดการเรียนการสอน", "description": "คุณภาพการวางแผน สื่อ และการวัดผล" },
    { "id": 5, "period_id": 2, "name_th": "การพัฒนาตนเอง", "description": "อบรม สัมมนา งานวิจัย" }
  ],
  "total": 3, "page": 1, "itemsPerPage": 10
}
```

### GET `/api/topics/:id` · ทุกบทบาท
```jsonc
{ "success": true, "data": { "id": 4, "period_id": 2, "name_th": "การจัดการเรียนการสอน", "description": "คุณภาพการวางแผน สื่อ และการวัดผล" } }
```

### POST `/api/topics` · admin
```jsonc
// → request body
{ "period_id": 2, "name_th": "งานกิจกรรมนักเรียน", "description": "การดูแลกิจกรรมและชมรม" }
// ← 201
{ "success": true, "data": { "id": 10, "period_id": 2, "name_th": "งานกิจกรรมนักเรียน", "description": "การดูแลกิจกรรมและชมรม" } }
```

### PUT `/api/topics/:id` · admin
```jsonc
// → PUT /api/topics/10   body:
{ "name_th": "งานกิจกรรมพัฒนาผู้เรียน" }
// ← 200
{ "success": true, "data": { "id": 10, "period_id": 2, "name_th": "งานกิจกรรมพัฒนาผู้เรียน", "description": "การดูแลกิจกรรมและชมรม" } }
```

### DELETE `/api/topics/:id` · admin
```jsonc
{ "success": true }
```

---

## 5. Indicators (ตัวชี้วัด) — `/api/indicators`

CRUD มาตรฐาน + ไฟล์แม่แบบ · body: `{ topic_id, name_th, description, weight, type, evidence_kind, template_url }`
- `type`: `score_1_4` (คะแนน 1-4 มีน้ำหนัก) | `yes_no` (มี/ไม่มี ไม่คิดคะแนน)
- `evidence_kind`: ชนิดหลักฐานคั่นด้วยจุลภาค เช่น `"pdf,image,url"`

### GET `/api/indicators` · ทุกบทบาท
```jsonc
// ← 200
{
  "success": true,
  "items": [
    { "id": 7, "topic_id": 4, "name_th": "แผนการจัดการเรียนรู้", "description": "แผนสอนสอดคล้องมาตรฐาน", "weight": "2.00", "type": "score_1_4", "evidence_kind": "pdf,image", "template_name": null, "template_path": null, "template_url": null }
  ],
  "total": 6, "page": 1, "itemsPerPage": 10
}
```

### GET `/api/indicators/:id` · ทุกบทบาท
```jsonc
{ "success": true, "data": { "id": 7, "topic_id": 4, "name_th": "แผนการจัดการเรียนรู้", "weight": "2.00", "type": "score_1_4", "evidence_kind": "pdf,image", "template_name": null, "template_path": null, "template_url": null } }
```

### POST `/api/indicators` · admin
```jsonc
// → request body
{ "topic_id": 4, "name_th": "การใช้สื่อเทคโนโลยี", "description": "ใช้สื่อดิจิทัลในการสอน", "weight": 1, "type": "score_1_4", "evidence_kind": "pdf,url" }
// ← 201
{ "success": true, "data": { "id": 20, "topic_id": 4, "name_th": "การใช้สื่อเทคโนโลยี", "weight": "1.00", "type": "score_1_4", "evidence_kind": "pdf,url", "template_name": null, "template_path": null, "template_url": null } }
```

### PUT `/api/indicators/:id` · admin
```jsonc
// → PUT /api/indicators/20   body:
{ "weight": 2 }
// ← 200
{ "success": true, "data": { "id": 20, "topic_id": 4, "name_th": "การใช้สื่อเทคโนโลยี", "weight": "2.00", "type": "score_1_4", "evidence_kind": "pdf,url" } }
```

### DELETE `/api/indicators/:id` · admin
```jsonc
{ "success": true }
```

### POST `/api/indicators/:id/template` · admin
อัปโหลดไฟล์แม่แบบ — `Content-Type: multipart/form-data`, field ชื่อ `file` (1 ไฟล์)
```jsonc
// → multipart/form-data: file=<แผนการสอน_ตัวอย่าง.pdf>
// ← 200
{ "success": true, "data": { "id": 7, "topic_id": 4, "name_th": "แผนการจัดการเรียนรู้", "template_name": "แผนการสอน_ตัวอย่าง.pdf", "template_path": "/uploads/1784013993892_แผนการสอน_ตัวอย่าง.pdf" } }
```

### DELETE `/api/indicators/:id/template` · admin
ลบไฟล์แม่แบบ (ลบทั้งไฟล์บนดิสก์และค่าใน DB)
```jsonc
{ "success": true }
```

---

## 6. Assignments (มอบหมายกรรมการ) — `/api/assignments`

body: `{ period_id, evaluator_id, evaluatee_id, committee_role }`
- `committee_role`: `chair` (ประธาน) | `member` (กรรมการร่วม)

### GET `/api/assignments?period_id=2` · admin, evaluator
คืนชื่อจริง (join แล้ว)
```jsonc
// ← 200
{
  "success": true,
  "items": [
    { "id": 21, "period_id": 2, "evaluator_id": 3, "evaluatee_id": 7, "committee_role": "chair", "status": "submitted", "submitted_at": "2026-07-14 06:33:21", "unlocked_at": null, "unlocked_by": null, "period_name": "การประเมินครูประจำปี 2568 ภาคเรียนที่ 2", "evaluator_name": "วิภาดา รุ่งเรือง", "evaluatee_name": "สมชาย ใจดี" }
  ],
  "total": 20, "page": 1, "itemsPerPage": 10
}
```

### POST `/api/assignments` · admin
```jsonc
// → request body
{ "period_id": 2, "evaluator_id": 2, "evaluatee_id": 8, "committee_role": "member" }
// ← 201
{ "success": true, "data": { "id": 61, "period_id": 2, "evaluator_id": 2, "evaluatee_id": 8, "committee_role": "member", "status": "pending", "period_name": "...", "evaluator_name": "สมพงษ์ วัฒนกิจ", "evaluatee_name": "สมหญิง เก่งงาน" } }
// ← 409 (มอบหมายซ้ำ คน+รอบเดิม)
{ "success": false, "message": "ข้อมูลซ้ำ (เช่น อีเมลนี้มีอยู่แล้ว)" }
```

### PUT `/api/assignments/:id` · admin
```jsonc
// → PUT /api/assignments/61   body:
{ "committee_role": "chair" }
// ← 200
{ "success": true, "data": { "id": 61, "committee_role": "chair", "evaluator_name": "สมพงษ์ วัฒนกิจ", "evaluatee_name": "สมหญิง เก่งงาน" } }
```

### DELETE `/api/assignments/:id` · admin
```jsonc
{ "success": true }
```

### POST `/api/assignments/:id/unlock` · admin
ปลดล็อกใบที่ส่งผลแล้ว → สถานะกลับเป็น pending + ล้างลายเซ็น ให้กรรมการแก้+เซ็นใหม่
```jsonc
// → POST /api/assignments/21/unlock
// ← 200
{ "success": true, "message": "ปลดล็อกแล้ว กรรมการแก้ไขคะแนนและเซ็นส่งใหม่ได้" }
// ← 404 (ยังไม่ได้ส่งผล จึงปลดล็อกไม่ได้)
{ "success": false, "message": "ไม่พบใบประเมินนี้ หรือยังไม่ได้ส่งผล" }
```

---

## 7. Evidences (ข้อมูล/หลักฐานของผู้รับการประเมิน) — `/api/evidences`

### GET `/api/evidences/periods` · evaluatee
รอบที่เปิดอยู่ + ความคืบหน้าของตนเองแต่ละรอบ
```jsonc
// ← 200
{
  "success": true,
  "items": [
    { "id": 2, "name_th": "การประเมินครูประจำปี 2568 ภาคเรียนที่ 2", "start_date": "2026-04-01", "end_date": "2026-12-31", "total": 6, "filled": 6, "percent": 100 },
    { "id": 3, "name_th": "การประเมิน วPA ปีการศึกษา 2569", "start_date": "2026-07-01", "end_date": "2026-07-17", "total": 6, "filled": 0, "percent": 0 }
  ]
}
```

### GET `/api/evidences?period_id=2` · ทุกบทบาท
ตัวชี้วัดของรอบ + ข้อมูลที่กรอก (ถ้ายังไม่กรอก ฟิลด์ `evidence_id`/`detail`/`self_score` เป็น null) + ไฟล์แนบ
```jsonc
// ← 200
{
  "success": true,
  "items": [
    {
      "indicator_id": 7, "indicator": "แผนการจัดการเรียนรู้", "description": "แผนสอนสอดคล้องมาตรฐาน",
      "type": "score_1_4", "weight": "2.00", "evidence_kind": "pdf,image",
      "template_name": null, "template_path": null, "template_url": null, "topic": "การจัดการเรียนการสอน",
      "evidence_id": 12, "detail": "จัดทำแผนครบทุกหน่วย", "url": null, "self_score": "3.5", "self_note": "ดำเนินการครบถ้วน",
      "files": [ { "id": 5, "evidence_id": 12, "file_name": "แผนการสอน.pdf", "path": "/uploads/1784_แผนการสอน.pdf", "mime": "application/pdf", "size": 24500 } ]
    }
  ]
}
```

### POST `/api/evidences` · evaluatee
บันทึกข้อมูล+ประเมินตนเอง (upsert: มีอยู่แล้ว=แก้, ยังไม่มี=เพิ่ม) — ปฏิเสธถ้ารอบหมดเขต
```jsonc
// → request body
{ "indicator_id": 7, "period_id": 2, "detail": "จัดทำแผนครบทุกหน่วย", "url": null, "self_score": 3.5, "self_note": "ดำเนินการครบถ้วน" }
// ← 200
{ "success": true, "data": { "id": 12, "evaluatee_id": 7, "indicator_id": 7, "period_id": 2, "detail": "จัดทำแผนครบทุกหน่วย", "url": null, "self_score": "3.5", "self_note": "ดำเนินการครบถ้วน" } }
// ← 400 (รอบหมดเขต)
{ "success": false, "message": "หมดเขตการประเมินของรอบ \"...\" แล้ว (สิ้นสุด 2026-03-31)" }
```

### POST `/api/evidences/:id/files` · evaluatee
อัปโหลดไฟล์หลักฐานหลายไฟล์ — `multipart/form-data`, field `files` (≤5 ไฟล์ PDF/JPG/PNG ไฟล์ละ ≤5MB)
```jsonc
// → multipart/form-data: files=<หลักฐาน1.pdf>, files=<รูปกิจกรรม.jpg>
// ← 201
{
  "success": true,
  "data": [
    { "evidence_id": 12, "file_name": "หลักฐาน1.pdf", "path": "/uploads/1784_หลักฐาน1.pdf", "mime": "application/pdf", "size": 10240 },
    { "evidence_id": 12, "file_name": "รูปกิจกรรม.jpg", "path": "/uploads/1784_รูปกิจกรรม.jpg", "mime": "image/jpeg", "size": 88300 }
  ]
}
// ← 400 (ไฟล์ผิดชนิด — จาก middleware)
{ "success": false, "message": "อนุญาตเฉพาะไฟล์ PDF, JPG, PNG" }
```

### DELETE `/api/evidences/files/:fileId` · evaluatee
```jsonc
{ "success": true }
```

---

## 8. Reviews (การให้คะแนนของกรรมการ) — `/api/reviews`

### GET `/api/reviews/assignments` · evaluator
รายชื่อที่กรรมการคนนี้ต้องประเมิน + สถานะ
```jsonc
// ← 200
{
  "success": true,
  "items": [
    { "id": 21, "status": "submitted", "committee_role": "chair", "evaluatee": "สมชาย ใจดี", "email": "teacher1@pes.ac.th", "period_name": "การประเมินครูประจำปี 2568 ภาคเรียนที่ 2" },
    { "id": 28, "status": "pending", "committee_role": "member", "evaluatee": "กาญจนา ศรีวิไล", "email": "teacher4@pes.ac.th", "period_name": "การประเมินครูประจำปี 2568 ภาคเรียนที่ 2" }
  ]
}
```

### GET `/api/reviews/:assignmentId` · evaluator
รายละเอียดใบประเมิน: หัวใบ (`assignment`) + ตัวชี้วัดพร้อมข้อมูลผู้รับ (`self_score`) และคะแนนกรรมการที่เคยให้ (`score`)
```jsonc
// ← 200
{
  "success": true,
  "assignment": {
    "id": 28, "period_id": 2, "evaluator_id": 2, "evaluatee_id": 10, "committee_role": "member",
    "status": "pending", "overall_comment": null, "signature_path": null,
    "evaluatee": "กาญจนา ศรีวิไล", "evaluatee_email": "teacher4@pes.ac.th",
    "period_name": "การประเมินครูประจำปี 2568 ภาคเรียนที่ 2", "period_end_date": "2026-12-31"
  },
  "items": [
    { "indicator_id": 7, "indicator": "แผนการจัดการเรียนรู้", "type": "score_1_4", "weight": "2.00", "topic": "การจัดการเรียนการสอน", "detail": "จัดทำแผนครบ", "url": null, "self_score": "3.5", "score": null, "comment": null, "files": [] }
  ]
}
```

### POST `/api/reviews` · evaluator
ให้คะแนนทีละตัวชี้วัด (upsert) — ปฏิเสธถ้ารอบหมดเขต หรือใบส่งผลไปแล้ว
```jsonc
// → request body
{ "assignment_id": 28, "indicator_id": 7, "score": 3, "comment": "แผนดี ควรเพิ่มการวัดผล" }
// ← 200
{ "success": true }
// ← 400 (ส่งผลไปแล้ว)
{ "success": false, "message": "ส่งผลการประเมินไปแล้ว ไม่สามารถแก้ไขคะแนนได้" }
```

### POST `/api/reviews/:assignmentId/submit` · evaluator
ยืนยันส่งผล + ความเห็นสรุป + ลายเซ็น (base64) → สถานะเป็น submitted (ล็อกใบ)
```jsonc
// → request body
{ "overall_comment": "ผลงานอยู่ในเกณฑ์ดี", "signature": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA..." }
// ← 200
{ "success": true }
```

### GET `/api/reviews/feedback?period_id=2` · evaluatee
ผู้รับการประเมินดูความเห็น/คะแนนที่กรรมการให้ตน
```jsonc
// ← 200
{
  "success": true,
  "perIndicator": [
    { "indicator": "แผนการจัดการเรียนรู้", "score": "4.0", "comment": "แผนละเอียดดีมาก", "evaluator": "วิภาดา รุ่งเรือง", "committee_role": "chair" }
  ],
  "overall": [
    { "evaluator": "วิภาดา รุ่งเรือง", "overall_comment": "ผลงานอยู่ในเกณฑ์ดี", "signature_path": "/uploads/sign_21_1784.png", "committee_role": "chair" }
  ]
}
```

---

## 9. Tracking (ติดตามสถานะ) — `/api/tracking`

### GET `/api/tracking/evaluators?period_id=2` · admin
สถานะกรรมการแต่ละคน: ประเมินใครแล้ว/ยัง
```jsonc
// ← 200
{
  "success": true,
  "items": [
    { "assignment_id": 21, "evaluator_id": 3, "evaluator_name": "วิภาดา รุ่งเรือง", "evaluatee_id": 7, "evaluatee_name": "สมชาย ใจดี", "committee_role": "chair", "status": "submitted", "submitted_at": "2026-07-14 06:33:21" }
  ]
}
```

### GET `/api/tracking/evaluatees?period_id=2` · admin
ความคืบหน้าประเมินตนเองของผู้รับแต่ละคน + กรรมการส่งผลแล้วกี่คน
```jsonc
// ← 200
{
  "success": true,
  "items": [
    { "id": 7, "name_th": "สมชาย ใจดี", "email": "teacher1@pes.ac.th", "totalIndicators": 6, "filled": 6, "percent": 100, "evaluatorsTotal": 2, "evaluatorsSubmitted": 1 }
  ]
}
```

---

## 10. Report (รายงาน/สถิติ) — `/api`

### GET `/api/summary/:evaluateeId?period_id=2` · ทุกบทบาท
สรุปผลรายบุคคล — ระบุ `&evaluator_id=` เพื่อดูคะแนนดิบของกรรมการรายคน (ไม่ระบุ = ค่าเฉลี่ยรวม)
```jsonc
// ← 200
{
  "success": true,
  "user": { "id": 7, "name_th": "สมชาย ใจดี", "email": "teacher1@pes.ac.th" },
  "period": { "id": 2, "name_th": "การประเมินครูประจำปี 2568 ภาคเรียนที่ 2" },
  "items": [
    { "topic": "การจัดการเรียนการสอน", "indicator": "แผนการจัดการเรียนรู้", "weight": "2.00", "type": "score_1_4", "self_score": "3.5", "committee_score": "4.00" },
    { "topic": "การจัดการเรียนการสอน", "indicator": "บันทึกหลังการสอน", "weight": "1.00", "type": "yes_no", "self_score": "1.0", "committee_score": "1.00" }
  ],
  "overall": 3.78,
  "compliance": { "total": 1, "met": 1 },
  "committees": [
    { "evaluator_id": 3, "evaluator": "วิภาดา รุ่งเรือง", "committee_role": "chair", "status": "submitted", "signature_path": "/uploads/sign_21_1784.png" }
  ]
}
```

### GET `/api/stats?period_id=2&level=topic` · admin
สถิติ dashboard + คะแนนเฉลี่ยรายหัวข้อ (`level=topic`) หรือรายตัวชี้วัด (`level=indicator`)
```jsonc
// ← 200
{
  "success": true,
  "roles": { "admin": 1, "evaluator": 5, "evaluatee": 10 },
  "submitted": 10,
  "pending": 10,
  "byTopic": [
    { "topic": "การจัดการเรียนการสอน", "avg_score": 3.33 },
    { "topic": "การพัฒนาตนเอง", "avg_score": 3.5 },
    { "topic": "จรรยาบรรณวิชาชีพ", "avg_score": 3.1 }
  ]
}
// ← เมื่อ level=indicator แต่ละแท่งเพิ่ม group_topic (บอกว่าตัวชี้วัดอยู่หัวข้อไหน)
// { "topic": "แผนการจัดการเรียนรู้", "group_topic": "การจัดการเรียนการสอน", "avg_score": 4.0 }
```

---

## 11. Backup (สำรอง/กู้คืน) — `/api`

### POST `/api/backup` · admin
สร้าง snapshot (ทุกตาราง + สำเนาไฟล์แนบ)
```jsonc
// ← 200
{ "success": true, "message": "สำรองข้อมูลสำเร็จ", "file": "backup_2026-07-15T09-30-00-000Z.json" }
```

### GET `/api/backups` · admin
รายการไฟล์สำรอง (ใหม่สุดขึ้นก่อน)
```jsonc
// ← 200
{
  "success": true,
  "items": [
    { "file": "backup_2026-07-15T09-30-00-000Z.json", "size": 21504, "hasFiles": true, "filesSize": 815104 }
  ]
}
```

### POST `/api/restore/:file` · admin
กู้คืนจาก snapshot (แทนที่ข้อมูลทุกตาราง + ไฟล์แนบทั้งโฟลเดอร์)
```jsonc
// → POST /api/restore/backup_2026-07-15T09-30-00-000Z.json
// ← 200
{ "success": true, "message": "กู้คืนข้อมูลและไฟล์แนบสำเร็จ" }
```

### DELETE `/api/backups/:file` · admin
```jsonc
{ "success": true, "message": "ลบไฟล์สำรองแล้ว" }
```

---

## สรุปหลัก RESTful ที่ใช้ในระบบนี้

1. **ใช้ HTTP method ให้ตรงความหมาย** — GET (อ่าน ไม่เปลี่ยนข้อมูล), POST (สร้าง), PUT (แก้), DELETE (ลบ)
2. **จัด URL เป็น resource (คำนามพหูพจน์)** — `/api/users`, `/api/topics` ไม่ใช่ `/api/getUsers`
3. **รายตัวใช้ id ต่อท้าย** — `/api/users/:id`
4. **resource ซ้อน resource** — `/api/indicators/:id/template`, `/api/evidences/:id/files`
5. **action พิเศษที่ไม่ใช่ CRUD ใช้ sub-path กริยา** — `/api/assignments/:id/unlock`, `/api/reviews/:id/submit`
6. **สื่อสถานะด้วย HTTP status code** — ไม่ใช่ตอบ 200 แล้วซ่อน error ใน body
7. **โครงสร้าง response เหมือนกันทั้งระบบ** — `{ success, data }` / `{ success, items, total }` / `{ success, message }`
8. **แบ่งหน้า/ค้นหา/เรียง ผ่าน query string** — ไม่ทำ endpoint แยก
