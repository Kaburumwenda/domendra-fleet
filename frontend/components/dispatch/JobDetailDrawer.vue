<template>
  <v-navigation-drawer :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" location="right" width="520" temporary permanent style="top:0; height:100vh; z-index:1000">
    <div v-if="job" class="d-flex flex-column h-100">
      <!-- Header -->
      <div class="drawer-head">
        <div class="d-flex align-center ga-2">
          <v-chip :color="statusColor(job.status)" variant="flat" size="small" class="text-capitalize">{{ job.status.replace('_', ' ') }}</v-chip>
          <v-chip :color="priorityColor(job.priority)" variant="tonal" size="small" class="text-capitalize"><v-icon start size="14">mdi-flag</v-icon>{{ job.priority }}</v-chip>
        </div>
        <div class="d-flex align-center mt-2 mb-1">
          <h2 class="text-h6 font-weight-bold flex-grow-1">{{ job.title }}</h2>
          <v-btn icon variant="text" size="small" @click="$emit('update:modelValue', false)"><v-icon>mdi-close</v-icon></v-btn>
        </div>
        <p class="text-caption text-medium-emphasis">#{{ job.id }} · Created {{ fmt(job.created_at) }}</p>
      </div>
      <v-divider />

      <div class="drawer-body">
        <!-- Route summary -->
        <div class="route-summary">
          <div class="route-line">
            <div class="route-dot" style="background:#10b981" />
            <div class="route-content">
              <p class="text-caption text-medium-emphasis">Pickup</p>
              <p class="text-body-2 font-weight-medium">{{ job.pickup_address || 'Not set' }}</p>
            </div>
          </div>
          <div class="route-connector" />
          <div class="route-line">
            <div class="route-dot" style="background:#ef4444" />
            <div class="route-content">
              <p class="text-caption text-medium-emphasis">Dropoff</p>
              <p class="text-body-2 font-weight-medium">{{ job.dropoff_address || 'Not set' }}</p>
            </div>
          </div>
        </div>

        <!-- Assignment -->
        <div class="info-grid">
          <div class="info-item">
            <v-icon size="16" color="medium-emphasis">mdi-truck</v-icon>
            <div>
              <p class="text-caption text-medium-emphasis">Vehicle</p>
              <p class="text-body-2 font-weight-medium">{{ job.vehicle_name || 'Unassigned' }}</p>
            </div>
          </div>
          <div class="info-item">
            <v-icon size="16" color="medium-emphasis">mdi-account</v-icon>
            <div>
              <p class="text-caption text-medium-emphasis">Driver</p>
              <p class="text-body-2 font-weight-medium">{{ job.driver_name || 'Unassigned' }}</p>
            </div>
          </div>
          <div class="info-item">
            <v-icon size="16" color="medium-emphasis">mdi-clock-start</v-icon>
            <div>
              <p class="text-caption text-medium-emphasis">Scheduled Start</p>
              <p class="text-body-2 font-weight-medium">{{ fmt(job.scheduled_start) }}</p>
            </div>
          </div>
          <div class="info-item">
            <v-icon size="16" color="medium-emphasis">mdi-clock-end</v-icon>
            <div>
              <p class="text-caption text-medium-emphasis">Scheduled End</p>
              <p class="text-body-2 font-weight-medium">{{ fmt(job.scheduled_end) }}</p>
            </div>
          </div>
          <div class="info-item">
            <v-icon size="16" color="medium-emphasis">mdi-timer-sand</v-icon>
            <div>
              <p class="text-caption text-medium-emphasis">ETA</p>
              <p class="text-body-2 font-weight-medium">{{ job.eta_minutes ? job.eta_minutes + ' min' : '—' }}</p>
            </div>
          </div>
          <div class="info-item">
            <v-icon size="16" :color="job.is_on_schedule ? 'success' : 'error'">mdi-check-clock</v-icon>
            <div>
              <p class="text-caption text-medium-emphasis">On Schedule</p>
              <p class="text-body-2 font-weight-medium" :class="job.is_on_schedule ? 'text-success' : 'text-error'">
                {{ job.is_on_schedule == null ? '—' : job.is_on_schedule ? 'On time' : 'Delayed' }}
              </p>
            </div>
          </div>
        </div>

        <!-- Action buttons -->
        <div class="action-row">
          <v-btn v-if="job.status === 'pending'" color="info" variant="flat" prepend-icon="mdi-send" block @click="$emit('assign', job)">Assign</v-btn>
          <v-btn v-if="job.status === 'assigned'" color="success" variant="flat" prepend-icon="mdi-play" block @click="$emit('start', job)">Start Job</v-btn>
          <v-btn v-if="job.status === 'in_progress'" v-can="'dispatch:update'" color="success" variant="flat" prepend-icon="mdi-check" block @click="$emit('complete', job)">Complete</v-btn>
          <v-btn v-can="'dispatch:update'" variant="outlined" prepend-icon="mdi-pencil" block @click="$emit('edit', job)">Edit</v-btn>
          <div class="d-flex ga-2">
            <v-btn variant="tonal" color="primary" prepend-icon="mdi-routes" block @click="$emit('optimizeRoute', job)">Optimize</v-btn>
            <v-btn variant="tonal" color="warning" prepend-icon="mdi-traffic-cone" block @click="$emit('trafficWeather', job)">Traffic</v-btn>
          </div>
          <v-btn v-if="job.status !== 'completed' && job.status !== 'cancelled'" variant="text" color="error" prepend-icon="mdi-cancel" block @click="$emit('cancel', job)">Cancel Job</v-btn>
          <v-btn v-can="'dispatch:delete'" variant="text" color="error" prepend-icon="mdi-delete" block @click="$emit('delete', job)">Delete</v-btn>
        </div>

        <!-- Notes -->
        <div v-if="job.notes" class="notes-block">
          <p class="text-caption text-medium-emphasis mb-1"><v-icon size="14">mdi-note-text</v-icon> Notes</p>
          <p class="text-body-2">{{ job.notes }}</p>
        </div>

        <!-- Route stops timeline -->
        <div class="stops-block">
          <div class="d-flex align-center justify-space-between mb-2">
            <p class="text-subtitle-2 font-weight-bold"><v-icon size="18" color="primary" class="mr-1">mdi-map-marker-multiple</v-icon>Route Stops ({{ stops.length }})</p>
            <v-btn v-can="'dispatch:create'" size="small" variant="text" color="primary" prepend-icon="mdi-plus" @click="openStopDialog()">Add</v-btn>
          </div>
          <v-timeline density="compact" side="end" align="start" v-if="stops.length">
            <v-timeline-item v-for="(s, i) in stops" :key="s.id" :dot-color="stopDotColor(s.status)" size="x-small" fill-dot>
              <div class="stop-item">
                <div class="d-flex align-center ga-2">
                  <v-chip size="x-small" variant="outlined">{{ i + 1 }}</v-chip>
                  <p class="text-body-2 font-weight-medium flex-grow-1">{{ s.address }}</p>
                  <v-menu>
                    <template #activator="{ props: p }">
                      <v-btn icon="mdi-dots-vertical" variant="text" size="x-small" v-bind="p" />
                    </template>
                    <v-list density="compact">
                      <v-list-item prepend-icon="mdi-arrow-up" @click="moveStop(s, -1)" :disabled="i === 0">Move Up</v-list-item>
                      <v-list-item prepend-icon="mdi-arrow-down" @click="moveStop(s, 1)" :disabled="i === stops.length - 1">Move Down</v-list-item>
                      <v-list-item v-can="'dispatch:update'" prepend-icon="mdi-pencil" @click="openStopDialog(s)">Edit</v-list-item>
                      <v-list-item v-can="'dispatch:delete'" prepend-icon="mdi-delete" base-color="error" @click="deleteStop(s)">Delete</v-list-item>
                    </v-list>
                  </v-menu>
                </div>
                <div class="d-flex flex-wrap ga-3 mt-1 text-caption text-medium-emphasis">
                  <span v-if="s.scheduled_arrival"><v-icon size="12">mdi-clock</v-icon> Arrive {{ fmt(s.scheduled_arrival) }}</span>
                  <span v-if="s.actual_arrival" class="text-success"><v-icon size="12">mdi-check</v-icon> {{ fmt(s.actual_arrival) }}</span>
                  <v-chip :color="stopChipColor(s.status)" variant="flat" size="x-small" class="text-capitalize">{{ s.status }}</v-chip>
                </div>
                <p v-if="s.notes" class="text-caption text-medium-emphasis mt-1">{{ s.notes }}</p>
              </div>
            </v-timeline-item>
          </v-timeline>
          <div v-else class="text-center pa-6 text-medium-emphasis">
            <v-icon size="36">mdi-map-marker-remove-variant</v-icon>
            <p class="text-caption mt-2">No stops added yet.</p>
          </div>
        </div>
      </div>
    </div>
    <div v-else class="d-flex align-center justify-center h-100">
      <v-progress-circular indeterminate color="primary" />
    </div>
  </v-navigation-drawer>
</template>

<script setup lang="ts">
const props = defineProps<{ modelValue: boolean; job: any; stops: any[] }>()
const emit = defineEmits<{
  'update:modelValue': [v: boolean]
  assign: [job: any]; start: [job: any]; complete: [job: any]; edit: [job: any]; cancel: [job: any]; delete: [job: any]
  addStop: []; editStop: [stop: any]; deleteStop: [stop: any]; reorderStop: [stop: any, direction: number]
  optimizeRoute: [job: any]; trafficWeather: [job: any]
}>()

function fmt(v?: string) { return v ? new Date(v).toLocaleString([], { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : '—' }
function statusColor(s: string) { return ({ pending: 'grey', assigned: 'info', in_progress: 'warning', completed: 'success', cancelled: 'error' } as any)[s] || 'grey' }
function priorityColor(p: string) { return ({ low: 'grey', medium: 'warning', high: 'orange', urgent: 'error' } as any)[p] || 'grey' }
function stopDotColor(s: string) { return ({ pending: 'grey', arrived: 'info', departed: 'success', skipped: 'error' } as any)[s] || 'grey' }
function stopChipColor(s: string) { return stopDotColor(s) }

function openStopDialog(stop?: any) {
  if (stop) emit('editStop', stop); else emit('addStop')
}
function deleteStop(s: any) { emit('deleteStop', s) }
function moveStop(s: any, dir: number) { emit('reorderStop', s, dir) }
</script>

<style scoped>
.drawer-head { padding:18px 20px 14px; }
.drawer-body { flex:1; overflow-y:auto; padding:0 20px 20px; display:flex; flex-direction:column; gap:18px; }
.route-summary { background:#f8fafc; border:1px solid #e2e8f0; border-radius:12px; padding:14px; }
.route-line { display:flex; gap:12px; align-items:flex-start; }
.route-dot { width:12px; height:12px; border-radius:50%; margin-top:4px; flex-shrink:0; }
.route-content { flex:1; min-width:0; }
.route-connector { width:2px; height:24px; background:#cbd5e1; margin-left:5px; }
.info-grid { display:grid; grid-template-columns: repeat(2, 1fr); gap:12px; }
.info-item { display:flex; gap:10px; align-items:flex-start; }
.action-row { display:flex; flex-direction:column; gap:8px; }
.notes-block { background:#fffbeb; border:1px solid #fde68a; border-radius:10px; padding:12px; }
.stops-block { background:#fff; border:1px solid #e2e8f0; border-radius:12px; padding:14px; }
.stop-item { padding-bottom: 8px; }
</style>
