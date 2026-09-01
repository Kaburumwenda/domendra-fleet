<template>
  <v-navigation-drawer :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" location="right" width="520" temporary style="top:0; height:100vh; z-index:1000">
    <div v-if="doc" class="d-flex flex-column h-100">
      <!-- Header -->
      <div class="drawer-head">
        <div class="d-flex align-center ga-2 mb-2">
          <v-chip :color="typeColor(doc.document_type)" variant="flat" size="small">
            <v-icon start size="14">{{ typeIcon(doc.document_type) }}</v-icon>{{ typeLabel(doc.document_type) }}
          </v-chip>
          <v-chip v-if="doc.is_expired" color="error" variant="flat" size="small"><v-icon start size="14">mdi-alert-circle</v-icon>Expired</v-chip>
          <v-chip v-else-if="doc.is_expiring_soon" color="warning" variant="flat" size="small"><v-icon start size="14">mdi-clock-alert</v-icon>Expiring Soon</v-chip>
        </div>
        <div class="d-flex align-center">
          <h2 class="text-h6 font-weight-bold flex-grow-1">{{ doc.title }}</h2>
          <v-btn icon variant="text" size="small" @click="$emit('update:modelValue', false)"><v-icon>mdi-close</v-icon></v-btn>
        </div>
      </div>
      <v-divider />

      <div class="drawer-body">
        <!-- File Preview Card -->
        <v-card elevation="0" border rounded="lg" class="mb-4">
          <div class="d-flex align-center ga-3 pa-4">
            <div class="file-icon" :style="{ background: fileTypeBg }">
              <v-icon size="28" :color="fileTypeColor">{{ fileIcon }}</v-icon>
            </div>
            <div class="flex-grow-1" style="min-width:0">
              <p class="text-body-2 font-weight-medium text-truncate">{{ fileName }}</p>
              <p class="text-caption text-medium-emphasis">{{ doc.file_size_display || '—' }} · {{ (doc.file_extension || 'file').toUpperCase() }}</p>
            </div>
            <v-btn
              :href="resolvedFileUrl"
              target="_blank"
              icon="mdi-download"
              variant="tonal"
              size="small"
              color="primary"
            />
          </div>
        </v-card>

        <!-- Info Grid -->
        <div class="info-grid">
          <div class="info-item">
            <v-icon size="18" color="medium-emphasis">mdi-car</v-icon>
            <div>
              <p class="text-caption text-medium-emphasis">Vehicle</p>
              <p class="text-body-2 font-weight-medium">{{ doc.vehicle_name || '—' }}</p>
            </div>
          </div>
          <div class="info-item">
            <v-icon size="18" color="medium-emphasis">mdi-account</v-icon>
            <div>
              <p class="text-caption text-medium-emphasis">Contact / Driver</p>
              <p class="text-body-2 font-weight-medium">{{ doc.contact_name || '—' }}</p>
            </div>
          </div>
          <div class="info-item">
            <v-icon size="18" color="medium-emphasis">mdi-account-circle</v-icon>
            <div>
              <p class="text-caption text-medium-emphasis">Uploaded By</p>
              <p class="text-body-2 font-weight-medium">{{ doc.uploaded_by_name || '—' }}</p>
            </div>
          </div>
          <div class="info-item">
            <v-icon size="18" color="medium-emphasis">mdi-calendar-clock</v-icon>
            <div>
              <p class="text-caption text-medium-emphasis">Expiry Date</p>
              <p class="text-body-2 font-weight-medium" :class="expiryClass">
                {{ doc.expiry_date ? fmtDate(doc.expiry_date) : 'No expiry' }}
                <v-icon v-if="doc.is_expired" size="14" color="error">mdi-alert</v-icon>
                <v-icon v-else-if="doc.is_expiring_soon" size="14" color="warning">mdi-clock-alert</v-icon>
              </p>
              <p v-if="doc.days_to_expiry != null && doc.days_to_expiry >= 0" class="text-caption text-medium-emphasis">{{ doc.days_to_expiry }} days remaining</p>
              <p v-else-if="doc.days_to_expiry != null && doc.days_to_expiry < 0" class="text-caption" style="color:#ef4444">{{ Math.abs(doc.days_to_expiry) }} days overdue</p>
            </div>
          </div>
        </div>

        <!-- Notes -->
        <div v-if="doc.notes" class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-text-box-outline</v-icon>Notes</p>
          <div class="notes-card">{{ doc.notes }}</div>
        </div>

        <!-- Metadata -->
        <div class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-information-outline</v-icon>Metadata</p>
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-key-variant</v-icon>
            <span class="text-caption text-medium-emphasis">ID:</span>
            <span class="text-body-2 font-weight-medium">#{{ doc.id }}</span>
          </div>
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-clock-outline</v-icon>
            <span class="text-caption text-medium-emphasis">Uploaded:</span>
            <span class="text-body-2">{{ fmtDate(doc.created_at) }}</span>
          </div>
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-update</v-icon>
            <span class="text-caption text-medium-emphasis">Updated:</span>
            <span class="text-body-2">{{ fmtDate(doc.updated_at) }}</span>
          </div>
        </div>
      </div>

      <!-- Actions -->
      <div class="drawer-actions">
        <v-btn v-can="'documents:update'" variant="text" prepend-icon="mdi-pencil-outline" @click="$emit('edit', doc)">Edit</v-btn>
        <v-btn variant="tonal" color="primary" prepend-icon="mdi-download" :href="resolvedFileUrl" target="_blank">Download</v-btn>
        <v-spacer />
        <v-btn v-can="'documents:delete'" variant="tonal" color="error" prepend-icon="mdi-delete-outline" @click="$emit('delete', doc)">Delete</v-btn>
      </div>
    </div>
    <div v-else class="d-flex align-center justify-center h-100">
      <v-icon size="48" color="grey-lighten-2">mdi-file-document-outline</v-icon>
    </div>
  </v-navigation-drawer>
</template>

<script setup lang="ts">
import { useMediaUrl } from '~/composables/useMediaUrl'

const props = defineProps<{ modelValue: boolean; doc: any }>()
defineEmits<{ 'update:modelValue': [v: boolean]; edit: [d: any]; delete: [d: any] }>()

const { resolveMediaUrl } = useMediaUrl()

const resolvedFileUrl = computed(() => resolveMediaUrl(props.doc?.file))

const fileName = computed(() => {
  if (!props.doc?.file) return 'No file'
  const parts = props.doc.file.split('/')
  return parts[parts.length - 1] || props.doc.file
})

const fileIcon = computed(() => {
  const ft = props.doc?.file_type_icon || 'other'
  return ({
    pdf: 'mdi-file-pdf-box',
    image: 'mdi-file-image',
    word: 'mdi-file-word-box',
    excel: 'mdi-file-excel-box',
    text: 'mdi-file-document-outline',
    other: 'mdi-file-outline',
  } as any)[ft] || 'mdi-file-outline'
})

const fileTypeBg = computed(() => {
  const ft = props.doc?.file_type_icon || 'other'
  return ({
    pdf: '#fef2f2',
    image: '#f0f7ff',
    word: '#eff6ff',
    excel: '#f0fdf4',
    text: '#f8fafc',
    other: '#f8fafc',
  } as any)[ft] || '#f8fafc'
})

const fileTypeColor = computed(() => {
  const ft = props.doc?.file_type_icon || 'other'
  return ({
    pdf: '#ef4444',
    image: '#3b82f6',
    word: '#2563eb',
    excel: '#22c55e',
    text: '#64748b',
    other: '#64748b',
  } as any)[ft] || '#64748b'
})

const expiryClass = computed(() => {
  if (props.doc?.is_expired) return 'text-error font-weight-bold'
  if (props.doc?.is_expiring_soon) return 'text-warning font-weight-bold'
  return ''
})

function typeColor(t: string) {
  return ({
    insurance: 'primary', registration: 'info', title: 'success', inspection: 'warning',
    license: 'deep-purple', medical_card: 'pink', warranty: 'teal', contract: 'indigo',
    permit: 'orange', maintenance: 'cyan', other: 'grey',
  } as any)[t] || 'grey'
}

function typeIcon(t: string) {
  return ({
    insurance: 'mdi-shield-outline', registration: 'mdi-file-document-outline',
    title: 'mdi-bookmark-outline', inspection: 'mdi-clipboard-check-outline',
    license: 'mdi-card-account-details-outline', medical_card: 'mdi-heart-pulse',
    warranty: 'mdi-shield-home-outline', contract: 'mdi-file-sign',
    permit: 'mdi-ticket-confirmation', maintenance: 'mdi-wrench-check',
    other: 'mdi-file-document-outline',
  } as any)[t] || 'mdi-file-document-outline'
}

function typeLabel(t: string) {
  return ({
    insurance: 'Insurance', registration: 'Registration', title: 'Title',
    inspection: 'Inspection', license: 'License', medical_card: 'Medical Card',
    warranty: 'Warranty', contract: 'Contract', permit: 'Permit',
    maintenance: 'Maintenance', other: 'Other',
  } as any)[t] || t
}

function fmtDate(v?: string) {
  return v ? new Date(v).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' }) : '—'
}
</script>

<style scoped>
.drawer-head { padding: 16px 20px 12px; }
.drawer-body { padding: 12px 20px; overflow-y: auto; flex: 1 1 0; }
.drawer-actions { padding: 12px 16px; border-top: 1px solid #e2e8f0; display: flex; gap: 4px; flex-wrap: wrap; align-items: center; }
.file-icon { width: 56px; height: 56px; border-radius: 12px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.info-item { display: flex; align-items: flex-start; gap: 10px; }
.section-block { margin-top: 16px; }
.notes-card { padding: 12px; border-radius: 10px; background: #f8fafc; font-size: 14px; line-height: 1.5; white-space: pre-wrap; }
.info-row { display: flex; align-items: center; gap: 8px; padding: 4px 0; }
</style>
