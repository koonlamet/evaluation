// โรงงานสร้าง CRUD มาตรฐาน 1 ตาราง — เขียนครั้งเดียว ใช้ซ้ำได้ทุก resource
// (topics, indicators, periods, assignments ใช้ตัวนี้หมด → โค้ดสั้นมาก)
const db = require("../db");

// เก็บเฉพาะฟิลด์ที่อนุญาต (กันแอบยัดคอลัมน์แปลกปลอม)
const pick = (obj = {}, keys) => // obj = req.body ที่ส่งมา, keys = ชื่อฟิลด์ที่อนุญาต (fields ของแต่ละตาราง) — คืน object ใหม่ที่มีแค่ฟิลด์ที่อนุญาตเท่านั้น
  keys.reduce((o, k) => (obj[k] !== undefined ? ((o[k] = obj[k]), o) : o), {});

// พารามิเตอร์ของโรงงาน: table = ชื่อตาราง, fields = คอลัมน์ที่แก้ไขได้ผ่าน API นี้,
// searchable = คอลัมน์ที่ค้นหาได้, sortable = คอลัมน์ที่เรียงได้ (default แค่ id), filterable = คอลัมน์ที่กรองตรงๆ ผ่าน query string ได้
module.exports = ({ table, fields, searchable = [], sortable = ["id"], filterable = [] }) => ({
  // GET /  → รองรับ v-data-table-server: page, itemsPerPage, search, sortBy, sortDesc
  // เก็บเกณฑ์ 8.1 (pagination), 8.6 (global search ข้ามคอลัมน์ + sort)
  // filterable: คอลัมน์ที่ยอมให้กรองตรง ๆ ผ่าน query string เช่น ?period_id=1
  async list(req, res, next) {
    try {
      const page = Number(req.query.page) || 1;        // หน้าที่ต้องการ
      const per = Number(req.query.itemsPerPage) || 10; // จำนวนแถวต่อหน้า
      const search = String(req.query.search || "").trim(); // คำค้นหา
      const sortBy = sortable.includes(req.query.sortBy) ? req.query.sortBy : "id"; // คอลัมน์ที่จะเรียง (กันยิงคอลัมน์ที่ไม่อยู่ใน sortable มา)
      const dir = req.query.sortDesc === "false" ? "asc" : "desc"; // ทิศทางเรียง

      const q = db(table); // query builder ของตารางนี้ ต่อเงื่อนไขทีละอันก่อนค่อยยิงจริง
      if (search && searchable.length)
        q.where((b) => searchable.forEach((c) => b.orWhere(c, "like", `%${search}%`))); // ค้นแบบ OR ข้ามทุกคอลัมน์ใน searchable
      filterable.forEach((col) => { if (req.query[col] != null) q.where(col, req.query[col]); }); // กรองตรงๆ ตามคอลัมน์ที่อนุญาต (เช่น ?period_id=1)

      const [{ total }] = await q.clone().count({ total: "*" }); // จำนวนแถวทั้งหมดที่ตรงเงื่อนไข — clone() กันไม่ให้ .count() กระทบ query จริงด้านล่าง
      const items = await q.clone().orderBy(sortBy, dir).limit(per).offset((page - 1) * per); // แถวข้อมูลจริงเฉพาะหน้านี้
      res.json({ success: true, items, total: Number(total), page, itemsPerPage: per });
    } catch (e) { next(e); }
  },

  // GET /:id
  async get(req, res, next) {
    try {
      const row = await db(table).where({ id: req.params.id }).first(); // แถวเดียวที่ id ตรงกับที่ระบุใน URL
      if (!row) return res.status(404).json({ success: false, message: "ไม่พบข้อมูล" });
      res.json({ success: true, data: row });
    } catch (e) { next(e); }
  },

  // POST /
  async create(req, res, next) {
    try {
      const [id] = await db(table).insert(pick(req.body, fields)); // id ที่ MySQL สร้างให้แถวใหม่ (pick กรองเหลือแค่คอลัมน์ที่อนุญาต)
      res.status(201).json({ success: true, data: await db(table).where({ id }).first() });
    } catch (e) { next(e); }
  },

  // PUT /:id
  async update(req, res, next) {
    try {
      const n = await db(table).where({ id: req.params.id }).update(pick(req.body, fields)); // n = จำนวนแถวที่แก้ได้จริง (0 = ไม่พบ id นี้)
      if (!n) return res.status(404).json({ success: false, message: "ไม่พบข้อมูล" });
      res.json({ success: true, data: await db(table).where({ id: req.params.id }).first() });
    } catch (e) { next(e); }
  },

  // DELETE /:id
  async remove(req, res, next) {
    try {
      const n = await db(table).where({ id: req.params.id }).del(); // n = จำนวนแถวที่ลบได้จริง
      if (!n) return res.status(404).json({ success: false, message: "ไม่พบข้อมูล" });
      res.json({ success: true });
    } catch (e) { next(e); }
  },
});
