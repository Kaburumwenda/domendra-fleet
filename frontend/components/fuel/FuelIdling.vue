<template>
  <div class="d-flex flex-column ga-4">
    <!-- Summary KPIs -->
    <v-row dense>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5" style="background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%)">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-clock-outline</v-icon><span class="text-caption text-white">Events (30d)</span></div>
          <p class="text-h4 font-weight-bold text-white">{{ summary?.total_events || 0 }}</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5" style="background: linear-gradient(135deg, #ef4444 0%, #f87171 100%)">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-timer-sand</v-icon><span class="text-caption text-white">Total Hours</span></div>
          <p class="text-h4 font-weight-bold text-white">{{ summary?.total_hours || 0 }}h</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5" style="background: linear-gradient(135deg, #8b5cf6 0%, #a78bfa 100%)">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-gauge</v-icon><span class="text-caption text-white">Fuel Burned</span></div>
          <p class="text-h4 font-weight-bold text-white">{{ summary?.total_fuel_burned || 0 }} gal</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5" style="background: linear-gradient(135deg, #ec4899 0%, #f472b6 100%)">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-currency-usd-off</v-icon><span class="text-caption text-white">Wasted Cost</span></div>
          <p class="text-h4 font-weight-bold text-white">{{ currencySymbol }}{{ summary?.total_cost || 0 }}</p>
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

const form = reactive<any>({
  vehicle: null, start_time: new Date().toISOString().slice(0, 16), end_time: '',
  fuel_burn_rate: 0.5, fuel_price_per_gallon: '3.50', location: '', notes: '',
})

const { data: eventData, pending, refresh: refreshEvents } = useAsyncData(
  'fuel-idling-tab',
  () => fetchIdling().catch(() => ({ results: [] })) as Promise<any>,
  { default: () => ({ results: [] }) }
)
const events = computed(() => eventData.value?.results || [])

const { data: summaryData, refresh: refreshSummary } = useAsyncData(
  'fuel-idling-summary-tab',
  () => fetchIdlingSummary(30).catch(() => null),
  { default: () => null }
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

async function save() {
  if (!form.vehicle) { $swal.fire({ icon: 'error', title: 'Vehicle required', timer: 3000 }); return }
  saving.value = true
  try {
    const payload = { ...form }
    payload.start_time = new Date(payload.start_time).toISOString()
    if (payload.end_time) payload.end_time = new Date(payload.end_time).toISOString()
    await saveIdlingEvent(payload, editingEvent.value?.id)
    refreshEvents(); refreshSummary()
    dialogVisible.value = false
    $swal.fire({ icon: 'success', title: 'Saved', timer: 1500 })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Save failed', text: e?.data?.detail || 'Could not save', timer: 3000 })
  } finally { saving.value = false }
}

async function removeEvent(e: any) {
  const r = await $swal.fire({ icon: 'warning', title: 'Delete event?', showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!r.isConfirmed) return
  try { await deleteIdlingEvent(e.id); refreshEvents(); refreshSummary() } catch {}
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
