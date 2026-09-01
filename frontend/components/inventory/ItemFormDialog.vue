<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="640" scrollable>
    <v-card rounded="xl">
      <AppModalHeader :icon="editing ? 'mdi-package-variant-closed' : 'mdi-plus'">{{ editing ? 'Edit Parts Item' : 'Add Parts Item' }}</AppModalHeader>
      <v-card-text>
        <v-row dense>
          <v-col cols="6"><v-text-field v-model="form.sku" label="SKU *" density="compact" variant="outlined" hide-details /></v-col>
          <v-col cols="6"><v-text-field v-model="form.barcode" label="Barcode" density="compact" variant="outlined" hide-details /></v-col>
          <v-col cols="8"><v-text-field v-model="form.name" label="Name *" density="compact" variant="outlined" hide-details /></v-col>
          <v-col cols="4"><v-text-field v-model="form.category" label="Category" density="compact" variant="outlined" hide-details /></v-col>
          <v-col cols="6">
            <v-select v-model="form.location" :items="locationOptions" item-title="name" item-value="id" label="Location" density="compact" variant="outlined" hide-details clearable />
          </v-col>
          <v-col cols="6"><v-text-field v-model="form.bin_location" label="Bin Location" density="compact" variant="outlined" hide-details /></v-col>
          <v-col cols="4"><v-text-field v-model.number="form.quantity_on_hand" label="Qty On Hand" type="number" density="compact" variant="outlined" hide-details /></v-col>
          <v-col cols="4"><v-text-field v-model.number="form.reorder_point" label="Reorder Point" type="number" density="compact" variant="outlined" hide-details /></v-col>
          <v-col cols="4"><v-text-field v-model.number="form.max_stock" label="Max Stock" type="number" density="compact" variant="outlined" hide-details /></v-col>
          <v-col cols="6"><v-text-field v-model="form.unit_cost" :label="`Unit Cost (${currencySymbol})`" type="number" density="compact" variant="outlined" hide-details /></v-col>
          <v-col cols="6">
            <v-select v-model="form.costing_method" :items="['FIFO','LIFO','AVERAGE']" label="Costing Method" density="compact" variant="outlined" hide-details />
          </v-col>
          <v-col cols="12"><v-textarea v-model="form.description" label="Description" rows="2" density="compact" variant="outlined" hide-details /></v-col>
          <v-col cols="12">
            <v-switch v-model="form.is_active" label="Active" color="primary" density="compact" hide-details inset />
          </v-col>
        </v-row>
      </v-card-text>
      <v-card-actions class="px-4 pb-4">
        <v-spacer />
        <v-btn variant="text" @click="$emit('update:modelValue', false)">Cancel</v-btn>
        <v-btn color="primary" prepend-icon="mdi-check" @click="$emit('save', { ...form })" :loading="saving">{{ editing ? 'Update' : 'Create' }}</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
defineProps<{ modelValue: boolean; editing: boolean; saving: boolean; locationOptions: any[] }>()
const emit = defineEmits<{ 'update:modelValue': [v: boolean]; save: [form: any] }>()
const { currencySymbol } = useCurrency()
const form = reactive<any>({
  _id: null, sku: '', name: '', barcode: '', category: '',
  location: null, bin_location: '',
  quantity_on_hand: 0, reorder_point: 0, max_stock: 0,
  unit_cost: '0', costing_method: 'FIFO',
  description: '', is_active: true,
})

function reset(r?: any) {
  Object.assign(form, {
    _id: null, sku: '', name: '', barcode: '', category: '',
    location: null, bin_location: '',
    quantity_on_hand: 0, reorder_point: 0, max_stock: 0,
    unit_cost: '0', costing_method: 'FIFO',
    description: '', is_active: true,
  })
  if (r) {
    Object.assign(form, {
      _id: r.id, sku: r.sku || '', name: r.name || '', barcode: r.barcode || '',
      category: r.category || '', location: r.location || null,
      bin_location: r.bin_location || '',
      quantity_on_hand: r.quantity_on_hand || 0,
      reorder_point: r.reorder_point || 0,
      max_stock: r.max_stock || 0,
      unit_cost: r.unit_cost != null ? String(r.unit_cost) : '0',
      costing_method: r.costing_method || 'FIFO',
      description: r.description || '', is_active: r.is_active !== false,
    })
  }
}

defineExpose({ reset })
</script>
