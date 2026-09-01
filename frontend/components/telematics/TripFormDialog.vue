<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="640">
    <v-card rounded="lg">
      <AppModalHeader :title="isEdit ? 'Edit Trip' : 'New Trip'" icon="mdi-route" />
      <v-card-text class="pa-5">
        <v-row dense>
          <v-col cols="12" md="6">
            <v-select
              v-model="form.vehicle"
              :items="vehicles"
              item-title="display_name"
              item-value="id"
              label="Vehicle *"
              density="comfortable"
              variant="outlined"
              :error-messages="errors.vehicle"
              hide-details="auto"
              @update:model-value="onVehicleChange"
            />
          </v-col>
          <v-col cols="12" md="6">
            <v-select
              v-model="form.driver"
              :items="drivers"
              :item-title="(d: any) => `${d.first_name} ${d.last_name}`"
              item-value="id"
              label="Driver"
              density="comfortable"
              variant="outlined"
              clearable
              hide-details="auto"
            />
          </v-col>
          <v-col cols="12" md="6">
            <v-select
              v-model="form.device"
              :items="deviceOptions"
              item-title="serial_number"
              item-value="id"
              label="Device"
              density="comfortable"
              variant="outlined"
              clearable
              hide-details="auto"
            />
          </v-col>
          <v-col cols="12" md="6">
            <v-select
              v-model="form.status"
              :items="tripStatusOptions"
              item-title="label"
              item-value="value"
              label="Status"
              density="comfortable"
              variant="outlined"
              hide-details="auto"
            />
          </v-col>
          <v-col cols="12" md="6">
            <v-text-field
              v-model="form.start_address"
              label="Start Address"
              density="comfortable"
              variant="outlined"
              hide-details="auto"
            />
          </v-col>
          <v-col cols="12" md="6">
            <v-text-field
              v-model="form.end_address"
              label="End Address"
              density="comfortable"
              variant="outlined"
              hide-details="auto"
            />
          </v-col>
          <v-col cols="12" md="6">
            <v-text-field
              v-model="form.started_at"
              label="Start Time"
              type="datetime-local"
              density="comfortable"
              variant="outlined"
              hide-details="auto"
            />
          </v-col>
          <v-col cols="12" md="6">
            <v-text-field
              v-model="form.start_odometer"
              label="Start Odometer"
              type="number"
              density="comfortable"
              variant="outlined"
              hide-details="auto"
            />
          </v-col>
        </v-row>
      </v-card-text>
      <v-card-actions class="pa-4 pt-0">
        <v-spacer />
        <v-btn variant="text" @click="$emit('update:modelValue', false)">Cancel</v-btn>
        <v-btn color="primary" variant="flat" :loading="saving" @click="save">
          {{ isEdit ? 'Save Changes' : 'Create Trip' }}
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
  drivers: any[]
  devices: any[]
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', val: boolean): void
  (e: 'saved'): void
}>()

const { $api, $swal } = useNuxtApp() as any

const isEdit = computed(() => !!props.editItem?.id)
const saving = ref(false)
const errors = reactive<any>({})

const tripStatusOptions = [
  { label: 'Active', value: 'active' },
  { label: 'Completed', value: 'completed' },
  { label: 'Cancelled', value: 'cancelled' },
]

const deviceOptions = computed(() => {
  if (!form.vehicle) return props.devices
  return props.devices.filter((d) => d.vehicle === form.vehicle || d.vehicle === null)
})

const defaultForm = () => ({
  vehicle: null,
  driver: null,
  device: null,
  status: 'active',
  start_address: '',
  end_address: '',
  started_at: '',
  start_odometer: null,
})

const form = reactive<any>(defaultForm())

function onVehicleChange() {
  form.device = null
}

watch(() => props.modelValue, (v) => {
  if (v) {
    Object.keys(errors).forEach((k) => delete errors[k])
    if (props.editItem?.id) {
      Object.assign(form, defaultForm(), props.editItem)
    } else {
      Object.assign(form, defaultForm())
      form.started_at = new Date().toISOString().slice(0, 16)
    }
  }
}, { immediate: true })

async function save() {
  saving.value = true
  Object.keys(errors).forEach((k) => delete errors[k])
  try {
    const body = { ...form }
    if (body.started_at) body.started_at = new Date(body.started_at).toISOString()

    if (isEdit.value) {
      await $api(`/telematics/trips/${props.editItem.id}/`, { method: 'PATCH', body })
      $swal?.fire?.({ icon: 'success', title: 'Trip updated', toast: true, timer: 1500, position: 'top-end' })
    } else {
      await $api('/telematics/trips/', { method: 'POST', body })
      $swal?.fire?.({ icon: 'success', title: 'Trip created', toast: true, timer: 1500, position: 'top-end' })
    }
    emit('update:modelValue', false)
    emit('saved')
  } catch (e: any) {
    if (e?.data) Object.assign(errors, e.data)
    $swal?.fire?.({ icon: 'error', title: 'Save failed', toast: true, timer: 2000, position: 'top-end' })
  } finally {
    saving.value = false
  }
}
</script>
