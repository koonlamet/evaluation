<template>
  <div>
    <h2 class="mb-4">รายชื่อผู้รับการประเมินที่ต้องประเมิน</h2>
    <v-table hover>
      <thead>
        <tr><th>รอบการประเมิน</th><th>ผู้รับการประเมิน</th><th>อีเมล</th><th>บทบาทของฉัน</th><th>สถานะ</th><th></th></tr>
      </thead>
      <tbody>
        <tr v-for="a in items" :key="a.id">
          <td>{{ a.period_name }}</td>
          <td>{{ a.evaluatee }}</td>
          <td>{{ a.email }}</td>
          <td>{{ a.committee_role === 'chair' ? 'ประธาน' : 'กรรมการร่วม' }}</td>
          <td>
            <v-chip size="small" :color="a.status === 'submitted' ? 'green' : 'orange'">
              {{ a.status === 'submitted' ? 'ส่งผลแล้ว' : 'รอประเมิน' }}
            </v-chip>
          </td>
          <td><v-btn size="small" color="indigo" :to="`/eval/${a.id}`">ประเมิน</v-btn></td>
        </tr>
        <tr v-if="!items.length"><td colspan="6" class="text-center text-grey">ยังไม่มีงานที่ได้รับมอบหมาย</td></tr>
      </tbody>
    </v-table>
  </div>
</template>

<script setup>
definePageMeta({ layout: "dashboard" });
const items = ref([]); // รายการใบมอบหมายทั้งหมดของกรรมการคนนี้ (พร้อมสถานะ) — ป้อนตารางในหน้า
// โหลดรายการงานที่กรรมการคนนี้ต้องประเมิน จาก GET /api/reviews/assignments (กรองตาม token ของผู้ล็อกอิน)
// → แสดงเป็นตารางด้านบน กดปุ่ม "ประเมิน" ไปหน้า /eval/:assignmentId
onMounted(async () => {
  items.value = (await useApi().get("/api/reviews/assignments")).data.items;
});
</script>
