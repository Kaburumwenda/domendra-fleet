<template>
  <v-dialog :model-value="modelValue" @update:model-value="onToggle" max-width="640" scrollable>
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-alert-plus-outline">{{ editing ? 'Edit Issue' : 'Report Issue' }}</AppModalHeader>
      <v-card-text>
        <v-row dense>
          <v-col cols="12">
            <v-text-field v-model="form.title" label="Title *" variant="outlined" density="compact" hide-details="auto" :error-messages="errors.title" prepend-inner-icon="mdi-format-title" />
          </v-col>
          <v-col cols="12">
            <v-select v-model="form.vehicle" :items="vehicleOptions" item-title="display_name" item-value="id" label="Vehicle *" variant="outlined" density="compact" hide-details="auto" :error-messages="errors.vehicle" prepend-inner-icon="mdi-truck" />
          </v-col>
          <v-col cols="6">
            <v-select v-model="form.status" :items="statusOptions" item-title="label" item-value="value" label="Status" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-state-machine" />
          </v-col>
          <v-col cols="6">
            <v-select v-model="form.priority" :items="priorityOptions" item-title="label" item-value="value" label="Priority" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-flag-variant-outline" />
          </v-col>
          <v-col cols="12">
            <v-textarea v-model="form.description" label="Description / Details" rows="3" variant="outlined" density="compact" hide-details="auto" prepend-inner-icon="mdi-note-text" />
          </v-col>
          <v-col cols="12">
            <!-- Image upload drop zone -->
            <p class="text-caption text-medium-emphasis mb-1">
              <v-icon size="14" class="mr-1">mdi-camera-image</v-icon>Photos (optional — drag and drop or click to browse)
            </p>
            <div
              class="photo-dropzone"
              :class="{ 'drag-over': isDragging, 'has-images': newPhotos.length > 0 }"
              @dragover.prevent="isDragging = true"
              @dragleave.prevent="isDragging = false"
              @drop.prevent="onDrop"
              @click="newPhotos.length === 0 && $refs.fileInput?.click()"
            >
              <input ref="fileInput" type="file" multiple accept="image/*" class="d-none" @change="onFileSelect" />
              <div v-if="newPhotos.length === 0" class="text-center py-3">
                <v-icon size="32" color="medium-emphasis">mdi-tray-arrow-up</v-icon>
                <p class="text-caption text-medium-emphasis mt-1">Drop images here or click to upload</p>
              </div>
              <div v-else class="d-flex flex-wrap ga-2 pa-2">
                <div v-for="(preview, i) in photoPreviews" :key="i" class="photo-thumb-wrap">
                  <img :src="preview" class="photo-thumb" />
                  <v-btn icon="mdi-close" size="x-small" variant="flat" color="error" class="photo-thumb-remove" @click.stop="removeNewPhoto(i)" />
                  <v-chip v-if="i < newPhotos.length" size="x-small" color="success" variant="flat" class="photo-thumb-badge">New</v-chip>
                </div>
                <div class="photo-add-tile" @click.stop="$refs.fileInput?.click()">
                  <v-icon size="24" color="medium-emphasis">mdi-plus</v-icon>
                  <span class="text-caption text-medium-emphasis">Add</span>
                </div>
              </div>
            </div>
            <!-- Existing photos (edit mode) -->
            <div v-if="existingPhotos.length > 0" class="d-flex flex-wrap ga-2 mt-2">
              <div v-for="(photo, i) in existingPhotos" :key="photo.id" class="photo-thumb-wrap">
                <img :src="resolveMediaUrl(photo.image_url || photo.image)" class="photo-thumb" />
                <v-btn icon="mdi-close" size="x-small" variant="flat" color="error" class="photo-thumb-remove" @click.stop="removeExistingPhoto(i, photo)" />
              </div>
            </div>
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
import { useMediaUrl } from '~/composables/useMediaUrl'

const props = defineProps<{
  modelValue: boolean; editing: boolean; saving: boolean
  vehicleOptions: any[]
}>()
const emit = defineEmits<{ 'update:modelValue': [v: boolean]; save: [payload: any] }>()

const { resolveMediaUrl } = useMediaUrl()

const statusOptions = [
  { label: 'Open', value: 'open' }, { label: 'Assigned', value: 'assigned' },
  { label: 'Parts Ordered', value: 'parts_ordered' }, { label: 'In Progress', value: 'in_progress' },
  { label: 'Resolved', value: 'resolved' }, { label: 'Closed', value: 'closed' },
]
const priorityOptions = [
  { label: 'Low', value: 'low' }, { label: 'Medium', value: 'medium' },
  { label: 'High', value: 'high' }, { label: 'Critical', value: 'critical' },
]

const form = reactive<any>({ title: '', vehicle: null, status: 'open', priority: 'medium', description: '' })
const errors = reactive<any>({})

// ── Photo upload state ──
const fileInput = ref<HTMLInputElement | null>(null)
const isDragging = ref(false)
const newPhotos = ref<File[]>([])
const photoPreviews = ref<string[]>([])
const existingPhotos = ref<any[]>([])
const deletedPhotoIds = ref<number[]>([])

function onDrop(e: DragEvent) {
  isDragging.value = false
  const files = Array.from(e.dataTransfer?.files || [])
  addPhotos(files)
}

function onFileSelect(e: Event) {
  const target = e.target as HTMLInputElement
  const files = Array.from(target.files || [])
  addPhotos(files)
  target.value = ''
}

function addPhotos(files: File[]) {
  const images = files.filter(f => f.type.startsWith('image/'))
  for (const f of images) {
    newPhotos.value.push(f)
    photoPreviews.value.push(URL.createObjectURL(f))
  }
}

function removeNewPhoto(i: number) {
  URL.revokeObjectURL(photoPreviews.value[i])
  newPhotos.value.splice(i, 1)
  photoPreviews.value.splice(i, 1)
}

async function removeExistingPhoto(i: number, photo: any) {
  existingPhotos.value.splice(i, 1)
  if (photo.id) deletedPhotoIds.value.push(photo.id)
}

function onToggle(v: boolean) {
  if (!v) {
    // Clean up previews when dialog closes
    photoPreviews.value.forEach(p => URL.revokeObjectURL(p))
  }
  emit('update:modelValue', v)
}

function reset(issue?: any) {
  if (issue) {
    Object.assign(form, { title: issue.title || '', vehicle: issue.vehicle || null, status: issue.status || 'open', priority: issue.priority || 'medium', description: issue.description || '', _id: issue.id })
    existingPhotos.value = (issue.issue_photos || []).map((p: any) => ({ ...p }))
  } else {
    Object.assign(form, { title: '', vehicle: null, status: 'open', priority: 'medium', description: '', _id: undefined })
    existingPhotos.value = []
  }
  // Clear new photo uploads
  photoPreviews.value.forEach(p => URL.revokeObjectURL(p))
  newPhotos.value = []
  photoPreviews.value = []
  deletedPhotoIds.value = []
  Object.keys(errors).forEach(k => delete errors[k])
}

function validate(): boolean {
  Object.keys(errors).forEach(k => delete errors[k])
  if (!form.title?.trim()) errors.title = 'Title is required'
  if (!form.vehicle) errors.vehicle = 'Vehicle is required'
  return Object.keys(errors).length === 0
}

function onSave() {
  if (!validate()) return
  const { _id, ...body } = form
  emit('save', { ...body, _id, newPhotos: newPhotos.value, deletedPhotoIds: deletedPhotoIds.value })
  // Clear new photos after emit (parent will upload them)
  photoPreviews.value.forEach(p => URL.revokeObjectURL(p))
  newPhotos.value = []
  photoPreviews.value = []
  deletedPhotoIds.value = []
}

defineExpose({ reset, populate: reset, form })
</script>

<style scoped>
.photo-dropzone {
  border: 2px dashed #cbd5e1;
  border-radius: 12px;
  cursor: pointer;
  transition: border-color 0.15s, background-color 0.15s;
  min-height: 72px;
}
.photo-dropzone:hover { border-color: #93c5fd; background: #eff6ff; }
.photo-dropzone.drag-over { border-color: #3b82f6; background: #dbeafe; }

.photo-thumb-wrap {
  position: relative;
  width: 72px;
  height: 72px;
}
.photo-thumb {
  width: 72px;
  height: 72px;
  object-fit: cover;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}
.photo-thumb-remove {
  position: absolute !important;
  top: -6px;
  right: -6px;
  z-index: 2;
}
.photo-thumb-badge {
  position: absolute;
  bottom: -2px;
  left: 0;
  right: 0;
  z-index: 2;
  border-radius: 0 0 7px 7px;
  font-size: 9px;
}
.photo-add-tile {
  width: 72px;
  height: 72px;
  border: 2px dashed #cbd5e1;
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: border-color 0.15s, background-color 0.15s;
}
.photo-add-tile:hover { border-color: #93c5fd; background: #eff6ff; }
.photo-add-tile span { font-size: 10px; margin-top: 2px; }
</style>
