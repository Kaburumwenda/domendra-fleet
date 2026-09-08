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
    <v-dialog v-model="runnerVisible" max-width="860" fullscreen>
      <v-card rounded="0" class="runner-card">
        <AppModalHeader icon="mdi-clipboard-check-outline">Inspection Runner</AppModalHeader>
        <v-card-text class="pa-0">
          <v-stepper v-model="step" flat>
            <v-stepper-header class="runner-header">
              <v-stepper-item value="1" title="Setup" />
              <v-divider />
              <v-stepper-item value="2" title="Inspection" :complete="!!runnerForm.form" />
              <v-divider />
              <v-stepper-item value="3" title="Review" />
            </v-stepper-header>
            <v-stepper-window>
              <!-- Step 1: setup -->
              <v-stepper-window-item value="1">
                <div class="runner-body">
                  <div class="runner-step-intro">
                    <v-icon size="32" color="primary" class="mb-1">mdi-truck-check-outline</v-icon>
                    <h3 class="text-h6 font-weight-bold mb-1">Start a New Inspection</h3>
                    <p class="text-body-2 text-medium-emphasis">Select a vehicle and inspection form to begin.</p>
                  </div>
                  <div class="runner-form-grid">
                    <v-select v-model="runnerForm.vehicle" :items="vehicleOptions" item-title="display_name" item-value="id" label="Vehicle *" hide-details="auto" variant="outlined" prepend-inner-icon="mdi-truck">
                      <template #selection="{ item }">
                        <span class="font-weight-medium">{{ item.raw.display_name }}</span>
                        <span v-if="item.raw.license_plate" class="text-caption text-medium-emphasis ml-2">· {{ item.raw.license_plate }}</span>
                      </template>
                      <template #item="{ item, props }">
                        <v-list-item v-bind="props" :title="item.raw.display_name" :subtitle="item.raw.license_plate || 'No plate'" />
                      </template>
                    </v-select>
                    <v-select v-model="runnerForm.form" :items="formOptions" item-title="name" item-value="id" label="Inspection Form *" hide-details="auto" variant="outlined" prepend-inner-icon="mdi-form-select" @update:model-value="loadFormItems" />
                    <v-text-field v-model.number="runnerForm.odometer_reading" label="Odometer Reading" type="number" variant="outlined" hide-details="auto" prepend-inner-icon="mdi-counter" suffix="mi" />
                    <v-autocomplete v-model="runnerForm.driver" :items="driverOptions" item-title="full_name" item-value="id" label="Driver" hide-details="auto" variant="outlined" prepend-inner-icon="mdi-account" clearable />
                  </div>
                  <v-textarea v-model="runnerForm.notes" label="Notes" rows="2" variant="outlined" hide-details="auto" prepend-inner-icon="mdi-note-text" class="mt-1" />
                  <div class="runner-actions mt-4">
                    <v-spacer />
                    <v-btn color="primary" size="large" :disabled="!runnerForm.vehicle || !runnerForm.form" @click="step = '2'">Start Inspection <v-icon end>mdi-arrow-right</v-icon></v-btn>
                  </div>
                </div>
              </v-stepper-window-item>

              <!-- Step 2: items -->
              <v-stepper-window-item value="2">
                <div class="runner-body">
                  <!-- Progress summary bar -->
                  <div class="runner-progress-bar">
                    <div class="d-flex align-center ga-3">
                      <v-chip :color="runnerProgress.completes ? 'success' : 'grey'" variant="tonal" size="small">
                        <v-icon start size="14">mdi-check-circle</v-icon>{{ runnerProgress.completes }}/{{ formItems.length }} Done
                      </v-chip>
                      <v-chip v-if="failCount > 0" color="error" variant="tonal" size="small">
                        <v-icon start size="14">mdi-alert-circle</v-icon>{{ failCount }} Failing
                      </v-chip>
                      <v-chip v-if="criticalFailCount > 0" color="error" variant="flat" size="small">
                        <v-icon start size="14">mdi-alert-octagon</v-icon>{{ criticalFailCount }} Critical
                      </v-chip>
                    </div>
                    <v-progress-linear :model-value="runnerProgress.pct" color="primary" height="6" rounded class="mt-2" />
                  </div>

                  <!-- Inspection items -->
                  <div v-if="!formItems.length" class="text-center py-12 text-medium-emphasis">
                    <v-icon size="48" class="mb-2">mdi-clipboard-outline</v-icon>
                    <p>This form has no items.</p>
                  </div>
                  <v-card
                    v-for="item in formItems"
                    :key="item.id"
                    elevation="0"
                    border
                    class="runner-item-card mb-3"
                    :class="{ 'runner-item--fail': responses[item.id]?.value === 'fail', 'runner-item--pass': responses[item.id]?.value === 'pass' }"
                  >
                    <div class="runner-item-header">
                      <div class="d-flex align-center ga-2 flex-grow-1">
                        <div class="runner-item-icon" :class="runnerItemIconClass(item)">
                          <v-icon size="18">{{ runnerItemIcon(item) }}</v-icon>
                        </div>
                        <div>
                          <p class="font-weight-medium text-body-1">{{ item.label }}</p>
                          <p v-if="item.help_text" class="text-caption text-medium-emphasis">{{ item.help_text }}</p>
                        </div>
                      </div>
                      <v-chip v-if="item.is_critical" size="x-small" color="error" variant="flat" prepend-icon="mdi-alert-octagon">Critical</v-chip>
                      <v-chip size="x-small" variant="outlined" class="text-uppercase text-medium-emphasis">{{ item.item_type?.replace('_', ' ') }}</v-chip>
                    </div>

                    <div class="runner-item-body">
                      <template v-if="item.item_type === 'pass_fail'">
                        <v-btn-toggle v-model="responses[item.id].value" mandatory color="primary" divided>
                          <v-btn value="pass" color="success" variant="outlined" prepend-icon="mdi-check"><span>Pass</span></v-btn>
                          <v-btn value="fail" color="error" variant="outlined" prepend-icon="mdi-close"><span>Fail</span></v-btn>
                        </v-btn-toggle>
                      </template>
                      <template v-else-if="item.item_type === 'text'">
                        <v-text-field v-model="responses[item.id].value" density="compact" variant="outlined" hide-details placeholder="Enter value…" />
                      </template>
                      <template v-else-if="item.item_type === 'number'">
                        <v-text-field v-model.number="responses[item.id].value" type="number" density="compact" variant="outlined" hide-details style="max-width: 200px" />
                      </template>
                      <template v-else-if="item.item_type === 'checklist'">
                        <v-switch v-model="responses[item.id].value" true-value="checked" false-value="unchecked" color="success" label="Checked" density="compact" hide-details />
                      </template>
                      <template v-else-if="item.item_type === 'photo'">
                        <v-file-input density="compact" variant="outlined" hide-details accept="image/*" label="Capture photo" prepend-icon="mdi-camera" />
                      </template>
                      <template v-else-if="item.item_type === 'signature'">
                        <div class="runner-sig-placeholder"><v-icon color="grey-lighten-1">mdi-draw</v-icon><span class="text-caption text-medium-emphasis">Signature capture (touch/mouse)</span></div>
                      </template>
                    </div>

                    <v-textarea v-model="responses[item.id].notes" label="Item notes" rows="1" density="compact" variant="outlined" hide-details class="mt-2" prepend-inner-icon="mdi-note-edit-outline" />
                  </v-card>

                  <div class="runner-actions mt-4">
                    <v-btn variant="text" size="large" @click="step = '1'"><v-icon start>mdi-arrow-left</v-icon> Back</v-btn>
                    <v-spacer />
                    <v-btn color="primary" size="large" @click="step = '3'">Review <v-icon end>mdi-arrow-right</v-icon></v-btn>
                  </div>
                </div>
              </v-stepper-window-item>

              <!-- Step 3: review -->
              <v-stepper-window-item value="3">
                <div class="runner-body">
                  <!-- Result hero card -->
                  <div class="runner-result-hero" :class="'hero--' + computedStatus">
                    <div class="hero-icon-wrapper">
                      <v-icon size="40">{{ computedStatus === 'pass' ? 'mdi-check-circle' : computedStatus === 'fail' ? 'mdi-close-circle' : 'mdi-alert-circle' }}</v-icon>
                    </div>
                    <div class="flex-grow-1">
                      <p class="text-overline text-medium-emphasis mb-0">Computed Result</p>
                      <h2 class="text-h5 font-weight-bold text-capitalize">{{ computedStatus }}</h2>
                      <p class="text-body-2 text-medium-emphasis mt-1">{{ runnerReviewSummary }}</p>
                    </div>
                    <v-chip :color="resultColor(computedStatus)" variant="flat" size="large" class="ml-auto font-weight-bold text-uppercase">{{ computedStatus }}</v-chip>
                  </div>

                  <!-- Item summary grid -->
                  <div class="runner-review-stats">
                    <div class="runner-stat-tile pass">
                      <v-icon color="success">mdi-check-circle</v-icon>
                      <p class="stat-value">{{ runnerProgress.passes }}</p>
                      <p class="stat-label">Passed</p>
                    </div>
                    <div class="runner-stat-tile fail">
                      <v-icon color="error">mdi-alert-circle</v-icon>
                      <p class="stat-value">{{ failCount }}</p>
                      <p class="stat-label">Failed</p>
                    </div>
                    <div class="runner-stat-tile total">
                      <v-icon color="primary">mdi-format-list-checks</v-icon>
                      <p class="stat-value">{{ formItems.length }}</p>
                      <p class="stat-label">Total Items</p>
                    </div>
                    <div v-if="criticalFailCount > 0" class="runner-stat-tile critical">
                      <v-icon color="error">mdi-alert-octagon</v-icon>
                      <p class="stat-value">{{ criticalFailCount }}</p>
                      <p class="stat-label">Critical</p>
                    </div>
                  </div>

                  <!-- Failed items list -->
                  <div v-if="runnerFailedItems.length" class="runner-failed-list">
                    <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" color="error" class="mr-1">mdi-alert-circle-outline</v-icon>Failed Items</p>
                    <v-list density="compact" class="pa-0" border rounded="lg">
                      <v-list-item v-for="fi in runnerFailedItems" :key="fi.id" class="runner-failed-item">
                        <template #prepend>
                          <v-icon color="error" size="20">mdi-close</v-icon>
                        </template>
                        <v-list-item-title class="text-body-2"><span class="font-weight-medium">{{ fi.label }}</span> <v-chip v-if="fi.is_critical" size="x-small" color="error" variant="flat">Critical</v-chip></v-list-item-title>
                        <v-list-item-subtitle v-if="responses[fi.id]?.notes" class="text-caption">{{ responses[fi.id]?.notes }}</v-list-item-subtitle>
                      </v-list-item>
                    </v-list>
                  </div>

                  <!-- Inspection meta -->
                  <div class="runner-review-meta">
                    <div class="meta-row"><v-icon size="18">mdi-truck</v-icon><span class="meta-label">Vehicle</span><span class="meta-value">{{ selectedVehicleName }}</span></div>
                    <div class="meta-row"><v-icon size="18">mdi-form-select</v-icon><span class="meta-label">Form</span><span class="meta-value">{{ selectedFormName }}</span></div>
                    <div v-if="runnerForm.odometer_reading" class="meta-row"><v-icon size="18">mdi-counter</v-icon><span class="meta-label">Odometer</span><span class="meta-value">{{ runnerForm.odometer_reading.toLocaleString() }} mi</span></div>
                  </div>

                  <!-- Final notes -->
                  <v-textarea v-model="runnerForm.notes" label="Final Notes" rows="3" variant="outlined" hide-details="auto" prepend-inner-icon="mdi-note-text" class="mt-4" />

                  <div class="runner-actions mt-4">
                    <v-btn variant="text" size="large" @click="step = '2'"><v-icon start>mdi-arrow-left</v-icon> Back</v-btn>
                    <v-spacer />
                    <v-btn color="primary" size="large" prepend-icon="mdi-check-circle" @click="submit" :loading="saving">Submit Inspection</v-btn>
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
const runnerForm = reactive<any>({ vehicle: null, form: null, odometer_reading: null, driver: null, notes: '' })

// --- Drawer ---
const drawerOpen = ref(false)
const selectedReport = ref<any>(null)

// --- Lookup data ---
const { data: vehicleData } = useAsyncData('insp-vehicles', () => $api('/vehicles/vehicles/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const vehicleOptions = computed(() => vehicleData.value?.results || [])
const { data: formData } = useAsyncData('insp-forms', () => $api('/inspections/forms/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const formOptions = computed(() => formData.value?.results || [])
const { data: driverData } = useAsyncData('insp-drivers', () => $api('/drivers/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const driverOptions = computed(() => (driverData.value?.results || []).map((d: any) => ({ id: d.id, full_name: `${d.first_name || ''} ${d.last_name || ''}`.trim() || d.email || `Driver #${d.id}` })))

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
function openRunner() { Object.assign(runnerForm, { vehicle: null, form: null, odometer_reading: null, driver: null, notes: '' }); formItems.value = []; step.value = '1'; runnerVisible.value = true }

function reopenRunner(r: any) {
  drawerOpen.value = false
  Object.assign(runnerForm, { vehicle: r.vehicle_id || r.vehicle, form: r.form, odometer_reading: r.odometer_reading, driver: r.driver_id || r.driver || null, notes: r.notes || '' })
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

// --- Runner UI computeds ---
const runnerProgress = computed(() => {
  const total = formItems.value.length || 1
  const passFailItems = formItems.value.filter(i => i.item_type === 'pass_fail')
  const passes = passFailItems.filter(i => responses[i.id]?.value === 'pass').length
  const fails = passFailItems.filter(i => responses[i.id]?.value === 'fail').length
  const completes = formItems.value.filter(i => {
    const v = responses[i.id]?.value
    if (i.item_type === 'pass_fail') return v === 'pass' || v === 'fail'
    if (i.item_type === 'checklist') return v === 'checked' || v === 'unchecked'
    return v != null && v !== ''
  }).length
  return { passes, fails, completes, pct: Math.round((completes / total) * 100) }
})
const runnerFailedItems = computed(() => formItems.value.filter(i => responses[i.id]?.value === 'fail'))
const runnerReviewSummary = computed(() => {
  if (computedStatus.value === 'pass') return 'All items passed inspection successfully.'
  if (computedStatus.value === 'fail') return 'One or more critical items failed — this inspection must be flagged.'
  return 'Some non-critical items failed — review before submitting.'
})
const selectedVehicleName = computed(() => runnerForm.vehicle ? (vehicleOptions.value.find((v: any) => v.id === runnerForm.vehicle)?.display_name || '—') : '—')
const selectedFormName = computed(() => runnerForm.form ? (formOptions.value.find((f: any) => f.id === runnerForm.form)?.name || '—') : '—')

function runnerItemIcon(item: any) {
  const map: Record<string, string> = { pass_fail: 'mdi-checkbox-marked-circle-outline', text: 'mdi-form-textbox', number: 'mdi-numeric', checklist: 'mdi-checkbox-outline', photo: 'mdi-camera-outline', signature: 'mdi-draw-pen' }
  return map[item.item_type] || 'mdi-circle-outline'
}
function runnerItemIconClass(item: any) {
  const v = responses[item.id]?.value
  if (item.item_type === 'pass_fail' && v === 'pass') return 'icon-pass'
  if (item.item_type === 'pass_fail' && v === 'fail') return 'icon-fail'
  return 'icon-default'
}

async function submit() {
  saving.value = true
  try {
    const payload = {
      vehicle: runnerForm.vehicle, form: runnerForm.form, status: computedStatus.value,
      driver: runnerForm.driver || null,
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

/* ---------------- Inspection Runner ---------------- */
.runner-card { background: rgb(249, 250, 251); }
.runner-header { background: #fff !important; border-bottom: 1px solid rgb(226, 232, 240); box-shadow: none; }
.runner-header :deep(.v-stepper-item) { font-weight: 600; }

.runner-body {
  max-width: 760px;
  margin: 0 auto;
  padding: 32px 24px 48px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.runner-step-intro { text-align: center; padding: 8px 0 4px; }

.runner-form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}
.runner-form-grid > .v-input:first-child { grid-column: 1 / -1; }
@media (max-width: 600px) { .runner-form-grid { grid-template-columns: 1fr; } }

.runner-actions { display: flex; align-items: center; gap: 8px; padding-top: 8px; }

/* Progress bar (step 2) */
.runner-progress-bar {
  background: #fff;
  border-radius: 12px;
  border: 1px solid rgb(226, 232, 240);
  padding: 14px 16px;
}

/* Inspection item cards (step 2) */
.runner-item-card {
  border-radius: 14px !important;
  transition: border-color .15s, box-shadow .15s;
  padding: 0;
  overflow: hidden;
}
.runner-item-card .runner-item-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  padding: 16px 20px 0;
}
.runner-item-card .runner-item-body { padding: 12px 20px 4px; }
.runner-item-card :deep(.v-textarea) { margin-bottom: 4px; }
.runner-item-card :deep(.v-card__text) { padding: 0; }
.runner-item-card :deep(.v-card__underlay) { display: none; }

.runner-item--fail { border-color: rgb(239, 68, 68, .35) !important; box-shadow: 0 0 0 1px rgb(239, 68, 68, .12) inset; }
.runner-item--pass { border-color: rgb(34, 197, 94, .35) !important; box-shadow: 0 0 0 1px rgb(34, 197, 94, .12) inset; }

.runner-item-icon {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  background: rgb(241, 245, 249);
  color: rgb(100, 116, 139);
}
.runner-item-icon.icon-pass { background: rgb(220, 252, 231); color: rgb(22, 163, 74); }
.runner-item-icon.icon-fail { background: rgb(254, 226, 226); color: rgb(220, 38, 38); }

.runner-sig-placeholder {
  display: flex; flex-direction: column; align-items: center; gap: 4px;
  padding: 24px; border: 2px dashed rgb(203, 213, 225); border-radius: 12px;
  background: rgb(248, 250, 252);
}

/* Result hero card (step 3) */
.runner-result-hero {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 24px;
  border-radius: 16px;
  background: #fff;
  border: 1px solid rgb(226, 232, 240);
  position: relative;
  overflow: hidden;
}
.runner-result-hero::before {
  content: ''; position: absolute; left: 0; top: 0; bottom: 0; width: 6px;
}
.runner-result-hero.hero--pass::before { background: rgb(34, 197, 94); }
.runner-result-hero.hero--fail::before { background: rgb(239, 68, 68); }
.runner-result-hero.hero--conditional::before { background: rgb(249, 115, 22); }
.runner-result-hero.hero--pass .hero-icon-wrapper { background: rgb(220, 252, 231); color: rgb(22, 163, 74); }
.runner-result-hero.hero--fail .hero-icon-wrapper { background: rgb(254, 226, 226); color: rgb(220, 38, 38); }
.runner-result-hero.hero--conditional .hero-icon-wrapper { background: rgb(255, 237, 213); color: rgb(234, 88, 12); }
.hero-icon-wrapper { width: 56px; height: 56px; border-radius: 14px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }

/* Stat tiles (step 3) */
.runner-review-stats {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
  gap: 12px;
}
.runner-stat-tile {
  background: #fff;
  border: 1px solid rgb(226, 232, 240);
  border-radius: 12px;
  padding: 16px;
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}
.runner-stat-tile .stat-value { font-size: 24px; font-weight: 800; color: rgb(15, 23, 42); }
.runner-stat-tile .stat-label { font-size: 11px; text-transform: uppercase; letter-spacing: .05em; color: rgb(100, 116, 139); font-weight: 600; }
.runner-stat-tile.pass { border-top: 3px solid rgb(34, 197, 94); }
.runner-stat-tile.fail { border-top: 3px solid rgb(239, 68, 68); }
.runner-stat-tile.total { border-top: 3px solid rgb(99, 102, 241); }
.runner-stat-tile.critical { border-top: 3px solid rgb(220, 38, 38); background: rgb(254, 242, 242); }

/* Failed items list (step 3) */
.runner-failed-list { margin-top: 4px; }

.runner-failed-item :deep(.v-list-item__content) { padding: 8px 0; }

/* Meta rows (step 3) */
.runner-review-meta {
  background: #fff;
  border: 1px solid rgb(226, 232, 240);
  border-radius: 12px;
  padding: 8px 16px;
}
.meta-row {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 0;
  border-bottom: 1px solid rgb(241, 245, 249);
}
.meta-row:last-child { border-bottom: none; }
.meta-row .meta-label { font-size: 13px; color: rgb(100, 116, 139); min-width: 90px; }
.meta-row .meta-value { font-size: 14px; font-weight: 600; color: rgb(15, 23, 42); }
.meta-row .v-icon { color: rgb(148, 163, 184); }
</style>
