const router = require("express").Router(); // router ย่อยของ resource นี้ (ถูกเอาไป app.use("/api/xxx", router) ใน app.js)
const auth = require("../middlewares/auth"); // ด่านตรวจ JWT+บทบาท ใช้เป็น middleware หน้าแต่ละ route
const c = require("../controllers/assignments.controller"); // ฟังก์ชันจริงที่แต่ละ route จะเรียกใช้

router.get("/", auth("admin", "evaluator"), c.list); // GET /api/assignments (พร้อมชื่อจริง)
router.post("/", auth("admin"), c.create);
router.put("/:id", auth("admin"), c.update);
router.delete("/:id", auth("admin"), c.remove);
router.post("/:id/unlock", auth("admin"), c.unlock); // ปลดล็อกใบประเมินที่ส่งแล้ว ให้กรรมการแก้ไขได้อีกครั้ง

module.exports = router;
