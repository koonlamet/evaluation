const router = require("express").Router(); // router ย่อยของ resource นี้ (ถูกเอาไป app.use("/api/xxx", router) ใน app.js)
const c = require("../controllers/auth.controller"); // ฟังก์ชันจริงที่แต่ละ route จะเรียกใช้

router.post("/login", c.login);                       // POST /api/auth/login
router.post("/register", c.registerRules, c.register); // POST /api/auth/register

module.exports = router;
