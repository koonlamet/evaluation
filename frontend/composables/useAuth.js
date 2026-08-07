// จัดการสถานะผู้ใช้ล็อกอิน (เก็บ token/user ใน localStorage)
export const useAuth = () => {
  // user = สถานะผู้ใช้ที่ล็อกอินอยู่ (Nuxt useState = state กลางที่ทุก component เรียกใช้ตัวเดียวกันได้)
  // ค่าเริ่มต้น: อ่านจาก localStorage ถ้ามี (กันหน้ารีเฟรชแล้ว user หายไป) — import.meta.client กันไม่ให้รันฝั่ง server (SSR ไม่มี localStorage)
  const user = useState("user", () => {
    const raw = import.meta.client ? localStorage.getItem("user") : null; // raw = ข้อความ JSON ที่เก็บไว้ (หรือ null ถ้ายังไม่เคย login)
    return raw ? JSON.parse(raw) : null;
  });

  // ส่ง email/password → POST /api/auth/login → เก็บ JWT+ข้อมูลผู้ใช้ลง localStorage และ state กลาง
  // (token ถูก useApi แนบเป็น header อัตโนมัติทุก request หลังจากนี้)
  const login = async (email, password) => {
    const { data } = await useApi().post("/api/auth/login", { email, password }); // data = { accessToken, user } ที่ backend ตอบกลับ
    localStorage.setItem("token", data.accessToken); // เก็บ token ไว้ใช้แนบทุก request ต่อไป
    localStorage.setItem("user", JSON.stringify(data.user)); // เก็บข้อมูลผู้ใช้ไว้กันรีเฟรชหน้าแล้วหาย
    user.value = data.user; // อัปเดต state กลางทันที ให้ทุกหน้าที่ใช้ user เปลี่ยนตาม
    return data.user;
  };

  // ล้าง token/user ทั้ง localStorage และ state → เด้งไปหน้า login (ใช้ทั้งปุ่มออกจากระบบ และหลังเปลี่ยนรหัสผ่าน)
  const logout = () => {
    localStorage.clear();
    user.value = null;
    navigateTo("/login");
  };

  return { user, login, logout };
};
