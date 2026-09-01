<template>
  <div class="d-flex flex-column ga-4">
    <!-- Page header -->
    <div class="page-header">
      <div>
        <h1 class="text-h5 font-weight-bold d-flex align-center ga-2">
          <v-icon color="primary">mdi-garage-variant</v-icon>
          Garage
        </h1>
        <p class="text-caption text-medium-emphasis">Manage garage bays, track availability, and schedule vehicle service reservations across your workshop.</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn variant="outlined" prepend-icon="mdi-refresh" @click="reloadAll" :loading="pending">Refresh</v-btn>
        <v-btn v-can="'garage:create'" variant="tonal" color="deep-purple" prepend-icon="mdi-database-plus" @click="seedDemo" :loading="seeding">
          <span class="hidden-sm-and-down">Seed Demo Data</span>
        </v-btn>
        <v-btn v-can="'garage:create'" color="primary" prepend-icon="mdi-plus" @click="openCreateBay">
          <span class="hidden-sm-and-down">Add Bay</span>
        </v-btn>
      </div>
    </div>

    <!-- Analytics -->
    <GarageAnalytics
      :bay-stats="bayStats"
      :res-stats="resStats"
      :bays="bays"
      @filter-bay-status="setBayStatusFilter"
      @filter-res-status="setResStatusFilter"
      @filter-bay="setBayFilter"
    />

    <!-- Filters bar -->
    <div class="d-flex flex-wrap align-center ga-2 filter-bar">
      <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Search garage…" density="compact" hide-details variant="outlined" style="max-width:260px" clearable />
      <v-select v-model="bayTypeFilter" :items="bayTypeOptions" item-title="label" item-value="value" placeholder="All Bay Types" density="compact" hide-details variant="outlined" clearable style="max-width:160px" />
      <v-select v-model="resStatusFilter" :items="resStatusOptions" item-title="label" item-value="value" placeholder="All Res. Status" density="compact" hide-details variant="outlined" clearable style="max-width:160px" />
      <v-select v-model="bayFilter" :items="bays" item-title="name" item-value="name" placeholder="All Bays" density="compact" hide-details variant="outlined" clearable style="max-width:180px" />
      <v-btn v-if="hasFilters" variant="text" size="small" prepend-icon="mdi-filter-remove" @click="clearFilters">Clear</v-btn>
      <v-spacer />
      <div class="text-caption text-medium-emphasis">
        <span v-if="tab === 'bays'">{{ filteredBays.length }} of {{ bays.length }} bays</span>
        <span v-else>{{ filteredReservations.length }} of {{ reservations.length }} reservations</span>
      </div>
      <v-btn v-can="'garage:create'" color="primary" variant="outlined" prepend-icon="mdi-calendar-plus" size="small" @click="openCreateRes">New Reservation</v-btn>
    </div>

    <!-- Tabs -->
    <v-tabs v-model="tab" color="primary" density="compact" class="gar-tabs">
      <v-tab value="bays" prepend-icon="mdi-view-column-outline">Bays Board</v-tab>
      <v-tab value="schedule" prepend-icon="mdi-calendar-clock">Schedule</v-tab>
      <v-tab value="records" prepend-icon="mdi-format-list-bulleted">Records</v-tab>
      <v-tab value="timeline" prepend-icon="mdi-timeline-text-outline">Timeline</v-tab>
    </v-tabs>

    <v-window v-model="tab" class="flex-grow-1">
      <!-- BAYS BOARD -->
      <v-window-item value="bays">
        <GarageScheduleBoard :bays="filteredBays" @open-bay="openBayDetail" />
      </v-window-item>

      <!-- SCHEDULE (data table of reservations) -->
      <v-window-item value="schedule">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="resHeaders" :items="filteredReservations" :loading="resPending" hover density="compact" :search="search">
            <template #item.id="{ value }"><span class="font-weight-medium text-primary">#{{ value }}</span></template>
            <template #item.bay_name="{ item }">
              <div class="cursor-pointer" @click="openResDetail(item)">
                <p class="font-weight-medium">{{ item.bay_name }}</p>
                <p class="text-caption text-medium-emphasis">{{ item.vehicle_name }}</p>
              </div>
            </template>
            <template #item.status="{ value }">
              <v-chip :color="resStatusColor(value)" variant="flat" size="small" class="text-capitalize">
                <v-icon start size="14">{{ resStatusIcon(value) }}</v-icon>{{ value }}
              </v-chip>
            </template>
            <template #item.start_time="{ value }">{{ fmtDT(value) }}</template>
            <template #item.end_time="{ value }">{{ fmtDT(value) }}</template>
            <template #item.duration_hours="{ value }"><span class="font-weight-medium">{{ value }}h</span></template>
            <template #item.actions="{ item }">
              <v-menu>
                <template #activator="{ props: p }">
                  <v-btn icon="mdi-dots-vertical" variant="text" size="small" v-bind="p" />
                </template>
                <v-list density="compact">
                  <v-list-item prepend-icon="mdi-eye-outline" @click="openResDetail(item)">View Details</v-list-item>
                  <v-list-item v-can="'garage:update'" prepend-icon="mdi-pencil" @click="openEditRes(item)">Edit</v-list-item>
                  <v-list-item v-can="'garage:update'" v-if="item.status === 'scheduled'" prepend-icon="mdi-play" @click="setResStatus(item, 'active')">Activate</v-list-item>
                  <v-list-item v-can="'garage:update'" v-if="item.status === 'active'" prepend-icon="mdi-check-circle" @click="setResStatus(item, 'completed')">Complete</v-list-item>
                  <v-list-item v-can="'garage:update'" v-if="item.status !== 'cancelled'" prepend-icon="mdi-cancel" @click="setResStatus(item, 'cancelled')">Cancel</v-list-item>
                  <v-list-item v-can="'garage:delete'" prepend-icon="mdi-trash-can-outline" base-color="error" @click="deleteRes(item)">Delete</v-list-item>
                </v-list>
              </v-menu>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-calendar-clock</v-icon>
                <p>No reservations yet. Click <b>Seed Demo Data</b> or <b>New Reservation</b> to get started.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>

      <!-- RECORDS (bays table) -->
      <v-window-item value="records">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="bayHeaders" :items="filteredBays" :loading="pending" hover density="compact" :search="search">
            <template #item.name="{ item }">
              <div class="cursor-pointer" @click="openBayDetail(item)">
                <p class="font-weight-medium">{{ item.name }}</p>
              </div>
            </template>
            <template #item.bay_type="{ value }">
              <v-chip :color="bayTypeColor(value)" variant="tonal" size="small">
                <v-icon start size="14">{{ bayTypeIcon(value) }}</v-icon>{{ bayTypeLabel(value) }}
              </v-chip>
            </template>
            <template #item.is_occupied="{ value }">
              <v-chip v-if="value" color="error" variant="flat" size="small"><v-icon start size="14">mdi-car-connected</v-icon>Occupied</v-chip>
              <v-chip v-else color="success" variant="flat" size="small"><v-icon start size="14">mdi-check-circle</v-icon>Available</v-chip>
            </template>
            <template #item.is_active="{ value }">
              <v-icon :color="value ? 'success' : 'grey-lighten-2'" :icon="value ? 'mdi-check-circle' : 'mdi-close-circle'" size="small" />
            </template>
            <template #item.actions="{ item }">
              <v-menu>
                <template #activator="{ props: p }">
                  <v-btn icon="mdi-dots-vertical" variant="text" size="small" v-bind="p" />
                </template>
                <v-list density="compact">
                  <v-list-item prepend-icon="mdi-eye-outline" @click="openBayDetail(item)">View Details</v-list-item>
                  <v-list-item v-can="'garage:update'" prepend-icon="mdi-pencil" @click="openEditBay(item)">Edit</v-list-item>
                  <v-list-item v-can="'garage:delete'" prepend-icon="mdi-trash-can-outline" base-color="error" @click="deleteBay(item)">Delete</v-list-item>
                </v-list>
              </v-menu>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-garage-variant</v-icon>
                <p>No garage bays yet. Click <b>Seed Demo Data</b> or <b>Add Bay</b> to get started.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>

      <!-- TIMELINE -->
      <v-window-item value="timeline">
        <v-card elevation="0" border rounded="lg">
          <v-card-text>
            <div v-if="!filteredReservations.length" class="text-center py-12 text-medium-emphasis">
              <v-icon size="48" class="mb-3">mdi-timeline-text-outline</v-icon>
              <p>No reservations to show.</p>
            </div>
            <v-timeline v-else side="end" density="compact">
              <v-timeline-item v-for="r in timelineReservations" :key="r.id" :dot-color="resStatusColor(r.status)" size="small" fill-dot>
                <template #opposite>
                  <span class="text-caption text-medium-emphasis">{{ fmtDate(r.start_time) }}</span>
                </template>
                <v-card elevation="0" border class="pa-3 cursor-pointer" @click="openResDetail(r)">
                  <div class="d-flex align-start justify-space-between">
                    <div class="flex-grow-1">
                      <div class="d-flex align-center ga-2 mb-1">
                        <p class="font-weight-medium">{{ r.bay_name }}</p>
                        <v-chip :color="resStatusColor(r.status)" variant="flat" size="x-small" class="text-capitalize">{{ r.status }}</v-chip>
                      </div>
                      <p class="text-caption text-medium-emphasis">{{ r.vehicle_name }} · {{ r.duration_hours }}h · {{ fmtDT(r.start_time) }} → {{ fmtDT(r.end_time) }}</p>
                      <div v-if="r.notes" class="d-flex align-center ga-1 mt-1">
                        <span class="text-caption text-medium-emphasis"><v-icon size="12">mdi-note</v-icon> {{ r.notes.substring(0, 60) }}{{ r.notes.length > 60 ? '…' : '' }}</span>
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

    <!-- Bay Form Dialog -->
    <GarageBayFormDialog
      ref="bayFormRef"
      v-model="bayDialog"
      :editing="editingBay"
      :saving="saving"
      @save="saveBay"
    />

    <!-- Reservation Form Dialog -->
    <ReservationFormDialog
      ref="resFormRef"
      v-model="resDialog"
      :editing="editingRes"
      :saving="saving"
      :bay-options="bays"
      :vehicle-options="vehicleOptions"
      @save="saveRes"
    />

    <!-- Reservation Detail Drawer -->
    <ReservationDetailDrawer
      v-model="drawerOpen"
      :reservation="selectedReservation"
      @edit="openEditRes"
      @delete="deleteRes"
      @set-status="onSetResStatus"
    />
  </div>
</template>

<script setup lang="ts">
import GarageBayFormDialog from '~/components/garage/GarageBayFormDialog.vue'
import ReservationFormDialog from '~/components/garage/ReservationFormDialog.vue'
import GarageScheduleBoard from '~/components/garage/GarageScheduleBoard.vue'
import GarageAnalytics from '~/components/garage/GarageAnalytics.vue'
import ReservationDetailDrawer from '~/components/garage/ReservationDetailDrawer.vue'

const { $api } = useNuxtApp()
const route = useRoute()
const router = useRouter()

/* ─── refs for dialog components ─── */
const bayFormRef = ref()
const resFormRef = ref()

/* ─── state ─── */
const tab = ref('bays')
const saving = ref(false)
const seeding = ref(false)
const bayDialog = ref(false)
const resDialog = ref(false)
const drawerOpen = ref(false)
const editingBay = ref(false)
const editingRes = ref(false)
const selectedReservation = ref<any>(null)
const search = ref('')
const bayTypeFilter = ref('')
const resStatusFilter = ref('')
const bayFilter = ref('')

/* ─── options ─── */
const bayTypeOptions = [
  { label: 'Lift', value: 'lift' }, { label: 'Flat', value: 'flat' }, { label: 'Paint', value: 'paint' },
  { label: 'Wash', value: 'wash' }, { label: 'Inspection', value: 'inspection' }, { label: 'General', value: 'general' },
]
const resStatusOptions = [
  { label: 'Scheduled', value: 'scheduled' }, { label: 'Active', value: 'active' },
  { label: 'Completed', value: 'completed' }, { label: 'Cancelled', value: 'cancelled' },
]

/* ─── headers ─── */
const bayHeaders = [
  { title: 'Bay', key: 'name', sortable: true },
  { title: 'Type', key: 'bay_type', sortable: true, width: '140px' },
  { title: 'Capacity', key: 'capacity', sortable: true, width: '100px' },
  { title: 'Status', key: 'is_occupied', width: '120px' },
  { title: 'Active', key: 'is_active', width: '80px' },
  { title: 'Notes', key: 'notes' },
  { title: '', key: 'actions', width: '60px', sortable: false },
]
const resHeaders = [
  { title: 'ID', key: 'id', width: '60px' },
  { title: 'Bay / Vehicle', key: 'bay_name', sortable: true, width: '200px' },
  { title: 'Status', key: 'status', width: '120px' },
  { title: 'Start', key: 'start_time', sortable: true, width: '160px' },
  { title: 'End', key: 'end_time', sortable: true, width: '160px' },
  { title: 'Duration', key: 'duration_hours', width: '90px' },
  { title: '', key: 'actions', width: '60px', sortable: false },
]

/* ─── data ─── */
const { data: bayData, pending: bayPending, refresh: refreshBays } = useAsyncData('garage-bays', () => $api('/garage/bays/?page_size=1000'), { default: () => ({ results: [] }) })
const bays = computed<any[]>(() => bayData.value?.results || bayData.value || [])
const { data: bayStatsData, refresh: refreshBayStats } = useAsyncData('garage-bay-stats', () => $api('/garage/bays/stats/'), { default: () => ({}) })
const bayStats = computed(() => bayStatsData.value || {})
const { data: vehicleData } = useAsyncData('garage-vehicles', () => $api('/vehicles/vehicles/?page_size=500'), { default: () => ({ results: [] }) })
const vehicleOptions = computed<any[]>(() => vehicleData.value?.results || [])
const { data: resData, pending: resPending, refresh: refreshRes } = useAsyncData('garage-res', () => $api('/garage/reservations/?page_size=1000'), { default: () => ({ results: [] }) })
const reservations = computed<any[]>(() => resData.value?.results || resData.value || [])
const { data: resStatsData, refresh: refreshResStats } = useAsyncData('garage-res-stats', () => $api('/garage/reservations/stats/'), { default: () => ({}) })
const resStats = computed(() => resStatsData.value || {})

const pending = computed(() => bayPending.value || resPending.value)

/* ─── filters ─── */
const filteredBays = computed(() => {
  let list = bays.value
  if (bayTypeFilter.value) list = list.filter(b => b.bay_type === bayTypeFilter.value)
  if (search.value) {
    const q = search.value.toLowerCase()
    list = list.filter(b => b.name?.toLowerCase().includes(q) || b.notes?.toLowerCase().includes(q))
  }
  return list
})
const filteredReservations = computed(() => {
  let list = reservations.value
  if (resStatusFilter.value) list = list.filter(r => r.status === resStatusFilter.value)
  if (bayFilter.value) list = list.filter(r => r.bay_name === bayFilter.value)
  if (search.value) {
    const q = search.value.toLowerCase()
    list = list.filter(r => r.bay_name?.toLowerCase().includes(q) || r.vehicle_name?.toLowerCase().includes(q) || r.notes?.toLowerCase().includes(q))
  }
  return list
})
const timelineReservations = computed(() => [...filteredReservations.value].sort((a, b) => new Date(b.start_time).getTime() - new Date(a.start_time).getTime()))
const hasFilters = computed(() => !!search.value || !!bayTypeFilter.value || !!resStatusFilter.value || !!bayFilter.value)
function clearFilters() { search.value = ''; bayTypeFilter.value = ''; resStatusFilter.value = ''; bayFilter.value = '' }

/* ─── filter setters from analytics ─── */
function setBayStatusFilter(v: string) { resStatusFilter.value = v; tab.value = 'schedule' }
function setResStatusFilter(v: string) { resStatusFilter.value = v; tab.value = 'schedule' }
function setBayFilter(name: string) { bayFilter.value = bayFilter.value === name ? '' : name; tab.value = 'schedule' }

/* ─── helpers ─── */
function bayTypeColor(t: string) { return ({ lift: 'indigo', flat: 'grey', paint: 'purple', wash: 'cyan', inspection: 'orange', general: 'blue-grey' } as any)[t] || 'grey' }
function bayTypeIcon(t: string) { return ({ lift: 'mdi-elevator-passenger', flat: 'mdi-square-outline', paint: 'mdi-spray', wash: 'mdi-car-wash', inspection: 'mdi-magnify-scan', general: 'mdi-garage-open' } as any)[t] || 'mdi-garage-open' }
function bayTypeLabel(t: string) { return ({ lift: 'Lift', flat: 'Flat', paint: 'Paint', wash: 'Wash', inspection: 'Inspection', general: 'General' } as any)[t] || t }
function resStatusColor(s: string) { return ({ scheduled: 'info', active: 'success', completed: 'grey', cancelled: 'error' } as any)[s] || 'grey' }
function resStatusIcon(s: string) { return ({ scheduled: 'mdi-clock-outline', active: 'mdi-play-circle', completed: 'mdi-check-circle', cancelled: 'mdi-cancel' } as any)[s] || 'mdi-clock' }
function fmtDT(v?: string) { return v ? new Date(v).toLocaleString([], { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : '—' }
function fmtDate(v?: string) { return v ? new Date(v).toLocaleDateString([], { month: 'short', day: 'numeric' }) : '—' }

/* ─── reload all ─── */
async function reloadAll() { await Promise.all([refreshBays(), refreshBayStats(), refreshRes(), refreshResStats()]) }

/* ─── seed demo ─── */
async function seedDemo() {
  const { $swal } = useNuxtApp() as any
  const res = await ($swal as any)?.fire?.({ icon: 'question', title: 'Seed Garage Demo Data?', text: 'This will create demo bays and reservations. Existing data will remain.', showCancelButton: true, confirmButtonText: 'Yes, seed it', cancelButtonText: 'Cancel' })
  if (res?.isDismissed) return
  seeding.value = true
  try {
    await $api('/garage/reservations/seed-demo/', { method: 'POST' })
    await reloadAll()
    ;(useNuxtApp() as any).$swal?.fire?.({ icon: 'success', title: 'Demo data seeded', toast: true, timer: 1500, position: 'top-end' })
  } catch (e) { console.error(e) } finally { seeding.value = false }
}

/* ─── Bay create/edit ─── */
function openCreateBay() { editingBay.value = false; bayFormRef.value?.reset(); bayDialog.value = true }
function openEditBay(bay: any) { editingBay.value = true; bayFormRef.value?.reset(bay); bayDialog.value = true }
async function saveBay(form: any) {
  saving.value = true
  try {
    if (editingBay.value && form.id) {
      await $api(`/garage/bays/${form.id}/`, { method: 'PATCH', body: form })
    } else {
      await $api('/garage/bays/', { method: 'POST', body: form })
    }
    bayDialog.value = false
    await Promise.all([refreshBays(), refreshBayStats()])
    ;(useNuxtApp() as any).$swal?.fire?.({ icon: 'success', title: `Bay ${editingBay.value ? 'updated' : 'created'}`, toast: true, timer: 1500, position: 'top-end' })
  } catch (e) { console.error(e) } finally { saving.value = false }
}
async function deleteBay(bay: any) {
  const { $swal } = useNuxtApp() as any
  const r = await ($swal as any)?.fire?.({ icon: 'warning', title: 'Delete this bay?', text: 'This action cannot be undone.', showCancelButton: true, confirmButtonText: 'Delete', cancelButtonText: 'Cancel' })
  if (r?.isDismissed) return
  await $api(`/garage/bays/${bay.id}/`, { method: 'DELETE' })
  await Promise.all([refreshBays(), refreshBayStats()])
  ;(useNuxtApp() as any).$swal?.fire?.({ icon: 'success', title: 'Bay deleted', toast: true, timer: 1500, position: 'top-end' })
}

/* ─── Reservation create/edit ─── */
function openCreateRes() { editingRes.value = false; resFormRef.value?.reset(); resDialog.value = true }
function openEditRes(r: any) { editingRes.value = true; drawerOpen.value = false; resFormRef.value?.reset(r); resDialog.value = true }
async function saveRes(form: any) {
  saving.value = true
  try {
    const payload = { ...form, start_time: form.start_time ? new Date(form.start_time).toISOString() : null, end_time: form.end_time ? new Date(form.end_time).toISOString() : null }
    if (editingRes.value && form.id) {
      await $api(`/garage/reservations/${form.id}/`, { method: 'PATCH', body: payload })
    } else {
      await $api('/garage/reservations/', { method: 'POST', body: payload })
    }
    resDialog.value = false
    await Promise.all([refreshRes(), refreshResStats()])
    ;(useNuxtApp() as any).$swal?.fire?.({ icon: 'success', title: `Reservation ${editingRes.value ? 'updated' : 'created'}`, toast: true, timer: 1500, position: 'top-end' })
  } catch (e) { console.error(e) } finally { saving.value = false }
}
async function deleteRes(r: any) {
  const { $swal } = useNuxtApp() as any
  const res1 = await ($swal as any)?.fire?.({ icon: 'warning', title: 'Delete this reservation?', text: 'This action cannot be undone.', showCancelButton: true, confirmButtonText: 'Delete', cancelButtonText: 'Cancel' })
  if (res1?.isDismissed) return
  await $api(`/garage/reservations/${r.id}/`, { method: 'DELETE' })
  drawerOpen.value = false
  await Promise.all([refreshRes(), refreshResStats()])
  ;(useNuxtApp() as any).$swal?.fire?.({ icon: 'success', title: 'Reservation deleted', toast: true, timer: 1500, position: 'top-end' })
}
async function setResStatus(r: any, status: string) {
  await $api(`/garage/reservations/${r.id}/`, { method: 'PATCH', body: { status } })
  await Promise.all([refreshRes(), refreshResStats()])
  ;(useNuxtApp() as any).$swal?.fire?.({ icon: 'success', title: `Marked ${status}`, toast: true, timer: 1500, position: 'top-end' })
}
async function onSetResStatus({ reservation, status }: { reservation: any; status: string }) { await setResStatus(reservation, status) }

/* ─── Detail drawer ─── */
function openResDetail(r: any) { selectedReservation.value = r; drawerOpen.value = true }
function openBayDetail(bay: any) {
  bayFilter.value = bay.name
  tab.value = 'schedule'
}

/* ─── query param sync ─── */
onMounted(() => {
  const t = route.query.tab
  if (t) tab.value = String(t)
})
</script>

<style scoped>
.page-header { display: flex; align-items: flex-start; justify-content: space-between; gap: 16px; flex-wrap: wrap; }
.filter-bar { background: #f8fafc; padding: 8px 12px; border-radius: 12px; }
.gar-tabs :deep(.v-btn) { text-transform: none; letter-spacing: 0; font-weight: 500; }
.cursor-pointer { cursor: pointer; }
</style>
