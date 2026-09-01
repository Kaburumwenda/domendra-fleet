<template>
  <div class="kanban-board">
    <div v-for="col in columns" :key="col.key" class="kanban-col">
      <div class="kanban-col-head" :style="{ borderTopColor: col.color }">
        <div class="d-flex align-center ga-2">
          <v-icon size="18" :color="col.color">{{ col.icon }}</v-icon>
          <span class="font-weight-bold text-body-2">{{ col.label }}</span>
          <v-chip size="x-small" variant="tonal" :color="col.color">{{ col.count }}</v-chip>
        </div>
        <v-menu>
          <template #activator="{ props: p }">
            <v-btn icon="mdi-dots-vertical" variant="text" size="x-small" v-bind="p" />
          </template>
          <v-list density="compact">
            <v-list-item prepend-icon="mdi-arrow-right-bold" @click="moveAll?.(col.key)">Move all here</v-list-item>
          </v-list>
        </v-menu>
      </div>
      <div class="kanban-col-body">
        <div v-for="item in col.items" :key="item.id" class="kanban-card" :class="{ critical: item.priority === 'critical' }" draggable="true" @dragstart="onDragStart($event, item)" @click="$emit('openDetail', item)">
          <div class="d-flex align-start ga-2 mb-1">
            <v-chip :color="priorityColor(item.priority)" variant="flat" size="x-small" class="font-weight-bold text-uppercase">{{ item.priority }}</v-chip>
            <v-spacer />
            <span class="text-caption text-medium-emphasis">#{{ item.id }}</span>
          </div>
          <p class="kanban-title">{{ item.title }}</p>
          <p class="kanban-vehicle text-caption text-medium-emphasis">{{ item.vehicle_name }}</p>
          <div class="d-flex align-center ga-2 mt-2">
            <v-icon size="14" color="medium-emphasis">mdi-truck</v-icon>
            <span v-if="item.has_work_order" class="text-caption text-info"><v-icon size="12">mdi-clipboard-list-outline</v-icon> WO #{{ item.work_order_id }}</span>
            <span v-if="item.reported_by_name" class="text-caption text-medium-emphasis ml-auto">{{ item.reported_by_name }}</span>
          </div>
        </div>
        <div v-if="!col.items.length" class="kanban-empty">
          <v-icon size="28" color="grey-lighten-2">mdi-tray-minus</v-icon>
          <p class="text-caption text-medium-emphasis mt-1">No issues</p>
        </div>
      </div>
      <div
        class="kanban-drop-zone"
        @dragover.prevent
        @drop="onDrop($event, col.key)"
      >
        <v-icon size="16" color="grey-lighten-1">mdi-plus-circle-outline</v-icon>
        <span class="text-caption text-medium-emphasis ml-1">Drop here</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ issues: any[] }>()
const emit = defineEmits<{ openDetail: [i: any]; moveIssue: [id: number, status: string] }>()

const columns = computed(() => {
  const cols = [
    { key: 'open', label: 'Open', color: '#3b82f6', icon: 'mdi-alert-circle-outline' },
    { key: 'assigned', label: 'Assigned', color: '#6366f1', icon: 'mdi-account-check-outline' },
    { key: 'in_progress', label: 'In Progress', color: '#f97316', icon: 'mdi-progress-clock' },
    { key: 'parts_ordered', label: 'Parts Ordered', color: '#f59e0b', icon: 'mdi-package-variant-closed' },
    { key: 'resolved', label: 'Resolved', color: '#10b981', icon: 'mdi-check-circle' },
    { key: 'closed', label: 'Closed', color: '#94a3b8', icon: 'mdi-lock-check-outline' },
  ]
  return cols.map(c => ({ ...c, items: props.issues.filter(i => i.status === c.key), count: props.issues.filter(i => i.status === c.key).length }))
})

function priorityColor(p: string) { return ({ low: 'grey', medium: 'yellow-darken-2', high: 'orange', critical: 'error' } as any)[p] || 'grey' }

function onDragStart(e: DragEvent, item: any) {
  e.dataTransfer?.setData('issue-id', String(item.id))
}

function onDrop(e: DragEvent, status: string) {
  e.preventDefault()
  const id = parseInt(e.dataTransfer?.getData('issue-id') || '0')
  if (id) emit('moveIssue', id, status)
}
</script>

<style scoped>
.kanban-board { display: flex; gap: 12px; overflow-x: auto; padding-bottom: 8px; min-height: 400px; }
.kanban-col { min-width: 280px; max-width: 320px; display: flex; flex-direction: column; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; }
.kanban-col-head { display: flex; align-items: center; justify-content: space-between; padding: 10px 12px; border-top: 3px solid #ccc; border-top-left-radius: 12px; border-top-right-radius: 12px; background: #fff; }
.kanban-col-body { padding: 8px; display: flex; flex-direction: column; gap: 8px; flex: 1; overflow-y: auto; max-height: 500px; }
.kanban-card { background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 10px 12px; cursor: pointer; transition: box-shadow .15s, transform .15s; }
.kanban-card:hover { box-shadow: 0 4px 12px rgba(2,6,23,.08); transform: translateY(-1px); }
.kanban-card.critical { border-left: 3px solid #ef4444; }
.kanban-title { font-size: 13px; font-weight: 600; color: #0f172a; margin-bottom: 2px; line-height: 1.3; }
.kanban-vehicle { font-size: 11px; }
.kanban-empty { display: flex; flex-direction: column; align-items: center; padding: 20px; opacity: .5; }
.kanban-drop-zone { display: flex; align-items: center; justify-content: center; padding: 8px; border-top: 2px dashed #e2e8f0; border-bottom-left-radius: 12px; border-bottom-right-radius: 12px; margin-top: auto; opacity: .5; transition: opacity .15s, background .15s; }
.kanban-drop-zone:hover { opacity: 1; background: #eef2ff; }
</style>
