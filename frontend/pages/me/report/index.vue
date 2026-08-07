<template>
  <div>
    <h2 class="mb-4">รายงานผลการประเมิน</h2>
    <!-- อาจมีหลายรอบประเมินพร้อมกัน เลือกดูรายงานทีละรอบ -->
    <v-row>
      <v-col v-for="p in periods" :key="p.id" cols="12" sm="6" md="4">
        <v-card class="pa-4" hover :to="`/me/report/${p.id}`">
          <h3>{{ p.name_th }}</h3>
          <div class="text-caption text-grey mb-3">{{ p.start_date?.slice(0, 10) }} — {{ p.end_date?.slice(0, 10) }}</div>
          <v-btn color="indigo" size="small" block>ดูรายงาน/ส่งออก PDF</v-btn>
        </v-card>
      </v-col>
    </v-row>
    <v-alert v-if="!periods.length" type="info" variant="tonal">
      ยังไม่มีรอบการประเมินที่เปิดใช้งานอยู่ในขณะนี้
    </v-alert>
  </div>
</template>

<script setup>
definePageMeta({ layout: "dashboard" });
const periods = ref([]); // รอบประเมินที่เปิดอยู่ ป้อนการ์ดเลือกรอบ
// โหลดรอบประเมินที่เปิดอยู่ จาก GET /api/evidences/periods → การ์ดเลือกรอบ กดไปดูรายงานที่ /me/report/:id
onMounted(async () => {
  periods.value = (await useApi().get("/api/evidences/periods")).data.items;
});
</script>
