// จัดการข้อผิดพลาดรวมศูนย์ (Exception Handling) — controller เรียก next(e) มาที่นี่
module.exports = (err, req, res, next) => { // err = error ที่ถูกโยนมาจาก controller ไหนก็ได้ผ่าน next(e) หรือ throw ใน try/catch
  console.error("ERROR:", err.message);
  // อีเมล/ค่าซ้ำจาก MySQL
  if (err.code === "ER_DUP_ENTRY") // err.code นี้มาจาก MySQL โดยตรง ตอนข้อมูลชนกับ UNIQUE constraint
    return res.status(409).json({ success: false, message: "ข้อมูลซ้ำ (เช่น อีเมลนี้มีอยู่แล้ว)" });
  res.status(err.status || 500).json({ success: false, message: err.message || "เกิดข้อผิดพลาด" }); // err.status = รหัส HTTP ที่ controller ตั้งเอง (เช่น 400/404) ไม่ระบุ = ถือว่าเป็น error ไม่คาดคิด (500)
};
