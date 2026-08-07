<template>
  <div>
    <h2 class="mb-4">แบบประเมินของฉัน</h2>
    <!-- อาจมีหลายรอบประเมินเปิดพร้อมกัน (เช่น ประเมินการสอน + ประเมิน PA) เลือกเข้าไปกรอกทีละรอบ -->
    <v-row>
      <v-col v-for="p in periods" :key="p.id" cols="12" sm="6" md="4" class="d-flex">
        <v-card class="pa-4 d-flex flex-column h-100" hover :to="`/me/period/${p.id}`" style="width: 100%">
          <h3>{{ p.name_th }}</h3>
          <div class="text-caption text-grey mb-2">{{ p.start_date?.slice(0, 10) }} — {{ p.end_date?.slice(0, 10) }}</div>
          <v-progress-linear :model-value="p.percent" height="16" color="green" rounded class="mb-1">
            {{ p.percent }}%
          </v-progress-linear>
          <div class="text-caption">กรอกแล้ว {{ p.filled }}/{{ p.total }} ตัวชี้วัด</div>
          <v-btn color="indigo" size="small" class="mt-auto py-3" block>เข้าประเมิน</v-btn>
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
const periods = ref([]); // รอบประเมินที่เปิดอยู่ พร้อมความคืบหน้าของตนเอง (filled/total/percent) — ป้อนการ์ดรายรอบ
// โหลดรอบประเมินที่เปิดอยู่ + ความคืบหน้าของตนเองแต่ละรอบ จาก GET /api/evidences/periods
// → แสดงเป็นการ์ดรายรอบ กด "เข้าประเมิน" ไปกรอกที่ /me/period/:id
onMounted(async () => {
  periods.value = (await useApi().get("/api/evidences/periods")).data.items;
});
</script>
