<template>
  <div class="d-flex flex-column ga-4">
    <!-- Header -->
    <div class="d-flex align-center ga-3">
      <v-btn icon="mdi-arrow-left" variant="text" size="small" @click="navigateTo('/app/fuel')" />
      <h2 class="text-h5 font-weight-bold">Fraud Alerts</h2>
      <v-spacer />
      <v-select
        v-model="statusFilter"
        :items="statusFilterOptions"
        item-title="title"
        item-value="value"
        label="Status"
        density="compact"
        variant="outlined"
        hide-details
        style="max-width: 180px"
        @update:model-value="refreshList"
      />
    </div>

    <!-- Summary Cards -->
    <v-row dense>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5" :class="{ 'cursor-pointer border-primary': statusFilter === 'open' }" @click="filterByStatus('open')">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="error" size="small">mdi-alert-circle</v-icon><span class="text-caption text-medium-emphasis">Open</span></div>
          <p class="text-h5 font-weight-bold text-error">{{ summary?.open || 0 }}</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5" :class="{ 'cursor-pointer border-info': statusFilter === 'under_review' }" @click="filterByStatus('under_review')">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="info" size="small">mdi-magnify</v-icon><span class="text-caption text-medium-emphasis">Under Review</span></div>
          <p class="text-h5 font-weight-bold text-info">{{ summary?.under_review || 0 }}</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5" :class="{ 'cursor-pointer border-success': statusFilter === 'resolved' }" @click="filterByStatus('resolved')">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="success" size="small">mdi-check-circle</v-icon><span class="text-caption text-medium-emphasis">Resolved</span></div>
          <p class="text-h5 font-weight-bold text-success">{{ summary?.resolved || 0 }}</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5" :class="{ 'cursor-pointer border-grey': statusFilter === 'dismissed' }" @click="filterByStatus('dismissed')">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="grey" size="small">mdi-close-circle</v-icon><span class="text-caption text-medium-emphasis">Dismissed</span></div>
          <p class="text-h5 font-weight-bold text-grey">{{ summary?.dismissed || 0 }}</p>
        </v-card>
      </v-col>
    </v-row>

    <!-- Alerts List -->
    <v-card elevation="0" border class="overflow-hidden">
      <v-data-table
        :headers="headers"
        :items="alerts"
        :loading="pending"
        hover
        items-per-page="20"
      >
        <template #item.severity="{ value }">
          <v-chip :color="severityColor(value)" variant="flat" size="small">{{ value }}</v-chip>
        </template>
        <template #item.alert_type="{ value }">
          {{ formatAlertType(value) }}
        </template>
        <template #item.action_status="{ value }">
          <v-chip size="x-small" :color="statusChipColor(value)" variant="tonal">{{ formatStatus(value) }}</v-chip>
        </template>
        <template #item.vehicle_name="{ value }">
          <span class="text-caption text-medium-emphasis">{{ value }}</span>
        </template>
        <template #item.transaction_date="{ value }">
          <span class="text-caption">{{ formatDate(value) }}</span>
        </template>
        <template #item.actions="{ item }">
          <div class="d-flex ga-1">
            <template v-if="item.action_status === 'open'">
              <v-btn size="x-small" variant="tonal" color="info" @click="reviewAlert(item)">Review</v-btn>
              <v-btn size="x-small" variant="tonal" color="success" @click="resolveAlert(item)">Resolve</v-btn>
              <v-btn size="x-small" variant="tonal" color="warning" @click="dismissAlert(item)">Dismiss</v-btn>
            </template>
            <template v-else-if="item.action_status === 'under_review'">
              <v-btn size="x-small" variant="tonal" color="success" @click="resolveAlert(item)">Resolve</v-btn>
              <v-btn size="x-small" variant="tonal" color="warning" @click="dismissAlert(item)">Dismiss</v-btn>
              <v-btn size="x-small" variant="text" color="error" @click="reopenAlert(item)">Reopen</v-btn>
            </template>
            <template v-else-if="item.action_status === 'resolved'">
              <v-chip size="x-small" color="success" variant="tonal">Resolved</v-chip>
              <v-btn size="x-small" variant="text" color="error" @click="reopenAlert(item)">Reopen</v-btn>
            </template>
            <template v-else-if="item.action_status === 'dismissed'">
              <v-chip size="x-small" color="grey" variant="tonal">Dismissed</v-chip>
              <v-btn size="x-small" variant="text" color="info" @click="reopenAlert(item)">Reopen</v-btn>
            </template>
          </div>
        </template>
        <template #no-data>
          <div class="text-center py-12 text-medium-emphasis">
            <v-icon size="48" class="mb-3">mdi-shield-check-outline</v-icon>
            <p>No fraud alerts found.</p>
          </div>
        </template>
      </v-data-table>
    </v-card>

    <!-- Status Note Dialog -->
    <v-dialog v-model="noteDialogVisible" max-width="480">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-pencil-outline">{{ noteDialogTitle }}</AppModalHeader>
        <v-card-text class="pt-4">
          <v-textarea
            v-model="statusNote"
            label="Note (optional)"
            rows="3"
            placeholder="Add a note about this action..."
            hide-details="auto"
            variant="outlined"
          />
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="noteDialogVisible = false">Cancel</v-btn>
          <v-btn color="primary" @click="confirmAction" :loading="actionLoading">{{ confirmLabel }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
const { $api, $swal } = useNuxtApp()
const statusFilter = ref('')
const pending = ref(false)
const noteDialogVisible = ref(false)
const noteDialogTitle = ref('')
const confirmLabel = ref('')
const statusNote = ref('')
const actionLoading = ref(false)

const statusFilterOptions = [
  { title: 'All', value: '' },
  { title: 'Open', value: 'open' },
  { title: 'Under Review', value: 'under_review' },
  { title: 'Resolved', value: 'resolved' },
  { title: 'Dismissed', value: 'dismissed' },
]

let pendingAction: (() => Promise<void>) | null = null

const queryParams = computed(() => {
  const params: Record<string, string> = {}
  if (statusFilter.value) params.action_status = statusFilter.value
  return params
})

const { data: alertData, refresh } = useAsyncData(
  'fraud-alerts-page',
  () => $api('/fuel/fraud/', { query: queryParams.value }).catch(() => ({ results: [], count: 0 })),
  { default: () => ({ results: [], count: 0 }), watch: [queryParams] }
)
const alerts = computed(() => alertData.value?.results || [])

const { data: summaryRaw } = useAsyncData(
  'fraud-summary-page',
  () => $api('/fuel/fraud/summary/').catch(() => null),
  { default: () => null }
)
const summary = computed(() => {
  if (!summaryRaw.value) return { open: 0, under_review: 0, resolved: 0, dismissed: 0, total: 0, unresolved: 0 }
  const counts: Record<string, number> = { open: 0, under_review: 0, resolved: 0, dismissed: 0 }
  const byStatus = summaryRaw.value.by_status || []
  for (const s of byStatus) {
    counts[s.action_status] = s.count || 0
  }
  return {
    ...counts,
    total: summaryRaw.value.total || 0,
    unresolved: summaryRaw.value.unresolved || 0,
  }
})

function refreshList() {
  refresh()
}

function filterByStatus(status: string) {
  statusFilter.value = statusFilter.value === status ? '' : status
}

const headers = [
  { title: 'Severity', key: 'severity', width: '90px', sortable: true },
  { title: 'Type', key: 'alert_type', width: '160px', sortable: true },
  { title: 'Description', key: 'description' },
  { title: 'Status', key: 'action_status', width: '120px', sortable: true },
  { title: 'Vehicle', key: 'vehicle_name', width: '120px' },
  { title: 'Date', key: 'transaction_date', width: '120px', sortable: true },
  { title: 'Actions', key: 'actions', width: '200px', sortable: false },
]

function severityColor(severity: string) {
  const map: Record<string, string> = { critical: 'error', high: 'warning', medium: 'amber', low: 'info' }
  return map[severity] || 'default'
}
function statusChipColor(status: string) {
  const map: Record<string, string> = { open: 'error', under_review: 'info', resolved: 'success', dismissed: 'grey' }
  return map[status] || 'default'
}
function formatAlertType(type: string) {
  return type ? type.replace(/_/g, ' ').replace(/\b\w/g, (c: string) => c.toUpperCase()) : ''
}
function formatStatus(status: string) {
  return status ? status.replace(/_/g, ' ').replace(/\b\w/g, (c: string) => c.toUpperCase()) : ''
}
function formatDate(value: string) {
  const d = new Date(value)
  if (Number.isNaN(d.getTime())) return ''
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}

function promptNote(title: string, label: string, action: () => Promise<void>) {
  noteDialogTitle.value = title
  confirmLabel.value = label
  statusNote.value = ''
  pendingAction = action
  noteDialogVisible.value = true
}

async function confirmAction() {
  if (!pendingAction) return
  actionLoading.value = true
  try {
    await pendingAction()
    noteDialogVisible.value = false
    await refresh()
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Action failed', text: e?.data?.detail || e?.message || 'Something went wrong', timer: 3000 })
  } finally {
    actionLoading.value = false
    pendingAction = null
  }
}

function resolveAlert(alert: any) {
  promptNote('Resolve Alert', 'Resolve', async () => {
    await $api(`/fuel/fraud/${alert.id}/resolve/`, { method: 'POST', body: { status_note: statusNote.value } })
  })
}
function dismissAlert(alert: any) {
  promptNote('Dismiss Alert', 'Dismiss', async () => {
    await $api(`/fuel/fraud/${alert.id}/dismiss/`, { method: 'POST', body: { status_note: statusNote.value } })
  })
}
function reviewAlert(alert: any) {
  promptNote('Mark Under Review', 'Start Review', async () => {
    await $api(`/fuel/fraud/${alert.id}/review/`, { method: 'POST', body: { status_note: statusNote.value } })
  })
}
function reopenAlert(alert: any) {
  promptNote('Reopen Alert', 'Reopen', async () => {
    await $api(`/fuel/fraud/${alert.id}/reopen/`, { method: 'POST', body: { status_note: statusNote.value } })
  })
}
</script>

<style scoped>
.cursor-pointer {
  cursor: pointer;
  transition: border-color 0.15s ease;
}
.cursor-pointer:hover {
  filter: brightness(0.96);
}
</style>
