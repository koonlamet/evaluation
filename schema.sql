-- ============================================================
-- PES : ระบบประเมินบุคลากร  (ไฟล์เดียว: สร้างตาราง + ใส่ข้อมูลตัวอย่าง)
-- MySQL 8.x  | ทุก user รหัสผ่าน = 123456
-- 8 ตาราง ครอบคลุมเกณฑ์ส่วนที่ 2 (>=3 ตาราง, มีความสัมพันธ์, data type เหมาะสม)
-- ============================================================
SET NAMES utf8mb4;
DROP DATABASE IF EXISTS pes_db;
CREATE DATABASE pes_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pes_db;

-- 1) ผู้ใช้ระบบ 3 บทบาท: admin=งานบุคลากร, evaluator=กรรมการ, evaluatee=ผู้รับการประเมิน
CREATE TABLE users (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  email         VARCHAR(150) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  name_th       VARCHAR(150) NOT NULL,
  role          ENUM('admin','evaluator','evaluatee') NOT NULL DEFAULT 'evaluatee',
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2) ช่วงเวลาการประเมิน (เปิด/ปิดระบบ)
CREATE TABLE periods (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  name_th    VARCHAR(150) NOT NULL,
  start_date DATE NOT NULL,
  end_date   DATE NOT NULL,
  is_active  TINYINT(1) NOT NULL DEFAULT 1
);

-- 3) หัวข้อการประเมิน (ผูกกับช่วงเวลาประเมิน — คนละรอบ ตั้งหัวข้อ/ตัวชี้วัดของตัวเองได้)
CREATE TABLE topics (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  period_id   INT NOT NULL,
  name_th     VARCHAR(150) NOT NULL,
  description TEXT,
  FOREIGN KEY (period_id) REFERENCES periods(id) ON DELETE CASCADE
);

-- 4) ตัวชี้วัดในแต่ละหัวข้อ
CREATE TABLE indicators (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  topic_id      INT NOT NULL,
  name_th       VARCHAR(200) NOT NULL,
  description   TEXT,
  weight        DECIMAL(5,2) NOT NULL DEFAULT 1.00,          -- น้ำหนักคะแนน
  type          ENUM('score_1_4','yes_no') NOT NULL DEFAULT 'score_1_4',
  evidence_kind VARCHAR(50) NOT NULL DEFAULT 'pdf',           -- แนบได้หลายชนิด คั่นด้วยจุลภาค เช่น "pdf,image,url"
  template_name VARCHAR(255) NULL,                            -- ชื่อไฟล์แม่แบบที่ admin อัปโหลด (ถ้ามี)
  template_path VARCHAR(500) NULL,                            -- พาธไฟล์แม่แบบ (PDF/รูปภาพ) ให้ผู้รับการประเมินดาวน์โหลด
  template_url  VARCHAR(500) NULL,                             -- ลิงก์อ้างอิงแทน/เพิ่มเติมจากไฟล์
  FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
);

-- 5) การมอบหมายกรรมการให้ประเมินผู้รับการประเมิน (= 1 ใบประเมิน)
CREATE TABLE assignments (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  period_id       INT NOT NULL,
  evaluator_id    INT NOT NULL,                              -- กรรมการ
  evaluatee_id    INT NOT NULL,                              -- ผู้รับการประเมิน
  committee_role  ENUM('chair','member') NOT NULL DEFAULT 'member',
  overall_comment TEXT,                                      -- ความเห็นสรุปภาพรวม
  signature_path  VARCHAR(255),                              -- ลายเซ็น (ไฟล์ภาพ)
  status          ENUM('pending','submitted') NOT NULL DEFAULT 'pending',
  submitted_at    TIMESTAMP NULL,
  unlocked_at     TIMESTAMP NULL,                              -- เวลาที่ admin ปลดล็อกล่าสุด (ถ้าเคยปลดล็อก)
  unlocked_by     INT NULL,                                    -- admin คนที่ปลดล็อก
  UNIQUE KEY uq_assign (period_id, evaluator_id, evaluatee_id),
  FOREIGN KEY (period_id)    REFERENCES periods(id) ON DELETE CASCADE,
  FOREIGN KEY (evaluator_id) REFERENCES users(id),
  FOREIGN KEY (evaluatee_id) REFERENCES users(id),
  FOREIGN KEY (unlocked_by)  REFERENCES users(id)
);

-- 6) ข้อมูล + การประเมินตนเอง ของผู้รับการประเมิน (1 แถวต่อ 1 ตัวชี้วัด)
CREATE TABLE evidences (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  evaluatee_id INT NOT NULL,
  indicator_id INT NOT NULL,
  period_id    INT NOT NULL,
  detail       TEXT,                                         -- รายละเอียดที่กรอก
  url          VARCHAR(500),                                 -- หลักฐานแบบ URL
  self_score   DECIMAL(3,1),                                 -- คะแนนประเมินตนเอง
  self_note    TEXT,
  UNIQUE KEY uq_evi (evaluatee_id, indicator_id, period_id),
  FOREIGN KEY (evaluatee_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (indicator_id) REFERENCES indicators(id) ON DELETE CASCADE,
  FOREIGN KEY (period_id)    REFERENCES periods(id) ON DELETE CASCADE
);

-- 7) ไฟล์หลักฐานแนบ (หลายไฟล์ต่อ 1 ตัวชี้วัด)  → รองรับ Upload หลายไฟล์
CREATE TABLE evidence_files (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  evidence_id INT NOT NULL,
  file_name   VARCHAR(255) NOT NULL,
  path        VARCHAR(500) NOT NULL,
  mime        VARCHAR(100),
  size        INT UNSIGNED,
  FOREIGN KEY (evidence_id) REFERENCES evidences(id) ON DELETE CASCADE
);

-- 8) ผลการให้คะแนนของกรรมการ (1 แถวต่อ 1 ตัวชี้วัด ต่อ 1 ใบประเมิน)
CREATE TABLE reviews (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  assignment_id INT NOT NULL,
  indicator_id  INT NOT NULL,
  score         DECIMAL(3,1),
  comment       TEXT,
  UNIQUE KEY uq_review (assignment_id, indicator_id),
  FOREIGN KEY (assignment_id) REFERENCES assignments(id) ON DELETE CASCADE,
  FOREIGN KEY (indicator_id)  REFERENCES indicators(id) ON DELETE CASCADE
);

-- ============================================================
-- ข้อมูลตัวอย่าง (รหัสผ่านทุกคน = 123456)
-- 3 รอบการประเมิน (ปิดแล้ว 1 / กำลังใช้งาน 1 / ใกล้หมดเขต 1) กรรมการ 5 คน ผู้รับการประเมิน 10 คน
-- ============================================================

-- ผู้ใช้: admin 1 + กรรมการ 5 + ผู้รับการประเมิน 10
INSERT INTO `users` (`id`, `email`, `password_hash`, `name_th`, `role`, `created_at`) VALUES (1,'admin@pes.ac.th','$2a$10$UfkkPEvfPLe5c42Vuut6EesafinqX1Izl0JIKwikuO8YsKYdYoGnW','อรวรรณ ศรีสมบูรณ์','admin','2026-07-14 06:33:21');
INSERT INTO `users` (`id`, `email`, `password_hash`, `name_th`, `role`, `created_at`) VALUES (2,'eval1@pes.ac.th','$2a$10$UfkkPEvfPLe5c42Vuut6EesafinqX1Izl0JIKwikuO8YsKYdYoGnW','สมพงษ์ วัฒนกิจ','evaluator','2026-07-14 06:33:21');
INSERT INTO `users` (`id`, `email`, `password_hash`, `name_th`, `role`, `created_at`) VALUES (3,'eval2@pes.ac.th','$2a$10$UfkkPEvfPLe5c42Vuut6EesafinqX1Izl0JIKwikuO8YsKYdYoGnW','วิภาดา รุ่งเรือง','evaluator','2026-07-14 06:33:21');
INSERT INTO `users` (`id`, `email`, `password_hash`, `name_th`, `role`, `created_at`) VALUES (4,'eval3@pes.ac.th','$2a$10$UfkkPEvfPLe5c42Vuut6EesafinqX1Izl0JIKwikuO8YsKYdYoGnW','ประยุทธ สายบัว','evaluator','2026-07-14 06:33:21');
INSERT INTO `users` (`id`, `email`, `password_hash`, `name_th`, `role`, `created_at`) VALUES (5,'eval4@pes.ac.th','$2a$10$UfkkPEvfPLe5c42Vuut6EesafinqX1Izl0JIKwikuO8YsKYdYoGnW','อัจฉรา ทองสุข','evaluator','2026-07-14 06:33:21');
INSERT INTO `users` (`id`, `email`, `password_hash`, `name_th`, `role`, `created_at`) VALUES (6,'eval5@pes.ac.th','$2a$10$UfkkPEvfPLe5c42Vuut6EesafinqX1Izl0JIKwikuO8YsKYdYoGnW','สุเมธ ไกรฤกษ์','evaluator','2026-07-14 06:33:21');
INSERT INTO `users` (`id`, `email`, `password_hash`, `name_th`, `role`, `created_at`) VALUES (7,'teacher1@pes.ac.th','$2a$10$UfkkPEvfPLe5c42Vuut6EesafinqX1Izl0JIKwikuO8YsKYdYoGnW','สมชาย ใจดี','evaluatee','2026-07-14 06:33:21');
INSERT INTO `users` (`id`, `email`, `password_hash`, `name_th`, `role`, `created_at`) VALUES (8,'teacher2@pes.ac.th','$2a$10$UfkkPEvfPLe5c42Vuut6EesafinqX1Izl0JIKwikuO8YsKYdYoGnW','สมหญิง เก่งงาน','evaluatee','2026-07-14 06:33:21');
INSERT INTO `users` (`id`, `email`, `password_hash`, `name_th`, `role`, `created_at`) VALUES (9,'teacher3@pes.ac.th','$2a$10$UfkkPEvfPLe5c42Vuut6EesafinqX1Izl0JIKwikuO8YsKYdYoGnW','มานะ อดทน','evaluatee','2026-07-14 06:33:21');
INSERT INTO `users` (`id`, `email`, `password_hash`, `name_th`, `role`, `created_at`) VALUES (10,'teacher4@pes.ac.th','$2a$10$UfkkPEvfPLe5c42Vuut6EesafinqX1Izl0JIKwikuO8YsKYdYoGnW','กาญจนา ศรีวิไล','evaluatee','2026-07-14 06:33:21');
INSERT INTO `users` (`id`, `email`, `password_hash`, `name_th`, `role`, `created_at`) VALUES (11,'teacher5@pes.ac.th','$2a$10$UfkkPEvfPLe5c42Vuut6EesafinqX1Izl0JIKwikuO8YsKYdYoGnW','ธนากร รุ่งโรจน์','evaluatee','2026-07-14 06:33:21');
INSERT INTO `users` (`id`, `email`, `password_hash`, `name_th`, `role`, `created_at`) VALUES (12,'teacher6@pes.ac.th','$2a$10$UfkkPEvfPLe5c42Vuut6EesafinqX1Izl0JIKwikuO8YsKYdYoGnW','สุพรรณี บุญมาก','evaluatee','2026-07-14 06:33:21');
INSERT INTO `users` (`id`, `email`, `password_hash`, `name_th`, `role`, `created_at`) VALUES (13,'teacher7@pes.ac.th','$2a$10$UfkkPEvfPLe5c42Vuut6EesafinqX1Izl0JIKwikuO8YsKYdYoGnW','อนุชา แก้วมณี','evaluatee','2026-07-14 06:33:21');
INSERT INTO `users` (`id`, `email`, `password_hash`, `name_th`, `role`, `created_at`) VALUES (14,'teacher8@pes.ac.th','$2a$10$UfkkPEvfPLe5c42Vuut6EesafinqX1Izl0JIKwikuO8YsKYdYoGnW','รัตนา ไพศาล','evaluatee','2026-07-14 06:33:21');
INSERT INTO `users` (`id`, `email`, `password_hash`, `name_th`, `role`, `created_at`) VALUES (15,'teacher9@pes.ac.th','$2a$10$UfkkPEvfPLe5c42Vuut6EesafinqX1Izl0JIKwikuO8YsKYdYoGnW','ชัยวัฒน์ สุขสมบูรณ์','evaluatee','2026-07-14 06:33:21');
INSERT INTO `users` (`id`, `email`, `password_hash`, `name_th`, `role`, `created_at`) VALUES (16,'teacher10@pes.ac.th','$2a$10$UfkkPEvfPLe5c42Vuut6EesafinqX1Izl0JIKwikuO8YsKYdYoGnW','มาลี ประดิษฐ์','evaluatee','2026-07-14 06:33:21');

-- รอบการประเมิน 3 รอบ
INSERT INTO `periods` (`id`, `name_th`, `start_date`, `end_date`, `is_active`) VALUES (1,'การประเมินครูประจำปี 2568 ภาคเรียนที่ 1','2025-10-01','2026-03-31',0);
INSERT INTO `periods` (`id`, `name_th`, `start_date`, `end_date`, `is_active`) VALUES (2,'การประเมินครูประจำปี 2568 ภาคเรียนที่ 2','2026-04-01','2026-12-31',1);
INSERT INTO `periods` (`id`, `name_th`, `start_date`, `end_date`, `is_active`) VALUES (3,'การประเมิน วPA ปีการศึกษา 2569','2026-07-01','2026-07-17',1);

-- หัวข้อการประเมิน (3 หัวข้อ x 3 รอบ)
INSERT INTO `topics` (`id`, `period_id`, `name_th`, `description`) VALUES (1,1,'การจัดการเรียนการสอน','คุณภาพการวางแผน สื่อ และการวัดผล');
INSERT INTO `topics` (`id`, `period_id`, `name_th`, `description`) VALUES (2,1,'การพัฒนาตนเอง','อบรม สัมมนา งานวิจัย');
INSERT INTO `topics` (`id`, `period_id`, `name_th`, `description`) VALUES (3,1,'จรรยาบรรณวิชาชีพ','การปฏิบัติตามจรรยาบรรณครู');
INSERT INTO `topics` (`id`, `period_id`, `name_th`, `description`) VALUES (4,2,'การจัดการเรียนการสอน','คุณภาพการวางแผน สื่อ และการวัดผล');
INSERT INTO `topics` (`id`, `period_id`, `name_th`, `description`) VALUES (5,2,'การพัฒนาตนเอง','อบรม สัมมนา งานวิจัย');
INSERT INTO `topics` (`id`, `period_id`, `name_th`, `description`) VALUES (6,2,'จรรยาบรรณวิชาชีพ','การปฏิบัติตามจรรยาบรรณครู');
INSERT INTO `topics` (`id`, `period_id`, `name_th`, `description`) VALUES (7,3,'ด้านการจัดการเรียนรู้','การออกแบบและจัดกระบวนการเรียนรู้');
INSERT INTO `topics` (`id`, `period_id`, `name_th`, `description`) VALUES (8,3,'ด้านการส่งเสริมผู้เรียน','การดูแลช่วยเหลือและพัฒนาผู้เรียน');
INSERT INTO `topics` (`id`, `period_id`, `name_th`, `description`) VALUES (9,3,'ด้านการพัฒนาตนเองและวิชาชีพ','ชุมชนแห่งการเรียนรู้และผลงานวิชาชีพ');

-- ตัวชี้วัด (6 ตัวชี้วัด x 3 รอบ)
INSERT INTO `indicators` (`id`, `topic_id`, `name_th`, `description`, `weight`, `type`, `evidence_kind`, `template_name`, `template_path`, `template_url`) VALUES (1,1,'แผนการจัดการเรียนรู้','แผนสอนสอดคล้องมาตรฐาน',2.00,'score_1_4','pdf,image',NULL,NULL,NULL);
INSERT INTO `indicators` (`id`, `topic_id`, `name_th`, `description`, `weight`, `type`, `evidence_kind`, `template_name`, `template_path`, `template_url`) VALUES (2,1,'สื่อการเรียนรู้','ใบงาน/สื่อมัลติมีเดีย',1.00,'score_1_4','image,url',NULL,NULL,NULL);
INSERT INTO `indicators` (`id`, `topic_id`, `name_th`, `description`, `weight`, `type`, `evidence_kind`, `template_name`, `template_path`, `template_url`) VALUES (3,1,'บันทึกหลังการสอน','สะท้อนผลและปรับปรุง',1.00,'yes_no','pdf',NULL,NULL,NULL);
INSERT INTO `indicators` (`id`, `topic_id`, `name_th`, `description`, `weight`, `type`, `evidence_kind`, `template_name`, `template_path`, `template_url`) VALUES (4,2,'เกียรติบัตรการอบรม','หลักฐานการพัฒนาตนเอง',1.00,'yes_no','pdf,image',NULL,NULL,NULL);
INSERT INTO `indicators` (`id`, `topic_id`, `name_th`, `description`, `weight`, `type`, `evidence_kind`, `template_name`, `template_path`, `template_url`) VALUES (5,2,'งานวิจัยในชั้นเรียน','วิจัย/บทความวิชาการ',2.00,'score_1_4','url,pdf',NULL,NULL,NULL);
INSERT INTO `indicators` (`id`, `topic_id`, `name_th`, `description`, `weight`, `type`, `evidence_kind`, `template_name`, `template_path`, `template_url`) VALUES (6,3,'การปฏิบัติตามจรรยาบรรณ','หลักฐานเชิงประจักษ์',1.00,'score_1_4','pdf,image,url',NULL,NULL,NULL);
INSERT INTO `indicators` (`id`, `topic_id`, `name_th`, `description`, `weight`, `type`, `evidence_kind`, `template_name`, `template_path`, `template_url`) VALUES (7,4,'แผนการจัดการเรียนรู้','แผนสอนสอดคล้องมาตรฐาน',2.00,'score_1_4','pdf,image',NULL,NULL,NULL);
INSERT INTO `indicators` (`id`, `topic_id`, `name_th`, `description`, `weight`, `type`, `evidence_kind`, `template_name`, `template_path`, `template_url`) VALUES (8,4,'สื่อการเรียนรู้','ใบงาน/สื่อมัลติมีเดีย',1.00,'score_1_4','image,url',NULL,NULL,NULL);
INSERT INTO `indicators` (`id`, `topic_id`, `name_th`, `description`, `weight`, `type`, `evidence_kind`, `template_name`, `template_path`, `template_url`) VALUES (9,4,'บันทึกหลังการสอน','สะท้อนผลและปรับปรุง',1.00,'yes_no','pdf',NULL,NULL,NULL);
INSERT INTO `indicators` (`id`, `topic_id`, `name_th`, `description`, `weight`, `type`, `evidence_kind`, `template_name`, `template_path`, `template_url`) VALUES (10,5,'เกียรติบัตรการอบรม','หลักฐานการพัฒนาตนเอง',1.00,'yes_no','pdf,image',NULL,NULL,NULL);
INSERT INTO `indicators` (`id`, `topic_id`, `name_th`, `description`, `weight`, `type`, `evidence_kind`, `template_name`, `template_path`, `template_url`) VALUES (11,5,'งานวิจัยในชั้นเรียน','วิจัย/บทความวิชาการ',2.00,'score_1_4','url,pdf',NULL,NULL,NULL);
INSERT INTO `indicators` (`id`, `topic_id`, `name_th`, `description`, `weight`, `type`, `evidence_kind`, `template_name`, `template_path`, `template_url`) VALUES (12,6,'การปฏิบัติตามจรรยาบรรณ','หลักฐานเชิงประจักษ์',1.00,'score_1_4','pdf,image,url',NULL,NULL,NULL);
INSERT INTO `indicators` (`id`, `topic_id`, `name_th`, `description`, `weight`, `type`, `evidence_kind`, `template_name`, `template_path`, `template_url`) VALUES (13,7,'การออกแบบหน่วยการเรียนรู้','หน่วยการเรียนรู้เชิงรุก (Active Learning)',2.00,'score_1_4','pdf',NULL,NULL,NULL);
INSERT INTO `indicators` (`id`, `topic_id`, `name_th`, `description`, `weight`, `type`, `evidence_kind`, `template_name`, `template_path`, `template_url`) VALUES (14,7,'นวัตกรรมการสอน','สื่อ/นวัตกรรมที่พัฒนาขึ้นเอง',2.00,'score_1_4','pdf,url',NULL,NULL,NULL);
INSERT INTO `indicators` (`id`, `topic_id`, `name_th`, `description`, `weight`, `type`, `evidence_kind`, `template_name`, `template_path`, `template_url`) VALUES (15,8,'การดูแลช่วยเหลือนักเรียน','ระบบดูแลช่วยเหลือรายบุคคล',1.00,'score_1_4','pdf',NULL,NULL,NULL);
INSERT INTO `indicators` (`id`, `topic_id`, `name_th`, `description`, `weight`, `type`, `evidence_kind`, `template_name`, `template_path`, `template_url`) VALUES (16,8,'กิจกรรมพัฒนาผู้เรียน','กิจกรรมเสริมหลักสูตร',1.00,'yes_no','pdf,image',NULL,NULL,NULL);
INSERT INTO `indicators` (`id`, `topic_id`, `name_th`, `description`, `weight`, `type`, `evidence_kind`, `template_name`, `template_path`, `template_url`) VALUES (17,9,'PLC ชุมชนแห่งการเรียนรู้','บันทึกการเข้าร่วม PLC',1.00,'yes_no','pdf',NULL,NULL,NULL);
INSERT INTO `indicators` (`id`, `topic_id`, `name_th`, `description`, `weight`, `type`, `evidence_kind`, `template_name`, `template_path`, `template_url`) VALUES (18,9,'ผลงานเชิงประจักษ์','ผลงาน/รางวัลที่ได้รับ',2.00,'score_1_4','pdf,image,url',NULL,NULL,NULL);

-- มอบหมายกรรมการ (ประธาน+กรรมการร่วม ต่อผู้รับการประเมิน 1 คน)
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (1,1,2,7,'chair','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:21');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (2,1,3,7,'member','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:21');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (3,1,3,8,'chair','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:21');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (4,1,4,8,'member','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:21');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (5,1,4,9,'chair','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:21');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (6,1,5,9,'member','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:21');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (7,1,5,10,'chair','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:21');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (8,1,6,10,'member','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:21');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (9,1,6,11,'chair','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:21');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (10,1,2,11,'member','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:21');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (11,1,2,12,'chair','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:22');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (12,1,3,12,'member','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:22');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (13,1,3,13,'chair','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:22');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (14,1,4,13,'member','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:22');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (15,1,4,14,'chair','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:22');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (16,1,5,14,'member','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:22');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (17,1,5,15,'chair','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:22');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (18,1,6,15,'member','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:22');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (19,1,6,16,'chair','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:22');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (20,1,2,16,'member','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:22');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (21,2,3,7,'chair','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:22');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (22,2,4,7,'member',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (23,2,4,8,'chair',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (24,2,5,8,'member',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (25,2,5,9,'chair','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:22');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (26,2,6,9,'member',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (27,2,6,10,'chair','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:22');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (28,2,2,10,'member',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (29,2,2,11,'chair','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:22');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (30,2,3,11,'member',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (31,2,3,12,'chair',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (32,2,4,12,'member','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:22');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (33,2,4,13,'chair',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (34,2,5,13,'member','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:22');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (35,2,5,14,'chair','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:22');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (36,2,6,14,'member','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:22');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (37,2,6,15,'chair','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:22');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (38,2,2,15,'member',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (39,2,2,16,'chair',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (40,2,3,16,'member','ประเมินตามหลักฐานที่ปรากฏ ผลงานอยู่ในเกณฑ์ดี',NULL,'submitted','2026-07-14 06:33:22');
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (41,3,4,7,'chair',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (42,3,5,7,'member',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (43,3,5,8,'chair',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (44,3,6,8,'member',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (45,3,6,9,'chair',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (46,3,2,9,'member',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (47,3,2,10,'chair',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (48,3,3,10,'member',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (49,3,3,11,'chair',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (50,3,4,11,'member',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (51,3,4,12,'chair',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (52,3,5,12,'member',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (53,3,5,13,'chair',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (54,3,6,13,'member',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (55,3,6,14,'chair',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (56,3,2,14,'member',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (57,3,2,15,'chair',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (58,3,3,15,'member',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (59,3,3,16,'chair',NULL,NULL,'pending',NULL);
INSERT INTO `assignments` (`id`, `period_id`, `evaluator_id`, `evaluatee_id`, `committee_role`, `overall_comment`, `signature_path`, `status`, `submitted_at`) VALUES (60,3,4,16,'member',NULL,NULL,'pending',NULL);

-- ข้อมูล/ประเมินตนเองของผู้รับการประเมิน (ความคืบหน้าไม่เท่ากันในแต่ละรอบ)
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (1,7,1,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด แผนการจัดการเรียนรู้',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (2,7,2,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด สื่อการเรียนรู้',NULL,2.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (3,7,3,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด บันทึกหลังการสอน',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (4,7,4,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด เกียรติบัตรการอบรม',NULL,0.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (5,7,5,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด งานวิจัยในชั้นเรียน',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (6,7,6,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด การปฏิบัติตามจรรยาบรรณ',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (7,8,1,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด แผนการจัดการเรียนรู้',NULL,2.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (8,8,2,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด สื่อการเรียนรู้',NULL,4.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (9,8,3,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด บันทึกหลังการสอน',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (10,8,4,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด เกียรติบัตรการอบรม',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (11,8,5,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด งานวิจัยในชั้นเรียน',NULL,3.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (12,8,6,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด การปฏิบัติตามจรรยาบรรณ',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (13,9,1,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด แผนการจัดการเรียนรู้',NULL,3.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (14,9,2,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด สื่อการเรียนรู้',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (15,9,3,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด บันทึกหลังการสอน',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (16,9,4,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด เกียรติบัตรการอบรม',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (17,9,5,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด งานวิจัยในชั้นเรียน',NULL,4.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (18,9,6,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด การปฏิบัติตามจรรยาบรรณ',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (19,10,1,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด แผนการจัดการเรียนรู้',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (20,10,2,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด สื่อการเรียนรู้',NULL,2.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (21,10,3,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด บันทึกหลังการสอน',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (22,10,4,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด เกียรติบัตรการอบรม',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (23,10,5,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด งานวิจัยในชั้นเรียน',NULL,4.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (24,10,6,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด การปฏิบัติตามจรรยาบรรณ',NULL,4.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (25,11,1,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด แผนการจัดการเรียนรู้',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (26,11,2,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด สื่อการเรียนรู้',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (27,11,3,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด บันทึกหลังการสอน',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (28,11,4,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด เกียรติบัตรการอบรม',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (29,11,5,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด งานวิจัยในชั้นเรียน',NULL,3.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (30,11,6,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด การปฏิบัติตามจรรยาบรรณ',NULL,4.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (31,12,1,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด แผนการจัดการเรียนรู้',NULL,2.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (32,12,2,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด สื่อการเรียนรู้',NULL,3.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (33,12,3,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด บันทึกหลังการสอน',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (34,12,4,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด เกียรติบัตรการอบรม',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (35,12,5,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด งานวิจัยในชั้นเรียน',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (36,12,6,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด การปฏิบัติตามจรรยาบรรณ',NULL,2.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (37,13,1,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด แผนการจัดการเรียนรู้',NULL,3.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (38,13,2,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด สื่อการเรียนรู้',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (39,13,3,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด บันทึกหลังการสอน',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (40,13,4,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด เกียรติบัตรการอบรม',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (41,13,5,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด งานวิจัยในชั้นเรียน',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (42,13,6,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด การปฏิบัติตามจรรยาบรรณ',NULL,3.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (43,14,1,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด แผนการจัดการเรียนรู้',NULL,3.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (44,14,2,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด สื่อการเรียนรู้',NULL,3.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (45,14,3,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด บันทึกหลังการสอน',NULL,0.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (46,14,4,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด เกียรติบัตรการอบรม',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (47,14,5,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด งานวิจัยในชั้นเรียน',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (48,14,6,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด การปฏิบัติตามจรรยาบรรณ',NULL,3.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (49,15,1,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด แผนการจัดการเรียนรู้',NULL,4.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (50,15,2,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด สื่อการเรียนรู้',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (51,15,3,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด บันทึกหลังการสอน',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (52,15,4,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด เกียรติบัตรการอบรม',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (53,15,5,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด งานวิจัยในชั้นเรียน',NULL,2.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (54,15,6,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด การปฏิบัติตามจรรยาบรรณ',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (55,16,1,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด แผนการจัดการเรียนรู้',NULL,4.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (56,16,2,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด สื่อการเรียนรู้',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (57,16,3,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด บันทึกหลังการสอน',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (58,16,4,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด เกียรติบัตรการอบรม',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (59,16,5,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด งานวิจัยในชั้นเรียน',NULL,4.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (60,16,6,1,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด การปฏิบัติตามจรรยาบรรณ',NULL,2.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (61,9,7,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด แผนการจัดการเรียนรู้',NULL,2.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (62,9,8,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด สื่อการเรียนรู้',NULL,3.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (63,9,9,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด บันทึกหลังการสอน',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (64,9,10,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด เกียรติบัตรการอบรม',NULL,0.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (65,9,11,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด งานวิจัยในชั้นเรียน',NULL,3.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (66,9,12,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด การปฏิบัติตามจรรยาบรรณ',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (67,10,7,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด แผนการจัดการเรียนรู้',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (68,10,8,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด สื่อการเรียนรู้',NULL,3.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (69,10,9,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด บันทึกหลังการสอน',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (70,10,10,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด เกียรติบัตรการอบรม',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (71,10,11,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด งานวิจัยในชั้นเรียน',NULL,4.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (72,10,12,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด การปฏิบัติตามจรรยาบรรณ',NULL,2.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (73,11,7,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด แผนการจัดการเรียนรู้',NULL,3.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (74,11,8,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด สื่อการเรียนรู้',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (75,11,9,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด บันทึกหลังการสอน',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (76,11,10,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด เกียรติบัตรการอบรม',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (77,11,11,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด งานวิจัยในชั้นเรียน',NULL,2.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (78,11,12,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด การปฏิบัติตามจรรยาบรรณ',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (79,12,7,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด แผนการจัดการเรียนรู้',NULL,2.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (80,12,8,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด สื่อการเรียนรู้',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (81,12,9,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด บันทึกหลังการสอน',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (82,12,10,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด เกียรติบัตรการอบรม',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (83,12,11,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด งานวิจัยในชั้นเรียน',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (84,12,12,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด การปฏิบัติตามจรรยาบรรณ',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (85,13,7,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด แผนการจัดการเรียนรู้',NULL,3.5,'อยู่ระหว่างดำเนินการ');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (86,13,8,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด สื่อการเรียนรู้',NULL,2.0,'อยู่ระหว่างดำเนินการ');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (87,13,9,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด บันทึกหลังการสอน',NULL,1.0,'อยู่ระหว่างดำเนินการ');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (88,14,7,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด แผนการจัดการเรียนรู้',NULL,2.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (89,14,8,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด สื่อการเรียนรู้',NULL,3.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (90,14,9,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด บันทึกหลังการสอน',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (91,14,10,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด เกียรติบัตรการอบรม',NULL,0.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (92,14,11,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด งานวิจัยในชั้นเรียน',NULL,2.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (93,14,12,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด การปฏิบัติตามจรรยาบรรณ',NULL,3.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (94,15,7,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด แผนการจัดการเรียนรู้',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (95,15,8,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด สื่อการเรียนรู้',NULL,3.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (96,15,9,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด บันทึกหลังการสอน',NULL,0.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (97,15,10,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด เกียรติบัตรการอบรม',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (98,15,11,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด งานวิจัยในชั้นเรียน',NULL,2.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (99,15,12,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด การปฏิบัติตามจรรยาบรรณ',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (100,16,7,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด แผนการจัดการเรียนรู้',NULL,4.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (101,16,8,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด สื่อการเรียนรู้',NULL,2.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (102,16,9,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด บันทึกหลังการสอน',NULL,0.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (103,16,10,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด เกียรติบัตรการอบรม',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (104,16,11,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด งานวิจัยในชั้นเรียน',NULL,3.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (105,16,12,2,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด การปฏิบัติตามจรรยาบรรณ',NULL,2.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (106,9,13,3,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด การออกแบบหน่วยการเรียนรู้',NULL,3.0,'อยู่ระหว่างดำเนินการ');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (107,9,14,3,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด นวัตกรรมการสอน',NULL,4.0,'อยู่ระหว่างดำเนินการ');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (108,13,13,3,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด การออกแบบหน่วยการเรียนรู้',NULL,2.0,'อยู่ระหว่างดำเนินการ');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (109,13,14,3,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด นวัตกรรมการสอน',NULL,3.5,'อยู่ระหว่างดำเนินการ');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (110,15,13,3,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด การออกแบบหน่วยการเรียนรู้',NULL,4.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (111,15,14,3,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด นวัตกรรมการสอน',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (112,15,15,3,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด การดูแลช่วยเหลือนักเรียน',NULL,4.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (113,15,16,3,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด กิจกรรมพัฒนาผู้เรียน',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (114,15,17,3,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด PLC ชุมชนแห่งการเรียนรู้',NULL,1.0,'ดำเนินการครบถ้วนตามที่กำหนด');
INSERT INTO `evidences` (`id`, `evaluatee_id`, `indicator_id`, `period_id`, `detail`, `url`, `self_score`, `self_note`) VALUES (115,15,18,3,'หลักฐาน/ผลการดำเนินงานตัวชี้วัด ผลงานเชิงประจักษ์',NULL,3.5,'ดำเนินการครบถ้วนตามที่กำหนด');

-- ผลการให้คะแนนของกรรมการ
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (1,1,1,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (2,1,2,2.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (3,1,3,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (4,1,4,0.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (5,1,5,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (6,1,6,2.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (7,2,1,2.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (8,2,2,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (9,2,3,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (10,2,4,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (11,2,5,2.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (12,2,6,2.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (13,3,1,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (14,3,2,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (15,3,3,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (16,3,4,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (17,3,5,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (18,3,6,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (19,4,1,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (20,4,2,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (21,4,3,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (22,4,4,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (23,4,5,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (24,4,6,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (25,5,1,2.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (26,5,2,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (27,5,3,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (28,5,4,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (29,5,5,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (30,5,6,2.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (31,6,1,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (32,6,2,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (33,6,3,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (34,6,4,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (35,6,5,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (36,6,6,2.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (37,7,1,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (38,7,2,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (39,7,3,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (40,7,4,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (41,7,5,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (42,7,6,2.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (43,8,1,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (44,8,2,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (45,8,3,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (46,8,4,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (47,8,5,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (48,8,6,2.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (49,9,1,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (50,9,2,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (51,9,3,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (52,9,4,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (53,9,5,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (54,9,6,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (55,10,1,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (56,10,2,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (57,10,3,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (58,10,4,0.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (59,10,5,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (60,10,6,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (61,11,1,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (62,11,2,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (63,11,3,0.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (64,11,4,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (65,11,5,2.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (66,11,6,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (67,12,1,2.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (68,12,2,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (69,12,3,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (70,12,4,0.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (71,12,5,2.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (72,12,6,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (73,13,1,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (74,13,2,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (75,13,3,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (76,13,4,0.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (77,13,5,2.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (78,13,6,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (79,14,1,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (80,14,2,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (81,14,3,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (82,14,4,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (83,14,5,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (84,14,6,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (85,15,1,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (86,15,2,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (87,15,3,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (88,15,4,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (89,15,5,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (90,15,6,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (91,16,1,2.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (92,16,2,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (93,16,3,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (94,16,4,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (95,16,5,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (96,16,6,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (97,17,1,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (98,17,2,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (99,17,3,0.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (100,17,4,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (101,17,5,2.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (102,17,6,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (103,18,1,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (104,18,2,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (105,18,3,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (106,18,4,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (107,18,5,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (108,18,6,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (109,19,1,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (110,19,2,2.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (111,19,3,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (112,19,4,0.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (113,19,5,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (114,19,6,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (115,20,1,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (116,20,2,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (117,20,3,0.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (118,20,4,0.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (119,20,5,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (120,20,6,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (121,21,7,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (122,21,8,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (123,21,9,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (124,21,10,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (125,21,11,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (126,21,12,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (127,22,7,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (128,22,8,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (129,22,9,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (130,23,7,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (131,23,8,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (132,23,9,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (133,25,7,2.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (134,25,8,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (135,25,9,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (136,25,10,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (137,25,11,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (138,25,12,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (139,26,7,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (140,26,8,2.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (141,26,9,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (142,27,7,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (143,27,8,2.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (144,27,9,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (145,27,10,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (146,27,11,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (147,27,12,2.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (148,28,7,2.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (149,28,8,2.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (150,28,9,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (151,29,7,2.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (152,29,8,2.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (153,29,9,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (154,29,10,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (155,29,11,2.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (156,29,12,2.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (157,30,7,2.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (158,30,8,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (159,30,9,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (160,32,7,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (161,32,8,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (162,32,9,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (163,32,10,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (164,32,11,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (165,32,12,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (166,33,7,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (167,33,8,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (168,33,9,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (169,34,7,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (170,34,8,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (171,34,9,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (172,34,10,0.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (173,34,11,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (174,34,12,2.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (175,35,7,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (176,35,8,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (177,35,9,0.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (178,35,10,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (179,35,11,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (180,35,12,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (181,36,7,2.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (182,36,8,2.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (183,36,9,0.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (184,36,10,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (185,36,11,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (186,36,12,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (187,37,7,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (188,37,8,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (189,37,9,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (190,37,10,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (191,37,11,2.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (192,37,12,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (193,38,7,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (194,38,8,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (195,38,9,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (196,40,7,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (197,40,8,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (198,40,9,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (199,40,10,1.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (200,40,11,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (201,40,12,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (202,43,13,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (203,43,14,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (204,44,13,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (205,44,14,3.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (206,49,13,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (207,49,14,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (208,51,13,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (209,51,14,4.0,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (210,53,13,3.5,NULL);
INSERT INTO `reviews` (`id`, `assignment_id`, `indicator_id`, `score`, `comment`) VALUES (211,53,14,3.0,NULL);
