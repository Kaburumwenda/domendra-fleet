<template>
  <div class="d-flex flex-column ga-4">
    <!-- Page header -->
    <div class="page-header">
      <div>
        <h1 class="text-h5 font-weight-bold d-flex align-center ga-2">
          <v-icon color="primary">mdi-clipboard-list-outline</v-icon>
          Work Orders
        </h1>
        <p class="text-caption text-medium-emphasis">Manage repair work orders, track labor time, parts, and costs across your fleet.</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn variant="outlined" prepend-icon="mdi-refresh" @click="reloadAll" :loading="pending">Refresh</v-btn>
        <v-btn variant="tonal" color="deep-purple" prepend-icon="mdi-database-plus" @click="seedDemo" :loading="seeding">
          <span class="hidden-sm-and-down">Seed Demo Data</span>
        </v-btn>
        <v-btn v-can="'maintenance:create'" color="primary" prepend-icon="mdi-plus" @click="openCreate">
          <span class="hidden-sm-and-down">New Work Order</span>
        </v-btn>
      </div>
    </div>

    <!-- Analytics -->
    <WorkOrdersAnalytics
      :work-orders="workOrders"
      :currency-symbol="currencySymbol"
      :active-status-filter="statusFilter"
      @filter-status="setStatusFilter"
    />

    <!-- Filters bar -->
    <div class="d-flex flex-wrap align-center ga-2 filter-bar">
      <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Search work orders…" density="compact" hide-details variant="outlined" style="max-width:280px" clearable />
      <v-select v-model="statusFilter" :items="statusOptions" item-title="label" item-value="value" placeholder="All Status" density="compact" hide-details variant="outlined" clearable style="max-width:170px" />
      <v-select v-model="assigneeFilter" :items="mechanicOptions" item-title="full_name" item-value="id" placeholder="All Assignees" density="compact" hide-details variant="outlined" clearable style="max-width:200px" />
      <v-select v-model="typeFilter" :items="typeOptions" item-title="label" item-value="value" placeholder="All Types" density="compact" hide-details variant="outlined" clearable style="max-width:170px" />
      <v-btn v-if="hasFilters" variant="text" size="small" prepend-icon="mdi-filter-remove" @click="clearFilters">Clear</v-btn>
      <v-spacer />
      <div class="text-caption text-medium-emphasis">{{ filteredWorkOrders.length }} of {{ workOrders.length }} work orders</div>
    </div>

    <!-- Tabs -->
    <v-tabs v-model="tab" color="primary" density="compact" class="wo-tabs">
      <v-tab value="board" prepend-icon="mdi-view-column-outline">Board</v-tab>
      <v-tab value="records" prepend-icon="mdi-format-list-bulleted">Records</v-tab>
      <v-tab value="timeline" prepend-icon="mdi-timeline-text-outline">Timeline</v-tab>
    </v-tabs>

    <v-window v-model="tab" class="flex-grow-1">
      <!-- KANBAN BOARD -->
      <v-window-item value="board">
        <WorkOrderKanbanBoard :work-orders="filteredWorkOrders" :currency-symbol="currencySymbol" @open-detail="openDetail" @move-wo="moveWO" />
      </v-window-item>

      <!-- RECORDS (data table) -->
      <v-window-item value="records">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="headers" :items="filteredWorkOrders" :loading="pending" hover density="compact" :search="search">
            <template #item.id="{ value }">
              <NuxtLink :to="`/app/work-orders/${value}`" class="text-decoration-none font-weight-medium text-primary">#{{ value }}</NuxtLink>
            </template>
            <template #item.issue_title="{ item }">
              <div class="cursor-pointer" @click="openDetail(item)">
                <p class="font-weight-medium">{{ item.issue_title || '—' }}</p>
                <p class="text-caption text-medium-emphasis">{{ item.vehicle_name || '—' }}</p>
              </div>
            </template>
            <template #item.status="{ value }">
              <v-chip :color="statusColor(value)" variant="flat" size="small" class="text-capitalize">
                <v-icon start size="14">{{ statusIcon(value) }}</v-icon>{{ value ? value.replace('_', ' ') : '' }}
              </v-chip>
            </template>
            <template #item.assignment_type="{ value }">
              <v-chip :color="value === 'internal' ? 'primary' : 'deep-purple'" variant="tonal" size="small" class="text-capitalize">
                {{ value === 'internal' ? 'Internal' : 'External' }}
              </v-chip>
            </template>
            <template #item.assigned_to_name="{ value }">{{ value || '—' }}</template>
            <template #item.estimated_cost="{ value }"><span class="font-weight-medium">{{ currencySymbol }}{{ money(value) }}</span></template>
            <template #item.total_cost="{ value }"><span class="font-weight-bold text-success">{{ currencySymbol }}{{ money(value) }}</span></template>
            <template #item.created_at="{ value }">{{ fmt(value) }}</template>
            <template #item.actions="{ item }">
              <v-menu>
                <template #activator="{ props: p }">
                  <v-btn icon="mdi-dots-vertical" variant="text" size="small" v-bind="p" />
                </template>
                <v-list density="compact">
                  <v-list-item prepend-icon="mdi-eye-outline" @click="openDetail(item)">View Details</v-list-item>
                  <v-list-item prepend-icon="mdi-arrow-expand-all" :to="`/app/work-orders/${item.id}`">Full Page</v-list-item>
                  <v-list-item v-can="'maintenance:update'" v-if="item.status === 'assigned'" prepend-icon="mdi-play" @click="startWork(item)">Start Work</v-list-item>
                  <v-list-item v-can="'maintenance:update'" v-if="!['completed','closed'].includes(item.status)" prepend-icon="mdi-check-circle" @click="completeWO(item)">Mark Complete</v-list-item>
                  <v-list-item v-can="'maintenance:update'" prepend-icon="mdi-pencil" @click="openEdit(item)">Edit</v-list-item>
                </v-list>
              </v-menu>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-clipboard-list-outline</v-icon>
                <p>No work orders yet. Click <b>New Work Order</b> to add one.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>

      <!-- TIMELINE -->
      <v-window-item value="timeline">
        <v-card elevation="0" border rounded="lg">
          <v-card-text>
            <div v-if="!filteredWorkOrders.length" class="text-center py-12 text-medium-emphasis">
              <v-icon size="48" class="mb-3">mdi-timeline-text-outline</v-icon>
              <p>No work orders to show.</p>
            </div>
            <v-timeline v-else side="end" density="compact">
              <v-timeline-item v-for="w in timelineWorkOrders" :key="w.id" :dot-color="statusColor(w.status)" size="small" fill-dot>
                <template #opposite>
                  <span class="text-caption text-medium-emphasis">{{ fmt(w.created_at) }}</span>
                </template>
                <v-card elevation="0" border class="pa-3 cursor-pointer" @click="openDetail(w)">
                  <div class="d-flex align-start justify-space-between">
                    <div class="flex-grow-1">
                      <div class="d-flex align-center ga-2 mb-1">
                        <p class="font-weight-medium">WO #{{ w.id }} · {{ w.issue_title || '—' }}</p>
                        <v-chip :color="statusColor(w.status)" variant="tonal" size="x-small" class="text-capitalize">{{ w.status.replace('_', ' ') }}</v-chip>
                      </div>
                      <p class="text-caption text-medium-emphasis">{{ w.vehicle_name || '—' }} · {{ w.assigned_to_name || 'Unassigned' }} · {{ currencySymbol }}{{ money(w.total_cost) }}</p>
                      <div class="d-flex align-center ga-2 mt-1">
                        <v-chip :color="w.assignment_type === 'internal' ? 'primary' : 'deep-purple'" variant="outlined" size="x-small">{{ w.assignment_type === 'internal' ? 'Internal' : 'External' }}</v-chip>
                        <v-chip v-if="w.time_logs?.length" size="x-small" variant="outlined"><v-icon start size="12">mdi-clock-outline</v-icon>{{ w.time_logs.length }} logs</v-chip>
                        <v-chip v-if="w.parts_used?.length" size="x-small" variant="outlined"><v-icon start size="12">mdi-package-variant-closed</v-icon>{{ w.parts_used.length }} parts</v-chip>
                        <v-chip v-if="w.notes?.length" size="x-small" variant="outlined"><v-icon start size="12">mdi-comment-outline</v-icon>{{ w.notes.length }} notes</v-chip>
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
    <WorkOrderFormDialog
      ref="formRef"
      v-model="formDialog"
      :editing="editing"
      :saving="saving"
      :currency-symbol="currencySymbol"
      :open-issues="openIssues"
      :mechanics="mechanics"
      @save="saveWO"
    />

    <!-- Detail drawer -->
    <WorkOrderDetailDrawer
      v-model="drawerOpen"
      :wo="selectedWO"
      :currency-symbol="currencySymbol"
      @edit="openEdit"
      @start-work="startWork"
      @complete="completeWO"
    />
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })
const { $api, $swal } = useNuxtApp() as any
const { currencySymbol } = useCurrency()

const tab = ref<'board' | 'records' | 'timeline'>('board')
const search = ref('')
const statusFilter = ref<string | null>(null)
const assigneeFilter = ref<number | null>(null)
const typeFilter = ref<string | null>(null)

const statusOptions = [
  { label: 'Open', value: 'open' }, { label: 'Assigned', value: 'assigned' },
  { label: 'Parts Ordered', value: 'parts_ordered' }, { label: 'In Progress', value: 'in_progress' },
  { label: 'On Hold', value: 'on_hold' }, { label: 'Completed', value: 'completed' },
  { label: 'Closed', value: 'closed' },
]
const typeOptions = [
  { label: 'Internal', value: 'internal' },
  { label: 'External', value: 'external' },
]

const headers = [
  { title: 'WO #', key: 'id', width: '70px' },
  { title: 'Issue', key: 'issue_title', sortable: true },
  { title: 'Status', key: 'status', sortable: true, width: '130px' },
  { title: 'Type', key: 'assignment_type', width: '90px', sortable: true },
  { title: 'Assignee', key: 'assigned_to_name', width: '120px' },
  { title: 'Estimated', key: 'estimated_cost', sortable: true, width: '100px' },
  { title: 'Total', key: 'total_cost', sortable: true, width: '100px' },
  { title: 'Created', key: 'created_at', sortable: true, width: '100px' },
  { title: '', key: 'actions', width: '50px', sortable: false },
]

// --- Lookup data ---
const { data: issueData } = useAsyncData('wo-open-issues', () => $api('/issues/issues/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const openIssues = computed(() => issueData.value?.results || [])
const { data: mechData } = useAsyncData('wo-list-mechanics', () => $api('/contacts/', { query: { contact_type: 'mechanic', page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const mechanics = computed(() => mechData.value?.results || [])
const mechanicOptions = computed(() => mechanics.value)

// --- Main data ---
const { data: woData, pending, refresh } = useAsyncData('work-orders-page', () =>
  $api('/issues/work-orders/', { query: { page_size: 1000 } }), { default: () => ({ results: [], count: 0 }) })
const workOrders = computed(() => woData.value?.results || woData.value || [])

const filteredWorkOrders = computed(() => {
  let arr = workOrders.value
  if (statusFilter.value) arr = arr.filter(w => w.status === statusFilter.value)
  if (assigneeFilter.value) arr = arr.filter(w => w.assigned_to === assigneeFilter.value)
  if (typeFilter.value) arr = arr.filter(w => w.assignment_type === typeFilter.value)
  if (search.value) {
    const q = search.value.toLowerCase()
    arr = arr.filter(w => (w.issue_title || '').toLowerCase().includes(q) || (w.vehicle_name || '').toLowerCase().includes(q) || (w.assigned_to_name || '').toLowerCase().includes(q))
  }
  return arr
})
const hasFilters = computed(() => !!(statusFilter.value || assigneeFilter.value || typeFilter.value || search.value))
const timelineWorkOrders = computed(() => [...filteredWorkOrders.value].sort((a, b) => new Date(b.created_at).valueOf() - new Date(a.created_at).valueOf()))

// --- Dialogs ---
const formRef = ref<any>(null)
const formDialog = ref(false)
const editing = ref(false)
const saving = ref(false)
const drawerOpen = ref(false)
const selectedWO = ref<any>(null)

function openCreate() { editing.value = false; formRef.value?.reset(); formDialog.value = true }
function openEdit(w: any) { editing.value = true; formRef.value?.reset(w); formDialog.value = true; drawerOpen.value = false }
function openDetail(w: any) { selectedWO.value = w; drawerOpen.value = true }

async function saveWO(payload: any) {
  saving.value = true
  try {
    const { _id, ...body } = payload
    if (editing.value && payload._id) await $api(`/issues/work-orders/${payload._id}/`, { method: 'PATCH', body })
    else await $api('/issues/work-orders/', { method: 'POST', body })
    formDialog.value = false
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: editing.value ? 'Work order updated' : 'Work order created', toast: true, timer: 1500, position: 'top-end' })
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Save failed', toast: true, timer: 2000, position: 'top-end' }) } finally { saving.value = false }
}

async function startWork(w: any) {
  try {
    await $api(`/issues/work-orders/${w.id}/start-work/`, { method: 'POST' })
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: 'Work started', toast: true, timer: 1500, position: 'top-end' })
    if (selectedWO.value?.id === w.id) selectedWO.value = workOrders.value.find((x: any) => x.id === w.id) || null
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Failed to start work', toast: true, timer: 2000, position: 'top-end' }) }
}

async function completeWO(w: any) {
  const r = await $swal?.fire?.({ icon: 'question', title: 'Mark work order complete?', text: `WO #${w.id} · ${w.issue_title}`, showCancelButton: true, confirmButtonText: 'Complete', confirmButtonColor: '#10b981' })
  if (!r?.isConfirmed) return
  try {
    await $api(`/issues/work-orders/${w.id}/complete/`, { method: 'POST' })
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: 'Work order completed', toast: true, timer: 2000, position: 'top-end' })
    if (selectedWO.value?.id === w.id) selectedWO.value = workOrders.value.find((x: any) => x.id === w.id) || null
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Failed to complete', toast: true, timer: 2000, position: 'top-end' }) }
}

async function moveWO(id: number, status: string) {
  const w = workOrders.value.find((x: any) => x.id === id)
  if (!w || w.status === status) return
  try {
    await $api(`/issues/work-orders/${id}/`, { method: 'PATCH', body: { status } })
    await refresh()
    $swal?.fire?.({ icon: 'success', title: `Moved to ${status.replace('_', ' ')}`, toast: true, timer: 1200, position: 'top-end' })
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Move failed', toast: true, timer: 2000, position: 'top-end' }) }
}

// --- Filter helpers ---
function setStatusFilter(k: string) { statusFilter.value = statusFilter.value === k ? null : k; tab.value = 'records' }
function clearFilters() { search.value = ''; statusFilter.value = null; assigneeFilter.value = null; typeFilter.value = null }

// --- Utils ---
function money(v: any) { return parseFloat(v || 0).toFixed(2) }
function fmt(v?: string) { return v ? new Date(v).toLocaleDateString([], { month: 'short', day: 'numeric', year: '2-digit' }) : '—' }
function statusColor(s: string) { return ({ open: 'blue', assigned: 'indigo', parts_ordered: 'amber', in_progress: 'orange', on_hold: 'purple', completed: 'success', closed: 'grey' } as any)[s] || 'grey' }
function statusIcon(s: string) { return ({ open: 'mdi-clipboard-outline', assigned: 'mdi-account-check-outline', parts_ordered: 'mdi-package-variant-closed', in_progress: 'mdi-wrench', on_hold: 'mdi-pause-circle', completed: 'mdi-check-circle', closed: 'mdi-lock-check-outline' } as any)[s] || 'mdi-clipboard' }

// --- Bulk reload ---
async function reloadAll() { await refresh() }

// --- Seed demo data ---
const seeding = ref(false)
async function seedDemo() {
  const r = await $swal?.fire?.({
    icon: 'question',
    title: 'Seed demo data?',
    text: 'This will add sample work orders with time logs, parts, and mechanic assignments.',
    showCancelButton: true,
    confirmButtonText: 'Seed Data',
  })
  if (!r?.isConfirmed) return
  seeding.value = true
  try {
    const res = await $api('/issues/work-orders/seed-demo/', { method: 'POST' })
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: res?.detail || 'Demo data seeded', toast: true, timer: 2000, position: 'top-end' })
  } catch (e: any) {
    console.error(e)
    $swal?.fire?.({ icon: 'error', title: e?.response?._data?.detail || 'Failed to seed data', toast: true, timer: 3000, position: 'top-end' })
  } finally { seeding.value = false }
}
</script>

<style scoped>
.page-header { display:flex; align-items:flex-start; justify-content:space-between; gap:12px; flex-wrap:wrap; }
.filter-bar { flex-wrap:wrap; }
.wo-tabs :deep(.v-tab) { text-transform: none; font-weight: 600; }
.cursor-pointer { cursor: pointer; }
</style>
