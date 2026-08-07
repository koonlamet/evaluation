import axios from "axios";

// axios instance เดียวของทั้งระบบ: แนบ token อัตโนมัติ + ดักจับ error แจ้งเตือนรวมศูนย์
export const useApi = () => {
  const api = axios.create({ baseURL: useRuntimeConfig().public.apiBase }); // api = axios instance ตัวใหม่ ตั้ง base URL เป็นที่อยู่ backend (มาจาก nuxt.config.ts)

  // แนบ JWT ทุก request
  api.interceptors.request.use((cfg) => { // cfg = ค่าตั้งต้นของ request ที่กำลังจะยิงออกไป (ใส่ header เพิ่มได้ก่อนส่งจริง)
    const t = localStorage.getItem("token"); // t = token ที่เก็บไว้ตอน login (null ถ้ายังไม่ login)
    if (t) cfg.headers.Authorization = "Bearer " + t; // แนบ token ไปกับทุก request อัตโนมัติ ไม่ต้องเขียนซ้ำทุกหน้า
    return cfg;
  });

  // จัดการ error ที่เดียว: โชว์ snackbar + เตะออกเมื่อ token หมดอายุ (โจทย์พิเศษ 8.6)
  api.interceptors.response.use(
    (res) => res, // request สำเร็จ ส่งผลลัพธ์ต่อไปตามปกติ
    (err) => { // err = error ที่เกิดขึ้น (ทั้ง backend ตอบ error กลับมา และเชื่อมต่อไม่ได้เลย)
      const msg = err.response?.data?.message || "เชื่อมต่อเซิร์ฟเวอร์ไม่สำเร็จ"; // ข้อความจาก backend ถ้ามี ไม่งั้นใช้ข้อความกลางกรณีต่อเซิร์ฟเวอร์ไม่ได้เลย
      useSnackbar().show(msg, "error"); // โชว์แจ้งเตือนสีแดงมุมจอ ทุกหน้าไม่ต้องเขียน try/catch ดักเอง
      if (err.response?.status === 401) { // 401 = token หมดอายุ/ไม่ถูกต้อง
        localStorage.removeItem("token");
        navigateTo("/login"); // เตะกลับไปหน้า login ให้เข้าสู่ระบบใหม่
      }
      return Promise.reject(err); // ส่ง error ต่อให้โค้ดที่เรียก (เผื่ออยากดักเพิ่มเป็นกรณีๆ)
    }
  );
  return api;
};
