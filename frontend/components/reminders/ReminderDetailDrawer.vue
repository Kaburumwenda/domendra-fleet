<template>
  <v-navigation-drawer :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" location="right" width="480" temporary permanent style="top:0; height:100vh; z-index:1000">
    <div v-if="reminder" class="d-flex flex-column h-100">
      <!-- Header -->
      <div class="drawer-head">
        <div class="d-flex align-center ga-2 mb-2">
          <v-chip :color="statusColor" variant="flat" size="small">
            <v-icon start size="14">{{ statusIcon }}</v-icon>{{ statusLabel }}
          </v-chip>
          <v-chip :color="reminder.is_active ? 'success' : 'grey'" variant="tonal" size="small">
            <v-icon start size="14">{{ reminder.is_active ? 'mdi-check-circle' : 'mdi-close-circle' }}</v-icon>{{ reminder.is_active ? 'Active' : 'Inactive' }}
          </v-chip>
        </div>
        <div class="d-flex align-center">
          <h2 class="text-h6 font-weight-bold flex-grow-1">{{ reminder.title }}</h2>
          <v-btn icon variant="text" size="small" @click="$emit('update:modelValue', false)"><v-icon>mdi-close</v-icon></v-btn>
        </div>
        <p class="text-caption text-medium-emphasis mt-1"><v-icon size="14">mdi-car</v-icon>{{ reminder.vehicle_name }}</p>
      </div>
      <v-divider />

      <div class="drawer-body">
        <!-- Trigger Info -->
        <div class="info-grid">
          <div class="info-item">
            <v-icon size="18" :color="triggerColor">{{ triggerIcon }}</v-icon>
            <div>
              <p class="text-caption text-medium-emphasis">Trigger Type</p>
              <p class="text-body-2 font-weight-medium">{{ triggerLabel }}</p>
            </div>
          </div>
          <div class="info-item">
            <v-icon size="18" color="medium-emphasis">mdi-repeat</v-icon>
            <div>
              <p class="text-caption text-medium-emphasis">Interval</p>
              <p class="text-body-2 font-weight-medium">Every {{ reminder.trigger_interval }} {{ intervalUnit }}</p>
            </div>
          </div>
        </div>

        <!-- Next Due -->
        <div class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-calendar-clock</v-icon>Next Due</p>
          <div class="due-card" :class="'due-card-' + statusKey">
            <v-icon size="28" :color="statusColor">{{ statusIcon }}</v-icon>
            <div class="ml-2">
              <p class="text-body-1 font-weight-bold" :class="'text-' + statusColor">{{ statusLabel }}</p>
              <p class="text-caption text-medium-emphasis">{{ nextDueText }}</p>
            </div>
          </div>
        </div>

        <!-- Escalation -->
        <div class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-shield-alert-outline</v-icon>Escalation</p>
          <v-chip :color="escalationColor" variant="flat" size="small">
            <v-icon start size="14">{{ escalationIcon }}</v-icon>{{ escalationLabel }}
          </v-chip>
        </div>

        <!-- Settings -->
        <div class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-cog-outline</v-icon>Settings</p>
          <div class="setting-row">
            <v-icon size="18" :color="reminder.auto_generate_work_order ? 'info' : 'grey'">mdi-clipboard-plus-outline</v-icon>
            <span class="text-body-2">Auto-generate Work Order</span>
            <v-chip size="small" :color="reminder.auto_generate_work_order ? 'info' : 'grey'" variant="tonal" class="ml-auto">{{ reminder.auto_generate_work_order ? 'Yes' : 'No' }}</v-chip>
          </div>
          <div class="setting-row">
            <v-icon size="18" :color="reminder.is_active ? 'success' : 'grey'">mdi-power-standby</v-icon>
            <span class="text-body-2">Active</span>
            <v-chip size="small" :color="reminder.is_active ? 'success' : 'grey'" variant="tonal" class="ml-auto">{{ reminder.is_active ? 'Yes' : 'No' }}</v-chip>
          </div>
        </div>

        <!-- Meta -->
        <div class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-information-outline</v-icon>Metadata</p>
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-key-variant</v-icon>
            <span class="text-caption text-medium-emphasis">ID:</span>
            <span class="text-body-2 font-weight-medium">#{{ reminder.id }}</span>
          </div>
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-clock-outline</v-icon>
            <span class="text-caption text-medium-emphasis">Created:</span>
            <span class="text-body-2">{{ fmt(reminder.created_at) }}</span>
          </div>
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-update</v-icon>
            <span class="text-caption text-medium-emphasis">Updated:</span>
            <span class="text-body-2">{{ fmt(reminder.updated_at) }}</span>
          </div>
        </div>
      </div>

      <!-- Actions -->
      <div class="drawer-actions">
        <v-btn variant="text" prepend-icon="mdi-pencil-outline" @click="$emit('edit', reminder)">Edit</v-btn>
        <v-spacer />
        <v-btn v-if="reminder.is_active" variant="tonal" color="grey" prepend-icon="mdi-pause" @click="$emit('toggleActive', reminder)">Deactivate</v-btn>
        <v-btn v-else variant="tonal" color="success" prepend-icon="mdi-play" @click="$emit('toggleActive', reminder)">Activate</v-btn>
        <v-btn variant="tonal" color="error" prepend-icon="mdi-delete-outline" @click="$emit('delete', reminder)">Delete</v-btn>
      </div>
    </div>
    <div v-else class="d-flex align-center justify-center h-100">
      <v-icon size="48" color="grey-lighten-2">mdi-bell-outline</v-icon>
    </div>
  </v-navigation-drawer>
</template>

<script setup lang="ts">
const props = defineProps<{ modelValue: boolean; reminder: any }>()
defineEmits<{ 'update:modelValue': [v: boolean]; edit: [r: any]; delete: [r: any]; toggleActive: [r: any] }>()

const triggerColor = computed(() => ({ time: 'primary', mileage: 'warning', engine_hours: 'info' } as any)[props.reminder?.trigger_type] || 'grey')
const triggerIcon = computed(() => ({ time: 'mdi-calendar-clock', mileage: 'mdi-counter', engine_hours: 'mdi-engine-outline' } as any)[props.reminder?.trigger_type] || 'mdi-bell')
const triggerLabel = computed(() => ({ time: 'Time (Months)', mileage: 'Mileage', engine_hours: 'Engine Hours' } as any)[props.reminder?.trigger_type] || '—')
const intervalUnit = computed(() => ({ time: 'months', mileage: 'miles', engine_hours: 'hours' } as any)[props.reminder?.trigger_type] || '')

const statusKey = computed(() => {
  if (!props.reminder) return 'scheduled'
  if (props.reminder.is_overdue) return 'overdue'
  if (props.reminder.is_due) return 'due'
  return 'upcoming'
})
const statusColor = computed(() => ({ overdue: 'error', due: 'warning', upcoming: 'success', scheduled: 'info' } as any)[statusKey.value])
const statusIcon = computed(() => ({ overdue: 'mdi-alert-octagon', due: 'mdi-bell-alert', upcoming: 'mdi-check-circle', scheduled: 'mdi-clock-outline' } as any)[statusKey.value])
const statusLabel = computed(() => ({ overdue: 'Overdue', due: 'Due Now', upcoming: 'Upcoming', scheduled: 'Scheduled' } as any)[statusKey.value])

const nextDueText = computed(() => {
  if (!props.reminder) return '—'
  if (props.reminder.trigger_type === 'time' && props.reminder.next_due_date) {
    return new Date(props.reminder.next_due_date).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' })
  }
  if (props.reminder.trigger_type === 'mileage' && props.reminder.next_due_mileage) {
    return `${props.reminder.next_due_mileage.toLocaleString()} miles`
  }
  if (props.reminder.trigger_type === 'engine_hours' && props.reminder.next_due_engine_hours) {
    return `${props.reminder.next_due_engine_hours.toLocaleString()} hours`
  }
  return '—'
})

const escalationColor = computed(() => ({ 0: 'grey', 1: 'info', 2: 'warning', 3: 'error' } as any)[props.reminder?.escalation_level] || 'grey')
const escalationIcon = computed(() => ({ 0: 'mdi-shield-off-outline', 1: 'mdi-email-alert-outline', 2: 'mdi-cellphone-text', 3: 'mdi-block-helper' } as any)[props.reminder?.escalation_level] || 'mdi-shield')
const escalationLabel = computed(() => ({ 0: 'None', 1: 'Email Driver', 2: 'SMS Manager', 3: 'Block Dispatch' } as any)[props.reminder?.escalation_level] || 'None')

function fmt(v?: string) { return v ? new Date(v).toLocaleString([], { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : '—' }
</script>

<style scoped>
.drawer-head { padding: 16px 20px 12px; }
.drawer-body { padding: 12px 20px; overflow-y: auto; flex: 1 1 0; }
.drawer-actions { padding: 12px 16px; border-top: 1px solid #e2e8f0; display: flex; gap: 4px; flex-wrap: wrap; }
.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.info-item { display: flex; align-items: flex-start; gap: 10px; }
.section-block { margin-top: 16px; }
.due-card { display: flex; align-items: center; padding: 12px; border-radius: 10px; background: #f8fafc; }
.due-card-overdue { background: #fef2f2; }
.due-card-due { background: #fffbeb; }
.setting-row { display: flex; align-items: center; gap: 10px; padding: 6px 0; }
.info-row { display: flex; align-items: center; gap: 8px; padding: 4px 0; }
</style>
