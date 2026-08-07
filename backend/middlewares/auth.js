// ตรวจสอบสิทธิ์ด้วย JWT + จำกัดบทบาท (RBAC)
// ใช้:  auth()            = ต้องล็อกอิน (บทบาทใดก็ได้)
//       auth('admin')     = ต้องเป็น admin เท่านั้น
//       auth('a','b')     = เป็น a หรือ b
const jwt = require("jsonwebtoken");

module.exports = (...roles) => (req, res, next) => { // roles = บทบาทที่อนุญาต ("admin","evaluator",...) เว้นว่าง = แค่ต้อง login
  try {
    const token = (req.headers.authorization || "").replace("Bearer ", ""); // ดึง JWT ออกจาก header "Authorization: Bearer xxxx" (ตัดคำว่า "Bearer " ทิ้ง)
    if (!token)
      return res.status(401).json({ success: false, message: "กรุณาเข้าสู่ระบบ" });

    const user = jwt.verify(token, process.env.JWT_SECRET); // ถอดรหัส token กลับเป็นข้อมูลผู้ใช้ { id, role, name } — ถ้าปลอม/หมดอายุจะ throw
    if (roles.length && !roles.includes(user.role)) // ถ้ามีการระบุ roles ไว้ แต่บทบาทของผู้ใช้ไม่อยู่ในรายการนั้น
      return res.status(403).json({ success: false, message: "ไม่มีสิทธิ์เข้าถึง" });

    req.user = user; // { id, role, name } แปะไว้ที่ req ให้ controller ปลายทางอ่านต่อได้ (เช่น req.user.id)
    next(); // ผ่านด่านแล้ว ส่งต่อไป route/controller ถัดไป
  } catch {
    res.status(401).json({ success: false, message: "โทเค็นไม่ถูกต้องหรือหมดอายุ" });
  }
};
