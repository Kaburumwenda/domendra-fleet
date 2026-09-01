<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="560">
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-map-marker-plus">{{ editing ? 'Edit Route Stop' : 'Add Route Stop' }}</AppModalHeader>
      <v-card-text>
        <v-row dense>
          <v-col cols="6">
            <v-text-field v-model="form.sequence" type="number" label="Sequence" variant="outlined" density="compact" hide-details="auto" />
          </v-col>
          <v-col cols="6">
            <v-select v-model="form.status" :items="stopStatuses" item-title="label" item-value="value" label="Status" variant="outlined" density="compact" hide-details="auto" />
          </v-col>
          <v-col cols="12">
            <v-text-field ref="addrInput" v-model="form.address" label="Address *" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-map-marker" @blur="maybeGeocode" />
          </v-col>
          <v-col cols="6">
            <v-text-field v-model="form.latitude" type="number" label="Latitude" variant="outlined" density="compact" hide-details="auto" />
          </v-col>
          <v-col cols="6">
            <v-text-field v-model="form.longitude" type="number" label="Longitude" variant="outlined" density="compact" hide-details="auto" />
          </v-col>
          <v-col cols="6">
            <v-text-field v-model="form.scheduled_arrival" type="datetime-local" label="Scheduled Arrival" variant="outlined" density="compact" hide-details="auto" />
          </v-col>
          <v-col cols="6">
            <v-text-field v-model="form.scheduled_departure" type="datetime-local" label="Scheduled Departure" variant="outlined" density="compact" hide-details="auto" />
          </v-col>
          <v-col cols="12">
            <v-textarea v-model="form.notes" label="Notes" rows="2" variant="outlined" density="compact" hide-details="auto" />
          </v-col>
        </v-row>
      </v-card-text>
      <v-card-actions class="px-4 pb-4">
        <v-spacer />
        <v-btn variant="text" @click="$emit('update:modelValue', false)">Cancel</v-btn>
        <v-btn color="primary" prepend-icon="mdi-check" :loading="saving" @click="onSave">{{ editing ? 'Update' : 'Add' }}</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { useGoogleMaps } from '~/composables/useGoogleMaps'
const props = defineProps<{ modelValue: boolean; editing: boolean; job: any; saving: boolean; suggestedSequence: number }>()
const emit = defineEmits<{ 'update:modelValue': [v: boolean]; save: [payload: any] }>()
const stopStatuses = [{ label: 'Pending', value: 'pending' }, { label: 'Arrived', value: 'arrived' }, { label: 'Departed', value: 'departed' }, { label: 'Skipped', value: 'skipped' }]
const { attachAutocomplete, geocodeAddress } = useGoogleMaps()
const addrInput = ref<any>(null)
const form = reactive<any>(defaultStop())

function defaultStop() { return { sequence: 1, address: '', latitude: null, longitude: null, scheduled_arrival: null, scheduled_departure: null, status: 'pending', notes: '' } }

watch(() => props.modelValue, async (open) => {
  if (!open) return
  await nextTick()
  if (props.editing === false) { Object.assign(form, defaultStop()); form.sequence = props.suggestedSequence || 1 }
  if (addrInput.value) {
    const input = addrInput.value.$el?.tagName === 'INPUT' ? addrInput.value.$el : addrInput.value.$el?.querySelector('input')
    if (input) attachAutocomplete(input, { onPlace: (p: any) => { if (p.geometry?.location) { form.latitude = p.geometry.location.lat(); form.longitude = p.geometry.location.lng(); if (p.formatted_address) form.address = p.formatted_address } } }).catch(() => {})
  }
})
defineExpose({ populate: (s: any) => {
  Object.assign(form, { sequence: s.sequence, address: s.address, latitude: s.latitude, longitude: s.longitude, scheduled_arrival: toLocal(s.scheduled_arrival), scheduled_departure: toLocal(s.scheduled_departure), status: s.status, notes: s.notes, _id: s.id, _jobId: s.job })
} })
function toLocal(v?: string) { return v ? new Date(v).toISOString().slice(0, 16) : null }

async function maybeGeocode() {
  if (!form.address || (form.latitude && form.longitude)) return
  try { const r = await geocodeAddress(form.address); if (r) { form.latitude = r.lat; form.longitude = r.lng } } catch {}
}
function onSave() {
  const payload: any = { ...form, job: props.job.id }
  if (payload.scheduled_arrival) payload.scheduled_arrival = new Date(payload.scheduled_arrival).toISOString()
  if (payload.scheduled_departure) payload.scheduled_departure = new Date(payload.scheduled_departure).toISOString()
  emit('save', payload)
}
</script>
