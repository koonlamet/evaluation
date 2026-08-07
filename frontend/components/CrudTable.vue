<template>
  <v-card>
    <v-card-title class="d-flex align-center flex-wrap ga-2">
      <span>{{ title }}</span>
      <v-spacer />
      <!-- ค้นหาแบบ real-time + debounce (โจทย์พิเศษ 8.6) -->
      <v-text-field
        v-model="search" density="compact" variant="outlined" hide-details
        placeholder="ค้นหา..." prepend-inner-icon="mdi-magnify" style="max-width: 260px"
      />
      <v-btn color="indigo" prepend-icon="mdi-plus" @click="openAdd">เพิ่ม</v-btn>
    </v-card-title>

    <!-- ตารางแบบ server-side: ได้ pagination + sort + loading + hover ครบในตัว -->
    <v-data-table-server
      :headers="cols" :items="items" :items-length="total" :loading="loading"
      :items-per-page="10" hover density="comfortable"
      @update:options="onOptions"
    >
      <template #item.actions="{ item }">
        <v-icon size="small" class="mr-2" @click="openEdit(item)">mdi-pencil</v-icon>
        <v-icon size="small" color="red" @click="remove(item)">mdi-delete</v-icon>
      </template>
      <!-- ส่งต่อ slot คอลัมน์กำหนดเองจากหน้าที่เรียกใช้ (เช่น #item.status_label) เข้า v-data-table-server -->
      <template v-for="(_, name) in $slots" #[name]="slotProps" :key="name">
        <slot :name="name" v-bind="slotProps" />
      </template>
    </v-data-table-server>

    <!-- ฟอร์มเพิ่ม/แก้ไข -->
    <v-dialog v-model="dialog" max-width="520">
      <v-card>
        <v-card-title>{{ editing ? "แก้ไข" : "เพิ่ม" }} {{ title }}</v-card-title>
        <v-card-text>
          <template v-for="f in fields" :key="f.key">
            <v-select
              v-if="f.type === 'select'" v-model="form[f.key]" :items="f.items"
              :label="f.label" variant="outlined" density="comfortable"
            />
            <v-textarea
              v-else-if="f.type === 'textarea'" v-model="form[f.key]" :label="f.label"
              variant="outlined" rows="2"
            />
            <v-text-field
              v-else v-model="form[f.key]" :label="f.label" :type="f.type || 'text'"
              variant="outlined" density="comfortable"
            />
          </template>
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn @click="dialog = false">ยกเลิก</v-btn>
          <v-btn color="indigo" @click="save">บันทึก</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-card>
</template>

<script setup>
const props = defineProps({
  title: String,
  endpoint: String,     // เช่น '/api/topics'
  headers: Array,       // คอลัมน์ตาราง [{ title, key, sortable }]
  fields: Array,        // ฟิลด์ฟอร์ม [{ key, label, type, items? }]
  extraParams: { type: Object, default: () => ({}) },   // query คงที่เพิ่มเติม เช่น { role: 'admin' }
  newDefaults: { type: Object, default: () => ({}) },   // ค่าตั้งต้นตอนกด "เพิ่ม" เช่น { role: 'admin' }
  defaultSortBy: { type: String, default: "id" },       // คอลัมน์ที่ใช้เรียงตอนยังไม่ได้กดหัวตาราง
});

const emit = defineEmits(["changed"]); // แจ้งหน้าที่เรียกใช้เมื่อมีการเพิ่ม/แก้ไข/ลบ (เผื่อหน้านั้นมีข้อมูลชุดเดียวกันเก็บแยกไว้เอง)
const api = useApi();
const items = ref([]), total = ref(0), loading = ref(false); // items = แถวข้อมูลหน้าปัจจุบัน, total = จำนวนแถวทั้งหมด (คำนวณจำนวนหน้า), loading = true ระหว่างรอ backend ตอบ (โชว์ spinner)
const search = ref("");                                       // คำค้นหาที่ผู้ใช้พิมพ์ในกล่องค้นหา
const opts = ref({ page: 1, itemsPerPage: 10, sortBy: [] });   // ตัวเลือกปัจจุบันของตาราง (หน้า/จำนวนต่อหน้า/คอลัมน์ที่เรียง) — v-data-table-server เป็นคนอัปเดตให้
const dialog = ref(false), editing = ref(null), form = ref({}); // dialog = เปิด/ปิดฟอร์ม, editing = แถวที่กำลังแก้ไข (null = กำลังเพิ่มใหม่), form = ค่าที่กรอกในฟอร์ม

const cols = computed(() => [...props.headers, { title: "จัดการ", key: "actions", sortable: false }]); // คอลัมน์ตารางจริง = คอลัมน์ที่หน้าแม่กำหนด + คอลัมน์ "จัดการ" (ปุ่มแก้ไข/ลบ) ต่อท้ายเสมอ

// โหลดข้อมูลตาราง 1 หน้า จาก GET {endpoint} โดยส่ง page/itemsPerPage/search/sort ให้ backend จัดการ (server-side)
// → items+total ป้อนเข้า v-data-table-server (ถูกเรียกซ้ำทุกครั้งที่เปลี่ยนหน้า/เรียง/ค้นหา/บันทึก/ลบ)
async function load() {
  loading.value = true;
  const s = opts.value.sortBy?.[0]; // s = คอลัมน์ที่กำลังเรียงอยู่ (v-data-table-server ให้เป็น array แต่ตารางนี้เรียงได้ทีละคอลัมน์ เอาตัวแรกพอ) — undefined ถ้ายังไม่ได้กดหัวตาราง
  try {
    const { data } = await api.get(props.endpoint, {
      params: {
        page: opts.value.page,
        itemsPerPage: opts.value.itemsPerPage,
        search: search.value,
        sortBy: s?.key || props.defaultSortBy,
        sortDesc: s ? s.order === "desc" : false, // ไม่กดหัวตาราง → เรียงน้อยไปมากเป็นค่าเริ่มต้น
        ...props.extraParams,
      },
    });
    items.value = data.items;
    total.value = data.total;
  } finally {
    loading.value = false;
  }
}
// v-data-table-server แจ้ง page/sort ที่ผู้ใช้เปลี่ยน → เก็บไว้แล้วโหลดข้อมูลหน้านั้นใหม่
function onOptions(o) { opts.value = o; load(); } // o = ตัวเลือกใหม่จาก v-data-table-server (หน้า/จำนวนต่อหน้า/คอลัมน์เรียง)

// หน่วงเวลา (debounce) 400ms ก่อนยิงค้นหา
let timer; // timer = ตัวจับเวลานับถอยหลังของ debounce (พิมพ์ใหม่ก่อนครบ 400ms จะยกเลิกตัวเก่าทิ้งแล้วเริ่มนับใหม่)
watch(search, () => {
  clearTimeout(timer);
  timer = setTimeout(() => { opts.value.page = 1; load(); }, 400);
});
watch(() => props.extraParams, () => { opts.value.page = 1; load(); }, { deep: true });

// เปิดฟอร์มเปล่า (ใส่ค่าตั้งต้นจาก newDefaults เช่น role/period_id ของแท็บที่เปิดอยู่) สำหรับเพิ่มรายการใหม่
function openAdd() { editing.value = null; form.value = { ...props.newDefaults }; dialog.value = true; }
// เปิดฟอร์มพร้อมข้อมูลแถวที่เลือก สำหรับแก้ไข
function openEdit(item) {
  editing.value = item;
  form.value = { ...item };
  // ฟิลด์วันที่จาก DB มาเป็น ISO string เต็ม (เช่น 2025-10-01T00:00:00.000Z) แต่ input type=date ต้องการแค่ YYYY-MM-DD
  props.fields.forEach((f) => {
    if (f.type === "date" && form.value[f.key]) form.value[f.key] = String(form.value[f.key]).slice(0, 10);
  });
  dialog.value = true;
}

// ส่งค่าฟอร์ม → PUT {endpoint}/:id (แก้ไข) หรือ POST {endpoint} (เพิ่มใหม่) แล้วโหลดตาราง + แจ้งหน้าแม่ผ่าน event "changed"
async function save() {
  if (editing.value) await api.put(`${props.endpoint}/${editing.value.id}`, form.value);
  else await api.post(props.endpoint, form.value);
  dialog.value = false;
  useSnackbar().show("บันทึกสำเร็จ");
  load();
  emit("changed");
}
// ลบแถวที่เลือก (confirm ก่อน) → DELETE {endpoint}/:id แล้วโหลดตาราง + แจ้งหน้าแม่
async function remove(item) {
  if (!confirm("ยืนยันการลบรายการนี้?")) return;
  await api.delete(`${props.endpoint}/${item.id}`);
  useSnackbar().show("ลบสำเร็จ");
  load();
  emit("changed");
}
</script>
