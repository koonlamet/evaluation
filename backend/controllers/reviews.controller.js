// การให้คะแนนของกรรมการผู้ประเมิน
const db = require("../db");
const fs = require("fs");
const path = require("path");
const assertPeriodOpen = require("../utils/assertPeriodOpen");

/**
 * GET /api/reviews/assignments  (บทบาท evaluator)
 * รายชื่อผู้รับการประเมินที่กรรมการคนนี้ต้องประเมิน + สถานะ
 */
exports.myAssignments = async (req, res, next) => {
  try {
    // join ชื่อรอบด้วย เพราะอาจมีหลายรอบประเมินเปิดพร้อมกัน (เช่น ประเมินการสอน + ประเมิน PA)
    const items = await db("assignments as a") // items = ใบมอบหมายทั้งหมดของกรรมการคนที่ล็อกอินอยู่ (a = assignments เรียกสั้นๆ)
      .join("users as u", "u.id", "a.evaluatee_id")
      .join("periods as p", "p.id", "a.period_id")
      .where("a.evaluator_id", req.user.id)
      .select("a.id", "a.status", "a.committee_role", "u.name_th as evaluatee", "u.email", "p.name_th as period_name")
      .orderBy(["p.name_th", "u.name_th"]);
    res.json({ success: true, items });
  } catch (e) { next(e); }
};

/**
 * GET /api/reviews/:assignmentId  (บทบาท evaluator)
 * รายละเอียด 1 ใบประเมิน: ตัวชี้วัด + ข้อมูล/คะแนนที่ผู้รับประเมินกรอกเอง + คะแนนกรรมการ
 */
exports.detail = async (req, res, next) => {
  try {
    const a = await db("assignments as a") // a = หัวใบประเมินนี้ (ผู้รับ/รอบ/สถานะ) พร้อมชื่อจริงที่ join มา
      .join("users as u", "u.id", "a.evaluatee_id")
      .join("periods as p", "p.id", "a.period_id")
      .where("a.id", req.params.assignmentId)
      .select(
        "a.*", "u.name_th as evaluatee", "u.email as evaluatee_email",
        "p.name_th as period_name", "p.end_date as period_end_date"
      ).first();
    if (!a) return res.status(404).json({ success: false, message: "ไม่พบใบประเมิน" });

    const items = await db("indicators as i") // items = ตัวชี้วัดทั้งหมดของรอบนี้ พร้อมข้อมูลผู้รับการประเมิน (e.*) และคะแนนกรรมการที่เคยให้ (r.*) ถ้ามี
      .join("topics as t", "t.id", "i.topic_id")
      .where("t.period_id", a.period_id)
      .leftJoin("evidences as e", function () {
        this.on("e.indicator_id", "i.id")
          .andOn("e.evaluatee_id", db.raw("?", [a.evaluatee_id]))
          .andOn("e.period_id", db.raw("?", [a.period_id]));
      })
      .leftJoin("reviews as r", function () {
        this.on("r.indicator_id", "i.id").andOn("r.assignment_id", db.raw("?", [a.id]));
      })
      .select(
        "i.id as indicator_id", "i.name_th as indicator", "i.type", "i.weight",
        "t.name_th as topic",
        "e.detail", "e.url", "e.self_score",
        "r.score", "r.comment"
      )
      .orderBy(["i.topic_id", "i.id"]);

    // ไฟล์แนบของผู้รับการประเมิน
    const evi = await db("evidences") // evi = แถว evidences ของผู้รับคนนี้ในรอบนี้ (แค่ id/indicator_id พอ ไว้ผูกไฟล์)
      .where({ evaluatee_id: a.evaluatee_id, period_id: a.period_id }).select("id", "indicator_id");
    const files = evi.length // files = ไฟล์แนบทั้งหมดของ evidences เหล่านี้ในทีเดียว (กันยิง query ทีละแถว)
      ? await db("evidence_files").whereIn("evidence_id", evi.map((x) => x.id))
      : [];
    items.forEach((it) => {
      const ev = evi.find((x) => x.indicator_id === it.indicator_id); // ev = evidence ของตัวชี้วัดข้อนี้โดยเฉพาะ (ถ้าเคยกรอกไว้)
      it.files = ev ? files.filter((f) => f.evidence_id === ev.id) : []; // แนบเฉพาะไฟล์ของ evidence นี้เข้าตัวชี้วัดข้อนี้
    });

    res.json({ success: true, assignment: a, items });
  } catch (e) { next(e); }
};

/**
 * POST /api/reviews  (บทบาท evaluator)
 * body: { assignment_id, indicator_id, score, comment }  → upsert ทีละตัวชี้วัด
 */
exports.save = async (req, res, next) => {
  try {
    const { assignment_id, indicator_id, score, comment } = req.body || {}; // คะแนน+ความเห็นของกรรมการต่อ 1 ตัวชี้วัด
    const a = await db("assignments").where({ id: assignment_id }).first(); // ใบประเมิน ต้องมีอยู่จริงและยังไม่ถูกล็อกถึงจะให้คะแนนได้
    if (!a) return res.status(404).json({ success: false, message: "ไม่พบใบประเมิน" });
    if (a.status === "submitted") return res.status(400).json({ success: false, message: "ส่งผลการประเมินไปแล้ว ไม่สามารถแก้ไขคะแนนได้" });
    await assertPeriodOpen(a.period_id); // ถ้ารอบนี้หมดเขตแล้ว throw error ทันที

    const existing = await db("reviews").where({ assignment_id, indicator_id }).first(); // เคยให้คะแนนตัวชี้วัดนี้มาก่อนหรือยัง (ใช้ตัดสิน insert/update)
    if (existing) await db("reviews").where({ id: existing.id }).update({ score, comment });
    else await db("reviews").insert({ assignment_id, indicator_id, score, comment });
    res.json({ success: true });
  } catch (e) { next(e); }
};

/**
 * POST /api/reviews/:assignmentId/submit  (บทบาท evaluator)
 * body: { overall_comment, signature }  (signature = รูป base64 dataURL)
 * บันทึกความเห็นสรุป + ลายเซ็น + เปลี่ยนสถานะเป็น submitted
 */
exports.submit = async (req, res, next) => {
  try {
    const a = await db("assignments").where({ id: req.params.assignmentId }).first(); // ใบประเมินที่จะยืนยันส่ง
    if (!a) return res.status(404).json({ success: false, message: "ไม่พบใบประเมิน" });
    if (a.status === "submitted") return res.status(400).json({ success: false, message: "ส่งผลการประเมินไปแล้ว" });
    await assertPeriodOpen(a.period_id); // ถ้ารอบนี้หมดเขตแล้ว throw error ทันที

    const { overall_comment, signature } = req.body || {}; // signature = รูปลายเซ็นจาก canvas ส่งมาเป็น base64 dataURL (เช่น "data:image/png;base64,...")
    let signature_path = null; // ที่อยู่ไฟล์ลายเซ็นบนดิสก์ (null ถ้าไม่มีลายเซ็นส่งมา)
    if (signature?.startsWith("data:image")) {
      const b64 = signature.split(",")[1]; // ตัดส่วนหัว "data:image/png;base64," ออก เหลือแค่ข้อมูลรูปที่เข้ารหัส base64 จริงๆ
      const file = `sign_${req.params.assignmentId}_${Date.now()}.png`; // ตั้งชื่อไฟล์กันชนกัน (ผูกกับใบประเมิน+เวลา)
      fs.writeFileSync(path.join(__dirname, "..", "uploads", file), Buffer.from(b64, "base64")); // ถอดรหัส base64 กลับเป็นไฟล์รูปจริง เขียนลงดิสก์
      signature_path = "/uploads/" + file; // path แบบที่ frontend เอาไปต่อ URL เปิดรูปได้
    }
    const n = await db("assignments").where({ id: req.params.assignmentId }).update({ // n = จำนวนแถวที่แก้ได้จริง
      overall_comment,
      ...(signature_path && { signature_path }),
      status: "submitted",
      submitted_at: db.fn.now(),
    });
    if (!n) return res.status(404).json({ success: false, message: "ไม่พบใบประเมิน" });
    res.json({ success: true });
  } catch (e) { next(e); }
};

/**
 * GET /api/reviews/feedback?period_id=  (บทบาท evaluatee)
 * ผู้รับการประเมินดูความเห็น/คะแนนที่กรรมการให้ตนเอง เฉพาะรอบที่ระบุ (เกณฑ์ 5.2.8)
 * (ไม่ระบุ period_id → คืนทุกรอบ เผื่อเรียกใช้จากที่อื่นที่ไม่สนใจแยกรอบ)
 */
exports.feedback = async (req, res, next) => {
  try {
    const periodFilter = (q) => (req.query.period_id ? q.where("a.period_id", req.query.period_id) : q); // ต่อเงื่อนไขกรองรอบ ถ้ามีการระบุ period_id มา (ไม่งั้นคืนทุกรอบ)

    const perIndicator = await periodFilter( // คะแนน+ความเห็นรายตัวชี้วัดจากทุกกรรมการที่เคยให้คะแนนคนนี้
      db("reviews as r")
        .join("assignments as a", "a.id", "r.assignment_id")
        .join("indicators as i", "i.id", "r.indicator_id")
        .join("users as u", "u.id", "a.evaluator_id")
        .where("a.evaluatee_id", req.user.id) // req.user.id = ผู้รับการประเมินที่ล็อกอินอยู่ (ดูของตัวเองเท่านั้น)
    ).select("i.name_th as indicator", "r.score", "r.comment", "u.name_th as evaluator", "a.committee_role");

    const overall = await periodFilter( // ความเห็นสรุปภาพรวม + ลายเซ็น เฉพาะกรรมการที่ส่งผลแล้ว (status = submitted)
      db("assignments as a")
        .join("users as u", "u.id", "a.evaluator_id")
        .where({ "a.evaluatee_id": req.user.id, "a.status": "submitted" })
    ).select("u.name_th as evaluator", "a.overall_comment", "a.signature_path", "a.committee_role");

    res.json({ success: true, perIndicator, overall });
  } catch (e) { next(e); }
};
