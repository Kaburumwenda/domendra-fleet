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
      <!-- Cost by service type -->
      <div class="breakdown-card">
        <div class="breakdown-head">
          <v-icon size="18" color="primary">mdi-chart-donut</v-icon>
          <span class="breakdown-title">Cost by Service Type</span>
        </div>
        <div class="breakdown-rows">
          <div v-for="t in costByType" :key="t.key" class="breakdown-row" :class="{ active: t.key === activeTypeFilter }" @click="onTypeFilter(t.key)">
            <div class="d-flex align-center ga-2 breakdown-label">
              <v-icon size="16" :color="typeColorHex(t.key)">{{ typeIcon(t.key) }}</v-icon>
              <span class="text-capitalize">{{ t.key.replace('_', ' ') }}</span>
              <span class="breakdown-count">{{ t.count }}</span>
            </div>
            <div class="breakdown-bar">
              <div class="breakdown-bar-fill" :style="{ width: t.pct + '%', background: typeColorHex(t.key) }" />
            </div>
            <div class="breakdown-cost">{{ currencySymbol }}{{ money(t.cost) }}</div>
          </div>
          <div v-if="!services.length" class="text-body-2 text-medium-emphasis py-2">No services yet.</div>
        </div>
      </div>

      <!-- Service type distribution (count) -->
      <div class="breakdown-card">
        <div class="breakdown-head">
          <v-icon size="18" color="primary">mdi-chart-bar</v-icon>
          <span class="breakdown-title">Service Type Distribution</span>
        </div>
        <div class="breakdown-rows">
          <div v-for="t in typeCount" :key="t.key" class="breakdown-row" :class="{ active: t.key === activeTypeFilter }" @click="onTypeFilter(t.key)">
            <div class="d-flex align-center ga-2 breakdown-label">
              <span class="dot" :style="{ background: typeColorHex(t.key) }" />
              <span class="text-capitalize">{{ t.key.replace('_', ' ') }}</span>
              <span class="breakdown-count">{{ t.count }}</span>
            </div>
            <div class="breakdown-bar">
              <div class="breakdown-bar-fill" :style="{ width: t.pct + '%', background: typeColorHex(t.key) }" />
            </div>
          </div>
          <div v-if="!services.length" class="text-body-2 text-medium-emphasis py-2">No services yet.</div>
        </div>
      </div>

      <!-- Top vendors by cost -->
      <div class="breakdown-card">
        <div class="breakdown-head">
          <v-icon size="18" color="primary">mdi-account-cash-outline</v-icon>
          <span class="breakdown-title">Top Vendors by Spend</span>
        </div>
        <div class="breakdown-rows">
          <div v-for="v in topVendors" :key="v.name" class="vendor-row" @click="onVendorFilter(v.id)">
            <div class="d-flex align-center ga-2">
              <v-avatar size="30" :color="avatarColor(v.name)" variant="tonal"><span class="text-caption font-weight-bold">{{ initials(v.name) }}</span></v-avatar>
              <div class="flex-grow-1">
                <p class="text-body-2 font-weight-medium">{{ v.name }}</p>
                <p class="text-caption text-medium-emphasis">{{ v.count }} services · avg {{ currencySymbol }}{{ money(v.avg) }}</p>
              </div>
              <v-rating v-if="v.avgRating > 0" :model-value="v.avgRating" readonly half-increments density="compact" size="x-small" />
            </div>
            <div class="breakdown-bar mt-2">
              <div class="breakdown-bar-fill" style="background:#8b5cf6" :style="{ width: v.pct + '%' }" />
            </div>
            <div class="breakdown-cost">{{ currencySymbol }}{{ money(v.total) }}</div>
          </div>
          <div v-if="!topVendors.length" class="text-body-2 text-medium-emphasis py-2">No vendor services yet.</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ services: any[]; currencySymbol: string; activeTypeFilter: string | null }>()
const emit = defineEmits<{ filterType: [key: string]; filterVendor: [id: number] }>()

const money = (v: any) => parseFloat(v || 0).toFixed(2)

const kpiCards = computed(() => {
  const s = props.services || []
  const totalCost = s.reduce((a, x) => a + parseFloat(x.cost || 0), 0)
  const totalDowntime = s.reduce((a, x) => a + (x.downtime_hours || 0), 0)
  const rated = s.filter(x => x.rating).length
  const avgCost = s.length ? totalCost / s.length : 0
  const avgRating = rated ? s.filter(x => x.rating).reduce((a, x) => a + (x.rating.overall_rating || 0), 0) / rated : 0
  return [
    { label: 'Total Services', value: s.length, icon: 'mdi-wrench-clock', gradient: 'linear-gradient(135deg,#6366f1,#4f46e5)', sub: `${distinctVehicles.value} vehicles serviced`, subIcon: 'mdi-truck-multiple', subColor: '#6366f1' },
    { label: 'Total Cost', value: `${props.currencySymbol}${money(totalCost)}`, icon: 'mdi-cash-multiple', gradient: 'linear-gradient(135deg,#0ea5e9,#2563eb)', sub: `avg ${props.currencySymbol}${money(avgCost)}`, subIcon: 'mdi-chart-line', subColor: '#0ea5e9' },
    { label: 'Downtime', value: `${totalDowntime.toFixed(1)}h`, icon: 'mdi-timer-sand', gradient: 'linear-gradient(135deg,#f59e0b,#d97706)', sub: `${(totalDowntime / (s.length || 1)).toFixed(1)}h avg`, subIcon: 'mdi-clock-alert', subColor: '#f59e0b' },
    { label: 'Vendor Ratings', value: rated, icon: 'mdi-star-check', gradient: 'linear-gradient(135deg,#10b981,#059669)', sub: avgRating > 0 ? `${avgRating.toFixed(1)} avg` : 'not rated', subIcon: 'mdi-star', subColor: '#10b981' },
  ]
})

const distinctVehicles = computed(() => new Set((props.services || []).map(s => s.vehicle)).size)

const costByType = computed(() => {
  const map: Record<string, { count: number; cost: number }> = {}
  props.services.forEach(s => {
    const k = s.service_type || 'other'
    if (!map[k]) map[k] = { count: 0, cost: 0 }
    map[k].count++; map[k].cost += parseFloat(s.cost || 0)
  })
  const totalCost = Object.values(map).reduce((a, v) => a + v.cost, 0) || 1
  return Object.entries(map).map(([key, v]) => ({ key, count: v.count, cost: v.cost, pct: Math.round((v.cost / totalCost) * 100) })).sort((a, b) => b.cost - a.cost)
})

const typeCount = computed(() => {
  const map: Record<string, number> = {}
  props.services.forEach(s => { const k = s.service_type || 'other'; map[k] = (map[k] || 0) + 1 })
  const total = props.services.length || 1
  return Object.entries(map).map(([key, count]) => ({ key, count, pct: Math.round((count / total) * 100) })).sort((a, b) => b.count - a.count)
})

const topVendors = computed(() => {
  const map: Record<string, { id: number; name: string; count: number; total: number; ratings: number[] }> = {}
  props.services.forEach(s => {
    if (!s.vendor_name) return
    const key = s.vendor_name
    if (!map[key]) map[key] = { id: s.vendor, name: s.vendor_name, count: 0, total: 0, ratings: [] }
    map[key].count++; map[key].total += parseFloat(s.cost || 0)
    if (s.rating?.overall_rating != null) map[key].ratings.push(s.rating.overall_rating)
  })
  const max = Math.max(...Object.values(map).map(v => v.total), 1)
  return Object.values(map).map(v => ({
    id: v.id, name: v.name, count: v.count, total: v.total,
    avg: v.count ? v.total / v.count : 0,
    avgRating: v.ratings.length ? v.ratings.reduce((a, r) => a + r, 0) / v.ratings.length : 0,
    pct: Math.round((v.total / max) * 100),
  })).sort((a, b) => b.total - a.total).slice(0, 6)
})

function onTypeFilter(k: string) { emit('filterType', props.activeTypeFilter === k ? '' : k) }
function onVendorFilter(id: number) { emit('filterVendor', id) }

function typeColorHex(t: string) { return ({ oil_change: '#f59e0b', tire_rotation: '#3b82f6', brake_service: '#ef4444', inspection: '#16a34a', repair: '#f97316', preventive: '#6366f1', other: '#94a3b8' } as any)[t] || '#94a3b8' }
function typeIcon(t: string) { return ({ oil_change: 'mdi-oil', tire_rotation: 'mdi-tire', brake_service: 'mdi-car-brake-abs', inspection: 'mdi-clipboard-check-outline', repair: 'mdi-wrench', preventive: 'mdi-calendar-sync', other: 'mdi-dots-horizontal' } as any)[t] || 'mdi-wrench' }
function initials(n: string) { return (n || '?').split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase() }
function avatarColor(n: string) { const colors = ['#6366f1', '#0ea5e9', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6']; let h = 0; for (let i = 0; i < n.length; i++) h = n.charCodeAt(i) + ((h << 5) - h); return colors[Math.abs(h) % colors.length] }
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
.breakdown-cost { font-size:11px; color:#64748b; margin-top:3px; text-align:right; font-weight:600; }
.vendor-row { cursor:pointer; border-radius:8px; padding:6px; margin:-4px; transition: background .12s; }
.vendor-row:hover { background:#f8fafc; }
.dot { width:8px; height:8px; border-radius:50%; display:inline-block; }
</style>
