<template>
  <div class="d-flex flex-column ga-4">
    <div class="page-header-bar">
      <div class="d-flex align-center ga-2">
        <v-btn icon="mdi-arrow-left" variant="text" size="small" @click="goBack" />
        <div class="d-flex align-center ga-2">
          <v-icon color="primary">mdi-account-plus-outline</v-icon>
          <span class="text-h6 font-weight-bold page-header-title">Add Driver</span>
        </div>
      </div>
    </div>

    <v-card elevation="0" border rounded="lg" class="pa-6">
      <DriverFormWizard @saved="onSaved" @cancel="goBack" />
    </v-card>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

function goBack() { navigateTo('/app/drivers') }
function onSaved() { navigateTo('/app/drivers') }
</script>

<style scoped>
.page-header-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 16px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
}
.page-header-title { color: #0f172a; letter-spacing: -0.01em; }
</style>
