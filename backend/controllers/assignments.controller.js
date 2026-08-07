// การมอบหมายกรรมการให้ประเมินผู้รับการประเมิน (5.1.7-5.1.9)
// ต่างจาก CRUD ทั่วไปตรงที่ join ชื่อจริงของกรรมการ/ผู้รับการประเมิน/รอบ มาแสดง (อ่านง่ายกว่าใช้ id ดิบ)
const db = require("../db");

// withNames: ต่อ query assignments เดิม (q) ให้ join ชื่อจริงจาก periods/users มาด้วย — ใช้ซ้ำใน list/create/update
const withNames = (q) =>
  q
    .join("periods as p", "p.id", "assignments.period_id")     // p = ตาราง periods เรียกสั้นๆ เอาชื่อรอบ
    .join("users as ev", "ev.id", "assignments.evaluator_id")  // ev = ผู้ใช้ที่เป็นกรรมการของแถวนี้
    .join("users as ee", "ee.id", "assignments.evaluatee_id")  // ee = ผู้ใช้ที่เป็นผู้รับการประเมินของแถวนี้
    .select(
      "assignments.*",
      "p.name_th as period_name",
      "ev.name_th as evaluator_name",
      "ee.name_th as evaluatee_name"
    );

// GET /api/assignments?page&itemsPerPage&sortBy&sortDesc&period_id
// อ่านตาราง assignments (join ชื่อจริงจาก users/periods) → หน้า "มอบหมายกรรมการ" ใน admin/setup
exports.list = async (req, res, next) => {
  try {
    const page = Number(req.query.page) || 1;        // หน้าที่ต้องการ
    const per = Number(req.query.itemsPerPage) || 10; // จำนวนแถวต่อหน้า
    const sortable = ["id", "period_id"];              // คอลัมน์ที่ยอมให้เรียงได้ (กันยิงคอลัมน์แปลกปลอมมา)
    const sortBy = sortable.includes(req.query.sortBy) ? req.query.sortBy : "id";
    const dir = req.query.sortDesc === "true" ? "desc" : "asc"; // ทิศทางเรียง

    const byPeriod = (q) => (req.query.period_id ? q.where("assignments.period_id", req.query.period_id) : q); // ต่อเงื่อนไขกรองรอบ ถ้ามีการระบุ period_id มา

    const [{ total }] = await byPeriod(db("assignments")).count({ total: "*" }); // จำนวนแถวทั้งหมดที่ตรงเงื่อนไข (สำหรับคำนวณจำนวนหน้า)
    const items = await byPeriod(withNames(db("assignments")))
      .orderBy(`assignments.${sortBy}`, dir)
      .limit(per)
      .offset((page - 1) * per);

    res.json({ success: true, items, total: Number(total), page, itemsPerPage: per });
  } catch (e) { next(e); }
};

// POST /api/assignments  { period_id, evaluator_id, evaluatee_id, committee_role }
// สร้างใบมอบหมาย 1 แถวลง assignments (unique ต่อ รอบ+กรรมการ+ผู้รับ — ซ้ำจะ 409 จาก error middleware)
exports.create = async (req, res, next) => {
  try {
    const { period_id, evaluator_id, evaluatee_id, committee_role = "member" } = req.body || {}; // ข้อมูลใบมอบหมายใหม่จากฟอร์ม (ไม่ระบุบทบาท → เป็นกรรมการร่วมโดย default)
    if (!period_id || !evaluator_id || !evaluatee_id)
      return res.status(400).json({ success: false, message: "กรอกรอบ/กรรมการ/ผู้รับการประเมินให้ครบ" });

    const [id] = await db("assignments").insert({ period_id, evaluator_id, evaluatee_id, committee_role }); // id ที่ MySQL สร้างให้แถวใหม่
    res.status(201).json({ success: true, data: await withNames(db("assignments")).where("assignments.id", id).first() });
  } catch (e) { next(e); }
};

// PUT /api/assignments/:id — แก้ไขการมอบหมาย (เปลี่ยนกรรมการ/บทบาท) เฉพาะฟิลด์ที่ส่งมา
exports.update = async (req, res, next) => {
  try {
    const { period_id, evaluator_id, evaluatee_id, committee_role } = req.body || {}; // เฉพาะฟิลด์ที่ส่งมาแก้ (ที่ไม่ส่ง = ไม่แตะ)
    const payload = {}; // ก่อร่างเฉพาะคอลัมน์ที่ต้อง update จริง
    if (period_id != null) payload.period_id = period_id;
    if (evaluator_id != null) payload.evaluator_id = evaluator_id;
    if (evaluatee_id != null) payload.evaluatee_id = evaluatee_id;
    if (committee_role != null) payload.committee_role = committee_role;

    const n = await db("assignments").where({ id: req.params.id }).update(payload); // n = จำนวนแถวที่แก้ได้จริง (0 = ไม่พบ id นี้)
    if (!n) return res.status(404).json({ success: false, message: "ไม่พบข้อมูล" });
    res.json({ success: true, data: await withNames(db("assignments")).where("assignments.id", req.params.id).first() });
  } catch (e) { next(e); }
};

// DELETE /api/assignments/:id — ถอนการมอบหมาย (คะแนน reviews ที่ผูกอยู่ถูกลบตาม FK cascade)
exports.remove = async (req, res, next) => {
  try {
    const n = await db("assignments").where({ id: req.params.id }).del(); // n = จำนวนแถวที่ลบได้จริง
    if (!n) return res.status(404).json({ success: false, message: "ไม่พบข้อมูล" });
    res.json({ success: true });
  } catch (e) { next(e); }
};

// POST /api/assignments/:id/unlock  (admin) — ปลดล็อกใบประเมินที่กรรมการส่งไปแล้ว ให้แก้ไขคะแนน+เซ็นใหม่ได้
// (กรณีกรรมการกรอกผิดแล้วมาแจ้งขอแก้ — คะแนนเดิมยังอยู่ให้แก้ต่อ ไม่ต้องกรอกใหม่หมด แต่ต้องเซ็นรับรองใหม่เพราะคะแนนเปลี่ยน)
exports.unlock = async (req, res, next) => {
  try {
    const n = await db("assignments") // n = จำนวนแถวที่ปลดล็อกได้จริง (0 = ไม่พบ หรือใบนี้ยังไม่ได้ส่งผลอยู่แล้ว)
      .where({ id: req.params.id, status: "submitted" }) // ปลดล็อกได้เฉพาะใบที่ status = submitted เท่านั้น กัน unlock ซ้ำ
      .update({
        status: "pending",       // ย้อนสถานะกลับเป็นรอประเมิน ให้กรรมการแก้ไขได้อีกครั้ง
        signature_path: null,    // ล้างลายเซ็นเดิม (คะแนนเปลี่ยนได้ ต้องเซ็นรับรองชุดใหม่)
        submitted_at: null,      // ล้างเวลาที่เคยส่ง
        unlocked_at: db.fn.now(), // เวลาปลดล็อกล่าสุด (db.fn.now() = เวลาปัจจุบันฝั่ง MySQL)
        unlocked_by: req.user.id, // id ของ admin ที่กดปลดล็อก (มาจาก JWT)
      });
    if (!n) return res.status(404).json({ success: false, message: "ไม่พบใบประเมินนี้ หรือยังไม่ได้ส่งผล" });
    res.json({ success: true, message: "ปลดล็อกแล้ว กรรมการแก้ไขคะแนนและเซ็นส่งใหม่ได้" });
  } catch (e) { next(e); }
};
