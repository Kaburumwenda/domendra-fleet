<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="560" scrollable>
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-calendar-clock">{{ editing ? 'Edit Reservation' : 'New Bay Reservation' }}</AppModalHeader>
      <v-card-text>
        <v-row dense>
          <v-col cols="6">
            <v-select v-model="form.bay" :items="bayOptions" item-title="name" item-value="id" label="Bay *" variant="outlined" density="compact" hide-details="auto" :error-messages="errors.bay" prepend-inner-icon="mdi-sitemap" />
          </v-col>
          <v-col cols="6">
            <v-select v-model="form.vehicle" :items="vehicleOptions" item-title="display_name" item-value="id" label="Vehicle *" variant="outlined" density="compact" hide-details="auto" :error-messages="errors.vehicle" prepend-inner-icon="mdi-car" />
          </v-col>
          <v-col cols="6">
            <v-text-field v-model="form.start_time" type="datetime-local" label="Start *" variant="outlined" density="compact" hide-details="auto" :error-messages="errors.start_time" prepend-inner-icon="mdi-clock-start" />
          </v-col>
          <v-col cols="6">
            <v-text-field v-model="form.end_time" type="datetime-local" label="End *" variant="outlined" density="compact" hide-details="auto" :error-messages="errors.end_time" prepend-inner-icon="mdi-clock-end" />
          </v-col>
          <v-col cols="6">
            <v-select v-model="form.status" :items="statusOptions" item-title="label" item-value="value" label="Status" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-flag-checkered" />
          </v-col>
          <v-col cols="12">
            <v-textarea v-model="form.notes" label="Notes" rows="2" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-note-text" />
          </v-col>
        </v-row>
      </v-card-text>
      <v-card-actions class="px-4 pb-4">
        <v-spacer />
        <v-btn variant="text" @click="$emit('update:modelValue', false)">Cancel</v-btn>
        <v-btn color="primary" prepend-icon="mdi-check" :loading="saving" @click="onSave">{{ editing ? 'Update' : 'Reserve' }}</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
const props = defineProps<{ modelValue: boolean; editing: boolean; saving: boolean; bayOptions: any[]; vehicleOptions: any[] }>()
const emit = defineEmits<{ 'update:modelValue': [v: boolean]; save: [payload: any] }>()

const statusOptions = [
  { label: 'Scheduled', value: 'scheduled' },
  { label: 'Active', value: 'active' },
  { label: 'Completed', value: 'completed' },
  { label: 'Cancelled', value: 'cancelled' },
]

function defaultForm() {
  return {
    bay: null, vehicle: null,
    start_time: new Date().toISOString().slice(0, 16),
    end_time: new Date(Date.now() + 4 * 3600 * 1000).toISOString().slice(0, 16),
    status: 'scheduled', notes: '',
  }
}

const form = reactive<any>(defaultForm())
const errors = reactive<any>({})

defineExpose({
  reset: (r?: any) => {
    Object.assign(form, defaultForm())
    Object.keys(errors).forEach(k => delete errors[k])
    if (r) Object.assign(form, {
      bay: r.bay, vehicle: r.vehicle,
      start_time: r.start_time?.slice(0, 16) || form.start_time,
      end_time: r.end_time?.slice(0, 16) || form.end_time,
      status: r.status || 'scheduled', notes: r.notes || '',
      _id: r.id,
    })
  },
})

function onSave() {
  Object.keys(errors).forEach(k => delete errors[k])
  errors.bay = form.bay ? '' : 'Bay is required'
  errors.vehicle = form.vehicle ? '' : 'Vehicle is required'
  const now = new Date()
  const s = new Date(form.start_time)
  const e = new Date(form.end_time)
  if (form.start_time) errors.start_time = s > now ? '' : '' // allow past for demo
  if (form.start_time && form.end_time) {
    if (e <= s) { errors.end_time = 'End must be after start'; }
  }
  if (!form.bay || !form.vehicle || (errors.end_time && e <= s)) return
  const payload = {
    ...form,
    start_time: new Date(form.start_time).toISOString(),
    end_time: new Date(form.end_time).toISOString(),
  }
  emit('save', payload)
}
</script>
