<template>
  <TireRotationScreen
    :vehicles="vehicleOptions"
    :tires="tires"
    :loading="loadingRotation || vehiclesPending"
    :editing-rotation="rotation"
    @rotated="handleRotated"
    @cancel="goBack"
  />
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

const route = useRoute()
const { $api } = useNuxtApp()

const rotationId = computed(() => Number(route.params.id) || null)

const { data: rotation, pending: loadingRotation } = useAsyncData<any>(
  `rotation-edit-${rotationId.value}`,
  () => $api(`/tires/rotations/${rotationId.value}/`),
  { default: () => null, watch: [rotationId] }
)

const { data: vehiclesData, pending: vehiclesPending } = useAsyncData<any>(
  'rotation-edit-vehicles',
  () => $api('/vehicles/vehicles/'),
  { default: () => ({ results: [] }) }
)
const vehicleOptions = computed(() => vehiclesData.value?.results || [])

const { data: tiresData } = useAsyncData<any>(
  'rotation-edit-tires',
  () => $api('/tires/'),
  { default: () => ({ results: [] }) }
)
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
