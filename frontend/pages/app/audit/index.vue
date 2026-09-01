<template>
  <div class="d-flex flex-column ga-4">
    <!-- Header -->
    <div class="d-flex align-center ga-3 flex-wrap">
      <div class="d-flex align-center justify-center rounded-xl" style="width: 48px; height: 48px; background: linear-gradient(135deg, #6366f1, #818cf8)">
        <v-icon color="white">mdi-shield-search</v-icon>
      </div>
      <div>
        <h1 class="text-h5 font-weight-bold" style="color: #1e293b">Audit Logs</h1>
        <p class="text-body-2 text-medium-emphasis mb-0">Track all system activities — create, update, delete, login, and more</p>
      </div>
      <v-spacer />
    </div>

    <!-- Stats Row -->
    <v-row dense>
      <v-col cols="6" md="3" v-for="stat in statsCards" :key="stat.label">
        <v-card elevation="0" border rounded="lg" class="pa-4 h-100" :style="{ background: stat.bg }">
          <div class="d-flex align-center ga-3">
            <v-avatar size="40" rounded :color="stat.color" variant="flat">
              <v-icon :icon="stat.icon" color="white" size="20" />
            </v-avatar>
            <div>
              <p class="text-h5 font-weight-bold mb-0" :style="{ color: stat.textColor }">{{ stat.value }}</p>
              <p class="text-caption mb-0" :style="{ color: stat.subColor }">{{ stat.label }}</p>
            </div>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <!-- Filters Bar -->
    <v-card elevation="0" border rounded="lg" class="pa-4">
      <div class="d-flex align-center ga-3 flex-wrap">
        <v-text-field
          v-model="search"
          density="compact"
          variant="outlined"
          prepend-inner-icon="mdi-magnify"
          placeholder="Search by path, resource…"
          hide-details
          clearable
          style="max-width: 300px"
          @keyup.enter="load"
          @click:clear="clearSearch"
        />
        <v-select
          v-model="filterAction"
          :items="actionOptions"
          item-title="label"
          item-value="value"
          density="compact"
          variant="outlined"
          label="Action"
          hide-details
          clearable
          style="max-width: 160px"
        />
        <v-select
          v-model="filterPriority"
          :items="priorityOptions"
          item-title="label"
          item-value="value"
          density="compact"
          variant="outlined"
          label="Priority"
          hide-details
          clearable
          style="max-width: 140px"
        />
        <v-select
          v-model="filterMethod"
          :items="methodOptions"
          density="compact"
          variant="outlined"
          label="Method"
          hide-details
          clearable
          style="max-width: 140px"
        />
        <v-select
          v-model="filterResource"
          :items="resourceOptions"
          density="compact"
          variant="outlined"
          label="Resource"
          hide-details
          clearable
          style="max-width: 180px"
        />
        <v-text-field
          v-model="filterUser"
          density="compact"
          variant="outlined"
          label="User ID"
          placeholder="Filter by user"
          hide-details
          clearable
          style="max-width: 140px"
        />
        <v-spacer />
        <v-btn icon="mdi-refresh" variant="tonal" :loading="loading" @click="load" />
        <v-btn variant="tonal" color="info" prepend-icon="mdi-download" @click="downloadCsv">Export CSV</v-btn>
      </div>
    </v-card>

    <!-- Data Table -->
    <v-card elevation="0" border rounded="lg">
      <v-data-table
        :headers="headers"
        :items="filteredLogs"
        :loading="loading"
        hover
        items-per-page="25"
        v-model:page="page"
        :items-per-page-options="[10, 25, 50, 100]"
      >
        <template #item.index="{ index }">
          <span class="text-caption text-medium-emphasis">{{ (page - 1) * itemsPerPage + index + 1 }}</span>
        </template>
        <template #item.action="{ value }">
          <div class="d-flex align-center ga-2">
            <v-avatar size="28" :color="actionColor(value)" variant="flat">
              <v-icon size="small" color="white">{{ actionIcon(value) }}</v-icon>
            </v-avatar>
            <v-chip :color="actionColor(value)" size="small" variant="flat" class="text-capitalize">{{ value }}</v-chip>
          </div>
        </template>
        <template #item.priority="{ value }">
          <div class="d-flex align-center ga-1">
            <v-icon size="16" :color="priorityColor(value)">{{ priorityIcon(value) }}</v-icon>
            <v-chip :color="priorityColor(value)" size="x-small" variant="tonal" class="text-capitalize font-weight-bold">{{ value || 'info' }}</v-chip>
          </div>
        </template>
        <template #item.resource_type="{ value }">
          <span class="text-body-2 font-weight-medium">{{ value || '—' }}</span>
        </template>
        <template #item.method="{ value }">
          <v-chip v-if="value" size="x-small" :color="methodColor(value)" variant="tonal" label>{{ value }}</v-chip>
          <span v-else>—</span>
        </template>
        <template #item.status_code="{ value }">
          <v-chip v-if="value" size="x-small" :color="statusColor(value)" variant="tonal">{{ value }}</v-chip>
          <span v-else>—</span>
        </template>
        <template #item.path="{ value }">
          <span class="text-caption" style="font-family: monospace; color: #64748b">{{ value || '—' }}</span>
        </template>
        <template #item.user_name="{ value }">
          <div class="d-flex align-center ga-2">
            <v-avatar size="24" color="#eef2ff">
              <v-icon size="14" color="#4f46e5">mdi-account</v-icon>
            </v-avatar>
            <span class="text-body-2">{{ value || 'System' }}</span>
          </div>
        </template>
        <template #item.ip_address="{ value }">
          <span class="text-caption text-medium-emphasis" style="font-family: monospace">{{ value || '—' }}</span>
        </template>
        <template #item.timestamp="{ value }">
          <span class="text-caption text-medium-emphasis" :title="new Date(value).toLocaleString()">{{ formatRelative(value) }}</span>
        </template>
        <template #item.details="{ item }">
          <v-btn
            v-if="item.details && Object.keys(item.details).length"
            size="x-small"
            variant="text"
            color="primary"
            prepend-icon="mdi-information-outline"
            @click="showDetails(item)"
          >View</v-btn>
          <span v-else class="text-caption text-medium-emphasis">—</span>
        </template>
      </v-data-table>
    </v-card>

    <!-- Details Dialog -->
    <v-dialog v-model="detailsDialog" max-width="600">
      <v-card>
        <v-card-title class="text-h6 d-flex align-center ga-2">
          <v-icon color="primary">mdi-code-json</v-icon> Log Details
        </v-card-title>
        <v-divider />
        <v-card-text v-if="selectedLog">
          <div class="mb-3 d-flex ga-2 flex-wrap">
            <v-chip :color="actionColor(selectedLog.action)" size="small" variant="flat" class="text-capitalize">{{ selectedLog.action }}</v-chip>
            <v-chip :color="priorityColor(selectedLog.priority)" size="small" variant="tonal" class="text-capitalize font-weight-bold" prepend-icon="mdi-alert-circle">{{ selectedLog.priority || 'info' }}</v-chip>
            <v-chip v-if="selectedLog.method" size="small" variant="tonal">{{ selectedLog.method }}</v-chip>
            <v-chip v-if="selectedLog.status_code" size="small" :color="statusColor(selectedLog.status_code)" variant="tonal">{{ selectedLog.status_code }}</v-chip>
          </div>
          <div class="mb-3">
            <p class="text-caption text-medium-emphasis mb-1">Path</p>
            <code style="font-size: 12px; background: #f1f5f9; padding: 4px 8px; border-radius: 4px">{{ selectedLog.path || '—' }}</code>
          </div>
          <div class="mb-3">
            <p class="text-caption text-medium-emphasis mb-1">User</p>
            <p class="text-body-2">{{ selectedLog.user_name || 'System' }}</p>
          </div>
          <div class="mb-3">
            <p class="text-caption text-medium-emphasis mb-1">IP Address</p>
            <p class="text-body-2" style="font-family: monospace">{{ selectedLog.ip_address || '—' }}</p>
          </div>
          <div class="mb-3">
            <p class="text-caption text-medium-emphasis mb-1">Resource ID</p>
            <p class="text-body-2" style="font-family: monospace">{{ selectedLog.resource_id || '—' }}</p>
          </div>
          <div class="mb-3">
            <p class="text-caption text-medium-emphasis mb-1">Timestamp</p>
            <p class="text-body-2">{{ new Date(selectedLog.timestamp).toLocaleString() }}</p>
          </div>
          <div v-if="selectedLog.details && Object.keys(selectedLog.details).length">
            <p class="text-caption text-medium-emphasis mb-1">Request Details (JSON)</p>
            <pre style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 12px; font-size: 12px; max-height: 300px; overflow-auto">{{ JSON.stringify(selectedLog.details, null, 2) }}</pre>
          </div>
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn variant="text" @click="detailsDialog = false">Close</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

const { $api, $swal } = useNuxtApp()

const loading = ref(false)
const logs = ref<any[]>([])
const page = ref(1)
const itemsPerPage = ref(25)
const search = ref('')
const filterAction = ref<string | null>(null)
const filterMethod = ref<string | null>(null)
const filterPriority = ref<string | null>(null)
const filterResource = ref<string | null>(null)
const filterUser = ref<string | null>(null)

const detailsDialog = ref(false)
const selectedLog = ref<any>(null)

const actionOptions = [
  { label: 'Create', value: 'create' },
  { label: 'Update', value: 'update' },
  { label: 'Delete', value: 'delete' },
  { label: 'View', value: 'view' },
  { label: 'Login', value: 'login' },
  { label: 'Logout', value: 'logout' },
  { label: 'Export', value: 'export' },
]
const methodOptions = ['POST', 'PUT', 'PATCH', 'DELETE', 'GET']
const priorityOptions = [
  { label: 'Info', value: 'info' },
  { label: 'Warning', value: 'warning' },
  { label: 'Critical', value: 'critical' },
]

const headers = [
  { title: '#', key: 'index', width: '50px', sortable: false },
  { title: 'Action', key: 'action', width: '130px', sortable: true },
  { title: 'Priority', key: 'priority', width: '110px', sortable: true },
  { title: 'Resource', key: 'resource_type', width: '140px', sortable: true },
  { title: 'Method', key: 'method', width: '80px' },
  { title: 'Status', key: 'status_code', width: '80px' },
  { title: 'Path', key: 'path', width: '280px' },
  { title: 'User', key: 'user_name', width: '150px' },
  { title: 'IP Address', key: 'ip_address', width: '130px' },
  { title: 'Timestamp', key: 'timestamp', width: '140px', sortable: true },
  { title: '', key: 'details', width: '80px', sortable: false },
]

/* ── Stats ── */
const statsCards = computed(() => {
  const list = logs.value
  return [
    { label: 'Total Events', value: list.length, icon: 'mdi-chart-line', color: '#6366f1', bg: 'rgba(99, 102, 241, 0.06)', textColor: '#4f46e5', subColor: '#6366f1' },
    { label: 'Warnings', value: list.filter((l) => l.priority === 'warning').length, icon: 'mdi-alert-circle', color: '#f59e0b', bg: 'rgba(245, 158, 11, 0.06)', textColor: '#d97706', subColor: '#f59e0b' },
    { label: 'Critical', value: list.filter((l) => l.priority === 'critical').length, icon: 'mdi-alert-octagon', color: '#ef4444', bg: 'rgba(239, 68, 68, 0.06)', textColor: '#dc2626', subColor: '#ef4444' },
    { label: 'Info', value: list.filter((l) => l.priority === 'info' || !l.priority).length, icon: 'mdi-information', color: '#10b981', bg: 'rgba(16, 185, 129, 0.06)', textColor: '#059669', subColor: '#10b981' },
  ]
})

/* ── Filtered logs ── */
const resourceOptions = computed(() => {
  const set = new Set(logs.value.map((l) => l.resource_type).filter(Boolean))
  return Array.from(set).sort()
})

const filteredLogs = computed(() => {
  let list = logs.value
  if (filterAction.value) list = list.filter((l) => l.action === filterAction.value)
  if (filterMethod.value) list = list.filter((l) => l.method === filterMethod.value)
  if (filterPriority.value) list = list.filter((l) => (l.priority || 'info') === filterPriority.value)
  if (filterResource.value) list = list.filter((l) => l.resource_type === filterResource.value)
  if (filterUser.value) list = list.filter((l) => String(l.user || '') === filterUser.value)
  if (search.value) {
    const q = search.value.toLowerCase()
    list = list.filter((l) =>
      (l.path || '').toLowerCase().includes(q) ||
      (l.resource_type || '').toLowerCase().includes(q) ||
      (l.user_name || '').toLowerCase().includes(q) ||
      (l.ip_address || '').toLowerCase().includes(q)
    )
  }
  return list
})

/* ── Load ── */
async function load() {
  loading.value = true
  try {
    const res = await $api('/audit/', { query: { page_size: 500 } })
    logs.value = res?.results || res || []
  } catch {
    logs.value = []
  } finally {
    loading.value = false
  }
}

function clearSearch() {
  search.value = ''
  load()
}

/* ── Watch filters ── */
watch([filterAction, filterMethod, filterResource, filterPriority], () => {
  page.value = 1
})
watch(filterUser, () => {
  page.value = 1
})

/* ── Show details ── */
function showDetails(item: any) {
  selectedLog.value = item
  detailsDialog.value = true
}

/* ── Export CSV ── */
function downloadCsv() {
  if (!filteredLogs.value.length) {
    $swal.fire({ icon: 'info', title: 'No data to export', toast: true, timer: 1500, position: 'top-end' })
    return
  }
  const cols = ['Action', 'Priority', 'Resource', 'Method', 'Status', 'Path', 'User', 'IP Address', 'Timestamp']
  const rows = filteredLogs.value.map((l) => [
    l.action || '',
    l.priority || 'info',
    l.resource_type || '',
    l.method || '',
    l.status_code || '',
    l.path || '',
    l.user_name || '',
    l.ip_address || '',
    l.timestamp ? new Date(l.timestamp).toISOString() : '',
  ])
  const csv = [cols, ...rows].map((r) => r.map((c) => `"${String(c).replace(/"/g, '""')}"`).join(',')).join('\n')
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `audit-logs-${new Date().toISOString().slice(0, 10)}.csv`
  a.click()
  URL.revokeObjectURL(url)
}

/* ── Helpers ── */
function actionColor(a: string): string {
  const map: Record<string, string> = {
    create: 'success', update: 'info', delete: 'error', login: 'primary', logout: 'warning', view: 'grey', export: 'secondary',
  }
  return map[a] || 'grey'
}
function actionIcon(a: string): string {
  const map: Record<string, string> = {
    create: 'mdi-plus', update: 'mdi-pencil', delete: 'mdi-delete', login: 'mdi-login', logout: 'mdi-logout', view: 'mdi-eye', export: 'mdi-download',
  }
  return map[a] || 'mdi-circle-small'
}
function methodColor(m: string): string {
  const map: Record<string, string> = { POST: 'success', PUT: 'info', PATCH: 'warning', DELETE: 'error', GET: 'grey' }
  return map[m] || 'grey'
}
function priorityColor(p: string): string {
  const map: Record<string, string> = { info: 'success', warning: 'warning', critical: 'error' }
  return map[p] || 'success'
}
function priorityIcon(p: string): string {
  const map: Record<string, string> = { info: 'mdi-information', warning: 'mdi-alert', critical: 'mdi-alert-octagon' }
  return map[p] || 'mdi-information'
}
function statusColor(c: number): string {
  if (!c) return 'grey'
  if (c < 300) return 'success'
  if (c < 400) return 'info'
  if (c < 500) return 'warning'
  return 'error'
}
function formatRelative(ts: string): string {
  if (!ts) return '—'
  const diff = Date.now() - new Date(ts).getTime()
  if (diff < 60000) return 'just now'
  if (diff < 3600000) return `${Math.floor(diff / 60000)}m ago`
  if (diff < 86400000) return `${Math.floor(diff / 3600000)}h ago`
  if (diff < 604800000) return `${Math.floor(diff / 86400000)}d ago`
  return new Date(ts).toISOString().slice(0, 16).replace('T', ' ')
}

/* ── Init ── */
onMounted(load)
</script>

<style scoped>
pre {
  white-space: pre-wrap;
  word-break: break-all;
}
</style>
