<template>
  <div>
    <h2 class="mb-4">ติดตามสถานะการประเมิน</h2>
    <!-- อาจมีหลายรอบประเมินเปิดพร้อมกัน เลือกดูทีละรอบ -->
    <v-select
      v-model="selectedPeriodId" label="รอบการประเมิน" variant="outlined" density="comfortable"
      :items="periods.map((p) => ({ title: p.name_th, value: p.id }))"
      class="mb-2" style="max-width: 420px"
    />

    <!-- แถบสรุปรวม + เตือนใกล้หมดเขต -->
    <div class="d-flex flex-wrap ga-2 mb-4">
      <v-chip color="indigo" variant="tonal">กรรมการส่งผลแล้ว {{ evaluatorSubmittedCount }}/{{ evaluatorRows.length }} ใบ</v-chip>
      <v-chip color="teal" variant="tonal">ผู้รับการประเมินกรอกครบ {{ evaluateeDoneCount }}/{{ byEvaluatee.length }} คน</v-chip>
      <v-chip v-if="daysLeft != null" :color="urgent ? 'red' : 'grey'" :variant="urgent ? 'flat' : 'tonal'">
        {{ daysLeft >= 0 ? `เหลือเวลา ${daysLeft} วัน` : "หมดเขตแล้ว" }}
      </v-chip>
    </div>

    <v-tabs v-model="tab" color="indigo" class="mb-4">
      <v-tab value="evaluator">สถานะกรรมการ</v-tab>
      <v-tab value="evaluatee">สถานะผู้รับการประเมิน</v-tab>
    </v-tabs>

    <!-- 5.1.10-5.1.11: กรรมการแต่ละคนประเมินใครไปแล้ว/ใครยังไม่ประเมิน (คนที่ยังค้างอยู่ขึ้นก่อน) -->
    <div v-show="tab === 'evaluator'">
      <v-card v-for="grp in byEvaluator" :key="grp.evaluator_id" class="mb-4">
        <v-card-title class="d-flex align-center">
          <v-icon class="mr-2">mdi-account-tie</v-icon>{{ grp.evaluator_name }}
          <v-spacer />
          <span class="text-caption text-grey">
            ประเมินแล้ว {{ grp.rows.filter(r => r.status === 'submitted').length }}/{{ grp.rows.length }} คน
          </span>
        </v-card-title>
        <v-table density="comfortable" class="fixed-table">
          <thead>
            <tr>
              <th style="width: 35%">ผู้รับการประเมิน</th><th style="width: 25%">บทบาทของกรรมการ</th>
              <th style="width: 20%">สถานะ</th><th style="width: 20%">การจัดการ</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="r in grp.rows" :key="r.assignment_id">
              <td>{{ r.evaluatee_name }}</td>
              <td>{{ r.committee_role === 'chair' ? 'ประธานกรรมการ' : 'กรรมการ' }}</td>
              <td>
                <v-chip size="small" :color="r.status === 'submitted' ? 'green' : (urgent ? 'red' : 'orange')">
                  {{ r.status === 'submitted' ? 'ประเมินแล้ว' : 'รอประเมิน' }}
                </v-chip>
              </td>
              <td>
                <v-btn size="small" variant="text" :to="`/admin/report/${r.evaluatee_id}?period=${selectedPeriodId}`">ดูรายงาน</v-btn>
                <!-- ให้กรรมการที่ส่งผลผิดพลาดแก้ไขได้อีกครั้ง (ปลดล็อก = สถานะกลับเป็นรอประเมิน + ล้างลายเซ็นเดิม ต้องเซ็นรับรองใหม่) -->
                <v-btn
                  v-if="r.status === 'submitted'" size="small" variant="text" color="red"
                  @click="unlockAssignment(r)"
                >
                  ปลดล็อก
                </v-btn>
              </td>
            </tr>
          </tbody>
        </v-table>
      </v-card>
      <v-alert v-if="!byEvaluator.length" type="info" variant="tonal">ยังไม่มีการมอบหมายกรรมการ</v-alert>
    </div>

    <!-- 5.1.12: ผู้รับการประเมินแต่ละคนกรอกข้อมูลตนเองไปแล้วกี่ตัวชี้วัด (คนที่ยังกรอกไม่ครบขึ้นก่อน) -->
    <div v-show="tab === 'evaluatee'">
      <v-table density="comfortable" class="fixed-table">
        <thead>
          <tr>
            <th style="width: 30%">ผู้รับการประเมิน</th><th style="width: 35%">ความคืบหน้าประเมินตนเอง</th>
            <th class="text-center" style="width: 20%">กรรมการส่งผลแล้ว</th><th style="width: 15%"></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="e in byEvaluateeSorted" :key="e.id">
            <td>{{ e.name_th }}</td>
            <td style="min-width: 220px">
              <div class="d-flex align-center ga-2">
                <v-progress-linear :model-value="e.percent" height="14" color="green" rounded style="flex:1" />
                <span class="text-caption">{{ e.filled }}/{{ e.totalIndicators }}</span>
              </div>
            </td>
            <td class="text-center">{{ e.evaluatorsSubmitted }}/{{ e.evaluatorsTotal }}</td>
            <td><v-btn size="small" variant="text" :to="`/admin/report/${e.id}?period=${selectedPeriodId}`">ดูรายงาน</v-btn></td>
          </tr>
          <tr v-if="!byEvaluatee.length"><td colspan="4" class="text-center text-grey">ยังไม่มีผู้รับการประเมิน</td></tr>
        </tbody>
      </v-table>
    </div>
  </div>
</template>

<script setup>
definePageMeta({ layout: "dashboard" });
const api = useApi();
const route = useRoute();
const tab = ref("evaluator"); // แท็บที่เปิดอยู่ (สถานะกรรมการ / สถานะผู้รับการประเมิน)
const periods = ref([]); // รอบทั้งหมด ป้อน dropdown เลือกรอบ
const selectedPeriodId = ref(null); // รอบที่กำลังดูสถานะอยู่
const evaluatorRows = ref([]), byEvaluatee = ref([]); // evaluatorRows = ข้อมูลดิบจาก /api/tracking/evaluators (ยังไม่จัดกลุ่ม), byEvaluatee = ข้อมูลจาก /api/tracking/evaluatees (จัดกลุ่มมาจาก backend แล้ว)

// จัดกลุ่มรายการดิบตามกรรมการ (ทำฝั่ง client เพราะข้อมูลไม่เยอะ) — คนที่ยังไม่ประเมิน (pending) ขึ้นก่อนในแต่ละกลุ่ม
const byEvaluator = computed(() => {
  const map = new Map(); // map = กรรมการ 1 คน → { ชื่อ, รายชื่อผู้รับที่ต้องประเมิน } (Map กันซ้ำ + เข้าถึงเร็ว)
  for (const r of evaluatorRows.value) { // r = ใบมอบหมาย 1 ใบ (กรรมการ+ผู้รับ+สถานะ)
    if (!map.has(r.evaluator_id)) map.set(r.evaluator_id, { evaluator_id: r.evaluator_id, evaluator_name: r.evaluator_name, rows: [] });
    map.get(r.evaluator_id).rows.push(r);
  }
  for (const grp of map.values()) grp.rows.sort((a, b) => (a.status === "submitted") - (b.status === "submitted")); // grp = กรรมการ 1 คนพร้อมงานทั้งหมด — เรียง pending ก่อน submitted
  return [...map.values()];
});
// คนที่ยังกรอกไม่ครบขึ้นก่อน
const byEvaluateeSorted = computed(() => [...byEvaluatee.value].sort((a, b) => a.percent - b.percent));

const evaluatorSubmittedCount = computed(() => evaluatorRows.value.filter((r) => r.status === "submitted").length); // จำนวนใบที่กรรมการส่งผลแล้ว (ตัวเลขในแถบสรุป)
const evaluateeDoneCount = computed(() => byEvaluatee.value.filter((e) => e.percent === 100).length); // จำนวนผู้รับการประเมินที่กรอกครบ 100%

// เตือนใกล้หมดเขตของรอบที่เลือก (≤3 วัน → แดง)
const selectedPeriod = computed(() => periods.value.find((p) => p.id === selectedPeriodId.value)); // ข้อมูลเต็มของรอบที่เลือก (เอา end_date มาคำนวณ)
const daysLeft = computed(() => {
  if (!selectedPeriod.value?.end_date) return null;
  return Math.ceil((new Date(selectedPeriod.value.end_date) - new Date()) / 86400000); // จำนวนวันที่เหลือ (86400000 = มิลลิวินาทีใน 1 วัน)
});
const urgent = computed(() => daysLeft.value != null && daysLeft.value <= 3); // true ถ้าเหลือเวลา 3 วันหรือน้อยกว่า → ใช้เปลี่ยนสีเป็นแดงเตือน

// ปลดล็อกใบประเมินที่กรรมการส่งแล้ว (กรณีกรอกผิดมาขอแก้) → POST /api/assignments/:id/unlock
// backend รีเซ็ต status→pending + ล้างลายเซ็น → โหลดตารางใหม่ให้เห็นสถานะกลับเป็น "รอประเมิน"
async function unlockAssignment(r) {
  if (!confirm(`ปลดล็อกใบประเมินของ "${r.evaluator_name}" ที่ประเมิน "${r.evaluatee_name}"? กรรมการจะต้องเซ็นรับรองส่งใหม่อีกครั้ง`)) return;
  const { data } = await api.post(`/api/assignments/${r.assignment_id}/unlock`);
  useSnackbar().show(data.message);
  loadTracking();
}

// โหลดข้อมูลติดตามสถานะของรอบที่เลือก 2 ชุด:
// GET /api/tracking/evaluators → ใบประเมินรายกรรมการ (จัดกลุ่มต่อใน byEvaluator ฝั่ง client)
// GET /api/tracking/evaluatees → ความคืบหน้าประเมินตนเองรายคน → ตารางแท็บที่สอง
async function loadTracking() {
  if (!selectedPeriodId.value) return;
  const params = { period_id: selectedPeriodId.value };
  evaluatorRows.value = (await api.get("/api/tracking/evaluators", { params })).data.items;
  byEvaluatee.value = (await api.get("/api/tracking/evaluatees", { params })).data.items;
}
watch(selectedPeriodId, loadTracking);

onMounted(async () => {
  periods.value = (await api.get("/api/periods", { params: { itemsPerPage: 100 } })).data.items;
  // ถ้ากลับมาจากหน้ารายงาน (มี ?period= ติดมา) ให้คงรอบเดิมที่เลือกไว้ก่อนหน้า ไม่งั้นค่อยใช้รอบที่เปิดใช้งานอยู่
  const fromQuery = periods.value.find((p) => String(p.id) === String(route.query.period));
  selectedPeriodId.value = fromQuery?.id ?? periods.value.find((p) => p.is_active)?.id ?? periods.value[0]?.id;
});
</script>

<style scoped>
/* บังคับ column width % ให้มีผลจริง (table-layout: auto ค่า default จะให้แต่ละการ์ดคำนวณความกว้างคอลัมน์เองตามความยาวชื่อในการ์ดนั้นๆ
   ทำให้แต่ละการ์ดกรรมการมีเส้นแบ่งคอลัมน์ไม่ตรงกัน) fixed บังคับให้ทุกการ์ดใช้สัดส่วน % เดียวกันหมด */
.fixed-table :deep(table) {
  table-layout: fixed;
}
</style>
