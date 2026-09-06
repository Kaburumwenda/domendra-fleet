<template>
  <div class="d-flex flex-column ga-4">
    <!-- Header -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-2">
      <div>
        <h1 class="text-h5 font-weight-bold" style="color: #1e293b">Transfers</h1>
        <p class="text-caption text-medium-emphasis">Point-to-point passenger transfers - airport, hotels, inter-city and executive</p>
      </div>
      <div class="d-flex ga-2">
        <v-btn variant="outlined" size="small" prepend-icon="mdi-map-clock-outline" @click="liveTrackOpen = true">Live Tracking</v-btn>
        <v-btn v-can="'transfers:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="navigateTo('/app/transfers/new')">New Booking</v-btn>
      </div>
    </div>

    <!-- KPI Row -->
    <v-row dense>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #6366f1 0%, #818cf8 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-car-clock</v-icon><span style="color:#fff; font-size:0.75rem; font-weight:500">Upcoming</span></div>
          <p class="text-h4 font-weight-bold" style="color:#fff !important">{{ stats.upcoming || 0 }}</p>
          <p style="color:#fff; opacity:.85; font-size:0.75rem">{{ stats.today_count || 0 }} scheduled today</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-car-side</v-icon><span style="color:#fff; font-size:0.75rem; font-weight:500">En Route</span></div>
          <p class="text-h4 font-weight-bold" style="color:#fff !important">{{ stats.en_route || 0 }}</p>
          <p style="color:#fff; opacity:.85; font-size:0.75rem">Active trips now</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #10b981 0%, #34d399 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-check-circle-outline</v-icon><span style="color:#fff; font-size:0.75rem; font-weight:500">Completed</span></div>
          <p class="text-h4 font-weight-bold" style="color:#fff !important">{{ stats.completed || 0 }}</p>
          <p style="color:#fff; opacity:.85; font-size:0.75rem">{{ currencySymbol }}{{ (stats.revenue || 0).toFixed(0) }} revenue</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #ef4444 0%, #f87171 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-cash-remove</v-icon><span style="color:#fff; font-size:0.75rem; font-weight:500">Outstanding</span></div>
          <p class="text-h4 font-weight-bold" style="color:#fff !important">{{ currencySymbol }}{{ (stats.outstanding || 0).toFixed(0) }}</p>
          <p style="color:#fff; opacity:.85; font-size:0.75rem">Unpaid balances</p>
        </v-card>
      </v-col>
    </v-row>

    <!-- Filter bar -->
    <v-card elevation="0" border rounded="lg" class="pa-4">
      <div class="d-flex align-center flex-wrap ga-2">
        <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Search ref, passenger, phone, flight..." density="compact" variant="outlined" hide-details clearable style="max-width: 320px; flex: 1 1 280px" />
        <v-select v-model="statusFilter" :items="TRANSFER_STATUS_OPTIONS" item-title="title" item-value="value" density="compact" variant="outlined" hide-details label="Status" style="max-width: 160px" clearable />
        <v-select v-model="classFilter" :items="TRANSFER_SERVICE_CLASS_OPTIONS" item-title="title" item-value="value" density="compact" variant="outlined" hide-details label="Class" style="max-width: 160px" clearable />
        <v-select v-model="paymentFilter" :items="TRANSFER_PAYMENT_STATUS_OPTIONS" item-title="title" item-value="value" density="compact" variant="outlined" hide-details label="Payment" style="max-width: 160px" clearable />
        <v-text-field v-model="dateFrom" type="date" label="From" density="compact" variant="outlined" hide-details clearable style="max-width: 150px" prepend-inner-icon="mdi-calendar-start-outline" />
        <v-text-field v-model="dateTo" type="date" label="To" density="compact" variant="outlined" hide-details clearable style="max-width: 150px" prepend-inner-icon="mdi-calendar-end-outline" />
        <v-btn v-if="hasFilters" size="small" variant="text" color="primary" prepend-icon="mdi-filter-remove-outline" @click="clearFilters">Clear</v-btn>
      </div>
    </v-card>

    <!-- Bookings table -->
    <v-card elevation="0" border rounded="lg">
      <v-data-table-server
        v-model:page="page"
        v-model:items-per-page="itemsPerPage"
        :items="transfers"
        :headers="headers"
        :loading="loading"
        :items-length="totalItems"
        item-value="id"
        hover
        density="comfortable"
        @update:options="loadTransfers"
      >
        <template #item.index="{ index }">
          <span class="text-caption text-medium-emphasis">{{ (page - 1) * itemsPerPage + index + 1 }}</span>
        </template>

        <template #item.reference="{ item }">
          <span class="font-weight-bold text-primary">{{ item.reference }}</span>
        </template>

        <template #item.passenger_name="{ item }">
          <div class="d-flex align-center ga-2">
            <div class="transfer-avatar">{{ initials(item.passenger_name) }}</div>
            <div>
              <p class="text-body-2 font-weight-medium mb-0">{{ item.passenger_name }}</p>
              <p class="text-caption text-medium-emphasis mb-0">{{ item.passenger_phone || item.passenger_email }}</p>
            </div>
          </div>
        </template>

        <template #item.route="{ item }">
          <div class="d-flex align-center ga-1 flex-wrap" style="max-width: 260px">
            <v-icon size="small" color="success">mdi-circle-medium</v-icon>
            <span class="text-body-2 text-truncate" style="max-width: 100px">{{ item.pickup_name }}</span>
            <v-icon size="small" color="grey">mdi-arrow-right</v-icon>
            <v-icon size="small" color="error">mdi-circle-medium</v-icon>
            <span class="text-body-2 text-truncate" style="max-width: 100px">{{ item.dropoff_name }}</span>
          </div>
        </template>

        <template #item.pickup_datetime="{ item }">
          <div>
            <p class="text-body-2 mb-0">{{ formatDate(item.pickup_datetime) }}</p>
            <p class="text-caption text-medium-emphasis mb-0">{{ formatTime(item.pickup_datetime) }}</p>
          </div>
        </template>

        <template #item.service_class="{ item }">
          <v-chip size="small" variant="tonal" :color="classColor(item.service_class)">
            {{ classLabel(item.service_class) }}
          </v-chip>
        </template>

        <template #item.status="{ item }">
          <v-chip size="small" variant="flat" :color="statusColor(item.status)">
            {{ statusLabel(item.status) }}
          </v-chip>
        </template>

        <template #item.total_amount="{ item }">
          <div>
            <p class="text-body-2 font-weight-bold mb-0">{{ currencySymbol }}{{ Number(item.total_amount).toFixed(2) }}</p>
            <v-chip v-if="item.payment_status === 'paid'" size="x-small" variant="text" color="success">Paid</v-chip>
            <v-chip v-else-if="item.payment_status === 'partial'" size="x-small" variant="text" color="warning">Partial</v-chip>
            <v-chip v-else size="x-small" variant="text" color="error">Unpaid</v-chip>
          </div>
        </template>

        <template #item.remaining_balance="{ item }">
          <span v-if="Number(item.remaining_balance) > 0" class="text-body-2 font-weight-bold" style="color: #ef4444">
            {{ currencySymbol }}{{ Number(item.remaining_balance).toFixed(2) }}
          </span>
          <span v-else class="text-body-2 font-weight-medium" style="color: #16a34a">
            {{ currencySymbol }}0.00
          </span>
        </template>

        <template #item.vehicle_name="{ item }">
          <span v-if="item.vehicle_name" class="text-body-2">{{ item.vehicle_name }}</span>
          <span v-else class="text-caption text-medium-emphasis">Unassigned</span>
        </template>

        <template #item.driver_name="{ item }">
          <span v-if="item.driver_name" class="text-body-2">{{ item.driver_name }}</span>
          <span v-else class="text-caption text-medium-emphasis">--</span>
        </template>

        <template #item.actions="{ item }">
          <div class="d-flex align-center ga-1">
            <v-tooltip text="View & manage" location="top">
              <template #activator="{ props }">
                <v-btn v-bind="props" icon="mdi-eye-outline" size="x-small" variant="text" color="primary" @click="navigateTo(`/app/transfers/${item.id}`)" />
              </template>
            </v-tooltip>
            <v-tooltip text="Edit" location="top">
              <template #activator="{ props }">
                <v-btn v-can="'transfers:update'" v-bind="props" icon="mdi-pencil-outline" size="x-small" variant="text" color="info" @click="navigateTo(`/app/transfers/${item.id}/edit`)" />
              </template>
            </v-tooltip>
            <v-tooltip text="Generate Invoice" location="top">
              <template #activator="{ props }">
                <v-btn v-can="'billing:create'" v-bind="props" icon="mdi-receipt-text-outline" size="x-small" variant="text" color="teal" :loading="invoiceLoading === item.id" @click="generateInvoice(item)" />
              </template>
            </v-tooltip>
            <v-tooltip v-if="item.status === 'draft' || item.status === 'scheduled'" text="Delete" location="top">
              <template #activator="{ props }">
                <v-btn v-can="'transfers:delete'" v-bind="props" icon="mdi-trash-can-outline" size="x-small" variant="text" color="error" @click="confirmDelete(item)" />
              </template>
            </v-tooltip>
          </div>
        </template>

        <template #no-data>
          <div class="text-center py-12">
            <v-icon size="48" color="grey-lighten-1">mdi-car-off</v-icon>
            <p class="text-body-1 font-weight-medium mt-2 text-medium-emphasis">No transfers found</p>
            <v-btn v-can="'transfers:create'" color="primary" variant="tonal" size="small" prepend-icon="mdi-plus" class="mt-3" @click="navigateTo('/app/transfers/new')">Create New Transfer</v-btn>
          </div>
        </template>
      </v-data-table-server>
    </v-card>

    <!-- Live tracking dialog -->
    <v-dialog v-model="liveTrackOpen" max-width="900px">
      <v-card rounded="xl" elevation="0" border>
        <AppModalHeader icon="mdi-map-clock-outline" title="Live Transfer Tracking" color="primary" />
        <v-card-text class="pa-4">
          <div v-if="activeTransfers.length === 0" class="text-center py-8">
            <v-icon size="48" color="grey-lighten-1">mdi-map-marker-off</v-icon>
            <p class="text-body-2 text-medium-emphasis mt-2">No active transfers to track right now.</p>
          </div>
          <v-list v-else>
            <v-list-item v-for="t in activeTransfers" :key="t.id" @click="navigateTo(`/app/transfers/${t.id}`)">
              <template #prepend>
                <v-avatar :color="statusColor(t.status)" size="40" rounded>
                  <v-icon color="white">mdi-car-side</v-icon>
                </v-avatar>
              </template>
              <v-list-item-title class="font-weight-bold">{{ t.reference }} - {{ t.passenger_name }}</v-list-item-title>
              <v-list-item-subtitle>{{ t.pickup_name }} -> {{ t.dropoff_name }} | {{ statusLabel(t.status) }} | {{ t.driver_name || 'No driver' }}</v-list-item-subtitle>
            </v-list-item>
          </v-list>
        </v-card-text>
        <v-card-actions class="pa-4 pt-0">
          <v-spacer />
          <v-btn variant="text" @click="liveTrackOpen = false">Close</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Delete confirmation -->
    <v-dialog v-model="deleteDialog" max-width="420px">
      <v-card rounded="xl" elevation="0" border>
        <AppModalHeader icon="mdi-trash-can-outline" title="Delete Transfer" color="error" />
        <v-card-text class="pa-6">
          <p class="text-body-2">Are you sure you want to delete transfer <strong>{{ deletingItem?.reference }}</strong>? This action cannot be undone.</p>
        </v-card-text>
        <v-card-actions class="pa-4 pt-0">
          <v-spacer />
          <v-btn variant="text" @click="deleteDialog = false">Cancel</v-btn>
          <v-btn color="error" prepend-icon="mdi-trash-can-outline" :loading="deleting" @click="doDelete">Delete</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { TRANSFER_STATUS_OPTIONS, TRANSFER_SERVICE_CLASS_OPTIONS, TRANSFER_PAYMENT_STATUS_OPTIONS, useTransferApi } from '~/composables/useTransferApi'

definePageMeta({ layout: 'default', permission: 'transfers:view' })

const { $swal } = useNuxtApp()
const { fetchTransfers, fetchStats, deleteTransfer } = useTransferApi()
const { currencySymbol } = useCurrency()

const page = ref(1)
const itemsPerPage = ref(20)
const totalItems = ref(0)
const transfers = ref<any[]>([])
const loading = ref(false)

const search = ref('')
const debouncedSearch = ref('')
const statusFilter = ref('')
const classFilter = ref('')
const paymentFilter = ref('')
const dateFrom = ref('')
const dateTo = ref('')

const liveTrackOpen = ref(false)
const activeTransfers = ref<any[]>([])

const deleteDialog = ref(false)
const deletingItem = ref<any>(null)
const deleting = ref(false)

const headers = [
  { title: '#', key: 'index', sortable: false, width: '50px' },
  { title: 'Ref', key: 'reference', sortable: true, width: '110px' },
  { title: 'Passenger', key: 'passenger_name', sortable: true, width: '180px' },
  { title: 'Route', key: 'route', sortable: false, width: '220px' },
  { title: 'Pickup', key: 'pickup_datetime', sortable: true, width: '130px' },
  { title: 'Class', key: 'service_class', sortable: true, width: '100px' },
  { title: 'Vehicle', key: 'vehicle_name', sortable: false, width: '120px' },
  { title: 'Driver', key: 'driver_name', sortable: false, width: '120px' },
  { title: 'Status', key: 'status', sortable: true, width: '110px' },
  { title: 'Total', key: 'total_amount', sortable: true, width: '100px' },
  { title: 'Balance', key: 'remaining_balance', sortable: true, width: '110px' },
  { title: '', key: 'actions', sortable: false, width: '130px', align: 'end' as const },
]

let searchTimer: any = null
watch(search, (val) => {
  clearTimeout(searchTimer)
  searchTimer = setTimeout(() => { debouncedSearch.value = val; page.value = 1 }, 400)
})

const hasFilters = computed(() => debouncedSearch.value || statusFilter.value || classFilter.value || paymentFilter.value || dateFrom.value || dateTo.value)

function clearFilters() {
  debouncedSearch.value = ''
  search.value = ''
  statusFilter.value = ''
  classFilter.value = ''
  paymentFilter.value = ''
  dateFrom.value = ''
  dateTo.value = ''
  page.value = 1
}

const stats = ref<any>({})
async function loadStats() {
  try { stats.value = await fetchStats() } catch (e) { console.error('Transfer stats error:', e) }
}

async function loadTransfers() {
  loading.value = true
  try {
    const params: any = { page: page.value, page_size: itemsPerPage.value }
    if (debouncedSearch.value) params.search = debouncedSearch.value
    if (statusFilter.value) params.status = statusFilter.value
    if (classFilter.value) params.service_class = classFilter.value
    if (paymentFilter.value) params.payment_status = paymentFilter.value
    if (dateFrom.value) params.pickup_date_from = dateFrom.value
    if (dateTo.value) params.pickup_date_to = dateTo.value
    const data: any = await fetchTransfers(params)
    // Paginated or array
    if (Array.isArray(data)) {
      transfers.value = data
      totalItems.value = data.length
    } else if (data.results) {
      transfers.value = data.results
      totalItems.value = data.count
    }
  } catch (e) {
    console.error('Failed to load transfers:', e)
    transfers.value = []
  } finally {
    loading.value = false
  }
}

async function loadActiveTransfers() {
  try {
    const data: any = await fetchTransfers({ status: 'en_route' })
    const data2: any = await fetchTransfers({ status: 'picked_up' })
    const enRoute = Array.isArray(data) ? data : (data?.results || [])
    const pickedUp = Array.isArray(data2) ? data2 : (data2?.results || [])
    activeTransfers.value = [...enRoute, ...pickedUp]
  } catch { activeTransfers.value = [] }
}

function confirmDelete(item: any) {
  deletingItem.value = item
  deleteDialog.value = true
}

const invoiceLoading = ref<number | null>(null)
async function generateInvoice(item: any) {
  invoiceLoading.value = item.id
  try {
    const { $api } = useNuxtApp()
    const res = await $api('/rentals/invoices/from-transfer/', {
      method: 'POST',
      body: { transfer: item.id },
    })
    $swal.fire({
      icon: 'success',
      title: 'Invoice Created',
      text: `Invoice ${res.invoice_no} generated for ${item.reference}.`,
      timer: 2500,
      toast: true,
      position: 'top-end',
      showConfirmButton: false,
    })
    navigateTo(`/app/invoices`)
  } catch (e: any) {
    $swal.fire({
      icon: 'error',
      title: 'Invoice Failed',
      text: e?.data?.detail || 'Failed to generate invoice.',
    })
  } finally {
    invoiceLoading.value = null
  }
}

async function doDelete() {
  if (!deletingItem.value) return
  deleting.value = true
  try {
    await deleteTransfer(deletingItem.value.id)
    $swal.fire({ icon: 'success', title: 'Deleted', text: 'Transfer deleted.', timer: 2000, toast: true, position: 'top-end', showConfirmButton: false })
    deleteDialog.value = false
    await loadTransfers()
    await loadStats()
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Error', text: e?.data?.detail || 'Failed to delete transfer.' })
  } finally { deleting.value = false }
}

// ── Helpers ──
function initials(name: string) {
  if (!name) return '?'
  return name.split(' ').map((n: string) => n[0]).slice(0, 2).join('').toUpperCase()
}

function formatDate(d: string) {
  if (!d) return '--'
  return new Date(d).toLocaleDateString(undefined, { month: 'short', day: 'numeric' })
}

function formatTime(d: string) {
  if (!d) return ''
  return new Date(d).toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' })
}

function statusColor(s: string): string {
  const map: Record<string, string> = {
    draft: 'grey', scheduled: 'info', assigned: 'primary',
    en_route: 'warning', picked_up: 'orange-darken-2',
    completed: 'success', cancelled: 'error', no_show: 'grey-darken-1',
  }
  return map[s] || 'grey'
}

function statusLabel(s: string): string {
  const map: Record<string, string> = {
    draft: 'Draft', scheduled: 'Scheduled', assigned: 'Assigned',
    en_route: 'En Route', picked_up: 'Picked Up',
    completed: 'Completed', cancelled: 'Cancelled', no_show: 'No Show',
  }
  return map[s] || s
}

function classColor(c: string): string {
  const map: Record<string, string> = {
    economy: 'grey', business: 'primary', premium: 'info',
    luxury: 'purple', van: 'teal', executive: 'indigo-darken-2',
  }
  return map[c] || 'grey'
}

function classLabel(c: string): string {
  const map: Record<string, string> = {
    economy: 'Economy', business: 'Business', premium: 'Premium',
    luxury: 'Luxury', van: 'Van', executive: 'Executive',
  }
  return map[c] || c
}

function rebuildQuery() { loadTransfers() }
watch([statusFilter, classFilter, paymentFilter, dateFrom, dateTo], () => { page.value = 1; rebuildQuery() })

onMounted(async () => {
  await Promise.all([loadTransfers(), loadStats(), loadActiveTransfers()])
})
</script>

<style scoped>
.transfer-avatar {
  width: 36px; height: 36px; border-radius: 50%;
  background: linear-gradient(135deg, #6366f1, #818cf8);
  display: flex; align-items: center; justify-content: center;
  color: white; font-size: 0.75rem; font-weight: 700;
}
</style>
