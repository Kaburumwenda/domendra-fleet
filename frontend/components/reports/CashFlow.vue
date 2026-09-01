<template>
  <v-card elevation="0" border rounded="lg" class="pa-5">
    <div class="d-flex align-center justify-space-between mb-4 flex-wrap ga-2">
      <div class="d-flex align-center ga-2">
        <v-icon color="info" size="small">mdi-cash-flow</v-icon>
        <h3 class="text-subtitle-1 font-weight-bold section-heading">Cash Flow Statement</h3>
      </div>
      <div class="d-flex ga-1">
        <v-chip size="small" variant="tonal" color="success">In: {{ currencySymbol }}{{ formatNum(data?.total_inflow) }}</v-chip>
        <v-chip size="small" variant="tonal" color="error">Out: {{ currencySymbol }}{{ formatNum(data?.total_outflow) }}</v-chip>
        <v-chip size="small" variant="tonal" :color="netPositive ? 'success' : 'error'">
          Net: {{ netPositive ? '' : '-' }}{{ currencySymbol }}{{ formatNum(Math.abs(data?.net_cash_flow ?? 0)) }}
        </v-chip>
        <v-btn variant="text" size="small" prepend-icon="mdi-download" color="primary" @click="exportCsv">Export</v-btn>
      </div>
    </div>

    <!-- Chart -->
    <div ref="chartEl" style="height: 280px" class="mb-4" />

    <!-- Data Table -->
    <v-data-table
      :headers="headers"
      :items="data?.buckets || []"
      density="compact"
      :items-per-page="10"
      class="rounded-lg"
    >
      <template #item.inflow="{ value }"><span class="font-weight-medium" style="color: #166534">{{ currencySymbol }}{{ formatNum(value) }}</span></template>
      <template #item.outflow="{ value }"><span style="color: #991b1b">{{ currencySymbol }}{{ formatNum(value) }}</span></template>
      <template #item.net="{ value }">
        <v-chip size="small" :color="value >= 0 ? 'success' : 'error'" variant="tonal" class="font-weight-bold">
          <template v-if="value < 0">-</template>{{ currencySymbol }}{{ formatNum(Math.abs(value)) }}
        </v-chip>
      </template>
    </v-data-table>
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

const netPositive = computed(() => (props.data?.net_cash_flow ?? 0) >= 0)

const headers = [
  { title: 'Date', key: 'date', width: '120px' },
  { title: 'Inflow', key: 'inflow', align: 'end' as const },
  { title: 'Outflow', key: 'outflow', align: 'end' as const },
  { title: 'Net', key: 'net', align: 'end' as const },
]

function ensureInit() {
  if (chart || !chartEl.value) return
  if (chartEl.value.clientWidth === 0) return
  chart = echarts.init(chartEl.value)
  renderChart()
}

function renderChart() {
  if (!chart || !props.data?.buckets) return
  const buckets = props.data.buckets
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
  chart.setOption({
    tooltip: { trigger: 'axis' },
    legend: { data: ['Inflow', 'Outflow', 'Net'], top: 0 },
    grid: { left: 50, right: 20, top: 40, bottom: 75 },
    xAxis: { type: 'category', data: buckets.map((b: any) => {
      const d = new Date(b.date)
      return `${days[d.getDay()]} ${d.getDate()}`
    }), axisLabel: { rotate: 45, fontSize: 11, interval: 0 } },
    yAxis: { type: 'value', axisLabel: { formatter: (v: number) => `${currencySymbol}${(v / 1000).toFixed(0)}k` } },
    series: [
      { name: 'Inflow', type: 'bar', stack: 'flow', itemStyle: { color: '#16a34a' }, data: buckets.map((b: any) => b.inflow) },
      { name: 'Outflow', type: 'bar', stack: 'flow', itemStyle: { color: '#dc2626' }, data: buckets.map((b: any) => b.outflow) },
      { name: 'Net', type: 'line', smooth: true, lineStyle: { width: 2 }, itemStyle: { color: '#2563eb' }, data: buckets.map((b: any) => b.net) },
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

function formatNum(n: number | undefined) { return n ? Math.round(n).toLocaleString() : '0' }

function exportCsv() {
  if (!props.data?.buckets?.length) return
  const rows = ['Date,Inflow,Outflow,Net']
  for (const b of props.data.buckets) {
    rows.push(`${b.date},${b.inflow},${b.outflow},${b.net}`)
  }
  const blob = new Blob([rows.join('\n')], { type: 'text/csv' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `cash-flow-${new Date().toISOString().slice(0, 10)}.csv`
  a.click()
  URL.revokeObjectURL(url)
}
</script>

<style scoped>
.section-heading { color: #1e293b; }
.v-theme--dark .section-heading { color: #e2e8f0; }
</style>
