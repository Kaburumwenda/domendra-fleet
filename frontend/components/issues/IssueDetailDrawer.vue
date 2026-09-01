<template>
  <v-navigation-drawer :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" location="right" width="520" temporary permanent style="top:0; height:100vh; z-index:1000">
    <div v-if="issue" class="d-flex flex-column h-100">
      <!-- Header -->
      <div class="drawer-head">
        <div class="d-flex align-center ga-2 mb-2">
          <v-chip :color="statusColor(issue.status)" variant="flat" size="small" class="text-capitalize">
            <v-icon start size="14">{{ statusIcon(issue.status) }}</v-icon>{{ issue.status ? issue.status.replace('_', ' ') : '' }}
          </v-chip>
          <v-chip :color="priorityColor(issue.priority)" variant="tonal" size="small" class="text-capitalize font-weight-bold">
            <v-icon start size="14">{{ priorityIcon(issue.priority) }}</v-icon>{{ issue.priority }}
          </v-chip>
          <v-chip v-if="issue.has_work_order" color="info" variant="tonal" size="small">
            <v-icon start size="14">mdi-clipboard-list-outline</v-icon>WO #{{ issue.work_order_id }}
          </v-chip>
        </div>
        <div class="d-flex align-center">
          <h2 class="text-h6 font-weight-bold flex-grow-1">{{ issue.title }}</h2>
          <v-btn icon variant="text" size="small" @click="$emit('update:modelValue', false)"><v-icon>mdi-close</v-icon></v-btn>
        </div>
        <p class="text-caption text-medium-emphasis">#{{ issue.id }} · {{ fmt(issue.created_at) }}</p>
      </div>
      <v-divider />

      <div class="drawer-body">
        <!-- Issue Info -->
        <div class="info-list">
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-truck</v-icon>
            <div>
              <p class="text-caption text-medium-emphasis">Vehicle</p>
              <p class="text-body-2 font-weight-medium">{{ issue.vehicle_name || '—' }}</p>
            </div>
          </div>
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-account-voice-outline</v-icon>
            <div>
              <p class="text-caption text-medium-emphasis">Reported By</p>
              <p class="text-body-2 font-weight-medium">{{ issue.reported_by_name || 'Unassigned' }}</p>
            </div>
          </div>
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-clock-edit-outline</v-icon>
            <div>
              <p class="text-caption text-medium-emphasis">Last Updated</p>
              <p class="text-body-2 font-weight-medium">{{ fmt(issue.updated_at) }}</p>
            </div>
          </div>
        </div>

        <!-- Description -->
        <div v-if="issue.description" class="desc-block">
          <p class="text-subtitle-2 font-weight-bold mb-1"><v-icon size="16" class="mr-1">mdi-note-text-outline</v-icon>Description</p>
          <p class="text-body-2">{{ issue.description }}</p>
        </div>

        <!-- Photos -->
        <div v-if="photos.length" class="photos-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-camera-image-outline</v-icon>Photos ({{ photos.length }})</p>
          <div class="d-flex flex-wrap ga-2">
            <div v-for="photo in photos" :key="photo.id" class="detail-thumb-wrap">
              <img :src="resolveMediaUrl(photo.image_url || photo.image)" class="detail-thumb" @click="openPhoto(photo)" />
            </div>
          </div>
        </div>

        <!-- Work Order Info -->
        <div v-if="workOrder" class="wo-block">
          <div class="d-flex align-center justify-space-between mb-3">
            <p class="text-subtitle-2 font-weight-bold"><v-icon size="18" color="info" class="mr-1">mdi-clipboard-list-outline</v-icon>Work Order #{{ workOrder.id }}</p>
            <v-chip :color="statusColor(workOrder.status)" variant="tonal" size="small" class="text-capitalize">{{ workOrder.status?.replace('_', ' ') }}</v-chip>
          </div>
          <div class="cost-grid">
            <div class="cost-item">
              <p class="text-caption text-medium-emphasis">Estimated</p>
              <p class="text-subtitle-1 font-weight-bold text-primary">{{ currencySymbol }}{{ money(workOrder.estimated_cost) }}</p>
            </div>
            <div class="cost-item">
              <p class="text-caption text-medium-emphasis">Actual</p>
              <p class="text-subtitle-1 font-weight-bold text-warning">{{ currencySymbol }}{{ money(workOrder.actual_cost) }}</p>
            </div>
            <div class="cost-item">
              <p class="text-caption text-medium-emphasis">Total Cost</p>
              <p class="text-subtitle-1 font-weight-bold text-success">{{ currencySymbol }}{{ money(workOrder.total_cost) }}</p>
            </div>
          </div>
          <div class="info-list mt-3">
            <div class="info-row">
              <v-icon size="18" color="medium-emphasis">mdi-account-wrench</v-icon>
              <div>
                <p class="text-caption text-medium-emphasis">Assigned To</p>
                <p class="text-body-2 font-weight-medium">{{ workOrder.assigned_to_name || 'Unassigned' }}</p>
              </div>
            </div>
            <div class="info-row">
              <v-icon size="18" color="medium-emphasis">mdi-swap-horizontal</v-icon>
              <div>
                <p class="text-caption text-medium-emphasis">Assignment Type</p>
                <p class="text-body-2 font-weight-medium text-capitalize">{{ workOrder.assignment_type?.replace('_', ' ') }}</p>
              </div>
            </div>
            <div class="info-row">
              <v-icon size="18" color="medium-emphasis">mdi-timer-sand</v-icon>
              <div>
                <p class="text-caption text-medium-emphasis">Downtime</p>
                <p class="text-body-2 font-weight-medium">{{ workOrder.downtime_hours || 0 }}h</p>
              </div>
            </div>
          </div>

          <!-- Notes -->
          <div v-if="workOrder.notes?.length" class="notes-block">
            <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-comment-text-multiple-outline</v-icon>Notes ({{ workOrder.notes.length }})</p>
            <div v-for="n in workOrder.notes" :key="n.id" class="note-item">
              <div class="d-flex align-center ga-1 mb-1">
                <v-avatar size="20" :color="noteColor(n.author?.full_name)" variant="tonal"><span class="text-caption font-weight-bold">{{ initials(n.author?.full_name || '?') }}</span></v-avatar>
                <span class="text-caption font-weight-medium">{{ n.author_name || 'System' }}</span>
                <v-chip v-if="n.visibility === 'internal'" size="x-small" variant="tonal" color="grey">Internal</v-chip>
                <v-chip v-else size="x-small" variant="tonal" color="info">External</v-chip>
                <span class="text-caption text-medium-emphasis ml-auto">{{ fmt(n.created_at) }}</span>
              </div>
              <p class="text-body-2">{{ n.content }}</p>
            </div>
          </div>
        </div>

        <!-- Work Order Create / View -->
        <div v-if="!issue.has_work_order && issue.status !== 'closed'" class="mt-4">
          <v-btn color="info" variant="outlined" block prepend-icon="mdi-wrench-plus" @click="$emit('createWorkOrder', issue)">
            Create Work Order
          </v-btn>
        </div>
        <div v-if="issue.has_work_order && workOrder" class="mt-2">
          <v-btn color="info" variant="outlined" block prepend-icon="mdi-arrow-expand-all" :to="`/app/work-orders/${issue.work_order_id}`">
            View Full Work Order
          </v-btn>
        </div>
      </div>

      <!-- Actions -->
      <div class="drawer-actions">
        <v-btn variant="text" prepend-icon="mdi-pencil-outline" @click="$emit('edit', issue)">Edit</v-btn>
        <v-btn variant="text" prepend-icon="mdi-wrench" color="info" @click="$emit('assign', issue)">Assign / Create WO</v-btn>
        <v-spacer />
        <v-btn variant="text" color="error" prepend-icon="mdi-trash-can-outline" @click="$emit('delete', issue)">Delete</v-btn>
      </div>
    </div>
    <div v-else class="d-flex align-center justify-center h-100">
      <v-icon size="48" color="grey-lighten-2">mdi-alert-circle-outline</v-icon>
    </div>
  </v-navigation-drawer>
</template>

<script setup lang="ts">
import { useMediaUrl } from '~/composables/useMediaUrl'

const props = defineProps<{ modelValue: boolean; issue: any; currencySymbol: string }>()
const emit = defineEmits<{ 'update:modelValue': [v: boolean]; edit: [i: any]; delete: [i: any]; assign: [i: any]; createWorkOrder: [i: any] }>()

const { resolveMediaUrl } = useMediaUrl()

const workOrder = computed(() => props.issue?.work_order_id ? props.woData : null)
const woData = ref<any>(null)
const photos = computed<any[]>(() => props.issue?.issue_photos || [])

function openPhoto(photo: any) {
  const url = resolveMediaUrl(photo.image_url || photo.image)
  if (url && process.client) window.open(url, '_blank')
}

watch(() => props.issue, async (iss) => {
  woData.value = null
  if (iss?.work_order_id) {
    try {
      const { $api } = useNuxtApp()
      woData.value = await $api(`/issues/work-orders/${iss.work_order_id}/`)
    } catch { /* no-op */ }
  }
}, { immediate: true })

function money(v: any) { return parseFloat(v || 0).toFixed(2) }
function fmt(v?: string) { return v ? new Date(v).toLocaleString([], { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : '—' }
function statusColor(s: string) { return ({ open: 'blue', assigned: 'indigo', parts_ordered: 'amber', in_progress: 'orange', resolved: 'success', closed: 'grey', completed: 'success', closed_: 'grey' } as any)[s] || 'grey' }
function priorityColor(p: string) { return ({ low: 'grey', medium: 'yellow-darken-2', high: 'orange', critical: 'error' } as any)[p] || 'grey' }
function statusIcon(s: string) { return ({ open: 'mdi-alert-circle-outline', assigned: 'mdi-account-check-outline', parts_ordered: 'mdi-package-variant-closed', in_progress: 'mdi-progress-clock', resolved: 'mdi-check-circle', closed: 'mdi-lock-check-outline' } as any)[s] || 'mdi-alert' }
function priorityIcon(p: string) { return ({ low: 'mdi-flag-outline', medium: 'mdi-flag', high: 'mdi-flag-variant', critical: 'mdi-flag-variant' } as any)[p] || 'mdi-flag-outline' }
function initials(n: string) { return (n || '?').split(' ').map((w: string) => w[0]).slice(0, 2).join('').toUpperCase() }
function noteColor(n: string) { const cs = ['#6366f1', '#0ea5e9', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6']; let h = 0; for (let i = 0; i < n.length; i++) h = n.charCodeAt(i) + ((h << 5) - h); return cs[Math.abs(h) % cs.length] }
</script>

<style scoped>
.drawer-head { padding: 16px 20px 12px; }
.drawer-body { padding: 12px 20px; overflow-y: auto; flex: 1 1 0; }
.drawer-actions { padding: 12px 16px; border-top: 1px solid #e2e8f0; display: flex; gap: 4px; flex-wrap: wrap; }
.info-list { display: flex; flex-direction: column; gap: 12px; }
.info-row { display: flex; align-items: flex-start; gap: 10px; }
.cost-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; }
.cost-item { background: #f8fafc; border-radius: 10px; padding: 10px 12px; text-align: center; }
.desc-block { margin-top: 16px; padding: 12px 14px; background: #f8fafc; border-radius: 10px; }
.photos-block { margin-top: 16px; }
.detail-thumb-wrap { position: relative; }
.detail-thumb {
  width: 88px; height: 88px; object-fit: cover; border-radius: 10px;
  border: 1px solid #e2e8f0; cursor: pointer; transition: opacity 0.15s;
}
.detail-thumb:hover { opacity: 0.85; }
.wo-block { margin-top: 16px; padding: 14px; border: 1px solid #e2e8f0; border-radius: 12px; background: #fafbfc; }
.notes-block { margin-top: 16px; }
.note-item { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 10px 12px; margin-bottom: 8px; }
</style>
