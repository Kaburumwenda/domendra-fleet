<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="760">
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-handshake-outline">{{ editing ? 'Edit Lessor' : 'Add Lessor' }}</AppModalHeader>
      <v-card-text class="pt-2">
        <v-radio-group v-model="form.lessor_type" inline density="compact" class="mb-2" hide-details>
          <v-radio label="Individual" value="individual" />
          <v-radio label="Company" value="company" />
        </v-radio-group>

        <template v-if="form.lessor_type === 'individual'">
          <v-row dense>
            <v-col cols="6" md="4"><v-text-field v-model="form.first_name" label="First Name" density="compact" /></v-col>
            <v-col cols="6" md="4"><v-text-field v-model="form.middle_name" label="Middle Name" density="compact" /></v-col>
            <v-col cols="6" md="4"><v-text-field v-model="form.last_name" label="Last Name" density="compact" /></v-col>
            <v-col cols="6" md="4"><v-text-field v-model="form.national_id" label="National ID" density="compact" /></v-col>
          </v-row>
        </template>

        <template v-else>
          <v-row dense>
            <v-col cols="12" md="6"><v-text-field v-model="form.company_name" label="Company Name" density="compact" /></v-col>
            <v-col cols="12" md="6"><v-text-field v-model="form.representative_name" label="Representative Name" density="compact" /></v-col>
            <v-col cols="12" md="6"><v-text-field v-model="form.registration_number" label="Registration Number" density="compact" /></v-col>
          </v-row>
        </template>

        <v-divider class="my-3" />
        <p class="text-caption font-weight-medium text-medium-emphasis mb-2">Contact Information</p>
        <v-row dense>
          <v-col cols="12" md="6">
            <CountrySelect v-model="form.country" label="Country" density="compact" />
          </v-col>
          <v-col cols="12" md="6">
            <PhoneInput v-model="form.phone" :country-name="form.country" label="Telephone" density="compact" />
          </v-col>
          <v-col cols="12" md="6"><v-text-field v-model="form.email" label="Email" type="email" density="compact" /></v-col>
          <v-col cols="12" md="6"><v-text-field v-model="form.tax_id" label="Tax ID" density="compact" /></v-col>
          <v-col cols="12"><v-textarea v-model="form.address" label="Address" rows="2" density="compact" /></v-col>
        </v-row>

        <v-divider class="my-3" />
        <p class="text-caption font-weight-medium text-medium-emphasis mb-2">Lease Terms</p>
        <v-row dense>
          <v-col cols="12" md="6"><v-text-field v-model="form.payment_terms" label="Payment Terms" density="compact" hint="e.g. Net 30, Monthly in advance" persistent-hint /></v-col>
          <v-col cols="12" md="6"><v-text-field v-model="form.bank_account" label="Bank Account" density="compact" /></v-col>
          <v-col cols="12" md="6">
            <v-text-field v-model="form.contract_start_date" label="Contract Start Date" type="date" density="compact" />
          </v-col>
          <v-col cols="12" md="6">
            <v-text-field v-model="form.contract_end_date" label="Contract End Date" type="date" density="compact" />
          </v-col>
        </v-row>

        <v-divider class="my-3" />
        <v-row dense>
          <v-col cols="12"><v-textarea v-model="form.notes" label="Notes" rows="2" density="compact" /></v-col>
          <v-col cols="12">
            <v-switch v-model="form.is_active" label="Active" color="primary" hide-details density="compact" />
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
const props = defineProps<{ modelValue: boolean; lessor?: any | null }>()
const emit = defineEmits(['update:modelValue', 'saved'])

const { $api } = useNuxtApp()
const saving = ref(false)

const editing = computed(() => !!props.lessor?.id)

const defaultForm = () => ({
  lessor_type: 'individual',
  first_name: '', middle_name: '', last_name: '', national_id: '',
  company_name: '', representative_name: '', registration_number: '',
  email: '', phone: '', country: '', address: '', notes: '',
  tax_id: '', bank_account: '', payment_terms: '',
  contract_start_date: '', contract_end_date: '',
  is_active: true,
})

const form = reactive<any>(defaultForm())

watch(() => props.modelValue, (v) => {
  if (v) {
    Object.assign(form, defaultForm())
    if (props.lessor?.id) {
      Object.assign(form, {
        lessor_type: props.lessor.lessor_type,
        first_name: props.lessor.first_name, middle_name: props.lessor.middle_name,
        last_name: props.lessor.last_name, national_id: props.lessor.national_id,
        company_name: props.lessor.company_name, representative_name: props.lessor.representative_name,
        registration_number: props.lessor.registration_number,
        email: props.lessor.email, phone: props.lessor.phone, country: props.lessor.country,
        address: props.lessor.address, notes: props.lessor.notes,
        tax_id: props.lessor.tax_id, bank_account: props.lessor.bank_account,
        payment_terms: props.lessor.payment_terms,
        contract_start_date: props.lessor.contract_start_date || '',
        contract_end_date: props.lessor.contract_end_date || '',
        is_active: props.lessor.is_active,
      })
    }
  }
})

async function save() {
  saving.value = true
  try {
    const payload = { ...form }
    if (!payload.contract_start_date) payload.contract_start_date = null
    if (!payload.contract_end_date) payload.contract_end_date = null
    if (props.lessor?.id) {
      await $api(`/lessors/${props.lessor.id}/`, { method: 'PATCH', body: payload })
    } else {
      await $api('/lessors/', { method: 'POST', body: payload })
    }
    emit('update:modelValue', false)
    emit('saved')
  } catch (e: any) {
    console.error('Save lessor error:', e?.data)
    const { $swal } = useNuxtApp() as any
    $swal?.fire({ icon: 'error', title: 'Save Failed', text: e?.data?.detail || 'Check required fields.' })
  } finally {
    saving.value = false
  }
}
</script>
