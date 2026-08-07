const router = require("express").Router(); // router ย่อยของ resource นี้ (ถูกเอาไป app.use("/api/xxx", router) ใน app.js)
const auth = require("../middlewares/auth"); // ด่านตรวจ JWT+บทบาท ใช้เป็น middleware หน้าแต่ละ route
const c = require("../controllers/reviews.controller"); // ฟังก์ชันจริงที่แต่ละ route จะเรียกใช้

// เส้นทางแบบตายตัวต้องมาก่อน /:assignmentId
router.get("/assignments", auth("evaluator"), c.myAssignments); // งานที่ต้องประเมิน
router.get("/feedback", auth("evaluatee"), c.feedback);         // ผู้รับประเมินดูความเห็นกรรมการ
router.post("/", auth("evaluator"), c.save);                    // ให้คะแนนทีละตัวชี้วัด
router.post("/:assignmentId/submit", auth("evaluator"), c.submit); // ยืนยันส่ง + ลายเซ็น
router.get("/:assignmentId", auth("evaluator"), c.detail);      // รายละเอียดใบประเมิน

module.exports = router;
