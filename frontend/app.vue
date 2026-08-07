<template>
  <v-app>
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
    <!-- Snackbar แจ้งเตือนรวมศูนย์ (สำเร็จ/ผิดพลาด/เครือข่ายล้มเหลว) -->
    <v-snackbar v-model="snack.show" :color="snack.color" location="top">
      {{ snack.text }}
    </v-snackbar>
  </v-app>
</template>

<script setup>
const { state: snack } = useSnackbar();
</script>
