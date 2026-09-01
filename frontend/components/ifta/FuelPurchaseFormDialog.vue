<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="520" scrollable>
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-gas-station">{{ editing ? 'Edit Fuel Purchase' : 'Add Fuel Purchase' }}</AppModalHeader>
      <v-card-text>
        <v-row dense>
          <v-col cols="6"><v-select v-model="form.vehicle" :items="vehicleOptions" item-title="display_name" item-value="id" label="Vehicle *" :rules="[v => !!v || 'Required']" /></v-col>
          <v-col cols="6"><v-select v-model="form.jurisdiction" :items="jurisdictionOptions" item-title="name" item-value="id" label="Jurisdiction *" :rules="[v => !!v || 'Required']" /></v-col>
          <v-col cols="6"><v-text-field v-model="form.date" type="date" label="Date *" /></v-col>
          <v-col cols="6"><v-text-field v-model.number="form.gallons" label="Gallons *" type="number" :rules="[v => v > 0 || 'Required']" /></v-col>
          <v-col cols="6"><v-text-field v-model.number="form.total_cost" label="Total Cost" type="number" prefix="$" /></v-col>
          <v-col cols="6"><v-text-field v-model.number="form.tax_paid" label="Tax Paid at Pump" type="number" prefix="$" /></v-col>
          <v-col cols="12"><v-text-field v-model="form.vendor" label="Vendor" /></v-col>
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

const defaultForm = () => ({
  vehicle: null as any, jurisdiction: null as any, date: new Date().toISOString().slice(0, 10),
  gallons: null as number | null, total_cost: 0, tax_paid: 0, vendor: '', source: 'manual', notes: '',
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
