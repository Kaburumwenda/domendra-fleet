<template>
  <div class="d-flex flex-column ga-4">
    <!-- ── Date Filter Bar ── -->
    <v-card variant="outlined" rounded="lg" class="pa-3">
      <div class="d-flex align-center ga-4 flex-wrap">
        <div class="d-flex align-center ga-2">
          <v-icon icon="mdi-filter-calendar" color="primary" />
          <span class="text-body-2 font-weight-bold text-medium-emphasis">Date Range</span>
        </div>
        <div class="d-flex align-center ga-1 flex-wrap">
          <v-btn
            v-for="opt in datePresets"
            :key="opt.value"
            :variant="activePreset === opt.value ? 'flat' : 'text'"
            :color="activePreset === opt.value ? 'primary' : undefined"
            size="small"
            @click="setPreset(opt.value)"
          >
            {{ opt.label }}
          </v-btn>
        </div>
        <v-spacer />
        <div class="d-flex align-center ga-3 pt-3">
          <div class="d-flex flex-column">
            <span class="text-caption text-medium-emphasis mb-1">From</span>
            <v-text-field
              v-model="startDate"
              type="date"
              density="compact"
              variant="outlined"
              hide-details
              style="max-width: 170px"
              @update:model-value="onCustomDate"
            />
          </div>
          <v-icon icon="mdi-arrow-right" color="medium-emphasis" />
          <div class="d-flex flex-column">
            <span class="text-caption text-medium-emphasis mb-1">To</span>
            <v-text-field
              v-model="endDate"
              type="date"
              density="compact"
              variant="outlined"
              hide-details
              style="max-width: 170px"
              @update:model-value="onCustomDate"
            />
          </div>
          <v-btn variant="flat" color="primary" size="small" class="mt-4" @click="debouncedLoad">Apply</v-btn>
          <v-btn variant="text" prepend-icon="mdi-refresh" size="small" color="primary" class="mt-4" @click="resetFilter">
            Reset
          </v-btn>
        </div>
      </div>
    </v-card>

    <!-- ── Loading ── -->
    <div v-if="loading" class="d-flex justify-center align-center py-12">
      <v-progress-circular indeterminate size="48" color="primary" />
    </div>

    <!-- ── Error ── -->
    <div v-else-if="error" class="text-center text-error py-12">
      <v-icon size="48" class="mb-2">mdi-alert-circle-outline</v-icon>
      <p class="text-body-2">{{ error }}</p>
    </div>

    <!-- ── Empty ── -->
    <div v-else-if="!data" class="text-center text-medium-emphasis py-12">
      <v-icon size="48" class="mb-2">mdi-calculator</v-icon>
      <p>No data available.</p>
    </div>

    <template v-else>
      <!-- ── Hero: Total Cost of Ownership ── -->
      <v-card variant="outlined" rounded="xl" class="pa-5" style="background: linear-gradient(135deg, #1e293b, #0f172a)">
        <div class="d-flex align-center justify-space-between flex-wrap ga-3">
          <div>
            <p class="text-caption text-white opacity-70 mb-1">Total Cost of Ownership</p>
            <h2 class="text-h4 font-weight-bold text-white">{{ currencySymbol }}{{ Number(data.summary.total_cost).toLocaleString(undefined, { maximumFractionDigits: 0 }) }}</h2>
            <p class="text-caption text-white opacity-70 mt-1">
              for {{ data.summary.period_months }} months ·
              {{ currencySymbol }}{{ data.summary.cost_per_day }}/day ·
              {{ currencySymbol }}{{ data.summary.cost_per_km }}/km
            </p>
          </div>
          <div class="d-flex align-center ga-2">
            <v-chip variant="flat" color="warning" size="small">
              <v-icon start size="small">mdi-calendar-clock</v-icon>
              {{ data.summary.days_owned }} days owned
            </v-chip>
            <v-chip variant="flat" color="info" size="small">
              <v-icon start size="small">mdi-chart-line</v-icon>
              Est. Lifetime: {{ currencySymbol }}{{ Number(data.summary.lifetime_cost_estimate).toLocaleString(undefined, { maximumFractionDigits: 0 }) }}
            </v-chip>
          </div>
        </div>
      </v-card>

      <!-- ── KPI Cards ── -->
      <v-row dense>
        <v-col cols="12" sm="6" md="3">
          <StatCard
            label="Capital Cost"
            :value="fmtMoney(data.summary.capital_cost)"
            icon="mdi-bank"
            iconBg="#e0e7ff"
            iconColor="#4f46e5"
            :subtitle="data.financial_profile.ownership === 'lease' ? 'Lease + Financing' : 'Depreciation + Financing'"
          />
        </v-col>
        <v-col cols="12" sm="6" md="3">
          <StatCard
            label="Energy Cost"
            :value="fmtMoney(data.summary.energy_cost)"
            icon="mdi-fuel"
            iconBg="#fef3c7"
            iconColor="#d97706"
            :subtitle="`${data.usage_stats.fuel_entries} fuel entries · ${data.usage_stats.charging_sessions} charges`"
          />
        </v-col>
        <v-col cols="12" sm="6" md="3">
          <StatCard
            label="Maintenance"
            :value="fmtMoney(data.summary.maintenance_cost)"
            icon="mdi-wrench"
            iconBg="#fce7f3"
            iconColor="#db2777"
            :subtitle="`${data.usage_stats.service_count} services · ${data.usage_stats.downtime_hours}h downtime`"
          />
        </v-col>
        <v-col cols="12" sm="6" md="3">
          <StatCard
            label="Insurance"
            :value="fmtMoney(data.summary.insurance_cost)"
            icon="mdi-shield-car"
            iconBg="#dbeafe"
            iconColor="#2563eb"
            subtitle="Pro-rated for period"
          />
        </v-col>
      </v-row>

      <!-- ── Cost Breakdown Pie ── -->
      <DashboardChart :option="costPieOption" title="Cost Breakdown" icon="mdi-chart-pie" height="320px" />

      <!-- ── Monthly Cost Trend (full width) ── -->
      <DashboardChart :option="trendChartOption" title="Monthly Cost Trend" icon="mdi-chart-line" height="320px" />

      <!-- ── Cost Category Cards ── -->
      <v-row dense>
        <v-col cols="12" md="6">
          <v-card variant="outlined" rounded="lg" class="pa-4 h-100">
            <div class="d-flex align-center justify-space-between mb-3">
              <h3 class="text-subtitle-2 font-weight-medium d-flex align-center ga-2 section-heading">
                <v-icon size="small" color="primary">mdi-bank</v-icon> Capital &amp; Financing
              </h3>
              <v-chip size="small" variant="tonal" color="primary">{{ fmtMoney(categoryTotals.capital) }}</v-chip>
            </div>
            <div class="d-flex flex-column ga-2">
              <div v-if="data.financial_profile.ownership !== 'lease'" class="d-flex align-center justify-space-between">
                <span class="text-body-2 text-medium-emphasis">Purchase Price</span>
                <span class="text-body-2 font-weight-bold">{{ fmtMoney(data.financial_profile.purchase_price) }}</span>
              </div>
              <div v-if="data.financial_profile.ownership !== 'lease'" class="d-flex align-center justify-space-between">
                <span class="text-body-2 text-medium-emphasis">Salvage Value</span>
                <span class="text-body-2 font-weight-bold">{{ fmtMoney(data.financial_profile.salvage_value) }}</span>
              </div>
              <div v-if="data.financial_profile.ownership !== 'lease'" class="d-flex align-center justify-space-between">
                <span class="text-body-2 text-medium-emphasis">Current Book Value</span>
                <span class="text-body-2 font-weight-bold">{{ fmtMoney(data.financial_profile.current_book_value) }}</span>
              </div>
              <div v-if="data.financial_profile.ownership !== 'lease'" class="d-flex align-center justify-space-between">
                <span class="text-body-2 text-medium-emphasis">Annual Depreciation</span>
                <span class="text-body-2 font-weight-bold">{{ fmtMoney(data.financial_profile.annual_depreciation) }}</span>
              </div>
              <div v-if="data.financial_profile.ownership === 'lease'" class="d-flex align-center justify-space-between">
                <span class="text-body-2 text-medium-emphasis">Lease Monthly Rate</span>
                <span class="text-body-2 font-weight-bold">{{ fmtMoney(data.financial_profile.lease_monthly_rate) }}</span>
              </div>
              <div v-if="data.financial_profile.ownership === 'lease'" class="d-flex align-center justify-space-between">
                <span class="text-body-2 text-medium-emphasis">Deposit</span>
                <span class="text-body-2 font-weight-bold">{{ fmtMoney(data.financial_profile.deposit) }}</span>
              </div>
              <v-divider />
              <div class="d-flex align-center justify-space-between">
                <span class="text-body-2 text-medium-emphasis">Financing (Monthly)</span>
                <span class="text-body-2 font-weight-bold">{{ fmtMoney(data.financial_profile.monthly_payment) }}</span>
              </div>
              <div class="d-flex align-center justify-space-between">
                <span class="text-body-2 text-medium-emphasis">Useful Life</span>
                <span class="text-body-2 font-weight-bold">{{ data.financial_profile.useful_life_years || '—' }} years</span>
              </div>
            </div>
          </v-card>
        </v-col>

        <v-col cols="12" md="6">
          <v-card variant="outlined" rounded="lg" class="pa-4 h-100">
            <div class="d-flex align-center justify-space-between mb-3">
              <h3 class="text-subtitle-2 font-weight-medium d-flex align-center ga-2 section-heading">
                <v-icon size="small" color="warning">mdi-gauge</v-icon> Usage &amp; Efficiency
              </h3>
              <v-chip size="small" variant="tonal" color="warning">{{ currencySymbol }}{{ data.summary.cost_per_km }}/km</v-chip>
            </div>
            <div class="d-flex flex-column ga-2">
              <div class="d-flex align-center justify-space-between">
                <span class="text-body-2 text-medium-emphasis">Total Mileage</span>
                <span class="text-body-2 font-weight-bold">{{ Number(data.usage_stats.mileage).toLocaleString() }}</span>
              </div>
              <div class="d-flex align-center justify-space-between">
                <span class="text-body-2 text-medium-emphasis">Period Mileage (est.)</span>
                <span class="text-body-2 font-weight-bold">{{ Number(data.usage_stats.period_mileage).toLocaleString() }}</span>
              </div>
              <v-divider />
              <div class="d-flex align-center justify-space-between">
                <span class="text-body-2 text-medium-emphasis">Fuel Volume</span>
                <span class="text-body-2 font-weight-bold">{{ Number(data.usage_stats.fuel_volume).toLocaleString() }}</span>
              </div>
              <div class="d-flex align-center justify-space-between">
                <span class="text-body-2 text-medium-emphasis">Charging Energy</span>
                <span class="text-body-2 font-weight-bold">{{ Number(data.usage_stats.charging_energy).toLocaleString() }} kWh</span>
              </div>
              <div class="d-flex align-center justify-space-between">
                <span class="text-body-2 text-medium-emphasis">Downtime Hours</span>
                <span class="text-body-2 font-weight-bold">{{ data.usage_stats.downtime_hours }}h</span>
              </div>
              <div class="d-flex align-center justify-space-between">
                <span class="text-body-2 text-medium-emphasis">Accidents</span>
                <span class="text-body-2 font-weight-bold">{{ data.usage_stats.accident_count }}</span>
              </div>
              <div class="d-flex align-center justify-space-between">
                <span class="text-body-2 text-medium-emphasis">Days Owned</span>
                <span class="text-body-2 font-weight-bold">{{ data.summary.days_owned }}</span>
              </div>
            </div>
          </v-card>
        </v-col>
      </v-row>

      <!-- ── Cost Breakdown Bar Chart ── -->
      <DashboardChart :option="costBarOption" title="Cost Comparison by Category" icon="mdi-chart-bar" height="280px" />

      <!-- ── Cost Ledger Table ── -->
      <v-card variant="outlined" rounded="lg">
        <div class="d-flex align-center justify-space-between pa-4">
          <h3 class="text-subtitle-2 font-weight-medium d-flex align-center ga-2 section-heading">
            <v-icon size="small" color="primary">mdi-format-list-bulleted</v-icon> Cost Ledger
          </h3>
          <div class="d-flex align-center ga-2">
            <v-chip size="small" variant="tonal" color="primary">{{ ledgerItems.length }} items</v-chip>
            <v-btn variant="text" size="small" prepend-icon="mdi-download" @click="exportCsv">Export CSV</v-btn>
          </div>
        </div>
        <v-divider />
        <v-data-table
          :items="ledgerItems"
          :headers="ledgerHeaders"
          density="compact"
          :items-per-page="-1"
        >
          <template #item.amount="{ item }">
            <span class="font-weight-bold" :style="{ color: (item as any).amount > 0 ? '#dc2626' : '#64748b' }">
              {{ currencySymbol }}{{ Number((item as any).amount || 0).toLocaleString(undefined, { maximumFractionDigits: 2 }) }}
            </span>
          </template>
          <template #item.category="{ item }">
            <v-chip size="x-small" variant="tonal" :color="categoryColor((item as any).type)">
              {{ (item as any).category }}
            </v-chip>
          </template>
          <template #tfoot>
            <tr class="bg-grey-lighten-4">
              <td class="font-weight-bold">Total</td>
              <td></td>
              <td class="font-weight-bold text-right" style="color: #dc2626">
                {{ currencySymbol }}{{ Number(data.summary.total_cost).toLocaleString(undefined, { maximumFractionDigits: 2 }) }}
              </td>
            </tr>
          </template>
        </v-data-table>
      </v-card>
    </template>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ vehicleId: string | number }>()
const { currencySymbol } = useCurrency()
const { fetchCostOfOwnership } = useVehicleApi()

const now = new Date()

// ── Date presets ──
const datePresets = [
  { label: 'This Month', value: 'this_month' },
  { label: 'This Quarter', value: 'this_quarter' },
  { label: 'This Year', value: 'this_year' },
  { label: 'Last 12 Months', value: 'last_12' },
  { label: 'All Time', value: 'all_time' },
]
const activePreset = ref('last_12')

function localDate(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

function setPreset(val: string) {
  activePreset.value = val
  const t = new Date()
  const y = t.getFullYear()
  const m = t.getMonth()
  switch (val) {
    case 'this_month':
      startDate.value = localDate(new Date(y, m, 1))
      endDate.value = localDate(t)
      break
    case 'this_quarter': {
      const qStart = Math.floor(m / 3) * 3
      startDate.value = localDate(new Date(y, qStart, 1))
      endDate.value = localDate(t)
      break
    }
    case 'this_year':
      startDate.value = localDate(new Date(y, 0, 1))
      endDate.value = localDate(t)
      break
    case 'last_12':
      startDate.value = localDate(new Date(y, m - 11, 1))
      endDate.value = localDate(t)
      break
    case 'all_time':
      startDate.value = localDate(new Date(2020, 0, 1))
      endDate.value = localDate(t)
      break
  }
  load()
}

function onCustomDate() {
  activePreset.value = 'custom'
  debouncedLoad()
}

const endDate = ref(localDate(now))
const startDate = ref(localDate(new Date(now.getFullYear(), now.getMonth() - 11, 1)))

const data = ref<any>(null)
const loading = ref(false)
const error = ref('')

let debounceTimer: ReturnType<typeof setTimeout> | null = null
function debouncedLoad() {
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(load, 300)
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    const params: Record<string, any> = {}
    if (startDate.value) params.start_date = startDate.value
    if (endDate.value) params.end_date = endDate.value
    const res = await fetchCostOfOwnership(props.vehicleId, params)
    data.value = res
  } catch (err: any) {
    error.value = err?.data?.detail || err?.message || 'Failed to load cost of ownership data.'
  } finally {
    loading.value = false
  }
}

function resetFilter() {
  setPreset('last_12')
}

function fmtMoney(v: any): string {
  const n = Number(v || 0)
  if (n === 0) return '—'
  return `${currencySymbol.value}${n.toLocaleString(undefined, { maximumFractionDigits: 0 })}`
}

// ── Computed helpers ──
const categoryTotals = computed(() => {
  const d = data.value?.summary || {}
  return {
    capital: d.capital_cost || 0,
    energy: d.energy_cost || 0,
    maintenance: d.maintenance_cost || 0,
    insurance: d.insurance_cost || 0,
    incidents: d.incident_cost || 0,
  }
})

const ledgerItems = computed(() => {
  const rows = data.value?.ledger || []
  return rows.map((r: any, i: number) => ({ ...r, idx: i }))
})

const ledgerHeaders = [
  { title: 'Category', key: 'category', sortable: true },
  { title: 'Item', key: 'item', sortable: true },
  { title: 'Amount', key: 'amount', align: 'end' as const, sortable: true },
]

function categoryColor(type: string): string {
  const colors: Record<string, string> = {
    capital: 'primary',
    energy: 'warning',
    maintenance: 'pink',
    insurance: 'info',
    incidents: 'error',
  }
  return colors[type] || 'grey'
}

// ── Cost Breakdown Pie ──
const costPieOption = computed(() => {
  const items = (data.value?.cost_breakdown ?? []).filter((c: any) => c.value > 0)
  if (!items.length) return null
  const palette = ['#4f46e5', '#2563eb', '#f97316', '#eab308', '#22c55e', '#06b6d4', '#8b5cf6', '#ec4899', '#f43f5e']
  return {
    tooltip: { trigger: 'item', formatter: (p: any) => `${p.name}: ${currencySymbol.value}${Number(p.value).toLocaleString()} ({d}%)` },
    legend: { bottom: 0, type: 'scroll', textStyle: { fontSize: 11 } },
    color: palette,
    series: [{
      type: 'pie',
      radius: ['42%', '70%'],
      center: ['50%', '42%'],
      itemStyle: { borderRadius: 6, borderColor: '#fff', borderWidth: 2 },
      label: { show: false },
      emphasis: { label: { show: true, fontSize: 13, fontWeight: 'bold' } },
      data: items.map((c: any) => ({ name: c.name, value: c.value })),
    }],
  }
})

// ── Monthly Trend Chart (stacked area) ──
const trendChartOption = computed(() => {
  if (!data.value?.monthly_series?.length) return null
  const months = data.value.monthly_series.map((m: any) => m.month)
  const capital = data.value.monthly_series.map((m: any) => Number(m.capital))
  const insurance = data.value.monthly_series.map((m: any) => Number(m.insurance))
  const energy = data.value.monthly_series.map((m: any) => Number(m.energy))
  const maintenance = data.value.monthly_series.map((m: any) => Number(m.maintenance))
  const total = data.value.monthly_series.map((m: any) => Number(m.total))

  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'cross' } },
    legend: { data: ['Capital', 'Insurance', 'Energy', 'Maintenance'], bottom: 0, textStyle: { fontSize: 11 } },
    grid: { left: 60, right: 30, top: 20, bottom: 50 },
    xAxis: { type: 'category', data: months, boundaryGap: false, axisLabel: { fontSize: 10, rotate: 30 } },
    yAxis: {
      type: 'value',
      axisLabel: { formatter: (v: number) => {
        if (Math.abs(v) >= 1000) return currencySymbol.value + (v / 1000).toFixed(0) + 'k'
        return currencySymbol.value + v.toString()
      } },
    },
    series: [
      {
        name: 'Capital', type: 'bar', stack: 'cost', barWidth: '60%',
        data: capital, itemStyle: { color: '#4f46e5', borderRadius: [0, 0, 0, 0] },
      },
      {
        name: 'Insurance', type: 'bar', stack: 'cost',
        data: insurance, itemStyle: { color: '#2563eb' },
      },
      {
        name: 'Energy', type: 'bar', stack: 'cost',
        data: energy, itemStyle: { color: '#f97316' },
      },
      {
        name: 'Maintenance', type: 'bar', stack: 'cost',
        data: maintenance, itemStyle: { color: '#ec4899', borderRadius: [4, 4, 0, 0] },
      },
      {
        name: 'Total', type: 'line', smooth: true, data: total,
        itemStyle: { color: '#0f172a' }, lineStyle: { width: 2, type: 'dashed' },
        symbolSize: 6,
      },
    ],
  }
})

// ── Cost Comparison Bar Chart ──
const costBarOption = computed(() => {
  const items = (data.value?.cost_breakdown ?? []).filter((c: any) => c.value > 0)
  if (!items.length) return null
  const palette = ['#4f46e5', '#2563eb', '#f97316', '#eab308', '#22c55e', '#06b6d4', '#8b5cf6', '#ec4899', '#f43f5e']
  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
    grid: { left: 160, right: 30, top: 20, bottom: 20 },
    xAxis: { type: 'value', axisLabel: { formatter: (v: number) => {
      if (Math.abs(v) >= 1000) return currencySymbol.value + (v / 1000).toFixed(0) + 'k'
      return currencySymbol.value + v.toString()
    } } },
    yAxis: { type: 'category', data: items.map((c: any) => c.name), inverse: true },
    series: [{
      type: 'bar',
      data: items.map((c: any) => c.value),
      barMaxWidth: 24,
      itemStyle: {
        borderRadius: [0, 6, 6, 0],
        color: (params: any) => palette[params.dataIndex % palette.length],
      },
      label: { show: true, position: 'right', formatter: (p: any) => currencySymbol.value + Number(p.value).toLocaleString(), fontSize: 10 },
    }],
  }
})

// ── Export CSV ──
function exportCsv() {
  if (!data.value?.ledger) return
  const rows = ['Category,Item,Amount']
  for (const line of data.value.ledger) {
    rows.push(`"${line.category}","${line.item}",${line.amount}`)
  }
  rows.push('')
  rows.push(`"TOTAL","",${data.value.summary.total_cost}`)
  const csv = rows.join('\n')
  const blob = new Blob([csv], { type: 'text/csv' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `vehicle-${props.vehicleId}-tco-${data.value.period.start}-to-${data.value.period.end}.csv`
  a.click()
  URL.revokeObjectURL(url)
}

onMounted(load)
</script>

<style scoped>
.section-heading {
  color: #475569;
}
.v-theme--dark .section-heading {
  color: #94a3b8;
}
</style>
