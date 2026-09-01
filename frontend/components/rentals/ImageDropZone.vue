<template>
  <div
    class="drop-zone"
    :class="{ dragging: isDragging, filled: !!file || !!modelValue || !!existingUrl, portrait: aspect === 'portrait' }"
    @click="triggerFileInput"
    @dragover.prevent="isDragging = true"
    @dragenter.prevent="isDragging = true"
    @dragleave.prevent="isDragging = false"
    @drop.prevent="onDrop"
  >
    <input
      ref="inputRef"
      type="file"
      accept="image/*"
      class="hidden-input"
      @change="onFileSelect"
    />

    <!-- Preview / Placeholder -->
    <div v-if="previewUrl" class="preview">
      <img :src="previewUrl" alt="" class="preview-img" />
      <div class="overlay">
        <v-btn
          icon="mdi-pencil-outline" size="x-small" variant="flat" color="white"
          @click.stop="triggerFileInput"
        />
        <v-btn
          icon="mdi-trash-can-outline" size="x-small" variant="flat" color="error"
          @click.stop="remove"
        />
      </div>
    </div>

    <div v-else class="placeholder">
      <v-icon :icon="icon" size="28" class="mb-1" :color="isDragging ? 'primary' : 'medium-emphasis'" />
      <div class="text-caption font-weight-medium" :style="{ color: isDragging ? '#4f46e5' : '#94a3b8' }">
        {{ label }}
      </div>
      <div class="text-caption text-medium-emphasis" style="font-size: 0.68rem; line-height: 1.2">
        {{ hint }}
      </div>
      <div class="text-caption mt-1" style="font-size: 0.65rem; color: #cbd5e1">
        Drop or Click
      </div>
    </div>

    <!-- Label chip -->
    <div class="zone-label">
      {{ file || modelValue || existingUrl ? '✓ ' + label : label }}
    </div>
  </div>
</template>

<script setup lang="ts">
const props = withDefaults(defineProps<{
  label: string
  icon?: string
  hint?: string
  aspect?: 'portrait' | 'landscape' | 'square'
  existingUrl?: string
}>(), {
  icon: 'mdi-image-plus-outline',
  hint: '',
  aspect: 'square',
  existingUrl: '',
})

const emit = defineEmits<{
  'update:modelValue': [File | null]
  'remove-existing': []
}>()

const modelValue = defineModel<File | null>()

const inputRef = ref<HTMLInputElement>()
const isDragging = ref(false)
const file = ref<File | null>(null)
const localUrl = ref<string>('')

const previewUrl = computed(() => {
  if (file.value && localUrl.value) return localUrl.value
  if (props.existingUrl) return props.existingUrl
  return ''
})

function triggerFileInput() {
  inputRef.value?.click()
}

function onFileSelect(e: Event) {
  const target = e.target as HTMLInputElement
  if (target.files && target.files[0]) {
    applyFile(target.files[0])
  }
}

function onDrop(e: DragEvent) {
  isDragging.value = false
  const dropped = e.dataTransfer?.files
  if (dropped && dropped[0]) {
    applyFile(dropped[0])
  }
}

function applyFile(f: File) {
  if (!f.type.startsWith('image/')) return
  if (localUrl.value) URL.revokeObjectURL(localUrl.value)
  file.value = f
  localUrl.value = URL.createObjectURL(f)
  modelValue.value = f
  emit('update:modelValue', f)
}

function remove() {
  if (localUrl.value) URL.revokeObjectURL(localUrl.value)
  file.value = null
  localUrl.value = ''
  // Signal parent: null = no new file; '' sent as a sentinel to clear
  modelValue.value = null
  emit('update:modelValue', null)
  if (inputRef.value) inputRef.value.value = ''
  // If there was an existing (server-side) image, ask parent to clear it.
  if (props.existingUrl) {
    emit('remove-existing')
  }
}

onBeforeUnmount(() => {
  if (localUrl.value) URL.revokeObjectURL(localUrl.value)
})

// Allow parent to set existing file via modelValue reset
watch(() => modelValue.value, (v) => {
  if (!v && file.value) {
    if (localUrl.value) URL.revokeObjectURL(localUrl.value)
    file.value = null
    localUrl.value = ''
  }
})
</script>

<style scoped>
.drop-zone {
  border: 2px dashed #cbd5e1;
  border-radius: 12px;
  min-height: 140px;
  cursor: pointer;
  transition: all 0.25s;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  position: relative;
  overflow: hidden;
  background: #f8fafc;
}
.drop-zone.portrait {
  min-height: 180px;
}
.drop-zone:hover {
  border-color: #a5b4fc;
  background: #eef2ff;
}
.drop-zone.dragging {
  border-color: #4f46e5;
  border-style: solid;
  background: #e0e7ff;
  transform: scale(1.02);
}
.drop-zone.filled {
  border-style: solid;
  border-color: #10b981;
  background: #f0fdf4;
}

.hidden-input {
  display: none;
}

.placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 12px 8px;
  gap: 4px;
  text-align: center;
}

.preview {
  position: absolute;
  inset: 0;
}
.preview-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.overlay {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  opacity: 0;
  transition: opacity 0.2s;
  background: rgba(0, 0, 0, 0.4);
}
.drop-zone:hover .overlay {
  opacity: 1;
}

.zone-label {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  font-size: 0.68rem;
  font-weight: 600;
  text-align: center;
  padding: 3px 8px;
  background: rgba(255, 255, 255, 0.92);
  color: #475569;
  border-top: 1px solid rgba(0, 0, 0, 0.05);
  pointer-events: none;
}
.drop-zone.filled .zone-label {
  background: rgba(16, 185, 129, 0.1);
  color: #047857;
  border-top: 1px solid rgba(16, 185, 129, 0.2);
}
</style>
