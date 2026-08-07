// กันไม่ให้ error จาก API (เช่น 403/เครือข่ายล่ม) โผล่เป็น error แดงใน Console
// (ข้อความถูกแจ้งผ่าน snackbar กลางแล้วใน useApi) — ช่วยให้ Console สะอาดตามเกณฑ์ 7.7
export default defineNuxtPlugin((nuxtApp) => { // nuxtApp = instance ของแอป Nuxt (ใช้ตั้งค่าระดับแอปทั้งหมดตอนเริ่มทำงาน)
  nuxtApp.vueApp.config.errorHandler = (err) => { // err = error ที่หลุดออกมาจากที่ไหนก็ได้ในแอป Vue (ไม่ถูก try/catch ดักไว้)
    if (err?.isAxiosError) return; // error จากการเรียก API ถูกจัดการ (โชว์ snackbar) ใน useApi.js อยู่แล้ว ไม่ต้องทำซ้ำที่นี่
    console.warn("[app]", err?.message || err); // error อื่นๆ (บั๊กจริงในโค้ด) log ไว้เบาๆ ให้ dev เห็น ไม่ทำให้ผู้ใช้ตกใจ
  };
});
