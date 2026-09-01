<template>
  <div class="d-flex flex-column ga-4">
    <!-- Page header -->
    <div class="page-header">
      <div>
        <h1 class="text-h5 font-weight-bold d-flex align-center ga-2">
          <v-icon color="primary">mdi-map-outline</v-icon>
          Dispatch
        </h1>
        <p class="text-caption text-medium-emphasis">Plan, assign, and track freight movements with live route tracking.</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn variant="outlined" prepend-icon="mdi-traffic-cone" @click="openTrafficWeather" :disabled="!filteredJobs.length">
          <span class="hidden-sm-and-down">Traffic &amp; Weather</span>
        </v-btn>
        <v-btn variant="outlined" prepend-icon="mdi-routes" @click="openRouteOpt" :disabled="!filteredJobs.length">
          <span class="hidden-sm-and-down">Optimize Route</span>
        </v-btn>
        <v-btn variant="outlined" prepend-icon="mdi-refresh" @click="reloadAll" :loading="pending">Refresh</v-btn>
        <v-btn v-can="'dispatch:create'" color="primary" prepend-icon="mdi-plus" @click="openCreate">
          <span class="hidden-sm-and-down">New Job</span>
          <v-icon end class="d-none d-sm-none">mdi-plus</v-icon>
        </v-btn>
      </div>
    </div>

    <!-- Analytics -->
    <DispatchAnalytics :jobs="jobs" :active-filter="statusFilter" @filter="setStatusFilter" />

    <!-- Filtering bar outside cards -->
    <div class="d-flex flex-wrap align-center ga-2 filter-bar">
      <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Search jobs, addresses…" density="compact" hide-details variant="outlined" style="max-width: 280px" clearable />
      <v-select v-model="statusFilter" :items="statusOptions" item-title="label" item-value="value" placeholder="All Statuses" density="compact" hide-details variant="outlined" clearable style="max-width: 170px" />
      <v-select v-model="priorityFilter" :items="priorities" item-title="label" item-value="value" placeholder="All Priorities" density="compact" hide-details variant="outlined" clearable style="max-width: 170px" />
      <v-select v-model="driverFilter" :items="driverOptions" item-title="full_name" item-value="id" placeholder="All Drivers" density="compact" hide-details variant="outlined" clearable style="max-width: 200px" />
      <v-btn v-if="hasActiveFilters" variant="text" size="small" prepend-icon="mdi-filter-remove" @click="clearFilters">Clear</v-btn>
      <v-spacer />
      <div class="text-caption text-medium-emphasis">{{ filteredJobs.length }} of {{ jobs.length }} jobs</div>
    </div>

    <!-- Tabs -->
    <v-tabs v-model="tab" color="primary" density="compact" class="dispatch-tabs">
      <v-tab value="board" prepend-icon="mdi-view-column-outline">Board</v-tab>
      <v-tab value="list" prepend-icon="mdi-format-list-bulleted">List</v-tab>
      <v-tab value="map" prepend-icon="mdi-map">Map</v-tab>
      <v-tab value="assignments" prepend-icon="mdi-truck-check">Assignments</v-tab>
    </v-tabs>

    <v-window v-model="tab" class="flex-grow-1">
      <!-- KANBAN BOARD -->
      <v-window-item value="board">
        <DispatchBoard :jobs="filteredJobs" @change="onStatusChange" @select="openDetail" />
      </v-window-item>

      <!-- LIST -->
      <v-window-item value="list">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="headers" :items="filteredJobs" :loading="pending" hover :search="search" density="compact">
            <template #item.title="{ item }">
              <div class="cursor-pointer" @click="openDetail(item)">
                <p class="font-weight-medium">{{ item.title }}</p>
                <p class="text-caption text-medium-emphasis"><v-icon size="11" color="success">mdi-circle</v-icon>{{ item.pickup_address || '—' }} → <v-icon size="11" color="error">mdi-circle</v-icon>{{ item.dropoff_address || '—' }}</p>
              </div>
            </template>
            <template #item.status="{ value }">
              <v-chip :color="statusColor(value)" variant="flat" size="small" class="text-capitalize">{{ value.replace('_', ' ') }}</v-chip>
            </template>
            <template #item.priority="{ value }">
              <v-chip :color="priorityColor(value)" variant="tonal" size="small" class="text-capitalize"><v-icon start size="14">mdi-flag</v-icon>{{ value }}</v-chip>
            </template>
            <template #item.scheduled_start="{ value }">{{ fmt(value) }}</template>
            <template #item.eta_minutes="{ value }"><v-chip v-if="value" size="small" variant="outlined">{{ value }}m</v-chip><span v-else>—</span></template>
            <template #item.is_on_schedule="{ value }">
              <v-icon v-if="value === true" color="success">mdi-check-circle</v-icon>
              <v-icon v-else-if="value === false" color="error">mdi-alert-circle</v-icon>
              <span v-else>—</span>
            </template>
            <template #item.actions="{ item }">
              <v-menu>
                <template #activator="{ props: p }">
                  <v-btn icon="mdi-dots-vertical" variant="text" size="small" v-bind="p" />
                </template>
                <v-list density="compact">
                  <v-list-item prepend-icon="mdi-eye-outline" @click="openDetail(item)">View</v-list-item>
                  <v-list-item v-if="item.status === 'pending'" prepend-icon="mdi-send" @click="openAssign(item)">Assign</v-list-item>
                  <v-list-item v-if="item.status === 'assigned'" prepend-icon="mdi-play" @click="startJob(item)">Start Job</v-list-item>
                  <v-list-item v-if="item.status === 'in_progress'" v-can="'dispatch:update'" prepend-icon="mdi-check" @click="completeJob(item)">Complete</v-list-item>
                  <v-list-item v-can="'dispatch:update'" prepend-icon="mdi-pencil" @click="openEdit(item)">Edit</v-list-item>
                  <v-list-item v-if="item.status !== 'completed' && item.status !== 'cancelled'" prepend-icon="mdi-cancel" base-color="error" @click="cancelJob(item)">Cancel</v-list-item>
                  <v-list-item v-can="'dispatch:delete'" prepend-icon="mdi-delete" base-color="error" @click="deleteJob(item)">Delete</v-list-item>
                </v-list>
              </v-menu>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-map-marker-path</v-icon>
                <p>No dispatch jobs yet. Click <b>New Job</b> to create one.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>

      <!-- MAP -->
      <v-window-item value="map">
        <DispatchMap :jobs="filteredJobs" />
      </v-window-item>

      <!-- ASSIGNMENTS -->
      <v-window-item value="assignments">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="assignHeaders" :items="assignments" :loading="assignPending" density="compact" hover>
            <template #item.is_active="{ value }">
              <v-chip :color="value ? 'success' : 'default'" variant="flat" size="small">{{ value ? 'Active' : 'Released' }}</v-chip>
            </template>
            <template #item.assigned_at="{ value }">{{ fmt(value) }}</template>
            <template #item.unassigned_at="{ value }">{{ value ? fmt(value) : '—' }}</template>
            <template #item.actions="{ item }">
              <v-btn v-if="item.is_active" icon="mdi-link-off" variant="text" size="small" color="error" @click="releaseAssignment(item)" />
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="42" class="mb-2">mdi-truck-outline</v-icon>
                <p class="text-caption">No vehicle assignments on record.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>
    </v-window>

    <!-- Job create/edit dialog -->
    <JobFormDialog
      ref="jobFormRef"
      v-model="jobDialog"
      :editing="editing"
      :vehicle-options="vehicleOptions"
      :driver-options="driverOptions"
      :saving="saving"
      @save="saveJob"
    />

    <!-- Assign dialog -->
    <DispatchAssignDialog
      v-model="assignDialog"
      :job="assignTarget"
      :vehicle-options="vehicleOptions"
      :driver-options="driverOptions"
      :saving="saving"
      @confirm="doAssign"
    />

    <!-- Route stop dialog -->
    <StopFormDialog
      ref="stopFormRef"
      v-model="stopDialog"
      :editing="stopEditing"
      :job="selectedJob"
      :saving="saving"
      :suggested-sequence="stopsForSelected.length + 1"
      @save="saveStop"
    />

    <!-- Job detail drawer -->
    <JobDetailDrawer
      v-model="drawerOpen"
      :job="selectedJob"
      :stops="stopsForSelected"
      @assign="openAssign"
      @start="startJob"
      @complete="completeJob"
      @edit="openEdit"
      @cancel="cancelJob"
      @delete="deleteJob"
      @add-stop="openStopCreate"
      @edit-stop="openStopEdit"
      @delete-stop="deleteStop"
      @reorder-stop="reorderStop"
      @optimize-route="openRouteOptForJob"
      @traffic-weather="openTrafficForJob"
    />

    <!-- Route Optimization -->
    <RouteOptimizationPanel
      v-model="routeOptDialog"
      :job="routeOptJob"
      :stops="routeOptStops"
      :jobs="geocodedJobs"
      @apply-order="applyOptimizedOrder"
    />

    <!-- Traffic & Weather -->
    <TrafficWeatherPanel
      v-model="trafficDialog"
      :job="trafficJob"
      :stops="trafficStops"
      :jobs="geocodedJobs"
    />
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })
const { $api, $swal } = useNuxtApp() as any

const tab = ref<'board' | 'list' | 'map' | 'assignments'>('board')
const search = ref('')
const statusFilter = ref<string | null>(null)
const priorityFilter = ref<string | null>(null)
const driverFilter = ref<number | null>(null)

const statusOptions = [{ label: 'Pending', value: 'pending' }, { label: 'Assigned', value: 'assigned' }, { label: 'In Progress', value: 'in_progress' }, { label: 'Completed', value: 'completed' }, { label: 'Cancelled', value: 'cancelled' }]
const priorities = [{ label: 'Low', value: 'low' }, { label: 'Medium', value: 'medium' }, { label: 'High', value: 'high' }, { label: 'Urgent', value: 'urgent' }]

const headers = [
  { title: 'Job', key: 'title', sortable: true },
  { title: 'Vehicle', key: 'vehicle_name', width: '140px' },
  { title: 'Driver', key: 'driver_name', width: '130px' },
  { title: 'Status', key: 'status', sortable: true, width: '120px' },
  { title: 'Priority', key: 'priority', sortable: true, width: '90px' },
  { title: 'Scheduled', key: 'scheduled_start', width: '150px' },
  { title: 'ETA', key: 'eta_minutes', width: '70px' },
  { title: 'On Time', key: 'is_on_schedule', width: '80px', sortable: false },
  { title: '', key: 'actions', width: '50px', sortable: false },
]
const assignHeaders = [
  { title: 'Vehicle', key: 'vehicle_name' },
  { title: 'Driver', key: 'driver_name' },
  { title: 'Job', key: 'job' },
  { title: 'Active', key: 'is_active', width: '100px' },
  { title: 'Assigned', key: 'assigned_at', width: '150px' },
  { title: 'Released', key: 'unassigned_at', width: '150px' },
  { title: '', key: 'actions', width: '50px', sortable: false },
]

// Data
const { data: vehicleData } = useAsyncData('disp-vehicles', () => $api('/vehicles/vehicles/', { query: { page_size: 1000 } }), { default: () => ({ results: [] }) })
const vehicleOptions = computed(() => vehicleData.value?.results || [])
const { data: driverData } = useAsyncData('disp-drivers', () => $api('/contacts/drivers/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const driverOptions = computed(() => driverData.value?.results || [])

const { data: jobData, pending, refresh } = useAsyncData('jobs', () =>
  $api('/dispatch/jobs/', { query: { page_size: 1000 } }), { default: () => ({ results: [], count: 0 }) })
const jobs = computed(() => jobData.value?.results || [])
const filteredJobs = computed(() => {
  let arr = jobs.value
  if (statusFilter.value) arr = arr.filter(j => j.status === statusFilter.value)
  if (priorityFilter.value) arr = arr.filter(j => j.priority === priorityFilter.value)
  if (driverFilter.value) arr = arr.filter(j => j.driver === driverFilter.value)
  if (search.value) {
    const q = search.value.toLowerCase()
    arr = arr.filter(j => (j.title || '').toLowerCase().includes(q) || (j.pickup_address || '').toLowerCase().includes(q) || (j.dropoff_address || '').toLowerCase().includes(q))
  }
  return arr
})
const hasActiveFilters = computed(() => !!(statusFilter.value || priorityFilter.value || driverFilter.value || search.value))
function setStatusFilter(k: string) { statusFilter.value = statusFilter.value === k ? null : k }

// Assignments
const { data: assignData, pending: assignPending, refresh: refreshAssign } = useAsyncData('disp-assignments', () =>
  $api('/dispatch/assignments/', { query: { page_size: 1000 } }), { default: () => ({ results: [] }) })
const assignments = computed(() => assignData.value?.results || [])

// Dialogs
const jobFormRef = ref<any>(null)
const jobDialog = ref(false)
const editing = ref(false)
const saving = ref(false)
const assignDialog = ref(false)
const assignTarget = ref<any>(null)
const stopDialog = ref(false)
const stopEditing = ref(false)
const stopFormRef = ref<any>(null)
const drawerOpen = ref(false)
const selectedJob = ref<any>(null)
const stopsForSelected = ref<any[]>([])

watch(drawerOpen, async (open) => {
  if (open && selectedJob.value) await loadStops(selectedJob.value.id)
})

async function loadStops(jobId: number) {
  try {
    const data = await $api(`/dispatch/stops/for_job/${jobId}/`)
    stopsForSelected.value = Array.isArray(data) ? data : (data?.results || [])
  } catch { stopsForSelected.value = [] }
}
async function reloadStops() { if (selectedJob.value) await loadStops(selectedJob.value.id) }

function fmt(v?: string) { return v ? new Date(v).toLocaleString([], { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : '—' }
function statusColor(s: string) { return ({ pending: 'grey', assigned: 'info', in_progress: 'warning', completed: 'success', cancelled: 'error' } as any)[s] || 'grey' }
function priorityColor(p: string) { return ({ low: 'grey', medium: 'warning', high: 'orange', urgent: 'error' } as any)[p] || 'grey' }

// --- Job CRUD ---
function openCreate() {
  editing.value = false
  jobFormRef.value?.reset()
  jobDialog.value = true
}
function openEdit(j: any) {
  editing.value = true
  jobFormRef.value?.reset(j)
  jobDialog.value = true
  drawerOpen.value = false
}
async function saveJob(payload: any) {
  saving.value = true
  try {
    const body = { ...payload }
    delete body._id
    if (editing.value && payload._id) {
      await $api(`/dispatch/jobs/${payload._id}/`, { method: 'PATCH', body })
    } else {
      await $api('/dispatch/jobs/', { method: 'POST', body })
    }
    jobDialog.value = false
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: editing.value ? 'Job updated' : 'Job created', toast: true, timer: 1500, position: 'top-end' })
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Save failed', toast: true, timer: 2000, position: 'top-end' }) } finally { saving.value = false }
}

async function deleteJob(j: any) {
  const r = await $swal?.fire?.({ icon: 'warning', title: 'Delete job?', text: j.title, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#dc2626' })
  if (!r?.isConfirmed) return
  await $api(`/dispatch/jobs/${j.id}/`, { method: 'DELETE' })
  if (selectedJob.value?.id === j.id) { drawerOpen.value = false; selectedJob.value = null }
  await reloadAll()
  $swal?.fire?.({ icon: 'success', title: 'Job deleted', toast: true, timer: 1500, position: 'top-end' })
}

// --- Assignment ---
function openAssign(j: any) { assignTarget.value = j; assignDialog.value = true }
async function doAssign(jobId: number, vid: number | null, did: number | null, createRecord: boolean) {
  saving.value = true
  try {
    await $api(`/dispatch/jobs/${jobId}/assign/`, { method: 'POST', body: { vehicle: vid, driver: did } })
    if (createRecord && (vid || did)) {
      try { await $api('/dispatch/assignments/', { method: 'POST', body: { vehicle: vid, driver: did, job: jobId, is_active: true } }); await refreshAssign() } catch {}
    }
    assignDialog.value = false
    await reloadAll()
    if (selectedJob.value?.id === jobId) selectedJob.value = { ...selectedJob.value, vehicle: vid, driver: did, status: 'assigned', vehicle_name: vehicleOptions.value.find(v => v.id === vid)?.display_name, driver_name: driverOptions.value.find(d => d.id === did)?.full_name }
    $swal?.fire?.({ icon: 'success', title: 'Job assigned', toast: true, timer: 1500, position: 'top-end' })
  } catch (e) { console.error(e) } finally { saving.value = false }
}

// --- Lifecycle actions ---
async function startJob(j: any) {
  await $api(`/dispatch/jobs/${j.id}/start/`, { method: 'POST' }); await reloadAll(); syncSelected(j.id)
  $swal?.fire?.({ icon: 'info', title: 'Job started', toast: true, timer: 1500, position: 'top-end' })
}
async function completeJob(j: any) {
  await $api(`/dispatch/jobs/${j.id}/complete/`, { method: 'POST' }); await reloadAll(); syncSelected(j.id)
  $swal?.fire?.({ icon: 'success', title: 'Job completed', toast: true, timer: 1500, position: 'top-end' })
}
async function cancelJob(j: any) {
  const r = await $swal?.fire?.({ icon: 'warning', title: 'Cancel job?', text: j.title, showCancelButton: true, confirmButtonText: 'Cancel Job', confirmButtonColor: '#dc2626' })
  if (!r?.isConfirmed) return
  await $api(`/dispatch/jobs/${j.id}/cancel/`, { method: 'POST' }); await reloadAll(); syncSelected(j.id)
}
async function onStatusChange(jobId: number, newStatus: string) {
  // Map of allowed transitions; use defined actions, fallback to PATCH
  try {
    const j = jobs.value.find(x => x.id === jobId)
    if (!j) return
    if (newStatus === 'assigned' && j.vehicle && j.driver) await $api(`/dispatch/jobs/${jobId}/assign/`, { method: 'POST', body: { vehicle: j.vehicle, driver: j.driver } })
    else if (newStatus === 'in_progress') await $api(`/dispatch/jobs/${jobId}/start/`, { method: 'POST' })
    else if (newStatus === 'completed') await $api(`/dispatch/jobs/${jobId}/complete/`, { method: 'POST' })
    else if (newStatus === 'cancelled') await $api(`/dispatch/jobs/${jobId}/cancel/`, { method: 'POST' })
    else await $api(`/dispatch/jobs/${jobId}/`, { method: 'PATCH', body: { status: newStatus } })
    await reloadAll(); syncSelected(jobId)
    $swal?.fire?.({ icon: 'success', title: `Moved to ${newStatus.replace('_', ' ')}`, toast: true, timer: 1500, position: 'top-end' })
  } catch (e) { console.error(e) }
}

function syncSelected(id: number) {
  if (selectedJob.value?.id === id) selectedJob.value = jobs.value.find(j => j.id === id) || null
}

async function releaseAssignment(a: any) {
  await $api(`/dispatch/assignments/${a.id}/`, { method: 'PATCH', body: { is_active: false, unassigned_at: new Date().toISOString() } })
  await refreshAssign()
}

// --- Detail drawer ---
function openDetail(j: any) {
  selectedJob.value = j
  drawerOpen.value = true
}

// --- Route stops ---
function openStopCreate() { stopEditing.value = false; stopDialog.value = true }
function openStopEdit(s: any) { stopEditing.value = true; stopFormRef.value?.populate(s); stopDialog.value = true }
async function saveStop(payload: any) {
  saving.value = true
  try {
    const { _id, _jobId, ...body } = payload
    if (stopEditing.value && _id) await $api(`/dispatch/stops/${_id}/`, { method: 'PATCH', body })
    else await $api('/dispatch/stops/', { method: 'POST', body })
    stopDialog.value = false
    await reloadStops()
    await refresh()
    $swal?.fire?.({ icon: 'success', title: 'Stop saved', toast: true, timer: 1200, position: 'top-end' })
  } catch (e) { console.error(e) } finally { saving.value = false }
}
async function deleteStop(s: any) {
  const r = await $swal?.fire?.({ icon: 'warning', title: 'Delete stop?', text: s.address, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#dc2626' })
  if (!r?.isConfirmed) return
  await $api(`/dispatch/stops/${s.id}/`, { method: 'DELETE' }); await reloadStops(); await refresh()
}
async function reorderStop(s: any, dir: number) {
  const idx = stopsForSelected.value.findIndex(x => x.id === s.id)
  const swapIdx = idx + dir
  if (idx < 0 || swapIdx < 0 || swapIdx >= stopsForSelected.value.length) return
  const swap = stopsForSelected.value[swapIdx]
  await Promise.all([
    $api(`/dispatch/stops/${s.id}/`, { method: 'PATCH', body: { sequence: swap.sequence } }),
    $api(`/dispatch/stops/${swap.id}/`, { method: 'PATCH', body: { sequence: s.sequence } }),
  ])
  await reloadStops(); await refresh()
}

// --- Route Optimization & Traffic/Weather ---
const routeOptDialog = ref(false)
const routeOptJob = ref<any>(null)
const routeOptStops = ref<any[]>([])
const trafficDialog = ref(false)
const trafficJob = ref<any>(null)
const trafficStops = ref<any[]>([])

const geocodedJobs = computed(() =>
  filteredJobs.value.filter(j => j.pickup_lat != null && j.dropoff_lat != null)
)

async function openRouteOpt() {
  // Open the panel with a job selector — user picks which job to optimize
  if (!geocodedJobs.value.length) {
    $swal?.fire?.({ icon: 'info', title: 'No geocoded jobs found', toast: true, timer: 2000, position: 'top-end' })
    return
  }
  // Pre-select the first job with stops, otherwise the first geocoded job
  const candidate = geocodedJobs.value.find(j => j.stops?.length > 0) || geocodedJobs.value[0]
  await openRouteOptForJob(candidate)
}

async function openRouteOptForJob(j: any) {
  routeOptJob.value = j
  try {
    const data = await $api(`/dispatch/stops/for_job/${j.id}/`)
    routeOptStops.value = Array.isArray(data) ? data : (data?.results || [])
  } catch { routeOptStops.value = j.stops || [] }
  routeOptDialog.value = true
}

async function openTrafficWeather() {
  // Open the panel with a job selector — user picks which job to view
  if (!geocodedJobs.value.length) {
    $swal?.fire?.({ icon: 'info', title: 'No geocoded jobs found', toast: true, timer: 2000, position: 'top-end' })
    return
  }
  // Pre-select the first job so the dropdown has a default
  const first = geocodedJobs.value[0]
  await openTrafficForJob(first)
}

async function openTrafficForJob(j: any) {
  trafficJob.value = j
  try {
    const data = await $api(`/dispatch/stops/for_job/${j.id}/`)
    trafficStops.value = Array.isArray(data) ? data : (data?.results || [])
  } catch { trafficStops.value = j.stops || [] }
  trafficDialog.value = true
}

async function applyOptimizedOrder(order: number[]) {
  // Reorder the stopsForSelected based on the optimized order
  if (!selectedJob.value || !order.length) return
  const jobId = routeOptJob.value?.id
  if (!jobId) return
  // Fetch current stops
  let currentStops: any[] = []
  try {
    const data = await $api(`/dispatch/stops/for_job/${jobId}/`)
    currentStops = Array.isArray(data) ? data : (data?.results || [])
  } catch { currentStops = [] }
  if (order.length !== currentStops.length) return
  // Apply new sequence: order maps optimized index → original index
  try {
    await Promise.all(order.map((origIdx, newPos) => {
      const stop = currentStops[origIdx]
      return $api(`/dispatch/stops/${stop.id}/`, { method: 'PATCH', body: { sequence: newPos + 1 } })
    }))
    if (selectedJob.value?.id === jobId) await reloadStops()
    await refresh()
    $swal?.fire?.({ icon: 'success', title: 'Stops reordered to optimal sequence', toast: true, timer: 2000, position: 'top-end' })
  } catch (e) { console.error(e) }
}

// --- Bulk reload ---
async function reloadAll() { await Promise.all([refresh(), refreshAssign()]) }
function clearFilters() { search.value = ''; statusFilter.value = null; priorityFilter.value = null; driverFilter.value = null }
</script>

<style scoped>
.page-header { display:flex; align-items:flex-start; justify-content:space-between; gap:12px; flex-wrap:wrap; }
.filter-bar { flex-wrap:wrap; }
.dispatch-tabs :deep(.v-tab) { text-transform: none; font-weight: 600; }
.cursor-pointer { cursor: pointer; }
</style>
