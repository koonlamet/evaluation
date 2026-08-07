<template>
  <div>
    <div class="d-flex align-center mb-4">
      <v-btn icon="mdi-arrow-left" variant="text" to="/eval" />
      <h2 class="ml-2">ประเมิน: {{ a.evaluatee }}</h2>
      <v-chip class="ml-3" :color="a.status === 'submitted' ? 'green' : 'orange'">
        {{ a.status === 'submitted' ? 'ส่งผลแล้ว' : 'รอประเมิน' }}
      </v-chip>
      <v-btn size="small" variant="text" class="ml-3" @click="showInfo = true">ดูข้อมูลผู้รับการประเมิน</v-btn>
    </div>

    <v-dialog v-model="showInfo" max-width="400">
      <v-card class="pa-4">
        <h3 class="mb-3">ข้อมูลผู้รับการประเมิน</h3>
        <p><b>ชื่อ-สกุล:</b> {{ a.evaluatee }}</p>
        <p><b>อีเมล:</b> {{ a.evaluatee_email }}</p>
        <v-btn class="mt-3" variant="text" @click="showInfo = false">ปิด</v-btn>
      </v-card>
    </v-dialog>

    <v-alert v-if="a.status === 'submitted'" type="success" variant="tonal" class="mb-4">
      ส่งผลการประเมินไปแล้ว — แก้ไขคะแนน/ความเห็น/ลายเซ็นเพิ่มเติมไม่ได้
    </v-alert>
    <v-alert v-else-if="periodEnded" type="warning" variant="tonal" class="mb-4">
      หมดเขตการประเมินของรอบ "{{ a.period_name }}" แล้ว ({{ a.period_end_date?.slice(0, 10) }}) — บันทึก/ส่งผลเพิ่มเติมไม่ได้
    </v-alert>

    <!-- 5.3.2-5.3.4 แสดงข้อมูล/หลักฐาน + คะแนนตนเอง + ให้คะแนน -->
    <v-card v-for="it in items" :key="it.indicator_id" class="mb-3 pa-4">
      <div class="text-caption text-grey">{{ it.topic }}</div>
      <h4>
        {{ it.indicator }}
        <span v-if="it.type === 'yes_no'" class="text-caption">(มี/ไม่มี — ไม่มีน้ำหนักคะแนน)</span>
        <span v-else class="text-caption">(น้ำหนัก {{ it.weight }})</span>
      </h4>
      <p class="mt-1"><b>ข้อมูลผู้รับการประเมิน:</b> {{ it.detail || '-' }}</p>
      <p v-if="it.url"><b>ลิงก์:</b> <a :href="it.url" target="_blank">{{ it.url }}</a></p>
      <div class="mb-2">
        <v-chip v-for="f in it.files" :key="f.id" size="small" class="mr-2"
          :href="apiBase + f.path" target="_blank" prepend-icon="mdi-file">{{ f.file_name }}</v-chip>
      </div>
      <v-chip size="small" color="blue-grey" class="mb-3">ประเมินตนเอง: {{ selfScoreLabel(it) }}</v-chip>

      <v-row>
        <v-col cols="12" sm="4">
          <v-select v-model="it.score" :items="scoreItems(it.type)" label="คะแนนกรรมการ" :disabled="locked"
            variant="outlined" density="comfortable" />
        </v-col>
        <v-col cols="12" sm="8">
          <v-text-field v-model="it.comment" label="ความเห็นต่อตัวชี้วัดนี้" :disabled="locked" variant="outlined" density="comfortable" />
        </v-col>
      </v-row>
    </v-card>

    <!-- ผลลัพธ์การประเมิน แยกเป็นตัวชี้วัดภายใต้หัวข้อ ก่อนลงนาม ให้กรรมการตรวจทานก่อนยืนยันส่ง -->
    <v-card class="pa-4 mb-4">
      <h3 class="mb-2">ผลลัพธ์การประเมิน</h3>
      <v-table density="comfortable">
        <thead>
          <tr>
            <th>หัวข้อ</th><th>ตัวชี้วัด</th><th class="text-center">น้ำหนัก</th>
            <th class="text-center">ประเมินตนเอง</th><th class="text-center">คะแนนกรรมการ</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="it in items" :key="it.indicator_id">
            <td>{{ it.topic }}</td>
            <td>{{ it.indicator }}</td>
            <td class="text-center">{{ it.type === 'yes_no' ? '-' : it.weight }}</td>
            <td class="text-center">{{ selfScoreLabel(it) }}</td>
            <td class="text-center">{{ scoreLabel(it) }}</td>
          </tr>
        </tbody>
      </v-table>
      <!-- ค่าเฉลี่ยคำนวณสดจากคะแนนที่เลือกในฟอร์ม ให้กรรมการเห็นก่อนเซ็นส่ง (สูตรเดียวกับ weightedAverage ฝั่ง backend) -->
      <div class="mt-2">
        <span v-if="liveAverage != null"><b>คะแนนเฉลี่ยรวม (ถ่วงน้ำหนัก): {{ liveAverage }} / 4</b></span>
        <span v-if="compliance.total"> · เกณฑ์มี/ไม่มี: ผ่าน {{ compliance.met }}/{{ compliance.total }} ข้อ</span>
        <div v-if="unscoredCount" class="text-caption text-orange">(ยังไม่ได้ให้คะแนน {{ unscoredCount }} ตัวชี้วัด)</div>
      </div>
    </v-card>

    <!-- 5.3.5 ความเห็นสรุป + 5.3.7 ลายเซ็น + 5.3.8 ยืนยันส่ง -->
    <v-card class="pa-4">
      <h3 class="mb-2">สรุปผลการประเมิน</h3>
      <v-textarea v-model="overall" label="ความคิดเห็นสรุปภาพรวม" :disabled="locked" variant="outlined" rows="2" />

      <div class="mb-1">ลงลายมือชื่อกรรมการ:</div>
      <canvas
        ref="canvas" width="360" height="120" style="border: 1px solid #999; border-radius: 4px; touch-action: none"
        @pointerdown="!locked && start($event)" @pointermove="!locked && move($event)" @pointerup="end" @pointerleave="end"
      />
      <div><v-btn size="small" variant="text" :disabled="locked" @click="clearSig">ล้างลายเซ็น</v-btn></div>

      <v-btn color="green" size="large" class="mt-3" prepend-icon="mdi-send" :loading="busy" :disabled="locked" @click="submit">
        ยืนยันและส่งผลการประเมิน
      </v-btn>
    </v-card>
  </div>
</template>

<script setup>
definePageMeta({ layout: "dashboard" });
const api = useApi();
const apiBase = useRuntimeConfig().public.apiBase;
const id = useRoute().params.id; // id ของใบมอบหมาย (assignment) ที่กำลังประเมิน (มาจาก URL เช่น /eval/12)

const a = ref({}), items = ref([]), overall = ref(""), busy = ref(false); // a = หัวใบประเมิน (ผู้รับ/สถานะ/รอบ), items = ตัวชี้วัดทั้งหมด, overall = ความเห็นสรุปที่พิมพ์, busy = true ระหว่างกำลังส่ง
const periodEnded = computed(() => a.value.period_end_date && a.value.period_end_date.slice(0, 10) < new Date().toISOString().slice(0, 10)); // true ถ้าวันนี้เลยวันสิ้นสุดรอบไปแล้ว
// ส่งผลไปแล้ว หรือหมดเขตรอบ → ห้ามแก้ไขคะแนน/ความเห็น/ลายเซ็นซ้ำ
const locked = computed(() => a.value.status === "submitted" || periodEnded.value);
const canvas = ref(null); // อ้างอิง element <canvas> ที่วาดลายเซ็น
let drawing = false, ctx; // drawing = true ระหว่างกำลังลากเมาส์/นิ้ววาดอยู่, ctx = 2D context ของ canvas (ใช้สั่งวาดเส้น)

function scoreItems(type) { // type = ชนิดตัวชี้วัด, คืนตัวเลือกคะแนนที่จะโชว์ใน dropdown
  return type === "yes_no"
    ? [{ title: "มี", value: 1 }, { title: "ไม่มี", value: 0 }]
    : [1, 2, 3, 4].map((n) => ({ title: `ระดับ ${n}`, value: n }));
}
// ตัวชี้วัดแบบ มี/ไม่มี แสดงเป็นข้อความ ไม่ใช่ตัวเลขคะแนน
function selfScoreLabel(it) {
  if (it.self_score == null) return "-";
  return it.type === "yes_no" ? (Number(it.self_score) >= 1 ? "มี" : "ไม่มี") : it.self_score;
}
function scoreLabel(it) {
  if (it.score == null) return "-";
  return it.type === "yes_no" ? (Number(it.score) >= 1 ? "มี" : "ไม่มี") : it.score;
}
const showInfo = ref(false); // เปิด/ปิด dialog "ดูข้อมูลผู้รับการประเมิน"

// ค่าเฉลี่ยถ่วงน้ำหนักแบบสด (สูตรเดียวกับ weightedAverage() ใน report.controller.js) — ให้กรรมการเห็นก่อนกดส่ง
const liveAverage = computed(() => {
  let sum = 0, w = 0; // sum = ผลรวม (คะแนน×น้ำหนัก), w = ผลรวมน้ำหนักที่นำมาคิดจริง (เหมือนฝั่ง backend)
  for (const it of items.value) {
    if (it.type === "yes_no" || it.score == null) continue; // ข้ามตัวชี้วัดแบบมี/ไม่มี และตัวที่ยังไม่ได้ให้คะแนน
    sum += Number(it.score) * Number(it.weight);
    w += Number(it.weight);
  }
  return w ? Math.round((sum / w) * 100) / 100 : null; // w=0 (ยังไม่ให้คะแนนเลย) → คืน null แทนหารด้วยศูนย์
});
const compliance = computed(() => {
  const yesNo = items.value.filter((it) => it.type === "yes_no" && it.score != null); // ตัวชี้วัดแบบมี/ไม่มีที่ให้คะแนนแล้ว
  return { total: yesNo.length, met: yesNo.filter((it) => Number(it.score) >= 1).length }; // total = ให้คะแนนแล้วกี่ข้อ, met = ผ่านเกณฑ์ ("มี") กี่ข้อ
});
const unscoredCount = computed(() => items.value.filter((it) => it.score == null).length); // จำนวนตัวชี้วัดที่ยังไม่ได้ให้คะแนนเลย (เตือนก่อนส่ง)

// ลายเซ็นด้วย canvas
function xy(e) { const r = canvas.value.getBoundingClientRect(); return { x: e.clientX - r.left, y: e.clientY - r.top }; } // e = pointer event, คืนพิกัด x,y สัมพัทธ์กับมุมซ้ายบนของ canvas (ไม่ใช่พิกัดหน้าจอ)
function start(e) { drawing = true; const { x, y } = xy(e); ctx.beginPath(); ctx.moveTo(x, y); } // เริ่มลาก: เปิดเส้นทางใหม่ ย้ายปากกาไปจุดเริ่ม
function move(e) { if (!drawing) return; const { x, y } = xy(e); ctx.lineTo(x, y); ctx.stroke(); } // กำลังลากอยู่: ลากเส้นต่อไปยังจุดปัจจุบัน
function end() { drawing = false; } // ปล่อยเมาส์/นิ้ว หยุดลาก
function clearSig() { ctx.clearRect(0, 0, canvas.value.width, canvas.value.height); } // ล้างลายเซ็นทั้งหมดในกรอบ canvas

// ยืนยันส่งผลการประเมิน 2 ขั้น: คะแนน/ความเห็นรายตัวชี้วัดจากฟอร์ม → POST /api/reviews ทีละตัว (upsert ลง reviews)
// จากนั้นความเห็นสรุป + ลายเซ็นจาก canvas (base64) → POST /api/reviews/:id/submit (สถานะเป็น submitted ล็อกใบนี้)
async function submit() {
  busy.value = true;
  try {
    // บันทึกคะแนนทุกตัวชี้วัด แล้วยืนยันส่ง (คะแนน + ความเห็น + ลายเซ็น)
    for (const it of items.value)
      await api.post("/api/reviews", { assignment_id: id, indicator_id: it.indicator_id, score: it.score, comment: it.comment });
    await api.post(`/api/reviews/${id}/submit`, { overall_comment: overall.value, signature: canvas.value.toDataURL("image/png") });
    useSnackbar().show("ส่งผลการประเมินสำเร็จ");
    navigateTo("/eval");
  } finally { busy.value = false; }
}

// โหลดใบประเมินจาก GET /api/reviews/:assignmentId → assignment (หัวใบ/สถานะ) + items
// (ตัวชี้วัด + ข้อมูล/ไฟล์/คะแนนตนเองของผู้รับการประเมิน + คะแนนกรรมการที่เคยกรอกไว้) → เติมฟอร์มทั้งหน้า
onMounted(async () => {
  ctx = canvas.value.getContext("2d");
  ctx.lineWidth = 2;
  const { data } = await api.get(`/api/reviews/${id}`);
  a.value = data.assignment;
  items.value = data.items;
  overall.value = data.assignment.overall_comment || "";
});
</script>
