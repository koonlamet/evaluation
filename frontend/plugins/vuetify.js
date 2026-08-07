import { createVuetify } from "vuetify";

// สร้าง Vuetify instance (ธีม + ไอคอน mdi)
export default defineNuxtPlugin((nuxtApp) => { // nuxtApp = instance ของแอป Nuxt
  nuxtApp.vueApp.use(
    createVuetify({
      theme: { defaultTheme: "light" }, // ธีมเริ่มต้นของทั้งแอป (สว่าง)
      icons: { defaultSet: "mdi" },     // ชุดไอคอนที่ใช้ (Material Design Icons — เช่น mdi-account, mdi-delete ที่เห็นทั่วแอป)
    })
  );
});
