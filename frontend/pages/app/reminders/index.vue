<template>
  <div class="d-flex flex-column ga-4">
    <!-- Page header -->
    <div class="page-header">
      <div>
        <h1 class="text-h5 font-weight-bold d-flex align-center ga-2">
          <v-icon color="primary">mdi-bell-ring-outline</v-icon>
          Reminders
        </h1>
        <p class="text-caption text-medium-emphasis">Schedule and track recurring maintenance reminders across your fleet by time, mileage, or engine hours.</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn variant="outlined" prepend-icon="mdi-refresh" @click="reloadAll" :loading="pending">Refresh</v-btn>
        <v-btn variant="tonal" color="deep-purple" prepend-icon="mdi-database-plus" @click="seedDemo" :loading="seeding">
          <span class="hidden-sm-and-down">Seed Demo Data</span>
        </v-btn>
        <v-btn v-can="'reminders:create'" color="primary" prepend-icon="mdi-plus" @click="openCreate">
          <span class="hidden-sm-and-down">New Reminder</span>
        </v-btn>
      </div>
    </div>

    <!-- Analytics -->
    <RemindersAnalytics
      :reminders="reminders"
      :active-status-filter="statusFilter"
      @filter-status="setStatusFilter"
      @filter-trigger="setTriggerFilter"
      @filter-vehicle="setVehicleFilter"
    />

    <!-- Filters bar -->
    <div class="d-flex flex-wrap align-center ga-2 filter-bar">
      <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Search reminders…" density="compact" hide-details variant="outlined" style="max-width:280px" clearable />
      <v-select v-model="triggerFilter" :items="triggerOptions" item-title="label" item-value="value" placeholder="All Triggers" density="compact" hide-details variant="outlined" clearable style="max-width:170px" />
      <v-select v-model="vehicleFilter" :items="vehicleOptions" item-title="display_name" item-value="display_name" placeholder="All Vehicles" density="compact" hide-details variant="outlined" clearable style="max-width:220px" />
      <v-select v-model="activeFilter" :items="activeOptions" item-title="label" item-value="value" placeholder="All" density="compact" hide-details variant="outlined" clearable style="max-width:130px" />
      <v-btn v-if="hasFilters" variant="text" size="small" prepend-icon="mdi-filter-remove" @click="clearFilters">Clear</v-btn>
      <v-spacer />
      <div class="text-caption text-medium-emphasis">{{ filteredReminders.length }} of {{ reminders.length }} reminders</div>
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
        <ReminderKanbanBoard :reminders="filteredReminders" @open-detail="openDetail" />
      </v-window-item>

      <!-- RECORDS (data table) -->
      <v-window-item value="records">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="headers" :items="filteredReminders" :loading="pending" hover density="compact" :search="search">
            <template #item.title="{ item }">
              <div class="cursor-pointer" @click="openDetail(item)">
                <p class="font-weight-medium">{{ item.title }}</p>
                <p class="text-caption text-medium-emphasis">{{ item.vehicle_name }}</p>
              </div>
            </template>
            <template #item.trigger_type="{ value }">
              <v-chip :color="triggerColor(value)" variant="tonal" size="small">
                <v-icon start size="14">{{ triggerIcon(value) }}</v-icon>{{ triggerLabel(value) }}
              </v-chip>
            </template>
            <template #item.trigger_interval="{ item }">{{ item.trigger_interval }} {{ intervalUnit(item.trigger_type) }}</template>
            <template #item.next_due="{ item }">
              <v-chip v-if="item.is_overdue" color="error" variant="flat" size="small"><v-icon start size="14">mdi-alert-octagon</v-icon>Overdue</v-chip>
              <v-chip v-else-if="item.is_due" color="warning" variant="flat" size="small"><v-icon start size="14">mdi-bell-alert</v-icon>Due</v-chip>
              <span v-else class="text-body-2">{{ nextDueText(item) }}</span>
            </template>
            <template #item.escalation_level="{ value }">
              <v-chip :color="escalationColor(value)" variant="tonal" size="small">{{ escalationLabel(value) }}</v-chip>
            </template>
            <template #item.auto_generate_work_order="{ value }">
              <v-icon :color="value ? 'info' : 'grey-lighten-2'" :icon="value ? 'mdi-clipboard-check' : 'mdi-clipboard-off-outline'" size="small" />
            </template>
            <template #item.is_active="{ value }">
              <v-icon :color="value ? 'success' : 'grey-lighten-2'" :icon="value ? 'mdi-check-circle' : 'mdi-close-circle'" size="small" />
            </template>
            <template #item.actions="{ item }">
              <v-menu>
                <template #activator="{ props: p }">
                  <v-btn icon="mdi-dots-vertical" variant="text" size="small" v-bind="p" />
                </template>
                <v-list density="compact">
                  <v-list-item prepend-icon="mdi-eye-outline" @click="openDetail(item)">View Details</v-list-item>
                  <v-list-item v-can="'reminders:update'" prepend-icon="mdi-pencil" @click="openEdit(item)">Edit</v-list-item>
                  <v-list-item v-if="item.is_active" v-can="'reminders:update'" prepend-icon="mdi-pause" @click="toggleActive(item)">Deactivate</v-list-item>
                  <v-list-item v-else v-can="'reminders:update'" prepend-icon="mdi-play" @click="toggleActive(item)">Activate</v-list-item>
                  <v-list-item v-can="'reminders:delete'" prepend-icon="mdi-trash-can-outline" base-color="error" @click="deleteReminder(item)">Delete</v-list-item>
                </v-list>
              </v-menu>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-bell-outline</v-icon>
                <p>No reminders yet. Click <b>Seed Demo Data</b> or <b>New Reminder</b> to get started.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>

      <!-- TIMELINE -->
      <v-window-item value="timeline">
        <v-card elevation="0" border rounded="lg">
          <v-card-text>
            <div v-if="!filteredReminders.length" class="text-center py-12 text-medium-emphasis">
              <v-icon size="48" class="mb-3">mdi-timeline-text-outline</v-icon>
              <p>No reminders to show.</p>
            </div>
            <v-timeline v-else side="end" density="compact">
              <v-timeline-item v-for="r in timelineReminders" :key="r.id" :dot-color="statusColor(r)" size="small" fill-dot>
                <template #opposite>
                  <span class="text-caption text-medium-emphasis">{{ fmt(r.created_at) }}</span>
                </template>
                <v-card elevation="0" border class="pa-3 cursor-pointer" @click="openDetail(r)">
                  <div class="d-flex align-start justify-space-between">
                    <div class="flex-grow-1">
                      <div class="d-flex align-center ga-2 mb-1">
                        <p class="font-weight-medium">{{ r.title }}</p>
                        <v-chip v-if="r.is_overdue" color="error" variant="flat" size="x-small">Overdue</v-chip>
                        <v-chip v-else-if="r.is_due" color="warning" variant="flat" size="x-small">Due</v-chip>
                      </div>
                      <p class="text-caption text-medium-emphasis">{{ r.vehicle_name }} · Every {{ r.trigger_interval }} {{ intervalUnit(r.trigger_type) }}</p>
                      <div class="d-flex align-center ga-2 mt-1 flex-wrap">
                        <v-chip :color="triggerColor(r.trigger_type)" variant="outlined" size="x-small">{{ triggerLabel(r.trigger_type) }}</v-chip>
                        <v-chip :color="escalationColor(r.escalation_level)" variant="outlined" size="x-small">{{ escalationLabel(r.escalation_level) }}</v-chip>
                        <v-chip v-if="r.auto_generate_work_order" color="info" variant="outlined" size="x-small"><v-icon start size="12">mdi-clipboard-plus</v-icon>Auto WO</v-chip>
                        <v-chip v-if="!r.is_active" color="grey" variant="outlined" size="x-small">Inactive</v-chip>
                        <span class="text-caption text-medium-emphasis">Next: {{ nextDueText(r) }}</span>
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
    <ReminderFormDialog
      ref="formRef"
      v-model="formDialog"
      :editing="editing"
      :saving="saving"
      :vehicle-options="vehicleOptions"
      @save="saveReminder"
    />

    <!-- Detail drawer -->
    <ReminderDetailDrawer
      v-model="drawerOpen"
      :reminder="selectedReminder"
      @edit="openEdit"
      @delete="deleteReminder"
      @toggle-active="toggleActive"
    />
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })
const { $api, $swal } = useNuxtApp() as any

const tab = ref<'board' | 'records' | 'timeline'>('board')
const search = ref('')
const triggerFilter = ref<string | null>(null)
const vehicleFilter = ref<string | null>(null)
const activeFilter = ref<boolean | null>(null)
const statusFilter = ref<string | null>(null)

const triggerOptions = [
  { label: 'Time (Months)', value: 'time' },
  { label: 'Mileage', value: 'mileage' },
  { label: 'Engine Hours', value: 'engine_hours' },
]
const activeOptions = [
  { label: 'Active', value: true },
  { label: 'Inactive', value: false },
]

const headers = [
  { title: 'Reminder', key: 'title', sortable: true },
  { title: 'Trigger', key: 'trigger_type', width: '130px', sortable: true },
  { title: 'Interval', key: 'trigger_interval', width: '100px' },
  { title: 'Next Due', key: 'next_due', width: '140px' },
  { title: 'Escalation', key: 'escalation_level', width: '130px', sortable: true },
  { title: 'Auto WO', key: 'auto_generate_work_order', width: '80px' },
  { title: 'Active', key: 'is_active', width: '70px', sortable: true },
  { title: '', key: 'actions', width: '50px', sortable: false },
]

// --- Lookup data ---
const { data: vehicleData } = useAsyncData('rem-vehicles', () => $api('/vehicles/vehicles/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const vehicleOptions = computed(() => vehicleData.value?.results || [])

// --- Main data ---
const { data: remData, pending, refresh } = useAsyncData('reminders-page', () =>
  $api('/reminders/', { query: { page_size: 1000 } }), { default: () => ({ results: [], count: 0 }) })
const reminders = computed(() => remData.value?.results || remData.value || [])

const filteredReminders = computed(() => {
  let arr = reminders.value
  if (triggerFilter.value) arr = arr.filter(r => r.trigger_type === triggerFilter.value)
  if (vehicleFilter.value) arr = arr.filter(r => r.vehicle_name === vehicleFilter.value)
  if (activeFilter.value !== null) arr = arr.filter(r => r.is_active === activeFilter.value)
  if (statusFilter.value === 'overdue') arr = arr.filter(r => r.is_overdue)
  else if (statusFilter.value === 'due') arr = arr.filter(r => r.is_due)
  if (search.value) {
    const q = search.value.toLowerCase()
    arr = arr.filter(r => (r.title || '').toLowerCase().includes(q) || (r.vehicle_name || '').toLowerCase().includes(q))
  }
  return arr
})
const hasFilters = computed(() => !!(search.value || triggerFilter.value || vehicleFilter.value || activeFilter.value !== null || statusFilter.value))
const timelineReminders = computed(() => [...filteredReminders.value].sort((a, b) => new Date(b.created_at).valueOf() - new Date(a.created_at).valueOf()))

// --- Dialogs ---
const formRef = ref<any>(null)
const formDialog = ref(false)
const editing = ref(false)
const saving = ref(false)
const drawerOpen = ref(false)
const selectedReminder = ref<any>(null)

function openCreate() { editing.value = false; formRef.value?.reset(); formDialog.value = true }
function openEdit(r: any) { editing.value = true; formRef.value?.reset(r); formDialog.value = true; drawerOpen.value = false }
function openDetail(r: any) { selectedReminder.value = r; drawerOpen.value = true }

async function saveReminder(payload: any) {
  saving.value = true
  try {
    const { _id, ...body } = payload
    if (editing.value && payload._id) await $api(`/reminders/${payload._id}/`, { method: 'PATCH', body })
    else await $api('/reminders/', { method: 'POST', body })
    formDialog.value = false
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: editing.value ? 'Reminder updated' : 'Reminder created', toast: true, timer: 1500, position: 'top-end' })
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Save failed', toast: true, timer: 2000, position: 'top-end' }) } finally { saving.value = false }
}

async function deleteReminder(r: any) {
  const res = await $swal?.fire?.({ icon: 'warning', title: 'Delete reminder?', text: `"${r.title}" will be permanently removed.`, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!res?.isConfirmed) return
  try {
    await $api(`/reminders/${r.id}/`, { method: 'DELETE' })
    drawerOpen.value = false
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: 'Reminder deleted', toast: true, timer: 1500, position: 'top-end' })
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Delete failed', toast: true, timer: 2000, position: 'top-end' }) }
}

async function toggleActive(r: any) {
  try {
    await $api(`/reminders/${r.id}/`, { method: 'PATCH', body: { is_active: !r.is_active } })
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: r.is_active ? 'Reminder deactivated' : 'Reminder activated', toast: true, timer: 1500, position: 'top-end' })
    if (selectedReminder.value?.id === r.id) selectedReminder.value = reminders.value.find((x: any) => x.id === r.id) || null
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Update failed', toast: true, timer: 2000, position: 'top-end' }) }
}

// --- Filter helpers ---
function setStatusFilter(k: string) { statusFilter.value = statusFilter.value === k ? null : k; tab.value = 'records' }
function setTriggerFilter(k: string) { triggerFilter.value = triggerFilter.value === k ? null : k; tab.value = 'records' }
function setVehicleFilter(v: string) { vehicleFilter.value = vehicleFilter.value === v ? null : v; tab.value = 'records' }
function clearFilters() { search.value = ''; triggerFilter.value = null; vehicleFilter.value = null; activeFilter.value = null; statusFilter.value = null }

// --- Utils ---
function triggerColor(t: string) { return ({ time: 'primary', mileage: 'warning', engine_hours: 'info' } as any)[t] || 'grey' }
function triggerIcon(t: string) { return ({ time: 'mdi-calendar-clock', mileage: 'mdi-counter', engine_hours: 'mdi-engine-outline' } as any)[t] || 'mdi-bell' }
function triggerLabel(t: string) { return ({ time: 'Time', mileage: 'Mileage', engine_hours: 'Engine Hrs' } as any)[t] || t }
function intervalUnit(t: string) { return ({ time: 'months', mileage: 'miles', engine_hours: 'hours' } as any)[t] || '' }
function escalationColor(e: number) { return ({ 0: 'grey', 1: 'info', 2: 'warning', 3: 'error' } as any)[e] || 'grey' }
function escalationLabel(e: number) { return ({ 0: 'None', 1: 'Email Driver', 2: 'SMS Manager', 3: 'Block Dispatch' } as any)[e] || 'None' }
function statusColor(r: any) { return r.is_overdue ? 'error' : r.is_due ? 'warning' : r.is_active ? 'success' : 'grey' }
function nextDueText(r: any) {
  if (r.trigger_type === 'time' && r.next_due_date) return new Date(r.next_due_date).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' })
  if (r.trigger_type === 'mileage' && r.next_due_mileage) return `${r.next_due_mileage.toLocaleString()} mi`
  if (r.trigger_type === 'engine_hours' && r.next_due_engine_hours) return `${r.next_due_engine_hours.toLocaleString()} hrs`
  return '—'
}
function fmt(v?: string) { return v ? new Date(v).toLocaleDateString([], { month: 'short', day: 'numeric', year: '2-digit' }) : '—' }

// --- Bulk reload ---
async function reloadAll() { await refresh() }

// --- Seed demo data ---
const seeding = ref(false)
async function seedDemo() {
  const r = await $swal?.fire?.({
    icon: 'question',
    title: 'Seed demo data?',
    text: 'This will add sample maintenance reminders for each vehicle in your fleet.',
    showCancelButton: true,
    confirmButtonText: 'Seed Data',
  })
  if (!r?.isConfirmed) return
  seeding.value = true
  try {
    const res = await $api('/reminders/seed-demo/', { method: 'POST' })
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
.rem-tabs :deep(.v-tab) { text-transform: none; font-weight: 600; }
.cursor-pointer { cursor: pointer; }
</style>
