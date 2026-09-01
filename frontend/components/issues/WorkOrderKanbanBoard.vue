<template>
  <div class="kanban-board">
    <div v-for="col in columns" :key="col.key" class="kanban-col">
      <div class="kanban-col-head" :style="{ borderTopColor: col.color }">
        <div class="d-flex align-center ga-2">
          <v-icon size="18" :color="col.color">{{ col.icon }}</v-icon>
          <span class="font-weight-bold text-body-2">{{ col.label }}</span>
          <v-chip size="x-small" variant="tonal" :color="col.color">{{ col.count }}</v-chip>
        </div>
      </div>
      <div class="kanban-col-body">
        <div v-for="item in col.items" :key="item.id" class="kanban-card" draggable="true" @dragstart="onDragStart($event, item)" @click="$emit('openDetail', item)">
          <div class="d-flex align-start ga-2 mb-1">
            <v-chip size="x-small" variant="tonal" :color="item.assignment_type === 'internal' ? 'primary' : 'deep-purple'">
              {{ item.assignment_type === 'internal' ? 'Internal' : 'External' }}
            </v-chip>
            <v-spacer />
            <span class="text-caption text-medium-emphasis">#{{ item.id }}</span>
          </div>
          <p class="kanban-title">{{ item.issue_title || 'Untitled' }}</p>
          <p class="kanban-vehicle text-caption text-medium-emphasis">{{ item.vehicle_name }}</p>
          <div class="d-flex align-center ga-2 mt-2">
            <v-icon size="14" color="medium-emphasis">mdi-account-hard-hat</v-icon>
            <span class="text-caption text-medium-emphasis">{{ item.assigned_to_name || 'Unassigned' }}</span>
            <v-spacer />
            <span class="text-caption font-weight-bold text-primary">{{ currencySymbol }}{{ money(item.total_cost) }}</span>
          </div>
          <div v-if="item.time_logs?.length || item.parts_used?.length || item.notes?.length" class="d-flex align-center ga-2 mt-1">
            <v-chip v-if="item.time_logs?.length" size="x-small" variant="outlined"><v-icon start size="12">mdi-clock-outline</v-icon>{{ item.time_logs.length }}</v-chip>
            <v-chip v-if="item.parts_used?.length" size="x-small" variant="outlined"><v-icon start size="12">mdi-package-variant-closed</v-icon>{{ item.parts_used.length }}</v-chip>
            <v-chip v-if="item.notes?.length" size="x-small" variant="outlined"><v-icon start size="12">mdi-comment-outline</v-icon>{{ item.notes.length }}</v-chip>
          </div>
        </div>
        <div v-if="!col.items.length" class="kanban-empty">
          <v-icon size="28" color="grey-lighten-2">mdi-tray-minus</v-icon>
          <p class="text-caption text-medium-emphasis mt-1">No work orders</p>
        </div>
      </div>
      <div class="kanban-drop-zone" @dragover.prevent @drop="onDrop($event, col.key)">
        <v-icon size="16" color="grey-lighten-1">mdi-plus-circle-outline</v-icon>
        <span class="text-caption text-medium-emphasis ml-1">Drop here</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ workOrders: any[]; currencySymbol: string }>()
const emit = defineEmits<{ openDetail: [w: any]; moveWO: [id: number, status: string] }>()

const columns = computed(() => {
  const cols = [
    { key: 'open', label: 'Open', color: '#3b82f6', icon: 'mdi-clipboard-outline' },
    { key: 'assigned', label: 'Assigned', color: '#6366f1', icon: 'mdi-account-check-outline' },
    { key: 'in_progress', label: 'In Progress', color: '#f97316', icon: 'mdi-wrench' },
    { key: 'parts_ordered', label: 'Parts Ordered', color: '#f59e0b', icon: 'mdi-package-variant-closed' },
    { key: 'completed', label: 'Completed', color: '#10b981', icon: 'mdi-check-circle' },
    { key: 'closed', label: 'Closed', color: '#94a3b8', icon: 'mdi-lock-check-outline' },
  ]
  return cols.map(c => ({ ...c, items: props.workOrders.filter(w => w.status === c.key), count: props.workOrders.filter(w => w.status === c.key).length }))
})

function money(v: any) { return parseFloat(v || 0).toFixed(2) }

function onDragStart(e: DragEvent, item: any) {
  e.dataTransfer?.setData('wo-id', String(item.id))
}

function onDrop(e: DragEvent, status: string) {
  e.preventDefault()
  const id = parseInt(e.dataTransfer?.getData('wo-id') || '0')
  if (id) emit('moveWO', id, status)
}
</script>

<style scoped>
.kanban-board { display: flex; gap: 12px; overflow-x: auto; padding-bottom: 8px; min-height: 400px; }
.kanban-col { min-width: 280px; max-width: 320px; display: flex; flex-direction: column; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; }
.kanban-col-head { display: flex; align-items: center; justify-content: space-between; padding: 10px 12px; border-top: 3px solid #ccc; border-top-left-radius: 12px; border-top-right-radius: 12px; background: #fff; }
.kanban-col-body { padding: 8px; display: flex; flex-direction: column; gap: 8px; flex: 1; overflow-y: auto; max-height: 500px; }
.kanban-card { background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 10px 12px; cursor: pointer; transition: box-shadow .15s, transform .15s; }
.kanban-card:hover { box-shadow: 0 4px 12px rgba(2,6,23,.08); transform: translateY(-1px); }
.kanban-title { font-size: 13px; font-weight: 600; color: #0f172a; margin-bottom: 2px; line-height: 1.3; }
.kanban-vehicle { font-size: 11px; }
.kanban-empty { display: flex; flex-direction: column; align-items: center; padding: 20px; opacity: .5; }
.kanban-drop-zone { display: flex; align-items: center; justify-content: center; padding: 8px; border-top: 2px dashed #e2e8f0; border-bottom-left-radius: 12px; border-bottom-right-radius: 12px; margin-top: auto; opacity: .5; transition: opacity .15s, background .15s; }
.kanban-drop-zone:hover { opacity: 1; background: #eef2ff; }
</style>
