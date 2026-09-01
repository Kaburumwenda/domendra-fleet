<template>
  <div class="d-flex flex-column ga-4">
    <!-- Premium Gradient KPI Row -->
    <v-row dense>
      <v-col cols="6" md="3" v-for="(kpi, i) in kpis" :key="i">
        <v-card elevation="0" border class="pa-5 h-100 position-relative overflow-hidden" style="cursor: pointer" @click="$emit('navigate', kpi.tab)">
          <div class="position-absolute" style="top: -20px; right: -20px; opacity: 0.06">
            <v-icon :icon="kpi.icon" size="96" :color="kpi.color" />
          </div>
          <div class="d-flex align-center ga-2 mb-2">
            <v-icon :color="kpi.color" size="small">{{ kpi.icon }}</v-icon>
            <span class="text-caption text-medium-emphasis">{{ kpi.label }}</span>
          </div>
          <p class="text-h5 font-weight-bold" :style="{ color: kpi.textColor }">{{ kpi.prefix }}{{ kpi.value }}</p>
          <div v-if="kpi.sub" class="d-flex align-center ga-1 mt-1">
            <v-icon :color="kpi.subColor || 'medium-emphasis'" size="x-small">{{ kpi.subIcon || 'mdi-circle-medium' }}</v-icon>
            <span class="text-caption text-medium-emphasis">{{ kpi.sub }}</span>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <!-- Charts Row -->
    <v-row dense>
      <v-col cols="12" md="8">
        <DashboardChart :option="monthlyOption" title="Monthly Spend Trend" icon="mdi-chart-line" height="300px" />
      </v-col>
      <v-col cols="12" md="4">
        <DashboardChart :option="categoryOption" title="Spend by Category" icon="mdi-chart-pie" height="300px" />
      </v-col>
    </v-row>

    <v-row dense>
      <v-col cols="12" md="6">
        <DashboardChart :option="statusOption" title="Status Breakdown" icon="mdi-chart-donut" height="260px" />
      </v-col>
      <v-col cols="12" md="6">
        <DashboardChart :option="topVendorsOption" title="Top Vendors by Spend" icon="mdi-store-marker" height="260px" />
      </v-col>
    </v-row>

    <!-- Recently added (mini list) -->
    <v-card elevation="0" border class="pa-4">
      <div class="d-flex align-center justify-space-between mb-3">
        <h3 class="text-subtitle-2 font-weight-medium d-flex align-center ga-2" style="color: #475569">
          <v-icon size="small" color="primary">mdi-clock-outline</v-icon> Recent Expenses
        </h3>
        <v-btn size="small" variant="text" color="primary" append-icon="mdi-arrow-right" @click="$emit('navigate', 'records')">View all</v-btn>
      </div>
      <v-list density="compact" lines="two" class="pa-0">
        <v-list-item v-for="e in recentExpenses" :key="e.id" @click="$emit('open', e)">
          <template #prepend>
            <div class="d-flex align-center justify-center" :style="{ width: '38px', height: '38px', borderRadius: '10px', background: (e.category_color || '#6366f1') + '22' }">
              <v-icon :color="chipColor(e.category_color)" size="small">{{ e.category_icon || 'mdi-cash' }}</v-icon>
            </div>
          </template>
          <v-list-item-title class="font-weight-medium">{{ e.title }}</v-list-item-title>
          <v-list-item-subtitle>{{ e.category_name || 'Uncategorized' }} · {{ e.vendor_name || '—' }} · {{ fmtDate(e.expense_date) }}</v-list-item-subtitle>
          <template #append>
            <div class="d-flex flex-column align-end">
              <span class="font-weight-bold">{{ currencySymbol }}{{ money(e.amount) }}</span>
              <v-chip :color="statusColor(e.status)" variant="tonal" size="x-small" class="text-capitalize mt-1">{{ e.status }}</v-chip>
            </div>
          </template>
        </v-list-item>
        <div v-if="!recentExpenses.length" class="text-center py-8 text-medium-emphasis">
          <v-icon size="40" class="mb-2">mdi-receipt-text-outline</v-icon>
          <p>No recent expenses.</p>
        </div>
      </v-list>
    </v-card>
  </div>
</template>

<script setup lang="ts">
import * as echarts from 'echarts/core'

const { isDark } = useDarkMode()

const props = defineProps<{
  summary: any
  expenses: any[]
  currencySymbol: string
}>()

defineEmits<{
  navigate: [tab: string]
  open: [expense: any]
}>()

const recentExpenses = computed(() =>
  [...(props.expenses || [])].sort((a, b) => new Date(b.created_at).valueOf() - new Date(a.created_at).valueOf()).slice(0, 6)
)

const totalAmount = computed(() => Number(props.summary?.total_amount || 0))
const pendingCount = computed(() => Number(props.summary?.pending || 0))
const rejectedCount = computed(() => Number(props.summary?.rejected || 0))
const billableTotal = computed(() => Number(props.summary?.billable_total || 0))

const kpis = computed(() => [
  {
    label: 'Total Spend',
    value: money(totalAmount.value),
    prefix: props.currencySymbol,
    icon: 'mdi-cash-multiple',
    color: 'primary',
    textColor: '#6366f1',
    sub: `${props.summary?.total_count || 0} expenses`,
    tab: 'records',
  },
  {
    label: 'Pending Approval',
    value: pendingCount.value,
    prefix: '',
    icon: 'mdi-clock-alert-outline',
    color: 'warning',
    textColor: '#f59e0b',
    sub: 'Awaiting review',
    subIcon: 'mdi-account-clock-outline',
    tab: 'approvals',
  },
  {
    label: 'Rejected',
    value: rejectedCount.value,
    prefix: '',
    icon: 'mdi-close-circle-outline',
    color: 'error',
    textColor: '#ef4444',
    sub: 'Needs attention',
    subIcon: 'mdi-alert-circle-outline',
    subColor: 'error',
    tab: 'records',
  },
  {
    label: 'Billable',
    value: money(billableTotal.value),
    prefix: props.currencySymbol,
    icon: 'mdi-receipt-outline',
    color: 'success',
    textColor: '#10b981',
    sub: 'Reimbursable',
    subIcon: 'mdi-cash-refund',
    tab: 'records',
  },
])

// Dark-theme palette
const axisColor = computed(() => (isDark.value ? '#94a3b8' : '#64748b'))
const splitColor = computed(() => (isDark.value ? '#1e293b' : '#f1f5f9'))
const tooltipBg = computed(() => (isDark.value ? '#1e293b' : '#fff'))
const tooltipBorder = computed(() => (isDark.value ? '#334155' : '#e2e8f0'))
const tooltipText = computed(() => (isDark.value ? '#f1f5f9' : '#1e293b'))

const monthlyOption = computed(() => {
  const rows = props.summary?.monthly || []
  return {
    tooltip: { trigger: 'axis', backgroundColor: tooltipBg.value, borderColor: tooltipBorder.value, textStyle: { color: tooltipText.value } },
    grid: { left: 50, right: 20, top: 30, bottom: 30 },
    xAxis: {
      type: 'category', data: rows.map((r: any) => r.month),
      axisLabel: { color: axisColor.value }, axisLine: { lineStyle: { color: splitColor.value } },
    },
    yAxis: {
      type: 'value', axisLabel: { color: axisColor.value, formatter: (v: number) => `${props.currencySymbol}${v >= 1000 ? (v / 1000).toFixed(0) + 'k' : v}` },
      splitLine: { lineStyle: { color: splitColor.value } },
    },
    series: [
      {
        name: 'Spend', type: 'bar', data: rows.map((r: any) => Number(r.total)), smooth: true,
        itemStyle: { color: '#6366f1', borderRadius: [6, 6, 0, 0] },
        areaStyle: { color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{ offset: 0, color: 'rgba(99,102,241,0.25)' }, { offset: 1, color: 'rgba(99,102,241,0)' }]) },
      },
      {
        name: 'Count', type: 'line', yAxisIndex: 0, data: rows.map((r: any) => r.count),
        smooth: true, symbol: 'circle', symbolSize: 6, lineStyle: { color: '#10b981' }, itemStyle: { color: '#10b981' },
      },
    ],
    legend: { textStyle: { color: axisColor.value }, top: 0 },
  }
})

const categoryOption = computed(() => {
  const rows = (props.summary?.by_category || []).slice(0, 8)
  return {
    tooltip: { trigger: 'item', backgroundColor: tooltipBg.value, borderColor: tooltipBorder.value, textStyle: { color: tooltipText.value } },
    legend: { type: 'scroll', orient: 'vertical', right: 0, top: 'middle', textStyle: { color: axisColor.value } },
    series: [
      {
        type: 'pie', radius: ['45%', '75%'], center: ['40%', '50%'],
        avoidLabelOverlap: true,
        itemStyle: { borderColor: tooltipBg.value, borderWidth: 2 },
        label: { show: false },
        data: rows.map((r: any) => ({
          value: Number(r.total), name: r.category__name,
          itemStyle: { color: r.category__color || '#6366f1' },
        })),
      },
    ],
  }
})

const statusOption = computed(() => {
  const rows = props.summary?.by_status || []
  const palette: Record<string, string> = { draft: '#94a3b8', submitted: '#f59e0b', approved: '#3b82f6', rejected: '#ef4444', paid: '#10b981' }
  return {
    tooltip: { trigger: 'item', backgroundColor: tooltipBg.value, borderColor: tooltipBorder.value, textStyle: { color: tooltipText.value } },
    legend: { bottom: 0, textStyle: { color: axisColor.value } },
    series: [
      {
        type: 'pie', radius: ['45%', '72%'], center: ['50%', '47%'],
        label: { show: false },
        data: rows.map((r: any) => ({
          value: Number(r.count), name: r.status,
          itemStyle: { color: palette[r.status] || '#6366f1' },
        })),
      },
    ],
  }
})

const topVendorsOption = computed(() => {
  const rows = props.summary?.top_vendors || []
  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, backgroundColor: tooltipBg.value, borderColor: tooltipBorder.value, textStyle: { color: tooltipText.value } },
    grid: { left: 140, right: 30, top: 10, bottom: 20 },
    xAxis: { type: 'value', axisLabel: { color: axisColor.value, formatter: (v: number) => `${props.currencySymbol}${v >= 1000 ? (v / 1000).toFixed(0) + 'k' : v}` }, splitLine: { lineStyle: { color: splitColor.value } } },
    yAxis: { type: 'category', data: [...rows].reverse().map((r: any) => r.vendor_name), axisLabel: { color: axisColor.value, width: 120, overflow: 'truncate' } },
    series: [
      {
        type: 'bar', data: [...rows].reverse().map((r: any) => Number(r.total)),
        itemStyle: { color: '#0ea5e9', borderRadius: [0, 6, 6, 0] },
      },
    ],
  }
})

// ── Utilities ──
function money(v: any) { return Number(v || 0).toFixed(2) }
function fmtDate(d?: string) { return d ? new Date(d).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' }) : '—' }
function chipColor(hex: string) {
  if (!hex) return 'primary'
  // approximate: use the category color as text color
  return hex
}
function statusColor(s: string) {
  return ({ draft: 'grey', submitted: 'warning', approved: 'info', rejected: 'error', paid: 'success' } as any)[s] || 'grey'
}
</script>
