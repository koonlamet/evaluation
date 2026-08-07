const router = require("express").Router(); // router ย่อยของ resource นี้ (ถูกเอาไป app.use("/api/xxx", router) ใน app.js)
const auth = require("../middlewares/auth"); // ด่านตรวจ JWT+บทบาท ใช้เป็น middleware หน้าแต่ละ route
const c = require("../controllers/tracking.controller"); // ฟังก์ชันจริงที่แต่ละ route จะเรียกใช้

router.get("/evaluators", auth("admin"), c.byEvaluator); // GET /api/tracking/evaluators
router.get("/evaluatees", auth("admin"), c.byEvaluatee); // GET /api/tracking/evaluatees

module.exports = router;
