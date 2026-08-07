# Frontend Template Reference

เอกสารนี้รวบรวม **element/component ทุกตัวที่ใช้จริงในส่วน `<template>`** ของโปรเจกต์ (สแกนจากไฟล์ `.vue` ทั้งหมด) พร้อมอธิบายว่าแต่ละตัวทำหน้าที่อะไร และ attribute ที่ใช้จริงแต่ละตัวมีไว้ทำอะไร

> Element ส่วนใหญ่มาจาก [Vuetify 3](https://vuetifyjs.com/) (ขึ้นต้นด้วย `v-`) ที่เหลือเป็น HTML มาตรฐาน, component ที่เขียนเอง (`CrudTable`, `EvaluationReport`), และ component จาก Nuxt (`NuxtLayout`, `NuxtPage`, `NuxtLink`)

---

## 1. โครงหน้า (Layout)

| Element | หน้าที่ |
|---|---|
| `v-app` | ครอบทั้งแอป (root) จำเป็นต้องมีเสมอเวลาใช้ Vuetify |
| `v-main` | พื้นที่เนื้อหาหลัก จัดให้อยู่ใต้ app-bar และข้าง navigation-drawer อัตโนมัติ |
| `v-container` | จำกัดความกว้างเนื้อหาให้อยู่กึ่งกลางจอ (ใช้คู่กับ `v-row`/`v-col`) |
| `v-row` / `v-col` | ระบบ grid 12 คอลัมน์ ของ Vuetify แบ่ง layout เป็นแถว/คอลัมน์ |
| `v-navigation-drawer` | เมนูด้านข้าง (sidebar) เปิด/ปิดได้ |
| `v-app-bar` | แถบด้านบนสุดของหน้า (header) |
| `v-app-bar-title` | ข้อความหัวเรื่องใน `v-app-bar` |
| `v-app-bar-nav-icon` | ปุ่ม hamburger สำหรับเปิด/ปิด `v-navigation-drawer` |
| `NuxtLayout` | ตัวเลือก layout ให้หน้าปัจจุบัน (จาก `layouts/*.vue`) |
| `NuxtPage` | จุดที่ page component ปัจจุบันถูก render ตาม route |

**Attribute ที่พบ**

| Element | Attribute | หน้าที่ |
|---|---|---|
| `v-container` | `fluid` | ให้ container กว้างเต็มจอ ไม่จำกัดความกว้างสูงสุด |
| `v-container` | `class` | ใส่ CSS utility class ของ Vuetify (เช่น `d-flex`, `mb-4`) |
| `v-col` | `cols` | จำนวนคอลัมน์ที่ครอบครองบนจอเล็ก (มือถือ, ค่าเต็ม 12) |
| `v-col` | `sm` / `md` | จำนวนคอลัมน์ตอนจอขนาด small / medium ขึ้นไป (responsive) |
| `v-col` | `:key` | key สำหรับ `v-for` (บังคับเวลา loop) |
| `v-navigation-drawer` | `v-model` | ผูกสถานะเปิด/ปิด (two-way binding กับตัวแปรใน script) |
| `v-navigation-drawer` | `:permanent` | true = ปักหมุดเปิดค้างตลอด ไม่ใช่ overlay ทับเนื้อหา |
| `v-app-bar` | `color` | สีพื้นหลังแถบบน |
| `v-app-bar` | `density` | ความสูง/ความอัดแน่นของแถบ (compact/comfortable/default) |
| `v-app-bar-nav-icon` | `@click` | เหตุการณ์ตอนกดปุ่ม → สลับค่า `drawer` |
| `v-app-bar-nav-icon` | `class` | ปรับสไตล์เพิ่มเติม (เช่นซ่อนตอนจอใหญ่) |
| `v-main` | `class` / `style` | จัดตำแหน่งเนื้อหา เช่น จัดกึ่งกลาง |

---

## 2. การ์ด / แสดงเนื้อหา (Content Display)

| Element | หน้าที่ |
|---|---|
| `v-card` | กล่องเนื้อหาแบบมีเงา (การ์ด) ใช้ห่อข้อมูลเป็นกลุ่มๆ |
| `v-card-title` | หัวเรื่องของการ์ด |
| `v-card-text` | เนื้อหาหลักของการ์ด |
| `v-card-actions` | แถบปุ่ม/action ท้ายการ์ด (เช่นปุ่มบันทึก/ยกเลิก) |
| `v-list` | รายการแนวตั้ง (ใช้เป็นเมนูหรือแสดงรายการข้อมูล) |
| `v-list-item` | แต่ละแถวใน `v-list` |
| `v-table` | ตารางสไตล์ Vuetify (ใช้ร่วมกับ `<thead>/<tbody>` แบบ HTML ปกติ) |
| `v-divider` | เส้นคั่นระหว่างเนื้อหา |
| `v-spacer` | ตัวดันเนื้อหาสองฝั่งให้ห่างกัน (มักใช้ใน `v-card-actions`/`v-app-bar` เพื่อดันปุ่มไปขวาสุด) |

**Attribute ที่พบ**

| Element | Attribute | หน้าที่ |
|---|---|---|
| `v-card` | `:color` | สีพื้นหลังการ์ด (bind ค่าจากตัวแปร เช่นสีตามสถานะ) |
| `v-card` | `:to` | คลิกที่การ์ดแล้วนำทางไปหน้าอื่น (การ์ดทำหน้าที่เหมือนลิงก์) |
| `v-card` | `hover` | เพิ่ม effect เงาตอนเอาเมาส์ชี้ |
| `v-card` | `max-width` / `width` | กำหนดความกว้างการ์ด |
| `v-card` | `theme` | บังคับธีมสี (light/dark) เฉพาะการ์ดนี้ |
| `v-card` | `id` | ใช้เป็น anchor สำหรับ scroll ไปยังตำแหน่งนี้ |
| `v-card` | `:key` / `v-for` / `v-if` | วนลูปแสดงการ์ดหลายใบจาก array + เงื่อนไขแสดงผล |
| `v-list` | `nav` | ปรับสไตล์ให้เหมาะกับใช้เป็นเมนูนำทาง |
| `v-list-item` | `:prepend-icon` | ไอคอนด้านหน้าของแต่ละแถวเมนู |
| `v-list-item` | `:title` | ข้อความหลักของแถว |
| `v-list-item` | `:to` | ลิงก์ปลายทางเมื่อกด (เมนูนำทาง) |
| `v-list-item` | `color` | สีข้อความ/ไอคอนตอนแถวถูกเลือก |
| `v-table` / `td` / `th` | `density` / `hover` | ความอัดแน่นของแถว / ไฮไลต์แถวตอนชี้เมาส์ |
| `td` | `colspan` | รวมช่องข้ามหลายคอลัมน์ (ใช้ตอนไม่มีข้อมูล) |

---

## 3. ปุ่มและการนำทาง (Buttons & Navigation)

| Element | หน้าที่ |
|---|---|
| `v-btn` | ปุ่มกด |
| `v-btn-toggle` | กลุ่มปุ่มให้เลือกได้ทีละอัน (คล้าย radio แต่หน้าตาเป็นปุ่ม) |
| `NuxtLink` | ลิงก์ไปหน้าอื่นในแอป (client-side navigation ไม่ reload หน้า) |
| `a` | ลิงก์ HTML ปกติ (ใช้ตอนต้องเปิดลิงก์ภายนอก/ดาวน์โหลดไฟล์) |

**Attribute ที่พบ**

| Element | Attribute | หน้าที่ |
|---|---|---|
| `v-btn` | `:to` / `to` | ปลายทางที่จะนำทางไปเมื่อกด (เหมือน `<NuxtLink>`) |
| `v-btn` | `@click` | ฟังก์ชันที่รันตอนกดปุ่ม |
| `v-btn` | `color` | สีปุ่ม |
| `v-btn` | `variant` | รูปแบบปุ่ม (`flat`, `outlined`, `text`, `tonal` ฯลฯ) |
| `v-btn` | `size` | ขนาดปุ่ม |
| `v-btn` | `icon` | true = ทำให้ปุ่มเป็นวงกลมมีแค่ไอคอน ไม่มีข้อความ |
| `v-btn` | `prepend-icon` | ใส่ไอคอนไว้หน้าข้อความในปุ่ม |
| `v-btn` | `:disabled` | ปิดการกดปุ่มตามเงื่อนไข (เช่นข้อมูลยังไม่ครบ) |
| `v-btn` | `:loading` | แสดงสถานะกำลังโหลด (spinner ในปุ่ม) ระหว่างรอ API ตอบกลับ |
| `v-btn` | `block` | ขยายปุ่มให้เต็มความกว้าง container |
| `v-btn` | `type` | ประเภทปุ่มในฟอร์ม (`submit` เพื่อ trigger `v-form`) |
| `v-btn` | `value` | ค่าประจำตัวเวลาอยู่ใน `v-btn-toggle` |
| `v-btn-toggle` | `v-model` | ผูกค่าปุ่มที่ถูกเลือกอยู่ |
| `v-btn-toggle` | `mandatory` | บังคับต้องเลือกอย่างน้อย 1 ปุ่มเสมอ |
| `v-btn-toggle` | `density` / `color` / `variant` | ปรับหน้าตากลุ่มปุ่ม |
| `NuxtLink` | `to` | เส้นทางปลายทาง |
| `a` | `:href` | ปลายทางลิงก์ (bind แบบ dynamic เช่น URL ไฟล์แนบ) |
| `a` | `target` | เปิดลิงก์แท็บใหม่ (`_blank`) |

---

## 4. ฟอร์ม / รับข้อมูล (Form Inputs)

| Element | หน้าที่ |
|---|---|
| `v-form` | ครอบ input ทั้งหมดของฟอร์ม เพื่อ validate/submit พร้อมกัน |
| `v-text-field` | ช่องกรอกข้อความบรรทัดเดียว |
| `v-textarea` | ช่องกรอกข้อความหลายบรรทัด |
| `v-select` | dropdown เลือกค่าจากรายการ |
| `v-checkbox` | checkbox (เลือกได้/ไม่ได้) |
| `v-file-input` | ปุ่มเลือกไฟล์อัปโหลด |

**Attribute ที่พบ**

| Element | Attribute | หน้าที่ |
|---|---|---|
| `v-form` | `@submit.prevent` | ดักเหตุการณ์ submit แล้วกัน browser reload หน้า (`.prevent`) เพื่อเรียกฟังก์ชันเอง |
| `v-text-field` / `v-textarea` / `v-select` / `v-checkbox` / `v-file-input` | `v-model` | ผูกค่าที่กรอก/เลือกเข้ากับตัวแปรใน script แบบ two-way |
| `v-text-field` / `v-select` / `v-textarea` | `label` | ข้อความ label ลอยเหนือช่อง |
| `v-text-field` | `:model-value` | ใช้แทน `v-model` ตอนต้องการ custom logic ตอนค่าเปลี่ยน (one-way + event) |
| `v-text-field` | `type` | ประเภท input (`password`, `date`, `number` ฯลฯ) |
| `v-text-field` | `autocomplete` | คุมพฤติกรรม autofill ของเบราว์เซอร์ (เช่น `new-password`) |
| `v-text-field` | `readonly` | ห้ามแก้ไขค่า (แสดงอย่างเดียว) |
| `v-text-field` | `placeholder` | ข้อความจางๆ ตอนช่องว่าง |
| `v-text-field` | `hint` / `persistent-hint` | ข้อความคำอธิบายใต้ช่อง / บังคับให้แสดงตลอด |
| `v-text-field` | `prepend-inner-icon` | ไอคอนด้านในซ้ายของช่อง |
| `v-text-field` / `v-select` / `v-textarea` / `v-checkbox` | `:disabled` | ปิดการแก้ไขตามเงื่อนไข |
| `v-text-field` / `v-select` / `v-textarea` / `v-checkbox` / `v-file-input` | `variant` | รูปแบบกรอบช่อง (`outlined`, `underlined` ฯลฯ) |
| `v-text-field` / `v-select` / `v-checkbox` | `density` / `hide-details` | ความอัดแน่น / ซ่อนพื้นที่ข้อความ error ด้านล่างเวลาไม่ใช้ |
| `v-text-field` | `:error-messages` | ข้อความ error ที่ผูกจาก validation ใน script |
| `v-select` | `:items` | รายการตัวเลือกทั้งหมดให้เลือก |
| `v-checkbox` | `label` / `value` | ข้อความข้าง checkbox / ค่าที่ใช้ตอนถูกเลือก |
| `v-file-input` | `multiple` | เลือกได้หลายไฟล์พร้อมกัน |
| `v-file-input` | `show-size` | แสดงขนาดไฟล์ที่เลือก |
| `v-file-input` | `prepend-icon` | ไอคอนหน้าปุ่มเลือกไฟล์ |
| `v-textarea` | `rows` | จำนวนบรรทัดที่แสดง |

---

## 5. แสดงข้อมูล / สถานะ (Data & Status Display)

| Element | หน้าที่ |
|---|---|
| `v-data-table-server` | ตารางข้อมูลแบบแบ่งหน้า (pagination) โดยดึงข้อมูลจาก backend ทีละหน้า |
| `v-chip` | ป้ายเล็กๆ แสดงสถานะ/แท็ก |
| `v-alert` | กล่องข้อความแจ้งเตือน (สำเร็จ/ผิดพลาด/คำเตือน) |
| `v-progress-linear` | แถบความคืบหน้าแนวนอน |
| `v-progress-circular` | วงกลมหมุนแสดงสถานะกำลังโหลด |
| `v-icon` | ไอคอน (จาก Material Design Icons) |
| `v-snackbar` | ข้อความแจ้งเตือนเด้งมุมจอชั่วคราว |

**Attribute ที่พบ**

| Element | Attribute | หน้าที่ |
|---|---|---|
| `v-data-table-server` | `:headers` | นิยามคอลัมน์ของตาราง (key, title) |
| `v-data-table-server` | `:items` | ข้อมูลของหน้าปัจจุบันที่จะแสดง |
| `v-data-table-server` | `:items-length` | จำนวนแถวทั้งหมด (ใช้คำนวณจำนวนหน้า) |
| `v-data-table-server` | `:items-per-page` | จำนวนแถวต่อหน้า |
| `v-data-table-server` | `:loading` | แสดง loading bar ระหว่างรอข้อมูลจาก API |
| `v-data-table-server` | `:options` | สถานะการแบ่งหน้า/เรียงลำดับปัจจุบัน (ผูกสองทาง) |
| `v-data-table-server` | `@update:options` | เหตุการณ์ตอนผู้ใช้เปลี่ยนหน้า/เรียงลำดับ → ไปดึงข้อมูลใหม่ |
| `v-chip` | `:color` | สีของป้าย (มักผูกตามสถานะ เช่น เขียว=ผ่าน แดง=ไม่ผ่าน) |
| `v-chip` | `:variant` | รูปแบบป้าย (`flat`, `outlined`, `tonal`) |
| `v-chip` | `size` | ขนาดป้าย |
| `v-chip` | `:closable` / `:close` | แสดงปุ่ม X ให้ลบป้ายนี้ได้ |
| `v-chip` | `:href` / `target` | ทำให้ป้ายเป็นลิงก์ (เช่นลิงก์ดาวน์โหลดไฟล์แนบ) |
| `v-chip` | `prepend-icon` | ไอคอนหน้าข้อความในป้าย |
| `v-alert` | `type` | ประเภทการแจ้งเตือน (`success`, `error`, `warning`, `info`) กำหนดสี/ไอคอนอัตโนมัติ |
| `v-alert` | `density` / `variant` | ความอัดแน่น / รูปแบบกล่อง |
| `v-progress-linear` | `:model-value` | ค่าความคืบหน้าปัจจุบัน (0-100) |
| `v-progress-linear` | `height` / `rounded` | ความหนา / มุมโค้งของแถบ |
| `v-progress-circular` | `indeterminate` | หมุนวนไม่มีค่าคงที่ (ใช้ตอนไม่รู้ % ความคืบหน้า) |
| `v-icon` | `color` / `size` | สี / ขนาดไอคอน |
| `v-icon` | `@click` | ทำให้ไอคอนกดได้เหมือนปุ่มเล็กๆ |
| `v-snackbar` | `v-model` | ควบคุมการแสดง/ซ่อน |
| `v-snackbar` | `:color` | สีพื้นหลัง (เขียว=สำเร็จ, แดง=error) |
| `v-snackbar` | `location` | ตำแหน่งที่เด้งขึ้นจอ (เช่น `top right`) |

---

## 6. แท็บและช่องเนื้อหาสลับ (Tabs & Panels)

| Element | หน้าที่ |
|---|---|
| `v-tabs` | แถบแท็บให้สลับหมวดเนื้อหา |
| `v-tab` | แต่ละปุ่มแท็บใน `v-tabs` |
| `v-window` | คอนเทนเนอร์สลับเนื้อหาไปตามแท็บ/สถานะที่เลือก (ไม่มีอนิเมชันแท็บในตัว) |
| `v-window-item` | แต่ละหน้าเนื้อหาใน `v-window` |
| `v-expansion-panels` | กลุ่ม accordion (พับ/กางเนื้อหาได้) |
| `v-expansion-panel` | แต่ละแถวใน accordion |
| `v-expansion-panel-title` | หัวข้อที่กดเพื่อกาง/พับ |
| `v-expansion-panel-text` | เนื้อหาที่ซ่อน/แสดงเมื่อกาง |

**Attribute ที่พบ**

| Element | Attribute | หน้าที่ |
|---|---|---|
| `v-tabs` | `v-model` | ผูกแท็บที่กำลังถูกเลือกอยู่ |
| `v-tabs` | `color` | สีแท็บที่ถูกเลือก |
| `v-tab` | `value` | ค่าประจำตัวของแท็บ (จับคู่กับ `v-window-item :value`) |
| `v-window` | `v-model` | ผูกกับค่าที่กำลังแสดงอยู่ (ใช้ค่าเดียวกับ `v-tabs v-model`) |
| `v-window-item` | `:value` | ค่าที่ใช้จับคู่ว่าเนื้อหานี้แสดงเมื่อ `v-window` มีค่านี้ |
| `v-expansion-panels` | `multiple` | กางได้พร้อมกันหลายแถว (ปกติกางได้ทีละแถว) |
| `v-expansion-panels` | `variant` | รูปแบบ accordion |

---

## 7. Dialog / Overlay

| Element | หน้าที่ |
|---|---|
| `v-dialog` | หน้าต่าง popup ลอยทับหน้าจอ (modal) |

**Attribute ที่พบ**

| Element | Attribute | หน้าที่ |
|---|---|---|
| `v-dialog` | `v-model` | ควบคุมเปิด/ปิด dialog |
| `v-dialog` | `max-width` | จำกัดความกว้าง dialog |

---

## 8. Component ที่เขียนเอง (Custom Components)

| Element | หน้าที่ |
|---|---|
| `CrudTable` | ตาราง CRUD สำเร็จรูป ใช้ซ้ำได้ทุกหน้าที่ต้อง list/add/edit/delete ข้อมูล (ดู `components/CrudTable.vue`) |
| `EvaluationReport` | การ์ดสรุปผลคะแนนประเมิน ใช้ซ้ำทั้งฝั่งกรรมการดูรายงานและฝั่งผู้รับการประเมินดูผล (ดู `components/EvaluationReport.vue`) |

**Attribute ที่พบ**

| Element | Attribute | หน้าที่ |
|---|---|---|
| `CrudTable` | `title` | หัวข้อของตาราง (แสดงบนสุด) |
| `CrudTable` | `endpoint` | path ของ API ที่ตารางนี้จะเรียกใช้ (`/topics`, `/indicators` ฯลฯ) |
| `CrudTable` | `:headers` | นิยามคอลัมน์ตาราง |
| `CrudTable` | `:fields` | นิยาม field ของฟอร์ม add/edit (ใช้ generate dialog ฟอร์มอัตโนมัติ) |
| `CrudTable` | `:new-defaults` | ค่าเริ่มต้นของฟอร์มตอนกด "เพิ่มใหม่" |
| `CrudTable` | `:extra-params` | query param เพิ่มเติมที่ส่งไปกับทุก request (เช่น filter ตาม period) |
| `CrudTable` | `default-sort-by` | คอลัมน์ที่เรียงลำดับเริ่มต้น |
| `CrudTable` | `@changed` | เหตุการณ์แจ้งกลับไป parent ตอนข้อมูลในตารางถูกแก้ไข (เพิ่ม/ลบ/แก้) |
| `EvaluationReport` | `:summary` | ข้อมูลสรุปคะแนนที่จะเอามาแสดง (ได้มาจาก API `summary`) |

---

## 9. HTML พื้นฐาน (Native Elements)

| Element | หน้าที่ |
|---|---|
| `div`, `span`, `p`, `b` | กล่อง/ข้อความทั่วไป ใช้จัด layout หรือแสดงข้อความที่ Vuetify component ไม่ครอบคลุม |
| `h2`, `h3`, `h4` | หัวข้อ (heading) ตามลำดับความสำคัญ |
| `ul`, `li` | รายการแบบไม่มีลำดับ |
| `table`, `thead`, `tbody`, `tfoot`, `tr`, `th`, `td` | ตาราง HTML ปกติ (ใช้ตอนไม่ต้องการ feature ของ `v-table`) |
| `img` | รูปภาพ |
| `svg`, `g`, `text` | กราฟิกเวกเตอร์ (ใช้วาดกราฟแท่งในหน้า `admin/index.vue`) |
| `canvas` | พื้นที่วาดด้วย JavaScript (ใช้ทำลายเซ็นดิจิทัลในหน้าประเมิน) |
| `slot` | จุดที่ component รับเนื้อหาจาก parent มาแสดง (content projection) |

**Attribute ที่พบ**

| Element | Attribute | หน้าที่ |
|---|---|---|
| `img` | `:src` | ที่อยู่รูปภาพ (bind แบบ dynamic เช่น path ไฟล์แนบจาก API) |
| `img` | `alt` | ข้อความสำรองเมื่อโหลดรูปไม่ได้ |
| `svg` | `:viewBox` | กำหนดขอบเขตพิกัดของภาพ (ใช้คำนวณ scale ให้กราฟพอดีกรอบ) |
| `svg` / `g` | `:transform` | เลื่อน/ขยับตำแหน่งกลุ่ม element ภายใน (ใช้จัดแถวกราฟแท่ง) |
| `text` | `x`, `y` | ตำแหน่งข้อความในพิกัด SVG |
| `text` | `fill` | สีตัวอักษรใน SVG |
| `text` | `font-size` | ขนาดตัวอักษรใน SVG |
| `canvas` | `ref` | เก็บ reference ให้ script เข้าถึง DOM element เพื่อวาดลายเซ็นด้วย JS โดยตรง |
| `canvas` | `@pointerdown/@pointermove/@pointerup/@pointerleave` | เหตุการณ์ลาก mouse/นิ้ว เพื่อวาดลายเซ็น |
| `td` | `colspan` | รวมช่องข้ามหลายคอลัมน์ |

---

## 10. Directive มาตรฐานของ Vue (ใช้ปนอยู่ในแทบทุก element)

| Directive | หน้าที่ |
|---|---|
| `v-if` / `v-else-if` / `v-else` | แสดง/ซ่อน element ตามเงื่อนไข (ไม่ตรงเงื่อนไข = ไม่ render เลย) |
| `v-show` | แสดง/ซ่อนด้วย CSS (`display:none`) — element ยัง render อยู่ในหน้า |
| `v-for` | วนลูป render element ซ้ำตามจำนวนข้อมูลใน array |
| `:key` | ระบุ id เฉพาะของแต่ละ element ตอน `v-for` เพื่อให้ Vue update DOM ได้ถูกต้อง/มีประสิทธิภาพ |
| `v-model` | ผูกค่าสองทาง (two-way binding) ระหว่าง input กับตัวแปรใน script |
| `:attr` (v-bind) | ผูกค่า attribute แบบ dynamic จากตัวแปรใน script (แทน hardcode string) |
| `@event` (v-on) | ดักเหตุการณ์ (คลิก, submit, เปลี่ยนค่า ฯลฯ) แล้วเรียกฟังก์ชันใน script |
| `class` | ใส่ CSS class แบบ static หรือ dynamic (Vuetify มี utility class สำเร็จรูป เช่น `d-flex`, `mb-4`, `text-center`) |
| `style` | ใส่ inline CSS โดยตรง (มักใช้ตอนค่ามาจากตัวแปร เช่นความกว้าง % ที่คำนวณเอง) |
