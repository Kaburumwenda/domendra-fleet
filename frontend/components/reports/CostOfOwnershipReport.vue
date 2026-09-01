<template>
  <v-card elevation="0" border rounded="lg" class="pa-5">
    <!-- Header -->
    <div class="d-flex align-center justify-space-between mb-4 flex-wrap ga-2">
      <div class="d-flex align-center ga-2">
        <v-icon color="primary" size="small">mdi-calculator-variant</v-icon>
        <h3 class="text-subtitle-1 font-weight-bold section-heading">Cost of Ownership</h3>
      </div>
      <div class="d-flex ga-1 align-center flex-wrap">
        <v-chip size="small" variant="tonal" color="primary">
          <v-icon size="x-small" start>mdi-truck</v-icon>
          {{ data?.vehicle_count || 0 }} vehicles
        </v-chip>
        <v-chip size="small" variant="tonal" color="error">
          Total: {{ currencySymbol }}{{ fmt(data?.summary?.total_cost) }}
        </v-chip>
        <v-chip size="small" variant="tonal" :color="netPositive ? 'success' : 'warning'">
          Net: {{ netPositive ? '' : '-' }}{{ currencySymbol }}{{ fmt(Math.abs(data?.summary?.net_cost || 0)) }}
        </v-chip>
        <v-btn variant="text" size="small" prepend-icon="mdi-download" color="primary" @click="exportCsv">Export</v-btn>
      </div>
    </div>

    <div v-if="loading" class="d-flex justify-center align-center py-12">
      <v-progress-circular indeterminate size="48" color="primary" />
    </div>
    <div v-else>
      <!-- KPI Row -->
      <v-row dense class="mb-4">
        <v-col cols="6" sm="4" md="2">
          <div class="kpi-card">
            <div class="d-flex align-center ga-1 mb-1">
              <v-icon size="x-small" color="secondary">mdi-chart-line-variant</v-icon>
              <span class="kpi-sub">Capital</span>
            </div>
            <div class="kpi-value">{{ currencySymbol }}{{ fmt(data?.summary?.capital_cost) }}</div>
          </div>
        </v-col>
        <v-col cols="6" sm="4" md="2">
          <div class="kpi-card">
            <div class="d-flex align-center ga-1 mb-1">
              <v-icon size="x-small" color="warning">mdi-gas-station</v-icon>
              <span class="kpi-sub">Energy</span>
            </div>
            <div class="kpi-value">{{ currencySymbol }}{{ fmt(data?.summary?.energy_cost) }}</div>
          </div>
        </v-col>
        <v-col cols="6" sm="4" md="2">
          <div class="kpi-card">
            <div class="d-flex align-center ga-1 mb-1">
              <v-icon size="x-small" color="info">mdi-wrench</v-icon>
              <span class="kpi-sub">Operating</span>
            </div>
            <div class="kpi-value">{{ currencySymbol }}{{ fmt(data?.summary?.operating_cost) }}</div>
          </div>
        </v-col>
        <v-col cols="6" sm="4" md="2">
          <div class="kpi-card">
            <div class="d-flex align-center ga-1 mb-1">
              <v-icon size="x-small" color="error">mdi-cash-off</v-icon>
              <span class="kpi-sub">Total Cost</span>
            </div>
            <div class="kpi-value" style="color: #dc2626">{{ currencySymbol }}{{ fmt(data?.summary?.total_cost) }}</div>
          </div>
        </v-col>
        <v-col cols="6" sm="4" md="2">
          <div class="kpi-card">
            <div class="d-flex align-center ga-1 mb-1">
              <v-icon size="x-small" color="success">mdi-cash-multiple</v-icon>
              <span class="kpi-sub">Revenue</span>
            </div>
            <div class="kpi-value" style="color: #059669">{{ currencySymbol }}{{ fmt(data?.summary?.total_revenue) }}</div>
          </div>
        </v-col>
        <v-col cols="12" sm="4" md="2">
          <div class="kpi-card">
            <div class="d-flex align-center ga-1 mb-1">
              <v-icon size="x-small" color="success">mdi-chart-pie</v-icon>
              <span class="kpi-sub">Book Value</span>
            </div>
            <div class="kpi-value">{{ currencySymbol }}{{ fmt(data?.summary?.total_book_value) }}</div>
          </div>
        </v-col>
      </v-row>

      <v-row dense>
        <!-- Cost Breakdown -->
        <v-col cols="12" md="5">
          <div class="mb-2 text-caption font-weight-medium text-medium-emphasis">Cost Breakdown</div>
          <div class="d-flex flex-column ga-1">
            <div
              v-for="c in data?.breakdown?.length ? data.breakdown : []"
              :key="c.name"
              class="d-flex align-center justify-space-between rounded-lg px-3 py-2"
              style="background: var(--v-theme-surface-variant)"
            >
              <span class="text-body-2 font-weight-medium">{{ c.name }}</span>
              <span class="text-subtitle-2 font-weight-bold">
                {{ currencySymbol }}{{ fmt(c.value) }}
                <span class="text-caption text-medium-emphasis ml-1">({{ pct(c.value, data?.summary?.total_cost) }}%)</span>
              </span>
            </div>
            <div v-if="!data?.breakdown?.length" class="text-center text-medium-emphasis pa-4">
              <v-icon size="36" class="mb-2">mdi-chart-donut</v-icon>
              <p class="text-caption">No cost breakdown available.</p>
            </div>
          </div>
        </v-col>

        <!-- Monthly Trend -->
        <v-col cols="12" md="7">
          <div class="mb-2 text-caption font-weight-medium text-medium-emphasis">Monthly TCO Trend</div>
          <div ref="chartEl" style="height: 280px" />
        </v-col>
      </v-row>

      <v-divider class="my-4" />

      <!-- Per-Vehicle Table -->
      <div class="mb-2 text-caption font-weight-medium text-medium-emphasis">Per-Vehicle Cost of Ownership</div>
      <v-data-table
        :headers="vehicleHeaders"
        :items="data?.vehicles || []"
        density="compact"
        class="rounded-lg preview-table"
        :items-per-page="20"
      >
        <template #item.total_cost="{ value }">
          <span class="font-weight-bold" style="color: #991b1b">{{ currencySymbol }}{{ fmt(value) }}</span>
        </template>
        <template #item.net_profit="{ value }">
          <span :style="{ color: value >= 0 ? '#059669' : '#dc2626' }" class="font-weight-medium">
            {{ value >= 0 ? '' : '-' }}{{ currencySymbol }}{{ fmt(Math.abs(value)) }}
          </span>
        </template>
        <template #item.capital_cost="{ value }"><span class="text-medium-emphasis">{{ currencySymbol }}{{ fmt(value) }}</span></template>
        <template #item.energy_cost="{ value }"><span style="color: #d97706">{{ currencySymbol }}{{ fmt(value) }}</span></template>
        <template #item.operating_cost="{ value }"><span style="color: #2563eb">{{ currencySymbol }}{{ fmt(value) }}</span></template>
        <template #item.cost_per_km="{ value }">{{ value }}</template>
        <template #item.cost_per_day="{ value }">{{ value }}</template>
      </v-data-table>
    </div>
  </v-card>
</template>

<script setup lang="ts">
import * as echarts from 'echarts/core'
import { setupECharts } from '~/utils/echarts'

setupECharts()

const props = defineProps<{ data: any; loading?: boolean }>()
const { currencySymbol } = useCurrency()
const chartEl = ref<HTMLElement | null>(null)
let chart: echarts.ECharts | null = null

const vehicleHeaders = [
  { title: 'Vehicle', key: 'vehicle', width: '22%' },
  { title: 'Ownership', key: 'ownership', align: 'center' as const },
  { title: 'Capital', key: 'capital_cost', align: 'end' as const },
  { title: 'Energy', key: 'energy_cost', align: 'end' as const },
  { title: 'Operating', key: 'operating_cost', align: 'end' as const },
  { title: 'Total', key: 'total_cost', align: 'end' as const },
  { title: 'Revenue', key: 'revenue', align: 'end' as const },
  { title: 'Net', key: 'net_profit', align: 'end' as const },
  { title: '/km', key: 'cost_per_km', align: 'end' as const },
  { title: '/day', key: 'cost_per_day', align: 'end' as const },
]

const netPositive = computed(() => (props.data?.summary?.net_cost || 0) >= 0)

function fmt(n: number | undefined | null) {
  if (!n || isNaN(n)) return '0'
  return Math.round(n).toLocaleString()
}
function pct(val: number, total: number | undefined) {
  if (!val || !total) return 0
  return Math.round((val / total) * 100)
}

function ensureInit() {
  if (!chartEl.value || chartEl.value.clientWidth === 0) return
  chart = echarts.init(chartEl.value)
  renderChart()
}

function renderChart() {
  if (!chart) {
    ensureInit()
    return
  }
  if (!props.data?.monthly) return
  const months = props.data.monthly
  chart.setOption({
    tooltip: { trigger: 'axis', valueFormatter: (v: number) => `${currencySymbol.value}${fmt(v)}` },
    grid: { left: 50, right: 20, top: 20, bottom: 35 },
    xAxis: { type: 'category', data: months.map((m: any) => m.month), axisLabel: { rotate: 35, fontSize: 11 } },
    yAxis: { type: 'value', axisLabel: { formatter: (v: number) => `${currencySymbol.value}${(v / 1000).toFixed(0)}k` } },
    series: [
      {
        type: 'bar',
        data: months.map((m: any) => m.cost),
        itemStyle: { color: '#4f46e5', borderRadius: [6, 6, 0, 0] },
      },
    ],
  })
}

let ro: ResizeObserver | null = null

onMounted(() => {
  ensureInit()
  ro = new ResizeObserver(() => { if (chart) chart.resize(); else ensureInit() })
  if (chartEl.value) ro.observe(chartEl.value)
})

watch(() => props.data, () => renderChart(), { deep: true })

// When loading toggles:
//  - start: dispose the chart so the old DOM node doesn't linger
//  - end:   re-init the chart on the freshly mounted container
watch(() => props.loading, (isLoading) => {
  if (isLoading) {
    if (chart) { chart.dispose(); chart = null }
    return
  }
  nextTick(() => ensureInit())
})

onBeforeUnmount(() => {
  ro?.disconnect()
  chart?.dispose()
  chart = null
})

function exportCsv() {
  if (!props.data?.vehicles?.length) return
  const rows = ['Vehicle,Ownership,Capital,Energy,Operating,Total,Revenue,Net,CostPerKm,CostPerDay']
  for (const v of props.data.vehicles) {
    rows.push(`"${v.vehicle}",${v.ownership},${v.capital_cost},${v.energy_cost},${v.operating_cost},${v.total_cost},${v.revenue},${v.net_profit},${v.cost_per_km},${v.cost_per_day}`)
  }
  const blob = new Blob([rows.join('\n')], { type: 'text/csv' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `cost-of-ownership-${new Date().toISOString().slice(0, 10)}.csv`
  a.click()
  URL.revokeObjectURL(url)
}
</script>

<style scoped>
.section-heading { color: #1e293b; }
.v-theme--dark .section-heading { color: #e2e8f0; }
.kpi-card { padding: 12px; border-radius: 12px; background: rgba(99, 102, 241, 0.06); border: 1px solid rgba(99, 102, 241, 0.12); }
.v-theme--dark .kpi-card { background: rgba(30, 41, 59, 0.4); border-color: rgba(99, 102, 241, 0.18); }
.kpi-value { font-size: 1.05rem; font-weight: 700; color: #1e293b; line-height: 1.2; }
.v-theme--dark .kpi-value { color: #e2e8f0; }
.kpi-sub { font-size: 0.7rem; color: #64748b; text-transform: uppercase; letter-spacing: 0.04em; }
.v-theme--dark .kpi-sub { color: #94a3b8; }
.preview-table :deep(table) { font-size: 0.8rem; }
</style>
