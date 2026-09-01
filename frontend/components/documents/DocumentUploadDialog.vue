<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="640" scrollable>
    <v-card rounded="xl">
      <AppModalHeader :icon="editing ? 'mdi-file-document-edit-outline' : 'mdi-file-upload-outline'">{{ editing ? 'Edit Document' : 'Upload Document' }}</AppModalHeader>
      <v-card-text>
        <!-- File Drop Zone (only for create mode) -->
        <FileDropZone
          v-if="!editing"
          label="Drop file here or click to browse"
          icon="mdi-file-upload-outline"
          :file="file"
          accept="image/*,.pdf,.doc,.docx,.xls,.xlsx,.txt,.csv"
          @upload="onFileSelected"
          @remove="onFileRemove"
          class="mb-4"
        />

        <v-row dense>
          <v-col cols="12"><v-text-field v-model="form.title" label="Title *" density="compact" variant="outlined" hide-details /></v-col>
          <v-col cols="6">
            <v-select
              v-model="form.document_type"
              :items="docTypes"
              item-title="label"
              item-value="value"
              label="Document Type"
              density="compact"
              variant="outlined"
              hide-details
            />
          </v-col>
          <v-col cols="6"><v-text-field v-model="form.expiry_date" type="date" label="Expiry Date" density="compact" variant="outlined" hide-details /></v-col>
          <v-col cols="6">
            <v-autocomplete
              v-model="form.vehicle"
              :items="vehicleOptions"
              item-title="display_name"
              item-value="id"
              label="Vehicle"
              density="compact"
              variant="outlined"
              hide-details
              clearable
            />
          </v-col>
          <v-col cols="6">
            <v-autocomplete
              v-model="form.contact"
              :items="contactOptions"
              :item-title="contactLabel"
              item-value="id"
              label="Contact / Driver"
              density="compact"
              variant="outlined"
              hide-details
              clearable
            />
          </v-col>
          <v-col cols="12"><v-textarea v-model="form.notes" label="Notes" rows="2" density="compact" variant="outlined" hide-details /></v-col>
        </v-row>
      </v-card-text>
      <v-card-actions class="px-4 pb-4">
        <v-spacer />
        <v-btn variant="text" @click="$emit('update:modelValue', false)">Cancel</v-btn>
        <v-btn color="primary" prepend-icon="mdi-check" @click="$emit('save', buildPayload())" :loading="saving" :disabled="!canSave">{{ editing ? 'Update' : 'Upload' }}</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import FileDropZone from '~/components/FileDropZone.vue'

const props = defineProps<{
  modelValue: boolean
  editing: boolean
  saving: boolean
  vehicleOptions: any[]
  contactOptions: any[]
}>()
const emit = defineEmits<{ 'update:modelValue': [v: boolean]; save: [payload: any] }>()

const file = ref<File | null>(null)

const form = reactive<any>({
  _id: null,
  title: '',
  document_type: 'other',
  expiry_date: null,
  vehicle: null,
  contact: null,
  notes: '',
})

const docTypes = [
  { label: 'Insurance', value: 'insurance' },
  { label: 'Registration', value: 'registration' },
  { label: 'Title', value: 'title' },
  { label: 'Inspection', value: 'inspection' },
  { label: 'License', value: 'license' },
  { label: 'Medical Card', value: 'medical_card' },
  { label: 'Warranty', value: 'warranty' },
  { label: 'Contract', value: 'contract' },
  { label: 'Permit', value: 'permit' },
  { label: 'Maintenance Record', value: 'maintenance' },
  { label: 'Other', value: 'other' },
]

const canSave = computed(() => {
  if (props.editing) return !!form.title
  return !!file.value && !!form.title
})

function contactLabel(item: any) {
  return item?.full_name || item?.company_name || `Contact #${item?.id}`
}

function onFileSelected(f: File) {
  file.value = f
  if (!form.title) {
    // Auto-fill title from filename (strip extension)
    const name = f.name.replace(/\.[^/.]+$/, '')
    form.title = name.replace(/[-_]/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())
  }
}

function onFileRemove() {
  file.value = null
}

function reset(r?: any) {
  Object.assign(form, { _id: null, title: '', document_type: 'other', expiry_date: null, vehicle: null, contact: null, notes: '' })
  file.value = null
  if (r) {
    form._id = r.id
    form.title = r.title || ''
    form.document_type = r.document_type || 'other'
    form.expiry_date = r.expiry_date || null
    form.vehicle = r.vehicle || null
    form.contact = r.contact || null
    form.notes = r.notes || ''
  }
}

function buildPayload() {
  return {
    _id: form._id,
    title: form.title,
    document_type: form.document_type,
    expiry_date: form.expiry_date || null,
    vehicle: form.vehicle || null,
    contact: form.contact || null,
    notes: form.notes || '',
    file: file.value,
  }
}

defineExpose({ reset, file })
</script>
