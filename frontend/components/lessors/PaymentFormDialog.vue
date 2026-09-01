<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="640">
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-cash-multiple">{{ editing ? 'Edit Payment' : 'Record Payment' }}</AppModalHeader>
      <v-card-text class="pt-2">
        <v-form ref="formRef">
          <v-row dense>
            <v-col cols="12" md="6">
              <v-select
                v-model="form.lessor"
                :items="lessorItems"
                item-title="display_name"
                item-value="id"
                label="Lessor"
                density="compact"
                :rules="[v => !!v || 'Lessor is required']"
              />
            </v-col>
            <v-col cols="12" md="6">
              <v-select
                v-model="form.contract"
                :items="availableContracts"
                item-title="title"
                item-value="id"
                label="Contract"
                density="compact"
                :rules="[v => !!v || 'Contract is required']"
              />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="form.amount" label="Amount" type="number" prefix="$" density="compact" :rules="[v => (v !== null && v !== '' && Number(v) > 0) || 'Amount must be greater than 0']" />
            </v-col>
            <v-col cols="12" md="6">
              <v-select v-model="form.status" :items="statusOptions" label="Status" density="compact" :rules="[v => !!v || 'Status is required']" />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="form.due_date" label="Due Date" type="date" density="compact" :rules="dueDateRules" />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="form.paid_date" label="Paid Date" type="date" density="compact" :rules="[v => !!v || 'Paid date is required']" />
            </v-col>
            <v-col cols="12" md="6">
              <v-select v-model="form.payment_method" :items="methodOptions" label="Payment Method" density="compact" :rules="[v => !!v || 'Payment method is required']" />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="form.invoice_number" label="Invoice Number" density="compact" />
            </v-col>
            <v-col cols="12">
              <v-text-field v-model="form.reference" label="Reference / Transaction ID" density="compact" />
            </v-col>
            <v-col cols="12">
              <v-textarea v-model="form.notes" label="Notes" rows="2" density="compact" />
            </v-col>
          </v-row>
        </v-form>
      </v-card-text>
      <v-card-actions class="px-4 pb-4">
        <v-spacer />
        <v-btn variant="text" @click="$emit('update:modelValue', false)">Cancel</v-btn>
        <v-btn color="primary" prepend-icon="mdi-check" :loading="saving" @click="save">{{ editing ? 'Update' : 'Record' }}</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
const props = defineProps<{ modelValue: boolean; payment?: any | null; lessors: any[]; contracts: any[] }>()
const emit = defineEmits(['update:modelValue', 'saved'])

const { $api } = useNuxtApp()
const saving = ref(false)
const editing = computed(() => !!props.payment?.id)
const lessorItems = computed(() => props.lessors || [])

const formRef = ref()

// Due date is required only when status is NOT 'paid' (paid uses paid_date instead)
const dueDateRules = computed(() => {
  if (form.status === 'pending' || form.status === 'overdue') {
    return [v => !!v || 'Due date is required']
  }
  return []
})

const statusOptions = [
  { title: 'Pending', value: 'pending' },
  { title: 'Paid', value: 'paid' },
  { title: 'Overdue', value: 'overdue' },
  { title: 'Cancelled', value: 'cancelled' },
]
const methodOptions = [
  { title: 'Bank Transfer', value: 'bank_transfer' },
  { title: 'Check', value: 'check' },
  { title: 'Wire', value: 'wire' },
  { title: 'Card', value: 'card' },
  { title: 'Cash', value: 'cash' },
  { title: 'Other', value: 'other' },
]

const availableContracts = computed(() => {
  if (!props.contracts || props.contracts.length === 0) return []
  let cs: any[] = []
  if (form.lessor) {
    cs = props.contracts.filter(c => c.lessor === form.lessor)
  } else {
    cs = props.contracts
  }
  return cs.map(c => ({ id: c.id, title: `${c.title} — ${c.lessor_name || ''}` }))
})

const defaultForm = () => ({
  lessor: null as number | null,
  contract: null as number | null,
  amount: 0,
  status: 'pending',
  due_date: '',
  paid_date: '',
  payment_method: '',
  invoice_number: '',
  reference: '',
  notes: '',
})

const form = reactive<any>(defaultForm())

watch(() => props.modelValue, (v) => {
  if (v) {
    Object.assign(form, defaultForm())
    if (props.payment?.id) {
      Object.assign(form, {
        lessor: props.payment.lessor,
        contract: props.payment.contract,
        amount: props.payment.amount,
        status: props.payment.status,
        due_date: props.payment.due_date || '',
        paid_date: props.payment.paid_date || '',
        payment_method: props.payment.payment_method,
        invoice_number: props.payment.invoice_number,
        reference: props.payment.reference,
        notes: props.payment.notes,
      })
    }
    // Reset validation errors on open
    nextTick(() => formRef.value?.resetValidation())
  }
})

async function save() {
  const { valid } = await formRef.value?.validate()
  if (!valid) return
  saving.value = true
  try {
    const payload = { ...form }
    if (!payload.contract) payload.contract = null
    if (!payload.due_date) payload.due_date = null
    if (!payload.paid_date) payload.paid_date = null
    if (!payload.payment_method) payload.payment_method = ''
    if (props.payment?.id) {
      await $api(`/lessors/payments/${props.payment.id}/`, { method: 'PATCH', body: payload })
    } else {
      await $api('/lessors/payments/', { method: 'POST', body: payload })
    }
    emit('update:modelValue', false)
    emit('saved')
  } catch (e: any) {
    console.error('Save payment error:', e?.data)
    const { $swal } = useNuxtApp() as any
    $swal?.fire({ icon: 'error', title: 'Save Failed', text: e?.data?.detail || 'Check required fields.' })
  } finally {
    saving.value = false
  }
}
</script>
