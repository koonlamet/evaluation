// สร้าง router มาตรฐาน (list/get/create/update/remove) จาก controller ที่ได้จาก crud()
// read  = บทบาทที่อ่านได้, write = บทบาทที่เพิ่ม/แก้/ลบได้
const { Router } = require("express");
const auth = require("../middlewares/auth");

module.exports = (ctrl, { read = [], write = ["admin"] } = {}) => { // ctrl = object ฟังก์ชัน {list,get,create,update,remove} จาก crud(), read/write = บทบาทที่อนุญาต
  const r = Router(); // r = router ย่อยของตารางนี้ (จะถูกเอาไป app.use("/api/xxx", r) ใน app.js)
  r.get("/", auth(...read), ctrl.list);       // GET /            → ดูรายการ (แบ่งหน้า/ค้นหา/เรียง)
  r.get("/:id", auth(...read), ctrl.get);     // GET /:id         → ดูรายตัว
  r.post("/", auth(...write), ctrl.create);   // POST /           → เพิ่มใหม่
  r.put("/:id", auth(...write), ctrl.update); // PUT /:id         → แก้ไข
  r.delete("/:id", auth(...write), ctrl.remove); // DELETE /:id   → ลบ
  return r;
};
