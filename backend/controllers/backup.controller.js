// สำรอง/กู้คืนข้อมูล (โจทย์พิเศษ 8.4) — dump ทุกตารางเป็น JSON + สำเนาโฟลเดอร์ไฟล์แนบ
const db = require("../db");
const fs = require("fs");
const path = require("path");

const DIR = path.join(__dirname, "..", "backups"); // โฟลเดอร์เก็บไฟล์สำรอง (backend/backups/)
const UPLOADS = path.join(__dirname, "..", "uploads"); // โฟลเดอร์ไฟล์แนบจริงของระบบ (ต้นทาง/ปลายทางตอนสำรอง/กู้คืน)
fs.mkdirSync(DIR, { recursive: true });

// ลำดับตารางแบบปลอดภัยต่อ FK (แม่ก่อนลูก)
const TABLES = ["users", "periods", "topics", "indicators", "assignments", "evidences", "evidence_files", "reviews"]; // ทุกตารางในระบบ เรียงจากตารางแม่ไปตารางลูกตามลำดับ FK

// หา timestamp จากชื่อไฟล์ backup_<stamp>.json เพื่อไปหาโฟลเดอร์ไฟล์แนบคู่กัน files_<stamp>
const stampOf = (file) => file.replace(/^backup_/, "").replace(/\.json$/, ""); // แกะเวลาออกจากชื่อไฟล์ เช่น "backup_2026-01-01.json" → "2026-01-01"

function folderSize(dir) { // dir = โฟลเดอร์ที่จะรวมขนาด, คืนค่าขนาดรวมเป็น byte ของทุกไฟล์ข้างในชั้นบนสุด
  if (!fs.existsSync(dir)) return 0;
  return fs.readdirSync(dir).reduce((sum, f) => sum + fs.statSync(path.join(dir, f)).size, 0);
}

// POST /api/backup → สร้างไฟล์สำรอง 1 snapshot
exports.create = async (req, res, next) => {
  try {
    const data = {}; // data = ทุกแถวของทุกตาราง เก็บเป็น { ชื่อตาราง: [แถว, แถว, ...] }
    for (const t of TABLES) data[t] = await db(t).select("*");

    const stamp = new Date().toISOString().replace(/[:.]/g, "-"); // เวลาปัจจุบันแปลงเป็นข้อความที่ใช้เป็นชื่อไฟล์ได้ (ตัด : กับ . ที่ห้ามอยู่ในชื่อไฟล์ Windows)
    const file = `backup_${stamp}.json`; // ชื่อไฟล์สำรองที่จะสร้าง
    fs.writeFileSync(path.join(DIR, file), JSON.stringify({ createdAt: new Date(), data }, null, 2));

    // สำเนาไฟล์แนบทั้งโฟลเดอร์
    if (fs.existsSync(UPLOADS))
      fs.cpSync(UPLOADS, path.join(DIR, `files_${stamp}`), { recursive: true });

    res.json({ success: true, message: "สำรองข้อมูลสำเร็จ", file });
  } catch (e) { next(e); }
};

// GET /api/backups → รายการ snapshot ให้เลือกกู้คืน (บอกด้วยว่า snapshot ไหนมีไฟล์แนบสำรองคู่กันบ้าง)
exports.list = async (req, res, next) => {
  try {
    const files = fs.readdirSync(DIR) // files = รายการ snapshot ทั้งหมด (ใหม่สุดขึ้นก่อน) พร้อมขนาดไฟล์และว่ามีไฟล์แนบสำรองคู่กันไหม
      .filter((f) => f.endsWith(".json"))
      .map((f) => {
        const filesDir = path.join(DIR, `files_${stampOf(f)}`); // โฟลเดอร์ไฟล์แนบที่ควรคู่กับ snapshot นี้ (ถ้ามี)
        const hasFiles = fs.existsSync(filesDir); // true ถ้า snapshot นี้เคยสำรองไฟล์แนบไว้ด้วย
        return {
          file: f,
          size: fs.statSync(path.join(DIR, f)).size,
          hasFiles,
          filesSize: hasFiles ? folderSize(filesDir) : 0,
        };
      })
      .reverse();
    res.json({ success: true, items: files });
  } catch (e) { next(e); }
};

// POST /api/restore/:file → กู้คืนข้อมูลในฐานข้อมูล + ไฟล์แนบที่สำรองไว้คู่กัน (ถ้ามี) จาก snapshot ที่เลือก
exports.restore = async (req, res, next) => {
  try {
    const file = path.basename(req.params.file); // basename กัน path traversal (เช่นกันไม่ให้ส่ง "../../etc/passwd" มาอ่านไฟล์นอกโฟลเดอร์นี้)
    const p = path.join(DIR, file); // ที่อยู่เต็มของไฟล์ snapshot ที่จะกู้คืน
    if (!fs.existsSync(p)) return res.status(404).json({ success: false, message: "ไม่พบไฟล์สำรอง" });

    const { data } = JSON.parse(fs.readFileSync(p, "utf8")); // data = ข้อมูลทุกตารางที่เคยสำรองไว้ (โครงสร้างเดียวกับตอน create)
    await db.transaction(async (trx) => { // trx = การทำงานทั้งหมดในนี้ต้องสำเร็จพร้อมกันทุกตาราง ถ้าตัวใดพังจะย้อนกลับทั้งหมด (all-or-nothing)
      await trx.raw("SET FOREIGN_KEY_CHECKS=0");
      for (const t of TABLES) {
        await trx(t).del();
        if (data[t]?.length) await trx(t).insert(data[t]);
      }
      await trx.raw("SET FOREIGN_KEY_CHECKS=1");
    });

    // กู้คืนไฟล์แนบคู่กัน (ถ้า snapshot นี้มีสำรองไฟล์ไว้) — แทนที่ uploads/ ปัจจุบันทั้งหมดให้ตรงกับจุดเวลานั้น
    const filesDir = path.join(DIR, `files_${stampOf(file)}`); // โฟลเดอร์ไฟล์แนบที่สำรองไว้คู่กับ snapshot นี้ (ถ้ามี)
    let filesRestored = false; // ใช้บอกข้อความตอบกลับว่ากู้คืนไฟล์แนบด้วยไหม
    if (fs.existsSync(filesDir)) {
      // ล้างเฉพาะ "เนื้อหาข้างใน" uploads/ ไม่ลบตัวโฟลเดอร์เอง เพราะเป็น mount point ของ docker volume (ลบทั้งโฟลเดอร์แล้วจะ EBUSY)
      for (const f of fs.readdirSync(UPLOADS)) fs.rmSync(path.join(UPLOADS, f), { recursive: true, force: true });
      fs.cpSync(filesDir, UPLOADS, { recursive: true });
      filesRestored = true;
    }

    res.json({
      success: true,
      message: filesRestored ? "กู้คืนข้อมูลและไฟล์แนบสำเร็จ" : "กู้คืนข้อมูลสำเร็จ (snapshot นี้ไม่มีไฟล์แนบสำรองไว้)",
    });
  } catch (e) { next(e); }
};

// DELETE /api/backups/:file → ลบไฟล์สำรอง (json) + โฟลเดอร์ไฟล์แนบคู่กัน (ถ้ามี)
exports.remove = async (req, res, next) => {
  try {
    const file = path.basename(req.params.file); // basename กัน path traversal
    const p = path.join(DIR, file); // ที่อยู่เต็มของไฟล์ snapshot ที่จะลบ
    if (!fs.existsSync(p)) return res.status(404).json({ success: false, message: "ไม่พบไฟล์สำรอง" });

    fs.rmSync(p);
    const filesDir = path.join(DIR, `files_${stampOf(file)}`); // โฟลเดอร์ไฟล์แนบคู่กัน (ถ้ามี) ต้องลบตามไปด้วย ไม่งั้นค้างเป็นขยะ
    if (fs.existsSync(filesDir)) fs.rmSync(filesDir, { recursive: true, force: true });

    res.json({ success: true, message: "ลบไฟล์สำรองแล้ว" });
  } catch (e) { next(e); }
};
