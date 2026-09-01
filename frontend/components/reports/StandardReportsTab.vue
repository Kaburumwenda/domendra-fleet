<template>
  <div class="d-flex flex-column ga-5">
    <!-- ── Header ── -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-3">
      <div>
        <h2 class="text-h6 font-weight-bold mb-1 section-heading">Standard Report Library</h2>
        <p class="text-body-2 text-medium-emphasis">Run pre-built fleet reports, schedule recurring exports, and download in PDF, Excel, or CSV format</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn variant="tonal" color="primary" prepend-icon="mdi-plus" size="small" @click="templateDialog = true">
          New Template
        </v-btn>
        <v-btn variant="tonal" prepend-icon="mdi-refresh" size="small" @click="refreshSchedules">
          Refresh
        </v-btn>
      </div>
    </div>

    <!-- ── Report Cards Grid ── -->
    <v-row dense>
      <v-col cols="12" md="6" lg="4" v-for="report in reportCards" :key="report.type">
        <v-card
          elevation="0"
          border
          rounded="lg"
          class="report-card pa-5 d-flex flex-column h-100"
          :class="{ 'report-loaded': !!reportData[report.type] }"
        >
          <!-- Card header -->
          <div class="d-flex align-center ga-3 mb-4">
            <div class="d-flex align-center justify-center report-icon-box" :style="{ background: report.bg }">
              <v-icon :color="report.color" size="small">{{ report.icon }}</v-icon>
            </div>
            <div class="flex-grow-1">
              <h3 class="text-subtitle-2 font-weight-bold section-heading">{{ report.title }}</h3>
              <p class="text-caption text-medium-emphasis">{{ report.desc }}</p>
            </div>
            <v-chip v-if="reportData[report.type]" size="x-small" variant="flat" color="success">
              <v-icon size="x-small" start>mdi-check</v-icon>
              {{ reportData[report.type].length }}
            </v-chip>
          </div>

          <!-- Days selector -->
          <div class="d-flex align-center ga-2 mb-3">
            <span class="text-caption text-medium-emphasis">Period:</span>
            <v-btn-group density="compact" variant="outlined">
              <v-btn
                v-for="d in periodOptions"
                :key="d"
                size="x-small"
                :variant="reportDays[report.type] === d ? 'flat' : 'text'"
                :color="reportDays[report.type] === d ? 'primary' : undefined"
                @click="changeDays(report.type, d)"
              >
                {{ d }}d
              </v-btn>
            </v-btn-group>
          </div>

          <!-- Preview table -->
          <div v-if="reportLoading[report.type]" class="d-flex justify-center align-center py-8">
            <v-progress-circular indeterminate size="32" color="primary" />
          </div>
          <div v-else-if="reportData[report.type]" class="mb-3 preview-table">
            <v-data-table
              :items="reportData[report.type]"
              :headers="getHeaders(report.type, reportData[report.type][0] || {})"
              density="compact"
              :items-per-page="5"
              class="rounded-lg"
              @click:row="() => openDetail(report)"
            >
              <template #item.cost_per_mile="{ value }">
                <span class="font-weight-bold" style="color: #16a34a">{{ currencySymbol }}{{ formatNum(value) }}</span>
              </template>
              <template #item.mpg="{ value }">
                <span class="font-weight-bold" :style="{ color: (value || 0) >= 15 ? '#16a34a' : '#f59e0b' }">{{ value }}</span>
              </template>
              <template #item.variance_pct="{ value }">
                <v-chip size="x-small" :color="(value || 0) >= 0 ? 'success' : 'error'" variant="tonal">
                  {{ value >= 0 ? '+' : '' }}{{ value }}%
                </v-chip>
              </template>
              <template #item.replacement_needed="{ value }">
                <v-icon :color="value ? 'error' : 'success'" size="small">
                  {{ value ? 'mdi-alert-circle' : 'mdi-check-circle' }}
                </v-icon>
              </template>
              <template #item.age="{ value }">
                <span :style="{ color: (value || 0) >= 10 ? '#dc2626' : (value || 0) >= 7 ? '#f59e0b' : '#475569' }">
                  {{ value }}y
                </span>
              </template>
            </v-data-table>
          </div>
          <div v-else class="text-center text-medium-emphasis py-6">
            <v-icon size="32" class="mb-1">mdi-chart-box-outline</v-icon>
            <p class="text-caption">Click Run to load data</p>
          </div>

          <v-spacer />

          <!-- Card actions -->
          <div class="d-flex align-center justify-space-between pt-3 border-t">
            <v-btn
              size="small"
              :variant="reportData[report.type] ? 'text' : 'flat'"
              :color="reportData[report.type] ? undefined : 'primary'"
              :prepend-icon="reportData[report.type] ? 'mdi-refresh' : 'mdi-play'"
              :loading="reportLoading[report.type]"
              @click="loadReport(report.type)"
            >
              {{ reportData[report.type] ? 'Reload' : 'Run Report' }}
            </v-btn>
            <div class="d-flex align-center ga-1">
              <v-tooltip location="top" text="View Details">
                <template #activator="{ props: p }">
                  <v-btn v-bind="p" icon="mdi-eye-outline" size="small" variant="text" color="info"
                    :disabled="!reportData[report.type]" @click="openDetail(report)" />
                </template>
              </v-tooltip>
              <v-tooltip location="top" text="Export CSV">
                <template #activator="{ props: p }">
                  <v-btn v-bind="p" icon="mdi-file-document-outline" size="small" variant="text"
                    :disabled="!reportData[report.type]" @click="exportReport(report.type, 'csv')" />
                </template>
              </v-tooltip>
              <v-tooltip location="top" text="Export Excel">
                <template #activator="{ props: p }">
                  <v-btn v-bind="p" icon="mdi-file-excel-outline" size="small" variant="text" color="success"
                    :disabled="!reportData[report.type]" @click="exportReport(report.type, 'excel')" />
                </template>
              </v-tooltip>
              <v-tooltip location="top" text="Export PDF">
                <template #activator="{ props: p }">
                  <v-btn v-bind="p" icon="mdi-file-pdf-box" size="small" variant="text" color="error"
                    :disabled="!reportData[report.type]" @click="exportReport(report.type, 'pdf')" />
                </template>
              </v-tooltip>
            </div>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <!-- ── Scheduled Reports Section ── -->
    <div class="d-flex flex-column ga-3">
      <div class="d-flex align-center justify-space-between">
        <div class="d-flex align-center ga-2">
          <v-icon color="primary" size="small">mdi-calendar-clock</v-icon>
          <h3 class="text-subtitle-1 font-weight-bold section-heading">Scheduled Reports</h3>
          <v-chip v-if="activeCount" size="small" variant="tonal" color="success">{{ activeCount }} active</v-chip>
        </div>
        <v-btn variant="flat" color="primary" prepend-icon="mdi-plus" size="small" @click="openScheduleDialog()">
          Schedule Report
        </v-btn>
      </div>

      <v-card elevation="0" border rounded="lg" class="overflow-hidden">
        <v-data-table
          :headers="scheduleHeaders"
          :items="schedules"
          :loading="schedulePending"
          hover
          density="comfortable"
        >
          <template #item.template_name="{ value }">
            <div class="d-flex align-center ga-2">
              <v-icon size="small" color="primary">mdi-file-chart-outline</v-icon>
              <span class="font-weight-medium">{{ value || '—' }}</span>
            </div>
          </template>
          <template #item.frequency="{ value }">
            <v-chip :color="freqColor(value)" variant="tonal" size="small" class="text-capitalize">
              <v-icon size="x-small" start>{{ freqIcon(value) }}</v-icon>
              {{ value }}
            </v-chip>
          </template>
          <template #item.format="{ value }">
            <span class="text-caption font-weight-bold text-uppercase format-badge" :style="{ color: fmtColor(value) }">
              {{ value }}
            </span>
          </template>
          <template #item.recipients="{ value }">
            <span class="text-body-2">{{ value ? (value.split(',').length + ' recipients') : '—' }}</span>
          </template>
          <template #item.next_run="{ value }">
            <span v-if="value" class="text-body-2">{{ formatDate(value) }}</span>
            <span v-else class="text-caption text-medium-emphasis">—</span>
          </template>
          <template #item.last_run="{ value }">
            <span v-if="value" class="text-caption text-medium-emphasis">{{ formatDate(value) }}</span>
            <span v-else class="text-caption text-medium-emphasis">never</span>
          </template>
          <template #item.is_active="{ value, item }">
            <v-switch
              :model-value="value"
              color="success"
              density="compact"
              hide-details
              @update:model-value="toggleSchedule(item.id, !value)"
            />
          </template>
          <template #item.actions="{ item }">
            <div class="d-flex align-center ga-1">
              <v-tooltip location="top" text="View"><template #activator="{ props: p }"><v-btn v-bind="p" icon="mdi-eye-outline" size="small" variant="text" color="info" @click="viewSchedule(item)" /></template></v-tooltip>
              <v-tooltip location="top" text="Edit"><template #activator="{ props: p }"><v-btn v-bind="p" icon="mdi-pencil-outline" size="small" variant="text" color="primary" @click="editSchedule(item)" /></template></v-tooltip>
              <v-tooltip location="top" text="Delete"><template #activator="{ props: p }"><v-btn v-bind="p" icon="mdi-delete-outline" size="small" variant="text" color="error" @click="deleteSchedule(item)" /></template></v-tooltip>
            </div>
          </template>
          <template #no-data>
            <div class="text-center py-10">
              <v-icon size="48" class="mb-2" color="grey-lighten-1">mdi-calendar-blank-outline</v-icon>
              <p class="text-body-2 text-medium-emphasis mb-2">No scheduled reports yet</p>
              <v-btn variant="tonal" color="primary" size="small" prepend-icon="mdi-plus" @click="scheduleDialog = true">
                Schedule your first report
              </v-btn>
            </div>
          </template>
        </v-data-table>
      </v-card>
    </div>

    <!-- ── Execution History ── -->
    <div v-if="executions.length" class="d-flex flex-column ga-3">
      <div class="d-flex align-center ga-2">
        <v-icon color="primary" size="small">mdi-history</v-icon>
        <h3 class="text-subtitle-1 font-weight-bold section-heading">Execution History</h3>
      </div>
      <v-card elevation="0" border rounded="lg" class="overflow-hidden">
        <v-data-table
          :headers="executionHeaders"
          :items="executions"
          density="compact"
          :items-per-page="5"
          hover
        >
          <template #item.status="{ value }">
            <v-chip size="small" variant="tonal" :color="value === 'completed' ? 'success' : value === 'failed' ? 'error' : 'warning'">
              <v-icon size="x-small" start>
                {{ value === 'completed' ? 'mdi-check-circle' : value === 'failed' ? 'mdi-alert-circle' : 'mdi-clock-outline' }}
              </v-icon>
              {{ value }}
            </v-chip>
          </template>
          <template #item.started_at="{ value }">{{ formatDate(value) }}</template>
          <template #item.file="{ value }">
            <v-btn v-if="value" icon="mdi-download" size="small" variant="text" color="primary" @click="downloadExecution(value)" />
            <span v-else class="text-caption text-medium-emphasis">—</span>
          </template>
        </v-data-table>
      </v-card>
    </div>

    <!-- ── Schedule Dialog ── -->
    <v-dialog v-model="scheduleDialog" max-width="560">
      <v-card rounded="xl" class="pa-2">
        <AppModalHeader icon="mdi-calendar-clock" :title="editingScheduleId ? 'Edit Schedule' : 'Schedule Report'" />
        <v-card-text class="pa-5">
          <div class="d-flex flex-column ga-4">
            <v-select
              v-model="schedForm.template"
              :items="templateOptions"
              item-title="name"
              item-value="id"
              label="Report Template"
              variant="outlined"
              density="comfortable"
              prepend-inner-icon="mdi-file-chart-outline"
              :rules="[v => !!v || 'Select a template']"
            />
            <v-row dense>
              <v-col cols="6">
                <v-select
                  v-model="schedForm.frequency"
                  :items="freqOptions"
                  item-title="label"
                  item-value="value"
                  label="Frequency"
                  variant="outlined"
                  density="comfortable"
                />
              </v-col>
              <v-col cols="6">
                <v-select
                  v-model="schedForm.format"
                  :items="fmtOptions"
                  item-title="label"
                  item-value="value"
                  label="Format"
                  variant="outlined"
                  density="comfortable"
                />
              </v-col>
            </v-row>
            <v-text-field
              v-model="schedForm.recipients"
              label="Recipients (comma-separated emails)"
              variant="outlined"
              density="comfortable"
              prepend-inner-icon="mdi-email-multiple-outline"
              placeholder="user1@example.com, user2@example.com"
              hint="Reports will be emailed to these addresses on schedule"
              persistent-hint
            />
          </div>
        </v-card-text>
        <v-card-actions class="px-5 pb-5">
          <v-spacer />
          <v-btn variant="text" @click="scheduleDialog = false">Cancel</v-btn>
          <v-btn color="primary" variant="flat" :prepend-icon="editingScheduleId ? 'mdi-content-save' : 'mdi-check'" :loading="saving" @click="saveSchedule">
            {{ editingScheduleId ? 'Update Schedule' : 'Create Schedule' }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- ── View Schedule Dialog ── -->
    <v-dialog v-model="viewDialog" max-width="520">
      <v-card rounded="xl" class="pa-2">
        <AppModalHeader icon="mdi-eye-outline" title="Schedule Details" />
        <v-card-text v-if="viewingSchedule" class="pa-5">
          <div class="d-flex flex-column ga-3">
            <div class="d-flex justify-space-between">
              <span class="text-body-2 text-medium-emphasis">Report Template</span>
              <span class="text-body-2 font-weight-medium">{{ viewingSchedule.template_name || '—' }}</span>
            </div>
            <div class="d-flex justify-space-between">
              <span class="text-body-2 text-medium-emphasis">Frequency</span>
              <v-chip :color="freqColor(viewingSchedule.frequency)" variant="tonal" size="small" class="text-capitalize">
                <v-icon size="x-small" start>{{ freqIcon(viewingSchedule.frequency) }}</v-icon>
                {{ viewingSchedule.frequency }}
              </v-chip>
            </div>
            <div class="d-flex justify-space-between">
              <span class="text-body-2 text-medium-emphasis">Format</span>
              <span class="text-body-2 font-weight-bold text-uppercase">{{ viewingSchedule.format }}</span>
            </div>
            <div class="d-flex justify-space-between">
              <span class="text-body-2 text-medium-emphasis">Recipients</span>
              <span class="text-body-2 text-right" style="max-width: 250px; word-break: break-all">{{ viewingSchedule.recipients || '—' }}</span>
            </div>
            <v-divider />
            <div class="d-flex justify-space-between">
              <span class="text-body-2 text-medium-emphasis">Next Run</span>
              <span class="text-body-2 font-weight-medium">{{ formatDate(viewingSchedule.next_run) }}</span>
            </div>
            <div class="d-flex justify-space-between">
              <span class="text-body-2 text-medium-emphasis">Last Run</span>
              <span class="text-body-2 font-weight-medium">{{ viewingSchedule.last_run ? formatDate(viewingSchedule.last_run) : 'Never' }}</span>
            </div>
            <div class="d-flex justify-space-between">
              <span class="text-body-2 text-medium-emphasis">Status</span>
              <v-chip :color="viewingSchedule.is_active ? 'success' : 'grey'" variant="tonal" size="small">
                {{ viewingSchedule.is_active ? 'Active' : 'Paused' }}
              </v-chip>
            </div>
          </div>
        </v-card-text>
        <v-card-actions class="px-5 pb-5">
          <v-spacer />
          <v-btn variant="text" @click="viewDialog = false">Close</v-btn>
          <v-btn color="primary" variant="flat" prepend-icon="mdi-pencil" @click="viewDialog = false; editSchedule(viewingSchedule)">Edit</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- ── Template Dialog ── -->
    <v-dialog v-model="templateDialog" max-width="560">
      <v-card rounded="xl" class="pa-2">
        <AppModalHeader icon="mdi-file-plus-outline" title="New Report Template" />
        <v-card-text class="pa-5">
          <div class="d-flex flex-column ga-4">
            <v-text-field
              v-model="tmplForm.name"
              label="Template Name"
              variant="outlined"
              density="comfortable"
              prepend-inner-icon="mdi-form-textbox"
            />
            <v-select
              v-model="tmplForm.report_type"
              :items="reportTypeOptions"
              item-title="label"
              item-value="value"
              label="Report Type"
              variant="outlined"
              density="comfortable"
            />
            <v-textarea
              v-model="tmplForm.description"
              label="Description"
              variant="outlined"
              density="comfortable"
              rows="2"
            />
          </div>
        </v-card-text>
        <v-card-actions class="px-5 pb-5">
          <v-spacer />
          <v-btn variant="text" @click="templateDialog = false">Cancel</v-btn>
          <v-btn color="primary" variant="flat" prepend-icon="mdi-check" :loading="savingTemplate" @click="saveTemplate">
            Create Template
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- ── Report Detail Dialog ── -->
    <v-dialog v-model="detailDialog" max-width="80%" width="80vw">
      <v-card rounded="xl" class="pa-2">
        <AppModalHeader :icon="selectedReport?.icon || 'mdi-chart-box-outline'" :title="selectedReport?.title || 'Report'" />
        <v-card-text class="pa-5">
          <v-data-table
            v-if="selectedReport"
            :items="reportData[selectedReport.type] || []"
            :headers="getHeaders(selectedReport.type, (reportData[selectedReport.type] || [])[0] || {})"
            density="comfortable"
            :items-per-page="-1"
            class="rounded-lg"
          />
        </v-card-text>
        <v-card-actions class="px-5 pb-5">
          <v-spacer />
          <v-btn variant="text" @click="detailDialog = false">Close</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
const { $api, $swal } = useNuxtApp()
const config = useRuntimeConfig()
const auth = useAuthStore()
const { currencySymbol } = useCurrency()

const scheduleDialog = ref(false)
const templateDialog = ref(false)
const detailDialog = ref(false)
const viewDialog = ref(false)
const editingScheduleId = ref<number | null>(null)
const viewingSchedule = ref<any>(null)
const saving = ref(false)
const savingTemplate = ref(false)
const selectedReport = ref<any>(null)
const reportData = reactive<Record<string, any[]>>({})
const reportLoading = reactive<Record<string, boolean>>({})
const reportDays = reactive<Record<string, number>>({
  'cost-per-mile': 90, 'fuel-efficiency': 90, 'mechanic-utilization': 90,
  'fleet-aging': 90, 'benchmark': 90,
})

const periodOptions = [30, 90, 180, 365]

const reportCards = [
  { type: 'cost-per-mile', title: 'Cost per Mile', desc: 'Fuel and service cost per mile by vehicle', icon: 'mdi-currency-usd', bg: 'rgba(34,197,94,0.12)', color: 'success' },
  { type: 'fuel-efficiency', title: 'Fuel Efficiency', desc: 'MPG, fuel volume, and cost analysis', icon: 'mdi-gauge', bg: 'rgba(59,130,246,0.12)', color: 'info' },
  { type: 'mechanic-utilization', title: 'Mechanic Utilization', desc: 'Hours, work orders, and turnaround time', icon: 'mdi-account-group', bg: 'rgba(168,85,247,0.12)', color: 'purple' },
  { type: 'fleet-aging', title: 'Fleet Aging', desc: 'Age, book value, and replacement forecast', icon: 'mdi-calendar-alert', bg: 'rgba(245,158,11,0.12)', color: 'warning' },
  { type: 'benchmark', title: 'Fleet Benchmark', desc: 'Compare each vehicle vs fleet average', icon: 'mdi-chart-line', bg: 'rgba(99,102,241,0.12)', color: 'indigo' },
]

const reportTypeOptions = [
  { label: 'Cost per Mile', value: 'cost_per_mile' },
  { label: 'Fuel Efficiency', value: 'fuel_efficiency' },
  { label: 'Mechanic Utilization', value: 'mechanic_utilization' },
  { label: 'Fleet Aging', value: 'fleet_aging' },
  { label: 'Cost Summary', value: 'cost_summary' },
  { label: 'Custom Report', value: 'custom' },
]

const scheduleHeaders = [
  { title: 'Report', key: 'template_name', sortable: true },
  { title: 'Frequency', key: 'frequency', width: 120, sortable: true },
  { title: 'Format', key: 'format', width: 90 },
  { title: 'Recipients', key: 'recipients', width: 140 },
  { title: 'Next Run', key: 'next_run', width: 130, sortable: true },
  { title: 'Last Run', key: 'last_run', width: 130 },
  { title: 'Active', key: 'is_active', width: 70, align: 'center' as const },
  { title: '', key: 'actions', width: 120, align: 'center' as const },
]

const executionHeaders = [
  { title: 'Report', key: 'template_name', sortable: true },
  { title: 'Status', key: 'status', width: 120 },
  { title: 'Started', key: 'started_at', width: 140 },
  { title: 'Completed', key: 'completed_at', width: 140 },
  { title: 'File', key: 'file', width: 70, align: 'center' as const },
]

const freqOptions = [
  { label: 'Daily', value: 'daily' },
  { label: 'Weekly', value: 'weekly' },
  { label: 'Monthly', value: 'monthly' },
  { label: 'Quarterly', value: 'quarterly' },
]
const fmtOptions = [
  { label: 'PDF', value: 'pdf' },
  { label: 'Excel', value: 'excel' },
  { label: 'CSV', value: 'csv' },
]

const schedForm = reactive<any>({ template: null, frequency: 'monthly', format: 'pdf', recipients: '' })
const tmplForm = reactive<any>({ name: '', report_type: 'cost_per_mile', description: '' })

// ── Data fetching ──
const { data: templatesData, refresh: refreshTemplates } = useAsyncData(
  'rpt-templates',
  () => $api('/reports/templates/').catch(() => ({ results: [] })),
  { default: () => ({ results: [] }) }
)
const templates = computed(() => templatesData.value?.results || [])
const templateOptions = computed(() => templates.value)

const { data: scheduleData, pending: schedulePending, refresh: refreshSchedules } = useAsyncData(
  'rpt-schedules',
  () => $api('/reports/schedules/').catch(() => ({ results: [] })),
  { default: () => ({ results: [] }) }
)
const schedules = computed(() => scheduleData.value?.results || [])
const activeCount = computed(() => schedules.value.filter((s: any) => s.is_active).length)

const { data: executionData, refresh: refreshExecutions } = useAsyncData(
  'rpt-executions',
  () => $api('/reports/executions/').catch(() => ({ results: [] })),
  { default: () => ({ results: [] }) }
)
const executions = computed(() => executionData.value?.results || [])

async function loadReport(type: string) {
  reportLoading[type] = true
  try {
    const days = reportDays[type] || 90
    const data = await $api(`/reports/standard/${type}/`, { query: { days } })
    reportData[type] = data
  } catch (e: any) {
    $swal?.fire?.({ icon: 'error', title: 'Failed to load report', toast: true, timer: 2000, position: 'top-end' })
  } finally {
    reportLoading[type] = false
  }
}

function changeDays(type: string, days: number) {
  reportDays[type] = days
  loadReport(type)
}

function openDetail(report: any) {
  selectedReport.value = report
  detailDialog.value = true
}

function exportReport(type: string, format: string) {
  const days = reportDays[type] || 90
  const url = `${config.public.apiBase}/reports/export/?type=${type}&format=${format}&days=${days}`
  fetch(url, {
    headers: {
      Authorization: `Bearer ${auth.accessToken}`,
      'x-tenant-schema': auth.tenantSchema,
    },
  })
    .then((r) => {
      if (!r.ok) throw new Error('Export failed')
      return r.blob()
    })
    .then((blob) => {
      const a = document.createElement('a')
      a.href = URL.createObjectURL(blob)
      a.download = `${type}_${new Date().toISOString().slice(0, 10)}.${format === 'excel' ? 'xlsx' : format}`
      a.click()
      URL.revokeObjectURL(a.href)
      $swal?.fire?.({ icon: 'success', title: 'Export downloaded', toast: true, timer: 2000, position: 'top-end' })
    })
    .catch(() => {
      $swal?.fire?.({ icon: 'error', title: 'Export failed', toast: true, timer: 2500, position: 'top-end' })
    })
}

function downloadExecution(url: string) {
  const fullUrl = url.startsWith('http') ? url : `${config.public.apiBase}${url}`
  fetch(fullUrl, {
    headers: { Authorization: `Bearer ${auth.accessToken}`, 'x-tenant-schema': auth.tenantSchema },
  })
    .then((r) => r.blob())
    .then((blob) => {
      const a = document.createElement('a')
      a.href = URL.createObjectURL(blob)
      a.download = url.split('/').pop() || 'report'
      a.click()
      URL.revokeObjectURL(a.href)
    })
}

async function saveSchedule() {
  if (!schedForm.template) {
    $swal?.fire?.({ icon: 'warning', title: 'Select a template first', text: 'Create a template using the New Template button if none are available.', toast: true, timer: 3000, position: 'top-end' })
    return
  }
  saving.value = true
  try {
    const payload = { ...schedForm, template: Number(schedForm.template) }
    if (editingScheduleId.value) {
      await $api(`/reports/schedules/${editingScheduleId.value}/`, { method: 'PATCH', body: payload })
      $swal?.fire?.({ icon: 'success', title: 'Schedule updated', toast: true, timer: 2000, position: 'top-end' })
    } else {
      await $api('/reports/schedules/', { method: 'POST', body: payload })
      $swal?.fire?.({ icon: 'success', title: 'Report scheduled', toast: true, timer: 2000, position: 'top-end' })
    }
    scheduleDialog.value = false
    editingScheduleId.value = null
    schedForm.template = null
    schedForm.recipients = ''
    await refreshSchedules()
  } catch (e: any) {
    $swal?.fire?.({ icon: 'error', title: e?.data?.detail || 'Failed to save schedule', toast: true, timer: 2500, position: 'top-end' })
  } finally { saving.value = false }
}

function openScheduleDialog() {
  editingScheduleId.value = null
  schedForm.template = null
  schedForm.frequency = 'monthly'
  schedForm.format = 'pdf'
  schedForm.recipients = ''
  scheduleDialog.value = true
}

function editSchedule(item: any) {
  editingScheduleId.value = item.id
  schedForm.template = item.template
  schedForm.frequency = item.frequency
  schedForm.format = item.format
  schedForm.recipients = item.recipients || ''
  scheduleDialog.value = true
}

function viewSchedule(item: any) {
  viewingSchedule.value = item
  viewDialog.value = true
}

async function saveTemplate() {
  if (!tmplForm.name) {
    $swal?.fire?.({ icon: 'warning', title: 'Enter a name', toast: true, timer: 2000, position: 'top-end' })
    return
  }
  savingTemplate.value = true
  try {
    await $api('/reports/templates/', { method: 'POST', body: tmplForm })
    templateDialog.value = false
    tmplForm.name = ''
    tmplForm.description = ''
    await refreshTemplates()
    $swal?.fire?.({ icon: 'success', title: 'Template created', toast: true, timer: 2000, position: 'top-end' })
  } catch (e: any) {
    $swal?.fire?.({ icon: 'error', title: e?.data?.detail || 'Failed to create template', toast: true, timer: 2500, position: 'top-end' })
  } finally { savingTemplate.value = false }
}

async function toggleSchedule(id: number, active: boolean) {
  try {
    await $api(`/reports/schedules/${id}/`, { method: 'PATCH', body: { is_active: active } })
    await refreshSchedules()
    $swal?.fire?.({
      icon: 'success',
      title: active ? 'Schedule activated' : 'Schedule paused',
      toast: true, timer: 1500, position: 'top-end',
    })
  } catch {
    $swal?.fire?.({ icon: 'error', title: 'Failed to update', toast: true, timer: 2000, position: 'top-end' })
  }
}

async function deleteSchedule(item: any) {
  const r = await $swal?.fire?.({
    icon: 'warning',
    title: 'Delete this schedule?',
    text: `"${item.template_name}" will no longer be sent automatically.`,
    showCancelButton: true,
    confirmButtonText: 'Delete',
    confirmButtonColor: '#dc2626',
  })
  if (!r?.isConfirmed) return
  try {
    await $api(`/reports/schedules/${item.id}/`, { method: 'DELETE' })
    await refreshSchedules()
    $swal?.fire?.({ icon: 'success', title: 'Schedule deleted', toast: true, timer: 1500, position: 'top-end' })
  } catch {
    $swal?.fire?.({ icon: 'error', title: 'Failed to delete', toast: true, timer: 2000, position: 'top-end' })
  }
}

// ── Helpers ──
function getHeaders(type: string, sample: Record<string, any>): any[] {
  const keys = Object.keys(sample)
  if (!keys.length) return []
  const customLabels: Record<string, string> = {
    cost_per_mile: 'Cost/Mile',
    total_cost: 'Total Cost',
    fuel_cost: 'Fuel Cost',
    service_cost: 'Service Cost',
    total_gallons: 'Gallons',
    avg_price: 'Avg Price',
    total_miles: 'Miles',
    total_hours: 'Hours',
    work_order_count: 'WOs',
    avg_turnaround_hours: 'Avg Turnaround',
    book_value: 'Book Value',
    annual_depreciation: 'Depreciation',
    replacement_needed: 'Replace?',
    fleet_avg_cost: 'Fleet Avg',
    variance_pct: 'Variance',
  }
  return keys.map((k) => ({
    title: customLabels[k] || k.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase()),
    key: k,
    align: typeof sample[k] === 'number' ? ('end' as const) : ('start' as const),
    sortable: true,
  }))
}

function freqColor(f: string): string {
  return { daily: 'info', weekly: 'primary', monthly: 'success', quarterly: 'warning' }[f] || 'grey'
}
function freqIcon(f: string): string {
  return { daily: 'mdi-calendar-today', weekly: 'mdi-calendar-week', monthly: 'mdi-calendar-month', quarterly: 'mdi-calendar-star' }[f] || ' mdi-calendar'
}
function fmtColor(f: string): string {
  return { pdf: '#dc2626', excel: '#16a34a', csv: '#64748b' }[f] || '#64748b'
}

function formatDate(d: string): string {
  if (!d) return '—'
  return new Date(d).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
}

function formatNum(n: number | undefined): string {
  if (!n) return '0'
  if (n < 1 && n > 0) return n.toFixed(4)
  return Math.round(n).toLocaleString()
}

onMounted(() => {
  loadReport('cost-per-mile')
  loadReport('fuel-efficiency')
  loadReport('mechanic-utilization')
  loadReport('fleet-aging')
  loadReport('benchmark')
})
</script>

<style scoped>
.section-heading { color: #1e293b; }

.report-card {
  transition: border-color 0.2s, box-shadow 0.2s;
}
.report-loaded {
  border-color: rgba(99, 102, 241, 0.3) !important;
}

.report-icon-box {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.border-t {
  border-top: 1px solid #e2e8f0;
}

.preview-table {
  border-radius: 8px;
  overflow: hidden;
}

.format-badge {
  letter-spacing: 0.5px;
}

.v-theme--dark .section-heading { color: #e2e8f0; }
.v-theme--dark .border-t { border-color: rgba(255,255,255,0.08) !important; }
.v-theme--dark .report-loaded { border-color: rgba(99, 102, 241, 0.2) !important; }
</style>
