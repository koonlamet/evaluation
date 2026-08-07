// แจ้งเตือนรวมศูนย์ — เรียก useSnackbar().show('ข้อความ', 'error'|'success')
export const useSnackbar = () => {
  // state = สถานะกล่องแจ้งเตือน (Nuxt useState = state กลางตัวเดียวใช้ร่วมกันทุกหน้า) — v-snackbar ใน app.vue อ่านค่านี้ไปแสดง
  const state = useState("snackbar", () => ({ show: false, text: "", color: "success" }));
  const show = (text, color = "success") => (state.value = { show: true, text, color }); // text = ข้อความที่จะโชว์, color = สี ("success" เขียว, "error" แดง)
  return { state, show };
};
