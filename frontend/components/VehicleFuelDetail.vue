<template>
  <div class="d-flex flex-column ga-4">
    <!-- Page header bar -->
    <div class="page-header-bar">
      <div class="d-flex align-center ga-2">
        <v-btn icon="mdi-arrow-left" variant="text" size="small" @click="goBack" />
        <div class="d-flex align-center ga-2">
          <v-icon color="primary">mdi-gas-station</v-icon>
          <div class="d-flex flex-column">
            <span class="text-h6 font-weight-bold page-header-title">Vehicle Fuel Details</span>
            <span v-if="vehicle" class="text-caption text-medium-emphasis">{{ vehicle.display_name }} · {{ vehicle.license_plate || '—' }}</span>
          </div>
        </div>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn v-can="'fuel:create'" variant="text" prepend-icon="mdi-pencil-outline" @click="navigateTo(`/app/vehicles/${props.vehicleId}/edit`)">Edit Vehicle</v-btn>
        <v-btn variant="tonal" color="primary" size="small" prepend-icon="mdi-file-pdf-box" :loading="pdfLoading" @click="exportPDF">Export PDF</v-btn>
      </div>
    </div>

    <!-- Summary KPIs -->
    <v-row dense>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5">
          <div class="d-flex align-center ga-2 mb-2">
            <div class="d-flex align-center justify-center" style="width: 36px; height: 36px; border-radius: 10px; background: rgba(99,102,241,0.12)">
              <v-icon color="primary" size="small">mdi-gas-station</v-icon>
            </div>
            <span class="text-caption text-medium-emphasis">Fill-ups</span>
          </div>
          <p class="text-h5 font-weight-bold text-high-emphasis">{{ summary.fill_count || 0 }}</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5">
          <div class="d-flex align-center ga-2 mb-2">
            <div class="d-flex align-center justify-center" style="width: 36px; height: 36px; border-radius: 10px; background: rgba(245,158,11,0.12)">
              <v-icon color="amber-darken-1" size="small">mdi-gauge</v-icon>
            </div>
            <span class="text-caption text-medium-emphasis">Total Volume</span>
          </div>
          <p class="text-h5 font-weight-bold text-high-emphasis">{{ (summary.total_gallons || 0).toLocaleString(undefined, { maximumFractionDigits: 1 }) }}</p>
          <p class="text-caption text-medium-emphasis">{{ summary.total_gallons ? 'gallons / liters' : '' }}</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5">
          <div class="d-flex align-center ga-2 mb-2">
            <div class="d-flex align-center justify-center" style="width: 36px; height: 36px; border-radius: 10px; background: rgba(16,185,129,0.12)">
              <v-icon color="success" size="small">mdi-currency-usd</v-icon>
            </div>
            <span class="text-caption text-medium-emphasis">Total Cost</span>
          </div>
          <p class="text-h5 font-weight-bold text-high-emphasis">{{ currencySymbol }}{{ (summary.total_cost || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) }}</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5">
          <div class="d-flex align-center ga-2 mb-2">
            <div class="d-flex align-center justify-center" style="width: 36px; height: 36px; border-radius: 10px; background: rgba(6,182,212,0.12)">
              <v-icon color="cyan-darken-1" size="small">mdi-tag-outline</v-icon>
            </div>
            <span class="text-caption text-medium-emphasis">Avg Price/Unit</span>
          </div>
          <p class="text-h5 font-weight-bold text-high-emphasis">{{ currencySymbol }}{{ summary.avg_price_per_unit?.toFixed(3) || '0' }}</p>
        </v-card>
      </v-col>
    </v-row>

    <!-- Distance & Efficiency -->
    <v-row dense>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-4">
          <span class="text-caption text-medium-emphasis">Distance Travelled</span>
          <p class="text-h6 font-weight-bold text-high-emphasis mt-1">
            {{ summary.distance != null ? Number(summary.distance).toLocaleString() + ' mi' : '—' }}
          </p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-4">
          <span class="text-caption text-medium-emphasis">Avg MPG</span>
          <p class="text-h6 font-weight-bold mt-1">
            <span v-if="summary.avg_mpg" class="text-success">{{ summary.avg_mpg }}</span>
            <span v-else class="text-medium-emphasis">—</span>
          </p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-4">
          <span class="text-caption text-medium-emphasis">Min Odometer</span>
          <p class="text-h6 font-weight-bold text-high-emphasis mt-1">
            {{ summary.min_odometer != null ? Number(summary.min_odometer).toLocaleString() + ' mi' : '—' }}
          </p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-4">
          <span class="text-caption text-medium-emphasis">Max Odometer</span>
          <p class="text-h6 font-weight-bold text-high-emphasis mt-1">
            {{ summary.max_odometer != null ? Number(summary.max_odometer).toLocaleString() + ' mi' : '—' }}
          </p>
        </v-card>
      </v-col>
    </v-row>

    <!-- Cost Trend Area Chart -->
    <DashboardChart :option="costTrendOption" title="Fuel Cost Trend" icon="mdi-chart-line" height="280px" />

    <!-- Fuel type breakdown -->
    <v-card v-if="Object.keys(fuelTypeBreakdown).length" elevation="0" border class="pa-5">
      <h3 class="text-subtitle-2 font-weight-medium mb-3" style="color: #475569">
        <v-icon size="small" color="primary" class="me-1">mdi-fuel</v-icon> Fuel Type Breakdown
      </h3>
      <div class="d-flex flex-wrap ga-2">
        <v-chip v-for="(info, type) in fuelTypeBreakdown" :key="type" :color="fuelChipColor(type as string)" variant="tonal" size="small">
          {{ type }}: {{ info.count }} fills · {{ currencySymbol }}{{ info.cost.toFixed(0) }}
        </v-chip>
      </div>
    </v-card>

    <!-- All transactions table -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-2">
      <span class="text-caption text-medium-emphasis">{{ transactions.length }} fuel transactions</span>
      <v-btn variant="tonal" size="small" prepend-icon="mdi-download" @click="exportCSV">Export CSV</v-btn>
    </div>

    <v-card elevation="0" border rounded="lg">
      <v-data-table
        :headers="headers"
        :items="transactions"
        :loading="pending"
        hover
        density="comfortable"
        :items-per-page="15"
      >
        <template #item.date="{ value }">
          <div class="d-flex flex-column">
            <span class="text-body-2 font-weight-medium">{{ formatFuelDate(value).date }}</span>
            <span class="text-caption text-medium-emphasis">{{ formatFuelDate(value).time }}</span>
          </div>
        </template>
        <template #item.fuel_type="{ value }">
          <v-chip :color="fuelChipColor(value)" variant="flat" size="small">{{ value }}</v-chip>
        </template>
        <template #item.total_cost="{ value }">
          <span class="font-weight-medium">{{ currencySymbol }}{{ parseFloat(value).toFixed(2) }}</span>
        </template>
        <template #item.price_per_unit="{ value }">
          {{ currencySymbol }}{{ value?.toFixed(3) || '—' }}
        </template>
        <template #item.quantity="{ value, item }">
          {{ value }} {{ (item as any).unit?.[0] === 'l' ? 'L' : 'gal' }}
        </template>
        <template #item.odometer_reading="{ value }">
          {{ value ? Number(value).toLocaleString() : '—' }}
        </template>
        <template #item.mpg="{ value }">
          <span v-if="value" :class="{ 'text-success': value > 8, 'text-warning': value > 0 && value <= 8 }">{{ value }}</span>
          <span v-else class="text-medium-emphasis">—</span>
        </template>
        <template #item.station_name="{ value, item }">
          <div class="d-flex flex-column">
            <span class="text-body-2">{{ value || '—' }}</span>
            <span v-if="(item as any).station_location" class="text-caption text-medium-emphasis text-truncate" style="max-width: 160px">{{ (item as any).station_location }}</span>
          </div>
        </template>
        <template #item.receipt_image="{ value }">
          <v-icon v-if="value" color="success" size="small">mdi-receipt-text-check-outline</v-icon>
          <v-icon v-else color="grey-lighten-1" size="small">mdi-receipt-text-outline</v-icon>
        </template>
        <template #no-data>
          <div class="text-center py-12 text-medium-emphasis">
            <v-icon size="48" class="mb-3">mdi-gas-station</v-icon>
            <p>No fuel transactions for this vehicle.</p>
          </div>
        </template>
      </v-data-table>
    </v-card>
  </div>
</template>

<script setup lang="ts">
import * as echarts from 'echarts/core'
import { setupECharts } from '~/utils/echarts'
import { useDarkMode } from '~/composables/useDarkMode'

setupECharts()

const { $api } = useNuxtApp()
const { currencySymbol } = useCurrency()
const { fetchTransactions } = useFuelApi()
const { fuelChipColor, formatFuelDate } = useFuelHelpers()
const { isDark } = useDarkMode()

const props = defineProps<{ vehicleId: string | number }>()

// Load vehicle details for the header
const { data: vehicle } = useAsyncData(
  `vehicle-fuel-detail-vehicle-${props.vehicleId}`,
  () => $api(`/vehicles/vehicles/${props.vehicleId}/`).catch(() => null) as Promise<any>,
  { default: () => null }
)

function goBack() { navigateTo('/app/fuel') }

const pdfLoading = ref(false)

const { data: txData, pending } = useAsyncData(
  `vehicle-fuel-detail-${props.vehicleId}`,
  () => fetchTransactions({ vehicle: props.vehicleId }).catch(() => ({ results: [] })) as Promise<any>,
  { default: () => ({ results: [] }) }
)
const transactions = computed(() => txData.value?.results || [])

const summary = computed(() => {
  const txs = transactions.value
  if (!txs.length) return {}
  const totalCost = txs.reduce((s: number, t: any) => s + parseFloat(t.total_cost || 0), 0)
  const totalGallons = txs.reduce((s: number, t: any) => s + parseFloat(t.quantity || 0), 0)
  const odometers = txs.map((t: any) => t.odometer_reading).filter((v: any) => v != null) as number[]
  const minOdo = odometers.length ? Math.min(...odometers) : null
  const maxOdo = odometers.length ? Math.max(...odometers) : null
  const distance = (minOdo != null && maxOdo != null) ? maxOdo - minOdo : null
  const avgPrice = totalGallons ? totalCost / totalGallons : 0
  const avgMpg = (distance && totalGallons) ? (distance / totalGallons).toFixed(1) : null
  return {
    fill_count: txs.length,
    total_cost: totalCost,
    total_gallons: totalGallons,
    avg_price_per_unit: avgPrice,
    distance,
    avg_mpg: avgMpg ? parseFloat(avgMpg) : null,
    min_odometer: minOdo,
    max_odometer: maxOdo,
  }
})

const fuelTypeBreakdown = computed(() => {
  const map: Record<string, { count: number; cost: number }> = {}
  for (const t of transactions.value) {
    const type = t.fuel_type || 'Unknown'
    if (!map[type]) map[type] = { count: 0, cost: 0 }
    map[type].count++
    map[type].cost += parseFloat(t.total_cost || 0)
  }
  return map
})

const axisLabelColor = computed(() => isDark.value ? '#94a3b8' : '#64748b')
const splitLineColor = computed(() => isDark.value ? '#334155' : '#f1f5f9')

const costTrendOption = computed(() => {
  const txs = [...transactions.value].sort((a: any, b: any) => new Date(a.date).getTime() - new Date(b.date).getTime())
  const labels = txs.map((t: any) => formatFuelDate(t.date).date)
  const costData = txs.map((t: any) => parseFloat(t.total_cost || 0).toFixed(2))
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: 70, right: 20, top: 20, bottom: 60 },
    xAxis: {
      type: 'category',
      data: labels,
      axisLabel: { color: axisLabelColor.value, fontSize: 11, rotate: labels.length > 10 ? 25 : 0 },
    },
    yAxis: {
      type: 'value',
      axisLabel: { color: axisLabelColor.value, fontSize: 11 },
      splitLine: { lineStyle: { color: splitLineColor.value } },
    },
    series: [{
      type: 'line',
      smooth: true,
      symbol: 'circle',
      symbolSize: 6,
      data: costData,
      lineStyle: { width: 3, color: '#6366f1' },
      itemStyle: { color: '#6366f1' },
      areaStyle: {
        color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
          { offset: 0, color: 'rgba(99,102,241,0.25)' },
          { offset: 1, color: 'rgba(99,102,241,0.02)' },
        ]),
      },
    }],
  }
})

const headers = [
  { title: 'Date', key: 'date', sortable: true, width: '170px' },
  { title: 'Fuel', key: 'fuel_type', width: '90px' },
  { title: 'Qty', key: 'quantity', width: '90px' },
  { title: 'Cost', key: 'total_cost', width: '110px' },
  { title: 'Price/Unit', key: 'price_per_unit', width: '100px' },
  { title: 'Odometer', key: 'odometer_reading', width: '100px' },
  { title: 'MPG', key: 'mpg', width: '70px' },
  { title: 'Station', key: 'station_name', width: '160px' },
  { title: '', key: 'receipt_image', width: '50px', sortable: false },
]

function exportCSV() {
  const rows = transactions.value.map((t: any) => [
    formatFuelDate(t.date).date,
    t.fuel_type,
    t.quantity,
    t.unit,
    parseFloat(t.total_cost).toFixed(2),
    t.price_per_unit?.toFixed(3) || '',
    t.odometer_reading || '',
    t.mpg || '',
    t.station_name || '',
    t.station_location || '',
  ])
  rows.unshift(['Date', 'Fuel Type', 'Quantity', 'Unit', 'Cost', 'Price/Unit', 'Odometer', 'MPG', 'Station', 'Location'])
  const csv = rows.map((r) => r.map((c) => `"${c}"`).join(',')).join('\n')
  const blob = new Blob([csv], { type: 'text/csv' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = `vehicle-${props.vehicleId}-fuel-${new Date().toISOString().slice(0, 10)}.csv`
  link.click()
  URL.revokeObjectURL(url)
}

async function exportPDF() {
  pdfLoading.value = true
  try {
    const auth = useAuthStore()
    const token = auth.accessToken || localStorage.getItem('fc_access') || ''
    const tenantSchema = auth.tenantSchema || localStorage.getItem('fc_tenant') || ''
    const res = await fetch(
      `${useRuntimeConfig().public.apiBase}/fuel/transactions/vehicle-pdf/?vehicle_id=${props.vehicleId}`,
      {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${token}`,
          'x-tenant-schema': tenantSchema,
        },
      },
    )
    if (!res.ok) throw new Error('Failed to generate PDF')
    const blob = await res.blob()
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `vehicle-${props.vehicleId}-fuel-report-${new Date().toISOString().slice(0, 10)}.pdf`
    link.click()
    URL.revokeObjectURL(url)
  } catch (e) {
    console.error('PDF export error:', e)
  } finally {
    pdfLoading.value = false
  }
}
</script>

<style scoped>
.page-header-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 16px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
}
.page-header-title {
  color: #0f172a;
  letter-spacing: -0.01em;
}
</style>
