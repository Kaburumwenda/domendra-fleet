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
                  <v-icon :color="col.color" size="18" class="mt-0">{{ col.icon }}</v-icon>
                  <span class="text-body-2 font-weight-bold flex-grow-1 text-truncate">{{ r.form_name || 'Ad-hoc' }}</span>
                </div>
                <p class="text-caption text-medium-emphasis mb-2"><v-icon size="12">mdi-car</v-icon>{{ r.vehicle_name }}</p>
                <div class="d-flex align-center ga-1 flex-wrap mb-1">
                  <v-chip v-if="r.responses?.some((x:any) => x.is_fail && x.is_critical)" size="x-small" variant="flat" color="error">Critical Fail</v-chip>
                  <v-chip v-if="r.responses?.length" size="x-small" variant="tonal" color="primary">{{ r.responses.filter((x:any) => x.is_fail).length }} / {{ r.responses.length }} items</v-chip>
                </div>
                <div class="text-caption text-medium-emphasis">
                  <v-icon size="12">mdi-account</v-icon>{{ r.driver_name || 'Unassigned' }}
                  <span class="ml-2"><v-icon size="12">mdi-calendar</v-icon> {{ fmtDate(r.submitted_at) }}</span>
                </div>
                <div v-if="r.odometer_reading" class="text-caption text-medium-emphasis mt-0">
                  <v-icon size="12">mdi-counter</v-icon>{{ r.odometer_reading.toLocaleString() }} mi
                </div>
              </div>
            </v-card>
            <div v-if="!col.items.length" class="text-center text-caption text-medium-emphasis py-6">
              <v-icon size="32" color="grey-lighten-2">mdi-inbox-outline</v-icon>
              <p class="mt-1">No inspections</p>
            </div>
          </div>
        </div>
      </v-col>
    </v-row>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ reports: any[] }>()
defineEmits<{ openDetail: [r: any] }>()

const columns = computed(() => [
  { key: 'draft', title: 'Draft', color: '#94a3b8', icon: 'mdi-pencil-outline', items: props.reports.filter(r => r.status === 'draft') },
  { key: 'pass', title: 'Passed', color: '#22c55e', icon: 'mdi-check-decagram', items: props.reports.filter(r => r.status === 'pass') },
  { key: 'conditional', title: 'Conditional', color: '#f59e0b', icon: 'mdi-alert-circle', items: props.reports.filter(r => r.status === 'conditional') },
  { key: 'fail', title: 'Failed', color: '#ef4444', icon: 'mdi-close-circle', items: props.reports.filter(r => r.status === 'fail') },
])

function fmtDate(d?: string) { if (!d) return '—'; return new Date(d).toLocaleDateString([], { month: 'short', day: 'numeric' }) }
</script>

<style scoped>
.kanban-col { border-top: 3px solid #ccc; background: #f8fafc; border-radius: 12px; padding: 12px; min-height: 240px; }
.kanban-list { min-height: 180px; }
.kanban-card { transition: transform .15s, box-shadow .15s; }
.kanban-card:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(2,6,23,.08); }
.kanban-card-draft { border-left: 3px solid #94a3b8; }
.kanban-card-pass { border-left: 3px solid #22c55e; }
.kanban-card-conditional { border-left: 3px solid #f59e0b; }
.kanban-card-fail { border-left: 3px solid #ef4444; }
.cursor-pointer { cursor: pointer; }
</style>
