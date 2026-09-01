<template>
  <div class="d-flex flex-column ga-3">
    <!-- KPI cards -->
    <v-row dense>
      <v-col cols="6" md="3">
        <v-card elevation="0" border rounded="lg" class="kpi-card pa-3" :class="{'cursor-pointer': true}" @click="$emit('filterStatus', 'all')">
          <div class="d-flex align-center ga-2">
            <v-avatar size="36" variant="tonal" color="primary"><v-icon>mdi-bell-ring-outline</v-icon></v-avatar>
            <div><p class="text-h5 font-weight-bold text-primary mb-0">{{ reminders.length }}</p><p class="text-caption text-medium-emphasis">Total Reminders</p></div>
          </div>
          <p class="text-caption text-medium-emphasis mt-1"><v-icon size="12">mdi-check-circle</v-icon>{{ activeCount }} active · {{ reminders.length - activeCount }} inactive</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border rounded="lg" class="kpi-card pa-3 cursor-pointer" @click="$emit('filterStatus', 'due')">
          <div class="d-flex align-center ga-2">
            <v-avatar size="36" variant="tonal" color="warning"><v-icon>mdi-bell-alert-outline</v-icon></v-avatar>
            <div><p class="text-h5 font-weight-bold text-warning mb-0">{{ dueCount }}</p><p class="text-caption text-medium-emphasis">Due Now</p></div>
          </div>
          <p class="text-caption text-medium-emphasis mt-1"><v-icon size="12">mdi-clock-alert-outline</v-icon>{{ (dueCount - overdueCount) }} due · {{ overdueCount }} overdue</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border rounded="lg" class="kpi-card pa-3 cursor-pointer" @click="$emit('filterStatus', 'overdue')">
          <div class="d-flex align-center ga-2">
            <v-avatar size="36" variant="tonal" color="error"><v-icon>mdi-alert-octagon-outline</v-icon></v-avatar>
            <div><p class="text-h5 font-weight-bold text-error mb-0">{{ overdueCount }}</p><p class="text-caption text-medium-emphasis">Overdue</p></div>
          </div>
          <p class="text-caption text-medium-emphasis mt-1"><v-icon size="12">mdi-account-clock</v-icon>Needs immediate attention</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border rounded="lg" class="kpi-card pa-3">
          <div class="d-flex align-center ga-2">
            <v-avatar size="36" variant="tonal" color="info"><v-icon>mdi-wrench-clock</v-icon></v-avatar>
            <div><p class="text-h5 font-weight-bold text-info mb-0">{{ autoGenCount }}</p><p class="text-caption text-medium-emphasis">Auto WO</p></div>
          </div>
          <p class="text-caption text-medium-emphasis mt-1"><v-icon size="12">mdi-clipboard-check</v-icon>Auto-generate work orders</p>
        </v-card>
      </v-col>
    </v-row>

    <!-- Breakdown cards -->
    <v-row dense>
      <v-col cols="12" md="4">
        <v-card elevation="0" border rounded="lg" class="pa-3 h-100">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-toggle-switch-outline</v-icon>By Trigger Type</p>
          <div v-for="t in triggerBreakdown" :key="t.key" class="d-flex align-center ga-2 py-1 cursor-pointer" @click="$emit('filterTrigger', t.key)">
            <v-icon size="18" :color="triggerColor(t.key)">{{ triggerIcon(t.key) }}</v-icon>
            <span class="text-body-2 flex-grow-1">{{ t.label }}</span>
            <v-chip size="small" variant="tonal" :color="triggerColor(t.key)">{{ t.count }}</v-chip>
          </div>
          <div v-if="!reminders.length" class="text-center text-caption text-medium-emphasis py-2">No data</div>
        </v-card>
      </v-col>
      <v-col cols="12" md="4">
        <v-card elevation="0" border rounded="lg" class="pa-3 h-100">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-trending-up</v-icon>By Escalation Level</p>
          <div v-for="e in escalationBreakdown" :key="e.key" class="d-flex align-center ga-2 py-1">
            <v-icon size="18" :color="escalationColor(e.key)">{{ escalationIcon(e.key) }}</v-icon>
            <span class="text-body-2 flex-grow-1">{{ e.label }}</span>
            <v-chip size="small" variant="tonal" :color="escalationColor(e.key)">{{ e.count }}</v-chip>
          </div>
          <div v-if="!reminders.length" class="text-center text-caption text-medium-emphasis py-2">No data</div>
        </v-card>
      </v-col>
      <v-col cols="12" md="4">
        <v-card elevation="0" border rounded="lg" class="pa-3 h-100">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-car-multiple</v-icon>Top Vehicles</p>
          <div v-for="v in topVehicles" :key="v.vehicle_name" class="d-flex align-center ga-2 py-1 cursor-pointer" @click="$emit('filterVehicle', v.vehicle_name)">
            <v-avatar size="28" variant="tonal" color="primary"><v-icon size="16">mdi-car</v-icon></v-avatar>
            <span class="text-body-2 flex-grow-1 text-truncate" style="max-width:140px">{{ v.vehicle_name }}</span>
            <v-chip size="small" variant="tonal" color="primary">{{ v.count }}</v-chip>
            <v-chip v-if="v.due" size="x-small" variant="flat" color="warning">{{ v.due }} due</v-chip>
          </div>
          <div v-if="!topVehicles.length" class="text-center text-caption text-medium-emphasis py-2">No data</div>
        </v-card>
      </v-col>
    </v-row>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ reminders: any[]; activeStatusFilter?: string }>()
defineEmits<{ filterStatus: [s: string]; filterTrigger: [t: string]; filterVehicle: [v: string] }>()

const activeCount = computed(() => props.reminders.filter(r => r.is_active).length)
const dueCount = computed(() => props.reminders.filter(r => r.is_due).length)
const overdueCount = computed(() => props.reminders.filter(r => r.is_overdue).length)
const autoGenCount = computed(() => props.reminders.filter(r => r.auto_generate_work_order).length)

const triggerLabels: Record<string, string> = { time: 'Time (Months)', mileage: 'Mileage', engine_hours: 'Engine Hours' }
const triggerBreakdown = computed(() => {
  const map: Record<string, number> = { time: 0, mileage: 0, engine_hours: 0 }
  props.reminders.forEach(r => { if (map[r.trigger_type] != null) map[r.trigger_type]++ })
  return Object.entries(map).map(([k, v]) => ({ key: k, label: triggerLabels[k] || k, count: v }))
})

const escalationLabels: Record<string, string> = { '0': 'None', '1': 'Email Driver', '2': 'SMS Manager', '3': 'Block Dispatch' }
const escalationBreakdown = computed(() => {
  const map: Record<string, number> = { '0': 0, '1': 0, '2': 0, '3': 0 }
  props.reminders.forEach(r => { map[String(r.escalation_level)] = (map[String(r.escalation_level)] || 0) + 1 })
  return Object.entries(map).map(([k, v]) => ({ key: k, label: escalationLabels[k] || k, count: v }))
})

const topVehicles = computed(() => {
  const map: Record<string, { vehicle_name: string; count: number; due: number }> = {}
  props.reminders.forEach(r => {
    const key = r.vehicle_name || '—'
    if (!map[key]) map[key] = { vehicle_name: key, count: 0, due: 0 }
    map[key].count++
    if (r.is_due) map[key].due++
  })
  return Object.values(map).sort((a, b) => b.count - a.count).slice(0, 5)
})

function triggerColor(t: string) { return ({ time: 'primary', mileage: 'warning', engine_hours: 'info' } as any)[t] || 'grey' }
function triggerIcon(t: string) { return ({ time: 'mdi-calendar-clock', mileage: 'mdi-counter', engine_hours: 'mdi-engine-outline' } as any)[t] || 'mdi-bell' }
function escalationColor(k: string) { return ({ '0': 'grey', '1': 'info', '2': 'warning', '3': 'error' } as any)[k] || 'grey' }
function escalationIcon(k: string) { return ({ '0': 'mdi-shield-off-outline', '1': 'mdi-email-alert-outline', '2': 'mdi-cellphone-text', '3': 'mdi-block-helper' } as any)[k] || 'mdi-shield' }
</script>

<style scoped>
.kpi-card { transition: transform .15s, box-shadow .15s; }
.kpi-card:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(2,6,23,.08); }
.cursor-pointer { cursor: pointer; }
</style>
