<template>
  <div>
    <div class="d-flex align-center mb-4 no-print">
      <v-btn icon="mdi-arrow-left" variant="text" to="/me/report" />
      <h2>รายงานผลการประเมิน</h2>
      <v-spacer />
      <v-btn color="red" prepend-icon="mdi-file-pdf-box" :loading="exporting" @click="askPassword = true">ส่งออก PDF</v-btn>
    </div>

    <div ref="reportEl">
      <EvaluationReport :summary="sum" />
    </div>

    <!-- 8.5 ตั้งรหัสผ่านก่อนส่งออก PDF -->
    <v-dialog v-model="askPassword" max-width="420">
      <v-card class="pa-4">
        <v-card-title>ตั้งรหัสผ่านสำหรับไฟล์ PDF</v-card-title>
        <v-card-text>
          <p class="text-caption mb-2">กำหนดรหัสผ่านเพื่อควบคุมการเข้าถึงเอกสารก่อนส่งออก</p>
          <v-text-field v-model="pwd" label="ตั้งรหัสผ่าน" type="password" variant="outlined" />
          <v-text-field v-model="pwd2" label="ยืนยันรหัสผ่าน" type="password" variant="outlined" />
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn @click="askPassword = false">ยกเลิก</v-btn>
          <v-btn color="red" @click="exportPdf">ยืนยันและส่งออก</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup>
import jsPDF from "jspdf";
import html2canvas from "html2canvas";

definePageMeta({ layout: "dashboard" });
const { user } = useAuth(); // user = ตัวเอง (ดูรายงานของตัวเองเท่านั้น)
const api = useApi();
const periodId = useRoute().params.id; // รอบที่กำลังดูรายงาน (มาจาก URL)
const sum = ref({}); // ผลลัพธ์จาก GET /api/summary/:id (ส่งต่อให้ <EvaluationReport>)
const askPassword = ref(false), pwd = ref(""), pwd2 = ref(""), exporting = ref(false); // askPassword = เปิด/ปิด dialog ตั้งรหัส, pwd/pwd2 = รหัสผ่าน+ยืนยัน, exporting = true ระหว่างกำลังสร้าง PDF
const reportEl = ref(null); // อ้างอิง DOM ของรายงาน (ใช้แปลงเป็นรูปก่อนใส่ลง PDF)

// 5.2.7 ส่งออกเป็นไฟล์ PDF จริง (ดาวน์โหลดได้เลย) + 8.5 ตั้งรหัสผ่านล็อกไฟล์
// flow: DOM ของรายงาน (reportEl) → html2canvas แปลงเป็นรูป → jsPDF ตัดแบ่งหน้า A4 + เข้ารหัสด้วยรหัสผ่านที่ตั้ง → save ลงเครื่องผู้ใช้
async function exportPdf() {
  if (!pwd.value || pwd.value.length < 4) return useSnackbar().show("ตั้งรหัสผ่านอย่างน้อย 4 ตัว", "error");
  if (pwd.value !== pwd2.value) return useSnackbar().show("รหัสผ่านไม่ตรงกัน", "error");
  askPassword.value = false;
  exporting.value = true;
  try {
    const canvas = await html2canvas(reportEl.value, { scale: 2 }); // canvas = ภาพถ่ายหน้าจอของรายงาน (scale 2 = ความละเอียดสูงขึ้น คมชัดตอนพิมพ์)
    const pdf = new jsPDF({
      unit: "mm", format: "a4", // หน่วยมิลลิเมตร กระดาษขนาด A4
      encryption: { userPassword: pwd.value, ownerPassword: pwd.value, userPermissions: ["print"] }, // ล็อกไฟล์ด้วยรหัสผ่านที่ตั้ง เปิดได้แค่พิมพ์ อย่างอื่นทำไม่ได้ถ้าไม่มีรหัส
    });
    const pageW = pdf.internal.pageSize.getWidth();  // ความกว้างหน้ากระดาษ A4 (mm)
    const pageH = pdf.internal.pageSize.getHeight(); // ความสูงหน้ากระดาษ A4 (mm)
    const imgH = (canvas.height * pageW) / canvas.width; // ความสูงของรูปเมื่อย่อ/ขยายให้พอดีความกว้างหน้ากระดาษ (รักษาสัดส่วนเดิม)
    const imgData = canvas.toDataURL("image/png"); // แปลง canvas เป็นรูปภาพ base64 พร้อมฝังลง PDF

    let heightLeft = imgH, position = 0; // heightLeft = ความสูงของรูปที่ยังไม่ได้ใส่ลงหน้ากระดาษ, position = ตำแหน่งเลื่อนรูปขึ้น (ค่าติดลบ) เพื่อโชว์ส่วนถัดไปในหน้าใหม่
    pdf.addImage(imgData, "PNG", 0, position, pageW, imgH);
    heightLeft -= pageH;
    while (heightLeft > 0) { // รายงานยาวกว่า 1 หน้ากระดาษ → ต้องตัดแบ่งหลายหน้า
      position -= pageH; // เลื่อนรูปขึ้นอีก 1 หน้ากระดาษ (โชว์ส่วนที่ยังไม่เห็น)
      pdf.addPage();
      pdf.addImage(imgData, "PNG", 0, position, pageW, imgH);
      heightLeft -= pageH;
    }
    pdf.save(`รายงานผลการประเมิน_${sum.value.user?.name_th || ""}.pdf`);
    useSnackbar().show("ส่งออก PDF สำเร็จ");
  } finally {
    exporting.value = false;
    pwd.value = ""; pwd2.value = "";
  }
}

// โหลดสรุปผลของตัวเอง (คะแนนตนเอง + เฉลี่ยกรรมการ ต่อตัวชี้วัด) จาก GET /api/summary/:myId → ส่งให้ <EvaluationReport> แสดง
onMounted(async () => {
  sum.value = (await api.get(`/api/summary/${user.value.id}`, { params: { period_id: periodId } })).data;
});
</script>
