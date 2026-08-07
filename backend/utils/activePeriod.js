// หาช่วงเวลาประเมินที่ควรใช้ เมื่อไม่ได้ระบุ period_id มาชัดเจน
// ใช้รอบที่เปิดใช้งานอยู่ (is_active=1) ก่อน ถ้าไม่มีให้ใช้รอบล่าสุด
const db = require("../db");

module.exports = async function resolvePeriodId(explicit) { // explicit = period_id ที่ผู้เรียกระบุมาชัดเจน (เช่นจาก query string) ถ้ามี
  if (explicit) return explicit; // ระบุมาแล้ว ใช้ตามนั้นเลย ไม่ต้องเดา
  const active = await db("periods").where({ is_active: 1 }).orderBy("id", "desc").first(); // ไม่ระบุมา → หารอบที่เปิดใช้งานอยู่ล่าสุด (ถ้ามีหลายรอบเปิดพร้อมกัน เอาที่สร้างทีหลังสุด)
  if (active) return active.id;
  const latest = await db("periods").orderBy("id", "desc").first(); // ไม่มีรอบไหนเปิดอยู่เลย → fallback ไปใช้รอบล่าสุดที่มีในระบบ (เผื่อ demo/ทดสอบตอนยังไม่เปิดรอบไหน)
  return latest ? latest.id : null;
};
