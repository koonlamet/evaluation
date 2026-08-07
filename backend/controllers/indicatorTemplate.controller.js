// ไฟล์แม่แบบ/ตัวอย่าง (PDF หรือรูปภาพ) ที่ฝ่ายบุคลากรแนบไว้ให้ผู้รับการประเมินดาวน์โหลด (5.1.3 หลักฐานที่ใช้แนบ)
const db = require("../db");
const fs = require("fs");
const path = require("path");

/**
 * POST /api/indicators/:id/template  (บทบาท admin)
 * form-data: file  → อัปโหลดไฟล์แม่แบบ 1 ไฟล์ต่อ 1 ตัวชี้วัด (แทนที่ไฟล์เดิมถ้ามี)
 */
exports.upload = async (req, res, next) => {
  try {
    const indicator = await db("indicators").where({ id: req.params.id }).first(); // ตัวชี้วัดที่จะแนบไฟล์แม่แบบให้
    if (!indicator) return res.status(404).json({ success: false, message: "ไม่พบตัวชี้วัดนี้" });
    if (!req.file) return res.status(400).json({ success: false, message: "ไม่มีไฟล์ที่อัปโหลด" }); // req.file = ไฟล์ที่ multer แกะให้แล้ว (ตัวชี้วัดนี้รับได้แค่ 1 ไฟล์)

    // ลบไฟล์เดิมถ้ามี ก่อนบันทึกไฟล์ใหม่แทน
    if (indicator.template_path) {
      const old = path.join(__dirname, "..", indicator.template_path.replace(/^\/uploads\//, "uploads/")); // ที่อยู่ไฟล์แม่แบบเดิมบนดิสก์ (แปลง path เว็บ "/uploads/x" กลับเป็น path ระบบไฟล์จริง)
      fs.existsSync(old) && fs.unlinkSync(old); // ลบไฟล์เดิมทิ้งถ้ายังมีอยู่จริง (กันไฟล์เก่าค้างเป็นขยะบนดิสก์)
    }

    await db("indicators").where({ id: req.params.id }).update({
      template_name: req.file.originalname,
      template_path: "/uploads/" + req.file.filename,
    });
    res.json({ success: true, data: await db("indicators").where({ id: req.params.id }).first() });
  } catch (e) { next(e); }
};

// DELETE /api/indicators/:id/template  (บทบาท admin) — ลบไฟล์แม่แบบออก
exports.remove = async (req, res, next) => {
  try {
    const indicator = await db("indicators").where({ id: req.params.id }).first(); // ตัวชี้วัดที่จะลบไฟล์แม่แบบออก
    if (!indicator) return res.status(404).json({ success: false, message: "ไม่พบตัวชี้วัดนี้" });

    if (indicator.template_path) {
      const p = path.join(__dirname, "..", indicator.template_path.replace(/^\/uploads\//, "uploads/")); // ที่อยู่ไฟล์จริงบนดิสก์
      fs.existsSync(p) && fs.unlinkSync(p); // ลบไฟล์จริงออกจากดิสก์ด้วย ไม่ใช่แค่ล้างค่าใน DB
    }
    await db("indicators").where({ id: req.params.id }).update({ template_name: null, template_path: null });
    res.json({ success: true });
  } catch (e) { next(e); }
};
