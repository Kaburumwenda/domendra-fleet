<template>
  <div class="d-flex flex-column ga-4">
    <!-- Page header -->
    <div class="page-header">
      <div>
        <h1 class="text-h5 font-weight-bold d-flex align-center ga-2">
          <v-icon color="primary">mdi-receipt-text-outline</v-icon>
          Expenses
        </h1>
        <p class="text-caption text-medium-emphasis">Track, approve, and analyze fleet and operational expenses.</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn variant="outlined" prepend-icon="mdi-refresh" :loading="pending" @click="reloadAll">Refresh</v-btn>
        <v-btn variant="tonal" color="deep-purple" prepend-icon="mdi-database-plus" :loading="seeding" @click="seedDemo">
          <span class="hidden-sm-and-down">Seed Demo Data</span>
        </v-btn>
        <v-btn v-can="'expenses:create'" color="primary" prepend-icon="mdi-plus" @click="openCreate">
          <span class="hidden-sm-and-down">New Expense</span>
        </v-btn>
      </div>
    </div>

    <!-- Tabs -->
    <v-tabs v-model="tab" color="primary" density="compact" class="exp-tabs">
      <v-tab value="overview" prepend-icon="mdi-view-dashboard-outline">Overview</v-tab>
      <v-tab value="records" prepend-icon="mdi-format-list-bulleted">Records</v-tab>
      <v-tab value="approvals" prepend-icon="mdi-clock-alert-outline">
        Approvals
        <v-chip v-if="pendingCount" color="warning" size="x-small" class="ml-2">{{ pendingCount }}</v-chip>
      </v-tab>
      <v-tab value="recurring" prepend-icon="mdi-calendar-sync">Recurring</v-tab>
      <v-tab value="budgets" prepend-icon="mdi-chart-arc">Budgets</v-tab>
      <v-tab value="categories" prepend-icon="mdi-tag-multiple-outline">Categories</v-tab>
    </v-tabs>

    <v-window v-model="tab" class="flex-grow-1">
      <!-- OVERVIEW -->
      <v-window-item value="overview">
        <ExpenseOverview
          :summary="summary"
          :expenses="expenses"
          :currency-symbol="currencySymbol"
          @navigate="tab = $event"
          @open="openDetail"
        />
      </v-window-item>

      <!-- RECORDS -->
      <v-window-item value="records">
        <div class="d-flex flex-column ga-4">
          <!-- Filters -->
          <div class="d-flex flex-wrap align-center ga-2 filter-bar">
            <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Search…" density="compact" hide-details variant="outlined" style="max-width: 280px" clearable />
            <v-select v-model="filterStatus" :items="statusOptions" item-title="label" item-value="value" placeholder="All Statuses" density="compact" hide-details variant="outlined" clearable style="max-width: 170px" />
            <v-select v-model="filterCategory" :items="categoryOptions" item-title="name" item-value="id" placeholder="All Categories" density="compact" hide-details variant="outlined" clearable style="max-width: 200px" />
            <v-select v-model="filterVehicle" :items="vehicleOptions" item-title="display_name" item-value="id" placeholder="All Vehicles" density="compact" hide-details variant="outlined" clearable style="max-width: 200px" />
            <v-btn-toggle v-model="datePreset" density="compact" color="primary" divided rounded="lg">
              <v-btn value="30" size="small">30d</v-btn>
              <v-btn value="90" size="small">90d</v-btn>
              <v-btn value="365" size="small">1y</v-btn>
              <v-btn value="all" size="small">All</v-btn>
              <v-btn value="custom" size="small" prepend-icon="mdi-calendar-cursor">
                <span class="hidden-sm-and-down">Custom</span>
                <v-tooltip activator="parent" location="top">Custom date range</v-tooltip>
              </v-btn>
            </v-btn-toggle>
            <!-- Custom date range popover -->
            <v-menu v-model="dateMenu" :close-on-content-click="false" location="bottom start" transition="slide-y-transition">
              <template #activator="{ props: dp }">
                <v-text-field
                  v-if="datePreset === 'custom'"
                  v-bind="dp"
                  :model-value="dateRangeLabel"
                  prepend-inner-icon="mdi-calendar-range"
                  placeholder="Pick a date range"
                  density="compact" hide-details variant="outlined" readonly
                  style="max-width: 220px"
                >
                  <template #append-inner>
                    <v-icon v-if="dateFrom || dateTo" size="small" @click.stop="dateFrom = ''; dateTo = ''">mdi-close</v-icon>
                  </template>
                </v-text-field>
              </template>
              <v-card rounded="lg" border elevation="8" width="auto" class="d-flex ga-0 pa-0" style="overflow: hidden">
                <div class="d-flex flex-column">
                  <div class="text-caption font-weight-bold pa-2 text-center" style="background: rgb(var(--v-theme-surface-variant))">From</div>
                  <v-date-picker v-model="dateFrom" color="primary" show-adjacent hide-header density="compact" width="260" />
                </div>
                <div class="d-flex flex-column" style="border-left: 1px solid rgb(var(--v-theme-border))">
                  <div class="text-caption font-weight-bold pa-2 text-center" style="background: rgb(var(--v-theme-surface-variant))">To</div>
                  <v-date-picker v-model="dateTo" color="primary" show-adjacent hide-header density="compact" width="260" />
                </div>
                <div class="d-flex flex-column justify-end pa-3 ga-2" style="border-left: 1px solid rgb(var(--v-theme-border))">
                  <v-btn size="small" variant="text" @click="setQuickRange('today')">Today</v-btn>
                  <v-btn size="small" variant="text" @click="setQuickRange('week')">This Week</v-btn>
                  <v-btn size="small" variant="text" @click="setQuickRange('month')">This Month</v-btn>
                  <v-btn size="small" variant="text" @click="setQuickRange('quarter')">This Quarter</v-btn>
                  <v-btn size="small" variant="text" @click="setQuickRange('year')">This Year</v-btn>
                  <v-btn size="small" color="primary" @click="dateMenu = false">Apply</v-btn>
                </div>
              </v-card>
            </v-menu>
            <v-btn v-if="hasFilters" variant="text" size="small" prepend-icon="mdi-filter-remove" @click="clearFilters">Clear</v-btn>
            <v-spacer />
            <div class="text-caption text-medium-emphasis">{{ filteredExpenses.length }} of {{ expenses.length }} expenses</div>
          </div>

          <!-- Table -->
          <v-card elevation="0" border rounded="lg">
            <v-data-table
              :headers="headers" :items="filteredExpenses" :loading="pending"
              hover density="compact" :items-per-page="15"
              :sort-by="[{ key: 'expense_date', order: 'desc' }]"
            >
              <template #item.title="{ item }">
                <div class="cursor-pointer" @click="openDetail(item)">
                  <p class="font-weight-medium mb-0">{{ item.title }}</p>
                  <p class="text-caption text-medium-emphasis mb-0">{{ item.expense_number }}</p>
                </div>
              </template>
              <template #item.category_name="{ item }">
                <v-chip :color="item.category_color || 'primary'" variant="tonal" size="small" class="text-capitalize">
                  <v-icon start size="14">{{ item.category_icon || 'mdi-cash' }}</v-icon>{{ item.category_name || 'Uncategorized' }}
                </v-chip>
              </template>
              <template #item.amount="{ item }"><span class="font-weight-medium">{{ currencySymbol }}{{ money(item.amount) }}</span></template>
              <template #item.tax_amount="{ value }"><span class="text-medium-emphasis">{{ currencySymbol }}{{ money(value) }}</span></template>
              <template #item.expense_date="{ value }">{{ fmtDate(value) }}</template>
              <template #item.vendor_name="{ value }">{{ value || '—' }}</template>
              <template #item.vehicle_name="{ value }">{{ value || '—' }}</template>
              <template #item.status="{ value }">
                <v-chip :color="statusColor(value)" variant="flat" size="small" class="text-capitalize">{{ value }}</v-chip>
              </template>
              <template #item.actions="{ item }">
                <v-menu>
                  <template #activator="{ props: p }"><v-btn icon="mdi-dots-vertical" variant="text" size="small" v-bind="p" /></template>
                  <v-list density="compact">
                    <v-list-item prepend-icon="mdi-eye-outline" @click="openDetail(item)">View Details</v-list-item>
                    <v-list-item v-if="item.status === 'draft'" prepend-icon="mdi-send-outline" @click="submitExpense(item)">Submit for Approval</v-list-item>
                    <v-list-item v-if="item.status === 'submitted'" v-can="'expenses:approve'" prepend-icon="mdi-check" @click="approveExpense(item)">Approve</v-list-item>
                    <v-list-item v-if="item.status === 'submitted'" prepend-icon="mdi-cash-check" @click="markPaid(item)">Mark Paid</v-list-item>
                    <v-list-item v-can="'expenses:update'" prepend-icon="mdi-pencil" @click="openEdit(item)">Edit</v-list-item>
                    <v-list-item v-can="'expenses:delete'" prepend-icon="mdi-delete" base-color="error" @click="deleteExpense(item)">Delete</v-list-item>
                  </v-list>
                </v-menu>
              </template>
              <template #no-data>
                <div class="text-center py-12 text-medium-emphasis">
                  <v-icon size="48" class="mb-3">mdi-receipt-text-outline</v-icon>
                  <p>No expenses yet. Click <b>New Expense</b> to add one.</p>
                </div>
              </template>
            </v-data-table>
          </v-card>
        </div>
      </v-window-item>

      <!-- APPROVALS -->
      <v-window-item value="approvals">
        <v-card elevation="0" border rounded="lg">
          <v-data-table
            :headers="approvalHeaders" :items="approvalExpenses"
            :loading="pending" hover density="compact"
            :items-per-page="-1" hide-default-footer
          >
            <template #item.title="{ item }">
              <div class="cursor-pointer" @click="openDetail(item)">
                <p class="font-weight-medium mb-0">{{ item.title }}</p>
                <p class="text-caption text-medium-emphasis mb-0">{{ item.expense_number }} · {{ fmtDate(item.expense_date) }}</p>
              </div>
            </template>
            <template #item.category_name="{ item }">
              <v-chip :color="item.category_color || 'primary'" variant="tonal" size="small" class="text-capitalize">{{ item.category_name || 'Uncategorized' }}</v-chip>
            </template>
            <template #item.vendor_name="{ value }">{{ value || '—' }}</template>
            <template #item.amount="{ item }"><span class="font-weight-medium">{{ currencySymbol }}{{ money(item.amount) }}</span></template>
            <template #item.submitted_by_name="{ value }">{{ value || '—' }}</template>
            <template #item.status="{ value }">
              <v-chip :color="statusColor(value)" variant="flat" size="small" class="text-capitalize">{{ value }}</v-chip>
            </template>
            <template #item.actions="{ item }">
              <div class="d-flex ga-1">
                <v-btn v-if="item.status === 'draft'" icon="mdi-send-outline" size="small" variant="text" color="warning" @click="submitExpense(item)" />
                <v-btn v-if="item.status === 'submitted'" v-can="'expenses:approve'" icon="mdi-check" size="small" variant="text" color="success" @click="approveExpense(item)" />
                <v-btn v-if="item.status === 'submitted'" icon="mdi-close" size="small" variant="text" color="error" @click="openReject(item)" />
                <v-btn icon="mdi-eye-outline" size="small" variant="text" @click="openDetail(item)" />
              </div>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-check-circle-outline</v-icon>
                <p>No expenses awaiting approval.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>

      <!-- RECURRING -->
      <v-window-item value="recurring">
        <ExpenseRecurring
          :currency-symbol="currencySymbol"
          :category-options="categoryOptions"
          :vehicle-options="vehicleOptions"
          :contact-options="contactOptions"
        />
      </v-window-item>

      <!-- BUDGETS -->
      <v-window-item value="budgets">
        <ExpenseBudgets
          :currency-symbol="currencySymbol"
          :vehicle-options="vehicleOptions"
          :category-options="categoryOptions"
        />
      </v-window-item>

      <!-- CATEGORIES -->
      <v-window-item value="categories">
        <ExpenseCategories />
      </v-window-item>
    </v-window>

    <!-- Form dialog -->
    <ExpenseFormDialog
      ref="formRef"
      v-model="formDialog"
      :editing="editing"
      :saving="saving"
      :currency-symbol="currencySymbol"
      :category-options="categoryOptions"
      :vehicle-options="vehicleOptions"
      :contact-options="contactOptions"
      @save="saveExpense"
      @remove-attachment="removeAttachment"
    />

    <!-- Detail drawer -->
    <ExpenseDetailDrawer
      v-model="drawerOpen"
      :exp="selected"
      :currency-symbol="currencySymbol"
      @edit="openEdit"
      @delete="deleteExpense"
      @submit="submitExpense"
      @approve="approveExpense"
      @reject="rejectExpense"
      @mark-paid="markPaid"
      @remove-attachment="removeAttachment"
      @add-comment="postComment"
      @upload-attachments="uploadAttachments"
    />
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })
const { $api, $swal } = useNuxtApp() as any
const { currencySymbol } = useCurrency()
const {
  fetchExpenses, fetchExpenseSummary, saveExpense: apiSave, deleteExpense: apiDel,
  submitExpense: apiSubmit, approveExpense: apiApprove, rejectExpense: apiReject,
  markPaid: apiMarkPaid, seedDemo: apiSeed,
  uploadAttachment: apiUpload, deleteAttachment: apiDelAtt,
  addComment: apiComment,
} = useExpenseApi()

const tab = ref<string>('overview')

// ── Lookup data ────────────────────────────────────────────
const { data: catData } = useAsyncData('exp-cats-lookup', () => $api('/expenses/categories/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const categoryOptions = computed(() => catData.value?.results || [])

const { data: vehicleData } = useAsyncData('exp-vehicles', () => $api('/vehicles/vehicles/', { query: { page_size: 1000 } }), { default: () => ({ results: [] }) })
const vehicleOptions = computed(() => vehicleData.value?.results || [])

const { data: contactData } = useAsyncData('exp-contacts', () => $api('/contacts/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const contactOptions = computed(() => contactData.value?.results || [])

// ── Expense data ────────────────────────────────────────────
const { data: expData, pending, refresh } = useAsyncData('expenses', () =>
  fetchExpenses(), { default: () => ({ results: [], count: 0 }) })
const expenses = computed(() => expData.value?.results || expData.value || [])

const { data: summaryData, refresh: refreshSummary } = useAsyncData('expenses-summary', () =>
  fetchExpenseSummary().catch(() => ({})) as Promise<any>, { default: () => ({}) })
const summary = computed(() => summaryData.value || {})

// ── Filters ─────────────────────────────────────────────────
const search = ref('')
const filterStatus = ref<string | null>(null)
const filterCategory = ref<number | null>(null)
const filterVehicle = ref<number | null>(null)
const datePreset = ref<string>('all')
const dateMenu = ref(false)
const dateFrom = ref<string>('')
const dateTo = ref<string>('')
const dateRangeLabel = computed(() => {
  if (!dateFrom.value && !dateTo.value) return ''
  const f = dateFrom.value ? new Date(dateFrom.value).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' }) : ''
  const t = dateTo.value ? new Date(dateTo.value).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' }) : ''
  return f || t ? `${f} → ${t}` : ''
})
function setQuickRange(kind: string) {
  const now = new Date()
  const start = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  let s = new Date(start)
  if (kind === 'today') { /* already today */ }
  else if (kind === 'week') { s.setDate(s.getDate() - s.getDay()) }
  else if (kind === 'month') { s.setDate(1) }
  else if (kind === 'quarter') { s = new Date(now.getFullYear(), Math.floor(now.getMonth() / 3) * 3, 1) }
  else if (kind === 'year') { s = new Date(now.getFullYear(), 0, 1) }
  dateFrom.value = s.toISOString().split('T')[0]
  dateTo.value = start.toISOString().split('T')[0]
}

const statusOptions = [
  { label: 'Draft', value: 'draft' },
  { label: 'Submitted', value: 'submitted' },
  { label: 'Paid', value: 'paid' },
  { label: 'Rejected', value: 'rejected' },
]

const headers = [
  { title: 'Title', key: 'title', sortable: true },
  { title: 'Category', key: 'category_name', width: '160px' },
  { title: 'Amount', key: 'amount', width: '110px', sortable: true },
  { title: 'Tax', key: 'tax_amount', width: '90px' },
  { title: 'Date', key: 'expense_date', width: '120px', sortable: true },
  { title: 'Vendor', key: 'vendor_name', width: '140px' },
  { title: 'Vehicle', key: 'vehicle_name', width: '140px' },
  { title: 'Status', key: 'status', width: '110px' },
  { title: '', key: 'actions', width: '50px', sortable: false },
]

const approvalHeaders = [
  { title: 'Expense', key: 'title' },
  { title: 'Category', key: 'category_name', width: '160px' },
  { title: 'Vendor', key: 'vendor_name', width: '150px' },
  { title: 'Amount', key: 'amount', width: '110px' },
  { title: 'Submitted By', key: 'submitted_by_name', width: '140px' },
  { title: 'Status', key: 'status', width: '110px' },
  { title: '', key: 'actions', width: '160px', sortable: false },
]

const filteredExpenses = computed(() => {
  let arr = expenses.value
  if (filterStatus.value) arr = arr.filter((e: any) => e.status === filterStatus.value)
  if (filterCategory.value) arr = arr.filter((e: any) => e.category === filterCategory.value)
  if (filterVehicle.value) arr = arr.filter((e: any) => e.vehicle === filterVehicle.value)
  if (datePreset.value === 'custom') {
    if (dateFrom.value) {
      const f = new Date(dateFrom.value); f.setHours(0, 0, 0, 0)
      arr = arr.filter((e: any) => new Date(e.expense_date) >= f)
    }
    if (dateTo.value) {
      const t = new Date(dateTo.value); t.setHours(23, 59, 59, 999)
      arr = arr.filter((e: any) => new Date(e.expense_date) <= t)
    }
  } else if (datePreset.value !== 'all') {
    const days = Number(datePreset.value)
    const since = new Date(); since.setDate(since.getDate() - days)
    arr = arr.filter((e: any) => new Date(e.expense_date) >= since)
  }
  if (search.value) {
    const q = search.value.toLowerCase()
    arr = arr.filter((e: any) =>
      (e.title || '').toLowerCase().includes(q) ||
      (e.vendor_name || '').toLowerCase().includes(q) ||
      (e.expense_number || '').toLowerCase().includes(q) ||
      (e.description || '').toLowerCase().includes(q)
    )
  }
  return arr
})

const approvalExpenses = computed(() =>
  expenses.value.filter((e: any) => e.status === 'draft' || e.status === 'submitted')
)
const pendingCount = computed(() => approvalExpenses.value.length)

const hasFilters = computed(() => !!(filterStatus.value || filterCategory.value || filterVehicle.value || search.value || datePreset.value !== 'all' || dateFrom.value || dateTo.value))
function clearFilters() { search.value = ''; filterStatus.value = null; filterCategory.value = null; filterVehicle.value = null; datePreset.value = 'all'; dateFrom.value = ''; dateTo.value = '' }

// ── Dialogs & selected ──────────────────────────────────────
const formRef = ref<any>(null)
const formDialog = ref(false)
const editing = ref(false)
const saving = ref(false)
const drawerOpen = ref(false)
const selected = ref<any>(null)

function openCreate() { editing.value = false; formRef.value?.reset(); formDialog.value = true }
function openEdit(e: any) { editing.value = true; formRef.value?.reset(e); formDialog.value = true; drawerOpen.value = false }
function openDetail(e: any) { selected.value = e; drawerOpen.value = true }

async function saveExpense(payload: any, files: File[]) {
  if (!payload.title || !payload.amount) {
    $swal?.fire?.({ icon: 'error', title: 'Title & amount required', toast: true, timer: 2000, position: 'top-end' }); return
  }
  saving.value = true
  try {
    const formData = new FormData()
    Object.entries(payload).forEach(([k, v]) => {
      if (v === null || v === undefined) return
      formData.append(k, String(v))
    })
    if (editing.value && payload._id) {
      await apiSave(formData, payload._id)
    } else {
      const res: any = await apiSave(formData)
      if (files?.length && res?.id) await apiUpload(res.id, files)
    }
    formDialog.value = false
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: editing.value ? 'Expense updated' : 'Expense created', toast: true, timer: 1500, position: 'top-end' })
  } catch (e: any) {
    console.error(e); $swal?.fire?.({ icon: 'error', title: 'Save failed', text: e?.data?.detail || '', toast: true, timer: 2500, position: 'top-end' })
  } finally { saving.value = false }
}

async function deleteExpense(e: any) {
  const r = await $swal?.fire?.({ icon: 'warning', title: 'Delete expense?', text: e.title, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#dc2626' })
  if (!r?.isConfirmed) return
  await apiDel(e.id)
  if (selected.value?.id === e.id) { drawerOpen.value = false; selected.value = null }
  await reloadAll()
  $swal?.fire?.({ icon: 'success', title: 'Expense deleted', toast: true, timer: 1500, position: 'top-end' })
}

async function submitExpense(e: any) {
  try {
    await apiSubmit(e.id)
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: 'Expense submitted', toast: true, timer: 1500, position: 'top-end' })
  } catch (e2: any) { console.error(e2); $swal?.fire?.({ icon: 'error', title: 'Submit failed', toast: true, timer: 2000, position: 'top-end' }) }
}

async function approveExpense(e: any) {
  try {
    await apiApprove(e.id)
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: 'Expense approved', toast: true, timer: 1500, position: 'top-end' })
  } catch (e2: any) { console.error(e2); $swal?.fire?.({ icon: 'error', title: 'Approve failed', toast: true, timer: 2000, position: 'top-end' }) }
}

async function rejectExpense(e: any, reason: string) {
  try {
    await apiReject(e.id, reason)
    await reloadAll()
    $swal?.fire?.({ icon: 'info', title: 'Expense rejected', toast: true, timer: 1500, position: 'top-end' })
  } catch (e2: any) { console.error(e2); $swal?.fire?.({ icon: 'error', title: 'Reject failed', toast: true, timer: 2000, position: 'top-end' }) }
}

async function markPaid(e: any) {
  try {
    await apiMarkPaid(e.id)
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: 'Marked as paid', toast: true, timer: 1500, position: 'top-end' })
  } catch (e2: any) { console.error(e2); $swal?.fire?.({ icon: 'error', title: 'Mark paid failed', toast: true, timer: 2000, position: 'top-end' }) }
}

async function removeAttachment(att: any) {
  if (!selected.value?.id) return
  await apiDelAtt(selected.value.id, att.id)
  await reloadSelected()
  $swal?.fire?.({ icon: 'success', title: 'Attachment removed', toast: true, timer: 1500, position: 'top-end' })
}

async function uploadAttachments(e: any, files: File[]) {
  if (!e?.id || !files?.length) return
  await apiUpload(e.id, files)
  await reloadSelected()
  $swal?.fire?.({ icon: 'success', title: 'Attachments uploaded', toast: true, timer: 1500, position: 'top-end' })
}

async function postComment(e: any, body: string) {
  if (!body) return
  await apiComment(e.id, body)
  await reloadSelected()
}

async function reloadSelected() {
  if (!selected.value?.id) return
  try {
    const updated: any = await $api(`/expenses/${selected.value.id}/`)
    selected.value = updated
  } catch (e) { console.error(e) }
  // also update list
  await refresh()
}

// ── Seed ──────────────────────────────────────────────────
const seeding = ref(false)
async function seedDemo() {
  const r = await $swal?.fire?.({ icon: 'question', title: 'Seed demo data?', text: 'This will create 36 random expenses + default categories', showCancelButton: true, confirmButtonText: 'Seed', confirmButtonColor: '#6366f1' })
  if (!r?.isConfirmed) return
  seeding.value = true
  try {
    const res: any = await apiSeed()
    await reloadAll()
    // refresh category lookup
    const cd: any = await $api('/expenses/categories/', { query: { page_size: 1000 } })
    catData.value = cd
    $swal?.fire?.({ icon: 'success', title: res?.detail || 'Seeded', toast: true, timer: 2000, position: 'top-end' })
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Seed failed', toast: true, timer: 2000, position: 'top-end' }) } finally { seeding.value = false }
}

// ── Bulk reload ─────────────────────────────────────────────
async function reloadAll() {
  await Promise.all([refresh(), refreshSummary()])
}

// ── Utils ───────────────────────────────────────────────────
function money(v: any) { return Number(v || 0).toFixed(2) }
function fmtDate(d?: string) { return d ? new Date(d).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' }) : '—' }
function statusColor(s: string) { return ({ draft: 'grey', submitted: 'warning', approved: 'info', rejected: 'error', paid: 'success' } as any)[s] || 'grey' }
function openReject(e: any) { selected.value = e; drawerOpen.value = true; /* drawer handles reject UI */ }
</script>

<style scoped>
.page-header {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}
.filter-bar {
  flex-wrap: wrap;
}
.exp-tabs :deep(.v-slide-group__content) {
  padding: 0 8px;
}
</style>
