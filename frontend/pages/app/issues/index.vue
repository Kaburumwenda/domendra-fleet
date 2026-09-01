<template>
  <div class="d-flex flex-column ga-4">
    <!-- Page header -->
    <div class="page-header">
      <div>
        <h1 class="text-h5 font-weight-bold d-flex align-center ga-2">
          <v-icon color="primary">mdi-alert-circle-multiple-outline</v-icon>
          Issues
        </h1>
        <p class="text-caption text-medium-emphasis">Track and resolve vehicle issues, manage work orders, and monitor fleet health.</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn variant="outlined" prepend-icon="mdi-refresh" @click="reloadAll" :loading="pending">Refresh</v-btn>
        <v-btn variant="tonal" color="deep-purple" prepend-icon="mdi-database-plus" @click="seedDemo" :loading="seeding">
          <span class="hidden-sm-and-down">Seed Demo Data</span>
        </v-btn>
        <v-btn v-can="'maintenance:create'" color="primary" prepend-icon="mdi-plus" @click="openCreate">
          <span class="hidden-sm-and-down">Report Issue</span>
        </v-btn>
      </div>
    </div>

    <!-- Analytics -->
    <IssuesAnalytics
      :issues="issues"
      :active-status-filter="statusFilter"
      :active-priority-filter="priorityFilter"
      @filter-status="setStatusFilter"
      @filter-priority="setPriorityFilter"
      @filter-vehicle="setVehicleFilter"
    />

    <!-- Filters bar -->
    <div class="d-flex flex-wrap align-center ga-2 filter-bar">
      <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Search issues…" density="compact" hide-details variant="outlined" style="max-width:280px" clearable />
      <v-select v-model="statusFilter" :items="statusOptions" item-title="label" item-value="value" placeholder="All Status" density="compact" hide-details variant="outlined" clearable style="max-width:170px" />
      <v-select v-model="priorityFilter" :items="priorityOptions" item-title="label" item-value="value" placeholder="All Priority" density="compact" hide-details variant="outlined" clearable style="max-width:160px" />
      <v-select v-model="vehicleFilter" :items="vehicleOptions" item-title="display_name" item-value="id" placeholder="All Vehicles" density="compact" hide-details variant="outlined" clearable style="max-width:200px" />
      <v-btn v-if="hasFilters" variant="text" size="small" prepend-icon="mdi-filter-remove" @click="clearFilters">Clear</v-btn>
      <v-spacer />
      <div class="text-caption text-medium-emphasis">{{ filteredIssues.length }} of {{ issues.length }} issues</div>
    </div>

    <!-- Tabs -->
    <v-tabs v-model="tab" color="primary" density="compact" class="issue-tabs">
      <v-tab value="board" prepend-icon="mdi-view-column-outline">Board</v-tab>
      <v-tab value="records" prepend-icon="mdi-format-list-bulleted">Records</v-tab>
      <v-tab value="timeline" prepend-icon="mdi-timeline-text-outline">Timeline</v-tab>
    </v-tabs>

    <v-window v-model="tab" class="flex-grow-1">
      <!-- KANBAN BOARD -->
      <v-window-item value="board">
        <IssueKanbanBoard :issues="filteredIssues" @open-detail="openDetail" @move-issue="moveIssue" />
      </v-window-item>

      <!-- RECORDS (data table) -->
      <v-window-item value="records">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="headers" :items="filteredIssues" :loading="pending" hover density="compact" :search="search">
            <template #item.title="{ item }">
              <div class="cursor-pointer" @click="openDetail(item)">
                <p class="font-weight-medium">{{ item.title }}</p>
                <p class="text-caption text-medium-emphasis">{{ item.vehicle_name }}</p>
              </div>
            </template>
            <template #item.status="{ value }">
              <v-chip :color="issueStatusColor(value)" variant="flat" size="small" class="text-capitalize">
                <v-icon start size="14">{{ statusIcon(value) }}</v-icon>{{ value ? value.replace('_', ' ') : '' }}
              </v-chip>
            </template>
            <template #item.priority="{ value }">
              <v-chip :color="priorityColor(value)" variant="flat" size="small" class="text-capitalize font-weight-bold">
                <v-icon start size="14">{{ priorityIcon(value) }}</v-icon>{{ value }}
              </v-chip>
            </template>
            <template #item.has_work_order="{ value }">
              <v-icon :color="value ? 'success' : 'grey-lighten-2'" :icon="value ? 'mdi-clipboard-check-outline' : 'mdi-clipboard-off-outline'" size="small" />
            </template>
            <template #item.reported_by_name="{ value }">{{ value || '—' }}</template>
            <template #item.created_at="{ value }">{{ fmt(value) }}</template>
            <template #item.actions="{ item }">
              <v-menu>
                <template #activator="{ props: p }">
                  <v-btn icon="mdi-dots-vertical" variant="text" size="small" v-bind="p" />
                </template>
                <v-list density="compact">
                  <v-list-item prepend-icon="mdi-eye-outline" @click="openDetail(item)">View Details</v-list-item>
                  <v-list-item v-can="'maintenance:create'" v-if="!item.has_work_order" prepend-icon="mdi-wrench-plus" @click="openAssign(item)">Create Work Order</v-list-item>
                  <v-list-item v-if="item.has_work_order" prepend-icon="mdi-arrow-expand-all" :to="`/app/work-orders/${item.work_order_id}`">View Work Order</v-list-item>
                  <v-list-item v-can="'maintenance:update'" prepend-icon="mdi-pencil" @click="openEdit(item)">Edit</v-list-item>
                  <v-list-item v-can="'maintenance:delete'" prepend-icon="mdi-delete" base-color="error" @click="deleteIssue(item)">Delete</v-list-item>
                </v-list>
              </v-menu>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-alert-circle-outline</v-icon>
                <p>No issues found. Click <b>Report Issue</b> to add one.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>

      <!-- TIMELINE -->
      <v-window-item value="timeline">
        <v-card elevation="0" border rounded="lg">
          <v-card-text>
            <div v-if="!filteredIssues.length" class="text-center py-12 text-medium-emphasis">
              <v-icon size="48" class="mb-3">mdi-timeline-text-outline</v-icon>
              <p>No issues to show.</p>
            </div>
            <v-timeline v-else side="end" density="compact">
              <v-timeline-item v-for="i in timelineIssues" :key="i.id" :dot-color="issueStatusColor(i.status)" size="small" fill-dot>
                <template #opposite>
                  <span class="text-caption text-medium-emphasis">{{ fmt(i.created_at) }}</span>
                </template>
                <v-card elevation="0" border class="pa-3 cursor-pointer" @click="openDetail(i)">
                  <div class="d-flex align-start justify-space-between">
                    <div class="flex-grow-1">
                      <div class="d-flex align-center ga-2 mb-1">
                        <p class="font-weight-medium">{{ i.title }}</p>
                        <v-chip :color="priorityColor(i.priority)" variant="flat" size="x-small" class="font-weight-bold text-uppercase">{{ i.priority }}</v-chip>
                      </div>
                      <p class="text-caption text-medium-emphasis">{{ i.vehicle_name || '—' }} · {{ i.reported_by_name || 'Unassigned' }}</p>
                      <p v-if="i.description" class="text-body-2 mt-1 desc-clamp">{{ i.description }}</p>
                      <div class="d-flex align-center ga-2 mt-1">
                        <v-chip :color="issueStatusColor(i.status)" variant="tonal" size="x-small" class="text-capitalize">{{ i.status.replace('_', ' ') }}</v-chip>
                        <v-chip v-if="i.has_work_order" size="x-small" variant="outlined" color="info"><v-icon start size="12">mdi-clipboard-list-outline</v-icon>WO #{{ i.work_order_id }}</v-chip>
                      </div>
                    </div>
                    <v-btn v-can="'maintenance:update'" icon="mdi-pencil-outline" size="x-small" variant="text" @click.stop="openEdit(i)" />
                  </div>
                </v-card>
              </v-timeline-item>
            </v-timeline>
          </v-card-text>
        </v-card>
      </v-window-item>
    </v-window>

    <!-- Issue create/edit dialog -->
    <IssueFormDialog
      ref="formRef"
      v-model="formDialog"
      :editing="editing"
      :saving="saving"
      :vehicle-options="vehicleOptions"
      @save="saveIssue"
    />

    <!-- Assign / Create Work Order dialog -->
    <IssueAssignDialog
      ref="assignRef"
      v-model="assignDialog"
      :saving="saving"
      :currency-symbol="currencySymbol"
      :mechanics="mechanics"
      :issue="activeIssue"
      @submit="submitAssign"
    />

    <!-- Detail drawer -->
    <IssueDetailDrawer
      v-model="drawerOpen"
      :issue="selectedIssue"
      :currency-symbol="currencySymbol"
      @edit="openEdit"
      @delete="deleteIssue"
      @assign="openAssign"
      @create-work-order="openAssign"
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
const priorityFilter = ref<string | null>(null)
const vehicleFilter = ref<number | null>(null)

const statusOptions = [
  { label: 'Open', value: 'open' }, { label: 'Assigned', value: 'assigned' },
  { label: 'Parts Ordered', value: 'parts_ordered' }, { label: 'In Progress', value: 'in_progress' },
  { label: 'Resolved', value: 'resolved' }, { label: 'Closed', value: 'closed' },
]
const priorityOptions = [
  { label: 'Low', value: 'low' }, { label: 'Medium', value: 'medium' },
  { label: 'High', value: 'high' }, { label: 'Critical', value: 'critical' },
]

const headers = [
  { title: 'Issue', key: 'title', sortable: true },
  { title: 'Status', key: 'status', sortable: true, width: '140px' },
  { title: 'Priority', key: 'priority', sortable: true, width: '110px' },
  { title: 'Work Order', key: 'has_work_order', width: '90px', sortable: false },
  { title: 'Reported By', key: 'reported_by_name', width: '120px' },
  { title: 'Created', key: 'created_at', sortable: true, width: '120px' },
  { title: '', key: 'actions', width: '50px', sortable: false },
]

// --- Lookup data ---
const { data: vehicleData } = useAsyncData('issue-vehicles', () => $api('/vehicles/vehicles/', { query: { page_size: 1000 } }), { default: () => ({ results: [] }) })
const vehicleOptions = computed(() => vehicleData.value?.results || [])
const { data: mechData } = useAsyncData('issue-mechanics', () => $api('/contacts/', { query: { contact_type: 'mechanic', page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const mechanics = computed(() => mechData.value?.results || [])

// --- Main data ---
const { data: issueData, pending, refresh } = useAsyncData('issues-page', () =>
  $api('/issues/issues/', { query: { page_size: 1000 } }), { default: () => ({ results: [], count: 0 }) })
const issues = computed(() => issueData.value?.results || issueData.value || [])

const filteredIssues = computed(() => {
  let arr = issues.value
  if (statusFilter.value) arr = arr.filter(i => i.status === statusFilter.value)
  if (priorityFilter.value) arr = arr.filter(i => i.priority === priorityFilter.value)
  if (vehicleFilter.value) arr = arr.filter(i => i.vehicle === vehicleFilter.value)
  if (search.value) {
    const q = search.value.toLowerCase()
    arr = arr.filter(i => (i.title || '').toLowerCase().includes(q) || (i.description || '').toLowerCase().includes(q) || (i.vehicle_name || '').toLowerCase().includes(q))
  }
  return arr
})
const hasFilters = computed(() => !!(statusFilter.value || priorityFilter.value || vehicleFilter.value || search.value))
const timelineIssues = computed(() => [...filteredIssues.value].sort((a, b) => new Date(b.created_at).valueOf() - new Date(a.created_at).valueOf()))

// --- Dialogs ---
const formRef = ref<any>(null)
const formDialog = ref(false)
const editing = ref(false)
const saving = ref(false)
const assignRef = ref<any>(null)
const assignDialog = ref(false)
const drawerOpen = ref(false)
const selectedIssue = ref<any>(null)
const activeIssue = ref<any>(null)

function openCreate() { editing.value = false; formRef.value?.reset(); formDialog.value = true }
function openEdit(i: any) { editing.value = true; formRef.value?.reset(i); formDialog.value = true; drawerOpen.value = false }
function openDetail(i: any) { selectedIssue.value = i; drawerOpen.value = true }
function openAssign(i: any) { activeIssue.value = i; assignRef.value?.reset(); assignDialog.value = true; drawerOpen.value = false }

async function saveIssue(payload: any) {
  saving.value = true
  try {
    const { _id, newPhotos: photos, deletedPhotoIds: delIds, ...body } = payload
    let issueId: number = _id
    if (editing.value && _id) {
      await $api(`/issues/issues/${_id}/`, { method: 'PATCH', body })
    } else {
      const created = await $api('/issues/issues/', { method: 'POST', body })
      issueId = created.id
    }
    // Upload new photos
    if (photos && photos.length && issueId) {
      for (const file of photos as File[]) {
        const formData = new FormData()
        formData.append('issue', String(issueId))
        formData.append('image', file)
        await $api('/issues/photos/', { method: 'POST', body: formData })
      }
    }
    // Delete removed photos
    if (delIds && delIds.length) {
      for (const pid of delIds as number[]) {
        await $api(`/issues/photos/${pid}/`, { method: 'DELETE' }).catch(() => {})
      }
    }
    formDialog.value = false
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: editing.value ? 'Issue updated' : 'Issue reported', toast: true, timer: 1500, position: 'top-end' })
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Save failed', toast: true, timer: 2000, position: 'top-end' }) } finally { saving.value = false }
}

async function deleteIssue(i: any) {
  const r = await $swal?.fire?.({ icon: 'warning', title: 'Delete this issue?', text: i.title, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#dc2626' })
  if (!r?.isConfirmed) return
  await $api(`/issues/issues/${i.id}/`, { method: 'DELETE' })
  if (selectedIssue.value?.id === i.id) { drawerOpen.value = false; selectedIssue.value = null }
  await reloadAll()
  $swal?.fire?.({ icon: 'success', title: 'Issue deleted', toast: true, timer: 1500, position: 'top-end' })
}

async function submitAssign(payload: any) {
  if (!activeIssue.value) return
  saving.value = true
  try {
    await $api(`/issues/issues/${activeIssue.value.id}/assign/`, { method: 'POST', body: payload })
    assignDialog.value = false
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: 'Issue assigned & work order created', toast: true, timer: 2000, position: 'top-end' })
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Assignment failed', toast: true, timer: 2000, position: 'top-end' }) } finally { saving.value = false }
}

async function moveIssue(id: number, status: string) {
  const issue = issues.value.find((i: any) => i.id === id)
  if (!issue || issue.status === status) return
  try {
    await $api(`/issues/issues/${id}/`, { method: 'PATCH', body: { status } })
    await refresh()
    $swal?.fire?.({ icon: 'success', title: `Moved to ${status.replace('_', ' ')}`, toast: true, timer: 1200, position: 'top-end' })
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Move failed', toast: true, timer: 2000, position: 'top-end' }) }
}

// --- Filter helpers ---
function setStatusFilter(k: string) { statusFilter.value = statusFilter.value === k ? null : k; tab.value = 'records' }
function setPriorityFilter(k: string) { priorityFilter.value = priorityFilter.value === k ? null : k; tab.value = 'records' }
function setVehicleFilter(id: number) { vehicleFilter.value = vehicleFilter.value === id ? null : id; tab.value = 'records' }
function clearFilters() { search.value = ''; statusFilter.value = null; priorityFilter.value = null; vehicleFilter.value = null }

// --- Utils ---
function fmt(v?: string) { return v ? new Date(v).toLocaleDateString([], { month: 'short', day: 'numeric', year: '2-digit' }) : '—' }
function issueStatusColor(s: string) { return ({ open: 'blue', assigned: 'indigo', parts_ordered: 'amber', in_progress: 'orange', resolved: 'success', closed: 'grey' } as any)[s] || 'grey' }
function statusIcon(s: string) { return ({ open: 'mdi-alert-circle-outline', assigned: 'mdi-account-check-outline', parts_ordered: 'mdi-package-variant-closed', in_progress: 'mdi-progress-clock', resolved: 'mdi-check-circle', closed: 'mdi-lock-check-outline' } as any)[s] || 'mdi-alert' }
function priorityColor(p: string) { return ({ low: 'grey', medium: 'yellow-darken-2', high: 'orange', critical: 'error' } as any)[p] || 'grey' }
function priorityIcon(p: string) { return ({ low: 'mdi-flag-outline', medium: 'mdi-flag', high: 'mdi-flag-variant', critical: 'mdi-flag-variant' } as any)[p] || 'mdi-flag-outline' }

// --- Bulk reload ---
async function reloadAll() { await refresh() }

// --- Seed demo data ---
const seeding = ref(false)
async function seedDemo() {
  const r = await $swal?.fire?.({
    icon: 'question',
    title: 'Seed demo data?',
    text: 'This will add 22 sample issues with work orders, notes, and mechanics.',
    showCancelButton: true,
    confirmButtonText: 'Seed Data',
  })
  if (!r?.isConfirmed) return
  seeding.value = true
  try {
    const res = await $api('/issues/issues/seed-demo/', { method: 'POST' })
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
.issue-tabs :deep(.v-tab) { text-transform: none; font-weight: 600; }
.cursor-pointer { cursor: pointer; }
.desc-clamp { display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }
</style>
