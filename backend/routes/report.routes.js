const router = require("express").Router(); // router ย่อยของ resource นี้ (ถูกเอาไป app.use("/api/xxx", router) ใน app.js)
const auth = require("../middlewares/auth"); // ด่านตรวจ JWT+บทบาท ใช้เป็น middleware หน้าแต่ละ route
const c = require("../controllers/report.controller"); // ฟังก์ชันจริงที่แต่ละ route จะเรียกใช้

router.get("/stats", auth("admin"), c.stats);              // GET /api/stats (dashboard)
router.get("/summary/:evaluateeId", auth(), c.summary);    // GET /api/summary/:id

module.exports = router;
