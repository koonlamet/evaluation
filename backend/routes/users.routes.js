const router = require("express").Router(); // router ย่อยของ resource นี้ (ถูกเอาไป app.use("/api/xxx", router) ใน app.js)
const auth = require("../middlewares/auth"); // ด่านตรวจ JWT+บทบาท ใช้เป็น middleware หน้าแต่ละ route
const c = require("../controllers/users.controller"); // ฟังก์ชันจริงที่แต่ละ route จะเรียกใช้

router.get("/me", auth(), c.me);       // GET /api/users/me (5.2.2 ดูข้อมูลตนเอง) — ต้องมาก่อน "/:id"
router.put("/me", auth(), c.updateMe);                  // PUT /api/users/me (5.2.2 แก้ข้อมูลตนเอง)
router.put("/me/password", auth(), c.changePassword);   // PUT /api/users/me/password (เปลี่ยนรหัสผ่านตนเอง ทุกบทบาท)

router.get("/", auth("admin", "evaluator"), c.list); // GET /api/users
router.post("/", auth("admin"), c.create);           // POST /api/users
router.put("/:id", auth("admin"), c.update);         // PUT /api/users/:id
router.delete("/:id", auth("admin"), c.remove);      // DELETE /api/users/:id

module.exports = router;
