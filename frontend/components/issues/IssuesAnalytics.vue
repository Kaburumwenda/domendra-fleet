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
      <!-- Issues by Status -->
      <div class="breakdown-card">
        <div class="breakdown-head">
          <v-icon size="18" color="primary">mdi-chart-donut</v-icon>
          <span class="breakdown-title">Issues by Status</span>
        </div>
        <div class="breakdown-rows">
          <div v-for="s in statusBreakdown" :key="s.key" class="breakdown-row" :class="{ active: s.key === activeStatusFilter }" @click="onStatusFilter(s.key)">
            <div class="d-flex align-center ga-2 breakdown-label">
              <v-icon size="16" :color="statusColorHex(s.key)">{{ statusIcon(s.key) }}</v-icon>
              <span class="text-capitalize">{{ s.key.replace('_', ' ') }}</span>
              <span class="breakdown-count">{{ s.count }}</span>
            </div>
            <div class="breakdown-bar">
              <div class="breakdown-bar-fill" :style="{ width: s.pct + '%', background: statusColorHex(s.key) }" />
            </div>
          </div>
          <div v-if="!issues.length" class="text-body-2 text-medium-emphasis py-2">No issues yet.</div>
        </div>
      </div>

      <!-- Issues by Priority -->
      <div class="breakdown-card">
        <div class="breakdown-head">
          <v-icon size="18" color="primary">mdi-flag-variant-outline</v-icon>
          <span class="breakdown-title">Issues by Priority</span>
        </div>
        <div class="breakdown-rows">
          <div v-for="p in priorityBreakdown" :key="p.key" class="breakdown-row" :class="{ active: p.key === activePriorityFilter }" @click="onPriorityFilter(p.key)">
            <div class="d-flex align-center ga-2 breakdown-label">
              <span class="dot" :style="{ background: priorityColorHex(p.key) }" />
              <span class="text-capitalize">{{ p.key }}</span>
              <span class="breakdown-count">{{ p.count }}</span>
            </div>
            <div class="breakdown-bar">
              <div class="breakdown-bar-fill" :style="{ width: p.pct + '%', background: priorityColorHex(p.key) }" />
            </div>
          </div>
          <div v-if="!issues.length" class="text-body-2 text-medium-emphasis py-2">No issues yet.</div>
        </div>
      </div>

      <!-- Most Affected Vehicles -->
      <div class="breakdown-card">
        <div class="breakdown-head">
          <v-icon size="18" color="primary">mdi-truck-alert-outline</v-icon>
          <span class="breakdown-title">Most Affected Vehicles</span>
        </div>
        <div class="breakdown-rows">
          <div v-for="v in topVehicles" :key="v.name" class="vehicle-row" @click="onVehicleFilter(v.id)">
            <div class="d-flex align-center ga-2">
              <v-avatar size="30" :color="avatarColor(v.name)" variant="tonal"><span class="text-caption font-weight-bold">{{ initials(v.name) }}</span></v-avatar>
              <div class="flex-grow-1">
                <p class="text-body-2 font-weight-medium">{{ v.name }}</p>
                <p class="text-caption text-medium-emphasis">{{ v.open }} open · {{ v.resolved }} resolved</p>
              </div>
              <v-chip size="small" variant="tonal" :color="v.open > 2 ? 'error' : v.open > 0 ? 'warning' : 'success'">{{ v.count }}</v-chip>
            </div>
          </div>
          <div v-if="!topVehicles.length" class="text-body-2 text-medium-emphasis py-2">No issues recorded yet.</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ issues: any[]; activeStatusFilter: string | null; activePriorityFilter: string | null }>()
const emit = defineEmits<{ filterStatus: [key: string]; filterPriority: [key: string]; filterVehicle: [id: number] }>()

const kpiCards = computed(() => {
  const s = props.issues || []
  const open = s.filter(i => i.status === 'open').length
  const inProgress = s.filter(i => ['assigned', 'in_progress', 'parts_ordered'].includes(i.status)).length
  const resolved = s.filter(i => ['resolved', 'closed'].includes(i.status)).length
  const critical = s.filter(i => i.priority === 'critical' && i.status !== 'closed').length
  const withWO = s.filter(i => i.has_work_order).length
  const woPct = s.length ? Math.round((withWO / s.length) * 100) : 0
  return [
    { label: 'Total Issues', value: s.length, icon: 'mdi-alert-circle-outline', gradient: 'linear-gradient(135deg,#6366f1,#4f46e5)', sub: `${open} currently open`, subIcon: 'mdi-alert', subColor: '#6366f1' },
    { label: 'In Progress', value: inProgress, icon: 'mdi-progress-clock', gradient: 'linear-gradient(135deg,#f59e0b,#d97706)', sub: `${critical} critical unresolved`, subIcon: critical > 0 ? 'mdi-alert-octagon' : 'mdi-check-circle', subColor: critical > 0 ? '#ef4444' : '#10b981' },
    { label: 'Resolved', value: resolved, icon: 'mdi-check-decagram', gradient: 'linear-gradient(135deg,#10b981,#059669)', sub: s.length ? `${Math.round((resolved / s.length) * 100)}% resolution rate` : '—', subIcon: 'mdi-chart-line-variant', subColor: '#10b981' },
    { label: 'Work Orders', value: withWO, icon: 'mdi-clipboard-list-outline', gradient: 'linear-gradient(135deg,#0ea5e9,#2563eb)', sub: `${woPct}% of issues`, subIcon: 'mdi-wrench', subColor: '#0ea5e9' },
  ]
})

const statusBreakdown = computed(() => {
  const map: Record<string, number> = {}
  props.issues.forEach(i => { map[i.status] = (map[i.status] || 0) + 1 })
  const total = props.issues.length || 1
  const order = ['open', 'assigned', 'parts_ordered', 'in_progress', 'resolved', 'closed']
  return order.map(k => ({ key: k, count: map[k] || 0, pct: Math.round(((map[k] || 0) / total) * 100) })).filter(x => x.count > 0 || true)
})

const priorityBreakdown = computed(() => {
  const map: Record<string, number> = {}
  props.issues.forEach(i => { map[i.priority] = (map[i.priority] || 0) + 1 })
  const total = props.issues.length || 1
  const order = ['low', 'medium', 'high', 'critical']
  return order.map(k => ({ key: k, count: map[k] || 0, pct: Math.round(((map[k] || 0) / total) * 100) }))
})

const topVehicles = computed(() => {
  const map: Record<string, { id: number; name: string; count: number; open: number; resolved: number }> = {}
  props.issues.forEach(i => {
    const name = i.vehicle_name || 'Unknown'
    if (!map[name]) map[name] = { id: i.vehicle, name, count: 0, open: 0, resolved: 0 }
    map[name].count++
    if (i.status === 'open') map[name].open++
    if (['resolved', 'closed'].includes(i.status)) map[name].resolved++
  })
  return Object.values(map).sort((a, b) => b.count - a.count).slice(0, 5)
})

function onStatusFilter(k: string) { emit('filterStatus', k) }
function onPriorityFilter(k: string) { emit('filterPriority', k) }
function onVehicleFilter(id: number) { emit('filterVehicle', id) }

function statusColorHex(s: string) {
  return ({ open: '#3b82f6', assigned: '#6366f1', parts_ordered: '#f59e0b', in_progress: '#f97316', resolved: '#10b981', closed: '#94a3b8' } as any)[s] || '#94a3b8'
}
function statusIcon(s: string) {
  return ({ open: 'mdi-alert-circle-outline', assigned: 'mdi-account-check-outline', parts_ordered: 'mdi-package-variant-closed', in_progress: 'mdi-progress-clock', resolved: 'mdi-check-circle', closed: 'mdi-lock-check-outline' } as any)[s] || 'mdi-alert'
}
function priorityColorHex(p: string) {
  return ({ low: '#94a3b8', medium: '#eab308', high: '#f97316', critical: '#ef4444' } as any)[p] || '#94a3b8'
}
function initials(n: string) { return (n || '?').split(' ').map((w: string) => w[0]).slice(0, 2).join('').toUpperCase() }
function avatarColor(n: string) { const cs = ['#6366f1', '#0ea5e9', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6']; let h = 0; for (let i = 0; i < n.length; i++) h = n.charCodeAt(i) + ((h << 5) - h); return cs[Math.abs(h) % cs.length] }
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
.dot { width:10px; height:10px; border-radius:50%; flex-shrink:0; }
.vehicle-row { cursor:pointer; border-radius:8px; padding:6px; margin:-6px; transition: background .12s; }
.vehicle-row:hover { background:#f8fafc; }
</style>
