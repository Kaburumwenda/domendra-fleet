<template>
  <div class="d-flex flex-column ga-4">
    <!-- Page header -->
    <div class="page-header">
      <div>
        <h1 class="text-h5 font-weight-bold d-flex align-center ga-2">
          <v-icon color="primary">mdi-wrench-cog</v-icon>
          Services
        </h1>
        <p class="text-caption text-medium-emphasis">Track maintenance, repairs, and vendor performance across your fleet.</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn variant="outlined" prepend-icon="mdi-refresh" @click="reloadAll" :loading="pending">Refresh</v-btn>
        <v-btn variant="tonal" color="deep-purple" prepend-icon="mdi-database-plus" @click="seedDemo" :loading="seeding">
          <span class="hidden-sm-and-down">Seed Demo Data</span>
        </v-btn>
        <v-btn v-can="'maintenance:create'" color="primary" prepend-icon="mdi-plus" @click="openCreate">
          <span class="hidden-sm-and-down">Log Service</span>
        </v-btn>
      </div>
    </div>

    <!-- Analytics -->
    <ServicesAnalytics :services="services" :currency-symbol="currencySymbol" :active-type-filter="typeFilter" @filter-type="setTypeFilter" @filter-vendor="setVendorFilter" />

    <!-- Filters bar (outside cards) -->
    <div class="d-flex flex-wrap align-center ga-2 filter-bar">
      <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Search descriptions…" density="compact" hide-details variant="outlined" style="max-width:280px" clearable />
      <v-select v-model="typeFilter" :items="serviceTypes" item-title="label" item-value="value" placeholder="All Types" density="compact" hide-details variant="outlined" clearable style="max-width:170px" />
      <v-select v-model="vehicleFilter" :items="vehicleOptions" item-title="display_name" item-value="id" placeholder="All Vehicles" density="compact" hide-details variant="outlined" clearable style="max-width:200px" />
      <v-select v-model="vendorFilter" :items="vendorOptions" item-title="full_name" item-value="id" placeholder="All Vendors" density="compact" hide-details variant="outlined" clearable style="max-width:200px" />
      <v-btn v-if="hasFilters" variant="text" size="small" prepend-icon="mdi-filter-remove" @click="clearFilters">Clear</v-btn>
      <v-spacer />
      <div class="text-caption text-medium-emphasis">{{ filteredServices.length }} of {{ services.length }} services</div>
    </div>

    <!-- Tabs -->
    <v-tabs v-model="tab" color="primary" density="compact" class="svc-tabs">
      <v-tab value="records" prepend-icon="mdi-format-list-bulleted">Records</v-tab>
      <v-tab value="timeline" prepend-icon="mdi-timeline-text-outline">Timeline</v-tab>
      <v-tab value="vendors" prepend-icon="mdi-store-marker-outline">Vendors</v-tab>
    </v-tabs>

    <v-window v-model="tab" class="flex-grow-1">
      <!-- RECORDS (data table) -->
      <v-window-item value="records">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="headers" :items="filteredServices" :loading="pending" hover density="compact" :search="search">
            <template #item.vehicle_name="{ item }">
              <div class="cursor-pointer" @click="openDetail(item)">
                <p class="font-weight-medium">{{ item.vehicle_name }}</p>
                <p class="text-caption text-medium-emphasis">{{ fmt(item.performed_at) }}</p>
              </div>
            </template>
            <template #item.service_type="{ value }">
              <v-chip :color="typeColor(value)" variant="flat" size="small" class="text-capitalize">
                <v-icon start size="14">{{ typeIcon(value) }}</v-icon>{{ value ? value.replace('_', ' ') : '' }}
              </v-chip>
            </template>
            <template #item.cost="{ value }"><span class="font-weight-medium">{{ currencySymbol }}{{ money(value) }}</span></template>
            <template #item.odometer_reading="{ value }">{{ value != null ? value.toLocaleString() + ' mi' : '—' }}</template>
            <template #item.vendor_name="{ value }">{{ value || '—' }}</template>
            <template #item.downtime_hours="{ value }"><v-chip v-if="value" size="small" color="warning" variant="tonal">{{ value }}h</v-chip><span v-else>—</span></template>
            <template #item.rating="{ value }">
              <v-rating v-if="value" :model-value="value.overall_rating || 0" readonly size="x-small" density="compact" half-increments color="amber" />
              <span v-else class="text-caption text-medium-emphasis">—</span>
            </template>
            <template #item.actions="{ item }">
              <v-menu>
                <template #activator="{ props: p }">
                  <v-btn icon="mdi-dots-vertical" variant="text" size="small" v-bind="p" />
                </template>
                <v-list density="compact">
                  <v-list-item prepend-icon="mdi-eye-outline" @click="openDetail(item)">View Details</v-list-item>
                  <v-list-item v-can="'maintenance:update'" prepend-icon="mdi-star-outline" @click="openRate(item)">Rate Vendor</v-list-item>
                  <v-list-item v-can="'maintenance:update'" prepend-icon="mdi-pencil" @click="openEdit(item)">Edit</v-list-item>
                  <v-list-item v-can="'maintenance:delete'" prepend-icon="mdi-delete" base-color="error" @click="deleteService(item)">Delete</v-list-item>
                </v-list>
              </v-menu>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-wrench</v-icon>
                <p>No service records yet. Click <b>Log Service</b> to add one.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>

      <!-- TIMELINE -->
      <v-window-item value="timeline">
        <v-card elevation="0" border rounded="lg">
          <v-card-text>
            <div v-if="!filteredServices.length" class="text-center py-12 text-medium-emphasis">
              <v-icon size="48" class="mb-3">mdi-timeline-text-outline</v-icon>
              <p>No service records to show.</p>
            </div>
            <v-timeline v-else side="end" density="compact">
              <v-timeline-item v-for="s in timelineServices" :key="s.id" :dot-color="typeColor(s.service_type)" size="small" fill-dot>
                <template #opposite>
                  <span class="text-caption text-medium-emphasis">{{ fmt(s.performed_at) }}</span>
                </template>
                <v-card elevation="0" border class="pa-3 cursor-pointer" @click="openDetail(s)">
                  <div class="d-flex align-start justify-space-between">
                    <div class="flex-grow-1">
                      <div class="d-flex align-center ga-2 mb-1">
                        <p class="font-weight-medium">{{ s.vehicle_name }}</p>
                        <v-chip :color="typeColor(s.service_type)" variant="flat" size="x-small" class="text-capitalize">
                          <v-icon start size="12">{{ typeIcon(s.service_type) }}</v-icon>{{ s.service_type ? s.service_type.replace('_', ' ') : '' }}
                        </v-chip>
                      </div>
                      <p class="text-caption text-medium-emphasis">{{ s.vendor_name || 'No vendor' }} · {{ s.technician_name || 'No tech' }} · {{ currencySymbol }}{{ money(s.cost) }}{{ s.downtime_hours ? ` · ${s.downtime_hours}h downtime` : '' }}</p>
                      <p v-if="s.description" class="text-body-2 mt-1 desc-clamp">{{ s.description }}</p>
                      <div class="d-flex align-center ga-2 mt-1">
                        <v-chip v-if="s.odometer_reading != null" size="x-small" variant="outlined"><v-icon start size="12">mdi-counter</v-icon>{{ s.odometer_reading.toLocaleString() }} mi</v-chip>
                        <v-rating v-if="s.rating" :model-value="s.rating.overall_rating || 0" readonly size="x-small" density="compact" half-increments color="amber" />
                        <v-chip v-can="'maintenance:update'" v-else-if="s.vendor" size="x-small" variant="tonal" color="amber" @click.stop="openRate(s)"><v-icon start size="12">mdi-star-plus</v-icon>Rate</v-chip>
                      </div>
                    </div>
                    <div class="d-flex flex-column align-end ga-1">
                      <v-btn v-can="'maintenance:update'" icon="mdi-pencil-outline" size="x-small" variant="text" @click.stop="openEdit(s)" />
                    </div>
                  </div>
                </v-card>
              </v-timeline-item>
            </v-timeline>
          </v-card-text>
        </v-card>
      </v-window-item>

      <!-- VENDORS (vendor performance overview) -->
      <v-window-item value="vendors">
        <v-row dense>
          <v-col v-for="v in vendorPerformance" :key="v.id" cols="12" md="6" lg="4">
            <v-card elevation="0" border rounded="lg" class="vendor-card h-100">
              <v-card-text>
                <div class="d-flex align-center ga-3 mb-3">
                  <v-avatar :color="avatarColor(v.name)" variant="tonal" size="44"><span class="text-h6 font-weight-bold">{{ initials(v.name) }}</span></v-avatar>
                  <div class="flex-grow-1">
                    <p class="font-weight-bold text-body-1">{{ v.name }}</p>
                    <p class="text-caption text-medium-emphasis">{{ v.count }} services performed</p>
                  </div>
                </div>
                <div class="d-flex align-center ga-2 mb-3">
                  <v-rating v-if="v.avgRating > 0" :model-value="v.avgRating" readonly half-increments size="small" color="amber" />
                  <span v-if="v.avgRating > 0" class="text-subtitle-2 font-weight-bold text-amber">{{ v.avgRating.toFixed(1) }}</span>
                  <span v-else class="text-caption text-medium-emphasis">No ratings</span>
                </div>
                <v-divider class="mb-3" />
                <div class="d-flex justify-space-between ga-2">
                  <div class="stat-mini"><p class="stat-mini-value">{{ currencySymbol }}{{ money(v.total) }}</p><p class="stat-mini-label">Total Spend</p></div>
                  <div class="stat-mini"><p class="stat-mini-value">{{ currencySymbol }}{{ money(v.avg) }}</p><p class="stat-mini-label">Avg / Service</p></div>
                  <div class="stat-mini"><p class="stat-mini-value">{{ v.downtime.toFixed(1) }}h</p><p class="stat-mini-label">Downtime</p></div>
                </div>
                <v-btn variant="outlined" block size="small" class="mt-3" prepend-icon="mdi-filter-variant" @click="setVendorFilter(v.id)">Filter by this vendor</v-btn>
              </v-card-text>
            </v-card>
          </v-col>
          <v-col v-if="!vendorPerformance.length" cols="12">
            <div class="text-center py-12 text-medium-emphasis">
              <v-icon size="48" class="mb-3">mdi-store-off-outline</v-icon>
              <p>No vendor services recorded yet.</p>
            </div>
          </v-col>
        </v-row>
      </v-window-item>
    </v-window>

    <!-- Service create/edit dialog -->
    <ServiceFormDialog
      ref="formRef"
      v-model="formDialog"
      :editing="editing"
      :saving="saving"
      :currency-symbol="currencySymbol"
      :vehicle-options="vehicleOptions"
      :vendor-options="vendorOptions"
      :work-order-options="workOrderOptions"
      :used-work-order-ids="usedWorkOrderIds"
      @save="saveService"
    />

    <!-- Vendor rating dialog -->
    <VendorRatingDialog
      ref="rateRef"
      v-model="rateDialog"
      :vendor-name="activeService?.vendor_name || 'Vendor'"
      :saving="saving"
      @submit="submitRating"
    />

    <!-- Detail drawer -->
    <ServiceDetailDrawer
      v-model="drawerOpen"
      :svc="selectedService"
      :currency-symbol="currencySymbol"
      @edit="openEdit"
      @rate="openRate"
      @delete="deleteService"
    />
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })
const { $api, $swal } = useNuxtApp() as any
const { currencySymbol } = useCurrency()

const tab = ref<'records' | 'timeline' | 'vendors'>('records')
const search = ref('')
const typeFilter = ref<string | null>(null)
const vehicleFilter = ref<number | null>(null)
const vendorFilter = ref<number | null>(null)

const serviceTypes = [
  { label: 'Oil Change', value: 'oil_change' }, { label: 'Tire Rotation', value: 'tire_rotation' },
  { label: 'Brake Service', value: 'brake_service' }, { label: 'Inspection', value: 'inspection' },
  { label: 'Repair', value: 'repair' }, { label: 'Preventive', value: 'preventive' }, { label: 'Other', value: 'other' },
]

const headers = [
  { title: 'Vehicle', key: 'vehicle_name', sortable: true },
  { title: 'Type', key: 'service_type', sortable: true, width: '130px' },
  { title: 'Cost', key: 'cost', sortable: true, width: '110px' },
  { title: 'Vendor', key: 'vendor_name', width: '140px' },
  { title: 'Odometer', key: 'odometer_reading', width: '110px' },
  { title: 'Downtime', key: 'downtime_hours', width: '90px' },
  { title: 'Rating', key: 'rating', width: '120px', sortable: false },
  { title: '', key: 'actions', width: '50px', sortable: false },
]

// --- Lookup data ---
const { data: vehicleData } = useAsyncData('svc-vehicles', () => $api('/vehicles/vehicles/', { query: { page_size: 1000 } }), { default: () => ({ results: [] }) })
const vehicleOptions = computed(() => vehicleData.value?.results || [])
const { data: contactData } = useAsyncData('svc-vendors', () => $api('/contacts/', { query: { contact_type: 'vendor', page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const vendorOptions = computed(() => contactData.value?.results || [])
const { data: workOrderData } = useAsyncData('svc-workorders', () => $api('/issues/work-orders/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const workOrderOptions = computed(() => (workOrderData.value?.results || []).map((w: any) => {
  // Find the matching vehicle ID by vehicle name
  const veh = (vehicleOptions.value || []).find((v: any) => v.display_name === w.vehicle_name)
  return { id: w.id, label: `WO-${w.id} · ${w.vehicle_name || w.issue_title || ''}`, vehicle_id: veh?.id || null, vehicle_name: w.vehicle_name }
}))

// Track WO IDs already linked to other services (to disable them in the dropdown)
const usedWorkOrderIds = computed(() => {
  const ids = new Set<number>()
  const editingId = formRef.value?.form?._id
  services.value.forEach((s: any) => {
    if (s.work_order && s.id !== editingId) ids.add(s.work_order)
  })
  return [...ids]
})

// --- Main data ---
const { data: svcData, pending, refresh } = useAsyncData('services', () =>
  $api('/services/', { query: { page_size: 1000 } }), { default: () => ({ results: [], count: 0 }) })
const services = computed(() => svcData.value?.results || svcData.value || [])

const filteredServices = computed(() => {
  let arr = services.value
  if (typeFilter.value) arr = arr.filter(s => s.service_type === typeFilter.value)
  if (vehicleFilter.value) arr = arr.filter(s => s.vehicle === vehicleFilter.value)
  if (vendorFilter.value) arr = arr.filter(s => s.vendor === vendorFilter.value)
  if (search.value) {
    const q = search.value.toLowerCase()
    arr = arr.filter(s => (s.description || '').toLowerCase().includes(q) || (s.vehicle_name || '').toLowerCase().includes(q) || (s.vendor_name || '').toLowerCase().includes(q))
  }
  return arr
})
const hasFilters = computed(() => !!(typeFilter.value || vehicleFilter.value || vendorFilter.value || search.value))
const timelineServices = computed(() => [...filteredServices.value].sort((a, b) => new Date(b.performed_at).valueOf() - new Date(a.performed_at).valueOf()))

// --- Vendor performance grid ---
const vendorPerformance = computed(() => {
  const map: Record<string, { id: number; name: string; count: number; total: number; downtime: number; ratings: number[] }> = {}
  services.value.forEach(s => {
    if (!s.vendor_name) return
    const key = s.vendor_name
    if (!map[key]) map[key] = { id: s.vendor, name: s.vendor_name, count: 0, total: 0, downtime: 0, ratings: [] }
    map[key].count++; map[key].total += parseFloat(s.cost || 0); map[key].downtime += (s.downtime_hours || 0)
    if (s.rating?.overall_rating != null) map[key].ratings.push(s.rating.overall_rating)
  })
  return Object.values(map).map(v => ({
    ...v, avg: v.count ? v.total / v.count : 0, avgRating: v.ratings.length ? v.ratings.reduce((a, r) => a + r, 0) / v.ratings.length : 0,
  })).sort((a, b) => b.total - a.total)
})

// --- Dialogs ---
const formRef = ref<any>(null)
const formDialog = ref(false)
const editing = ref(false)
const saving = ref(false)
const rateRef = ref<any>(null)
const rateDialog = ref(false)
const drawerOpen = ref(false)
const selectedService = ref<any>(null)
const activeService = ref<any>(null)

function openCreate() { editing.value = false; formRef.value?.reset(); formDialog.value = true }
function openEdit(s: any) { editing.value = true; formRef.value?.reset(s); formDialog.value = true; drawerOpen.value = false }
function openDetail(s: any) { selectedService.value = s; drawerOpen.value = true }

async function saveService(payload: any) {
  saving.value = true
  try {
    const { _id, ...body } = payload
    if (editing.value && payload._id) await $api(`/services/${payload._id}/`, { method: 'PATCH', body })
    else await $api('/services/', { method: 'POST', body })
    formDialog.value = false
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: editing.value ? 'Service updated' : 'Service logged', toast: true, timer: 1500, position: 'top-end' })
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Save failed', toast: true, timer: 2000, position: 'top-end' }) } finally { saving.value = false }
}

async function deleteService(s: any) {
  const r = await $swal?.fire?.({ icon: 'warning', title: 'Delete service record?', text: `${s.vehicle_name} · ${s.service_type?.replace('_', ' ')}`, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#dc2626' })
  if (!r?.isConfirmed) return
  await $api(`/services/${s.id}/`, { method: 'DELETE' })
  if (selectedService.value?.id === s.id) { drawerOpen.value = false; selectedService.value = null }
  await reloadAll()
  $swal?.fire?.({ icon: 'success', title: 'Service deleted', toast: true, timer: 1500, position: 'top-end' })
}

function openRate(s: any) {
  activeService.value = s
  if (s.rating) rateRef.value?.populate(s.rating); else rateRef.value?.reset()
  rateDialog.value = true
}
async function submitRating(payload: any) {
  saving.value = true
  try {
    await $api(`/services/${activeService.value.id}/rate-vendor/`, { method: 'POST', body: payload })
    rateDialog.value = false
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: 'Rating submitted', toast: true, timer: 1500, position: 'top-end' })
    if (selectedService.value?.id === activeService.value.id) selectedService.value = services.value.find((x: any) => x.id === activeService.value.id) || null
  } catch (e) { console.error(e) } finally { saving.value = false }
}

// --- Filter helpers ---
function setTypeFilter(k: string) { typeFilter.value = typeFilter.value === k ? null : k }
function setVendorFilter(id: number) { vendorFilter.value = vendorFilter.value === id ? null : id; tab.value = 'records' }
function clearFilters() { search.value = ''; typeFilter.value = null; vehicleFilter.value = null; vendorFilter.value = null }

// --- Utils ---
function money(v: any) { return parseFloat(v || 0).toFixed(2) }
function fmt(v?: string) { return v ? new Date(v).toLocaleString([], { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : '—' }
function typeColor(t: string) { return ({ oil_change: 'amber', tire_rotation: 'blue', brake_service: 'error', inspection: 'success', repair: 'deep-orange', preventive: 'indigo', other: 'grey' } as any)[t] || 'grey' }
function typeIcon(t: string) { return ({ oil_change: 'mdi-oil', tire_rotation: 'mdi-tire', brake_service: 'mdi-car-brake-abs', inspection: 'mdi-clipboard-check-outline', repair: 'mdi-wrench', preventive: 'mdi-calendar-sync', other: 'mdi-dots-horizontal' } as any)[t] || 'mdi-wrench' }
function initials(n: string) { return (n || '?').split(' ').map((w: string) => w[0]).slice(0, 2).join('').toUpperCase() }
function avatarColor(n: string) { const cs = ['#6366f1', '#0ea5e9', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6']; let h = 0; for (let i = 0; i < n.length; i++) h = n.charCodeAt(i) + ((h << 5) - h); return cs[Math.abs(h) % cs.length] }

// --- Bulk reload ---
async function reloadAll() { await refresh() }

// --- Seed demo data ---
const seeding = ref(false)
async function seedDemo() {
  const r = await $swal?.fire?.({
    icon: 'question',
    title: 'Seed demo data?',
    text: 'This will add 28 sample service records with vendor ratings.',
    showCancelButton: true,
    confirmButtonText: 'Seed Data',
  })
  if (!r?.isConfirmed) return
  seeding.value = true
  try {
    const res = await $api('/services/seed-demo/', { method: 'POST' })
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: res?.detail || 'Demo data seeded', toast: true, timer: 2000, position: 'top-end' })
  } catch (e: any) {
    console.error(e)
    $swal?.fire?.({ icon: 'error', title: e?.response?._data?.detail || 'Failed to seed data', toast: true, timer: 3000, position: 'top-end' })
  } finally {
    seeding.value = false
  }
}
</script>

<style scoped>
.page-header { display:flex; align-items:flex-start; justify-content:space-between; gap:12px; flex-wrap:wrap; }
.filter-bar { flex-wrap:wrap; }
.svc-tabs :deep(.v-tab) { text-transform: none; font-weight: 600; }
.cursor-pointer { cursor: pointer; }
.desc-clamp { display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }
.vendor-card { transition: box-shadow .15s; }
.vendor-card:hover { box-shadow: 0 6px 18px rgba(2,6,23,.08); }
.stat-mini { text-align:center; flex:1; }
.stat-mini-value { font-size:15px; font-weight:800; color:#0f172a; }
.stat-mini-label { font-size:10px; color:#64748b; font-weight:600; text-transform:uppercase; letter-spacing:.04em; }
.text-amber { color:#d97706; }
</style>
