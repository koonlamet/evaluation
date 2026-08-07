import vuetify, { transformAssetUrls } from "vite-plugin-vuetify";

// SPA อย่างเดียว (ssr:false) → ง่ายต่อการใช้ localStorage/JWT ไม่ต้องกังวล hydration
export default defineNuxtConfig({
  ssr: false,
  devtools: { enabled: false },
  build: { transpile: ["vuetify"] },
  css: ["vuetify/styles", "@mdi/font/css/materialdesignicons.min.css"],

  modules: [
    (_, nuxt) => {
      nuxt.hooks.hook("vite:extendConfig", (cfg) => {
        cfg.plugins.push(vuetify({ autoImport: true }));
      });
    },
  ],

  vite: { vue: { template: { transformAssetUrls } } },

  runtimeConfig: {
    public: { apiBase: process.env.NUXT_PUBLIC_API_BASE || "http://localhost:7000" },
  },

  compatibilityDate: "2026-07-10",
});