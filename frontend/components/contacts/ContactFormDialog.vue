<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="640" persistent>
    <v-card elevation="0" border rounded="lg">
      <v-card-title class="d-flex align-center ga-2 pa-4 border-b">
        <v-icon color="primary">{{ editing ? 'mdi-pencil-outline' : 'mdi-account-plus-outline' }}</v-icon>
        <span class="text-h6 font-weight-bold">{{ editing ? 'Edit Contact' : 'Add Contact' }}</span>
        <v-spacer />
        <v-btn icon variant="text" size="small" @click="$emit('update:modelValue', false)"><v-icon>mdi-close</v-icon></v-btn>
      </v-card-title>

      <v-card-text class="pa-4" style="max-height: 65vh; overflow-y: auto;">
        <v-row dense>
          <v-col cols="12">
            <v-select v-model="form.contact_type" :items="contactTypes" item-title="label" item-value="value" label="Contact Type *" density="compact" variant="outlined" />
          </v-col>
          <v-col cols="6"><v-text-field v-model="form.first_name" label="First Name" density="compact" variant="outlined" :disabled="isCompany" /></v-col>
          <v-col cols="6"><v-text-field v-model="form.last_name" label="Last Name" density="compact" variant="outlined" :disabled="isCompany" /></v-col>
          <v-col v-if="isCompany" cols="12"><v-text-field v-model="form.company_name" label="Company Name *" density="compact" variant="outlined" /></v-col>
          <v-col cols="6"><v-text-field v-model="form.email" label="Email" type="email" density="compact" variant="outlined" /></v-col>
          <v-col cols="6"><v-text-field v-model="form.phone" label="Phone" density="compact" variant="outlined" /></v-col>
          <v-col cols="12"><v-text-field v-model="form.address" label="Address" density="compact" variant="outlined" /></v-col>
          <v-col cols="4"><v-text-field v-model="form.city" label="City" density="compact" variant="outlined" /></v-col>
          <v-col cols="4"><v-text-field v-model="form.state" label="State / Province" density="compact" variant="outlined" /></v-col>
          <v-col cols="4"><v-text-field v-model="form.zip_code" label="ZIP / Postal Code" density="compact" variant="outlined" /></v-col>
          <v-col cols="12"><CountrySelect v-model="form.country" label="Country" density="compact" variant="outlined" hide-details /></v-col>
          <v-col cols="6"><v-text-field v-model="form.department" label="Department" density="compact" variant="outlined" /></v-col>
          <v-col cols="6"><v-text-field v-model="form.employee_id" label="Employee ID" density="compact" variant="outlined" /></v-col>
          <v-col cols="6"><v-text-field v-model="form.date_of_birth" type="date" label="Date of Birth" density="compact" variant="outlined" /></v-col>
          <v-col cols="6"><v-select v-model="form.is_active" :items="[{label:'Active',value:true},{label:'Inactive',value:false}]" item-title="label" item-value="value" label="Status" density="compact" variant="outlined" /></v-col>
          <v-col cols="12"><v-textarea v-model="form.notes" label="Notes" rows="2" density="compact" variant="outlined" /></v-col>
        </v-row>

        <!-- Vendor Profile fields (only for vendor type) -->
        <div v-if="form.contact_type === 'vendor'" class="mt-3">
          <v-divider class="mb-3" />
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-store-outline</v-icon>Vendor Profile</p>
          <v-row dense>
            <v-col cols="6"><v-text-field v-model="vendor.service_type" label="Service Type" density="compact" variant="outlined" /></v-col>
            <v-col cols="6"><v-text-field v-model="vendor.payment_terms" label="Payment Terms" density="compact" variant="outlined" placeholder="e.g. Net 30" /></v-col>
            <v-col cols="6"><v-text-field v-model="vendor.rating" type="number" label="Rating (0-5)" density="compact" variant="outlined" min="0" max="5" step="0.1" /></v-col>
            <v-col cols="6"><v-text-field v-model="vendor.tax_id" label="Tax ID" density="compact" variant="outlined" /></v-col>
          </v-row>
        </div>
      </v-card-text>

      <v-card-actions class="pa-4 border-t">
        <v-btn variant="text" @click="$emit('update:modelValue', false)">Cancel</v-btn>
        <v-spacer />
        <v-btn color="primary" prepend-icon="mdi-check" :loading="saving" @click="submit">{{ editing ? 'Update' : 'Create' }}</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
const props = defineProps<{ modelValue: boolean; editing: boolean; saving: boolean; editingContact?: any }>()
const emit = defineEmits<{ 'update:modelValue': [v: boolean]; save: [body: any] }>()

const contactTypes = [
  { label: 'Driver', value: 'driver' },
  { label: 'Vendor', value: 'vendor' },
  { label: 'Mechanic', value: 'mechanic' },
  { label: 'Manager', value: 'manager' },
  { label: 'Insurance Agent', value: 'insurance_agent' },
  { label: 'Towing Company', value: 'towing' },
]

const companyTypes = ['vendor', 'insurance_agent', 'towing']
const isCompany = computed(() => companyTypes.includes(form.contact_type))

const defaultForm = () => ({
  contact_type: 'vendor',
  first_name: '', last_name: '', company_name: '',
  email: '', phone: '', address: '', city: '', state: '', zip_code: '', country: '',
  department: '', employee_id: '', date_of_birth: '', notes: '', is_active: true,
})
const form = reactive<any>(defaultForm())
const vendor = reactive({ service_type: '', rating: 0, payment_terms: '', tax_id: '' })

watch(() => props.modelValue, (val) => {
  if (!val) return
  if (props.editing && props.editingContact) {
    const c = props.editingContact
    Object.keys(form).forEach(k => { if (c[k] !== undefined) form[k] = c[k] })
    if (c.vendor_profile) {
      vendor.service_type = c.vendor_profile.service_type || ''
      vendor.rating = c.vendor_profile.rating || 0
      vendor.payment_terms = c.vendor_profile.payment_terms || ''
      vendor.tax_id = c.vendor_profile.tax_id || ''
    }
  } else {
    Object.assign(form, defaultForm())
    Object.assign(vendor, { service_type: '', rating: 0, payment_terms: '', tax_id: '' })
  }
})

function submit() {
  if (!form.contact_type) { return }
  if (isCompany.value && !form.company_name) { return }
  if (!isCompany.value && !form.first_name && !form.last_name) { return }

  const body: any = { ...form }
  // Clean empty date
  if (!body.date_of_birth) body.date_of_birth = null

  // Add vendor profile if vendor type
  if (form.contact_type === 'vendor') {
    body.vendor_profile = {
      service_type: vendor.service_type,
      rating: Number(vendor.rating) || 0,
      payment_terms: vendor.payment_terms,
      tax_id: vendor.tax_id,
    }
  }

  emit('save', body)
}
</script>
