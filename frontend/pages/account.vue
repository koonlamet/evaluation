<template>
  <div>
    <h2 class="mb-4">บัญชีผู้ใช้</h2>
    <v-card class="pa-4 mb-4" max-width="480">
      <h3 class="mb-3">ข้อมูลส่วนตัว</h3>
      <v-text-field v-model="profile.name_th" label="ชื่อ-นามสกุล" variant="outlined" density="comfortable" />
      <!-- อีเมลใช้เป็น username สำหรับ login แก้เองไม่ได้ (กัน session ที่หลุดไปอยู่มือคนอื่นยึดบัญชีด้วยการเปลี่ยนอีเมล)
           ต้องการเปลี่ยนอีเมลติดต่องานบุคลากรที่หน้า "ผู้ใช้งาน" -->
      <v-text-field :model-value="profile.email" label="อีเมล (สำหรับเข้าสู่ระบบ)" variant="outlined" density="comfortable"
        readonly hint="แก้ไขอีเมลไม่ได้ที่นี่ — ติดต่องานบุคลากรหากต้องการเปลี่ยน" persistent-hint />
      <v-btn color="indigo" prepend-icon="mdi-content-save" class="mt-4" :loading="profileBusy" @click="saveProfile">บันทึก</v-btn>
    </v-card>

    <!-- เปลี่ยนรหัสผ่าน แยกฟอร์มจากข้อมูลส่วนตัว บังคับยืนยันรหัสผ่านเดิมก่อนเสมอ (ทุกบทบาท: งานบุคลากร/กรรมการ/ผู้รับการประเมิน) -->
    <v-card class="pa-4" max-width="480">
      <h3 class="mb-3">เปลี่ยนรหัสผ่าน</h3>
      <v-text-field
        v-model="pwd.current_password" label="รหัสผ่านเดิม" type="password"
        variant="outlined" density="comfortable" autocomplete="current-password"
      />
      <v-text-field
        v-model="pwd.new_password" label="รหัสผ่านใหม่" type="password"
        variant="outlined" density="comfortable" autocomplete="new-password"
      />
      <v-text-field
        v-model="pwd.confirm_password" label="ยืนยันรหัสผ่านใหม่" type="password"
        variant="outlined" density="comfortable" autocomplete="new-password"
        :error-messages="confirmError"
      />
      <v-btn color="indigo" prepend-icon="mdi-lock-reset" :loading="pwdBusy" @click="changePassword">เปลี่ยนรหัสผ่าน</v-btn>
    </v-card>
  </div>
</template>

<script setup>
definePageMeta({ layout: "dashboard" });
const api = useApi();
const { user, logout } = useAuth();
const profile = ref({ name_th: "", email: "" }); // ข้อมูลส่วนตัวที่แสดง/แก้ในฟอร์ม (email แสดงอย่างเดียว แก้ไม่ได้)
const profileBusy = ref(false); // true ระหว่างกำลังบันทึกชื่อ (โชว์ spinner บนปุ่ม)

const pwd = ref({ current_password: "", new_password: "", confirm_password: "" }); // ค่าที่กรอกในฟอร์มเปลี่ยนรหัสผ่าน
const pwdBusy = ref(false); // true ระหว่างกำลังส่งเปลี่ยนรหัสผ่าน
const confirmError = computed(() => // ข้อความ error ใต้ช่องยืนยันรหัสผ่าน โชว์เฉพาะตอนกรอกแล้วไม่ตรงกับรหัสใหม่
  pwd.value.confirm_password && pwd.value.new_password !== pwd.value.confirm_password
    ? "รหัสผ่านใหม่ทั้งสองช่องไม่ตรงกัน" : ""
);

// โหลดข้อมูลตนเองจาก GET /api/users/me → เติมฟอร์มชื่อ + โชว์อีเมล (read-only)
onMounted(async () => {
  const { data } = await api.get("/api/users/me");
  profile.value = { name_th: data.data.name_th, email: data.data.email };
});

// บันทึกชื่อใหม่ → PUT /api/users/me (backend รับเฉพาะ name_th) → อัปเดต user ใน state+localStorage ให้ชื่อบน app bar เปลี่ยนตาม
async function saveProfile() {
  profileBusy.value = true;
  try {
    const { data } = await api.put("/api/users/me", { name_th: profile.value.name_th });
    user.value = { ...user.value, name: data.data.name_th };
    localStorage.setItem("user", JSON.stringify(user.value));
    useSnackbar().show("บันทึกข้อมูลสำเร็จ");
  } finally { profileBusy.value = false; }
}

// ส่งรหัสผ่านเดิม+ใหม่ → PUT /api/users/me/password (backend เทียบรหัสเดิมกับ hash ก่อน จึงยอมเปลี่ยน)
// สำเร็จ → บังคับ login ใหม่ทันที (token เดิมยังไม่หมดอายุฝั่ง server แต่เคลียร์ฝั่งนี้ทิ้ง
// เพื่อให้พฤติกรรมตรงกับที่ผู้ใช้คาดหวัง และกันใช้ต่อบนเครื่อง/แท็บเดิมโดยไม่ตั้งใจ)
async function changePassword() {
  if (pwd.value.new_password !== pwd.value.confirm_password) return;
  pwdBusy.value = true;
  try {
    await api.put("/api/users/me/password", {
      current_password: pwd.value.current_password,
      new_password: pwd.value.new_password,
    });
    useSnackbar().show("เปลี่ยนรหัสผ่านสำเร็จ กรุณาเข้าสู่ระบบใหม่");
    logout();
  } finally { pwdBusy.value = false; }
}
</script>
