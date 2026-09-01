<template>
  <div class="board-wrap">
    <div class="board-grid">
      <div
        v-for="col in columns"
        :key="col.key"
        class="board-col"
        :class="{ 'drag-over': dragOver === col.key }"
        @dragover.prevent="dragOver = col.key"
        @dragleave.prevent="dragOver = null"
        @drop.prevent="onDrop(col.key)"
      >
        <div class="board-col-head" :style="{ borderTopColor: col.color }">
          <div class="d-flex align-center ga-2">
            <v-icon size="18" :color="col.color">{{ col.icon }}</v-icon>
            <span class="font-weight-bold text-subtitle-2">{{ col.label }}</span>
          </div>
          <v-chip size="x-small" color="default" variant="flat" rounded="lg">{{ col.items.length }}</v-chip>
        </div>
        <div class="board-col-body">
          <div
            v-for="job in col.items"
            :key="job.id"
            class="board-card"
            :class="{ urgent: job.priority === 'urgent', dragging: draggingId === job.id }"
            draggable="true"
            @dragstart="onDragStart(job, $event)"
            @dragend="onDragEnd"
            @click="$emit('select', job)"
          >
            <div class="board-card-top">
              <span class="board-priority" :style="priorityBg(job.priority)" />
              <p class="font-weight-bold text-body-2 text-truncate">{{ job.title }}</p>
            </div>
            <p class="text-caption text-medium-emphasis two-line">
              <v-icon size="12" color="success">mdi-circle-medium</v-icon>{{ job.pickup_address || '—' }}
              <v-icon size="12" color="primary">mdi-arrow-right</v-icon>
              <v-icon size="12" color="error">mdi-circle-medium</v-icon>{{ job.dropoff_address || '—' }}
            </p>
            <div class="board-card-meta">
              <v-icon size="14" color="medium-emphasis">mdi-truck-outline</v-icon>
              <span>{{ job.vehicle_name || 'Unassigned' }}</span>
            </div>
            <div class="board-card-meta">
              <v-icon size="14" color="medium-emphasis">mdi-account-outline</v-icon>
              <span>{{ job.driver_name || 'Unassigned' }}</span>
              <span v-if="job.eta_minutes" class="ml-auto text-caption">
                <v-icon size="13">mdi-timer-sand</v-icon>{{ job.eta_minutes }}m
              </span>
            </div>
            <div v-if="job.scheduled_start" class="board-card-meta text-medium-emphasis">
              <v-icon size="14">mdi-clock-outline</v-icon>
              <span class="text-caption">{{ fmtTime(job.scheduled_start) }}</span>
            </div>
          </div>
          <div v-if="!col.items.length" class="board-empty">
            <v-icon size="26" color="medium-emphasis">mdi-inbox-outline</v-icon>
            <p class="text-caption text-medium-emphasis mt-1">Drag a job here</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ jobs: any[] }>()
const emit = defineEmits<{ change: [jobId: number, newStatus: string]; select: [job: any] }>()

interface Column { key: string; label: string; icon: string; color: string; items: any[] }

const columns = computed(() => {
  const map: Record<string, any[]> = { pending: [], assigned: [], in_progress: [], completed: [], cancelled: [] }
  props.jobs.forEach(j => {
    const k = map[j.status] ? j.status : 'pending'
    map[k].push(j)
  })
  return [
    { key: 'pending', label: 'Pending', icon: 'mdi-inbox', color: '#64748b', items: map.pending },
    { key: 'assigned', label: 'Assigned', icon: 'mdi-truck-check', color: '#0ea5e9', items: map.assigned },
    { key: 'in_progress', label: 'In Progress', icon: 'mdi-truck-fast', color: '#f59e0b', items: map.in_progress },
    { key: 'completed', label: 'Completed', icon: 'mdi-check-circle', color: '#16a34a', items: map.completed },
    { key: 'cancelled', label: 'Cancelled', icon: 'mdi-cancel', color: '#dc2626', items: map.cancelled },
  ] as Column[]
})

const draggingId = ref<number | null>(null)
const dragOver = ref<string | null>(null)

function onDragStart(job: any, e: DragEvent) {
  draggingId.value = job.id
  if (e.dataTransfer) {
    e.dataTransfer.effectAllowed = 'move'
    e.dataTransfer.setData('text/plain', String(job.id))
  }
}
function onDragEnd() {
  draggingId.value = null
  dragOver.value = null
}
function onDrop(target: string) {
  dragOver.value = null
  const id = draggingId.value
  if (id == null) return
  const job = props.jobs.find(j => j.id === id)
  if (job && job.status !== target) emit('change', id, target)
  draggingId.value = null
}

function priorityBg(p: string) {
  return { background: p === 'urgent' ? '#ef4444' : p === 'high' ? '#f97316' : p === 'medium' ? '#f59e0b' : '#94a3b8' }
}
function fmtTime(v: string) {
  try { return new Date(v).toLocaleString([], { hour: '2-digit', minute: '2-digit', month: 'short', day: 'numeric' }) } catch { return '—' }
}
</script>

<style scoped>
.board-wrap { overflow-x: auto; padding-bottom: 6px; }
.board-grid { display:grid; grid-template-columns: repeat(5, minmax(240px, 1fr)); gap:12px; min-width: 1240px; }
.board-col { background:#f8fafc; border:1px solid #e2e8f0; border-radius:14px; display:flex; flex-direction:column; min-height: 420px; transition: background .15s, border-color .15s; }
.board-col.drag-over { background:#eef2ff; border-color:#6366f1; }
.board-col-head { display:flex; align-items:center; justify-content:space-between; padding:12px 14px; border-top:3px solid #64748b; background:#fff; border-radius:14px 14px 0 0; }
.board-col-body { flex:1; padding:10px; overflow-y:auto; display:flex; flex-direction:column; gap:10px; }
.board-card { background:#fff; border:1px solid #e2e8f0; border-radius:12px; padding:12px; cursor:grab; box-shadow: 0 1px 2px rgba(2,6,23,.04); transition: box-shadow .15s, border-color .15s, transform .1s; }
.board-card:hover { box-shadow: 0 6px 18px rgba(2,6,23,.08); border-color:#c7d2fe; }
.board-card:active { cursor:grabbing; }
.board-card.dragging { opacity:.4; transform: rotate(1deg); }
.board-card.urgent { border-left:3px solid #ef4444; }
.board-card-top { display:flex; align-items:flex-start; gap:8px; margin-bottom:6px; }
.board-priority { width:8px; height:8px; border-radius:50%; margin-top:6px; flex-shrink:0; }
.board-card-meta { display:flex; align-items:center; gap:5px; font-size:12px; color:#475569; margin-top:4px; }
.two-line { display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }
.board-empty { display:flex; flex-direction:column; align-items:center; justify-content:center; padding:24px; min-height: 120px; border:2px dashed #cbd5e1; border-radius:10px; margin-top: 6px; }
</style>
