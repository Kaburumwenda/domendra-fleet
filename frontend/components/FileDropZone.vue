<template>
  <div
    class="file-drop-zone"
    :class="{ 'file-drop-zone--active': isDragging, 'file-drop-zone--filled': !!file }"
    @dragover.prevent="isDragging = true"
    @dragleave.prevent="isDragging = false"
    @drop.prevent="onDrop"
    @click="$refs.fileInput.click()"
  >
    <input ref="fileInput" type="file" :accept="accept" class="d-none" @change="onFileChange" />

    <template v-if="!file">
      <div class="file-drop-zone__empty">
        <v-icon :icon="icon" size="32" color="primary" class="mb-2" />
        <p class="text-body-2 font-weight-medium" style="color: #1e293b">{{ label }}</p>
        <p class="text-caption text-medium-emphasis">
          <v-icon size="14" class="mr-1">mdi-tray-arrow-up</v-icon>
          Drag &amp; drop here, or <span class="text-primary font-weight-medium">browse</span>
        </p>
      </div>
    </template>

    <template v-else>
      <div class="file-drop-zone__filled">
        <v-icon :icon="fileIcon" size="28" color="success" class="mr-2" />
        <div class="file-drop-zone__info" style="min-width: 0">
          <p class="text-body-2 font-weight-medium text-truncate" style="color: #1e293b">{{ file.name }}</p>
          <p class="text-caption text-medium-emphasis">{{ formatSize(file.size) }}</p>
        </div>
        <v-btn icon="mdi-close" variant="text" size="small" color="error" @click.stop="$emit('remove')" class="ml-2" />
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  label: string
  icon?: string
  file: File | null
  accept?: string
}>()

const emit = defineEmits<{ upload: [file: File]; remove: [] }>()

const isDragging = ref(false)

const fileIcon = computed(() => {
  if (!props.file) return 'mdi-file-outline'
  const name = props.file.name.toLowerCase()
  if (/\.(jpg|jpeg|png|gif|webp)$/.test(name)) return 'mdi-file-image-outline'
  if (/\.pdf$/.test(name)) return 'mdi-file-pdf-box-outline'
  return 'mdi-file-outline'
})

function onDrop(e: DragEvent) {
  isDragging.value = false
  const files = e.dataTransfer?.files
  if (files && files.length) emit('upload', files[0])
}

function onFileChange(e: Event) {
  const target = e.target as HTMLInputElement
  const file = target.files?.[0]
  if (file) emit('upload', file)
  target.value = ''
}

function formatSize(bytes: number) {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}
</script>

<style scoped>
.file-drop-zone {
  position: relative;
  min-height: 120px;
  border: 2px dashed #c7d2fe;
  border-radius: 12px;
  background: #f8fafc;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: border-color 0.2s ease, background 0.2s ease, transform 0.15s ease;
  padding: 12px;
}
.file-drop-zone:hover {
  border-color: #818cf8;
  background: #f5f3ff;
}
.file-drop-zone--active {
  border-color: #6366f1;
  background: #eef2ff;
  transform: scale(1.01);
}
.file-drop-zone--filled {
  border-style: solid;
  border-color: #bbf7d0;
  background: #f0fdf4;
}
.file-drop-zone__empty {
  text-align: center;
}
.file-drop-zone__filled {
  display: flex;
  align-items: center;
  width: 100%;
}
.file-drop-zone__info {
  flex: 1;
  min-width: 0;
}
</style>
