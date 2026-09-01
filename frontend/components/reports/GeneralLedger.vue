<template>
  <div class="d-flex flex-column ga-4">
    <!-- ── Loading ── -->
    <div v-if="loading" class="d-flex justify-center align-center py-12">
      <v-progress-circular indeterminate size="48" color="primary" />
    </div>

    <!-- ── Empty ── -->
    <div v-else-if="!data || !data.entries?.length" class="text-center text-medium-emphasis py-12">
      <v-icon size="48" class="mb-2">mdi-book-open-variant</v-icon>
      <p>No ledger entries found for the selected period.</p>
    </div>

    <template v-else>
      <!-- ── Period and actions ── -->
      <div class="d-flex align-center ga-2 flex-wrap">
        <v-chip size="small" variant="tonal" color="primary" prepend-icon="mdi-calendar">
          {{ data.period?.start }} — {{ data.period?.end }}
        </v-chip>
        <v-chip size="small" variant="tonal" color="success" prepend-icon="mdi-check-circle">
          {{ data.summary?.entry_count }} entries
        </v-chip>
        <v-chip size="small" variant="tonal" :color="data.summary?.balanced ? 'success' : 'error'" prepend-icon="mdi-scale-balance">
          {{ data.summary?.balanced ? 'Balanced' : 'Out of Balance' }}
        </v-chip>
        <v-spacer />
        <v-btn variant="text" size="small" prepend-icon="mdi-download" color="primary" @click="exportCsv">
          Export CSV
        </v-btn>
      </div>

      <!-- ── KPI Row ── -->
      <v-row dense>
        <v-col cols="6" sm="3">
          <div class="gl-kpi">
            <div class="d-flex align-center ga-1 mb-1">
              <v-icon size="x-small" color="primary">mdi-book-open-variant</v-icon>
              <span class="kpi-sub">Journal Entries</span>
            </div>
            <div class="kpi-value">{{ data.summary?.entry_count || 0 }}</div>
          </div>
        </v-col>
        <v-col cols="6" sm="3">
          <div class="gl-kpi">
            <div class="d-flex align-center ga-1 mb-1">
              <v-icon size="x-small" color="success">mdi-trending-up</v-icon>
              <span class="kpi-sub">Total Debits</span>
            </div>
            <div class="kpi-value" style="color: #166534">{{ currencySymbol }}{{ fmt(data.summary?.total_debits) }}</div>
          </div>
        </v-col>
        <v-col cols="6" sm="3">
          <div class="gl-kpi">
            <div class="d-flex align-center ga-1 mb-1">
              <v-icon size="x-small" color="error">mdi-trending-down</v-icon>
              <span class="kpi-sub">Total Credits</span>
            </div>
            <div class="kpi-value" style="color: #991b1b">{{ currencySymbol }}{{ fmt(data.summary?.total_credits) }}</div>
          </div>
        </v-col>
        <v-col cols="6" sm="3">
          <div class="gl-kpi">
            <div class="d-flex align-center ga-1 mb-1">
              <v-icon size="x-small" color="warning">mdi-account-cash</v-icon>
              <span class="kpi-sub">A/R Outstanding</span>
            </div>
            <div class="kpi-value" style="color: #d97706">{{ currencySymbol }}{{ fmt(data.summary?.ar_outstanding) }}</div>
          </div>
        </v-col>
      </v-row>

      <!-- ── Monthly Trend + Source Breakdown side-by-side ── -->
      <v-row dense>
        <v-col cols="12" md="7">
          <v-card elevation="0" border rounded="lg" class="pa-4 h-100">
            <div class="mb-2 text-caption font-weight-medium text-medium-emphasis">Monthly Debits vs Credits</div>
            <div ref="chartEl" style="height: 240px" />
          </v-card>
        </v-col>
        <v-col cols="12" md="5">
          <v-card elevation="0" border rounded="lg" class="pa-4 h-100">
            <div class="mb-2 text-caption font-weight-medium text-medium-emphasis">Entry Sources Breakdown</div>
            <div ref="sourceChartEl" style="height: 240px" />
          </v-card>
        </v-col>
      </v-row>

      <!-- ── A/R and A/P Aging ── -->
      <v-row dense>
        <v-col cols="12" md="6">
          <v-card elevation="0" border rounded="lg" class="pa-4 h-100">
            <div class="d-flex align-center justify-space-between mb-3">
              <div>
                <div class="text-caption font-weight-medium text-medium-emphasis">Accounts Receivable Aging</div>
                <div class="text-subtitle-2 font-weight-bold" style="color: #d97706">
                  Total: {{ currencySymbol }}{{ fmt(data.ar_aging?.total_outstanding) }}
                </div>
              </div>
              <v-btn size="x-small" variant="text" color="primary" prepend-icon="mdi-magnify" @click="arDialog = true">Detail</v-btn>
            </div>
            <div class="bars-container">
              <div v-for="b in agingBuckets" :key="'ar-' + b.key" v-show="props.data?.ar_aging?.buckets?.[b.key] > 0">
                <div class="bar-row">
                  <span class="text-caption font-weight-medium text-medium-emphasis" style="width: 80px">{{ b.label }}</span>
                  <div class="bar-track">
                    <div class="bar-fill" :style="{ width: arBarWidth(b.key), background: b.color }" />
                  </div>
                  <span class="text-caption font-weight-bold text-right" style="color: #d97706; min-width: 90px">
                    {{ currencySymbol }}{{ fmt(props.data?.ar_aging?.buckets?.[b.key]) }}
                  </span>
                </div>
              </div>
              <div v-if="!props.data?.ar_aging?.total_outstanding" class="text-center text-medium-emphasis py-2">
                <span class="text-caption">No outstanding receivables.</span>
              </div>
            </div>
          </v-card>
        </v-col>
        <v-col cols="12" md="6">
          <v-card elevation="0" border rounded="lg" class="pa-4 h-100">
            <div class="d-flex align-center justify-space-between mb-3">
              <div>
                <div class="text-caption font-weight-medium text-medium-emphasis">Accounts Payable Aging</div>
                <div class="text-subtitle-2 font-weight-bold" style="color: #991b1b">
                  Total: {{ currencySymbol }}{{ fmt(data.ap_aging?.total_outstanding) }}
                </div>
              </div>
              <v-btn size="x-small" variant="text" color="primary" prepend-icon="mdi-magnify" @click="apDialog = true">Detail</v-btn>
            </div>
            <div class="bars-container">
              <div v-for="b in agingBuckets" :key="'ap-' + b.key" v-show="props.data?.ap_aging?.buckets?.[b.key] > 0">
                <div class="bar-row">
                  <span class="text-caption font-weight-medium text-medium-emphasis" style="width: 80px">{{ b.label }}</span>
                  <div class="bar-track">
                    <div class="bar-fill" :style="{ width: apBarWidth(b.key), background: b.color }" />
                  </div>
                  <span class="text-caption font-weight-bold text-right" style="color: #991b1b; min-width: 90px">
                    {{ currencySymbol }}{{ fmt(props.data?.ap_aging?.buckets?.[b.key]) }}
                  </span>
                </div>
              </div>
              <div v-if="!props.data?.ap_aging?.total_outstanding" class="text-center text-medium-emphasis py-2">
                <span class="text-caption">No outstanding payables.</span>
              </div>
            </div>
          </v-card>
        </v-col>
      </v-row>

      <!-- ── Comparative Trial Balance ── -->
      <v-card elevation="0" border rounded="lg" class="pa-4">
        <div class="d-flex align-center ga-2 mb-3">
          <div class="d-flex align-center ga-2">
            <v-icon icon="mdi-compare-horizontal" color="primary" size="small" />
            <h3 class="text-subtitle-2 font-weight-bold section-heading">Comparative Trial Balance</h3>
          </div>
          <span class="text-caption text-medium-emphasis hidden-sm-and-down hidden-xs">Current vs Previous Period</span>
          <v-spacer />
        </div>
        <v-data-table
          :headers="compHeaders"
          :items="props.data?.comparative_trial_balance || []"
          density="compact"
          :items-per-page="-1"
          hide-default-footer
          class="rounded-lg"
        >
          <template #item.account="{ item }">
            <div class="d-flex align-center ga-1">
              <span class="text-caption font-weight-bold text-medium-emphasis" style="width: 36px">{{ item.code }}</span>
              <span class="text-body-2 font-weight-medium">{{ item.name }}</span>
            </div>
          </template>
          <template #item.current_debit="{ value }">
            <span class="font-weight-bold" style="color: #166534">{{ currencySymbol }}{{ fmt(value) }}</span>
          </template>
          <template #item.current_credit="{ value }">
            <span class="font-weight-bold" style="color: #991b1b">{{ currencySymbol }}{{ fmt(value) }}</span>
          </template>
          <template #item.previous_balance="{ value }">
            <span class="text-medium-emphasis">{{ currencySymbol }}{{ fmt(Math.abs(value)) }} {{ value >= 0 ? 'Dr' : 'Cr' }}</span>
          </template>
          <template #item.change="{ item }">
            <span class="font-weight-bold" :style="{ color: item.change >= 0 ? '#166534' : '#991b1b' }">
              {{ item.change >= 0 ? '+' : '-' }}{{ currencySymbol }}{{ fmt(Math.abs(item.change)) }}
            </span>
            <span class="text-caption text-medium-emphasis ml-1">({{ item.change_pct }}%)</span>
          </template>
          <template #body.append>
            <tr class="font-weight-bold total-row">
              <td>Totals</td>
              <td class="text-right">{{ currencySymbol }}{{ fmt(compTotals.currentDr) }}</td>
              <td class="text-right">{{ currencySymbol }}{{ fmt(compTotals.currentCr) }}</td>
              <td />
              <td />
            </tr>
          </template>
        </v-data-table>
      </v-card>

      <!-- ── Trial Balance (with T-account / Filter toggle) ── -->
      <v-card elevation="0" border rounded="lg" class="pa-4">
        <div class="d-flex align-center ga-2 mb-3">
          <div class="d-flex align-center ga-2">
            <v-icon icon="mdi-scale-balance" color="primary" size="small" />
            <h3 class="text-subtitle-2 font-weight-bold section-heading">Trial Balance</h3>
          </div>
          <span class="text-caption text-medium-emphasis hidden-sm-and-down">Click an account to open its T-account or filter the journal</span>
          <v-spacer />
          <v-btn-toggle v-model="tbAction" density="compact" color="primary" mandatory size="small">
            <v-btn value="taccount" size="x-small">T-Account</v-btn>
            <v-btn value="filter" size="x-small">Filter</v-btn>
          </v-btn-toggle>
        </div>
        <div class="trial-balance-list">
          <div
            v-for="row in data.trial_balance"
            :key="row.code"
            class="d-flex align-center justify-space-between rounded-lg px-3 py-2 mb-1 trial-row"
            :class="{ 'trial-row-active': selectedAccount === row.code }"
            @click="onAccountClick(row.code)"
          >
            <div class="d-flex align-center ga-2" style="min-width: 0">
              <v-icon size="x-small" color="primary">mdi-chevron-right</v-icon>
              <span class="text-caption font-weight-bold text-medium-emphasis" style="width: 36px">{{ row.code }}</span>
              <span class="text-body-2 font-weight-medium text-truncate">{{ row.name }}</span>
            </div>
            <div class="d-flex align-center ga-3 flex-shrink-0">
              <span class="text-subtitle-2 font-weight-bold" style="color: #166534; min-width: 70px; text-align: right">{{ currencySymbol }}{{ fmt(row.debit) }}</span>
              <span class="text-subtitle-2 font-weight-bold" style="color: #991b1b; min-width: 70px; text-align: right">{{ currencySymbol }}{{ fmt(row.credit) }}</span>
              <v-chip size="x-small" :color="row.balance >= 0 ? 'success' : 'error'" variant="tonal" class="font-weight-bold" style="min-width: 65px; justify-content: center">
                {{ currencySymbol }}{{ fmt(Math.abs(row.balance)) }}
              </v-chip>
            </div>
          </div>
        </div>
      </v-card>

      <!-- ── Journal Entries Table ── -->
      <v-card elevation="0" border rounded="lg" class="pa-4">
        <div class="d-flex align-center ga-2 flex-wrap mb-4">
          <div class="d-flex align-center ga-2">
            <v-icon icon="mdi-book-open-variant" color="primary" size="small" />
            <h3 class="text-subtitle-1 font-weight-bold section-heading">Journal Entries</h3>
          </div>
          <v-chip v-if="selectedAccount" close size="x-small" color="primary" variant="tonal" @click:close="clearAccountFilter">
            {{ selectedAccountName }}
          </v-chip>
          <v-spacer />
          <v-text-field
            v-model="search"
            prepend-inner-icon="mdi-magnify"
            placeholder="Search reference or description..."
            density="compact"
            variant="outlined"
            hide-details
            style="max-width: 260px"
            clearable
            class="mr-2"
          />
          <v-select
            v-model="sourceFilter"
            :items="sourceOptions"
            label="Source"
            density="compact"
            variant="outlined"
            hide-details
            style="max-width: 150px"
            clearable
            class="mr-2"
          />
          <v-select
            v-model="typeFilter"
            :items="typeOptions"
            label="Type"
            density="compact"
            variant="outlined"
            hide-details
            style="max-width: 130px"
            clearable
          />
        </div>

        <v-data-table
          :headers="entryHeaders"
          :items="filteredEntries"
          density="compact"
          :items-per-page="20"
          class="rounded-lg"
          :sort-by="[{ key: 'date', order: 'asc' }]"
        >
          <template #item.date="{ value }">
            <span class="text-caption text-medium-emphasis">{{ formatDate(value) }}</span>
          </template>
          <template #item.account="{ item }">
            <div class="d-flex align-center ga-1">
              <span class="text-caption font-weight-bold text-medium-emphasis" style="width: 36px">{{ item.account_code }}</span>
              <span class="text-body-2 font-weight-medium">{{ item.account_name }}</span>
            </div>
          </template>
          <template #item.debit="{ value }">
            <span v-if="value" class="font-weight-bold" style="color: #166534">{{ currencySymbol }}{{ fmt(value) }}</span>
            <span v-else class="text-medium-emphasis">—</span>
          </template>
          <template #item.credit="{ value }">
            <span v-if="value" class="font-weight-bold" style="color: #991b1b">{{ currencySymbol }}{{ fmt(value) }}</span>
            <span v-else class="text-medium-emphasis">—</span>
          </template>
          <template #item.reference="{ value }">
            <v-chip size="x-small" variant="tonal" color="primary" class="font-weight-medium">{{ value }}</v-chip>
          </template>
          <template #item.source="{ value }">
            <v-chip size="x-small" label variant="tonal" color="secondary" class="text-uppercase font-weight-medium" style="font-size: 0.65rem">{{ value }}</v-chip>
          </template>
        </v-data-table>
      </v-card>
    </template>

    <!-- ── T-Account dialog ── -->
    <v-dialog v-model="taccountDialog" max-width="700">
      <v-card rounded="xl" class="pa-2">
        <AppModalHeader icon="mdi-book-open-variant" :title="taccountTitle" />
        <v-card-text v-if="taccountRows.length" class="pa-5">
          <!-- Summary at top -->
          <v-row dense class="mb-4">
            <v-col cols="4">
              <div class="ta-summary-card">
                <div class="ta-summary-label">Total Debits</div>
                <div class="ta-summary-value" style="color: #166534">{{ currencySymbol }}{{ fmt(taccountTotals.debit) }}</div>
              </div>
            </v-col>
            <v-col cols="4">
              <div class="ta-summary-card">
                <div class="ta-summary-label">Total Credits</div>
                <div class="ta-summary-value" style="color: #991b1b">{{ currencySymbol }}{{ fmt(taccountTotals.credit) }}</div>
              </div>
            </v-col>
            <v-col cols="4">
              <div class="ta-summary-card">
                <div class="ta-summary-label">Balance</div>
                <div class="ta-summary-value" :style="{ color: taccountTotals.balance >= 0 ? '#166534' : '#991b1b' }">
                  {{ currencySymbol }}{{ fmt(Math.abs(taccountTotals.balance)) }} {{ taccountTotals.balance >= 0 ? 'Dr' : 'Cr' }}
                </div>
              </div>
            </v-col>
          </v-row>

          <v-data-table
            :headers="tHeaders"
            :items="taccountRows"
            density="compact"
            :items-per-page="-1"
            hide-default-footer
            class="rounded-lg"
          >
            <template #item.date="{ value }">
              <span class="text-caption text-medium-emphasis">{{ formatDate(value) }}</span>
            </template>
            <template #item.debit="{ value }">
              <span v-if="value" class="font-weight-medium" style="color: #166534">{{ currencySymbol }}{{ fmt(value) }}</span>
              <span v-else class="text-medium-emphasis">—</span>
            </template>
            <template #item.credit="{ value }">
              <span v-if="value" class="font-weight-medium" style="color: #991b1b">{{ currencySymbol }}{{ fmt(value) }}</span>
              <span v-else class="text-medium-emphasis">—</span>
            </template>
            <template #item.running_balance="{ value }">
              <span class="font-weight-bold" :style="{ color: value >= 0 ? '#166534' : '#991b1b' }">
                {{ currencySymbol }}{{ fmt(Math.abs(value)) }} {{ value >= 0 ? 'Dr' : 'Cr' }}
              </span>
            </template>
          </v-data-table>
        </v-card-text>
        <v-card-actions class="px-5 pb-5">
          <v-spacer />
          <v-btn variant="text" @click="taccountDialog = false">Close</v-btn>
          <v-btn color="primary" variant="flat" prepend-icon="mdi-filter" @click="closeTaccountToFilter">Filter Journal By This Account</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- ── A/R Aging detail dialog ── -->
    <v-dialog v-model="arDialog" max-width="800">
      <v-card rounded="xl" class="pa-2">
        <AppModalHeader icon="mdi-account-cash" title="Accounts Receivable Aging Detail" />
        <v-card-text class="pa-5">
          <v-data-table
            :headers="agingDetailHeaders"
            :items="props.data?.ar_aging?.detail || []"
            density="compact"
            :items-per-page="15"
          >
            <template #item.date="{ value }"><span class="text-caption">{{ formatDate(value) }}</span></template>
            <template #item.reference="{ value }"><v-chip size="x-small" variant="tonal" color="primary">{{ value }}</v-chip></template>
            <template #item.remaining="{ value }">
              <span class="font-weight-bold" style="color: #d97706">{{ currencySymbol }}{{ fmt(value) }}</span>
            </template>
            <template #item.bucket="{ value }">
              <v-chip size="x-small" :color="bucketColor(value)" variant="tonal" class="text-uppercase font-weight-bold" style="font-size: 0.65rem">{{ bucketLabel(value) }}</v-chip>
            </template>
          </v-data-table>
        </v-card-text>
        <v-card-actions class="px-5 pb-5"><v-spacer /><v-btn variant="text" @click="arDialog = false">Close</v-btn></v-card-actions>
      </v-card>
    </v-dialog>

    <!-- ── A/P Aging detail dialog ── -->
    <v-dialog v-model="apDialog" max-width="800">
      <v-card rounded="xl" class="pa-2">
        <AppModalHeader icon="mdi-cash-off" title="Accounts Payable Aging Detail" />
        <v-card-text class="pa-5">
          <v-data-table
            :headers="agingDetailHeaders"
            :items="props.data?.ap_aging?.detail || []"
            density="compact"
            :items-per-page="15"
          >
            <template #item.date="{ value }"><span class="text-caption">{{ formatDate(value) }}</span></template>
            <template #item.reference="{ value }"><v-chip size="x-small" variant="tonal" color="primary">{{ value }}</v-chip></template>
            <template #item.remaining="{ value }">
              <span class="font-weight-bold" style="color: #991b1b">{{ currencySymbol }}{{ fmt(value) }}</span>
            </template>
            <template #item.bucket="{ value }">
              <v-chip size="x-small" :color="bucketColor(value)" variant="tonal" class="text-uppercase font-weight-bold" style="font-size: 0.65rem">{{ bucketLabel(value) }}</v-chip>
            </template>
          </v-data-table>
        </v-card-text>
        <v-card-actions class="px-5 pb-5"><v-spacer /><v-btn variant="text" @click="apDialog = false">Close</v-btn></v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, onMounted, onBeforeUnmount, watch, nextTick } from 'vue'
import * as echarts from 'echarts/core'
import { setupECharts } from '~/utils/echarts'

setupECharts()

const props = defineProps<{ data: any; loading?: boolean }>()
const { currencySymbol } = useCurrency()

// ── Charts: monthly trend + source breakdown ──
const chartEl = ref<HTMLElement | null>(null)
const sourceChartEl = ref<HTMLElement | null>(null)
let chart: echarts.ECharts | null = null
let sourceChart: echarts.ECharts | null = null
let ro: ResizeObserver | null = null

function ensureInit() {
  if (chartEl.value && chartEl.value.clientWidth > 0 && !chart) {
    chart = echarts.init(chartEl.value)
  }
  if (sourceChartEl.value && sourceChartEl.value.clientWidth > 0 && !sourceChart) {
    sourceChart = echarts.init(sourceChartEl.value)
  }
  renderChart()
  renderSourceChart()
}

function renderChart() {
  if (!chart) return
  const monthly = props.data?.monthly || []
  if (!monthly.length) return
  chart.setOption({
    tooltip: {
      trigger: 'axis',
      axisPointer: { type: 'shadow' },
      valueFormatter: (v: number) => `${currencySymbol.value}${fmt(v)}`,
    },
    legend: { data: ['Debits', 'Credits'], top: 0, right: 10 },
    grid: { left: 50, right: 20, top: 35, bottom: 35 },
    xAxis: { type: 'category', data: monthly.map((m: any) => m.month), axisLabel: { rotate: 35, fontSize: 11 } },
    yAxis: { type: 'value', axisLabel: { formatter: (v: number) => `${currencySymbol.value}${(v / 1000).toFixed(0)}k` } },
    series: [
      {
        name: 'Debits',
        type: 'bar',
        data: monthly.map((m: any) => m.debit),
        itemStyle: { color: '#166534', borderRadius: [4, 4, 0, 0] },
      },
      {
        name: 'Credits',
        type: 'bar',
        data: monthly.map((m: any) => m.credit),
        itemStyle: { color: '#991b1b', borderRadius: [4, 4, 0, 0] },
      },
    ],
  })
}

function renderSourceChart() {
  if (!sourceChart) return
  const sb = props.data?.source_breakdown || []
  if (!sb.length) return
  const isDark = !!document.querySelector('.v-application.v-theme--dark')
  const legendColor = isDark ? '#e2e8f0' : '#475569'
  const labelColor = isDark ? '#e2e8f0' : '#1e293b'
  sourceChart.setOption({
    tooltip: {
      trigger: 'item',
      valueFormatter: (v: number) => `${currencySymbol.value}${fmt(v)}`,
    },
    legend: { type: 'scroll', bottom: 0, left: 'center', textStyle: { fontSize: 11, color: legendColor } },
    series: [
      {
        type: 'pie',
        radius: ['38%', '68%'],
        center: ['50%', '42%'],
        avoidLabelOverlap: true,
        itemStyle: { borderRadius: 6, borderColor: isDark ? 'rgba(30,41,59,0.4)' : 'rgba(255,255,255,0.3)', borderWidth: 2 },
        label: { show: false },
        emphasis: {
          label: { show: true, fontSize: 13, fontWeight: 'bold', color: labelColor },
        },
        data: sb.map((s: any) => ({
          name: s.source.charAt(0).toUpperCase() + s.source.slice(1),
          value: s.total,
        })),
      },
    ],
  })
}

onMounted(() => {
  nextTick(() => {
    ensureInit()
    ro = new ResizeObserver(() => {
      if (chart) chart.resize()
      else ensureInit()
      if (sourceChart) sourceChart.resize()
    })
    if (chartEl.value) ro.observe(chartEl.value)
    if (sourceChartEl.value) ro.observe(sourceChartEl.value)
  })
})

watch(() => props.data, () => { renderChart(); renderSourceChart() }, { deep: true })

watch(() => props.loading, (isLoading) => {
  if (isLoading) {
    if (chart) { chart.dispose(); chart = null }
    if (sourceChart) { sourceChart.dispose(); sourceChart = null }
    return
  }
  nextTick(() => ensureInit())
})

onBeforeUnmount(() => {
  ro?.disconnect()
  chart?.dispose()
  sourceChart?.dispose()
  chart = null
  sourceChart = null
})

// ── A/R & A/P Aging ──
const agingBuckets = [
  { key: 'current', label: 'Current', color: '#16a34a' },
  { key: '1_30', label: '1-30 days', color: '#65a30d' },
  { key: '31_60', label: '31-60 days', color: '#ca8a04' },
  { key: '61_90', label: '61-90 days', color: '#ea580c' },
  { key: '90_plus', label: '90+ days', color: '#dc2626' },
]

function bucketLabel(key: string) {
  return agingBuckets.find((b) => b.key === key)?.label || key
}
function bucketColor(key: string) {
  return agingBuckets.find((b) => b.key === key)?.color || '#94a3b8'
}

function arBarWidth(key: string) {
  const total = props.data?.ar_aging?.total_outstanding || 0
  const val = props.data?.ar_aging?.buckets?.[key] || 0
  return total > 0 ? `${Math.min(100, (val / total) * 100)}%` : '0%'
}
function apBarWidth(key: string) {
  const total = props.data?.ap_aging?.total_outstanding || 0
  const val = props.data?.ap_aging?.buckets?.[key] || 0
  return total > 0 ? `${Math.min(100, (val / total) * 100)}%` : '0%'
}

const arDialog = ref(false)
const apDialog = ref(false)

const agingDetailHeaders = [
  { title: 'Date', key: 'date', width: '100px' },
  { title: 'Reference', key: 'reference', width: '110px' },
  { title: 'Description', key: 'description' },
  { title: 'Original', key: 'amount', align: 'end' as const, width: '100px' },
  { title: 'Remaining', key: 'remaining', align: 'end' as const, width: '100px' },
  { title: 'Days', key: 'days_outstanding', align: 'end' as const, width: '70px' },
  { title: 'Bucket', key: 'bucket', width: '100px' },
]

// ── Trial Balance account selection (T-account or filter) ──
const selectedAccount = ref<string | null>(null)
const tbAction = ref<'taccount' | 'filter'>('taccount')

const selectedAccountName = computed(() => {
  if (!selectedAccount.value) return ''
  const row = (props.data?.trial_balance || []).find((r: any) => r.code === selectedAccount.value)
  return row ? `${row.code} - ${row.name}` : selectedAccount.value
})

function onAccountClick(code: string) {
  if (tbAction.value === 'taccount') {
    openTaccount(code)
  } else {
    selectedAccount.value = selectedAccount.value === code ? null : code
  }
}

function clearAccountFilter() {
  selectedAccount.value = null
}

// ── T-Account dialog ──
const taccountDialog = ref(false)
const taccountCode = ref('')

const taccountTitle = computed(() => {
  const row = (props.data?.trial_balance || []).find((r: any) => r.code === taccountCode.value)
  return row ? `T-Account: ${row.code} - ${row.name}` : 'T-Account'
})

const taccountRows = computed(() => {
  const entries = (props.data?.entries || []).filter((e: any) => e.account_code === taccountCode.value)
  const sorted = [...entries].sort((a: any, b: any) => new Date(a.date).getTime() - new Date(b.date).getTime())
  let running = 0
  return sorted.map((e: any) => {
    running += (e.debit || 0) - (e.credit || 0)
    return { ...e, running_balance: running }
  })
})

const taccountTotals = computed(() => {
  const rows = taccountRows.value
  const debit = rows.reduce((s: number, r: any) => s + (r.debit || 0), 0)
  const credit = rows.reduce((s: number, r: any) => s + (r.credit || 0), 0)
  return { debit, credit, balance: debit - credit }
})

function openTaccount(code: string) {
  taccountCode.value = code
  taccountDialog.value = true
}

function closeTaccountToFilter() {
  selectedAccount.value = taccountCode.value
  tbAction.value = 'filter'
  taccountDialog.value = false
}

const tHeaders = [
  { title: 'Date', key: 'date', width: '100px' },
  { title: 'Description', key: 'description' },
  { title: 'Reference', key: 'reference', width: '100px' },
  { title: 'Debit', key: 'debit', align: 'end' as const, width: '100px' },
  { title: 'Credit', key: 'credit', align: 'end' as const, width: '100px' },
  { title: 'Balance', key: 'running_balance', align: 'end' as const, width: '110px' },
]

// ── Comparative Trial Balance ──
const compHeaders = [
  { title: 'Account', key: 'account' },
  { title: 'Current Dr', key: 'current_debit', align: 'end' as const, width: '120px' },
  { title: 'Current Cr', key: 'current_credit', align: 'end' as const, width: '120px' },
  { title: 'Previous Bal.', key: 'previous_balance', align: 'end' as const, width: '110px' },
  { title: 'Change', key: 'change', align: 'end' as const, width: '120px' },
]

const compTotals = computed(() => {
  const items = props.data?.comparative_trial_balance || []
  return {
    currentDr: items.reduce((s: number, r: any) => s + (r.current_debit || 0), 0),
    currentCr: items.reduce((s: number, r: any) => s + (r.current_credit || 0), 0),
  }
})

// ── Filters & search ──
const search = ref('')
const sourceFilter = ref<string | null>(null)
const typeFilter = ref<string | null>(null)

const sourceOptions = [
  { title: 'Rental', value: 'rental' },
  { title: 'Payment', value: 'payment' },
  { title: 'Charge', value: 'charge' },
  { title: 'Fuel', value: 'fuel' },
  { title: 'Charging', value: 'charging' },
  { title: 'Idling', value: 'idling' },
  { title: 'Service', value: 'service' },
  { title: 'Accident', value: 'accident' },
  { title: 'Damage', value: 'damage' },
  { title: 'Insurance', value: 'insurance' },
  { title: 'Depreciation', value: 'depreciation' },
  { title: 'Lease', value: 'lease' },
  { title: 'Financing', value: 'financing' },
  { title: 'Purchase', value: 'purchase' },
]

const typeOptions = [
  { title: 'Asset', value: 'asset' },
  { title: 'Liability', value: 'liability' },
  { title: 'Equity', value: 'equity' },
  { title: 'Revenue', value: 'revenue' },
  { title: 'Expense', value: 'expense' },
]

const entryHeaders = [
  { title: 'Date', key: 'date', width: '110px', sortable: true },
  { title: 'Account', key: 'account', width: '22%' },
  { title: 'Reference', key: 'reference', width: '100px', sortable: false },
  { title: 'Description', key: 'description', sortable: false },
  { title: 'Source', key: 'source', width: '90px', sortable: false },
  { title: 'Debit', key: 'debit', align: 'end' as const, width: '110px' },
  { title: 'Credit', key: 'credit', align: 'end' as const, width: '110px' },
]

const filteredEntries = computed(() => {
  let items = props.data?.entries || []
  if (selectedAccount.value) {
    items = items.filter((e: any) => e.account_code === selectedAccount.value)
  }
  if (typeFilter.value) {
    items = items.filter((e: any) => e.account_type === typeFilter.value)
  }
  if (sourceFilter.value) {
    items = items.filter((e: any) => e.source === sourceFilter.value)
  }
  if (search.value) {
    const q = search.value.toLowerCase()
    items = items.filter((e: any) =>
      (e.reference || '').toLowerCase().includes(q) ||
      (e.description || '').toLowerCase().includes(q) ||
      (e.account_name || '').toLowerCase().includes(q)
    )
  }
  return items
})

// ── Helpers ──
function fmt(n: number | undefined | null) {
  if (!n || isNaN(n)) return '0'
  return Math.round(n).toLocaleString()
}

function formatDate(d: string) {
  if (!d) return ''
  const date = new Date(d)
  return date.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
}

function exportCsv() {
  const sections: string[] = []

  // 1. Journal Entries
  if (props.data?.entries?.length) {
    sections.push('JOURNAL ENTRIES')
    sections.push('ID,Date,Account Code,Account Name,Account Type,Reference,Description,Source,Debit,Credit')
    for (const e of props.data.entries) {
      sections.push([
        e.id, `"${e.date}"`, e.account_code, `"${e.account_name}"`, e.account_type,
        `"${e.reference || ''}"`, `"${(e.description || '').replace(/"/g, '""')}"`,
        e.source || '', e.debit || 0, e.credit || 0,
      ].join(','))
    }
  }

  // 2. Trial Balance
  if (props.data?.trial_balance?.length) {
    sections.push('')
    sections.push('TRIAL BALANCE')
    sections.push('Code,Name,Type,Debit,Credit,Balance')
    for (const r of props.data.trial_balance) {
      sections.push([r.code, `"${r.name}"`, r.type, r.debit || 0, r.credit || 0, r.balance || 0].join(','))
    }
  }

  // 3. Comparative Trial Balance
  if (props.data?.comparative_trial_balance?.length) {
    sections.push('')
    sections.push('COMPARATIVE TRIAL BALANCE')
    sections.push('Code,Name,Current Debit,Current Credit,Previous Balance,Change,Change %')
    for (const r of props.data.comparative_trial_balance) {
      sections.push([
        r.code, `"${r.name}"`, r.current_debit || 0, r.current_credit || 0,
        r.previous_balance || 0, r.change || 0, r.change_pct || 0,
      ].join(','))
    }
  }

  // 4. A/R Aging
  if (props.data?.ar_aging?.detail?.length) {
    sections.push('')
    sections.push('ACCOUNTS RECEIVABLE AGING DETAIL')
    sections.push('Date,Reference,Description,Amount,Remaining,Days Outstanding,Bucket')
    for (const r of props.data.ar_aging.detail) {
      sections.push([
        `"${r.date}"`, `"${r.reference || ''}"`, `"${(r.description || '').replace(/"/g, '""')}"`,
        r.amount || 0, r.remaining || 0, r.days_outstanding || 0, r.bucket || '',
      ].join(','))
    }
  }

  // 5. A/P Aging
  if (props.data?.ap_aging?.detail?.length) {
    sections.push('')
    sections.push('ACCOUNTS PAYABLE AGING DETAIL')
    sections.push('Date,Reference,Description,Amount,Remaining,Days Outstanding,Bucket')
    for (const r of props.data.ap_aging.detail) {
      sections.push([
        `"${r.date}"`, `"${r.reference || ''}"`, `"${(r.description || '').replace(/"/g, '""')}"`,
        r.amount || 0, r.remaining || 0, r.days_outstanding || 0, r.bucket || '',
      ].join(','))
    }
  }

  // 6. Source Breakdown
  if (props.data?.source_breakdown?.length) {
    sections.push('')
    sections.push('ENTRY SOURCES BREAKDOWN')
    sections.push('Source,Total Debit,Total Credit,Entry Count')
    for (const s of props.data.source_breakdown) {
      sections.push([s.source, s.debit || 0, s.credit || 0, s.count || 0].join(','))
    }
  }

  const blob = new Blob([sections.join('\n')], { type: 'text/csv' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `general-ledger-${new Date().toISOString().slice(0, 10)}.csv`
  a.click()
  URL.revokeObjectURL(url)
}
</script>

<style scoped>
.section-heading { color: #1e293b; }
.v-theme--dark .section-heading { color: #e2e8f0; }
.gl-kpi { padding: 12px; border-radius: 12px; background: rgba(99, 102, 241, 0.06); border: 1px solid rgba(99, 102, 241, 0.12); }
.v-theme--dark .gl-kpi { background: rgba(30, 41, 59, 0.4); border-color: rgba(99, 102, 241, 0.18); }
.kpi-value { font-size: 1.05rem; font-weight: 700; color: #1e293b; line-height: 1.2; }
.v-theme--dark .kpi-value { color: #e2e8f0; }
.kpi-sub { font-size: 0.7rem; color: #64748b; text-transform: uppercase; letter-spacing: 0.04em; }
.v-theme--dark .kpi-sub { color: #94a3b8; }
.trial-balance-list { max-height: 320px; overflow-y: auto; }
.trial-row { cursor: pointer; transition: background 0.15s; background: var(--v-theme-surface-variant); }
.trial-row:hover { filter: brightness(0.96); }
.trial-row-active { outline: 2px solid rgb(var(--v-theme-primary)); outline-offset: -2px; }
.bars-container { display: flex; flex-direction: column; gap: 8px; }
.bar-row { display: flex; align-items: center; gap: 10px; }
.bar-track { flex: 1; height: 18px; background: rgba(0, 0, 0, 0.06); border-radius: 9px; overflow: hidden; }
.v-theme--dark .bar-track { background: rgba(255, 255, 255, 0.08); }
.bar-fill { height: 100%; border-radius: 9px; transition: width 0.4s ease; min-width: 2px; }
.total-row { background: rgba(99, 102, 241, 0.06); }
.v-theme--dark .total-row { background: rgba(99, 102, 241, 0.12); }
.ta-summary-card { padding: 10px; border-radius: 10px; background: rgba(99, 102, 241, 0.06); border: 1px solid rgba(99, 102, 241, 0.12); text-align: center; }
.v-theme--dark .ta-summary-card { background: rgba(30, 41, 59, 0.4); border-color: rgba(99, 102, 241, 0.18); }
.ta-summary-label { font-size: 0.68rem; color: #64748b; text-transform: uppercase; letter-spacing: 0.04em; margin-bottom: 4px; }
.v-theme--dark .ta-summary-label { color: #94a3b8; }
.ta-summary-value { font-size: 1.1rem; font-weight: 700; }
</style>
