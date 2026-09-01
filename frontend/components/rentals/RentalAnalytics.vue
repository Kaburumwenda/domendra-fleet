<template>
  <!-- Date Filter Bar -->
  <div class="d-flex align-center ga-3 flex-wrap mb-4 pa-3 rounded-lg" style="border: 1px solid #e2e8f0;">
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
      />
      <v-text-field
        v-model="customEndDate"
        type="date"
        density="compact"
        variant="outlined"
        label="End"
        hide-details
        style="max-width: 160px"
      />
    </template>
    <v-spacer />
    <v-chip v-if="periodLabel" size="small" variant="tonal" color="primary" prepend-icon="mdi-calendar">
      {{ periodLabel }}
    </v-chip>
  </div>

  <div class="kpi-grid">
    <div
      v-for="c in cards"
      :key="c.label"
      class="kpi-card"
      :class="{ 'kpi-clickable': !!c.click }"
      @click="c.click?.()"
    >
      <div class="kpi-icon" :style="{ background: c.gradient }">
        <v-icon size="22" color="white">{{ c.icon }}</v-icon>
      </div>
      <div class="kpi-body">
        <div class="kpi-value">{{ c.value }}</div>
        <div class="kpi-label">{{ c.label }}</div>
        <div v-if="c.sub" class="kpi-sub" :style="{ color: c.subColor }">
          <v-icon v-if="c.subIcon" size="13" :color="c.subColor">{{ c.subIcon }}</v-icon>
          {{ c.sub }}
        </div>
      </div>
    </div>
  </div>

  <div class="status-grid mt-4">
    <!-- Status Distribution -->
    <div class="status-card">
      <div class="status-head">
        <v-icon size="18" color="primary">mdi-chart-donut</v-icon>
        <span class="status-title">Agreement Status</span>
      </div>
      <div class="status-rows">
        <div
          v-for="s in statusBreakdown"
          :key="s.key"
          class="status-row"
          :class="{ active: s.key === activeFilter }"
          @click="$emit('filter', s.key)"
        >
          <div class="d-flex align-center ga-2 status-label">
            <span class="dot" :class="dotClass(s.key)" />
            <span class="text-capitalize">{{ s.key.replace('_', ' ') }}</span>
            <span class="status-count">{{ s.count }}</span>
          </div>
          <div class="status-bar">
            <div class="status-bar-fill" :class="dotClass(s.key)" :style="{ width: s.pct + '%' }" />
          </div>
        </div>
        <div v-if="!total" class="text-body-2 text-medium-emphasis py-2">No agreements yet.</div>
      </div>
    </div>

    <!-- Payment Distribution -->
    <div class="status-card">
      <div class="status-head">
        <v-icon size="18" color="success">mdi-cash-multiple</v-icon>
        <span class="status-title">Payment Status</span>
      </div>
      <div class="status-rows">
        <div
          v-for="p in paymentBreakdown"
          :key="p.key"
          class="status-row"
          :class="{ active: p.key === paymentFilter }"
          @click="$emit('filterPayment', p.key)"
        >
          <div class="d-flex align-center ga-2 status-label">
            <span class="dot" :class="payDotClass(p.key)" />
            <span class="text-capitalize">{{ p.key }}</span>
            <span class="status-count">{{ p.count }}</span>
          </div>
          <div class="status-bar">
            <div class="status-bar-fill" :class="payDotClass(p.key)" :style="{ width: p.pct + '%' }" />
          </div>
        </div>
        <div v-if="!total" class="text-body-2 text-medium-emphasis py-2">No agreements yet.</div>
      </div>
    </div>

    <!-- On-Time Performance -->
    <div class="status-card">
      <div class="status-head">
        <v-icon size="18" color="primary">mdi-clock-outline</v-icon>
        <span class="status-title">On-Time Performance</span>
      </div>
      <div class="ontrack-body">
        <div class="ontrack-ring">
          <v-progress-circular :model-value="onTimeRate" size="92" width="9" color="success" rotate="-90">
            <span class="ontrack-pct">{{ onTimeRate }}<span class="ontrack-pct-unit">%</span></span>
          </v-progress-circular>
        </div>
        <div class="ontrack-stats">
          <div class="ontrack-line"><span class="dot dot-success" /> On time: <b>{{ onTimeCount }}</b></div>
          <div class="ontrack-line"><span class="dot dot-error" /> Overdue: <b>{{ overdueCount }}</b></div>
          <div class="ontrack-line text-medium-emphasis">Completed: <b>{{ completedCount }}</b></div>
        </div>
      </div>
    </div>
  </div>

  <!-- Revenue & Customer Type Breakdown -->
  <div class="status-grid mt-4">
    <!-- Revenue by Rate Period -->
    <div class="status-card">
      <div class="status-head">
        <v-icon size="18" color="success">mdi-chart-bar</v-icon>
        <span class="status-title">Revenue by Rate Period</span>
      </div>
      <div class="status-rows">
        <div v-for="r in revenueByPeriod" :key="r.key" class="status-row">
          <div class="d-flex align-center ga-2 status-label">
            <v-icon size="16" :color="periodColor(r.key)">{{ periodIcon(r.key) }}</v-icon>
            <span class="text-capitalize">{{ r.key }}</span>
            <span class="status-count">{{ currencySymbol }}{{ formatNum(r.value) }}</span>
          </div>
          <div class="status-bar">
            <div class="status-bar-fill" :style="{ width: r.pct + '%', background: periodColor(r.key) }" />
          </div>
        </div>
        <div v-if="!total" class="text-body-2 text-medium-emphasis py-2">No revenue yet.</div>
      </div>
    </div>

    <!-- Customer Type Mix -->
    <div class="status-card">
      <div class="status-head">
        <v-icon size="18" color="info">mdi-account-group</v-icon>
        <span class="status-title">Customer Type</span>
      </div>
      <div class="ontrack-body" style="gap: 24px;">
        <div class="ontrack-ring">
          <v-progress-circular :model-value="localPct" size="92" width="9" color="success" rotate="-90">
            <span class="ontrack-pct">{{ localPct }}<span class="ontrack-pct-unit">%</span></span>
          </v-progress-circular>
        </div>
        <div class="ontrack-stats">
          <div class="ontrack-line"><span class="dot dot-success" /> Local: <b>{{ localCount }}</b></div>
          <div class="ontrack-line"><span class="dot dot-info" /> Foreigner: <b>{{ foreignerCount }}</b></div>
          <div class="ontrack-line text-medium-emphasis">Total: <b>{{ totalCustomers }}</b></div>
        </div>
      </div>
    </div>

    <!-- Top Vehicles by Rental Count -->
    <div class="status-card">
      <div class="status-head">
        <v-icon size="18" color="warning">mdi-car-multiple</v-icon>
        <span class="status-title">Most Rented Vehicles</span>
      </div>
      <div class="status-rows">
        <div v-for="(v, i) in topVehicles" :key="v.name" class="status-row">
          <div class="d-flex align-center ga-2 status-label">
            <v-avatar size="24" :color="rankColor(i)" variant="tonal" class="text-caption font-weight-bold">{{ i + 1 }}</v-avatar>
            <span class="text-body-2" style="overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">{{ v.name }}</span>
            <span class="status-count">{{ v.count }}x</span>
          </div>
          <div class="status-bar">
            <div class="status-bar-fill" :style="{ width: v.pct + '%', background: rankColor(i) }" />
          </div>
        </div>
        <div v-if="!topVehicles.length" class="text-body-2 text-medium-emphasis py-2">No rentals yet.</div>
      </div>
    </div>
  </div>

  <!-- Revenue by Location & Vehicle Type -->
  <div class="status-grid mt-4">
    <!-- Revenue by Location -->
    <div class="status-card">
      <div class="status-head">
        <v-icon size="18" color="deep-orange">mdi-map-marker-multiple-outline</v-icon>
        <span class="status-title">Revenue by Location</span>
      </div>
      <div class="status-rows">
        <div v-for="loc in revenueByLocation" :key="loc.name" class="status-row">
          <div class="d-flex align-center ga-2 status-label">
            <v-icon size="16" :color="locColor(loc.idx)">{{ locIcon }}</v-icon>
            <span class="text-body-2" style="overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">{{ loc.name }}</span>
            <span class="status-count">{{ currencySymbol }}{{ formatNum(loc.value) }}</span>
          </div>
          <div class="status-bar">
            <div class="status-bar-fill" :style="{ width: loc.pct + '%', background: locColor(loc.idx) }" />
          </div>
        </div>
        <div v-if="!revenueByLocation.length" class="text-body-2 text-medium-emphasis py-2">No location data yet.</div>
      </div>
    </div>

    <!-- Revenue by Vehicle Type -->
    <div class="status-card">
      <div class="status-head">
        <v-icon size="18" color="indigo">mdi-car-estate</v-icon>
        <span class="status-title">Revenue by Vehicle Type</span>
      </div>
      <div class="status-rows">
        <div v-for="vt in revenueByVehicleType" :key="vt.name" class="status-row">
          <div class="d-flex align-center ga-2 status-label">
            <v-icon size="16" :color="vtColor(vt.idx)">{{ vtIcon(vt.name) }}</v-icon>
            <span class="text-body-2" style="overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">{{ vt.name }}</span>
            <span class="status-count">{{ currencySymbol }}{{ formatNum(vt.value) }}</span>
          </div>
          <div class="status-bar">
            <div class="status-bar-fill" :style="{ width: vt.pct + '%', background: vtColor(vt.idx) }" />
          </div>
        </div>
        <div v-if="!revenueByVehicleType.length" class="text-body-2 text-medium-emphasis py-2">No vehicle type data yet.</div>
      </div>
    </div>
  </div>

  <!-- Revenue Trend Chart -->
  <div class="status-card mt-4" style="padding-bottom: 0;">
    <div class="status-head" style="margin-bottom: 0; padding-bottom: 12px;">
      <v-icon size="18" color="primary">mdi-chart-line-variant</v-icon>
      <span class="status-title">Revenue &amp; Payment Trend</span>
    </div>
    <DashboardChart :option="trendChartOption" height="320px" />
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  agreements: any[]
  customers: any[]
  payments: any[]
  activeFilter?: string | null
  paymentFilter?: string | null
}>()

defineEmits<{
  filter: [key: string]
  filterPayment: [key: string]
}>()

const { currencySymbol } = useCurrency()

// ── Date Filter ──
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

const dateRange = computed(() => {
  const now = new Date()
  let start = ''
  let end = ''
  switch (datePreset.value) {
    case 'this_week': {
      const day = now.getDay() || 7
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
  return { start, end }
})

const periodLabel = computed(() => {
  const { start, end } = dateRange.value
  if (!start || !end) return ''
  const fmt = (d: string) => new Date(d).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
  return `${fmt(start)} — ${fmt(end)}`
})

function applyDatePreset(p: DatePreset) {
  datePreset.value = p
}

// Agreements filtered by selected date range (client-side).
// Uses start_datetime as primary, falls back to created_at.
const filteredAgreements = computed(() => {
  const { start, end } = dateRange.value
  if (!start || !end) return props.agreements || []
  const s = new Date(start + 'T00:00:00').getTime()
  const e = new Date(end + 'T23:59:59').getTime()
  return (props.agreements || []).filter((a: any) => {
    const d = a.start_datetime || a.created_at
    if (!d) return false
    const ts = new Date(d).getTime()
    return !isNaN(ts) && ts >= s && ts <= e
  })
})

const total = computed(() => filteredAgreements.value.length)

function formatNum(n: number): string {
  return Math.round(n).toLocaleString()
}

// ── KPI Cards ──
const cards = computed(() => {
  const a = filteredAgreements.value
  const active = a.filter((x: any) => effectiveStatus(x) === 'active').length
  const overdue = a.filter((x: any) => effectiveStatus(x) === 'overdue').length
  const completed = a.filter((x: any) => x.status === 'completed').length
  const draft = a.filter((x: any) => x.status === 'draft').length
  const revenue = a.reduce((s: number, x: any) => s + Number(x.total_amount || 0), 0)
  const collected = a.reduce((s: number, x: any) => s + Number(x.amount_paid || 0), 0)
  const collectionRate = revenue ? Math.round((collected / revenue) * 100) : 0
  return [
    {
      label: 'Total Agreements', value: total.value, icon: 'mdi-file-document-multiple-outline',
      gradient: 'linear-gradient(135deg,#6366f1,#4f46e5)',
      sub: `${active} active · ${completed} completed`, subIcon: 'mdi-update', subColor: '#6366f1',
      click: () => {},
    },
    {
      label: 'On Rent Now', value: active, icon: 'mdi-car-key',
      gradient: 'linear-gradient(135deg,#f59e0b,#d97706)',
      sub: active ? 'Currently active' : 'No active rentals', subIcon: 'mdi-truck-fast', subColor: '#f59e0b',
      click: () => {},
    },
    {
      label: 'Total Revenue', value: `${currencySymbol.value}${formatNum(revenue)}`, icon: 'mdi-cash-multiple',
      gradient: 'linear-gradient(135deg,#10b981,#059669)',
      sub: `${collectionRate}% collected (${currencySymbol.value}${formatNum(collected)})`, subIcon: 'mdi-chart-arraw-up', subColor: '#10b981',
      click: () => {},
    },
    {
      label: 'Overdue', value: overdue, icon: 'mdi-alert-octagon',
      gradient: 'linear-gradient(135deg,#ef4444,#dc2626)',
      sub: overdue ? 'Needs attention' : 'All clear', subIcon: overdue ? 'mdi-bell-alert' : 'mdi-check', subColor: overdue ? '#ef4444' : '#10b981',
      click: () => {},
    },
  ]
})

// ── Effective status (client-side overdue detection) ──
function effectiveStatus(item: any) {
  const s = item.status || ''
  if (s === 'active' && item.end_datetime) {
    const end = new Date(item.end_datetime).getTime()
    if (!isNaN(end) && end < Date.now()) return 'overdue'
  }
  return s
}

// ── Status Distribution ──
const statusBreakdown = computed(() => {
  const order = ['draft', 'active', 'overdue', 'completed', 'cancelled']
  const counts: Record<string, number> = { draft: 0, active: 0, overdue: 0, completed: 0, cancelled: 0 }
  ;(filteredAgreements.value).forEach((a: any) => {
    const s = effectiveStatus(a)
    if (counts[s] != null) counts[s]++
    else if (counts[a.status] != null) counts[a.status]++
  })
  const tot = total.value || 1
  return order.map(k => ({ key: k, count: counts[k], pct: Math.round((counts[k] / tot) * 100) }))
})

// ── Payment Distribution ──
const paymentBreakdown = computed(() => {
  const order = ['paid', 'partial', 'unpaid']
  const counts: Record<string, number> = { paid: 0, partial: 0, unpaid: 0 }
  ;(filteredAgreements.value).forEach((a: any) => {
    if (a.status === 'draft' || a.status === 'cancelled') return
    const ps = a.payment_status || 'unpaid'
    if (counts[ps] != null) counts[ps]++
  })
  const tot = (counts.paid + counts.partial + counts.unpaid) || 1
  return order.map(k => ({ key: k, count: counts[k], pct: Math.round((counts[k] / tot) * 100) }))
})

// ── On-Time Performance ──
// An agreement is "overdue" (returned late) if:
//  - active and end_datetime has passed, OR
//  - completed but actual_return_datetime > end_datetime
function wasLate(a: any): boolean {
  if (!a.end_datetime) return false
  const end = new Date(a.end_datetime).getTime()
  if (isNaN(end)) return false
  if (a.status === 'active' && end < Date.now()) return true
  if (a.status === 'completed' && a.actual_return_datetime) {
    const ret = new Date(a.actual_return_datetime).getTime()
    return !isNaN(ret) && ret > end
  }
  return false
}
const onTimeCount = computed(() => filteredAgreements.value.filter((a: any) => a.status === 'completed' && !wasLate(a)).length)
const overdueCount = computed(() => filteredAgreements.value.filter((a: any) =>
  effectiveStatus(a) === 'overdue' || (a.status === 'completed' && wasLate(a))
).length)
const completedCount = computed(() => filteredAgreements.value.filter((a: any) => a.status === 'completed').length)
const onTimeRate = computed(() => {
  // on-time % = on-time completions / (on-time + late returns + currently overdue active)
  const total = onTimeCount.value + overdueCount.value
  return total ? Math.round((onTimeCount.value / total) * 100) : 0
})

// ── Revenue by Rate Period ──
const revenueByPeriod = computed(() => {
  const periods = ['daily', 'weekly', 'weekend', 'monthly']
  const sums: Record<string, number> = { daily: 0, weekly: 0, weekend: 0, monthly: 0 }
  ;(filteredAgreements.value).forEach((a: any) => {
    const rp = a.rate_period || 'daily'
    if (sums[rp] != null) sums[rp] += Number(a.total_amount || 0)
  })
  const tot = Object.values(sums).reduce((s, v) => s + v, 0) || 1
  return periods.map(k => ({ key: k, value: sums[k], pct: Math.round((sums[k] / tot) * 100) }))
})

// ── Customer Type ──
const totalCustomers = computed(() => props.customers?.length || 0)
const localCount = computed(() => (props.customers || []).filter((c: any) => c.customer_type === 'local').length)
const foreignerCount = computed(() => (props.customers || []).filter((c: any) => c.customer_type === 'foreigner').length)
const localPct = computed(() => totalCustomers.value ? Math.round((localCount.value / totalCustomers.value) * 100) : 0)

// ── Top Vehicles ──
const topVehicles = computed(() => {
  const counts: Record<string, number> = {}
  ;(filteredAgreements.value).forEach((a: any) => {
    const name = a.vehicle_display || 'Unknown'
    counts[name] = (counts[name] || 0) + 1
  })
  const entries = Object.entries(counts)
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 5)
  const max = entries.length ? entries[0].count : 1
  return entries.map(e => ({ ...e, pct: Math.round((e.count / max) * 100) }))
})

// ── Revenue by Location ──
const revenueByLocation = computed(() => {
  const sums: Record<string, number> = {}
  ;(filteredAgreements.value).forEach((a: any) => {
    const loc = a.pickup_location || 'Unspecified'
    sums[loc] = (sums[loc] || 0) + Number(a.total_amount || 0)
  })
  const entries = Object.entries(sums)
    .map(([name, value]) => ({ name, value }))
    .sort((a, b) => b.value - a.value)
    .slice(0, 8)
  const max = entries.length ? entries[0].value : 1
  return entries.map((e, i) => ({ ...e, idx: i, pct: Math.round((e.value / max) * 100) }))
})

// ── Revenue by Vehicle Type ──
const revenueByVehicleType = computed(() => {
  const sums: Record<string, number> = {}
  ;(filteredAgreements.value).forEach((a: any) => {
    const vt = a.vehicle_type || 'Unspecified'
    sums[vt] = (sums[vt] || 0) + Number(a.total_amount || 0)
  })
  const entries = Object.entries(sums)
    .map(([name, value]) => ({ name, value }))
    .sort((a, b) => b.value - a.value)
    .slice(0, 8)
  const max = entries.length ? entries[0].value : 1
  return entries.map((e, i) => ({ ...e, idx: i, pct: Math.round((e.value / max) * 100) }))
})

// ── Revenue Trend Chart ──
const trendChartOption = computed(() => {
  // Build time series from agreements — use daily granularity if data spans
  // less than 60 days, weekly if < 6 months, otherwise monthly.
  const items = (filteredAgreements.value)
    .map((a: any) => {
      const d = a.created_at || a.start_datetime
      if (!d) return null
      const date = new Date(d)
      if (isNaN(date.getTime())) return null
      return { date, revenue: Number(a.total_amount || 0), collected: Number(a.amount_paid || 0) }
    })
    .filter(Boolean) as { date: Date; revenue: number; collected: number }[]

  // Determine the span to pick bucket size
  const timestamps = items.map((i) => i.date.getTime())
  const spanDays = timestamps.length ? (Math.max(...timestamps) - Math.min(...timestamps)) / 86_400_000 : 0
  const bucket: 'daily' | 'weekly' | 'monthly' = spanDays < 60 ? 'daily' : spanDays < 180 ? 'weekly' : 'monthly'

  const pts: Record<string, { ts: number; label: string; revenue: number; collected: number }> = {}
  items.forEach((item) => {
    let key: string
    let ts: number
    if (bucket === 'daily') {
      key = item.date.toISOString().slice(0, 10)
      ts = new Date(key).getTime()
    } else if (bucket === 'weekly') {
      const tmp = new Date(item.date)
      const day = (tmp.getDay() + 6) % 7
      tmp.setDate(tmp.getDate() - day)
      key = 'W' + tmp.toISOString().slice(0, 10)
      ts = tmp.getTime()
    } else {
      key = item.date.toLocaleDateString('en-US', { month: 'short', year: '2-digit' })
      ts = new Date(item.date.getFullYear(), item.date.getMonth(), 1).getTime()
    }
    if (!pts[key]) pts[key] = { ts, label: key, revenue: 0, collected: 0 }
    pts[key].revenue += item.revenue
    pts[key].collected += item.collected
  })

  // Sort by timestamp and limit to last 12 buckets
  const sorted = Object.values(pts)
    .sort((a, b) => a.ts - b.ts)
    .slice(-12)

  // Format labels: daily → "Jul 3", weekly → "W Jul 3", monthly → "Jul 26"
  const formatted = sorted.map((s) => {
    if (/^\d{4}-\d{2}-\d{2}$/.test(s.label)) {
      return { ...s, label: new Date(s.ts).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }) }
    }
    if (s.label.startsWith('W')) {
      const d = new Date(s.ts)
      return { ...s, label: `W${d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}` }
    }
    return s
  })

  return {
    tooltip: {
      trigger: 'axis',
      backgroundColor: 'rgba(30,41,59,0.92)',
      borderWidth: 0, textStyle: { color: '#e2e8f0', fontSize: 12 },
      axisPointer: { type: 'cross', crossStyle: { color: '#cbd5e1' } },
      formatter: (params: any[]) => {
        let html = `<div style="font-weight:600;margin-bottom:4px">${params[0].axisValue}</div>`
        params.forEach((p) => {
          html += `<div style="display:flex;align-items:center;gap:6px"><span style="display:inline-block;width:8px;height:8px;border-radius:50%;background:${p.color}"></span>${p.seriesName}: ${currencySymbol.value}${Number(p.value).toLocaleString()}</div>`
        })
        return html
      },
    },
    legend: { data: ['Revenue', 'Collected'], bottom: 0, textStyle: { fontSize: 11 }, icon: 'roundRect', itemWidth: 14, itemHeight: 10 },
    grid: { left: 65, right: 24, top: 16, bottom: 48 },
    xAxis: {
      type: 'category',
      data: formatted.map((s) => s.label),
      boundaryGap: false,
      axisTick: { show: false },
      axisLine: { lineStyle: { color: '#e2e8f0' } },
      axisLabel: { fontSize: 10, color: '#64748b', rotate: formatted.length > 8 ? 30 : 0 },
    },
    yAxis: {
      type: 'value',
      splitLine: { lineStyle: { color: '#f1f5f9', type: 'dashed' } },
      axisLabel: { color: '#94a3b8', fontSize: 10, formatter: (v: number) => `${currencySymbol.value}${(v / 1000).toFixed(0)}k` },
    },
    series: [
      {
        name: 'Revenue', type: 'line', smooth: true, symbol: 'circle', symbolSize: 6,
        areaStyle: {
          color: { type: 'linear', x: 0, y: 0, x2: 0, y2: 1, colorStops: [
            { offset: 0, color: 'rgba(59, 130, 246, 0.35)' },
            { offset: 1, color: 'rgba(59, 130, 246, 0.02)' },
          ] },
          shadowColor: 'rgba(59, 130, 246, 0.1)', shadowBlur: 10,
        },
        lineStyle: { width: 3, color: '#3b82f6' }, itemStyle: { color: '#3b82f6', borderColor: '#fff', borderWidth: 2 },
        emphasis: { focus: 'series', scale: 1.5 },
        data: formatted.map((s) => Math.round(s.revenue)),
      },
      {
        name: 'Collected', type: 'line', smooth: true, symbol: 'circle', symbolSize: 6,
        areaStyle: {
          color: { type: 'linear', x: 0, y: 0, x2: 0, y2: 1, colorStops: [
            { offset: 0, color: 'rgba(16, 185, 129, 0.35)' },
            { offset: 1, color: 'rgba(16, 185, 129, 0.02)' },
          ] },
          shadowColor: 'rgba(16, 185, 129, 0.1)', shadowBlur: 10,
        },
        lineStyle: { width: 3, color: '#10b981' }, itemStyle: { color: '#10b981', borderColor: '#fff', borderWidth: 2 },
        emphasis: { focus: 'series', scale: 1.5 },
        data: formatted.map((s) => Math.round(s.collected)),
      },
    ],
  }
})

// ── Helpers ──
function dotClass(s: string) {
  return {
    draft: 'dot-grey', active: 'dot-success', overdue: 'dot-warning',
    completed: 'dot-info', cancelled: 'dot-error',
  }[s] || 'dot-grey'
}
function payDotClass(s: string) {
  return { paid: 'dot-success', partial: 'dot-warning', unpaid: 'dot-error' }[s] || 'dot-grey'
}
function periodColor(p: string) {
  return { daily: '#3b82f6', weekly: '#f59e0b', weekend: '#8b5cf6', monthly: '#10b981' }[p] || '#94a3b8'
}
function periodIcon(p: string) {
  return { daily: 'mdi-calendar-today', weekly: 'mdi-calendar-week', weekend: 'mdi-calendar-clock', monthly: 'mdi-calendar-month' }[p] || 'mdi-calendar'
}
function rankColor(i: number) {
  return ['#f59e0b', '#94a3b8', '#a78bfa', '#64748b', '#334155'][i] || '#94a3b8'
}

const _locationPalette = ['#f97316', '#3b82f6', '#10b981', '#8b5cf6', '#ef4444', '#14b8a6', '#ec4899', '#6366f1']
const locIcon = 'mdi-map-marker-radius-outline'
function locColor(idx: number): string {
  return _locationPalette[idx % _locationPalette.length]
}

const _vtPalette = ['#6366f1', '#10b981', '#f59e0b', '#ec4899', '#14b8a6', '#ef4444', '#8b5cf6', '#3b82f6']
function vtColor(idx: number): string {
  return _vtPalette[idx % _vtPalette.length]
}
function vtIcon(vt: string): string {
  const v = (vt || '').toLowerCase()
  if (v.includes('suv') || v.includes('crossover')) return 'mdi-car-suv'
  if (v.includes('van') || v.includes('mini')) return 'mdi-van-passenger'
  if (v.includes('truck') || v.includes('pickup') || v.includes('lorry')) return 'mdi-truck'
  if (v.includes('bus') || v.includes('coaster')) return 'mdi-bus'
  if (v.includes('sedan') || v.includes('saloon')) return 'mdi-car'
  if (v.includes('luxury') || v.includes('premium')) return 'mdi-car-sports'
  return 'mdi-car-estate'
}
</script>

<style scoped>
.kpi-grid { display:grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap:14px; }
.kpi-card { display:flex; align-items:center; gap:14px; background:#fff; border:1px solid #e2e8f0; border-radius:14px; padding:16px 18px; }
.kpi-clickable { cursor:pointer; transition: box-shadow .15s, transform .15s; }
.kpi-clickable:hover { box-shadow: 0 6px 18px rgba(2,6,23,.08); transform: translateY(-1px); }
.kpi-icon { width:44px; height:44px; border-radius:12px; display:flex; align-items:center; justify-content:center; flex-shrink:0; }
.kpi-body { min-width:0; }
.kpi-value { font-size:22px; font-weight:800; color:#0f172a; line-height:1.1; }
.kpi-label { font-size:12px; color:#64748b; font-weight:600; }
.kpi-sub { font-size:11px; display:flex; align-items:center; gap:4px; margin-top:4px; }
.status-grid { display:grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap:14px; }
.status-card { background:#fff; border:1px solid #e2e8f0; border-radius:14px; padding:16px; }
.status-head { display:flex; align-items:center; gap:8px; margin-bottom:12px; }
.status-title { font-weight:700; color:#1e293b; font-size:14px; }
.status-rows { display:flex; flex-direction:column; gap:10px; }
.status-row { cursor:pointer; }
.status-row.active { background:#eef2ff; border-radius:8px; padding:4px 6px; margin:-4px -6px; }
.status-label { font-size:13px; color:#334155; }
.status-count { margin-left:auto; font-weight:700; color:#475569; }
.status-bar { height:8px; border-radius:5px; background:#f1f5f9; margin-top:6px; overflow:hidden; }
.status-bar-fill { height:100%; border-radius:5px; }
.ontrack-body { display:flex; align-items:center; gap:18px; }
.ontrack-pct { font-size:18px; font-weight:800; color:#16a34a; }
.ontrack-pct-unit { font-size:11px; }
.ontrack-stats { display:flex; flex-direction:column; gap:6px; font-size:12px; color:#475569; }
.ontrack-line { display:flex; align-items:center; gap:6px; }
.dot { width:8px; height:8px; border-radius:50%; display:inline-block; }
.dot-grey { background:#94a3b8; } .dot-info { background:#0ea5e9; } .dot-warning { background:#f59e0b; }
.dot-success { background:#16a34a; } .dot-error { background:#dc2626; }
</style>
