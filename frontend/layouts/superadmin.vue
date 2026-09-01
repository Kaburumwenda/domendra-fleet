<template>
  <v-app>
    <SuperAdminSidebar :collapsed="collapsed" />
    <SuperAdminHeader :collapsed="collapsed" @toggle="collapsed = !collapsed" />
    <v-main>
      <v-container fluid class="pa-4 pa-md-6">
        <slot />
      </v-container>
    </v-main>
  </v-app>
</template>

<script setup lang="ts">
const collapsed = ref(false)
</script>
