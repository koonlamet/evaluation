// ตัวเชื่อมฐานข้อมูล MySQL ด้วย Knex (ใช้ที่เดียว import ไปทุก controller)
require("dotenv").config();

module.exports = require("knex")({
  client: "mysql2", // ไดรเวอร์ฐานข้อมูลที่ใช้ (mysql2 คุยกับ MySQL/MariaDB)
  connection: {
    host: process.env.DB_HOST || "127.0.0.1",     // เครื่อง/container ที่รัน MySQL อยู่ (ใน docker-compose คือ "db")
    port: Number(process.env.DB_PORT) || 3306,     // พอร์ตของ MySQL
    user: process.env.DB_USER || "root",           // ผู้ใช้ MySQL
    password: process.env.DB_PASS || "rootpassword", // รหัสผ่าน MySQL
    database: process.env.DB_NAME || "pes_db",     // ชื่อฐานข้อมูลที่จะเชื่อมต่อ
    dateStrings: true, // คืนค่า DATE/DATETIME เป็น string ตรง ๆ (กัน timezone แปลงวันที่เพี้ยนตอนผ่าน JS Date object)
  },
  pool: { min: 0, max: 10 }, // pool = กลุ่ม connection ที่เปิดค้างไว้ใช้ซ้ำ (อย่างน้อย 0 อย่างมาก 10 connection พร้อมกัน)
});
