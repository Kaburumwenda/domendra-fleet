<template>
  <div class="d-flex flex-column ga-4">
    <!-- ── Header ── -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-2">
      <div>
        <h1 class="text-h5 font-weight-bold" style="color: #1e293b">Vehicle Financing Monitor</h1>
        <p class="text-caption text-medium-emphasis">Manage fleet vehicles under bank/institution financing</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn v-can="'financing:view'" variant="text" size="small" prepend-icon="mdi-refresh" @click="refreshAll">Refresh</v-btn>
        <v-btn v-can="'financing:create'" color="indigo" size="small" prepend-icon="mdi-plus" @click="openLoanDialog()">New Financing</v-btn>
      </div>
    </div>

    <!-- ── Portfolio KPI Cards ── -->
    <v-row dense>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #6366f1 0%, #818cf8 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2">
            <v-icon color="white" size="small">mdi-bank-outline</v-icon>
            <span style="color: #fff; font-size: 0.75rem; font-weight: 500">Active Loans</span>
          </div>
          <p class="text-h4 font-weight-bold" style="color: #fff !important">{{ stats.active_loans }}</p>
          <p style="color: #fff; opacity: 0.85; font-size: 0.75rem">{{ stats.total_loans }} total · {{ stats.pending_loans }} pending</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #0ea5e9 0%, #38bdf8 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2">
            <v-icon color="white" size="small">mdi-cash-multiple</v-icon>
            <span style="color: #fff; font-size: 0.75rem; font-weight: 500">Total Principal</span>
          </div>
          <p class="text-h4 font-weight-bold" style="color: #fff !important">{{ currencySymbol }}{{ Number(stats.active_principal || 0).toLocaleString() }}</p>
          <p style="color: #fff; opacity: 0.85; font-size: 0.75rem">{{ currencySymbol }}{{ Number(stats.total_principal || 0).toLocaleString() }} disbursed</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2">
            <v-icon color="white" size="small">mdi-chart-line-variant</v-icon>
            <span style="color: #fff; font-size: 0.75rem; font-weight: 500">Outstanding</span>
          </div>
          <p class="text-h4 font-weight-bold" style="color: #fff !important">{{ currencySymbol }}{{ Number(stats.total_outstanding || 0).toLocaleString() }}</p>
          <p style="color: #fff; opacity: 0.85; font-size: 0.75rem">{{ currencySymbol }}{{ Number(stats.due_this_month || 0).toLocaleString() }} due this month</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #ef4444 0%, #f87171 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2">
            <v-icon color="white" size="small">mdi-alert-circle</v-icon>
            <span style="color: #fff; font-size: 0.75rem; font-weight: 500">Overdue</span>
          </div>
          <p class="text-h4 font-weight-bold" style="color: #fff !important">{{ stats.overdue_count }}</p>
          <p style="color: #fff; opacity: 0.85; font-size: 0.75rem">{{ currencySymbol }}{{ Number(stats.overdue_amount || 0).toLocaleString() }} overdue</p>
        </v-card>
      </v-col>
    </v-row>

    <!-- ── Tabs ── -->
    <v-card elevation="0" border rounded="lg">
      <v-tabs v-model="tab" density="compact" color="primary">
        <v-tab value="loans" prepend-icon=" mdi-bank">Loans</v-tab>
        <v-tab value="payments" prepend-icon=" mdi-calendar-clock">Payments</v-tab>
        <v-tab value="overdue" prepend-icon=" mdi-alert-decagram">Overdue</v-tab>
      </v-tabs>
      <v-divider />

      <v-window v-model="tab" class="pa-4">
        <!-- ── Loans Tab ── -->
        <v-window-item value="loans">
          <div class="d-flex align-center ga-2 mb-3 flex-wrap">
            <v-text-field v-model="search" density="compact" variant="outlined" prepend-inner-icon="mdi-magnify" placeholder="Search loans…" hide-details style="max-width: 280px" />
            <v-select v-model="statusFilter" :items="statusOptions" item-title="label" item-value="value" density="compact" variant="outlined" label="Status" clearable hide-details style="max-width: 150px" />
            <v-spacer />
            <v-btn v-can="'financing:export'" variant="text" size="small" prepend-icon="mdi-download" @click="exportLoans">Export</v-btn>
          </div>
          <v-data-table :headers="loanHeaders" :items="filteredLoans" :loading="loansPending" density="compact" items-per-page="15" hover>
            <template #item.loan_no="{ value }">
              <span class="font-weight-medium" style="color: #4f46e5; font-family: monospace">{{ value }}</span>
            </template>
            <template #item.vehicle_name="{ value, item }">
              <div class="d-flex align-center ga-2">
                <v-icon size="small" color="medium-emphasis">mdi-car</v-icon>
                <div>
                  <div class="text-body-2 font-weight-medium">{{ value || '—' }}</div>
                  <div v-if="item.vehicle_license_plate" class="text-caption text-medium-emphasis">{{ item.vehicle_license_plate }}</div>
                </div>
              </div>
            </template>
            <template #item.principal_amount="{ value }">{{ currencySymbol }}{{ Number(value || 0).toLocaleString() }}</template>
            <template #item.monthly_instalment="{ value }">{{ currencySymbol }}{{ Number(value || 0).toLocaleString() }}</template>
            <template #item.outstanding_balance="{ value }">
              <span class="font-weight-bold" style="color: #ea580c">{{ currencySymbol }}{{ Number(value || 0).toLocaleString() }}</span>
            </template>
            <template #item.progress_pct="{ value }">
              <div class="d-flex align-center ga-2" style="min-width: 120px">
                <v-progress-linear :model-value="Number(value || 0)" color="indigo" height="6" rounded />
                <span class="text-caption font-weight-medium" style="min-width: 42px">{{ Number(value || 0).toFixed(0) }}%</span>
              </div>
            </template>
            <template #item.status="{ value }">
              <v-chip size="small" :color="loanStatusColor(value)" variant="flat" class="text-capitalize">{{ loanStatusLabel(value) }}</v-chip>
            </template>
            <template #item.is_overdue="{ value }">
              <v-icon v-if="value" color="error" size="small">mdi-alert-circle</v-icon>
              <span v-else class="text-caption text-medium-emphasis">—</span>
            </template>
            <template #item.actions="{ item }">
              <div class="d-flex ga-1">
                <v-btn v-can="'financing:view'" icon="mdi-eye-outline" size="x-small" variant="text" color="primary" @click="viewLoan(item)" />
                <v-btn v-can="'financing:update'" icon="mdi-pencil-outline" size="x-small" variant="text" color="warning" @click="openLoanDialog(item)" />
                <v-btn v-can="'financing:delete'" icon="mdi-delete-outline" size="x-small" variant="text" color="error" @click="deleteLoan(item)" />
              </div>
            </template>
          </v-data-table>
        </v-window-item>

        <!-- ── Payments Tab ── -->
        <v-window-item value="payments">
          <div class="d-flex align-center ga-2 mb-3 flex-wrap">
            <v-text-field v-model="paymentSearch" density="compact" variant="outlined" prepend-inner-icon="mdi-magnify" placeholder="Search payments…" hide-details style="max-width: 280px" />
            <v-select v-model="paymentStatusFilter" :items="paymentStatusOptions" item-title="label" item-value="value" density="compact" variant="outlined" label="Status" clearable hide-details style="max-width: 150px" />
            <v-spacer />
            <v-btn v-can="'financing:approve'" color="success" size="small" variant="tonal" prepend-icon="mdi-cash-plus" @click="openRecordPaymentDialog">Record Payment</v-btn>
          </div>
          <v-data-table :headers="paymentHeaders" :items="filteredPayments" :loading="paymentsPending" density="compact" items-per-page="15" hover>
            <template #item.loan_no="{ value, item }">
              <div>
                <span class="font-weight-medium" style="color: #4f46e5; font-family: monospace">{{ value }}</span>
                <div class="text-caption text-medium-emphasis">{{ item.vehicle_name }}</div>
              </div>
            </template>
            <template #item.instalment_no="{ value }">
              <v-chip size="small" variant="tonal" color="primary">#{{ value }}</v-chip>
            </template>
            <template #item.due_date="{ value }">
              <span class="text-body-2">{{ formatDate(value) }}</span>
            </template>
            <template #item.amount="{ value }">{{ currencySymbol }}{{ Number(value || 0).toLocaleString() }}</template>
            <template #item.outstanding="{ value }">
              <span :class="Number(value) > 0 ? 'font-weight-bold' : ''" :style="Number(value) > 0 ? 'color: #ea580c' : ''">
                {{ currencySymbol }}{{ Number(value || 0).toLocaleString() }}
              </span>
            </template>
            <template #item.status="{ value }">
              <v-chip size="small" :color="paymentStatusColor(value)" variant="flat" class="text-capitalize">{{ paymentStatusLabel(value) }}</v-chip>
            </template>
            <template #item.paid_date="{ value }">
              <span v-if="value" class="text-caption">{{ formatDate(value) }}</span>
              <span v-else class="text-caption text-medium-emphasis">—</span>
            </template>
            <template #item.actions="{ item }">
              <div class="d-flex ga-1">
                <v-btn v-if="item.status !== 'paid' && item.status !== 'waived'" v-can="'financing:approve'" icon="mdi-cash-plus" size="x-small" variant="text" color="success" @click="openRecordPaymentDialog(item)" />
                <v-btn v-if="item.evidence_file_url" icon="mdi-paperclip" size="x-small" variant="text" color="info" @click="viewEvidence(item)" />
                <v-btn v-can="'financing:view'" icon="mdi-eye-outline" size="x-small" variant="text" color="primary" @click="viewPayment(item)" />
                <v-btn v-can="'financing:delete'" icon="mdi-delete-outline" size="x-small" variant="text" color="error" @click="deletePayment(item)" />
              </div>
            </template>
          </v-data-table>
        </v-window-item>

        <!-- ── Overdue Tab ── -->
        <v-window-item value="overdue">
          <v-alert v-if="!overduePayments.length" type="info" variant="tonal" density="comfortable" icon="mdi-check-circle-outline" class="mb-3">
            No overdue payments. All instalments are up to date.
          </v-alert>
          <v-data-table v-else :headers="paymentHeaders" :items="overduePayments" density="compact" items-per-page="15" hover>
            <template #item.loan_no="{ value, item }">
              <span class="font-weight-medium" style="color: #dc2626; font-family: monospace">{{ value }}</span>
              <div class="text-caption text-medium-emphasis">{{ item.vehicle_name }}</div>
            </template>
            <template #item.instalment_no="{ value }"><v-chip size="small" variant="tonal" color="error">#{{ value }}</v-chip></template>
            <template #item.due_date="{ value }">
              <span class="text-body-2 text-error">{{ formatDate(value) }}</span>
            </template>
            <template #item.amount="{ value }">{{ currencySymbol }}{{ Number(value || 0).toLocaleString() }}</template>
            <template #item.outstanding="{ value }">
              <span class="font-weight-bold text-error">{{ currencySymbol }}{{ Number(value || 0).toLocaleString() }}</span>
            </template>
            <template #item.status="{ value }">
              <v-chip size="small" color="error" variant="flat" class="text-capitalize">{{ paymentStatusLabel(value) }}</v-chip>
            </template>
            <template #item.actions="{ item }">
              <v-btn v-can="'financing:approve'" icon="mdi-check-circle-outline" size="x-small" variant="text" color="success" @click="markPaymentPaid(item)">Settle</v-btn>
            </template>
          </v-data-table>
        </v-window-item>
      </v-window>
    </v-card>

    <!-- ── Loan Form Dialog ── -->
    <v-dialog v-model="loanDialog" max-width="780">
      <v-card rounded="lg">
        <v-card-title class="text-h6 d-flex align-center ga-2">
          <v-icon color="indigo">{{ editingLoan ? 'mdi-pencil' : 'mdi-bank-plus' }}</v-icon>
          {{ editingLoan ? 'Edit Financing' : 'New Vehicle Financing' }}
        </v-card-title>
        <v-divider />
        <v-card-text class="pt-4">
          <v-row dense>
            <v-col cols="12" md="6">
              <v-autocomplete
                v-model="loanForm.vehicle"
                :items="vehicleOptions"
                item-title="label"
                item-value="id"
                label="Vehicle *"
                density="compact"
                variant="outlined"
                hide-details="auto"
                class="mb-3"
                :loading="vehiclesLoading"
                prepend-inner-icon="mdi-car"
                clearable
              />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="loanForm.bank_name" label="Bank / Institution *" density="compact" variant="outlined" hide-details="auto" class="mb-3" prepend-inner-icon="mdi-bank" />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="loanForm.branch" label="Branch" density="compact" variant="outlined" hide-details="auto" class="mb-3" prepend-inner-icon="mdi-map-marker-outline" />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="loanForm.account_no" label="Account Number" density="compact" variant="outlined" hide-details="auto" class="mb-3" prepend-inner-icon="mdi-numeric" />
            </v-col>
            <v-col cols="12" md="4">
              <v-text-field v-model.number="loanForm.principal_amount" type="number" label="Principal Amount *" density="compact" variant="outlined" hide-details="auto" class="mb-3" :prefix="currencySymbol" prepend-inner-icon="mdi-cash" />
            </v-col>
            <v-col cols="12" md="4">
              <v-text-field v-model.number="loanForm.interest_rate" type="number" step="0.01" label="Interest Rate (%)" density="compact" variant="outlined" hide-details="auto" class="mb-3" prepend-inner-icon="mdi-percent" />
            </v-col>
            <v-col cols="12" md="4">
              <v-select v-model="loanForm.interest_type" :items="interestTypes" item-title="label" item-value="value" label="Interest Type" density="compact" variant="outlined" hide-details="auto" class="mb-3" />
            </v-col>
            <v-col cols="12" md="4">
              <v-text-field v-model.number="loanForm.tenor_months" type="number" label="Tenor (months) *" density="compact" variant="outlined" hide-details="auto" class="mb-3" prepend-inner-icon="mdi-calendar" />
            </v-col>
            <v-col cols="12" md="4">
              <v-text-field v-model.number="loanForm.monthly_instalment" type="number" label="Monthly Instalment (EMI)" density="compact" variant="outlined" hide-details="auto" class="mb-3" :prefix="currencySymbol" prepend-inner-icon="mdi-calendar-clock" />
            </v-col>
            <v-col cols="12" md="4">
              <v-select v-model="loanForm.status" :items="statusOptions" item-title="label" item-value="value" label="Status" density="compact" variant="outlined" hide-details="auto" class="mb-3" />
            </v-col>
          </v-row>
          <v-divider class="my-3" />
          <div class="text-caption font-weight-bold mb-2" style="color: #64748b">DATES</div>
          <v-row dense>
            <v-col cols="12" md="4">
              <v-text-field v-model="loanForm.disbursement_date" type="date" label="Disbursement Date" density="compact" variant="outlined" hide-details="auto" class="mb-3" />
            </v-col>
            <v-col cols="12" md="4">
              <v-text-field v-model="loanForm.first_payment_date" type="date" label="First Payment Date" density="compact" variant="outlined" hide-details="auto" class="mb-3" hint="Enter to auto-generate payment schedule" />
            </v-col>
            <v-col cols="12" md="4">
              <v-text-field v-model="loanForm.maturity_date" type="date" label="Maturity Date" density="compact" variant="outlined" hide-details="auto" class="mb-3" />
            </v-col>
          </v-row>
          <v-divider class="my-3" />
          <div class="text-caption font-weight-bold mb-2" style="color: #64748b">ADDITIONAL</div>
          <v-row dense>
            <v-col cols="12" md="4">
              <v-text-field v-model.number="loanForm.down_payment" type="number" label="Down Payment" density="compact" variant="outlined" hide-details="auto" class="mb-3" :prefix="currencySymbol" />
            </v-col>
            <v-col cols="12" md="4">
              <v-text-field v-model.number="loanForm.processing_fee" type="number" label="Processing Fee" density="compact" variant="outlined" hide-details="auto" class="mb-3" :prefix="currencySymbol" />
            </v-col>
            <v-col cols="12" md="4">
              <v-text-field v-model.number="loanForm.collateral_value" type="number" label="Collateral Value" density="compact" variant="outlined" hide-details="auto" class="mb-3" :prefix="currencySymbol" />
            </v-col>
          </v-row>
          <v-textarea v-model="loanForm.remarks" label="Remarks" density="compact" variant="outlined" hide-details="auto" rows="2" class="mt-2" />
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn variant="text" @click="loanDialog = false">Cancel</v-btn>
          <v-btn color="primary" :loading="saving" @click="saveLoan">{{ editingLoan ? 'Update' : 'Create' }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- ── View Loan Dialog ── -->
    <v-dialog v-model="viewDialog" max-width="720">
      <v-card v-if="viewingLoan" rounded="lg">
        <v-card-title class="d-flex align-center justify-space-between">
          <div class="d-flex align-center ga-2">
            <v-avatar size="36" rounded="lg" :color="loanStatusColor(viewingLoan.status)">
              <v-icon color="white" size="20">mdi-bank</v-icon>
            </v-avatar>
            <div>
              <v-chip size="small" :color="loanStatusColor(viewingLoan.status)" variant="flat" class="text-capitalize mb-1">{{ loanStatusLabel(viewingLoan.status) }}</v-chip>
              <div class="text-h6 font-weight-bold" style="color: #1e293b">{{ viewingLoan.bank_name }}</div>
            </div>
          </div>
          <span style="font-family: monospace; font-size: 0.85rem; color: #4f46e5">{{ viewingLoan.loan_no }}</span>
        </v-card-title>
        <v-divider />
        <v-card-text>
          <v-row dense class="mb-2">
            <v-col cols="12" md="6">
              <div class="financing-detail-box mb-3">
                <div class="text-caption font-weight-bold" style="color: #64748b">VEHICLE</div>
                <div class="text-body-1 font-weight-medium">{{ viewingLoan.vehicle_name || '—' }}</div>
                <div v-if="viewingLoan.vehicle_license_plate" class="text-caption text-medium-emphasis">{{ viewingLoan.vehicle_license_plate }}</div>
              </div>
            </v-col>
            <v-col cols="12" md="6">
              <div class="financing-detail-box mb-3">
                <div class="text-caption font-weight-bold" style="color: #64748b">PRINCIPAL</div>
                <div class="text-h6 font-weight-bold" style="color: #4f46e5">{{ currencySymbol }}{{ Number(viewingLoan.principal_amount || 0).toLocaleString() }}</div>
                <div class="text-caption text-medium-emphasis">{{ viewingLoan.tenor_months }} months · {{ interestTypeLabel(viewingLoan.interest_type) }}</div>
              </div>
            </v-col>
          </v-row>
          <v-divider class="mb-3" />
          <!-- Progress -->
          <div class="d-flex align-center ga-3 mb-3">
            <div style="flex: 1">
              <div class="d-flex justify-space-between mb-1">
                <span class="text-caption font-weight-bold" style="color: #64748b">REPAYMENT PROGRESS</span>
                <span class="text-caption font-weight-bold" style="color: #4f46e5">{{ Number(viewingLoan.progress_pct || 0).toFixed(1) }}%</span>
              </div>
              <v-progress-linear :model-value="Number(viewingLoan.progress_pct || 0)" color="indigo" height="10" rounded />
            </div>
          </div>
          <v-divider class="mb-3" />
          <!-- Mini stats -->
          <v-row dense>
            <v-col cols="6" md="3">
              <div class="financing-stat-box">
                <div class="text-caption" style="color: #64748b">Total Payable</div>
                <div class="text-body-2 font-weight-bold">{{ currencySymbol }}{{ Number(viewingLoan.total_payable || 0).toLocaleString() }}</div>
              </div>
            </v-col>
            <v-col cols="6" md="3">
              <div class="financing-stat-box">
                <div class="text-caption" style="color: #64748b">Paid</div>
                <div class="text-body-2 font-weight-bold" style="color: #059669">{{ currencySymbol }}{{ Number(viewingLoan.total_paid || 0).toLocaleString() }}</div>
              </div>
            </v-col>
            <v-col cols="6" md="3">
              <div class="financing-stat-box">
                <div class="text-caption" style="color: #64748b">Outstanding</div>
                <div class="text-body-2 font-weight-bold" style="color: #ea580c">{{ currencySymbol }}{{ Number(viewingLoan.outstanding_balance || 0).toLocaleString() }}</div>
              </div>
            </v-col>
            <v-col cols="6" md="3">
              <div class="financing-stat-box">
                <div class="text-caption" style="color: #64748b">LTV Ratio</div>
                <div class="text-body-2 font-weight-bold">{{ Number(viewingLoan.ltv_ratio || 0).toFixed(1) }}%</div>
              </div>
            </v-col>
          </v-row>
          <v-divider class="my-3" />
          <v-row dense>
            <v-col cols="6" md="3"><div class="text-caption" style="color: #64748b">Interest Rate</div><div class="text-body-2 font-weight-medium">{{ Number(viewingLoan.interest_rate || 0).toFixed(2) }}%</div></v-col>
            <v-col cols="6" md="3"><div class="text-caption" style="color: #64748b">Monthly EMI</div><div class="text-body-2 font-weight-medium">{{ currencySymbol }}{{ Number(viewingLoan.monthly_instalment || 0).toLocaleString() }}</div></v-col>
            <v-col cols="6" md="3"><div class="text-caption" style="color: #64748b">Disbursed</div><div class="text-body-2">{{ viewingLoan.disbursement_date ? formatDate(viewingLoan.disbursement_date) : '—' }}</div></v-col>
            <v-col cols="6" md="3"><div class="text-caption" style="color: #64748b">Maturity</div><div class="text-body-2">{{ viewingLoan.maturity_date ? formatDate(viewingLoan.maturity_date) : '—' }}</div></v-col>
          </v-row>
        </v-card-text>
        <v-card-actions>
          <v-btn v-if="viewingLoan.status === 'active'" v-can="'financing:approve'" variant="text" color="success" prepend-icon="mdi-check-circle-outline" @click="closeLoan(viewingLoan)">Mark Closed</v-btn>
          <v-btn v-can="'financing:update'" variant="text" color="warning" prepend-icon="mdi-pencil-outline" @click="openLoanDialog(viewingLoan); viewDialog = false">Edit</v-btn>
          <v-spacer />
          <v-btn variant="text" @click="viewDialog = false">Close</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- ── Payment Detail Dialog ── -->
    <v-dialog v-model="paymentDialog" max-width="540">
      <v-card v-if="viewingPayment" rounded="lg">
        <v-card-title class="d-flex align-center ga-2">
          <v-icon :color="paymentStatusColor(viewingPayment.status)">mdi-calendar-clock</v-icon>
          <span class="text-h6">Instalment #{{ viewingPayment.instalment_no }}</span>
        </v-card-title>
        <v-divider />
        <v-card-text>
          <div class="d-flex align-center justify-space-between mb-3">
            <div>
              <div class="text-caption" style="color: #64748b">LOAN</div>
              <div class="text-body-2 font-weight-medium" style="color: #4f46e5">{{ viewingPayment.loan_no }}</div>
              <div class="text-caption text-medium-emphasis">{{ viewingPayment.vehicle_name }}</div>
            </div>
            <v-chip :color="paymentStatusColor(viewingPayment.status)" variant="flat" class="text-capitalize">{{ paymentStatusLabel(viewingPayment.status) }}</v-chip>
          </div>
          <v-divider class="mb-3" />
          <v-row dense>
            <v-col cols="6"><div class="text-caption" style="color: #64748b">Due Date</div><div class="text-body-2 font-weight-medium">{{ formatDate(viewingPayment.due_date) }}</div></v-col>
            <v-col cols="6"><div class="text-caption" style="color: #64748b">Amount</div><div class="text-body-1 font-weight-bold">{{ currencySymbol }}{{ Number(viewingPayment.amount || 0).toLocaleString() }}</div></v-col>
            <v-col cols="6"><div class="text-caption" style="color: #64748b">Principal Component</div><div class="text-body-2">{{ currencySymbol }}{{ Number(viewingPayment.principal_component || 0).toLocaleString() }}</div></v-col>
            <v-col cols="6"><div class="text-caption" style="color: #64748b">Interest Component</div><div class="text-body-2">{{ currencySymbol }}{{ Number(viewingPayment.interest_component || 0).toLocaleString() }}</div></v-col>
            <v-col cols="6" v-if="viewingPayment.paid_date"><div class="text-caption" style="color: #64748b">Paid Date</div><div class="text-body-2">{{ formatDate(viewingPayment.paid_date) }}</div></v-col>
            <v-col cols="6" v-if="viewingPayment.paid_amount"><div class="text-caption" style="color: #64748b">Paid Amount</div><div class="text-body-2 font-weight-bold" style="color: #059669">{{ currencySymbol }}{{ Number(viewingPayment.paid_amount || 0).toLocaleString() }}</div></v-col>
            <v-col cols="6" v-if="viewingPayment.payment_method"><div class="text-caption" style="color: #64748b">Method</div><div class="text-body-2">{{ viewingPayment.payment_method_display || viewingPayment.payment_method }}</div></v-col>
            <v-col cols="6" v-if="viewingPayment.reference_no"><div class="text-caption" style="color: #64748b">Reference</div><div class="text-body-2" style="font-family: monospace">{{ viewingPayment.reference_no }}</div></v-col>
          </v-row>
        </v-card-text>
        <v-card-actions>
          <v-btn v-if="viewingPayment.status !== 'paid' && viewingPayment.status !== 'waived'" v-can="'financing:approve'" color="success" prepend-icon="mdi-cash-plus" @click="openRecordPaymentDialog(viewingPayment); paymentDialog = false">Record Payment</v-btn>
          <v-spacer />
          <v-btn variant="text" @click="paymentDialog = false">Close</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- ── Record Payment Dialog ── -->
    <v-dialog v-model="recordDialog" max-width="600">
      <v-card rounded="lg">
        <v-card-title class="text-h6 d-flex align-center ga-2">
          <v-icon color="success">mdi-cash-plus</v-icon>
          Record Payment
        </v-card-title>
        <v-divider />
        <v-card-text class="pt-4">
          <div v-if="recordPayment.targetPayment" class="record-summary mb-4">
            <div class="d-flex align-center justify-space-between">
              <div>
                <div class="text-caption" style="color: #64748b">INSTALMENT</div>
                <div class="text-body-2 font-weight-bold">{{ recordPayment.targetPayment.loan_no }} · #{{ recordPayment.targetPayment.instalment_no }}</div>
                <div class="text-caption text-medium-emphasis mt-1">{{ recordPayment.targetPayment.vehicle_name }}</div>
              </div>
              <div class="text-right">
                <div class="text-caption" style="color: #64748b">DUE</div>
                <div class="text-body-2 font-weight-bold">{{ currencySymbol }}{{ Number(recordPayment.targetPayment.amount || 0).toLocaleString() }}</div>
              </div>
            </div>
          </div>
          <template v-else>
            <v-autocomplete
              v-model="recordPayment.vehicle_id"
              :items="vehicleOptions"
              item-title="label"
              item-value="id"
              label="Vehicle (filter)"
              density="compact"
              variant="outlined"
              hide-details="auto"
              class="mb-3"
              prepend-inner-icon="mdi-car"
              clearable
              :loading="vehiclesLoading"
              hint="Filter instalments by vehicle, or leave blank to see all"
              persistent-hint
            />
            <v-select
              v-model="recordPayment.targetPaymentId"
              :items="unpaidPaymentsForSelect"
              item-title="label"
              item-value="id"
              label="Select Instalment *"
              density="compact"
              variant="outlined"
              hide-details="auto"
              class="mb-3"
              prepend-inner-icon="mdi-format-list-numbered"
              hint="Choose which instalment to record payment for"
              persistent-hint
            />
          </template>

          <v-row dense>
            <v-col cols="6">
              <v-text-field
                v-model="recordPayment.paid_amount"
                type="number"
                label="Paid Amount"
                density="compact"
                variant="outlined"
                hide-details="auto"
                class="mb-3"
                :prefix="currencySymbol"
                prepend-inner-icon="mdi-cash"
              />
            </v-col>
            <v-col cols="6">
              <v-text-field
                v-model="recordPayment.paid_date"
                type="date"
                label="Payment Date"
                density="compact"
                variant="outlined"
                hide-details="auto"
                class="mb-3"
                prepend-inner-icon="mdi-calendar-check"
              />
            </v-col>
          </v-row>

          <v-select
            v-model="recordPayment.payment_method"
            :items="paymentMethodOptions"
            item-title="label"
            item-value="value"
            label="Payment Method"
            density="compact"
            variant="outlined"
            hide-details="auto"
            class="mb-3"
            prepend-inner-icon="mdi-bank-transfer"
          />

          <v-text-field
            v-model="recordPayment.reference_no"
            label="Reference / Transaction ID"
            density="compact"
            variant="outlined"
            hide-details="auto"
            class="mb-3"
            prepend-inner-icon="mdi-identifier"
          />

          <!-- Evidence File Upload -->
          <div class="evidence-upload-zone" @click="$refs.evidenceInput.click()" @dragover.prevent @drop.prevent="onEvidenceDrop">
            <input ref="evidenceInput" type="file" accept="image/*,.pdf" style="display:none" @change="onEvidenceSelect" />
            <div v-if="!recordPayment.evidencePreview" class="text-center py-4">
              <v-icon size="32" color="medium-emphasis">mdi-cloud-upload-outline</v-icon>
              <p class="text-caption font-weight-medium mt-1" style="color: #64748b">Drag and drop payment evidence here</p>
              <p class="text-caption text-medium-emphasis">or click to browse — receipts, screenshots, bank confirmations (PDF/Image)</p>
            </div>
            <div v-else class="d-flex align-center ga-2 pa-2">
              <v-img v-if="recordPayment.evidencePreview" :src="recordPayment.evidencePreview" max-width="60" max-height="60" class="rounded-lg flex-grow-0" cover eager />
              <div class="flex-grow-1">
                <div class="text-body-2 font-weight-medium">{{ recordPayment.evidence_file_name }}</div>
                <v-btn size="x-small" variant="text" color="error" prepend-icon="mdi-close" @click.stop="clearEvidence">Remove</v-btn>
              </div>
              <v-icon color="success">mdi-check-circle</v-icon>
            </div>
          </div>

          <v-textarea
            v-model="recordPayment.remarks"
            label="Remarks (optional)"
            density="compact"
            variant="outlined"
            hide-details="auto"
            rows="2"
            class="mt-3"
          />
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn variant="text" @click="recordDialog = false">Cancel</v-btn>
          <v-btn color="success" :loading="recordSaving" prepend-icon="mdi-check-circle" @click="submitRecordPayment">Record Payment</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- ── Evidence Preview Dialog ── -->
    <v-dialog v-model="evidenceDialog" max-width="640">
      <v-card rounded="lg">
        <v-card-title class="d-flex align-center ga-2">
          <v-icon color="info">mdi-paperclip</v-icon>
          Payment Evidence
        </v-card-title>
        <v-divider />
        <v-card-text class="text-center">
          <img v-if="evidencePreviewUrl && !evidenceIsPdf" :src="evidencePreviewUrl" alt="Payment evidence" style="max-width: 100%; border-radius: 8px;" />
          <div v-else-if="evidencePreviewUrl && evidenceIsPdf" class="pa-8">
            <v-icon size="48" color="red">mdi-file-pdf-box</v-icon>
            <p class="text-body-1 mt-3">PDF Document</p>
            <v-btn color="primary" class="mt-3" prepend-icon="mdi-download" :href="evidencePreviewUrl" target="_blank">View PDF</v-btn>
          </div>
        </v-card-text>
        <v-card-actions>
          <v-btn color="info" variant="text" prepend-icon="mdi-download" :href="evidencePreviewUrl" target="_blank" download>Download</v-btn>
          <v-spacer />
          <v-btn variant="text" @click="evidenceDialog = false">Close</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

const { $api, $swal } = useNuxtApp() as any
const { currencySymbol } = useCurrency()
const { resolveMediaUrl } = useMediaUrl()

/* ── Tabs ── */
const tab = ref('loans')

/* ── Loans data ── */
const { data: loansData, pending: loansPending, refresh: refreshLoans } = useAsyncData('financing-loans', () =>
  $api('/financing/', { query: { page_size: 1000 } }), { default: () => ({ results: [], count: 0 }) } as any
)
const loans = computed(() => loansData.value?.results || loansData.value || [])

/* ── Payments data ── */
const { data: paymentsData, pending: paymentsPending, refresh: refreshPayments } = useAsyncData('financing-payments', () =>
  $api('/financing/payments/', { query: { page_size: 1000 } }), { default: () => ({ results: [], count: 0 }) } as any
)
const payments = computed(() => paymentsData.value?.results || paymentsData.value || [])

/* ── Overdue ── */
const { data: overdueData, refresh: refreshOverdue } = useAsyncData('financing-overdue', () =>
  $api('/financing/payments/overdue/'), { default: () => [] } as any
)
const overduePayments = computed(() => overdueData.value || [])

/* ── Dashboard stats ── */
const { data: statsData, refresh: refreshStats } = useAsyncData('financing-stats', () =>
  $api('/financing/dashboard/'), { default: () => ({}) } as any
)
const stats = computed(() => statsData.value || {})

function refreshAll() {
  refreshLoans()
  refreshPayments()
  refreshOverdue()
  refreshStats()
}

/* ── Filters ── */
const search = ref('')
const statusFilter = ref<string | null>(null)
const paymentSearch = ref('')
const paymentStatusFilter = ref<string | null>(null)

const statusOptions = [
  { label: 'Pending', value: 'pending' },
  { label: 'Active', value: 'active' },
  { label: 'Closed', value: 'closed' },
  { label: 'Defaulted', value: 'defaulted' },
  { label: 'Restructured', value: 'restructured' },
]
const paymentStatusOptions = [
  { label: 'Upcoming', value: 'upcoming' },
  { label: 'Paid', value: 'paid' },
  { label: 'Partially Paid', value: 'partially_paid' },
  { label: 'Overdue', value: 'overdue' },
  { label: 'Waived', value: 'waived' },
]
const interestTypes = [
  { label: 'Fixed', value: 'fixed' },
  { label: 'Floating', value: 'floating' },
  { label: 'Reducing Balance', value: 'reducing' },
]

const loanHeaders = [
  { title: 'Loan No', key: 'loan_no', width: '140px', sortable: true },
  { title: 'Vehicle', key: 'vehicle_name', width: '180px' },
  { title: 'Bank', key: 'bank_name', width: '150px', sortable: true },
  { title: 'Principal', key: 'principal_amount', width: '130px', align: 'end' as const, sortable: true },
  { title: 'EMI', key: 'monthly_instalment', width: '120px', align: 'end' as const },
  { title: 'Outstanding', key: 'outstanding_balance', width: '130px', align: 'end' as const },
  { title: 'Progress', key: 'progress_pct', width: '160px' },
  { title: 'Status', key: 'status', width: '110px', sortable: true },
  { title: 'Overdue', key: 'is_overdue', width: '80px' },
  { title: '', key: 'actions', width: '110px', sortable: false },
]

const paymentHeaders = [
  { title: 'Loan', key: 'loan_no', width: '160px' },
  { title: 'Inst.', key: 'instalment_no', width: '60px' },
  { title: 'Due Date', key: 'due_date', width: '110px', sortable: true },
  { title: 'Amount', key: 'amount', width: '120px', align: 'end' as const, sortable: true },
  { title: 'Outstanding', key: 'outstanding', width: '120px', align: 'end' as const },
  { title: 'Status', key: 'status', width: '110px', sortable: true },
  { title: 'Paid Date', key: 'paid_date', width: '110px' },
  { title: '', key: 'actions', width: '100px', sortable: false },
]

const filteredLoans = computed(() => {
  let list = loans.value
  if (search.value) {
    const s = search.value.toLowerCase()
    list = list.filter((l: any) =>
      (l.loan_no || '').toLowerCase().includes(s) ||
      (l.bank_name || '').toLowerCase().includes(s) ||
      (l.vehicle_name || '').toLowerCase().includes(s) ||
      (l.account_no || '').toLowerCase().includes(s)
    )
  }
  if (statusFilter.value) list = list.filter((l: any) => l.status === statusFilter.value)
  return list
})

const filteredPayments = computed(() => {
  let list = payments.value
  if (paymentSearch.value) {
    const s = paymentSearch.value.toLowerCase()
    list = list.filter((p: any) =>
      (p.loan_no || '').toLowerCase().includes(s) ||
      (p.reference_no || '').toLowerCase().includes(s) ||
      (p.vehicle_name || '').toLowerCase().includes(s)
    )
  }
  if (paymentStatusFilter.value) list = list.filter((p: any) => p.status === paymentStatusFilter.value)
  return list
})

/* ── Vehicles ── */
const vehicleOptions = ref<any[]>([])
const vehiclesLoading = ref(false)

async function loadVehicles() {
  vehiclesLoading.value = true
  try {
    const res = await $api('/vehicles/vehicles/', { query: { page_size: 500 } })
    const list = res?.results || res || []
    vehicleOptions.value = list.map((v: any) => ({
      id: v.id,
      label: `${v.display_name || v.license_plate || `#${v.id}`}${v.license_plate ? ` · ${v.license_plate}` : ''}`,
    }))
  } catch {
    vehicleOptions.value = []
  } finally {
    vehiclesLoading.value = false
  }
}

/* ── Loan Form ── */
const loanDialog = ref(false)
const editingLoan = ref<any>(null)
const saving = ref(false)

const defaultLoanForm = () => ({
  vehicle: null as number | null,
  bank_name: '',
  branch: '',
  account_no: '',
  principal_amount: 0,
  interest_rate: 0,
  interest_type: 'fixed',
  tenor_months: 0,
  monthly_instalment: 0,
  status: 'pending',
  disbursement_date: '',
  first_payment_date: '',
  maturity_date: '',
  down_payment: 0,
  processing_fee: 0,
  collateral_value: 0,
  insurance_premium: 0,
  remarks: '',
})
const loanForm = reactive(defaultLoanForm())

function openLoanDialog(item?: any) {
  if (item) {
    editingLoan.value = item
    Object.assign(loanForm, {
      vehicle: item.vehicle,
      bank_name: item.bank_name || '',
      branch: item.branch || '',
      account_no: item.account_no || '',
      principal_amount: Number(item.principal_amount) || 0,
      interest_rate: Number(item.interest_rate) || 0,
      interest_type: item.interest_type || 'fixed',
      tenor_months: item.tenor_months || 0,
      monthly_instalment: Number(item.monthly_instalment) || 0,
      status: item.status || 'pending',
      disbursement_date: item.disbursement_date || '',
      first_payment_date: item.first_payment_date || '',
      maturity_date: item.maturity_date || '',
      down_payment: Number(item.down_payment) || 0,
      processing_fee: Number(item.processing_fee) || 0,
      collateral_value: Number(item.collateral_value) || 0,
      insurance_premium: Number(item.insurance_premium) || 0,
      remarks: item.remarks || '',
    })
  } else {
    editingLoan.value = null
    Object.assign(loanForm, defaultLoanForm())
  }
  loanDialog.value = true
}

async function saveLoan() {
  if (!loanForm.vehicle || !loanForm.bank_name || !loanForm.principal_amount) {
    $swal.fire({ icon: 'warning', title: 'Missing fields', text: 'Vehicle, bank name, and principal are required.', toast: true, timer: 2500, position: 'top-end' })
    return
  }
  saving.value = true
  try {
    const payload = { ...loanForm }
    if (!payload.disbursement_date) payload.disbursement_date = null
    if (!payload.first_payment_date) payload.first_payment_date = null
    if (!payload.maturity_date) payload.maturity_date = null
    if (editingLoan.value) {
      await $api(`/financing/${editingLoan.value.id}/`, { method: 'PATCH', body: payload })
      $swal.fire({ icon: 'success', title: 'Financing updated', toast: true, timer: 1500, position: 'top-end' })
    } else {
      await $api('/financing/', { method: 'POST', body: payload })
      $swal.fire({ icon: 'success', title: 'Financing created', toast: true, timer: 1500, position: 'top-end' })
    }
    loanDialog.value = false
    await refreshAll()
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Failed', text: e?.data?.detail || '', toast: true, timer: 3000, position: 'top-end' })
  } finally {
    saving.value = false
  }
}

async function deleteLoan(item: any) {
  const res = await $swal.fire({ icon: 'warning', title: 'Delete financing?', text: `${item.loan_no} — ${item.bank_name}`, showCancelButton: true, confirmButtonColor: '#dc2626' })
  if (!res.isConfirmed) return
  try {
    await $api(`/financing/${item.id}/`, { method: 'DELETE' })
    await refreshAll()
    $swal.fire({ icon: 'success', title: 'Deleted', toast: true, timer: 1500, position: 'top-end' })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Delete failed', text: e?.data?.detail || '', toast: true, timer: 2500, position: 'top-end' })
  }
}

/* ── View Loan ── */
const viewDialog = ref(false)
const viewingLoan = ref<any>(null)

async function viewLoan(item: any) {
  try {
    const data = await $api(`/financing/${item.id}/`)
    viewingLoan.value = data
    viewDialog.value = true
  } catch {
    $swal.fire({ icon: 'error', title: 'Failed to load', toast: true, timer: 2000, position: 'top-end' })
  }
}

async function closeLoan(loan: any) {
  const res = await $swal.fire({ icon: 'question', title: 'Mark as closed?', text: `${loan.loan_no} will be marked as settled.`, showCancelButton: true, confirmButtonColor: '#059669' })
  if (!res.isConfirmed) return
  try {
    await $api(`/financing/${loan.id}/mark-closed/`, { method: 'PATCH' })
    await refreshAll()
    viewDialog.value = false
    $swal.fire({ icon: 'success', title: 'Loan closed', toast: true, timer: 1500, position: 'top-end' })
  } catch {
    $swal.fire({ icon: 'error', title: 'Failed', toast: true, timer: 2000, position: 'top-end' })
  }
}

/* ── View Payment ── */
const paymentDialog = ref(false)
const viewingPayment = ref<any>(null)

function viewPayment(item: any) {
  viewingPayment.value = item
  paymentDialog.value = true
}

async function markPaymentPaid(item: any) {
  const res = await $swal.fire({
    icon: 'question',
    title: 'Mark as paid?',
    text: `Instalment #${item.instalment_no} — ${currencySymbol.value}${Number(item.amount || 0).toLocaleString()}`,
    showCancelButton: true,
    confirmButtonColor: '#059669',
  })
  if (!res.isConfirmed) return
  try {
    await $api(`/financing/payments/${item.id}/mark-paid/`, { method: 'PATCH', body: { paid_amount: item.amount } })
    await refreshAll()
    $swal.fire({ icon: 'success', title: 'Payment marked as paid', toast: true, timer: 1500, position: 'top-end' })
  } catch {
    $swal.fire({ icon: 'error', title: 'Failed', toast: true, timer: 2000, position: 'top-end' })
  }
}

/* ── Record Payment with Evidence ── */
const paymentMethodOptions = [
  { label: 'Bank Transfer', value: 'bank_transfer' },
  { label: 'Cheque', value: 'cheque' },
  { label: 'Cash', value: 'cash' },
  { label: 'Mobile Money', value: 'mobile_money' },
  { label: 'Auto Debit', value: 'auto_debit' },
  { label: 'Other', value: 'other' },
]

const recordDialog = ref(false)
const recordSaving = ref(false)
const recordPayment = reactive({
  targetPaymentId: null as number | null,
  targetPayment: null as any,
  vehicle_id: null as number | null,
  paid_amount: 0,
  paid_date: '',
  payment_method: '',
  reference_no: '',
  remarks: '',
  evidence_file: null as File | null,
  evidence_file_name: '',
  evidencePreview: '',
})

function openRecordPaymentDialog(item?: any) {
  // Reset
  recordPayment.targetPaymentId = null
  recordPayment.targetPayment = null
  recordPayment.vehicle_id = null
  recordPayment.paid_amount = 0
  recordPayment.paid_date = new Date().toISOString().slice(0, 10)
  recordPayment.payment_method = ''
  recordPayment.reference_no = ''
  recordPayment.remarks = ''
  recordPayment.evidence_file = null
  recordPayment.evidence_file_name = ''
  recordPayment.evidencePreview = ''

  if (item) {
    // Direct instalment selected
    recordPayment.targetPayment = item
    recordPayment.targetPaymentId = item.id
    recordPayment.paid_amount = Number(item.outstanding || item.amount || 0)
  }
  recordDialog.value = true
}

const unpaidPaymentsForSelect = computed(() => {
  let list = payments.value
    .filter((p: any) => p.status !== 'paid' && p.status !== 'waived')
  // Filter by vehicle if selected
  if (recordPayment.vehicle_id) {
    list = list.filter((p: any) => {
      // Match by loan's vehicle — find the loan for this payment
      const loan = loans.value.find((l: any) => l.id === p.loan)
      return loan && loan.vehicle === recordPayment.vehicle_id
    })
  }
  return list.map((p: any) => ({
    id: p.id,
    label: `${p.loan_no} · #${p.instalment_no} — ${currencySymbol.value}${Number(p.amount || 0).toLocaleString()} (due ${formatDate(p.due_date)})`,
  }))
})

// When vehicle filter changes, clear the selected instalment if it's no longer in the list
watch(() => recordPayment.vehicle_id, () => {
  if (recordPayment.targetPaymentId) {
    const stillValid = unpaidPaymentsForSelect.value.some((opt: any) => opt.id === recordPayment.targetPaymentId)
    if (!stillValid) {
      recordPayment.targetPaymentId = null
      recordPayment.paid_amount = 0
    }
  }
})

// When target is selected from dropdown, pre-fill paid_amount
watch(() => recordPayment.targetPaymentId, (newId) => {
  if (newId && !recordPayment.targetPayment) {
    const p = payments.value.find((x: any) => x.id === newId)
    if (p) recordPayment.paid_amount = Number(p.outstanding || p.amount || 0)
  }
})

function onEvidenceSelect(e: Event) {
  const input = e.target as HTMLInputElement
  if (input.files && input.files[0]) handleEvidenceFile(input.files[0])
}

function onEvidenceDrop(e: DragEvent) {
  const f = e.dataTransfer?.files?.[0]
  if (f) handleEvidenceFile(f)
}

function handleEvidenceFile(file: File) {
  const allowed = ['image/jpeg', 'image/png', 'image/jpg', 'image/webp', 'image/gif', 'application/pdf']
  if (!allowed.includes(file.type)) {
    $swal.fire({ icon: 'warning', title: 'Invalid file', text: 'Only images (JPG, PNG, WebP, GIF) or PDF files are accepted.', toast: true, timer: 3000, position: 'top-end' })
    return
  }
  if (file.size > 10 * 1024 * 1024) {
    $swal.fire({ icon: 'warning', title: 'File too large', text: 'Maximum file size is 10 MB.', toast: true, timer: 3000, position: 'top-end' })
    return
  }
  recordPayment.evidence_file = file
  recordPayment.evidence_file_name = file.name
  if (file.type.startsWith('image/')) {
    const reader = new FileReader()
    reader.onload = (ev) => { recordPayment.evidencePreview = ev.target?.result as string }
    reader.readAsDataURL(file)
  } else {
    recordPayment.evidencePreview = ''
  }
}

function clearEvidence() {
  recordPayment.evidence_file = null
  recordPayment.evidence_file_name = ''
  recordPayment.evidencePreview = ''
}

async function submitRecordPayment() {
  const paymentId = recordPayment.targetPaymentId
  if (!paymentId) {
    $swal.fire({ icon: 'warning', title: 'Select instalment', text: 'Please select which instalment to record the payment for.', toast: true, timer: 2500, position: 'top-end' })
    return
  }
  if (!recordPayment.paid_amount || recordPayment.paid_amount <= 0) {
    $swal.fire({ icon: 'warning', title: 'Invalid amount', text: 'Please enter a valid payment amount.', toast: true, timer: 2500, position: 'top-end' })
    return
  }
  recordSaving.value = true
  try {
    const formData = new FormData()
    formData.append('paid_amount', String(recordPayment.paid_amount))
    formData.append('paid_date', recordPayment.paid_date || new Date().toISOString().slice(0, 10))
    if (recordPayment.payment_method) formData.append('payment_method', recordPayment.payment_method)
    if (recordPayment.reference_no) formData.append('reference_no', recordPayment.reference_no)
    if (recordPayment.remarks) formData.append('remarks', recordPayment.remarks)
    if (recordPayment.evidence_file) formData.append('evidence_file', recordPayment.evidence_file)

    await $api(`/financing/payments/${paymentId}/mark-paid/`, { method: 'PATCH', body: formData })
    $swal.fire({ icon: 'success', title: 'Payment recorded', toast: true, timer: 1800, position: 'top-end' })
    recordDialog.value = false
    await refreshAll()
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Failed to record', text: e?.data?.detail || '', toast: true, timer: 3000, position: 'top-end' })
  } finally {
    recordSaving.value = false
  }
}

/* ── Evidence Preview ── */
const evidenceDialog = ref(false)
const evidencePreviewUrl = ref('')
const evidenceIsPdf = ref(false)

function viewEvidence(item: any) {
  const url = resolveMediaUrl(item.evidence_file_url)
  if (!url) return
  evidenceIsPdf.value = (item.evidence_file_url || '').toLowerCase().endsWith('.pdf')
  evidencePreviewUrl.value = url
  evidenceDialog.value = true
}

async function deletePayment(item: any) {
  const res = await $swal.fire({ icon: 'warning', title: 'Delete payment?', showCancelButton: true, confirmButtonColor: '#dc2626' })
  if (!res.isConfirmed) return
  try {
    await $api(`/financing/payments/${item.id}/`, { method: 'DELETE' })
    await refreshAll()
    $swal.fire({ icon: 'success', title: 'Deleted', toast: true, timer: 1500, position: 'top-end' })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Failed', text: e?.data?.detail || '', toast: true, timer: 2000, position: 'top-end' })
  }
}

/* ── Export ── */
function exportLoans() {
  const rows = filteredLoans.value
  if (!rows.length) return
  const headers = ['Loan No', 'Vehicle', 'Bank', 'Principal', 'EMI', 'Outstanding', 'Progress %', 'Status']
  const csv = [headers.join(',')]
  rows.forEach((r: any) => {
    csv.push([
      r.loan_no, r.vehicle_name, r.bank_name, r.principal_amount, r.monthly_instalment,
      r.outstanding_balance, r.progress_pct, r.status,
    ].join(','))
  })
  const blob = new Blob([csv.join('\n')], { type: 'text/csv' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = 'financing-loans.csv'
  a.click()
  URL.revokeObjectURL(url)
}

/* ── Helpers ── */
function formatDate(d: any) {
  if (!d) return '—'
  const date = new Date(d + 'T00:00:00')
  return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })
}

function loanStatusColor(s: string): string {
  const map: Record<string, string> = {
    active: 'success', closed: 'grey', defaulted: 'error',
    restructured: 'warning', pending: 'info',
  }
  return map[s] || 'grey'
}

function loanStatusLabel(s: string): string {
  const map: Record<string, string> = {
    active: 'Active', closed: 'Closed', defaulted: 'Defaulted',
    restructured: 'Restructured', pending: 'Pending',
  }
  return map[s] || s
}

function paymentStatusColor(s: string): string {
  const map: Record<string, string> = {
    paid: 'success', upcoming: 'info', overdue: 'error',
    partially_paid: 'warning', waived: 'grey',
  }
  return map[s] || 'grey'
}

function paymentStatusLabel(s: string): string {
  const map: Record<string, string> = {
    paid: 'Paid', upcoming: 'Upcoming', overdue: 'Overdue',
    partially_paid: 'Partially Paid', waived: 'Waived',
  }
  return map[s] || s
}

function interestTypeLabel(t: string): string {
  const opt = interestTypes.find((i) => i.value === t)
  return opt ? opt.label : t
}

onMounted(() => {
  loadVehicles()
})
</script>

<style scoped>
.financing-detail-box {
  background: rgba(var(--v-theme-on-surface), 0.04);
  border: 1px solid rgba(var(--v-theme-on-surface), 0.08);
  border-radius: 10px;
  padding: 12px 14px;
}

.financing-stat-box {
  background: rgba(var(--v-theme-on-surface), 0.03);
  border-radius: 8px;
  padding: 8px 10px;
  text-align: center;
}

.record-summary {
  background: rgba(var(--v-theme-on-surface), 0.04);
  border: 1px solid rgba(var(--v-theme-on-surface), 0.08);
  border-radius: 10px;
  padding: 12px 14px;
}

.evidence-upload-zone {
  border: 2px dashed rgba(var(--v-theme-on-surface), 0.25);
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.15s ease;
  background: rgba(var(--v-theme-on-surface), 0.02);
}
.evidence-upload-zone:hover {
  border-color: #6366f1;
  background: rgba(99, 102, 241, 0.04);
}
.evidence-upload-zone:active {
  border-color: #4f46e5;
}
</style>
