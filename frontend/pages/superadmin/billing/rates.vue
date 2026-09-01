<template>
  <div class="d-flex flex-column ga-4">
    <div class="d-flex align-center ga-3 flex-wrap">
      <div class="d-flex align-center justify-center rounded-xl" style="width: 48px; height: 48px; background: linear-gradient(135deg, #14b8a6, #0d9488)">
        <v-icon color="white">mdi-currency-usd</v-icon>
      </div>
      <div>
        <h1 class="text-h5 font-weight-bold">Exchange Rates</h1>
        <p class="text-body-2 text-medium-emphasis mb-0">USD → local currency conversion rates used by billing</p>
      </div>
      <v-spacer />
      <v-btn color="primary" prepend-icon="mdi-plus" @click="openDialog()">New Rate</v-btn>
    </div>

    <v-card elevation="0" border rounded="lg">
      <v-table density="comfortable" hover>
        <thead>
          <tr>
            <th>Currency</th>
            <th class="text-end">USD → Currency</th>
            <th>Updated</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="r in rows" :key="r.currency">
            <td><v-chip size="small" variant="flat" color="primary">{{ r.currency }}</v-chip> {{ symbolFor(r.currency) }}</td>
            <td class="text-end font-weight-bold">{{ Number(r.rate).toFixed(4) }}</td>
            <td class="text-body-2">{{ fmtDateTime(r.updated_at) }}</td>
            <td class="text-end">
              <v-btn size="small" variant="text" icon="mdi-pencil" @click="openDialog(r)" />
              <v-btn size="small" variant="text" color="error" icon="mdi-delete" @click="remove(r)" />
            </td>
          </tr>
          <tr v-if="!rows.length"><td colspan="4" class="text-center text-medium-emphasis py-6">No rates</td></tr>
        </tbody>
      </v-table>
    </v-card>

    <v-dialog v-model="open" max-width="480">
      <v-card rounded="lg" elevation="12">
        <v-card-title class="text-h6 font-weight-bold">{{ editing ? 'Edit Rate' : 'New Rate' }}</v-card-title>
        <v-card-text>
          <v-row dense>
            <v-col cols="6"><v-text-field v-model="form.currency" label="Currency (ISO 4217)" :disabled="!!editing" maxlength="3" /></v-col>
            <v-col cols="6"><v-text-field v-model.number="form.rate" type="number" step="0.000001" label="Rate (1 USD = ?)" /></v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-6 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="open = false">Cancel</v-btn>
          <v-btn color="primary" :loading="saving" @click="save">{{ editing ? 'Save' : 'Create' }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'superadmin' })
const { $api, $swal } = useNuxtApp()
const rows = ref<any[]>([])
const open = ref(false)
const editing = ref<any>(null)
const saving = ref(false)
const form = reactive<any>({ currency: '', rate: 1 })

async function load() {
  const data: any = await $api('/superadmin/exchange-rates/')
  rows.value = data.results || data
}
onMounted(load)

function openDialog(r?: any) {
  if (r) {
    editing.value = r
    Object.assign(form, { currency: r.currency, rate: Number(r.rate) })
  } else {
    editing.value = null
    Object.assign(form, { currency: '', rate: 1 })
  }
  open.value = true
}

async function save() {
  saving.value = true
  try {
    if (editing.value) {
      await $api(`/superadmin/exchange-rates/${editing.value.currency}/`, { method: 'PATCH', body: { rate: form.rate } })
    } else {
      await $api('/superadmin/exchange-rates/', { method: 'POST', body: form })
    }
    open.value = false
    await load()
    $swal.fire({ icon: 'success', title: 'Rate saved', timer: 1500, toast: true, position: 'top-end' })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Failed', text: e?.data?.detail || 'Could not save' })
  } finally { saving.value = false }
}

async function remove(r: any) {
  const res = await $swal.fire({ icon: 'warning', title: `Delete ${r.currency}?`, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!res.isConfirmed) return
  await $api(`/superadmin/exchange-rates/${r.currency}/`, { method: 'DELETE' })
  load()
}
</script>
