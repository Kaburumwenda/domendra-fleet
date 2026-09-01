<template>
  <div class="d-flex flex-column ga-4">
    <!-- Page header -->
    <div class="page-header">
      <div>
        <h1 class="text-h5 font-weight-bold d-flex align-center ga-2">
          <v-icon color="primary">mdi-steering</v-icon>
          Drivers
        </h1>
        <p class="text-caption text-medium-emphasis">Manage driver records, licenses, MVR status, medical cards, violations, drug tests, training, and compliance.</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn variant="outlined" prepend-icon="mdi-refresh" @click="reloadAll" :loading="pending">Refresh</v-btn>
        <v-btn variant="tonal" color="deep-purple" prepend-icon="mdi-database-plus" @click="seedDemo" :loading="seeding">
          <span class="hidden-sm-and-down">Seed Demo Data</span>
        </v-btn>
        <v-btn v-can="'drivers:create'" color="primary" prepend-icon="mdi-plus" @click="openCreate">
          <span class="hidden-sm-and-down">Add Driver</span>
        </v-btn>
      </div>
    </div>

    <!-- Analytics -->
    <DriversAnalytics
      :stats="driverStats"
      :active-status-filter="filterStatus || ''"
      :active-mvr-filter="filterMvr || ''"
      :active-compliance-filter="complianceFilter"
      @filter-status="setStatusFilter"
      @filter-mvr="setMvrFilter"
      @filter-compliance="setComplianceFilter"
    />

    <!-- Filters bar -->
    <div class="d-flex flex-wrap align-center ga-2 filter-bar">
      <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Search drivers…" density="compact" hide-details variant="outlined" style="max-width:280px" clearable />
      <v-select v-model="filterStatus" :items="employmentStatuses" item-title="label" item-value="value" placeholder="All Statuses" density="compact" hide-details variant="outlined" clearable style="max-width:170px" />
      <v-select v-model="filterMvr" :items="mvrStatuses" item-title="label" item-value="value" placeholder="All MVR" density="compact" hide-details variant="outlined" clearable style="max-width:160px" />
      <v-select v-model="filterActive" :items="activeOptions" item-title="label" item-value="value" placeholder="All Active" density="compact" hide-details variant="outlined" clearable style="max-width:140px" />
      <v-btn v-if="hasFilters" variant="text" size="small" prepend-icon="mdi-filter-remove" @click="clearFilters">Clear</v-btn>
      <v-spacer />
      <div class="text-caption text-medium-emphasis">{{ filteredDrivers.length }} of {{ drivers.length }} drivers</div>
    </div>

    <!-- Tabs -->
    <v-tabs v-model="tab" color="primary" density="compact" class="rem-tabs">
      <v-tab value="all" prepend-icon="mdi-account-group-outline">All Drivers</v-tab>
      <v-tab value="compliance" prepend-icon="mdi-shield-alert-outline">Compliance Issues</v-tab>
      <v-tab value="active" prepend-icon="mdi-account-check-outline">Active Assignments</v-tab>
    </v-tabs>

    <v-window v-model="tab" class="flex-grow-1">
      <!-- ALL DRIVERS -->
      <v-window-item value="all">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="headers" :items="filteredDrivers" :loading="pending" :search="search" hover density="compact" items-per-page="15">
            <template #item.full_name="{ item }">
              <div class="d-flex align-center ga-2 cursor-pointer" @click="openDetail(item)">
                <div class="driver-avatar" :style="{ background: avatarColor(item) }">
                  <img v-if="item.photo" :src="resolveMediaUrl(item.photo)" :alt="item.full_name" />
                  <span v-else>{{ initials(item) }}</span>
                </div>
                <div>
                  <p class="text-body-2 font-weight-medium" style="color: #1e293b">{{ item.full_name }}</p>
                  <p class="text-caption text-medium-emphasis">{{ item.email || item.phone || '—' }}</p>
                </div>
              </div>
            </template>

            <template #item.employment_status="{ item }">
              <v-chip :color="employmentColor(item.driver_profile?.employment_status)" variant="tonal" size="small">
                <v-icon size="x-small" start>{{ employmentIcon(item.driver_profile?.employment_status) }}</v-icon>
                {{ employmentLabel(item.driver_profile?.employment_status) }}
              </v-chip>
            </template>

            <template #item.license="{ item }">
              <div v-if="item.driver_profile">
                <p class="text-body-2">{{ item.driver_profile.license_number || '—' }}</p>
                <p class="text-caption text-medium-emphasis">{{ item.driver_profile.license_class_label || item.driver_profile.license_class || '' }}</p>
              </div>
              <span v-else class="text-medium-emphasis">—</span>
            </template>

            <template #item.license_expiry="{ item }">
              <span v-if="item.driver_profile?.license_expiry" :class="expiryClass(item.driver_profile.license_expiry)">{{ fmtDate(item.driver_profile.license_expiry) }}</span>
              <span v-else class="text-medium-emphasis">—</span>
            </template>

            <template #item.medical_card_expiry="{ item }">
              <span v-if="item.driver_profile?.medical_card_expiry" :class="expiryClass(item.driver_profile.medical_card_expiry)">{{ fmtDate(item.driver_profile.medical_card_expiry) }}</span>
              <span v-else class="text-medium-emphasis">—</span>
            </template>

            <template #item.mvr_status="{ item }">
              <v-chip v-if="item.driver_profile" :color="mvrColor(item.driver_profile.mvr_status)" variant="flat" size="small">
                {{ item.driver_profile.mvr_status_label || item.driver_profile.mvr_status }}
              </v-chip>
              <span v-else class="text-medium-emphasis">—</span>
            </template>

            <template #item.hire_date="{ item }">
              <span>{{ fmtDate(item.driver_profile?.hire_date) }}</span>
            </template>

            <template #item.actions="{ item }">
              <v-menu>
                <template #activator="{ props: p }">
                  <v-btn icon="mdi-dots-vertical" variant="text" size="small" v-bind="p" />
                </template>
                <v-list density="compact">
                  <v-list-item prepend-icon="mdi-eye-outline" @click="openDetail(item)">View Details</v-list-item>
                  <v-list-item v-can="'drivers:update'" prepend-icon="mdi-pencil-outline" @click="goEdit(item)">Edit</v-list-item>
                  <v-list-item prepend-icon="mdi-open-in-new" @click="goDetailPage(item)">Full Page</v-list-item>
                  <v-list-item v-can="'drivers:delete'" prepend-icon="mdi-trash-can-outline" base-color="error" @click="deleteDriver(item)">Delete</v-list-item>
                </v-list>
              </v-menu>
            </template>

            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-steering</v-icon>
                <p>No drivers yet. Click <b>Seed Demo Data</b> or <b>Add Driver</b> to get started.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>

      <!-- COMPLIANCE ISSUES -->
      <v-window-item value="compliance">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="complianceHeaders" :items="complianceDrivers" :loading="pending" hover density="compact" items-per-page="15">
            <template #item.full_name="{ item }">
              <div class="d-flex align-center ga-2 cursor-pointer" @click="openDetail(item)">
                <div class="driver-avatar" :style="{ background: avatarColor(item) }">
                  <span>{{ initials(item) }}</span>
                </div>
                <div>
                  <p class="text-body-2 font-weight-medium" style="color: #1e293b">{{ item.full_name }}</p>
                  <p class="text-caption text-medium-emphasis">{{ item.employee_id || '—' }}</p>
                </div>
              </div>
            </template>
            <template #item.issues="{ item }">
              <div class="d-flex flex-wrap ga-1">
                <v-chip v-if="item.driver_profile?.license_is_expired" color="error" variant="tonal" size="small" prepend-icon="mdi-card-bulleted-outline">License Expired</v-chip>
                <v-chip v-else-if="isExpiringSoon(item.driver_profile?.license_expiry)" color="warning" variant="tonal" size="small" prepend-icon="mdi-clock-alert-outline">License Expiring</v-chip>
                <v-chip v-if="item.driver_profile?.medical_is_expired" color="error" variant="tonal" size="small" prepend-icon="mdi-heart-pulse">Med Card Expired</v-chip>
                <v-chip v-else-if="isExpiringSoon(item.driver_profile?.medical_card_expiry)" color="warning" variant="tonal" size="small" prepend-icon="mdi-clock-alert-outline">Med Card Expiring</v-chip>
                <v-chip v-if="item.driver_profile?.mvr_status === 'warning'" color="warning" variant="tonal" size="small" prepend-icon="mdi-shield-alert">MVR Warning</v-chip>
                <v-chip v-if="item.driver_profile?.mvr_status === 'suspended'" color="error" variant="tonal" size="small" prepend-icon="mdi-shield-off">MVR Suspended</v-chip>
                <v-chip v-if="item.driver_profile?.mvr_status === 'expired'" color="grey" variant="tonal" size="small" prepend-icon="mdi-shield-remove">MVR Expired</v-chip>
              </div>
            </template>
            <template #item.mvr_status="{ item }">
              <v-chip :color="mvrColor(item.driver_profile?.mvr_status)" variant="flat" size="small">
                {{ item.driver_profile?.mvr_status_label || item.driver_profile?.mvr_status || '—' }}
              </v-chip>
            </template>
            <template #item.actions="{ item }">
              <v-btn icon="mdi-eye-outline" variant="text" size="small" @click="openDetail(item)" />
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-shield-check-outline</v-icon>
                <p>No compliance issues. All drivers are up to date!</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>

      <!-- ACTIVE ASSIGNMENTS -->
      <v-window-item value="active">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="assignmentHeaders" :items="assignedDrivers" :loading="pending" hover density="compact" items-per-page="15">
            <template #item.full_name="{ item }">
              <div class="d-flex align-center ga-2 cursor-pointer" @click="openDetail(item)">
                <div class="driver-avatar" :style="{ background: avatarColor(item) }">
                  <span>{{ initials(item) }}</span>
                </div>
                <div>
                  <p class="text-body-2 font-weight-medium" style="color: #1e293b">{{ item.full_name }}</p>
                  <p class="text-caption text-medium-emphasis">{{ item.driver_profile?.home_terminal || '—' }}</p>
                </div>
              </div>
            </template>
            <template #item.vehicle="{ item }">
              <div class="d-flex align-center ga-2">
                <v-icon size="16">mdi-truck</v-icon>
                <span class="text-body-2 font-weight-medium">{{ activeVehicleLabel(item) }}</span>
              </div>
            </template>
            <template #item.assigned_at="{ item }">
              {{ fmtDate(activeAssignment(item)?.assigned_at) }}
            </template>
            <template #item.actions="{ item }">
              <v-btn icon="mdi-eye-outline" variant="text" size="small" @click="openDetail(item)" />
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-car-connected</v-icon>
                <p>No active vehicle assignments.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>
    </v-window>

    <!-- Detail drawer -->
    <DriverDetailDrawer
      v-model="drawerOpen"
      :driver="selectedDriver"
      @edit="goEdit"
      @delete="deleteDriver"
      @view-full="goDetailPage"
    />
  </div>
</template>

<script setup lang="ts">
import DriversAnalytics from '~/components/drivers/DriversAnalytics.vue'
import DriverDetailDrawer from '~/components/drivers/DriverDetailDrawer.vue'
import { useMediaUrl } from '~/composables/useMediaUrl'

definePageMeta({ layout: 'default' })
const { $api, $swal } = useNuxtApp() as any
const { resolveMediaUrl } = useMediaUrl()

/* ─── state ─── */
const tab = ref<'all' | 'compliance' | 'active'>('all')
const search = ref('')
const filterStatus = ref<string | null>(null)
const filterMvr = ref<string | null>(null)
const filterActive = ref<string | null>(null)
const complianceFilter = ref('')
const seeding = ref(false)
const drawerOpen = ref(false)
const selectedDriver = ref<any>(null)

const employmentStatuses = [
  { label: 'Active', value: 'active' },
  { label: 'On Leave', value: 'on_leave' },
  { label: 'Suspended', value: 'suspended' },
  { label: 'Terminated', value: 'terminated' },
  { label: 'Probation', value: 'probation' },
]
const mvrStatuses = [
  { label: 'Clean', value: 'clean' },
  { label: 'Warning', value: 'warning' },
  { label: 'Suspended', value: 'suspended' },
  { label: 'Expired', value: 'expired' },
]
const activeOptions = [
  { label: 'Yes', value: 'true' },
  { label: 'No', value: 'false' },
]

const headers = [
  { title: 'Driver', key: 'full_name', sortable: true },
  { title: 'Status', key: 'employment_status', sortable: true, width: '130px' },
  { title: 'License', key: 'license', width: '140px' },
  { title: 'License Exp.', key: 'license_expiry', width: '120px', sortable: true },
  { title: 'Med. Card', key: 'medical_card_expiry', width: '120px', sortable: true },
  { title: 'MVR', key: 'mvr_status', width: '110px', sortable: true },
  { title: 'Hire Date', key: 'hire_date', width: '120px', sortable: true },
  { title: '', key: 'actions', width: '50px', sortable: false },
]
const complianceHeaders = [
  { title: 'Driver', key: 'full_name', sortable: true },
  { title: 'Issues', key: 'issues' },
  { title: 'MVR', key: 'mvr_status', width: '120px' },
  { title: '', key: 'actions', width: '50px', sortable: false },
]
const assignmentHeaders = [
  { title: 'Driver', key: 'full_name', sortable: true },
  { title: 'Vehicle', key: 'vehicle' },
  { title: 'Assigned', key: 'assigned_at', width: '130px', sortable: true },
  { title: '', key: 'actions', width: '50px', sortable: false },
]

/* ─── data ─── */
const { data: driversData, pending, refresh } = useAsyncData('drivers-list', () =>
  $api('/contacts/drivers/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })),
  { default: () => ({ results: [] as any[] }) },
)
const drivers = computed<any[]>(() => driversData.value?.results || [])

const { data: statsData, refresh: refreshStats } = useAsyncData('drivers-stats', () =>
  $api('/contacts/drivers/stats/').catch(() => ({})),
  { default: () => ({}) },
)
const driverStats = computed(() => statsData.value || {})

/* ─── filters ─── */
const filteredDrivers = computed(() => {
  return drivers.value.filter((d: any) => {
    if (filterStatus.value && d.driver_profile?.employment_status !== filterStatus.value) return false
    if (filterMvr.value && d.driver_profile?.mvr_status !== filterMvr.value) return false
    if (filterActive.value === 'true' && !d.is_active) return false
    if (filterActive.value === 'false' && d.is_active) return false
    return true
  })
})

const hasFilters = computed(() => !!(search.value || filterStatus.value || filterMvr.value || filterActive.value))

const complianceDrivers = computed(() => {
  return drivers.value.filter((d: any) => {
    const p = d.driver_profile
    if (!p) return false
    if (p.license_is_expired) return true
    if (p.medical_is_expired) return true
    if (isExpiringSoon(p.license_expiry)) return true
    if (isExpiringSoon(p.medical_card_expiry)) return true
    if (p.mvr_status === 'warning') return true
    if (p.mvr_status === 'suspended') return true
    if (p.mvr_status === 'expired') return true
    return false
  })
})

const assignedDrivers = computed(() => {
  return drivers.value.filter((d: any) => {
    const assignments = d.driver_profile?.assignments || []
    return assignments.some((a: any) => a.is_active)
  })
})

function clearFilters() { search.value = ''; filterStatus.value = null; filterMvr.value = null; filterActive.value = null; complianceFilter.value = '' }
function setStatusFilter(v: string) {
  if (v === '') { filterStatus.value = null; return }
  filterStatus.value = filterStatus.value === v ? null : v
}
function setMvrFilter(v: string) {
  filterMvr.value = filterMvr.value === v ? null : v
  if (v === 'warning' || v === 'suspended' || v === 'expired') tab.value = 'compliance'
}
function setComplianceFilter(v: string) {
  complianceFilter.value = complianceFilter.value === v ? '' : v
  tab.value = 'compliance'
}

/* ─── helpers ─── */
function initials(d: any) {
  return ((d.first_name?.[0] || '') + (d.last_name?.[0] || '')).toUpperCase() || '?'
}
function avatarColor(d: any) {
  const colors = ['#e0e7ff', '#dcfce7', '#fef9c3', '#fee2e2', '#f3e8ff', '#cffafe']
  return colors[(d.first_name?.charCodeAt(0) || 0) % colors.length]
}
function employmentColor(s?: string) {
  return ({ active: 'success', on_leave: 'info', suspended: 'warning', terminated: 'grey', probation: 'amber' } as any)[s || ''] || 'grey'
}
function employmentIcon(s?: string) {
  return ({ active: 'mdi-check-circle', on_leave: 'mdi-pause-circle', suspended: 'mdi-alert-circle', terminated: 'mdi-close-circle', probation: 'mdi-clock-alert' } as any)[s || ''] || 'mdi-help-circle'
}
function employmentLabel(s?: string) {
  return employmentStatuses.find(e => e.value === s)?.label || s || '—'
}
function mvrColor(s?: string) {
  return ({ clean: 'success', warning: 'warning', suspended: 'error', expired: 'grey' } as any)[s || ''] || 'grey'
}
function fmtDate(v?: string) { return v ? new Date(v).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' }) : '—' }
function expiryClass(dateStr?: string) {
  if (!dateStr) return ''
  const d = new Date(dateStr)
  const now = new Date()
  const days = (d.getTime() - now.getTime()) / 86400000
  if (days < 0) return 'text-error font-weight-medium'
  if (days < 30) return 'text-warning font-weight-medium'
  return ''
}
function isExpiringSoon(dateStr?: string) {
  if (!dateStr) return false
  const d = new Date(dateStr)
  const now = new Date()
  const days = (d.getTime() - now.getTime()) / 86400000
  return days >= 0 && days < 30
}
function activeAssignment(d: any) {
  return (d.driver_profile?.assignments || []).find((a: any) => a.is_active)
}
function activeVehicleLabel(d: any) {
  const a = activeAssignment(d)
  return a?.vehicle_label || 'Unassigned'
}

/* ─── reload all ─── */
async function reloadAll() { await Promise.all([refresh(), refreshStats()]) }

/* ─── seed demo ─── */
async function seedDemo() {
  const r = await $swal?.fire?.({ icon: 'question', title: 'Seed driver demo data?', text: 'This will create 8 sample drivers with violations, drug tests, trainings, HOS logs, and notes.', showCancelButton: true, confirmButtonText: 'Seed Data' })
  if (!r?.isConfirmed) return
  seeding.value = true
  try {
    const res = await $api('/contacts/drivers/seed_demo/', { method: 'POST' })
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: res?.detail || 'Demo data seeded', toast: true, timer: 2000, position: 'top-end' })
  } catch (e: any) {
    console.error(e)
    $swal?.fire?.({ icon: 'error', title: e?.response?._data?.detail || 'Failed to seed data', toast: true, timer: 3000, position: 'top-end' })
  } finally { seeding.value = false }
}

/* ─── actions ─── */
function openCreate() { navigateTo('/app/drivers/new') }
function goEdit(d: any) { drawerOpen.value = false; navigateTo(`/app/drivers/${d.id}/edit`) }
function goDetailPage(d: any) { drawerOpen.value = false; navigateTo(`/app/drivers/${d.id}`) }
function openDetail(d: any) { selectedDriver.value = d; drawerOpen.value = true }

async function deleteDriver(d: any) {
  const res = await $swal?.fire?.({ icon: 'warning', title: 'Delete driver?', text: `"${d.full_name}" will be permanently removed.`, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!res?.isConfirmed) return
  try {
    await $api(`/contacts/drivers/${d.id}/`, { method: 'DELETE' })
    drawerOpen.value = false
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: 'Driver deleted', toast: true, timer: 1500, position: 'top-end' })
  } catch (e: any) {
    console.error(e)
    $swal?.fire?.({ icon: 'error', title: 'Delete failed', toast: true, timer: 2000, position: 'top-end' })
  }
}
</script>

<style scoped>
.page-header { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
.filter-bar { flex-wrap: wrap; background: #f8fafc; padding: 8px 12px; border-radius: 12px; }
.rem-tabs :deep(.v-tab) { text-transform: none; font-weight: 600; }
.cursor-pointer { cursor: pointer; }
.driver-avatar { width: 38px; height: 38px; border-radius: 50%; display: flex; align-items: center; justify-content: center; overflow: hidden; flex-shrink: 0; font-weight: 700; font-size: 14px; }
.driver-avatar img { width: 100%; height: 100%; object-fit: cover; }
.driver-avatar span { font-size: 14px; font-weight: 700; color: #4338ca; }
</style>
