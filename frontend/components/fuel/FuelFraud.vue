<template>
  <div class="d-flex flex-column ga-4">
    <!-- Summary Cards -->
    <v-row dense>
      <v-col cols="6" md="3" v-for="card in statusCards" :key="card.key">
        <v-card elevation="0" border class="pa-5" :class="{ ['cursor-pointer border-' + card.color]: statusFilter === card.value }" style="cursor: pointer" @click="filterByStatus(card.value)">
          <div class="d-flex align-center ga-2 mb-2"><v-icon :color="card.color" size="small">{{ card.icon }}</v-icon><span class="text-caption text-medium-emphasis">{{ card.label }}</span></div>
          <p class="text-h5 font-weight-bold" :class="'text-' + card.color">{{ card.count }}</p>
        </v-card>
      </v-col>
    </v-row>

    <!-- Severity breakdown -->
    <v-row dense v-if="(summary?.by_type || []).length">
      <v-col cols="12">
        <DashboardChart :option="byTypeOption" title="Fraud Alerts by Type" icon="mdi-shield-alert-outline" height="220px" />
      </v-col>
    </v-row>

    <!-- Alerts List -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-2">
      <v-select v-model="statusFilter" :items="statusFilterOptions" item-title="title" item-value="value" label="Status" density="compact" variant="outlined" hide-details style="max-width: 180px" @update:model-value="refreshList" />
      <span class="text-caption text-medium-emphasis">{{ alerts.length }} alerts</span>
    </div>

    <v-card v-if="alerts.length" elevation="0" border class="pa-5 overflow-hidden">
      <div class="d-flex flex-column ga-2">
        <div v-for="alert in alerts" :key="alert.id"
          class="d-flex align-center justify-space-between pa-3 rounded-lg"
          :style="{ background: alert.severity === 'critical' ? '#fef2f2' : alert.severity === 'high' ? '#fff7ed' : '#fffbeb' }"
        >
          <div class="d-flex align-center ga-3">
            <v-chip :color="severityColor(alert.severity)" variant="flat" size="small">{{ alert.severity }}</v-chip>
            <div>
              <p class="text-body-2 font-weight-medium" style="color: #1e293b">{{ formatAlertType(alert.alert_type) }}</p>
              <p class="text-caption text-medium-emphasis">{{ alert.description }}</p>
              <div class="d-flex align-center ga-2 mt-1">
                <v-chip size="x-small" :color="statusChipColor(alert.action_status)" variant="tonal">{{ alert.action_status_display || formatAlertType(alert.action_status) }}</v-chip>
                <span class="text-caption text-medium-emphasis">{{ alert.vehicle_name }}</span>
              </div>
            </div>
          </div>
          <div class="d-flex align-center ga-1 flex-shrink-0">
            <template v-if="alert.action_status === 'open'">
              <v-btn size="small" variant="tonal" color="info" @click="doReview(alert)">Review</v-btn>
              <v-btn size="small" variant="tonal" color="success" @click="doResolve(alert)">Resolve</v-btn>
              <v-btn size="small" variant="tonal" color="warning" @click="doDismiss(alert)">Dismiss</v-btn>
            </template>
            <template v-else-if="alert.action_status === 'under_review'">
              <v-btn size="small" variant="tonal" color="success" @click="doResolve(alert)">Resolve</v-btn>
              <v-btn size="small" variant="tonal" color="warning" @click="doDismiss(alert)">Dismiss</v-btn>
              <v-btn size="small" variant="text" color="error" @click="doReopen(alert)">Reopen</v-btn>
            </template>
            <template v-else-if="alert.action_status === 'resolved'">
              <v-icon color="success" size="small">mdi-check-circle-outline</v-icon>
              <v-btn size="small" variant="text" color="error" @click="doReopen(alert)">Reopen</v-btn>
            </template>
            <template v-else>
              <v-icon color="grey" size="small">mdi-close-circle-outline</v-icon>
              <v-btn size="small" variant="text" color="info" @click="doReopen(alert)">Reopen</v-btn>
            </template>
          </div>
        </div>
      </div>
    </v-card>

    <v-card v-else elevation="0" border class="pa-12 text-center text-medium-emphasis">
      <v-icon size="48" class="mb-3">mdi-shield-check-outline</v-icon>
      <p>No fraud alerts in this view.</p>
    </v-card>

    <!-- Note dialog -->
    <v-dialog v-model="noteDialogVisible" max-width="480">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-pencil-outline">{{ noteDialogTitle }}</AppModalHeader>
        <v-card-text class="pt-4">
          <v-textarea v-model="statusNote" label="Note (optional)" rows="3" placeholder="Add a note about this action..." hide-details="auto" variant="outlined" />
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
import * as echarts from 'echarts/core'
import { setupECharts } from '~/utils/echarts'
import { useDarkMode } from '~/composables/useDarkMode'

setupECharts()

const { fetchFraud, fetchFraudSummary, resolveFraud, dismissFraud, reviewFraud, reopenFraud } = useFuelApi()
const { severityColor, statusChipColor, formatAlertType } = useFuelHelpers()

const { isDark } = useDarkMode()
const axisLabelColor = computed(() => isDark.value ? '#94a3b8' : '#64748b')

const statusFilter = ref('')
const noteDialogVisible = ref(false)
const noteDialogTitle = ref('')
const confirmLabel = ref('Confirm')
const statusNote = ref('')
const actionLoading = ref(false)
let pendingAction: (() => Promise<void>) | null = null

const statusFilterOptions = [
  { title: 'All', value: '' },
  { title: 'Open', value: 'open' },
  { title: 'Under Review', value: 'under_review' },
  { title: 'Resolved', value: 'resolved' },
  { title: 'Dismissed', value: 'dismissed' },
]

const queryParams = computed(() => {
  const params: Record<string, string> = {}
  if (statusFilter.value) params.action_status = statusFilter.value
  if (statusFilter.value !== 'resolved' && statusFilter.value !== 'dismissed') params.is_resolved = 'false'
  return params
})

const { data: alertData, refresh } = useAsyncData(
  'fuel-fraud-tab',
  () => fetchFraud(queryParams.value).catch(() => ({ results: [] })) as Promise<any>,
  { default: () => ({ results: [] }), watch: [queryParams] }
)
const alerts = computed(() => alertData.value?.results || [])

const { data: summaryRaw } = useAsyncData(
  'fuel-fraud-summary-tab',
  () => fetchFraudSummary().catch(() => null),
  { default: () => null }
)
const summary = computed(() => summaryRaw.value)

const statusCards = computed(() => {
  const byStatus = summary.value?.by_status || []
  const counts: Record<string, number> = { open: 0, under_review: 0, resolved: 0, dismissed: 0 }
  for (const s of byStatus) counts[s.action_status] = s.count || 0
  return [
    { key: 'open', label: 'Open', value: 'open', icon: 'mdi-alert-circle', color: 'error', count: counts.open },
    { key: 'review', label: 'Under Review', value: 'under_review', icon: 'mdi-magnify', color: 'info', count: counts.under_review },
    { key: 'resolved', label: 'Resolved', value: 'resolved', icon: 'mdi-check-circle', color: 'success', count: counts.resolved },
    { key: 'dismissed', label: 'Dismissed', value: 'dismissed', icon: 'mdi-close-circle', color: 'grey', count: counts.dismissed },
  ]
})

function filterByStatus(status: string) {
  statusFilter.value = statusFilter.value === status ? '' : status
}
function refreshList() { refresh() }

function openNote(title: string, label: string, action: () => Promise<void>) {
  noteDialogTitle.value = title
  confirmLabel.value = label
  statusNote.value = ''
  pendingAction = action
  noteDialogVisible.value = true
}
async function confirmAction() {
  if (!pendingAction) return
  actionLoading.value = true
  try { await pendingAction(); noteDialogVisible.value = false; refresh() } finally { actionLoading.value = false }
}

async function doResolve(a: any) {
  openNote('Resolve Alert', 'Resolve', async () => { await resolveFraud(a.id, statusNote.value); a.action_status = 'resolved'; a.is_resolved = true })
}
async function doDismiss(a: any) {
  openNote('Dismiss Alert', 'Dismiss', async () => { await dismissFraud(a.id, statusNote.value); a.action_status = 'dismissed' })
}
async function doReview(a: any) {
  openNote('Review Alert', 'Mark Under Review', async () => { await reviewFraud(a.id, statusNote.value); a.action_status = 'under_review' })
}
async function doReopen(a: any) {
  openNote('Reopen Alert', 'Reopen', async () => { await reopenFraud(a.id, statusNote.value); a.action_status = 'open'; a.is_resolved = false })
}

const byTypeOption = computed(() => {
  const data = (summary.value?.by_type || []).map((t: any) => ({
    name: formatAlertType(t.alert_type),
    value: t.count,
  }))
  return {
    tooltip: { trigger: 'item' },
    grid: { left: 10, right: 10, top: 10, bottom: 10 },
    series: [{
      type: 'pie', radius: ['35%', '65%'], center: ['50%', '50%'],
      label: { color: axisLabelColor.value, fontSize: 11, formatter: '{b}: {c}' },
      data,
      color: ['#ef4444', '#f59e0b', '#f97316', '#eab308', '#6366f1', '#8b5cf6'],
    }],
  }
})
</script>
