<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="580" scrollable>
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-map-marker-path">{{ editing ? 'Edit Trip Log' : 'Add Trip Log' }}</AppModalHeader>
      <v-card-text>
        <v-row dense>
          <v-col cols="6"><v-select v-model="form.vehicle" :items="vehicleOptions" item-title="display_name" item-value="id" label="Vehicle *" :rules="[v => !!v || 'Required']" /></v-col>
          <v-col cols="6"><v-select v-model="form.jurisdiction" :items="jurisdictionOptions" item-title="name" item-value="id" label="Jurisdiction *" :rules="[v => !!v || 'Required']" /></v-col>
          <v-col cols="6"><v-text-field v-model="form.date" type="date" label="Date *" /></v-col>
          <v-col cols="6"><v-select v-model="form.distance_unit" :items="unitOptions" item-title="label" item-value="value" label="Unit" /></v-col>
          <v-col cols="6"><v-text-field v-model.number="form.start_odometer" label="Start Odometer" type="number" /></v-col>
          <v-col cols="6"><v-text-field v-model.number="form.end_odometer" label="End Odometer" type="number" /></v-col>
          <v-col cols="6"><v-text-field v-model.number="form.distance" label="Distance *" type="number" /></v-col>
          <v-col cols="6"><v-select v-model="form.trip_type" :items="tripTypeOptions" item-title="label" item-value="value" label="Trip Type" /></v-col>
          <v-col cols="12"><v-text-field v-model="form.route" label="Route (From / To)" /></v-col>
          <v-col cols="12"><v-textarea v-model="form.notes" label="Notes" rows="2" /></v-col>
        </v-row>
      </v-card-text>
      <v-divider />
      <v-card-actions class="px-4 pb-4">
        <v-spacer />
        <v-btn variant="text" @click="$emit('update:modelValue', false)">Cancel</v-btn>
        <v-btn color="primary" prepend-icon="mdi-check" @click="onSave" :loading="saving">{{ editing ? 'Update' : 'Save' }}</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
const props = defineProps<{ modelValue: boolean; editing: boolean; saving: boolean; vehicleOptions: any[]; jurisdictionOptions: any[] }>()
const emit = defineEmits<{ 'update:modelValue': [v: boolean]; save: [form: any] }>()

const unitOptions = [{ label: 'Miles', value: 'miles' }, { label: 'Kilometers', value: 'km' }]
const tripTypeOptions = [{ label: 'Loaded', value: 'loaded' }, { label: 'Empty', value: 'empty' }, { label: 'Bobtail', value: 'bobtail' }]

const defaultForm = () => ({
  vehicle: null as any, jurisdiction: null as any, date: new Date().toISOString().slice(0, 10),
  distance_unit: 'miles', start_odometer: null as number | null, end_odometer: null as number | null,
  distance: null as number | null, trip_type: 'loaded', route: '', notes: '', source: 'manual',
})

const form = reactive<any>(defaultForm())

function reset(r?: any) {
  Object.assign(form, defaultForm())
  if (r) {
    Object.keys(form).forEach(k => { if (k in r) form[k] = r[k] })
    form._id = r.id
  }
}

function onSave() { emit('save', { ...form }) }

defineExpose({ reset })
</script>
