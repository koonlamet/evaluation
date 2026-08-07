# รายละเอียดลำดับการเขียน API ทั้ง 51 เส้น (Complete API Breakdown & Mapping)

เอกสารนี้รวบรวมและจัดกลุ่ม **API ทั้งหมด 51 เส้นทาง (Endpoints)** ในระบบ PES อย่างสมบูรณ์ โดยจับคู่ระหว่าง **Backend Route/Controller** กับ **Frontend Page/Composable** สำหรับให้ทีมงาน (Backend & Frontend) นำไปไล่เขียนทีละเส้นได้อย่างแม่นยำ

---

## 📍 สรุปจำนวน API แบ่งตามหมวดหมู่ (51 Endpoints)

| หมวดหมู่ (Category) | จำนวน API | ไฟล์ Controller หลัก | ไฟล์ Frontend หลัก |
|---|---|---|---|
| 1. Authentication (ระบบยืนยันตัวตน) | 2 เส้น | `auth.controller.js` | `useAuth.js`, `login.vue`, `register.vue` |
| 2. User Management (จัดการผู้ใช้) | 7 เส้น | `users.controller.js` | `admin/users.vue`, `account.vue` |
| 3. Evaluation Setup (ตั้งค่ารอบ/หัวข้อ/ตัวชี้วัด) | 17 เส้น | `crud.js`, `indicatorTemplate.controller.js` | `admin/setup.vue`, `CrudTable.vue` |
| 4. Assignments (มอบหมายกรรมการ) | 5 เส้น | `assignments.controller.js` | `admin/setup.vue` (แท็บ 3) |
| 5. Evidences (ส่งผลงาน/ไฟล์แนบ) | 5 เส้น | `evidences.controller.js` | `me/period/[id].vue` |
| 6. Reviews (ประเมินและให้คะแนน) | 5 เส้น | `reviews.controller.js` | `eval/index.vue`, `eval/[id].vue` |
| 7. Tracking & Monitoring (ติดตามสถานะ) | 2 เส้น | `tracking.controller.js` | `admin/tracking.vue` |
| 8. Reports & Dashboard (รายงานและสถิติ) | 2 เส้น | `report.controller.js` | `admin/index.vue`, `me/report/[id].vue` |
| 9. Backup & Restore (สำรองข้อมูล) | 4 เส้น | `backup.controller.js` | `admin/index.vue` |
| 10. System (ระบบและเอกสาร) | 2 เส้น | `app.js` | - |
| **รวมทั้งหมด** | **51 เส้น** | | |

---

## 🛠️ ตารางรายละเอียด API ทั้ง 51 เส้นทาง (เรียงลำดับการเขียน)

### Group 1: Authentication (ระบบยืนยันตัวตน)
| # | HTTP Method | API Path | สิทธิ์ (Auth Gate) | Backend Controller & Function | Frontend Page / Composable |
|---|---|---|---|---|---|
| 1 | `POST` | `/api/auth/login` | Public | `auth.controller.js` ➔ `login` | `login.vue` ➔ `useAuth().login()` |
| 2 | `POST` | `/api/auth/register` | Public | `auth.controller.js` ➔ `register` | `register.vue` |

---

### Group 2: User Management (จัดการโปรไฟล์และผู้ใช้งาน)
| # | HTTP Method | API Path | สิทธิ์ (Auth Gate) | Backend Controller & Function | Frontend Page / Composable |
|---|---|---|---|---|---|
| 3 | `GET` | `/api/users/me` | Logged In | `users.controller.js` ➔ `me` | `account.vue`, `useAuth().fetchUser()` |
| 4 | `PUT` | `/api/users/me` | Logged In | `users.controller.js` ➔ `updateMe` | `account.vue` |
| 5 | `PUT` | `/api/users/me/password` | Logged In | `users.controller.js` ➔ `changePassword` | `account.vue` |
| 6 | `GET` | `/api/users` | Admin, Evaluator | `users.controller.js` ➔ `list` | `admin/users.vue` (ใช้ CrudTable) |
| 7 | `POST` | `/api/users` | Admin | `users.controller.js` ➔ `create` | `admin/users.vue` |
| 8 | `PUT` | `/api/users/:id` | Admin | `users.controller.js` ➔ `update` | `admin/users.vue` |
| 9 | `DELETE` | `/api/users/:id` | Admin | `users.controller.js` ➔ `remove` | `admin/users.vue` |

---

### Group 3: Evaluation Setup (รอบการประเมิน, หัวข้อ, ตัวชี้วัด, และไฟล์แม่แบบ)
| # | HTTP Method | API Path | สิทธิ์ (Auth Gate) | Backend Controller & Function | Frontend Page / Composable |
|---|---|---|---|---|---|
| 10 | `GET` | `/api/periods` | Logged In | `utils/crud.js` ➔ `list` (periods) | `admin/setup.vue` (แท็บ 1) |
| 11 | `GET` | `/api/periods/:id` | Logged In | `utils/crud.js` ➔ `get` (periods) | `admin/setup.vue` |
| 12 | `POST` | `/api/periods` | Admin | `utils/crud.js` ➔ `create` (periods) | `admin/setup.vue` |
| 13 | `PUT` | `/api/periods/:id` | Admin | `utils/crud.js` ➔ `update` (periods) | `admin/setup.vue` |
| 14 | `DELETE` | `/api/periods/:id` | Admin | `utils/crud.js` ➔ `remove` (periods) | `admin/setup.vue` |
| 15 | `GET` | `/api/topics` | Logged In | `utils/crud.js` ➔ `list` (topics) | `admin/setup.vue` (แท็บ 2) |
| 16 | `GET` | `/api/topics/:id` | Logged In | `utils/crud.js` ➔ `get` (topics) | `admin/setup.vue` |
| 17 | `POST` | `/api/topics` | Admin | `utils/crud.js` ➔ `create` (topics) | `admin/setup.vue` |
| 18 | `PUT` | `/api/topics/:id` | Admin | `utils/crud.js` ➔ `update` (topics) | `admin/setup.vue` |
| 19 | `DELETE` | `/api/topics/:id` | Admin | `utils/crud.js` ➔ `remove` (topics) | `admin/setup.vue` |
| 20 | `GET` | `/api/indicators` | Logged In | `utils/crud.js` ➔ `list` (indicators) | `admin/setup.vue` (ตารางตัวชี้วัด) |
| 21 | `GET` | `/api/indicators/:id` | Logged In | `utils/crud.js` ➔ `get` (indicators) | `admin/setup.vue` |
| 22 | `POST` | `/api/indicators` | Admin | `utils/crud.js` ➔ `create` (indicators) | `admin/setup.vue` |
| 23 | `PUT` | `/api/indicators/:id` | Admin | `utils/crud.js` ➔ `update` (indicators) | `admin/setup.vue` |
| 24 | `DELETE` | `/api/indicators/:id` | Admin | `utils/crud.js` ➔ `remove` (indicators) | `admin/setup.vue` |
| 25 | `POST` | `/api/indicators/:id/template` | Admin | `indicatorTemplate.controller.js` ➔ `upload` | `admin/setup.vue` (อัปแม่แบบ) |
| 26 | `DELETE` | `/api/indicators/:id/template` | Admin | `indicatorTemplate.controller.js` ➔ `remove` | `admin/setup.vue` (ลบแม่แบบ) |

---

### Group 4: Assignments (การมอบหมายกรรมการ)
| # | HTTP Method | API Path | สิทธิ์ (Auth Gate) | Backend Controller & Function | Frontend Page / Composable |
|---|---|---|---|---|---|
| 27 | `GET` | `/api/assignments` | Admin, Evaluator | `assignments.controller.js` ➔ `list` | `admin/setup.vue` (แท็บ 3) |
| 28 | `POST` | `/api/assignments` | Admin | `assignments.controller.js` ➔ `create` | `admin/setup.vue` |
| 29 | `PUT` | `/api/assignments/:id` | Admin | `assignments.controller.js` ➔ `update` | `admin/setup.vue` |
| 30 | `DELETE` | `/api/assignments/:id` | Admin | `assignments.controller.js` ➔ `remove` | `admin/setup.vue` |
| 31 | `POST` | `/api/assignments/:id/unlock` | Admin | `assignments.controller.js` ➔ `unlock` | `admin/setup.vue` / `tracking.vue` |

---

### Group 5: Evidences (ผู้รับการประเมินกรอกข้อมูลและแนบหลักฐาน)
| # | HTTP Method | API Path | สิทธิ์ (Auth Gate) | Backend Controller & Function | Frontend Page / Composable |
|---|---|---|---|---|---|
| 32 | `GET` | `/api/evidences/periods` | Evaluatee | `evidences.controller.js` ➔ `myPeriods` | `me/index.vue` (เลือกรอบ) |
| 33 | `GET` | `/api/evidences` | Logged In | `evidences.controller.js` ➔ `list` | `me/period/[id].vue` |
| 34 | `POST` | `/api/evidences` | Evaluatee | `evidences.controller.js` ➔ `save` | `me/period/[id].vue` (บันทึกข้อมูล) |
| 35 | `POST` | `/api/evidences/:id/files` | Evaluatee | `evidences.controller.js` ➔ `uploadFiles` | `me/period/[id].vue` (อัปโหลดไฟล์) |
| 36 | `DELETE` | `/api/evidences/files/:fileId` | Evaluatee | `evidences.controller.js` ➔ `removeFile` | `me/period/[id].vue` (ลบไฟล์) |

---

### Group 6: Reviews (กรรมการประเมินผลและให้คะแนน)
| # | HTTP Method | API Path | สิทธิ์ (Auth Gate) | Backend Controller & Function | Frontend Page / Composable |
|---|---|---|---|---|---|
| 37 | `GET` | `/api/reviews/assignments` | Evaluator | `reviews.controller.js` ➔ `myAssignments` | `eval/index.vue` (ตารางงาน) |
| 38 | `GET` | `/api/reviews/feedback` | Evaluatee | `reviews.controller.js` ➔ `feedback` | `me/report/[id].vue` (ข้อเสนอแนะ) |
| 39 | `GET` | `/api/reviews/:assignmentId` | Evaluator | `reviews.controller.js` ➔ `detail` | `eval/[id].vue` (ดูหลักฐาน) |
| 40 | `POST` | `/api/reviews` | Evaluator | `reviews.controller.js` ➔ `save` | `eval/[id].vue` (ให้คะแนน) |
| 41 | `POST` | `/api/reviews/:assignmentId/submit` | Evaluator | `reviews.controller.js` ➔ `submit` | `eval/[id].vue` (เซ็นชื่อส่งผล) |

---

### Group 7: Tracking & Monitoring (ติดตามสถานะการประเมิน)
| # | HTTP Method | API Path | สิทธิ์ (Auth Gate) | Backend Controller & Function | Frontend Page / Composable |
|---|---|---|---|---|---|
| 42 | `GET` | `/api/tracking/evaluators` | Admin | `tracking.controller.js` ➔ `byEvaluator` | `admin/tracking.vue` (แท็บกรรมการ) |
| 43 | `GET` | `/api/tracking/evaluatees` | Admin | `tracking.controller.js` ➔ `byEvaluatee` | `admin/tracking.vue` (แท็บผู้รับ) |

---

### Group 8: Reports & Dashboard (รายงานสรุปผลและสถิติ)
| # | HTTP Method | API Path | สิทธิ์ (Auth Gate) | Backend Controller & Function | Frontend Page / Composable |
|---|---|---|---|---|---|
| 44 | `GET` | `/api/stats` | Admin | `report.controller.js` ➔ `stats` | `admin/index.vue` (Dashboard) |
| 45 | `GET` | `/api/summary/:evaluateeId` | Logged In | `report.controller.js` ➔ `summary` | `EvaluationReport.vue`, `me/report/[id].vue`, `admin/report/[id].vue` |

---

### Group 9: Backup & Restore (สำรองและกู้คืนฐานข้อมูล)
| # | HTTP Method | API Path | สิทธิ์ (Auth Gate) | Backend Controller & Function | Frontend Page / Composable |
|---|---|---|---|---|---|
| 46 | `POST` | `/api/backup` | Admin | `backup.controller.js` ➔ `create` | `admin/index.vue` (กดสำรองข้อมูล) |
| 47 | `GET` | `/api/backups` | Admin | `backup.controller.js` ➔ `list` | `admin/index.vue` (ตารางไฟล์สำรอง) |
| 48 | `POST` | `/api/restore/:file` | Admin | `backup.controller.js` ➔ `restore` | `admin/index.vue` (กดกู้คืน) |
| 49 | `DELETE` | `/api/backups/:file` | Admin | `backup.controller.js` ➔ `remove` | `admin/index.vue` (ลบไฟล์สำรอง) |

---

### Group 10: System Utilities & Health (ระบบและเอกสาร)
| # | HTTP Method | API Path | สิทธิ์ (Auth Gate) | Backend Controller & Function | Frontend Page / Composable |
|---|---|---|---|---|---|
| 50 | `GET` | `/health` | Public | `app.js` ➔ Inline handler | - |
| 51 | `GET` | `/api` | Public | `app.js` ➔ Inline handler (อ่าน `apidoc.json`) | - |

---

## 🎯 คำแนะนำในการแบ่งงาน API 51 เส้นสำหรับ 2 คน

1. **คนทำ Backend:** 
   - ให้เปิดตารางด้านบนแล้วสร้าง Route/Controller ไล่ตามหมายเลข #1 ถึง #51 โดยเน้นสร้าง Middlewares & Generic CRUD (`mountCrud`) ในข้อ #10-#24 ให้เสร็จก่อน เพราะจะได้ API รวดเดียว 15 เส้นทันที!
2. **คนทำ Frontend:**
   - ใช้ตารางช่อง "Frontend Page / Composable" เพื่อดูว่าแต่ละหน้าเว็บต้องใช้ API เลขไหนบ้าง (เช่น หน้า `admin/setup.vue` จะใช้ API เลข #10-#31) แล้วเขียน Axios เรียก API ตาม Path และ HTTP Method ในตารางได้เลย
