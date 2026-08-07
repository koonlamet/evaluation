// จัดการผู้ใช้ (งานบุคลากร) — มี pagination/search/sort ฝั่ง server + แฮชรหัสผ่าน
const db = require("../db");
const bcrypt = require("bcrypt");

const COLS = ["id", "name_th", "email", "role", "created_at"]; // รายชื่อคอลัมน์ที่ยอมส่งออกไปนอก backend (ไม่ดึง password_hash)

/**
 * GET /api/users?page&itemsPerPage&search&sortBy&sortDesc&role
 * รองรับ v-data-table-server (เกณฑ์ 8.1 pagination, 8.6 search/sort)
 */
exports.list = async (req, res, next) => {
  try {
    const page = Number(req.query.page) || 1;              // หน้าที่ต้องการ (เริ่มที่ 1) มาจาก v-data-table-server ฝั่งหน้าเว็บ
    const per = Number(req.query.itemsPerPage) || 10;       // จำนวนแถวต่อหน้า
    const search = String(req.query.search || "").trim();   // คำค้นหา (ค้นในชื่อ/อีเมล)
    const sortBy = ["id", "name_th", "email", "role"].includes(req.query.sortBy) ? req.query.sortBy : "id"; // คอลัมน์ที่จะเรียง (กันยิงคอลัมน์แปลกปลอมมา)
    const dir = req.query.sortDesc === "false" ? "asc" : "desc"; // ทิศทางเรียง น้อย→มาก หรือ มาก→น้อย

    const q = db("users"); // query builder ของ Knex — ต่อเงื่อนไข where ทีละอันได้ก่อนค่อยยิงจริง
    if (req.query.role) q.where("role", req.query.role); // กรองเฉพาะบทบาทที่ระบุ (เช่นแท็บ "กรรมการ" ในหน้าจัดการผู้ใช้)
    if (search)
      q.where((b) =>
        b.where("name_th", "like", `%${search}%`).orWhere("email", "like", `%${search}%`)
      );

    const [{ total }] = await q.clone().count({ total: "*" }); // จำนวนแถวทั้งหมดที่ตรงเงื่อนไข (ใช้คำนวณจำนวนหน้าฝั่ง frontend) — clone() กันไม่ให้ .count() ไปกระทบ query ตัวจริงด้านล่าง
    const items = await q.clone().select(COLS).orderBy(sortBy, dir).limit(per).offset((page - 1) * per); // แถวข้อมูลจริงเฉพาะหน้านี้หน้าเดียว
    res.json({ success: true, items, total: Number(total), page, itemsPerPage: per });
  } catch (e) { next(e); }
};

// POST /api/users  { name_th, email, password, role }
exports.create = async (req, res, next) => {
  try {
    const { name_th, email, password, role = "evaluatee" } = req.body || {}; // ข้อมูลผู้ใช้ใหม่จากฟอร์ม admin (role ไม่ระบุ → ตั้งเป็นผู้รับการประเมิน)
    if (!name_th || !email || !password)
      return res.status(400).json({ success: false, message: "กรอก ชื่อ อีเมล รหัสผ่าน ให้ครบ" });
    const password_hash = await bcrypt.hash(password, 10); // เข้ารหัสก่อนเก็บเสมอ ห้ามเก็บรหัสผ่านดิบ
    const [id] = await db("users").insert({ name_th, email, password_hash, role }); // id ที่ MySQL สร้างให้แถวใหม่
    res.status(201).json({ success: true, data: await db("users").select(COLS).where({ id }).first() });
  } catch (e) { next(e); }
};

// PUT /api/users/:id  (partial update; ส่ง password มาถ้าจะเปลี่ยน)
exports.update = async (req, res, next) => {
  try {
    const { name_th, email, role, password } = req.body || {}; // เฉพาะฟิลด์ที่ admin ส่งมาแก้ (ฟิลด์ที่ไม่ส่ง = ไม่แตะ)
    const data = {}; // ก่อร่างเฉพาะคอลัมน์ที่ต้อง update จริง (ไม่ overwrite ฟิลด์ที่ผู้ใช้ไม่ได้ส่งมา)
    if (name_th != null) data.name_th = name_th;
    if (email != null) data.email = email;
    if (role != null) data.role = role;
    if (password) data.password_hash = await bcrypt.hash(password, 10); // เปลี่ยนรหัสผ่านเฉพาะตอนที่ admin กรอกรหัสใหม่มา (เว้นว่าง = ไม่เปลี่ยน)

    const n = await db("users").where({ id: req.params.id }).update(data); // n = จำนวนแถวที่แก้ได้จริง (0 = ไม่พบ id นี้)
    if (!n) return res.status(404).json({ success: false, message: "ไม่พบผู้ใช้" });
    res.json({ success: true, data: await db("users").select(COLS).where({ id: req.params.id }).first() });
  } catch (e) { next(e); }
};

// GET /api/users/me  (ผู้ใช้ที่ล็อกอินอยู่ดูข้อมูลตนเอง — 5.2.2)
exports.me = async (req, res, next) => {
  try {
    res.json({ success: true, data: await db("users").select(COLS).where({ id: req.user.id }).first() });
  } catch (e) { next(e); }
};

// PUT /api/users/me  (แก้ข้อมูลส่วนตัวของตนเอง — ชื่อเท่านั้น ไม่รวม role/email/รหัสผ่าน)
// email เป็น username สำหรับ login แก้เองไม่ได้ (กัน session ที่หลุดไปอยู่มือคนอื่นยึดบัญชีด้วยการเปลี่ยนอีเมล)
// ต้องให้ admin แก้ผ่าน PUT /api/users/:id เท่านั้น — เปลี่ยนรหัสผ่านแยกไปที่ changePassword ด้านล่าง
exports.updateMe = async (req, res, next) => {
  try {
    const { name_th } = req.body || {}; // ชื่อใหม่จากฟอร์ม "บัญชีผู้ใช้" (ไม่รับ email/role/password ที่นี่)
    const data = {}; // ก่อร่างเฉพาะคอลัมน์ที่ต้อง update จริง
    if (name_th != null) data.name_th = name_th;

    if (Object.keys(data).length) await db("users").where({ id: req.user.id }).update(data); // req.user.id มาจาก JWT ที่ auth middleware ถอดรหัสไว้ (แก้ได้แค่ของตัวเองเท่านั้น)
    res.json({ success: true, data: await db("users").select(COLS).where({ id: req.user.id }).first() });
  } catch (e) { next(e); }
};

// PUT /api/users/me/password  { current_password, new_password }
// ทุกบทบาท (admin/evaluator/evaluatee) เปลี่ยนรหัสผ่านตนเองได้ ต้องยืนยันรหัสผ่านเดิมถูกต้องก่อนเสมอ
// กันกรณี session ค้างไว้ที่เครื่องแล้วมีคนอื่นมาเปลี่ยนรหัสผ่านแทนโดยไม่รู้รหัสเดิม
exports.changePassword = async (req, res, next) => {
  try {
    const { current_password, new_password } = req.body || {}; // รหัสผ่านเดิม (ไว้ยืนยันตัวตน) และรหัสผ่านใหม่ที่ต้องการตั้ง
    if (!current_password || !new_password)
      return res.status(400).json({ success: false, message: "กรอกรหัสผ่านเดิมและรหัสผ่านใหม่ให้ครบ" });
    if (String(new_password).length < 6)
      return res.status(400).json({ success: false, message: "รหัสผ่านใหม่ต้องมีอย่างน้อย 6 ตัวอักษร" });

    const user = await db("users").where({ id: req.user.id }).first(); // แถวผู้ใช้ปัจจุบัน (เอา password_hash เดิมมาเทียบ)
    const ok = await bcrypt.compare(current_password, user.password_hash); // true ถ้ารหัสผ่านเดิมที่กรอกตรงกับ hash ที่เก็บไว้
    if (!ok) return res.status(400).json({ success: false, message: "รหัสผ่านเดิมไม่ถูกต้อง" });

    await db("users").where({ id: req.user.id }).update({ password_hash: await bcrypt.hash(new_password, 10) }); // เข้ารหัสรหัสผ่านใหม่ก่อนบันทึกทับ
    res.json({ success: true, message: "เปลี่ยนรหัสผ่านสำเร็จ" });
  } catch (e) { next(e); }
};

// DELETE /api/users/:id
exports.remove = async (req, res, next) => {
  try {
    const n = await db("users").where({ id: req.params.id }).del(); // n = จำนวนแถวที่ลบได้จริง (0 = ไม่พบ id นี้)
    if (!n) return res.status(404).json({ success: false, message: "ไม่พบผู้ใช้" });
    res.json({ success: true });
  } catch (e) { next(e); }
};
