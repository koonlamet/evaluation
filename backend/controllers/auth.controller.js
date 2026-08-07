// การยืนยันตัวตน: Login (ออก JWT) + Register (สมัครเป็นผู้รับการประเมิน)
const db = require("../db");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const { body, validationResult } = require("express-validator");

// pub: ฟังก์ชันแปลงแถว user จาก DB (มี password_hash ติดมาด้วย) ให้เหลือเฉพาะฟิลด์ที่ปลอดภัยจะส่งกลับให้ frontend
const pub = (u) => ({ id: u.id, name: u.name_th, email: u.email, role: u.role });

/**
 * POST /api/auth/login
 * body: { email, password }
 * 200 { success, accessToken, user } | 400 ข้อมูลไม่ครบ | 401 รหัสผิด
 */
exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body || {}; // ค่าที่ผู้ใช้กรอกในฟอร์ม login (password เป็นข้อความธรรมดา ยังไม่เข้ารหัส)
    if (!email || !password)
      return res.status(400).json({ success: false, message: "กรอกอีเมลและรหัสผ่าน" });

    const user = await db("users").where({ email }).first(); // แถว user จาก DB ถ้าไม่พบอีเมลนี้จะได้ undefined
    if (!user || !(await bcrypt.compare(password, user.password_hash)))
      return res.status(401).json({ success: false, message: "อีเมลหรือรหัสผ่านไม่ถูกต้อง" });

    // accessToken: JWT (บัตรผ่านดิจิทัล) เข้ารหัส id/role/name ไว้ข้างใน ใช้แนบไปกับทุก request หลังจากนี้แทนการ login ซ้ำ
    const accessToken = jwt.sign(
      { id: user.id, role: user.role, name: user.name_th },
      process.env.JWT_SECRET,           // กุญแจลับเซ็นรับรอง token (ตั้งไว้ใน .env)
      { expiresIn: process.env.JWT_EXPIRES || "8h" } // อายุ token ก่อนหมดอายุ ต้อง login ใหม่
    );
    res.json({ success: true, accessToken, user: pub(user) });
  } catch (e) { next(e); }
};

/**
 * POST /api/auth/register
 * body: { name_th, email, password }  → สร้างผู้ใช้บทบาท evaluatee
 * ตรวจ Validate ข้อมูลก่อนบันทึก (เกณฑ์ 7.4 / โจทย์พิเศษ 8.2)
 */
// registerRules: กฎตรวจสอบข้อมูลก่อนเข้าฟังก์ชัน register (express-validator) — วางเป็น middleware ในไฟล์ route
exports.registerRules = [
  body("name_th").trim().notEmpty().withMessage("กรุณากรอกชื่อ"),
  body("email").isEmail().withMessage("รูปแบบอีเมลไม่ถูกต้อง"),
  body("password").isLength({ min: 6 }).withMessage("รหัสผ่านอย่างน้อย 6 ตัวอักษร"),

];

exports.register = async (req, res, next) => {
  try {
    const errors = validationResult(req); // ผลตรวจจาก registerRules ด้านบน (รันมาก่อนแล้วโดย middleware)
    if (!errors.isEmpty())
      return res.status(400).json({ success: false, message: errors.array()[0].msg });

    const { name_th, email, password} = req.body; // ข้อมูลสมัครจากฟอร์ม (ผ่านการตรวจแล้ว)
    const password_hash = await bcrypt.hash(password, 10); // เข้ารหัสรหัสผ่านก่อนเก็บ (10 = ความหนักของการเข้ารหัส) ถอดกลับเป็นข้อความเดิมไม่ได้
    const [id] = await db("users").insert({ name_th, email, password_hash, role: "evaluatee" }); // id ที่ MySQL สร้างให้แถวใหม่ (สมัครเองได้แค่บทบาท evaluatee)
    res.status(201).json({ success: true, data: { id, name_th, email, role: "evaluatee" } });
  } catch (e) { next(e); }
};
