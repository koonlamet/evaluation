// รายงานสรุปผล + สถิติ (งานบุคลากร / ผู้รับการประเมิน)
const db = require("../db");
const resolvePeriodId = require("../utils/activePeriod");

/**
 * GET /api/summary/:evaluateeId?period_id=1
 * สรุปผลรายบุคคล: คะแนนตนเอง + ค่าเฉลี่ยคะแนนจากกรรมการ ต่อตัวชี้วัด/หัวข้อ (เฉพาะหัวข้อของรอบนี้)
 * ใช้ทั้งหน้า HR (5.1.10-13) และหน้า Report ของผู้รับการประเมิน (5.2.7)
 */
exports.summary = async (req, res, next) => {
  try {
    const evaluateeId = req.params.evaluateeId; // ผู้รับการประเมินที่จะดูรายงาน (มาจาก URL เช่น /api/summary/7)
    const periodId = await resolvePeriodId(req.query.period_id); // รอบที่ระบุ หรือรอบที่เปิดใช้งานอยู่ถ้าไม่ระบุมา
    const user = await db("users").select("id", "name_th", "email").where({ id: evaluateeId }).first(); // ข้อมูลเจ้าของรายงาน
    if (!user) return res.status(404).json({ success: false, message: "ไม่พบผู้ใช้" });
    const period = await db("periods").select("id", "name_th").where({ id: periodId }).first(); // ชื่อรอบ ไว้แสดงหัวรายงาน

    // ต่อ 1 ตัวชี้วัด: คะแนนตนเอง + ค่าเฉลี่ยกรรมการ (AVG ข้ามกรรมการทุกคน)
    const items = await db("indicators as i") // items = ตารางคะแนนทั้งหมดของรายงาน (1 แถวต่อ 1 ตัวชี้วัด) — self_score จากผู้รับเอง, committee_score เฉลี่ยจากกรรมการ
      .join("topics as t", "t.id", "i.topic_id")
      .where("t.period_id", periodId)
      .leftJoin("evidences as e", function () {
        this.on("e.indicator_id", "i.id")
          .andOn("e.evaluatee_id", db.raw("?", [evaluateeId]))
          .andOn("e.period_id", db.raw("?", [periodId]));
      })
      .leftJoin("assignments as a", function () {
        this.on("a.evaluatee_id", db.raw("?", [evaluateeId]))
          .andOn("a.period_id", db.raw("?", [periodId]));
        // ระบุ ?evaluator_id= มา → ดูคะแนนดิบของกรรมการคนนั้นคนเดียว แทนค่าเฉลี่ยรวมทุกคน
        if (req.query.evaluator_id) this.andOn("a.evaluator_id", db.raw("?", [req.query.evaluator_id]));
      })
      .leftJoin("reviews as r", function () {
        this.on("r.assignment_id", "a.id").andOn("r.indicator_id", "i.id");
      })
      .groupBy("i.id", "i.name_th", "i.weight", "i.type", "t.name_th", "e.self_score")
      .select(
        "t.name_th as topic", "i.name_th as indicator", "i.weight", "i.type",
        "e.self_score",
        db.raw("ROUND(AVG(r.score),2) as committee_score")
      )
      .orderBy(["i.topic_id", "i.id"]);

    // ค่าเฉลี่ยถ่วงน้ำหนักภาพรวม — นับเฉพาะตัวชี้วัดแบบสเกลคะแนน 1-4 (ฟังก์ชันคำนวณคะแนน — เกณฑ์ทดสอบ 7.5)
    // ตัวชี้วัดแบบ "มี/ไม่มี" เป็นการตรวจสอบผ่าน/ไม่ผ่าน ไม่ใช่คะแนน จึงไม่นำมารวมในค่าเฉลี่ย
    const overall = weightedAverage(items); // คะแนนเฉลี่ยถ่วงน้ำหนักรวมทั้งรายงาน (ตัวเลขเดียว) หรือ null ถ้ายังไม่มีใครให้คะแนนเลย
    const compliance = complianceSummary(items); // สรุปตัวชี้วัดแบบมี/ไม่มี เช่น { total: 3, met: 2 }

    // สถานะกรรมการแต่ละคน
    const committees = await db("assignments as a") // committees = รายชื่อกรรมการที่ถูกมอบหมายให้ประเมินคนนี้ในรอบนี้ + สถานะส่งผล/ลายเซ็น
      .join("users as u", "u.id", "a.evaluator_id")
      .where({ "a.evaluatee_id": evaluateeId, "a.period_id": periodId })
      .select("a.evaluator_id", "u.name_th as evaluator", "a.committee_role", "a.status", "a.signature_path");

    res.json({ success: true, user, period, items, overall, compliance, committees });
  } catch (e) { next(e); }
};

// ฟังก์ชันคำนวณค่าเฉลี่ยถ่วงน้ำหนัก (แยกไว้เพื่อทดสอบ unit test ได้)
// นับเฉพาะตัวชี้วัดแบบ score_1_4 — แบบ yes_no ไม่ใช่คะแนน จึงไม่ร่วมคำนวณ
function weightedAverage(items) {
  let sum = 0, w = 0; // sum = ผลรวม (คะแนน×น้ำหนัก) ของทุกตัวชี้วัดที่มีคะแนน, w = ผลรวมน้ำหนักที่นำมาคิดจริง
  for (const it of items) {
    if (it.type === "yes_no") continue; // ตัวชี้วัดแบบมี/ไม่มี ไม่ใช่คะแนน ข้ามไป ไม่นำมาคิดเฉลี่ย
    if (it.committee_score != null) { // นับเฉพาะตัวชี้วัดที่มีคนให้คะแนนแล้วเท่านั้น (ยังไม่ให้คะแนน = ไม่นับ ไม่ใช่นับเป็น 0)
      sum += Number(it.committee_score) * Number(it.weight);
      w += Number(it.weight);
    }
  }
  return w ? Math.round((sum / w) * 100) / 100 : null; // ปัดทศนิยม 2 ตำแหน่ง, w=0 (ยังไม่มีคะแนนเลย) → คืน null แทนการหารด้วยศูนย์
}
exports.weightedAverage = weightedAverage;

// สรุปตัวชี้วัดแบบ "มี/ไม่มี" แยกจากคะแนน: ผ่านเกณฑ์กี่ข้อจากที่กรรมการตรวจแล้วทั้งหมด
function complianceSummary(items) {
  const yesNo = items.filter((it) => it.type === "yes_no" && it.committee_score != null); // ตัวชี้วัดแบบมี/ไม่มีที่กรรมการตรวจแล้วเท่านั้น
  return { total: yesNo.length, met: yesNo.filter((it) => Number(it.committee_score) >= 1).length }; // total = ตรวจแล้วทั้งหมดกี่ข้อ, met = ผ่านเกณฑ์ ("มี") กี่ข้อ
}
exports.complianceSummary = complianceSummary;

/**
 * GET /api/stats
 * สถิติภาพรวมสำหรับ Dashboard + แผนภูมิ (5.1.9 / โจทย์พิเศษ 8.5)
 */
exports.stats = async (req, res, next) => {
  try {
    const periodId = await resolvePeriodId(req.query.period_id); // รอบที่ระบุ หรือรอบที่เปิดใช้งานอยู่ถ้าไม่ระบุมา
    const roles = await db("users").select("role").count({ c: "*" }).groupBy("role"); // จำนวนผู้ใช้แยกตามบทบาท ป้อนการ์ดตัวเลขบน dashboard
    const [{ submitted }] = await db("assignments").where({ status: "submitted", period_id: periodId }).count({ submitted: "*" }); // จำนวนใบประเมินที่ส่งผลแล้วในรอบนี้
    const [{ pending }] = await db("assignments").where({ status: "pending", period_id: periodId }).count({ pending: "*" }); // จำนวนใบประเมินที่ยังรอ

    // คะแนนเฉลี่ยของกรรมการ เฉพาะรอบที่เลือก (ไม่งั้นถ้ามีหลายรอบเปิดพร้อมกัน หัวข้อจากคนละรอบจะปนกันในกราฟเดียว)
    // นับเฉพาะตัวชี้วัดแบบสเกลคะแนน ไม่รวมแบบ มี/ไม่มี — group ตาม level ที่ frontend ขอ (topic หรือ indicator)
    const level = req.query.level === "indicator" ? "indicator" : "topic"; // level = ความละเอียดของกราฟที่ frontend ขอ: "topic" (รวมเป็นรายหัวข้อ) หรือ "indicator" (แยกทีละตัวชี้วัด)
    // เฉลี่ยคะแนนกรรมการต่อ "ตัวชี้วัด" ก่อนเสมอ (ไม่ถ่วงน้ำหนัก เพราะเป็นการเฉลี่ยข้ามกรรมการของตัวชี้วัดเดียวกัน)
    // เริ่มจาก indicators (LEFT JOIN reviews) ไม่ใช่เริ่มจาก reviews — ตัวชี้วัด/หัวข้อที่ยังไม่มีใครให้คะแนนเลย
    // ต้องยังโผล่ในกราฟ (เป็น null) ไม่งั้นจะหายไปเงียบๆ ทำให้ดูเหมือนกราฟแสดงหัวข้อไม่ครบ
    const perIndicator = await db("indicators as i") // perIndicator = คะแนนเฉลี่ยกรรมการต่อตัวชี้วัด 1 แถวต่อ 1 ตัวชี้วัด (committee_score เป็น null ได้ ถ้ายังไม่มีใครให้คะแนน)
      .join("topics as t", "t.id", "i.topic_id")
      .leftJoin("reviews as r", "r.indicator_id", "i.id")
      .where("i.type", "score_1_4")
      .where("t.period_id", periodId)
      .groupBy("i.id", "i.name_th", "i.weight", "t.id", "t.name_th")
      .select(
        "i.id as indicator_id", "i.name_th as indicator", "i.weight", "i.type",
        "t.id as topic_id", "t.name_th as topic",
        db.raw("ROUND(AVG(r.score),2) as committee_score")
      )
      .orderBy(["t.id", "i.id"]);

    let byTopic; // byTopic = ข้อมูลสุดท้ายที่ป้อนกราฟแท่ง (1 แถวต่อ 1 แท่ง ไม่ว่าจะเป็นรายหัวข้อหรือรายตัวชี้วัด)
    if (level === "indicator") {
      // แนบชื่อหัวข้อไว้ด้วย (group_topic) เพื่อระบุว่าตัวชี้วัดนี้อยู่ภายใต้หัวข้อไหน
      byTopic = perIndicator.map((it) => ({ topic: it.indicator, group_topic: it.topic, avg_score: it.committee_score }));
    } else {
      // รวมข้ามตัวชี้วัดเป็นรายหัวข้อต้องถ่วงน้ำหนัก ใช้สูตรเดียวกับ weightedAverage() ด้านล่าง
      // (ตัวชี้วัดน้ำหนัก 30 ไม่ควรมีผลเท่าตัวชี้วัดน้ำหนัก 10) เพื่อให้ตรงกับคะแนนสรุปในหน้ารายงานรายบุคคล
      const byTopicId = new Map(); // จัดกลุ่มตัวชี้วัดตาม topic_id ก่อนจะถ่วงน้ำหนักรวมเป็นคะแนนเดียวต่อหัวข้อ
      for (const it of perIndicator) {
        if (!byTopicId.has(it.topic_id)) byTopicId.set(it.topic_id, { topic: it.topic, items: [] });
        byTopicId.get(it.topic_id).items.push(it);
      }
      byTopic = [...byTopicId.values()].map((g) => ({ topic: g.topic, avg_score: weightedAverage(g.items) })); // g = ตัวชี้วัดทั้งหมดของหัวข้อเดียวกัน ส่งเข้า weightedAverage() ตัวเดียวกับหน้ารายงาน
    }

    res.json({
      success: true,
      roles: Object.fromEntries(roles.map((r) => [r.role, Number(r.c)])),
      submitted: Number(submitted),
      pending: Number(pending),
      byTopic,
    });
  } catch (e) { next(e); }
};
