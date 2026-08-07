// ตั้งค่า Multer สำหรับอัปโหลดไฟล์หลักฐาน (โจทย์พิเศษ 8.3)
// - จำกัดชนิดไฟล์ (File Type): pdf / jpg / png
// - จำกัดขนาดไฟล์ 5MB (กัน Large File DoS)
// - รับได้หลายไฟล์พร้อมกัน (ใช้ .array ในเราต์)
const multer = require("multer");
const path = require("path");
const fs = require("fs");

const DIR = path.join(__dirname, "..", "uploads"); // โฟลเดอร์ปลายทางที่เก็บไฟล์อัปโหลดทั้งหมด (backend/uploads/)
fs.mkdirSync(DIR, { recursive: true });

// busboy (ที่ multer ใช้ข้างใน) ถอดรหัสชื่อไฟล์จาก header เป็น latin1 เสมอ ทำให้ภาษาไทย (multi-byte UTF-8) เพี้ยน
// ต้อง re-decode กลับเป็น utf8 ก่อนใช้งาน — แก้ที่จุดเดียวนี้ (fileFilter ทำงานก่อน storage เสมอ) แล้วทุกจุดที่อ่าน
// req.file(s).originalname ต่อจากนี้ (เช่น evidences.controller.js, indicatorTemplate.controller.js) จะได้ค่าที่ถูกต้อง
const fixEncoding = (name) => Buffer.from(name, "latin1").toString("utf8"); // name = ชื่อไฟล์ที่ multer ถอดรหัสผิดมา, คืนชื่อไฟล์ที่ decode ใหม่ให้ถูกต้อง

const storage = multer.diskStorage({ // กำหนดว่าไฟล์ที่อัปโหลดเข้ามาจะถูกเก็บที่ไหนและตั้งชื่อว่าอะไร
  destination: (req, file, cb) => cb(null, DIR), // ทุกไฟล์ไปลงโฟลเดอร์เดียวกัน (DIR)
  filename: (req, file, cb) => // ตั้งชื่อไฟล์บนดิสก์: timestamp + ชื่อเดิม (กันชื่อไฟล์ชนกัน + เว้นวรรคแทนด้วย _)
    cb(null, Date.now() + "_" + file.originalname.replace(/\s+/g, "_")),
});

const ALLOWED = ["application/pdf", "image/jpeg", "image/png"]; // ชนิดไฟล์ (MIME type) ที่ยอมให้อัปโหลด

module.exports = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // จำกัดขนาดไฟล์ 5MB ต่อไฟล์ (กันไฟล์ใหญ่เกินจนเซิร์ฟเวอร์ล่ม/ดิสก์เต็ม)
  fileFilter: (req, file, cb) => { // ด่านตรวจก่อนรับไฟล์ทุกไฟล์ (file = ข้อมูลไฟล์ที่กำลังจะอัปโหลด, cb = ฟังก์ชันบอกผลลัพธ์กลับ)
    file.originalname = fixEncoding(file.originalname); // แก้ชื่อไฟล์ภาษาไทยก่อนเสมอ ไม่ว่าจะรับไฟล์นี้หรือไม่
    return ALLOWED.includes(file.mimetype)
      ? cb(null, true)  // ชนิดไฟล์ผ่าน → รับไฟล์นี้
      : cb(new Error("อนุญาตเฉพาะไฟล์ PDF, JPG, PNG")); // ไม่ผ่าน → ปฏิเสธพร้อมข้อความ error
  },
});
