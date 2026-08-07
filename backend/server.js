require("dotenv").config(); // โหลดค่าตั้งค่าจากไฟล์ .env เข้า process.env (ต้องเรียกก่อนใช้ process.env ตัวไหนเลย)
const app = require("./app"); // แอป Express ที่ประกอบ middleware/route ไว้ครบแล้ว (app.js)
const PORT = process.env.PORT || 7000; // พอร์ตที่จะเปิดฟัง (ไม่ตั้งค่าไว้ = ใช้ 7000)
app.listen(PORT, () => console.log(`PES API running on http://localhost:${PORT}`));
