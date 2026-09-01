<template>
  <div class="d-flex flex-column ga-4">
    <!-- Page header -->
    <div class="page-header">
      <div>
        <h1 class="text-h5 font-weight-bold d-flex align-center ga-2">
          <v-icon color="primary">mdi-car-info</v-icon>
          Recalls
        </h1>
        <p class="text-caption text-medium-emphasis">Track vehicle safety recalls, service campaigns, and field notices. Match affected vehicles and monitor resolution progress.</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn variant="outlined" prepend-icon="mdi-refresh" @click="reloadAll" :loading="pending">Refresh</v-btn>
        <v-btn variant="tonal" color="deep-purple" prepend-icon="mdi-database-plus" @click="seedDemo" :loading="seeding">
          <span class="hidden-sm-and-down">Seed Demo Data</span>
        </v-btn>
        <v-btn v-can="'recalls:create'" color="primary" prepend-icon="mdi-plus" @click="openCreate">
          <span class="hidden-sm-and-down">New Recall</span>
        </v-btn>
      </div>
    </div>

    <!-- Analytics -->
    <RecallsAnalytics
      :stats="recallStats"
      :active-status-filter="statusFilter"
      @filter-status="setStatusFilter"
    />

    <!-- Filters bar -->
    <div class="d-flex flex-wrap align-center ga-2 filter-bar">
      <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Search recalls…" density="compact" hide-details variant="outlined" style="max-width:280px" clearable />
      <v-select v-model="typeFilter" :items="typeOptions" item-title="label" item-value="value" placeholder="All Types" density="compact" hide-details variant="outlined" clearable style="max-width:170px" />
      <v-select v-model="statusFilter" :items="statusOptions" item-title="label" item-value="value" placeholder="All Status" density="compact" hide-details variant="outlined" clearable style="max-width:160px" />
      <v-select v-model="oemFilter" :items="oemOptions" placeholder="All OEMs" density="compact" hide-details variant="outlined" clearable style="max-width:160px" />
      <v-checkbox v-model="criticalOnly" label="Critical only" density="compact" hide-details color="error" />
      <v-btn v-if="hasFilters" variant="text" size="small" prepend-icon="mdi-filter-remove" @click="clearFilters">Clear</v-btn>
      <v-spacer />
      <div class="text-caption text-medium-emphasis">{{ filteredRecalls.length }} of {{ recalls.length }} recalls</div>
    </div>

    <!-- Tabs -->
    <v-tabs v-model="tab" color="primary" density="compact" class="rem-tabs">
      <v-tab value="board" prepend-icon="mdi-view-column-outline">Board</v-tab>
      <v-tab value="records" prepend-icon="mdi-format-list-bulleted">Records</v-tab>
      <v-tab value="timeline" prepend-icon="mdi-timeline-text-outline">Timeline</v-tab>
    </v-tabs>

    <v-window v-model="tab" class="flex-grow-1">
      <!-- KANBAN BOARD -->
      <v-window-item value="board">
        <RecallKanbanBoard :recalls="filteredRecalls" @open-detail="openDetail" />
      </v-window-item>

      <!-- RECORDS (data table) -->
      <v-window-item value="records">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="headers" :items="filteredRecalls" :loading="pending" hover density="compact" :search="search">
            <template #item.title="{ item }">
              <div class="cursor-pointer" @click="openDetail(item)">
                <p class="font-weight-medium">{{ item.title }}</p>
                <p class="text-caption text-medium-emphasis">{{ item.nhtsa_campaign_number || item.manufacturer_campaign_number || '—' }}</p>
              </div>
            </template>
            <template #item.recall_type="{ value }">
              <v-chip :color="typeColor(value)" variant="tonal" size="small" class="text-capitalize">
                <v-icon start size="14">{{ typeIcon(value) }}</v-icon>{{ typeLabel(value) }}
              </v-chip>
            </template>
            <template #item.status="{ value }">
              <v-chip :color="statusColor(value)" variant="flat" size="small" class="text-capitalize">
                <v-icon start size="14">{{ statusIcon(value) }}</v-icon>{{ value.replace('_', ' ') }}
              </v-chip>
            </template>
            <template #item.is_critical="{ value }">
              <v-icon v-if="value" color="error" size="small">mdi-alert-circle</v-icon>
              <span v-else class="text-medium-emphasis">—</span>
            </template>
            <template #item.affected_count="{ value }">{{ value || 0 }}</template>
            <template #item.resolved_count="{ item }">
              <span :class="item.resolved_count === item.affected_count && item.affected_count > 0 ? 'text-success font-weight-bold' : ''">{{ item.resolved_count || 0 }}/{{ item.affected_count || 0 }}</span>
            </template>
            <template #item.issue_date="{ value }">{{ fmtDate(value) }}</template>
            <template #item.actions="{ item }">
              <v-menu>
                <template #activator="{ props: p }">
                  <v-btn icon="mdi-dots-vertical" variant="text" size="small" v-bind="p" />
                </template>
                <v-list density="compact">
                  <v-list-item prepend-icon="mdi-eye-outline" @click="openDetail(item)">View Details</v-list-item>
                  <v-list-item v-can="'recalls:update'" prepend-icon="mdi-magnify" @click="autoMatch(item)">Auto-Match Vehicles</v-list-item>
                  <v-list-item v-can="'recalls:update'" prepend-icon="mdi-link-plus" @click="openApply(item)">Apply to Vehicles</v-list-item>
                  <v-list-item v-can="'recalls:update'" prepend-icon="mdi-pencil" @click="openEdit(item)">Edit</v-list-item>
                  <v-list-item v-can="'recalls:delete'" prepend-icon="mdi-trash-can-outline" base-color="error" @click="deleteRecall(item)">Delete</v-list-item>
                </v-list>
              </v-menu>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-car-info</v-icon>
                <p>No recalls yet. Click <b>Seed Demo Data</b> or <b>New Recall</b> to get started.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>

      <!-- TIMELINE -->
      <v-window-item value="timeline">
        <v-card elevation="0" border rounded="lg">
          <v-card-text>
            <div v-if="!filteredRecalls.length" class="text-center py-12 text-medium-emphasis">
              <v-icon size="48" class="mb-3">mdi-timeline-text-outline</v-icon>
              <p>No recalls to show.</p>
            </div>
            <v-timeline v-else side="end" density="compact">
              <v-timeline-item v-for="r in timelineRecalls" :key="r.id" :dot-color="statusColor(r.status)" size="small" fill-dot>
                <template #opposite>
                  <span class="text-caption text-medium-emphasis">{{ fmtDate(r.issue_date) }}</span>
                </template>
                <v-card elevation="0" border class="pa-3 cursor-pointer" @click="openDetail(r)">
                  <div class="d-flex align-start justify-space-between">
                    <div class="flex-grow-1">
                      <div class="d-flex align-center ga-2 mb-1">
                        <p class="font-weight-medium">{{ r.title }}</p>
                        <v-chip v-if="r.is_critical" color="error" variant="flat" size="x-small">Critical</v-chip>
                      </div>
                      <p class="text-caption text-medium-emphasis">{{ r.oem }} · {{ r.component }} · {{ r.nhtsa_campaign_number || '—' }}</p>
                      <div class="d-flex align-center ga-2 mt-1 flex-wrap">
                        <v-chip :color="typeColor(r.recall_type)" variant="outlined" size="x-small" class="text-capitalize">{{ typeLabel(r.recall_type) }}</v-chip>
                        <v-chip :color="statusColor(r.status)" variant="outlined" size="x-small" class="text-capitalize">{{ r.status.replace('_', ' ') }}</v-chip>
                        <span class="text-caption text-medium-emphasis">{{ r.resolved_count || 0 }}/{{ r.affected_count || 0 }} vehicles resolved</span>
                      </div>
                    </div>
                  </div>
                </v-card>
              </v-timeline-item>
            </v-timeline>
          </v-card-text>
        </v-card>
      </v-window-item>
    </v-window>

    <!-- Create/edit dialog -->
    <RecallFormDialog
      ref="formRef"
      v-model="formDialog"
      :editing="editing"
      :saving="saving"
      @save="saveRecall"
    />

    <!-- Apply to vehicles dialog -->
    <ApplyVehiclesDialog
      v-model="applyDialog"
      :recall="activeRecall"
      :vehicle-options="vehicleOptions"
      :saving="saving"
      @apply="applyToVehicles"
    />

    <!-- Detail drawer -->
    <RecallDetailDrawer
      v-model="drawerOpen"
      :recall="selectedRecall"
      @edit="openEdit"
      @delete="deleteRecall"
      @auto-match="autoMatch"
      @apply-vehicles="openApply"
    />
  </div>
</template>

<script setup lang="ts">
import RecallsAnalytics from '~/components/recalls/RecallsAnalytics.vue'
import RecallFormDialog from '~/components/recalls/RecallFormDialog.vue'
import RecallKanbanBoard from '~/components/recalls/RecallKanbanBoard.vue'
import RecallDetailDrawer from '~/components/recalls/RecallDetailDrawer.vue'
import ApplyVehiclesDialog from '~/components/recalls/ApplyVehiclesDialog.vue'

definePageMeta({ layout: 'default' })
const { $api, $swal } = useNuxtApp() as any

/* ─── state ─── */
const tab = ref<'board' | 'records' | 'timeline'>('board')
const search = ref('')
const typeFilter = ref<string | null>(null)
const statusFilter = ref<string | null>(null)
const oemFilter = ref<string | null>(null)
const criticalOnly = ref(false)
const formRef = ref<any>(null)
const formDialog = ref(false)
const editing = ref(false)
const saving = ref(false)
const seeding = ref(false)
const drawerOpen = ref(false)
const applyDialog = ref(false)
const selectedRecall = ref<any>(null)
const activeRecall = ref<any>(null)

const typeOptions = [
  { label: 'Safety Recall', value: 'safety_recall' },
  { label: 'Service Campaign', value: 'campaign' },
  { label: 'Field Notice', value: 'field_notice' },
  { label: 'Emission', value: 'emission' },
]
const statusOptions = [
  { label: 'Open', value: 'open' },
  { label: 'In Progress', value: 'in_progress' },
  { label: 'Completed', value: 'completed' },
  { label: 'Closed', value: 'closed' },
]

const headers = [
  { title: 'Title', key: 'title', sortable: true },
  { title: 'Type', key: 'recall_type', width: '130px', sortable: true },
  { title: 'OEM', key: 'oem', width: '110px', sortable: true },
  { title: 'Component', key: 'component', width: '130px' },
  { title: 'Critical', key: 'is_critical', width: '70px', sortable: true },
  { title: 'Affected', key: 'affected_count', width: '80px' },
  { title: 'Resolved', key: 'resolved_count', width: '90px' },
  { title: 'Status', key: 'status', width: '120px', sortable: true },
  { title: 'Issue Date', key: 'issue_date', width: '110px', sortable: true },
  { title: '', key: 'actions', width: '50px', sortable: false },
]

/* ─── data ─── */
const { data: recallData, pending, refresh } = useAsyncData('recalls-page', () =>
  $api('/recalls/', { query: { page_size: 1000 } }), { default: () => ({ results: [], count: 0 }) })
const recalls = computed<any[]>(() => recallData.value?.results || recallData.value || [])

const { data: statsData, refresh: refreshStats } = useAsyncData('recalls-stats', () =>
  $api('/recalls/stats/').catch(() => ({})), { default: () => ({}) })
const recallStats = computed(() => statsData.value || {})

const { data: vehicleData } = useAsyncData('recalls-vehicles', () =>
  $api('/vehicles/vehicles/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const vehicleOptions = computed<any[]>(() => vehicleData.value?.results || [])

/* ─── filters ─── */
const oemOptions = computed(() => {
  const set = new Set<string>()
  recalls.value.forEach(r => { if (r.oem) set.add(r.oem) })
  return [...set]
})
const filteredRecalls = computed(() => {
  let arr = recalls.value
  if (typeFilter.value) arr = arr.filter(r => r.recall_type === typeFilter.value)
  if (statusFilter.value) arr = arr.filter(r => r.status === statusFilter.value)
  if (oemFilter.value) arr = arr.filter(r => r.oem === oemFilter.value)
  if (criticalOnly.value) arr = arr.filter(r => r.is_critical)
  if (search.value) {
    const q = search.value.toLowerCase()
    arr = arr.filter(r => (r.title || '').toLowerCase().includes(q) || (r.nhtsa_campaign_number || '').toLowerCase().includes(q) || (r.component || '').toLowerCase().includes(q) || (r.oem || '').toLowerCase().includes(q))
  }
  return arr
})
const hasFilters = computed(() => !!(search.value || typeFilter.value || statusFilter.value || oemFilter.value || criticalOnly.value))
const timelineRecalls = computed(() => [...filteredRecalls.value].sort((a, b) => new Date(b.issue_date || b.created_at).valueOf() - new Date(a.issue_date || a.created_at).valueOf()))
function clearFilters() { search.value = ''; typeFilter.value = null; statusFilter.value = null; oemFilter.value = null; criticalOnly.value = false }
function setStatusFilter(v: string) { statusFilter.value = statusFilter.value === v ? null : v; tab.value = 'records' }

/* ─── helpers ─── */
function typeColor(t: string) { return ({ safety_recall: 'error', campaign: 'warning', field_notice: 'info', emission: 'success' } as any)[t] || 'grey' }
function typeIcon(t: string) { return ({ safety_recall: 'mdi-shield-alert', campaign: 'mdi-bullhorn', field_notice: 'mdi-file-alert', emission: 'mdi-leaf' } as any)[t] || 'mdi-car-info' }
function typeLabel(t: string) { return ({ safety_recall: 'Safety', campaign: 'Campaign', field_notice: 'Field Notice', emission: 'Emission' } as any)[t] || t }
function statusColor(s: string) { return ({ open: 'error', in_progress: 'warning', completed: 'success', closed: 'grey' } as any)[s] || 'grey' }
function statusIcon(s: string) { return ({ open: 'mdi-alert-circle', in_progress: 'mdi-progress-wrench', completed: 'mdi-check-circle', closed: 'mdi-close-circle' } as any)[s] || 'mdi-circle-outline' }
function fmtDate(v?: string) { return v ? new Date(v).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' }) : '—' }

/* ─── reload all ─── */
async function reloadAll() { await Promise.all([refresh(), refreshStats()]) }

/* ─── seed demo ─── */
async function seedDemo() {
  const r = await $swal?.fire?.({ icon: 'question', title: 'Seed recall demo data?', text: 'This will create sample recalls with affected vehicles from your fleet.', showCancelButton: true, confirmButtonText: 'Seed Data' })
  if (!r?.isConfirmed) return
  seeding.value = true
  try {
    const res = await $api('/recalls/seed-demo/', { method: 'POST' })
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: res?.detail || 'Demo data seeded', toast: true, timer: 2000, position: 'top-end' })
  } catch (e: any) { console.error(e); $swal?.fire?.({ icon: 'error', title: e?.response?._data?.detail || 'Failed to seed data', toast: true, timer: 3000, position: 'top-end' }) } finally { seeding.value = false }
}

/* ─── CRUD ─── */
function openCreate() { editing.value = false; formRef.value?.reset(); formDialog.value = true }
function openEdit(r: any) { editing.value = true; formRef.value?.reset(r); formDialog.value = true; drawerOpen.value = false }
function openDetail(r: any) { selectedRecall.value = r; drawerOpen.value = true }
async function saveRecall(payload: any) {
  saving.value = true
  try {
    const { _id, ...body } = payload
    if (editing.value && payload._id) await $api(`/recalls/${payload._id}/`, { method: 'PATCH', body })
    else await $api('/recalls/', { method: 'POST', body })
    formDialog.value = false
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: editing.value ? 'Recall updated' : 'Recall created', toast: true, timer: 1500, position: 'top-end' })
  } catch (e: any) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Save failed', toast: true, timer: 2000, position: 'top-end' }) } finally { saving.value = false }
}
async function deleteRecall(r: any) {
  const res = await $swal?.fire?.({ icon: 'warning', title: 'Delete recall?', text: `"${r.title}" will be permanently removed.`, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!res?.isConfirmed) return
  try { await $api(`/recalls/${r.id}/`, { method: 'DELETE' }); drawerOpen.value = false; await reloadAll(); $swal?.fire?.({ icon: 'success', title: 'Recall deleted', toast: true, timer: 1500, position: 'top-end' }) }
  catch (e: any) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Delete failed', toast: true, timer: 2000, position: 'top-end' }) }
}
async function autoMatch(r: any) {
  try { const res = await $api(`/recalls/${r.id}/auto-match/`, { method: 'POST' }); await reloadAll(); $swal?.fire?.({ icon: 'success', title: `Auto-matched ${res?.length || 0} vehicles`, toast: true, timer: 2000, position: 'top-end' }) }
  catch (e: any) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Auto-match failed', toast: true, timer: 2000, position: 'top-end' }) }
}
function openApply(r: any) { activeRecall.value = r; applyDialog.value = true }
async function applyToVehicles({ recall, vehicle_ids }: { recall: any; vehicle_ids: number[] }) {
  saving.value = true
  try { await $api(`/recalls/${recall.id}/apply-to-vehicles/`, { method: 'POST', body: { vehicle_ids } }); applyDialog.value = false; await reloadAll(); $swal?.fire?.({ icon: 'success', title: `Applied to ${vehicle_ids.length} vehicles`, toast: true, timer: 1500, position: 'top-end' }) }
  catch (e: any) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Apply failed', toast: true, timer: 2000, position: 'top-end' }) } finally { saving.value = false }
}
</script>

<style scoped>
.page-header { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
.filter-bar { flex-wrap: wrap; background: #f8fafc; padding: 8px 12px; border-radius: 12px; }
.rem-tabs :deep(.v-tab) { text-transform: none; font-weight: 600; }
.cursor-pointer { cursor: pointer; }
</style>
