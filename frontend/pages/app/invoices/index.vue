<template>
  <div class="d-flex flex-column ga-4">
    <!-- Header -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-2">
      <div>
        <h1 class="text-h5 font-weight-bold" style="color: #1e293b">Invoices</h1>
        <p class="text-caption text-medium-emphasis">Generate and manage invoices from rental agreements</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn v-can="'billing:view'" color="teal" prepend-icon="mdi-file-document-edit-outline" size="small" variant="tonal" @click="navigateTo('/app/invoices/custom')">Customized Invoice</v-btn>
        <v-btn v-can="'billing:view'" color="indigo" prepend-icon="mdi-file-document-multiple-plus-outline" size="small" variant="tonal" @click="navigateTo('/app/invoices/multi')">Consolidated Invoice</v-btn>
        <v-btn v-can="'billing:view'" color="primary" prepend-icon="mdi-plus" size="small" @click="generateDialog = true">Generate from Agreement</v-btn>
      </div>
    </div>

    <!-- KPI Row -->
    <v-row dense>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #6366f1 0%, #818cf8 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-file-document-multiple-outline</v-icon><span style="color:#fff; font-size:0.75rem; font-weight:500">Total Invoices</span></div>
          <p class="text-h4 font-weight-bold" style="color:#fff !important">{{ stats.total }}</p>
          <p style="color:#fff; opacity:.85; font-size:0.75rem">{{ stats.draft }} draft · {{ stats.sent }} sent</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #10b981 0%, #34d399 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-check-circle</v-icon><span style="color:#fff; font-size:0.75rem; font-weight:500">Paid</span></div>
          <p class="text-h4 font-weight-bold" style="color:#fff !important">{{ stats.paid }}</p>
          <p style="color:#fff; opacity:.85; font-size:0.75rem">{{ stats.partially_paid }} partially paid</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-cash-clock</v-icon><span style="color:#fff; font-size:0.75rem; font-weight:500">Outstanding</span></div>
          <p class="text-h4 font-weight-bold" style="color:#fff !important">{{ currencySymbol }}{{ Number(stats.outstanding || 0).toLocaleString() }}</p>
          <p style="color:#fff; opacity:.85; font-size:0.75rem">Unpaid balance</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #ef4444 0%, #f87171 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-alert-circle</v-icon><span style="color:#fff; font-size:0.75rem; font-weight:500">Overdue</span></div>
          <p class="text-h4 font-weight-bold" style="color:#fff !important">{{ stats.overdue }}</p>
          <p style="color:#fff; opacity:.85; font-size:0.75rem">Past due date</p>
        </v-card>
      </v-col>
    </v-row>

    <!-- Search + Filter -->
    <div class="d-flex align-center ga-2 flex-wrap">
      <v-text-field v-model="search" density="compact" variant="outlined" prepend-inner-icon="mdi-magnify" placeholder="Search invoices…" hide-details style="max-width: 280px" />
      <v-select v-model="statusFilter" :items="statusOptions" item-title="label" item-value="value" density="compact" variant="outlined" label="Status" clearable hide-details style="max-width: 150px" />
      <v-select v-model="dateFilter" :items="dateFilterOptions" item-title="label" item-value="value" density="compact" variant="outlined" label="Date" hide-details style="max-width: 160px" @update:model-value="onDateFilterChange" />
      <template v-if="dateFilter === 'custom'">
        <v-text-field v-model="dateFrom" type="date" density="compact" variant="outlined" label="From" hide-details style="max-width: 150px" prepend-inner-icon="mdi-calendar-start" />
        <v-text-field v-model="dateTo" type="date" density="compact" variant="outlined" label="To" hide-details style="max-width: 150px" prepend-inner-icon="mdi-calendar-end" />
      </template>
      <v-spacer />
    </div>

    <!-- Invoice Table -->
    <v-card elevation="0" border rounded="lg">
      <v-data-table :headers="headers" :items="filteredInvoices" :loading="loading" hover items-per-page="15" v-model:page="page">
        <template #item.index="{ index }">
          <span class="text-caption text-medium-emphasis">{{ (page - 1) * 15 + index + 1 }}</span>
        </template>
        <template #item.invoice_no="{ value }">
          <span class="font-weight-bold" style="color: #4f46e5; font-family: 'JetBrains Mono', monospace; letter-spacing: 0.02em">{{ value }}</span>
        </template>
        <template #item.customer_name="{ item }">
          <div class="d-flex align-center ga-2">
            <v-avatar size="32" color="#eef2ff">
              <v-icon size="18" color="#4f46e5">mdi-account</v-icon>
            </v-avatar>
            <div>
              <div class="text-body-2 font-weight-medium" style="color:#1e293b">{{ item.customer_name || item.invoice_to?.name || '—' }}</div>
              <div v-if="item.invoice_to?.company" class="text-caption" style="color:#94a3b8">{{ item.invoice_to.company }}</div>
              <div v-else class="text-caption text-capitalize" style="color:#94a3b8">{{ item.customer_type }}</div>
            </div>
          </div>
        </template>
        <template #item.agreement_no="{ item, value }">
          <v-chip v-if="item.agreements && item.agreements.length > 1" size="small" color="indigo" variant="tonal" prepend-icon="mdi-file-document-multiple">{{ item.agreements.length }} agreements</v-chip>
          <span v-else class="text-body-2" style="color:#64748b; font-family: monospace">{{ value }}</span>
        </template>
        <template #item.status="{ value }">
          <v-chip size="small" :color="statusColor(value)" variant="flat" class="text-capitalize">{{ statusLabel(value) }}</v-chip>
        </template>
        <template #item.total_amount="{ value }">
          <span class="font-weight-bold" style="color:#1e293b">{{ currencySymbol }}{{ Number(value || 0).toLocaleString() }}</span>
        </template>
        <template #item.balance_due="{ value }">
          <span :class="Number(value) > 0 ? 'text-error font-weight-medium' : 'text-success'">{{ currencySymbol }}{{ Number(value || 0).toLocaleString() }}</span>
        </template>
        <template #item.issue_date="{ value }">
          <span style="white-space: nowrap">{{ formatDate(value) }}</span>
        </template>
        <template #item.actions="{ item }">
          <div class="d-flex ga-1">
            <v-btn icon="mdi-eye-outline" size="x-small" variant="text" color="primary" @click="viewInvoice(item)" />
            <v-btn v-can="'billing:export'" icon="mdi-download" size="x-small" variant="text" color="info" @click="downloadInvoice(item)" />
            <v-btn v-if="!item.agreement && !(item.agreements && item.agreements.length)" v-can="'billing:view'" icon=" mdi-file-document-edit-outline" size="x-small" variant="text" color="teal" @click="editInvoice(item)" />
            <v-btn v-else v-can="'billing:view'" icon="mdi-pencil-outline" size="x-small" variant="text" color="warning" @click="editInvoice(item)" />
          </div>
        </template>
      </v-data-table>
    </v-card>

    <!-- Generate from Agreement Dialog -->
    <v-dialog v-model="generateDialog" max-width="720">
      <v-card>
        <v-card-title class="text-h6 d-flex align-center ga-2">
          <v-icon color="primary">mdi-file-document-plus-outline</v-icon>
          Generate Invoice
        </v-card-title>
        <v-divider />
        <v-card-text class="pt-4">
          <v-autocomplete
            v-model="selectedAgreement"
            :items="agreementOptions"
            item-title="label"
            item-value="id"
            label="Select Rental Agreement"
            density="compact"
            variant="outlined"
            hide-details="auto"
            class="mb-3"
            clearable
            :loading="agreementsLoading"
          />
          <v-text-field
            v-model="generateDueDate"
            type="date"
            label="Due Date (optional)"
            density="compact"
            variant="outlined"
            hide-details="auto"
            class="mb-3"
          />
          <v-textarea
            v-model="generateNotes"
            label="Notes (optional)"
            density="compact"
            variant="outlined"
            hide-details="auto"
            rows="2"
          />
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn variant="text" @click="generateDialog = false">Cancel</v-btn>
          <v-btn color="primary" :loading="generating" :disabled="!selectedAgreement" @click="doGenerate">Generate Invoice</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Edit Dialog -->
    <v-dialog v-model="editDialog" max-width="500">
      <v-card>
        <v-card-title class="text-h6">Edit Invoice</v-card-title>
        <v-card-text v-if="editingItem">
          <v-select v-model="editingItem.status" :items="statusOptions" item-title="label" item-value="value" label="Status" density="compact" variant="outlined" hide-details="auto" class="mb-3" />
          <v-text-field v-model="editingItem.due_date" type="date" label="Due Date" density="compact" variant="outlined" hide-details="auto" class="mb-3" />
          <v-textarea v-model="editingItem.notes" label="Notes" density="compact" variant="outlined" hide-details="auto" rows="2" />
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn variant="text" @click="editDialog = false">Cancel</v-btn>
          <v-btn color="primary" :loading="saving" @click="saveEdit">Save</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- View Invoice Dialog -->
    <v-dialog v-model="viewDialog" max-width="720">
      <v-card v-if="viewingItem" rounded="lg">
        <v-card-title class="d-flex align-center justify-space-between">
          <span class="text-h6" style="color:#4f46e5;font-family:monospace">{{ viewingItem.invoice_no }}</span>
          <v-chip size="small" :color="statusColor(viewingItem.status)" variant="flat">{{ statusLabel(viewingItem.status) }}</v-chip>
        </v-card-title>
        <v-card-text>
          <v-row dense class="mb-2">
            <v-col cols="6"><div class="text-caption text-medium-emphasis">Customer</div><div class="text-body-1 font-weight-medium">{{ viewingItem.customer_name || '—' }}</div></v-col>
            <v-col cols="6">
              <div class="text-caption text-medium-emphasis">{{ viewingItem.agreements && viewingItem.agreements.length > 1 ? 'Agreements' : 'Agreement' }}</div>
              <div v-if="viewingItem.agreements && viewingItem.agreements.length > 1" class="d-flex flex-wrap ga-1 mt-1">
                <v-chip v-for="a in viewingItem.agreements" :key="a.id" size="x-small" color="indigo" variant="tonal" style="font-family:monospace">{{ a.agreement_no }}</v-chip>
              </div>
              <div v-else class="text-body-2 font-weight-medium" style="font-family:monospace">{{ viewingItem.agreement_no }}</div>
            </v-col>
            <template v-if="viewingItem.invoice_to && viewingItem.invoice_to.name">
              <v-col cols="6"><div class="text-caption text-medium-emphasis">Invoice To</div><div class="text-body-2 font-weight-medium">{{ viewingItem.invoice_to.name }}<span v-if="viewingItem.invoice_to.company" class="text-medium-emphasis"> · {{ viewingItem.invoice_to.company }}</span></div></v-col>
              <v-col cols="6"><div class="text-caption text-medium-emphasis">Contact</div><div class="text-body-2">{{ [viewingItem.invoice_to.phone, viewingItem.invoice_to.email].filter(Boolean).join(' · ') || '—' }}</div></v-col>
              <v-col v-if="viewingItem.invoice_to.address" cols="12"><div class="text-caption text-medium-emphasis">Address</div><div class="text-body-2">{{ viewingItem.invoice_to.address }}</div></v-col>
            </template>
            <v-col :cols="viewingItem.invoice_to && viewingItem.invoice_to.name ? 6 : 6"><div class="text-caption text-medium-emphasis">Vehicle</div><div class="text-body-2">{{ viewingItem.vehicle_display }} · {{ viewingItem.vehicle_license_plate }}</div></v-col>
            <v-col cols="6"><div class="text-caption text-medium-emphasis">Issue / Due</div><div class="text-body-2">{{ formatDate(viewingItem.issue_date) }} · {{ formatDate(viewingItem.due_date) }}</div></v-col>
          </v-row>

          <div class="text-caption font-weight-bold mt-3 mb-1" style="color:#4f46e5">LINE ITEMS</div>
          <v-table density="compact" class="rounded-lg border">
            <thead><tr><th>Description</th><th>Vehicle</th><th class="text-center">Qty</th><th class="text-end">Rate</th><th class="text-end">Amount</th></tr></thead>
            <tbody>
              <template v-for="(li, i) in (viewingItem.line_items || [])" :key="'li'+i">
                <tr v-if="li.is_header" class="font-weight-bold" style="background:#f1f5fd">
                  <td colspan="5" class="py-2" style="color:#4f46e5">{{ li.description }}</td>
                </tr>
                <tr v-else>
                  <td class="py-1" :class="{ 'text-red font-weight-medium': (li.description || '').startsWith('Damage') || (li.description || '').trim().startsWith('Damage') }">{{ li.description || '\u2014' }}</td>
                  <td class="py-1" style="font-size:0.75rem">{{ li.vehicle ? (li.vehicle.display_name || li.vehicle.license_plate || '\u2014') : '\u2014' }}</td>
                  <td class="text-center py-1">{{ li.quantity ?? 1 }}</td>
                  <td class="text-end py-1">{{ li.unit_amount === '' ? '' : currencySymbol + Number(li.unit_amount || 0).toLocaleString() }}<span v-if="li.rate_period && li.rate_period !== 'flat'" class="text-caption text-medium-emphasis ml-1">/{{ li.rate_period }}</span></td>
                  <td class="text-end py-1 font-weight-medium">{{ li.total_amount === '' ? '' : currencySymbol + Number(li.total_amount || 0).toLocaleString() }}</td>
                </tr>
              </template>
            </tbody>
          </v-table>

          <template v-if="viewingItem.damages && viewingItem.damages.length">
            <div class="text-caption font-weight-bold mt-4 mb-1" style="color:#ef4444">DAMAGES BREAKDOWN</div>
            <v-table density="compact" class="rounded-lg border">
              <thead><tr><th>Location</th><th>Description</th><th class="text-center">Severity</th><th class="text-end">Repair Cost</th><th v-if="viewingItem.agreements && viewingItem.agreements.length > 1">Agreement</th></tr></thead>
              <tbody>
                <tr v-for="(d, i) in viewingItem.damages" :key="'dm'+i">
                  <td class="py-1">{{ d.location || '\u2014' }}</td>
                  <td class="py-1">{{ d.description || '\u2014' }}</td>
                  <td class="text-center py-1"><v-chip size="x-small" :color="d.severity === 'severe' ? 'error' : d.severity === 'moderate' ? 'warning' : d.severity === 'minor' ? 'info' : 'grey'" variant="flat">{{ d.severity_display || (d.severity || '\u2014').replace('_', ' ') }}</v-chip></td>
                  <td class="text-end py-1 text-error font-weight-medium">{{ currencySymbol }}{{ Number(d.repair_cost || 0).toLocaleString() }}</td>
                  <td v-if="viewingItem.agreements && viewingItem.agreements.length > 1" class="py-1 text-caption" style="font-family:monospace;color:#64748b">{{ d.agreement_no || '\u2014' }}</td>
                </tr>
              </tbody>
            </v-table>
          </template>

          <v-row dense class="mt-3">
            <v-spacer />
            <v-col cols="auto">
              <div class="d-flex flex-column ga-1" style="min-width: 240px">
                <div class="d-flex justify-space-between"><span class="text-body-2 text-medium-emphasis">Subtotal</span><span class="text-body-2">{{ currencySymbol }}{{ Number(viewingItem.subtotal || 0).toLocaleString() }}</span></div>
                <div class="d-flex justify-space-between"><span class="text-body-2 text-medium-emphasis">Discount</span><span class="text-body-2">- {{ currencySymbol }}{{ Number(viewingItem.discount_total || 0).toLocaleString() }}</span></div>
                <div class="d-flex justify-space-between"><span class="text-body-2 text-medium-emphasis">Taxes</span><span class="text-body-2">{{ currencySymbol }}{{ Number(viewingItem.taxes || 0).toLocaleString() }}</span></div>
                <div class="d-flex justify-space-between" style="background:#eef2ff;border-radius:8px;padding:6px 12px"><span class="text-subtitle-2 font-weight-bold">Total</span><span class="text-subtitle-1 font-weight-bold" style="color:#4f46e5">{{ currencySymbol }}{{ Number(viewingItem.total_amount || 0).toLocaleString() }}</span></div>
                <div class="d-flex justify-space-between"><span class="text-body-2 text-success">Amount Paid</span><span class="text-body-2 text-success">{{ currencySymbol }}{{ Number(viewingItem.amount_paid || 0).toLocaleString() }}</span></div>
                <div class="d-flex justify-space-between"><span class="text-body-1 font-weight-bold text-error">Balance Due</span><span class="text-body-1 font-weight-bold text-error">{{ currencySymbol }}{{ Number(viewingItem.balance_due || 0).toLocaleString() }}</span></div>
              </div>
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions>
          <v-btn v-if="viewingItem.agreement" variant="text" prepend-icon="mdi-open-in-new" @click="navigateTo(`/app/rentals/${viewingItem.agreement}/view`)">View {{ viewingItem.agreements && viewingItem.agreements.length > 1 ? 'Primary ' : '' }}Agreement</v-btn>
          <v-btn v-if="!viewingItem.agreement && !(viewingItem.agreements && viewingItem.agreements.length)" v-can="'billing:view'" color="teal" variant="text" prepend-icon="mdi-file-document-edit-outline" @click="navigateTo(`/app/invoices/custom?edit=${viewingItem.id}`)">Edit Invoice</v-btn>
          <v-spacer />
          <v-btn variant="text" @click="viewDialog = false">Close</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

const { $api, $swal } = useNuxtApp()
const { currencySymbol } = useCurrency()
const { tenant, load: loadTenant, logoUrl: tenantLogoUrl } = useTenant()

const search = ref('')
const statusFilter = ref<string | null>(null)
const dateFilter = ref<string>('all')
const dateFrom = ref('')
const dateTo = ref('')
const loading = ref(true)
const page = ref(1)
const invoices = ref<any[]>([])

const dateFilterOptions = [
  { label: 'All Time', value: 'all' },
  { label: 'This Week', value: 'this_week' },
  { label: 'This Month', value: 'this_month' },
  { label: 'Last Month', value: 'last_month' },
  { label: 'Custom', value: 'custom' },
]

function onDateFilterChange(val: string) {
  if (val === 'custom') return
  // Clear custom dates when switching to a preset
  dateFrom.value = ''
  dateTo.value = ''
}

function dateRangeForFilter(filter: string): [string, string] | null {
  const now = new Date()
  if (filter === 'this_week') {
    const day = now.getDay() || 7 // Mon=1..Sun=7
    const monday = new Date(now)
    monday.setHours(0, 0, 0, 0)
    monday.setDate(now.getDate() - day + 1)
    const sunday = new Date(monday)
    sunday.setDate(monday.getDate() + 6)
    sunday.setHours(23, 59, 59, 999)
    return [monday.toISOString(), sunday.toISOString()]
  }
  if (filter === 'this_month') {
    const start = new Date(now.getFullYear(), now.getMonth(), 1)
    const end = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999)
    return [start.toISOString(), end.toISOString()]
  }
  if (filter === 'last_month') {
    const start = new Date(now.getFullYear(), now.getMonth() - 1, 1)
    const end = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59, 999)
    return [start.toISOString(), end.toISOString()]
  }
  return null
}

const statusOptions = [
  { label: 'Draft', value: 'draft' },
  { label: 'Sent', value: 'sent' },
  { label: 'Paid', value: 'paid' },
  { label: 'Partially Paid', value: 'partially_paid' },
  { label: 'Unpaid', value: 'unpaid' },
  { label: 'Overdue', value: 'overdue' },
  { label: 'Cancelled', value: 'cancelled' },
]

const headers = [
  { title: '#', key: 'index', width: '50px', sortable: false },
  { title: 'Invoice No', key: 'invoice_no', width: '160px', sortable: true },
  { title: 'Customer', key: 'customer_name', width: '200px' },
  { title: 'Agreement', key: 'agreement_no', width: '150px' },
  { title: 'Status', key: 'status', width: '120px', sortable: true },
  { title: 'Total', key: 'total_amount', width: '140px', align: 'end' as const, sortable: true },
  { title: 'Balance', key: 'balance_due', width: '140px', align: 'end' as const },
  { title: 'Issue Date', key: 'issue_date', width: '150px', sortable: true },
  { title: '', key: 'actions', width: '120px', sortable: false },
]

const stats = computed(() => {
  const list = invoices.value
  return {
    total: list.length,
    paid: list.filter((i) => i.status === 'paid').length,
    partially_paid: list.filter((i) => i.status === 'partially_paid').length,
    draft: list.filter((i) => i.status === 'draft').length,
    sent: list.filter((i) => i.status === 'sent').length,
    overdue: list.filter((i) => i.status === 'overdue').length,
    outstanding: list.reduce((s, i) => s + Number(i.balance_due || 0), 0),
  }
})

const filteredInvoices = computed(() => {
  let list = invoices.value
  if (statusFilter.value) list = list.filter((i) => i.status === statusFilter.value)
  // Date filter
  let range: [string, string] | null = null
  if (dateFilter.value === 'custom' && dateFrom.value && dateTo.value) {
    range = [new Date(dateFrom.value + 'T00:00:00').toISOString(), new Date(dateTo.value + 'T23:59:59').toISOString()]
  } else if (dateFilter.value !== 'all' && dateFilter.value !== 'custom') {
    range = dateRangeForFilter(dateFilter.value)
  }
  if (range) {
    const [from, to] = range
    list = list.filter((i) => {
      const d = new Date(i.issue_date || i.created_at)
      return d >= new Date(from) && d <= new Date(to)
    })
  }
  if (search.value) {
    const q = search.value.toLowerCase()
    list = list.filter((i) =>
      (i.invoice_no || '').toLowerCase().includes(q) ||
      (i.customer_name || '').toLowerCase().includes(q) ||
      (i.invoice_to?.name || '').toLowerCase().includes(q) ||
      (i.agreement_no || '').toLowerCase().includes(q)
    )
  }
  return list
})

/* ── Generate from agreement ── */
const generateDialog = ref(false)
const selectedAgreement = ref<number | null>(null)
const agreementOptions = ref<any[]>([])
const agreementsLoading = ref(false)
const generateDueDate = ref('')
const generateNotes = ref('')
const generating = ref(false)

watch(generateDialog, async (open) => {
  if (open && !agreementOptions.value.length) {
    agreementsLoading.value = true
    try {
      const res = await $api('/rentals/agreements/', { query: { page_size: 100 } })
      const list = res?.results || res || []
      agreementOptions.value = list
        .filter((a: any) => a.status !== 'draft' && a.status !== 'cancelled')
        .map((a: any) => ({
          id: a.id,
          label: `${a.agreement_no} — ${a.customer_name} (${a.vehicle_display || '—'})`,
        }))
    } catch {
      agreementOptions.value = []
    } finally {
      agreementsLoading.value = false
    }
  }
})

function resetGenerate() {
  selectedAgreement.value = null
  generateDueDate.value = ''
  generateNotes.value = ''
}

async function doGenerate() {
  if (!selectedAgreement.value) return
  generating.value = true
  try {
    const payload: any = { agreement: selectedAgreement.value }
    if (generateDueDate.value) payload.due_date = generateDueDate.value
    if (generateNotes.value) payload.notes = generateNotes.value
    await $api('/rentals/invoices/from-agreement/', { method: 'POST', body: payload })
    $swal.fire({ icon: 'success', title: 'Invoice generated', toast: true, timer: 1800, position: 'top-end' })
    generateDialog.value = false
    resetGenerate()
    await loadInvoices()
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Failed to generate', text: e?.data?.detail || '', toast: true, timer: 2500, position: 'top-end' })
  } finally {
    generating.value = false
  }
}

/* ── Edit ── */
const editDialog = ref(false)
const editingItem = ref<any>(null)
const saving = ref(false)

function editInvoice(item: any) {
  // Custom invoices (no agreement) → edit on the custom page
  if (!item.agreement && !(item.agreements && item.agreements.length)) {
    navigateTo(`/app/invoices/custom?edit=${item.id}`)
    return
  }
  editingItem.value = { ...item }
  editDialog.value = true
}

async function saveEdit() {
  if (!editingItem.value) return
  saving.value = true
  try {
    const payload = {
      status: editingItem.value.status,
      due_date: editingItem.value.due_date || null,
      notes: editingItem.value.notes || '',
    }
    await $api(`/rentals/invoices/${editingItem.value.id}/`, { method: 'PATCH', body: payload })
    $swal.fire({ icon: 'success', title: 'Invoice updated', toast: true, timer: 1500, position: 'top-end' })
    editDialog.value = false
    await loadInvoices()
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Update failed', text: e?.data?.detail || '', toast: true, timer: 2500, position: 'top-end' })
  } finally {
    saving.value = false
  }
}

/* ── View ── */
const viewDialog = ref(false)
const viewingItem = ref<any>(null)

async function viewInvoice(item: any) {
  // Fetch the full invoice record (with damages) from the API
  try {
    const full = await $api(`/rentals/invoices/${item.id}/`)
    viewingItem.value = full
  } catch {
    viewingItem.value = item
  }
  viewDialog.value = true
}

/* ── Download PDF ── */
async function downloadInvoice(rawItem: any) {
  // Fetch the full invoice record (with damages) so we have all line items
  let item = rawItem
  try {
    item = await $api(`/rentals/invoices/${rawItem.id}/`)
  } catch {
    // fall back to the list item
  }

  const t = tenant.value
  const companyFullName = t?.full_name || t?.short_name || 'DomendraFleet'
  const companyEmail = t?.email || ''
  const companyTel = t?.mobile_number || ''
  const companyAddress = t?.address || ''
  const companyLogoUrl = tenantLogoUrl.value || ''
  const logoHtml = companyLogoUrl
    ? `<img src="${companyLogoUrl}" alt="logo" style="max-height:56px; max-width:200px; border-radius:6px;" />`
    : `<div class="logo">${(t?.short_name || 'Domendra')}</div>`

  const lineItems = item.line_items || []
  const isMulti = item.agreements && item.agreements.length > 1
  const itemsHtml = lineItems.length
    ? lineItems.map((li: any) => {
        if (li.is_header) return `<tr><td colspan="5" style="background:#eef2ff;color:#4f46e5;font-weight:700;padding:6px 8px">${li.description || ''}</td></tr>`
        const vehicleName = li.vehicle ? (li.vehicle.display_name || li.vehicle.license_plate || '\u2014') : '\u2014'
        const ratePeriod = li.rate_period && li.rate_period !== 'flat' ? ` /${li.rate_period}` : ''
        const rateStr = li.unit_amount === '' ? '' : currencySymbol.value + Number(li.unit_amount || 0).toLocaleString() + ratePeriod
        return `<tr><td>${li.description || '\u2014'}</td><td style="font-size:11px;color:#64748b">${vehicleName}</td><td style="text-align:center">${li.quantity ?? 1}</td><td style="text-align:right">${rateStr}</td><td style="text-align:right"><b>${li.total_amount === '' ? '' : currencySymbol.value + Number(li.total_amount || 0).toLocaleString()}</b></td></tr>`
      }).join('')
    : '<tr><td colspan="5" style="text-align:center;color:#94a3b8">No line items.</td></tr>'

  // Build damages breakdown section if the invoice/agreement has damage records
  const damageItems = item.damages || []
  const dmgAgreeCol = isMulti ? '<th style="text-align:left;width:130px">Agreement</th>' : ''
  const damagesHtml = damageItems.length
    ? `<div class="section-title" style="margin-top:14px;color:#ef4444;border-left-color:#ef4444">Damages Breakdown</div>
      <table>
        <thead><tr><th>Location</th><th>Description</th><th style="text-align:center;width:80px">Severity</th><th style="text-align:right;width:140px">Repair Cost</th>${dmgAgreeCol}</tr></thead>
        <tbody>${damageItems.map((d: any) => `<tr><td>${d.location || '\u2014'}</td><td>${d.description || '\u2014'}</td><td style="text-align:center">${d.severity_display || (d.severity || '\u2014').replace('_', ' ')}</td><td style="text-align:right;color:#ef4444;font-weight:600">${currencySymbol.value}${Number(d.repair_cost || 0).toLocaleString()}</td>${isMulti ? `<td style="font-family:monospace;font-size:11px;color:#64748b">${d.agreement_no || '\u2014'}</td>` : ''}</tr>`).join('')}</tbody>
      </table>
      <div class="row" style="display:flex;justify-content:space-between;padding:6px 0;font-size:13px;font-weight:700;color:#ef4444"><span>Total Damages</span><span>${currencySymbol.value}${Number(damageItems.reduce((s: number, d: any) => s + Number(d.repair_cost || 0), 0)).toLocaleString()}</span></div>`
    : ''

  const dueDate = item.due_date ? item.due_date : '\u2014'

  // Branding color from the invoice, or default teal
  const brand = item.branding_color || '#0d9488'
  function hexToRgb(hex: string): string {
    const h = hex.replace('#', '')
    const n = parseInt(h.length === 3 ? h.split('').map((c) => c + c).join('') : h, 16)
    return `${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}`
  }
  function darkenHex(hex: string, factor: number): string {
    const h = hex.replace('#', '')
    const n = parseInt(h.length === 3 ? h.split('').map((c) => c + c).join('') : h, 16)
    return `#${Math.round(((n >> 16) & 255) * factor).toString(16).padStart(2, '0')}${Math.round(((n >> 8) & 255) * factor).toString(16).padStart(2, '0')}${Math.round((n & 255) * factor).toString(16).padStart(2, '0')}`
  }
  function tintHex(hex: string, ratio: number): string {
    const h = hex.replace('#', '')
    const n = parseInt(h.length === 3 ? h.split('').map((c) => c + c).join('') : h, 16)
    return `#${Math.round(((n >> 16) & 255) + (255 - ((n >> 16) & 255)) * ratio).toString(16).padStart(2, '0')}${Math.round(((n >> 8) & 255) + (255 - ((n >> 8) & 255)) * ratio).toString(16).padStart(2, '0')}${Math.round((n & 255) + (255 - (n & 255)) * ratio).toString(16).padStart(2, '0')}`
  }
  const brandRgb = hexToRgb(brand)
  const brandDark = darkenHex(brand, 0.7)
  const brandTint = tintHex(brand, 0.92)

  const w = window.open('', '_blank', 'width=900,height=1100')
  if (!w) {
    $swal.fire({ icon: 'warning', title: 'Popup blocked', text: 'Allow popups to download the invoice.', toast: true, timer: 2500, position: 'top-end' })
    return
  }
  w.document.write(`<!DOCTYPE html><html><head><meta charset="utf-8"><title>${item.invoice_no} - Invoice</title>
  <style>
    :root {
      --brand: ${brand};
      --brand-dark: ${brandDark};
      --brand-tint: ${brandTint};
      --brand-rgb: ${brandRgb};
    }
    body { font-family: 'Segoe UI', Arial, sans-serif; color:#1e293b; padding:30px; max-width:820px; margin:0 auto; -webkit-print-color-adjust:exact; print-color-adjust:exact; }
    .header { display:flex; justify-content:space-between; align-items:flex-start; border-bottom:3px solid var(--brand); padding-bottom:16px; margin-bottom:24px; }
    .header-left { display:flex; align-items:center; gap:14px; }
    .logo { font-size:28px; font-weight:800; color:var(--brand); }
    .company-name { font-size:18px; font-weight:700; color:#1e293b; line-height:1.3; }
    .company-contact { font-size:11px; color:#64748b; margin-top:3px; line-height:1.5; }
    .company-contact span { margin-right:12px; white-space:nowrap; }
    .meta { text-align:right; font-size:12px; color:#64748b; }
    .ref-badge { background:var(--brand-tint); color:var(--brand); padding:6px 12px; border-radius:6px; font-weight:700; font-family: monospace; -webkit-print-color-adjust:exact; print-color-adjust:exact; }
    h1 { font-size:22px; margin: 10px 0; }
    .section-title { font-size:12px; text-transform:uppercase; letter-spacing:0.05em; color:var(--brand); font-weight:700; margin:18px 0 8px; border-left:3px solid var(--brand); padding-left:8px; }
    table { width:100%; border-collapse:collapse; margin-bottom:12px; }
    th { background:var(--brand-tint); color:var(--brand); text-align:left; padding:8px; border:1px solid #e2e8f0; font-size:12px; -webkit-print-color-adjust:exact; print-color-adjust:exact; }
    td { padding:8px; border:1px solid #e2e8f0; font-size:12px; }
    .grid { display:grid; grid-template-columns: 1fr 1fr; gap:6px 24px; margin-bottom:8px; }
    .grid div { font-size:12px; padding:6px 0; border-bottom:1px dashed #e2e8f0; }
    .grid b { color:#475569; font-weight:600; display:block; font-size:10px; text-transform:uppercase; letter-spacing:0.05em; margin-bottom:2px; }
    .status-badge { display:inline-block; padding:4px 12px; border-radius:6px; font-size:11px; font-weight:700; text-transform:uppercase; letter-spacing:0.05em; -webkit-print-color-adjust:exact; print-color-adjust:exact; }
    .totals { margin-top:16px; max-width:280px; margin-left:auto; }
    .totals .row { display:flex; justify-content:space-between; padding:6px 0; font-size:13px; }
    .totals .grand { background:var(--brand-tint); padding:10px 14px; border-radius:8px; font-weight:800; font-size:16px; color:var(--brand); margin-top:6px; -webkit-print-color-adjust:exact; print-color-adjust:exact; }
    .foot { position:fixed; bottom:0; left:0; right:0; border-top:1px solid #e2e8f0; padding-top:10px; padding-bottom:10px; text-align:center; font-size:11px; color:#94a3b8; -webkit-print-color-adjust:exact; print-color-adjust:exact; }
    @media print {
      body { padding: 14px 14px 50px; }
      .foot { position:fixed; bottom:0; left:0; right:0; }
    }
  </style></head><body>
    <div class="header">
      <div class="header-left">
        ${logoHtml}
        <div>
          <div class="company-name">${companyFullName}</div>
          <div class="company-contact">
            ${companyEmail ? `<span>&#9993; ${companyEmail}</span>` : ''}
            ${companyTel ? `<span>&#9742; ${companyTel}</span>` : ''}
            ${companyAddress ? `<span>&#128205; ${companyAddress}</span>` : ''}
          </div>
        </div>
      </div>
      <div class="meta"><div class="ref-badge">${item.invoice_no}</div><div style="margin-top:6px">Issue Date: ${item.issue_date || '\u2014'}</div><div>Due Date: ${dueDate}</div></div>
    </div>
    <h1>Invoice</h1>

    ${item.agreement || (item.agreements && item.agreements.length) ? `<p style="font-size:12px;color:#475569">
      This invoice is issued for ${isMulti ? `the rental agreements <b>${item.agreements.map((a: any) => a.agreement_no).join(', ')}</b>` : `the vehicle rental agreement <b>${item.agreement_no || '\u2014'}</b>`}.
      Payment is due by the date shown above. Late payments may incur additional charges.
    </p>` : `<p style="font-size:12px;color:#475569">Payment is due by the date shown above. Late payments may incur additional charges.</p>`}

    <div class="section-title">Invoice To</div>
    <div class="grid">
      <div><b>Name</b>${item.invoice_to?.name || item.customer_name || '\u2014'}</div>
      <div><b>Type</b>${(item.customer_type || '\u2014').replace('_', ' ')}</div>
      <div><b>Phone</b>${item.invoice_to?.phone || item.customer_phone || '\u2014'}</div>
      <div><b>Email</b>${item.invoice_to?.email || item.customer_email || '\u2014'}</div>
      ${item.invoice_to?.company ? `<div><b>Company</b>${item.invoice_to.company}</div>` : ''}
      ${item.invoice_to?.address ? `<div style="grid-column:1/-1"><b>Address</b>${item.invoice_to.address}</div>` : ''}
    </div>

    ${item.agreement || (item.agreements && item.agreements.length) ? `<div class="section-title">Rental Details</div>
    <div class="grid">
      <div><b>Agreement${isMulti ? 's' : ''}</b>${isMulti ? item.agreements.map((a: any) => a.agreement_no).join(', ') : (item.agreement_no || '\u2014')}</div>
      <div><b>Vehicle</b>${item.vehicle_display || '\u2014'}</div>
      <div><b>License Plate</b>${item.vehicle_license_plate || '\u2014'}</div>
      <div><b>Status</b><span class="status-badge" style="background:${statusBadgeBg(item.status)};color:${statusBadgeColor(item.status)}">${statusLabel(item.status)}</span></div>
    </div>` : ''}

    <div class="section-title">Line Items</div>
    <table>
      <thead><tr><th>Description</th><th style="text-align:left;width:140px">Vehicle</th><th style="text-align:center;width:60px">Qty</th><th style="text-align:right;width:120px">Rate</th><th style="text-align:right;width:140px">Amount</th></tr></thead>
      <tbody>${itemsHtml}</tbody>
    </table>

    ${damagesHtml}

    <div class="totals">
      <div class="row"><span>Subtotal</span><span>${currencySymbol.value}${Number(item.subtotal || 0).toLocaleString()}</span></div>
      <div class="row"><span>Discount</span><span>- ${currencySymbol.value}${Number(item.discount_total || 0).toLocaleString()}</span></div>
      <div class="row"><span>Taxes</span><span>${currencySymbol.value}${Number(item.taxes || 0).toLocaleString()}</span></div>
      <div class="row grand"><span>Total Amount</span><span>${currencySymbol.value}${Number(item.total_amount || 0).toLocaleString()}</span></div>
    </div>
    <div style="margin-top:12px;max-width:280px;margin-left:auto">
      <div class="row" style="display:flex;justify-content:space-between;padding:6px 0;font-size:13px"><span>Amount Paid</span><span style="color:#10b981;font-weight:600">${currencySymbol.value}${Number(item.amount_paid || 0).toLocaleString()}</span></div>
      <div class="row" style="display:flex;justify-content:space-between;padding:6px 0;font-size:14px;font-weight:700"><span>Balance Due</span><span style="color:#ef4444">${currencySymbol.value}${Number(item.balance_due || 0).toLocaleString()}</span></div>
    </div>

    ${item.notes ? `<p style="font-size:11px;color:#475569;margin-top:20px;line-height:1.5"><b>Notes:</b> ${item.notes}</p>` : ''}

    <div class="foot">
      Generated by ${companyFullName} \u00b7 ${new Date().toISOString().slice(0, 10)} \u00b7 This is a system-generated document \u2014 Powered by: DomendraFleet.
    </div>
  </body></html>`)
  w.document.close()
  setTimeout(() => { w.focus(); w.print() }, 400)
}

/* ── Helpers ── */
function statusColor(s: string): string {
  const map: Record<string, string> = { draft: 'grey', sent: 'info', paid: 'success', partially_paid: 'warning', unpaid: 'error', overdue: 'error', cancelled: 'default' }
  return map[s] || 'default'
}
function statusLabel(s: string): string {
  return (s || '').replace('_', ' ')
}
function statusBadgeBg(s: string): string {
  const map: Record<string, string> = { draft: '#f1f5f9', sent: '#dbeafe', paid: '#dcfce7', partially_paid: '#fef9c3', unpaid: '#fee2e2', overdue: '#fee2e2', cancelled: '#f1f5f9' }
  return map[s] || '#f1f5f9'
}
function statusBadgeColor(s: string): string {
  const map: Record<string, string> = { draft: '#64748b', sent: '#2563eb', paid: '#16a34a', partially_paid: '#ca8a04', unpaid: '#dc2626', overdue: '#dc2626', cancelled: '#64748b' }
  return map[s] || '#64748b'
}
function formatDate(d: any): string {
  if (!d) return '\u2014'
  return String(d).slice(0, 10)
}

/* ── Load ── */
async function loadInvoices() {
  loading.value = true
  try {
    const res = await $api('/rentals/invoices/', { query: { page_size: 200 } })
    invoices.value = res?.results || res || []
  } catch {
    invoices.value = []
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  loadTenant()
  await loadInvoices()
})
</script>
