<template>
  <div>
    <div v-if="pending" class="d-flex justify-center align-center pa-16">
      <v-progress-circular indeterminate color="primary" />
    </div>
    <VehicleFuelDetail v-else :vehicle-id="id" />
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
</script>
