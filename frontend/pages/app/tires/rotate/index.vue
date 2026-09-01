<template>
  <TireRotationScreen
    :vehicles="vehicleOptions"
    :tires="tires"
    :loading="pending"
    :presets="presets"
    @rotated="handleRotated"
    @cancel="goBack"
  />
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

const route = useRoute()
const { $api } = useNuxtApp()

const vehicleId = computed(() => route.query.vehicle ? Number(route.query.vehicle) : null)

const presets = computed(() => ({
  vehicle: vehicleId.value ?? null,
}))

const { data: vehiclesData, pending } = useAsyncData<any>('rotation-vehicles', () => $api('/vehicles/vehicles/'), { default: () => ({ results: [] }) })
const vehicleOptions = computed(() => vehiclesData.value?.results || [])

const { data: tiresData } = useAsyncData<any>('rotation-tires', () => $api('/tires/'), { default: () => ({ results: [] }) })
const tires = computed(() => tiresData.value?.results || tiresData.value || [])

function goBack() {
  navigateTo('/app/tires')
}

async function handleRotated() {
  try {
    await refreshNuxtData(['tires-list', 'tire-rotations', 'tire-movements', 'rotation-tires'])
  } catch { /* noop */ }
  navigateTo('/app/tires')
}
</script>
