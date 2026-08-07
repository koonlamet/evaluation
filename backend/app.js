const express = require("express");
const cors = require("cors");
const morgan = require("morgan");
const path = require("path");
require("dotenv").config();

const crud = require("./utils/crud");       // โรงงานสร้างฟังก์ชัน CRUD (list/get/create/update/remove) ให้ 1 ตาราง
const mountCrud = require("./utils/mountCrud"); // ตัวห่อ crud() ให้กลายเป็น router พร้อมกำหนดสิทธิ์ read/write

const app = express(); // แอป Express หลัก — ทุก middleware/route ด้านล่างต่อเข้ากับตัวนี้ทั้งหมด


app.use(cors({ origin: process.env.CORS_ORIGIN?.split(",") || "*" })); // อนุญาตให้ frontend (คนละ origin/port) เรียก API นี้ได้
app.use(express.json({ limit: "6mb" })); // เผื่อรูปลายเซ็น base64
app.use(express.urlencoded({ extended: true }));
app.use(require("./middlewares/sanitize")); // กัน stored XSS ทุก endpoint (โจทย์พิเศษ 8.2)
app.use(morgan("dev"));
app.use("/uploads", express.static(path.join(__dirname, "uploads"))); // ให้เปิดไฟล์แนบได้

// ---- เส้นทางที่มี logic เฉพาะ ----
app.use("/api/auth", require("./routes/auth.routes"));
app.use("/api/users", require("./routes/users.routes"));
app.use("/api/evidences", require("./routes/evidences.routes"));
app.use("/api/reviews", require("./routes/reviews.routes"));
app.use("/api/assignments", require("./routes/assignments.routes")); // join ชื่อจริงกรรมการ/ผู้รับการประเมิน
app.use("/api/tracking", require("./routes/tracking.routes"));       // ติดตามสถานะ 5.1.10-5.1.12
app.use("/api/indicators", require("./routes/indicatorTemplate.routes")); // แม่แบบ/ไฟล์อ้างอิงที่ admin แนบให้ (มาก่อน mountCrud ทั่วไป)
app.use("/api", require("./routes/report.routes"));  // /api/stats, /api/summary/:id
app.use("/api", require("./routes/backup.routes"));  // /api/backup, /api/backups, /api/restore/:file

// ---- เส้นทาง CRUD มาตรฐาน (ใช้ตัวสร้างชุดเดียว) ----
app.use("/api/topics", mountCrud(
  crud({
    table: "topics", fields: ["period_id", "name_th", "description"], // fields = คอลัมน์ที่ยอมรับตอนเพิ่ม/แก้ (กันแอบยัดคอลัมน์อื่น)
    searchable: ["name_th"], sortable: ["id", "name_th"], filterable: ["period_id"], // searchable = ค้นหาได้ในคอลัมน์ไหน, filterable = กรองตรงๆ ผ่าน query string ได้ (เช่น ?period_id=1)
  }),
  { read: [], write: ["admin"] } // read: [] = ใครก็ได้ (แค่ login) อ่านได้, write: ["admin"] = แก้/ลบได้เฉพาะ admin
));
app.use("/api/indicators", mountCrud(
  crud({
    table: "indicators",
    fields: ["topic_id", "name_th", "description", "weight", "type", "evidence_kind", "template_url"],
    searchable: ["name_th"], sortable: ["id", "name_th", "weight"],
  }),
  { read: [], write: ["admin"] }
));
// หลายรอบเปิดใช้งานพร้อมกันได้ (เช่น ประเมินการสอน + ประเมิน PA คนละหัวข้อ คนละช่วงเวลา แต่ทับซ้อนกันได้)
app.use("/api/periods", mountCrud(
  crud({ table: "periods", fields: ["name_th", "start_date", "end_date", "is_active"], searchable: ["name_th"], sortable: ["id", "start_date"] }),
  { read: [], write: ["admin"] }
));

// Health + เอกสาร API แบบย่อ (คำอธิบายแต่ละ service + parameter — เกณฑ์ 6.7/6.8)
app.get("/health", (req, res) => res.json({ ok: true, time: new Date().toISOString() }));
app.get("/api", (req, res) => res.json(require("./apidoc.json")));

app.use((req, res) => res.status(404).json({ success: false, message: "ไม่พบเส้นทางนี้" }));
app.use(require("./middlewares/error"));

module.exports = app;
