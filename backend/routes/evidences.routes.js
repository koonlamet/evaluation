const router = require("express").Router(); // router ย่อยของ resource นี้ (ถูกเอาไป app.use("/api/xxx", router) ใน app.js)
const auth = require("../middlewares/auth"); // ด่านตรวจ JWT+บทบาท ใช้เป็น middleware หน้าแต่ละ route
const upload = require("../middlewares/upload"); // ตัวรับไฟล์อัปโหลด (multer) ใช้เป็น middleware เฉพาะ route ที่รับไฟล์
const c = require("../controllers/evidences.controller"); // ฟังก์ชันจริงที่แต่ละ route จะเรียกใช้

router.get("/periods", auth("evaluatee"), c.myPeriods);            // GET /api/evidences/periods
router.get("/", auth(), c.list);                                    // GET /api/evidences
router.post("/", auth("evaluatee"), c.save);                       // POST /api/evidences
router.post("/:id/files", auth("evaluatee"), upload.array("files", 5), c.uploadFiles); // อัปโหลดหลายไฟล์
router.delete("/files/:fileId", auth("evaluatee"), c.removeFile);  // ลบไฟล์แนบ

module.exports = router;
