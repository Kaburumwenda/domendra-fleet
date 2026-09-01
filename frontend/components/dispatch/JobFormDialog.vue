<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="720" scrollable>
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-map-outline">{{ editing ? 'Edit Dispatch Job' : 'New Dispatch Job' }}</AppModalHeader>
      <v-card-text>
        <v-row dense>
          <v-col cols="12">
            <v-text-field v-model="form.title" label="Job Title *" variant="outlined" density="compact" hide-details="auto" />
          </v-col>
          <v-col cols="6" md="3">
            <v-select v-model="form.priority" :items="priorities" item-title="label" item-value="value" label="Priority" variant="outlined" density="compact" hide-details="auto" />
          </v-col>
          <v-col cols="6" md="3">
            <v-select v-model="form.status" :items="statusOptions" item-title="label" item-value="value" label="Status" variant="outlined" density="compact" hide-details="auto" :disabled="!editing" />
          </v-col>
          <v-col cols="6" md="3">
            <v-select v-model="form.vehicle" :items="vehicleOptions" :item-title="(v:any)=>v.display_name||v.id" item-value="id" label="Vehicle" variant="outlined" density="compact" hide-details="auto" clearable return-object />
          </v-col>
          <v-col cols="6" md="3">
            <v-select v-model="form.driver" :items="driverOptions" :item-title="(d:any)=>d.full_name||`#${d.id}`" item-value="id" label="Driver" variant="outlined" density="compact" hide-details="auto" clearable return-object />
          </v-col>

          <v-col cols="12">
            <p class="text-caption text-medium-emphasis mb-1"><v-icon size="14">mdi-map-marker-up</v-icon> Pickup</p>
          </v-col>
          <v-col cols="12" md="8">
            <v-text-field ref="pickupInput" v-model="form.pickup_address" label="Pickup Address" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-map-marker" />
          </v-col>
          <v-col cols="12" md="4">
            <v-btn variant="outlined" block height="40" prepend-icon="mdi-crosshairs-gps" :loading="geoLoading" @click="geocode('pickup')">Geocode</v-btn>
          </v-col>

          <v-col cols="12">
            <p class="text-caption text-medium-emphasis mb-1"><v-icon size="14">mdi-map-marker-down</v-icon> Dropoff</p>
          </v-col>
          <v-col cols="12" md="8">
            <v-text-field ref="dropoffInput" v-model="form.dropoff_address" label="Dropoff Address" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-flag-checkered" />
          </v-col>
          <v-col cols="12" md="4">
            <v-btn variant="outlined" block height="40" prepend-icon="mdi-crosshairs-gps" :loading="geoLoading" @click="geocode('dropoff')">Geocode</v-btn>
          </v-col>

          <v-col cols="6" md="3">
            <v-text-field v-model="form.scheduled_start" type="datetime-local" label="Scheduled Start" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-clock-start" />
          </v-col>
          <v-col cols="6" md="3">
            <v-text-field v-model="form.scheduled_end" type="datetime-local" label="Scheduled End" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-clock-end" />
          </v-col>
          <v-col cols="6" md="3">
            <v-text-field :model-value="form.pickup_lat && form.pickup_lng ? `${form.pickup_lat.toFixed(4)}, ${form.pickup_lng.toFixed(4)}` : ''" label="Pickup Coords" variant="outlined" density="compact" hide-details="auto" readonly />
          </v-col>
          <v-col cols="6" md="3">
            <v-text-field :model-value="form.dropoff_lat && form.dropoff_lng ? `${form.dropoff_lat.toFixed(4)}, ${form.dropoff_lng.toFixed(4)}` : ''" label="Dropoff Coords" variant="outlined" density="compact" hide-details="auto" readonly />
          </v-col>
          <v-col cols="12">
            <v-textarea v-model="form.notes" label="Notes" rows="2" variant="outlined" density="compact" hide-details="auto" />
          </v-col>
        </v-row>
      </v-card-text>
      <v-card-actions class="px-4 pb-4">
        <v-spacer />
        <v-btn variant="text" @click="$emit('update:modelValue', false)">Cancel</v-btn>
        <v-btn color="primary" prepend-icon="mdi-check" :loading="saving" @click="onSave">{{ editing ? 'Update' : 'Create' }}</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { useGoogleMaps } from '~/composables/useGoogleMaps'

const props = defineProps<{
  modelValue: boolean
  editing: boolean
  vehicleOptions: any[]
  driverOptions: any[]
  saving: boolean
}>()
const emit = defineEmits<{
  'update:modelValue': [v: boolean]
  save: [payload: any]
}>()

const statusOptions = [{ label: 'Pending', value: 'pending' }, { label: 'Assigned', value: 'assigned' }, { label: 'In Progress', value: 'in_progress' }, { label: 'Completed', value: 'completed' }, { label: 'Cancelled', value: 'cancelled' }]
const priorities = [{ label: 'Low', value: 'low' }, { label: 'Medium', value: 'medium' }, { label: 'High', value: 'high' }, { label: 'Urgent', value: 'urgent' }]

const form = reactive<any>(defaultForm())
const pickupInput = ref<any>(null)
const dropoffInput = ref<any>(null)
const geoLoading = ref(false)
const { attachAutocomplete, geocodeAddress } = useGoogleMaps()

function defaultForm() {
  return { title: '', priority: 'medium', status: 'pending', vehicle: null, driver: null, pickup_address: '', dropoff_address: '', pickup_lat: null, pickup_lng: null, dropoff_lat: null, dropoff_lng: null, scheduled_start: null, scheduled_end: null, notes: '' }
}

watch(() => props.modelValue, async (open) => {
  if (!open) return
  await nextTick()
  setupAutocomplete()
})

function setupAutocomplete() {
  if (pickupInput.value?.$el?.querySelector) {
    const input = pickupInput.value.$el.tagName === 'INPUT' ? pickupInput.value.$el : pickupInput.value.$el.querySelector('input')
    if (input) attachAutocomplete(input, { onPlace: (p: any) => { if (p.geometry?.location) { form.pickup_lat = p.geometry.location.lat(); form.pickup_lng = p.geometry.location.lng(); if (p.formatted_address) form.pickup_address = p.formatted_address } } }).catch(() => {})
  }
  if (dropoffInput.value?.$el?.querySelector) {
    const input = dropoffInput.value.$el.tagName === 'INPUT' ? dropoffInput.value.$el : dropoffInput.value.$el.querySelector('input')
    if (input) attachAutocomplete(input, { onPlace: (p: any) => { if (p.geometry?.location) { form.dropoff_lat = p.geometry.location.lat(); form.dropoff_lng = p.geometry.location.lng(); if (p.formatted_address) form.dropoff_address = p.formatted_address } } }).catch(() => {})
  }
}

defineExpose({ reset: (j?: any) => { Object.assign(form, defaultForm()); if (j) populate(j) } })

function populate(j: any) {
  Object.assign(form, {
    title: j.title || '', priority: j.priority || 'medium', status: j.status || 'pending',
    vehicle: j.vehicle || null, driver: j.driver || null,
    pickup_address: j.pickup_address || '', dropoff_address: j.dropoff_address || '',
    pickup_lat: j.pickup_lat ?? null, pickup_lng: j.pickup_lng ?? null,
    dropoff_lat: j.dropoff_lat ?? null, dropoff_lng: j.dropoff_lng ?? null,
    scheduled_start: toLocal(j.scheduled_start), scheduled_end: toLocal(j.scheduled_end),
    notes: j.notes || '', _id: j.id,
  })
}
function toLocal(v?: string) { return v ? new Date(v).toISOString().slice(0, 16) : null }

async function geocode(which: 'pickup' | 'dropoff') {
  const addr = which === 'pickup' ? form.pickup_address : form.dropoff_address
  if (!addr) return
  geoLoading.value = true
  try {
    const r = await geocodeAddress(addr)
    if (r) {
      if (which === 'pickup') { form.pickup_lat = r.lat; form.pickup_lng = r.lng; if (r.formatted) form.pickup_address = r.formatted }
      else { form.dropoff_lat = r.lat; form.dropoff_lng = r.lng; if (r.formatted) form.dropoff_address = r.formatted }
    }
  } catch {} finally { geoLoading.value = false }
}

function onSave() {
  if (!form.title?.trim()) return
  const payload: any = { ...form }
  if (payload.vehicle?.id) payload.vehicle = payload.vehicle.id
  else payload.vehicle = null
  if (payload.driver?.id) payload.driver = payload.driver.id
  else payload.driver = null
  if (payload.scheduled_start) payload.scheduled_start = new Date(payload.scheduled_start).toISOString()
  if (payload.scheduled_end) payload.scheduled_end = new Date(payload.scheduled_end).toISOString()
  emit('save', payload)
}
</script>
