<template>
  <div class="d-flex flex-column ga-4">
    <!-- Header -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-2">
      <div>
        <h1 class="text-h5 font-weight-bold" style="color: #1e293b">Car Hire &amp; Rental Analytics</h1>
        <p class="text-caption text-medium-emphasis">Agreements, revenue, payments &amp; customer insights</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn-toggle v-model="period" mandatory density="compact" color="primary">
          <v-btn value="all" size="small">All Time</v-btn>
          <v-btn value="y" size="small">This Year</v-btn>
          <v-btn value="365" size="small">365d</v-btn>
          <v-btn value="90" size="small">90d</v-btn>
          <v-btn value="custom" size="small" @click="openCustomDate">Custom…</v-btn>
        </v-btn-toggle>
      </div>
    </div>

    <!-- Custom Date Range Dialog -->
    <v-dialog v-model="customDateDialogVisible" max-width="420">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-calendar-range">Custom Date Range</AppModalHeader>
        <v-card-text class="pt-4">
          <v-row dense>
            <v-col cols="12">
              <v-text-field v-model="customFrom" type="date" label="From (Agreement Created)" density="comfortable" variant="outlined" prepend-inner-icon="mdi-calendar-start" hide-details="auto" />
            </v-col>
            <v-col cols="12">
              <v-text-field v-model="customTo" type="date" label="To (Agreement Created)" density="comfortable" variant="outlined" prepend-inner-icon="mdi-calendar-end" hide-details="auto" />
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

    <!-- KPI Row -->
    <v-row dense>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100 kpi-hover" style="background: linear-gradient(135deg, #6366f1 0%, #818cf8 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-file-document-multiple</v-icon><span class="text-caption" style="color:#fff !important">Total Agreements</span></div>
          <p class="text-h4 font-weight-bold" style="color: #fff !important">{{ stats.total }}</p>
          <p class="text-caption" style="color:#fff !important; opacity:.85">{{ stats.active }} active · {{ stats.overdue }} overdue</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100 kpi-hover" style="background: linear-gradient(135deg, #10b981 0%, #34d399 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-cash-check</v-icon><span class="text-caption" style="color:#fff !important">Revenue</span></div>
          <p class="text-h4 font-weight-bold" style="color: #fff !important">{{ currencySymbol }}{{ formatNumber(stats.revenue) }}</p>
          <p class="text-caption" style="color:#fff !important; opacity:.85">Total billed</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100 kpi-hover" style="background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-chart-donut</v-icon><span class="text-caption" style="color:#fff !important">Collection Rate</span></div>
          <p class="text-h4 font-weight-bold" style="color: #fff !important">{{ collectionRate }}%</p>
          <p class="text-caption" style="color:#fff !important; opacity:.85">{{ currencySymbol }}{{ formatNumber(stats.collected) }} collected</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100 kpi-hover" style="background: linear-gradient(135deg, #ef4444 0%, #f87171 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-cash-off</v-icon><span class="text-caption" style="color:#fff !important">Outstanding</span></div>
          <p class="text-h4 font-weight-bold" style="color: #fff !important">{{ currencySymbol }}{{ formatNumber(stats.outstanding) }}</p>
          <p class="text-caption" style="color:#fff !important; opacity:.85">{{ stats.completed }} completed · {{ stats.cancelled }} cancelled</p>
        </v-card>
      </v-col>
    </v-row>

    <!-- Secondary KPI Row -->
    <v-row dense>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-4 h-100">
          <div class="d-flex align-center ga-2">
            <div class="kpi-icon-badge" style="background: #eef2ff; color: #4f46e5;"><v-icon size="20">mdi-car-key</v-icon></div>
            <div>
              <p class="text-h6 font-weight-bold mb-0" style="color:#1e293b">{{ stats.active }}</p>
              <p class="text-caption text-medium-emphasis">Active Now</p>
            </div>
          </div>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-4 h-100">
          <div class="d-flex align-center ga-2">
            <div class="kpi-icon-badge" style="background: #fef3c7; color: #d97706;"><v-icon size="20">mdi-clock-alert</v-icon></div>
            <div>
              <p class="text-h6 font-weight-bold mb-0" style="color:#1e293b">{{ stats.overdue }}</p>
              <p class="text-caption text-medium-emphasis">Overdue</p>
            </div>
          </div>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-4 h-100">
          <div class="d-flex align-center ga-2">
            <div class="kpi-icon-badge" style="background: #ecfdf5; color: #059669;"><v-icon size="20">mdi-account-multiple</v-icon></div>
            <div>
              <p class="text-h6 font-weight-bold mb-0" style="color:#1e293b">{{ stats.customers }}</p>
              <p class="text-caption text-medium-emphasis">Customers</p>
            </div>
          </div>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-4 h-100">
          <div class="d-flex align-center ga-2">
            <div class="kpi-icon-badge" style="background: #fce7f3; color: #db2777;"><v-icon size="20">mdi-cash-multiple</v-icon></div>
            <div>
              <p class="text-h6 font-weight-bold mb-0" style="color:#1e293b">{{ stats.paymentCount }}</p>
              <p class="text-caption text-medium-emphasis">Payments Recorded</p>
            </div>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <!-- Tabs for detailed analytics -->
    <v-card elevation="0" border rounded="lg">
      <v-tabs v-model="tab" color="primary" density="compact">
        <v-tab value="overview" slider-color="primary"><v-icon size="small" class="mr-2">mdi-chart-pie</v-icon> Overview</v-tab>
        <v-tab value="revenue" slider-color="primary"><v-icon size="small" class="mr-2">mdi-cash-multiple</v-icon> Revenue &amp; Payments</v-tab>
        <v-tab value="customers" slider-color="primary"><v-icon size="small" class="mr-2">mdi-account-group</v-icon> Customers &amp; Vehicles</v-tab>
      </v-tabs>
      <v-divider />
      <v-window v-model="tab" class="pa-5">
        <!-- Overview Tab -->
        <v-window-item value="overview">
          <v-row dense>
            <v-col cols="12" md="6" lg="4">
              <DashboardChart :option="statusChartOption" title="Agreement Status" icon="mdi-chart-pie" height="280px" />
            </v-col>
            <v-col cols="12" md="6" lg="4">
              <DashboardChart :option="paymentStatusChartOption" title="Payment Status" icon="mdi-cash-sync" height="280px" />
            </v-col>
            <v-col cols="12" md="6" lg="4">
              <DashboardChart :option="ratePeriodChartOption" title="Rate Periods" icon="mdi-calendar-multiple" height="280px" />
            </v-col>
            <v-col cols="12" md="6" lg="6">
              <DashboardChart :option="agreementTrendOption" title="Agreement Creation Trend" icon="mdi-chart-line-variant" height="300px" />
            </v-col>
            <v-col cols="12" md="6" lg="6">
              <v-card elevation="0" border class="pa-5 h-100">
                <h3 class="text-subtitle-1 font-weight-medium mb-4"><v-icon size="small" color="primary" class="mr-2">mdi-format-list-bulleted</v-icon> Status Summary</h3>
                <div v-for="item in statusList" :key="item.label" class="d-flex align-center justify-space-between pa-3 rounded-lg mb-2" :style="{ background: item.bg }">
                  <div class="d-flex align-center ga-2">
                    <v-avatar :color="item.color" size="32" rounded="lg" variant="flat">
                      <v-icon size="small" color="white">{{ item.icon }}</v-icon>
                    </v-avatar>
                    <span class="text-body-2 font-weight-medium" style="color: #1e293b">{{ item.label }}</span>
                  </div>
                  <span class="text-body-1 font-weight-bold" :style="{ color: item.color }">{{ item.count }}</span>
                </div>
              </v-card>
            </v-col>
          </v-row>
        </v-window-item>

        <!-- Revenue & Payments Tab -->
        <v-window-item value="revenue">
          <v-row dense>
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 text-center">
                <v-icon color="success" size="large">mdi-cash-check</v-icon>
                <p class="text-h6 font-weight-bold mt-2">{{ currencySymbol }}{{ formatNumber(stats.collected) }}</p>
                <p class="text-caption text-medium-emphasis">Collected</p>
              </v-card>
            </v-col>
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 text-center">
                <v-icon color="error" size="large">mdi-cash-off</v-icon>
                <p class="text-h6 font-weight-bold mt-2">{{ currencySymbol }}{{ formatNumber(stats.outstanding) }}</p>
                <p class="text-caption text-medium-emphasis">Outstanding</p>
              </v-card>
            </v-col>
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 text-center">
                <v-icon color="info" size="large">mdi-file-document-outline</v-icon>
                <p class="text-h6 font-weight-bold mt-2">{{ currencySymbol }}{{ formatNumber(stats.revenue) }}</p>
                <p class="text-caption text-medium-emphasis">Invoiced</p>
              </v-card>
            </v-col>
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 text-center">
                <v-icon color="primary" size="large"> mdi-chart-donut</v-icon>
                <p class="text-h6 font-weight-bold mt-2">{{ collectionRate }}%</p>
                <p class="text-caption text-medium-emphasis">Collection Rate</p>
              </v-card>
            </v-col>
            <v-col cols="12" md="6">
              <DashboardChart :option="revenueTrendOption" title="Revenue Trend" icon="mdi-chart-line" height="300px" />
            </v-col>
            <v-col cols="12" md="6">
              <DashboardChart :option="paymentMethodChartOption" title="Payment Methods" icon="mdi-credit-card-multiple" height="300px" />
            </v-col>
            <v-col cols="12">
              <DashboardChart :option="monthlyRevenueVsCollectedOption" title="Monthly Revenue vs Collected" icon="mdi-chart-areaspline" height="320px" />
            </v-col>
          </v-row>
        </v-window-item>

        <!-- Customers & Vehicles Tab -->
        <v-window-item value="customers">
          <v-row dense>
            <v-col cols="12" md="6" lg="4">
              <DashboardChart :option="customerTypeChartOption" title="Customer Type" icon="mdi-account-group" height="280px" />
            </v-col>
            <v-col cols="12" md="6" lg="8">
              <DashboardChart :option="topVehiclesChartOption" title="Top Rented Vehicles" icon="mdi-car-multiple" height="280px" />
            </v-col>
            <v-col cols="12" md="6">
              <DashboardChart :option="topCustomersChartOption" title="Top Customers by Revenue" icon="mdi-account-cash" height="300px" />
            </v-col>
            <v-col cols="12" md="6">
              <v-card elevation="0" border class="pa-5 h-100">
                <h3 class="text-subtitle-1 font-weight-medium mb-4"><v-icon size="small" color="primary" class="mr-2">mdi-account-group</v-icon> Customer Breakdown</h3>
                <div class="d-flex align-center justify-space-between pa-3 rounded-lg mb-2" style="background:#10b98108">
                  <div class="d-flex align-center ga-2">
                    <v-avatar color="#10b981" size="32" rounded="lg" variant="flat"><v-icon size="small" color="white">mdi-home-account</v-icon></v-avatar>
                    <span class="text-body-2 font-weight-medium" style="color:#1e293b">Local Customers</span>
                  </div>
                  <span class="text-body-1 font-weight-bold" style="color:#10b981">{{ stats.local }}</span>
                </div>
                <div class="d-flex align-center justify-space-between pa-3 rounded-lg mb-2" style="background:#6366f108">
                  <div class="d-flex align-center ga-2">
                    <v-avatar color="#6366f1" size="32" rounded="lg" variant="flat"><v-icon size="small" color="white">mdi-passport</v-icon></v-avatar>
                    <span class="text-body-2 font-weight-medium" style="color:#1e293b">Foreigner Customers</span>
                  </div>
                  <span class="text-body-1 font-weight-bold" style="color:#6366f1">{{ stats.foreigner }}</span>
                </div>
                <v-divider class="my-3" />
                <v-row dense>
                  <v-col cols="6" class="text-center">
                    <p class="text-h5 font-weight-bold text-primary">{{ stats.customers }}</p>
                    <p class="text-caption text-medium-emphasis">Total Customers</p>
                  </v-col>
                  <v-col cols="6" class="text-center">
                    <p class="text-h5 font-weight-bold text-info">{{ uniqueVehicles }}</p>
                    <p class="text-caption text-medium-emphasis">Unique Vehicles Rented</p>
                  </v-col>
                </v-row>
              </v-card>
            </v-col>
            <v-col cols="12">
              <DashboardChart :option="avgRentalDurationOption" title="Avg Rental Duration by Rate Period (days)" icon="mdi-calendar-clock" height="300px" />
            </v-col>
          </v-row>
        </v-window-item>
      </v-window>
    </v-card>
  </div>
</template>

<script setup lang="ts">
const { $api } = useNuxtApp()
const { currencySymbol } = useCurrency()
const tab = ref('overview')
const period = ref('all')
const customFrom = ref('')
const customTo = ref('')
const customDateDialogVisible = ref(false)
const customDateError = ref('')

/** Returns a date filter to apply to agreement creation date. */
function dateFilter(): (d: string | Date) => boolean {
  if (period.value === 'custom' && customFrom.value && customTo.value) {
    const from = new Date(customFrom.value)
    const to = new Date(customTo.value + 'T23:59:59')
    return (d) => { const dt = new Date(d); return dt >= from && dt <= to }
  }
  if (period.value === 'y') {
    const start = new Date(`${new Date().getFullYear()}-01-01`)
    return (d) => new Date(d) >= start
  }
  if (period.value === '365' || period.value === '90') {
    const past = new Date(); past.setDate(past.getDate() - Number(period.value))
    return (d) => new Date(d) >= past
  }
  return () => true
}

function openCustomDate() {
  if (!customFrom.value || !customTo.value) {
    const today = new Date()
    const past = new Date()
    past.setFullYear(past.getFullYear() - 1)
    customTo.value = today.toISOString().slice(0, 10)
    customFrom.value = past.toISOString().slice(0, 10)
  }
  customDateError.value = ''
  customDateDialogVisible.value = true
}
function applyCustomDate() {
  if (!customFrom.value || !customTo.value) { customDateError.value = 'Please select both from and to dates.'; return }
  if (new Date(customFrom.value) > new Date(customTo.value)) { customDateError.value = 'From date must be before To date.'; return }
  customDateDialogVisible.value = false
  refresh()
}
function cancelCustomDate() {
  customDateDialogVisible.value = false
  if (!customFrom.value || !customTo.value) period.value = 'all'
  else period.value = 'custom'
}

const { data, refresh, pending } = useAsyncData(
  'rentals-analytics',
  async () => {
    const [agreementsRes, customersRes, paymentsRes, summary] = await Promise.all([
      $api<any>('/rentals/agreements/?page_size=1000').catch(() => []),
      $api<any>('/rentals/customers/?page_size=1000').catch(() => []),
      $api<any>('/rentals/payments/?page_size=1000').catch(() => []),
      $api<any>('/rentals/payments/summary/').catch(() => ({})),
    ])
    // DRF paginated responses are { count, results: [...] }  — extract the array.
    const agreements = Array.isArray(agreementsRes) ? agreementsRes : (agreementsRes?.results || [])
    const customers = Array.isArray(customersRes) ? customersRes : (customersRes?.results || [])
    const payments = Array.isArray(paymentsRes) ? paymentsRes : (paymentsRes?.results || [])
    return { agreements, customers, payments, summary }
  },
  { default: () => ({ agreements: [], customers: [], payments: [], summary: {} }), watch: [period] }
)

/** Treat active agreements with past end_datetime as overdue (mirrors rentals/index.vue). */
function effectiveStatus(a: any): string {
  const s = a.status
  if (!s) return 'draft'
  if (s === 'active' && a.end_datetime) {
    if (new Date(a.end_datetime).getTime() < Date.now()) return 'overdue'
  }
  return s
}

const filteredAgreements = computed(() => {
  const fn = dateFilter()
  return (data.value.agreements || []).filter((a) => fn(a.created_at || a.start_datetime))
})
const filteredPayments = computed(() => {
  const fn = dateFilter()
  return (data.value.payments || []).filter((p) => fn(p.paid_at))
})

const stats = computed(() => {
  const list = filteredAgreements.value
  const paymentsList = filteredPayments.value
  const s = data.value.summary || {}
  const collected = Number(s.total_collected || 0)
  const outstanding = Number(s.total_outstanding || 0)
  return {
    total: list.length,
    active: list.filter((a) => effectiveStatus(a) === 'active').length,
    overdue: list.filter((a) => effectiveStatus(a) === 'overdue').length,
    completed: list.filter((a) => a.status === 'completed').length,
    cancelled: list.filter((a) => a.status === 'cancelled').length,
    customers: (data.value.customers || []).length,
    local: (data.value.customers || []).filter((c) => c.customer_type === 'local').length,
    foreigner: (data.value.customers || []).filter((c) => c.customer_type === 'foreigner').length,
    revenue: list.reduce((sum, a) => sum + Number(a.total_amount || 0), 0),
    collected,
    outstanding,
    paymentCount: paymentsList.length,
  }
})

const collectionRate = computed(() => {
  const inv = stats.value.revenue
  const col = stats.value.collected
  return inv > 0 ? Math.round((col / inv) * 100) : 0
})

const uniqueVehicles = computed(() => {
  const ids = new Set(filteredAgreements.value.map((a) => a.vehicle).filter(Boolean))
  return ids.size
})

function formatNumber(val: any) {
  if (!val || isNaN(val)) return '0'
  return Number(val).toLocaleString('en-US', { maximumFractionDigits: 0 })
}

/* ---------------- Charts ---------------- */
const palette = ['#6366f1', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4', '#ec4899', '#84cc16']

const statusChartOption = computed(() => {
  const list = filteredAgreements.value
  const counts: Record<string, number> = {}
  list.forEach((a) => { const s = effectiveStatus(a); counts[s] = (counts[s] || 0) + 1 })
  const statusData = Object.entries(counts).map(([name, value]) => ({ name: name.charAt(0).toUpperCase() + name.slice(1), value }))
  return {
    tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
    legend: { bottom: 0, textStyle: { fontSize: 11 } },
    color: palette,
    series: [{ type: 'pie', radius: ['40%', '70%'], avoidLabelOverlap: false, itemStyle: { borderRadius: 8, borderColor: '#fff', borderWidth: 2 }, label: { show: false }, emphasis: { label: { show: true, fontSize: 14, fontWeight: 'bold' } }, data: statusData }],
  }
})

const paymentStatusChartOption = computed(() => {
  const list = filteredAgreements.value.filter((a) => a.status !== 'draft' && a.status !== 'cancelled')
  const counts: Record<string, number> = { paid: 0, partial: 0, unpaid: 0 }
  list.forEach((a) => { const p = a.payment_status; if (counts[p] !== undefined) counts[p]++ })
  const payStatusData = Object.entries(counts).map(([name, value]) => ({ name: name.charAt(0).toUpperCase() + name.slice(1), value }))
  return {
    tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
    legend: { bottom: 0, textStyle: { fontSize: 11 } },
    color: ['#10b981', '#f59e0b', '#ef4444'],
    series: [{ type: 'pie', radius: ['40%', '70%'], itemStyle: { borderRadius: 8, borderColor: '#fff', borderWidth: 2 }, label: { show: false }, emphasis: { label: { show: true, fontSize: 14, fontWeight: 'bold' } }, data: payStatusData }],
  }
})

const ratePeriodChartOption = computed(() => {
  const list = filteredAgreements.value
  const counts: Record<string, number> = {}
  list.forEach((a) => { const r = a.rate_period; if (r) counts[r] = (counts[r] || 0) + 1 })
  const labels = Object.keys(counts)
  const values = Object.values(counts)
  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: labels, axisLabel: { fontSize: 11 } },
    yAxis: { type: 'value' },
    color: ['#8b5cf6'],
    series: [{ type: 'bar', data: values, itemStyle: { borderRadius: [6, 6, 0, 0], color: '#8b5cf6' }, barWidth: '40%' }],
  }
})

const agreementTrendOption = computed(() => {
  const list = filteredAgreements.value
  const months: Record<string, number> = {}
  list.forEach((a) => {
    const d = a.created_at || a.start_datetime
    if (!d) return
    const key = String(d).slice(0, 7) // YYYY-MM
    months[key] = (months[key] || 0) + 1
  })
  const sorted = Object.keys(months).sort()
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: sorted, axisLabel: { fontSize: 11, rotate: 30 } },
    yAxis: { type: 'value', minInterval: 1 },
    color: ['#6366f1'],
    series: [{ type: 'line', data: sorted.map((m) => months[m]), smooth: true, areaStyle: { opacity: 0.15 }, lineStyle: { width: 3 }, symbolSize: 8 }],
  }
})

const revenueTrendOption = computed(() => {
  const list = filteredAgreements.value
  const months: Record<string, number> = {}
  list.forEach((a) => {
    const d = a.created_at || a.start_datetime
    if (!d) return
    const key = String(d).slice(0, 7)
    months[key] = (months[key] || 0) + Number(a.total_amount || 0)
  })
  const sorted = Object.keys(months).sort()
  return {
    tooltip: { trigger: 'axis', formatter: (p: any) => `${p[0].name}<br/>${currencySymbol.value}${Number(p[0].value).toLocaleString()}` },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: sorted, axisLabel: { fontSize: 11, rotate: 30 } },
    yAxis: { type: 'value' },
    color: ['#10b981'],
    series: [{ type: 'line', data: sorted.map((m) => Math.round(months[m])), smooth: true, areaStyle: { opacity: 0.2 }, lineStyle: { width: 3 }, symbolSize: 8 }],
  }
})

const paymentMethodChartOption = computed(() => {
  const list = filteredPayments.value
  const counts: Record<string, number> = {}
  list.forEach((p) => { const m = p.payment_method; if (m) counts[m] = (counts[m] || 0) + 1 })
  const payData = Object.entries(counts).map(([name, value]) => ({
    name: name.split('_').map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join(' '),
    value,
  }))
  return {
    tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
    legend: { bottom: 0, textStyle: { fontSize: 11 } },
    color: ['#10b981', '#f59e0b', '#6366f1', '#8b5cf6', '#06b6d4', '#94a3b8'],
    series: [{ type: 'pie', radius: ['40%', '70%'], itemStyle: { borderRadius: 8, borderColor: '#fff', borderWidth: 2 }, label: { show: false }, emphasis: { label: { show: true, fontSize: 14, fontWeight: 'bold' } }, data: payData }],
  }
})

const monthlyRevenueVsCollectedOption = computed(() => {
  const agreements = filteredAgreements.value
  const payments = filteredPayments.value
  const inv: Record<string, number> = {}
  const col: Record<string, number> = {}
  agreements.forEach((a) => {
    const d = a.created_at || a.start_datetime
    if (!d) return
    const key = String(d).slice(0, 7)
    inv[key] = (inv[key] || 0) + Number(a.total_amount || 0)
  })
  payments.forEach((p) => {
    if (!p.paid_at) return
    const key = String(p.paid_at).slice(0, 7)
    col[key] = (col[key] || 0) + Number(p.amount || 0)
  })
  const sorted = Array.from(new Set([...Object.keys(inv), ...Object.keys(col)])).sort()
  return {
    tooltip: { trigger: 'axis' },
    legend: { data: ['Invoiced', 'Collected'], bottom: 0, textStyle: { fontSize: 11 } },
    grid: { left: '3%', right: '4%', bottom: '10%', containLabel: true },
    xAxis: { type: 'category', data: sorted, axisLabel: { fontSize: 11, rotate: 30 } },
    yAxis: { type: 'value' },
    color: ['#6366f1', '#10b981'],
    series: [
      { name: 'Invoiced', type: 'bar', data: sorted.map((m) => Math.round(inv[m] || 0)), itemStyle: { borderRadius: [6, 6, 0, 0], color: '#6366f1' }, barGap: '20%' },
      { name: 'Collected', type: 'bar', data: sorted.map((m) => Math.round(col[m] || 0)), itemStyle: { borderRadius: [6, 6, 0, 0], color: '#10b981' } },
    ],
  }
})

const customerTypeChartOption = computed(() => {
  const list = data.value.customers || []
  const counts: Record<string, number> = {}
  list.forEach((c) => { const t = c.customer_type; if (t) counts[t] = (counts[t] || 0) + 1 })
  const custData = Object.entries(counts).map(([name, value]) => ({
    name: name.charAt(0).toUpperCase() + name.slice(1),
    value,
  }))
  return {
    tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
    legend: { bottom: 0, textStyle: { fontSize: 11 } },
    color: ['#10b981', '#6366f1'],
    series: [{ type: 'pie', radius: ['40%', '70%'], itemStyle: { borderRadius: 8, borderColor: '#fff', borderWidth: 2 }, label: { show: false }, emphasis: { label: { show: true, fontSize: 14, fontWeight: 'bold' } }, data: custData }],
  }
})

const topVehiclesChartOption = computed(() => {
  const list = filteredAgreements.value
  const counts: Record<string, number> = {}
  list.forEach((a) => {
    const v = a.vehicle_display || 'Unknown'
    counts[v] = (counts[v] || 0) + 1
  })
  const sorted = Object.entries(counts).sort((a, b) => b[1] - a[1]).slice(0, 8)
  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: sorted.map((s) => s[0]), axisLabel: { fontSize: 11, rotate: 25 } },
    yAxis: { type: 'value', minInterval: 1 },
    color: ['#06b6d4'],
    series: [{ type: 'bar', data: sorted.map((s) => s[1]), itemStyle: { borderRadius: [6, 6, 0, 0], color: '#06b6d4' }, barWidth: '50%' }],
  }
})

const topCustomersChartOption = computed(() => {
  const list = filteredAgreements.value
  const rev: Record<string, number> = {}
  list.forEach((a) => {
    const c = a.customer_name || 'Unknown'
    rev[c] = (rev[c] || 0) + Number(a.total_amount || 0)
  })
  const sorted = Object.entries(rev).sort((a, b) => b[1] - a[1]).slice(0, 8)
  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, formatter: (p: any) => `${p[0].name}<br/>${currencySymbol.value}${Number(p[0].value).toLocaleString()}` },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: sorted.map((s) => s[0]), axisLabel: { fontSize: 11, rotate: 25 } },
    yAxis: { type: 'value' },
    color: ['#ec4899'],
    series: [{ type: 'bar', data: sorted.map((s) => Math.round(s[1])), itemStyle: { borderRadius: [6, 6, 0, 0], color: '#ec4899' }, barWidth: '50%' }],
  }
})

const avgRentalDurationOption = computed(() => {
  const list = filteredAgreements.value.filter((a) => a.start_datetime && a.end_datetime && (a.status === 'completed' || effectiveStatus(a) === 'overdue'))
  const byPeriod: Record<string, number[]> = {}
  list.forEach((a) => {
    if (!a.rate_period) return
    const start = new Date(a.start_datetime).getTime()
    const end = new Date(a.end_datetime).getTime()
    if (end <= start) return
    const days = Math.round((end - start) / (1000 * 60 * 60 * 24))
    if (!byPeriod[a.rate_period]) byPeriod[a.rate_period] = []
    byPeriod[a.rate_period].push(days)
  })
  const labels = Object.keys(byPeriod)
  const values = labels.map((l) => Math.round(byPeriod[l].reduce((a, b) => a + b, 0) / byPeriod[l].length))
  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, formatter: (p: any) => `${p[0].name}<br/>${p[0].value} days avg` },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: labels, axisLabel: { fontSize: 11 } },
    yAxis: { type: 'value', minInterval: 1 },
    color: ['#f59e0b'],
    series: [{ type: 'bar', data: values, itemStyle: { borderRadius: [6, 6, 0, 0], color: '#f59e0b' }, barWidth: '40%' }],
  }
})

/* ---------------- Status Summary list ---------------- */
const statusList = computed(() => {
  const list = filteredAgreements.value
  const counts: Record<string, number> = {}
  list.forEach((a) => { const s = effectiveStatus(a); counts[s] = (counts[s] || 0) + 1 })
  const map: Record<string, { color: string; icon: string; label: string }> = {
    draft: { color: '#64748b', icon: 'mdi-pencil-outline', label: 'Draft' },
    active: { color: '#10b981', icon: 'mdi-play-circle', label: 'Active' },
    overdue: { color: '#ef4444', icon: 'mdi-clock-alert', label: 'Overdue' },
    completed: { color: '#6366f1', icon: 'mdi-check-circle', label: 'Completed' },
    cancelled: { color: '#94a3b8', icon: 'mdi-cancel', label: 'Cancelled' },
  }
  return Object.entries(map).map(([key, m]) => ({
    label: m.label,
    count: counts[key] || 0,
    color: m.color,
    icon: m.icon,
    bg: `${m.color}08`,
  }))
})
</script>

<style scoped>
.kpi-hover { transition: transform .15s ease, box-shadow .15s ease; }
.kpi-hover:hover { transform: translateY(-2px); box-shadow: 0 10px 24px -8px rgba(15, 23, 42, 0.22); }
.kpi-icon-badge {
  width: 44px; height: 44px; border-radius: 12px;
  display: flex; align-items: center; justify-content: center; flex-shrink: 0;
  box-shadow: 0 2px 6px rgba(15, 23, 42, 0.10);
}
</style>
