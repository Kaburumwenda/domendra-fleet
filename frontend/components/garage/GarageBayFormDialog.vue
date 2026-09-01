<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="500" scrollable>
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-garage">{{ editing ? 'Edit Garage Bay' : 'Add Garage Bay' }}</AppModalHeader>
      <v-card-text>
        <v-row dense>
          <v-col cols="12">
            <v-text-field v-model="form.name" label="Bay Name *" variant="outlined" density="compact" hide-details="auto" :error-messages="errors.name" prepend-inner-icon="mdi-tag" />
          </v-col>
          <v-col cols="6">
            <v-select v-model="form.bay_type" :items="bayTypes" item-title="label" item-value="value" label="Bay Type *" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-sitemap" />
          </v-col>
          <v-col cols="6">
            <v-text-field v-model.number="form.capacity" label="Capacity" type="number" min="1" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-parking" suffix="veh" />
          </v-col>
          <v-col cols="12">
            <v-textarea v-model="form.notes" label="Notes" rows="2" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-note-text" />
          </v-col>
          <v-col cols="12">
            <v-switch v-model="form.is_active" label="Active" density="compact" color="success" hide-details="auto" />
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
const props = defineProps<{ modelValue: boolean; editing: boolean; saving: boolean }>()
const emit = defineEmits<{ 'update:modelValue': [v: boolean]; save: [payload: any] }>()

const bayTypes = [
  { label: 'Lift Bay', value: 'lift' },
  { label: 'Flat Bay', value: 'flat' },
  { label: 'Paint Bay', value: 'paint' },
  { label: 'Wash Bay', value: 'wash' },
  { label: 'Inspection Bay', value: 'inspection' },
  { label: 'General Bay', value: 'general' },
]

function defaultForm() { return { name: '', bay_type: 'general', capacity: 1, notes: '', is_active: true } }

const form = reactive<any>(defaultForm())
const errors = reactive<any>({})

defineExpose({
  reset: (b?: any) => {
    Object.assign(form, defaultForm())
    Object.keys(errors).forEach(k => delete errors[k])
    if (b) Object.assign(form, { name: b.name, bay_type: b.bay_type, capacity: b.capacity, notes: b.notes || '', is_active: b.is_active ?? true, _id: b.id })
  },
})

function onSave() {
  Object.keys(errors).forEach(k => delete errors[k])
  errors.name = form.name ? '' : 'Bay name is required'
  if (!form.name) return
  emit('save', { ...form })
}
</script>
