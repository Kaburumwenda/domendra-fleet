<template>
  <div class="d-flex flex-column ga-4">
    <!-- Page Header -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-3">
      <div class="d-flex align-center ga-3">
        <div class="d-flex align-center justify-center rounded-xl" style="width: 48px; height: 48px; background: linear-gradient(135deg, #6366f1, #4f46e5)">
          <v-icon color="white">mdi-view-dashboard-outline</v-icon>
        </div>
        <div>
          <h1 class="text-h5 font-weight-bold" style="color: #1e293b">Fleet Dashboard</h1>
          <p class="text-body-2 text-medium-emphasis">Real-time fleet overview, performance metrics, and operational insights</p>
        </div>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn variant="tonal" prepend-icon="mdi-refresh" @click="refresh()" :loading="pending">
          <span class="hidden-sm-and-down">Refresh</span>
        </v-btn>
      </div>
    </div>

    <!-- Date Filter Bar -->
    <v-card variant="outlined" rounded="lg" class="pa-3">
      <div class="d-flex align-center ga-3 flex-wrap">
        <div class="d-flex align-center ga-2">
          <v-icon icon="mdi-filter-calendar" color="primary" />
          <span class="text-body-2 font-weight-bold text-medium-emphasis">Period</span>
        </div>
        <v-btn-group density="compact" variant="outlined" color="primary">
          <v-btn
            v-for="opt in datePresetOptions"
            :key="opt.value"
            size="small"
            :variant="datePreset === opt.value ? 'flat' : 'text'"
            :color="datePreset === opt.value ? 'primary' : undefined"
            @click="applyDatePreset(opt.value)"
          >
            {{ opt.label }}
          </v-btn>
        </v-btn-group>
        <template v-if="datePreset === 'custom'">
          <v-text-field
            v-model="customStartDate"
            type="date"
            density="compact"
            variant="outlined"
            label="Start"
            hide-details
            style="max-width: 160px"
            @update:model-value="onCustomDateChange"
          />
          <v-text-field
            v-model="customEndDate"
            type="date"
            density="compact"
            variant="outlined"
            label="End"
            hide-details
            style="max-width: 160px"
            @update:model-value="onCustomDateChange"
          />
          <v-btn size="small" color="primary" variant="flat" @click="refresh" :loading="pending">
            Apply
          </v-btn>
        </template>
        <v-spacer />
        <v-chip v-if="periodLabel" size="small" variant="tonal" color="primary" prepend-icon="mdi-calendar">
          {{ periodLabel }}
        </v-chip>
      </div>
    </v-card>

    <!-- Premium KPI Cards Row -->
    <v-row dense>
      <v-col cols="12" sm="6" md="2" v-for="(kpi, i) in kpis" :key="i">
        <v-card elevation="0" border rounded="lg" class="pa-2 h-100" :style="{ background: kpi.bg, borderColor: kpi.border }">
          <div class="d-flex align-center justify-space-between mb-1">
            <div class="d-flex align-center justify-center rounded-lg" :style="{ width: '28px', height: '28px', background: kpi.iconBg }">
              <v-icon :color="kpi.iconColor" size="x-small">{{ kpi.icon }}</v-icon>
            </div>
          </div>
          <h2 class="text-h6 font-weight-bold" :style="{ color: kpi.valueColor }">{{ kpi.value }}</h2>
          <p class="text-caption text-medium-emphasis mt-1">{{ kpi.label }}</p>
        </v-card>
      </v-col>
    </v-row>

    <!-- Revenue + Cost Summary Row -->
    <v-row dense>
      <v-col cols="12" md="8">
        <v-card elevation="0" border rounded="lg" class="pa-5">
          <div class="d-flex align-center justify-space-between mb-4">
            <div class="d-flex align-center ga-2">
              <v-icon color="primary" size="small">mdi-chart-areaspline</v-icon>
              <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">Cost Trend ({{ periodLabel }})</h3>
            </div>
            <div class="d-flex ga-1">
              <v-chip size="x-small" variant="tonal" color="warning">Fuel: {{ currencySymbol }}{{ formatNum(monthly.fuel_cost) }}</v-chip>
              <v-chip size="x-small" variant="tonal" color="info">Service: {{ currencySymbol }}{{ formatNum(monthly.service_cost) }}</v-chip>
            </div>
          </div>
          <div ref="costChartEl" style="height: 260px" />
        </v-card>
      </v-col>
      <v-col cols="12" md="4">
        <v-card elevation="0" border rounded="lg" class="pa-5 h-100">
          <div class="d-flex align-center ga-2 mb-4">
            <v-icon color="success" size="small">mdi-cash-multiple</v-icon>
            <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">{{ periodLabel || 'This Month' }}</h3>
          </div>
          <div class="d-flex flex-column ga-2">
            <div class="d-flex align-center justify-space-between rounded-lg pa-3" style="background: #f0fdf4">
              <div class="d-flex align-center ga-2">
                <v-icon size="small" color="success">mdi-cash-plus</v-icon>
                <span class="text-body-2 text-medium-emphasis">Revenue (Collected)</span>
              </div>
              <span class="text-subtitle-1 font-weight-bold" style="color: #166534">{{ currencySymbol }}{{ formatNum(monthly.revenue) }}</span>
            </div>
            <div class="d-flex align-center justify-space-between rounded-lg pa-3" style="background: #eff6ff">
              <div class="d-flex align-center ga-2">
                <v-icon size="small" color="primary">mdi-file-sign</v-icon>
                <span class="text-body-2 text-medium-emphasis">Rental Total</span>
              </div>
              <span class="text-subtitle-1 font-weight-bold" style="color: #1e40af">{{ currencySymbol }}{{ formatNum(monthly.rental_total) }}</span>
            </div>
            <div class="d-flex align-center justify-space-between rounded-lg pa-3" style="background: #fef2f2">
              <div class="d-flex align-center ga-2">
                <v-icon size="small" color="error">mdi-gas-station</v-icon>
                <span class="text-body-2 text-medium-emphasis">Fuel Cost</span>
              </div>
              <span class="text-subtitle-1 font-weight-bold" style="color: #991b1b">{{ currencySymbol }}{{ formatNum(monthly.fuel_cost) }}</span>
            </div>
            <div class="d-flex align-center justify-space-between rounded-lg pa-3" style="background: #fff7ed">
              <div class="d-flex align-center ga-2">
                <v-icon size="small" color="warning">mdi-wrench</v-icon>
                <span class="text-body-2 text-medium-emphasis">Service Cost</span>
              </div>
              <span class="text-subtitle-1 font-weight-bold" style="color: #c2410c">{{ currencySymbol }}{{ formatNum(monthly.service_cost) }}</span>
            </div>
            <div class="d-flex align-center justify-space-between rounded-lg pa-3" style="background: #fef2f2">
              <div class="d-flex align-center ga-2">
                <v-icon size="small" color="error">mdi-car-emergency</v-icon>
                <span class="text-body-2 text-medium-emphasis">Accidents</span>
              </div>
              <span class="text-subtitle-1 font-weight-bold" style="color: #991b1b">{{ monthly.accidents }}</span>
            </div>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <!-- Bar Charts Row: Monthly Summary + Revenue by Vehicle Type -->
    <v-row dense>
      <v-col cols="12" md="6">
        <v-card elevation="0" border rounded="lg" class="pa-5">
          <div class="d-flex align-center justify-space-between mb-4">
            <div class="d-flex align-center ga-2">
              <v-icon color="success" size="small">mdi-chart-bar</v-icon>
              <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">{{ periodLabel || 'This Month' }} Summary</h3>
            </div>
            <v-chip size="x-small" variant="tonal" color="success">{{ currencySymbol }}{{ formatNum(monthly.revenue) }} revenue</v-chip>
          </div>
          <div ref="monthBarEl" style="height: 260px" />
        </v-card>
      </v-col>
      <v-col cols="12" md="6">
        <v-card elevation="0" border rounded="lg" class="pa-5">
          <div class="d-flex align-center justify-space-between mb-4">
            <div class="d-flex align-center ga-2">
              <v-icon color="primary" size="small">mdi-chart-bar</v-icon>
              <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">Rental Revenue by Vehicle Type</h3>
            </div>
            <v-chip size="x-small" variant="tonal" color="primary">{{ (data?.revenue_by_type || []).length }} types</v-chip>
          </div>
          <div ref="revTypeBarEl" style="height: 260px" />
        </v-card>
      </v-col>
    </v-row>

    <!-- Fleet Composition Charts Row -->
    <v-row dense>
      <v-col cols="12" md="4">
        <DashboardChart :option="statusChart" title="Fleet by Status" icon="mdi-chart-pie" height="220px" />
      </v-col>
      <v-col cols="12" md="4">
        <DashboardChart :option="typeChart" title="Fleet by Type" icon="mdi-chart-pie" height="220px" />
      </v-col>
      <v-col cols="12" md="4">
        <DashboardChart :option="fuelChart" title="Fleet by Fuel Type" icon="mdi-chart-pie" height="220px" />
      </v-col>
    </v-row>

    <!-- Alerts + Upcoming Row -->
    <v-row dense>
      <v-col cols="12" md="8">
        <v-card elevation="0" border rounded="lg" class="pa-5">
          <div class="d-flex align-center ga-2 mb-4">
            <v-icon color="warning" size="small">mdi-bell-ring-outline</v-icon>
            <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">Active Alerts</h3>
          </div>
          <v-row dense>
            <v-col cols="6" sm="4" v-for="alert in alerts" :key="alert.label">
              <div class="d-flex align-center ga-3 pa-3 rounded-lg h-100" :style="{ background: alert.bg }">
                <div class="d-flex align-center justify-center" style="width: 36px; height: 36px; border-radius: 8px; flex-shrink: 0; background: alert.iconBg">
                  <v-icon size="small" :color="alert.iconColor">{{ alert.icon }}</v-icon>
                </div>
                <div style="min-width: 0">
                  <p class="text-h6 font-weight-bold" :style="{ color: alert.valueColor }">{{ alert.value }}</p>
                  <p class="text-caption text-truncate text-medium-emphasis">{{ alert.label }}</p>
                </div>
              </div>
            </v-col>
          </v-row>
        </v-card>
      </v-col>
      <v-col cols="12" md="4">
        <v-card elevation="0" border rounded="lg" class="pa-5 h-100">
          <div class="d-flex align-center ga-2 mb-4">
            <v-icon color="info" size="small">mdi-calendar-clock</v-icon>
            <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">Upcoming</h3>
          </div>
          <div class="d-flex flex-column ga-3">
            <div class="d-flex align-center justify-space-between rounded-lg pa-3" style="background: #fffbeb">
              <div class="d-flex align-center ga-2">
                <v-icon size="small" color="warning">mdi-clock-outline</v-icon>
                <div>
                  <p class="text-body-2 font-weight-medium">Reminders (7d)</p>
                  <p class="text-caption text-medium-emphasis">{{ upcoming.reminders_7d ? 'Scheduled soon' : 'None' }}</p>
                </div>
              </div>
              <span class="text-h6 font-weight-bold" style="color: #b45309">{{ upcoming.reminders_7d ?? 0 }}</span>
            </div>
            <div class="d-flex align-center justify-space-between rounded-lg pa-3" style="background: #fef2f2">
              <div class="d-flex align-center ga-2">
                <v-icon size="small" color="error">mdi-file-document-outline</v-icon>
                <div>
                  <p class="text-body-2 font-weight-medium">Expiring Docs (30d)</p>
                  <p class="text-caption text-medium-emphasis">{{ upcoming.expiring_docs_30d ? 'Need attention' : 'All current' }}</p>
                </div>
              </div>
              <span class="text-h6 font-weight-bold" style="color: #dc2626">{{ upcoming.expiring_docs_30d ?? 0 }}</span>
            </div>
            <div class="d-flex align-center justify-space-between rounded-lg pa-3" style="background: #f0fdf4">
              <div class="d-flex align-center ga-2">
                <v-icon size="small" color="success">mdi-clipboard-check-outline</v-icon>
                <div>
                  <p class="text-body-2 font-weight-medium">Inspections (30d)</p>
                  <p class="text-caption text-medium-emphasis">{{ alertsRaw.failed_inspections_30d ? alertsRaw.failed_inspections_30d + ' failed' : 'No failures' }}</p>
                </div>
              </div>
              <span class="text-h6 font-weight-bold" style="color: #166534">{{ upcoming.recent_inspections_30d ?? 0 }}</span>
            </div>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <!-- Rental & Revenue Trend Chart with Date Filters -->
    <v-row dense>
      <v-col cols="12">
        <v-card elevation="0" border rounded="lg" class="pa-5">
          <div class="d-flex align-center justify-space-between flex-wrap ga-2 mb-4">
            <div class="d-flex align-center ga-2">
              <v-icon color="primary" size="small">mdi-chart-line-variant</v-icon>
              <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">Rental &amp; Revenue Trend</h3>
            </div>
            <div class="d-flex align-center ga-2">
              <v-btn-group density="compact" variant="outlined">
                <v-btn size="small" :variant="isWeek ? 'flat' : 'text'" :color="isWeek ? 'primary' : undefined" @click="setTrendPeriod('week')">Week</v-btn>
                <v-btn size="small" :variant="isMonth ? 'flat' : 'text'" :color="isMonth ? 'primary' : undefined" @click="setTrendPeriod('month')">Month</v-btn>
                <v-btn size="small" :variant="isYear ? 'flat' : 'text'" :color="isYear ? 'primary' : undefined" @click="setTrendPeriod('year')">Year</v-btn>
                <v-btn size="small" :variant="isCustom ? 'flat' : 'text'" :color="isCustom ? 'primary' : undefined" @click="trendPeriod = 'custom'">Custom</v-btn>
              </v-btn-group>
              <template v-if="isCustom">
                <v-text-field type="date" density="compact" variant="outlined" label="Start" v-model="trendStartDate" hide-details style="max-width: 160px" />
                <v-text-field type="date" density="compact" variant="outlined" label="End" v-model="trendEndDate" hide-details style="max-width: 160px" />
                <v-btn size="small" color="primary" variant="flat" @click="fetchTrendData" :loading="trendLoading">Apply</v-btn>
              </template>
              <v-btn size="small" variant="text" prepend-icon="mdi-refresh" @click="fetchTrendData" :loading="trendLoading">Refresh</v-btn>
              <v-chip v-if="trendMeta" size="x-small" variant="tonal" color="primary">{{ trendMeta.bucket }} • {{ trendMeta.since }} → {{ trendMeta.until }}</v-chip>
            </div>
          </div>
          <div ref="trendChartEl" style="height: 300px" />
        </v-card>
      </v-col>
    </v-row>

    <!-- Recent Activity Row -->
    <v-row dense>
      <!-- Recent Rentals -->
      <v-col cols="12" md="6">
        <v-card elevation="0" border rounded="lg" class="pa-5">
          <div class="d-flex align-center justify-space-between mb-4">
            <div class="d-flex align-center ga-2">
              <v-icon color="primary" size="small">mdi-car-key</v-icon>
              <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">Recent Rentals</h3>
            </div>
            <v-chip size="x-small" variant="tonal" color="primary">{{ (data?.recent_rentals || []).length }} active</v-chip>
          </div>
          <v-data-table
            :headers="rentalHeaders"
            :items="data?.recent_rentals || []"
            density="compact"
            hide-default-footer
            :items-per-page="8"
            class="rounded-lg"
          >
            <template #item.customer_name="{ value }"><span class="font-weight-medium">{{ value }}</span></template>
            <template #item.status="{ value }"><v-chip size="x-small" :color="rentalStatusColor(value)" variant="tonal">{{ value }}</v-chip></template>
            <template #item.total_amount="{ value }"><span class="font-weight-bold" style="color: #166534">{{ currencySymbol }}{{ formatNum(value) }}</span></template>
          </v-data-table>
        </v-card>
      </v-col>

      <!-- Recent Fuel + Services -->
      <v-col cols="12" md="6">
        <v-card elevation="0" border rounded="lg" class="pa-5">
          <v-tabs v-model="activityTab" density="compact" color="primary">
            <v-tab value="fuel" prepend-icon="mdi-gas-station">Fuel</v-tab>
            <v-tab value="service" prepend-icon="mdi-wrench">Services</v-tab>
          </v-tabs>
          <v-window v-model="activityTab" class="mt-2">
            <v-window-item value="fuel">
              <v-data-table
                :headers="fuelHeaders"
                :items="data?.recent_fuel || []"
                density="compact"
                hide-default-footer
                :items-per-page="5"
                class="rounded-lg"
              >
                <template #item.total_cost="{ value }"><span class="font-weight-bold" style="color: #d97706">{{ currencySymbol }}{{ formatNum(value) }}</span></template>
                <template #item.fuel_type="{ value }"><v-chip size="x-small" variant="tonal">{{ value }}</v-chip></template>
                <template #item.date="{ value }"><span class="text-caption">{{ formatDate(value) }}</span></template>
              </v-data-table>
            </v-window-item>
            <v-window-item value="service">
              <v-data-table
                :headers="serviceHeaders"
                :items="data?.recent_services || []"
                density="compact"
                hide-default-footer
                :items-per-page="5"
                class="rounded-lg"
              >
                <template #item.cost="{ value }"><span class="font-weight-bold" style="color: #2563eb">{{ currencySymbol }}{{ formatNum(value) }}</span></template>
                <template #item.service_type="{ value }"><v-chip size="x-small" variant="tonal">{{ value }}</v-chip></template>
                <template #item.performed_at="{ value }"><span class="text-caption">{{ formatDate(value) }}</span></template>
              </v-data-table>
            </v-window-item>
          </v-window>
        </v-card>
      </v-col>
    </v-row>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

import * as echarts from 'echarts/core'
import { setupECharts } from '~/utils/echarts'

setupECharts()

// Auto-enter fullscreen on dashboard load
onMounted(() => {
  const doc = document as any
  const el = document.documentElement as any
  if (!doc.fullscreenElement && !doc.webkitFullscreenElement) {
    if (el.requestFullscreen) el.requestFullscreen()
    else if (el.webkitRequestFullscreen) el.webkitRequestFullscreen()
  }
})

const { $api } = useNuxtApp()
const { currencySymbol } = useCurrency()
const activityTab = ref('fuel')
const costChartEl = ref<HTMLElement | null>(null)
let costChart: echarts.ECharts | null = null
let costRO: ResizeObserver | null = null

const monthBarEl = ref<HTMLElement | null>(null)
let monthBarChart: echarts.ECharts | null = null
let monthBarRO: ResizeObserver | null = null

const revTypeBarEl = ref<HTMLElement | null>(null)
let revTypeBarChart: echarts.ECharts | null = null
let revTypeBarRO: ResizeObserver | null = null

// ── Rental & Revenue Trend Chart ──
const trendChartEl = ref<HTMLElement | null>(null)
let trendChart: echarts.ECharts | null = null
let trendRO: ResizeObserver | null = null
const trendPeriod = ref<'week' | 'month' | 'year' | 'custom'>('year')
const trendStartDate = ref('')
const trendEndDate = ref('')
const trendData = ref<any[]>([])
const trendMeta = ref<any>(null)
const trendLoading = ref(false)
const isWeek = computed(() => trendPeriod.value === 'week')
const isMonth = computed(() => trendPeriod.value === 'month')
const isYear = computed(() => trendPeriod.value === 'year')
const isCustom = computed(() => trendPeriod.value === 'custom')

// ── Dashboard Date Filter ──
type DatePreset = 'this_week' | 'last_week' | 'this_month' | 'last_month' | 'this_year' | 'last_year' | 'custom'
const datePreset = ref<DatePreset>('this_year')
const customStartDate = ref('')
const customEndDate = ref('')

const datePresetOptions = [
  { label: 'This Week', value: 'this_week' as DatePreset },
  { label: 'Last Week', value: 'last_week' as DatePreset },
  { label: 'This Month', value: 'this_month' as DatePreset },
  { label: 'Last Month', value: 'last_month' as DatePreset },
  { label: 'This Year', value: 'this_year' as DatePreset },
  { label: 'Last Year', value: 'last_year' as DatePreset },
  { label: 'Custom', value: 'custom' as DatePreset },
]

function fmtDate(d: Date): string {
  return d.toISOString().slice(0, 10)
}

const dashboardDateQuery = computed(() => {
  const now = new Date()
  let start = ''
  let end = ''
  switch (datePreset.value) {
    case 'this_week': {
      const day = now.getDay() || 7 // Sunday=0 → 7
      start = fmtDate(new Date(now.getFullYear(), now.getMonth(), now.getDate() - day + 1))
      end = fmtDate(now)
      break
    }
    case 'last_week': {
      const day = now.getDay() || 7
      const thisMon = new Date(now.getFullYear(), now.getMonth(), now.getDate() - day + 1)
      const lastMon = new Date(thisMon)
      lastMon.setDate(lastMon.getDate() - 7)
      const lastSun = new Date(thisMon)
      lastSun.setDate(lastSun.getDate() - 1)
      start = fmtDate(lastMon)
      end = fmtDate(lastSun)
      break
    }
    case 'this_month': {
      start = fmtDate(new Date(now.getFullYear(), now.getMonth(), 1))
      end = fmtDate(now)
      break
    }
    case 'last_month': {
      start = fmtDate(new Date(now.getFullYear(), now.getMonth() - 1, 1))
      end = fmtDate(new Date(now.getFullYear(), now.getMonth(), 0))
      break
    }
    case 'this_year': {
      start = fmtDate(new Date(now.getFullYear(), 0, 1))
      end = fmtDate(now)
      break
    }
    case 'last_year': {
      start = fmtDate(new Date(now.getFullYear() - 1, 0, 1))
      end = fmtDate(new Date(now.getFullYear() - 1, 11, 31))
      break
    }
    case 'custom': {
      start = customStartDate.value
      end = customEndDate.value
      break
    }
  }
  if (!start || !end) return ''
  return `?start_date=${start}&end_date=${end}`
})

const periodLabel = computed(() => {
  const p = data.value?.period
  if (!p) return ''
  const s = new Date(p.start)
  const e = new Date(p.end)
  const fmt = (d: Date) => d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
  return `${fmt(s)} — ${fmt(e)}`
})

function applyDatePreset(p: DatePreset) {
  datePreset.value = p
  if (p !== 'custom') refresh()
}

function onCustomDateChange() {
  if (datePreset.value !== 'custom') return
  if (customStartDate.value && customEndDate.value) {
    const s = new Date(customStartDate.value)
    const e = new Date(customEndDate.value)
    if (s > e) return
    refresh()
  }
}

const { data, error, refresh, pending } = useAsyncData(
  'dashboard',
  () => $api(`/dashboard/${dashboardDateQuery.value}`),
  { watch: [dashboardDateQuery] }
)

if (error.value && error.value.statusCode !== 401) {
  console.error('Dashboard error:', error.value)
}

// ── KPI Cards ──
const kpis = computed(() => {
  const k = data.value?.kpis || {}
  return [
    { label: 'Total Vehicles', value: k.total_vehicles ?? '-', icon: 'mdi-car-multiple', bg: 'linear-gradient(135deg, #eef2ff, #e0e7ff)', border: '#c7d2fe', iconBg: '#e0e7ff', iconColor: 'primary', valueColor: '#4338ca' },
    { label: 'Active', value: k.active_vehicles ?? '-', icon: 'mdi-check-circle', bg: 'linear-gradient(135deg, #f0fdf4, #dcfce7)', border: '#bbf7d0', iconBg: '#dcfce7', iconColor: 'success', valueColor: '#166534' },
    { label: 'Out of Service', value: k.out_of_service ?? '-', icon: 'mdi-car-off', bg: 'linear-gradient(135deg, #fff7ed, #ffedd5)', border: '#fed7aa', iconBg: '#ffedd5', iconColor: 'warning', valueColor: '#c2410c' },
    { label: 'Utilization', value: k.fleet_utilization !== undefined ? k.fleet_utilization + '%' : '-', icon: 'mdi-chart-donut', bg: 'linear-gradient(135deg, #eff6ff, #dbeafe)', border: '#bfdbfe', iconBg: '#dbeafe', iconColor: 'info', valueColor: '#1e40af' },
    { label: 'Drivers', value: k.total_drivers ?? '-', icon: 'mdi-account-group', bg: 'linear-gradient(135deg, #faf5ff, #f3e8ff)', border: '#ddd6fe', iconBg: '#f3e8ff', iconColor: 'purple', valueColor: '#6b21a8' },
    { label: 'Fleet Value', value: k.total_purchase_value ? `${currencySymbol.value}` + k.total_purchase_value.toLocaleString() : '-', icon: 'mdi-cash', bg: 'linear-gradient(135deg, #ecfdf5, #d1fae5)', border: '#a7f3d0', iconBg: '#d1fae5', iconColor: 'teal', valueColor: '#115e59' },
  ]
})

const monthly = computed(() => data.value?.monthly || { revenue: 0, rental_total: 0, fuel_cost: 0, service_cost: 0, accidents: 0 })
const upcoming = computed(() => data.value?.upcoming || {})
const alertsRaw = computed(() => data.value?.alerts || {})

const alerts = computed(() => {
  const a = data.value?.alerts || {}
  return [
    { label: 'Open Issues', value: a.open_issues || 0, icon: 'mdi-alert', bg: '#fffbeb', iconBg: '#fef3c7', iconColor: '#d97706', valueColor: '#b45309' },
    { label: 'Critical', value: a.critical_issues || 0, icon: 'mdi-alert-circle-outline', bg: '#fef2f2', iconBg: '#fee2e2', iconColor: 'error', valueColor: '#dc2626' },
    { label: 'Work Orders', value: a.open_work_orders || 0, icon: 'mdi-wrench', bg: '#eff6ff', iconBg: '#dbeafe', iconColor: 'info', valueColor: '#2563eb' },
    { label: 'Overdue Rem.', value: a.overdue_reminders || 0, icon: 'mdi-bell-off-outline', bg: '#fff7ed', iconBg: '#ffedd5', iconColor: 'warning', valueColor: '#c2410c' },
    { label: 'Expired Docs', value: a.expired_docs || 0, icon: 'mdi-file-document-remove-outline', bg: '#fff1f2', iconBg: '#ffe4e6', iconColor: 'pink', valueColor: '#e11d48' },
    { label: 'Low Stock', value: a.low_stock_items || 0, icon: 'mdi-package-variant-closed', bg: '#faf5ff', iconBg: '#f3e8ff', iconColor: 'purple', valueColor: '#9333ea' },
  ]
})

// ── Chart configs ──
const STATUS_COLORS: Record<string, string> = { active: '#22c55e', out_of_service: '#f97316', in_maintenance: '#3b82f6', retired: '#94a3b8' }
const TYPE_COLORS: Record<string, string> = { vehicle: '#6366f1', trailer: '#a855f7', equipment: '#f59e0b', non_powered: '#64748b' }
const FUEL_COLORS: Record<string, string> = { ICE: '#ef4444', EV: '#22c55e', Hybrid: '#3b82f6' }

function pieOption(items: any[], colorMap: Record<string, string>) {
  const formatted = (items || []).map((i: any) => ({
    name: i.status || i.vehicle_type || i.fuel_type || 'Unknown',
    value: i.count,
    itemStyle: { color: colorMap[i.status || i.vehicle_type || i.fuel_type] || '#cbd5e1' },
  }))
  return {
    tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
    series: [{
      type: 'pie', radius: ['45%', '70%'], avoidLabelOverlap: false,
      label: { show: true, fontSize: 11, formatter: '{b}\n{c}' },
      labelLine: { length: 8, length2: 8 },
      data: formatted.length ? formatted : [{ name: 'No data', value: 1, itemStyle: { color: '#e2e8f0' } }],
    }],
  }
}

// Distinct colour palette for fleet types — each slice gets a different
// colour even when the colour map doesn't contain a matching entry.
const TYPE_PALETTE = [
  '#6366f1', '#22c55e', '#f59e0b', '#06b6d4', '#10b981', '#ec4899',
  '#ef4444', '#8b5cf6', '#f97316', '#4f46e5', '#0ea5e9', '#64748b',
  '#dc2626', '#0284c7', '#34d399', '#fb7185', '#facc15', '#1e293b',
  '#a855f7', '#14b8a6', '#e11d48', '#3b82f6', '#84cc16', '#d946ef',
]

function halfDoughnutOption(items: any[], colorMap: Record<string, string>) {
  const formatted = (items || []).map((i: any, idx: number) => {
    const key = i.vehicle_type || i.status || i.fuel_type || 'Unknown'
    return {
      name: key,
      value: i.count,
      itemStyle: {
        color: colorMap[key] || TYPE_PALETTE[idx % TYPE_PALETTE.length],
      },
    }
  })
  return {
    tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
    series: [{
      type: 'pie',
      radius: ['50%', '75%'],
      center: ['50%', '70%'],
      startAngle: 180,
      endAngle: 0,
      avoidLabelOverlap: false,
      label: { show: true, fontSize: 11, formatter: '{b}\n{c}' },
      labelLine: { length: 8, length2: 8 },
      data: formatted.length ? formatted : [{ name: 'No data', value: 1, itemStyle: { color: '#e2e8f0' } }],
    }],
  }
}

const statusChart = computed(() => pieOption(data.value?.charts?.vehicles_by_status, STATUS_COLORS))
const typeChart = computed(() => halfDoughnutOption(data.value?.charts?.vehicles_by_type, TYPE_COLORS))
const fuelChart = computed(() => pieOption(data.value?.charts?.vehicles_by_fuel, FUEL_COLORS))

// ── Cost Trend Chart ──
function renderCostChart() {
  if (!costChart || !costChartEl.value) return
  const trend = data.value?.cost_trend || []
  costChart.setOption({
    tooltip: { trigger: 'axis' },
    legend: { data: ['Fuel', 'Service'], top: 0 },
    grid: { left: 50, right: 20, top: 35, bottom: 30 },
    xAxis: { type: 'category', data: trend.map((t: any) => t.month), boundaryGap: false },
    yAxis: { type: 'value', axisLabel: { formatter: (v: number) => `${currencySymbol.value}${(v / 1000).toFixed(0)}k` } },
    series: [
      {
        name: 'Fuel', type: 'line', smooth: true, symbol: 'circle', symbolSize: 6,
        areaStyle: { color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
          { offset: 0, color: 'rgba(245, 158, 11, 0.3)' }, { offset: 1, color: 'rgba(245, 158, 11, 0.02)' },
        ]) },
        lineStyle: { width: 2.5, color: '#f59e0b' }, itemStyle: { color: '#f59e0b' },
        data: trend.map((t: any) => t.fuel),
      },
      {
        name: 'Service', type: 'line', smooth: true, symbol: 'circle', symbolSize: 6,
        areaStyle: { color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
          { offset: 0, color: 'rgba(59, 130, 246, 0.3)' }, { offset: 1, color: 'rgba(59, 130, 246, 0.02)' },
        ]) },
        lineStyle: { width: 2.5, color: '#3b82f6' }, itemStyle: { color: '#3b82f6' },
        data: trend.map((t: any) => t.service),
      },
    ],
  })
}

function ensureCostInit() {
  if (costChart || !costChartEl.value) return
  if (costChartEl.value.clientWidth === 0) return
  costChart = echarts.init(costChartEl.value)
  renderCostChart()
}

// ── This Month Bar Chart ──
function renderMonthBar() {
  if (!monthBarChart || !monthBarEl.value) return
  const bars = [...(data.value?.monthly_bar || [])].sort((a: any, b: any) => a.value - b.value)
  monthBarChart.setOption({
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, formatter: (p: any) => `${p[0].name}<br/>${currencySymbol.value}${Number(p[0].value).toLocaleString()}` },
    grid: { left: 80, right: 50, top: 10, bottom: 30 },
    xAxis: {
      type: 'value',
      axisLabel: { formatter: (v: number) => `${(v / 1000).toFixed(0)}k` },
      splitLine: { lineStyle: { color: '#f1f5f9' } },
    },
    yAxis: {
      type: 'category',
      data: bars.map((b: any) => b.label),
      axisLine: { show: false }, axisTick: { show: false },
      axisLabel: { fontWeight: 600, color: '#475569' },
    },
    series: [{
      type: 'bar',
      barWidth: '55%',
      data: bars.map((b: any) => ({ value: b.value, itemStyle: { color: b.color, borderRadius: [0, 6, 6, 0] } })),
      label: { show: true, position: 'right', formatter: (p: any) => `${(Number(p.value) / 1000).toFixed(1)}k`, fontWeight: 600, fontSize: 11 },
    }],
  })
}

function ensureMonthBarInit() {
  if (monthBarChart || !monthBarEl.value) return
  if (monthBarEl.value.clientWidth === 0) return
  monthBarChart = echarts.init(monthBarEl.value)
  renderMonthBar()
}

// ── Rental Revenue by Vehicle Type Bar Chart ──
function renderRevTypeBar() {
  if (!revTypeBarChart || !revTypeBarEl.value) return
  const rows = data.value?.revenue_by_type || []
  revTypeBarChart.setOption({
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, formatter: (p: any) => `${p[0].name}<br/>${currencySymbol.value}${Number(p[0].value).toLocaleString()}` },
    grid: { left: 60, right: 20, top: 10, bottom: 55 },
    xAxis: {
      type: 'category',
      data: rows.map((r: any) => r.type || 'Unknown'),
      axisLine: { show: false }, axisTick: { show: false },
      axisLabel: { fontWeight: 600, color: '#475569', interval: 0, rotate: rows.length > 4 ? 25 : 0, width: 120, overflow: 'truncate', ellipsis: '…' },
    },
    yAxis: {
      type: 'value',
      axisLabel: { formatter: (v: number) => `${(v / 1000).toFixed(0)}k` },
      splitLine: { lineStyle: { color: '#f1f5f9' } },
    },
    series: [{
      type: 'bar',
      barWidth: '50%',
      data: rows.map((r: any, i: number) => ({
        value: r.total,
        itemStyle: { color: ['#3b82f6', '#10b981', '#f59e0b', '#8b5cf6', '#ef4444', '#06b6d4'][i % 6], borderRadius: [6, 6, 0, 0] },
      })),
      label: { show: true, position: 'top', formatter: (p: any) => `${(Number(p.value) / 1000).toFixed(1)}k`, fontWeight: 600, fontSize: 11 },
    }],
  })
}

function ensureRevTypeBarInit() {
  if (revTypeBarChart || !revTypeBarEl.value) return
  if (revTypeBarEl.value.clientWidth === 0) return
  revTypeBarChart = echarts.init(revTypeBarEl.value)
  renderRevTypeBar()
}

// ── Rental & Revenue Trend Chart ──
async function fetchTrendData() {
  trendLoading.value = true
  try {
    const params = new URLSearchParams()
    if (trendPeriod.value !== 'custom') {
      params.append('period', trendPeriod.value)
    } else {
      params.append('period', 'custom')
      if (trendStartDate.value) params.append('start', trendStartDate.value)
      if (trendEndDate.value) params.append('end', trendEndDate.value)
    }
    const res = await $api(`/dashboard/rental-trend/?${params.toString()}`)
    trendData.value = res.trend || []
    trendMeta.value = { since: res.since, until: res.until, bucket: res.bucket }
  } catch (e) {
    console.error('Trend fetch error:', e)
    trendData.value = []
  } finally {
    trendLoading.value = false
  }
}

function setTrendPeriod(p: 'week' | 'month' | 'year') {
  trendPeriod.value = p
  fetchTrendData()
}

function renderTrendChart() {
  if (!trendChart || !trendChartEl.value) return
  const rows = trendData.value || []
  const hasData = rows.length > 0
  trendChart.setOption({
    tooltip: { trigger: 'axis' },
    legend: { data: ['Revenue', 'Payments'], top: 0 },
    grid: { left: 60, right: 20, top: 35, bottom: 75 },
    xAxis: {
      type: 'category',
      data: rows.map((r: any) => r.date),
      boundaryGap: false,
      axisLabel: { fontSize: 10, interval: 0, rotate: rows.length > 15 ? 45 : 0 },
    },
    yAxis: {
      type: 'value',
      axisLabel: { formatter: (v: number) => `${currencySymbol.value}${(v / 1000).toFixed(0)}k` },
      splitLine: { lineStyle: { color: '#f1f5f9' } },
    },
    series: [
      {
        name: 'Revenue', type: 'line', smooth: true, symbol: 'circle', symbolSize: 5,
        areaStyle: { color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
          { offset: 0, color: 'rgba(59, 130, 246, 0.3)' }, { offset: 1, color: 'rgba(59, 130, 246, 0.02)' },
        ]) },
        lineStyle: { width: 2.5, color: '#3b82f6' }, itemStyle: { color: '#3b82f6' },
        data: rows.map((r: any) => r.revenue),
      },
      {
        name: 'Payments', type: 'line', smooth: true, symbol: 'circle', symbolSize: 5,
        areaStyle: { color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
          { offset: 0, color: 'rgba(16, 185, 129, 0.3)' }, { offset: 1, color: 'rgba(16, 185, 129, 0.02)' },
        ]) },
        lineStyle: { width: 2.5, color: '#10b981' }, itemStyle: { color: '#10b981' },
        data: rows.map((r: any) => r.payments),
      },
    ],
  })
}

function ensureTrendInit() {
  if (trendChart || !trendChartEl.value) return
  if (trendChartEl.value.clientWidth === 0) return
  trendChart = echarts.init(trendChartEl.value)
  renderTrendChart()
}

onMounted(() => {
  ensureCostInit()
  ensureMonthBarInit()
  ensureRevTypeBarInit()
  ensureTrendInit()
  costRO = new ResizeObserver(() => { if (costChart) costChart.resize(); else ensureCostInit() })
  monthBarRO = new ResizeObserver(() => { if (monthBarChart) monthBarChart.resize(); else ensureMonthBarInit() })
  revTypeBarRO = new ResizeObserver(() => { if (revTypeBarChart) revTypeBarChart.resize(); else ensureRevTypeBarInit() })
  trendRO = new ResizeObserver(() => { if (trendChart) trendChart.resize(); else ensureTrendInit() })
  if (costChartEl.value) costRO.observe(costChartEl.value)
  if (monthBarEl.value) monthBarRO.observe(monthBarEl.value)
  if (revTypeBarEl.value) revTypeBarRO.observe(revTypeBarEl.value)
  if (trendChartEl.value) trendRO.observe(trendChartEl.value)
  // Fetch trend data on mount
  fetchTrendData()
})

onUnmounted(() => {
  costChart?.dispose()
  monthBarChart?.dispose()
  revTypeBarChart?.dispose()
  trendChart?.dispose()
  costRO?.disconnect()
  monthBarRO?.disconnect()
  revTypeBarRO?.disconnect()
  trendRO?.disconnect()
})

watch(() => data.value, () => {
  if (costChart) renderCostChart()
  else ensureCostInit()
  if (monthBarChart) renderMonthBar()
  else ensureMonthBarInit()
  if (revTypeBarChart) renderRevTypeBar()
  else ensureRevTypeBarInit()
}, { flush: 'post' })

watch(() => trendData.value, () => {
  if (trendChart) renderTrendChart()
  else ensureTrendInit()
}, { flush: 'post' })

// ── Table headers ──
const rentalHeaders = [
  { title: 'Agreement', key: 'agreement_no', width: '110px' },
  { title: 'Customer', key: 'customer_name' },
  { title: 'Vehicle', key: 'vehicle_display' },
  { title: 'Status', key: 'status', width: '90px' },
  { title: 'Amount', key: 'total_amount', align: 'end' as const },
]
const fuelHeaders = [
  { title: 'Vehicle', key: 'vehicle_display' },
  { title: 'Type', key: 'fuel_type', width: '80px' },
  { title: 'Qty', key: 'quantity', width: '70px' },
  { title: 'Cost', key: 'total_cost', align: 'end' as const },
  { title: 'Date', key: 'date', width: '90px' },
]
const serviceHeaders = [
  { title: 'Vehicle', key: 'vehicle_display' },
  { title: 'Type', key: 'service_type', width: '100px' },
  { title: 'Cost', key: 'cost', align: 'end' as const },
  { title: 'Date', key: 'performed_at', width: '90px' },
]

function rentalStatusColor(status: string) {
  const map: Record<string, string> = { active: 'success', completed: 'info', overdue: 'error', cancelled: 'grey', draft: 'warning' }
  return map[status] || 'grey'
}

function formatNum(n: number | undefined) {
  if (!n) return '0'
  return Math.round(n).toLocaleString()
}

function formatDate(iso: string | null) {
  if (!iso) return ''
  const d = new Date(iso)
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
}

useHead({ title: 'Fleet Dashboard' })
</script>

