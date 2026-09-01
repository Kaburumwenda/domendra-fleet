<template>
  <div class="d-flex flex-column ga-4">
    <!-- Primary KPI cards -->
    <div class="kpi-grid">
      <div v-for="c in kpiCards" :key="c.label" class="kpi-card">
        <div class="kpi-icon" :style="{ background: c.gradient }">
          <v-icon size="22" color="white">{{ c.icon }}</v-icon>
        </div>
        <div class="kpi-body">
          <div class="kpi-value">{{ c.value }}</div>
          <div class="kpi-label">{{ c.label }}</div>
          <div v-if="c.sub" class="kpi-sub" :style="{ color: c.subColor }">
            <v-icon v-if="c.subIcon" size="13">{{ c.subIcon }}</v-icon>
            {{ c.sub }}
          </div>
        </div>
      </div>
    </div>

    <!-- Breakdown cards -->
    <div class="breakdown-grid">
      <!-- WOs by Status -->
      <div class="breakdown-card">
        <div class="breakdown-head">
          <v-icon size="18" color="primary">mdi-chart-donut</v-icon>
          <span class="breakdown-title">Work Orders by Status</span>
        </div>
        <div class="breakdown-rows">
          <div v-for="s in statusBreakdown" :key="s.key" class="breakdown-row" :class="{ active: s.key === activeStatusFilter }" @click="$emit('filterStatus', s.key)">
            <div class="d-flex align-center ga-2 breakdown-label">
              <v-icon size="16" :color="statusColorHex(s.key)">{{ statusIcon(s.key) }}</v-icon>
              <span class="text-capitalize">{{ s.key.replace('_', ' ') }}</span>
              <span class="breakdown-count">{{ s.count }}</span>
            </div>
            <div class="breakdown-bar">
              <div class="breakdown-bar-fill" :style="{ width: s.pct + '%', background: statusColorHex(s.key) }" />
            </div>
          </div>
          <div v-if="!workOrders.length" class="text-body-2 text-medium-emphasis py-2">No work orders yet.</div>
        </div>
      </div>

      <!-- Cost breakdown -->
      <div class="breakdown-card">
        <div class="breakdown-head">
          <v-icon size="18" color="primary">mdi-cash-multiple</v-icon>
          <span class="breakdown-title">Cost Breakdown</span>
        </div>
        <div class="breakdown-rows">
          <div class="cost-row">
            <div class="d-flex align-center ga-2 breakdown-label">
              <v-icon size="16" color="primary">mdi-clipboard-text-outline</v-icon>
              <span>Estimated</span>
            </div>
            <div class="breakdown-cost">{{ currencySymbol }}{{ money(costSummary.estimated) }}</div>
          </div>
          <div class="cost-row">
            <div class="d-flex align-center ga-2 breakdown-label">
              <v-icon size="16" color="success">mdi-check-circle</v-icon>
              <span>Actual</span>
            </div>
            <div class="breakdown-cost">{{ currencySymbol }}{{ money(costSummary.actual) }}</div>
          </div>
          <div class="cost-row">
            <div class="d-flex align-center ga-2 breakdown-label">
              <v-icon size="16" color="warning">mdi-package-variant-closed</v-icon>
              <span>Parts</span>
            </div>
            <div class="breakdown-cost">{{ currencySymbol }}{{ money(costSummary.parts) }}</div>
          </div>
          <div class="cost-row">
            <div class="d-flex align-center ga-2 breakdown-label">
              <v-icon size="16" color="info">mdi-account-hard-hat</v-icon>
              <span>Labor</span>
            </div>
            <div class="breakdown-cost">{{ currencySymbol }}{{ money(costSummary.labor) }}</div>
          </div>
          <v-divider class="my-1" />
          <div class="cost-row total">
            <div class="d-flex align-center ga-2 breakdown-label">
              <v-icon size="18" color="success">mdi-cash-plus</v-icon>
              <span class="font-weight-bold">Total Cost</span>
            </div>
            <div class="breakdown-cost font-weight-bold text-success">{{ currencySymbol }}{{ money(costSummary.total) }}</div>
          </div>
        </div>
      </div>

      <!-- Assignment breakdown -->
      <div class="breakdown-card">
        <div class="breakdown-head">
          <v-icon size="18" color="primary">mdi-account-group-outline</v-icon>
          <span class="breakdown-title">By Assignment Type</span>
        </div>
        <div class="breakdown-rows">
          <div v-for="a in assignmentBreakdown" :key="a.key" class="breakdown-row">
            <div class="d-flex align-center ga-2 breakdown-label">
              <v-icon size="16" :color="a.key === 'internal' ? 'primary' : 'deep-purple'">{{ a.key === 'internal' ? 'mdi-account-wrench' : 'mdi-store' }}</v-icon>
              <span class="text-capitalize">{{ a.key === 'internal' ? 'Internal Mechanic' : 'External Shop' }}</span>
              <span class="breakdown-count">{{ a.count }}</span>
            </div>
            <div class="breakdown-bar">
              <div class="breakdown-bar-fill" :style="{ width: a.pct + '%', background: a.key === 'internal' ? '#6366f1' : '#8b5cf6' }" />
            </div>
          </div>
          <v-divider class="my-2" />
          <div class="d-flex ga-2 mt-1">
            <div class="stat-mini"><v-icon size="14" color="warning">mdi-timer-sand</v-icon><p class="stat-mini-value">{{ costSummary.downtime }}h</p><p class="stat-mini-label">Downtime</p></div>
            <div class="stat-mini"><v-icon size="14" color="info">mdi-clock-outline</v-icon><p class="stat-mini-value">{{ costSummary.timeHours }}h</p><p class="stat-mini-label">Labor Hrs</p></div>
            <div class="stat-mini"><v-icon size="14" color="success">mdi-check-decagram</v-icon><p class="stat-mini-value">{{ completionRate }}%</p><p class="stat-mini-label">Done Rate</p></div>
          </div>
          <div v-if="!workOrders.length" class="text-body-2 text-medium-emphasis py-2">No work orders yet.</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ workOrders: any[]; currencySymbol: string; activeStatusFilter: string | null }>()
defineEmits<{ filterStatus: [key: string] }>()

const money = (v: any) => parseFloat(v || 0).toFixed(2)

const kpiCards = computed(() => {
  const w = props.workOrders || []
  const active = w.filter(x => ['assigned', 'in_progress'].includes(x.status)).length
  const completed = w.filter(x => ['completed', 'closed'].includes(x.status)).length
  const totalCost = w.reduce((a, x) => a + parseFloat(x.total_cost || 0), 0)
  const totalDowntime = w.reduce((a, x) => a + (x.downtime_hours || 0), 0)
  const estTotal = w.reduce((a, x) => a + parseFloat(x.estimated_cost || 0), 0)
  const completionRate = w.length ? Math.round((completed / w.length) * 100) : 0
  return [
    { label: 'Total Work Orders', value: w.length, icon: 'mdi-clipboard-list-outline', gradient: 'linear-gradient(135deg,#6366f1,#4f46e5)', sub: `${active} active · ${completed} done`, subIcon: 'mdi-progress-clock', subColor: '#6366f1' },
    { label: 'Active', value: active, icon: 'mdi-progress-clock', gradient: 'linear-gradient(135deg,#f59e0b,#d97706)', sub: `${w.filter(x => x.status === 'in_progress').length} in progress`, subIcon: 'mdi-wrench', subColor: '#f59e0b' },
    { label: 'Total Cost', value: `${props.currencySymbol}${money(totalCost)}`, icon: 'mdi-cash-multiple', gradient: 'linear-gradient(135deg,#0ea5e9,#2563eb)', sub: `${props.currencySymbol}${money(estTotal)} estimated`, subIcon: 'mdi-chart-line', subColor: '#0ea5e9' },
    { label: 'Completion Rate', value: `${completionRate}%`, icon: 'mdi-check-decagram', gradient: 'linear-gradient(135deg,#10b981,#059669)', sub: `${totalDowntime.toFixed(1)}h total downtime`, subIcon: 'mdi-timer-sand', subColor: '#10b981' },
  ]
})

const statusBreakdown = computed(() => {
  const map: Record<string, number> = {}
  props.workOrders.forEach(w => { map[w.status] = (map[w.status] || 0) + 1 })
  const total = props.workOrders.length || 1
  const order = ['open', 'assigned', 'parts_ordered', 'in_progress', 'on_hold', 'completed', 'closed']
  return order.map(k => ({ key: k, count: map[k] || 0, pct: Math.round(((map[k] || 0) / total) * 100) }))
})

const costSummary = computed(() => {
  const w = props.workOrders || []
  return {
    estimated: w.reduce((a, x) => a + parseFloat(x.estimated_cost || 0), 0),
    actual: w.reduce((a, x) => a + parseFloat(x.actual_cost || 0), 0),
    parts: w.reduce((a, x) => a + parseFloat(x.parts_cost || 0), 0),
    labor: w.reduce((a, x) => a + parseFloat(x.labor_cost || 0), 0),
    total: w.reduce((a, x) => a + parseFloat(x.total_cost || 0), 0),
    downtime: w.reduce((a, x) => a + (x.downtime_hours || 0), 0).toFixed(1),
    timeHours: w.reduce((acc, x) => acc + (x.time_logs?.reduce((t, l) => t + (l.hours || 0), 0) || 0), 0).toFixed(1),
  }
})

const completionRate = computed(() => {
  const w = props.workOrders || []
  if (!w.length) return 0
  return Math.round((w.filter(x => ['completed', 'closed'].includes(x.status)).length / w.length) * 100)
})

const assignmentBreakdown = computed(() => {
  const map: Record<string, number> = { internal: 0, external: 0 }
  props.workOrders.forEach(w => { map[w.assignment_type] = (map[w.assignment_type] || 0) + 1 })
  const total = props.workOrders.length || 1
  return [
    { key: 'internal', count: map.internal, pct: Math.round((map.internal / total) * 100) },
    { key: 'external', count: map.external, pct: Math.round((map.external / total) * 100) },
  ]
})

function statusColorHex(s: string) {
  return ({ open: '#3b82f6', assigned: '#6366f1', parts_ordered: '#f59e0b', in_progress: '#f97316', on_hold: '#a78bfa', completed: '#10b981', closed: '#94a3b8' } as any)[s] || '#94a3b8'
}
function statusIcon(s: string) {
  return ({ open: 'mdi-clipboard-outline', assigned: 'mdi-account-check-outline', parts_ordered: 'mdi-package-variant-closed', in_progress: 'mdi-wrench', on_hold: 'mdi-pause-circle', completed: 'mdi-check-circle', closed: 'mdi-lock-check-outline' } as any)[s] || 'mdi-clipboard'
}
</script>

<style scoped>
.kpi-grid { display:grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap:14px; }
.kpi-card { display:flex; align-items:center; gap:14px; background:#fff; border:1px solid #e2e8f0; border-radius:14px; padding:16px 18px; }
.kpi-icon { width:44px; height:44px; border-radius:12px; display:flex; align-items:center; justify-content:center; flex-shrink:0; }
.kpi-body { min-width:0; }
.kpi-value { font-size:22px; font-weight:800; color:#0f172a; line-height:1.1; }
.kpi-label { font-size:12px; color:#64748b; font-weight:600; }
.kpi-sub { font-size:11px; display:flex; align-items:center; gap:4px; margin-top:4px; }
.breakdown-grid { display:grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap:14px; }
.breakdown-card { background:#fff; border:1px solid #e2e8f0; border-radius:14px; padding:16px; }
.breakdown-head { display:flex; align-items:center; gap:8px; margin-bottom:12px; }
.breakdown-title { font-weight:700; color:#1e293b; font-size:14px; }
.breakdown-rows { display:flex; flex-direction:column; gap:10px; }
.breakdown-row { cursor:pointer; border-radius:8px; padding:4px 6px; margin:-4px -6px; transition: background .12s; }
.breakdown-row:hover { background:#f8fafc; }
.breakdown-row.active { background:#eef2ff; }
.breakdown-label { font-size:13px; color:#334155; }
.breakdown-count { margin-left:auto; font-weight:700; color:#475569; font-size:12px; }
.breakdown-bar { height:8px; border-radius:5px; background:#f1f5f9; margin-top:6px; overflow:hidden; }
.breakdown-bar-fill { height:100%; border-radius:5px; }
.breakdown-cost { font-size:13px; color:#1e293b; margin-top:3px; text-align:right; font-weight:600; }
.cost-row { display:flex; align-items:center; justify-content:space-between; padding:4px 0; }
.cost-row.total { padding:8px 0 2px; }
.stat-mini { text-align:center; flex:1; }
.stat-mini-value { font-size:15px; font-weight:800; color:#0f172a; margin-top:2px; }
.stat-mini-label { font-size:10px; color:#64748b; font-weight:600; text-transform:uppercase; letter-spacing:.04em; }
</style>
