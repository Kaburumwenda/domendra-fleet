<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="640" scrollable>
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-wrench-edit">{{ editing ? 'Edit Service' : 'Log Service' }}</AppModalHeader>
      <v-card-text>
        <v-row dense>
          <v-col cols="12">
            <v-select v-model="form.vehicle" :items="vehicleOptions" item-title="display_name" item-value="id" label="Vehicle *" variant="outlined" density="compact" hide-details="auto" :error-messages="errors.vehicle">
              <template #selection="{ item }">
                <span class="font-weight-medium">{{ item.raw.display_name }}</span>
                <span v-if="item.raw.license_plate" class="text-caption text-medium-emphasis ml-2">· {{ item.raw.license_plate }}</span>
              </template>
              <template #item="{ item, props }">
                <v-list-item v-bind="props" :title="item.raw.display_name" :subtitle="item.raw.license_plate || 'No plate'" />
              </template>
            </v-select>
          </v-col>
          <v-col cols="6">
            <v-select v-model="form.service_type" :items="serviceTypes" item-title="label" item-value="value" label="Service Type *" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-wrench" />
          </v-col>
          <v-col cols="6">
            <v-text-field v-model="form.performed_at" type="datetime-local" label="Performed At *" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-calendar-clock" />
          </v-col>
          <v-col cols="6">
            <v-text-field v-model="form.cost" :label="`Cost (${currencySymbol})`" type="number" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-cash" prefix="$" />
          </v-col>
          <v-col cols="6">
            <v-text-field v-model.number="form.odometer_reading" label="Odometer Reading" type="number" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-counter" suffix="mi" />
          </v-col>
          <v-col cols="6">
            <v-select v-model="form.vendor" :items="vendorOptions" item-title="full_name" item-value="id" label="Vendor" variant="outlined" density="compact" hide-details="auto" clearable prepend-inner-icon="mdi-store" />
          </v-col>
          <v-col cols="6">
            <v-text-field v-model.number="form.downtime_hours" label="Downtime (hrs)" type="number" step="0.5" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-timer-sand" />
          </v-col>
          <v-col cols="12">
            <v-select v-model="form.work_order" :items="filteredWorkOrders" item-title="label" item-value="id" label="Work Order *" variant="outlined" density="compact" hide-details="auto" :error-messages="errors.work_order" prepend-inner-icon="mdi-clipboard-list-outline">
              <template #item="{ item, props }">
                <v-list-item v-bind="props" :disabled="(usedWorkOrderIds || []).includes(item.raw.id)" :subtitle="(usedWorkOrderIds || []).includes(item.raw.id) ? 'Already used by another service' : undefined" />
              </template>
            </v-select>
          </v-col>
          <v-col cols="12">
            <v-textarea v-model="form.description" label="Description / Notes" rows="3" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-note-text" />
          </v-col>
        </v-row>
      </v-card-text>
      <v-card-actions class="px-4 pb-4">
        <v-spacer />
        <v-btn variant="text" @click="$emit('update:modelValue', false)">Cancel</v-btn>
        <v-btn color="primary" prepend-icon="mdi-check" :loading="saving" @click="onSave">{{ editing ? 'Update' : 'Save' }}</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
const props = defineProps<{
  modelValue: boolean; editing: boolean; saving: boolean; currencySymbol: string
  vehicleOptions: any[]; vendorOptions: any[]; workOrderOptions: any[]; usedWorkOrderIds?: number[]
}>()
const emit = defineEmits<{ 'update:modelValue': [v: boolean]; save: [payload: any] }>()

const serviceTypes = [
  { label: 'Oil Change', value: 'oil_change' }, { label: 'Tire Rotation', value: 'tire_rotation' },
  { label: 'Brake Service', value: 'brake_service' }, { label: 'Inspection', value: 'inspection' },
  { label: 'Repair', value: 'repair' }, { label: 'Preventive', value: 'preventive' }, { label: 'Other', value: 'other' },
]

const form = reactive<any>(defaultForm())
const errors = reactive<any>({})

// Lay out raw work-order records (with vehicle_id) for filtering
const workOrderRecords = computed(() => {
  // workOrderOptions items are { id, label } but we need vehicle_id; rebuild from raw prop if available
  return (props.workOrderOptions || []).map((w: any) => w)
})

// Filter work orders by the selected vehicle
const filteredWorkOrders = computed(() => {
  const all = props.workOrderOptions || []
  if (!form.vehicle) return all
  // Each item may carry a `vehicle` field; if not, fall back to matching by label text
  return all.filter((w: any) => {
    if (w.vehicle_id != null) return w.vehicle_id === form.vehicle
    if (w.vehicle != null) return w.vehicle === form.vehicle
    return true // can't filter — show all
  })
})

// Clear work order if it's not in filtered list when vehicle changes
watch(() => form.vehicle, () => {
  if (form.work_order && !filteredWorkOrders.value.some((w: any) => w.id === form.work_order)) {
    form.work_order = null
  }
})

function defaultForm() {
  return { vehicle: null, service_type: 'preventive', performed_at: new Date().toISOString().slice(0, 16), cost: '0', vendor: null, odometer_reading: null, downtime_hours: 0, description: '', work_order: null }
}

defineExpose({
  reset: (s?: any) => {
    Object.assign(form, defaultForm())
    Object.keys(errors).forEach(k => delete errors[k])
    if (s) populate(s)
  },
})
function populate(s: any) {
  Object.assign(form, {
    vehicle: s.vehicle, service_type: s.service_type || 'preventive',
    performed_at: s.performed_at ? new Date(s.performed_at).toISOString().slice(0, 16) : '',
    cost: s.cost != null ? String(s.cost) : '0',
    vendor: s.vendor, odometer_reading: s.odometer_reading, downtime_hours: s.downtime_hours || 0,
    description: s.description || '', work_order: s.work_order, _id: s.id,
  })
}

function onSave() {
  errors.vehicle = form.vehicle ? '' : 'Vehicle is required'
  errors.work_order = form.work_order ? '' : 'Work order is required'
  if (!form.vehicle || !form.work_order) return
  const payload: any = { ...form }
  if (payload.cost != null) payload.cost = parseFloat(payload.cost)
  if (payload.performed_at) payload.performed_at = new Date(payload.performed_at).toISOString()
  else if (!payload.performed_at) return
  emit('save', payload)
}
</script>
