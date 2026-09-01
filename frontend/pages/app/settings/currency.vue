<template>
  <div class="d-flex flex-column ga-6">
    <div class="d-flex align-center justify-space-between">
      <h2 class="text-h6 font-weight-bold">Currency</h2>
      <v-btn variant="text" size="small" prepend-icon="mdi-arrow-left" @click="$router.push('/settings')">Back to Settings</v-btn>
    </div>

    <v-card elevation="0" border class="pa-6">
      <h3 class="text-subtitle-1 font-weight-bold mb-1 d-flex align-center ga-2">
        <v-icon color="primary">mdi-cash</v-icon> Default Currency
      </h3>
      <p class="text-caption text-medium-emphasis mb-4">
        This currency is used across DomendraFleet for costs, billing, and reports.
      </p>

      <v-alert
        v-if="suggested && suggested !== form.currency"
        type="info"
        variant="tonal"
        density="comfortable"
        class="mb-4 text-body-2"
        closable
      >
        Based on your company country, the recommended currency is
        <strong>{{ currencyLabel(suggested) }}</strong>.
        <v-btn variant="text" size="small" class="ml-2 px-1" @click="applySuggested">Use {{ suggested }}</v-btn>
      </v-alert>

      <v-select
        v-model="form.currency"
        :items="currencyOptions"
        item-title="label"
        item-value="value"
        label="Default Currency"
        prepend-inner-icon="mdi-cash-multiple"
        :loading="loading"
        style="max-width: 360px"
      />

      <div class="d-flex justify-end mt-4">
        <v-btn color="primary" size="small" prepend-icon="mdi-content-save" :loading="saving" @click="save">Save Currency</v-btn>
      </div>
    </v-card>

    <v-card elevation="0" border class="pa-6">
      <h3 class="text-subtitle-1 font-weight-bold mb-4 d-flex align-center ga-2">
        <v-icon color="grey">mdi-help-circle-outline</v-icon> How it works
      </h3>
      <v-list density="compact" class="text-body-2">
        <v-list-item prepend-icon="mdi-map-marker-outline">Domendra matches the default currency to your company country.</v-list-item>
        <v-list-item prepend-icon="mdi-cash-usd-outline">If no match is found, it falls back to USD ($).</v-list-item>
        <v-list-item prepend-icon="mdi-pencil-outline">You can override the default at any time using the selector above.</v-list-item>
      </v-list>
    </v-card>

    <v-snackbar v-model="snackbar" :timeout="2500" color="success">Currency updated.</v-snackbar>
  </div>
</template>

<script setup lang="ts">
const { $api } = useNuxtApp()
const loading = ref(true)
const saving = ref(false)
const snackbar = ref(false)

const currencyOptions = ref<{ value: string; label: string }[]>([])
const suggested = ref('')

const form = reactive({ currency: 'USD' })

async function load() {
  loading.value = true
  try {
    const d: any = await $api('/tenant/')
    form.currency = d.currency || 'USD'
    currencyOptions.value = d.currency_choices || []
    try {
      const s: any = await $api('/tenant/suggested-currency/')
      suggested.value = s.suggested || 'USD'
    } catch {}
  } catch {} finally {
    loading.value = false
  }
}

onMounted(load)

async function save() {
  saving.value = true
  try {
    await $api('/tenant/', { method: 'PATCH', body: { currency: form.currency } })
    snackbar.value = true
  } catch (e) { console.error(e) } finally { saving.value = false }
}

function applySuggested() {
  if (suggested.value) form.currency = suggested.value
}

function currencyLabel(code: string) {
  return currencyOptions.value.find((c) => c.value === code)?.label || code
}
</script>
