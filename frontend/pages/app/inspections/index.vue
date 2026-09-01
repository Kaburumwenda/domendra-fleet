<template>
  <div class="d-flex flex-column ga-4">
    <!-- Page header -->
    <div class="page-header">
      <div>
        <h1 class="text-h5 font-weight-bold d-flex align-center ga-2">
          <v-icon color="primary">mdi-clipboard-check-outline</v-icon>
          Inspections
        </h1>
        <p class="text-caption text-medium-emphasis">Conduct vehicle inspections, track pass/fail results, and manage inspection forms across your fleet.</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn variant="outlined" prepend-icon="mdi-refresh" @click="reloadAll" :loading="pending">Refresh</v-btn>
        <v-btn variant="outlined" prepend-icon="mdi-clipboard-edit-outline" to="/app/inspections/forms">Form Builder</v-btn>
        <v-btn v-can="'inspections:create'" variant="tonal" color="deep-purple" prepend-icon="mdi-database-plus" @click="seedDemo" :loading="seeding">
          <span class="hidden-sm-and-down">Seed Demo Data</span>
        </v-btn>
        <v-btn v-can="'inspections:create'" color="primary" prepend-icon="mdi-clipboard-check" @click="openRunner">
          <span class="hidden-sm-and-down">Run Inspection</span>
        </v-btn>
      </div>
    </div>

    <!-- Analytics -->
    <InspectionsAnalytics
      :stats="stats"
      :reports="reports"
      @filter-status="setStatusFilter"
      @filter-vehicle="setVehicleFilter"
    />

    <!-- Filters bar -->
    <div class="d-flex flex-wrap align-center ga-2 filter-bar">
      <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Search inspections…" density="compact" hide-details variant="outlined" style="max-width:280px" clearable />
      <v-select v-model="statusFilter" :items="statusOptions" item-title="label" item-value="value" placeholder="All Status" density="compact" hide-details variant="outlined" clearable style="max-width:160px" />
      <v-select v-model="vehicleFilter" :items="vehicleOptions" item-title="display_name" item-value="display_name" placeholder="All Vehicles" density="compact" hide-details variant="outlined" clearable style="max-width:220px" />
      <v-select v-model="formFilter" :items="formOptions" item-title="name" item-value="name" placeholder="All Forms" density="compact" hide-details variant="outlined" clearable style="max-width:200px" />
      <v-btn v-if="hasFilters" variant="text" size="small" prepend-icon="mdi-filter-remove" @click="clearFilters">Clear</v-btn>
      <v-spacer />
      <div class="text-caption text-medium-emphasis">{{ filteredReports.length }} of {{ reports.length }} reports</div>
    </div>

    <!-- Tabs -->
    <v-tabs v-model="tab" color="primary" density="compact" class="insp-tabs">
      <v-tab value="board" prepend-icon="mdi-view-column-outline">Board</v-tab>
      <v-tab value="records" prepend-icon="mdi-format-list-bulleted">Records</v-tab>
      <v-tab value="timeline" prepend-icon="mdi-timeline-text-outline">Timeline</v-tab>
    </v-tabs>

    <v-window v-model="tab" class="flex-grow-1">
      <!-- KANBAN BOARD -->
      <v-window-item value="board">
        <InspectionKanbanBoard :reports="filteredReports" @open-detail="openDetail" />
      </v-window-item>

      <!-- RECORDS (data table) -->
      <v-window-item value="records">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="headers" :items="filteredReports" :loading="pending" hover density="compact" :search="search">
            <template #item.id="{ value }">
              <span class="font-weight-medium text-primary">#{{ value }}</span>
            </template>
            <template #item.form_name="{ item }">
              <div class="cursor-pointer" @click="openDetail(item)">
                <p class="font-weight-medium">{{ item.form_name || 'Ad-hoc' }}</p>
                <p class="text-caption text-medium-emphasis">{{ item.vehicle_name }}</p>
              </div>
            </template>
            <template #item.status="{ value }">
              <v-chip :color="resultColor(value)" variant="flat" size="small" class="text-capitalize">
                <v-icon start size="14">{{ statusIcon(value) }}</v-icon>{{ value }}
              </v-chip>
            </template>
            <template #item.driver_name="{ value }">{{ value || '—' }}</template>
            <template #item.responses="{ item }">
              <v-chip v-if="item.responses?.length" size="small" variant="tonal" :color="item.responses.filter((x:any) => x.is_fail).length ? 'error' : 'success'">
                {{ item.responses.filter((x:any) => x.is_fail).length }} / {{ item.responses.length }}
              </v-chip>
              <span v-else class="text-medium-emphasis">—</span>
            </template>
            <template #item.submitted_at="{ value }">{{ value ? new Date(value).toLocaleString([], { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : '—' }}</template>
            <template #item.actions="{ item }">
              <v-menu>
                <template #activator="{ props: p }">
                  <v-btn icon="mdi-dots-vertical" variant="text" size="small" v-bind="p" />
                </template>
                <v-list density="compact">
                  <v-list-item prepend-icon="mdi-eye-outline" @click="openDetail(item)">View Details</v-list-item>
                  <v-list-item v-if="item.status === 'draft'" v-can="'inspections:update'" prepend-icon="mdi-check-decagram" @click="setStatus(item, 'pass')">Mark Passed</v-list-item>
                  <v-list-item v-if="item.status === 'draft'" v-can="'inspections:update'" prepend-icon="mdi-close-circle" @click="setStatus(item, 'fail')">Mark Failed</v-list-item>
                  <v-list-item v-can="'inspections:create'" prepend-icon="mdi-clipboard-check" @click="reopenRunner(item)">Re-run</v-list-item>
                  <v-list-item v-can="'inspections:delete'" prepend-icon="mdi-trash-can-outline" base-color="error" @click="deleteReport(item)">Delete</v-list-item>
                </v-list>
              </v-menu>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-clipboard-check-outline</v-icon>
                <p>No inspection reports yet. Click <b>Seed Demo Data</b> or <b>Run Inspection</b> to get started.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>

      <!-- TIMELINE -->
      <v-window-item value="timeline">
        <v-card elevation="0" border rounded="lg">
          <v-card-text>
            <div v-if="!filteredReports.length" class="text-center py-12 text-medium-emphasis">
              <v-icon size="48" class="mb-3">mdi-timeline-text-outline</v-icon>
              <p>No inspection reports to show.</p>
            </div>
            <v-timeline v-else side="end" density="compact">
              <v-timeline-item v-for="r in timelineReports" :key="r.id" :dot-color="resultColor(r.status)" size="small" fill-dot>
                <template #opposite>
                  <span class="text-caption text-medium-emphasis">{{ fmt(r.submitted_at) }}</span>
                </template>
                <v-card elevation="0" border class="pa-3 cursor-pointer" @click="openDetail(r)">
                  <div class="d-flex align-start justify-space-between">
                    <div class="flex-grow-1">
                      <div class="d-flex align-center ga-2 mb-1">
                        <p class="font-weight-medium">{{ r.form_name || 'Ad-hoc Inspection' }}</p>
                        <v-chip :color="resultColor(r.status)" variant="flat" size="x-small" class="text-capitalize">{{ r.status }}</v-chip>
                      </div>
                      <p class="text-caption text-medium-emphasis">{{ r.vehicle_name }} · {{ r.driver_name || 'Unassigned' }} · {{ r.odometer_reading ? r.odometer_reading.toLocaleString() + ' mi' : '' }}</p>
                      <div class="d-flex align-center ga-2 mt-1 flex-wrap">
                        <v-chip v-if="r.responses?.some((x:any) => x.is_fail && x.is_critical)" color="error" variant="outlined" size="x-small"><v-icon start size="12">mdi-alert-octagon</v-icon>Critical</v-chip>
                        <v-chip :color="r.responses?.some((x:any) => x.is_fail) ? 'warning' : 'success'" variant="outlined" size="x-small">{{ r.responses?.filter((x:any) => x.is_fail).length || 0 }} / {{ r.responses?.length || 0 }} items</v-chip>
                        <span v-if="r.notes" class="text-caption text-medium-emphasis"><v-icon size="12">mdi-note</v-icon> Notes</span>
                      </div>
                    </div>
                  </div>
                </v-card>
              </v-timeline-item>
            </v-timeline>
          </v-card-text>
        </v-card>
      </v-window-item>
    </v-window>

    <!-- Inspection Runner (fullscreen stepper dialog) -->
    <v-dialog v-model="runnerVisible" max-width="720" fullscreen>
      <v-card rounded="0">
        <AppModalHeader icon="mdi-clipboard-check-outline">Inspection Runner</AppModalHeader>
        <v-card-text class="pa-0">
          <v-stepper v-model="step" flat>
            <v-stepper-header>
              <v-stepper-item value="1" title="Setup" />
              <v-divider />
              <v-stepper-item value="2" title="Inspection" :complete="!!runnerForm.form" />
              <v-divider />
              <v-stepper-item value="3" title="Review" />
            </v-stepper-header>
            <v-stepper-window>
              <!-- Step 1: setup -->
              <v-stepper-window-item value="1">
                <div class="pa-6 d-flex flex-column ga-4" style="max-width: 560px; margin: 0 auto">
                  <v-select v-model="runnerForm.vehicle" :items="vehicleOptions" item-title="display_name" item-value="id" label="Vehicle *" hide-details="auto" variant="outlined" />
                  <v-select v-model="runnerForm.form" :items="formOptions" item-title="name" item-value="id" label="Inspection Form *" hide-details="auto" variant="outlined" @update:model-value="loadFormItems" />
                  <v-text-field v-model.number="runnerForm.odometer_reading" label="Odometer Reading" type="number" variant="outlined" hide-details="auto" suffix="mi" />
                  <v-textarea v-model="runnerForm.notes" label="Notes" rows="2" variant="outlined" hide-details="auto" />
                  <v-btn color="primary" :disabled="!runnerForm.vehicle || !runnerForm.form" @click="step = '2'">Next →</v-btn>
                </div>
              </v-stepper-window-item>

              <!-- Step 2: items -->
              <v-stepper-window-item value="2">
                <div class="pa-4" style="max-width: 680px; margin: 0 auto">
                  <div v-if="!formItems.length" class="text-center py-8 text-medium-emphasis">This form has no items.</div>
                  <v-card v-for="item in formItems" :key="item.id" elevation="0" border class="mb-3 pa-4">
                    <div class="d-flex align-center justify-space-between mb-2">
                      <p class="font-weight-medium">{{ item.label }}<v-chip v-if="item.is_critical" size="x-small" color="error" class="ms-2">Critical</v-chip></p>
                      <span class="text-caption text-medium-emphasis">{{ item.item_type }}</span>
                    </div>
                    <p v-if="item.help_text" class="text-caption text-medium-emphasis mb-2">{{ item.help_text }}</p>

                    <template v-if="item.item_type === 'pass_fail'">
                      <v-btn-toggle v-model="responses[item.id].value" mandatory color="primary" divided>
                        <v-btn value="pass" color="success" variant="outlined">Pass</v-btn>
                        <v-btn value="fail" color="error" variant="outlined">Fail</v-btn>
                      </v-btn-toggle>
                    </template>
                    <template v-else-if="item.item_type === 'text'">
                      <v-text-field v-model="responses[item.id].value" density="compact" variant="outlined" hide-details />
                    </template>
                    <template v-else-if="item.item_type === 'number'">
                      <v-text-field v-model.number="responses[item.id].value" type="number" density="compact" variant="outlined" hide-details style="max-width: 200px" />
                    </template>
                    <template v-else-if="item.item_type === 'checklist'">
                      <v-switch v-model="responses[item.id].value" true-value="checked" false-value="unchecked" color="success" label="Checked" density="compact" hide-details />
                    </template>
                    <template v-else-if="item.item_type === 'photo'">
                      <v-file-input density="compact" variant="outlined" hide-details accept="image/*" label="Capture photo" />
                    </template>
                    <template v-else-if="item.item_type === 'signature'">
                      <p class="text-caption text-medium-emphasis">Signature capture (touch/mouse)</p>
                    </template>
                    <v-textarea v-model="responses[item.id].notes" label="Notes" rows="1" density="compact" variant="outlined" hide-details class="mt-2" />
                  </v-card>
                  <div class="d-flex justify-space-between mt-2">
                    <v-btn variant="text" @click="step = '1'">← Back</v-btn>
                    <v-btn color="primary" @click="step = '3'">Review →</v-btn>
                  </div>
                </div>
              </v-stepper-window-item>

              <!-- Step 3: review -->
              <v-stepper-window-item value="3">
                <div class="pa-6" style="max-width: 680px; margin: 0 auto">
                  <p class="text-body-1 mb-3">Computed result: <v-chip :color="resultColor(computedStatus)" size="small">{{ computedStatus }}</v-chip></p>
                  <p class="text-body-2 text-medium-emphasis mb-1">{{ failCount }} failing item(s), {{ criticalFailCount }} critical.</p>
                  <v-textarea v-model="runnerForm.notes" label="Final Notes" rows="2" variant="outlined" hide-details="auto" class="mb-4" />
                  <div class="d-flex justify-space-between">
                    <v-btn variant="text" @click="step = '2'">← Back</v-btn>
                    <v-btn color="primary" prepend-icon="mdi-check" @click="submit" :loading="saving">Submit Inspection</v-btn>
                  </div>
                </div>
              </v-stepper-window-item>
            </v-stepper-window>
          </v-stepper>
        </v-card-text>
      </v-card>
    </v-dialog>

    <!-- Detail drawer -->
    <InspectionDetailDrawer
      v-model="drawerOpen"
      :report="selectedReport"
      @edit="reopenRunner"
      @delete="deleteReport"
      @set-status="onSetStatus"
    />
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })
const { $api, $swal } = useNuxtApp() as any

const tab = ref<'board' | 'records' | 'timeline'>('board')
const search = ref('')
const statusFilter = ref<string | null>(null)
const vehicleFilter = ref<string | null>(null)
const formFilter = ref<string | null>(null)

const statusOptions = [
  { label: 'Passed', value: 'pass' },
  { label: 'Failed', value: 'fail' },
  { label: 'Conditional', value: 'conditional' },
  { label: 'Draft', value: 'draft' },
]

const headers = [
  { title: '#', key: 'id', width: '60px' },
  { title: 'Form / Vehicle', key: 'form_name', sortable: true },
  { title: 'Result', key: 'status', sortable: true, width: '120px' },
  { title: 'Driver', key: 'driver_name', width: '130px' },
  { title: 'Items', key: 'responses', width: '100px' },
  { title: 'Submitted', key: 'submitted_at', sortable: true, width: '140px' },
  { title: '', key: 'actions', width: '50px', sortable: false },
]

// --- Runner state ---
const step = ref('1')
const runnerVisible = ref(false)
const saving = ref(false)
const formItems = ref<any[]>([])
const responses = reactive<Record<number, any>>({})
const runnerForm = reactive<any>({ vehicle: null, form: null, odometer_reading: null, notes: '' })

// --- Drawer ---
const drawerOpen = ref(false)
const selectedReport = ref<any>(null)

// --- Lookup data ---
const { data: vehicleData } = useAsyncData('insp-vehicles', () => $api('/vehicles/vehicles/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const vehicleOptions = computed(() => vehicleData.value?.results || [])
const { data: formData } = useAsyncData('insp-forms', () => $api('/inspections/forms/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const formOptions = computed(() => formData.value?.results || [])

// --- Stats ---
const { data: statsData, refresh: refreshStats } = useAsyncData('insp-stats', () => $api('/inspections/reports/stats/').catch(() => ({})), { default: () => ({}) })
const stats = computed(() => statsData.value || {})

// --- Main data ---
const { data: reportsData, pending, refresh } = useAsyncData('inspections-page', () => $api('/inspections/reports/', { query: { page_size: 1000 } }), { default: () => ({ results: [], count: 0 }) })
const reports = computed(() => reportsData.value?.results || reportsData.value || [])

const filteredReports = computed(() => {
  let arr = reports.value
  if (statusFilter.value) arr = arr.filter(r => r.status === statusFilter.value)
  if (vehicleFilter.value) arr = arr.filter(r => r.vehicle_name === vehicleFilter.value)
  if (formFilter.value) arr = arr.filter(r => (r.form_name || 'Ad-hoc') === formFilter.value)
  if (search.value) {
    const q = search.value.toLowerCase()
    arr = arr.filter(r => (r.form_name || '').toLowerCase().includes(q) || (r.vehicle_name || '').toLowerCase().includes(q) || (r.driver_name || '').toLowerCase().includes(q))
  }
  return arr
})
const hasFilters = computed(() => !!(search.value || statusFilter.value || vehicleFilter.value || formFilter.value))
const timelineReports = computed(() => [...filteredReports.value].sort((a, b) => new Date(b.submitted_at).valueOf() - new Date(a.submitted_at).valueOf()))

// --- Runner functions ---
function openRunner() { Object.assign(runnerForm, { vehicle: null, form: null, odometer_reading: null, notes: '' }); formItems.value = []; step.value = '1'; runnerVisible.value = true }

function reopenRunner(r: any) {
  drawerOpen.value = false
  Object.assign(runnerForm, { vehicle: r.vehicle_id || r.vehicle, form: r.form, odometer_reading: r.odometer_reading, notes: r.notes || '' })
  if (r.form) loadFormItems(r.form)
  step.value = '1'
  runnerVisible.value = true
}

async function loadFormItems(formId: number) {
  const form = formOptions.value.find(f => f.id === formId)
  formItems.value = form?.items || []
  Object.keys(responses).forEach(k => delete responses[+k])
  for (const item of formItems.value) {
    responses[item.id] = { value: item.item_type === 'pass_fail' ? 'pass' : item.item_type === 'checklist' ? 'unchecked' : '', notes: '' }
  }
}

const failCount = computed(() => formItems.value.filter(i => responses[i.id]?.value === 'fail').length)
const criticalFailCount = computed(() => formItems.value.filter(i => i.is_critical && responses[i.id]?.value === 'fail').length)
const computedStatus = computed(() => { if (criticalFailCount.value > 0) return 'fail'; if (failCount.value > 0) return 'conditional'; return 'pass' })

async function submit() {
  saving.value = true
  try {
    const payload = {
      vehicle: runnerForm.vehicle, form: runnerForm.form, status: computedStatus.value,
      odometer_reading: runnerForm.odometer_reading, notes: runnerForm.notes,
      responses: formItems.value.map(item => ({
        item: item.id,
        value: responses[item.id]?.value || '',
        notes: responses[item.id]?.notes || '',
        is_fail: item.item_type === 'pass_fail' && responses[item.id]?.value === 'fail',
      })),
    }
    await $api('/inspections/reports/', { method: 'POST', body: payload })
    runnerVisible.value = false
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: 'Inspection submitted', toast: true, timer: 1500, position: 'top-end' })
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Submission failed', toast: true, timer: 2000, position: 'top-end' }) } finally { saving.value = false }
}

// --- Detail drawer ---
function openDetail(r: any) { selectedReport.value = r; drawerOpen.value = true }

async function setStatus(r: any, status: string) {
  try {
    await $api(`/inspections/reports/${r.id}/`, { method: 'PATCH', body: { status } })
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: `Marked as ${status}`, toast: true, timer: 1500, position: 'top-end' })
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Update failed', toast: true, timer: 2000, position: 'top-end' }) }
}

function onSetStatus(payload: { report: any; status: string }) { setStatus(payload.report, payload.status) }

async function deleteReport(r: any) {
  const res = await $swal?.fire?.({ icon: 'warning', title: 'Delete inspection report?', text: `"${r.form_name || 'Report'} #${r.id}" for ${r.vehicle_name} will be permanently removed.`, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!res?.isConfirmed) return
  try {
    await $api(`/inspections/reports/${r.id}/`, { method: 'DELETE' })
    drawerOpen.value = false
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: 'Report deleted', toast: true, timer: 1500, position: 'top-end' })
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Delete failed', toast: true, timer: 2000, position: 'top-end' }) }
}

// --- Filter helpers ---
function setStatusFilter(s: string) { statusFilter.value = statusFilter.value === s ? null : s; tab.value = 'records' }
function setVehicleFilter(v: string) { vehicleFilter.value = vehicleFilter.value === v ? null : v; tab.value = 'records' }
function clearFilters() { search.value = ''; statusFilter.value = null; vehicleFilter.value = null; formFilter.value = null }

// --- Utils ---
function resultColor(s: string) { return ({ pass: 'success', fail: 'error', conditional: 'warning', draft: 'grey' } as any)[s] || 'grey' }
function statusIcon(s: string) { return ({ pass: 'mdi-check-decagram', fail: 'mdi-close-circle', conditional: 'mdi-alert-circle', draft: 'mdi-pencil-outline' } as any)[s] || 'mdi-clipboard' }
function fmt(v?: string) { return v ? new Date(v).toLocaleDateString([], { month: 'short', day: 'numeric' }) : '—' }

// --- Bulk reload ---
async function reloadAll() { await Promise.all([refresh(), refreshStats()]) }

// --- Seed demo data ---
const seeding = ref(false)
async function seedDemo() {
  const r = await $swal?.fire?.({
    icon: 'question',
    title: 'Seed demo data?',
    text: 'This will create sample inspection forms, items, and reports for each vehicle in your fleet.',
    showCancelButton: true,
    confirmButtonText: 'Seed Data',
  })
  if (!r?.isConfirmed) return
  seeding.value = true
  try {
    const res = await $api('/inspections/reports/seed-demo/', { method: 'POST' })
    await Promise.all([refresh(), refreshStats(), formData.value && (formData.value = await $api('/inspections/forms/', { query: { page_size: 1000 } }))])
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: res?.detail || 'Demo data seeded', toast: true, timer: 2000, position: 'top-end' })
  } catch (e: any) {
    console.error(e)
    $swal?.fire?.({ icon: 'error', title: e?.response?._data?.detail || 'Failed to seed data', toast: true, timer: 3000, position: 'top-end' })
  } finally { seeding.value = false }
}
</script>

<style scoped>
.page-header { display:flex; align-items:flex-start; justify-content:space-between; gap:12px; flex-wrap:wrap; }
.filter-bar { flex-wrap:wrap; }
.insp-tabs :deep(.v-tab) { text-transform: none; font-weight: 600; }
.cursor-pointer { cursor: pointer; }
</style>
