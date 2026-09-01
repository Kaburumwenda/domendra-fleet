<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="520" scrollable>
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-account-wrench">
        {{ existingWO ? 'Update Work Order' : 'Assign & Create Work Order' }}
      </AppModalHeader>
      <v-card-text>
        <div class="d-flex flex-column ga-3">
          <div class="assignee-preview">
            <v-icon size="18" class="mr-1">mdi-alert-circle-outline</v-icon>
            <span class="text-body-2">{{ issue?.title || '—' }}</span>
            <span class="text-caption text-medium-emphasis ml-2">· {{ issue?.vehicle_name }}</span>
          </div>

          <v-select
            v-model="form.assigned_to"
            :items="mechanics"
            item-title="full_name"
            item-value="id"
            label="Assign To (Mechanic)"
            variant="outlined"
            density="compact"
            hide-details="auto"
            clearable
            prepend-inner-icon="mdi-account-hard-hat"
          />

          <v-select
            v-model="form.assignment_type"
            :items="assignmentOptions"
            item-title="label"
            item-value="value"
            label="Assignment Type"
            variant="outlined"
            density="compact"
            hide-details="auto"
            prepend-inner-icon="mdi-swap-horizontal"
          />

          <v-text-field
            v-model="form.estimated_cost"
            :label="`Estimated Cost (${currencySymbol})`"
            type="number"
            variant="outlined"
            density="compact"
            hide-details="auto"
            prepend-inner-icon="mdi-cash"
            :prefix="currencySymbol"
          />

          <v-expansion-panels class="mt-1" v-if="!existingWO">
            <v-expansion-panel title="Additional Notes (optional)">
              <v-expansion-panel-text>
                <v-textarea v-model="form.internal_notes" label="Internal Notes" rows="2" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-shield-lock-outline" />
                <v-textarea v-model="form.external_notes" label="External Notes (visible to driver)" rows="2" variant="outlined" density="compact" hide-details="auto" class="mt-3" prepend-inner-icon="mdi-eye-outline" />
              </v-expansion-panel-text>
            </v-expansion-panel>
          </v-expansion-panels>

          <v-alert v-if="existingWO" type="info" density="compact" variant="tonal" class="mt-1">
            This issue already has Work Order #{{ issue?.work_order_id }}. Updates will apply to the existing work order.
          </v-alert>
        </div>
      </v-card-text>
      <v-card-actions class="px-4 pb-4">
        <v-spacer />
        <v-btn variant="text" @click="$emit('update:modelValue', false)">Cancel</v-btn>
        <v-btn color="info" prepend-icon="mdi-check" :loading="saving" @click="onSubmit">
          {{ existingWO ? 'Update WO' : 'Create & Assign' }}
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
const props = defineProps<{
  modelValue: boolean; saving: boolean; currencySymbol: string
  mechanics: any[]; issue: any
}>()
const emit = defineEmits<{ 'update:modelValue': [v: boolean]; submit: [payload: any] }>()

const assignmentOptions = [
  { label: 'Internal Mechanic', value: 'internal' },
  { label: 'External Shop', value: 'external' },
]

const form = reactive<any>({
  assigned_to: null, assignment_type: 'internal', estimated_cost: '0',
  internal_notes: '', external_notes: '',
})

const existingWO = computed(() => !!props.issue?.has_work_order)

function reset(issue?: any) {
  if (issue && issue.has_work_order) {
    Object.assign(form, {
      assigned_to: null, assignment_type: 'internal', estimated_cost: '0',
      internal_notes: '', external_notes: '',
    })
  } else {
    Object.assign(form, {
      assigned_to: null, assignment_type: 'internal', estimated_cost: '0',
      internal_notes: '', external_notes: '',
    })
  }
}

function onSubmit() {
  const payload = { ...form }
  if (payload.estimated_cost) payload.estimated_cost = parseFloat(payload.estimated_cost)
  emit('submit', payload)
}

defineExpose({ reset, populate: reset, form })
</script>

<style scoped>
.assignee-preview { display: flex; align-items: center; padding: 10px 12px; background: #f8fafc; border-radius: 10px; border: 1px solid #e2e8f0; }
</style>
