<template>
  <div class="d-flex flex-column ga-4">
    <div class="page-header-bar">
      <div class="d-flex align-center ga-2">
        <v-btn icon="mdi-arrow-left" variant="text" size="small" @click="goBack" />
        <div class="d-flex align-center ga-2">
          <v-icon color="primary">mdi-account-edit-outline</v-icon>
          <span class="text-h6 font-weight-bold page-header-title">Edit Driver</span>
        </div>
      </div>
    </div>

    <v-card v-if="pending" elevation="0" border rounded="lg" class="d-flex justify-center align-center pa-16">
      <v-progress-circular indeterminate color="primary" />
    </v-card>

    <v-card v-else elevation="0" border rounded="lg" class="overflow-hidden page-wizard-card">
      <DriverFormWizard :driver="driver" @saved="onSaved" @cancel="goBack" />
    </v-card>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

const { $api } = useNuxtApp()
const route = useRoute()
const id = computed(() => route.params.id as string)

const pending = ref(true)
const driver = ref<any>(null)

onMounted(async () => {
  try {
    driver.value = await $api(`/contacts/drivers/${id.value}/`)
  } catch (e) {
    console.error(e)
  } finally {
    pending.value = false
  }
})

function goBack() { navigateTo(`/app/drivers/${id.value}`) }
function onSaved() { navigateTo(`/app/drivers/${id.value}`) }
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
.page-wizard-card {
  border-color: #e2e8f0 !important;
  box-shadow: 0 12px 32px rgba(15, 23, 42, 0.06) !important;
}
</style>
