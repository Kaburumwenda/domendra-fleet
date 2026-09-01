<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="620">
    <v-card rounded="lg">
      <AppModalHeader :title="isEdit ? 'Edit Device' : 'Add Telematics Device'" icon="mdi-crosshairs-gps" />
      <v-card-text class="pa-5">
        <v-row dense>
          <v-col cols="12" md="6">
            <v-text-field
              v-model="form.serial_number"
              label="Serial Number *"
              density="comfortable"
              variant="outlined"
              :error-messages="errors.serial_number"
              hide-details="auto"
            />
          </v-col>
          <v-col cols="12" md="6">
            <v-text-field
              v-model="form.imei"
              label="IMEI"
              density="comfortable"
              variant="outlined"
              hide-details="auto"
            />
          </v-col>
          <v-col cols="12" md="6">
            <v-select
              v-model="form.provider"
              :items="providerOptions"
              item-title="label"
              item-value="value"
              label="Provider *"
              density="comfortable"
              variant="outlined"
              hide-details="auto"
            />
          </v-col>
          <v-col cols="12" md="6">
            <v-select
              v-model="form.status"
              :items="statusOptions"
              item-title="label"
              item-value="value"
              label="Status"
              density="comfortable"
              variant="outlined"
              hide-details="auto"
            />
          </v-col>
          <v-col cols="12">
            <v-select
              v-model="form.vehicle"
              :items="vehicles"
              item-title="display_name"
              item-value="id"
              label="Assign Vehicle"
              density="comfortable"
              variant="outlined"
              clearable
              hide-details="auto"
            />
          </v-col>
          <v-col cols="12" md="6">
            <v-text-field
              v-model="form.installed_at"
              label="Install Date"
              type="date"
              density="comfortable"
              variant="outlined"
              hide-details="auto"
            />
          </v-col>

          <v-col cols="12">
            <v-divider class="mb-2" />
            <p class="text-caption font-weight-medium text-medium-emphasis mb-2">Alert Thresholds</p>
          </v-col>
          <v-col cols="12" md="4">
            <v-text-field
              v-model="form.speed_limit"
              label="Speed Limit"
              type="number"
              suffix="km/h"
              density="comfortable"
              variant="outlined"
              hide-details="auto"
              clearable
            />
          </v-col>
          <v-col cols="12" md="4">
            <v-text-field
              v-model="form.idle_threshold_minutes"
              label="Idle Threshold"
              type="number"
              suffix="min"
              density="comfortable"
              variant="outlined"
              hide-details="auto"
            />
          </v-col>
          <v-col cols="12" md="4">
            <v-text-field
              v-model="form.low_fuel_threshold"
              label="Low Fuel"
              type="number"
              suffix="%"
              density="comfortable"
              variant="outlined"
              hide-details="auto"
              clearable
            />
          </v-col>
        </v-row>
      </v-card-text>
      <v-card-actions class="pa-4 pt-0">
        <v-spacer />
        <v-btn variant="text" @click="$emit('update:modelValue', false)">Cancel</v-btn>
        <v-btn color="primary" variant="flat" :loading="saving" @click="save">
          {{ isEdit ? 'Save Changes' : 'Create Device' }}
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
const props = defineProps<{
  modelValue: boolean
  editItem?: any
  vehicles: any[]
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', val: boolean): void
  (e: 'saved'): void
}>()

const { $api, $swal } = useNuxtApp() as any

const isEdit = computed(() => !!props.editItem?.id)
const saving = ref(false)
const errors = reactive<any>({})

const providerOptions = [
  { label: 'Geotab', value: 'geotab' },
  { label: 'Samsara', value: 'samsara' },
  { label: 'KeepTruckin (Motive)', value: 'keeptruckin' },
  { label: 'Verizon Connect', value: 'verizon' },
  { label: 'Generic / Custom', value: 'generic' },
]

const statusOptions = [
  { label: 'Active', value: 'active' },
  { label: 'Inactive', value: 'inactive' },
  { label: 'Offline', value: 'offline' },
]

const defaultForm = () => ({
  serial_number: '',
  imei: '',
  provider: 'generic',
  status: 'active',
  vehicle: null,
  installed_at: '',
  speed_limit: null,
  idle_threshold_minutes: 10,
  low_fuel_threshold: null,
})

const form = reactive<any>(defaultForm())

watch(() => props.modelValue, (v) => {
  if (v) {
    Object.keys(errors).forEach((k) => delete errors[k])
    if (props.editItem?.id) {
      Object.assign(form, {
        ...defaultForm(),
        ...props.editItem,
        speed_limit: props.editItem.speed_limit ?? null,
        low_fuel_threshold: props.editItem.low_fuel_threshold ?? null,
      })
    } else {
      Object.assign(form, defaultForm())
    }
  }
}, { immediate: true })

async function save() {
  saving.value = true
  Object.keys(errors).forEach((k) => delete errors[k])
  try {
    const body = { ...form }
    if (!body.speed_limit) body.speed_limit = null
    if (!body.low_fuel_threshold) body.low_fuel_threshold = null

    if (isEdit.value) {
      await $api(`/telematics/devices/${props.editItem.id}/`, { method: 'PATCH', body })
      $swal?.fire?.({ icon: 'success', title: 'Device updated', toast: true, timer: 1500, position: 'top-end' })
    } else {
      await $api('/telematics/devices/', { method: 'POST', body })
      $swal?.fire?.({ icon: 'success', title: 'Device added', toast: true, timer: 1500, position: 'top-end' })
    }
    emit('update:modelValue', false)
    emit('saved')
  } catch (e: any) {
    if (e?.data) {
      Object.assign(errors, e.data)
    }
    $swal?.fire?.({ icon: 'error', title: 'Save failed', toast: true, timer: 2000, position: 'top-end' })
  } finally {
    saving.value = false
  }
}
</script>
