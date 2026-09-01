<template>
  <div class="d-flex flex-column ga-4">
    <v-row dense>
      <!-- Budget tracking -->
      <v-col cols="12" md="7">
        <v-card elevation="0" border class="pa-5 h-100">
          <div class="d-flex align-center justify-space-between mb-3">
            <h3 class="text-subtitle-2 font-weight-medium d-flex align-center ga-2" style="color: #475569">
              <v-icon size="small" color="primary">mdi-chart-arc</v-icon> Monthly Budget Tracking
            </h3>
            <v-btn v-can="'fuel:create'" color="primary" prepend-icon="mdi-plus" size="small" variant="tonal" @click="openBudgetDialog()">Add Budget</v-btn>
          </div>
          <div v-if="budgetRows.length">
            <div v-for="row in budgetRows" :key="row.id" class="mb-4">
              <div class="d-flex align-center justify-space-between mb-1">
                <span class="text-body-2 font-weight-medium text-capitalize">{{ row.scope }}{{ row.target_ref ? ' · ' + row.target_ref : '' }}</span>
                <div class="d-flex align-center ga-2">
                  <span class="text-caption text-medium-emphasis">{{ currencySymbol }}{{ row.actual.toFixed(0) }} / {{ currencySymbol }}{{ row.budget.toFixed(0) }}</span>
                  <v-chip size="x-small" :color="row.pct_used >= 100 ? 'error' : row.pct_used >= 80 ? 'warning' : 'success'" variant="tonal">{{ row.pct_used }}%</v-chip>
                  <v-btn v-can="'fuel:delete'" icon="mdi-delete-outline" size="x-small" variant="text" color="error" @click="removeBudget(row)" />
                </div>
              </div>
              <v-progress-linear :model-value="Math.min(row.pct_used, 100)" :color="row.pct_used >= 100 ? 'error' : row.pct_used >= 80 ? 'warning' : 'success'" height="10" rounded />
              <p class="text-caption mt-1" :class="row.variance >= 0 ? 'text-error' : 'text-success'">
                {{ row.variance >= 0 ? 'Over by' : 'Under by' }} {{ currencySymbol }}{{ Math.abs(row.variance).toFixed(0) }}
              </p>
            </div>
          </div>
          <div v-else class="text-center py-8 text-medium-emphasis">
            <v-icon size="40" class="mb-2">mdi-chart-arc</v-icon>
            <p>No budgets set for this month.</p>
          </div>
        </v-card>
      </v-col>

      <!-- Charge schedules -->
      <v-col cols="12" md="5">
        <v-card elevation="0" border class="pa-5 h-100">
          <div class="d-flex align-center justify-space-between mb-3">
            <h3 class="text-subtitle-2 font-weight-medium d-flex align-center ga-2" style="color: #475569">
              <v-icon size="small" color="success">mdi-ev-station</v-icon> Charge Schedules
            </h3>
            <v-btn v-can="'fuel:create'" color="primary" prepend-icon="mdi-plus" size="small" variant="tonal" @click="openScheduleDialog()">Add Schedule</v-btn>
          </div>
          <div v-if="schedules.length">
            <div v-for="sched in schedules" :key="sched.id" class="pa-3 rounded-lg mb-2" style="background: #f8fafc">
              <div class="d-flex align-center justify-space-between">
                <div>
                  <p class="text-body-2 font-weight-medium">{{ sched.vehicle_name }}</p>
                  <p class="text-caption text-medium-emphasis">{{ sched.start_time }} – {{ sched.end_time }} · Target {{ sched.target_soc }}%</p>
                  <div v-if="sched.recurring_days" class="d-flex ga-1 mt-1">
                    <v-chip v-for="day in sched.recurring_days.split(',')" :key="day" size="x-small" variant="tonal" color="primary">{{ weekdayLabel(day.trim()) }}</v-chip>
                  </div>
                </div>
                <div class="d-flex align-center ga-1">
                  <v-chip :color="sched.is_active ? 'success' : 'grey'" size="x-small" variant="tonal">{{ sched.is_active ? 'Active' : 'Off' }}</v-chip>
                  <v-btn v-can="'fuel:update'" icon="mdi-pencil-outline" size="x-small" variant="text" color="warning" @click="editSchedule(sched)" />
                  <v-btn v-can="'fuel:delete'" icon="mdi-delete-outline" size="x-small" variant="text" color="error" @click="removeSchedule(sched)" />
                </div>
              </div>
            </div>
          </div>
          <div v-else class="text-center py-8 text-medium-emphasis">
            <v-icon size="40" class="mb-2">mdi-ev-station</v-icon>
            <p>No charge schedules yet.</p>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <!-- Budget Dialog -->
    <v-dialog v-model="budgetDialogVisible" max-width="440" scroll-strategy="none">
      <v-card rounded="xl" class="overflow-hidden">
        <AppModalHeader icon="mdi-chart-arc">{{ editingBudget ? 'Edit' : 'Add' }} Budget</AppModalHeader>
        <v-card-text class="pt-5">
          <v-row dense>
            <v-col cols="12">
              <v-select v-model="budgetForm.scope" :items="scopeOptions" item-title="label" item-value="value" label="Scope *" @update:model-value="onScopeChange" />
            </v-col>
            <v-col cols="12" v-if="budgetForm.scope === 'vehicle_type'">
              <v-select v-model="budgetForm.target_ref" :items="vehicleTypeOptions" label="Vehicle Type" hide-details="auto" clearable @update:model-value="onTargetChange" />
            </v-col>
            <v-col cols="12" v-if="budgetForm.scope === 'location'">
              <v-select v-model="budgetForm.target_ref" :items="locationOptions" label="Location" hide-details="auto" clearable @update:model-value="onTargetChange" />
            </v-col>
            <v-col cols="12" md="6">
              <v-select v-model="budgetForm.month" :items="monthOptions" item-title="label" item-value="value" label="Month *" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="budgetForm.budget_amount" :label="`Budget Amount (${currencySymbol}) *`" type="number" min="0" step="0.01" hide-details="auto" />
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="budgetDialogVisible = false">Cancel</v-btn>
          <v-btn color="primary" prepend-icon="mdi-check" @click="saveBudget" :loading="savingBudget">Save</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Schedule Dialog -->
    <v-dialog v-model="scheduleDialogVisible" max-width="500" scroll-strategy="none">
      <v-card rounded="xl" class="overflow-hidden">
        <AppModalHeader icon="mdi-ev-station">{{ editingSchedule ? 'Edit' : 'Add' }} Charge Schedule</AppModalHeader>
        <v-card-text class="pt-5">
          <v-row dense>
            <v-col cols="12">
              <v-select v-model="schedForm.vehicle" :items="vehicleOptions" item-title="display_name" item-value="id" label="Vehicle *" />
            </v-col>
            <v-col cols="6" md="6">
              <v-text-field v-model="schedForm.start_time" type="time" label="Start Time *" hide-details="auto" />
            </v-col>
            <v-col cols="6" md="6">
              <v-text-field v-model="schedForm.end_time" type="time" label="End Time *" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model.number="schedForm.target_soc" label="Target SOC %" type="number" min="0" max="100" hide-details="auto" />
            </v-col>
            <v-col cols="12">
              <v-select v-model="schedForm.recurring_days_arr" :items="WEEKDAYS" item-title="label" item-value="value" label="Recurring Days" multiple chips closable-chips hide-details="auto" />
            </v-col>
            <v-col cols="12">
              <v-textarea v-model="schedForm.notes" label="Notes" rows="2" hide-details="auto" />
            </v-col>
            <v-col cols="12">
              <v-switch v-model="schedForm.is_active" label="Active" color="success" density="compact" hide-details="auto" />
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="scheduleDialogVisible = false">Cancel</v-btn>
          <v-btn color="primary" prepend-icon="mdi-check" @click="saveSchedule" :loading="savingSchedule">Save</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
const { $swal } = useNuxtApp()
const { currencySymbol } = useCurrency()
const { fetchBudgets, fetchBudgetSummary, saveBudget: apiSaveBudget, deleteBudget, fetchSchedules, saveSchedule: apiSaveSchedule, deleteSchedule } = useFuelApi()
const { WEEKDAYS, weekdayLabel } = useFuelHelpers()

const props = defineProps<{ vehicleOptions: any[] }>()
const emit = defineEmits<{ refresh: [] }>()

// ---- Budgets ----
const scopeOptions = [
  { label: 'Fleet-wide', value: 'fleet' },
  { label: 'Vehicle Type', value: 'vehicle_type' },
  { label: 'Location', value: 'location' },
]

// Vehicle type options derived from vehicleOptions prop
const vehicleTypeOptions = computed(() => {
  const types = [...new Set(props.vehicleOptions.map((v: any) => v.vehicle_type).filter(Boolean))]
  return types.map((t: string) => ({ title: t, value: t }))
})

// Location options derived from vehicleOptions prop
const locationOptions = computed(() => {
  const locs = [...new Set(props.vehicleOptions.map((v: any) => v.location).filter(Boolean))]
  return locs.map((l: string) => ({ title: l, value: l }))
})

// Month options: remaining months of the current year (from current month through December)
const monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
const monthOptions = computed(() => {
  const now = new Date()
  const year = now.getFullYear()
  const currentMonth = now.getMonth() // 0-indexed
  const options: { label: string; value: string }[] = []
  for (let m = currentMonth; m < 12; m++) {
    const val = `${year}-${String(m + 1).padStart(2, '0')}-01`
    options.push({ label: `${monthNames[m]} ${year}`, value: val })
  }
  return options
})

const budgetDialogVisible = ref(false)
const savingBudget = ref(false)
const editingBudget = ref<any>(null)
const budgetForm = reactive<any>({ scope: 'fleet', target_ref: '', month: monthOptions.value[0]?.value || '', budget_amount: '0' })

function onScopeChange() {
  budgetForm.target_ref = ''
}
function onTargetChange(val: any) {
  // When cleared (null), treat as "all" → empty string
  budgetForm.target_ref = val || ''
}

const { data: budgetSummaryData, refresh: refreshBudgetSummary } = useAsyncData(
  'fuel-budget-summary-tab',
  () => fetchBudgetSummary().catch(() => ({ rows: [] })) as Promise<any>,
  { default: () => ({ rows: [] }) }
)
const budgetRows = computed(() => budgetSummaryData.value?.rows || [])

function openBudgetDialog() {
  editingBudget.value = null
  Object.assign(budgetForm, { scope: 'fleet', target_ref: '', month: monthOptions.value[0]?.value || '', budget_amount: '0' })
  budgetDialogVisible.value = true
}
function editBudget(b: any) {
  editingBudget.value = b
  Object.assign(budgetForm, b)
  budgetDialogVisible.value = true
}

async function saveBudget() {
  if (!budgetForm.budget_amount || Number(budgetForm.budget_amount) <= 0) {
    $swal.fire({ icon: 'error', title: 'Budget amount required', timer: 3000 }); return
  }
  savingBudget.value = true
  try {
    await apiSaveBudget({ ...budgetForm }, editingBudget.value?.id)
    refreshBudgetSummary()
    budgetDialogVisible.value = false
    $swal.fire({ icon: 'success', title: 'Saved', timer: 1500 })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Save failed', text: e?.data?.detail || 'Could not save budget', timer: 3000 })
  } finally { savingBudget.value = false }
}

async function removeBudget(row: any) {
  const r = await $swal.fire({ icon: 'warning', title: 'Delete budget?', showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!r.isConfirmed) return
  try { await deleteBudget(row.id); refreshBudgetSummary() } catch {}
}

// ---- Schedules ----
const scheduleDialogVisible = ref(false)
const savingSchedule = ref(false)
const editingSchedule = ref<any>(null)
const schedForm = reactive<any>({
  vehicle: null, start_time: '22:00', end_time: '06:00', target_soc: 80,
  recurring_days_arr: ['mon', 'tue', 'wed', 'thu', 'fri'], is_active: true, notes: '',
})

const { data: schedData, refresh: refreshSchedules } = useAsyncData(
  'fuel-schedules-tab',
  () => fetchSchedules().catch(() => ({ results: [] })) as Promise<any>,
  { default: () => ({ results: [] }) }
)
const schedules = computed(() => schedData.value?.results || [])

function openScheduleDialog() {
  editingSchedule.value = null
  Object.assign(schedForm, {
    vehicle: null, start_time: '22:00', end_time: '06:00', target_soc: 80,
    recurring_days_arr: ['mon', 'tue', 'wed', 'thu', 'fri'], is_active: true, notes: '',
  })
  scheduleDialogVisible.value = true
}
function editSchedule(s: any) {
  editingSchedule.value = s
  Object.assign(schedForm, {
    vehicle: s.vehicle, start_time: s.start_time, end_time: s.end_time, target_soc: s.target_soc,
    recurring_days_arr: s.recurring_days ? s.recurring_days.split(',').map((d: string) => d.trim()) : [],
    is_active: s.is_active, notes: s.notes || '',
  })
  scheduleDialogVisible.value = true
}

async function saveSchedule() {
  if (!schedForm.vehicle) { $swal.fire({ icon: 'error', title: 'Vehicle required', timer: 3000 }); return }
  savingSchedule.value = true
  try {
    const payload = { ...schedForm, recurring_days: (schedForm.recurring_days_arr || []).join(',') }
    delete payload.recurring_days_arr
    await apiSaveSchedule(payload, editingSchedule.value?.id)
    refreshSchedules()
    scheduleDialogVisible.value = false
    $swal.fire({ icon: 'success', title: 'Saved', timer: 1500 })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Save failed', text: e?.data?.detail || 'Could not save schedule', timer: 3000 })
  } finally { savingSchedule.value = false }
}

async function removeSchedule(s: any) {
  const r = await $swal.fire({ icon: 'warning', title: 'Delete schedule?', showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!r.isConfirmed) return
  try { await deleteSchedule(s.id); refreshSchedules() } catch {}
}
</script>
