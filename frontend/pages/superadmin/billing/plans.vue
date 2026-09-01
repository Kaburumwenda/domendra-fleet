<template>
  <div class="d-flex flex-column ga-4">
    <div class="d-flex align-center ga-3 flex-wrap">
      <div class="d-flex align-center justify-center rounded-xl" style="width: 48px; height: 48px; background: linear-gradient(135deg, #8b5cf6, #7c3aed)">
        <v-icon color="white">mdi-package-variant-closed</v-icon>
      </div>
      <div>
        <h1 class="text-h5 font-weight-bold">Billing Plans</h1>
        <p class="text-body-2 text-medium-emphasis mb-0">Tier configuration for tenant subscriptions</p>
      </div>
      <v-spacer />
      <v-btn color="primary" prepend-icon="mdi-plus" @click="openDialog()">New Plan</v-btn>
    </div>

    <v-row dense>
      <v-col cols="12" sm="6" md="3" v-for="plan in rows" :key="plan.id">
        <v-card elevation="0" border rounded="lg" class="pa-5 h-100 d-flex flex-column">
          <div class="d-flex align-center justify-space-between mb-2">
            <v-avatar rounded color="primary" variant="tonal" size="36"><v-icon size="small">mdi-package-variant</v-icon></v-avatar>
            <v-chip v-if="plan.is_active" color="success" size="x-small" variant="flat">Active</v-chip>
            <v-chip v-else color="grey" size="x-small" variant="flat">Inactive</v-chip>
          </div>
          <h3 class="text-h6 font-weight-bold text-capitalize">{{ plan.name }}</h3>
          <p class="text-body-2 text-medium-emphasis flex-1">{{ plan.description || '—' }}</p>
          <div class="d-flex flex-column ga-1 mt-3">
            <div class="d-flex justify-space-between"><span class="text-caption text-medium-emphasis">Base price</span><span class="text-body-2 font-weight-medium">{{ fmtUsd(plan.price) }}</span></div>
            <div class="d-flex justify-space-between"><span class="text-caption text-medium-emphasis">Included requests</span><span class="text-body-2 font-weight-medium">{{ fmtNum(plan.included_requests) }}</span></div>
            <div class="d-flex justify-space-between"><span class="text-caption text-medium-emphasis">Rate /1k</span><span class="text-body-2 font-weight-medium">{{ fmtUsd(plan.rate_per_1000_requests) }}</span></div>
          </div>
          <div class="d-flex ga-1 mt-3">
            <v-btn size="small" variant="text" icon="mdi-pencil" @click="openDialog(plan)" />
            <v-btn size="small" variant="text" color="error" icon="mdi-delete" @click="remove(plan)" />
          </div>
        </v-card>
      </v-col>
    </v-row>

    <v-dialog v-model="open" max-width="520">
      <v-card rounded="lg" elevation="12">
        <v-card-title class="text-h6 font-weight-bold">{{ editing ? 'Edit Plan' : 'New Plan' }}</v-card-title>
        <v-card-text>
          <v-row dense>
            <v-col cols="12"><v-text-field v-model="form.name" label="Name" /></v-col>
            <v-col cols="12"><v-textarea v-model="form.description" label="Description" rows="2" /></v-col>
            <v-col cols="6"><v-text-field v-model.number="form.price" type="number" label="Base price (USD)" /></v-col>
            <v-col cols="6"><v-text-field v-model.number="form.included_requests" type="number" label="Included requests" /></v-col>
            <v-col cols="6"><v-text-field v-model.number="form.rate_per_1000_requests" type="number" step="0.0001" label="Rate per 1k requests" /></v-col>
            <v-col cols="6" class="d-flex align-center"><v-switch v-model="form.is_active" color="primary" label="Active" /></v-col>
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
const loading = ref(false)
const open = ref(false)
const editing = ref<any>(null)
const saving = ref(false)
const form = reactive<any>({ name: '', description: '', price: 0, included_requests: 10000, rate_per_1000_requests: 0.077, is_active: true })

async function load() {
  loading.value = true
  try {
    const data: any = await $api('/superadmin/plans/')
    rows.value = data.results || data
  } finally { loading.value = false }
}
onMounted(load)

function openDialog(plan?: any) {
  if (plan) {
    editing.value = plan
    Object.assign(form, plan)
  } else {
    editing.value = null
    Object.assign(form, { name: '', description: '', price: 0, included_requests: 10000, rate_per_1000_requests: 0.077, is_active: true })
  }
  open.value = true
}

async function save() {
  saving.value = true
  try {
    if (editing.value) {
      await $api(`/superadmin/plans/${editing.value.id}/`, { method: 'PATCH', body: form })
    } else {
      await $api('/superadmin/plans/', { method: 'POST', body: form })
    }
    open.value = false
    await load()
    $swal.fire({ icon: 'success', title: 'Plan saved', timer: 1500, toast: true, position: 'top-end' })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Failed', text: e?.data?.detail || 'Could not save plan' })
  } finally { saving.value = false }
}

async function remove(plan: any) {
  const res = await $swal.fire({ icon: 'warning', title: `Delete ${plan.name}?`, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!res.isConfirmed) return
  await $api(`/superadmin/plans/${plan.id}/`, { method: 'DELETE' })
  load()
}
</script>
