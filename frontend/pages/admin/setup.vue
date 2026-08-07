<template>
  <div>
    <h2 class="mb-4">ตั้งค่าการประเมิน</h2>
    <!-- รวม 3 ขั้นตอนของ "การประเมินเดียวกัน" ไว้ในหน้าเดียว: กำหนดรอบ → ตั้งหัวข้อ/ตัวชี้วัด → มอบหมายกรรมการ -->
    <v-tabs v-model="tab" color="indigo" class="mb-4">
      <v-tab value="period">1. ช่วงเวลาประเมิน</v-tab>
      <v-tab value="topics">2. หัวข้อ/ตัวชี้วัด</v-tab>
      <v-tab value="assign">3. มอบหมายกรรมการ</v-tab>
    </v-tabs>

    <!-- ขั้นที่ 1: ช่วงเวลาการประเมิน (5.1.2) -->
    <div v-show="tab === 'period'">
      <CrudTable
        title="ช่วงเวลาการประเมิน"
        endpoint="/api/periods"
        :headers="[
          { title: 'รหัส', key: 'id' },
          { title: 'ชื่อรอบ', key: 'name_th' },
          { title: 'เริ่ม', key: 'start_date' },
          { title: 'สิ้นสุด', key: 'end_date' },
          { title: 'เปิดใช้', key: 'is_active' },
        ]"
        :fields="[
          { key: 'name_th', label: 'ชื่อรอบการประเมิน' },
          { key: 'start_date', label: 'วันเริ่ม', type: 'date' },
          { key: 'end_date', label: 'วันสิ้นสุด', type: 'date' },
          { key: 'is_active', label: 'สถานะ', type: 'select', items: [{ title: 'เปิด', value: 1 }, { title: 'ปิด', value: 0 }] },
        ]"
        @update:options="loadPeriods"
        @changed="loadPeriods"
      />
    </div>

    <!-- ขั้นที่ 2: หัวข้อและตัวชี้วัด ผูกกับรอบการประเมินที่เลือก (5.1.1, 5.1.3, 5.1.4, 5.1.5) -->
    <div v-show="tab === 'topics'">
      <v-select
        v-model="selectedPeriodId" label="กำลังตั้งค่าหัวข้อ/ตัวชี้วัดของรอบ" variant="outlined" density="comfortable"
        :items="periods.map((p) => ({ title: p.name_th + (p.is_active ? ' (เปิดใช้งาน)' : ''), value: p.id }))"
        class="mb-4" style="max-width: 420px"
      />
      <v-alert v-if="!periods.length" type="warning" variant="tonal" density="compact" class="mb-4">
        ยังไม่มีช่วงเวลาการประเมิน — ไปสร้างที่แท็บ "1. ช่วงเวลาประเมิน" ก่อน แล้วจึงตั้งหัวข้อ/ตัวชี้วัดของรอบนั้นได้
      </v-alert>

      <CrudTable
        v-if="selectedPeriodId"
        title="หัวข้อการประเมิน"
        endpoint="/api/topics"
        :extra-params="{ period_id: selectedPeriodId }"
        :new-defaults="{ period_id: selectedPeriodId }"
        :headers="[{ title: 'รหัส', key: 'id' }, { title: 'ชื่อหัวข้อ', key: 'name_th' }, { title: 'คำอธิบาย', key: 'description' }]"
        :fields="[{ key: 'name_th', label: 'ชื่อหัวข้อ' }, { key: 'description', label: 'คำอธิบาย', type: 'textarea' }]"
        @update:options="loadTopics"
        @changed="loadTopics"
      />

      <h3 class="mt-8 mb-2">ตัวชี้วัดในแต่ละหัวข้อ</h3>
      <v-expansion-panels multiple variant="accordion">
        <v-expansion-panel v-for="t in topics" :key="t.id">
          <v-expansion-panel-title>
            <span>{{ t.name_th }}</span>
            <v-chip size="x-small" class="ml-2">{{ indicatorsOf(t.id).length }} ตัวชี้วัด</v-chip>
          </v-expansion-panel-title>
          <v-expansion-panel-text>
            <v-table density="comfortable">
              <thead>
                <tr>
                  <th>ชื่อตัวชี้วัด</th><th>น้ำหนัก</th><th>รูปแบบการประเมิน</th><th>หลักฐานที่แนบได้</th><th>แม่แบบจาก HR</th><th></th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="ind in indicatorsOf(t.id)" :key="ind.id">
                  <td>{{ ind.name_th }}</td>
                  <td>{{ ind.type === 'yes_no' ? '-' : ind.weight }}</td>
                  <td>{{ ind.type === 'yes_no' ? 'มี/ไม่มี' : 'สเกลคะแนน 1-4' }}</td>
                  <td>
                    <v-chip v-for="k in kindList(ind.evidence_kind)" :key="k" size="x-small" class="mr-1">
                      {{ kindLabel(k) }}
                    </v-chip>
                  </td>
                  <td>
                    <v-chip v-if="ind.template_path" size="small" color="teal" class="mr-1"
                      :href="apiBase + ind.template_path" target="_blank" prepend-icon="mdi-file-download"
                    >{{ ind.template_name }}</v-chip>
                    <v-chip v-if="ind.template_url" size="small" color="blue" class="mr-1"
                      :href="ind.template_url" target="_blank" prepend-icon="mdi-link"
                    >ลิงก์อ้างอิง</v-chip>
                    <span v-if="!ind.template_path && !ind.template_url" class="text-caption text-grey">-</span>
                  </td>
                  <td>
                    <v-icon size="small" class="mr-2" @click="openEditIndicator(t.id, ind)">mdi-pencil</v-icon>
                    <v-icon size="small" color="red" @click="removeIndicator(ind)">mdi-delete</v-icon>
                  </td>
                </tr>
                <tr v-if="!indicatorsOf(t.id).length">
                  <td colspan="6" class="text-center text-grey">ยังไม่มีตัวชี้วัดในหัวข้อนี้</td>
                </tr>
              </tbody>
            </v-table>
            <v-btn size="small" color="indigo" prepend-icon="mdi-plus" class="mt-2" @click="openAddIndicator(t.id)">
              เพิ่มตัวชี้วัด
            </v-btn>
          </v-expansion-panel-text>
        </v-expansion-panel>
      </v-expansion-panels>
      <v-alert v-if="!topics.length" type="info" variant="tonal" density="compact" class="mt-3">
        ยังไม่มีหัวข้อการประเมิน — เพิ่มหัวข้อด้านบนก่อน แล้วจึงเพิ่มตัวชี้วัดใต้หัวข้อนั้นได้
      </v-alert>

      <v-dialog v-model="indicatorDialog" max-width="520">
        <v-card>
          <v-card-title>{{ editingIndicator ? "แก้ไข" : "เพิ่ม" }}ตัวชี้วัด</v-card-title>
          <v-card-text>
            <v-text-field v-model="indicatorForm.name_th" label="ชื่อตัวชี้วัด" variant="outlined" density="comfortable" />
            <v-textarea v-model="indicatorForm.description" label="รายละเอียด" variant="outlined" rows="2" />
            <v-select
              v-model="indicatorForm.type" label="รูปแบบการประเมิน" variant="outlined" density="comfortable"
              :items="[{ title: 'สเกลคะแนน 1-4', value: 'score_1_4' }, { title: 'มี/ไม่มี', value: 'yes_no' }]"
            />
            <!-- มี/ไม่มี เป็นการตรวจสอบผ่านเกณฑ์ ไม่ใช่คะแนน จึงไม่มีน้ำหนักให้ตั้ง -->
            <v-text-field
              v-if="indicatorForm.type !== 'yes_no'" v-model="indicatorForm.weight"
              label="น้ำหนักคะแนน" type="number" variant="outlined" density="comfortable"
            />
            <div class="text-caption mb-1">หลักฐานประกอบการประเมิน (เลือกได้มากกว่า 1)</div>
            <v-checkbox v-model="indicatorForm.evidence_kinds" label="ไฟล์ PDF" value="pdf" density="compact" hide-details />
            <v-checkbox v-model="indicatorForm.evidence_kinds" label="ไฟล์รูปภาพ" value="image" density="compact" hide-details />
            <v-checkbox v-model="indicatorForm.evidence_kinds" label="ลิงก์ URL" value="url" density="compact" hide-details />

            <v-divider class="my-4" />
            <div class="text-caption mb-1">แม่แบบ/ตัวอย่างจากฝ่ายบุคลากร (ไม่บังคับ) — ให้ผู้รับการประเมินดาวน์โหลดไปดูก่อนกรอก</div>
            <v-file-input
              v-model="templateFile" label="แนบไฟล์แม่แบบ (PDF/รูปภาพ)" variant="outlined" density="compact"
              prepend-icon="mdi-paperclip" show-size
            />
            <v-chip v-if="editingIndicator?.template_path && !templateFile" size="small" color="teal" closable
              :href="apiBase + editingIndicator.template_path" target="_blank" class="mb-2"
              @click:close="removeTemplate"
            >{{ editingIndicator.template_name }}</v-chip>
            <v-text-field
              v-model="indicatorForm.template_url" label="ลิงก์อ้างอิง (URL)" variant="outlined" density="comfortable"
            />
          </v-card-text>
          <v-card-actions>
            <v-spacer />
            <v-btn @click="indicatorDialog = false">ยกเลิก</v-btn>
            <v-btn color="indigo" @click="saveIndicator">บันทึก</v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
    </div>

    <!-- ขั้นที่ 3: มอบหมายกรรมการ + กำหนดบทบาท (5.1.8, 5.1.9) — แบ่งตามรอบประเมินเหมือนหัวข้อ/ตัวชี้วัด -->
    <div v-show="tab === 'assign'">
      <v-select
        v-model="selectedPeriodId" label="กำลังมอบหมายกรรมการของรอบ" variant="outlined" density="comfortable"
        :items="periods.map((p) => ({ title: p.name_th + (p.is_active ? ' (เปิดใช้งาน)' : ''), value: p.id }))"
        class="mb-4" style="max-width: 420px"
      />
      <CrudTable
        v-if="selectedPeriodId"
        title="การมอบหมายกรรมการ"
        endpoint="/api/assignments"
        :extra-params="{ period_id: selectedPeriodId }"
        :new-defaults="{ period_id: selectedPeriodId }"
        :headers="[
          { title: 'กรรมการผู้ประเมิน', key: 'evaluator_name' },
          { title: 'ผู้รับการประเมิน', key: 'evaluatee_name' },
          { title: 'บทบาท', key: 'role_label' },
          { title: 'สถานะ', key: 'status_label' },
        ]"
        :fields="assignFields"
      >
        <template #item.role_label="{ item }">
          <v-chip size="small" :color="item.committee_role === 'chair' ? 'indigo' : 'blue-grey'">
            {{ item.committee_role === 'chair' ? 'ประธานกรรมการ' : 'กรรมการ' }}
          </v-chip>
        </template>
        <template #item.status_label="{ item }">
          <v-chip size="small" :color="item.status === 'submitted' ? 'green' : 'orange'">
            {{ item.status === 'submitted' ? 'ส่งผลแล้ว' : 'รอประเมิน' }}
          </v-chip>
        </template>
      </CrudTable>
    </div>
  </div>
</template>

<script setup>
definePageMeta({ layout: "dashboard" });
const api = useApi();
const apiBase = useRuntimeConfig().public.apiBase; // ที่อยู่ backend ไว้ต่อ path ไฟล์แม่แบบให้เป็น URL เต็ม
const tab = ref("period"); // แท็บที่เปิดอยู่ (period/topics/assign)

// ---- ขั้นที่ 1: ช่วงเวลา ----
const periods = ref([]); // รอบประเมินทั้งหมด ใช้ป้อน dropdown เลือกรอบของแท็บ 2 และ 3
// โหลดรอบประเมินทั้งหมดจาก GET /api/periods → dropdown เลือกรอบของแท็บ 2/3 (CrudTable ของแท็บ 1 โหลดของมันเอง)
async function loadPeriods() {
  periods.value = (await api.get("/api/periods", { params: { itemsPerPage: 100 } })).data.items;
  // ถ้ายังไม่ได้เลือกรอบ (ครั้งแรก) ให้เลือกรอบที่เปิดใช้งานอยู่ก่อน ถ้าไม่มีใช้รอบล่าสุด
  if (!selectedPeriodId.value && periods.value.length)
    selectedPeriodId.value = periods.value.find((p) => p.is_active)?.id ?? periods.value[0].id;
}

// ---- ขั้นที่ 2: หัวข้อ/ตัวชี้วัด (ผูกกับรอบที่เลือกด้านบน) ----
const selectedPeriodId = ref(null); // รอบที่กำลังตั้งค่าหัวข้อ/ตัวชี้วัดอยู่ (ใช้ร่วมกับแท็บ 3 ด้วย)
const topics = ref([]), indicators = ref([]); // topics = หัวข้อของรอบที่เลือก, indicators = ตัวชี้วัดทั้งหมดในระบบ (กรองเข้าหัวข้อด้วย indicatorsOf)
const indicatorDialog = ref(false), editingIndicator = ref(null), indicatorForm = ref({}); // dialog เปิด/ปิด, ตัวชี้วัดที่กำลังแก้ (null = เพิ่มใหม่), ค่าที่กรอกในฟอร์ม
const templateFile = ref(null); // ไฟล์แม่แบบที่เลือกไว้ในฟอร์ม (ยังไม่ได้อัปโหลดจนกว่าจะกดบันทึก)

const KIND_LABELS = { pdf: "ไฟล์ PDF", image: "รูปภาพ", url: "URL" }; // แปลรหัสชนิดหลักฐาน → ข้อความไทยที่อ่านได้
const kindLabel = (k) => KIND_LABELS[k] || k; // k = รหัสชนิดหลักฐาน 1 ตัว
const kindList = (s) => String(s || "").split(",").filter(Boolean); // s = string จาก DB เช่น "pdf,url" → แตกเป็น array ["pdf","url"]
const indicatorsOf = (topicId) => indicators.value.filter((i) => i.topic_id === topicId); // ตัวชี้วัดทั้งหมดของหัวข้อนี้ (ใช้ในตาราง expansion panel แต่ละหัวข้อ)

// โหลดหัวข้อของรอบที่เลือกจาก GET /api/topics และตัวชี้วัดทั้งหมดจาก GET /api/indicators
// → ตาราง expansion panel ด้านล่าง (ตัวชี้วัดถูกกรองเข้าหัวข้อด้วย indicatorsOf ฝั่ง client)
async function loadTopics() {
  if (!selectedPeriodId.value) return;
  // เรียงจากน้อยไปมากให้ตรงกับตารางหัวข้อด้านบน (ไม่งั้น panel ด้านล่างจะเรียงคนละทางกับตาราง)
  const params = { itemsPerPage: 100, sortBy: "id", sortDesc: false, period_id: selectedPeriodId.value }; // ดึงมาทีเดียว 100 แถว (ไม่แบ่งหน้า เพราะหน้านี้แสดงเป็น panel ไม่ใช่ตารางแบ่งหน้า)
  topics.value = (await api.get("/api/topics", { params })).data.items;
  // indicators ไม่มี period_id ตรง ๆ (ผูกผ่าน topic) — ดึงมาแล้วกรองด้วย indicatorsOf() ตาม topics ของรอบนี้
  indicators.value = (await api.get("/api/indicators", { params: { itemsPerPage: 100, sortBy: "id", sortDesc: false } })).data.items;
}
watch(selectedPeriodId, loadTopics);

// เปิด dialog ฟอร์มตัวชี้วัดเปล่า ผูกกับหัวข้อที่กดปุ่ม "เพิ่มตัวชี้วัด"
function openAddIndicator(topicId) {
  editingIndicator.value = null;
  templateFile.value = null;
  indicatorForm.value = { topic_id: topicId, name_th: "", description: "", weight: 1, type: "score_1_4", evidence_kinds: ["pdf"], template_url: "" };
  indicatorDialog.value = true;
}
// เปิด dialog พร้อมข้อมูลตัวชี้วัดเดิม (แปลง evidence_kind จาก "pdf,url" เป็น array ให้ checkbox)
function openEditIndicator(topicId, ind) {
  editingIndicator.value = ind;
  templateFile.value = null;
  indicatorForm.value = { ...ind, topic_id: topicId, evidence_kinds: kindList(ind.evidence_kind) };
  indicatorDialog.value = true;
}
// บันทึกตัวชี้วัดจากฟอร์ม → PUT/POST /api/indicators (แปลง evidence_kinds array กลับเป็น string ก่อนส่ง)
// ถ้าแนบไฟล์แม่แบบไว้ ส่งต่อ POST /api/indicators/:id/template แยกอีก request (multipart)
async function saveIndicator() {
  if (!indicatorForm.value.evidence_kinds?.length)
    return useSnackbar().show("เลือกหลักฐานอย่างน้อย 1 ชนิด", "error");
  const payload = { ...indicatorForm.value, evidence_kind: indicatorForm.value.evidence_kinds.join(",") }; // แปลง evidence_kinds (array จาก checkbox) กลับเป็น string คั่นจุลภาคตามที่ backend ต้องการ
  let id = editingIndicator.value?.id; // มี id แล้ว = กำลังแก้ไข, ไม่มี = กำลังเพิ่มใหม่ (id จะได้มาหลัง insert สำเร็จ)
  if (id) await api.put(`/api/indicators/${id}`, payload);
  else id = (await api.post("/api/indicators", payload)).data.data.id;

  // ถ้าเลือกไฟล์แม่แบบไว้ อัปโหลดต่อ (คนละ request เพราะเป็น multipart)
  if (templateFile.value) {
    const fd = new FormData(); // fd = ก้อนข้อมูลแบบ multipart สำหรับส่งไฟล์ (ต่างจาก JSON ปกติ)
    fd.append("file", templateFile.value);
    await api.post(`/api/indicators/${id}/template`, fd);
  }
  indicatorDialog.value = false;
  useSnackbar().show("บันทึกสำเร็จ");
  loadTopics();
}
// ลบไฟล์แม่แบบของตัวชี้วัดที่กำลังแก้ → DELETE /api/indicators/:id/template (backend ลบทั้งไฟล์บนดิสก์และค่าใน DB)
async function removeTemplate() {
  if (!editingIndicator.value) return;
  await api.delete(`/api/indicators/${editingIndicator.value.id}/template`);
  editingIndicator.value.template_path = null;
  editingIndicator.value.template_name = null;
  useSnackbar().show("ลบไฟล์แม่แบบสำเร็จ");
  loadTopics();
}
// ลบตัวชี้วัด (confirm ก่อน) → DELETE /api/indicators/:id แล้วโหลดรายการใหม่
async function removeIndicator(ind) {
  if (!confirm(`ลบตัวชี้วัด "${ind.name_th}" ?`)) return;
  await api.delete(`/api/indicators/${ind.id}`);
  useSnackbar().show("ลบสำเร็จ");
  loadTopics();
}

// ---- ขั้นที่ 3: มอบหมายกรรมการ ----
const evaluators = ref([]), evaluatees = ref([]); // รายชื่อกรรมการ/ผู้รับการประเมินทั้งหมด ใช้ป้อน dropdown ในฟอร์มมอบหมาย
const assignFields = computed(() => [ // ฟิลด์ฟอร์มของ CrudTable แท็บนี้ (dropdown ต้องคำนวณใหม่ทุกครั้งที่ evaluators/evaluatees เปลี่ยน จึงเป็น computed)
  { key: "evaluator_id", label: "กรรมการ", type: "select", items: evaluators.value.map((u) => ({ title: `${u.name_th} (#${u.id})`, value: u.id })) },
  { key: "evaluatee_id", label: "ผู้รับการประเมิน", type: "select", items: evaluatees.value.map((u) => ({ title: `${u.name_th} (#${u.id})`, value: u.id })) },
  { key: "committee_role", label: "บทบาท", type: "select", items: [{ title: "ประธาน", value: "chair" }, { title: "กรรมการร่วม", value: "member" }] },
]);

onMounted(async () => {
  await loadPeriods(); // ตั้ง selectedPeriodId ให้แล้วข้างใน → watch ด้านบนจะเรียก loadTopics() ต่อเอง
  evaluators.value = (await api.get("/api/users", { params: { role: "evaluator", itemsPerPage: 100 } })).data.items;
  evaluatees.value = (await api.get("/api/users", { params: { role: "evaluatee", itemsPerPage: 100 } })).data.items;
});
</script>
