<template>
  <div>
    <v-row dense>
      <v-col v-for="col in columns" :key="col.key" cols="12" md="3">
        <div class="kanban-col" :style="{ borderTopColor: col.color }">
          <div class="d-flex align-center ga-2 mb-3 px-1">
            <v-icon :color="col.color" size="20">{{ col.icon }}</v-icon>
            <span class="text-subtitle-2 font-weight-bold">{{ col.title }}</span>
            <v-chip size="small" variant="tonal" :color="col.color" class="ml-auto">{{ col.items.length }}</v-chip>
          </div>
          <div class="kanban-list">
            <v-card
              v-for="r in col.items" :key="r.id"
              elevation="0" border rounded="lg" class="kanban-card mb-2 cursor-pointer"
              :class="'kanban-card-' + col.key"
              @click="$emit('openDetail', r)"
            >
              <div class="pa-3">
                <div class="d-flex align-start ga-2 mb-1">
                  <v-icon :color="triggerColor(r.trigger_type)" size="18" class="mt-0">{{ triggerIcon(r.trigger_type) }}</v-icon>
                  <span class="text-body-2 font-weight-bold flex-grow-1 text-truncate">{{ r.title }}</span>
                </div>
                <p class="text-caption text-medium-emphasis mb-2"><v-icon size="12">mdi-car</v-icon>{{ r.vehicle_name }}</p>
                <div class="d-flex align-center ga-1 flex-wrap">
                  <v-chip size="x-small" variant="tonal" :color="triggerColor(r.trigger_type)">{{ triggerLabel(r.trigger_type) }}</v-chip>
                  <v-chip v-if="r.is_overdue" size="x-small" variant="flat" color="error">Overdue</v-chip>
                  <v-chip size="x-small" variant="tonal" :color="escalationColor(r.escalation_level)">{{ escalationLabel(r.escalation_level) }}</v-chip>
                </div>
                <div class="text-caption text-medium-emphasis mt-2">
                  <template v-if="r.trigger_type === 'time'"><v-icon size="12">mdi-calendar</v-icon> {{ fmtDate(r.next_due_date) }}</template>
                  <template v-else-if="r.trigger_type === 'mileage'"><v-icon size="12">mdi-counter</v-icon> {{ r.next_due_mileage?.toLocaleString() }} mi</template>
                  <template v-else><v-icon size="12">mdi-engine</v-icon> {{ r.next_due_engine_hours?.toLocaleString() }} hrs</template>
                  <span v-if="!r.is_active" class="ml-2"><v-icon size="12" color="grey">mdi-pause-circle</v-icon></span>
                  <span v-if="r.auto_generate_work_order" class="ml-1"><v-icon size="12" color="info">mdi-clipboard-plus</v-icon></span>
                </div>
              </div>
            </v-card>
            <div v-if="!col.items.length" class="text-center text-caption text-medium-emphasis py-6">
              <v-icon size="32" color="grey-lighten-2">mdi-inbox-outline</v-icon>
              <p class="mt-1">No reminders</p>
            </div>
          </div>
        </div>
      </v-col>
    </v-row>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ reminders: any[] }>()
defineEmits<{ openDetail: [r: any] }>()

const columns = computed(() => [
  { key: 'overdue', title: 'Overdue', color: '#ef4444', icon: 'mdi-alert-octagon-outline', items: props.reminders.filter(r => r.is_overdue) },
  { key: 'due', title: 'Due Now', color: '#f59e0b', icon: 'mdi-bell-alert-outline', items: props.reminders.filter(r => r.is_due && !r.is_overdue) },
  { key: 'upcoming', title: 'Upcoming', color: '#3b82f6', icon: 'mdi-clock-outline', items: props.reminders.filter(r => !r.is_due && r.is_active) },
  { key: 'scheduled', title: 'Scheduled', color: '#94a3b8', icon: 'mdi-calendar-blank-outline', items: props.reminders.filter(r => !r.is_due && !r.is_active) },
])

function triggerColor(t: string) { return ({ time: 'primary', mileage: 'warning', engine_hours: 'info' } as any)[t] || 'grey' }
function triggerIcon(t: string) { return ({ time: 'mdi-calendar-clock', mileage: 'mdi-counter', engine_hours: 'mdi-engine-outline' } as any)[t] || 'mdi-bell' }
function triggerLabel(t: string) { return ({ time: 'Time', mileage: 'Mileage', engine_hours: 'Engine Hrs' } as any)[t] || '—' }
function escalationColor(e: number) { return ({ 0: 'grey',  1: 'info', 2: 'warning', 3: 'error' } as any)[e] || 'grey' }
function escalationLabel(e: number) { return ({ 0: 'None', 1: 'Email', 2: 'SMS', 3: 'Block' } as any)[e] || 'None' }
function fmtDate(d?: string) { if (!d) return '—'; return new Date(d).toLocaleDateString([], { month: 'short', day: 'numeric' }) }
</script>

<style scoped>
.kanban-col { border-top: 3px solid #ccc; background: #f8fafc; border-radius: 12px; padding: 12px; min-height: 240px; }
.kanban-list { min-height: 180px; }
.kanban-card { transition: transform .15s, box-shadow .15s; }
.kanban-card:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(2,6,23,.08); }
.kanban-card-overdue { border-left: 3px solid #ef4444; }
.kanban-card-due { border-left: 3px solid #f59e0b; }
.kanban-card-upcoming { border-left: 3px solid #3b82f6; }
.kanban-card-scheduled { border-left: 3px solid #94a3b8; }
.cursor-pointer { cursor: pointer; }
</style>
