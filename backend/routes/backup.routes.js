const router = require("express").Router(); // router ย่อยของ resource นี้ (ถูกเอาไป app.use("/api/xxx", router) ใน app.js)
const auth = require("../middlewares/auth"); // ด่านตรวจ JWT+บทบาท ใช้เป็น middleware หน้าแต่ละ route
const c = require("../controllers/backup.controller"); // ฟังก์ชันจริงที่แต่ละ route จะเรียกใช้

router.post("/backup", auth("admin"), c.create);        // POST /api/backup
router.get("/backups", auth("admin"), c.list);          // GET /api/backups
router.post("/restore/:file", auth("admin"), c.restore); // POST /api/restore/:file
router.delete("/backups/:file", auth("admin"), c.remove); // DELETE /api/backups/:file

module.exports = router;
