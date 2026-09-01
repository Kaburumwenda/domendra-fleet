<template>
  <v-card elevation="0" border rounded="lg" class="pa-5">
    <div class="d-flex align-center justify-space-between mb-4 flex-wrap ga-2">
      <div class="d-flex align-center ga-2">
        <v-icon color="primary" size="small">mdi-tanker-truck</v-icon>
        <h3 class="text-subtitle-1 font-weight-bold section-heading">Revenue Analysis</h3>
      </div>
      <div class="d-flex ga-1">
        <v-chip size="small" variant="tonal" color="success">Total: {{ currencySymbol }}{{ formatNum(data?.total_revenue) }}</v-chip>
        <v-chip size="small" variant="tonal" color="deep-purple">Add-ons: {{ currencySymbol }}{{ formatNum(data?.addon_total) }}</v-chip>
        <v-btn variant="text" size="small" prepend-icon="mdi-download" color="primary" @click="exportCsv">Export</v-btn>
      </div>
    </div>

    <v-row dense>
      <!-- Revenue by Customer -->
      <v-col cols="12" md="6">
        <div class="mb-2 text-caption font-weight-medium text-medium-emphasis">Top Customers by Revenue</div>
        <div class="d-flex flex-column ga-1">
          <div v-for="c in (data?.by_customer || []).slice(0, 8)" :key="c.customer" class="d-flex align-center justify-space-between rounded-lg px-3 py-2 rev-tile-customer">
            <div class="d-flex align-center ga-2">
              <v-avatar size="28" color="indigo" variant="tonal"><span class="text-caption font-weight-bold">{{ initials(c.customer) }}</span></v-avatar>
              <div>
                <div class="text-body-2 font-weight-medium">{{ c.customer }}</div>
                <div class="text-caption text-medium-emphasis">{{ c.count }} rental{{ c.count !== 1 ? 's' : '' }}</div>
              </div>
            </div>
            <span class="text-subtitle-2 font-weight-bold text-revenue-green">{{ currencySymbol }}{{ formatNum(c.revenue) }}</span>
          </div>
        </div>
      </v-col>

      <!-- Revenue by Vehicle -->
      <v-col cols="12" md="6">
        <div class="mb-2 text-caption font-weight-medium text-medium-emphasis">Top Vehicles by Revenue</div>
        <v-data-table
          :headers="vehicleHeaders"
          :items="data?.by_vehicle || []"
          density="compact"
          hide-default-footer
          :items-per-page="8"
          class="rounded-lg"
        >
          <template #item.revenue="{ value }"><span class="font-weight-bold text-revenue-green">{{ currencySymbol }}{{ formatNum(value) }}</span></template>
          <template #item.driver_cost="{ value }"><span class="text-revenue-red">{{ currencySymbol }}{{ formatNum(value) }}</span></template>
          <template #item.net="{ value }"><span class="font-weight-bold" :class="value >= 0 ? 'text-revenue-green' : 'text-revenue-red-dark'">{{ currencySymbol }}{{ formatNum(value) }}</span></template>

        </v-data-table>
      </v-col>
    </v-row>

    <!-- Add-on Revenue + Payment Methods -->
    <v-row dense class="mt-2">
      <v-col cols="12" md="6">
        <div class="mb-2 text-caption font-weight-medium text-medium-emphasis">Add-on Revenue Breakdown</div>
        <div class="d-flex flex-column ga-1">
          <div v-for="(val, key) in data?.addon_revenue || {}" :key="key" class="d-flex align-center justify-space-between rounded-lg px-3 py-1.5 rev-tile-addon">
            <div class="d-flex align-center ga-2">
              <v-icon size="x-small" color="deep-purple">{{ addonIcon(key) }}</v-icon>
              <span class="text-body-2 text-capitalize">{{ key.replace(/_/g, ' ') }}</span>
            </div>
            <span class="text-body-2 font-weight-medium text-revenue-purple">{{ currencySymbol }}{{ formatNum(val) }}</span>
          </div>
        </div>
      </v-col>

      <v-col cols="12" md="6">
        <div class="mb-2 text-caption font-weight-medium text-medium-emphasis">Payments by Method</div>
        <div class="d-flex flex-column ga-1">
          <div v-for="m in data?.payment_methods || []" :key="m.method" class="d-flex align-center justify-space-between rounded-lg px-3 py-1.5 rev-tile-payment">
            <div class="d-flex align-center ga-2">
              <v-icon size="x-small" color="primary">{{ methodIcon(m.method) }}</v-icon>
              <span class="text-body-2 text-capitalize font-weight-medium">{{ m.method }}</span>
              <v-chip size="x-small" variant="flat" color="grey">{{ m.count }}</v-chip>
            </div>
            <span class="text-body-2 font-weight-bold text-revenue-blue">{{ currencySymbol }}{{ formatNum(m.amount) }}</span>
          </div>
        </div>
      </v-col>
    </v-row>

    <!-- Revenue Trend Chart -->
    <v-divider class="my-4" />
    <div class="d-flex align-center ga-2 mb-3">
      <v-icon color="success" size="small">mdi-chart-areaspline</v-icon>
      <h3 class="text-subtitle-2 font-weight-bold section-heading">Revenue Trend</h3>
      <v-chip size="x-small" variant="tonal" color="success">{{ currencySymbol }}{{ formatNum(data?.total_revenue) }} total</v-chip>
    </div>
    <div ref="chartEl" style="height: 300px" />
  </v-card>
</template>

<script setup lang="ts">
import * as echarts from 'echarts/core'
import { setupECharts } from '~/utils/echarts'

setupECharts()

const props = defineProps<{ data: any }>()
const { currencySymbol } = useCurrency()
const chartEl = ref<HTMLElement | null>(null)
let chart: echarts.ECharts | null = null

const vehicleHeaders = [
  { title: 'Vehicle', key: 'vehicle', width: '30%' },
  { title: 'Count', key: 'count', width: '60px' },
  { title: 'Revenue', key: 'revenue', align: 'end' as const },
  { title: 'Driver Cost', key: 'driver_cost', align: 'end' as const },
  { title: 'Net', key: 'net', align: 'end' as const },
]

function formatNum(n: number | undefined) {
  if (!n) return '0'
  return Math.round(n).toLocaleString()
}
function initials(s: string) { return s.split(' ').slice(0, 2).map(w => w[0]).join('').toUpperCase() }
function ensureInit() {
  if (chart || !chartEl.value) return
  if (chartEl.value.clientWidth === 0) return
  chart = echarts.init(chartEl.value)
  renderChart()
}

function renderChart() {
  if (!chart || !props.data?.trend) return
  const trend = props.data.trend
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
  chart.setOption({
    tooltip: { trigger: 'axis' },
    legend: { data: ['Revenue', 'Payments'], top: 0 },
    grid: { left: 50, right: 20, top: 40, bottom: 75 },
    xAxis: { type: 'category', data: trend.map((t: any) => {
      const d = new Date(t.date)
      return `${days[d.getDay()]} ${d.getDate()}`
    }), boundaryGap: false, axisLabel: { rotate: 45, fontSize: 11, interval: 0 } },
    yAxis: { type: 'value', axisLabel: { formatter: (v: number) => `${currencySymbol}${(v / 1000).toFixed(0)}k` } },
    series: [
      {
        name: 'Revenue',
        type: 'line',
        smooth: true,
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(22, 163, 74, 0.35)' },
            { offset: 1, color: 'rgba(22, 163, 74, 0.02)' },
          ]),
        },
        lineStyle: { width: 2.5, color: '#16a34a' },
        itemStyle: { color: '#16a34a' },
        data: trend.map((t: any) => t.revenue),
      },
      {
        name: 'Payments',
        type: 'line',
        smooth: true,
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(59, 130, 246, 0.25)' },
            { offset: 1, color: 'rgba(59, 130, 246, 0.02)' },
          ]),
        },
        lineStyle: { width: 2, color: '#3b82f6' },
        itemStyle: { color: '#3b82f6' },
        data: trend.map((t: any) => t.payments),
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

onUnmounted(() => {
  chart?.dispose()
  ro?.disconnect()
})

watch(() => props.data, () => {
  if (chart) renderChart()
  else ensureInit()
}, { flush: 'post' })

function addonIcon(key: string) {
  const icons: Record<string, string> = { insurance: 'mdi-shield-car', gps: 'mdi-satellite-variant', child_seat: 'mdi-car-child-seat', additional_driver: 'mdi-account-plus', delivery: 'mdi-truck-delivery' }
  return icons[key] || 'mdi-plus'
}
function methodIcon(m: string) {
  const icons: Record<string, string> = { mpesa: 'mdi-cellphone', cash: 'mdi-cash', card: 'mdi-credit-card', bank_transfer: 'mdi-bank', cheque: 'mdi-file-sign', other: 'mdi-swap-horizontal' }
  return icons[m] || 'mdi-cash'
}

function exportCsv() {
  if (!props.data?.by_vehicle?.length) return
  const rows = ['Vehicle,Count,Revenue,Driver Cost,Net']
  for (const v of props.data.by_vehicle) {
    rows.push(`"${v.vehicle}",${v.count},${v.revenue},${v.driver_cost},${v.net}`)
  }
  const blob = new Blob([rows.join('\n')], { type: 'text/csv' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `revenue-analysis-${new Date().toISOString().slice(0, 10)}.csv`
  a.click()
  URL.revokeObjectURL(url)
}
</script>

<style scoped>
.section-heading { color: #1e293b; }
.v-theme--dark .section-heading { color: #e2e8f0; }
.rev-tile-customer { background: #f8fafc; }
.rev-tile-addon { background: #faf5ff; }
.rev-tile-payment { background: #eff6ff; }
.v-theme--dark .rev-tile-customer { background: rgba(99, 102, 241, 0.08); }
.v-theme--dark .rev-tile-addon { background: rgba(147, 51, 234, 0.08); }
.v-theme--dark .rev-tile-payment { background: rgba(59, 130, 246, 0.08); }
.text-revenue-green { color: #166534; }
.text-revenue-red { color: #dc2626; }
.text-revenue-red-dark { color: #991b1b; }
.text-revenue-purple { color: #6b21a8; }
.text-revenue-blue { color: #1e40af; }
.v-theme--dark .text-revenue-green { color: #4ade80; }
.v-theme--dark .text-revenue-red { color: #f87171; }
.v-theme--dark .text-revenue-red-dark { color: #f87171; }
.v-theme--dark .text-revenue-purple { color: #c084fc; }
.v-theme--dark .text-revenue-blue { color: #60a5fa; }
</style>
