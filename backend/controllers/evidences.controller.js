// ข้อมูล+หลักฐาน+ประเมินตนเอง ของผู้รับการประเมิน
const db = require("../db");
const resolvePeriodId = require("../utils/activePeriod");
const assertPeriodOpen = require("../utils/assertPeriodOpen");

/**
 * GET /api/evidences/periods  (บทบาท evaluatee)
 * รายการรอบการประเมินที่เปิดใช้งานอยู่ (อาจมีหลายรอบพร้อมกัน เช่น ประเมินการสอน + ประเมิน PA)
 * พร้อมความคืบหน้าประเมินตนเองของตัวเองในแต่ละรอบ — ใช้เป็นหน้ารายการก่อนกดเข้าไปกรอกทีละรอบ
 */
exports.myPeriods = async (req, res, next) => {
  try {
    const evaluateeId = req.user.id; // ผู้รับการประเมินที่ล็อกอินอยู่ (มาจาก JWT)
    const periods = await db("periods").where({ is_active: 1 }).orderBy("id"); // รอบทั้งหมดที่เปิดใช้งานอยู่ตอนนี้ (อาจมีหลายรอบพร้อมกัน)

    const items = []; // ผลลัพธ์สุดท้าย 1 แถวต่อ 1 รอบ พร้อมความคืบหน้าของ evaluateeId คนนี้
    for (const p of periods) {
      const [{ total }] = await db("indicators as i") // total = จำนวนตัวชี้วัดทั้งหมดของรอบนี้ (ตัวหารของ %)
        .join("topics as t", "t.id", "i.topic_id")
        .where("t.period_id", p.id)
        .count({ total: "*" });
      // นับเฉพาะ evidence ของตัวชี้วัดที่ "ยังอยู่ในหัวข้อของรอบนี้จริง" (join ผ่าน topic เหมือน list())
      // ไม่นับแค่ evidences.period_id ตรงๆ เพราะอาจเป็นข้อมูลค้างจากตอนหัวข้อ/ตัวชี้วัดถูกย้ายรอบภายหลัง
      const [{ filled }] = await db("indicators as i") // filled = จำนวนตัวชี้วัดที่คนนี้กรอกคะแนนตนเองแล้ว (ตัวตั้งของ %)
        .join("topics as t", "t.id", "i.topic_id")
        .join("evidences as e", function () {
          this.on("e.indicator_id", "i.id")
            .andOn("e.evaluatee_id", db.raw("?", [evaluateeId]))
            .andOn("e.period_id", db.raw("?", [p.id]));
        })
        .where("t.period_id", p.id)
        .whereNotNull("e.self_score")
        .count({ filled: "*" });
      items.push({
        id: p.id, name_th: p.name_th, start_date: p.start_date, end_date: p.end_date,
        total: Number(total), filled: Number(filled),
        percent: total ? Math.round((Number(filled) / Number(total)) * 100) : 0,
      });
    }
    res.json({ success: true, items });
  } catch (e) { next(e); }
};

/**
 * GET /api/evidences?evaluatee_id&period_id
 * คืน "ตัวชี้วัดของรอบประเมินนั้น" พร้อมข้อมูลที่ผู้รับการประเมินกรอกไว้ (ถ้ามี) + ไฟล์แนบ
 * ถ้าไม่ส่ง evaluatee_id จะใช้ผู้ที่ล็อกอิน (หน้า /me ของตัวเอง)
 * ถ้าไม่ส่ง period_id จะใช้รอบที่เปิดใช้งานอยู่ (is_active=1)
 */
exports.list = async (req, res, next) => {
  try {
    const evaluateeId = req.query.evaluatee_id || req.user.id; // ระบุ id มา (admin/กรรมการดูของคนอื่น) หรือไม่ระบุ = ดูของตัวเอง
    const periodId = await resolvePeriodId(req.query.period_id); // รอบที่ระบุ หรือรอบที่เปิดใช้งานอยู่ถ้าไม่ระบุมา

    // ตัวชี้วัดของหัวข้อในรอบนี้เท่านั้น + ข้อมูลที่กรอก (LEFT JOIN)
    const rows = await db("indicators as i") // rows = 1 แถวต่อ 1 ตัวชี้วัด พร้อมข้อมูลที่ evaluateeId คนนี้เคยกรอกไว้ (ถ้ายังไม่กรอก ฟิลด์ e.* จะเป็น null)
      .join("topics as t", "t.id", "i.topic_id")
      .where("t.period_id", periodId)
      .leftJoin("evidences as e", function () {
        this.on("e.indicator_id", "i.id")
          .andOn("e.evaluatee_id", db.raw("?", [evaluateeId]))
          .andOn("e.period_id", db.raw("?", [periodId]));
      })
      .select(
        "i.id as indicator_id", "i.name_th as indicator", "i.description",
        "i.type", "i.weight", "i.evidence_kind",
        "i.template_name", "i.template_path", "i.template_url", // แม่แบบ/ลิงก์อ้างอิงที่ admin แนบไว้
        "t.name_th as topic",
        "e.id as evidence_id", "e.detail", "e.url", "e.self_score", "e.self_note"
      )
      .orderBy(["i.topic_id", "i.id"]);

    // แนบไฟล์ของแต่ละ evidence
    const ids = rows.map((r) => r.evidence_id).filter(Boolean); // เก็บเฉพาะ evidence_id ที่มีจริง (ตัวชี้วัดที่ยังไม่เคยกรอกจะเป็น null ตัด Boolean ทิ้ง)
    const files = ids.length ? await db("evidence_files").whereIn("evidence_id", ids) : []; // ไฟล์แนบทั้งหมดของ evidence เหล่านี้ในทีเดียว (กันยิง query ทีละแถวในลูป)
    rows.forEach((r) => (r.files = files.filter((f) => f.evidence_id === r.evidence_id))); // แจกไฟล์กลับเข้าแถวของตัวเอง ฝั่งไหนเป็นเจ้าของไฟล์นั้น

    res.json({ success: true, items: rows });
  } catch (e) { next(e); }
};

/**
 * POST /api/evidences  (บทบาท evaluatee)
 * body: { indicator_id, period_id, detail, url, self_score, self_note }
 * บันทึกแบบ upsert (มีอยู่แล้ว=แก้ไข, ยังไม่มี=เพิ่ม)
 */
exports.save = async (req, res, next) => {
  try {
    const evaluatee_id = req.user.id; // เจ้าของข้อมูล = คนที่ล็อกอินอยู่เท่านั้น (บันทึกแทนคนอื่นไม่ได้)
    const { indicator_id, detail, url, self_score, self_note } = req.body || {}; // ค่าที่กรอกในฟอร์มของตัวชี้วัด 1 ข้อ
    const period_id = await resolvePeriodId(req.body?.period_id); // รอบที่ระบุ หรือรอบที่เปิดใช้งานอยู่ถ้าไม่ระบุมา
    if (!indicator_id)
      return res.status(400).json({ success: false, message: "ต้องระบุ indicator_id" });
    await assertPeriodOpen(period_id); // ถ้ารอบนี้หมดเขตแล้ว ฟังก์ชันนี้จะ throw error ให้ทันที (ห้ามบันทึกเพิ่ม)

    const existing = await db("evidences") // แถวเดิมของตัวชี้วัดนี้ (ถ้าเคยกรอกไว้แล้ว) — ใช้ตัดสินว่าจะ insert หรือ update
      .where({ evaluatee_id, indicator_id, period_id }).first();

    const data = { detail, url, self_score, self_note }; // ค่าที่จะบันทึก (ใช้ร่วมกันทั้ง insert และ update)
    let id; // id ของแถว evidences ที่บันทึกเสร็จแล้ว (ไม่ว่าจะเป็นแถวเดิมหรือแถวใหม่)
    if (existing) {
      await db("evidences").where({ id: existing.id }).update(data); // มีแถวเดิมอยู่แล้ว → แก้ไขทับ (upsert ฝั่ง update)
      id = existing.id;
    } else {
      [id] = await db("evidences").insert({ evaluatee_id, indicator_id, period_id, ...data }); // ยังไม่เคยกรอก → สร้างแถวใหม่ (upsert ฝั่ง insert)
    }
    res.json({ success: true, data: await db("evidences").where({ id }).first() });
  } catch (e) { next(e); }
};

/**
 * POST /api/evidences/:id/files  (บทบาท evaluatee)
 * อัปโหลดไฟล์หลักฐานหลายไฟล์ (ใช้ multer .array มาก่อนหน้า)
 */
exports.uploadFiles = async (req, res, next) => {
  try {
    const evidence = await db("evidences").where({ id: req.params.id }).first(); // ตัวชี้วัด (evidence) ที่จะแนบไฟล์เข้าไป ต้องมีแถวนี้อยู่ก่อน (เคยกด "บันทึก" มาแล้ว)
    if (!evidence) return res.status(404).json({ success: false, message: "ไม่พบตัวชี้วัดนี้" });
    if (!req.files?.length) // req.files = ไฟล์ที่ multer (middleware อัปโหลด) แกะออกมาให้แล้วเป็น array
      return res.status(400).json({ success: false, message: "ไม่มีไฟล์ที่อัปโหลด" });

    const rows = req.files.map((f) => ({ // แปลงไฟล์แต่ละไฟล์เป็นแถวที่จะลง evidence_files
      evidence_id: evidence.id,
      file_name: f.originalname,      // ชื่อไฟล์ต้นฉบับที่ผู้ใช้อัปโหลด (รองรับภาษาไทยแล้ว)
      path: "/uploads/" + f.filename, // ที่อยู่ไฟล์จริงบนดิสก์ (multer ตั้งชื่อไฟล์กันชนกันให้แล้ว)
      mime: f.mimetype,               // ชนิดไฟล์ เช่น application/pdf
      size: f.size,                   // ขนาดไฟล์ (byte)
    }));
    await db("evidence_files").insert(rows);
    res.status(201).json({ success: true, data: rows });
  } catch (e) { next(e); }
};

// DELETE /api/evidences/files/:fileId
exports.removeFile = async (req, res, next) => {
  try {
    const n = await db("evidence_files").where({ id: req.params.fileId }).del(); // n = จำนวนแถวที่ลบได้จริง
    if (!n) return res.status(404).json({ success: false, message: "ไม่พบไฟล์" });
    res.json({ success: true });
  } catch (e) { next(e); }
};
