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
            v-for="a in col.items"
            :key="a.id"
            class="board-card"
            :class="{ overdue: cardStatus(a) === 'overdue', dragging: draggingId === a.id }"
            draggable="true"
            @dragstart="onDragStart(a, $event)"
            @dragend="onDragEnd"
            @click="$emit('select', a)"
          >
            <div class="board-card-top">
              <span class="board-dot" :style="dotStyle(cardStatus(a))" />
              <p class="font-weight-bold text-body-2 text-truncate" style="color:#4f46e5; font-family:'JetBrains Mono',monospace; letter-spacing:.02em">{{ a.agreement_no }}</p>
            </div>
            <div class="board-card-meta">
              <v-icon size="14" color="medium-emphasis">mdi-account-outline</v-icon>
              <span class="text-truncate">{{ a.customer_name || '—' }}</span>
            </div>
            <div class="board-card-meta">
              <v-icon size="14" color="medium-emphasis">mdi-car-side</v-icon>
              <span class="text-truncate">{{ a.vehicle_display || 'Unassigned' }}</span>
            </div>
            <div class="board-card-meta">
              <v-icon size="14" color="medium-emphasis">mdi-cash-multiple</v-icon>
              <span class="font-weight-bold" style="color:#059669">{{ currencySymbol }}{{ Number(a.total_amount || 0).toLocaleString() }}</span>
              <v-chip v-if="a.payment_status && a.status !== 'draft' && a.status !== 'cancelled'" size="x-small" :color="payColor(a.payment_status)" variant="flat" class="ml-auto text-capitalize" style="height:18px; font-size:10px">
                {{ a.payment_status }}
              </v-chip>
            </div>
            <div v-if="a.start_datetime" class="board-card-meta text-medium-emphasis">
              <v-icon size="14">mdi-calendar-clock</v-icon>
              <span class="text-caption">{{ fmtDate(a.start_datetime) }} → {{ a.end_datetime ? fmtDate(a.end_datetime) : '—' }}</span>
            </div>
          </div>
          <div v-if="!col.items.length" class="board-empty">
            <v-icon size="26" color="medium-emphasis">mdi-inbox-outline</v-icon>
            <p class="text-caption text-medium-emphasis mt-1">Drag a card here</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  agreements: any[]
  currencySymbol: string
  activeFilter?: string | null
}>()

const emit = defineEmits<{
  select: [agreement: any]
  change: [id: number, newStatus: string]
}>()

const draggingId = ref<number | null>(null)
const dragOver = ref<string | null>(null)

function cardStatus(a: any): string {
  // effective status: active → overdue if end_datetime passed
  if (a.status === 'active' && a.end_datetime) {
    const end = new Date(a.end_datetime).getTime()
    if (!isNaN(end) && end < Date.now()) return 'overdue'
  }
  return a.status || 'draft'
}

const columns = computed(() => {
  const map: Record<string, any[]> = { draft: [], active: [], overdue: [], completed: [], cancelled: [] }
  ;(props.agreements || []).forEach((a: any) => {
    const s = cardStatus(a)
    if (map[s]) map[s].push(a)
    else map.draft.push(a)
  })
  return [
    { key: 'draft', label: 'Draft', icon: 'mdi-file-document-outline', color: '#64748b', items: map.draft },
    { key: 'active', label: 'Active', icon: 'mdi-car-key', color: '#10b981', items: map.active },
    { key: 'overdue', label: 'Overdue', icon: 'mdi-alert-octagon', color: '#f59e0b', items: map.overdue },
    { key: 'completed', label: 'Completed', icon: 'mdi-check-circle', color: '#3b82f6', items: map.completed },
    { key: 'cancelled', label: 'Cancelled', icon: 'mdi-cancel', color: '#ef4444', items: map.cancelled },
  ] as { key: string; label: string; icon: string; color: string; items: any[] }[]
})

function onDragStart(a: any, e: DragEvent) {
  draggingId.value = a.id
  if (e.dataTransfer) {
    e.dataTransfer.effectAllowed = 'move'
    e.dataTransfer.setData('text/plain', String(a.id))
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
  const a = (props.agreements || []).find((x: any) => x.id === id)
  if (a && cardStatus(a) !== target) emit('change', id, target)
  draggingId.value = null
}

function dotStyle(s: string) {
  const map: Record<string, string> = { draft: '#64748b', active: '#10b981', overdue: '#f59e0b', completed: '#3b82f6', cancelled: '#ef4444' }
  return { background: map[s] || '#94a3b8' }
}
function payColor(ps: string) {
  return { paid: 'success', partial: 'warning', unpaid: 'error' }[ps] || 'default'
}
function fmtDate(d: string): string {
  return new Date(d).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
}
</script>

<style scoped>
.board-wrap { overflow-x: auto; padding-bottom: 6px; }
.board-grid { display:grid; grid-template-columns: repeat(5, minmax(240px, 1fr)); gap:12px; min-width: 1240px; }
.board-col { background:#f8fafc; border:1px solid #e2e8f0; border-radius:14px; display:flex; flex-direction:column; min-height: 420px; max-height: 65vh; transition: background .15s, border-color .15s; }
.board-col.drag-over { background:#eef2ff; border-color:#6366f1; }
.board-col-head { display:flex; align-items:center; justify-content:space-between; padding:12px 14px; border-top:3px solid #64748b; background:#fff; border-radius:14px 14px 0 0; }
.board-col-body { flex:1; padding:10px; overflow-y:auto; display:flex; flex-direction:column; gap:10px; }
.board-card { background:#fff; border:1px solid #e2e8f0; border-radius:12px; padding:12px; cursor:grab; box-shadow: 0 1px 2px rgba(2,6,23,.04); transition: box-shadow .15s, border-color .15s, transform .1s; }
.board-card:hover { box-shadow: 0 6px 18px rgba(2,6,23,.08); border-color:#c7d2fe; }
.board-card:active { cursor:grabbing; }
.board-card.dragging { opacity:.4; transform: rotate(1deg); }
.board-card.overdue { border-left:3px solid #ef4444; }
.board-card-top { display:flex; align-items:flex-start; gap:8px; margin-bottom:6px; }
.board-dot { width:8px; height:8px; border-radius:50%; margin-top:6px; flex-shrink:0; }
.board-card-meta { display:flex; align-items:center; gap:5px; font-size:12px; color:#475569; margin-top:4px; }
.board-empty { display:flex; flex-direction:column; align-items:center; justify-content:center; padding:24px; min-height: 120px; border:2px dashed #cbd5e1; border-radius:10px; margin-top: 6px; }
</style>
