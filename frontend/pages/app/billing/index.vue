<template>
  <div class="d-flex flex-column ga-6">
    <!-- Page header -->
    <div class="d-flex flex-wrap align-center justify-space-between ga-3">
      <div>
        <h2 class="text-h5 font-weight-bold" style="color: #1e293b">Billing &amp; API Usage</h2>
        <p class="text-body-2 text-medium-emphasis">Monitor API consumption, project month-end costs, and manage invoices</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-chip color="primary" variant="tonal" size="small">
          <v-icon start size="x-small">mdi-cash-100</v-icon>
          Rate: $0.077 / 1,000 requests
        </v-chip>
        <v-btn variant="outlined" prepend-icon="mdi-refresh" :loading="pending" @click="refresh">Refresh</v-btn>
      </div>
    </div>

    <!-- Usage cost summary cards -->
    <v-row dense>
      <v-col cols="12" md="3">
        <StatCard
          label="Requests This Month"
          :value="fmtNum(sub?.request_count)"
          icon="mdi-api"
          icon-bg="#ecfdf5"
          icon-color="success"
          :subtitle="`Cycle day ${sub?.cycle_day || 0}`"
        />
      </v-col>
      <v-col cols="12" md="3">
        <StatCard
          label="Cost This Month (USD)"
          :value="`$${fmtMoneyRaw(sub?.estimated_cost_usd)}`"
          icon="mdi-currency-usd"
          icon-bg="#eef2ff"
          icon-color="primary"
          :subtitle="fmtCurrencyLabel(sub?.estimated_cost_local)"
        />
      </v-col>
      <v-col cols="12" md="3">
        <StatCard
          label="Projected Month-End (USD)"
          :value="`$${fmtMoneyRaw(sub?.projected_cost_usd)}`"
          icon="mdi-trending-up"
          icon-bg="#fff7ed"
          icon-color="warning"
          :subtitle="fmtCurrencyLabel(sub?.projected_cost_local)"
        />
      </v-col>
      <v-col cols="12" md="3">
        <StatCard
          label="Avg Requests / Day"
          :value="fmtNum(sub?.monthly_average)"
          icon="mdi-chart-bar"
          icon-bg="#f0fdf4"
          icon-color="success"
          :subtitle="`~${fmtNum(sub?.end_of_month_projection)} by period end`"
        />
      </v-col>
    </v-row>

    <!-- Rate explanation banner -->
    <v-alert type="info" variant="tonal" border density="comfortable" class="text-body-2">
      <template #prepend><v-icon color="info">mdi-information-outline</v-icon></template>
      Billing is purely usage-based. You are charged
      <strong>${{ sub?.rate_per_1000_requests ? fmtMoneyRaw(sub.rate_per_1000_requests) : '0.077' }}</strong>
      per 1,000 API requests in USD.
      <template v-if="billingCurrency && billingCurrency !== 'USD'">
        Amounts are converted to your local currency ({{ billingCurrency }}) at <strong>{{
          exchangeRate ? fmtRateRaw(exchangeRate) : '—'
        }}</strong> USD to {{ billingCurrency }} for display and payment.
      </template>
    </v-alert>

    <!-- Date filter bar -->
    <v-card elevation="0" border class="pa-4">
      <div class="d-flex flex-wrap align-center ga-3">
        <div class="d-flex align-center ga-1 flex-wrap">
          <v-btn
            v-for="opt in presets"
            :key="opt.value"
            :variant="activePreset === opt.value ? 'flat' : 'text'"
            :color="activePreset === opt.value ? 'primary' : undefined"
            size="small"
            @click="setPreset(opt.value)"
          >
            {{ opt.label }}
          </v-btn>
        </div>
        <v-spacer />
        <div class="d-flex align-center ga-2">
          <v-text-field
            v-model="customStart"
            type="date"
            label="From"
            density="compact"
            variant="outlined"
            hide-details
            style="max-width: 170px"
          />
          <v-text-field
            v-model="customEnd"
            type="date"
            label="To"
            density="compact"
            variant="outlined"
            hide-details
            style="max-width: 170px"
          />
          <v-btn color="primary" variant="flat" size="small" @click="setCustom">Apply</v-btn>
        </div>
      </div>
    </v-card>

    <!-- Analytics summary cards -->
    <v-row dense>
      <v-col cols="6" md="3">
        <StatCard
          label="Total Requests"
          :value="fmtNum(summary.total_requests)"
          icon="mdi-chart-line"
          icon-bg="#eef2ff"
          icon-color="primary"
          :trend="summary.request_trend"
        />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard label="Errors" :value="fmtNum(summary.total_errors)" icon="mdi-alert-circle-outline" icon-bg="#fef2f2" icon-color="error" />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard label="Error Rate" :value="`${summary.error_rate}%`" icon="mdi-percent-outline" icon-bg="#fffbeb" icon-color="warning" />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard label="Avg Response" :value="`${summary.avg_response_ms}ms`" icon="mdi-timer-sand" icon-bg="#f0fdf4" icon-color="success" />
      </v-col>
    </v-row>

    <!-- Charts row -->
    <v-row dense>
      <v-col cols="12" md="8">
        <DashboardChart :option="dailyChartOption" title="Daily API Requests" icon="mdi-chart-line" height="320px" />
      </v-col>
      <v-col cols="12" md="4">
        <DashboardChart :option="methodChartOption" title="Method Distribution" icon="mdi-chart-donut" height="320px" />
      </v-col>
    </v-row>

    <v-row dense>
      <v-col cols="12" md="8">
        <DashboardChart :option="hourChartOption" title="Usage by Hour of Day" icon="mdi-clock-outline" height="280px" />
      </v-col>
      <v-col cols="12" md="4">
        <DashboardChart :option="statusChartOption" title="Status Codes" icon="mdi-shield-check-outline" height="280px" />
      </v-col>
    </v-row>

    <!-- Usage projection card -->
    <v-card elevation="0" border class="pa-5">
      <div class="d-flex align-center justify-space-between mb-4">
        <h3 class="text-subtitle-1 font-weight-bold">Current Cycle Projection</h3>
        <v-chip color="primary" variant="tonal" size="small">
          $0.077/1k rate
        </v-chip>
      </div>
      <v-row dense>
        <v-col cols="6" md="3">
          <p class="text-caption text-medium-emphasis">Requests used</p>
          <p class="text-body-1 font-weight-bold">{{ fmtNum(sub?.request_count) }}</p>
        </v-col>
        <v-col cols="6" md="3">
          <p class="text-caption text-medium-emphasis">Avg / day</p>
          <p class="text-body-1 font-weight-bold">{{ fmtNum(sub?.monthly_average) }}</p>
        </v-col>
        <v-col cols="6" md="3">
          <p class="text-caption text-medium-emphasis">Projected requests</p>
          <p class="text-body-1 font-weight-bold">{{ fmtNum(sub?.end_of_month_projection) }}</p>
        </v-col>
        <v-col cols="6" md="3">
          <p class="text-caption text-medium-emphasis">Period ends</p>
          <p class="text-body-1 font-weight-bold">{{ fmtDate(sub?.current_period_end) }}</p>
        </v-col>
      </v-row>

      <v-divider class="my-4" />

      <v-row dense>
        <v-col cols="6" md="3">
          <p class="text-caption text-medium-emphasis">Cost so far (USD)</p>
          <p class="text-body-1 font-weight-bold">${{ fmtMoneyRaw(sub?.estimated_cost_usd) }}</p>
        </v-col>
        <v-col cols="6" md="3">
          <p class="text-caption text-medium-emphasis">Projected total (USD)</p>
          <p class="text-body-1 font-weight-bold">${{ fmtMoneyRaw(sub?.projected_cost_usd) }}</p>
        </v-col>
        <v-col v-if="billingCurrency && billingCurrency !== 'USD'" cols="6" md="3">
          <p class="text-caption text-medium-emphasis">Cost so far ({{ billingCurrency }})</p>
          <p class="text-body-1 font-weight-bold">{{ currencySymbol }}{{ fmtMoneyRaw(sub?.estimated_cost_local) }}</p>
        </v-col>
        <v-col v-if="billingCurrency && billingCurrency !== 'USD'" cols="6" md="3">
          <p class="text-caption text-medium-emphasis">Projected total ({{ billingCurrency }})</p>
          <p class="text-body-1 font-weight-bold">{{ currencySymbol }}{{ fmtMoneyRaw(sub?.projected_cost_local) }}</p>
        </v-col>
      </v-row>
    </v-card>

    <!-- Monthly Bills -->
    <v-card elevation="0" border class="pa-5">
      <div class="d-flex align-center justify-space-between mb-3">
        <div class="d-flex align-center ga-2">
          <h3 class="text-subtitle-1 font-weight-bold">Monthly Invoices</h3>
          <v-chip color="primary" variant="tonal" size="x-small">
            <v-icon start size="x-small">mdi-filter-outline</v-icon>
            Filtered by date range above
          </v-chip>
        </div>
        <v-chip v-if="overdueCount" color="error" variant="tonal" size="small">{{ overdueCount }} overdue</v-chip>
      </div>
      <v-alert v-if="overdueCount" type="error" variant="tonal" border class="mb-3">
        You have {{ overdueCount }} unpaid invoice(s) that are past due. Please settle them to avoid service interruption.
      </v-alert>

      <v-alert v-if="!bills.length && !pending" type="info" variant="tonal" border class="mb-3">
        No invoices found for the selected date range. Try adjusting your filters.
      </v-alert>

      <v-data-table :items="bills" :headers="billHeaders" density="comfortable" :items-per-page="10">
        <template #[`item.billing_month`]="{ item }">
          <span class="font-weight-medium">{{ item.billing_month ? formatMonth(item.billing_month) : '—' }}</span>
        </template>
        <template #[`item.invoice_number`]="{ item }">
          <span class="font-mono">{{ item.invoice_number || '—' }}</span>
        </template>
        <template #[`item.total_requests`]="{ item }">
          {{ item.total_requests?.toLocaleString() }}
        </template>
        <template #[`item.grand_total_usd`]="{ item }">
          <div class="d-flex flex-column">
            <span class="font-weight-bold">${{ fmtMoneyRaw(item.grand_total_usd || item.grand_total) }}</span>
            <span v-if="item.billing_currency && item.billing_currency !== 'USD'" class="text-caption text-medium-emphasis">
              {{ symbolForCode(item.billing_currency) }}{{ fmtMoneyRaw(item.grand_total_local) }}
            </span>
          </div>
        </template>
        <template #[`item.status`]="{ item }">
          <v-chip :color="billStatusColor(item.status)" variant="tonal" size="small" class="text-capitalize">
            <v-icon start size="x-small">{{ billStatusIcon(item.status) }}</v-icon>
            {{ item.status }}
          </v-chip>
        </template>
        <template #[`item.due_date`]="{ item }">
          {{ item.due_date ? fmtDate(item.due_date) : '—' }}
        </template>
        <template #[`item.actions`]="{ item }">
          <v-btn
            v-if="item.status === 'unpaid' || item.status === 'overdue'"
            color="primary"
            variant="flat"
            size="small"
            @click="openPayDialog(item)"
          >
            Pay Now
          </v-btn>
          <v-btn v-else variant="text" size="small" @click="openBillDetail(item)">View</v-btn>
        </template>
      </v-data-table>
    </v-card>

    <!-- Payment dialog -->
    <v-dialog v-model="payDialog" max-width="500">
      <v-card rounded="lg">
        <AppModalHeader title="Make a Payment" icon="mdi-cash-multiple" />
        <v-card-text class="pa-5">
          <div v-if="selectedBill" class="mb-4">
            <div class="d-flex justify-space-between mb-2">
              <span class="text-body-2 text-medium-emphasis">Invoice</span>
              <span class="text-body-2 font-mono">{{ selectedBill.invoice_number }}</span>
            </div>
            <div class="d-flex justify-space-between mb-2">
              <span class="text-body-2 text-medium-emphasis">Billing Month</span>
              <span class="text-body-2 font-weight-medium">{{ formatMonth(selectedBill.billing_month) }}</span>
            </div>
            <div class="d-flex justify-space-between mb-2">
              <span class="text-body-2 text-medium-emphasis">Total Requests</span>
              <span class="text-body-2 font-weight-medium">{{ selectedBill.total_requests?.toLocaleString() }}</span>
            </div>

            <!-- USD amounts -->
            <div class="d-flex justify-space-between mb-1 mt-2">
              <span class="text-body-2 text-medium-emphasis">Amount Due (USD)</span>
              <span class="text-body-1 font-weight-bold" style="color: #1e293b">
                ${{ fmtMoneyRaw(selectedBill.balance_due !== undefined ? selectedBill.balance_due : (selectedBill.grand_total_usd || selectedBill.grand_total)) }}
              </span>
            </div>
            <!-- Local currency amounts -->
            <div v-if="selectedBill.billing_currency && selectedBill.billing_currency !== 'USD'" class="d-flex justify-space-between mb-1">
              <span class="text-body-2 text-medium-emphasis">Amount Due ({{ selectedBill.billing_currency }})</span>
              <span class="text-body-1 font-weight-bold" style="color: #1e293b">
                {{ symbolForCode(selectedBill.billing_currency) }}{{ fmtMoneyRaw(selectedBill.balance_due_local !== undefined ? selectedBill.balance_due_local : selectedBill.grand_total_local) }}
              </span>
            </div>

            <v-divider class="mb-4 mt-2" />
          </div>

          <div class="d-flex flex-column ga-3">
            <v-text-field
              v-model="payAmount"
              label="Payment Amount (USD)"
              type="number"
              prefix="$"
              density="comfortable"
              variant="outlined"
              hide-details="auto"
            />
            <v-select
              v-model="payMethod"
              :items="payMethods"
              label="Payment Method"
              density="comfortable"
              variant="outlined"
              hide-details="auto"
            />
            <v-text-field
              v-model="payReference"
              label="Reference (optional)"
              density="comfortable"
              variant="outlined"
              hide-details="auto"
            />
          </div>
        </v-card-text>
        <v-card-actions class="pa-4 pt-0">
          <v-spacer />
          <v-btn variant="text" @click="payDialog = false">Cancel</v-btn>
          <v-btn color="primary" variant="flat" :loading="paying" @click="submitPayment">
            Pay ${{ fmtMoneyRaw(payAmount) }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Bill detail dialog -->
    <v-dialog v-model="detailDialog" max-width="620">
      <v-card rounded="lg">
        <AppModalHeader title="Invoice Details" icon="mdi-file-document-outline" />
        <v-card-text v-if="selectedBill" class="pa-5">
          <div class="d-flex justify-space-between mb-3">
            <div>
              <p class="text-caption text-medium-emphasis">Invoice Number</p>
              <p class="text-body-1 font-mono font-weight-medium">{{ selectedBill.invoice_number || '—' }}</p>
            </div>
            <div class="text-right">
              <p class="text-caption text-medium-emphasis">Status</p>
              <v-chip :color="billStatusColor(selectedBill.status)" variant="tonal" size="small" class="text-capitalize">{{ selectedBill.status }}</v-chip>
            </div>
          </div>

          <v-divider class="my-3" />

          <div class="d-flex justify-space-between mb-2">
            <span class="text-body-2 text-medium-emphasis">Billing Month</span>
            <span class="text-body-2 font-weight-medium">{{ formatMonth(selectedBill.billing_month) }}</span>
          </div>
          <div class="d-flex justify-space-between mb-2">
            <span class="text-body-2 text-medium-emphasis">Period</span>
            <span class="text-body-2">{{ fmtDate(selectedBill.period_start) }} – {{ fmtDate(selectedBill.period_end) }}</span>
          </div>
          <div class="d-flex justify-space-between mb-2">
            <span class="text-body-2 text-medium-emphasis">Total Requests</span>
            <span class="text-body-2 font-weight-medium">{{ selectedBill.total_requests?.toLocaleString() }}</span>
          </div>

          <v-divider class="my-3" />

          <!-- USD cost breakdown -->
          <p class="text-subtitle-2 font-weight-medium mb-2">Cost Breakdown (USD)</p>
          <div class="d-flex justify-space-between mb-2">
            <span class="text-body-2">Usage Cost (${{ fmtMoneyRaw(selectedBill.rate_per_1000_usd) }}/1k)</span>
            <span class="text-body-2">${{ fmtMoneyRaw(selectedBill.usage_cost_usd) }}</span>
          </div>
          <div class="d-flex justify-space-between mb-2">
            <span class="text-body-2 text-medium-emphasis">Tax</span>
            <span class="text-body-2">${{ fmtMoneyRaw(selectedBill.tax_amount_usd) }}</span>
          </div>
          <div class="d-flex justify-space-between mb-2">
            <span class="text-body-1 font-weight-bold">Grand Total (USD)</span>
            <span class="text-h6 font-weight-bold" style="color: #1e293b">${{ fmtMoneyRaw(selectedBill.grand_total_usd || selectedBill.grand_total) }}</span>
          </div>
          <div class="d-flex justify-space-between mb-2">
            <span class="text-body-2 text-success">Paid</span>
            <span class="text-body-2 font-weight-medium">${{ fmtMoneyRaw(selectedBill.paid_amount) }}</span>
          </div>
          <div class="d-flex justify-space-between">
            <span class="text-body-1 font-weight-bold">Balance Due (USD)</span>
            <span class="text-body-1 font-weight-bold" :class="(selectedBill.balance_due !== undefined ? selectedBill.balance_due : 0) > 0 ? 'text-error' : 'text-success'">
              ${{ fmtMoneyRaw(selectedBill.balance_due !== undefined ? selectedBill.balance_due : selectedBill.grand_total_usd) }}
            </span>
          </div>

          <!-- Local currency breakdown -->
          <template v-if="selectedBill.billing_currency && selectedBill.billing_currency !== 'USD'">
            <v-divider class="my-3" />
            <p class="text-subtitle-2 font-weight-medium mb-2">
              Cost Breakdown ({{ selectedBill.billing_currency }})
              <span class="text-caption text-medium-emphasis ml-1">@ {{ fmtRateRaw(selectedBill.exchange_rate) }}</span>
            </p>
            <div class="d-flex justify-space-between mb-2">
              <span class="text-body-2">Usage Cost</span>
              <span class="text-body-2">{{ symbolForCode(selectedBill.billing_currency) }}{{ fmtMoneyRaw(selectedBill.usage_cost || selectedBill.usage_cost_local) }}</span>
            </div>
            <div class="d-flex justify-space-between mb-2">
              <span class="text-body-2 text-medium-emphasis">Tax</span>
              <span class="text-body-2">{{ symbolForCode(selectedBill.billing_currency) }}{{ fmtMoneyRaw(selectedBill.tax_amount_local || selectedBill.tax_amount) }}</span>
            </div>
            <div class="d-flex justify-space-between mb-2">
              <span class="text-body-1 font-weight-bold">Grand Total ({{ selectedBill.billing_currency }})</span>
              <span class="text-body-1 font-weight-bold">
                {{ symbolForCode(selectedBill.billing_currency) }}{{ fmtMoneyRaw(selectedBill.grand_total_local || selectedBill.grand_total) }}
              </span>
            </div>
            <div class="d-flex justify-space-between mb-2">
              <span class="text-body-2 text-success">Paid</span>
              <span class="text-body-2 font-weight-medium">
                {{ symbolForCode(selectedBill.billing_currency) }}{{ fmtMoneyRaw(selectedBill.paid_amount_local !== undefined ? selectedBill.paid_amount_local : selectedBill.paid_amount) }}
              </span>
            </div>
            <div class="d-flex justify-space-between">
              <span class="text-body-1 font-weight-bold">Balance Due ({{ selectedBill.billing_currency }})</span>
              <span class="text-body-1 font-weight-bold" :class="(selectedBill.balance_due_local || 0) > 0 ? 'text-error' : 'text-success'">
                {{ symbolForCode(selectedBill.billing_currency) }}{{ fmtMoneyRaw(selectedBill.balance_due_local !== undefined ? selectedBill.balance_due_local : 0) }}
              </span>
            </div>
          </template>

          <div v-if="selectedBill.payments?.length" class="mt-4">
            <p class="text-subtitle-2 font-weight-medium mb-2">Payment History</p>
            <div v-for="pmt in selectedBill.payments" :key="pmt.id" class="d-flex justify-space-between pa-2 mb-1" style="background: #f8fafc; border-radius: 8px;">
              <div>
                <p class="text-body-2 font-weight-medium">
                  ${{ fmtMoneyRaw(pmt.amount) }}
                  <span v-if="selectedBill.billing_currency && selectedBill.billing_currency !== 'USD'" class="text-caption text-medium-emphasis">
                    ({{ symbolForCode(selectedBill.billing_currency) }}{{ fmtMoneyRaw(Number(pmt.amount) * Number(selectedBill.exchange_rate || 1)) }})
                  </span>
                  and <span class="text-capitalize">{{ pmt.method }}</span>
                </p>
                <p class="text-caption text-medium-emphasis">{{ fmtDate(pmt.created_at) }} {{ pmt.reference ? '· ' + pmt.reference : '' }}</p>
              </div>
              <v-chip color="success" size="x-small" variant="tonal">Paid</v-chip>
            </div>
          </div>
        </v-card-text>
        <v-card-actions class="pa-4 pt-0">
          <v-spacer />
          <v-btn variant="text" @click="detailDialog = false">Close</v-btn>
          <v-btn
            v-if="selectedBill && (selectedBill.status === 'unpaid' || selectedBill.status === 'overdue')"
            color="primary" variant="flat"
            @click="detailDialog = false; openPayDialog(selectedBill)"
          >
            Pay Now
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

const { $api, $swal } = useNuxtApp() as any
const { currencySymbol, currencyCode, fmtMoney, load: loadCurrency } = useCurrency()

// ── State ──────────────────────────────────────────────
const activePreset = ref('this_month')
const customStart = ref('')
const customEnd = ref('')
const analytics = ref<any>(null)
const sub = computed(() => analytics.value?.subscription || null)
const summary = computed(() => analytics.value?.summary || {})
const dailySeries = computed(() => analytics.value?.daily_series || [])
const methodDist = computed(() => analytics.value?.method_distribution || [])
const statusDist = computed(() => analytics.value?.status_distribution || [])
const hourDist = computed(() => analytics.value?.hour_distribution || [])

const bills = ref<any[]>([])
const pending = ref(false)
const billingCurrency = ref<string>('')
const exchangeRate = ref<string>('')

const presets = [
  { label: 'Today', value: 'today' },
  { label: 'This Week', value: 'this_week' },
  { label: 'Last Week', value: 'last_week' },
  { label: 'This Month', value: 'this_month' },
  { label: 'Last Month', value: 'last_month' },
  { label: 'This Quarter', value: 'this_quarter' },
  { label: 'This Year', value: 'this_year' },
  { label: 'Last Year', value: 'last_year' },
  { label: 'All Time', value: 'all_time' },
]

// ── Data fetching ───────────────────────────────────────
async function fetchAnalytics() {
  pending.value = true
  try {
    const params: Record<string, any> = {}
    if (activePreset.value === 'custom' && customStart.value && customEnd.value) {
      params.start = customStart.value
      params.end = customEnd.value
    } else {
      params.preset = activePreset.value
    }
    analytics.value = await $api('/billing/analytics/', { query: params })
  } catch (e: any) {
    analytics.value = null
    $swal?.fire?.({ icon: 'error', title: 'Failed to load analytics', toast: true, timer: 2000, position: 'top-end' })
  } finally {
    pending.value = false
  }
}

async function fetchBills() {
  try {
    const params: Record<string, any> = { page_size: 100 }
    if (activePreset.value === 'custom' && customStart.value && customEnd.value) {
      params.start = customStart.value
      params.end = customEnd.value
    } else if (activePreset.value !== 'all_time') {
      params.preset = activePreset.value
    }
    const res = await $api('/billing/bills/', { query: params })
    bills.value = res.results || res || []
  } catch {
    bills.value = []
  }
}

async function fetchExchangeRate() {
  try {
    const res = await $api('/billing/exchange-rate/')
    billingCurrency.value = res.currency || 'USD'
    exchangeRate.value = res.rate || '1'
  } catch {
    billingCurrency.value = currencyCode?.value || 'USD'
    exchangeRate.value = '1'
  }
}

function setPreset(val: string) {
  activePreset.value = val
  customStart.value = ''
  customEnd.value = ''
  fetchAnalytics()
  fetchBills()
}

function setCustom() {
  if (customStart.value && customEnd.value) {
    activePreset.value = 'custom'
    fetchAnalytics()
    fetchBills()
  }
}

async function refresh() {
  await Promise.all([fetchAnalytics(), fetchBills(), fetchExchangeRate()])
}

onMounted(async () => {
  await loadCurrency()
  fetchAnalytics()
  fetchBills()
  fetchExchangeRate()
})

// ── Computed UI helpers ─────────────────────────────────
const overdueCount = computed(() => bills.value.filter((b) => b.status === 'overdue').length)

function fmtNum(v: any): string {
  if (v === null || v === undefined) return '—'
  return Number(v).toLocaleString()
}

function fmtMoneyRaw(v: any): string {
  if (v === null || v === undefined || v === '') return '0.00'
  const n = Number(v)
  if (Number.isNaN(n)) return String(v)
  return n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

function fmtRateRaw(v: any): string {
  if (!v) return '—'
  const n = Number(v)
  if (Number.isNaN(n)) return String(v)
  return n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 4 })
}

function fmtCurrencyLabel(v: any): string | null {
  if (v === null || v === undefined || v === '') return null
  return `${currencySymbol.value}${fmtMoneyRaw(v)} local`
}

function symbolForCode(code: string): string {
  const symbols: Record<string, string> = {
    USD: '$', EUR: '€', GBP: '£', KES: 'KSh', NGN: '₦', ZAR: 'R',
    AED: 'AED', SAR: 'SAR', INR: '₹', CAD: 'C$', AUD: 'A$',
    JPY: '¥', CNY: '¥', BRL: 'R$', GHS: '₵', TZS: 'TSh',
    UGX: 'USh', RWF: 'FRw', ETB: 'Br',
  }
  return symbols[code] || code
}

function fmtDate(d: any): string {
  if (!d) return '—'
  try {
    return new Date(d).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' })
  } catch {
    return String(d)
  }
}
function formatMonth(d: any): string {
  if (!d) return '—'
  try {
    return new Date(d).toLocaleDateString('en-US', { year: 'numeric', month: 'long' })
  } catch {
    return String(d)
  }
}
function billStatusColor(s: string): string {
  return { paid: 'success', unpaid: 'warning', overdue: 'error', void: 'grey' }[s] || 'default'
}
function billStatusIcon(s: string): string {
  return {
    paid: 'mdi-check-circle', unpaid: 'mdi-clock-outline',
    overdue: 'mdi-alert-circle', void: 'mdi-cancel',
  }[s] || 'mdi-help-circle'
}

// ── Charts ──────────────────────────────────────────────
const dailyChartOption = computed(() => ({
  tooltip: { trigger: 'axis' },
  legend: { data: ['Requests', 'Errors'], bottom: 0 },
  grid: { left: '3%', right: '3%', bottom: '15%', top: '5%', containLabel: true },
  xAxis: {
    type: 'category',
    data: dailySeries.value.map((d: any) => d.date.slice(5)),
    axisLabel: { fontSize: 11 },
  },
  yAxis: [{ type: 'value', name: 'Requests' }],
  series: [
    {
      name: 'Requests',
      type: 'line',
      smooth: true,
      symbol: 'none',
      data: dailySeries.value.map((d: any) => d.requests),
      itemStyle: { color: '#6366f1' },
      areaStyle: { color: { type: 'linear', x: 0, y: 0, x2: 0, y2: 1, colorStops: [
        { offset: 0, color: 'rgba(99,102,241,0.25)' }, { offset: 1, color: 'rgba(99,102,241,0.02)' },
      ] } },
    },
    {
      name: 'Errors',
      type: 'bar',
      data: dailySeries.value.map((d: any) => d.errors),
      itemStyle: { color: '#ef4444' },
    },
  ],
}))

const methodChartOption = computed(() => ({
  tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
  legend: { bottom: 0, type: 'scroll' },
  series: [{
    type: 'pie',
    radius: ['40%', '70%'],
    center: ['50%', '45%'],
    data: methodDist.value.map((m: any) => ({ name: m.method, value: m.count })),
    itemStyle: { borderRadius: 6, borderColor: '#fff', borderWidth: 2 },
    label: { show: false },
  }],
  color: ['#6366f1', '#22c55e', '#f59e0b', '#ef4444', '#3b82f6'],
}))

const hourChartOption = computed(() => ({
  tooltip: { trigger: 'axis' },
  grid: { left: '3%', right: '5%', bottom: '10%', top: '8%', containLabel: true },
  xAxis: {
    type: 'category',
    data: Array.from({ length: 24 }, (_, i) => `${i}h`),
    axisLabel: { fontSize: 10 },
  },
  yAxis: { type: 'value', name: 'Requests' },
  series: [{
    type: 'bar',
    data: hourDist.value,
    itemStyle: { color: '#6366f1', borderRadius: [4, 4, 0, 0] },
  }],
}))

const statusChartOption = computed(() => ({
  tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
  legend: { bottom: 0, type: 'scroll' },
  series: [{
    type: 'pie',
    radius: '60%',
    center: ['50%', '45%'],
    data: statusDist.value.map((s: any) => ({
      name: `${s.status_code}`,
      value: s.count,
      itemStyle: { color: s.status_code >= 500 ? '#ef4444' : s.status_code >= 400 ? '#f59e0b' : '#22c55e' },
    })),
    label: { show: false },
  }],
}))

// ── Bills table headers ────────────────────────────────
const billHeaders = [
  { title: 'Invoice', key: 'invoice_number', sortable: true },
  { title: 'Month', key: 'billing_month', sortable: true },
  { title: 'Requests', key: 'total_requests', sortable: true, align: 'end' },
  { title: 'Amount (USD)', key: 'grand_total_usd', sortable: true, align: 'end' },
  { title: 'Status', key: 'status', sortable: true },
  { title: 'Due Date', key: 'due_date', sortable: true },
  { title: '', key: 'actions', sortable: false, align: 'end' },
]


// ── Payment dialog ──────────────────────────────────────
const payDialog = ref(false)
const detailDialog = ref(false)
const selectedBill = ref<any>(null)
const payAmount = ref(0)
const payMethod = ref('card')
const payReference = ref('')
const paying = ref(false)
const payMethods = [
  { title: 'Card', value: 'card' },
  { title: 'Bank Transfer', value: 'bank' },
  { title: 'Cash', value: 'cash' },
  { title: 'Wallet', value: 'wallet' },
  { title: 'Other', value: 'other' },
]

function openPayDialog(bill: any) {
  selectedBill.value = bill
  payAmount.value = Number(bill.balance_due !== undefined ? bill.balance_due : (bill.grand_total_usd || bill.grand_total)) || 0
  payMethod.value = 'card'
  payReference.value = ''
  payDialog.value = true
}

function openBillDetail(bill: any) {
  $api(`/billing/bills/${bill.id}/`).then((res: any) => {
    selectedBill.value = res
    detailDialog.value = true
  }).catch(() => {
    selectedBill.value = bill
    detailDialog.value = true
  })
}

async function submitPayment() {
  if (!selectedBill.value || payAmount.value <= 0) return
  paying.value = true
  try {
    await $api(`/billing/bills/${selectedBill.value.id}/pay/`, {
      method: 'POST',
      body: {
        amount: payAmount.value,
        method: payMethod.value,
        reference: payReference.value,
        currency: 'USD',
      },
    })
    payDialog.value = false
    $swal?.fire?.({ icon: 'success', title: 'Payment recorded', toast: true, timer: 1500, position: 'top-end' })
    await fetchBills()
  } catch (e: any) {
    $swal?.fire?.({ icon: 'error', title: 'Payment failed', text: e?.data?.detail || 'Please try again' })
  } finally {
    paying.value = false
  }
}

useHead({ title: 'Billing and Usage' })
</script>

<style scoped>
.font-mono {
  font-family: 'Courier New', monospace;
}
</style>
