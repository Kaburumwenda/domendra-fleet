<template>
  <v-navigation-drawer :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" location="right" width="540" temporary permanent style="top:0; height:100vh; z-index:1000">
    <div v-if="report" class="d-flex flex-column h-100">
      <!-- Header -->
      <div class="drawer-head">
        <div class="d-flex align-center ga-2 mb-2">
          <v-chip :color="statusColor" variant="flat" size="small">
            <v-icon start size="14">{{ statusIcon }}</v-icon>{{ statusLabel }}
          </v-chip>
          <v-chip v-if="hasCriticalFail" color="error" variant="flat" size="small"><v-icon start size="14">mdi-alert-octagon</v-icon>Critical</v-chip>
        </div>
        <div class="d-flex align-center">
          <h2 class="text-h6 font-weight-bold flex-grow-1">{{ report.form_name || 'Ad-hoc Inspection' }}</h2>
          <v-btn icon variant="text" size="small" @click="$emit('update:modelValue', false)"><v-icon>mdi-close</v-icon></v-btn>
        </div>
        <p class="text-caption text-medium-emphasis mt-1"><v-icon size="14">mdi-car</v-icon>{{ report.vehicle_name }}</p>
      </div>
      <v-divider />

      <div class="drawer-body">
        <!-- Info Grid -->
        <div class="info-grid">
          <div class="info-item">
            <v-icon size="18" color="medium-emphasis">mdi-account</v-icon>
            <div><p class="text-caption text-medium-emphasis">Driver</p><p class="text-body-2 font-weight-medium">{{ report.driver_name || 'Unassigned' }}</p></div>
          </div>
          <div class="info-item">
            <v-icon size="18" color="medium-emphasis">mdi-counter</v-icon>
            <div><p class="text-caption text-medium-emphasis">Odometer</p><p class="text-body-2 font-weight-medium">{{ report.odometer_reading ? report.odometer_reading.toLocaleString() + ' mi' : '—' }}</p></div>
          </div>
          <div class="info-item">
            <v-icon size="18" color="medium-emphasis">mdi-calendar-clock</v-icon>
            <div><p class="text-caption text-medium-emphasis">Submitted</p><p class="text-body-2 font-weight-medium">{{ fmt(report.submitted_at) }}</p></div>
          </div>
          <div class="info-item">
            <v-icon size="18" color="medium-emphasis">mdi-map-marker</v-icon>
            <div><p class="text-caption text-medium-emphasis">Location</p><p class="text-body-2 font-weight-medium">{{ report.latitude && report.longitude ? `${report.latitude.toFixed(3)}, ${report.longitude.toFixed(3)}` : '—' }}</p></div>
          </div>
        </div>

        <!-- Notes -->
        <div v-if="report.notes" class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-note-text</v-icon>Notes</p>
          <div class="notes-card">{{ report.notes }}</div>
        </div>

        <!-- Responses -->
        <div class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-format-list-checks</v-icon>Inspection Items <span class="text-caption text-medium-emphasis font-weight-normal">({{ report.responses?.length || 0 }})</span></p>
          <v-card v-for="r in report.responses || []" :key="r.id" elevation="0" border class="mb-2" :class="{ 'response-fail': r.is_fail }">
            <div class="pa-3">
              <div class="d-flex align-center justify-space-between">
                <span class="text-body-2 font-weight-medium">{{ r.item_label }}</span>
                <v-chip v-if="r.is_critical" size="x-small" variant="flat" color="error">Critical</v-chip>
              </div>
              <div class="d-flex align-center ga-2 mt-1">
                <v-chip v-if="r.is_fail" size="small" variant="flat" color="error"><v-icon start size="12">mdi-close</v-icon>Fail</v-chip>
                <v-chip v-else-if="r.item_type === 'pass_fail'" size="small" variant="flat" color="success"><v-icon start size="12">mdi-check</v-icon>Pass</v-chip>
                <v-chip v-else size="small" variant="tonal" color="grey">{{ r.value || '—' }}</v-chip>
                <span class="text-caption text-medium-emphasis">{{ r.item_type }}</span>
                <v-spacer />
                <v-chip v-if="r.notes" size="x-small" variant="outlined"><v-icon start size="12">mdi-note</v-icon>Notes</v-chip>
              </div>
              <p v-if="r.notes" class="text-caption text-medium-emphasis mt-2 pa-2 rounded" style="background:#f8fafc">{{ r.notes }}</p>
            </div>
          </v-card>
          <div v-if="!(report.responses || []).length" class="text-center text-caption text-medium-emphasis py-4">No responses recorded.</div>
        </div>
      </div>

      <!-- Actions -->
      <div class="drawer-actions">
        <v-btn variant="text" prepend-icon="mdi-pencil-outline" @click="$emit('edit', report)">Edit</v-btn>
        <v-spacer />
        <v-btn v-if="report.status === 'draft'" variant="tonal" color="success" prepend-icon="mdi-check-decagram" @click="$emit('setStatus', { report, status: 'pass' })">Mark Passed</v-btn>
        <v-btn variant="tonal" color="error" prepend-icon="mdi-delete-outline" @click="$emit('delete', report)">Delete</v-btn>
      </div>
    </div>
    <div v-else class="d-flex align-center justify-center h-100">
      <v-icon size="48" color="grey-lighten-2">mdi-clipboard-check-outline</v-icon>
    </div>
  </v-navigation-drawer>
</template>

<script setup lang="ts">
const props = defineProps<{ modelValue: boolean; report: any }>()
defineEmits<{ 'update:modelValue': [v: boolean]; edit: [r: any]; delete: [r: any]; setStatus: [payload: any] }>()

const hasCriticalFail = computed(() => (props.report?.responses || []).some((r: any) => r.is_fail && r.is_critical))

const statusColor = computed(() => ({ pass: 'success', fail: 'error', conditional: 'warning', draft: 'grey' } as any)[props.report?.status] || 'grey')
const statusIcon = computed(() => ({ pass: 'mdi-check-decagram', fail: 'mdi-close-circle', conditional: 'mdi-alert-circle', draft: 'mdi-pencil-outline' } as any)[props.report?.status] || 'mdi-clipboard')
const statusLabel = computed(() => ({ pass: 'Passed', fail: 'Failed', conditional: 'Conditional', draft: 'Draft' } as any)[props.report?.status] || props.report?.status)

function fmt(v?: string) { return v ? new Date(v).toLocaleString([], { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : '—' }
</script>

<style scoped>
.drawer-head { padding: 16px 20px 12px; }
.drawer-body { padding: 12px 20px; overflow-y: auto; flex: 1 1 0; }
.drawer-actions { padding: 12px 16px; border-top: 1px solid #e2e8f0; display: flex; gap: 4px; flex-wrap: wrap; }
.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.info-item { display: flex; align-items: flex-start; gap: 10px; }
.section-block { margin-top: 16px; }
.notes-card { padding: 12px; border-radius: 10px; background: #f8fafc; font-size: 14px; line-height: 1.5; }
.response-fail { border-left: 3px solid #ef4444; }
</style>
