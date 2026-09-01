<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="600" scrollable>
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-bell-plus-outline">{{ editing ? 'Edit Reminder' : 'Add Reminder' }}</AppModalHeader>
      <v-card-text>
        <v-row dense>
          <v-col cols="12">
            <v-text-field v-model="form.title" label="Title *" variant="outlined" density="compact" hide-details="auto" :error-messages="errors.title" prepend-inner-icon="mdi-format-title" />
          </v-col>
          <v-col cols="12">
            <v-select v-model="form.vehicle" :items="vehicleOptions" item-title="display_name" item-value="id" label="Vehicle *" variant="outlined" density="compact" hide-details="auto" :error-messages="errors.vehicle" prepend-inner-icon="mdi-car" />
          </v-col>
          <v-col cols="6">
            <v-select v-model="form.trigger_type" :items="triggerTypes" item-title="label" item-value="value" label="Trigger Type *" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-toggle-switch-outline" />
          </v-col>
          <v-col cols="6">
            <v-text-field v-model.number="form.trigger_interval" label="Interval *" type="number" variant="outlined" density="compact" hide-details="auto" :suffix="intervalSuffix" prepend-inner-icon="mdi-repeat" />
          </v-col>
          <v-col v-if="form.trigger_type === 'time'" cols="6">
            <v-text-field v-model="form.next_due_date" type="date" label="Next Due Date" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-calendar-clock" />
          </v-col>
          <v-col v-if="form.trigger_type === 'mileage'" cols="6">
            <v-text-field v-model.number="form.next_due_mileage" label="Next Due Mileage" type="number" variant="outlined" density="compact" hide-details="auto" suffix="mi" prepend-inner-icon="mdi-counter" />
          </v-col>
          <v-col v-if="form.trigger_type === 'engine_hours'" cols="6">
            <v-text-field v-model.number="form.next_due_engine_hours" label="Next Due Engine Hours" type="number" variant="outlined" density="compact" hide-details="auto" suffix="hrs" prepend-inner-icon="mdi-engine-outline" />
          </v-col>
          <v-col cols="6">
            <v-select v-model="form.escalation_level" :items="escalationOptions" item-title="label" item-value="value" label="Escalation Level" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-shield-alert-outline" />
          </v-col>
          <v-col cols="6">
            <v-select v-model="form.auto_generate_work_order" :items="booleanOptions" item-title="label" item-value="value" label="Auto-Generate WO" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-clipboard-plus-outline" />
          </v-col>
          <v-col cols="6">
            <v-select v-model="form.is_active" :items="booleanOptions" item-title="label" item-value="value" label="Active" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-power-standby" />
          </v-col>
        </v-row>
      </v-card-text>
      <v-card-actions class="px-4 pb-4">
        <v-spacer />
        <v-btn variant="text" @click="$emit('update:modelValue', false)">Cancel</v-btn>
        <v-btn color="primary" prepend-icon="mdi-check" :loading="saving" @click="onSave">{{ editing ? 'Update' : 'Create' }}</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
const props = defineProps<{
  modelValue: boolean; editing: boolean; saving: boolean
  vehicleOptions: any[]
}>()
const emit = defineEmits<{ 'update:modelValue': [v: boolean]; save: [payload: any] }>()

const triggerTypes = [
  { label: 'Time (Months)', value: 'time' },
  { label: 'Mileage', value: 'mileage' },
  { label: 'Engine Hours', value: 'engine_hours' },
]
const escalationOptions = [
  { label: 'None', value: 0 },
  { label: 'Email Driver', value: 1 },
  { label: 'SMS Manager', value: 2 },
  { label: 'Block Dispatch', value: 3 },
]
const booleanOptions = [
  { label: 'Yes', value: true },
  { label: 'No', value: false },
]

function defaultForm() {
  return { title: '', vehicle: null, trigger_type: 'time', trigger_interval: 6, next_due_date: null, next_due_mileage: null, next_due_engine_hours: null, escalation_level: 0, auto_generate_work_order: true, is_active: true }
}

const form = reactive<any>(defaultForm())
const errors = reactive<any>({})

const intervalSuffix = computed(() => {
  if (form.trigger_type === 'time') return 'months'
  if (form.trigger_type === 'mileage') return 'miles'
  return 'hours'
})

defineExpose({
  reset: (r?: any) => {
    Object.assign(form, defaultForm())
    Object.keys(errors).forEach(k => delete errors[k])
    if (r) populate(r)
  },
})
function populate(r: any) {
  Object.assign(form, {
    title: r.title || '', vehicle: r.vehicle, trigger_type: r.trigger_type || 'time',
    trigger_interval: r.trigger_interval || 6, next_due_date: r.next_due_date || null,
    next_due_mileage: r.next_due_mileage || null, next_due_engine_hours: r.next_due_engine_hours || null,
    escalation_level: r.escalation_level ?? 0, auto_generate_work_order: r.auto_generate_work_order ?? true,
    is_active: r.is_active ?? true, _id: r.id,
  })
}

function onSave() {
  Object.keys(errors).forEach(k => delete errors[k])
  errors.title = form.title ? '' : 'Title is required'
  errors.vehicle = form.vehicle ? '' : 'Vehicle is required'
  if (!form.title || !form.vehicle) return
  const payload: any = { ...form }
  if (!payload.next_due_date) delete payload.next_due_date
  if (!payload.next_due_mileage) delete payload.next_due_mileage
  if (!payload.next_due_engine_hours) delete payload.next_due_engine_hours
  emit('save', payload)
}
</script>
