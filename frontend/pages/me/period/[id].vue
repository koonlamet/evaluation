<template>
  <div>
    <div class="d-flex align-center mb-4 flex-wrap ga-3">
      <v-btn icon="mdi-arrow-left" variant="text" to="/me" />
      <h2>{{ periodName }}</h2>
      <v-spacer />
      <!-- 5.2.6 ความคืบหน้า -->
      <div style="min-width: 240px">
        <div class="text-caption">ความคืบหน้า {{ done }}/{{ items.length }} ตัวชี้วัด</div>
        <v-progress-linear :model-value="percent" height="18" color="green" rounded>
          {{ percent }}%
        </v-progress-linear>
      </div>
    </div>

    <v-alert v-if="periodEnded" type="warning" variant="tonal" class="mb-4">
      หมดเขตการประเมินของรอบนี้แล้ว ({{ periodEndDate }}) — บันทึกข้อมูลเพิ่มเติมไม่ได้
    </v-alert>

    <v-expansion-panels multiple>
      <v-expansion-panel v-for="it in items" :key="it.indicator_id">
        <v-expansion-panel-title>
          <span>[{{ it.topic }}] {{ it.indicator }}</span>
          <v-chip v-if="it.self_score != null" size="x-small" color="green" class="ml-2">กรอกแล้ว</v-chip>
        </v-expansion-panel-title>
        <v-expansion-panel-text>
          <!-- แม่แบบ/ลิงก์อ้างอิงที่ฝ่ายบุคลากรเตรียมไว้ให้ดูก่อนกรอก -->
          <v-alert v-if="it.template_path || it.template_url" type="info" variant="tonal" density="compact" class="mb-3">
            แม่แบบจากฝ่ายบุคลากร:
            <v-chip v-if="it.template_path" size="small" color="teal" class="ml-1"
              :href="apiBase + it.template_path" target="_blank" prepend-icon="mdi-file-download"
            >{{ it.template_name }}</v-chip>
            <v-chip v-if="it.template_url" size="small" color="blue" class="ml-1"
              :href="it.template_url" target="_blank" prepend-icon="mdi-link"
            >ลิงก์อ้างอิง</v-chip>
          </v-alert>

          <v-textarea v-model="it.detail" label="รายละเอียด/ผลการดำเนินงาน" variant="outlined" rows="2" />
          <div class="text-caption mb-1">
            หลักฐานที่แนบได้:
            <v-chip v-for="k in kindList(it.evidence_kind)" :key="k" size="x-small" class="mr-1">{{ kindLabel(k) }}</v-chip>
          </div>
          <v-text-field
            v-if="kindList(it.evidence_kind).includes('url')" v-model="it.url" label="ลิงก์หลักฐาน (URL)" variant="outlined"
          />
          <v-row>
            <v-col cols="12" sm="4">
              <!-- 5.2.4 กรอกคะแนนประเมินตนเอง (รูปแบบตามที่บุคลากรกำหนด) -->
              <v-select
                v-model="it.self_score" :items="scoreItems(it.type)" label="ประเมินตนเอง"
                variant="outlined" density="comfortable"
              />
            </v-col>
            <v-col cols="12" sm="8">
              <v-text-field v-model="it.self_note" label="หมายเหตุ" variant="outlined" density="comfortable" />
            </v-col>
          </v-row>

          <v-btn color="indigo" size="small" :disabled="periodEnded" @click="save(it)">บันทึกตัวชี้วัดนี้</v-btn>

          <!-- 8.3 อัปโหลดไฟล์หลายไฟล์ + progress (แสดงเฉพาะตัวชี้วัดที่รับหลักฐานเป็นไฟล์) -->
          <div class="mt-4" v-if="kindList(it.evidence_kind).some((k) => k === 'pdf' || k === 'image')">
            <v-file-input
              v-model="it._files" label="แนบไฟล์หลักฐาน (PDF/JPG/PNG หลายไฟล์ได้)"
              variant="outlined" density="compact" multiple show-size prepend-icon="mdi-paperclip"
            />
            <v-btn size="small" variant="tonal" :disabled="periodEnded || !it._files?.length" @click="upload(it)">
              อัปโหลด
            </v-btn>
            <v-progress-linear
              v-if="it._progress > 0 && it._progress < 100" :model-value="it._progress"
              color="blue" height="16" class="mt-2" rounded
            >{{ it._progress }}%</v-progress-linear>

            <!-- รายการไฟล์ที่แนบแล้ว -->
            <v-chip
              v-for="f in it.files" :key="f.id" class="mr-2 mt-2" size="small"
              :href="apiBase + f.path" target="_blank" prepend-icon="mdi-file"
            >{{ f.file_name }}</v-chip>
          </div>
        </v-expansion-panel-text>
      </v-expansion-panel>
    </v-expansion-panels>

    <!-- 5.2.8 ความคิดเห็นจากกรรมการ -->
    <v-card class="mt-6 pa-4" v-if="feedback.overall?.length">
      <h3 class="mb-3">ความคิดเห็นจากกรรมการ</h3>
      <v-alert v-for="(o, i) in feedback.overall" :key="i" type="success" variant="tonal" class="mb-2">
        <b>{{ o.evaluator }} ({{ o.committee_role === 'chair' ? 'ประธาน' : 'กรรมการ' }}):</b>
        {{ o.overall_comment || '(ไม่มีความเห็นเพิ่มเติม)' }}
      </v-alert>
    </v-card>
  </div>
</template>

<script setup>
definePageMeta({ layout: "dashboard" });
const api = useApi();
const apiBase = useRuntimeConfig().public.apiBase;
const periodId = useRoute().params.id; // รอบที่กำลังกรอกอยู่ (มาจาก URL เช่น /me/period/2)
const periodName = ref("แบบประเมิน"); // ชื่อรอบ ไว้แสดงหัวหน้า
const periodEndDate = ref(null); // วันสิ้นสุดรอบ (YYYY-MM-DD) ใช้คำนวณ periodEnded
const periodEnded = computed(() => periodEndDate.value && periodEndDate.value < new Date().toISOString().slice(0, 10)); // true ถ้าวันนี้เลยวันสิ้นสุดรอบไปแล้ว → ล็อกฟอร์ม
const items = ref([]), feedback = ref({ overall: [] }); // items = ตัวชี้วัดทั้งหมด+ค่าที่กรอก, feedback = ความเห็นกรรมการที่ส่งผลแล้ว

const done = computed(() => items.value.filter((i) => i.self_score != null).length); // จำนวนตัวชี้วัดที่กรอกคะแนนตนเองแล้ว
const percent = computed(() => (items.value.length ? Math.round((done.value / items.value.length) * 100) : 0)); // % ความคืบหน้า แสดงในแถบด้านบน

const KIND_LABELS = { pdf: "ไฟล์ PDF", image: "รูปภาพ", url: "URL" }; // แปลรหัสชนิดหลักฐาน → ข้อความไทย
const kindLabel = (k) => KIND_LABELS[k] || k; // k = รหัสชนิดหลักฐาน 1 ตัว
const kindList = (s) => String(s || "").split(",").filter(Boolean); // s = string จาก DB เช่น "pdf,url" → แตกเป็น array

// รูปแบบคะแนนตามชนิดตัวชี้วัด
function scoreItems(type) { // type = ชนิดตัวชี้วัด, คืนตัวเลือกคะแนนที่จะโชว์ใน dropdown
  return type === "yes_no"
    ? [{ title: "มี", value: 1 }, { title: "ไม่มี", value: 0 }]
    : [1, 2, 3, 4].map((n) => ({ title: `ระดับ ${n}`, value: n }));
}

// โหลดข้อมูลทั้งหน้า 3 ส่วน:
// 1) ตัวชี้วัดของรอบนี้ + ค่าที่เคยกรอก+ไฟล์แนบ จาก GET /api/evidences → items (ฟอร์มกรอกด้านบน)
// 2) ความเห็นกรรมการที่ส่งผลแล้ว จาก GET /api/reviews/feedback → feedback (การ์ดท้ายหน้า)
// 3) ชื่อ+วันหมดเขตของรอบ จาก GET /api/evidences/periods → ใช้โชว์หัวหน้า และคำนวณ periodEnded ล็อกฟอร์ม
async function load() {
  const { data } = await api.get("/api/evidences", { params: { period_id: periodId } });
  items.value = data.items.map((r) => ({ ...r, _files: [], _progress: 0 })); // r = ตัวชี้วัด 1 ข้อจาก backend, เติม _files/_progress (state เฉพาะฝั่ง frontend สำหรับฟอร์มอัปโหลด ไม่ได้มาจาก backend)
  feedback.value = (await api.get("/api/reviews/feedback", { params: { period_id: periodId } })).data;
  const periods = (await api.get("/api/evidences/periods")).data.items; // รอบทั้งหมดที่เปิดอยู่ (ดึงมาเพื่อหาชื่อ+วันหมดเขตของรอบนี้โดยเฉพาะ)
  const p = periods.find((p) => String(p.id) === String(periodId)); // p = ข้อมูลรอบปัจจุบันที่กำลังกรอกอยู่
  periodName.value = p?.name_th || "แบบประเมิน";
  periodEndDate.value = p?.end_date?.slice(0, 10) || null;
}

// ส่งค่าที่กรอกในตัวชี้วัดนี้ (detail/url/self_score/self_note) → POST /api/evidences (upsert ลงตาราง evidences)
// เก็บ evidence_id ที่ backend คืนมา ไว้เป็น parent ตอนอัปโหลดไฟล์แนบ
async function save(it) { // it = ตัวชี้วัด 1 ข้อจาก items (มี detail/url/self_score/self_note ที่ผู้ใช้กรอกในฟอร์ม)
  const { data } = await api.post("/api/evidences", {
    indicator_id: it.indicator_id, period_id: periodId,
    detail: it.detail, url: it.url, self_score: it.self_score, self_note: it.self_note,
  });
  it.evidence_id = data.data.id; // เก็บ id ของแถว evidences ที่เพิ่งบันทึก ไว้ใช้ตอนอัปโหลดไฟล์ (evidence ต้องมีก่อนถึงจะแนบไฟล์ได้)
  useSnackbar().show("บันทึกสำเร็จ");
}

// ส่งไฟล์ที่เลือก (หลายไฟล์) → POST /api/evidences/:evidenceId/files (multipart, ลงตาราง evidence_files + ดิสก์ /uploads)
// ระหว่างส่งอัปเดต _progress ให้แถบความคืบหน้า เสร็จแล้ว load() ใหม่เพื่อโชว์รายการไฟล์ล่าสุด
async function upload(it) { // it = ตัวชี้วัด 1 ข้อ (มี it._files = ไฟล์ที่เลือกไว้ในฟอร์ม)
  if (!it.evidence_id) await save(it); // ต้องมี evidence ก่อน
  const fd = new FormData(); // fd = ก้อนข้อมูลแบบ multipart สำหรับส่งไฟล์
  it._files.forEach((f) => fd.append("files", f));
  it._progress = 1; // เริ่มโชว์แถบความคืบหน้า (>0 ทำให้ v-progress-linear ขึ้น)
  await api.post(`/api/evidences/${it.evidence_id}/files`, fd, {
    onUploadProgress: (e) => (it._progress = Math.round((e.loaded / e.total) * 100)), // e.loaded/e.total = byte ที่ส่งไปแล้ว/ทั้งหมด → คำนวณ % สด
  });
  it._progress = 0; // อัปโหลดเสร็จ ซ่อนแถบความคืบหน้า
  it._files = [];
  useSnackbar().show("อัปโหลดไฟล์สำเร็จ");
  load();
}

onMounted(load);
</script>
