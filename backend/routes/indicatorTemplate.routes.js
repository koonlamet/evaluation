const router = require("express").Router(); // router ย่อยของ resource นี้ (ถูกเอาไป app.use("/api/xxx", router) ใน app.js)
const auth = require("../middlewares/auth"); // ด่านตรวจ JWT+บทบาท ใช้เป็น middleware หน้าแต่ละ route
const upload = require("../middlewares/upload"); // ตัวรับไฟล์อัปโหลด (multer) ใช้เป็น middleware เฉพาะ route ที่รับไฟล์
const c = require("../controllers/indicatorTemplate.controller"); // ฟังก์ชันจริงที่แต่ละ route จะเรียกใช้

router.post("/:id/template", auth("admin"), upload.single("file"), c.upload); // อัปโหลดไฟล์แม่แบบ
router.delete("/:id/template", auth("admin"), c.remove);                     // ลบไฟล์แม่แบบ

module.exports = router;
