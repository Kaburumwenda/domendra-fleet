<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="680" scrollable>
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-car-info">{{ editing ? 'Edit Recall' : 'Add Recall' }}</AppModalHeader>
      <v-card-text>
        <v-row dense>
          <v-col cols="12"><v-text-field v-model="form.title" label="Title *" :rules="[v => !!v || 'Required']" /></v-col>
          <v-col cols="6">
            <v-select v-model="form.recall_type" :items="typeOptions" item-title="label" item-value="value" label="Type *" />
          </v-col>
          <v-col cols="6">
            <v-select v-model="form.status" :items="statusOptions" item-title="label" item-value="value" label="Status" />
          </v-col>
          <v-col cols="6"><v-text-field v-model="form.nhtsa_campaign_number" label="NHTSA Campaign #" /></v-col>
          <v-col cols="6"><v-text-field v-model="form.manufacturer_campaign_number" label="Manufacturer Campaign #" /></v-col>
          <v-col cols="6"><v-text-field v-model="form.oem" label="Manufacturer / OEM" /></v-col>
          <v-col cols="6"><v-text-field v-model="form.component" label="Component" /></v-col>
          <v-col cols="6"><v-text-field v-model="form.affected_make" label="Affected Make" /></v-col>
          <v-col cols="6"><v-text-field v-model="form.affected_models" label="Affected Models (comma-separated)" /></v-col>
          <v-col cols="6"><v-text-field v-model.number="form.affected_year_from" label="Year From" type="number" /></v-col>
          <v-col cols="6"><v-text-field v-model.number="form.affected_year_to" label="Year To" type="number" /></v-col>
          <v-col cols="6"><v-text-field v-model="form.issue_date" label="Issue Date" type="date" /></v-col>
          <v-col cols="6">
            <v-switch v-model="form.is_critical" label="Critical Safety Risk" density="compact" color="error" hide-details />
          </v-col>
          <v-col cols="12"><v-textarea v-model="form.description" label="Description" rows="2" /></v-col>
          <v-col cols="12"><v-textarea v-model="form.remedy" label="Remedy" rows="2" /></v-col>
          <v-col cols="12"><v-textarea v-model="form.risk" label="Safety Risk" rows="2" /></v-col>
        </v-row>
      </v-card-text>
      <v-divider />
      <v-card-actions class="px-4 pb-4">
        <v-spacer />
        <v-btn variant="text" @click="$emit('update:modelValue', false)">Cancel</v-btn>
        <v-btn color="primary" prepend-icon="mdi-check" @click="onSave" :loading="saving">{{ editing ? 'Update' : 'Create' }}</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
const props = defineProps<{ modelValue: boolean; editing: boolean; saving: boolean }>()
const emit = defineEmits<{ 'update:modelValue': [v: boolean]; save: [form: any] }>()

const typeOptions = [
  { label: 'Safety Recall', value: 'safety_recall' },
  { label: 'Service Campaign', value: 'campaign' },
  { label: 'Field Notice', value: 'field_notice' },
  { label: 'Emission Recall', value: 'emission' },
]
const statusOptions = [
  { label: 'Open', value: 'open' },
  { label: 'In Progress', value: 'in_progress' },
  { label: 'Completed', value: 'completed' },
  { label: 'Closed', value: 'closed' },
]

const defaultForm = () => ({
  title: '', recall_type: 'safety_recall', status: 'open', nhtsa_campaign_number: '',
  manufacturer_campaign_number: '', oem: '', component: '', affected_make: '',
  affected_models: '', affected_year_from: null as number | null, affected_year_to: null as number | null,
  issue_date: '', is_critical: false, description: '', remedy: '', risk: '',
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
