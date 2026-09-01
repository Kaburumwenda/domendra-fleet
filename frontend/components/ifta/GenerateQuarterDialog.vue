<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="460">
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-sync">Generate Quarterly Report</AppModalHeader>
      <v-card-text>
        <v-row dense>
          <v-col cols="12"><v-select v-model="form.vehicle" :items="vehicleOptions" item-title="display_name" item-value="id" label="Vehicle *" :rules="[v => !!v || 'Required']" /></v-col>
          <v-col cols="6"><v-text-field v-model.number="form.year" label="Year" type="number" /></v-col>
          <v-col cols="6"><v-select v-model="form.quarter" :items="quarterOptions" item-title="label" item-value="value" label="Quarter *" /></v-col>
        </v-row>
        <p class="text-caption text-medium-emphasis mt-2"><v-icon size="14">mdi-information</v-icon> This aggregates all trip logs and fuel purchases for the selected period into a quarterly IFTA report.</p>
      </v-card-text>
      <v-divider />
      <v-card-actions class="px-4 pb-4">
        <v-spacer />
        <v-btn variant="text" @click="$emit('update:modelValue', false)">Cancel</v-btn>
        <v-btn color="primary" prepend-icon="mdi-sync" @click="onGenerate" :loading="saving">Generate Report</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
const props = defineProps<{ modelValue: boolean; saving: boolean; vehicleOptions: any[] }>()
const emit = defineEmits<{ 'update:modelValue': [v: boolean]; generate: [form: any] }>()

const quarterOptions = [
  { label: 'Q1 (Jan–Mar)', value: 'Q1' },
  { label: 'Q2 (Apr–Jun)', value: 'Q2' },
  { label: 'Q3 (Jul–Sep)', value: 'Q3' },
  { label: 'Q4 (Oct–Dec)', value: 'Q4' },
]

const defaultForm = () => ({
  vehicle: null as any, year: new Date().getFullYear(), quarter: 'Q1',
})

const form = reactive<any>(defaultForm())

watch(() => props.modelValue, (v) => {
  if (v) Object.assign(form, defaultForm())
})

function onGenerate() { emit('generate', { ...form }) }
</script>
