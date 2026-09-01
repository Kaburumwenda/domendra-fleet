<template>
  <v-navigation-drawer :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" location="right" width="540" temporary permanent style="top:0; height:100vh; z-index:1000">
    <div v-if="wo" class="d-flex flex-column h-100">
      <!-- Header -->
      <div class="drawer-head">
        <div class="d-flex align-center ga-2 mb-2">
          <v-chip :color="statusColor(wo.status)" variant="flat" size="small" class="text-capitalize">
            <v-icon start size="14">{{ statusIcon(wo.status) }}</v-icon>{{ wo.status ? wo.status.replace('_', ' ') : '' }}
          </v-chip>
          <v-chip :color="wo.assignment_type === 'internal' ? 'primary' : 'deep-purple'" variant="tonal" size="small" class="text-capitalize">
            <v-icon start size="14">{{ wo.assignment_type === 'internal' ? 'mdi-account-wrench' : 'mdi-store' }}</v-icon>{{ wo.assignment_type === 'internal' ? 'Internal' : 'External' }}
          </v-chip>
        </div>
        <div class="d-flex align-center">
          <h2 class="text-h6 font-weight-bold flex-grow-1">WO #{{ wo.id }}</h2>
          <v-btn icon variant="text" size="small" @click="$emit('update:modelValue', false)"><v-icon>mdi-close</v-icon></v-btn>
        </div>
        <p class="text-caption text-medium-emphasis">{{ wo.issue_title || '—' }} · {{ wo.vehicle_name || '—' }}</p>
      </div>
      <v-divider />

      <div class="drawer-body">
        <!-- Cost Summary -->
        <div class="cost-grid">
          <div class="cost-item">
            <p class="text-caption text-medium-emphasis">Estimated</p>
            <p class="text-subtitle-1 font-weight-bold text-primary">{{ currencySymbol }}{{ money(wo.estimated_cost) }}</p>
          </div>
          <div class="cost-item">
            <p class="text-caption text-medium-emphasis">Actual</p>
            <p class="text-subtitle-1 font-weight-bold text-warning">{{ currencySymbol }}{{ money(wo.actual_cost) }}</p>
          </div>
          <div class="cost-item">
            <p class="text-caption text-medium-emphasis">Total</p>
            <p class="text-subtitle-1 font-weight-bold text-success">{{ currencySymbol }}{{ money(wo.total_cost) }}</p>
          </div>
        </div>

        <!-- Assignment Info -->
        <div class="info-list mt-3">
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-account-hard-hat</v-icon>
            <div>
              <p class="text-caption text-medium-emphasis">Assigned To</p>
              <p class="text-body-2 font-weight-medium">{{ wo.assigned_to_name || 'Unassigned' }}</p>
            </div>
          </div>
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-clock-outline</v-icon>
            <div>
              <p class="text-caption text-medium-emphasis">Started At</p>
              <p class="text-body-2 font-weight-medium">{{ fmt(wo.started_at) }}</p>
            </div>
          </div>
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-check-circle-outline</v-icon>
            <div>
              <p class="text-caption text-medium-emphasis">Completed At</p>
              <p class="text-body-2 font-weight-medium">{{ fmt(wo.completed_at) }}</p>
            </div>
          </div>
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-timer-sand</v-icon>
            <div>
              <p class="text-caption text-medium-emphasis">Downtime</p>
              <p class="text-body-2 font-weight-medium">{{ wo.downtime_hours || 0 }}h</p>
            </div>
          </div>
        </div>

        <!-- Time Logs -->
        <div v-if="wo.time_logs?.length" class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-clock-outline</v-icon>Time Logs ({{ wo.time_logs.length }})</p>
          <div v-for="tl in wo.time_logs" :key="tl.id" class="log-item">
            <div class="d-flex align-center ga-2">
              <v-avatar size="24" variant="tonal" color="primary">{{ initials(tl.mechanic_name || '?') }}</v-avatar>
              <span class="text-body-2 font-weight-medium">{{ tl.mechanic_name || 'Unknown' }}</span>
              <v-chip size="x-small" variant="tonal" color="info">{{ tl.hours ? tl.hours.toFixed(2) + 'h' : 'active' }}</v-chip>
              <span class="text-caption text-medium-emphasis ml-auto">{{ fmt(tl.clock_in) }}</span>
            </div>
          </div>
        </div>

        <!-- Parts Used -->
        <div v-if="wo.parts_used?.length" class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-package-variant-closed</v-icon>Parts Used ({{ wo.parts_used.length }})</p>
          <div v-for="p in wo.parts_used" :key="p.id" class="part-item">
            <div class="d-flex align-center justify-space-between">
              <div>
                <p class="text-body-2 font-weight-medium">{{ p.item_name || '—' }}</p>
                <p class="text-caption text-medium-emphasis">SKU: {{ p.item_sku || '—' }} · Qty: {{ p.quantity }}</p>
              </div>
              <span class="text-body-2 font-weight-bold">{{ currencySymbol }}{{ money(p.total_cost) }}</span>
            </div>
          </div>
        </div>

        <!-- Notes -->
        <div v-if="wo.notes?.length" class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-comment-text-multiple-outline</v-icon>Notes ({{ wo.notes.length }})</p>
          <div v-for="n in wo.notes" :key="n.id" class="note-item">
            <div class="d-flex align-center ga-1 mb-1">
              <v-avatar size="20" variant="tonal" :color="n.visibility === 'internal' ? 'grey' : 'info'"><span class="text-caption font-weight-bold">{{ initials(n.author_name || '?') }}</span></v-avatar>
              <span class="text-caption font-weight-medium">{{ n.author_name || 'System' }}</span>
              <v-chip v-if="n.visibility === 'internal'" size="x-small" variant="tonal" color="grey">Internal</v-chip>
              <v-chip v-else size="x-small" variant="tonal" color="info">External</v-chip>
              <span class="text-caption text-medium-emphasis ml-auto">{{ fmt(n.created_at) }}</span>
            </div>
            <p class="text-body-2">{{ n.content }}</p>
          </div>
        </div>
      </div>

      <!-- Actions -->
      <div class="drawer-actions">
        <v-btn variant="text" prepend-icon="mdi-arrow-expand-all" :to="`/app/work-orders/${wo.id}`">View Full Page</v-btn>
        <v-btn variant="text" prepend-icon="mdi-pencil-outline" @click="$emit('edit', wo)">Edit</v-btn>
        <v-spacer />
        <v-btn v-if="wo.status === 'assigned'" variant="tonal" color="warning" prepend-icon="mdi-play" @click="$emit('startWork', wo)">Start Work</v-btn>
        <v-btn v-if="!['completed', 'closed'].includes(wo.status)" variant="tonal" color="success" prepend-icon="mdi-check-circle" @click="$emit('complete', wo)">Complete</v-btn>
      </div>
    </div>
    <div v-else class="d-flex align-center justify-center h-100">
      <v-icon size="48" color="grey-lighten-2">mdi-clipboard-list-outline</v-icon>
    </div>
  </v-navigation-drawer>
</template>

<script setup lang="ts">
defineProps<{ modelValue: boolean; wo: any; currencySymbol: string }>()
defineEmits<{ 'update:modelValue': [v: boolean]; edit: [w: any]; startWork: [w: any]; complete: [w: any] }>()

function money(v: any) { return parseFloat(v || 0).toFixed(2) }
function fmt(v?: string) { return v ? new Date(v).toLocaleString([], { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : '—' }
function statusColor(s: string) { return ({ open: 'blue', assigned: 'indigo', parts_ordered: 'amber', in_progress: 'orange', on_hold: 'purple', completed: 'success', closed: 'grey' } as any)[s] || 'grey' }
function statusIcon(s: string) { return ({ open: 'mdi-clipboard-outline', assigned: 'mdi-account-check-outline', parts_ordered: 'mdi-package-variant-closed', in_progress: 'mdi-wrench', on_hold: 'mdi-pause-circle', completed: 'mdi-check-circle', closed: 'mdi-lock-check-outline' } as any)[s] || 'mdi-clipboard' }
function initials(n: string) { return (n || '?').split(' ').map((w: string) => w[0]).slice(0, 2).join('').toUpperCase() }
</script>

<style scoped>
.drawer-head { padding: 16px 20px 12px; }
.drawer-body { padding: 12px 20px; overflow-y: auto; flex: 1 1 0; }
.drawer-actions { padding: 12px 16px; border-top: 1px solid #e2e8f0; display: flex; gap: 4px; flex-wrap: wrap; }
.info-list { display: flex; flex-direction: column; gap: 10px; }
.info-row { display: flex; align-items: flex-start; gap: 10px; }
.cost-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; }
.cost-item { background: #f8fafc; border-radius: 10px; padding: 10px 12px; text-align: center; }
.section-block { margin-top: 16px; }
.log-item, .part-item, .note-item { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 10px; margin-bottom: 6px; }
</style>
