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
      <v-btn v-can="'fuel:export'" variant="tonal" size="small" prepend-icon="mdi-download" @click="exportData">Export CSV</v-btn>
    </div>

    <!-- KPI Row -->
    <v-row dense>
      <v-col cols="6" md="3" v-for="(kpi, i) in kpis" :key="i">
        <v-card elevation="0" border class="pa-5" :style="kpi.bg">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">{{ kpi.icon }}</v-icon><span class="text-caption text-white">{{ kpi.label }}</span></div>
          <p class="text-h5 font-weight-bold text-white">{{ kpi.prefix }}{{ kpi.value }}</p>
          <p v-if="kpi.sub" class="text-caption text-white" style="opacity: 0.8">{{ kpi.sub }}</p>
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
    bg: 'background: linear-gradient(135deg, #6366f1 0%, #818cf8 100%)',
  },
  {
    label: 'Total Volume', value: Number(a.value.total_gallons || 0).toLocaleString(undefined, { maximumFractionDigits: 0 }),
    prefix: '', icon: 'mdi-gauge', sub: 'gallons / liters',
    bg: 'background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%)',
  },
  {
    label: 'Avg Price/Unit', value: a.value.avg_price_per_gallon || '0',
    prefix: currencySymbol.value, icon: 'mdi-tag-outline', sub: 'weighted average',
    bg: 'background: linear-gradient(135deg, #10b981 0%, #34d399 100%)',
  },
  {
    label: 'Max Transaction', value: Number(a.value.max_transaction_cost || 0).toFixed(0),
    prefix: currencySymbol.value, icon: 'mdi-arrow-up-bold', sub: 'single fill-up',
    bg: 'background: linear-gradient(135deg, #8b5cf6 0%, #a78bfa 100%)',
  },
])

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
    grid: { left: 140, right: 20, top: 10, bottom: 30 },
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
    grid: { left: 140, right: 20, top: 10, bottom: 30 },
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
  const rows = (a.value.by_vehicle || []).map((v: any, i: number) => [
    i + 1,
    `${v.vehicle__make || ''} ${v.vehicle__model || ''}`.trim() || v.vehicle__license_plate,
    Number(v.total_gallons).toFixed(2),
    Number(v.total_cost).toFixed(2),
    v.fill_count,
  ])
  rows.unshift(['#', 'Vehicle', 'Gallons', 'Cost', 'Fill-ups'])
  const csv = rows.map((r) => r.map((c) => `"${c}"`).join(',')).join('\n')
  const blob = new Blob([csv], { type: 'text/csv' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = `fuel-vehicle-report-${new Date().toISOString().slice(0, 10)}.csv`
  link.click()
  URL.revokeObjectURL(url)
}
</script>
