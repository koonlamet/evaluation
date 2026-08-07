<template>
  <div>
    <h2 class="mb-4">ภาพรวมระบบ</h2>

    <!-- การ์ดสรุปตัวเลข -->
    <v-row>
      <v-col cols="6" md="3" v-for="c in cards" :key="c.label">
        <v-card :color="c.color" theme="dark" class="pa-3">
          <div class="text-h4">{{ c.value }}</div>
          <div>{{ c.label }}</div>
        </v-card>
      </v-col>
    </v-row>

    <!-- แผนภูมิแท่ง: คะแนนเฉลี่ยรายหัวข้อ/ตัวชี้วัด (โจทย์พิเศษ 8.5) -->
    <v-card class="mt-4 pa-4">
      <div class="d-flex align-center flex-wrap ga-3 mb-3">
        <h3>คะแนนเฉลี่ยจากกรรมการ</h3>
        <v-spacer />
        <v-select
          v-model="selectedPeriodId" label="รอบการประเมิน" :items="periods.map((p) => ({ title: p.name_th, value: p.id }))"
          variant="outlined" density="compact" hide-details style="max-width: 260px"
        />
        <v-btn-toggle v-model="level" color="indigo" density="comfortable" mandatory variant="outlined">
          <v-btn value="topic" size="small">รายหัวข้อ</v-btn>
          <v-btn value="indicator" size="small">รายตัวชี้วัด</v-btn>
        </v-btn-toggle>
      </div>
      <!-- max-width จำกัดขนาดจริงของ svg ไว้ ไม่งั้นบนจอกว้างการ์ดจะยืดเต็มจอ แล้วตัวอักษร (หน่วยเป็น viewBox unit) จะถูกขยายใหญ่ตามไม่มีเพดาน -->
      <!-- +6 กันขอบล่าง: แท่งของแถวสุดท้ายวาดถึง y=46 ภายในแถวตัวเอง (32+14) แต่ rowHeight โหมดหัวข้อมีแค่ 44
           แถวอื่นไม่โดนตัดเพราะมีพื้นที่แถวถัดไปกันไว้ แถวสุดท้ายชนขอบ viewBox พอดีจนมุมโค้งด้านล่างถูกตัด -->
      <svg
        v-if="stats.byTopic?.length" :viewBox="`0 0 600 ${stats.byTopic.length * rowHeight + 6}`"
        width="100%" style="max-width: 640px; display: block"
      >
        <g v-for="(b, i) in stats.byTopic" :key="i" :transform="`translate(0,${i * rowHeight})`">
          <!-- ตอนดูรายตัวชี้วัด แสดงชื่อหัวข้อกำกับไว้เหนือชื่อตัวชี้วัด ว่ามาจากหัวข้อไหน -->
          <text v-if="b.group_topic" x="0" y="10" font-size="10" fill="#888">{{ b.group_topic }}</text>
          <text x="0" y="26" font-size="13">{{ b.topic }}</text>
          <!-- หัวข้อ/ตัวชี้วัดที่ยังไม่มีกรรมการให้คะแนนเลย (avg_score เป็น null) โชว์ข้อความแทนแท่งกราฟ ไม่ใช่ซ่อนออกจากกราฟ -->
          <template v-if="b.avg_score == null">
            <text x="0" y="44" font-size="12" fill="#aaa">ยังไม่มีคะแนน</text>
          </template>
          <template v-else>
            <rect x="0" y="32" :width="b.avg_score / 4 * 510" height="14" fill="#3949ab" rx="3" />
            <text :x="b.avg_score / 4 * 510 + 9" y="44" font-size="12">{{ b.avg_score }}</text>
          </template>
        </g>
      </svg>
      <v-alert v-else type="info" variant="tonal" density="compact">
        ยังไม่มีคะแนนจากกรรมการ (แผนภูมิจะแสดงเมื่อกรรมการเริ่มประเมิน)
      </v-alert>
    </v-card>

    <!-- สำรอง/กู้คืนข้อมูล (โจทย์พิเศษ 8.4) -->
    <v-card class="mt-4 pa-4">
      <h3 class="mb-3">สำรอง / กู้คืนข้อมูล</h3>
      <v-btn color="green" prepend-icon="mdi-content-save" :loading="busy" @click="backup" class="mr-2">
        สำรองข้อมูลตอนนี้
      </v-btn>
      <v-table density="compact" class="mt-3">
        <thead><tr><th>ไฟล์สำรอง (snapshot)</th><th>ขนาดข้อมูล</th><th>ไฟล์แนบ</th><th></th></tr></thead>
        <tbody>
          <tr v-for="b in backups" :key="b.file">
            <td>{{ b.file }}</td>
            <td>{{ (b.size / 1024).toFixed(1) }} KB</td>
            <td>
              <v-chip v-if="b.hasFiles" size="small" color="teal" prepend-icon="mdi-paperclip">
                {{ (b.filesSize / 1024).toFixed(1) }} KB
              </v-chip>
              <span v-else class="text-caption text-grey">ไม่มี</span>
            </td>
            <td class="text-right">
              <v-btn size="small" color="orange" variant="tonal" class="mr-2" @click="restore(b.file)">กู้คืน</v-btn>
              <v-btn size="small" color="red" variant="tonal" icon="mdi-delete" @click="removeBackup(b.file)" />
            </td>
          </tr>
          <tr v-if="!backups.length"><td colspan="4" class="text-center text-grey">ยังไม่มีไฟล์สำรอง</td></tr>
        </tbody>
      </v-table>
    </v-card>
  </div>
</template>

<script setup>
definePageMeta({ layout: "dashboard" });
const api = useApi();
const stats = ref({}), backups = ref([]), busy = ref(false); // stats = ผลลัพธ์จาก /api/stats ทั้งก้อน, backups = รายการไฟล์สำรอง, busy = true ระหว่างกำลังสำรองข้อมูล (โชว์ spinner)
const periods = ref([]), selectedPeriodId = ref(null), level = ref("topic"); // periods = รอบทั้งหมด (ป้อน dropdown), selectedPeriodId = รอบที่กำลังดูอยู่, level = ความละเอียดกราฟ (รายหัวข้อ/รายตัวชี้วัด)

const cards = computed(() => [ // การ์ดตัวเลข 4 ใบบนสุด คำนวณจาก stats ที่โหลดมา
  { label: "ผู้รับการประเมิน", value: stats.value.roles?.evaluatee || 0, color: "indigo" },
  { label: "กรรมการ", value: stats.value.roles?.evaluator || 0, color: "teal" },
  { label: "ประเมินแล้ว", value: stats.value.submitted || 0, color: "green" },
  { label: "รอประเมิน", value: stats.value.pending || 0, color: "orange" },
]);

const rowHeight = computed(() => (level.value === "indicator" ? 48 : 44)); // ความสูงต่อแถวของกราฟ SVG (โหมดรายตัวชี้วัดมีบรรทัดชื่อหัวข้อกำกับเพิ่ม เลยสูงกว่า)

// โหลดสถิติ dashboard จาก GET /api/stats (จำนวนคนตามบทบาท, นับส่งแล้ว/รอ, คะแนนเฉลี่ยถ่วงน้ำหนัก)
// → การ์ดตัวเลข 4 ใบ + กราฟแท่ง SVG ด้านล่าง (level เลือกดูรายหัวข้อหรือรายตัวชี้วัด)
async function loadStats() {
  stats.value = (await api.get("/api/stats", { params: { period_id: selectedPeriodId.value, level: level.value } })).data;
}
// โหลดรายการไฟล์สำรองจาก GET /api/backups → ตารางสำรอง/กู้คืนท้ายหน้า
async function loadBackups() { backups.value = (await api.get("/api/backups")).data.items; }
watch([selectedPeriodId, level], loadStats);

// สั่งสร้าง snapshot ใหม่ → POST /api/backup (backend dump ทุกตาราง + สำเนาโฟลเดอร์ไฟล์แนบ) แล้วโหลดรายการใหม่
async function backup() {
  busy.value = true;
  try {
    await api.post("/api/backup");
    useSnackbar().show("สำรองข้อมูลสำเร็จ");
    loadBackups();
  } finally { busy.value = false; }
}
// กู้คืนจาก snapshot ที่เลือก → POST /api/restore/:file (แทนที่ข้อมูลทุกตาราง + ไฟล์แนบทั้งโฟลเดอร์) แล้วรีเฟรชสถิติ
async function restore(file) {
  if (!confirm("กู้คืนข้อมูลจากไฟล์นี้? ข้อมูล+ไฟล์แนบปัจจุบันจะถูกแทนที่")) return;
  const { data } = await api.post(`/api/restore/${file}`);
  useSnackbar().show(data.message);
  loadStats();
}
// ลบ snapshot → DELETE /api/backups/:file (ลบทั้ง json และโฟลเดอร์ไฟล์แนบคู่กัน) แล้วโหลดรายการใหม่
async function removeBackup(file) {
  if (!confirm(`ลบไฟล์สำรอง "${file}" นี้? ไม่สามารถกู้คืนกลับมาได้อีก`)) return;
  const { data } = await api.delete(`/api/backups/${file}`);
  useSnackbar().show(data.message);
  loadBackups();
}

onMounted(async () => {
  periods.value = (await api.get("/api/periods", { params: { itemsPerPage: 100 } })).data.items;
  selectedPeriodId.value = periods.value.find((p) => p.is_active)?.id ?? periods.value[0]?.id;
  loadBackups();
});
</script>
