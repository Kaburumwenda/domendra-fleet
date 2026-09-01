<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="560" scrollable>
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-clipboard-edit-outline">{{ editing ? 'Edit Work Order' : 'New Work Order' }}</AppModalHeader>
      <v-card-text>
        <v-row dense>
          <v-col cols="12">
            <v-select v-model="form.issue" :items="openIssues" item-title="title" item-value="id" label="Issue *" variant="outlined" density="compact" hide-details="auto" :error-messages="errors.issue" prepend-inner-icon="mdi-alert-circle-outline" :disabled="editing">
              <template #item="{ item, props }">
                <v-list-item v-bind="props" :disabled="item.raw.has_work_order" :subtitle="item.raw.has_work_order ? 'Already has a work order' : undefined" />
              </template>
            </v-select>
          </v-col>
          <v-col cols="6">
            <v-select v-model="form.assigned_to" :items="mechanics" item-title="full_name" item-value="id" label="Assign To" variant="outlined" density="compact" hide-details="auto" clearable prepend-inner-icon="mdi-account-hard-hat" />
          </v-col>
          <v-col cols="6">
            <v-select v-model="form.assignment_type" :items="assignmentOptions" item-title="label" item-value="value" label="Assignment Type" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-swap-horizontal" />
          </v-col>
          <v-col cols="6">
            <v-select v-model="form.status" :items="statusOptions" item-title="label" item-value="value" label="Status" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-state-machine" />
          </v-col>
          <v-col cols="6">
            <v-text-field v-model="form.estimated_cost" :label="`Estimated Cost (${currencySymbol})`" type="number" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-cash" :prefix="currencySymbol" />
          </v-col>
          <v-col cols="12">
            <v-textarea v-model="form.internal_notes" label="Internal Notes" rows="2" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-shield-lock-outline" />
          </v-col>
          <v-col cols="12">
            <v-textarea v-model="form.external_notes" label="External Notes (visible to driver/manager)" rows="2" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-eye-outline" />
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
  modelValue: boolean; editing: boolean; saving: boolean; currencySymbol: string
  openIssues: any[]; mechanics: any[]
}>()
const emit = defineEmits<{ 'update:modelValue': [v: boolean]; save: [payload: any] }>()

const statusOptions = [
  { label: 'Open', value: 'open' }, { label: 'Assigned', value: 'assigned' },
  { label: 'Parts Ordered', value: 'parts_ordered' }, { label: 'In Progress', value: 'in_progress' },
  { label: 'On Hold', value: 'on_hold' }, { label: 'Completed', value: 'completed' },
  { label: 'Closed', value: 'closed' },
]
const assignmentOptions = [
  { label: 'Internal Mechanic', value: 'internal' },
  { label: 'External Shop', value: 'external' },
]

const form = reactive<any>({ issue: null, assigned_to: null, assignment_type: 'internal', status: 'assigned', estimated_cost: '0', internal_notes: '', external_notes: '' })
const errors = reactive<any>({})

function reset(wo?: any) {
  if (wo) {
    Object.assign(form, {
      issue: wo.issue, assigned_to: wo.assigned_to, assignment_type: wo.assignment_type || 'internal',
      status: wo.status || 'assigned', estimated_cost: wo.estimated_cost || '0',
      internal_notes: wo.internal_notes || '', external_notes: wo.external_notes || '', _id: wo.id,
    })
  } else {
    Object.assign(form, { issue: null, assigned_to: null, assignment_type: 'internal', status: 'assigned', estimated_cost: '0', internal_notes: '', external_notes: '', _id: undefined })
  }
  Object.keys(errors).forEach(k => delete errors[k])
}

function validate(): boolean {
  Object.keys(errors).forEach(k => delete errors[k])
  if (!form.issue) errors.issue = 'Issue is required'
  return Object.keys(errors).length === 0
}

function onSave() {
  if (!validate()) return
  const { _id, ...body } = form
  if (body.estimated_cost !== undefined) body.estimated_cost = parseFloat(body.estimated_cost) || 0
  if (_id) body._id = _id
  emit('save', body)
}

defineExpose({ reset, populate: reset, form })
</script>
