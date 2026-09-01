<template>
  <v-navigation-drawer :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" location="right" width="500" temporary permanent style="top:0; height:100vh; z-index:1000">
    <div v-if="reservation" class="d-flex flex-column h-100">
      <!-- Header -->
      <div class="drawer-head">
        <div class="d-flex align-center ga-2 mb-2">
          <v-chip :color="statusColor" variant="flat" size="small">
            <v-icon start size="14">{{ statusIcon }}</v-icon>{{ statusLabel }}
          </v-chip>
        </div>
        <div class="d-flex align-center">
          <h2 class="text-h6 font-weight-bold flex-grow-1">{{ reservation.bay_name }}</h2>
          <v-btn icon variant="text" size="small" @click="$emit('update:modelValue', false)"><v-icon>mdi-close</v-icon></v-btn>
        </div>
        <p class="text-caption text-medium-emphasis mt-1"><v-icon size="14">mdi-car</v-icon>{{ reservation.vehicle_name }}</p>
      </div>
      <v-divider />

      <div class="drawer-body">
        <!-- Info Grid -->
        <div class="info-grid">
          <div class="info-item">
            <v-icon size="18" color="medium-emphasis">mdi-clock-start</v-icon>
            <div><p class="text-caption text-medium-emphasis">Start</p><p class="text-body-2 font-weight-medium">{{ fmt(reservation.start_time) }}</p></div>
          </div>
          <div class="info-item">
            <v-icon size="18" color="medium-emphasis">mdi-clock-end</v-icon>
            <div><p class="text-caption text-medium-emphasis">End</p><p class="text-body-2 font-weight-medium">{{ fmt(reservation.end_time) }}</p></div>
          </div>
        </div>

        <!-- Duration -->
        <div class="section-block">
          <div class="duration-card">
            <v-icon size="22" color="primary">mdi-timer-sand</v-icon>
            <div class="ml-2">
              <p class="text-body-1 font-weight-bold text-primary">{{ reservation.duration_hours }} hours</p>
              <p class="text-caption text-medium-emphasis">{{ durationText }}</p>
            </div>
          </div>
        </div>

        <!-- Notes -->
        <div v-if="reservation.notes" class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-note-text</v-icon>Notes</p>
          <div class="notes-card">{{ reservation.notes }}</div>
        </div>

        <!-- Meta -->
        <div class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-information-outline</v-icon>Metadata</p>
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-key-variant</v-icon>
            <span class="text-caption text-medium-emphasis">ID:</span>
            <span class="text-body-2 font-weight-medium">#{{ reservation.id }}</span>
          </div>
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-clock-outline</v-icon>
            <span class="text-caption text-medium-emphasis">Created:</span>
            <span class="text-body-2">{{ fmt(reservation.created_at) }}</span>
          </div>
        </div>
      </div>

      <!-- Actions -->
      <div class="drawer-actions">
        <v-btn variant="text" prepend-icon="mdi-pencil-outline" @click="$emit('edit', reservation)">Edit</v-btn>
        <v-spacer />
        <v-btn v-if="reservation.status === 'scheduled'" variant="tonal" color="success" prepend-icon="mdi-play" @click="$emit('setStatus', { reservation, status: 'active' })">Activate</v-btn>
        <v-btn v-if="reservation.status === 'active'" variant="tonal" color="grey" prepend-icon="mdi-check-circle" @click="$emit('setStatus', { reservation, status: 'completed' })">Complete</v-btn>
        <v-btn v-if="reservation.status !== 'cancelled'" variant="tonal" color="warning" prepend-icon="mdi-cancel" @click="$emit('setStatus', { reservation, status: 'cancelled' })">Cancel</v-btn>
        <v-btn variant="tonal" color="error" prepend-icon="mdi-delete-outline" @click="$emit('delete', reservation)">Delete</v-btn>
      </div>
    </div>
    <div v-else class="d-flex align-center justify-center h-100">
      <v-icon size="48" color="grey-lighten-2">mdi-garage</v-icon>
    </div>
  </v-navigation-drawer>
</template>

<script setup lang="ts">
const props = defineProps<{ modelValue: boolean; reservation: any }>()
defineEmits<{ 'update:modelValue': [v: boolean]; edit: [r: any]; delete: [r: any]; setStatus: [payload: any] }>()

const statusColor = computed(() => ({ scheduled: 'info', active: 'success', completed: 'grey', cancelled: 'error' } as any)[props.reservation?.status] || 'grey')
const statusIcon = computed(() => ({ scheduled: 'mdi-clock-outline', active: 'mdi-play-circle', completed: 'mdi-check-circle', cancelled: 'mdi-cancel' } as any)[props.reservation?.status] || 'mdi-clock')
const statusLabel = computed(() => ({ scheduled: 'Scheduled', active: 'Active', completed: 'Completed', cancelled: 'Cancelled' } as any)[props.reservation?.status] || props.reservation?.status)

const durationText = computed(() => {
  if (!props.reservation) return ''
  const s = new Date(props.reservation.start_time)
  const e = new Date(props.reservation.end_time)
  return `${s.toLocaleDateString([], { month: 'short', day: 'numeric' })} → ${e.toLocaleDateString([], { month: 'short', day: 'numeric' })}`
})

function fmt(v?: string) { return v ? new Date(v).toLocaleString([], { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : '—' }
</script>

<style scoped>
.drawer-head { padding: 16px 20px 12px; }
.drawer-body { padding: 12px 20px; overflow-y: auto; flex: 1 1 0; }
.drawer-actions { padding: 12px 16px; border-top: 1px solid #e2e8f0; display: flex; gap: 4px; flex-wrap: wrap; }
.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.info-item { display: flex; align-items: flex-start; gap: 10px; }
.section-block { margin-top: 16px; }
.duration-card { display: flex; align-items: center; padding: 12px; border-radius: 10px; background: #f0f7ff; }
.notes-card { padding: 12px; border-radius: 10px; background: #f8fafc; font-size: 14px; line-height: 1.5; }
.info-row { display: flex; align-items: center; gap: 8px; padding: 4px 0; }
</style>
