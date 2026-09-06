<template>
  <div class="d-flex flex-column ga-4">
    <div class="d-flex align-center justify-space-between">
      <div class="d-flex align-center ga-2">
        <div class="fleet-count-badge">
          <v-icon size="16" color="white">mdi-car-multiple</v-icon>
          <span>{{ vehiclesData?.count || vehicles.length }}</span>
        </div>
        <span class="text-body-2 text-medium-emphasis">vehicles in fleet</span>
      </div>
      <v-btn v-can="'vehicles:create'" color="primary" prepend-icon="mdi-plus" to="/app/vehicles/new" class="add-vehicle-btn">Add Vehicle</v-btn>
    </div>

    <v-card elevation="0" border rounded="lg" class="vehicles-table-card">
      <div class="filters-bar d-flex flex-wrap align-center ga-3 pa-4">
        <v-text-field
          v-model="search"
          prepend-inner-icon="mdi-magnify"
          placeholder="Search vehicles..."
          density="compact"
          hide-details
          variant="outlined"
          style="min-width: 260px; max-width: 320px"
        />

        <v-select
          v-model="statusFilter"
          :items="statusOptions"
          item-title="label"
          item-value="value"
          label="Status"
          prepend-inner-icon="mdi-circle-medium"
          density="compact"
          hide-details
          clearable
          variant="outlined"
          style="min-width: 170px; max-width: 200px"
        />

        <v-select
          v-model="fuelFilter"
          :items="fuelOptions"
          label="Fuel"
          prepend-inner-icon="mdi-gas-station"
          density="compact"
          hide-details
          clearable
          variant="outlined"
          style="min-width: 170px; max-width: 200px"
        />

        <v-select
          v-model="groupFilter"
          :items="groupOptions"
          item-title="label"
          item-value="value"
          label="Group"
          prepend-inner-icon="mdi-folder-outline"
          density="compact"
          hide-details
          clearable
          variant="outlined"
          style="min-width: 170px; max-width: 200px"
        />

        <v-select
          v-model="locationFilter"
          :items="locationOptions"
          label="Location"
          prepend-inner-icon="mdi-map-marker-outline"
          density="compact"
          hide-details
          clearable
          variant="outlined"
          style="min-width: 170px; max-width: 220px"
        />

        <v-select
          v-model="rentalFilter"
          :items="rentalFilterOptions"
          item-title="label"
          item-value="value"
          label="Rental"
          prepend-inner-icon="mdi-car-key"
          density="compact"
          hide-details
          clearable
          variant="outlined"
          style="min-width: 150px; max-width: 180px"
        />

        <v-btn
          v-if="hasActiveFilters"
          variant="text"
          size="small"
          prepend-icon="mdi-filter-remove"
          @click="clearFilters"
        >Clear</v-btn>
      </div>

      <v-data-table-server
        :headers="headers"
        :items="displayVehicles"
        :items-length="totalCount"
        :loading="pending"
        :items-per-page="itemsPerPage"
        :items-per-page-options="[10, 20, 50]"
        v-model="selected"
        show-select
        hover
        @update:page="onPageChange"
        @update:items-per-page="onItemsPerPageChange"
      >
        <template #top>
          <div v-if="selected.length" class="d-flex align-center justify-end pa-4">
            <v-btn v-can="'vehicles:delete'" :label="`Delete (${selected.length})`" prepend-icon="mdi-trash-can-outline" color="error" variant="outlined" size="small" @click="bulkDelete" />
          </div>
        </template>

        <template #item.display_name="{ item }">
          <div class="d-flex align-center ga-3">
            <div class="vehicle-avatar" :style="vehicleAvatarStyle(item)">
              <img v-if="vehicleImageUrl(item)" :src="vehicleImageUrl(item)!" alt="Vehicle photo" class="vehicle-avatar__img" />
              <v-icon v-else size="16" color="white">{{ fuelIcon(item.fuel_type) }}</v-icon>
            </div>
            <div class="d-flex flex-column">
              <span class="font-weight-medium" style="color: #1e293b">{{ item.display_name }}</span>
              <span class="text-caption text-medium-emphasis">{{ item.vin }}</span>
            </div>
          </div>
        </template>

        <template #item.license_plate="{ value }">
          <v-chip variant="outlined" size="small" label class="font-weight-medium">{{ value || '—' }}</v-chip>
        </template>

        <template #item.status="{ value }">
          <div class="d-flex align-center ga-2">
            <span class="status-dot" :class="statusColor(value)" />
            <span class="text-capitalize text-body-2">{{ value.replace('_', ' ') }}</span>
          </div>
        </template>

        <template #item.rental_status="{ item }">
          <div v-if="item.rental_status === 'on_rent'" class="d-flex flex-column ga-1">
            <div class="d-flex align-center ga-2">
              <span class="status-dot assigned" />
              <span class="text-body-2 font-weight-medium">Assigned</span>
            </div>
            <span v-if="item.rental_agreement_no" class="text-caption text-medium-emphasis">
              {{ item.rental_agreement_no }}<span v-if="item.rental_customer_name"> · {{ item.rental_customer_name }}</span>
            </span>
          </div>
          <div v-else class="d-flex align-center ga-2">
            <span class="status-dot available" />
            <span class="text-body-2 text-medium-emphasis">Available</span>
          </div>
        </template>

        <template #item.fuel_type="{ value }">
          <v-chip size="small" variant="tonal" color="primary">{{ value || '—' }}</v-chip>
        </template>

        <template #item.current_mileage="{ item }">
          <span class="text-body-2">{{ item.current_mileage?.toLocaleString() }} <span class="text-medium-emphasis">{{ item.mileage_unit === 'miles' ? 'mi' : 'km' }}</span></span>
        </template>

        <template #item.ownership="{ item }">
          <div class="d-flex flex-column ga-1">
            <v-chip :color="item.ownership === 'lease' ? 'purple' : 'success'" variant="flat" size="small" class="text-capitalize">{{ item.ownership === 'lease' ? 'Leased' : 'Owned' }}</v-chip>
            <span v-if="item.ownership === 'lease' && item.lease_end_date" class="text-caption ownership-countdown" :class="leaseCountdownClass(item.lease_end_date)">
              {{ leaseCountdownLabel(item.lease_end_date) }}
            </span>
          </div>
        </template>

        <template #item.group_name="{ value }">
          <span class="text-body-2">{{ value || '—' }}</span>
        </template>

        <template #item.location="{ value }">
          <div class="d-flex align-center ga-2 text-body-2">
            <v-icon size="16" color="text-medium-emphasis" class="me-1">mdi-map-marker-outline</v-icon>
            <span>{{ value || '—' }}</span>
          </div>
        </template>

        <template #item.actions="{ item }">
          <div class="d-flex ga-1 action-row">
            <v-btn icon="mdi-eye-outline" variant="text" size="small" @click="openView(item)" />
            <v-btn v-can="'vehicles:update'" icon="mdi-pencil-outline" variant="text" size="small" @click="openEdit(item)" />
            <v-btn v-can="'vehicles:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deleteVehicle(item)" />
          </div>
        </template>

        <template #no-data>
          <div class="text-center py-12 text-medium-emphasis">
            <v-icon size="48" class="mb-3">mdi-car</v-icon>
            <p>No vehicles found. Click "Add Vehicle" to get started.</p>
          </div>
        </template>
      </v-data-table-server>

      <div class="d-flex align-center justify-space-between pa-3 pt-0 flex-wrap ga-2">
        <span class="text-caption text-medium-emphasis">
          Showing {{ vehicles.length }} of {{ totalCount }} vehicles
          <span v-if="hasActiveFilters">· filtered</span>
        </span>
      </div>
    </v-card>
  </div>
</template>

<script setup lang="ts">
const { $api, $swal } = useNuxtApp()

const search = ref('')
const debouncedSearch = ref('')
const selected = ref<any[]>([])
const statusFilter = ref<string | null>(null)
const fuelFilter = ref<string | null>(null)
const groupFilter = ref<number | null>(null)
const locationFilter = ref<string | null>(null)
const rentalFilter = ref<string | null>(null)

// ── Server-side pagination state ──
const page = ref(1)
const itemsPerPage = ref(20)

// Debounce search input
let searchTimer: ReturnType<typeof setTimeout> | null = null
watch(search, (val) => {
  if (searchTimer) clearTimeout(searchTimer)
  searchTimer = setTimeout(() => {
    debouncedSearch.value = val
  }, 400)
})

function buildQuery() {
  const q: Record<string, any> = { page: page.value, page_size: itemsPerPage.value }
  if (debouncedSearch.value.trim()) q.search = debouncedSearch.value.trim()
  if (statusFilter.value) q.status = statusFilter.value
  if (fuelFilter.value) q.fuel_type = fuelFilter.value
  if (groupFilter.value) q.group = groupFilter.value
  // location & rental are not backend filter fields, so they're handled client-side
  return q
}

function onPageChange(newPage: number) {
  page.value = newPage
}

function onItemsPerPageChange(newSize: number) {
  itemsPerPage.value = newSize
  page.value = 1
}

const rentalFilterOptions = [
  { value: 'on_rent', label: 'Assigned' },
  { value: 'available', label: 'Available' },
]

const headers = [
  { title: 'Vehicle', key: 'display_name', sortable: true, width: '260px' },
  { title: 'Plate', key: 'license_plate', sortable: true, width: '130px' },
  { title: 'Status', key: 'status', sortable: true, width: '150px' },
  { title: 'Rental', key: 'rental_status', sortable: true, width: '150px' },
  { title: 'Fuel', key: 'fuel_type', sortable: true, width: '110px' },
  { title: 'Mileage', key: 'current_mileage', sortable: true, width: '140px' },
  { title: 'Ownership', key: 'ownership', sortable: true, width: '110px' },
  { title: 'Group', key: 'group_name', sortable: true, width: '120px' },
  { title: 'Location', key: 'location', sortable: true, width: '160px' },
  { title: '', key: 'actions', width: '130px', sortable: false },
]

const { data: vehiclesData, pending, refresh } = useAsyncData('vehicles', () =>
  $api('/vehicles/vehicles/', { query: buildQuery() }),
  {
    default: () => ({ results: [], count: 0 }),
    watch: [page, itemsPerPage, debouncedSearch, statusFilter, fuelFilter, groupFilter],
  },
)
const vehicles = computed(() => vehiclesData.value?.results || [])
const totalCount = computed(() => vehiclesData.value?.count || 0)

const { data: groupsData } = useAsyncData('vehicle-groups-filter', () =>
  $api('/vehicles/groups/').catch(() => ({ results: [], count: 0 })),
)
const groupOptions = computed(() =>
  (groupsData.value?.results || []).map((g: any) => ({ label: g.name, value: g.id }))
    .sort((a, b) => a.label.localeCompare(b.label))
)

const { data: locationsData } = useAsyncData('locations-filter', () =>
  $api('/locations/').catch(() => ({ results: [], count: 0 })),
)
const locationOptions = computed(() =>
  (locationsData.value?.results || []).map((l: any) => l.name)
    .sort((a, b) => String(a).localeCompare(String(b)))
)

const statusOptions = [
  { value: 'active', label: 'Active' },
  { value: 'out_of_service', label: 'Out of Service' },
  { value: 'in_maintenance', label: 'In Maintenance' },
  { value: 'retired', label: 'Retired' },
]

const fuelOptions = [
  'Petrol',
  'Diesel',
  'Hybrid (Petrol)',
  'Hybrid (Diesel)',
  'Plug-in Hybrid (Petrol)',
  'Plug-in Hybrid (Diesel)',
  'Mild Hybrid',
  'Electric',
  'Fuel Cell (Hydrogen)',
  'LPG',
  'CNG',
  'LNG',
  'Ethanol (E85)',
  'Flex Fuel',
  'Biodiesel',
]

const hasActiveFilters = computed(() =>
  Boolean(statusFilter.value || fuelFilter.value || groupFilter.value || locationFilter.value || rentalFilter.value)
)

function clearFilters() {
  statusFilter.value = null
  fuelFilter.value = null
  groupFilter.value = null
  locationFilter.value = null
  rentalFilter.value = null
  page.value = 1
}

// Location & rental filters are not backend-supported, so filter client-side
// on top of the server-returned page
const displayVehicles = computed(() => {
  const location = locationFilter.value
  const rental = rentalFilter.value
  if (!location && !rental) return vehicles.value
  return vehicles.value.filter((v: any) => {
    if (location && v.location !== location) return false
    if (rental && v.rental_status !== rental) return false
    return true
  })
})

// Reset to page 1 when search or backend filters change
watch([debouncedSearch, statusFilter, fuelFilter, groupFilter], () => {
  page.value = 1
})

function openView(v: any) {
  navigateTo(`/app/vehicles/${v.id}`)
}

function openEdit(v: any) {
  navigateTo(`/app/vehicles/${v.id}/edit`)
}

async function deleteVehicle(v: any) {
  const { isConfirmed } = await $swal.fire({
    title: 'Delete Vehicle',
    text: `Delete ${v.display_name}?`,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Delete',
    cancelButtonText: 'Cancel',
  })
  if (!isConfirmed) return
  await $api(`/vehicles/vehicles/${v.id}/`, { method: 'DELETE' })
  await refresh()
}

async function bulkDelete() {
  const { isConfirmed } = await $swal.fire({
    title: 'Delete Vehicles',
    text: `Delete ${selected.value.length} vehicles?`,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Delete',
    cancelButtonText: 'Cancel',
  })
  if (!isConfirmed) return
  for (const v of selected.value) {
    await $api(`/vehicles/vehicles/${v.id}/`, { method: 'DELETE' })
  }
  selected.value = []
  await refresh()
}

function statusColor(status: string) {
  return { active: 'success', out_of_service: 'warning', in_maintenance: 'info', retired: 'grey' }[status] || 'grey'
}

function leaseCountdownDays(endDate: any): number | null {
  if (!endDate) return null
  const end = new Date(endDate)
  if (isNaN(end.getTime())) return null
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  end.setHours(0, 0, 0, 0)
  return Math.round((end.getTime() - today.getTime()) / 86400000)
}

function leaseCountdownLabel(endDate: any): string {
  const days = leaseCountdownDays(endDate)
  if (days === null) return ''
  if (days === 0) return 'Ends today'
  if (days > 0) return `${days}d left`
  return `Expired ${Math.abs(days)}d ago`
}

function leaseCountdownClass(endDate: any): string {
  const days = leaseCountdownDays(endDate)
  if (days === null) return 'text-medium-emphasis'
  if (days < 0) return 'text-error font-weight-medium'
  if (days <= 30) return 'text-warning font-weight-medium'
  return 'text-success'
}

function fuelIcon(fuel: string) {
  const f = (fuel || '').toString().toLowerCase()
  if (/electric|^ev$/.test(f)) return 'mdi-flash'
  if (/hybrid/.test(f)) return 'mdi-flash'
  if (/diesel/.test(f)) return 'mdi-gauge'
  return 'mdi-car'
}

const _gradients = [
  'linear-gradient(135deg,#6366f1,#4f46e5)',
  'linear-gradient(135deg,#0ea5e9,#2563eb)',
  'linear-gradient(135deg,#10b981,#059669)',
  'linear-gradient(135deg,#f59e0b,#d97706)',
  'linear-gradient(135deg,#ec4899,#db2777)',
  'linear-gradient(135deg,#8b5cf6,#7c3aed)',
  'linear-gradient(135deg,#06b6d4,#0891b2)',
]
function avatarGradient(item: any) {
  const id = item?.id || 0
  return _gradients[id % _gradients.length]
}

function vehicleImageUrl(item: any): string {
  const url = item?.image
  if (!url) return ''
  if (/^https?:\/\//i.test(url)) return url
  const base = (useRuntimeConfig().public.apiBase || '').replace(/\/api\/?$/, '')
  return `${base}/${url.replace(/^\/+/, '')}`
}

function vehicleAvatarStyle(item: any) {
  return vehicleImageUrl(item)
    ? { background: 'transparent' }
    : { background: avatarGradient(item) }
}

defineExpose({ refresh })
</script>

<style scoped>
.fleet-count-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 5px;
  padding: 4px 10px;
  border-radius: 999px;
  background: linear-gradient(135deg, #6366f1, #4f46e5);
  color: #ffffff;
  font-size: 13px;
  font-weight: 700;
  box-shadow: 0 4px 10px rgba(99, 102, 241, 0.25);
}
.add-vehicle-btn {
  text-transform: none;
  font-weight: 600;
  letter-spacing: 0.01em;
  box-shadow: 0 4px 12px rgba(99, 102, 241, 0.3);
}
.vehicles-table-card {
  overflow: hidden;
  border-color: #e2e8f0 !important;
}
.filters-bar {
  border-bottom: 1px solid #e2e8f0;
}
.search-field :deep(.v-field) {
  border-radius: 10px;
}
.vehicle-avatar {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  box-shadow: 0 2px 6px rgba(15, 23, 42, 0.12);
  overflow: hidden;
}
.vehicle-avatar__img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}
.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  display: inline-block;
  background: currentColor;
}
.status-dot.success { color: #16a34a; }
.status-dot.warning { color: #f59e0b; }
.status-dot.info { color: #0ea5e9; }
.status-dot.grey { color: #94a3b8; }
.status-dot.assigned { color: #dc2626; }
.status-dot.available { color: #16a34a; }
.action-row :deep(.v-btn) {
  opacity: 0.7;
  transition: opacity 0.15s ease;
}
.action-row :deep(.v-btn:hover) {
  opacity: 1;
}
</style>
