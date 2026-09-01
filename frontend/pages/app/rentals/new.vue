<template>
  <RentalWizard :editing="editingAgreement" @close="router.push('/app/rentals')" @saved="onSaved" />
</template>

<script setup lang="ts">
definePageMeta({ layout: 'fullwidth' })

const route = useRoute()
const router = useRouter()
const { $api } = useNuxtApp()

const editingAgreement = ref<any>(null)

onMounted(async () => {
  const editId = route.query.edit
  if (editId) {
    try {
      const full = await $api(`/rentals/agreements/${editId}/`)
      editingAgreement.value = full
    } catch {
      // If fetch fails, redirect to list
      router.push('/app/rentals')
    }
  }
})

function onSaved() {
  // The wizard already navigates back; this is a fallback
}
</script>
