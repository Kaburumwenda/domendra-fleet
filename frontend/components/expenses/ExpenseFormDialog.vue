<template>
  <v-dialog v-model="dialog" max-width="780" scroll-strategy="none" persistent>
    <v-card rounded="xl" class="overflow-hidden">
      <AppModalHeader icon="mdi-receipt-text-plus">{{ editing ? 'Edit' : 'New' }} Expense</AppModalHeader>
      <v-card-text class="pt-5" style="max-height: 70vh; overflow-y: auto">
        <v-row dense>
          <v-col cols="12">
            <v-text-field v-model="form.title" label="Title *" hide-details="auto" density="compact" variant="outlined" />
          </v-col>
          <v-col cols="12" md="6">
            <v-select v-model="form.category" :items="categoryOptions" item-title="name" item-value="id" label="Category" hide-details="auto" density="compact" variant="outlined" clearable />
          </v-col>
          <v-col cols="12" md="6">
            <v-menu v-model="dateMenu" :close-on-content-click="false" transition="scale-transition" location="bottom start">
              <template #activator="{ props: p }">
                <v-text-field v-bind="p" v-model="form.expense_date" label="Expense Date *" prepend-inner-icon="mdi-calendar" readonly density="compact" variant="outlined" hide-details="auto" />
              </template>
              <v-date-picker v-model="form.expense_date" @update:model-value="dateMenu = false" />
            </v-menu>
          </v-col>
          <v-col cols="12" md="4">
            <v-text-field v-model.number="form.amount" label="Amount *" prepend-inner-icon="mdi-cash" type="number" min="0" step="0.01" density="compact" variant="outlined" hide-details="auto" />
          </v-col>
          <v-col cols="12" md="4">
            <v-text-field v-model.number="form.tax_rate" label="Tax Rate (decimal)" placeholder="e.g. 0.0825" density="compact" variant="outlined" hide-details="auto" />
          </v-col>
          <v-col cols="12" md="4">
            <v-text-field :model-value="computedTax" label="Tax Amount" readonly density="compact" variant="outlined" hide-details="auto" :prefix="currencySymbol" />
          </v-col>
          <v-col cols="12" md="6">
            <v-text-field v-model="form.vendor_name" label="Vendor / Merchant" density="compact" variant="outlined" hide-details="auto" />
          </v-col>
          <v-col cols="12" md="6">
            <v-select v-model="form.payment_method" :items="paymentMethods" item-title="label" item-value="value" label="Payment Method" hide-details="auto" density="compact" variant="outlined" />
          </v-col>
          <v-col cols="12" md="6">
            <v-select v-model="form.vehicle" :items="vehicleOptions" item-title="display_name" item-value="id" label="Vehicle" hide-details="auto" density="compact" variant="outlined" clearable />
          </v-col>
          <v-col cols="12" md="6">
            <v-select v-model="form.contact" :items="contactOptions" item-title="full_name" item-value="id" label="Contact (Driver / Vendor)" hide-details="auto" density="compact" variant="outlined" clearable />
          </v-col>
          <v-col cols="12" md="6">
            <v-text-field v-model="form.payment_reference" label="Payment Reference" density="compact" variant="outlined" hide-details="auto" />
          </v-col>
          <v-col cols="12" md="6">
            <v-text-field v-model="form.tags" label="Tags (comma-separated)" density="compact" variant="outlined" hide-details="auto" />
          </v-col>
          <v-col cols="12">
            <v-textarea v-model="form.description" label="Description" rows="2" density="compact" variant="outlined" hide-details="auto" />
          </v-col>
          <v-col cols="12">
            <v-textarea v-model="form.notes" label="Notes" rows="2" density="compact" variant="outlined" hide-details="auto" />
          </v-col>
          <v-col v-if="form._id" cols="12">
            <div class="d-flex align-center ga-2 mb-2">
              <v-icon size="small" color="primary">mdi-paperclip</v-icon>
              <span class="text-body-2 font-weight-medium">Receipts / Attachments</span>
            </div>
            <v-file-input
              v-model="pendingFiles"
              multiple
              chips
              counter
              show-size
              prepend-icon="mdi-upload"
              label="Upload receipts / invoices"
              density="compact"
              variant="outlined"
              accept="image/*,.pdf"
            />
            <div v-if="(form._attachments || []).length" class="mt-2">
              <v-chip
                v-for="(att, i) in form._attachments"
                :key="i"
                closable
                class="ma-1"
                @click:close="$emit('remove-attachment', att)"
              >
                <v-icon start size="14">mdi-file-outline</v-icon>{{ att.filename || `file ${i + 1}` }}
              </v-chip>
            </div>
          </v-col>
          <v-col cols="12">
            <v-switch v-model="form.is_billable" label="Billable expense (can be invoiced to a customer)" color="primary" density="compact" hide-details="auto" />
          </v-col>
        </v-row>
      </v-card-text>
      <v-card-actions class="px-4 pb-4">
        <v-spacer />
        <v-btn variant="text" @click="dialog = false">Cancel</v-btn>
        <v-btn color="primary" prepend-icon="mdi-check" :loading="saving" @click="onSave">{{ editing ? 'Update' : 'Create' }}</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
const props = defineProps<{
  modelValue: boolean
  editing: boolean
  saving: boolean
  currencySymbol: string
  categoryOptions: any[]
  vehicleOptions: any[]
  contactOptions: any[]
}>()

const emit = defineEmits<{
  'update:modelValue': [val: boolean]
  save: [payload: any, files: File[]]
  'remove-attachment': [att: any]
}>()

const dialog = computed({ get: () => props.modelValue, set: (v) => emit('update:modelValue', v) })
const dateMenu = ref(false)
const pendingFiles = ref<File[]>([])

const defaultForm = () => ({
  _id: null as number | null,
  title: '',
  category: null as number | null,
  amount: 0,
  tax_rate: 0,
  vendor_name: '',
  expense_date: new Date().toISOString().slice(0, 10),
  payment_method: 'card',
  payment_reference: '',
  vehicle: null as number | null,
  contact: null as number | null,
  description: '',
  notes: '',
  tags: '',
  is_billable: false,
  _attachments: [] as any[],
})

const form = reactive<any>(defaultForm())

const paymentMethods = [
  { label: 'Cash', value: 'cash' },
  { label: 'Card', value: 'card' },
  { label: 'Bank Transfer', value: 'bank' },
  { label: 'Mobile Money', value: 'mobile' },
  { label: 'Check', value: 'check' },
  { label: 'Other', value: 'other' },
]

const computedTax = computed(() => {
  const amt = Number(form.amount || 0)
  const rate = Number(form.tax_rate || 0)
  return (amt * rate).toFixed(2)
})

function reset(item?: any) {
  Object.assign(form, defaultForm())
  if (item) {
    Object.keys(form).forEach((k) => {
      if (item[k] !== undefined && k !== '_attachments') form[k] = item[k]
    })
    form._id = item.id
    form._attachments = item.attachments || []
  }
  pendingFiles.value = []
}

function onSave() {
  if (!form.title || !form.amount) {
    return
  }
  const { _id, _attachments, ...payload } = form
  emit('save', payload, pendingFiles.value || [])
}

defineExpose({ reset, form })
</script>
