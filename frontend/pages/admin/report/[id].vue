<template>
  <div>
    <div class="d-flex align-center mb-2 ga-3 flex-wrap">
      <v-btn icon="mdi-arrow-left" variant="text" :to="`/admin/tracking?period=${route.query.period}`" />
      <!-- ดูค่าเฉลี่ยรวม หรือดูคะแนนดิบของกรรมการทีละคน -->
      <v-select
        v-model="evaluatorId" label="ดูคะแนน" :items="evaluatorOptions"
        variant="outlined" density="compact" hide-details style="max-width: 280px"
      />
    </div>
    <EvaluationReport :summary="sum" />
  </div>
</template>

<script setup>
// 5.1.13 งานบุคลากรดูรายงานผลการประเมินรายบุคคลของผู้รับการประเมินคนใดก็ได้
definePageMeta({ layout: "dashboard" });
const route = useRoute();
const id = route.params.id; // id ของผู้รับการประเมินที่จะดูรายงาน (มาจาก URL เช่น /admin/report/7)
const sum = ref({}); // ผลลัพธ์เต็มจาก GET /api/summary/:id (ส่งต่อให้ <EvaluationReport>)
const evaluatorId = ref(null); // null = ค่าเฉลี่ยรวมทุกกรรมการ (ค่าเริ่มต้น)

const evaluatorOptions = computed(() => [ // ตัวเลือกใน dropdown "ดูคะแนน" — ตัวแรกคงที่ (ค่าเฉลี่ยรวม) ตามด้วยกรรมการแต่ละคนจาก sum.committees
  { title: "ค่าเฉลี่ยรวมทุกกรรมการ", value: null },
  ...(sum.value.committees || []).map((c) => ({ title: c.evaluator, value: c.evaluator_id })),
]);

// โหลดสรุปผลของผู้รับการประเมินคนนี้ จาก GET /api/summary/:id → ส่งให้ <EvaluationReport> แสดง
// เลือกกรรมการใน dropdown → ส่ง evaluator_id ไปด้วย ได้คะแนนดิบของกรรมการคนนั้นแทนค่าเฉลี่ยรวม
async function load() {
  sum.value = (await useApi().get(`/api/summary/${id}`, {
    params: { period_id: route.query.period, evaluator_id: evaluatorId.value || undefined },
  })).data;
}
watch(evaluatorId, load);
onMounted(load);
</script>
