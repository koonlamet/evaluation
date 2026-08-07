<template>
  <v-card class="pa-5" id="report">
    <h2 class="text-center">รายงานผลการประเมินบุคลากร</h2>
    <p class="text-center mb-4">{{ summary.user?.name_th }} — {{ summary.period?.name_th }}</p>

    <v-table density="comfortable">
      <thead>
        <tr>
          <th>หัวข้อ</th><th>ตัวชี้วัด</th><th class="text-center">น้ำหนัก</th>
          <th class="text-center">ประเมินตนเอง</th><th class="text-center">คะแนนกรรมการ</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="(it, i) in summary.items" :key="i">
          <td>{{ it.topic }}</td>
          <td>
            {{ it.indicator }}
            <v-chip v-if="it.type === 'yes_no'" size="x-small" class="ml-1">มี/ไม่มี</v-chip>
          </td>
          <td class="text-center">{{ it.type === 'yes_no' ? '-' : it.weight }}</td>
          <td class="text-center">{{ displayValue(it.type, it.self_score) }}</td>
          <td class="text-center">{{ displayValue(it.type, it.committee_score) }}</td>
        </tr>
      </tbody>
      <tfoot>
        <tr class="font-weight-bold">
          <td colspan="4" class="text-right">คะแนนเฉลี่ยถ่วงน้ำหนักรวม (เฉพาะตัวชี้วัดแบบสเกลคะแนน)</td>
          <td class="text-center">{{ summary.overall ?? '-' }}</td>
        </tr>
      </tfoot>
    </v-table>
    <p class="text-caption text-grey mt-1">
      หมายเหตุ: ตัวชี้วัดแบบ "มี/ไม่มี" เป็นการตรวจสอบผ่านเกณฑ์ ไม่ใช่คะแนน จึงไม่นำมารวมในค่าเฉลี่ยด้านบน
    </p>

    <!-- สรุปตัวชี้วัดแบบ มี/ไม่มี แยกจากคะแนน -->
    <v-alert
      v-if="summary.compliance?.total" type="info" variant="tonal" density="compact" class="mt-2"
    >
      ตัวชี้วัดแบบ "มี/ไม่มี" ที่กรรมการตรวจแล้ว: ผ่านเกณฑ์ {{ summary.compliance.met }}/{{ summary.compliance.total }} ข้อ
    </v-alert>

    <div class="mt-4">
      <b>คณะกรรมการผู้ประเมิน:</b>
      <ul>
        <li v-for="(c, i) in summary.committees" :key="i" class="d-flex align-center ga-2 mb-1 flex-wrap">
          <span>
            {{ c.evaluator }} ({{ c.committee_role === 'chair' ? 'ประธาน' : 'กรรมการ' }}) —
            สถานะ: {{ c.status === 'submitted' ? 'ส่งผลแล้ว' : 'รอประเมิน' }}
          </span>
          <img
            v-if="c.signature_path" :src="apiBase + c.signature_path" alt="ลายเซ็น"
            style="height: 36px; border-bottom: 1px solid #999"
          />
        </li>
        <li v-if="!summary.committees?.length" class="text-grey">ยังไม่ได้มอบหมายกรรมการ</li>
      </ul>
    </div>
  </v-card>
</template>

<script setup>
defineProps({ summary: { type: Object, default: () => ({}) } }); // summary = ผลลัพธ์จาก GET /api/summary/:id ทั้งก้อน (ผู้ใช้/รอบ/รายการคะแนน/เฉลี่ยรวม/กรรมการ) — หน้าแม่โหลดมาส่งเข้ามา
const apiBase = useRuntimeConfig().public.apiBase; // ต่อ path ลายเซ็น (เก็บเป็น path สัมพัทธ์ เช่น /uploads/sign_..png)

// ตัวชี้วัดแบบ มี/ไม่มี แสดงเป็นข้อความ ไม่ใช่ตัวเลขคะแนน
function displayValue(type, value) { // type = ชนิดตัวชี้วัด, value = คะแนนดิบจาก DB — คืนข้อความที่พร้อมแสดงผล
  if (value == null) return "-"; // ยังไม่มีคะแนน (ไม่ว่าจะชนิดไหน)
  if (type === "yes_no") return Number(value) >= 1 ? "มี" : "ไม่มี"; // ยิง 0/1 → แปลงเป็นคำที่อ่านเข้าใจ
  return value; // ชนิดคะแนน 1-4 แสดงตัวเลขตรงๆ
}
</script>
