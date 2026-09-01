<template>
  <div class="d-flex flex-column ga-4">
    <!-- Page header -->
    <div class="page-header">
      <div>
        <h1 class="text-h5 font-weight-bold d-flex align-center ga-2">
          <v-icon color="primary">mdi-file-chart-outline</v-icon>
          IFTA & Fuel Tax
        </h1>
        <p class="text-caption text-medium-emphasis">Track per-jurisdiction mileage, fuel purchases, and generate quarterly fuel tax reports for IFTA compliance.</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn variant="outlined" prepend-icon="mdi-refresh" @click="reloadAll" :loading="pending">Refresh</v-btn>
        <v-btn v-can="'ifta:create'" variant="tonal" color="deep-purple" prepend-icon="mdi-database-plus" @click="seedDemo" :loading="seeding">
          <span class="hidden-sm-and-down">Seed Demo Data</span>
        </v-btn>
        <v-btn v-can="'ifta:create'" color="primary" prepend-icon="mdi-plus" @click="openCreateLog">
          <span class="hidden-sm-and-down">Add Trip Log</span>
        </v-btn>
      </div>
    </div>

    <!-- Analytics -->
    <IftaAnalytics :stats="iftaStats" @filter-tab="setTab" />

    <!-- Filters bar -->
    <div class="d-flex flex-wrap align-center ga-2 filter-bar">
      <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Search…" density="compact" hide-details variant="outlined" style="max-width:240px" clearable />
      <v-autocomplete v-model="vehicleFilter" :items="vehicleOptions" item-title="display_name" item-value="id" placeholder="All Vehicles" density="compact" hide-details variant="outlined" clearable style="max-width:200px" />
      <v-autocomplete v-model="jurFilter" :items="jurisdictionOptions" item-title="name" item-value="id" placeholder="All Jurisdictions" density="compact" hide-details variant="outlined" clearable style="max-width:180px" />
      <v-btn v-if="hasFilters" variant="text" size="small" prepend-icon="mdi-filter-remove" @click="clearFilters">Clear</v-btn>
      <v-spacer />
      <div class="text-caption text-medium-emphasis">{{ tabCount }}</div>
      <v-btn v-can="'ifta:create'" variant="outlined" prepend-icon="mdi-gas-station" size="small" @click="openCreateFuel">Add Fuel Purchase</v-btn>
      <v-btn v-can="'ifta:create'" variant="outlined" prepend-icon="mdi-sync" size="small" @click="openGenerate">Generate Quarter</v-btn>
    </div>

    <!-- Tabs -->
    <v-tabs v-model="tab" color="primary" density="compact" class="ifta-tabs">
      <v-tab value="triplogs" prepend-icon="mdi-map-marker-path">Trip Logs</v-tab>
      <v-tab value="quarters" prepend-icon="mdi-file-chart-outline">Quarterly Reports</v-tab>
      <v-tab value="fuel" prepend-icon="mdi-gas-station">Fuel Purchases</v-tab>
    </v-tabs>

    <v-window v-model="tab" class="flex-grow-1">
      <!-- TRIP LOGS -->
      <v-window-item value="triplogs">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="tripHeaders" :items="filteredTrips" :loading="logPending" density="compact" hover :search="search">
            <template #item.vehicle_name="{ value }"><span class="font-weight-medium">{{ value }}</span></template>
            <template #item.jurisdiction_code="{ value }">
              <v-chip size="small" variant="tonal" color="primary">{{ value }}</v-chip>
            </template>
            <template #item.date="{ value }">{{ fmtDate(value) }}</template>
            <template #item.distance_miles="{ value }"><span class="font-weight-medium">{{ value ? value.toLocaleString([], { maximumFractionDigits: 1 }) : '0' }}</span></template>
            <template #item.distance_unit="{ value }"><v-chip size="x-small" variant="flat">{{ value }}</v-chip></template>
            <template #item.trip_type="{ value }">
              <v-chip :color="tripTypeColor(value)" variant="tonal" size="x-small" class="text-capitalize">{{ value }}</v-chip>
            </template>
            <template #item.source="{ value }">
              <v-icon size="small" :color="value === 'telematics' ? 'info' : 'grey'">{{ value === 'telematics' ? 'mdi-router-wireless' : 'mdi-pencil' }}</v-icon>
            </template>
            <template #item.actions="{ item }">
              <v-menu>
                <template #activator="{ props: p }">
                  <v-btn icon="mdi-dots-vertical" variant="text" size="small" v-bind="p" />
                </template>
                <v-list density="compact">
                  <v-list-item v-can="'ifta:update'" prepend-icon="mdi-pencil" @click="openEditLog(item)">Edit</v-list-item>
                  <v-list-item v-can="'ifta:delete'" prepend-icon="mdi-trash-can-outline" base-color="error" @click="deleteLog(item)">Delete</v-list-item>
                </v-list>
              </v-menu>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-map-marker-path</v-icon>
                <p>No trip logs yet. Click <b>Seed Demo Data</b> or <b>Add Trip Log</b> to get started.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>

      <!-- QUARTERLY REPORTS -->
      <v-window-item value="quarters">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="quarterHeaders" :items="filteredQuarters" :loading="qPending" density="compact" hover :search="search">
            <template #item.vehicle_name="{ value }"><span class="font-weight-medium">{{ value }}</span></template>
            <template #item.label="{ value }">
              <v-chip variant="flat" color="primary" size="small">{{ value }}</v-chip>
            </template>
            <template #item.status="{ value }">
              <v-chip :color="statusColor(value)" variant="flat" size="small" class="text-capitalize">
                <v-icon start size="14">{{ statusIcon(value) }}</v-icon>{{ value }}
              </v-chip>
            </template>
            <template #item.total_miles="{ value }">{{ value ? value.toLocaleString([], { maximumFractionDigits: 0 }) : '0' }}</template>
            <template #item.total_gallons="{ value }">{{ value ? value.toLocaleString([], { maximumFractionDigits: 1 }) : '0' }}</template>
            <template #item.net_tax="{ value }"><span :class="parseFloat(value) > 0 ? 'text-error font-weight-bold' : 'text-success font-weight-bold'">{{ fmtCur(value) }}</span></template>
            <template #item.actions="{ item }">
              <v-menu>
                <template #activator="{ props: p }">
                  <v-btn icon="mdi-dots-vertical" variant="text" size="small" v-bind="p" />
                </template>
                <v-list density="compact">
                  <v-list-item prepend-icon="mdi-chart-box-outline" @click="showBreakdown(item)">View Breakdown</v-list-item>
                  <v-list-item v-can="'ifta:update'" v-if="item.status === 'draft'" prepend-icon="mdi-send" @click="setQuarterStatus(item, 'submitted')">Submit</v-list-item>
                  <v-list-item v-can="'ifta:update'" v-if="item.status === 'submitted'" prepend-icon="mdi-check-circle" @click="setQuarterStatus(item, 'filed')">File</v-list-item>
                  <v-list-item v-can="'ifta:update'" prepend-icon="mdi-sync" @click="regenerateQuarter(item)">Regenerate</v-list-item>
                  <v-list-item v-can="'ifta:delete'" prepend-icon="mdi-trash-can-outline" base-color="error" @click="deleteQuarter(item)">Delete</v-list-item>
                </v-list>
              </v-menu>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-file-chart-outline</v-icon>
                <p>No quarterly reports yet. Click <b>Seed Demo Data</b> or <b>Generate Quarter</b> to get started.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>

      <!-- FUEL PURCHASES -->
      <v-window-item value="fuel">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="fuelHeaders" :items="filteredFuel" :loading="fuelPending" density="compact" hover :search="search">
            <template #item.vehicle_name="{ value }"><span class="font-weight-medium">{{ value }}</span></template>
            <template #item.jurisdiction_code="{ value }">
              <v-chip size="small" variant="tonal" color="primary">{{ value }}</v-chip>
            </template>
            <template #item.date="{ value }">{{ fmtDate(value) }}</template>
            <template #item.gallons="{ value }"><span class="font-weight-medium">{{ value ? value.toFixed(2) : '0' }}</span></template>
            <template #item.total_cost="{ value }"><span class="font-weight-medium">{{ fmtCur(value) }}</span></template>
            <template #item.tax_paid="{ value }">{{ fmtCur(value) }}</template>
            <template #item.source="{ value }">
              <v-icon size="small" :color="value === 'fuel_card' ? 'info' : 'grey'">{{ value === 'fuel_card' ? 'mdi-credit-card' : 'mdi-pencil' }}</v-icon>
            </template>
            <template #item.actions="{ item }">
              <v-menu>
                <template #activator="{ props: p }">
                  <v-btn icon="mdi-dots-vertical" variant="text" size="small" v-bind="p" />
                </template>
                <v-list density="compact">
                  <v-list-item v-can="'ifta:update'" prepend-icon="mdi-pencil" @click="openEditFuel(item)">Edit</v-list-item>
                  <v-list-item v-can="'ifta:delete'" prepend-icon="mdi-trash-can-outline" base-color="error" @click="deleteFuel(item)">Delete</v-list-item>
                </v-list>
              </v-menu>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-gas-station</v-icon>
                <p>No fuel purchases yet. Click <b>Seed Demo Data</b> or <b>Add Fuel Purchase</b> to get started.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>
    </v-window>

    <!-- Trip Log Form Dialog -->
    <TripLogFormDialog
      ref="tripFormRef"
      v-model="logDialog"
      :editing="editingLog"
      :saving="saving"
      :vehicle-options="vehicleOptions"
      :jurisdiction-options="jurisdictionOptions"
      @save="saveLog"
    />

    <!-- Fuel Purchase Form Dialog -->
    <FuelPurchaseFormDialog
      ref="fuelFormRef"
      v-model="fuelDialog"
      :editing="editingFuel"
      :saving="saving"
      :vehicle-options="vehicleOptions"
      :jurisdiction-options="jurisdictionOptions"
      @save="saveFuel"
    />

    <!-- Generate Quarter Dialog -->
    <GenerateQuarterDialog
      v-model="genDialog"
      :saving="saving"
      :vehicle-options="vehicleOptions"
      @generate="generate"
    />

    <!-- Quarter Breakdown Drawer -->
    <QuarterBreakdownDrawer
      v-model="drawerOpen"
      :quarter="selectedQuarter"
      :breakdown="breakdown"
      @regenerate="regenerateQuarter"
      @delete="deleteQuarter"
      @set-status="onSetStatus"
    />
  </div>
</template>

<script setup lang="ts">
import IftaAnalytics from '~/components/ifta/IftaAnalytics.vue'
import TripLogFormDialog from '~/components/ifta/TripLogFormDialog.vue'
import FuelPurchaseFormDialog from '~/components/ifta/FuelPurchaseFormDialog.vue'
import GenerateQuarterDialog from '~/components/ifta/GenerateQuarterDialog.vue'
import QuarterBreakdownDrawer from '~/components/ifta/QuarterBreakdownDrawer.vue'

definePageMeta({ layout: 'default' })
const { $api, $swal } = useNuxtApp() as any

/* --- state --- */
const tab = ref('triplogs')
const search = ref('')
const vehicleFilter = ref<number | null>(null)
const jurFilter = ref<number | null>(null)
const saving = ref(false)
const seeding = ref(false)
const logDialog = ref(false)
const fuelDialog = ref(false)
const genDialog = ref(false)
const drawerOpen = ref(false)
const editingLog = ref(false)
const editingFuel = ref(false)
const selectedQuarter = ref<any>(null)
const breakdown = ref<any[]>([])
const tripFormRef = ref<any>(null)
const fuelFormRef = ref<any>(null)

/* --- headers --- */
const tripHeaders = [
  { title: 'Vehicle', key: 'vehicle_name', sortable: true },
  { title: 'Jur.', key: 'jurisdiction_code', width: '70px' },
  { title: 'Date', key: 'date', width: '110px', sortable: true },
  { title: 'Miles', key: 'distance_miles', width: '90px', sortable: true },
  { title: 'Unit', key: 'distance_unit', width: '60px' },
  { title: 'Type', key: 'trip_type', width: '80px' },
  { title: 'Route', key: 'route' },
  { title: 'Src', key: 'source', width: '50px' },
  { title: '', key: 'actions', width: '50px', sortable: false },
]
const quarterHeaders = [
  { title: 'Vehicle', key: 'vehicle_name', sortable: true },
  { title: 'Period', key: 'label', width: '100px' },
  { title: 'Miles', key: 'total_miles', width: '100px', sortable: true },
  { title: 'Gallons', key: 'total_gallons', width: '100px', sortable: true },
  { title: 'Net Tax', key: 'net_tax', width: '120px', sortable: true },
  { title: 'Status', key: 'status', width: '110px', sortable: true },
  { title: '', key: 'actions', width: '50px', sortable: false },
]
const fuelHeaders = [
  { title: 'Vehicle', key: 'vehicle_name', sortable: true },
  { title: 'Jur.', key: 'jurisdiction_code', width: '70px' },
  { title: 'Date', key: 'date', width: '110px', sortable: true },
  { title: 'Gallons', key: 'gallons', width: '90px', sortable: true },
  { title: 'Total Cost', key: 'total_cost', width: '110px', sortable: true },
  { title: 'Tax Paid', key: 'tax_paid', width: '100px' },
  { title: 'Vendor', key: 'vendor' },
  { title: 'Src', key: 'source', width: '50px' },
  { title: '', key: 'actions', width: '50px', sortable: false },
]

/* --- data --- */
const { data: vehData } = useAsyncData('ifta-vehicles', () => $api('/vehicles/vehicles/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const vehicleOptions = computed(() => vehData.value?.results || [])
const { data: jurData } = useAsyncData('ifta-jurisdictions', () => $api('/ifta/jurisdictions/').catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const jurisdictionOptions = computed(() => jurData.value?.results || [])

const { data: logData, pending: logPending, refresh: refreshLogs } = useAsyncData('ifta-triplogs', () => $api('/ifta/trip-logs/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const triplogs = computed(() => logData.value?.results || [])

const { data: qData, pending: qPending, refresh: refreshQuarters } = useAsyncData('ifta-quarters', () => $api('/ifta/quarters/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const quarters = computed(() => qData.value?.results || [])

const { data: fData, pending: fuelPending, refresh: refreshFuel } = useAsyncData('ifta-fuel', () => $api('/ifta/fuel-purchases/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const fuelPurchases = computed(() => fData.value?.results || [])

const { data: statsData, refresh: refreshStats } = useAsyncData('ifta-stats', () => $api('/ifta/quarters/stats/').catch(() => ({})), { default: () => ({}) })
const iftaStats = computed(() => statsData.value || {})

const pending = computed(() => logPending.value || qPending.value || fuelPending.value)

/* --- filters --- */
const filteredTrips = computed(() => {
  let arr = triplogs.value
  if (vehicleFilter.value) arr = arr.filter(t => t.vehicle === vehicleFilter.value)
  if (jurFilter.value) arr = arr.filter(t => t.jurisdiction === jurFilter.value)
  if (search.value) { const q = search.value.toLowerCase(); arr = arr.filter(t => (t.route || '').toLowerCase().includes(q) || (t.vehicle_name || '').toLowerCase().includes(q) || (t.jurisdiction_code || '').toLowerCase().includes(q)) }
  return arr
})
const filteredQuarters = computed(() => {
  let arr = quarters.value
  if (vehicleFilter.value) arr = arr.filter(q => q.vehicle === vehicleFilter.value)
  if (search.value) { const q = search.value.toLowerCase(); arr = arr.filter(q => (q.vehicle_name || '').toLowerCase().includes(q) || (q.label || '').toLowerCase().includes(q)) }
  return arr
})
const filteredFuel = computed(() => {
  let arr = fuelPurchases.value
  if (vehicleFilter.value) arr = arr.filter(f => f.vehicle === vehicleFilter.value)
  if (jurFilter.value) arr = arr.filter(f => f.jurisdiction === jurFilter.value)
  if (search.value) { const q = search.value.toLowerCase(); arr = arr.filter(f => (f.vendor || '').toLowerCase().includes(q) || (f.vehicle_name || '').toLowerCase().includes(q) || (f.jurisdiction_code || '').toLowerCase().includes(q)) }
  return arr
})
const hasFilters = computed(() => !!(search.value || vehicleFilter.value || jurFilter.value))
const tabCount = computed(() => {
  if (tab.value === 'triplogs') return `${filteredTrips.value.length} of ${triplogs.value.length} trip logs`
  if (tab.value === 'quarters') return `${filteredQuarters.value.length} of ${quarters.value.length} reports`
  return `${filteredFuel.value.length} of ${fuelPurchases.value.length} fuel purchases`
})
function clearFilters() { search.value = ''; vehicleFilter.value = null; jurFilter.value = null }
function setTab(t: string) { tab.value = t }

/* --- helpers --- */
function statusColor(s: string) { return ({ draft: 'grey', submitted: 'primary', filed: 'success' } as any)[s] || 'grey' }
function statusIcon(s: string) { return ({ draft: 'mdi-pencil-outline', submitted: 'mdi-send', filed: 'mdi-check-circle' } as any)[s] || 'mdi-circle-outline' }
function tripTypeColor(t: string) { return ({ loaded: 'success', empty: 'warning', bobtail: 'grey' } as any)[t] || 'grey' }
function fmtDate(v?: string) { return v ? new Date(v).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' }) : '—' }
function fmtCur(v?: number) { return v ? `$${parseFloat(v).toLocaleString([], { minimumFractionDigits: 2, maximumFractionDigits: 2 })}` : '$0.00' }
function fmtNum(v?: number) { return v ? parseFloat(v).toLocaleString([], { maximumFractionDigits: 1 }) : '0' }

/* --- reload all --- */
async function reloadAll() { await Promise.all([refreshLogs(), refreshQuarters(), refreshFuel(), refreshStats()]) }

/* --- seed demo --- */
async function seedDemo() {
  const r = await $swal?.fire?.({ icon: 'question', title: 'Seed IFTA demo data?', text: 'This will create jurisdictions, trip logs, fuel purchases, and quarterly reports for your fleet.', showCancelButton: true, confirmButtonText: 'Seed Data' })
  if (!r?.isConfirmed) return
  seeding.value = true
  try { const res = await $api('/ifta/quarters/seed-demo/', { method: 'POST' }); await reloadAll(); $swal?.fire?.({ icon: 'success', title: res?.detail || 'Demo data seeded', toast: true, timer: 3000, position: 'top-end' }) }
  catch (e: any) { console.error(e); $swal?.fire?.({ icon: 'error', title: e?.response?._data?.detail || 'Failed to seed data', toast: true, timer: 3000, position: 'top-end' }) } finally { seeding.value = false }
}

/* --- Trip Log CRUD --- */
function openCreateLog() { editingLog.value = false; tripFormRef.value?.reset(); logDialog.value = true }
function openEditLog(t: any) { editingLog.value = true; tripFormRef.value?.reset(t); logDialog.value = true }
async function saveLog(form: any) {
  saving.value = true
  try {
    const { _id, ...body } = form
    if (editingLog.value && form._id) await $api(`/ifta/trip-logs/${form._id}/`, { method: 'PATCH', body })
    else await $api('/ifta/trip-logs/', { method: 'POST', body })
    logDialog.value = false; await Promise.all([refreshLogs(), refreshStats()])
    $swal?.fire?.({ icon: 'success', title: editingLog.value ? 'Trip log updated' : 'Trip log created', toast: true, timer: 1500, position: 'top-end' })
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Save failed', toast: true, timer: 2000, position: 'top-end' }) } finally { saving.value = false }
}
async function deleteLog(t: any) {
  const res = await $swal?.fire?.({ icon: 'warning', title: 'Delete trip log?', text: 'This trip log will be permanently removed.', showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!res?.isConfirmed) return
  await $api(`/ifta/trip-logs/${t.id}/`, { method: 'DELETE' }); await Promise.all([refreshLogs(), refreshStats()])
  $swal?.fire?.({ icon: 'success', title: 'Trip log deleted', toast: true, timer: 1500, position: 'top-end' })
}

/* --- Fuel Purchase CRUD --- */
function openCreateFuel() { editingFuel.value = false; fuelFormRef.value?.reset(); fuelDialog.value = true }
function openEditFuel(f: any) { editingFuel.value = true; fuelFormRef.value?.reset(f); fuelDialog.value = true }
async function saveFuel(form: any) {
  saving.value = true
  try {
    const { _id, ...body } = form
    if (editingFuel.value && form._id) await $api(`/ifta/fuel-purchases/${form._id}/`, { method: 'PATCH', body })
    else await $api('/ifta/fuel-purchases/', { method: 'POST', body })
    fuelDialog.value = false; await Promise.all([refreshFuel(), refreshStats()])
    $swal?.fire?.({ icon: 'success', title: editingFuel.value ? 'Fuel purchase updated' : 'Fuel purchase created', toast: true, timer: 1500, position: 'top-end' })
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Save failed', toast: true, timer: 2000, position: 'top-end' }) } finally { saving.value = false }
}
async function deleteFuel(f: any) {
  const res = await $swal?.fire?.({ icon: 'warning', title: 'Delete fuel purchase?', showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!res?.isConfirmed) return
  await $api(`/ifta/fuel-purchases/${f.id}/`, { method: 'DELETE' }); await Promise.all([refreshFuel(), refreshStats()])
  $swal?.fire?.({ icon: 'success', title: 'Fuel purchase deleted', toast: true, timer: 1500, position: 'top-end' })
}

/* --- Quarter CRUD --- */
function openGenerate() { genDialog.value = true }
async function generate(form: any) {
  saving.value = true
  try { await $api('/ifta/quarters/generate/', { method: 'POST', body: form }); genDialog.value = false; await Promise.all([refreshQuarters(), refreshStats()]); $swal?.fire?.({ icon: 'success', title: 'Quarterly report generated', toast: true, timer: 2000, position: 'top-end' }) }
  catch (e: any) { console.error(e); $swal?.fire?.({ icon: 'error', title: e?.response?._data?.detail || 'Generate failed', toast: true, timer: 3000, position: 'top-end' }) } finally { saving.value = false }
}
async function regenerateQuarter(q: any) {
  const res = await $swal?.fire?.({ icon: 'question', title: 'Regenerate report?', text: `${q.label} for ${q.vehicle_name} will be recalculated from trip logs and fuel purchases.`, showCancelButton: true, confirmButtonText: 'Regenerate' })
  if (!res?.isConfirmed) return
  try { await $api('/ifta/quarters/generate/', { method: 'POST', body: { vehicle: q.vehicle, year: q.year, quarter: q.quarter } }); await Promise.all([refreshQuarters(), refreshStats()]); $swal?.fire?.({ icon: 'success', title: 'Report regenerated', toast: true, timer: 2000, position: 'top-end' }) }
  catch (e: any) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Regenerate failed', toast: true, timer: 2000, position: 'top-end' }) }
}
async function deleteQuarter(q: any) {
  const res = await $swal?.fire?.({ icon: 'warning', title: 'Delete quarterly report?', text: `${q.label} for ${q.vehicle_name} will be permanently removed.`, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!res?.isConfirmed) return
  await $api(`/ifta/quarters/${q.id}/`, { method: 'DELETE' }); drawerOpen.value = false; await Promise.all([refreshQuarters(), refreshStats()])
  $swal?.fire?.({ icon: 'success', title: 'Report deleted', toast: true, timer: 1500, position: 'top-end' })
}
async function setQuarterStatus(q: any, status: string) {
  await $api(`/ifta/quarters/${q.id}/`, { method: 'PATCH', body: { status } }); await Promise.all([refreshQuarters(), refreshStats()])
  $swal?.fire?.({ icon: 'success', title: `Marked ${status}`, toast: true, timer: 1500, position: 'top-end' })
}
async function onSetStatus({ quarter, status }: { quarter: any; status: string }) { await setQuarterStatus(quarter, status) }

/* --- Breakdown drawer --- */
async function showBreakdown(q: any) {
  selectedQuarter.value = q; drawerOpen.value = true
  try { breakdown.value = await $api(`/ifta/quarters/${q.id}/breakdown/`) }
  catch (e) { console.error(e); breakdown.value = [] }
}
</script>

<style scoped>
.page-header { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
.filter-bar { flex-wrap: wrap; background: #f8fafc; padding: 8px 12px; border-radius: 12px; }
.ifta-tabs :deep(.v-tab) { text-transform: none; font-weight: 600; }
.cursor-pointer { cursor: pointer; }
</style>

