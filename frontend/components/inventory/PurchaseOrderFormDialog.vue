<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="560" scrollable>
    <v-card rounded="xl">
      <AppModalHeader :icon="editing ? 'mdi-clipboard-text-edit' : 'mdi-clipboard-plus'">{{ editing ? 'Edit Purchase Order' : 'New Purchase Order' }}</AppModalHeader>
      <v-card-text>
        <v-row dense>
          <v-col cols="6">
            <v-autocomplete v-model="form.vendor" :items="vendorOptions" item-title="full_name" item-value="id" label="Vendor" density="compact" variant="outlined" hide-details clearable />
          </v-col>
          <v-col cols="6">
            <v-autocomplete v-model="form.location" :items="locationOptions" item-title="name" item-value="id" label="Destination Location" density="compact" variant="outlined" hide-details clearable />
          </v-col>
          <v-col cols="12"><v-textarea v-model="form.notes" label="Notes" rows="2" density="compact" variant="outlined" hide-details /></v-col>
        </v-row>
        <v-divider class="my-3" />
        <p class="text-subtitle-2 font-weight-bold mb-2">Line Items</p>
        <div v-if="!form.lines.length" class="text-center py-4 text-medium-emphasis">
          <v-icon size="32" class="mb-2">mdi-package-variant-closed</v-icon>
          <p class="text-caption">No line items yet. Click below to add one.</p>
        </div>
        <div v-for="(line, idx) in form.lines" :key="idx" class="line-item pa-3 mb-2 rounded-lg">
          <div class="d-flex align-center ga-2">
            <v-select v-model="line.inventory_item" :items="itemOptions" item-title="name" item-value="id" label="Item" density="compact" variant="outlined" hide-details style="flex:1" />
            <v-text-field v-model.number="line.quantity_ordered" label="Qty" type="number" density="compact" variant="outlined" hide-details style="max-width:70px" />
            <v-text-field v-model="line.unit_cost" :label="`Cost (${currencySymbol})`" type="number" density="compact" variant="outlined" hide-details style="max-width:90px" />
            <v-icon icon="mdi-close" color="error" size="small" @click="form.lines.splice(idx, 1)" class="cursor-pointer" />
          </div>
        </div>
        <v-btn variant="text" size="small" prepend-icon="mdi-plus" @click="addLine" class="mt-2">Add Line Item</v-btn>
        <div v-if="lineTotal" class="text-right mt-2">
          <span class="text-caption text-medium-emphasis">Total: </span>
          <span class="text-h6 font-weight-bold text-primary">{{ lineTotal }}</span>
        </div>
      </v-card-text>
      <v-card-actions class="px-4 pb-4">
        <v-spacer />
        <v-btn variant="text" @click="$emit('update:modelValue', false)">Cancel</v-btn>
        <v-btn color="primary" prepend-icon="mdi-check" @click="$emit('save', buildPayload())" :loading="saving">{{ editing ? 'Update' : 'Create' }}</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
defineProps<{ modelValue: boolean; editing: boolean; saving: boolean; vendorOptions: any[]; locationOptions: any[]; itemOptions: any[] }>()
const emit = defineEmits<{ 'update:modelValue': [v: boolean]; save: [form: any] }>()
const { currencySymbol } = useCurrency()
const form = reactive<any>({ _id: null, vendor: null, location: null, notes: '', lines: [] as any[] })

function addLine() { form.lines.push({ inventory_item: null, quantity_ordered: 1, unit_cost: '0' }) }
function reset(r?: any) {
  Object.assign(form, { _id: null, vendor: null, location: null, notes: '', lines: [] })
  if (r) {
    form._id = r.id; form.vendor = r.vendor; form.location = r.location; form.notes = r.notes || ''
    form.lines = (r.items || []).map((i: any) => ({ ...i, inventory_item: i.inventory_item }))
  } else {
    addLine()
  }
}
const lineTotal = computed(() => currencySymbol.value + form.lines.reduce((sum: number, l: any) => {
  const qty = parseFloat(l.quantity_ordered) || 0; const cost = parseFloat(l.unit_cost) || 0; return sum + qty * cost
}, 0).toFixed(2))
function buildPayload() { return { vendor: form.vendor, location: form.location, notes: form.notes, lines: form.lines.map((l:any) => ({ inventory_item: l.inventory_item, quantity_ordered: l.quantity_ordered, unit_cost: l.unit_cost, ...(l.id ? { id: l.id } : {}) })) } }
defineExpose({ reset })
</script>

<style scoped>
.line-item { border: 1px solid #e2e8f0; background: #f8fafc; }
.cursor-pointer { cursor: pointer; }
</style>
