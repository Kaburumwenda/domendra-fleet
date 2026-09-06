<template>
  <div class="d-flex flex-column ga-4">
    <!-- Page Header -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-3">
      <div class="d-flex align-center ga-3">
        <div class="d-flex align-center justify-center rounded-xl" style="width: 48px; height: 48px; background: linear-gradient(135deg, #6366f1, #4f46e5)">
          <v-icon color="white">mdi-chart-finance</v-icon>
        </div>
        <div>
          <h1 class="text-h5 font-weight-bold" style="color: #1e293b">Financial Reports</h1>
          <p class="text-body-2 text-medium-emphasis">Comprehensive financial reporting, P&L statements, revenue analysis, cost tracking, and vehicle ROI</p>
        </div>
      </div>
      <div class="d-flex align-center ga-2 flex-wrap">
        <v-btn variant="tonal" color="primary" prepend-icon="mdi-database-plus" @click="seedDemo" :loading="seeding">
          <span class="hidden-sm-and-down">Seed Demo</span>
        </v-btn>
        <v-btn variant="tonal" prepend-icon="mdi-refresh" @click="refreshAll" :loading="refreshing">
          <span class="hidden-sm-and-down">Refresh</span>
        </v-btn>
        <v-btn variant="flat" color="error" prepend-icon="mdi-file-pdf-box" @click="openPdfModal">
          <span class="hidden-sm-and-down">PDF Report</span>
        </v-btn>
      </div>
    </div>

    <!-- ── PDF Export Modal ── -->
    <v-dialog v-model="pdfModal" max-width="560" persistent>
      <v-card rounded="xl">
        <v-card-title class="d-flex align-center ga-2">
          <v-icon color="error">mdi-file-pdf-box</v-icon>
          <span class="text-h6 font-weight-bold">Export PDF Report</span>
        </v-card-title>
        <v-card-subtitle class="text-caption">
          Select the sections to include in the financial report PDF
        </v-card-subtitle>
        <v-divider />
        <v-card-text class="pt-4">
          <v-alert type="info" variant="tonal" density="compact" class="mb-4 text-caption">
            Selected period: <b>{{ periodLabel }}</b>
          </v-alert>
          <div class="d-flex flex-column ga-1">
            <v-checkbox v-for="sec in pdfSectionOptions" :key="sec.key" v-model="pdfSections" :value="sec.key" hide-details density="compact" color="error">
              <template #label>
                <span><v-icon :icon="sec.icon" size="16" /> {{ sec.label }}</span>
              </template>
            </v-checkbox>
          </div>
          <div class="d-flex ga-2 mt-2">
            <v-btn variant="text" size="small" @click="selectAllSections">Select All</v-btn>
            <v-btn variant="text" size="small" @click="clearSections">Clear All</v-btn>
          </div>
        </v-card-text>
        <v-divider />
        <v-card-actions class="pa-4">
          <v-spacer />
          <v-btn variant="text" @click="pdfModal = false">Cancel</v-btn>
          <v-btn variant="flat" color="error" prepend-icon="mdi-download" :loading="pdfLoading" :disabled="pdfSections.length === 0" @click="downloadPdf">
            Generate PDF
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- ── Date Filter Bar ── -->
    <v-card elevation="0" border rounded="lg" class="pa-4">
      <div class="d-flex flex-wrap align-center ga-3">
        <div class="d-flex align-center ga-2">
          <v-icon icon="mdi-filter-calendar" color="primary" size="small" />
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
        <div class="d-flex align-center ga-2">
          <v-text-field
            v-model="customStart"
            type="date"
            label="From"
            density="compact"
            variant="outlined"
            hide-details
            style="max-width: 170px"
            @update:model-value="onCustomDateChange"
          />
          <v-text-field
            v-model="customEnd"
            type="date"
            label="To"
            density="compact"
            variant="outlined"
            hide-details
            style="max-width: 170px"
            @update:model-value="onCustomDateChange"
          />
          <v-btn v-if="activePreset === 'custom'" color="primary" variant="flat" size="small" @click="refreshAll">Apply</v-btn>
        </div>
      </div>
    </v-card>

    <!-- Tabs -->
    <v-tabs v-model="tab" color="primary" density="compact" grow>
      <v-tab value="dashboard" prepend-icon="mdi-view-dashboard">Dashboard</v-tab>
      <v-tab value="revenue" prepend-icon="mdi-cash-multiple">Revenue</v-tab>
      <v-tab value="costs" prepend-icon="mdi-cash-off">Costs</v-tab>
      <v-tab value="roi" prepend-icon="mdi-cash-refund">Vehicle ROI</v-tab>
      <v-tab value="cashflow" prepend-icon="mdi-cash-flow">Cash Flow</v-tab>
      <v-tab value="pnl" prepend-icon="mdi-chart-arc">Profit and Loss</v-tab>
      <v-tab value="locations" prepend-icon="mdi-map-marker-multiple-outline">Locations</v-tab>
      <v-tab value="ownership" prepend-icon="mdi-calculator-variant">Cost of Ownership</v-tab>
      <v-tab value="ledger" prepend-icon="mdi-book-open-variant">General Ledger</v-tab>
      <v-tab value="standard" prepend-icon="mdi-file-chart">Standard Reports</v-tab>
    </v-tabs>

    <v-window v-model="tab">
      <!-- Dashboard Tab -->
      <v-window-item value="dashboard">
        <FinancialAnalytics :summary="overview?.summary || {}" :trends="overview?.trends || {}" />
      </v-window-item>

      <!-- Revenue Tab -->
      <v-window-item value="revenue">
        <RevenueAnalysis :data="revenueData" />
      </v-window-item>

      <!-- Costs Tab -->
      <v-window-item value="costs">
        <CostAnalysis :data="costData" />
      </v-window-item>

      <!-- ROI Tab -->
      <v-window-item value="roi">
        <VehicleROI :vehicles="roiData" />
      </v-window-item>

      <!-- Cash Flow Tab -->
      <v-window-item value="cashflow">
        <CashFlow :data="cashflowData" />
      </v-window-item>

      <!-- P&L Tab -->
      <v-window-item value="pnl">
        <ProfitLoss :data="profitLossData" :loading="profitLossPending" />
      </v-window-item>

      <!-- Locations Tab -->
      <v-window-item value="locations">
        <LocationsReport :data="locData" :loading="locPending" />
      </v-window-item>

      <!-- Cost of Ownership Tab -->
      <v-window-item value="ownership">
        <CostOfOwnershipReport :data="ownershipData" :loading="ownershipLoading" />
      </v-window-item>

      <!-- General Ledger Tab -->
      <v-window-item value="ledger">
        <GeneralLedger :data="ledgerData" :loading="ledgerLoading" />
      </v-window-item>

      <!-- Standard Reports Tab -->
      <v-window-item value="standard">
        <StandardReportsTab />
      </v-window-item>
    </v-window>
  </div>
</template>

<script setup lang="ts">
const { $api, $swal } = useNuxtApp()
const tab = ref('dashboard')
const activePreset = ref('last_30')
const seeding = ref(false)
const refreshing = ref(false)
const pdfLoading = ref(false)
const pdfModal = ref(false)
const pdfSections = ref([
  'business_details', 'executive_summary', 'revenue_charts',
  'cost_analysis', 'profit_loss', 'vehicle_roi',
])
const pdfSectionOptions = [
  { key: 'business_details', label: 'Business Details (Cover Page)', icon: 'mdi-office-building' },
  { key: 'executive_summary', label: 'Executive Summary (KPIs, Trends, Ratios)', icon: 'mdi-chart-line' },
  { key: 'revenue_charts', label: 'Revenue Charts (Customer, Vehicle, Trend)', icon: 'mdi-chart-bar' },
  { key: 'cost_analysis', label: 'Cost Analysis (Pie Chart, By Vehicle)', icon: 'mdi-chart-pie' },
  { key: 'profit_loss', label: 'Profit and Loss Statement', icon: 'mdi-cash-multiple' },
  { key: 'vehicle_roi', label: 'Vehicle ROI Analysis', icon: 'mdi-car-multiple' },
]
function selectAllSections() {
  pdfSections.value = pdfSectionOptions.map(s => s.key)
}
function clearSections() {
  pdfSections.value = []
}
function openPdfModal() {
  pdfModal.value = true
}

// ── Date presets ──
const datePresets = [
  { label: 'This Month', value: 'this_month' },
  { label: 'This Quarter', value: 'this_quarter' },
  { label: 'This Year', value: 'this_year' },
  { label: 'Last 30 Days', value: 'last_30' },
  { label: 'Last 90 Days', value: 'last_90' },
  { label: 'Last 12 Months', value: 'last_12' },
  { label: 'All Time', value: 'all_time' },
]

function localDate(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

const now = new Date()
const customStart = ref(localDate(new Date(now.getFullYear(), now.getMonth() - 11, 1)))
const customEnd = ref(localDate(now))

function setPreset(val: string) {
  activePreset.value = val
  const t = new Date()
  const y = t.getFullYear()
  const m = t.getMonth()
  switch (val) {
    case 'this_month':
      customStart.value = localDate(new Date(y, m, 1))
      customEnd.value = localDate(t)
      break
    case 'this_quarter': {
      const qStart = Math.floor(m / 3) * 3
      customStart.value = localDate(new Date(y, qStart, 1))
      customEnd.value = localDate(t)
      break
    }
    case 'this_year':
      customStart.value = localDate(new Date(y, 0, 1))
      customEnd.value = localDate(t)
      break
    case 'last_30':
      customStart.value = localDate(new Date(Date.now() - 30 * 86400000))
      customEnd.value = localDate(t)
      break
    case 'last_90':
      customStart.value = localDate(new Date(Date.now() - 90 * 86400000))
      customEnd.value = localDate(t)
      break
    case 'last_12':
      customStart.value = localDate(new Date(y, m - 11, 1))
      customEnd.value = localDate(t)
      break
    case 'all_time':
      customStart.value = localDate(new Date(2020, 0, 1))
      customEnd.value = localDate(t)
      break
  }
  // No need to call refreshAll() — the useAsyncData `watch: [queryStr]`
  // recomputes queryStr and fires each refresh automatically.
}

const queryStr = computed(() => {
  const s = `${customStart.value}T00:00:00`
  const e = `${customEnd.value}T23:59:59`
  return `?start=${encodeURIComponent(s)}&end=${encodeURIComponent(e)}`
})

let debounceTimer: ReturnType<typeof setTimeout> | null = null
function onCustomDateChange() {
  activePreset.value = 'custom'
  // The useAsyncData `watch: [queryStr]` handles the refresh automatically
  // when queryStr changes after the debounce settles.
  if (customStart.value && customEnd.value) {
    const s = new Date(customStart.value)
    const e = new Date(customEnd.value)
    if (s > e) return
    if (debounceTimer) clearTimeout(debounceTimer)
  }
}

// Financial Overview
const { data: overview, pending: overviewPending, refresh: refreshOverview } = useAsyncData(
  'fin-overview',
  () => $api(`/reports/financial/overview/${queryStr.value}`).catch(() => ({ summary: {}, trends: {} })),
  { default: () => ({ summary: {}, trends: {} }), watch: [queryStr] }
)

// Revenue Breakdown
const { data: revenueData, refresh: refreshRevenue } = useAsyncData(
  'fin-revenue',
  () => $api(`/reports/financial/revenue/${queryStr.value}`).catch(() => ({})),
  { default: () => ({}), watch: [queryStr] }
)

// Cost Breakdown
const { data: costData, refresh: refreshCosts } = useAsyncData(
  'fin-costs',
  () => $api(`/reports/financial/costs/${queryStr.value}`).catch(() => ({})),
  { default: () => ({}), watch: [queryStr] }
)

// Vehicle ROI
const { data: roiData, refresh: refreshROI } = useAsyncData(
  'fin-roi',
  () => $api(`/reports/financial/vehicle-roi/${queryStr.value}`).catch(() => []),
  { default: () => [], watch: [queryStr] }
)

// Cash Flow
const { data: cashflowData, refresh: refreshCashflow } = useAsyncData(
  'fin-cashflow',
  () => $api(`/reports/financial/cash-flow/${queryStr.value}`).catch(() => ({})),
  { default: () => ({}), watch: [queryStr] }
)

// Profit and Loss
const { data: profitLossData, pending: profitLossPending, refresh: refreshProfitLoss } = useAsyncData(
  'fin-pnl',
  () => $api(`/reports/financial/profit-loss/${queryStr.value}`).catch(() => ({})),
  { default: () => ({}), watch: [queryStr] }
)

// Locations Analysis
const { data: locData, pending: locPending, refresh: refreshLoc } = useAsyncData(
  'fin-locations',
  () => $api(`/reports/financial/locations/${queryStr.value}`).catch(() => ({})),
  { default: () => ({}), watch: [queryStr] }
)

// Cost of Ownership (fleet TCO) — loading controlled manually to prevent
// the spinner from getting stuck when the heavy ownership endpoint is slow.
const ownershipLoading = ref(false)
const { data: ownershipData, refresh: refreshOwnership } = useAsyncData(
  'fin-ownership',
  () => $api(`/reports/financial/ownership/${queryStr.value}`).catch(() => ({})),
  { default: () => ({}), immediate: false }
)
async function loadOwnership() {
  ownershipLoading.value = true
  try {
    await refreshOwnership()
  } finally {
    ownershipLoading.value = false
  }
}
watch(queryStr, () => loadOwnership(), { immediate: true })

// General Ledger — auto-generated double-entry journal entries
const ledgerLoading = ref(false)
const { data: ledgerData, refresh: refreshLedger } = useAsyncData(
  'fin-ledger',
  () => $api(`/reports/general-ledger/${queryStr.value}`).catch(() => ({})),
  { default: () => ({}), immediate: false }
)
async function loadLedger() {
  ledgerLoading.value = true
  try {
    await refreshLedger()
  } finally {
    ledgerLoading.value = false
  }
}
watch(queryStr, () => loadLedger(), { immediate: true })

async function refreshAll() {
  refreshing.value = true
  try {
    await Promise.all([
      refreshOverview(), refreshRevenue(), refreshCosts(), refreshROI(),
      refreshCashflow(), refreshProfitLoss(), refreshLoc(), loadOwnership(), loadLedger(),
    ])
  } finally {
    refreshing.value = false
  }
}

async function seedDemo() {
  const r = await $swal?.fire?.({
    icon: 'question',
    title: 'Seed demo financial data?',
    text: 'This will create 15 rental agreements with payments, fuel transactions, and service records for testing.',
    showCancelButton: true,
    confirmButtonText: 'Seed Data',
  })
  if (!r?.isConfirmed) return
  seeding.value = true
  try {
    const res = await $api('/reports/seed-demo/')
    $swal?.fire?.({ icon: 'success', title: res?.detail || 'Demo data seeded', toast: true, timer: 2000, position: 'top-end' })
    await refreshAll()
  } catch (e: any) {
    $swal?.fire?.({ icon: 'error', title: e?.response?._data?.detail || 'Failed to seed data', toast: true, timer: 3000, position: 'top-end' })
  } finally { seeding.value = false }
}

async function downloadPdf() {
  if (pdfSections.value.length === 0) return
  pdfLoading.value = true
  try {
    const sections = pdfSections.value.join(',')
    const res: any = await $api('/reports/financial/pdf/' + queryStr.value + '&sections=' + sections, { responseType: 'blob' })
    const url = window.URL.createObjectURL(res)
    const a = document.createElement('a')
    a.href = url
    a.download = `financial_report_${activePreset.value}.pdf`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    window.URL.revokeObjectURL(url)
    pdfModal.value = false
  } catch (e: any) {
    $swal?.fire?.({ icon: 'error', title: 'Failed to generate PDF', toast: true, timer: 3000, position: 'top-end' })
  } finally { pdfLoading.value = false }
}

const periodLabel = computed(() => {
  const m = datePresets.find(p => p.value === activePreset.value)
  return m ? m.label : 'Current Period'
})

useHead({ title: 'Financial Reports' })
</script>
