<template>
  <div class="d-flex flex-column ga-4">
    <!-- Header -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-2">
      <div>
        <h1 class="text-h5 font-weight-bold" style="color: #1e293b">Car Hire &amp; Rental</h1>
        <p class="text-caption text-medium-emphasis">Agreements, customers, signatures &amp; rental lifecycle</p>
      </div>
      <v-btn v-can="'rentals:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="navigateTo('/app/rentals/new')">New Agreement</v-btn>
    </div>

    <!-- KPI Row -->
    <v-row dense>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #6366f1 0%, #818cf8 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-file-document-outline</v-icon><span style="color:#fff; font-size:0.75rem; font-weight:500">Total Agreements</span></div>
          <p class="text-h4 font-weight-bold" style="color:#fff !important">{{ stats.total }}</p>
          <p style="color:#fff; opacity:.85; font-size:0.75rem">{{ stats.active }} active<span v-if="stats.overdue"> · {{ stats.overdue }} overdue</span> · {{ stats.completed }} completed</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #10b981 0%, #34d399 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-car-key</v-icon><span style="color:#fff; font-size:0.75rem; font-weight:500">Active</span></div>
          <p class="text-h4 font-weight-bold" style="color:#fff !important">{{ stats.active }}</p>
          <p style="color:#fff; opacity:.85; font-size:0.75rem">On rent now</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-account-multiple</v-icon><span style="color:#fff; font-size:0.75rem; font-weight:500">Customers</span></div>
          <p class="text-h4 font-weight-bold" style="color:#fff !important">{{ stats.customers }}</p>
          <p style="color:#fff; opacity:.85; font-size:0.75rem">{{ stats.local }} local · {{ stats.foreigner }} foreigner</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #ef4444 0%, #f87171 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-cash-multiple</v-icon><span style="color:#fff; font-size:0.75rem; font-weight:500">Revenue</span></div>
          <p class="text-h4 font-weight-bold" style="color:#fff !important">{{ currencySymbol }}{{ (stats.revenue || 0).toFixed(0) }}</p>
          <p style="color:#fff; opacity:.85; font-size:0.75rem">All-time total billed</p>
        </v-card>
      </v-col>
    </v-row>

    <!-- Tabs -->
    <v-card elevation="0" border rounded="lg">
      <v-tabs v-model="tab" color="primary" density="compact">
        <v-tab value="dashboard" slider-color="primary"><v-icon size="small" class="mr-2">mdi-view-dashboard</v-icon> Dashboard</v-tab>
        <v-tab value="agreements" slider-color="primary"><v-icon size="small" class="mr-2">mdi-file-document-multiple-outline</v-icon> Agreements</v-tab>
        <v-tab value="payments" slider-color="primary"><v-icon size="small" class="mr-2">mdi-cash-multiple</v-icon> Payments</v-tab>
        <v-tab value="customers" slider-color="primary"><v-icon size="small" class="mr-2">mdi-account-multiple</v-icon> Customers</v-tab>
        <v-tab value="pricing" slider-color="primary"><v-icon size="small" class="mr-2">mdi-cash-edit</v-icon> Pricing</v-tab>
      </v-tabs>
      <v-divider />

      <v-window v-model="tab">
        <!-- Dashboard -->
        <v-window-item value="dashboard" class="pa-4">
          <RentalAnalytics
            :agreements="agreements"
            :customers="customers"
            :payments="payments"
            :active-filter="statusFilter"
            :payment-filter="paymentStatusFilter"
            @filter="onAnalyticsFilter"
            @filter-payment="onAnalyticsPaymentFilter"
          />
        </v-window-item>

        <!-- Agreements -->
        <v-window-item value="agreements" class="pa-4">
          <!-- Filter bar -->
          <div class="d-flex align-center flex-wrap ga-2 mb-4">
            <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Search agreements, customer, vehicle…" density="compact" variant="outlined" hide-details clearable style="max-width: 360px; flex: 1 1 320px;" />
            <v-select v-model="statusFilter" :items="agreementStatusOptions" item-title="title" item-value="value" density="compact" variant="outlined" hide-details label="Status" style="max-width: 160px;" clearable />
            <v-select v-model="paymentStatusFilter" :items="paymentStatusOptions" item-title="title" item-value="value" density="compact" variant="outlined" hide-details label="Payment" style="max-width: 160px;" clearable />
            <v-btn v-if="hasAgreementFilters" size="small" variant="text" color="primary" prepend-icon="mdi-filter-remove-outline" @click="clearAgreementFilters">Clear</v-btn>
            <v-spacer />
            <v-btn-toggle v-model="agreementViewMode" mandatory density="compact" variant="outlined" color="primary">
              <v-btn value="table" size="small" prepend-icon="mdi-format-list-bulleted">Table</v-btn>
              <v-btn value="board" size="small" prepend-icon="mdi-view-column-outline">Board</v-btn>
            </v-btn-toggle>
          </div>
          <div v-if="!filteredAgreements.length" class="text-center py-12 text-medium-emphasis">
            <v-icon size="48" class="mb-3">mdi-file-document-outline</v-icon>
            <p>No rental agreements yet. Click <strong>New Agreement</strong> to create one.</p>
          </div>
          <AgreementBoard
            v-else-if="agreementViewMode === 'board'"
            :agreements="filteredAgreements"
            :currency-symbol="currencySymbol"
            :active-filter="statusFilter"
            @select="openView"
            @change="onAgreementStatusChange"
          />
          <v-data-table v-else :headers="agreementHeaders" :items="filteredAgreements" :loading="agreementsPending" hover items-per-page="10" v-model:page="agreementPage">
            <template #item.index="{ index }">
              <span class="text-caption text-medium-emphasis">{{ (agreementPage - 1) * agreementPageSize + index + 1 }}</span>
            </template>
            <template #item.agreement_no="{ value }">
              <span class="font-weight-bold" style="color: #4f46e5; font-family: 'JetBrains Mono', monospace; letter-spacing: 0.02em">{{ value }}</span>
            </template>
            <template #item.customer_name="{ item }">
              <div class="d-flex align-center ga-2">
                <v-avatar size="32" color="#eef2ff">
                  <v-icon size="18" color="#4f46e5">mdi-account</v-icon>
                </v-avatar>
                <div>
                  <div class="text-body-2 font-weight-medium" style="color:#1e293b">{{ item.customer_name }}</div>
                  <div class="text-caption text-capitalize" style="color:#94a3b8">{{ item.customer_type }}</div>
                </div>
              </div>
            </template>
            <template #item.vehicle_display="{ item }">
              <div>
                <div class="text-body-2" style="color:#1e293b">{{ item.vehicle_display || '—' }}</div>
                <div class="text-caption" style="color:#94a3b8">{{ item.vehicle_license_plate || '' }}</div>
              </div>
            </template>
            <template #item.status="{ item }">
              <v-chip size="small" :color="statusColor(effectiveStatus(item))" variant="flat" class="text-capitalize">{{ statusLabel(effectiveStatus(item)) }}</v-chip>
            </template>
            <template #item.payment_status="{ item }">
              <div v-if="item.status === 'draft' || item.status === 'cancelled'" class="text-caption text-medium-emphasis">—</div>
              <div v-else class="d-flex flex-column ga-1">
                <v-chip size="x-small" :color="payStatusColor(item.payment_status)" variant="flat" class="text-capitalize" style="width:fit-content;">
                  {{ payStatusLabel(item.payment_status) }}
                </v-chip>
                <div class="text-caption" style="color:#64748b;">
                  {{ currencySymbol }}{{ Number(item.amount_paid || 0).toLocaleString() }} / {{ currencySymbol }}{{ Number(item.total_amount || 0).toLocaleString() }}
                </div>
              </div>
            </template>
            <template #item.countdown="{ item }">
              <span v-if="countdownText(item)" :class="countdownClass(item)" class="d-inline-flex align-center ga-1 text-body-2 font-weight-medium">
                <v-icon size="14" :color="countdownColor(item)">{{ countdownIcon(item) }}</v-icon>
                {{ countdownText(item) }}
              </span>
              <span v-else class="text-caption text-medium-emphasis">—</span>
            </template>
            <template #item.total_amount="{ value }">
              <span class="font-weight-bold" style="color:#1e293b">{{ currencySymbol }}{{ Number(value || 0).toLocaleString() }}</span>
            </template>
            <template #item.actions="{ item }">
              <v-menu location="bottom end" :close-on-content-click="true">
                <template #activator="{ props: menuProps }">
                  <v-btn icon="mdi-dots-vertical" size="x-small" variant="text" v-bind="menuProps" />
                </template>
                <v-list density="compact" class="py-1" min-width="160">
                  <v-list-item prepend-icon="mdi-eye-outline" base-color="primary" title="View" @click="openView(item)" />
                  <v-list-item v-if="effectiveStatus(item) === 'active' || effectiveStatus(item) === 'overdue'" prepend-icon="mdi-key-arrow-right" base-color="success" title="Return Vehicle" @click="openReturn(item)" />
                  <v-list-item v-if="item.status !== 'draft' && item.status !== 'cancelled'" prepend-icon="mdi-cash-plus" base-color="teal-darken-1" title="Record Payment" @click="openPayment(item)" />
                  <v-list-item v-can="'rentals:update'" prepend-icon="mdi-pencil-outline" base-color="warning" title="Edit" @click="navigateTo(`/app/rentals/new?edit=${item.id}`)" />
                  <v-list-item prepend-icon="mdi-download" base-color="info" title="Download" @click="downloadAgreementWithFetch(item)" />
                  <v-list-item prepend-icon="mdi-file-document-edit-outline" base-color="indigo" title="Generate Invoice" @click="generateInvoiceFromAgreement(item)" />
                  <v-divider class="my-1" />
                  <v-list-item v-can="'rentals:delete'" prepend-icon="mdi-trash-can-outline" base-color="error" title="Delete" @click="deleteAgreement(item)" />
                </v-list>
              </v-menu>
            </template>
          </v-data-table>
        </v-window-item>

        <!-- Payments -->
        <v-window-item value="payments" class="pa-4">
          <!-- Payments KPI strip -->
          <v-row dense class="mb-4">
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 h-100" style="background: linear-gradient(135deg, #059669 0%, #34d399 100%) !important; color: #fff !important">
                <div class="d-flex align-center ga-2 mb-1"><v-icon color="white" size="small">mdi-cash-check</v-icon><span style="color:#fff; font-size:0.75rem; font-weight:500">Collected</span></div>
                <p class="text-h5 font-weight-bold mb-0" style="color:#fff !important">{{ currencySymbol }}{{ Number(paymentSummary.total_collected || 0).toLocaleString() }}</p>
                <p style="color:#fff; opacity:.8; font-size:0.75rem">{{ paymentSummary.payment_count || 0 }} payment(s)</p>
              </v-card>
            </v-col>
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 h-100" style="background: linear-gradient(135deg, #ef4444 0%, #f87171 100%) !important; color: #fff !important">
                <div class="d-flex align-center ga-2 mb-1"><v-icon color="white" size="small">mdi-cash-off</v-icon><span style="color:#fff; font-size:0.75rem; font-weight:500">Outstanding</span></div>
                <p class="text-h5 font-weight-bold mb-0" style="color:#fff !important">{{ currencySymbol }}{{ Number(paymentSummary.total_outstanding || 0).toLocaleString() }}</p>
                <p style="color:#fff; opacity:.8; font-size:0.75rem">Total unpaid balance</p>
              </v-card>
            </v-col>
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 h-100" style="background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%) !important; color: #fff !important">
                <div class="d-flex align-center ga-2 mb-1"><v-icon color="white" size="small">mdi-file-document-outline</v-icon><span style="color:#fff; font-size:0.75rem; font-weight:500">Invoiced</span></div>
                <p class="text-h5 font-weight-bold mb-0" style="color:#fff !important">{{ currencySymbol }}{{ Number(paymentSummary.total_invoices || 0).toLocaleString() }}</p>
                <p style="color:#fff; opacity:.8; font-size:0.75rem">Total billed</p>
              </v-card>
            </v-col>
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 h-100" style="background: linear-gradient(135deg, #6366f1 0%, #818cf8 100%) !important; color: #fff !important">
                <div class="d-flex align-center ga-2 mb-1"><v-icon color="white" size="small">mdi-chart-donut</v-icon><span style="color:#fff; font-size:0.75rem; font-weight:500">Collection Rate</span></div>
                <p class="text-h5 font-weight-bold mb-0" style="color:#fff !important">{{ collectionRate }}%</p>
                <p style="color:#fff; opacity:.8; font-size:0.75rem">Collected vs invoiced</p>
              </v-card>
            </v-col>
          </v-row>

          <!-- Payments table -->
          <div class="d-flex align-center justify-space-between flex-wrap ga-2 mb-3">
            <v-text-field v-model="paymentSearch" prepend-inner-icon="mdi-magnify" placeholder="Search payments by agreement, customer, ref…" density="compact" variant="outlined" hide-details clearable style="max-width: 50%; flex: 1 1 50%;" />
            <div class="d-flex align-center ga-2">
              <v-btn-toggle v-model="paymentViewMode" mandatory density="compact" variant="outlined" color="primary">
                <v-btn value="table" size="small" prepend-icon="mdi-format-list-bulleted">Table</v-btn>
                <v-btn value="board" size="small" prepend-icon="mdi-view-column-outline">Board</v-btn>
              </v-btn-toggle>
              <v-btn v-can="'rentals:create'" size="small" color="success" variant="tonal" prepend-icon="mdi-cash-plus" @click="recordPaymentFromTab">Record Payment</v-btn>
            </div>
          </div>
          <div v-if="!filteredPayments.length" class="text-center py-12 text-medium-emphasis">
            <v-icon size="48" class="mb-3">mdi-cash-multiple</v-icon>
            <p>No payments recorded yet. Click <strong>Record Payment</strong> to add one.</p>
          </div>
          <PaymentBoard
            v-else-if="paymentViewMode === 'board'"
            :payments="filteredPayments"
            :currency-symbol="currencySymbol"
            @select="openPaymentFromBoard"
            @change="onPaymentStatusChange"
          />
          <v-data-table v-else :headers="paymentHeaders" :items="filteredPayments" :loading="paymentsPending" hover items-per-page="10" v-model:page="paymentPage">
            <template #item.index="{ index }">
              <span class="text-caption text-medium-emphasis">{{ (paymentPage - 1) * paymentPageSize + index + 1 }}</span>
            </template>
            <template #item.agreement_no="{ item }">
              <span class="font-weight-bold" style="color: #4f46e5; font-family: 'JetBrains Mono', monospace;">{{ item.agreement_no }}</span>
            </template>
            <template #item.customer_name="{ value }">
              <div class="text-body-2" style="color:#1e293b">{{ value || '—' }}</div>
            </template>
            <template #item.amount="{ value }">
              <span class="font-weight-bold" style="color:#059669">{{ currencySymbol }}{{ Number(value || 0).toLocaleString() }}</span>
            </template>
            <template #item.payment_method="{ value }">
              <v-chip size="small" :color="methodChipColor(value)" variant="flat" class="text-capitalize">
                <v-icon size="small" start>{{ methodIconSmall(value) }}</v-icon>
                {{ methodLabelShort(value) }}
              </v-chip>
            </template>
            <template #item.status="{ value }">
              <v-chip size="small" :color="payStatusChipColor(value)" variant="flat" class="text-capitalize">{{ value }}</v-chip>
            </template>
            <template #item.paid_at="{ value }">
              <span class="text-body-2">{{ formatDate(value) }}</span>
            </template>
            <template #item.actions="{ item }">
              <v-btn v-can="'rentals:delete'" icon="mdi-trash-can-outline" size="x-small" variant="text" color="error" title="Delete" @click="deletePayment(item)" />
            </template>
          </v-data-table>
        </v-window-item>

        <!-- Customers -->
        <v-window-item value="customers" class="pa-4">
          <div class="d-flex align-center justify-space-between flex-wrap ga-2 mb-3">
            <v-text-field v-model="customerSearch" prepend-inner-icon="mdi-magnify" placeholder="Search customers by name, ID, email, phone…" density="compact" variant="outlined" hide-details clearable style="max-width: 50%; flex: 1 1 50%" />
            <v-btn v-can="'rentals:create'" size="small" color="primary" variant="tonal" prepend-icon="mdi-account-plus-outline" @click="navigateTo('/app/rentals/customers/new')">New Customer</v-btn>
          </div>
          <div v-if="!filteredCustomers.length" class="text-center py-12 text-medium-emphasis">
            <v-icon size="48" class="mb-3">mdi-account-multiple</v-icon>
            <p>No customers yet.</p>
          </div>
          <v-data-table v-else :headers="customerHeaders" :items="filteredCustomers" :loading="customersPending" hover items-per-page="10">
            <template #item.index="{ index }">
              <span class="text-caption text-medium-emphasis">{{ index + 1 }}</span>
            </template>
            <template #item.full_name="{ item }">
              <div class="d-flex align-center ga-2">
                <v-avatar size="32" color="#e0f2fe">
                  <img v-if="item.passport_photo" :src="resolveMediaUrl(item.passport_photo)" alt="" style="width:100%;height:100%;object-fit:cover" />
                  <v-icon v-else size="18" color="#0369a1">mdi-account</v-icon>
                </v-avatar>
                <div>
                  <div class="text-body-2 font-weight-medium" style="color:#1e293b">{{ item.full_name }}</div>
                  <div class="text-capitalize text-caption" style="color:#94a3b8">{{ item.customer_type }}</div>
                </div>
              </div>
            </template>
            <template #item.customer_type="{ value }">
              <v-chip size="x-small" :color="value === 'foreigner' ? 'info' : 'success'" variant="flat" class="text-capitalize">{{ value }}</v-chip>
            </template>
            <template #item.created_at="{ value }">
              <span :title="new Date(value).toLocaleString()" style="white-space: nowrap">{{ formatPrettyDate(value) }}</span>
            </template>
            <template #item.actions="{ item }">
              <v-btn icon="mdi-eye-outline" size="x-small" variant="text" color="primary" @click="navigateTo(`/app/rentals/customers/${item.id}`)" />
              <v-btn v-can="'rentals:update'" icon="mdi-pencil-outline" size="x-small" variant="text" color="warning" @click="navigateTo(`/app/rentals/customers/new?edit=${item.id}`)" />
              <v-btn v-can="'rentals:delete'" icon="mdi-trash-can-outline" size="x-small" variant="text" color="error" @click="deleteCustomer(item)" />
            </template>
          </v-data-table>
        </v-window-item>

        <!-- Pricing -->
        <v-window-item value="pricing" class="pa-4">
          <div class="d-flex justify-end mb-3">
            <v-btn v-can="'rentals:create'" size="small" color="primary" variant="tonal" prepend-icon="mdi-plus" @click="openPricingDialog()">New Pricing Plan</v-btn>
          </div>
          <div v-if="!filteredPricing.length" class="text-center py-12 text-medium-emphasis">
            <v-icon size="48" class="mb-3">mdi-cash-edit</v-icon>
            <p>No pricing plans yet. Create one to apply standardized rates to vehicles or groups.</p>
          </div>
          <v-data-table v-else :headers="pricingHeaders" :items="filteredPricing" :loading="pricingPending" hover items-per-page="10">
            <template #item.index="{ index }">
              <span class="text-caption text-medium-emphasis">{{ index + 1 }}</span>
            </template>
            <template #item.name="{ item }">
              <div class="d-flex align-center ga-2">
                <v-avatar size="32" :color="item.apply_to === 'group' ? '#fef3c7' : '#dbeafe'">
                  <v-icon size="18" :color="item.apply_to === 'group' ? '#d97706' : '#2563eb'">{{ item.apply_to === 'group' ? 'mdi-folder-multiple' : 'mdi-car-multiple' }}</v-icon>
                </v-avatar>
                <div>
                  <div class="text-body-2 font-weight-medium" style="color:#1e293b">{{ item.name }}</div>
                  <div class="text-caption" style="color:#94a3b8">{{ item.description || '—' }}</div>
                </div>
              </div>
            </template>
            <template #item.apply_target="{ item }">
              <v-chip size="small" :color="item.apply_to === 'group' ? 'warning' : 'info'" variant="flat" class="text-capitalize">
                <v-icon size="small" start :color="item.apply_to === 'group' ? (item.vehicle_type_color || undefined) : undefined">{{ item.apply_to === 'group' ? (item.vehicle_type_icon || 'mdi-shape') : 'mdi-car-multiple' }}</v-icon>
                {{ item.apply_to === 'group' ? (item.vehicle_type_name || 'All Types') : `${(item.vehicle_list || item.vehicle_ids || []).length} vehicle(s)` }}
              </v-chip>
            </template>
            <template #item.is_active="{ value }">
              <v-chip size="small" :color="value ? 'success' : 'default'" variant="flat">{{ value ? 'Active' : 'Inactive' }}</v-chip>
            </template>
            <template #item.daily_rate="{ item }">
              <div class="text-right">
                <div>{{ currencySymbol }}{{ Number(item.daily_rate || 0).toLocaleString() }}</div>
                <div v-if="Number(item.daily_discount_percent || 0) > 0" class="text-caption text-success">-{{ item.daily_discount_percent }}%</div>
                <div v-if="Number(item.daily_markup_percent || 0) > 0" class="text-caption text-error">+{{ item.daily_markup_percent }}%</div>
              </div>
            </template>
            <template #item.weekly_rate="{ item }">
              <div class="text-right">
                <div>{{ currencySymbol }}{{ Number(item.weekly_rate || 0).toLocaleString() }}</div>
                <div v-if="Number(item.weekly_discount_percent || 0) > 0" class="text-caption text-success">-{{ item.weekly_discount_percent }}%</div>
                <div v-if="Number(item.weekly_markup_percent || 0) > 0" class="text-caption text-error">+{{ item.weekly_markup_percent }}%</div>
              </div>
            </template>
            <template #item.weekend_rate="{ item }">
              <div class="text-right">
                <div>{{ currencySymbol }}{{ Number(item.weekend_rate || 0).toLocaleString() }}</div>
                <div v-if="Number(item.weekend_discount_percent || 0) > 0" class="text-caption text-success">-{{ item.weekend_discount_percent }}%</div>
                <div v-if="Number(item.weekend_markup_percent || 0) > 0" class="text-caption text-error">+{{ item.weekend_markup_percent }}%</div>
              </div>
            </template>
            <template #item.monthly_rate="{ item }">
              <div class="text-right">
                <div>{{ currencySymbol }}{{ Number(item.monthly_rate || 0).toLocaleString() }}</div>
                <div v-if="Number(item.monthly_discount_percent || 0) > 0" class="text-caption text-success">-{{ item.monthly_discount_percent }}%</div>
                <div v-if="Number(item.monthly_markup_percent || 0) > 0" class="text-caption text-error">+{{ item.monthly_markup_percent }}%</div>
              </div>
            </template>
            <template #item.actions="{ item }">
              <v-btn icon="mdi-eye-outline" size="x-small" variant="text" color="primary" title="View" @click="navigateTo(`/app/rentals/pricing/${item.id}`)" />
              <v-btn v-can="'rentals:update'" icon="mdi-pencil-outline" size="x-small" variant="text" color="warning" title="Edit" @click="openPricingDialog(item)" />
              <v-btn v-can="'rentals:delete'" icon="mdi-trash-can-outline" size="x-small" variant="text" color="error" title="Delete" @click="deletePricing(item)" />
            </template>
          </v-data-table>
        </v-window-item>
      </v-window>
    </v-card>

    <!-- Payment dialog -->
    <PaymentModal
      v-if="paymentVisible"
      v-model="paymentVisible"
      :agreement="payingAgreement"
      :agreements="agreements"
      @saved="onPaymentSaved"
    />

    <!-- Customer dialog -->
    <!-- Pricing dialog -->
    <v-dialog v-model="pricingDialog" max-width="900" scroll-strategy="none">
      <v-card rounded="xl" class="overflow-hidden">
        <AppModalHeader icon="mdi-cash-edit">{{ editingPricing ? 'Edit Pricing Plan' : 'New Pricing Plan' }}</AppModalHeader>
        <v-card-text class="pa-5" style="max-height: 70vh; overflow-y: auto">
          <v-row dense>
            <v-col cols="8"><v-text-field v-model="pricingForm.name" label="Plan Name *" prepend-inner-icon="mdi-tag-text-outline" hint="Name this pricing plan e.g. 'Corporate Fleet Rates'" persistent-hint :rules="[v => !!v || 'Required']" /></v-col>
            <v-col cols="4">
              <v-select v-model="pricingForm.is_active" :items="[{label:'Active', value:true},{label:'Inactive', value:false}]" item-title="label" item-value="value" label="Status" prepend-inner-icon="mdi-toggle-switch-outline" hint="Enable or disable this plan" persistent-hint />
            </v-col>
            <v-col cols="12"><v-textarea v-model="pricingForm.description" label="Description" rows="1" prepend-inner-icon="mdi-text-outline" hint="Optional notes about this pricing plan" persistent-hint /></v-col>

            <!-- Apply To -->
            <v-col cols="6">
              <v-select v-model="pricingForm.apply_to" :items="[{label:'Entire Vehicle Type', value:'group'},{label:'Specific Vehicles', value:'vehicles'}]" item-title="label" item-value="value" label="Applies To *" prepend-inner-icon="mdi-shape-outline" hint="Choose whether this plan applies to a vehicle type or specific vehicles" persistent-hint />
            </v-col>
            <v-col cols="6" v-if="pricingForm.apply_to === 'group'">
              <v-select v-model="pricingForm.vehicle_type" :items="[{ name: 'All Types', id: null }, ...vehicleTypes]" item-title="name" item-value="id" label="Vehicle Type" prepend-inner-icon="mdi-shape" clearable hint="Select the vehicle type this plan applies to" persistent-hint>
                <template #item="{ props, item }">
                  <v-list-item v-bind="props">
                    <template #prepend>
                      <v-icon :color="item.raw.color">{{ item.raw.icon || 'mdi-car' }}</v-icon>
                    </template>
                  </v-list-item>
                </template>
                <template #selection="{ item }">
                  <v-icon size="18" class="mr-2" :color="item.raw.color">{{ item.raw.icon || 'mdi-car' }}</v-icon>
                  <span>{{ item.raw.name }}</span>
                </template>
              </v-select>
            </v-col>
            <v-col cols="6" v-if="pricingForm.apply_to === 'vehicles'">
              <v-select v-model="pricingForm.vehicle_ids" :items="vehicles" item-title="display_name" item-value="id" label="Select Vehicles" prepend-inner-icon="mdi-car-multiple" clearable multiple chips closable-chips hint="Pick one or more vehicles this plan applies to" persistent-hint />
            </v-col>

            <!-- Validity -->
            <v-col cols="4"><v-text-field v-model="pricingForm.valid_from" type="date" label="Valid From" prepend-inner-icon="mdi-calendar-start" hint="When this plan becomes active" persistent-hint /></v-col>
            <v-col cols="4"><v-text-field v-model="pricingForm.valid_to" type="date" label="Valid To" prepend-inner-icon="mdi-calendar-end" hint="When this plan expires" persistent-hint /></v-col>

            <v-col cols="12"><v-divider class="my-2" /><span class="text-caption font-weight-bold text-primary">BASE RATES &amp; DISCOUNTS</span></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.daily_rate" type="number" :label="rateLabel('Daily')" prepend-inner-icon="mdi-calendar-today" hint="Rate per day — auto-fills other rates" persistent-hint @update:model-value="onDailyRateChange" /></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.weekly_rate" type="number" :label="rateLabel('Weekly')" prepend-inner-icon="mdi-calendar-week" hint="Rate per 7 days" persistent-hint /></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.weekend_rate" type="number" :label="rateLabel('Weekend')" prepend-inner-icon="mdi-calendar-clock" hint="Rate for Sat–Sun (2 days)" persistent-hint /></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.monthly_rate" type="number" :label="rateLabel('Monthly')" prepend-inner-icon="mdi-calendar-month" hint="Rate per 30 days" persistent-hint /></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.daily_discount_percent" type="number" label="Daily Discount %" prepend-inner-icon="mdi-percent-outline" density="compact" hint="Discount % off the daily rate" persistent-hint @update:model-value="(v:any) => onDiscountChange('daily_discount_percent', v)" /></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.weekly_discount_percent" type="number" label="Weekly Discount %" prepend-inner-icon="mdi-percent-outline" density="compact" hint="Discount % off the weekly rate" persistent-hint @update:model-value="(v:any) => onDiscountChange('weekly_discount_percent', v)" /></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.weekend_discount_percent" type="number" label="Weekend Discount %" prepend-inner-icon="mdi-percent-outline" density="compact" hint="Discount % off the weekend rate" persistent-hint @update:model-value="(v:any) => onDiscountChange('weekend_discount_percent', v)" /></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.monthly_discount_percent" type="number" label="Monthly Discount %" prepend-inner-icon="mdi-percent-outline" density="compact" hint="Discount % off the monthly rate" persistent-hint @update:model-value="(v:any) => onDiscountChange('monthly_discount_percent', v)" /></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.daily_markup_percent" type="number" label="Daily Markup %" prepend-inner-icon="mdi-percent-plus-outline" density="compact" hint="Markup % added to the daily rate" persistent-hint @update:model-value="(v:any) => onDiscountChange('daily_markup_percent', v)" /></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.weekly_markup_percent" type="number" label="Weekly Markup %" prepend-inner-icon="mdi-percent-plus-outline" density="compact" hint="Markup % added to the weekly rate" persistent-hint @update:model-value="(v:any) => onDiscountChange('weekly_markup_percent', v)" /></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.weekend_markup_percent" type="number" label="Weekend Markup %" prepend-inner-icon="mdi-percent-plus-outline" density="compact" hint="Markup % added to the weekend rate" persistent-hint @update:model-value="(v:any) => onDiscountChange('weekend_markup_percent', v)" /></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.monthly_markup_percent" type="number" label="Monthly Markup %" prepend-inner-icon="mdi-percent-plus-outline" density="compact" hint="Markup % added to the monthly rate" persistent-hint @update:model-value="(v:any) => onDiscountChange('monthly_markup_percent', v)" /></v-col>

            <v-col cols="12"><v-divider class="my-2" /><span class="text-caption font-weight-bold text-primary">CUSTOM RATE</span></v-col>
            <v-col cols="4"><v-text-field v-model="pricingForm.custom_rate_label" label="Custom Rate Label" prepend-inner-icon="mdi-tag-outline" placeholder='e.g. "3-Day Package"' hint="Name for a custom package" persistent-hint /></v-col>
            <v-col cols="4"><v-text-field v-model="pricingForm.custom_rate_value" type="number" :label="rateLabel('Custom Value')" prepend-inner-icon="mdi-cash" hint="Price for the custom package" persistent-hint /></v-col>
            <v-col cols="4"><v-text-field v-model="pricingForm.custom_rate_days" type="number" label="Days Covered" prepend-inner-icon="mdi-calendar-multiple" hint="How many days the custom rate covers" persistent-hint /></v-col>

            <v-col cols="12"><v-divider class="my-2" /><span class="text-caption font-weight-bold text-primary">DEPOSITS &amp; MISC</span></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.deposit_amount" type="number" :label="rateLabel('Deposit Amt')" prepend-inner-icon="mdi-cash-multiple" hint="General deposit collected at pickup" persistent-hint /></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.security_deposit" type="number" :label="rateLabel('Security Deposit')" prepend-inner-icon="mdi-shield-check-outline" hint="Refundable security hold" persistent-hint /></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.damage_deposit" type="number" :label="rateLabel('Damage Deposit')" prepend-inner-icon="mdi-car-brake-alert" hint="Covers potential vehicle damage" persistent-hint /></v-col>

            <v-col cols="12"><v-divider class="my-2" /><span class="text-caption font-weight-bold text-primary">ADD-ON FEES</span></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.insurance_premium" type="number" :label="rateLabel('Insurance')" prepend-inner-icon="mdi-shield-car" hint="CDW or comprehensive cover" persistent-hint /></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.gps_fee" type="number" :label="rateLabel('GPS')" prepend-inner-icon="mdi-crosshairs-gps" hint="GPS navigation device fee" persistent-hint /></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.child_seat_fee" type="number" :label="rateLabel('Child Seat')" prepend-inner-icon="mdi-baby-carriage" hint="Child or baby seat fee" persistent-hint /></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.additional_driver_fee" type="number" :label="rateLabel('Add. Driver')" prepend-inner-icon="mdi-account-plus" hint="Fee per extra authorised driver" persistent-hint /></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.driver_fee" type="number" :label="rateLabel('Driver')" prepend-inner-icon="mdi-account-tie" hint="Chauffeur / driver service fee" persistent-hint /></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.delivery_fee" type="number" :label="rateLabel('Delivery')" prepend-inner-icon="mdi-truck-fast" hint="Vehicle delivery to customer" persistent-hint /></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.prep_fee" type="number" :label="rateLabel('Prep')" prepend-inner-icon="mdi-car-wash" hint="Cleaning & preparation fee" persistent-hint /></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.after_hours_fee" type="number" :label="rateLabel('After Hours')" prepend-inner-icon="mdi-clock-time-nine" hint="Surcharge for pickups outside business hours" persistent-hint /></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.underage_fee" type="number" :label="rateLabel('Underage')" prepend-inner-icon="mdi-account-alert" hint="Surcharge for drivers under minimum age" persistent-hint /></v-col>
            <v-col cols="3"><v-text-field v-model="pricingForm.one_way_fee" type="number" :label="rateLabel('One Way')" prepend-inner-icon="mdi-arrow-decision" hint="Fee for dropping off at a different location" persistent-hint /></v-col>
          </v-row>
        </v-card-text>
        <v-divider />
        <v-card-actions class="pa-4">
          <v-spacer />
          <v-btn variant="text" @click="pricingDialog = false">Cancel</v-btn>
          <v-btn color="primary" prepend-icon="mdi-check" :loading="pricingSaving" @click="savePricing">{{ editingPricing ? 'Update' : 'Save' }}</v-btn>
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
const { resolveMediaUrl } = useMediaUrl()

/** Build a label like "Daily Rate (KSh)" for pricing form fields. */
function rateLabel(base: string, suffix = '') { const sym = currencySymbol || ''; return `${base} (${sym}${suffix})` }

const search = ref('')
const customerSearch = ref('')
const statusFilter = ref<string | null>(null)
const paymentStatusFilter = ref<string | null>(null)
const tab = ref('dashboard')
const agreementViewMode = ref<'table' | 'board'>('table')
const paymentViewMode = ref<'table' | 'board'>('table')
const agreementPage = ref(1)
const agreementPageSize = 10
const paymentPage = ref(1)
const paymentPageSize = 10
const agreementsPending = ref(true)
const customersPending = ref(true)
const pricingPending = ref(true)
const agreements = ref<any[]>([])
const customers = ref<any[]>([])
const pricing = ref<any[]>([])
const payments = ref<any[]>([])
const paymentsPending = ref(true)
const paymentSearch = ref('')
const paymentSummary = ref<any>({})
// View modal replaced by full-page route /app/rentals/[id]/view
const paymentVisible = ref(false)
const payingAgreement = ref<any>(null)
const fleetGroups = ref<any[]>([])
const vehicleTypes = ref<any[]>([])
const vehicles = ref<any[]>([])
const pricingDialog = ref(false)
const editingPricing = ref<any>(null)
const pricingSaving = ref(false)

const pricingFormDefault = {
  name: '', description: '', apply_to: 'group', vehicle_type: null, vehicle_ids: [] as number[],
  daily_rate: 0, weekly_rate: 0, weekend_rate: 0, monthly_rate: 0,
  daily_discount_percent: 0, weekly_discount_percent: 0, weekend_discount_percent: 0, monthly_discount_percent: 0,
  daily_markup_percent: 0, weekly_markup_percent: 0, weekend_markup_percent: 0, monthly_markup_percent: 0,
  custom_rate_label: '', custom_rate_value: 0, custom_rate_days: 0,
  deposit_amount: 0, security_deposit: 0, damage_deposit: 0,
  insurance_premium: 0, gps_fee: 0, child_seat_fee: 0, additional_driver_fee: 0,
  driver_fee: 0, delivery_fee: 0, prep_fee: 0, after_hours_fee: 0, underage_fee: 0, one_way_fee: 0,
  is_active: true, valid_from: null, valid_to: null,
}
const pricingForm = reactive<any>({ ...pricingFormDefault })
/** Mutex to suppress auto-calc when loading an existing plan into the form. */
let _pricingLoadingExisting = false

/**
 * When the daily rate changes, auto-fill weekly/weekend/monthly by multiplying
 * by the standard number of days (7 / 2 / 30) — but only if those fields are
 * empty or were previously auto-calculated (so we don't clobber manual entries).
 * Sunday rate = daily * 7, weekend rate = daily * 2, monthly rate = daily * 30.
 */
function onDailyRateChange(val: any) {
  if (_pricingLoadingExisting) return
  const daily = Number(val) || 0
  if (daily > 0) {
    pricingForm.weekly_rate = Math.round(daily * 7)
    pricingForm.weekend_rate = Math.round(daily * 2)
    pricingForm.monthly_rate = Math.round(daily * 30)
  }
}

/**
 * When a discount or markup % changes, auto-apply it to the matching rate.
 * discount: rate = base * (1 - percent/100)
 * markup:  rate = base * (1 + percent/100)
 * This keeps the rate field in sync so the two always reflect the same final price.
 */
function onDiscountChange(field: string, val: any) {
  if (_pricingLoadingExisting) return
  const pct = Number(val) || 0
  if (pct < 0 || pct > 100) return
  const daily = Number(pricingForm.daily_rate) || 0
  const baseMap: Record<string, number> = {
    daily_discount_percent: Math.round(daily),
    weekly_discount_percent: Math.round(daily * 7),
    weekend_discount_percent: Math.round(daily * 2),
    monthly_discount_percent: Math.round(daily * 30),
    daily_markup_percent: Math.round(daily),
    weekly_markup_percent: Math.round(daily * 7),
    weekend_markup_percent: Math.round(daily * 2),
    monthly_markup_percent: Math.round(daily * 30),
  }
  if (field in baseMap) {
    const base = baseMap[field]
    const isMarkup = field.includes('markup')
    const multiplier = isMarkup ? (1 + pct / 100) : (1 - pct / 100)
    const result = Math.round(base * multiplier)
    const target = field.replace(/_(discount|markup)_percent/, '_rate')
    pricingForm[target] = result
  }
}

// Customer add/edit moved to /app/rentals/customers/new (page, not dialog)

const customerTypeOptions = [
  { label: 'Local', value: 'local' },
  { label: 'Foreigner', value: 'foreigner' },
]
const idTypeOptions = [
  { label: 'National ID', value: 'national_id' },
  { label: 'Passport', value: 'passport' },
  { label: "Driver's License", value: 'driver_license' },
  { label: 'Alien Card', value: 'alien_card' },
]

const statusColors: Record<string, string> = {
  draft: 'default', active: 'success', completed: 'info', cancelled: 'error', overdue: 'warning',
}
function statusLabel(s: string) { return (s || 'draft').replace('_', ' ') }
function statusColor(s: string) { return statusColors[s] || 'default' }
function formatDate(d:any) { return d ? String(d).slice(0, 16).replace('T', ' ') : '—' }
function formatPrettyDate(d:any) {
  if (!d) return '—'
  try {
    const date = new Date(d)
    const day = date.getDate()
    const suffix = day % 10 === 1 && day !== 11 ? 'st' : day % 10 === 2 && day !== 12 ? 'nd' : day % 10 === 3 && day !== 13 ? 'rd' : 'th'
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December']
    const weekdays = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat']
    return weekdays[date.getDay()] + ' ' + months[date.getMonth()] + ' ' + day + suffix + ' ' + date.getFullYear()
  } catch { return d }
}

/* ---- Countdown helpers ---- */
const _now = ref(Date.now())
let _tick: any = null
onMounted(() => { _tick = setInterval(() => { _now.value = Date.now() }, 60_000) })
onBeforeUnmount(() => { if (_tick) clearInterval(_tick) })

function countdownMs(item: any): number | null {
  if (!item.end_datetime) return null
  const end = new Date(item.end_datetime).getTime()
  if (isNaN(end)) return null
  return end - _now.value
}

function effectiveStatus(item: any): string {
  const s = item.status || ''
  if (s === 'active' && countdownMs(item) !== null && (countdownMs(item) as number) < 0) return 'overdue'
  return s
}

function countdownText(item: any): string {
  const status = effectiveStatus(item)
  if (status === 'cancelled' || status === 'draft') return ''

  // Completed: show rental duration in days
  if (status === 'completed') {
    const start = item.start_datetime ? new Date(item.start_datetime).getTime() : NaN
    const end = item.actual_return_datetime ? new Date(item.actual_return_datetime).getTime()
      : item.end_datetime ? new Date(item.end_datetime).getTime() : NaN
    if (isNaN(start) || isNaN(end)) return ''
    const abs = Math.abs(end - start)
    const days = Math.floor(abs / 86_400_000)
    const hrs = Math.floor((abs % 86_400_000) / 3_600_000)
    if (days > 0) return `${days}d ${hrs}h`
    return `${hrs}h`
  }

  // Active / Overdue: countdown to end_datetime
  const ms = countdownMs(item)
  if (ms === null) return ''
  const abs = Math.abs(ms)
  const days = Math.floor(abs / 86_400_000)
  const hrs = Math.floor((abs % 86_400_000) / 3_600_000)
  const mins = Math.floor((abs % 3_600_000) / 60_000)
  const parts: string[] = []
  if (days > 0) parts.push(`${days}d`)
  if (hrs > 0 || days > 0) parts.push(`${hrs}h`)
  if (days === 0) parts.push(`${mins}m`)
  const label = parts.join(' ')
  if (ms < 0) return `${label} over`
  return `${label} left`
}

function countdownClass(item: any): string {
  const status = effectiveStatus(item)
  if (status === 'completed') return 'text-info'
  const ms = countdownMs(item)
  if (ms === null) return ''
  if (ms < 0) return 'text-error'
  const hrs = ms / 3_600_000
  if (hrs <= 6) return 'text-warning'
  return 'text-success'
}

function countdownColor(item: any): string {
  const status = effectiveStatus(item)
  if (status === 'completed') return 'info'
  const ms = countdownMs(item)
  if (ms === null) return 'medium-emphasis'
  if (ms < 0) return 'error'
  const hrs = ms / 3_600_000
  if (hrs <= 6) return 'warning'
  return 'success'
}

function countdownIcon(item: any): string {
  const status = effectiveStatus(item)
  if (status === 'completed') return 'mdi-check-circle-outline'
  const ms = countdownMs(item)
  if (ms === null) return 'mdi-clock-outline'
  if (ms < 0) return 'mdi-alert-circle-outline'
  const hrs = ms / 3_600_000
  if (hrs <= 6) return 'mdi-timer-alert-outline'
  return 'mdi-timer-sand'
}

const agreementHeaders = [
  { title: '#', key: 'index', width: '50px', sortable: false },
  { title: 'Agreement No', key: 'agreement_no', width: '150px', sortable: true },
  { title: 'Customer', key: 'customer_name', width: '200px' },
  { title: 'Vehicle', key: 'vehicle_display', width: '180px' },
  { title: 'Status', key: 'status', width: '120px' },
  { title: 'Payment', key: 'payment_status', width: '130px' },
  { title: 'Countdown', key: 'countdown', width: '160px', sortable: true },
  { title: 'Total', key: 'total_amount', width: '140px', align: 'end' as const, sortable: true },
  { title: '', key: 'actions', width: '60px', sortable: false },
]

const paymentHeaders = [
  { title: '#', key: 'index', width: '50px', sortable: false },
  { title: 'Agreement', key: 'agreement_no', width: '150px', sortable: true },
  { title: 'Customer', key: 'customer_name', width: '180px' },
  { title: 'Amount', key: 'amount', width: '130px', align: 'end' as const, sortable: true },
  { title: 'Method', key: 'payment_method', width: '140px' },
  { title: 'Reference', key: 'reference', width: '140px' },
  { title: 'Status', key: 'status', width: '110px' },
  { title: 'Date', key: 'paid_at', width: '150px', sortable: true },
  { title: '', key: 'actions', width: '60px', sortable: false },
]
const customerHeaders = [
  { title: '#', key: 'index', width: '50px', sortable: false },
  { title: 'Name', key: 'full_name', width: '220px' },
  { title: 'Type', key: 'customer_type', width: '120px' },
  { title: 'Phone', key: 'phone', width: '160px' },
  { title: 'ID Type', key: 'id_type', width: '140px' },
  { title: 'ID Number', key: 'id_number', width: '160px' },
  { title: 'Created', key: 'created_at', width: '160px', sortable: true },
  { title: '', key: 'actions', width: '120px', sortable: false },
]
const pricingHeaders = [
  { title: '#', key: 'index', width: '50px', sortable: false },
  { title: 'Plan Name', key: 'name', width: '220px' },
  { title: 'Applies To', key: 'apply_target', width: '170px' },
  { title: 'Daily', key: 'daily_rate', width: '100px', align: 'end' as const, sortable: true },
  { title: 'Wkly', key: 'weekly_rate', width: '100px', align: 'end' as const, sortable: true },
  { title: 'Wknd', key: 'weekend_rate', width: '100px', align: 'end' as const, sortable: true },
  { title: 'Mnthly', key: 'monthly_rate', width: '100px', align: 'end' as const, sortable: true },
  { title: 'Status', key: 'is_active', width: '90px' },
  { title: '', key: 'actions', width: '120px', sortable: false },
]

const stats = computed(() => {
  const list = agreements.value
  const customersList = customers.value
  const overdue = list.filter((a) => effectiveStatus(a) === 'overdue').length
  return {
    total: list.length,
    active: list.filter((a) => effectiveStatus(a) === 'active').length,
    overdue,
    completed: list.filter((a) => a.status === 'completed').length,
    customers: customersList.length,
    local: customersList.filter((c) => c.customer_type === 'local').length,
    foreigner: customersList.filter((c) => c.customer_type === 'foreigner').length,
    revenue: list.reduce((sum, a) => sum + Number(a.total_amount || 0), 0),
  }
})

const agreementStatusOptions = [
  { title: 'All', value: 'all' },
  { title: 'Draft', value: 'draft' },
  { title: 'Active', value: 'active' },
  { title: 'Overdue', value: 'overdue' },
  { title: 'Completed', value: 'completed' },
  { title: 'Cancelled', value: 'cancelled' },
]
const paymentStatusOptions = [
  { title: 'All', value: 'all' },
  { title: 'Paid', value: 'paid' },
  { title: 'Partial', value: 'partial' },
  { title: 'Unpaid', value: 'unpaid' },
]

const filteredAgreements = computed(() => {
  const q = search.value.trim().toLowerCase()
  let list = agreements.value
  if (q) {
    list = list.filter((a) =>
      (a.agreement_no || '').toLowerCase().includes(q) ||
      (a.customer_name || '').toLowerCase().includes(q) ||
      (a.vehicle_display || '').toLowerCase().includes(q) ||
      (a.vehicle_license_plate || '').toLowerCase().includes(q)
    )
  }
  if (statusFilter.value && statusFilter.value !== 'all') {
    const f = statusFilter.value
    list = list.filter((a) => effectiveStatus(a) === f || (f === 'draft' && a.status === 'draft') || (f === 'completed' && a.status === 'completed') || (f === 'cancelled' && a.status === 'cancelled'))
  }
  if (paymentStatusFilter.value && paymentStatusFilter.value !== 'all') {
    list = list.filter((a) => a.payment_status === paymentStatusFilter.value)
  }
  return list
})

const hasAgreementFilters = computed(() => !!(search.value || (statusFilter.value && statusFilter.value !== 'all') || (paymentStatusFilter.value && paymentStatusFilter.value !== 'all')))
function clearAgreementFilters() {
  search.value = ''
  statusFilter.value = null
  paymentStatusFilter.value = null
}

function onAnalyticsFilter(key: string) {
  statusFilter.value = key
  tab.value = 'agreements'
}

function onAnalyticsPaymentFilter(key: string) {
  paymentStatusFilter.value = key
  statusFilter.value = null
  tab.value = 'agreements'
}

const filteredCustomers = computed(() => {
  const q = (customerSearch.value || '').trim().toLowerCase()
  if (!q) return customers.value
  return customers.value.filter((c) =>
    (c.full_name || '').toLowerCase().includes(q) ||
    (c.email || '').toLowerCase().includes(q) ||
    (c.phone || '').toLowerCase().includes(q) ||
    (c.id_number || '').toLowerCase().includes(q)
  )
})

const filteredPricing = computed(() => {
  const q = search.value.trim().toLowerCase()
  if (!q) return pricing.value
  return pricing.value.filter((p) =>
    (p.name || '').toLowerCase().includes(q) ||
    (p.description || '').toLowerCase().includes(q) ||
    (p.vehicle_display || '').toLowerCase().includes(q) ||
    (p.vehicle_group_name || '').toLowerCase().includes(q)
  )
})

// Customer form functions removed — now navigates to /app/rentals/customers/new

async function openView(a: any) {
  navigateTo(`/app/rentals/${a.id}/view`)
}

async function openReturn(a: any) {
  navigateTo(`/app/rentals/${a.id}/return`)
}

async function loadAgreements() {
  agreementsPending.value = true
  try {
    const res = await $api('/rentals/agreements/')
    agreements.value = res?.results || res || []
  } catch (e) {
    $swal.fire({ icon: 'error', title: 'Failed to load agreements', toast: true, timer: 1800, position: 'top-end' })
  } finally { agreementsPending.value = false }
}

/* ---- Payments ---- */
const filteredPayments = computed(() => {
  const q = paymentSearch.value.toLowerCase().trim()
  if (!q) return payments.value
  return payments.value.filter((p: any) =>
    (p.agreement_no || '').toLowerCase().includes(q) ||
    (p.customer_name || '').toLowerCase().includes(q) ||
    (p.reference || '').toLowerCase().includes(q)
  )
})

const collectionRate = computed(() => {
  const inv = Number(paymentSummary.value.total_invoices || 0)
  const col = Number(paymentSummary.value.total_collected || 0)
  if (!inv) return 0
  return Math.round((col / inv) * 100)
})

async function loadPayments() {
  paymentsPending.value = true
  try {
    const res = await $api('/rentals/payments/')
    payments.value = res?.results || res || []
  } catch { payments.value = [] }
  finally { paymentsPending.value = false }
}

async function loadPaymentSummary() {
  try {
    paymentSummary.value = await $api('/rentals/payments/summary/')
  } catch { paymentSummary.value = {} }
}

function openPayment(a: any) {
  payingAgreement.value = a
  paymentVisible.value = true
}

async function onPaymentSaved() {
  await loadAgreements()
  await loadPayments()
  await loadPaymentSummary()
}

function recordPaymentFromTab() {
  if (!agreements.value.length) {
    $swal.fire({ icon: 'info', title: 'No agreements available', toast: true, timer: 1800, position: 'top-end' })
    return
  }
  // Check if there's at least one non-draft, non-cancelled agreement
  const available = agreements.value.filter((a: any) => a.status !== 'draft' && a.status !== 'cancelled')
  if (!available.length) {
    $swal.fire({ icon: 'info', title: 'No active agreements available', toast: true, timer: 2000, position: 'top-end' })
    return
  }
  // Open modal with null agreement so the agreement selector is shown
  payingAgreement.value = null
  paymentVisible.value = true
}

async function deletePayment(p: any) {
  const confirm = await $swal.fire({
    icon: 'warning',
    title: 'Delete payment?',
    text: `${currencySymbol}${Number(p.amount).toLocaleString()} for ${p.agreement_no}`,
    showCancelButton: true,
    confirmButtonText: 'Delete',
    confirmButtonColor: '#ef4444',
  })
  if (!confirm.isConfirmed) return
  try {
    await $api(`/rentals/payments/${p.id}/`, { method: 'DELETE' })
    $swal.fire({ icon: 'success', title: 'Payment deleted', toast: true, timer: 1500, position: 'top-end' })
    await loadPayments()
    await loadPaymentSummary()
    await loadAgreements()
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Delete failed', text: e?.data?.detail || '', toast: true, timer: 2000, position: 'top-end' })
  }
}

function payStatusColor(s: string) {
  const map: Record<string, string> = { paid: 'success', partial: 'warning', unpaid: 'error' }
  return map[s] || 'default'
}

// ── Board view: drag-and-drop status change handlers ──
async function onAgreementStatusChange(agreementId: number, newStatus: string) {
  try {
    const a = agreements.value.find((x: any) => x.id === agreementId)
    if (!a) return
    // Use the activate/complete actions for those transitions, PATCH for others
    if (newStatus === 'active') await $api(`/rentals/agreements/${agreementId}/activate/`, { method: 'POST' })
    else if (newStatus === 'completed') await $api(`/rentals/agreements/${agreementId}/complete/`, { method: 'POST' })
    else await $api(`/rentals/agreements/${agreementId}/`, { method: 'PATCH', body: { status: newStatus } })
    $swal.fire({ icon: 'success', title: `Moved to ${newStatus.replace('_', ' ')}`, toast: true, timer: 1500, position: 'top-end' })
    await loadAgreements()
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Status change failed', text: e?.data?.detail || '', toast: true, timer: 2500, position: 'top-end' })
    await loadAgreements()
  }
}

async function onPaymentStatusChange(paymentId: number, newStatus: string) {
  try {
    await $api(`/rentals/payments/${paymentId}/`, { method: 'PATCH', body: { status: newStatus } })
    $swal.fire({ icon: 'success', title: `Moved to ${newStatus}`, toast: true, timer: 1500, position: 'top-end' })
    await loadPayments()
    await loadPaymentSummary()
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Status change failed', text: e?.data?.detail || '', toast: true, timer: 2500, position: 'top-end' })
    await loadPayments()
  }
}

function openPaymentFromBoard(p: any) {
  // Find the associated agreement so the payment modal can open
  const a = agreements.value.find((x: any) => x.agreement_no === p.agreement_no)
  payingAgreement.value = a || null
  paymentVisible.value = true
}
function payStatusLabel(s: string) {
  const map: Record<string, string> = { paid: 'Paid', partial: 'Partial', unpaid: 'Unpaid' }
  return map[s] || s || '—'
}
function payStatusChipColor(s: string) {
  const map: Record<string, string> = { completed: 'success', pending: 'warning', failed: 'error', refunded: 'info' }
  return map[s] || 'default'
}
function methodChipColor(m: string) {
  const map: Record<string, string> = { mpesa: 'success', cash: 'warning', card: 'info', bank_transfer: 'primary', cheque: 'secondary', other: 'default' }
  return map[m] || 'default'
}
function methodIconSmall(m: string) {
  const map: Record<string, string> = { mpesa: 'mdi-cellphone', cash: 'mdi-cash', card: 'mdi-credit-card', bank_transfer: 'mdi-bank', cheque: 'mdi-checkbook', other: 'mdi-swap-horizontal' }
  return map[m] || 'mdi-cash'
}
function methodLabelShort(m: string) {
  const map: Record<string, string> = { mpesa: 'M-Pesa', cash: 'Cash', card: 'Card', bank_transfer: 'Bank', cheque: 'Cheque', other: 'Other' }
  return map[m] || m
}

async function loadCustomers() {
  customersPending.value = true
  try {
    const res = await $api('/rentals/customers/')
    customers.value = res?.results || res || []
  } catch (e) {
    $swal.fire({ icon: 'error', title: 'Failed to load customers', toast: true, timer: 1800, position: 'top-end' })
  } finally { customersPending.value = false }
}

// saveCustomer moved to /app/rentals/customers/new page

async function deleteCustomer(c: any) {
  // Check if the customer is linked to any agreements
  let links: any = null
  try {
    links = await $api(`/rentals/customers/${c.id}/check-links/`)
  } catch {
    // If check fails, proceed with normal delete
  }

  if (links && links.has_agreements) {
    // Customer has linked agreements — show warning and ask for cascade confirmation
    const agreementsList = (links.agreements || [])
      .slice(0, 5)
      .map((a: any) => `<li><b>${a.agreement_no}</b> — ${a.vehicle_display || 'N/A'} (${a.status})</li>`)
      .join('')
    const more = links.agreements_count > 5 ? `<li><i>...and ${links.agreements_count - 5} more</i></li>` : ''

    const r = await $swal.fire({
      icon: 'warning',
      title: `Delete ${c.full_name}?`,
      html: `<div style="text-align:left; font-size:0.85rem;">
        <p style="color:#b91c1c; font-weight:600; margin-bottom:8px;">
          ⚠️ This customer is linked to <b>${links.agreements_count}</b> rental agreement(s):
        </p>
        <ul style="margin:0 0 12px 20px; padding:0;">${agreementsList}${more}</ul>
        <p style="margin:0;">Deleting will also permanently delete <b>all linked agreements</b> and their charges, damages, and signatures. This cannot be undone.</p>
      </div>`,
      showCancelButton: true,
      confirmButtonText: 'Delete Customer & All Agreements',
      confirmButtonColor: '#ef4444',
      cancelButtonText: 'Cancel',
      width: 520,
    })
    if (!r.isConfirmed) return

    try {
      await $api(`/rentals/customers/${c.id}/?cascade=true`, { method: 'DELETE' })
      await loadCustomers()
      $swal.fire({ icon: 'success', title: 'Customer and agreements deleted', toast: true, timer: 1500, position: 'top-end' })
    } catch (e: any) {
      $swal.fire({ icon: 'error', title: 'Delete failed', text: e?.data?.detail || e?.message || '', toast: true, timer: 2500, position: 'top-end' })
    }
    return
  }

  // No linked agreements — simple confirm
  const r = await $swal.fire({ icon: 'warning', title: `Delete ${c.full_name}?`, text: 'This action cannot be undone.', showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!r.isConfirmed) return
  try {
    await $api(`/rentals/customers/${c.id}/`, { method: 'DELETE' })
    await loadCustomers()
    $swal.fire({ icon: 'success', title: 'Deleted', toast: true, timer: 1500, position: 'top-end' })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Delete failed', text: e?.data?.detail || e?.message || '', toast: true, timer: 2500, position: 'top-end' })
  }
}

// ── Pricing Plans ──
function resetPricingForm() {
  Object.assign(pricingForm, pricingFormDefault)
}

function openPricingDialog(p?: any) {
  _pricingLoadingExisting = true
  if (p) {
    editingPricing.value = p
    // Extract vehicle_ids from the nested vehicle_list or vehicle_ids field returned by API
    const vids = (p.vehicle_list || []).map((v:any) => v.id)
    Object.assign(pricingForm, { ...pricingFormDefault, ...p, vehicle_ids: vids.length ? vids : (p.vehicle_ids || []) })
  } else {
    editingPricing.value = null
    resetPricingForm()
  }
  pricingDialog.value = true
  // Allow auto-calc to resume on the next user keystroke
  setTimeout(() => { _pricingLoadingExisting = false }, 100)
}

async function loadPricing() {
  pricingPending.value = true
  try {
    const res = await $api('/rentals/pricing/')
    pricing.value = res?.results || res || []
  } catch {
    $swal.fire({ icon: 'error', title: 'Failed to load pricing plans', toast: true, timer: 1800, position: 'top-end' })
  } finally { pricingPending.value = false }
}

async function loadFleetGroups() {
  try { const res = await $api('/vehicles/groups/'); fleetGroups.value = res?.results || res || [] } catch {}
}
async function loadVehicleTypes() {
  try { const res = await $api('/vehicles/vehicle-types/?is_active=true'); vehicleTypes.value = res?.results || res || [] } catch {}
}

async function loadVehicles() {
  try { const res = await $api('/vehicles/vehicles/?page_size=200'); vehicles.value = (res?.results || res || []).map((v:any) => ({ ...v, display_name: v.display_name || `${v.year||''} ${v.make||''} ${v.model||''}` })) } catch {}
}

async function savePricing() {
  if (!pricingForm.name) {
    $swal.fire({ icon: 'warning', title: 'Plan name is required', toast: true, timer: 1800, position: 'top-end' })
    return
  }
  pricingSaving.value = true
  try {
    // Build a clean payload with only the form fields the API expects
    const {
      name, description, apply_to, vehicle_type, vehicle_ids,
      daily_rate, weekly_rate, weekend_rate, monthly_rate,
      daily_discount_percent, weekly_discount_percent, weekend_discount_percent, monthly_discount_percent,
      daily_markup_percent, weekly_markup_percent, weekend_markup_percent, monthly_markup_percent,
      custom_rate_label, custom_rate_value, custom_rate_days,
      deposit_amount, security_deposit, damage_deposit,
      insurance_premium, gps_fee, child_seat_fee, additional_driver_fee,
      driver_fee, delivery_fee, prep_fee, after_hours_fee, underage_fee, one_way_fee,
      valid_from, valid_to, is_active,
    } = pricingForm
    const payload: any = {
      name, description, apply_to,
      vehicle_type: apply_to === 'group' ? vehicle_type : null,
      vehicle_ids: apply_to === 'vehicles' ? vehicle_ids : [],
      daily_rate, weekly_rate, weekend_rate, monthly_rate,
      daily_discount_percent, weekly_discount_percent, weekend_discount_percent, monthly_discount_percent,
      daily_markup_percent, weekly_markup_percent, weekend_markup_percent, monthly_markup_percent,
      custom_rate_label, custom_rate_value, custom_rate_days,
      deposit_amount, security_deposit, damage_deposit,
      insurance_premium, gps_fee, child_seat_fee, additional_driver_fee,
      driver_fee, delivery_fee, prep_fee, after_hours_fee, underage_fee, one_way_fee,
      valid_from, valid_to, is_active,
    }

    if (editingPricing.value) {
      await $api(`/rentals/pricing/${editingPricing.value.id}/`, { method: 'PATCH', body: payload })
    } else {
      await $api('/rentals/pricing/', { method: 'POST', body: payload })
    }
    await loadPricing()
    pricingDialog.value = false
    $swal.fire({ icon: 'success', title: 'Pricing plan saved', toast: true, timer: 1500, position: 'top-end' })
  } catch (e:any) {
    $swal.fire({ icon: 'error', title: 'Save failed', text: e?.data?.detail || e?.message || '', toast: true, timer: 2500, position: 'top-end' })
  } finally { pricingSaving.value = false }
}

async function deletePricing(p: any) {
  const r = await $swal.fire({ icon: 'warning', title: `Delete ${p.name}?`, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!r.isConfirmed) return
  await $api(`/rentals/pricing/${p.id}/`, { method: 'DELETE' })
  await loadPricing()
  $swal.fire({ icon: 'success', title: 'Deleted', toast: true, timer: 1500, position: 'top-end' })
}

async function deleteAgreement(a: any) {
  const r = await $swal.fire({ icon: 'warning', title: `Delete ${a.agreement_no}?`, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!r.isConfirmed) return
  await $api(`/rentals/agreements/${a.id}/`, { method: 'DELETE' })
  await loadAgreements()
  $swal.fire({ icon: 'success', title: 'Deleted', toast: true, timer: 1500, position: 'top-end' })
}

/** Generate an invoice from a rental agreement. */
async function generateInvoiceFromAgreement(a: any) {
  const r = await $swal.fire({ icon: 'question', title: 'Generate Invoice', html: `Create an invoice from agreement <b>${a.agreement_no}</b>?`, showCancelButton: true, confirmButtonText: 'Generate', confirmButtonColor: '#6366f1' })
  if (!r.isConfirmed) return
  try {
    await $api('/rentals/invoices/from-agreement/', { method: 'POST', body: { agreement: a.id } })
    $swal.fire({ icon: 'success', title: 'Invoice generated', toast: true, timer: 1800, position: 'top-end' })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Failed to generate', text: e?.data?.detail || '', toast: true, timer: 2500, position: 'top-end' })
  }
}

/** Build a printable HTML and trigger browser print/save as PDF download. */
function downloadAgreement(a: any) {
  const html = buildAgreementHtml(a)
  const w = window.open('', '_blank', 'width=900,height=1100')
  if (!w) {
    $swal.fire({ icon: 'warning', title: 'Popup blocked', text: 'Allow popups to download the agreement.', toast: true, timer: 2500, position: 'top-end' })
    return
  }
  w.document.write(html)
  w.document.close()
  setTimeout(() => { w.focus(); w.print() }, 400)
}

async function buildAgreement(a: any) {
  let full = a
  if (!a.charges && !a.signatures && !a.damages && !a.vehicle_checks) {
    full = await $api(`/rentals/agreements/${a.id}/`)
  }
  return full
}

async function downloadAgreementWithFetch(a: any) {
  const full = await buildAgreement(a)
  downloadAgreement(full)
}

defineExpose({ downloadAgreementWithFetch })

function buildAgreementHtml(a: any): string {
  const charges = (a.charges || [])
  const damages = (a.damages || [])
  const vehicleChecks = (a.vehicle_checks || [])
  const signatures = (a.signatures || [])
  const customerSig = signatures.find((s:any) => s.party_type === 'customer')
  const companySig = signatures.find((s:any) => s.party_type === 'company_rep')

  // Active rate based on rate_period
  const rpLabels: Record<string,string> = { daily: 'Daily', weekly: 'Weekly', monthly: 'Monthly', weekend: 'Weekend' }
  const ratePeriodLabel = rpLabels[a.rate_period] || 'Daily'
  const activeRateValue = a[(a.rate_period || 'daily') + '_rate'] || 0

  // Company / tenant info
  const t = tenant.value
  const companyFullName = t?.full_name || t?.short_name || 'DomendraFleet'
  const companyEmail = t?.email || ''
  const companyTel = t?.mobile_number || ''
  const companyLogoUrl = tenantLogoUrl.value || ''
  const logoHtml = companyLogoUrl
    ? `<img src="${companyLogoUrl}" alt="logo" style="max-height:56px; max-width:200px; border-radius:6px;" />`
    : `<div class="logo">${(t?.short_name || 'Domendra')}</div>`

  return `<!DOCTYPE html><html><head><meta charset="utf-8"><title>${a.agreement_no} - Rental Agreement</title>
  <style>
    body { font-family: 'Segoe UI', Arial, sans-serif; color:#1e293b; padding:30px; max-width:820px; margin:0 auto; }
    .header { display:flex; justify-content:space-between; align-items:flex-start; border-bottom:3px solid #6366f1; padding-bottom:16px; margin-bottom:24px; }
    .header-left { display:flex; align-items:center; gap:14px; }
    .logo { font-size:28px; font-weight:800; color:#6366f1; }
    .company-name { font-size:18px; font-weight:700; color:#1e293b; line-height:1.3; }
    .company-contact { font-size:11px; color:#64748b; margin-top:3px; line-height:1.5; }
    .company-contact span { margin-right:12px; white-space:nowrap; }
    .meta { text-align:right; font-size:12px; color:#64748b; }
    .ref-badge { background:#eef2ff; color:#4f46e5; padding:6px 12px; border-radius:6px; font-weight:700; font-family: monospace; }
    h1 { font-size:22px; margin: 10px 0; }
    .section-title { font-size:12px; text-transform:uppercase; letter-spacing:0.05em; color:#4f46e5; font-weight:700; margin:18px 0 8px; border-left:3px solid #6366f1; padding-left:8px; }
    table { width:100%; border-collapse:collapse; margin-bottom:12px; }
    th { background:#f8fafc; text-align:left; padding:8px; border:1px solid #e2e8f0; font-size:12px; }
    td { padding:8px; border:1px solid #e2e8f0; font-size:12px; }
    .grid { display:grid; grid-template-columns: 1fr 1fr; gap:6px 24px; margin-bottom:8px; }
    .grid div { font-size:12px; padding:6px 0; border-bottom:1px dashed #e2e8f0; }
    .grid b { color:#475569; font-weight:600; display:block; font-size:10px; text-transform:uppercase; letter-spacing:0.05em; margin-bottom:2px; }
    .totals { margin-top:16px; }
    .totals .row { display:flex; justify-content:space-between; padding:6px 0; font-size:13px; }
    .totals .grand { background:#eef2ff; padding:10px 14px; border-radius:8px; font-weight:800; font-size:16px; color:#4f46e5; margin-top:6px; }
    .sigs { display:grid; grid-template-columns:1fr 1fr; gap:24px; margin-top:60px; }
    .sig-box { border-top:1.5px solid #1e293b; padding-top:10px; min-height:130px; position:relative; }
    .sig-box svg { width:100%; height:130px; }
    .sig-empty { text-align:center; color:#94a3b8; font-size:12px; padding-top:50px; }
    .foot { margin-top:30px; border-top:1px solid #e2e8f0; padding-top:14px; text-align:center; font-size:11px; color:#94a3b8; }
    @media print { body { padding: 14px; } }
  </style></head><body>
    <div class="header">
      <div class="header-left">
        ${logoHtml}
        <div>
          <div class="company-name">${companyFullName}</div>
          <div class="company-contact">
            ${companyEmail ? `<span>&#9993; ${companyEmail}</span>` : ''}
            ${companyTel ? `<span>&#9742; ${companyTel}</span>` : ''}
          </div>
        </div>
      </div>
      <div class="meta"><div class="ref-badge">${a.agreement_no}</div><div style="margin-top:6px">Date: ${new Date().toISOString().slice(0,10)}</div></div>
    </div>
    <h1>Vehicle Hire / Rental Agreement</h1>

    <p style="font-size:12px;color:#475569">
      This Vehicle Rental Agreement (the "Agreement") is made between <b>${companyFullName}</b> (the "Company") and the
      customer named below (the "Renter"). By signing, both parties accept the rates, terms, charges and
      conditions set out herein.
    </p>

    <div class="section-title">Renter (Customer)</div>
    <div class="grid">
      <div><b>Full Name</b>${a.customer_name || '—'}</div>
      <div><b>Type</b>${(a.customer_type||'—').replace('_',' ')}</div>
      <div><b>Phone</b>${a.customer_phone || '—'}</div>
      <div><b>Email</b>${a.customer_email || '—'}</div>
      <div><b>ID Number</b>${a.customer_id_number || '—'}</div>
      <div><b>Driving License</b>${a.customer_driving_license || '—'}</div>
      <div><b>Address</b>${a.customer_address || '—'}</div>
    </div>

    <div class="section-title">Vehicle</div>
    <div class="grid">
      <div><b>Vehicle</b>${a.vehicle_display || '—'}</div>
      <div><b>License Plate</b>${a.vehicle_license_plate || '—'}</div>
    </div>

    <div class="section-title">Rental Period</div>
    <div class="grid">
      <div><b>Start</b>${formatDate(a.start_datetime)}</div>
      <div><b>End</b>${formatDate(a.end_datetime)}</div>
      <div><b>Actual Return</b>${a.actual_return_datetime ? formatDate(a.actual_return_datetime) : '—'}</div>
      <div><b>Rate Period</b>${(a.rate_period||'daily').replace('_',' ')}</div>
      <div><b>Pickup</b>${a.pickup_location || '—'}</div>
      <div><b>Drop-off</b>${a.dropoff_location || '—'}</div>
    </div>

    <div class="section-title">Rates &amp; Add-ons</div>
    <div class="grid">
      <div><b>${ratePeriodLabel} Rate</b>${activeRateValue}</div>
      <div><b>Insurance</b>${a.insurance_type || '—'} (${a.insurance_premium || 0})</div>
      <div><b>GPS Fee</b>${a.gps_fee || 0}</div>
      <div><b>Child Seat</b>${a.child_seat_fee || 0}</div>
      <div><b>Additional Driver</b>${a.additional_driver_fee || 0}</div>
      <div><b>Delivery Fee</b>${a.delivery_fee || 0}</div>
      <div><b>Fuel Policy</b>${(a.fuel_policy||'').replace('_',' ')}</div>
    </div>

    <div class="section-title">Deposits, Discounts &amp; Mileage</div>
    <div class="grid">
      <div><b>Security Deposit</b>${a.security_deposit || 0}</div>
      <div><b>Damage Deposit</b>${a.damage_deposit || 0}</div>
      <div><b>Discount %</b>${a.discount_percent || 0}%</div>
      <div><b>Discount Amount</b>${a.discount_amount || 0}</div>
      <div><b>Free Mileage</b>${a.free_mileage || 0} km</div>
      <div><b>Excess Rate</b>${a.excess_mileage_rate || 0} / km</div>
      <div><b>Start Mileage</b>${a.start_mileage ?? '—'}</div>
      <div><b>End Mileage</b>${a.end_mileage ?? '—'}</div>
    </div>

    <div class="section-title">Additional Charges</div>
    <table>
      <thead><tr><th>Type</th><th>Description</th><th>Qty</th><th>Unit</th><th>Total</th></tr></thead>
      <tbody>
        ${charges.length ? charges.map((c:any) => `
          <tr><td>${(c.charge_type||'').replace('_',' ')}</td><td>${c.description||'—'}</td><td>${c.quantity||1}</td><td>${c.unit_amount||0}</td><td><b>${c.total_amount||0}</b></td></tr>`).join('') : '<tr><td colspan="5" style="text-align:center;color:#94a3b8">No additional charges.</td></tr>'}
      </tbody>
    </table>

    <div class="section-title">Vehicle Damages recorded</div>
    <table>
      <thead><tr><th>Location</th><th>Description</th><th>Severity</th><th>Repair Cost</th></tr></thead>
      <tbody>
        ${damages.length ? damages.map((d:any) => `<tr><td>${d.location||'—'}</td><td>${d.description||'—'}</td><td>${(d.severity||'none').replace('_',' ')}</td><td>${d.repair_cost||0}</td></tr>`).join('') : '<tr><td colspan="4" style="text-align:center;color:#94a3b8">No damages recorded.</td></tr>'}
      </tbody>
    </table>

    <div class="section-title">Vehicle Extras Checklist</div>
    <table>
      <thead><tr><th>Item</th><th>Status</th><th>Stage</th><th>Notes</th></tr></thead>
      <tbody>
        ${vehicleChecks.length ? vehicleChecks.map((vc:any) => `<tr><td>${vc.item_name||'—'}</td><td style="text-transform:capitalize">${(vc.status||'').replace('_','/')}</td><td style="text-transform:capitalize">${vc.stage||'pickup'}</td><td>${vc.notes||'—'}</td></tr>`).join('') : '<tr><td colspan="4" style="text-align:center;color:#94a3b8">No extras checklist recorded.</td></tr>'}
      </tbody>
    </table>

    <div class="totals">
      <div class="row"><span>Subtotal</span><span>${a.subtotal || 0}</span></div>
      <div class="row"><span>Discount</span><span>- ${a.discount_total || 0}</span></div>
      <div class="row"><span>Taxes</span><span>${a.taxes || 0}</span></div>
      <div class="row grand"><span>Total Amount</span><span>${a.total_amount || 0}</span></div>
    </div>

    <div class="sigs">
      <div>
        <div class="section-title" style="margin-top:0">Renter Signature</div>
        <div class="sig-box">${customerSig?.signature_data || '<div class="sig-empty">Not signed</div>'}</div>
        <div style="font-size:11px;color:#94a3b8;margin-top:6px">${customerSig?.signatory_name || '—'} · ${customerSig?.signed_at ? customerSig.signed_at.slice(0,16).replace('T',' ') : ''}</div>
      </div>
      <div>
        <div class="section-title" style="margin-top:0">Company Representative</div>
        <div class="sig-box">${companySig?.signature_data || '<div class="sig-empty">Not signed</div>'}</div>
        <div style="font-size:11px;color:#94a3b8;margin-top:6px">${companySig?.signatory_name || '—'} · ${companySig?.signed_at ? companySig.signed_at.slice(0,16).replace('T',' ') : ''}</div>
      </div>
    </div>

    <p style="font-size:11px;color:#475569;margin-top:30px;line-height:1.5">
      <b>Notes &amp; Terms:</b> ${a.notes || '—'}
    </p>

    ${(a.terms_and_conditions && a.terms_and_conditions.length) ? `
    <div class="section-title" style="margin-top:30px">Terms &amp; Conditions</div>
    <div style="font-size:11px;color:#475569;line-height:1.6">
      ${a.terms_and_conditions.map((t:any) => `<p style="margin:8px 0"><b>${t.id}. ${t.title}</b><br/>${t.text}</p>`).join('')}
    </div>` : ''}

    <div class="foot">
      Generated by ${companyFullName} · ${new Date().toISOString()} · This is a system-generated document for internal record purposes.
    </div>
  </body></html>`
}

onMounted(() => {
  // Support ?tab= query param so we can return to the right tab after navigation
  const route = useRoute()
  if (route.query.tab && typeof route.query.tab === 'string') {
    tab.value = route.query.tab as any
  }

  loadAgreements()
  loadPayments()
  loadPaymentSummary()
  loadCustomers()
  loadPricing()
  loadFleetGroups()
  loadVehicleTypes()
  loadVehicles()
  loadTenant()
})
</script>

<style scoped>
.page-header-bar { display:flex; align-items:center; justify-content:space-between; padding:10px 16px; background:#ffffff; border:1px solid #e2e8f0; border-radius:12px; }
</style>
