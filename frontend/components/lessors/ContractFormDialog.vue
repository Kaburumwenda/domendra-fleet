<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="800">
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-file-document-edit-outline">{{ editing ? 'Edit Contract' : 'New Contract' }}</AppModalHeader>
      <v-card-text class="pt-2">
        <v-row dense>
          <v-col cols="12" md="6">
            <v-select
              v-model="form.lessor"
              :items="lessorItems"
              item-title="display_name"
              item-value="id"
              label="Lessor"
              density="compact"
              :rules="[v => !!v || 'Required']"
            />
          </v-col>
          <v-col cols="12" md="6">
            <v-text-field v-model="form.title" label="Contract Title" density="compact" />
          </v-col>
          <v-col cols="12" md="6">
            <v-text-field v-model="form.contract_number" label="Contract Number" density="compact" />
          </v-col>
          <v-col cols="12" md="6">
            <v-select v-model="form.status" :items="statusOptions" label="Status" density="compact" />
          </v-col>
          <v-col cols="12" md="4">
            <v-text-field v-model="form.start_date" label="Start Date" type="date" density="compact" />
          </v-col>
          <v-col cols="12" md="4">
            <v-text-field v-model="form.end_date" label="End Date" type="date" density="compact" />
          </v-col>
          <v-col cols="12" md="4">
            <v-select v-model="form.payment_frequency" :items="frequencyOptions" label="Payment Frequency" density="compact" />
          </v-col>
          <v-col cols="12" md="4">
            <v-text-field v-model="form.monthly_rate" label="Monthly Rate" type="number" density="compact" prefix="$" />
          </v-col>
          <v-col cols="12" md="4">
            <v-text-field v-model="form.deposit_amount" label="Deposit Amount" type="number" density="compact" prefix="$" />
          </v-col>
          <v-col cols="12" md="4">
            <v-text-field v-model="form.mileage_limit" label="Mileage Limit (mi/mo)" type="number" density="compact" />
          </v-col>
          <v-col cols="12" md="6">
            <v-text-field v-model="form.excess_mileage_rate" label="Excess Mileage Rate" type="number" density="compact" prefix="$" />
          </v-col>
          <v-col cols="12" md="6">
            <v-text-field v-model="form.maintenance_responsibility" label="Maintenance Responsibility" density="compact" hint="lessor, lessee, or shared" persistent-hint />
          </v-col>
          <v-col cols="12" md="6">
            <v-text-field v-model="form.signed_date" label="Signed Date" type="date" density="compact" />
          </v-col>
          <v-col cols="12" md="3">
            <v-switch v-model="form.insurance_required" label="Insurance Req." color="primary" density="compact" hide-details />
          </v-col>
          <v-col cols="12" md="3">
            <v-switch v-model="form.auto_renew" label="Auto Renew" color="primary" density="compact" hide-details />
          </v-col>
          <v-col cols="12">
            <v-textarea v-model="form.terms" label="Terms and Conditions" rows="3" density="compact" />
          </v-col>
        </v-row>
      </v-card-text>
      <v-card-actions class="px-4 pb-4">
        <v-spacer />
        <v-btn variant="text" @click="$emit('update:modelValue', false)">Cancel</v-btn>
        <v-btn color="primary" prepend-icon="mdi-check" :loading="saving" @click="save">{{ editing ? 'Update' : 'Create' }}</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
const props = defineProps<{ modelValue: boolean; contract?: any | null; lessors: any[] }>()
const emit = defineEmits(['update:modelValue', 'saved'])

const { $api } = useNuxtApp()

const saving = ref(false)
const editing = computed(() => !!props.contract?.id)
const lessorItems = computed(() => props.lessors || [])

const statusOptions = [
  { title: 'Draft', value: 'draft' },
  { title: 'Pending Signature', value: 'pending' },
  { title: 'Active', value: 'active' },
  { title: 'Expired', value: 'expired' },
  { title: 'Terminated', value: 'terminated' },
]
const frequencyOptions = [
  { title: 'Weekly', value: 'weekly' },
  { title: 'Biweekly', value: 'biweekly' },
  { title: 'Monthly', value: 'monthly' },
  { title: 'Quarterly', value: 'quarterly' },
  { title: 'Annually', value: 'annually' },
]

const defaultForm = () => ({
  lessor: null as number | null,
  title: 'Lease Agreement',
  contract_number: '',
  status: 'draft',
  start_date: '',
  end_date: '',
  payment_frequency: 'monthly',
  monthly_rate: 0,
  deposit_amount: 0,
  mileage_limit: null as number | null,
  excess_mileage_rate: null as number | null,
  maintenance_responsibility: '',
  signed_date: '',
  insurance_required: true,
  auto_renew: false,
  terms: '',
})

const form = reactive<any>(defaultForm())

watch(() => props.modelValue, (v) => {
  if (v) {
    Object.assign(form, defaultForm())
    if (props.contract?.id) {
      Object.assign(form, {
        lessor: props.contract.lessor,
        title: props.contract.title,
        contract_number: props.contract.contract_number,
        status: props.contract.status,
        start_date: props.contract.start_date || '',
        end_date: props.contract.end_date || '',
        payment_frequency: props.contract.payment_frequency,
        monthly_rate: props.contract.monthly_rate,
        deposit_amount: props.contract.deposit_amount,
        mileage_limit: props.contract.mileage_limit,
        excess_mileage_rate: props.contract.excess_mileage_rate,
        maintenance_responsibility: props.contract.maintenance_responsibility,
        signed_date: props.contract.signed_date || '',
        insurance_required: props.contract.insurance_required,
        auto_renew: props.contract.auto_renew,
        terms: props.contract.terms,
      })
    }
  }
})

async function save() {
  saving.value = true
  try {
    const payload = { ...form }
    if (!payload.end_date) payload.end_date = null
    if (!payload.mileage_limit) payload.mileage_limit = null
    if (!payload.excess_mileage_rate) payload.excess_mileage_rate = null
    if (!payload.signed_date) payload.signed_date = null
    if (props.contract?.id) {
      await $api(`/lessors/contracts/${props.contract.id}/`, { method: 'PATCH', body: payload })
    } else {
      await $api('/lessors/contracts/', { method: 'POST', body: payload })
    }
    emit('update:modelValue', false)
    emit('saved')
  } catch (e: any) {
    console.error('Save contract error:', e?.data)
    const { $swal } = useNuxtApp() as any
    $swal?.fire({ icon: 'error', title: 'Save Failed', text: e?.data?.detail || 'Check required fields.' })
  } finally {
    saving.value = false
  }
}
</script>
