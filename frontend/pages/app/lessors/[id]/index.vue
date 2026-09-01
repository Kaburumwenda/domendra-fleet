<template>
  <div class="d-flex flex-column ga-4">
    <!-- Header bar -->
    <div class="page-header-bar">
      <div class="d-flex align-center ga-2">
        <v-btn icon="mdi-arrow-left" variant="text" size="small" @click="goBack" />
        <div class="d-flex align-center ga-2">
          <v-avatar :color="lessor?.lessor_type === 'company' ? 'purple' : 'info'" variant="tonal" size="36">
            <v-icon>{{ lessor?.lessor_type === 'company' ? 'mdi-office-building-outline' : 'mdi-account-outline' }}</v-icon>
          </v-avatar>
          <div>
            <div class="d-flex align-center ga-2">
              <span class="text-h6 font-weight-bold page-header-title">{{ lessor?.display_name || 'Lessor Details' }}</span>
              <v-chip v-if="lessor" :color="lessor.lessor_type === 'company' ? 'purple' : 'info'" variant="tonal" size="small" class="text-capitalize">
                {{ lessor.lessor_type }}
              </v-chip>
            </div>
            <span class="text-caption text-medium-emphasis">Lessor profile & lease management</span>
          </div>
        </div>
      </div>
      <div class="d-flex ga-2">
        <v-btn v-can="'lessors:update'" variant="outlined" prepend-icon="mdi-pencil-outline" @click="editLessor">Edit</v-btn>
        <v-btn v-can="'lessors:create'" color="primary" prepend-icon="mdi-plus" @click="openPaymentDlg">Record Payment</v-btn>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="pending" class="d-flex justify-center align-center py-16">
      <v-progress-circular indeterminate color="primary" size="48" />
    </div>

    <template v-else-if="lessor">
      <!-- KPI Cards -->
      <v-row dense>
        <v-col cols="6" md="3">
          <StatCard
            label="Vehicles"
            :value="summary?.vehicle_count ?? 0"
            icon="mdi-truck-outline"
            icon-bg="#eef2ff"
            icon-color="primary"
            :subtitle="`${summary?.active_vehicles ?? 0} active`"
          />
        </v-col>
        <v-col cols="6" md="3">
          <StatCard
            label="Monthly Earnings"
            :value="fmtMoney(summary?.monthly_earnings ?? 0)"
            icon="mdi-cash-multiple"
            icon-bg="#ecfdf5"
            icon-color="success"
            :subtitle="`${fmtMoney(summary?.total_deposit_held ?? 0)} deposits`"
          />
        </v-col>
        <v-col cols="6" md="3">
          <StatCard
            label="Paid Total"
            :value="fmtMoney(summary?.payment_paid ?? 0)"
            icon="mdi-check-circle-outline"
            icon-bg="#fff7ed"
            icon-color="warning"
            :subtitle="`${summary?.paid_payments_count ?? 0} payments`"
          />
        </v-col>
        <v-col cols="6" md="3">
          <StatCard
            label="Unpaid / Overdue"
            :value="fmtMoney(summary?.payment_pending ?? 0)"
            icon="mdi-alert-circle-outline"
            icon-bg="#fef2f2"
            icon-color="error"
            :subtitle="`${summary?.overdue_payments_count ?? 0} overdue`"
          />
        </v-col>
      </v-row>

      <!-- Tabs -->
      <v-tabs v-model="tab" color="primary" density="compact">
        <v-tab value="overview" prepend-icon="mdi-chart-box-outline">Overview</v-tab>
        <v-tab value="vehicles" prepend-icon="mdi-truck-outline">
          Vehicles
          <v-badge v-if="summary?.vehicle_count" :content="summary.vehicle_count" color="primary" offset-x="6" offset-y="6" inline />
        </v-tab>
        <v-tab value="payments" prepend-icon="mdi-cash-multiple">
          Payments
          <v-badge v-if="summary?.pending_payments_count + (summary?.overdue_payments_count ?? 0)" :content="summary.pending_payments_count + (summary.overdue_payments_count ?? 0)" color="error" offset-x="6" offset-y="6" inline />
        </v-tab>
        <v-tab value="contracts" prepend-icon="mdi-file-document-multiple-outline">Contracts</v-tab>
        <v-tab value="documents" prepend-icon="mdi-paperclip">Documents</v-tab>
      </v-tabs>

      <v-window v-model="tab" class="flex-grow-1">
        <!-- ===================== OVERVIEW ===================== -->
        <v-window-item value="overview">
          <div class="d-flex flex-column ga-4">
            <!-- Contact info cards -->
            <v-row dense>
              <v-col cols="12" md="6">
                <v-card elevation="0" border rounded="lg">
                  <v-card-title class="text-subtitle-2 font-weight-bold"><v-icon size="18" color="primary" class="mr-1">mdi-account-details-outline</v-icon>Contact Information</v-card-title>
                  <v-card-text>
                    <v-row dense>
                      <v-col cols="6"><p class="text-caption text-medium-emphasis">Email</p><p class="text-body-2">{{ lessor.email || '—' }}</p></v-col>
                      <v-col cols="6"><p class="text-caption text-medium-emphasis">Phone</p><p class="text-body-2">{{ lessor.phone || '—' }}</p></v-col>
                      <v-col cols="6"><p class="text-caption text-medium-emphasis">Country</p><p class="text-body-2">{{ lessor.country || '—' }}</p></v-col>
                      <v-col cols="6"><p class="text-caption text-medium-emphasis">Tax ID</p><p class="text-body-2">{{ lessor.tax_id || '—' }}</p></v-col>
                      <v-col cols="6"><p class="text-caption text-medium-emphasis">Bank Account</p><p class="text-body-2">{{ lessor.bank_account || '—' }}</p></v-col>
                      <v-col cols="6"><p class="text-caption text-medium-emphasis">Payment Terms</p><p class="text-body-2">{{ lessor.payment_terms || '—' }}</p></v-col>
                      <v-col cols="6"><p class="text-caption text-medium-emphasis">Contract Start</p><p class="text-body-2">{{ lessor.contract_start_date ? formatDate(lessor.contract_start_date) : '—' }}</p></v-col>
                      <v-col cols="6"><p class="text-caption text-medium-emphasis">Contract End</p><p class="text-body-2">{{ lessor.contract_end_date ? formatDate(lessor.contract_end_date) : '—' }}</p></v-col>
                      <v-col cols="12" v-if="lessor.address"><p class="text-caption text-medium-emphasis">Address</p><p class="text-body-2">{{ lessor.address }}</p></v-col>
                      <v-col cols="12" v-if="lessor.notes"><p class="text-caption text-medium-emphasis">Notes</p><p class="text-body-2">{{ lessor.notes }}</p></v-col>
                    </v-row>
                  </v-card-text>
                </v-card>
              </v-col>

              <v-col cols="12" md="6">
                <v-card elevation="0" border rounded="lg" class="h-100">
                  <v-card-title class="text-subtitle-2 font-weight-bold"><v-icon size="18" color="success" class="mr-1">mdi-finance</v-icon>Financial Summary</v-card-title>
                  <v-card-text>
                    <v-row dense>
                      <v-col cols="6">
                        <v-card variant="outlined" rounded="lg" class="pa-3">
                          <p class="text-caption text-medium-emphasis">Monthly Earnings</p>
                          <p class="text-h6 font-weight-bold" style="color: #16a34a">{{ fmtMoney(summary?.monthly_earnings ?? 0) }}</p>
                          <p class="text-caption">from {{ summary?.vehicle_count ?? 0 }} vehicles</p>
                        </v-card>
                      </v-col>
                      <v-col cols="6">
                        <v-card variant="outlined" rounded="lg" class="pa-3">
                          <p class="text-caption text-medium-emphasis">Deposits Held</p>
                          <p class="text-h6 font-weight-bold" style="color: #1e293b">{{ fmtMoney(summary?.total_deposit_held ?? 0) }}</p>
                          <p class="text-caption">security deposits</p>
                        </v-card>
                      </v-col>
                      <v-col cols="6">
                        <v-card variant="outlined" rounded="lg" class="pa-3">
                          <p class="text-caption text-medium-emphasis">Contract Monthly</p>
                          <p class="text-h6 font-weight-bold" style="color: #1e293b">{{ fmtMoney(summary?.contract_monthly_total ?? 0) }}</p>
                          <p class="text-caption">{{ summary?.active_contracts ?? 0 }} active contracts</p>
                        </v-card>
                      </v-col>
                      <v-col cols="6">
                        <v-card variant="outlined" rounded="lg" class="pa-3">
                          <p class="text-caption text-medium-emphasis">Total Paid</p>
                          <p class="text-h6 font-weight-bold" style="color: #16a34a">{{ fmtMoney(summary?.payment_paid ?? 0) }}</p>
                          <p class="text-caption">{{ summary?.paid_payments_count ?? 0 }} payments</p>
                        </v-card>
                      </v-col>
                      <v-col cols="6">
                        <v-card variant="outlined" rounded="lg" class="pa-3">
                          <p class="text-caption text-medium-emphasis">Pending</p>
                          <p class="text-h6 font-weight-bold" style="color: #ea580c">{{ fmtMoney(summary?.payment_pending ?? 0) }}</p>
                          <p class="text-caption">{{ summary?.pending_payments_count ?? 0 }} pending</p>
                        </v-card>
                      </v-col>
                      <v-col cols="6">
                        <v-card variant="outlined" rounded="lg" class="pa-3">
                          <p class="text-caption text-medium-emphasis">Overdue</p>
                          <p class="text-h6 font-weight-bold" style="color: #dc2626">{{ fmtMoney(summary?.payment_overdue ?? 0) }}</p>
                          <p class="text-caption">{{ summary?.overdue_payments_count ?? 0 }} overdue</p>
                        </v-card>
                      </v-col>
                    </v-row>
                  </v-card-text>
                </v-card>
              </v-col>
            </v-row>

            <!-- Vehicle status breakdown -->
            <v-card v-if="summary?.vehicle_status_breakdown && Object.keys(summary.vehicle_status_breakdown).length > 0" elevation="0" border rounded="lg">
              <v-card-title class="text-subtitle-2 font-weight-bold"><v-icon size="18" color="info" class="mr-1">mdi-chart-donut</v-icon>Vehicle Status Breakdown</v-card-title>
              <v-card-text>
                <div class="d-flex flex-wrap ga-2">
                  <v-chip
                    v-for="(count, status) in summary.vehicle_status_breakdown"
                    :key="status"
                    :color="vehicleStatusColor(String(status))"
                    variant="tonal"
                    size="default"
                  >
                    <v-icon start size="small" :icon="vehicleStatusIcon(String(status))" />
                    {{ status }}: {{ count }}
                  </v-chip>
                </div>
              </v-card-text>
            </v-card>

            <!-- Vehicle earnings chart -->
            <DashboardChart
              v-if="earningsChartOption"
              :option="earningsChartOption"
              title="Monthly Earnings by Vehicle"
              icon="mdi-chart-bar"
              height="280px"
            />
          </div>
        </v-window-item>

        <!-- ===================== VEHICLES ===================== -->
        <v-window-item value="vehicles">
          <div class="d-flex flex-column ga-4">
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis">{{ lessorVehicles.length }} vehicles leased</span>
              <span class="text-body-2 font-weight-bold" style="color: #16a34a">Total monthly: {{ fmtMoney(summary?.monthly_earnings ?? 0) }}</span>
            </div>

            <v-card elevation="0" border rounded="lg">
              <v-data-table
                :headers="vehicleHeaders"
                :items="lessorVehicles"
                :items-per-page="15"
                :items-per-page-options="[10, 15, 25, 50]"
                hover
              >
                <template #item.display_name="{ item }">
                  <div class="d-flex align-center ga-2">
                    <v-icon color="primary" size="small">mdi-truck-outline</v-icon>
                    <span class="font-weight-medium">{{ item.display_name || `${item.make || ''} ${item.model || ''}`.trim() || `#${item.id}` }}</span>
                    <span v-if="item.status" class="text-caption text-medium-emphasis">({{ item.status }})</span>
                  </div>
                </template>

                <template #item.status="{ value }">
                  <v-chip :color="vehicleStatusColor(value)" variant="tonal" size="small" class="text-capitalize">{{ value }}</v-chip>
                </template>

                <template #item.lease_start_date="{ value }">
                  <span v-if="value" class="text-body-2">{{ formatDate(value) }}</span>
                  <span v-else class="text-medium-emphasis">—</span>
                </template>

                <template #item.lease_end_date="{ value }">
                  <span v-if="value" class="text-body-2">{{ formatDate(value) }}</span>
                  <span v-else class="text-medium-emphasis">—</span>
                </template>

                <template #item.lease_monthly_rate="{ value }">
                  <span v-if="value > 0" class="font-weight-bold" style="color: #16a34a">{{ fmtMoney(value) }}</span>
                  <span v-else class="text-medium-emphasis">—</span>
                </template>

                <template #item.deposit="{ value }">
                  <span v-if="value > 0" class="text-body-2">{{ fmtMoney(value) }}</span>
                  <span v-else class="text-medium-emphasis">—</span>
                </template>

                <template #no-data>
                  <div class="text-center py-12 text-medium-emphasis">
                    <v-icon size="48" class="mb-3">mdi-truck-off-outline</v-icon>
                    <p>No vehicles assigned to this lessor.</p>
                    <p class="text-caption mt-1">Assign vehicles by setting ownership to "Lease" and selecting this lessor.</p>
                  </div>
                </template>
              </v-data-table>
            </v-card>

            <!-- Summary totals -->
            <v-card v-if="lessorVehicles.length > 0" elevation="0" border rounded="lg">
              <v-card-text>
                <v-row dense>
                  <v-col cols="6" md="3"><p class="text-caption text-medium-emphasis">Total Vehicles</p><p class="text-h6 font-weight-bold">{{ lessorVehicles.length }}</p></v-col>
                  <v-col cols="6" md="3"><p class="text-caption text-medium-emphasis">Active Vehicles</p><p class="text-h6 font-weight-bold" style="color: #16a34a">{{ lessorVehicles.filter(v => v.status === 'active').length }}</p></v-col>
                  <v-col cols="6" md="3"><p class="text-caption text-medium-emphasis">Total Monthly Rate</p><p class="text-h6 font-weight-bold" style="color: #16a34a">{{ fmtMoney(totalMonthlyRate) }}</p></v-col>
                  <v-col cols="6" md="3"><p class="text-caption text-medium-emphasis">Total Deposits</p><p class="text-h6 font-weight-bold">{{ fmtMoney(totalDeposits) }}</p></v-col>
                </v-row>
              </v-card-text>
            </v-card>
          </div>
        </v-window-item>

        <!-- ===================== PAYMENTS ===================== -->
        <v-window-item value="payments">
          <div class="d-flex flex-column ga-4">
            <div class="d-flex align-center justify-space-between">
              <div class="d-flex ga-2">
                <v-chip color="success" variant="tonal" size="small">Paid: {{ fmtMoney(summary?.payment_paid ?? 0) }}</v-chip>
                <v-chip color="warning" variant="tonal" size="small">Pending: {{ fmtMoney((summary?.payment_pending ?? 0) - (summary?.payment_overdue ?? 0)) }}</v-chip>
                <v-chip color="error" variant="tonal" size="small">Overdue: {{ fmtMoney(summary?.payment_overdue ?? 0) }}</v-chip>
              </div>
              <div class="d-flex ga-2">
                <v-btn v-can="'lessors:update'" variant="outlined" prepend-icon="mdi-alert-circle-outline" size="small" @click="markAllOverdue">Mark Overdue</v-btn>
                <v-btn v-can="'lessors:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="openPaymentDlg">Record Payment</v-btn>
              </div>
            </div>

            <v-card elevation="0" border rounded="lg">
              <v-data-table
                :headers="paymentHeaders"
                :items="lessorPayments"
                :loading="paymentsPending"
                :items-per-page="15"
                :items-per-page-options="[10, 15, 25, 50]"
                hover
              >
                <template #item.amount="{ value }">
                  <span class="font-weight-bold">{{ fmtMoney(value) }}</span>
                </template>

                <template #item.status="{ value }">
                  <v-chip :color="paymentStatusColor(value)" variant="tonal" size="small" class="text-capitalize">{{ value }}</v-chip>
                </template>

                <template #item.due_date="{ value }">
                  <span v-if="value" class="text-body-2">{{ formatDate(value) }}</span>
                  <span v-else class="text-medium-emphasis">—</span>
                </template>

                <template #item.paid_date="{ value }">
                  <span v-if="value" class="text-body-2">{{ formatDate(value) }}</span>
                  <span v-else class="text-medium-emphasis">—</span>
                </template>

                <template #item.payment_method="{ value }">
                  <span v-if="value" class="text-caption text-capitalize">{{ value.replace('_', ' ') }}</span>
                  <span v-else class="text-medium-emphasis">—</span>
                </template>

                <template #item.actions="{ item }">
                  <div class="d-flex ga-1">
                    <v-btn v-can="'lessors:update'" v-if="item.status !== 'paid'" icon="mdi-check-circle-outline" variant="text" size="small" color="success" @click="markPaid(item)" />
                    <v-btn v-can="'lessors:update'" icon="mdi-pencil-outline" variant="text" size="small" @click="openPaymentDlg(item)" />
                    <v-btn v-can="'lessors:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deletePayment(item)" />
                  </div>
                </template>

                <template #no-data>
                  <div class="text-center py-12 text-medium-emphasis">
                    <v-icon size="48" class="mb-3">mdi-cash-multiple</v-icon>
                    <p>No payments recorded for this lessor.</p>
                  </div>
                </template>
              </v-data-table>
            </v-card>
          </div>
        </v-window-item>

        <!-- ===================== CONTRACTS ===================== -->
        <v-window-item value="contracts">
          <div class="d-flex flex-column ga-4">
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis">{{ lessorContracts.length }} contracts</span>
              <v-btn v-can="'lessors:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="openContractDlg">New Contract</v-btn>
            </div>

            <v-card elevation="0" border rounded="lg">
              <v-data-table
                :headers="contractHeaders"
                :items="lessorContracts"
                :loading="contractsPending"
                :items-per-page="10"
                hover
              >
                <template #item.title="{ item }">
                  <div>
                    <p class="font-weight-medium" style="color: #1e293b">{{ item.title }}</p>
                    <p class="text-caption text-medium-emphasis">{{ item.contract_number || '—' }}</p>
                  </div>
                </template>

                <template #item.status="{ value }">
                  <v-chip :color="contractStatusColor(value)" variant="tonal" size="small" class="text-capitalize">{{ value }}</v-chip>
                </template>

                <template #item.monthly_rate="{ value }">
                  <span class="font-weight-medium">{{ fmtMoney(value) }}</span>
                </template>

                <template #item.total_value="{ value }">
                  <span class="text-body-2">{{ fmtMoney(value) }}</span>
                </template>

                <template #item.days_remaining="{ value }">
                  <v-chip v-if="value !== null && value !== undefined" :color="value < 0 ? 'error' : value < 30 ? 'warning' : 'success'" variant="tonal" size="small">
                    {{ value < 0 ? `${Math.abs(value)}d past` : `${value}d left` }}
                  </v-chip>
                  <span v-else class="text-medium-emphasis">—</span>
                </template>

                <template #item.actions="{ item }">
                  <div class="d-flex ga-1">
                    <v-btn v-can="'lessors:update'" v-if="item.status !== 'active'" icon="mdi-play-circle-outline" variant="text" size="small" color="success" @click="activateContract(item)" />
                    <v-btn v-can="'lessors:update'" v-if="item.status === 'active'" icon="mdi-stop-circle-outline" variant="text" size="small" color="error" @click="terminateContract(item)" />
                    <v-btn v-can="'lessors:update'" icon="mdi-pencil-outline" variant="text" size="small" @click="openContractDlg(item)" />
                  </div>
                </template>

                <template #no-data>
                  <div class="text-center py-12 text-medium-emphasis">
                    <v-icon size="48" class="mb-3">mdi-file-document-edit-outline</v-icon>
                    <p>No contracts for this lessor.</p>
                  </div>
                </template>
              </v-data-table>
            </v-card>
          </div>
        </v-window-item>

        <!-- ===================== DOCUMENTS ===================== -->
        <v-window-item value="documents">
          <div class="d-flex flex-column ga-4">
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis">{{ lessorDocuments.length }} documents</span>
              <v-btn v-can="'lessors:create'" color="primary" prepend-icon="mdi-upload" size="small" @click="openDocDlg">Upload Document</v-btn>
            </div>

            <v-row dense>
              <v-col v-for="doc in lessorDocuments" :key="doc.id" cols="12" sm="6" md="4">
                <v-card elevation="0" border rounded="lg" class="h-100">
                  <v-card-text>
                    <div class="d-flex align-start justify-space-between mb-2">
                      <v-avatar :color="docTypeColor(doc.document_type)" variant="tonal" size="40">
                        <v-icon>{{ docTypeIcon(doc.document_type) }}</v-icon>
                      </v-avatar>
                      <v-chip :color="doc.is_expired ? 'error' : doc.expires_at ? 'success' : 'grey'" variant="tonal" size="x-small">
                        {{ doc.is_expired ? 'Expired' : doc.expires_at ? formatDate(doc.expires_at) : 'No expiry' }}
                      </v-chip>
                    </div>
                    <p class="text-body-2 font-weight-medium">{{ doc.name }}</p>
                    <p class="text-caption text-medium-emphasis">{{ doc.description || '—' }}</p>
                    <div class="d-flex align-center justify-space-between mt-3">
                      <v-chip size="x-small" variant="tonal" :color="docTypeColor(doc.document_type)" class="text-capitalize">{{ doc.document_type }}</v-chip>
                      <div class="d-flex ga-1">
                        <v-btn v-if="doc.file || doc.file_url" icon="mdi-download-outline" variant="text" size="small" :href="resolveDocUrl(doc)" target="_blank" />
                        <v-btn v-can="'lessors:update'" icon="mdi-pencil-outline" variant="text" size="small" @click="openDocDlg(doc)" />
                        <v-btn v-can="'lessors:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deleteDocument(doc)" />
                      </div>
                    </div>
                  </v-card-text>
                </v-card>
              </v-col>
            </v-row>

            <div v-if="!lessorDocuments.length" class="text-center py-12 text-medium-emphasis">
              <v-icon size="48" class="mb-3">mdi-paperclip</v-icon>
              <p>No documents uploaded for this lessor.</p>
            </div>
          </div>
        </v-window-item>
      </v-window>
    </template>

    <!-- Empty state -->
    <div v-else class="text-center py-16 text-medium-emphasis">
      <v-icon size="56" class="mb-3">mdi-handshake-outline</v-icon>
      <p class="text-body-1">Lessor not found</p>
    </div>

    <!-- =================== DIALOGS =================== -->
    <LessorFormDialog v-model="lessorDlg" :lessor="lessor" @saved="reload" />
    <ContractFormDialog v-model="contractDlg" :contract="editingContract" :lessors="lessorList" @saved="reloadContracts" />
    <PaymentFormDialog v-model="paymentDlg" :payment="editingPayment" :lessors="lessorList" :contracts="lessorContracts" @saved="reloadPayments" />
    <DocumentFormDialog v-model="docDlg" :document="editingDoc" :lessors="lessorList" @saved="reloadDocs" />
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

const route = useRoute()
const { $api, $swal } = useNuxtApp() as any
const { fmtMoney } = useCurrency()

const id = computed(() => route.params.id as string)
const tab = ref('overview')
const pending = ref(true)
const lessor = ref<any>(null)
const summary = ref<any>(null)

// ---- Fetch lessor + summary ----
async function load() {
  pending.value = true
  try {
    const [lessorData, summaryData] = await Promise.all([
      $api(`/lessors/${id.value}/`),
      $api(`/lessors/${id.value}/summary/`),
    ])
    lessor.value = lessorData
    summary.value = summaryData
  } catch (e) {
    console.error('Load lessor detail error:', e)
  } finally {
    pending.value = false
  }
}

// ---- Lessors list for dialog selectors ----
const lessorList = computed(() => lessor.value ? [lessor.value] : [])

// ---- Vehicles ----
const lessorVehicles = computed(() => summary.value?.vehicles || [])

const vehicleHeaders = [
  { title: 'Vehicle', key: 'display_name', sortable: true },
  { title: 'VIN', key: 'vin', sortable: false, width: '180px' },
  { title: 'License', key: 'license_plate', sortable: true, width: '120px' },
  { title: 'Status', key: 'status', sortable: true, width: '110px' },
  { title: 'Lease Start', key: 'lease_start_date', sortable: true, width: '130px' },
  { title: 'Lease End', key: 'lease_end_date', sortable: true, width: '130px' },
  { title: 'Monthly Rate', key: 'lease_monthly_rate', sortable: true, width: '140px' },
  { title: 'Deposit', key: 'deposit', sortable: true, width: '120px' },
]

const totalMonthlyRate = computed(() => {
  return lessorVehicles.value.reduce((sum: number, v: any) => sum + Number(v.lease_monthly_rate || 0), 0)
})
const totalDeposits = computed(() => {
  return lessorVehicles.value.reduce((sum: number, v: any) => sum + Number(v.deposit || 0), 0)
})

const earningsChartOption = computed(() => {
  const vehicles = lessorVehicles.value
  if (!vehicles.length) return null
  const names = vehicles.map((v: any) => v.display_name || `${v.make || ''} ${v.model || ''}`.trim() || `#${v.id}`)
  const rates = vehicles.map((v: any) => Number(v.lease_monthly_rate || 0))
  const deposits = vehicles.map((v: any) => Number(v.deposit || 0))
  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
    legend: { data: ['Monthly Rate', 'Deposit'], bottom: 0 },
    grid: { left: 50, right: 20, top: 30, bottom: 50 },
    xAxis: { type: 'category', data: names, axisLabel: { rotate: 30 } },
    yAxis: { type: 'value' },
    series: [
      { name: 'Monthly Rate', type: 'bar', data: rates, itemStyle: { color: '#16a34a', borderRadius: [6, 6, 0, 0] } },
      { name: 'Deposit', type: 'bar', data: deposits, itemStyle: { color: '#6366f1', borderRadius: [6, 6, 0, 0] } },
    ],
  }
})

function vehicleStatusColor(s: string) {
  return { active: 'success', in_maintenance: 'warning', out_of_service: 'error', inactive: 'grey', sold: 'default' }[s] || 'grey'
}
function vehicleStatusIcon(s: string) {
  return { active: 'mdi-check-circle', in_maintenance: 'mdi-wrench', out_of_service: 'mdi-alert', inactive: 'mdi-pause', sold: 'mdi-cash' }[s] || 'mdi-help-circle'
}

// ---- Payments ----
const paymentHeaders = [
  { title: 'Invoice', key: 'invoice_number', sortable: true, width: '140px' },
  { title: 'Amount', key: 'amount', sortable: true, width: '120px' },
  { title: 'Status', key: 'status', sortable: true, width: '100px' },
  { title: 'Due Date', key: 'due_date', sortable: true, width: '120px' },
  { title: 'Paid Date', key: 'paid_date', sortable: true, width: '120px' },
  { title: 'Method', key: 'payment_method', sortable: true, width: '120px' },
  { title: 'Reference', key: 'reference', sortable: false, width: '160px' },
  { title: '', key: 'actions', width: '120px', sortable: false },
]

const { data: paymentsData, pending: paymentsPending, refresh: refreshPayments } = useAsyncData(`lessor-payments-${id.value}`, () =>
  $api(`/lessors/payments/?lessor=${id.value}&page_size=1000`), { default: () => ({ results: [], count: 0 }) }
)
const lessorPayments = computed(() => paymentsData.value?.results || paymentsData.value || [])

const paymentDlg = ref(false)
const editingPayment = ref<any>(null)

function openPaymentDlg(p?: any) {
  editingPayment.value = p || null
  paymentDlg.value = true
}

async function reloadPayments() {
  await refreshPayments()
  await load()
}

async function markPaid(p: any) {
  await $api(`/lessors/payments/${p.id}/mark-paid/`, { method: 'POST' })
  await reloadPayments()
}

async function markAllOverdue() {
  const res = await $swal.fire({ icon: 'warning', title: 'Mark all past-due as overdue?', showCancelButton: true, confirmButtonText: 'Yes', confirmButtonColor: '#dc2626' })
  if (!res.isConfirmed) return
  await $api('/lessors/payments/mark-overdue/', { method: 'POST' })
  await reloadPayments()
}

async function deletePayment(p: any) {
  const res = await $swal.fire({ icon: 'warning', title: 'Delete payment?', showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#dc2626' })
  if (!res.isConfirmed) return
  await $api(`/lessors/payments/${p.id}/`, { method: 'DELETE' })
  await reloadPayments()
}

function paymentStatusColor(s: string) {
  return { pending: 'warning', paid: 'success', overdue: 'error', cancelled: 'grey' }[s] || 'grey'
}

// ---- Contracts ----
const contractHeaders = [
  { title: 'Contract', key: 'title', sortable: true },
  { title: 'Status', key: 'status', sortable: true, width: '110px' },
  { title: 'Monthly', key: 'monthly_rate', sortable: true, width: '110px' },
  { title: 'Total Value', key: 'total_value', sortable: true, width: '120px' },
  { title: 'Days Left', key: 'days_remaining', sortable: true, width: '100px', align: 'center' },
  { title: '', key: 'actions', width: '130px', sortable: false },
]

const { data: contractsData, pending: contractsPending, refresh: refreshContracts } = useAsyncData(`lessor-contracts-${id.value}`, () =>
  $api(`/lessors/contracts/?lessor=${id.value}&page_size=1000`), { default: () => ({ results: [], count: 0 }) }
)
const lessorContracts = computed(() => contractsData.value?.results || contractsData.value || [])

const contractDlg = ref(false)
const editingContract = ref<any>(null)

function openContractDlg(c?: any) {
  editingContract.value = c || null
  contractDlg.value = true
}

async function reloadContracts() {
  await refreshContracts()
  await load()
}

async function activateContract(c: any) {
  await $api(`/lessors/contracts/${c.id}/activate/`, { method: 'POST' })
  await reloadContracts()
}

async function terminateContract(c: any) {
  const res = await $swal.fire({ icon: 'warning', title: 'Terminate contract?', text: c.title, showCancelButton: true, confirmButtonText: 'Terminate', confirmButtonColor: '#dc2626' })
  if (!res.isConfirmed) return
  await $api(`/lessors/contracts/${c.id}/terminate/`, { method: 'POST' })
  await reloadContracts()
}

function contractStatusColor(s: string) {
  return { draft: 'grey', pending: 'warning', active: 'success', expired: 'error', terminated: 'error' }[s] || 'grey'
}

// ---- Documents ----
const { data: docsData, refresh: refreshDocs } = useAsyncData(`lessor-docs-${id.value}`, () =>
  $api(`/lessors/documents/?lessor=${id.value}&page_size=1000`), { default: () => ({ results: [], count: 0 }) }
)
const lessorDocuments = computed(() => docsData.value?.results || docsData.value || [])

const docDlg = ref(false)
const editingDoc = ref<any>(null)

function openDocDlg(d?: any) {
  editingDoc.value = d || null
  docDlg.value = true
}

async function reloadDocs() {
  await refreshDocs()
  await load()
}

async function deleteDocument(d: any) {
  const res = await $swal.fire({ icon: 'warning', title: 'Delete document?', text: d.name, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#dc2626' })
  if (!res.isConfirmed) return
  await $api(`/lessors/documents/${d.id}/`, { method: 'DELETE' })
  await reloadDocs()
}

function docTypeIcon(t: string) {
  return {
    contract: 'mdi-file-document-outline', insurance: 'mdi-shield-account-outline',
    registration: 'mdi-account-badge-outline', license: 'mdi-card-account-details-outline',
    tax: 'mdi-receipt-text-outline', bank: 'mdi-bank-outline', other: 'mdi-paperclip',
  }[t] || 'mdi-paperclip'
}
function docTypeColor(t: string) {
  return {
    contract: 'primary', insurance: 'success', registration: 'info', license: 'warning',
    tax: 'error', bank: 'purple', other: 'grey',
  }[t] || 'grey'
}
function resolveDocUrl(doc: any) {
  const cfg = useRuntimeConfig()
  const apiBase = cfg.public.apiBase || 'http://localhost:8000/api'
  const host = apiBase.replace(/\/api\/?$/, '')
  const url = doc.file_url || (doc.file && typeof doc.file === 'string' ? doc.file : '')
  if (!url) return ''
  if (/^https?:\/\//.test(url)) return url
  return `${host}/${url.replace(/^\/+/, '')}`
}

// ---- Lessor edit ----
const lessorDlg = ref(false)

async function reload() {
  await load()
}

function editLessor() {
  lessorDlg.value = true
}

// ---- Helpers ----
function formatDate(d: string) {
  if (!d) return ''
  return new Date(d).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' })
}

function goBack() { navigateTo('/app/lessors') }

// ---- Init ----
await useAsyncData(`lessor-detail-${id.value}`, async () => {
  await load()
  return true
})
</script>

<style scoped>
.page-header-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 16px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
}
.page-header-title {
  color: #0f172a;
}
</style>
