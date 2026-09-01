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
            v-for="p in col.items"
            :key="p.id"
            class="board-card"
            :class="{ dragging: draggingId === p.id }"
            draggable="true"
            @dragstart="onDragStart(p, $event)"
            @dragend="onDragEnd"
            @click="$emit('select', p)"
          >
            <div class="board-card-top">
              <span class="board-dot" :style="dotStyle(col.key)" />
              <p class="font-weight-bold text-body-2 text-truncate" style="color:#4f46e5; font-family:'JetBrains Mono',monospace; letter-spacing:.02em">{{ p.agreement_no }}</p>
            </div>
            <div class="board-card-meta">
              <v-icon size="14" color="medium-emphasis">mdi-account-outline</v-icon>
              <span class="text-truncate">{{ p.customer_name || '—' }}</span>
            </div>
            <div class="board-card-meta">
              <v-icon size="14" color="success">mdi-cash-multiple</v-icon>
              <span class="font-weight-bold" style="color:#059669">{{ currencySymbol }}{{ Number(p.amount || 0).toLocaleString() }}</span>
            </div>
            <div class="board-card-meta">
              <v-icon size="14" :color="methodColor(p.payment_method)">{{ methodIcon(p.payment_method) }}</v-icon>
              <span class="text-capitalize">{{ p.payment_method || '—' }}</span>
              <span v-if="p.reference" class="ml-auto text-caption text-medium-emphasis text-truncate" style="max-width:80px">{{ p.reference }}</span>
            </div>
            <div v-if="p.paid_at" class="board-card-meta text-medium-emphasis">
              <v-icon size="14">mdi-clock-outline</v-icon>
              <span class="text-caption">{{ fmtDate(p.paid_at) }}</span>
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
  payments: any[]
  currencySymbol: string
}>()

const emit = defineEmits<{
  select: [payment: any]
  change: [id: number, newStatus: string]
}>()

const draggingId = ref<number | null>(null)
const dragOver = ref<string | null>(null)

const columns = computed(() => {
  const map: Record<string, any[]> = { completed: [], pending: [], failed: [], refunded: [] }
  ;(props.payments || []).forEach((p: any) => {
    const s = p.status || 'completed'
    if (map[s]) map[s].push(p)
    else map.completed.push(p)
  })
  return [
    { key: 'completed', label: 'Completed', icon: 'mdi-check-circle', color: '#10b981', items: map.completed },
    { key: 'pending', label: 'Pending', icon: 'mdi-clock-outline', color: '#f59e0b', items: map.pending },
    { key: 'failed', label: 'Failed', icon: 'mdi-alert-circle', color: '#ef4444', items: map.failed },
    { key: 'refunded', label: 'Refunded', icon: 'mdi-refund', color: '#6366f1', items: map.refunded },
  ] as { key: string; label: string; icon: string; color: string; items: any[] }[]
})

function onDragStart(p: any, e: DragEvent) {
  draggingId.value = p.id
  if (e.dataTransfer) {
    e.dataTransfer.effectAllowed = 'move'
    e.dataTransfer.setData('text/plain', String(p.id))
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
  const p = (props.payments || []).find((x: any) => x.id === id)
  if (p && p.status !== target) emit('change', id, target)
  draggingId.value = null
}

function dotStyle(s: string) {
  const map: Record<string, string> = { completed: '#10b981', pending: '#f59e0b', failed: '#ef4444', refunded: '#6366f1' }
  return { background: map[s] || '#94a3b8' }
}
function methodColor(m: string) {
  return { mpesa: 'success', cash: 'warning', card: 'info', bank_transfer: 'primary', cheque: 'secondary', other: 'default' }[m] || 'default'
}
function methodIcon(m: string) {
  return { mpesa: 'mdi-cellphone', cash: 'mdi-cash', card: 'mdi-credit-card', bank_transfer: 'mdi-bank', cheque: 'mdi-checkbook', other: 'mdi-swap-horizontal' }[m] || 'mdi-cash'
}
function fmtDate(d: string): string {
  return new Date(d).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: '2-digit' })
}
</script>

<style scoped>
.board-wrap { overflow-x: auto; padding-bottom: 6px; }
.board-grid { display:grid; grid-template-columns: repeat(4, minmax(260px, 1fr)); gap:12px; min-width: 1040px; }
.board-col { background:#f8fafc; border:1px solid #e2e8f0; border-radius:14px; display:flex; flex-direction:column; min-height: 420px; max-height: 65vh; transition: background .15s, border-color .15s; }
.board-col.drag-over { background:#eef2ff; border-color:#6366f1; }
.board-col-head { display:flex; align-items:center; justify-content:space-between; padding:12px 14px; border-top:3px solid #64748b; background:#fff; border-radius:14px 14px 0 0; }
.board-col-body { flex:1; padding:10px; overflow-y:auto; display:flex; flex-direction:column; gap:10px; }
.board-card { background:#fff; border:1px solid #e2e8f0; border-radius:12px; padding:12px; cursor:grab; box-shadow: 0 1px 2px rgba(2,6,23,.04); transition: box-shadow .15s, border-color .15s, transform .1s; }
.board-card:hover { box-shadow: 0 6px 18px rgba(2,6,23,.08); border-color:#c7d2fe; }
.board-card:active { cursor:grabbing; }
.board-card.dragging { opacity:.4; transform: rotate(1deg); }
.board-card-top { display:flex; align-items:flex-start; gap:8px; margin-bottom:6px; }
.board-card-meta { display:flex; align-items:center; gap:5px; font-size:12px; color:#475569; margin-top:4px; }
.board-empty { display:flex; flex-direction:column; align-items:center; justify-content:center; padding:24px; min-height: 120px; border:2px dashed #cbd5e1; border-radius:10px; margin-top: 6px; }
</style>
