<template>
  <v-card width="100%" max-width="400" class="pa-4">
    <v-card-title class="text-center text-h6">เข้าสู่ระบบประเมินบุคลากร</v-card-title>
    <v-card-text>
      <v-form @submit.prevent="submit">
        <v-text-field v-model="email" label="อีเมล" variant="outlined" prepend-inner-icon="mdi-email" />
        <v-text-field
          v-model="password" label="รหัสผ่าน" type="password" variant="outlined"
          prepend-inner-icon="mdi-lock"
        />
        <v-btn type="submit" color="indigo" block :loading="loading">เข้าสู่ระบบ</v-btn>
      </v-form>
      <div class="text-center mt-3">
        ยังไม่มีบัญชี? <NuxtLink to="/register">สมัคร (ผู้รับการประเมิน)</NuxtLink>
      </div>
      <v-alert type="info" variant="tonal" density="compact" class="mt-3 text-caption">
        ทดสอบ: admin@pes.ac.th / eval1@pes.ac.th / teacher1@pes.ac.th — รหัส 123456
      </v-alert>
    </v-card-text>
  </v-card>
</template>

<script setup>
definePageMeta({ layout: "default" });
const { login } = useAuth(); // ฟังก์ชัน login จาก composable กลาง (ยิง API + เก็บ token ให้เสร็จในตัว)
const email = ref(""), password = ref(""), loading = ref(false); // ค่าที่พิมพ์ในฟอร์ม + สถานะกำลังส่ง (โชว์ spinner บนปุ่ม)

// ส่ง email/password จากฟอร์ม → POST /api/auth/login (ผ่าน useAuth)
// สำเร็จ: token+user ถูกเก็บลง localStorage แล้วเด้งไป "/" ให้ index.vue พาไปหน้าแรกตามบทบาท
async function submit() {
  loading.value = true;
  try {
    await login(email.value, password.value);
    useSnackbar().show("เข้าสู่ระบบสำเร็จ");
    navigateTo("/");
  } catch {
    /* error แสดงผ่าน snackbar กลางแล้ว */
  } finally {
    loading.value = false;
  }
}
</script>
