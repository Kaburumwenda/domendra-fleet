<template>
  <div class="d-flex flex-column ga-4">
    <div class="d-flex flex-wrap align-center justify-space-between ga-2">
      <h3 class="text-subtitle-1 font-weight-bold">Expense Budgets</h3>
      <div class="d-flex align-center ga-2">
        <v-text-field v-model="month" type="date" label="Month" density="compact" variant="outlined" hide-details style="max-width: 170px" @update:model-value="loadSummary" />
        <v-btn color="primary" size="small" prepend-icon="mdi-plus" variant="tonal" @click="openDialog()">Add Budget</v-btn>
      </div>
    </div>

    <v-card elevation="0" border rounded="lg" class="pa-5">
      <div v-if="!summaryRows.length" class="text-center py-8 text-medium-emphasis">
        <v-icon size="48" class="mb-3">mdi-chart-arc</v-icon>
        <p>No budgets set for {{ fmtMonth(month) }}.</p>
        <v-btn color="primary" variant="tonal" size="small" class="mt-2" prepend-icon="mdi-plus" @click="openDialog()">Add a Budget</v-btn>
      </div>
      <div v-for="row in summaryRows" :key="row.id" class="mb-4">
        <div class="d-flex align-center justify-space-between mb-1">
          <span class="text-body-2 font-weight-medium">{{ row.budget_label }}{{ row.target_ref ? ' · ' + row.target_ref : '' }}</span>
          <div class="d-flex align-center ga-2">
            <span class="text-caption text-medium-emphasis">{{ currencySymbol }}{{ row.actual_amount }} / {{ currencySymbol }}{{ row.budget_amount }}</span>
            <v-chip size="x-small" :color="budgetColor(row.pct_used)" variant="tonal">{{ row.pct_used }}%</v-chip>
            <v-btn icon="mdi-delete-outline" size="x-small" variant="text" color="error" @click="removeBudget(row)" />
          </div>
        </div>
        <v-progress-linear :model-value="Math.min(row.pct_used, 100)" :color="budgetColor(row.pct_used)" height="10" rounded />
        <p class="text-caption mt-1" :class="Number(row.variance) &lt; 0 ? 'text-error' : 'text-success'">
          {{ Number(row.variance) &lt; 0 ? 'Over by' : 'Under by' }} {{ currencySymbol }}{{ Math.abs(Number(row.variance)).toFixed(0) }}
        </p>
      </div>
    </v-card>

    <!-- Dialog -->
    <v-dialog v-model="dialog" max-width="520" scroll-strategy="none">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-chart-arc">{{ editing ? 'Edit' : 'Add' }} Budget</AppModalHeader>
        <v-card-text class="pt-5">
          <v-row dense>
            <v-col cols="12">
              <v-select v-model="form.scope" :items="scopeOptions" item-title="label" item-value="value" label="Scope *" @update:model-value="onScopeChange" />
            </v-col>
            <v-col v-if="form.scope === 'vehicle_type'" cols="12">
              <v-select v-model="form.target_ref" :items="vehicleTypeOptions" label="Vehicle Type" hide-details="auto" clearable />
            </v-col>
            <v-col v-else-if="form.scope === 'location'" cols="12">
              <v-select v-model="form.target_ref" :items="locationOptions" label="Location" hide-details="auto" clearable />
            </v-col>
            <v-col v-else-if="form.scope === 'category'" cols="12">
              <v-select v-model="form.category" :items="categoryOptions" item-title="name" item-value="id" label="Category" hide-details="auto" clearable />
            </v-col>
            <v-col v-else-if="form.scope === 'vehicle'" cols="12">
              <v-select v-model="form.vehicle" :items="vehicleOptions" item-title="display_name" item-value="id" label="Vehicle" hide-details="auto" clearable />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="form.month" type="date" label="Month *" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="form.budget_amount" :label="`Budget Amount (${currencySymbol}) *`" type="number" min="0" step="0.01" hide-details="auto" />
            </v-col>
            <v-col cols="12">
              <v-textarea v-model="form.notes" label="Notes" rows="2" hide-details="auto" />
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="dialog = false">Cancel</v-btn>
          <v-btn color="primary" prepend-icon="mdi-check" :loading="saving" @click="save">{{ editing ? 'Update' : 'Create' }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
const { $swal } = useNuxtApp()
const { saveBudget: apiSave, deleteBudget: apiDel } = useExpenseApi()

const props = defineProps<{
  currencySymbol: string
  vehicleOptions: any[]
  categoryOptions: any[]
}>()

const scopeOptions = [
  { label: 'Fleet-wide', value: 'fleet' },
  { label: 'Vehicle Type', value: 'vehicle_type' },
  { label: 'Location', value: 'location' },
  { label: 'Category', value: 'category' },
  { label: 'Vehicle', value: 'vehicle' },
]

const nowDate = new Date()
const month = ref(`${nowDate.getFullYear()}-${String(nowDate.getMonth() + 1).padStart(2, '0')}-01`)

const vehicleTypeOptions = computed(() => {
  const types = [...new Set(props.vehicleOptions.map((v: any) => v.vehicle_type).filter(Boolean))]
  return types.map((t: string) => ({ title: t, value: t }))
})
const locationOptions = computed(() => {
  const locs = [...new Set(props.vehicleOptions.map((v: any) => v.location).filter(Boolean))]
  return locs.map((l: string) => ({ title: l, value: l }))
})

const summaryRows = ref<any[]>([])
const dialog = ref(false)
const saving = ref(false)
const editing = ref<any>(null)
const defaultForm = () => ({
  scope: 'fleet', target_ref: '', vehicle: null, category: null,
  month: month.value, budget_amount: '0', notes: '',
})
const form = reactive<any>(defaultForm())

function onScopeChange() { form.target_ref = ''; form.vehicle = null; form.category = null }

async function loadSummary() {
  try {
    const { $api } = useNuxtApp() as any
    const res: any = await $api('/expenses/budgets/summary/', { query: { month: month.value } })
    summaryRows.value = res?.rows || []
  } catch (e) { console.error(e); summaryRows.value = [] }
}

function openDialog(item?: any) {
  if (item) { editing.value = item; Object.assign(form, item) }
  else { editing.value = null; Object.assign(form, defaultForm(), { month: month.value }) }
  dialog.value = true
}

async function save() {
  if (!form.budget_amount || Number(form.budget_amount) <= 0) {
    $swal?.fire?.({ icon: 'error', title: 'Budget amount required', timer: 2000, position: 'top-end' }); return
  }
  // If vehicle/category chosen, set target_ref accordingly
  if (form.scope === 'vehicle' && form.vehicle) {
    const v = props.vehicleOptions.find((x: any) => x.id === form.vehicle)
    form.target_ref = v?.display_name || String(form.vehicle)
  } else if (form.scope === 'category' && form.category) {
    const c = props.categoryOptions.find((x: any) => x.id === form.category)
    form.target_ref = c?.name || String(form.category)
  }
  saving.value = true
  try {
    await apiSave({ ...form }, editing.value?.id)
    dialog.value = false
    await loadSummary()
    $swal?.fire?.({ icon: 'success', title: editing.value ? 'Budget updated' : 'Budget created', toast: true, timer: 1500, position: 'top-end' })
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Save failed', toast: true, timer: 2000, position: 'top-end' }) } finally { saving.value = false }
}

async function removeBudget(b: any) {
  const r = await $swal?.fire?.({ icon: 'warning', title: 'Delete budget?', text: b.budget_label, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#dc2626' })
  if (!r?.isConfirmed) return
  await apiDel(b.id)
  await loadSummary()
  $swal?.fire?.({ icon: 'success', title: 'Budget deleted', toast: true, timer: 1500, position: 'top-end' })
}

function fmtMonth(ymd: string) {
  if (!ymd) return ''
  const d = new Date(ymd)
  return d.toLocaleDateString([], { month: 'long', year: 'numeric' })
}

function budgetColor(pct: number) {
  if (pct >= 100) return 'error'
  if (pct >= 80) return 'warning'
  return 'success'
}

onMounted(loadSummary)
watch(month, loadSummary)
</script>
