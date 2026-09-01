<template>
  <div class="kpi-grid">
    <div v-for="c in cards" :key="c.label" class="kpi-card" :class="{ 'kpi-clickable': !!c.click }" @click="c.click?.()">
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
    <div class="status-card">
      <div class="status-head">
        <v-icon size="18" color="primary">mdi-chart-donut</v-icon>
        <span class="status-title">Status Distribution</span>
      </div>
      <div class="status-rows">
        <div v-for="s in statusBreakdown" :key="s.key" class="status-row" :class="{ active: s.key === activeFilter }" @click="$emit('filter', s.key)">
          <div class="d-flex align-center ga-2 status-label">
            <span class="dot" :class="dotClass(s.key)" />
            <span class="text-capitalize">{{ s.key.replace('_', ' ') }}</span>
            <span class="status-count">{{ s.count }}</span>
          </div>
          <div class="status-bar">
            <div class="status-bar-fill" :class="dotClass(s.key)" :style="{ width: s.pct + '%' }" />
          </div>
        </div>
        <div v-if="!total" class="text-body-2 text-medium-emphasis py-2">No jobs yet.</div>
      </div>
    </div>

    <div class="status-card">
      <div class="status-head">
        <v-icon size="18" color="primary"> mdi-flag-outline</v-icon>
        <span class="status-title">Priority Mix</span>
      </div>
      <div class="status-rows">
        <div v-for="p in priorityBreakdown" :key="p.key" class="status-row">
          <div class="d-flex align-center ga-2 status-label">
            <v-icon size="16" :color="priorityColorHex(p.key)"> mdi-flag</v-icon>
            <span class="text-capitalize">{{ p.key }}</span>
            <span class="status-count">{{ p.count }}</span>
          </div>
          <div class="status-bar">
            <div class="status-bar-fill" :style="{ width: p.pct + '%', background: priorityColorHex(p.key) }" />
          </div>
        </div>
        <div v-if="!total" class="text-body-2 text-medium-emphasis py-2">No jobs yet.</div>
      </div>
    </div>

    <div class="status-card">
      <div class="status-head">
        <v-icon size="18" color="primary"> mdi-clock-outline</v-icon>
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
          <div class="ontrack-line"><span class="dot dot-error" /> Delayed: <b>{{ delayedCount }}</b></div>
          <div class="ontrack-line text-medium-emphasis">Completed: <b>{{ completedJobs.length }}</b></div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ jobs: any[]; activeFilter?: string | null }>()
defineEmits<{ filter: [key: string] }>()

const total = computed(() => props.jobs.length)

const cards = computed(() => {
  const j = props.jobs || []
  const open = j.filter(x => x.status === 'pending' || x.status === 'assigned').length
  const active = j.filter(x => x.status === 'in_progress').length
  const done = j.filter(x => x.status === 'completed').length
  const urgent = j.filter(x => x.priority === 'urgent' && x.status !== 'completed' && x.status !== 'cancelled').length
  const assigned = j.filter(x => x.status === 'assigned' || x.status === 'in_progress').length
  const utilization = total.value ? Math.round((assigned / total.value) * 100) : 0
  return [
    { label: 'Total Jobs', value: total.value, icon: 'mdi-clipboard-list-outline', gradient: 'linear-gradient(135deg,#6366f1,#4f46e5)', sub: `${open} open · ${active} active`, subIcon: 'mdi-update', subColor: '#6366f1' },
    { label: 'In Progress', value: active, icon: 'mdi-truck-fast', gradient: 'linear-gradient(135deg,#f59e0b,#d97706)', sub: 'Live tracking', subIcon: 'mdi-radar', subColor: '#f59e0b' },
    { label: 'Completed', value: done, icon: 'mdi-check-circle', gradient: 'linear-gradient(135deg,#10b981,#059669)', sub: 'This period', subIcon: 'mdi-calendar-check', subColor: '#10b981' },
    { label: 'Urgent', value: urgent, icon: 'mdi-alert-octagon', gradient: 'linear-gradient(135deg,#ef4444,#dc2626)', sub: urgent ? 'Needs attention' : 'All clear', subIcon: urgent ? 'mdi-bell-alert' : 'mdi-check', subColor: urgent ? '#ef4444' : '#10b981' },
    { label: 'Fleet Utilization', value: `${utilization}%`, icon: 'mdi-chart-line-variant', gradient: 'linear-gradient(135deg,#0ea5e9,#2563eb)', sub: `${assigned} of ${total.value} assigned`, subIcon: 'mdi-chart-arraw-up', subColor: '#0ea5e9' },
  ]
})

const statusBreakdown = computed(() => {
  const order = ['pending', 'assigned', 'in_progress', 'completed', 'cancelled']
  const counts: Record<string, number> = { pending: 0, assigned: 0, in_progress: 0, completed: 0, cancelled: 0 }
  props.jobs.forEach(j => { if (counts[j.status] != null) counts[j.status]++ })
  const tot = total.value || 1
  return order.map(k => ({ key: k, count: counts[k], pct: Math.round((counts[k] / tot) * 100) }))
})

const priorityBreakdown = computed(() => {
  const order = ['low', 'medium', 'high', 'urgent']
  const counts: Record<string, number> = { low: 0, medium: 0, high: 0, urgent: 0 }
  props.jobs.forEach(j => { if (counts[j.priority] != null) counts[j.priority]++ })
  const tot = total.value || 1
  return order.map(k => ({ key: k, count: counts[k], pct: Math.round((counts[k] / tot) * 100) }))
})

const completedJobs = computed(() => props.jobs.filter(j => j.status === 'completed'))
const onTimeCount = computed(() => completedJobs.value.filter(j => j.is_on_schedule === true).length)
const delayedCount = computed(() => completedJobs.value.filter(j => j.is_on_schedule === false).length)
const onTimeRate = computed(() => {
  const done = completedJobs.value.length
  return done ? Math.round((onTimeCount.value / done) * 100) : 0
})

function dotClass(s: string) {
  return { pending: 'dot-grey', assigned: 'dot-info', in_progress: 'dot-warning', completed: 'dot-success', cancelled: 'dot-error' }[s] || 'dot-grey'
}
function priorityColorHex(p: string) {
  return { low: '#94a3b8', medium: '#f59e0b', high: '#f97316', urgent: '#ef4444' }[p] || '#94a3b8'
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
