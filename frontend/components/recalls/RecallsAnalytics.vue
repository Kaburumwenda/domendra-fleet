<template>
  <v-row dense>
    <!-- Total -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100" @click="$emit('filterStatus', '')" :class="{ active: activeStatusFilter === '' }">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" style="background: #f0f7ff; color: #3b82f6">
            <v-icon size="24">mdi-car-info</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0">{{ stats.total || 0 }}</p>
            <p class="text-caption text-medium-emphasis mb-0">Total Recalls</p>
          </div>
        </div>
        <div class="stat-sub"><v-icon size="14">mdi-shield-alert</v-icon> {{ stats.critical || 0 }} critical</div>
      </v-card>
    </v-col>

    <!-- Open -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100 cursor-pointer" @click="$emit('filterStatus', 'open')" :class="{ active: activeStatusFilter === 'open' }">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" style="background: #fef2f2; color: #ef4444">
            <v-icon size="24">mdi-alert-circle-outline</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0" style="color: #ef4444">{{ stats.by_status?.open || 0 }}</p>
            <p class="text-caption text-medium-emphasis mb-0">Open</p>
          </div>
        </div>
        <div class="stat-sub"><v-icon size="14">mdi-clock-alert</v-icon> Awaiting action</div>
      </v-card>
    </v-col>

    <!-- In Progress -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100 cursor-pointer" @click="$emit('filterStatus', 'in_progress')" :class="{ active: activeStatusFilter === 'in_progress' }">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" style="background: #fffbeb; color: #f59e0b">
            <v-icon size="24">mdi-progress-wrench</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0" style="color: #f59e0b">{{ stats.by_status?.in_progress || 0 }}</p>
            <p class="text-caption text-medium-emphasis mb-0">In Progress</p>
          </div>
        </div>
        <div class="stat-sub"><v-icon size="14">mdi-wrench</v-icon> Active campaigns</div>
      </v-card>
    </v-col>

    <!-- Resolution Rate -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" style="background: #f0fdf4; color: #22c55e">
            <v-icon size="24">mdi-check-decagram</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0" style="color: #22c55e">{{ stats.resolution_rate || 0 }}%</p>
            <p class="text-caption text-medium-emphasis mb-0">Resolution Rate</p>
          </div>
        </div>
        <div class="stat-sub"><v-icon size="14">mdi-car-multiple</v-icon> {{ stats.resolved_vehicles || 0 }}/{{ stats.affected_vehicles || 0 }} vehicles</div>
      </v-card>
    </v-col>

    <!-- Breakdown Row -->
    <v-col cols="12">
      <v-card elevation="0" border rounded="lg" class="pa-4">
        <v-row dense>
          <!-- By Type -->
          <v-col cols="12" md="6">
            <p class="text-subtitle-2 font-weight-bold mb-3"><v-icon size="16" class="mr-1">mdi-format-list-bulleted-type</v-icon>By Recall Type</p>
            <div class="d-flex flex-wrap ga-2">
              <div v-for="t in recallTypes" :key="t.value" class="type-chip" :class="{ active: false }">
                <v-icon size="16" :color="typeColor(t.value)">{{ typeIcon(t.value) }}</v-icon>
                <span class="text-body-2 font-weight-medium">{{ t.label }}</span>
                <v-chip size="x-small" variant="flat" :color="typeColor(t.value)">{{ stats.by_type?.[t.value] || 0 }}</v-chip>
              </div>
            </div>
          </v-col>

          <!-- By Status -->
          <v-col cols="12" md="6">
            <p class="text-subtitle-2 font-weight-bold mb-3"><v-icon size="16" class="mr-1">mdi-chart-donut</v-icon>By Status</p>
            <div class="d-flex flex-wrap ga-2">
              <div v-for="s in recallStatuses" :key="s.value" class="type-chip cursor-pointer" @click="$emit('filterStatus', s.value)" :class="{ active: activeStatusFilter === s.value }">
                <v-icon size="16" :color="statusColor(s.value)">{{ statusIcon(s.value) }}</v-icon>
                <span class="text-body-2 font-weight-medium">{{ s.label }}</span>
                <v-chip size="x-small" variant="flat" :color="statusColor(s.value)">{{ stats.by_status?.[s.value] || 0 }}</v-chip>
              </div>
            </div>
          </v-col>
        </v-row>

        <!-- By Vehicle -->
        <div v-if="stats.by_vehicle?.length" class="mt-4">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-car-multiple</v-icon>Affected Vehicles (total · resolved · critical)</p>
          <div class="d-flex flex-wrap ga-2">
            <div v-for="v in stats.by_vehicle" :key="v.vehicle_name" class="vehicle-chip">
              <v-icon size="14">mdi-car</v-icon>
              <span class="text-body-2 font-weight-medium">{{ v.vehicle_name }}</span>
              <v-chip size="x-small" variant="flat" color="primary">{{ v.total }}</v-chip>
              <v-chip v-if="v.resolved" size="x-small" variant="flat" color="success">{{ v.resolved }}</v-chip>
              <v-chip v-if="v.critical" size="x-small" variant="flat" color="error">{{ v.critical }}</v-chip>
            </div>
          </div>
        </div>
      </v-card>
    </v-col>
  </v-row>
</template>

<script setup lang="ts">
const props = defineProps<{ stats: any; activeStatusFilter?: string }>()
defineEmits<{ filterStatus: [v: string] }>()

const recallTypes = [
  { label: 'Safety Recall', value: 'safety_recall' },
  { label: 'Service Campaign', value: 'campaign' },
  { label: 'Field Notice', value: 'field_notice' },
  { label: 'Emission', value: 'emission' },
]
const recallStatuses = [
  { label: 'Open', value: 'open' },
  { label: 'In Progress', value: 'in_progress' },
  { label: 'Completed', value: 'completed' },
  { label: 'Closed', value: 'closed' },
]

function typeColor(t: string) { return ({ safety_recall: 'error', campaign: 'warning', field_notice: 'info', emission: 'success' } as any)[t] || 'grey' }
function typeIcon(t: string) { return ({ safety_recall: 'mdi-shield-alert', campaign: 'mdi-bullhorn', field_notice: 'mdi-file-alert', emission: 'mdi-leaf' } as any)[t] || 'mdi-car-info' }
function statusColor(s: string) { return ({ open: 'error', in_progress: 'warning', completed: 'success', closed: 'grey' } as any)[s] || 'grey' }
function statusIcon(s: string) { return ({ open: 'mdi-alert-circle', in_progress: 'mdi-progress-wrench', completed: 'mdi-check-circle', closed: 'mdi-close-circle' } as any)[s] || 'mdi-circle-outline' }
</script>

<style scoped>
.stat-card { border-radius: 12px; cursor: pointer; transition: all .2s; }
.stat-card:hover { border-color: #c7d2fe; box-shadow: 0 2px 8px rgba(99,102,241,.08); }
.stat-card.active { border-color: #6366f1; box-shadow: 0 0 0 2px rgba(99,102,241,.15); }
.stat-icon { width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.stat-sub { display: flex; align-items: center; gap: 4px; padding: 0 16px 10px; font-size: 12px; color: #64748b; }
.type-chip { display: flex; align-items: center; gap: 6px; padding: 6px 10px; border-radius: 10px; background: #f8fafc; border: 1px solid #e2e8f0; transition: all .15s; }
.type-chip.active { border-color: #6366f1; background: #f0f7ff; }
.vehicle-chip { display: flex; align-items: center; gap: 4px; padding: 4px 10px; border-radius: 10px; background: #fafafa; border: 1px solid #f1f5f9; }
</style>
