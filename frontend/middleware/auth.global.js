// ป้องกันหน้าที่ต้องล็อกอิน: ไม่มี token → เด้งไป /login
// (ไม่เด้งกลับกรณีมี token + อยู่หน้า login เพื่อกัน redirect วนลูป — ให้ index/หน้า login จัดการเอง)
export default defineNuxtRouteMiddleware((to) => { // to = หน้าที่ผู้ใช้กำลังจะไป (ทำงานก่อนเข้าทุกหน้า เพราะชื่อไฟล์ลงท้าย .global)
  if (import.meta.server) return; // ฝั่ง server (SSR) ไม่มี localStorage ให้เช็ค ข้ามไปก่อน รอเช็คฝั่ง client แทน
  const publicPages = ["/login", "/register"]; // หน้าที่เข้าได้โดยไม่ต้อง login
  const hasToken = !!localStorage.getItem("token"); // true ถ้ามี token เก็บไว้ (แปลว่าเคย login แล้ว)
  if (!hasToken && !publicPages.includes(to.path)) return navigateTo("/login"); // ไม่มี token และหน้าที่จะไปไม่ใช่หน้า public → เด้งไป login
});
