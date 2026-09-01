<template>
  <TireMountScreen
    :tire="tire"
    :vehicles="vehicleOptions"
    :tires="tires"
    :loading="pending"
    @mounted="handleMounted"
    @cancel="goBack"
  />
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

const route = useRoute()
const { $api } = useNuxtApp()

const tireId = computed(() => route.query.tire as string | undefined)

const { data: vehiclesData } = useAsyncData('mount-vehicles', () => $api('/vehicles/vehicles/'), { default: () => ({ results: [] }) })
const vehicleOptions = computed(() => vehiclesData.value?.results || [])

const { data: tiresData } = useAsyncData('mount-tires', () => $api('/tires/'), { default: () => ({ results: [] }) })
const tires = computed(() => tiresData.value?.results || tiresData.value || [])

const { data: tire, pending } = useAsyncData(
  'mount-tire',
  () => (tireId.value ? $api(`/tires/${tireId.value}/`) : Promise.resolve(null)),
  { watch: [tireId] },
)

function goBack() {
  navigateTo('/app/tires')
}

async function handleMounted() {
  // refresh the cached list data so the tires screen shows updated status on return
  try {
    await refreshNuxtData(['tires-list', 'tire-movements', 'mount-tires', 'tire-mount-history'])
  } catch { /* noop */ }
  navigateTo('/app/tires')
}
</script>
