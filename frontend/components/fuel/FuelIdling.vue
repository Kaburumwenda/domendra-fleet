<template>
  <div class="d-flex flex-column ga-4">
    <!-- Date Filter Bar -->
    <div class="d-flex align-center flex-wrap ga-2">
      <v-btn-toggle v-model="datePreset" mandatory density="compact" color="primary" divided rounded="lg">
        <v-btn value="today" size="small">Today</v-btn>
        <v-btn value="7d" size="small">7d</v-btn>
        <v-btn value="30d" size="small">30d</v-btn>
        <v-btn value="90d" size="small">90d</v-btn>
        <v-btn value="all" size="small">All</v-btn>
        <v-btn value="custom" size="small" @click="openCustomDate">Custom…</v-btn>
      </v-btn-toggle>
      <v-chip v-if="customFrom || customTo" size="small" variant="tonal" color="primary" closable @click:close="clearCustom">
        {{ customFrom || '…' }} → {{ customTo || '…' }}
      </v-chip>
    </div>

    <!-- Summary KPIs -->
    <v-row dense>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5">
          <div class="d-flex align-center ga-2 mb-2">
            <div class="d-flex align-center justify-center" style="width: 36px; height: 36px; border-radius: 10px; background: rgba(245,158,11,0.12)">
              <v-icon color="amber-darken-1" size="small">mdi-clock-outline</v-icon>
            </div>
            <span class="text-caption text-medium-emphasis">Events ({{ dateLabel }})</span>
          </div>
          <p class="text-h4 font-weight-bold text-high-emphasis">{{ summary?.total_events || 0 }}</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5">
          <div class="d-flex align-center ga-2 mb-2">
            <div class="d-flex align-center justify-center" style="width: 36px; height: 36px; border-radius: 10px; background: rgba(239,68,68,0.12)">
              <v-icon color="error" size="small">mdi-timer-sand</v-icon>
            </div>
            <span class="text-caption text-medium-emphasis">Total Hours</span>
          </div>
          <p class="text-h4 font-weight-bold text-high-emphasis">{{ summary?.total_hours || 0 }}h</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5">
          <div class="d-flex align-center ga-2 mb-2">
            <div class="d-flex align-center justify-center" style="width: 36px; height: 36px; border-radius: 10px; background: rgba(139,92,246,0.12)">
              <v-icon color="deep-purple" size="small">mdi-gauge</v-icon>
            </div>
            <span class="text-caption text-medium-emphasis">Fuel Burned</span>
          </div>
          <p class="text-h4 font-weight-bold text-high-emphasis">{{ summary?.total_fuel_burned || 0 }} gal</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5">
          <div class="d-flex align-center ga-2 mb-2">
            <div class="d-flex align-center justify-center" style="width: 36px; height: 36px; border-radius: 10px; background: rgba(236,72,153,0.12)">
              <v-icon color="pink-darken-1" size="small">mdi-currency-usd-off</v-icon>
            </div>
            <span class="text-caption text-medium-emphasis">Wasted Cost</span>
          </div>
          <p class="text-h4 font-weight-bold text-error">{{ currencySymbol }}{{ summary?.total_cost || 0 }}</p>
        </v-card>
      </v-col>
    </v-row>

    <!-- Top idling vehicles chart -->
    <DashboardChart v-if="(summary?.by_vehicle || []).length" :option="byVehicleOption" title="Top Idling Vehicles by Cost" icon="mdi-car-clock" height="260px" />

    <!-- Events table -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-2">
      <span class="text-caption text-medium-emphasis">{{ events.length }} idling events</span>
      <v-btn v-can="'fuel:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="openDialog()">Add Event</v-btn>
    </div>

    <v-card elevation="0" border rounded="lg">
      <v-data-table :headers="headers" :items="events" :loading="pending" hover items-per-page="15">
        <template #item.start_time="{ value }">
          <div class="d-flex flex-column">
            <span class="text-body-2 font-weight-medium">{{ formatFuelDate(value).date }}</span>
            <span class="text-caption text-medium-emphasis">{{ formatFuelDate(value).time }}</span>
          </div>
        </template>
        <template #item.vehicle_name="{ value }"><span class="font-weight-medium">{{ value || '—' }}</span></template>
        <template #item.duration="{ item }">
          <span v-if="(item as any).duration_hours" class="text-body-2">{{ (item as any).duration_hours }}h</span>
          <span v-else class="text-medium-emphasis">—</span>
        </template>
        <template #item.fuel_burned="{ value }">
          <span v-if="value" class="text-warning font-weight-medium">{{ value }} gal</span>
          <span v-else class="text-medium-emphasis">—</span>
        </template>
        <template #item.cost="{ value }">
          <span v-if="value" class="text-error font-weight-medium">{{ currencySymbol }}{{ value }}</span>
          <span v-else class="text-medium-emphasis">—</span>
        </template>
        <template #item.location="{ value }">{{ value || '—' }}</template>
        <template #item.actions="{ item }">
          <div class="d-flex ga-1">
            <v-btn v-can="'fuel:update'" icon="mdi-pencil-outline" size="x-small" variant="text" color="warning" title="Edit" @click="editEvent(item)" />
            <v-btn v-can="'fuel:delete'" icon="mdi-delete-outline" size="x-small" variant="text" color="error" title="Delete" @click="removeEvent(item)" />
          </div>
        </template>
        <template #no-data>
          <div class="text-center py-12 text-medium-emphasis">
            <v-icon size="48" class="mb-3">mdi-engine-off</v-icon>
            <p>No idling events recorded.</p>
          </div>
        </template>
      </v-data-table>
    </v-card>

    <!-- Custom Date Range Dialog -->
    <v-dialog v-model="customDateDialogVisible" max-width="420">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-calendar-range">Custom Date Range</AppModalHeader>
        <v-card-text class="pt-4">
          <v-row dense>
            <v-col cols="12">
              <v-text-field v-model="customFrom" type="date" label="From" density="comfortable" variant="outlined" prepend-inner-icon="mdi-calendar-start" hide-details="auto" />
            </v-col>
            <v-col cols="12">
              <v-text-field v-model="customTo" type="date" label="To" density="comfortable" variant="outlined" prepend-inner-icon="mdi-calendar-end" hide-details="auto" />
            </v-col>
            <v-col cols="12" v-if="customDateError" class="pt-2">
              <p class="text-caption text-error">{{ customDateError }}</p>
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="cancelCustomDate">Cancel</v-btn>
          <v-btn color="primary" prepend-icon="mdi-magnify" @click="applyCustomDate">Apply</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Add/Edit Dialog -->
    <v-dialog v-model="dialogVisible" max-width="500" scroll-strategy="none">
      <v-card rounded="xl" class="overflow-hidden">
        <AppModalHeader icon="mdi-engine-off">{{ editingEvent ? 'Edit' : 'Add' }} Idling Event</AppModalHeader>
        <v-card-text class="pt-5">
          <v-row dense>
            <v-col cols="12">
              <v-select v-model="form.vehicle" :items="vehicleOptions" item-title="display_name" item-value="id" label="Vehicle *" :rules="[v => !!v || 'Required']" required />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="form.start_time" type="datetime-local" label="Start Time *" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="form.end_time" type="datetime-local" label="End Time" hide-details="auto" />
            </v-col>
            <v-col cols="6" md="4">
              <v-text-field v-model.number="form.fuel_burn_rate" label="Burn Rate (gal/hr)" type="number" min="0" step="0.1" hide-details="auto" />
            </v-col>
            <v-col cols="6" md="4">
              <v-text-field v-model="form.fuel_price_per_gallon" :label="`Price/gal (${currencySymbol})`" type="number" min="0" step="0.01" hide-details="auto" />
            </v-col>
            <v-col cols="12">
              <v-text-field v-model="form.location" label="Location" hide-details="auto" />
            </v-col>
            <v-col cols="12">
              <v-textarea v-model="form.notes" label="Notes" rows="2" hide-details="auto" />
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="dialogVisible = false">Cancel</v-btn>
          <v-btn color="primary" prepend-icon="mdi-check" @click="save" :loading="saving">Save</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import * as echarts from 'echarts/core'
import { setupECharts } from '~/utils/echarts'
import { useDarkMode } from '~/composables/useDarkMode'

setupECharts()

const { $swal } = useNuxtApp()
const { currencySymbol } = useCurrency()
const { fetchIdling, fetchIdlingSummary, saveIdlingEvent, deleteIdlingEvent } = useFuelApi()
const { formatFuelDate } = useFuelHelpers()

const props = defineProps<{ vehicleOptions: any[] }>()

const { isDark } = useDarkMode()
const axisLabelColor = computed(() => isDark.value ? '#94a3b8' : '#64748b')
const splitLineColor = computed(() => isDark.value ? '#334155' : '#f1f5f9')

const dialogVisible = ref(false)
const saving = ref(false)
const editingEvent = ref<any>(null)

// ---- Date filters ----
const datePreset = ref('30d')
const customFrom = ref('')
const customTo = ref('')
const customDateDialogVisible = ref(false)
const customDateError = ref('')

const dateLabel = computed(() => {
  if (datePreset.value === 'custom' && (customFrom.value || customTo.value)) {
    return `${customFrom.value || '…'} → ${customTo.value || '…'}`
  }
  return datePreset.value === 'all' ? 'All' : datePreset.value === 'today' ? 'Today' : `${datePreset.value}`
})

function dateRangeQuery() {
  const now = new Date()
  const params: Record<string, string> = {}
  switch (datePreset.value) {
    case 'today': {
      const start = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0)
      const end = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59)
      params.date__gte = start.toISOString()
      params.date__lte = end.toISOString()
      break
    }
    case '7d': {
      params.date__gte = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString()
      break
    }
    case '30d': {
      params.date__gte = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000).toISOString()
      break
    }
    case '90d': {
      params.date__gte = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000).toISOString()
      break
    }
    case 'custom': {
      if (customFrom.value) params.date__gte = new Date(customFrom.value + 'T00:00:00').toISOString()
      if (customTo.value) params.date__lte = new Date(customTo.value + 'T23:59:59').toISOString()
      break
    }
    case 'all':
    default: break
  }
  return params
}

function openCustomDate() { customDateError.value = ''; customDateDialogVisible.value = true }
function applyCustomDate() {
  if (!customFrom.value && !customTo.value) { customDateError.value = 'Please select at least one date.'; return }
  if (customFrom.value && customTo.value && customFrom.value > customTo.value) { customDateError.value = '"From" cannot be after "To".'; return }
  customDateError.value = ''
  customDateDialogVisible.value = false
  datePreset.value = 'custom'
  refreshAll()
}
function cancelCustomDate() {
  customDateDialogVisible.value = false
  customDateError.value = ''
  if (!customFrom.value && !customTo.value) datePreset.value = '30d'
}
function clearCustom() {
  customFrom.value = ''
  customTo.value = ''
  datePreset.value = '30d'
  refreshAll()
}

watch(datePreset, () => refreshAll())

const form = reactive<any>({
  vehicle: null, start_time: new Date().toISOString().slice(0, 16), end_time: '',
  fuel_burn_rate: 0.5, fuel_price_per_gallon: '3.50', location: '', notes: '',
})

const { data: eventData, pending, refresh: refreshEvents } = useAsyncData(
  'fuel-idling-tab',
  () => fetchIdling(dateRangeQuery()).catch(() => ({ results: [] })) as Promise<any>,
  { default: () => ({ results: [] }), watch: [datePreset] }
)
const events = computed(() => eventData.value?.results || [])

const { data: summaryData, refresh: refreshSummary } = useAsyncData(
  'fuel-idling-summary-tab',
  () => fetchIdlingSummary(dateRangeQuery()).catch(() => null),
  { default: () => null, watch: [datePreset] }
)
const summary = computed(() => summaryData.value)

const headers = [
  { title: 'Vehicle', key: 'vehicle_name', sortable: true },
  { title: 'Start', key: 'start_time', sortable: true, width: '160px' },
  { title: 'Duration', key: 'duration', width: '100px' },
  { title: 'Fuel Burned', key: 'fuel_burned', width: '120px' },
  { title: 'Cost', key: 'cost', width: '110px', sortable: true },
  { title: 'Location', key: 'location', width: '150px' },
  { title: 'Notes', key: 'notes', width: '180px' },
  { title: '', key: 'actions', width: '100px', sortable: false },
]

function resetForm() {
  Object.assign(form, {
    vehicle: null, start_time: new Date().toISOString().slice(0, 16), end_time: '',
    fuel_burn_rate: 0.5, fuel_price_per_gallon: '3.50', location: '', notes: '',
  })
}
function openDialog() { editingEvent.value = null; resetForm(); dialogVisible.value = true }
function editEvent(e: any) {
  editingEvent.value = e
  Object.assign(form, {
    vehicle: e.vehicle,
    start_time: e.start_time ? new Date(e.start_time).toISOString().slice(0, 16) : '',
    end_time: e.end_time ? new Date(e.end_time).toISOString().slice(0, 16) : '',
    fuel_burn_rate: e.fuel_burn_rate, fuel_price_per_gallon: String(e.fuel_price_per_gallon),
    location: e.location, notes: e.notes,
  })
  dialogVisible.value = true
}

function refreshAll() { refreshEvents(); refreshSummary() }

async function save() {
  if (!form.vehicle) { $swal.fire({ icon: 'error', title: 'Vehicle required', timer: 3000 }); return }
  saving.value = true
  try {
    const payload = { ...form }
    payload.start_time = new Date(payload.start_time).toISOString()
    if (payload.end_time) payload.end_time = new Date(payload.end_time).toISOString()
    await saveIdlingEvent(payload, editingEvent.value?.id)
    refreshAll()
    dialogVisible.value = false
    $swal.fire({ icon: 'success', title: 'Saved', timer: 1500 })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Save failed', text: e?.data?.detail || 'Could not save', timer: 3000 })
  } finally { saving.value = false }
}

async function removeEvent(e: any) {
  const r = await $swal.fire({ icon: 'warning', title: 'Delete event?', showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!r.isConfirmed) return
  try { await deleteIdlingEvent(e.id); refreshAll() } catch {}
}

const byVehicleOption = computed(() => {
  const vehicles = summary.value?.by_vehicle || []
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: 130, right: 20, top: 10, bottom: 30 },
    xAxis: { type: 'value', axisLabel: { color: axisLabelColor.value, fontSize: 11 }, splitLine: { lineStyle: { color: splitLineColor.value } } },
    yAxis: {
      type: 'category',
      data: vehicles.map((v: any) => v.vehicle || '—'),
      inverse: true,
      axisLabel: { color: axisLabelColor.value, fontSize: 11 },
    },
    series: [{
      type: 'bar', barWidth: '50%',
      data: vehicles.map((v: any) => Number(v.cost).toFixed(2)),
      itemStyle: {
        borderRadius: [0, 4, 4, 0],
        color: new echarts.graphic.LinearGradient(0, 0, 1, 0, [
          { offset: 0, color: '#f87171' }, { offset: 1, color: '#ef4444' },
        ]),
      },
    }],
  }
})
</script>
