<template>
  <div class="d-flex flex-column ga-4">
    <!-- Filters -->
    <div class="d-flex flex-wrap align-center ga-3">
      <v-btn-toggle v-model="period" mandatory density="compact" color="primary" divided rounded="lg">
        <v-btn value="7" size="small">7d</v-btn>
        <v-btn value="30" size="small">30d</v-btn>
        <v-btn value="90" size="small">90d</v-btn>
        <v-btn value="365" size="small">365d</v-btn>
        <v-btn value="custom" size="small" @click="openCustomDate">Custom…</v-btn>
      </v-btn-toggle>
      <v-chip v-if="customFrom || customTo" size="small" variant="tonal" color="primary" closable @click:close="clearCustom">
        {{ customFrom || '…' }} → {{ customTo || '…' }}
      </v-chip>
      <v-spacer />
      <div class="d-flex ga-2">
        <v-btn v-can="'fuel:export'" variant="tonal" color="primary" size="small" prepend-icon="mdi-file-pdf-box" :loading="pdfLoading" @click="exportFleetPDF">Export PDF</v-btn>
        <v-btn v-can="'fuel:export'" variant="tonal" size="small" prepend-icon="mdi-download" @click="exportData">Export CSV</v-btn>
      </div>
    </div>

    <!-- KPI Row -->
    <v-row dense>
      <v-col cols="6" md="3" v-for="(kpi, i) in kpis" :key="i">
        <v-card elevation="0" border class="pa-5 h-100">
          <div class="d-flex align-center ga-2 mb-2">
            <div class="d-flex align-center justify-center" :style="{ width: '36px', height: '36px', borderRadius: '10px', background: kpi.iconBg }">
              <v-icon :color="kpi.color" size="small">{{ kpi.icon }}</v-icon>
            </div>
            <span class="text-caption text-medium-emphasis">{{ kpi.label }}</span>
          </div>
          <p class="text-h5 font-weight-bold text-high-emphasis">{{ kpi.prefix }}{{ kpi.value }}</p>
          <p v-if="kpi.sub" class="text-caption text-medium-emphasis mt-1">{{ kpi.sub }}</p>
        </v-card>
      </v-col>
    </v-row>

    <!-- Charts row 1 -->
    <v-row dense>
      <v-col cols="12" md="8">
        <DashboardChart :option="dailyCostOption" title="Daily Fuel Cost" icon="mdi-chart-line" height="300px" />
      </v-col>
      <v-col cols="12" md="4">
        <DashboardChart :option="fuelTypeOption" title="By Fuel Type" icon="mdi-fuel" height="300px" />
      </v-col>
    </v-row>

    <!-- Vehicle Fuel Summary Table -->
    <v-card elevation="0" border rounded="lg" class="overflow-hidden">
      <div class="d-flex align-center justify-space-between pa-4 pb-2">
        <h3 class="text-subtitle-1 font-weight-medium d-flex align-center ga-2" style="color: #475569">
          <v-icon size="small" color="primary">mdi-car-multiple</v-icon>
          Vehicle Fuel Summary
        </h3>
        <div class="d-flex ga-2">
          <v-btn v-can="'fuel:export'" variant="tonal" color="primary" size="small" prepend-icon="mdi-file-pdf-box" :loading="pdfLoading" @click="exportFleetPDF">Export PDF</v-btn>
          <v-btn v-can="'fuel:export'" variant="tonal" size="small" prepend-icon="mdi-download" @click="exportData">Export CSV</v-btn>
        </div>
      </div>
      <v-data-table
        :headers="vehicleHeaders"
        :items="vehicleRows"
        :loading="false"
        hover
        density="comfortable"
        :items-per-page="10"
      >
        <template #item.vehicle="{ item }">
          <div class="d-flex align-center ga-2">
            <span class="font-weight-medium">{{ (item as any).vehicle }}</span>
          </div>
        </template>
        <template #item.total_cost="{ value }">
          <span class="font-weight-medium">{{ currencySymbol }}{{ Number(value).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) }}</span>
        </template>
        <template #item.total_gallons="{ value }">
          {{ Number(value).toLocaleString(undefined, { minimumFractionDigits: 1, maximumFractionDigits: 1 }) }}
        </template>
        <template #item.distance="{ value, item }">
          <span v-if="value != null" class="font-weight-medium">{{ Number(value).toLocaleString() }} {{ (item as any).unit === 'liters' ? 'km' : 'mi' }}</span>
          <span v-else class="text-medium-emphasis">—</span>
        </template>
        <template #item.avg_mpg="{ value }">
          <span v-if="value" class="text-success font-weight-medium">{{ Number(value).toFixed(1) }}</span>
          <span v-else class="text-medium-emphasis">—</span>
        </template>
        <template #item.min_odometer="{ value, item }">
          <span v-if="value != null">{{ Number(value).toLocaleString() }} {{ (item as any).unit === 'liters' ? 'km' : 'mi' }}</span>
          <span v-else class="text-medium-emphasis">—</span>
        </template>
        <template #item.max_odometer="{ value, item }">
          <span v-if="value != null">{{ Number(value).toLocaleString() }} {{ (item as any).unit === 'liters' ? 'km' : 'mi' }}</span>
          <span v-else class="text-medium-emphasis">—</span>
        </template>
        <template #item.cost_per_distance="{ value }">
          <span v-if="value != null">{{ currencySymbol }}{{ Number(value).toFixed(2) }}</span>
          <span v-else class="text-medium-emphasis">—</span>
        </template>
        <template #item.actions="{ item }">
          <v-btn icon="mdi-eye-outline" size="x-small" variant="text" color="info" title="View vehicle fuel details" @click="navigateTo(`/app/fuel/vehicle/${(item as any).vehicle_id}`)" />
        </template>
        <template #no-data>
          <div class="text-center py-8 text-medium-emphasis">
            <v-icon size="40" class="mb-2">mdi-car-off</v-icon>
            <p class="text-body-2">No vehicle fuel data for this period.</p>
          </div>
        </template>
      </v-data-table>
    </v-card>

    <!-- Charts row 2 -->
    <v-row dense>
      <v-col cols="12" md="6">
        <DashboardChart :option="priceTrendOption" title="Price / Unit Trend" icon="mdi-chart-bell-curve" height="260px" />
      </v-col>
      <v-col cols="12" md="6">
        <DashboardChart :option="monthlyOption" title="Monthly Trend" icon="mdi-chart-line-variant" height="260px" />
      </v-col>
    </v-row>

    <!-- Top vehicles & stations -->
    <v-row dense>
      <v-col cols="12" md="6">
        <DashboardChart :option="topVehiclesOption" title="Top Vehicles by Cost" icon="mdi-car-multiple" height="260px" />
      </v-col>
      <v-col cols="12" md="6">
        <DashboardChart :option="topStationsOption" title="Top Stations by Spend" icon="mdi-store-marker" height="260px" />
      </v-col>
    </v-row>

    <!-- Vehicle type analysis -->
    <v-row dense>
      <v-col cols="12" md="7">
        <DashboardChart :option="vehicleTypeCostOption" title="Fuel Cost by Vehicle Type" icon="mdi-car-info" height="280px" />
      </v-col>
      <v-col cols="12" md="5">
        <DashboardChart :option="vehicleTypePieOption" title="Vehicle Type Share" icon="mdi-chart-donut" height="280px" />
      </v-col>
    </v-row>

    <!-- Weekday Race -->
    <DashboardChart :option="weekdayRaceOption" title="Fuel Spend by Day of Week" icon="mdi-calendar" height="280px" />

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
  </div>
</template>

<script setup lang="ts">
import * as echarts from 'echarts/core'
import { setupECharts } from '~/utils/echarts'
import { useDarkMode } from '~/composables/useDarkMode'

setupECharts()

const props = defineProps<{ analytics: any }>()
const emit = defineEmits<{
  updatePeriod: [days: number]
  customDateRange: [range: { date__gte: string; date__lte: string } | null]
}>()

const { currencySymbol } = useCurrency()
const { isDark } = useDarkMode()
const period = ref('30')
const customFrom = ref('')
const customTo = ref('')
const customDateDialogVisible = ref(false)
const customDateError = ref('')
const pdfLoading = ref(false)

watch(period, (val) => {
  if (val !== 'custom') emit('updatePeriod', Number(val))
})

function openCustomDate() {
  customDateError.value = ''
  customDateDialogVisible.value = true
}
function applyCustomDate() {
  if (!customFrom.value && !customTo.value) {
    customDateError.value = 'Please select at least one date.'
    return
  }
  if (customFrom.value && customTo.value && customFrom.value > customTo.value) {
    customDateError.value = '"From" date cannot be after "To" date.'
    return
  }
  customDateError.value = ''
  customDateDialogVisible.value = false
  period.value = 'custom'
  const range: any = {}
  if (customFrom.value) range.date__gte = new Date(customFrom.value + 'T00:00:00').toISOString()
  if (customTo.value) range.date__lte = new Date(customTo.value + 'T23:59:59').toISOString()
  emit('customDateRange', range)
}
function cancelCustomDate() {
  customDateDialogVisible.value = false
  customDateError.value = ''
  if (!customFrom.value && !customTo.value) period.value = '30'
}
function clearCustom() {
  customFrom.value = ''
  customTo.value = ''
  period.value = '30'
  emit('customDateRange', null)
  emit('updatePeriod', 30)
}

const axisLabelColor = computed(() => isDark.value ? '#94a3b8' : '#64748b')
const splitLineColor = computed(() => isDark.value ? '#334155' : '#f1f5f9')

const a = computed(() => props.analytics || {})

const kpis = computed(() => [
  {
    label: 'Total Cost', value: Number(a.value.total_cost || 0).toLocaleString(undefined, { maximumFractionDigits: 0 }),
    prefix: currencySymbol.value, icon: 'mdi-currency-usd', sub: `${a.value.transaction_count || 0} txns`,
    color: 'primary', iconBg: 'rgba(99,102,241,0.12)',
  },
  {
    label: 'Total Volume', value: Number(a.value.total_gallons || 0).toLocaleString(undefined, { maximumFractionDigits: 0 }),
    prefix: '', icon: 'mdi-gauge', sub: 'gallons / liters',
    color: 'amber-darken-1', iconBg: 'rgba(245,158,11,0.12)',
  },
  {
    label: 'Avg Price/Unit', value: a.value.avg_price_per_gallon || '0',
    prefix: currencySymbol.value, icon: 'mdi-tag-outline', sub: 'weighted average',
    color: 'success', iconBg: 'rgba(16,185,129,0.12)',
  },
  {
    label: 'Max Transaction', value: Number(a.value.max_transaction_cost || 0).toFixed(0),
    prefix: currencySymbol.value, icon: 'mdi-arrow-up-bold', sub: 'single fill-up',
    color: 'deep-purple', iconBg: 'rgba(139,92,246,0.12)',
  },
])

// ---- Vehicle summary table ----
const vehicleHeaders = [
  { title: '#', key: 'index', width: '50px', sortable: false },
  { title: 'Vehicle', key: 'vehicle', sortable: true, minWidth: '160px' },
  { title: 'Fill-ups', key: 'fill_count', width: '90px', sortable: true, align: 'center' as const },
  { title: 'Total Volume', key: 'total_gallons', width: '120px', sortable: true },
  { title: 'Total Cost', key: 'total_cost', width: '130px', sortable: true },
  { title: 'Cost / Dist', key: 'cost_per_distance', width: '120px', sortable: true },
  { title: 'Distance', key: 'distance', width: '120px', sortable: true },
  { title: 'Min Odo', key: 'min_odometer', width: '120px', sortable: true },
  { title: 'Max Odo', key: 'max_odometer', width: '120px', sortable: true },
  { title: 'Avg MPG', key: 'avg_mpg', width: '90px', sortable: true },
  { title: '', key: 'actions', width: '60px', sortable: false },
]

const vehicleRows = computed(() => {
  const list = a.value.by_vehicle || []
  return list.map((v: any, i: number) => {
    const name = `${v.vehicle__make || ''} ${v.vehicle__model || ''}`.trim() || v.vehicle__license_plate || '—'
    const dist = v.distance ?? null
    const totalCost = Number(v.total_cost || 0)
    return {
      index: i + 1,
      vehicle_id: v.vehicle_id,
      vehicle: name,
      fill_count: v.fill_count || 0,
      total_gallons: v.total_gallons || 0,
      total_cost: totalCost,
      cost_per_distance: dist ? totalCost / dist : null,
      distance: dist,
      min_odometer: v.min_odometer ?? null,
      max_odometer: v.max_odometer ?? null,
      avg_mpg: v.avg_mpg ?? null,
    }
  })
})

const dailyCostOption = computed(() => {
  const daily = a.value.daily_trend || []
  return {
    tooltip: { trigger: 'axis' },
    legend: { data: ['Cost', 'Gallons'], textStyle: { color: axisLabelColor.value } },
    grid: { left: 50, right: 50, top: 40, bottom: 30 },
    xAxis: { type: 'category', data: daily.map((d: any) => d.day), axisLabel: { color: axisLabelColor.value, fontSize: 11 } },
    yAxis: [
      { type: 'value', name: 'Cost', axisLabel: { color: axisLabelColor.value, fontSize: 11 }, splitLine: { lineStyle: { color: splitLineColor.value } } },
      { type: 'value', name: 'Gallons', axisLabel: { color: axisLabelColor.value, fontSize: 11 } },
    ],
    series: [
      {
        name: 'Cost', type: 'line', smooth: true, symbol: 'circle', symbolSize: 6,
        data: daily.map((d: any) => Number(d.total_cost).toFixed(2)),
        lineStyle: { width: 3, color: '#6366f1' }, itemStyle: { color: '#6366f1' },
        areaStyle: { color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{ offset: 0, color: 'rgba(99,102,241,0.25)' }, { offset: 1, color: 'rgba(99,102,241,0.02)' }]) },
      },
      {
        name: 'Gallons', type: 'bar', yAxisIndex: 1, barWidth: '40%',
        data: daily.map((d: any) => Number(d.total_gallons).toFixed(1)),
        itemStyle: { borderRadius: [4, 4, 0, 0], color: 'rgba(245,158,11,0.6)' },
      },
    ],
  }
})

const fuelTypeOption = computed(() => {
  const data = (a.value.by_fuel_type || []).map((f: any) => ({ name: f.fuel_type, value: Number(f.total_cost).toFixed(2) }))
  return {
    tooltip: { trigger: 'item' },
    legend: { bottom: 0, textStyle: { color: axisLabelColor.value, fontSize: 11 }, type: 'scroll' },
    color: ['#6366f1', '#f59e0b', '#10b981', '#8b5cf6', '#ec4899', '#06b6d4', '#84cc16', '#ef4444'],
    series: [{
      type: 'pie', radius: ['40%', '70%'], center: ['50%', '45%'],
      label: { show: false },
      emphasis: { label: { show: true, fontSize: 14, fontWeight: 'bold' } },
      data,
    }],
  }
})

const priceTrendOption = computed(() => {
  const trend = a.value.price_trend || []
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: 50, right: 20, top: 20, bottom: 30 },
    xAxis: { type: 'category', data: trend.map((t: any) => t.day), axisLabel: { color: axisLabelColor.value, fontSize: 11 } },
    yAxis: { type: 'value', axisLabel: { color: axisLabelColor.value, fontSize: 11 }, splitLine: { lineStyle: { color: splitLineColor.value } } },
    series: [{
      type: 'line', smooth: true, symbol: 'none',
      data: trend.map((t: any) => t.avg_price_per_gallon),
      lineStyle: { width: 2, color: '#10b981' },
      areaStyle: { color: 'rgba(16,185,129,0.15)' },
    }],
  }
})

const monthlyOption = computed(() => {
  const months = a.value.monthly_trend || []
  return {
    tooltip: { trigger: 'axis' },
    legend: { data: ['Cost', 'Gallons'], textStyle: { color: axisLabelColor.value } },
    grid: { left: 50, right: 50, top: 40, bottom: 30 },
    xAxis: { type: 'category', data: months.map((m: any) => m.month), axisLabel: { color: axisLabelColor.value, fontSize: 11 } },
    yAxis: [
      { type: 'value', name: 'Cost', axisLabel: { color: axisLabelColor.value, fontSize: 11 }, splitLine: { lineStyle: { color: splitLineColor.value } } },
      { type: 'value', name: 'Gallons', axisLabel: { color: axisLabelColor.value, fontSize: 11 } },
    ],
    series: [
      { name: 'Cost', type: 'bar', data: months.map((m: any) => Number(m.total_cost).toFixed(2)), itemStyle: { borderRadius: [4, 4, 0, 0], color: '#6366f1' } },
      { name: 'Gallons', type: 'line', yAxisIndex: 1, data: months.map((m: any) => Number(m.total_gallons).toFixed(1)), lineStyle: { color: '#f59e0b' } },
    ],
  }
})

const topVehiclesOption = computed(() => {
  const vehicles = (a.value.by_vehicle || []).slice(0, 10)
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: 180, right: 20, top: 10, bottom: 30 },
    xAxis: { type: 'value', axisLabel: { color: axisLabelColor.value, fontSize: 11 }, splitLine: { lineStyle: { color: splitLineColor.value } } },
    yAxis: {
      type: 'category', inverse: true,
      data: vehicles.map((v: any) => `${v.vehicle__make || ''} ${v.vehicle__model || ''}`.trim() || v.vehicle__license_plate || '—'),
      axisLabel: { color: axisLabelColor.value, fontSize: 11 },
    },
    series: [{
      type: 'bar', barWidth: '50%',
      data: vehicles.map((v: any) => Number(v.total_cost).toFixed(2)),
      itemStyle: {
        borderRadius: [0, 4, 4, 0],
        color: new echarts.graphic.LinearGradient(0, 0, 1, 0, [{ offset: 0, color: '#818cf8' }, { offset: 1, color: '#6366f1' }]),
      },
    }],
  }
})

const topStationsOption = computed(() => {
  const stations = (a.value.by_station || []).slice(0, 10)
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: 180, right: 20, top: 10, bottom: 30 },
    xAxis: { type: 'value', axisLabel: { color: axisLabelColor.value, fontSize: 11 }, splitLine: { lineStyle: { color: splitLineColor.value } } },
    yAxis: {
      type: 'category', inverse: true,
      data: stations.map((s: any) => s.station_name || '—'),
      axisLabel: { color: axisLabelColor.value, fontSize: 11 },
    },
    series: [{
      type: 'bar', barWidth: '50%',
      data: stations.map((s: any) => Number(s.total_cost).toFixed(2)),
      itemStyle: {
        borderRadius: [0, 4, 4, 0],
        color: new echarts.graphic.LinearGradient(0, 0, 1, 0, [{ offset: 0, color: '#fbbf24' }, { offset: 1, color: '#f59e0b' }]),
      },
    }],
  }
})

const weekdayRaceOption = computed(() => {
  // Aggregate daily trend by weekday
  const daily = a.value.daily_trend || []
  const weekdayTotals: Record<string, number> = { 'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0 }
  const wdMap: Record<number, string> = { 0: 'Sun', 1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat' }
  for (const d of daily) {
    if (!d.day) continue
    const dt = new Date(d.day)
    const wd = wdMap[dt.getDay()]
    if (wd && weekdayTotals[wd] !== undefined) weekdayTotals[wd] += Number(d.total_cost || 0)
  }
  const order = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: 50, right: 20, top: 20, bottom: 30 },
    xAxis: { type: 'category', data: order, axisLabel: { color: axisLabelColor.value, fontSize: 12 } },
    yAxis: { type: 'value', axisLabel: { color: axisLabelColor.value, fontSize: 11 }, splitLine: { lineStyle: { color: splitLineColor.value } } },
    series: [{
      type: 'bar', barWidth: '50%',
      data: order.map((d) => weekdayTotals[d].toFixed(2)),
      itemStyle: {
        borderRadius: [4, 4, 0, 0],
        color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{ offset: 0, color: '#34d399' }, { offset: 1, color: '#10b981' }]),
      },
      label: { show: true, position: 'top', color: axisLabelColor.value, fontSize: 11 },
    }],
  }
})

const vehicleTypeCostOption = computed(() => {
  const types = a.value.by_vehicle_type || []
  return {
    tooltip: { trigger: 'axis' },
    legend: { data: ['Cost', 'Volume'], textStyle: { color: axisLabelColor.value }, bottom: 0 },
    grid: { left: 50, right: 50, top: 20, bottom: 50 },
    xAxis: {
      type: 'category',
      data: types.map((t: any) => t.vehicle__vehicle_type || 'Unknown'),
      axisLabel: { color: axisLabelColor.value, fontSize: 11, interval: 0, rotate: types.length > 4 ? 20 : 0 },
    },
    yAxis: [
      { type: 'value', name: 'Cost', axisLabel: { color: axisLabelColor.value, fontSize: 11 }, splitLine: { lineStyle: { color: splitLineColor.value } } },
      { type: 'value', name: 'Volume', axisLabel: { color: axisLabelColor.value, fontSize: 11 } },
    ],
    series: [
      {
        name: 'Cost', type: 'bar', barWidth: '40%',
        data: types.map((t: any) => Number(t.total_cost).toFixed(2)),
        itemStyle: {
          borderRadius: [4, 4, 0, 0],
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{ offset: 0, color: '#818cf8' }, { offset: 1, color: '#6366f1' }]),
        },
      },
      {
        name: 'Volume', type: 'line', yAxisIndex: 1, smooth: true, symbol: 'circle', symbolSize: 8,
        data: types.map((t: any) => Number(t.total_gallons).toFixed(2)),
        lineStyle: { width: 3, color: '#f59e0b' },
        itemStyle: { color: '#f59e0b' },
      },
    ],
  }
})

const vehicleTypePieOption = computed(() => {
  const types = a.value.by_vehicle_type || []
  const data = types.map((t: any) => ({ name: t.vehicle__vehicle_type || 'Unknown', value: Number(t.total_cost).toFixed(2) }))
  return {
    tooltip: { trigger: 'item', formatter: '{b}: $' + '{c} ({d}%)' },
    legend: { bottom: 0, textStyle: { color: axisLabelColor.value, fontSize: 11 }, type: 'scroll' },
    color: ['#6366f1', '#f59e0b', '#10b981', '#8b5cf6', '#ec4899', '#06b6d4', '#84cc16', '#ef4444'],
    series: [{
      type: 'pie', radius: ['40%', '70%'], center: ['50%', '45%'],
      label: { show: false },
      emphasis: { label: { show: true, fontSize: 14, fontWeight: 'bold', formatter: '{b}\n{d}%' } },
      data,
    }],
  }
})

function exportData() {
  const rows = vehicleRows.value.map((v: any) => [
    v.index,
    v.vehicle,
    v.fill_count,
    Number(v.total_gallons).toFixed(2),
    Number(v.total_cost).toFixed(2),
    v.distance != null ? v.distance : '',
    v.min_odometer != null ? v.min_odometer : '',
    v.max_odometer != null ? v.max_odometer : '',
    v.avg_mpg ? Number(v.avg_mpg).toFixed(1) : '',
    v.cost_per_distance != null ? Number(v.cost_per_distance).toFixed(2) : '',
  ])
  rows.unshift(['#', 'Vehicle', 'Fill-ups', 'Volume', 'Cost', 'Distance', 'Min Odo', 'Max Odo', 'Avg MPG', 'Cost/Distance'])
  const csv = rows.map((r) => r.map((c) => `"${c}"`).join(',')).join('\n')
  const blob = new Blob([csv], { type: 'text/csv' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = `fuel-vehicle-report-${new Date().toISOString().slice(0, 10)}.csv`
  link.click()
  URL.revokeObjectURL(url)
}

function buildDateParams(): Record<string, string> {
  const params: Record<string, string> = {}
  if (period.value === 'custom' && (customFrom.value || customTo.value)) {
    if (customFrom.value) params.date__gte = new Date(customFrom.value + 'T00:00:00').toISOString()
    if (customTo.value) params.date__lte = new Date(customTo.value + 'T23:59:59').toISOString()
  } else if (period.value !== 'custom') {
    params.days = period.value
  }
  return params
}

async function exportFleetPDF() {
  pdfLoading.value = true
  try {
    const auth = useAuthStore()
    const token = auth.accessToken || localStorage.getItem('fc_access') || ''
    const tenantSchema = auth.tenantSchema || localStorage.getItem('fc_tenant') || ''
    const qp = buildDateParams()
    const qs = new URLSearchParams(qp).toString()
    const url = `${useRuntimeConfig().public.apiBase}/fuel/transactions/fleet-pdf/${qs ? '?' + qs : ''}`
    const res = await fetch(url, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${token}`,
        'x-tenant-schema': tenantSchema,
      },
    })
    if (!res.ok) throw new Error('Failed to generate PDF')
    const blob = await res.blob()
    const blobUrl = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = blobUrl
    link.download = `fleet-fuel-report-${new Date().toISOString().slice(0, 10)}.pdf`
    link.click()
    URL.revokeObjectURL(blobUrl)
  } catch (e) {
    console.error('Fleet PDF export error:', e)
  } finally {
    pdfLoading.value = false
  }
}
</script>
