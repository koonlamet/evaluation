// ติดตามสถานะการประเมิน สำหรับงานบุคลากร (5.1.10, 5.1.11, 5.1.12)
const db = require("../db");
const resolvePeriodId = require("../utils/activePeriod");

/**
 * GET /api/tracking/evaluators?period_id=1
 * สถานะการประเมินของกรรมการแต่ละคน: ประเมินใครไปแล้ว/ใครยังไม่ประเมิน (5.1.10, 5.1.11)
 */
exports.byEvaluator = async (req, res, next) => {
  try {
    const periodId = await resolvePeriodId(req.query.period_id); // รอบที่ระบุ หรือรอบที่เปิดใช้งานอยู่ถ้าไม่ระบุมา
    const rows = await db("assignments as a") // rows = ใบมอบหมายทุกใบของรอบนี้ พร้อมชื่อจริงกรรมการ(ev)/ผู้รับ(ee) — หน้า tracking จัดกลุ่มตามกรรมการเองฝั่ง client
      .join("users as ev", "ev.id", "a.evaluator_id")
      .join("users as ee", "ee.id", "a.evaluatee_id")
      .where("a.period_id", periodId)
      .select(
        "a.id as assignment_id", "a.evaluator_id", "ev.name_th as evaluator_name",
        "a.evaluatee_id", "ee.name_th as evaluatee_name",
        "a.committee_role", "a.status", "a.submitted_at"
      )
      .orderBy(["ev.name_th", "ee.name_th"]);
    res.json({ success: true, items: rows });
  } catch (e) { next(e); }
};

/**
 * GET /api/tracking/evaluatees?period_id=1
 * สถานะการประเมินตนเองของผู้รับการประเมินแต่ละคน: กรอกไปแล้วกี่ตัวชี้วัดจากทั้งหมด (5.1.12)
 */
exports.byEvaluatee = async (req, res, next) => {
  try {
    const periodId = await resolvePeriodId(req.query.period_id); // รอบที่ระบุ หรือรอบที่เปิดใช้งานอยู่ถ้าไม่ระบุมา
    // นับเฉพาะตัวชี้วัดของหัวข้อที่อยู่ในรอบนี้ (ไม่ใช่ตัวชี้วัดทั้งหมดในระบบ)
    const [{ totalIndicators }] = await db("indicators as i") // ตัวหารของ % ความคืบหน้า (จำนวนตัวชี้วัดทั้งหมดของรอบนี้)
      .join("topics as t", "t.id", "i.topic_id")
      .where("t.period_id", periodId)
      .count({ totalIndicators: "*" });

    const evaluatees = await db("users").where("role", "evaluatee").select("id", "name_th", "email").orderBy("name_th"); // ผู้รับการประเมินทุกคนในระบบ (ไม่กรองตามรอบ เพราะทุกคนมีสิทธิ์ถูกประเมินได้ทุกรอบ)
    // นับเฉพาะ evidence ของตัวชี้วัดที่ "ยังอยู่ในหัวข้อของรอบนี้จริง" (join ผ่าน topic)
    // ไม่นับแค่ evidences.period_id ตรงๆ เพราะอาจเป็นข้อมูลค้างจากตอนหัวข้อ/ตัวชี้วัดถูกย้ายรอบภายหลัง
    const filledCounts = await db("evidences as e") // filledCounts = จำนวนตัวชี้วัดที่กรอกคะแนนตนเองแล้ว จัดกลุ่มตามคน (1 แถวต่อ 1 คน)
      .join("indicators as i", "i.id", "e.indicator_id")
      .join("topics as t", "t.id", "i.topic_id")
      .where("e.period_id", periodId)
      .where("t.period_id", periodId)
      .whereNotNull("e.self_score")
      .groupBy("e.evaluatee_id")
      .select("e.evaluatee_id", db.raw("COUNT(*) as filled"));
    const reviewCounts = await db("assignments") // reviewCounts = จำนวนใบมอบหมายของแต่ละคน แยกตามสถานะ (1 แถวต่อ คน+สถานะ) เช่น คนที่ 5: pending=1, submitted=1
      .where({ period_id: periodId })
      .groupBy("evaluatee_id", "status")
      .select("evaluatee_id", "status", db.raw("COUNT(*) as cnt"));

    const items = evaluatees.map((u) => { // u = ผู้รับการประเมิน 1 คนที่กำลังคำนวณสรุปให้
      const filled = filledCounts.find((f) => f.evaluatee_id === u.id)?.filled || 0; // จำนวนตัวชี้วัดที่คนนี้กรอกแล้ว (0 ถ้ายังไม่เคยกรอกเลย)
      const mine = reviewCounts.filter((r) => r.evaluatee_id === u.id); // แถวสถานะใบมอบหมายทั้งหมดของคนนี้ (แยกตาม pending/submitted)
      const evaluatorsTotal = mine.reduce((s, r) => s + Number(r.cnt), 0); // กรรมการทั้งหมดที่ถูกมอบหมายให้ประเมินคนนี้ (รวมทุกสถานะ)
      const evaluatorsSubmitted = Number(mine.find((r) => r.status === "submitted")?.cnt || 0); // กรรมการที่ส่งผลไปแล้ว
      return {
        ...u,
        totalIndicators: Number(totalIndicators),
        filled: Number(filled),
        percent: totalIndicators ? Math.round((Number(filled) / Number(totalIndicators)) * 100) : 0,
        evaluatorsTotal,
        evaluatorsSubmitted,
      };
    });
    res.json({ success: true, items });
  } catch (e) { next(e); }
};
