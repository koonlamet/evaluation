// ตรวจว่ารอบประเมินยังไม่หมดเขต (end_date >= วันนี้) ก่อนอนุญาตให้บันทึกข้อมูล/ให้คะแนน
const db = require("../db");

module.exports = async function assertPeriodOpen(periodId) { // periodId = รอบที่กำลังจะบันทึกข้อมูล/ให้คะแนน
  const p = await db("periods").where({ id: periodId }).first(); // p = แถวรอบนั้น (เอา end_date มาเทียบวันที่)
  if (!p) throw Object.assign(new Error("ไม่พบรอบการประเมิน"), { status: 404 }); // ไม่มีรอบนี้อยู่จริง → โยน error ให้ error middleware จับ (status ติดไปกับ error object)
  const today = new Date().toISOString().slice(0, 10); // วันที่ปัจจุบันรูปแบบ YYYY-MM-DD (ตัดเวลาออก เทียบแค่วัน)
  if (String(p.end_date).slice(0, 10) < today) // วันสิ้นสุดของรอบผ่านไปแล้ว → หมดเขต
    throw Object.assign(new Error(`หมดเขตการประเมินของรอบ "${p.name_th}" แล้ว (สิ้นสุด ${String(p.end_date).slice(0, 10)})`), { status: 400 });
  return p; // รอบยังเปิดอยู่ → คืนข้อมูลรอบกลับไป (ผู้เรียกใช้ต่อได้ถ้าต้องการ)
};
