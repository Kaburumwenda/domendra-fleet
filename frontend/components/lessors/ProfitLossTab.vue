<template>
  <div class="d-flex flex-column ga-4">
    <!-- ── Date Filter Bar ── -->
    <v-card variant="outlined" rounded="lg" class="pa-3">
      <div class="d-flex align-center ga-4 flex-wrap">
        <div class="d-flex align-center ga-2">
          <v-icon icon="mdi-filter-calendar" color="primary" />
          <span class="text-body-2 font-weight-bold text-medium-emphasis">Date Range</span>
        </div>
        <div class="d-flex align-center ga-2 flex-wrap">
          <div class="d-flex flex-column">
            <span class="text-caption text-medium-emphasis mb-1">From</span>
            <v-text-field
              :model-value="startDate"
              type="date"
              density="compact"
              variant="outlined"
              hide-details
              style="max-width: 170px"
              @update:model-value="$emit('update:start-date', $event)"
            />
          </div>
          <v-icon icon="mdi-arrow-right" class="mt-4" color="medium-emphasis" />
          <div class="d-flex flex-column">
            <span class="text-caption text-medium-emphasis mb-1">To</span>
            <v-text-field
              :model-value="endDate"
              type="date"
              density="compact"
              variant="outlined"
              hide-details
              style="max-width: 170px"
              @update:model-value="$emit('update:end-date', $event)"
            />
          </div>
        </div>
        <v-btn variant="text" prepend-icon="mdi-refresh" size="small" color="primary" class="mt-4" @click="$emit('reset')">
          Reset
        </v-btn>
        <v-spacer />
        <v-chip v-if="data" size="small" variant="tonal" color="primary">
          {{ data.period.start }} — {{ data.period.end }}
        </v-chip>
      </div>
    </v-card>

    <!-- ── Loading ── -->
    <div v-if="loading" class="d-flex justify-center align-center py-12">
      <v-progress-circular indeterminate size="48" color="primary" />
    </div>

    <!-- ── Empty ── -->
    <div v-else-if="!data" class="text-center text-medium-emphasis py-12">
      <v-icon size="48" class="mb-2">mdi-chart-arc</v-icon>
      <p>No data available.</p>
    </div>

    <template v-else>
      <!-- ── KPI Cards ── -->
      <v-row dense>
        <v-col cols="12" sm="6" md="3">
          <StatCard
            label="Total Revenue"
            :value="fmtMoney(data.summary.total_revenue)"
            icon="mdi-cash-multiple"
            iconBg="#dbeafe"
            iconColor="#2563eb"
            :subtitle="`${data.trends.revenue_change_pct}% vs prev`"
            :trend="data.trends.revenue_change_pct"
          />
        </v-col>
        <v-col cols="12" sm="6" md="3">
          <StatCard
            label="Total Costs"
            :value="fmtMoney(data.summary.total_costs)"
            icon="mdi-cash-remove"
            iconBg="#fee2e2"
            iconColor="#dc2626"
            :subtitle="`${data.trends.cost_change_pct}% vs prev`"
            :trend="-data.trends.cost_change_pct"
          />
        </v-col>
        <v-col cols="12" sm="6" md="3">
          <StatCard
            label="Net Profit / Loss"
            :value="fmtMoney(data.summary.net_profit)"
            :icon="netProfitIcon"
            :iconBg="netProfitIconBg"
            :iconColor="netProfitIconColor"
            :subtitle="`${data.trends.profit_change_pct}% vs prev`"
          />
        </v-col>
        <v-col cols="12" sm="6" md="3">
          <StatCard
            label="Net Margin"
            :value="`${data.summary.net_margin}%`"
            :icon="marginIcon"
            :iconBg="netProfitIconBg"
            :iconColor="netProfitIconColor"
            :subtitle="`Gross: ${data.summary.gross_margin}%`"
          />
        </v-col>
      </v-row>

      <!-- ── Secondary KPIs ── -->
      <v-row dense>
        <v-col cols="6" md="3">
          <v-card variant="outlined" rounded="lg" class="pa-3">
            <div class="d-flex align-center ga-2">
              <v-icon color="primary" size="20">mdi-bank-outline</v-icon>
              <span class="text-caption text-medium-emphasis">Cash Collected</span>
            </div>
            <p class="text-h6 font-weight-bold mt-2" style="color: #2563eb">{{ fmtMoney(data.summary.cash_collected) }}</p>
          </v-card>
        </v-col>
        <v-col cols="6" md="3">
          <v-card variant="outlined" rounded="lg" class="pa-3">
            <div class="d-flex align-center ga-2">
              <v-icon color="warning" size="20">mdi-clock-outline</v-icon>
              <span class="text-caption text-medium-emphasis">Outstanding A/R</span>
            </div>
            <p class="text-h6 font-weight-bold mt-2" style="color: #ea580c">{{ fmtMoney(data.summary.outstanding_ar) }}</p>
          </v-card>
        </v-col>
        <v-col cols="6" md="3">
          <v-card variant="outlined" rounded="lg" class="pa-3">
            <div class="d-flex align-center ga-2">
              <v-icon color="info" size="20">mdi-chart-line-variant</v-icon>
              <span class="text-caption text-medium-emphasis">Operating Profit</span>
            </div>
            <p class="text-h6 font-weight-bold mt-2" :style="{ color: operatingPositive ? '#16a34a' : '#dc2626' }">
              {{ fmtMoney(data.summary.operating_profit) }}
            </p>
          </v-card>
        </v-col>
        <v-col cols="6" md="3">
          <v-card variant="outlined" rounded="lg" class="pa-3">
            <div class="d-flex align-center ga-2">
              <v-icon color="success" size="20">mdi-chart-bell-curve</v-icon>
              <span class="text-caption text-medium-emphasis">Gross Profit</span>
            </div>
            <p class="text-h6 font-weight-bold mt-2" :style="{ color: grossPositive ? '#16a34a' : '#dc2626' }">
              {{ fmtMoney(data.summary.gross_profit) }}
            </p>
          </v-card>
        </v-col>
      </v-row>

      <!-- ── Charts Row ── -->
      <v-row dense>
        <v-col cols="12" lg="8">
          <DashboardChart
            :option="trendChartOption"
            title="Revenue, Costs & Profit (Monthly)"
            icon="mdi-chart-line"
            height="340px"
          />
        </v-col>
        <v-col cols="12" lg="4">
          <DashboardChart
            :option="costPieOption"
            title="Cost Distribution"
            icon="mdi-chart-donut"
            height="340px"
          />
        </v-col>
      </v-row>

      <!-- ── P&L Statement ── -->
      <v-card variant="outlined" rounded="lg">
        <v-card-title class="d-flex align-center ga-2 pb-2">
          <v-icon color="primary">mdi-file-chart-outline</v-icon>
          <span class="text-subtitle-1 font-weight-bold">Profit and Loss Statement</span>
          <v-spacer />
          <v-btn
            variant="text"
            size="small"
            prepend-icon="mdi-download"
            color="primary"
            @click="exportCsv"
          >
            Export CSV
          </v-btn>
        </v-card-title>
        <v-divider />
        <v-table density="comfortable">
          <thead>
            <tr>
              <th class="text-left" style="min-width: 280px">Line Item</th>
              <th class="text-right" style="min-width: 140px">Amount</th>
            </tr>
          </thead>
          <tbody>
            <template v-for="(line, i) in data.statement" :key="i">
              <!-- Section Header -->
              <tr v-if="line.section === 'header'" class="section-header">
                <td class="font-weight-bold text-uppercase text-body-2" style="color: #475569; letter-spacing: 0.5px; background: #f8fafc">
                  {{ line.label }}
                </td>
                <td class="text-right font-weight-bold text-body-2" style="background: #f8fafc">
                  {{ fmtMoney(line.amount) }}
                </td>
              </tr>
              <!-- Line item -->
              <tr v-else-if="line.section === 'revenue' || line.section === 'cost'">
                <td class="pl-8 text-body-2">{{ line.label }}</td>
                <td class="text-right text-body-2" :style="{ color: line.type === 'revenue' ? '#16a34a' : '#dc2626' }">
                  {{ line.type === 'revenue' ? '+' : '-' }}{{ fmtMoney(line.amount) }}
                </td>
              </tr>
              <!-- Subtotal -->
              <tr v-else-if="line.section === 'subtotal'">
                <td class="font-weight-bold text-body-2" style="color: #475569; border-top: 2px solid #e2e8f0">
                  {{ line.label }}
                </td>
                <td class="text-right font-weight-bold text-body-2" :style="{ color: line.type === 'revenue' ? '#16a34a' : '#dc2626', borderTop: '2px solid #e2e8f0' }">
                  {{ fmtMoney(line.amount) }}
                </td>
              </tr>
              <!-- Result (Gross/Operating/Net) -->
              <tr v-else-if="line.section === 'result'" class="result-row">
                <td class="font-weight-bold text-subtitle-2 py-3" :style="{ color: line.amount >= 0 ? '#16a34a' : '#dc2626', background: resultBg(line.amount) }">
                  {{ line.label }}
                </td>
                <td class="text-right font-weight-bold text-subtitle-1 py-3" :style="{ color: line.amount >= 0 ? '#16a34a' : '#dc2626', background: resultBg(line.amount) }">
                  {{ fmtMoney(line.amount) }}
                </td>
              </tr>
            </template>
          </tbody>
        </v-table>
      </v-card>

      <!-- ── Cost Breakdown Bar Chart ── -->
      <v-row dense>
        <v-col cols="12">
          <DashboardChart
            :option="costBarOption"
            title="Cost Breakdown by Category"
            icon="mdi-chart-bar"
            height="300px"
          />
        </v-col>
      </v-row>
    </template>
  </div>
</template>

<script setup lang="ts">
const { fmtMoney } = useCurrency()

const props = defineProps<{
  data: any
  loading: boolean
  startDate: string
  endDate: string
}>()

defineEmits<{
  'update:start-date': [value: string]
  'update:end-date': [value: string]
  reset: []
}>()

const netProfit = computed(() => props.data?.summary?.net_profit ?? 0)
const netProfitPositive = computed(() => netProfit.value >= 0)
const netProfitIcon = computed(() => netProfitPositive.value ? 'mdi-trending-up' : 'mdi-trending-down')
const netProfitIconBg = computed(() => netProfitPositive.value ? '#dcfce7' : '#fee2e2')
const netProfitIconColor = computed(() => netProfitPositive.value ? '#16a34a' : '#dc2626')
const marginIcon = computed(() => netProfitPositive.value ? 'mdi-percent-circle' : 'mdi-alert-circle')
const operatingPositive = computed(() => (props.data?.summary?.operating_profit ?? 0) >= 0)
const grossPositive = computed(() => (props.data?.summary?.gross_profit ?? 0) >= 0)

function resultBg(amount: number) {
  return amount >= 0 ? '#f0fdf4' : '#fef2f2'
}

// ── Trend Chart (Revenue + Costs + Profit) ──
const trendChartOption = computed(() => {
  if (!props.data?.monthly_series) return null
  const months = props.data.monthly_series.map((m: any) => m.month)
  const revenue = props.data.monthly_series.map((m: any) => Number(m.revenue))
  const costs = props.data.monthly_series.map((m: any) => Number(m.costs))
  const profit = props.data.monthly_series.map((m: any) => Number(m.profit))

  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'cross' } },
    legend: { data: ['Revenue', 'Costs', 'Profit'], bottom: 0 },
    grid: { left: 60, right: 30, top: 30, bottom: 50 },
    xAxis: { type: 'category', data: months, boundaryGap: false },
    yAxis: {
      type: 'value',
      axisLabel: { formatter: (v: number) => {
        if (Math.abs(v) >= 1_000_000) return (v / 1_000_000).toFixed(1) + 'M'
        if (Math.abs(v) >= 1_000) return (v / 1_000).toFixed(0) + 'K'
        return v.toString()
      } },
    },
    series: [
      {
        name: 'Revenue',
        type: 'line',
        smooth: true,
        data: revenue,
        itemStyle: { color: '#2563eb' },
        lineStyle: { width: 3 },
        areaStyle: {
          color: { type: 'linear', x: 0, y: 0, x2: 0, y2: 1,
            colorStops: [{ offset: 0, color: 'rgba(37,99,235,0.25)' }, { offset: 1, color: 'rgba(37,99,235,0.01)' }] },
        },
      },
      {
        name: 'Costs',
        type: 'line',
        smooth: true,
        data: costs,
        itemStyle: { color: '#dc2626' },
        lineStyle: { width: 3 },
        areaStyle: {
          color: { type: 'linear', x: 0, y: 0, x2: 0, y2: 1,
            colorStops: [{ offset: 0, color: 'rgba(220,38,38,0.25)' }, { offset: 1, color: 'rgba(220,38,38,0.01)' }] },
        },
      },
      {
        name: 'Profit',
        type: 'line',
        smooth: true,
        data: profit,
        itemStyle: { color: '#16a34a' },
        lineStyle: { width: 3, type: 'dashed' },
      },
    ],
  }
})

// ── Cost Distribution Pie ──
const costPieOption = computed(() => {
  const items = (props.data?.cost_breakdown ?? []).filter((c: any) => c.value > 0)
  if (!items.length) return null
  const palette = [
    '#ef4444', '#f97316', '#eab308', '#84cc16', '#22c55e',
    '#06b6d4', '#3b82f6', '#8b5cf6', '#d946ef', '#ec4899', '#f43f5e',
  ]
  return {
    tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
    legend: { bottom: 0, type: 'scroll' },
    color: palette,
    series: [{
      type: 'pie',
      radius: ['40%', '70%'],
      center: ['50%', '45%'],
      itemStyle: { borderRadius: 6, borderColor: '#fff', borderWidth: 2 },
      label: { show: false },
      emphasis: { label: { show: true, fontSize: 14, fontWeight: 'bold' } },
      data: items.map((c: any) => ({ name: c.name, value: c.value })),
    }],
  }
})

// ── Cost Breakdown Bar Chart ──
const costBarOption = computed(() => {
  const items = (props.data?.cost_breakdown ?? []).filter((c: any) => c.value > 0)
  if (!items.length) return null
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: 160, right: 30, top: 20, bottom: 20 },
    xAxis: { type: 'value', axisLabel: { formatter: (v: number) => {
      if (Math.abs(v) >= 1_000_000) return (v / 1_000_000).toFixed(1) + 'M'
      if (Math.abs(v) >= 1_000) return (v / 1_000).toFixed(0) + 'K'
      return v.toString()
    } } },
    yAxis: { type: 'category', data: items.map((c: any) => c.name), inverse: true },
    series: [{
      type: 'bar',
      data: items.map((c: any) => c.value),
      barMaxWidth: 24,
      itemStyle: {
        borderRadius: [0, 6, 6, 0],
        color: function (params: any) {
          const palette = ['#ef4444', '#f97316', '#eab308', '#84cc16', '#22c55e', '#06b6d4', '#3b82f6', '#8b5cf6', '#d946ef', '#ec4899', '#f43f5e']
          return palette[params.dataIndex % palette.length]
        },
      },
    }],
  }
})

// ── Export CSV ──
function exportCsv() {
  if (!props.data?.statement) return
  const rows = ['Section,Line Item,Amount']
  for (const line of props.data.statement) {
    rows.push(`"${line.section}","${line.label}",${line.amount}`)
  }
  const csv = rows.join('\n')
  const blob = new Blob([csv], { type: 'text/csv' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `profit-loss-${props.data.period.start}-to-${props.data.period.end}.csv`
  a.click()
  URL.revokeObjectURL(url)
}
</script>

<style scoped>
.section-header td {
  border-bottom: 1px solid #e2e8f0;
}
.result-row td {
  border-bottom: 1px solid #e2e8f0;
}
.result-row:last-child td {
  border-bottom: none;
}
</style>
