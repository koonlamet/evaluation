<template>
  <v-main class="d-flex align-center justify-center" style="min-height: 100vh">
    <v-progress-circular indeterminate color="indigo" />
  </v-main>
</template>

<script setup>
// หน้าแรก: เด้งไปตามบทบาท (ถ้าไม่มี token/user ล้าง localStorage แล้วไป login — กันค้าง/ลูป)
definePageMeta({ layout: "default" });
const { user } = useAuth(); // user = ข้อมูลผู้ใช้ที่ล็อกอินอยู่ (อ่านจาก state กลาง/localStorage)
onMounted(() => {
  const token = localStorage.getItem("token"); // เช็คว่ามี token ค้างอยู่ไหม (อาจไม่มีถ้ายังไม่เคย login)
  if (!token || !user.value?.role) { // ไม่มี token หรือข้อมูล user เสียหาย/ไม่ครบ → ถือว่ายังไม่ login
    localStorage.clear();
    return navigateTo("/login");
  }
  const home = { admin: "/admin", evaluator: "/eval", evaluatee: "/me" }; // แผนที่ บทบาท → หน้าแรกของบทบาทนั้น
  navigateTo(home[user.value.role] || "/login"); // เด้งไปหน้าแรกตามบทบาท (ถ้า role แปลกไม่รู้จัก → กลับไป login)
});
</script>
