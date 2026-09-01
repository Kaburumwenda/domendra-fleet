<template>
  <div class="d-flex flex-column ga-4">
    <div class="page-header-bar">
      <div class="d-flex align-center ga-2">
        <v-btn icon="mdi-arrow-left" variant="text" size="small" @click="goBack" />
        <div class="d-flex align-center ga-2">
          <v-icon color="primary">mdi-eye-outline</v-icon>
          <span class="text-h6 font-weight-bold page-header-title">View Vehicle</span>
        </div>
      </div>
      <v-btn variant="text" prepend-icon="mdi-pencil-outline" @click="goEdit">Edit</v-btn>
    </div>

    <v-card elevation="0" border rounded="lg" class="overflow-hidden page-wizard-card">
      <div v-if="pending" class="d-flex justify-center align-center pa-16">
        <v-progress-circular indeterminate color="primary" />
      </div>
      <VehicleViewWizard v-else :vehicle-id="id" @back="goBack" @edit="goEdit" />
    </v-card>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

const route = useRoute()
const id = computed(() => route.params.id as string)

const { $api } = useNuxtApp()
const pending = ref(true)
onMounted(async () => {
  try { await $api(`/vehicles/vehicles/${id.value}/`) } finally { pending.value = false }
})

function goBack() { navigateTo('/app/vehicles') }
function goEdit() { navigateTo(`/app/vehicles/${id.value}/edit`) }
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
.page-header-title {
  color: #0f172a;
  letter-spacing: -0.01em;
}
.page-wizard-card {
  border-color: #e2e8f0 !important;
  box-shadow: 0 12px 32px rgba(15, 23, 42, 0.06) !important;
}
</style>
