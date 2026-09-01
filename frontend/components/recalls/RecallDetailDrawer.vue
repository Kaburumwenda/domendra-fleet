<template>
  <v-navigation-drawer :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" location="right" width="500" temporary style="top:0; height:100vh; z-index:1000">
    <div v-if="recall" class="d-flex flex-column h-100">
      <!-- Header -->
      <div class="drawer-head">
        <div class="d-flex align-center ga-2 mb-2">
          <v-chip :color="statusColor(recall.status)" variant="flat" size="small">
            <v-icon start size="14">{{ statusIcon(recall.status) }}</v-icon>{{ statusLabel(recall.status) }}
          </v-chip>
          <v-chip :color="typeColor(recall.recall_type)" variant="tonal" size="small" class="text-capitalize">
            <v-icon start size="14">{{ typeIcon(recall.recall_type) }}</v-icon>{{ typeLabel(recall.recall_type) }}
          </v-chip>
          <v-chip v-if="recall.is_critical" color="error" variant="flat" size="small"><v-icon start size="14">mdi-alert</v-icon>Critical</v-chip>
        </div>
        <div class="d-flex align-center">
          <h2 class="text-h6 font-weight-bold flex-grow-1">{{ recall.title }}</h2>
          <v-btn icon variant="text" size="small" @click="$emit('update:modelValue', false)"><v-icon>mdi-close</v-icon></v-btn>
        </div>
        <div class="d-flex flex-wrap ga-1 mt-2">
          <span class="text-caption text-medium-emphasis mr-2"><v-icon size="14">mdi-factory</v-icon> {{ recall.oem || '—' }}</span>
          <span class="text-caption text-medium-emphasis mr-2"><v-icon size="14">mdi-wrench</v-icon> {{ recall.component || '—' }}</span>
        </div>
      </div>
      <v-divider />

      <div class="drawer-body">
        <!-- Campaign Numbers -->
        <div class="info-grid">
          <div class="info-item">
            <v-icon size="18" color="medium-emphasis">mdi-card-account-details</v-icon>
            <div><p class="text-caption text-medium-emphasis">NHTSA #</p><p class="text-body-2 font-weight-medium">{{ recall.nhtsa_campaign_number || '—' }}</p></div>
          </div>
          <div class="info-item">
            <v-icon size="18" color="medium-emphasis">mdi-card-account-details-outline</v-icon>
            <div><p class="text-caption text-medium-emphasis">MFR #</p><p class="text-body-2 font-weight-medium">{{ recall.manufacturer_campaign_number || '—' }}</p></div>
          </div>
        </div>

        <!-- Dates -->
        <div class="info-grid mt-3">
          <div class="info-item">
            <v-icon size="18" color="medium-emphasis">mdi-calendar</v-icon>
            <div><p class="text-caption text-medium-emphasis">Issue Date</p><p class="text-body-2 font-weight-medium">{{ fmtDate(recall.issue_date) }}</p></div>
          </div>
          <div class="info-item">
            <v-icon size="18" color="medium-emphasis">mdi-update</v-icon>
            <div><p class="text-caption text-medium-emphasis">Updated</p><p class="text-body-2 font-weight-medium">{{ fmtDate(recall.updated_at) }}</p></div>
          </div>
        </div>

        <!-- Progress -->
        <div class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-chart-line</v-icon>Resolution Progress</p>
          <div class="progress-card">
            <div class="d-flex justify-space-between mb-1">
              <span class="text-body-2 font-weight-medium">{{ recall.resolved_count || 0 }} / {{ recall.affected_count || 0 }} vehicles</span>
              <span class="text-body-2 font-weight-bold text-success">{{ resolutionPct }}%</span>
            </div>
            <v-progress-linear :model-value="resolutionPct" color="success" height="8" rounded />
          </div>
        </div>

        <!-- Description -->
        <div v-if="recall.description" class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-text-box-outline</v-icon>Description</p>
          <div class="notes-card">{{ recall.description }}</div>
        </div>

        <!-- Remedy -->
        <div v-if="recall.remedy" class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-wrench-check</v-icon>Remedy</p>
          <div class="notes-card">{{ recall.remedy }}</div>
        </div>

        <!-- Risk -->
        <div v-if="recall.risk" class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1" color="error">mdi-shield-alert</v-icon>Safety Risk</p>
          <div class="notes-card" style="border-left: 3px solid #ef4444">{{ recall.risk }}</div>
        </div>

        <!-- Affected Vehicles -->
        <div v-if="recall.vehicles?.length" class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-car-multiple</v-icon>Affected Vehicles ({{ recall.vehicles.length }})</p>
          <div class="vehicle-list">
            <div v-for="rv in recall.vehicles" :key="rv.id" class="vehicle-row">
              <v-icon size="16">mdi-car</v-icon>
              <div class="flex-grow-1">
                <p class="text-body-2 font-weight-medium">{{ rv.vehicle_name }}</p>
                <p class="text-caption text-medium-emphasis">{{fmtDate(rv.scheduled_date) !== '—' ? 'Scheduled: ' + fmtDate(rv.scheduled_date) : 'Not scheduled' }}</p>
              </div>
              <v-chip :color="resColor(rv.status)" variant="tonal" size="x-small" class="text-capitalize">{{ rv.status }}</v-chip>
            </div>
          </div>
        </div>

        <!-- Meta -->
        <div class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-information-outline</v-icon>Metadata</p>
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-key-variant</v-icon>
            <span class="text-caption text-medium-emphasis">ID:</span>
            <span class="text-body-2 font-weight-medium">#{{ recall.id }}</span>
          </div>
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-clock-outline</v-icon>
            <span class="text-caption text-medium-emphasis">Created:</span>
            <span class="text-body-2">{{ fmtDate(recall.created_at) }}</span>
          </div>
        </div>
      </div>

      <!-- Actions -->
      <div class="drawer-actions">
        <v-btn variant="text" prepend-icon="mdi-pencil-outline" @click="$emit('edit', recall)">Edit</v-btn>
        <v-btn variant="tonal" color="info" prepend-icon="mdi-magnify" @click="$emit('autoMatch', recall)">Auto-Match</v-btn>
        <v-btn variant="tonal" color="primary" prepend-icon="mdi-link-plus" @click="$emit('applyVehicles', recall)">Apply to Vehicles</v-btn>
        <v-spacer />
        <v-btn variant="tonal" color="error" prepend-icon="mdi-delete-outline" @click="$emit('delete', recall)">Delete</v-btn>
      </div>
    </div>
    <div v-else class="d-flex align-center justify-center h-100">
      <v-icon size="48" color="grey-lighten-2">mdi-car-info</v-icon>
    </div>
  </v-navigation-drawer>
</template>

<script setup lang="ts">
const props = defineProps<{ modelValue: boolean; recall: any }>()
defineEmits<{ 'update:modelValue': [v: boolean]; edit: [r: any]; delete: [r: any]; autoMatch: [r: any]; applyVehicles: [r: any] }>()

const resolutionPct = computed(() => {
  if (!props.recall || !props.recall.affected_count) return 0
  return Math.round((props.recall.resolved_count / props.recall.affected_count) * 100)
})

function statusColor(s: string) { return ({ open: 'error', in_progress: 'warning', completed: 'success', closed: 'grey' } as any)[s] || 'grey' }
function statusIcon(s: string) { return ({ open: 'mdi-alert-circle', in_progress: 'mdi-progress-wrench', completed: 'mdi-check-circle', closed: 'mdi-close-circle' } as any)[s] || 'mdi-circle-outline' }
function statusLabel(s: string) { return ({ open: 'Open', in_progress: 'In Progress', completed: 'Completed', closed: 'Closed' } as any)[s] || s }
function typeColor(t: string) { return ({ safety_recall: 'error', campaign: 'warning', field_notice: 'info', emission: 'success' } as any)[t] || 'grey' }
function typeIcon(t: string) { return ({ safety_recall: 'mdi-shield-alert', campaign: 'mdi-bullhorn', field_notice: 'mdi-file-alert', emission: 'mdi-leaf' } as any)[t] || 'mdi-car-info' }
function typeLabel(t: string) { return ({ safety_recall: 'Safety Recall', campaign: 'Campaign', field_notice: 'Field Notice', emission: 'Emission' } as any)[t] || t }
function resColor(s: string) { return ({ affected: 'error', scheduled: 'warning', in_progress: 'info', resolved: 'success', not_affected: 'grey' } as any)[s] || 'grey' }
function fmtDate(v?: string) { return v ? new Date(v).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' }) : '—' }
</script>

<style scoped>
.drawer-head { padding: 16px 20px 12px; }
.drawer-body { padding: 12px 20px; overflow-y: auto; flex: 1 1 0; }
.drawer-actions { padding: 12px 16px; border-top: 1px solid #e2e8f0; display: flex; gap: 4px; flex-wrap: wrap; align-items: center; }
.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.info-item { display: flex; align-items: flex-start; gap: 10px; }
.section-block { margin-top: 16px; }
.progress-card { padding: 12px; border-radius: 10px; background: #f8fafc; }
.notes-card { padding: 12px; border-radius: 10px; background: #f8fafc; font-size: 14px; line-height: 1.5; }
.vehicle-list { display: flex; flex-direction: column; gap: 6px; }
.vehicle-row { display: flex; align-items: center; gap: 8px; padding: 8px 10px; border-radius: 8px; background: #fafafa; border: 1px solid #f1f5f9; }
.info-row { display: flex; align-items: center; gap: 8px; padding: 4px 0; }
</style>
