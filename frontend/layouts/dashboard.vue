<template>
  <div>
    <v-app-bar color="indigo-darken-2" density="comfortable">
      <v-app-bar-nav-icon @click="drawer = !drawer" class="d-md-none" />
      <v-app-bar-title>ระบบประเมินบุคลากร (PES)</v-app-bar-title>
      <v-spacer />
      <span class="mr-3 d-none d-sm-inline">{{ user?.name }} ({{ roleLabel }})</span>
      <v-btn variant="text" prepend-icon="mdi-logout" @click="logout">ออกจากระบบ</v-btn>
    </v-app-bar>

    <v-navigation-drawer v-model="drawer" :permanent="mdAndUp">
      <v-list nav>
        <v-list-item
          v-for="m in menu" :key="m.to"
          :to="m.to" :prepend-icon="m.icon" :title="m.text" color="indigo"
        />
      </v-list>
    </v-navigation-drawer>

    <v-main style="background: #f4f6fa">
      <v-container fluid class="pa-4">
        <slot />
      </v-container>
    </v-main>
  </div>
</template>

<script setup>
import { useDisplay } from "vuetify";
const { user, logout } = useAuth();
const { mdAndUp } = useDisplay();
const drawer = ref(true);

const roleLabel = computed(
  () => ({ admin: "งานบุคลากร", evaluator: "กรรมการ", evaluatee: "ผู้รับการประเมิน" }[user.value?.role])
);

// เมนูตามบทบาท
const menus = {
  admin: [
    { to: "/admin", icon: "mdi-view-dashboard", text: "ภาพรวม/สถิติ" },
    { to: "/admin/setup", icon: "mdi-clipboard-list", text: "ตั้งค่าการประเมิน" },
    { to: "/admin/users", icon: "mdi-account-group", text: "ผู้ใช้งาน" },
    { to: "/admin/tracking", icon: "mdi-clipboard-text-clock", text: "ติดตามสถานะ" },
    { to: "/account", icon: "mdi-account-edit", text: "บัญชีผู้ใช้" },
  ],
  evaluatee: [
    { to: "/me", icon: "mdi-clipboard-edit", text: "แบบประเมินของฉัน" },
    { to: "/me/report", icon: "mdi-file-chart", text: "รายงาน/ส่งออก PDF" },
    { to: "/account", icon: "mdi-account-edit", text: "บัญชีผู้ใช้" },
  ],
  evaluator: [
    { to: "/eval", icon: "mdi-check-decagram", text: "รายการที่ต้องประเมิน" },
    { to: "/account", icon: "mdi-account-edit", text: "บัญชีผู้ใช้" },
  ],
};
const menu = computed(() => menus[user.value?.role] || []);
</script>
