<template>
  <div class="d-flex flex-column ga-4">
    <!-- Summary -->
    <div class="d-flex align-center flex-wrap ga-2 mb-2">
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
    <v-row dense>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5">
          <div class="d-flex align-center ga-2 mb-2">
            <div class="d-flex align-center justify-center" style="width: 36px; height: 36px; border-radius: 10px; background: rgba(16,185,129,0.12)">
              <v-icon color="success" size="small">mdi-flash</v-icon>
            </div>
            <span class="text-caption text-medium-emphasis">Sessions ({{ dateLabel }})</span>
          </div>
          <p class="text-h4 font-weight-bold text-high-emphasis">{{ summary?.session_count || 0 }}</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5">
          <div class="d-flex align-center ga-2 mb-2">
            <div class="d-flex align-center justify-center" style="width: 36px; height: 36px; border-radius: 10px; background: rgba(6,182,212,0.12)">
              <v-icon color="cyan-darken-1" size="small">mdi-battery-charging</v-icon>
            </div>
            <span class="text-caption text-medium-emphasis">Total kWh</span>
          </div>
          <p class="text-h4 font-weight-bold text-high-emphasis">{{ summary?.total_kwh?.toFixed(1) || '0' }}</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5">
          <div class="d-flex align-center ga-2 mb-2">
            <div class="d-flex align-center justify-center" style="width: 36px; height: 36px; border-radius: 10px; background: rgba(139,92,246,0.12)">
              <v-icon color="deep-purple" size="small">mdi-currency-usd</v-icon>
            </div>
            <span class="text-caption text-medium-emphasis">Total Cost</span>
          </div>
          <p class="text-h4 font-weight-bold text-high-emphasis">{{ currencySymbol }}{{ summary?.total_cost?.toFixed(0) || '0' }}</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5">
          <div class="d-flex align-center ga-2 mb-2">
            <div class="d-flex align-center justify-center" style="width: 36px; height: 36px; border-radius: 10px; background: rgba(245,158,11,0.12)">
              <v-icon color="amber-darken-1" size="small">mdi-chart-line</v-icon>
            </div>
            <span class="text-caption text-medium-emphasis">Avg /kWh</span>
          </div>
          <p class="text-h4 font-weight-bold text-high-emphasis">{{ currencySymbol }}{{ summary?.avg_cost_per_kwh || '0' }}</p>
        </v-card>
      </v-col>
    </v-row>

    <!-- Chart toggle row -->
    <v-row dense v-if="(summary?.by_network || []).length">
      <v-col cols="12" md="6">
        <DashboardChart :option="networkOption" title="Cost by Charging Network" icon="mdi-ev-station" height="260px" />
      </v-col>
      <v-col cols="12" md="6">
        <DashboardChart :option="vehicleOption" title="Charging by Vehicle" icon="mdi-car-electric" height="260px" />
      </v-col>
    </v-row>

    <!-- Sessions table -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-2">
      <span class="text-caption text-medium-emphasis">{{ sessions.length }} charging sessions</span>
      <v-btn v-can="'fuel:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="openDialog()">Add Session</v-btn>
    </div>

    <v-card elevation="0" border rounded="lg">
      <v-data-table :headers="headers" :items="sessions" :loading="pending" hover items-per-page="15">
        <template #item.start_time="{ value }">
          <div class="d-flex flex-column">
            <span class="text-body-2 font-weight-medium">{{ formatFuelDate(value).date }}</span>
            <span class="text-caption text-medium-emphasis">{{ formatFuelDate(value).time }}</span>
          </div>
        </template>
        <template #item.vehicle_name="{ value }">
          <span class="font-weight-medium">{{ value || '—' }}</span>
        </template>
        <template #item.station_network="{ value }">
          <v-chip size="small" variant="tonal" color="success">{{ networkLabel(value) }}</v-chip>
        </template>
        <template #item.energy_kwh="{ value }"><span class="font-weight-medium">{{ value }} kWh</span></template>
        <template #item.cost="{ value }">{{ currencySymbol }}{{ parseFloat(value || 0).toFixed(2) }}</template>
        <template #item.duration="{ item }">
          <span v-if="(item as any).duration_hours" class="text-body-2">{{ (item as any).duration_hours }}h</span>
          <span v-else class="text-medium-emphasis">—</span>
        </template>
        <template #item.soc="{ item }">
          <div v-if="(item as any).start_soc != null || (item as any).end_soc != null" class="d-flex align-center ga-1">
            <span class="text-caption">{{ (item as any).start_soc ?? '—' }}%</span>
            <v-icon size="x-small">mdi-arrow-right</v-icon>
            <span class="text-caption font-weight-medium text-success">{{ (item as any).end_soc ?? '—' }}%</span>
          </div>
          <span v-else class="text-medium-emphasis">—</span>
        </template>
        <template #item.actions="{ item }">
          <div class="d-flex ga-1">
            <v-btn v-can="'fuel:update'" icon="mdi-pencil-outline" size="x-small" variant="text" color="warning" title="Edit" @click="editSession(item)" />
            <v-btn v-can="'fuel:delete'" icon="mdi-delete-outline" size="x-small" variant="text" color="error" title="Delete" @click="removeSession(item)" />
          </div>
        </template>
        <template #no-data>
          <div class="text-center py-12 text-medium-emphasis">
            <v-icon size="48" class="mb-3">mdi-ev-station</v-icon>
            <p>No charging sessions yet.</p>
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
    <v-dialog v-model="dialogVisible" max-width="540" scroll-strategy="none">
      <v-card rounded="xl" class="overflow-hidden">
        <AppModalHeader icon="mdi-ev-station">{{ editingSession ? 'Edit' : 'Add' }} Charging Session</AppModalHeader>
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
            <v-col cols="6" md="3">
              <v-text-field v-model.number="form.energy_kwh" label="Energy (kWh) *" type="number" min="0" step="0.1" hide-details="auto" />
            </v-col>
            <v-col cols="6" md="3">
              <v-text-field v-model="form.cost" :label="`Cost (${currencySymbol}) *`" type="number" min="0" step="0.01" hide-details="auto" />
            </v-col>
            <v-col cols="6" md="3">
              <v-text-field v-model.number="form.start_soc" label="Start SOC %" type="number" min="0" max="100" hide-details="auto" />
            </v-col>
            <v-col cols="6" md="3">
              <v-text-field v-model.number="form.end_soc" label="End SOC %" type="number" min="0" max="100" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="form.station_name" label="Station Name" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="6">
              <v-select v-model="form.station_network" :items="CHARGING_NETWORKS" item-title="label" item-value="value" label="Network" hide-details="auto" />
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
const { fetchCharging, fetchChargingSummary, saveChargingSession, deleteChargingSession } = useFuelApi()
const { CHARGING_NETWORKS, networkLabel, formatFuelDate } = useFuelHelpers()

const props = defineProps<{ vehicleOptions: any[] }>()
const emit = defineEmits<{ refresh: [] }>()

const { isDark } = useDarkMode()
const axisLabelColor = computed(() => isDark.value ? '#94a3b8' : '#64748b')

const dialogVisible = ref(false)
const saving = ref(false)
const editingSession = ref<any>(null)

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
  energy_kwh: 0, cost: '0', start_soc: null, end_soc: null,
  station_name: '', station_network: 'other',
})

const { data: sessionData, pending, refresh: refreshSessions } = useAsyncData(
  'fuel-charging-tab',
  () => fetchCharging(dateRangeQuery()).catch(() => ({ results: [] })) as Promise<any>,
  { default: () => ({ results: [] }), watch: [datePreset] }
)
const sessions = computed(() => sessionData.value?.results || [])

const { data: summaryData, refresh: refreshSummary } = useAsyncData(
  'fuel-charging-summary-tab',
  () => fetchChargingSummary(dateRangeQuery()).catch(() => null),
  { default: () => null, watch: [datePreset] }
)
const summary = computed(() => summaryData.value)

const headers = [
  { title: 'Vehicle', key: 'vehicle_name', sortable: true },
  { title: 'Start', key: 'start_time', sortable: true, width: '160px' },
  { title: 'Network', key: 'station_network', width: '130px' },
  { title: 'Station', key: 'station_name', width: '150px' },
  { title: 'Energy', key: 'energy_kwh', width: '100px', sortable: true },
  { title: 'Cost', key: 'cost', width: '100px', sortable: true },
  { title: 'Duration', key: 'duration', width: '90px' },
  { title: 'SOC', key: 'soc', width: '100px' },
  { title: '', key: 'actions', width: '100px', sortable: false },
]

function resetForm() {
  Object.assign(form, {
    vehicle: null, start_time: new Date().toISOString().slice(0, 16), end_time: '',
    energy_kwh: 0, cost: '0', start_soc: null, end_soc: null,
    station_name: '', station_network: 'other',
  })
}
function openDialog() { editingSession.value = null; resetForm(); dialogVisible.value = true }
function editSession(s: any) {
  editingSession.value = s
  Object.assign(form, {
    vehicle: s.vehicle,
    start_time: s.start_time ? new Date(s.start_time).toISOString().slice(0, 16) : '',
    end_time: s.end_time ? new Date(s.end_time).toISOString().slice(0, 16) : '',
    energy_kwh: s.energy_kwh, cost: String(s.cost), start_soc: s.start_soc, end_soc: s.end_soc,
    station_name: s.station_name, station_network: s.station_network,
  })
  dialogVisible.value = true
}

function refreshAll() { refreshSessions(); refreshSummary() }

async function save() {
  if (!form.vehicle) { $swal.fire({ icon: 'error', title: 'Vehicle required', timer: 3000 }); return }
  saving.value = true
  try {
    const payload = { ...form }
    payload.start_time = new Date(payload.start_time).toISOString()
    if (payload.end_time) payload.end_time = new Date(payload.end_time).toISOString()
    await saveChargingSession(payload, editingSession.value?.id)
    refreshAll()
    dialogVisible.value = false
    $swal.fire({ icon: 'success', title: 'Saved', timer: 1500 })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Save failed', text: e?.data?.detail || 'Could not save', timer: 3000 })
  } finally { saving.value = false }
}
async function removeSession(s: any) {
  const r = await $swal.fire({ icon: 'warning', title: 'Delete session?', showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!r.isConfirmed) return
  try { await deleteChargingSession(s.id); refreshAll() } catch {}
}

// ---- Charts ----
const networkOption = computed(() => {
  const data = (summary.value?.by_network || []).map((n: any) => ({
    name: networkLabel(n.station_network),
    value: Number(n.total_cost).toFixed(2),
  }))
  return {
    tooltip: { trigger: 'item' },
    legend: { bottom: 0, textStyle: { color: axisLabelColor.value, fontSize: 11 } },
    series: [{
      type: 'pie', radius: ['35%', '65%'], center: ['50%', '45%'],
      label: { color: axisLabelColor.value, fontSize: 11 },
      data,
    }],
  }
})
const vehicleOption = computed(() => {
  const vehicles = summary.value?.by_vehicle || []
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: 130, right: 20, top: 10, bottom: 30 },
    xAxis: { type: 'value', axisLabel: { color: axisLabelColor.value, fontSize: 11 } },
    yAxis: {
      type: 'category',
      data: vehicles.map((v: any) => `${v.vehicle__make || ''} ${v.vehicle__model || ''}`.trim() || v.vehicle__license_plate || '—'),
      inverse: true,
      axisLabel: { color: axisLabelColor.value, fontSize: 11 },
    },
    series: [{
      type: 'bar', barWidth: '50%',
      data: vehicles.map((v: any) => Number(v.total_kwh).toFixed(1)),
      itemStyle: {
        borderRadius: [0, 4, 4, 0],
        color: new echarts.graphic.LinearGradient(0, 0, 1, 0, [
          { offset: 0, color: '#34d399' }, { offset: 1, color: '#10b981' },
        ]),
      },
    }],
  }
})
</script>
