<template>
  <v-card width="100%" max-width="400" class="pa-4">
    <v-card-title class="text-center text-h6">สมัครใช้งาน (ผู้รับการประเมิน)</v-card-title>
    <v-card-text>
      <v-form @submit.prevent="submit">
        <v-text-field v-model="form.name_th" label="ชื่อ-นามสกุล" variant="outlined" />
        <v-text-field v-model="form.email" label="อีเมล" variant="outlined" />
        <v-text-field v-model="form.password" label="รหัสผ่าน (อย่างน้อย 6 ตัว)" type="password" variant="outlined" />

        <v-btn type="submit" color="indigo" block :loading="loading">สมัครสมาชิก</v-btn>
      </v-form>
      <div class="text-center mt-3"><NuxtLink to="/login">กลับไปหน้าเข้าสู่ระบบ</NuxtLink></div>
    </v-card-text>
  </v-card>
</template>
<script setup>

definePageMeta({ layout: "default" });
const form = ref({ name_th: "", email: "", password: "" }); // ค่าที่กรอกในฟอร์มสมัคร (ส่งตรงไป backend ทั้งก้อน)

const loading = ref(false); // true ระหว่างรอ backend ตอบ (โชว์ spinner บนปุ่ม)

// ส่งข้อมูลฟอร์มสมัคร → POST /api/auth/register (backend validate + สร้าง user บทบาท evaluatee)
// สำเร็จ: เด้งไปหน้า login ให้เข้าสู่ระบบด้วยบัญชีที่เพิ่งสร้าง
async function submit() {
  loading.value = true;
  try {
    await useApi().post("/api/auth/register", form.value);
    useSnackbar().show("สมัครสำเร็จ กรุณาเข้าสู่ระบบ");
    navigateTo("/login");
  } catch {
    /* snackbar กลางแสดง error validate ให้แล้ว */
  } finally {
    loading.value = false;
  }
}
</script>
