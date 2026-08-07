<template>
  <div>
    <h2 class="mb-4">จัดการผู้ใช้งาน</h2>
    <v-tabs v-model="tab" color="indigo" class="mb-4">
      <v-tab value="admin">งานบุคลากร</v-tab>
      <v-tab value="evaluator">กรรมการ</v-tab>
      <v-tab value="evaluatee">ผู้รับการประเมิน</v-tab>
    </v-tabs>

    <!-- แยกกลุ่มตามบทบาท จัดการง่ายขึ้น + เรียงชื่อจากน้อยไปมาก (ก-ฮ) เป็นค่าเริ่มต้น -->
    <v-window v-model="tab">
      <v-window-item v-for="r in roleList" :key="r.value" :value="r.value">
        <CrudTable
          :title="r.label"
          endpoint="/api/users"
          :extra-params="{ role: r.value }"
          :new-defaults="{ role: r.value }"
          default-sort-by="name_th"
          :headers="[
            { title: 'รหัส', key: 'id' },
            { title: 'ชื่อ', key: 'name_th' },
            { title: 'อีเมล', key: 'email' },
          ]"
          :fields="[
            { key: 'name_th', label: 'ชื่อ-นามสกุล' },
            { key: 'email', label: 'อีเมล' },
            { key: 'password', label: 'รหัสผ่าน (เว้นว่าง = ไม่เปลี่ยน)', type: 'password' },
          ]"
        />
      </v-window-item>
    </v-window>
  </div>
</template>

<script setup>
definePageMeta({ layout: "dashboard" });
const tab = ref("admin"); // แท็บที่เปิดอยู่ (ค่าตรงกับ role ในฐานข้อมูล)
const roleList = [ // รายชื่อบทบาททั้งหมด ใช้สร้างทั้งแท็บและ CrudTable ของแต่ละแท็บ (1 CrudTable ต่อ 1 บทบาท กรองด้วย extra-params)
  { value: "admin", label: "งานบุคลากร (admin)" },
  { value: "evaluator", label: "กรรมการ (evaluator)" },
  { value: "evaluatee", label: "ผู้รับการประเมิน (evaluatee)" },
];
</script>
