// ตรวจจับ/ตัดอักขระพิเศษที่ไม่ควรอยู่ในข้อมูลข้อความทั่วไป กัน stored XSS (โจทย์พิเศษ 8.2)
// - ตัดแท็ก HTML/สคริปต์ทิ้ง (เช่น <script>...) ออกจากทุก field ที่เป็น string ใน req.body
// - ยกเว้นฟิลด์ที่ต้องคงค่าดิบไว้เสมอ (รหัสผ่าน, URL, ลายเซ็น base64, token)
// - SQL Injection ป้องกันอยู่แล้วโดย knex query builder (parameterized query ทุกจุด ไม่มี raw string concat)
const validator = require("validator");
const SKIP_KEYS = new Set(["password", "email", "url", "signature", "accessToken", "token", "template_url"]); // ชื่อฟิลด์ที่ห้ามแตะ ต้องคงค่าดิบไว้เสมอ (เช่น รหัสผ่านมีอักขระพิเศษได้ ไม่ใช่ HTML)

function clean(v) { // v = ค่า string 1 ค่าที่จะทำความสะอาด, คืนค่าที่ตัดแท็ก HTML + อักขระควบคุมแปลกปลอมออกแล้ว
  return validator.stripLow(v.replace(/<[^>]*>/g, ""), true).trim(); // ตัดแท็ก HTML + control character แปลกปลอม (เก็บ \n ไว้)
}

function walk(obj) { // obj = req.body (หรือ object ย่อยข้างใน) — วนทำความสะอาดทุก field แบบ recursive จนสุดทุกชั้น
  for (const [k, v] of Object.entries(obj)) { // k = ชื่อฟิลด์, v = ค่าของฟิลด์นั้น
    if (SKIP_KEYS.has(k)) continue; // ฟิลด์ที่อยู่ใน SKIP_KEYS ข้ามไปเลย ไม่แตะ
    if (typeof v === "string") obj[k] = clean(v); // เป็นข้อความ → ทำความสะอาดแล้วเขียนทับ
    else if (v && typeof v === "object") walk(v); // เป็น object/array ซ้อนอยู่ข้างใน → ไล่ลงไปทำความสะอาดต่อ
  }
  return obj;
}

module.exports = (req, res, next) => {
  if (req.body && typeof req.body === "object") walk(req.body);
  next();
};
