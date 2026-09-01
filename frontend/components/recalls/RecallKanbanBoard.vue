<template>
  <v-row dense>
    <!-- Open -->
    <v-col cols="12" md="3">
      <div class="kanban-column">
        <div class="kanban-head" style="background: #fef2f2">
          <v-icon color="error" size="20">mdi-alert-circle-outline</v-icon>
          <span class="font-weight-bold">Open</span>
          <v-chip variant="flat" color="error" size="x-small">{{ openItems.length }}</v-chip>
        </div>
        <div class="kanban-body">
          <div v-if="!openItems.length" class="empty-state"><v-icon size="32" class="mb-2">mdi-shield-off-outline</v-icon><p>No open recalls</p></div>
          <div v-for="r in openItems" :key="r.id" class="kanban-card" @click="$emit('openDetail', r)">
            <div class="d-flex align-center ga-2 mb-1">
              <v-chip :color="typeColor(r.recall_type)" variant="tonal" size="x-small" class="text-capitalize">
                <v-icon start size="12">{{ typeIcon(r.recall_type) }}</v-icon>{{ typeLabel(r.recall_type) }}
              </v-chip>
              <v-chip v-if="r.is_critical" color="error" variant="flat" size="x-small"><v-icon start size="12">mdi-alert</v-icon>Critical</v-chip>
            </div>
            <p class="text-body-2 font-weight-medium mb-1">{{ r.title }}</p>
            <p class="text-caption text-medium-emphasis mb-1">
              <v-icon size="12">mdi-factory</v-icon> {{ r.oem }} · <v-icon size="12">mdi-wrench</v-icon> {{ r.component }}
            </p>
            <div class="d-flex align-center ga-1 mt-1">
              <v-chip size="x-small" variant="outlined">{{ r.affected_count || 0 }} affected</v-chip>
              <v-chip size="x-small" variant="outlined" color="success">{{ r.resolved_count || 0 }} resolved</v-chip>
            </div>
          </div>
        </div>
      </div>
    </v-col>

    <!-- In Progress -->
    <v-col cols="12" md="3">
      <div class="kanban-column">
        <div class="kanban-head" style="background: #fffbeb">
          <v-icon color="warning" size="20">mdi-progress-wrench</v-icon>
          <span class="font-weight-bold">In Progress</span>
          <v-chip variant="flat" color="warning" size="x-small">{{ inProgressItems.length }}</v-chip>
        </div>
        <div class="kanban-body">
          <div v-if="!inProgressItems.length" class="empty-state"><v-icon size="32" class="mb-2">mdi-wrench-outline</v-icon><p>None in progress</p></div>
          <div v-for="r in inProgressItems" :key="r.id" class="kanban-card" @click="$emit('openDetail', r)">
            <div class="d-flex align-center ga-2 mb-1">
              <v-chip :color="typeColor(r.recall_type)" variant="tonal" size="x-small" class="text-capitalize">
                <v-icon start size="12">{{ typeIcon(r.recall_type) }}</v-icon>{{ typeLabel(r.recall_type) }}
              </v-chip>
              <v-chip v-if="r.is_critical" color="error" variant="flat" size="x-small"><v-icon start size="12">mdi-alert</v-icon>Critical</v-chip>
            </div>
            <p class="text-body-2 font-weight-medium mb-1">{{ r.title }}</p>
            <p class="text-caption text-medium-emphasis mb-1">
              <v-icon size="12">mdi-factory</v-icon> {{ r.oem }} · <v-icon size="12">mdi-wrench</v-icon> {{ r.component }}
            </p>
            <div class="d-flex align-center ga-1 mt-1">
              <v-chip size="x-small" variant="outlined">{{ r.affected_count || 0 }} affected</v-chip>
              <v-chip size="x-small" variant="outlined" color="success">{{ r.resolved_count || 0 }} resolved</v-chip>
            </div>
          </div>
        </div>
      </div>
    </v-col>

    <!-- Completed -->
    <v-col cols="12" md="3">
      <div class="kanban-column">
        <div class="kanban-head" style="background: #f0fdf4">
          <v-icon color="success" size="20">mdi-check-circle-outline</v-icon>
          <span class="font-weight-bold">Completed</span>
          <v-chip variant="flat" color="success" size="x-small">{{ completedItems.length }}</v-chip>
        </div>
        <div class="kanban-body">
          <div v-if="!completedItems.length" class="empty-state"><v-icon size="32" class="mb-2">mdi-check-circle-outline</v-icon><p>No completed</p></div>
          <div v-for="r in completedItems" :key="r.id" class="kanban-card" @click="$emit('openDetail', r)">
            <div class="d-flex align-center ga-2 mb-1">
              <v-chip :color="typeColor(r.recall_type)" variant="tonal" size="x-small" class="text-capitalize">
                <v-icon start size="12">{{ typeIcon(r.recall_type) }}</v-icon>{{ typeLabel(r.recall_type) }}
              </v-chip>
            </div>
            <p class="text-body-2 font-weight-medium mb-1">{{ r.title }}</p>
            <p class="text-caption text-medium-emphasis mb-1">
              <v-icon size="12">mdi-factory</v-icon> {{ r.oem }} · <v-icon size="12">mdi-wrench</v-icon> {{ r.component }}
            </p>
            <div class="d-flex align-center ga-1 mt-1">
              <v-chip size="x-small" variant="outlined">{{ r.affected_count || 0 }} affected</v-chip>
              <v-chip size="x-small" variant="outlined" color="success">{{ r.resolved_count || 0 }} resolved</v-chip>
            </div>
          </div>
        </div>
      </div>
    </v-col>

    <!-- Closed -->
    <v-col cols="12" md="3">
      <div class="kanban-column">
        <div class="kanban-head" style="background: #f8fafc">
          <v-icon color="grey" size="20">mdi-close-circle-outline</v-icon>
          <span class="font-weight-bold">Closed</span>
          <v-chip variant="flat" color="grey" size="x-small">{{ closedItems.length }}</v-chip>
        </div>
        <div class="kanban-body">
          <div v-if="!closedItems.length" class="empty-state"><v-icon size="32" class="mb-2">mdi-close-circle-outline</v-icon><p>No closed recalls</p></div>
          <div v-for="r in closedItems" :key="r.id" class="kanban-card" @click="$emit('openDetail', r)">
            <div class="d-flex align-center ga-2 mb-1">
              <v-chip :color="typeColor(r.recall_type)" variant="tonal" size="x-small" class="text-capitalize">
                <v-icon start size="12">{{ typeIcon(r.recall_type) }}</v-icon>{{ typeLabel(r.recall_type) }}
              </v-chip>
            </div>
            <p class="text-body-2 font-weight-medium mb-1">{{ r.title }}</p>
            <p class="text-caption text-medium-emphasis mb-1">
              <v-icon size="12">mdi-factory</v-icon> {{ r.oem }}
            </p>
          </div>
        </div>
      </div>
    </v-col>
  </v-row>
</template>

<script setup lang="ts">
const props = defineProps<{ recalls: any[] }>()
defineEmits<{ openDetail: [r: any] }>()

const openItems = computed(() => props.recalls.filter(r => r.status === 'open'))
const inProgressItems = computed(() => props.recalls.filter(r => r.status === 'in_progress'))
const completedItems = computed(() => props.recalls.filter(r => r.status === 'completed'))
const closedItems = computed(() => props.recalls.filter(r => r.status === 'closed'))

function typeColor(t: string) { return ({ safety_recall: 'error', campaign: 'warning', field_notice: 'info', emission: 'success' } as any)[t] || 'grey' }
function typeIcon(t: string) { return ({ safety_recall: 'mdi-shield-alert', campaign: 'mdi-bullhorn', field_notice: 'mdi-file-alert', emission: 'mdi-leaf' } as any)[t] || 'mdi-car-info' }
function typeLabel(t: string) { return ({ safety_recall: 'Safety', campaign: 'Campaign', field_notice: 'Field Notice', emission: 'Emission' } as any)[t] || t }
</script>

<style scoped>
.kanban-column { border-radius: 12px; border: 1px solid #e2e8f0; background: #fafafa; min-height: 300px; display: flex; flex-direction: column; }
.kanban-head { display: flex; align-items: center; gap: 8px; padding: 10px 12px; border-radius: 12px 12px 0 0; font-size: 14px; }
.kanban-body { padding: 8px; flex: 1; overflow-y: auto; display: flex; flex-direction: column; gap: 8px; }
.kanban-card { background: white; border: 1px solid #e2e8f0; border-radius: 10px; padding: 10px 12px; cursor: pointer; transition: all .15s; }
.kanban-card:hover { border-color: #c7d2fe; box-shadow: 0 2px 8px rgba(99,102,241,.08); }
.empty-state { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 40px 0; color: #94a3b8; font-size: 13px; }
</style>
