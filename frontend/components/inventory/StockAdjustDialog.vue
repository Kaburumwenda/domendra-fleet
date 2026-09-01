<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="520" scrollable>
    <v-card rounded="xl">
      <AppModalHeader :icon="'mdi-swap-horizontal'">Stock Adjustment</AppModalHeader>
      <v-card-text>
        <div class="mb-3">
          <p class="text-subtitle-2 font-weight-bold">{{ item?.name }}</p>
          <p class="text-caption text-medium-emphasis">SKU: {{ item?.sku }} · On Hand: {{ item?.quantity_on_hand }}</p>
        </div>
        <v-row dense>
          <v-col cols="12">
            <v-select
              v-model="form.transaction_type"
              :items="typeOptions"
              item-title="label"
              item-value="value"
              label="Transaction Type *"
              density="compact" variant="outlined" hide-details
            />
          </v-col>
          <v-col cols="6"><v-text-field v-model.number="form.quantity" label="Quantity *" type="number" density="compact" variant="outlined" hide-details /></v-col>
          <v-col cols="6"><v-text-field v-model="form.unit_cost" :label="`Unit Cost (${currencySymbol})`" type="number" density="compact" variant="outlined" hide-details hint="Optional — defaults to item cost" persistent-hint /></v-col>
          <v-col cols="12"><v-text-field v-model="form.reference" label="Reference (PO, WO, etc.)" density="compact" variant="outlined" hide-details /></v-col>
          <v-col cols="12"><v-textarea v-model="form.notes" label="Notes" rows="2" density="compact" variant="outlined" hide-details /></v-col>
        </v-row>
        <v-alert v-if="form.transaction_type === 'out'" type="info" density="compact" variant="tonal" class="mt-2" border="start">
          Stock Out will decrement quantity by the absolute value.
        </v-alert>
      </v-card-text>
      <v-card-actions class="px-4 pb-4">
        <v-spacer />
        <v-btn variant="text" @click="$emit('update:modelValue', false)">Cancel</v-btn>
        <v-btn color="primary" prepend-icon="mdi-check" @click="$emit('save', { ...form })" :loading="saving">Apply</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
defineProps<{ modelValue: boolean; saving: boolean; item: any }>()
defineEmits<{ 'update:modelValue': [v: boolean]; save: [form: any] }>()
const { currencySymbol } = useCurrency()
const typeOptions = [
  { label: 'Stock In', value: 'in' },
  { label: 'Stock Out', value: 'out' },
  { label: 'Adjustment', value: 'adjust' },
  { label: 'Transfer', value: 'transfer' },
]
const form = reactive<any>({ transaction_type: 'in', quantity: 0, unit_cost: '', reference: '', notes: '' })
function reset(item?: any) {
  Object.assign(form, { transaction_type: 'in', quantity: 0, unit_cost: '', reference: '', notes: '' })
  if (item) form.unit_cost = item.unit_cost != null ? String(item.unit_cost) : ''
}
defineExpose({ reset })
</script>
