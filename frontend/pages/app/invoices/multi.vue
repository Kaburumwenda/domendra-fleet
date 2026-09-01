<template>
  <div class="d-flex flex-column ga-4">
    <!-- Header -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-2">
      <div class="d-flex align-center ga-3">
        <v-btn icon="mdi-arrow-left" size="small" variant="text" @click="navigateTo('/app/invoices')" />
        <div>
          <h1 class="text-h5 font-weight-bold" style="color: #1e293b">Consolidated Invoice</h1>
          <p class="text-caption text-medium-emphasis">Generate a single invoice from multiple rental agreements</p>
        </div>
      </div>
    </div>

    <!-- Step 1: Select Customer -->
    <v-card elevation="0" border rounded="lg" class="pa-5">
      <div class="d-flex align-center ga-2 mb-3">
        <v-avatar size="32" color="indigo" variant="tonal">
          <span class="text-body-2 font-weight-bold" style="color:#4f46e5">1</span>
        </v-avatar>
        <span class="text-subtitle-2 font-weight-bold" style="color:#1e293b">Select Customer</span>
      </div>
      <v-autocomplete
        v-model="multiCustomerId"
        :items="customerOptions"
        item-title="label"
        item-value="id"
        label="Select Customer"
        density="comfortable"
        variant="outlined"
        hide-details="auto"
        clearable
        :loading="customersLoading"
        prepend-inner-icon="mdi-account-search"
        @update:model-value="onCustomerChange"
      />
    </v-card>

    <!-- Step 2: Select Agreements -->
    <v-card v-if="multiCustomerId" elevation="0" border rounded="lg" class="pa-5">
      <div class="d-flex align-center ga-2 mb-3">
        <v-avatar size="32" color="indigo" variant="tonal">
          <span class="text-body-2 font-weight-bold" style="color:#4f46e5">2</span>
        </v-avatar>
        <span class="text-subtitle-2 font-weight-bold" style="color:#1e293b">Select Agreements</span>
      </div>

      <!-- Summary bar -->
      <div class="d-flex align-center justify-space-between mb-3 flex-wrap ga-2">
        <span class="text-caption font-weight-bold" style="color:#4f46e5">AGREEMENTS (latest first)</span>
        <div class="d-flex align-center ga-3">
          <span class="text-caption text-medium-emphasis">{{ multiSelected.length }} selected · {{ currencySymbol }}{{ multiSelectedTotal.toLocaleString() }} total</span>
          <v-btn size="x-small" variant="tonal" color="primary" prepend-icon="mdi-check-all" @click="multiSelectAll">Select all</v-btn>
          <v-btn size="x-small" variant="text" prepend-icon="mdi-close" @click="multiSelected = []">Clear</v-btn>
        </div>
      </div>

      <!-- Date filter bar -->
      <div class="d-flex align-center ga-2 mb-3 flex-wrap">
        <v-select v-model="dateFilter" :items="dateFilterOptions" item-title="label" item-value="value" density="compact" variant="outlined" label="Date" hide-details style="max-width: 160px" @update:model-value="onDateFilterChange" />
        <template v-if="dateFilter === 'custom'">
          <v-text-field v-model="dateFrom" type="date" density="compact" variant="outlined" label="From" hide-details style="max-width: 150px" prepend-inner-icon="mdi-calendar-start" />
          <v-text-field v-model="dateTo" type="date" density="compact" variant="outlined" label="To" hide-details style="max-width: 150px" prepend-inner-icon="mdi-calendar-end" />
        </template>
        <span v-if="dateFilter !== 'all'" class="text-caption text-medium-emphasis">{{ filteredDateRangeText }}</span>
      </div>

      <v-card variant="outlined" rounded="lg" max-height="420" style="overflow-y:auto">
        <v-list density="compact" lines="two">
          <template v-if="agreementsLoading">
            <div class="d-flex justify-center align-center pa-8">
              <v-progress-circular indeterminate color="primary" />
            </div>
          </template>
          <template v-else-if="filteredMultiAgreements.length">
            <v-list-item v-for="a in filteredMultiAgreements" :key="a.id" @click="toggleMultiAgreement(a.id)" :active="multiSelected.includes(a.id)" class="agree-item">
              <template #prepend>
                <v-list-item-action start>
                  <v-checkbox-btn :model-value="multiSelected.includes(a.id)" color="primary" hide-details density="compact" readonly />
                </v-list-item-action>
              </template>
              <v-list-item-title class="text-body-2 font-weight-medium" style="font-family:monospace">{{ a.agreement_no }}</v-list-item-title>
              <v-list-item-subtitle class="text-caption">
                {{ a.vehicle_display || '—' }} · {{ formatDate(a.start_datetime) }} → {{ formatDate(a.actual_return_datetime || a.end_datetime) }}
              </v-list-item-subtitle>
              <template #append>
                <div class="d-flex flex-column align-end ga-1">
                  <div class="d-flex ga-1">
                    <v-chip size="x-small" :color="agreementStatusColor(a.status)" variant="flat">{{ (a.status || '').replace('_',' ') }}</v-chip>
                    <v-chip size="x-small" :color="paymentStatusColor(a.payment_status)" variant="tonal" prepend-icon="mdi-cash">
                      {{ paymentStatusLabel(a.payment_status) }}<template v-if="a.payment_status === 'partial' && a.balance_due && Number(a.balance_due) > 0">
                        · bal {{ currencySymbol }}{{ Number(a.balance_due).toLocaleString() }}
                      </template>
                    </v-chip>
                  </div>
                  <span class="text-caption font-weight-medium">{{ currencySymbol }}{{ Number(a.total_amount || 0).toLocaleString() }}</span>
                </div>
              </template>
            </v-list-item>
          </template>
          <v-list-item v-else-if="multiAgreements.length">
            <v-list-item-title class="text-body-2 text-medium-emphasis">No agreements match the selected date filter.</v-list-item-title>
          </v-list-item>
          <v-list-item v-else>
            <v-list-item-title class="text-body-2 text-medium-emphasis">No agreements found for this customer.</v-list-item-title>
          </v-list-item>
        </v-list>
      </v-card>
    </v-card>

    <!-- Step 3: Invoice Details + Summary -->
    <v-card v-if="multiCustomerId && multiSelected.length" elevation="0" border rounded="lg" class="pa-5">
      <div class="d-flex align-center ga-2 mb-3">
        <v-avatar size="32" color="indigo" variant="tonal">
          <span class="text-body-2 font-weight-bold" style="color:#4f46e5">3</span>
        </v-avatar>
        <span class="text-subtitle-2 font-weight-bold" style="color:#1e293b">Invoice Details</span>
      </div>

      <v-row dense>
        <v-col cols="12" md="6">
          <v-text-field
            v-model="multiDueDate"
            type="date"
            label="Due Date (optional)"
            density="comfortable"
            variant="outlined"
            hide-details="auto"
            prepend-inner-icon="mdi-calendar-alert"
          />
          <v-textarea
            v-model="multiNotes"
            label="Notes (optional)"
            density="comfortable"
            variant="outlined"
            hide-details="auto"
            rows="3"
            class="mt-3"
          />
        </v-col>
        <v-col cols="12" md="6">
          <v-card variant="tonal" color="indigo" class="pa-4 rounded-lg">
            <div class="text-caption font-weight-bold mb-2" style="color:#4f46e5">CONSOLIDATED INVOICE SUMMARY</div>
            <div class="d-flex justify-space-between py-1">
              <span class="text-body-2 text-medium-emphasis">Agreements selected</span>
              <span class="text-body-2 font-weight-medium">{{ multiSelected.length }}</span>
            </div>
            <div class="d-flex justify-space-between py-1">
              <span class="text-body-2 text-medium-emphasis">Customer</span>
              <span class="text-body-2 font-weight-medium">{{ selectedCustomerName }}</span>
            </div>
            <div class="d-flex justify-space-between py-1">
              <span class="text-body-2 text-medium-emphasis">Total amount</span>
              <span class="text-body-2 font-weight-medium">{{ currencySymbol }}{{ multiSelectedTotal.toLocaleString() }}</span>
            </div>
            <div class="d-flex justify-space-between py-1">
              <span class="text-body-2 text-medium-emphasis">Already paid (across agreements)</span>
              <span class="text-body-2 font-weight-medium text-success">{{ currencySymbol }}{{ multiSelectedPaid.toLocaleString() }}</span>
            </div>
            <v-divider class="my-2" />
            <div class="d-flex justify-space-between py-1">
              <span class="text-subtitle-2 font-weight-bold">Estimated balance</span>
              <span class="text-subtitle-1 font-weight-bold text-error">{{ currencySymbol }}{{ Math.max(0, multiSelectedTotal - multiSelectedPaid).toLocaleString() }}</span>
            </div>
          </v-card>
        </v-col>
      </v-row>

      <div class="d-flex justify-end ga-2 mt-4">
        <v-btn variant="text" @click="navigateTo('/app/invoices')">Cancel</v-btn>
        <v-btn color="primary" prepend-icon="mdi-file-document-plus-outline" :loading="multiGenerating" @click="doGenerateMulti">
          Generate Consolidated Invoice
        </v-btn>
      </div>
    </v-card>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

const { $api, $swal } = useNuxtApp()
const { currencySymbol } = useCurrency()

/* ── Customer selection ── */
const multiCustomerId = ref<number | null>(null)
const customerOptions = ref<any[]>([])
const customersLoading = ref(false)

/* ── Agreements ── */
const multiAgreements = ref<any[]>([])
const multiSelected = ref<number[]>([])
const agreementsLoading = ref(false)

/* ── Date filter ── */
const dateFilter = ref<string>('all')
const dateFrom = ref('')
const dateTo = ref('')

const dateFilterOptions = [
  { label: 'All Time', value: 'all' },
  { label: 'This Week', value: 'this_week' },
  { label: 'This Month', value: 'this_month' },
  { label: 'Last Month', value: 'last_month' },
  { label: 'Custom', value: 'custom' },
]

function onDateFilterChange(val: string) {
  if (val === 'custom') return
  dateFrom.value = ''
  dateTo.value = ''
}

function dateRangeForFilter(filter: string): [string, string] | null {
  const now = new Date()
  if (filter === 'this_week') {
    const day = now.getDay() || 7
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

const activeDateRange = computed<[string, string] | null>(() => {
  if (dateFilter.value === 'custom' && dateFrom.value && dateTo.value) {
    return [new Date(dateFrom.value + 'T00:00:00').toISOString(), new Date(dateTo.value + 'T23:59:59').toISOString()]
  }
  if (dateFilter.value !== 'all' && dateFilter.value !== 'custom') {
    return dateRangeForFilter(dateFilter.value)
  }
  return null
})

const filteredMultiAgreements = computed(() => {
  if (!activeDateRange.value) return multiAgreements.value
  const [from, to] = activeDateRange.value
  const fromD = new Date(from)
  const toD = new Date(to)
  return multiAgreements.value.filter((a) => {
    const d = new Date(a.start_datetime || a.created_at)
    return d >= fromD && d <= toD
  })
})

const filteredDateRangeText = computed(() => {
  if (!activeDateRange.value) return ''
  const [from, to] = activeDateRange.value
  const fmt = (d: string) => new Date(d).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
  return `${fmt(from)} — ${fmt(to)}`
})

/* ── Invoice details ── */
const multiDueDate = ref('')
const multiNotes = ref('')
const multiGenerating = ref(false)

const selectedCustomerName = computed(() => {
  const c = customerOptions.value.find((c) => c.id === multiCustomerId.value)
  return c ? c.label.split(' (')[0] : '—'
})

const multiSelectedTotal = computed(() =>
  multiAgreements.value
    .filter((a) => multiSelected.value.includes(a.id))
    .reduce((s, a) => s + Number(a.total_amount || 0), 0)
)

const multiSelectedPaid = computed(() =>
  multiAgreements.value
    .filter((a) => multiSelected.value.includes(a.id))
    .reduce((s, a) => s + Number(a.amount_paid || 0), 0)
)

async function loadCustomers() {
  customersLoading.value = true
  try {
    const res = await $api('/rentals/customers/', { query: { page_size: 200 } })
    const list = res?.results || res || []
    customerOptions.value = list.map((c: any) => ({
      id: c.id,
      label: `${c.full_name} (${(c.customer_type || '').replace('_', ' ')})`,
    }))
  } catch {
    customerOptions.value = []
  } finally {
    customersLoading.value = false
  }
}

async function onCustomerChange() {
  multiAgreements.value = []
  multiSelected.value = []
  if (!multiCustomerId.value) return
  agreementsLoading.value = true
  try {
    const res = await $api('/rentals/agreements/', { query: { customer: multiCustomerId.value, page_size: 200 } })
    const list = (res?.results || res || []).filter((a: any) => a.status !== 'draft' && a.status !== 'cancelled')
    multiAgreements.value = list.sort((a: any, b: any) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
  } catch {
    multiAgreements.value = []
  } finally {
    agreementsLoading.value = false
  }
}

function toggleMultiAgreement(id: number) {
  const idx = multiSelected.value.indexOf(id)
  if (idx >= 0) multiSelected.value.splice(idx, 1)
  else multiSelected.value.push(id)
}

function multiSelectAll() {
  multiSelected.value = filteredMultiAgreements.value.map((a) => a.id)
}

function agreementStatusColor(s: string): string {
  const map: Record<string, string> = { active: 'info', completed: 'success', overdue: 'error', draft: 'grey', cancelled: 'default' }
  return map[s] || 'default'
}

function paymentStatusLabel(s: string): string {
  const map: Record<string, string> = { paid: 'Paid', partial: 'Partially', partially_paid: 'Partially', unpaid: 'Unpaid' }
  return map[s] || (s || '—').replace('_', ' ')
}

function paymentStatusColor(s: string): string {
  const map: Record<string, string> = { paid: 'success', partial: 'warning', partially_paid: 'warning', unpaid: 'error' }
  return map[s] || 'grey'
}

function formatDate(d: any): string {
  if (!d) return '—'
  return new Date(d).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
}

async function doGenerateMulti() {
  if (!multiSelected.value.length) return
  multiGenerating.value = true
  try {
    const payload: any = { agreements: [...multiSelected.value] }
    if (multiDueDate.value) payload.due_date = multiDueDate.value
    if (multiNotes.value) payload.notes = multiNotes.value
    await $api('/rentals/invoices/from-agreements/', { method: 'POST', body: payload })
    $swal.fire({ icon: 'success', title: 'Consolidated invoice generated', toast: true, timer: 1800, position: 'top-end' })
    navigateTo('/app/invoices')
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Failed to generate', text: e?.data?.detail || '', toast: true, timer: 3000, position: 'top-end' })
  } finally {
    multiGenerating.value = false
  }
}

onMounted(() => {
  loadCustomers()
})
</script>

<style scoped>
.agree-item {
  transition: background 0.15s ease;
}
.agree-item.v-list-item--active {
  background: #eef2ff !important;
}
</style>
