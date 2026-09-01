<template>
  <div class="d-flex flex-column ga-5">
    <!-- Page header -->
    <div class="d-flex flex-wrap align-center justify-space-between ga-3">
      <div>
        <h2 class="text-h5 font-weight-bold d-flex align-center ga-2" style="color: #1e293b">
          <v-icon color="primary">mdi-handshake-outline</v-icon>
          Lessors
        </h2>
        <p class="text-body-2 text-medium-emphasis">Lease management, contracts, payments and documents</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-chip v-if="analytics" color="primary" variant="tonal" size="small">
          <v-icon start size="x-small">mdi-file-document-multiple-outline</v-icon>
          {{ analytics?.summary?.active_contracts ?? 0 }} active
        </v-chip>
        <v-btn variant="outlined" prepend-icon="mdi-refresh" :loading="pending" @click="reloadAll">Refresh</v-btn>
        <v-btn v-can="'lessors:create'" color="primary" prepend-icon="mdi-plus" @click="openLessorDlg()">Add Lessor</v-btn>
      </div>
    </div>

    <!-- KPI Cards -->
    <v-row dense>
      <v-col cols="6" md="3">
        <StatCard
          label="Total Lessors"
          :value="analytics?.summary?.total_lessors ?? 0"
          icon="mdi-handshake-outline"
          icon-bg="#eef2ff"
          icon-color="primary"
          :subtitle="`${analytics?.summary?.active_lessors ?? 0} active`"
        />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard
          label="Active Contracts"
          :value="analytics?.summary?.active_contracts ?? 0"
          icon="mdi-file-document-edit-outline"
          icon-bg="#ecfdf5"
          icon-color="success"
          :subtitle="`${analytics?.summary?.expiring_30d ?? 0} expiring 30d`"
        />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard
          label="Pending Payments"
          :value="analytics?.summary?.total_pending ?? 0"
          icon="mdi-cash-clock"
          icon-bg="#fff7ed"
          icon-color="warning"
          :subtitle="`${analytics?.summary?.overdue_count ?? 0} overdue`"
        />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard
          label="Monthly Lease Value"
          :value="fmtMoney(analytics?.summary?.total_monthly_lease ?? 0)"
          icon="mdi-cash-multiple"
          icon-bg="#fef2f2"
          icon-color="error"
          :subtitle="`${analytics?.summary?.leased_vehicles ?? 0} leased`"
        />
      </v-col>
    </v-row>

    <!-- Tabs -->
    <v-tabs v-model="tab" color="primary" density="compact">
      <v-tab value="overview" prepend-icon="mdi-chart-box-outline">Overview</v-tab>
      <v-tab value="lessors" prepend-icon="mdi-account-group-outline">Lessors</v-tab>
      <v-tab value="contracts" prepend-icon="mdi-file-document-multiple-outline">Contracts</v-tab>
      <v-tab value="payments" prepend-icon="mdi-cash-multiple">Payments</v-tab>
      <v-tab value="documents" prepend-icon="mdi-paperclip">Documents</v-tab>
      <v-tab value="locations" prepend-icon="mdi-map-marker-multiple-outline">Locations</v-tab>
      <v-tab value="pnl" prepend-icon="mdi-chart-arc"><span>Profit &amp; Loss</span></v-tab>
    </v-tabs>

    <v-window v-model="tab" class="flex-grow-1">
      <!-- =================== OVERVIEW =================== -->
      <v-window-item value="overview">
        <div class="d-flex flex-column ga-4">
          <!-- Date filter bar -->
          <v-card variant="outlined" rounded="lg" class="pa-3">
            <div class="d-flex align-center ga-4 flex-wrap">
              <div class="d-flex align-center ga-2">
                <v-icon icon="mdi-filter-calendar" color="primary" />
                <span class="text-body-2 font-weight-bold text-medium-emphasis">Date Range</span>
              </div>
              <div class="d-flex align-center ga-2 flex-wrap">
                <div class="d-flex flex-column">
                  <span class="text-caption text-medium-emphasis mb-1">From</span>
                  <v-text-field
                    v-model="filterStartDate"
                    type="date"
                    density="compact"
                    variant="outlined"
                    hide-details
                    style="max-width: 170px"
                    @update:model-value="loadAnalytics"
                  />
                </div>
                <v-icon icon="mdi-arrow-right" class="mt-4" color="medium-emphasis" />
                <div class="d-flex flex-column">
                  <span class="text-caption text-medium-emphasis mb-1">To</span>
                  <v-text-field
                    v-model="filterEndDate"
                    type="date"
                    density="compact"
                    variant="outlined"
                    hide-details
                    style="max-width: 170px"
                    @update:model-value="loadAnalytics"
                  />
                </div>
              </div>
              <v-btn variant="text" prepend-icon="mdi-refresh" size="small" color="primary" class="mt-4" @click="resetFilter">Reset</v-btn>
            </div>
          </v-card>

          <v-row dense>
            <v-col cols="12" md="8">
              <DashboardChart
                v-if="monthlyChartOption"
                :option="monthlyChartOption"
                title="Monthly Payments Collected vs Paid to Lessors"
                icon="mdi-chart-bar"
                height="320px"
              />
              <DashboardChart
                v-if="monthlyLineChartOption"
                :option="monthlyLineChartOption"
                title="Collected vs Paid to Lessors (Trend)"
                icon="mdi-chart-line"
                height="280px"
                class="mt-4"
              />
            </v-col>
            <v-col cols="12" md="4">
              <v-card elevation="0" border rounded="lg" class="h-100">
                <v-card-title class="text-subtitle-2 font-weight-bold">
                  <v-icon size="18" color="primary" class="mr-1">mdi-trophy-outline</v-icon>
                  Top Lessors by Fleet
                </v-card-title>
                <v-card-text>
                  <div v-if="!analytics?.top_lessors?.length" class="text-center text-medium-emphasis py-6">
                    <v-icon size="40" class="mb-2">mdi-handshake-outline</v-icon>
                    <p class="text-caption">No lessor data yet.</p>
                  </div>
                  <v-list density="compact" v-else>
                    <v-list-item v-for="(l, i) in analytics.top_lessors" :key="l.id" class="px-0">
                      <template #prepend>
                        <v-avatar :color="i === 0 ? 'warning' : 'primary'" variant="tonal" size="32" class="mr-3">
                          <span class="text-body-2 font-weight-bold">{{ i + 1 }}</span>
                        </v-avatar>
                      </template>
                      <v-list-item-title class="text-body-2 font-weight-medium">
                        {{ l.display_name || `${l.first_name || ''} ${l.last_name || ''}`.trim() || l.company_name }}
                      </v-list-item-title>
                      <v-list-item-subtitle>{{ l.vehicle_count }} vehicles</v-list-item-subtitle>
                      <template #append>
                        <v-chip size="x-small" variant="tonal" color="primary">{{ l.vehicle_count }}</v-chip>
                      </template>
                    </v-list-item>
                  </v-list>
                </v-card-text>
              </v-card>
            </v-col>
          </v-row>

          <!-- Alerts row -->
          <v-row dense>
            <v-col cols="12" md="4">
              <v-card elevation="0" border rounded="lg" class="h-100">
                <v-card-text class="d-flex align-center ga-3">
                  <v-avatar color="success" variant="tonal" size="44"><v-icon>mdi-check-circle-outline</v-icon></v-avatar>
                  <div>
                    <p class="text-caption text-medium-emphasis">Total Paid</p>
                    <p class="text-h6 font-weight-bold" style="color: #16a34a">{{ fmtMoney(analytics?.summary?.total_paid ?? 0) }}</p>
                  </div>
                </v-card-text>
              </v-card>
            </v-col>
            <v-col cols="12" md="4">
              <v-card elevation="0" border rounded="lg" class="h-100">
                <v-card-text class="d-flex align-center ga-3">
                  <v-avatar color="warning" variant="tonal" size="44"><v-icon>mdi-clock-outline</v-icon></v-avatar>
                  <div>
                    <p class="text-caption text-medium-emphasis">Pending</p>
                    <p class="text-h6 font-weight-bold" style="color: #ea580c">{{ fmtMoney(analytics?.summary?.total_pending ?? 0) }}</p>
                  </div>
                </v-card-text>
              </v-card>
            </v-col>
            <v-col cols="12" md="4">
              <v-card elevation="0" border rounded="lg" class="h-100">
                <v-card-text class="d-flex align-center ga-3">
                  <v-avatar color="error" variant="tonal" size="44"><v-icon>mdi-alert-circle-outline</v-icon></v-avatar>
                  <div>
                    <p class="text-caption text-medium-emphasis">Overdue</p>
                    <p class="text-h6 font-weight-bold" style="color: #dc2626">{{ fmtMoney(analytics?.summary?.overdue_amount ?? 0) }}</p>
                  </div>
                </v-card-text>
              </v-card>
            </v-col>
          </v-row>

          <!-- Company vs Individual breakdown -->
          <v-row dense>
            <v-col cols="12" md="6">
              <v-card elevation="0" border rounded="lg">
                <v-card-title class="text-subtitle-2 font-weight-bold"><v-icon size="18" color="primary" class="mr-1">mdi-sitemap-outline</v-icon>Lessor Composition</v-card-title>
                <v-card-text>
                  <div class="d-flex align-center ga-4">
                    <div class="d-flex flex-column align-center">
                      <v-progress-circular :model-value="companyPct" color="purple" size="80" width="8">
                        <span class="text-body-2 font-weight-bold">{{ Math.round(companyPct) }}%</span>
                      </v-progress-circular>
                      <p class="text-caption mt-2">Companies</p>
                    </div>
                    <div class="flex-grow-1">
                      <v-list density="compact">
                        <v-list-item class="px-0">
                          <v-list-item-title class="text-body-2"><v-icon color="purple" size="16" class="mr-2">mdi-office-building</v-icon>Companies</v-list-item-title>
                          <template #append><v-chip size="small" variant="tonal" color="purple">{{ analytics?.summary?.company_lessors ?? 0 }}</v-chip></template>
                        </v-list-item>
                        <v-list-item class="px-0">
                          <v-list-item-title class="text-body-2"><v-icon color="info" size="16" class="mr-2">mdi-account</v-icon>Individuals</v-list-item-title>
                          <template #append><v-chip size="small" variant="tonal" color="info">{{ analytics?.summary?.individual_lessors ?? 0 }}</v-chip></template>
                        </v-list-item>
                      </v-list>
                    </div>
                  </div>
                </v-card-text>
              </v-card>
            </v-col>
            <v-col cols="12" md="6">
              <v-card elevation="0" border rounded="lg">
                <v-card-title class="text-subtitle-2 font-weight-bold"><v-icon size="18" color="success" class="mr-1">mdi-truck-outline</v-icon>Leased Vehicles</v-card-title>
                <v-card-text class="d-flex flex-column align-center justify-center py-8">
                  <p class="text-h3 font-weight-bold" style="color: #16a34a">{{ analytics?.summary?.leased_vehicles ?? 0 }}</p>
                  <p class="text-body-2 text-medium-emphasis">vehicles currently on lease</p>
                  <p class="text-caption mt-2">Monthly: {{ fmtMoney(analytics?.summary?.total_monthly_lease ?? 0) }}</p>
                </v-card-text>
              </v-card>
            </v-col>
          </v-row>
        </div>
      </v-window-item>

      <!-- =================== LESSORS =================== -->
      <v-window-item value="lessors">
        <div class="d-flex flex-column ga-4">
          <div class="d-flex align-center justify-space-between">
            <v-text-field
              v-model="lessorSearch"
              prepend-inner-icon="mdi-magnify"
              placeholder="Search lessors..."
              density="compact"
              hide-details
              style="max-width: 320px"
              variant="outlined"
            />
            <v-btn v-can="'lessors:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="openLessorDlg()">Add Lessor</v-btn>
          </div>

          <v-card elevation="0" border rounded="lg">
            <v-data-table
              :headers="lessorHeaders"
              :items="lessors"
              :loading="lessorsPending"
              :items-per-page="15"
              :items-per-page-options="[10, 15, 25, 50]"
              :search="lessorSearch"
              hover
            >
              <template #item.display_name="{ item }">
                <div class="d-flex align-center ga-2" style="cursor: pointer" @click="goToDetail(item)">
                  <v-avatar size="32" :color="item.lessor_type === 'company' ? 'purple' : 'info'" variant="tonal">
                    <v-icon size="18">{{ item.lessor_type === 'company' ? 'mdi-office-building-outline' : 'mdi-account-outline' }}</v-icon>
                  </v-avatar>
                  <span class="font-weight-medium" style="color: #1e293b">{{ item.display_name }}</span>
                </div>
              </template>

              <template #item.lessor_type="{ value }">
                <v-chip :color="value === 'company' ? 'purple' : 'info'" variant="tonal" size="small" class="text-capitalize">{{ value }}</v-chip>
              </template>

              <template #item.vehicle_count="{ value }">
                <v-chip size="small" variant="tonal" color="primary">{{ value || 0 }}</v-chip>
              </template>

              <template #item.active_lease_count="{ value }">
                <span class="text-body-2 font-weight-medium">{{ value || 0 }}</span>
              </template>

              <template #item.monthly_earnings="{ value }">
                <span v-if="value > 0" class="font-weight-bold" style="color: #16a34a">{{ fmtMoney(value) }}</span>
                <span v-else class="text-medium-emphasis">—</span>
              </template>

              <template #item.unpaid_amount="{ value }">
                <span v-if="value > 0" class="text-error font-weight-medium">{{ fmtMoney(value) }}</span>
                <span v-else class="text-medium-emphasis">—</span>
              </template>

              <template #item.is_active="{ value }">
                <v-chip :color="value ? 'success' : 'grey'" variant="flat" size="small">{{ value ? 'Active' : 'Inactive' }}</v-chip>
              </template>

              <template #item.actions="{ item }">
                <div class="d-flex ga-1">
                  <v-btn icon="mdi-eye-outline" variant="text" size="small" @click="goToDetail(item)" />
                  <v-btn v-can="'lessors:update'" icon="mdi-pencil-outline" variant="text" size="small" @click="openLessorDlg(item)" />
                  <v-btn v-can="'lessors:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deleteLessor(item)" />
                </div>
              </template>

              <template #no-data>
                <div class="text-center py-12 text-medium-emphasis">
                  <v-icon size="48" class="mb-3">mdi-handshake-outline</v-icon>
                  <p>No lessors found. Click "Add Lessor" to get started.</p>
                </div>
              </template>
            </v-data-table>
          </v-card>
        </div>
      </v-window-item>

      <!-- =================== CONTRACTS =================== -->
      <v-window-item value="contracts">
        <div class="d-flex flex-column ga-4">
          <div class="d-flex align-center justify-space-between">
            <v-text-field
              v-model="contractSearch"
              prepend-inner-icon="mdi-magnify"
              placeholder="Search contracts..."
              density="compact"
              hide-details
              style="max-width: 320px"
              variant="outlined"
            />
            <v-btn v-can="'lessors:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="openContractDlg()">New Contract</v-btn>
          </div>

          <v-card elevation="0" border rounded="lg">
            <v-data-table
              :headers="contractHeaders"
              :items="contracts"
              :loading="contractsPending"
              :items-per-page="15"
              :items-per-page-options="[10, 15, 25, 50]"
              :search="contractSearch"
              hover
            >
              <template #item.title="{ item }">
                <div>
                  <p class="font-weight-medium" style="color: #1e293b">{{ item.title }}</p>
                  <p class="text-caption text-medium-emphasis">{{ item.contract_number || '—' }}</p>
                </div>
              </template>

              <template #item.lessor_name="{ value }">
                <span class="text-body-2">{{ value }}</span>
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
                  <v-btn v-can="'lessors:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deleteContract(item)" />
                </div>
              </template>

              <template #no-data>
                <div class="text-center py-12 text-medium-emphasis">
                  <v-icon size="48" class="mb-3">mdi-file-document-edit-outline</v-icon>
                  <p>No contracts found. Click "New Contract" to create one.</p>
                </div>
              </template>
            </v-data-table>
          </v-card>
        </div>
      </v-window-item>

      <!-- =================== PAYMENTS =================== -->
      <v-window-item value="payments">
        <div class="d-flex flex-column ga-4">
          <div class="d-flex align-center justify-space-between">
            <div class="d-flex align-center ga-2">
              <v-text-field
                v-model="paymentSearch"
                prepend-inner-icon="mdi-magnify"
                placeholder="Search payments..."
                density="compact"
                hide-details
                style="max-width: 280px"
                variant="outlined"
              />
              <v-select
                v-model="paymentStatusFilter"
                :items="paymentStatuses"
                item-title="title"
                item-value="value"
                label="Status"
                density="compact"
                hide-details
                style="max-width: 160px"
                variant="outlined"
                clearable
              />
            </div>
            <div class="d-flex ga-2">
              <v-btn v-can="'lessors:update'" variant="outlined" prepend-icon="mdi-alert-circle-outline" size="small" @click="markAllOverdue">Mark Overdue</v-btn>
              <v-btn v-can="'lessors:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="openPaymentDlg()">Record Payment</v-btn>
            </div>
          </div>

          <v-card elevation="0" border rounded="lg">
            <v-data-table
              :headers="paymentHeaders"
              :items="filteredPayments"
              :loading="paymentsPending"
              :items-per-page="15"
              :items-per-page-options="[10, 15, 25, 50]"
              :search="paymentSearch"
              hover
            >
              <template #item.lessor_name="{ value }">
                <span class="font-weight-medium">{{ value }}</span>
              </template>

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

              <template #item.is_overdue="{ value }">
                <v-icon v-if="value" color="error" size="small">mdi-alert-circle</v-icon>
                <v-icon v-else color="grey-lighten-2" size="small">mdi-circle-medium</v-icon>
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
                  <p>No payments recorded. Click "Record Payment" to add one.</p>
                </div>
              </template>
            </v-data-table>
          </v-card>
        </div>
      </v-window-item>

      <!-- =================== DOCUMENTS =================== -->
      <v-window-item value="documents">
        <div class="d-flex flex-column ga-4">
          <div class="d-flex align-center justify-space-between">
            <v-text-field
              v-model="docSearch"
              prepend-inner-icon="mdi-magnify"
              placeholder="Search documents..."
              density="compact"
              hide-details
              style="max-width: 320px"
              variant="outlined"
            />
            <v-btn v-can="'lessors:create'" color="primary" prepend-icon="mdi-upload" size="small" @click="openDocDlg()">Upload Document</v-btn>
          </div>

          <v-row dense>
            <v-col v-for="doc in filteredDocuments" :key="doc.id" cols="12" sm="6" md="4">
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
                  <p class="text-caption text-medium-emphasis">{{ doc.lessor_name }}</p>
                  <p v-if="doc.description" class="text-caption mt-2">{{ doc.description }}</p>
                  <div class="d-flex align-center justify-space-between mt-3">
                    <v-chip size="x-small" variant="tonal" :color="docTypeColor(doc.document_type)" class="text-capitalize">{{ doc.document_type }}</v-chip>
                    <div class="d-flex ga-1">
                      <v-btn
                        v-if="doc.file || doc.file_url"
                        icon="mdi-download-outline"
                        variant="text"
                        size="small"
                        :href="resolveDocUrl(doc)"
                        target="_blank"
                      />
                      <v-btn v-can="'lessors:update'" icon="mdi-pencil-outline" variant="text" size="small" @click="openDocDlg(doc)" />
                      <v-btn v-can="'lessors:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deleteDocument(doc)" />
                    </div>
                  </div>
                </v-card-text>
              </v-card>
            </v-col>
          </v-row>

          <div v-if="!filteredDocuments.length" class="text-center py-12 text-medium-emphasis">
            <v-icon size="48" class="mb-3">mdi-paperclip</v-icon>
            <p>No documents found. Click "Upload Document" to add one.</p>
          </div>
        </div>
      </v-window-item>

      <!-- =================== PROFIT & LOSS =================== -->
      <!-- =================== LOCATIONS =================== -->
      <v-window-item value="locations">
        <LessorLocationsTab
          :data="locData"
          :loading="locLoading"
          :start-date="locStartDate"
          :end-date="locEndDate"
          @update:start-date="locStartDate = $event; loadLocations()"
          @update:end-date="locEndDate = $event; loadLocations()"
          @reset="resetLocFilter"
        />
      </v-window-item>

      <v-window-item value="pnl">
        <ProfitLossTab
          :data="pnlData"
          :loading="pnlLoading"
          :start-date="pnlStartDate"
          :end-date="pnlEndDate"
          @update:start-date="pnlStartDate = $event; loadProfitLoss()"
          @update:end-date="pnlEndDate = $event; loadProfitLoss()"
          @reset="resetPnlFilter"
        />
      </v-window-item>
    </v-window>

    <!-- =================== DIALOGS =================== -->
    <LessorFormDialog v-model="lessorDlg" :lessor="editingLessor" @saved="onLessorSaved" />
    <ContractFormDialog v-model="contractDlg" :contract="editingContract" :lessors="lessors" @saved="onContractSaved" />
    <PaymentFormDialog v-model="paymentDlg" :payment="editingPayment" :lessors="lessors" :contracts="contracts" @saved="onPaymentSaved" />
    <DocumentFormDialog v-model="docDlg" :document="editingDoc" :lessors="lessors" @saved="onDocSaved" />

    <!-- =================== LESSOR DETAIL DRAWER =================== -->
    <v-navigation-drawer v-model="detailDrawer" location="right" width="520" temporary>
      <v-card variant="flat" v-if="detailData">
        <v-card-title class="d-flex align-center justify-space-between">
          <span class="text-h6 font-weight-bold">{{ detailData.lessor.display_name }}</span>
          <v-btn icon="mdi-close" variant="text" size="small" @click="detailDrawer = false" />
        </v-card-title>
        <v-card-text class="pt-0">
          <v-chip :color="detailData.lessor.lessor_type === 'company' ? 'purple' : 'info'" variant="tonal" size="small" class="mb-3 text-capitalize">
            {{ detailData.lessor.lessor_type }}
          </v-chip>

          <v-row dense>
            <v-col cols="6"><p class="text-caption text-medium-emphasis">Email</p><p class="text-body-2">{{ detailData.lessor.email || '—' }}</p></v-col>
            <v-col cols="6"><p class="text-caption text-medium-emphasis">Phone</p><p class="text-body-2">{{ detailData.lessor.phone || '—' }}</p></v-col>
            <v-col cols="6"><p class="text-caption text-medium-emphasis">Country</p><p class="text-body-2">{{ detailData.lessor.country || '—' }}</p></v-col>
            <v-col cols="6"><p class="text-caption text-medium-emphasis">Tax ID</p><p class="text-body-2">{{ detailData.lessor.tax_id || '—' }}</p></v-col>
            <v-col cols="6"><p class="text-caption text-medium-emphasis">Bank Account</p><p class="text-body-2">{{ detailData.lessor.bank_account || '—' }}</p></v-col>
            <v-col cols="6"><p class="text-caption text-medium-emphasis">Payment Terms</p><p class="text-body-2">{{ detailData.lessor.payment_terms || '—' }}</p></v-col>
          </v-row>

          <v-divider class="my-3" />

          <p class="text-subtitle-2 font-weight-bold mb-2">Summary</p>
          <v-row dense>
            <v-col cols="6"><v-card variant="outlined" rounded="lg" class="pa-3"><p class="text-caption text-medium-emphasis">Vehicles</p><p class="text-h6 font-weight-bold" style="color: #1e293b">{{ detailData.summary.vehicle_count }}</p><p class="text-caption">{{ detailData.summary.active_vehicles }} active</p></v-card></v-col>
            <v-col cols="6"><v-card variant="outlined" rounded="lg" class="pa-3"><p class="text-caption text-medium-emphasis">Contracts</p><p class="text-h6 font-weight-bold" style="color: #1e293b">{{ detailData.summary.contract_count }}</p><p class="text-caption">{{ detailData.summary.active_contracts }} active</p></v-card></v-col>
            <v-col cols="6"><v-card variant="outlined" rounded="lg" class="pa-3"><p class="text-caption text-medium-emphasis">Monthly Lease</p><p class="text-h6 font-weight-bold" style="color: #16a34a">{{ fmtMoney(detailData.summary.total_lease_value) }}</p></v-card></v-col>
            <v-col cols="6"><v-card variant="outlined" rounded="lg" class="pa-3"><p class="text-caption text-medium-emphasis">Unpaid</p><p class="text-h6 font-weight-bold" style="color: #dc2626">{{ fmtMoney(detailData.summary.payment_pending) }}</p></v-card></v-col>
          </v-row>

          <v-divider class="my-3" />

          <p class="text-subtitle-2 font-weight-bold mb-2">Vehicles ({{ detailData.vehicles.length }})</p>
          <v-list density="compact" class="pa-0">
            <v-list-item v-for="v in detailData.vehicles" :key="v.id" class="px-0">
              <template #prepend><v-icon color="primary" class="mr-3">mdi-truck-outline</v-icon></template>
              <v-list-item-title class="text-body-2">{{ v.display_name || `${v.make || ''} ${v.model || ''}`.trim() || `#${v.id}` }}</v-list-item-title>
              <v-list-item-subtitle v-if="v.lease_monthly_rate">{{ fmtMoney(v.lease_monthly_rate) }}/mo</v-list-item-subtitle>
            </v-list-item>
            <v-list-item v-if="!detailData.vehicles.length" class="text-medium-emphasis text-caption">No vehicles assigned.</v-list-item>
          </v-list>
        </v-card-text>
      </v-card>
      <div v-else class="d-flex justify-center align-center h-100">
        <v-progress-circular indeterminate color="primary" />
      </div>
    </v-navigation-drawer>
  </div>
</template>

<script setup lang="ts">
const { $api, $swal } = useNuxtApp() as any
const { fmtMoney } = useCurrency()

const tab = ref('overview')
const pending = ref(false)

// ---- Analytics ----
const analytics = ref<any>(null)
const filterStartDate = ref('')
const filterEndDate = ref('')

async function loadAnalytics() {
  try {
    const params = new URLSearchParams()
    if (filterStartDate.value) params.append('start_date', filterStartDate.value)
    if (filterEndDate.value) params.append('end_date', filterEndDate.value)
    const qs = params.toString()
    analytics.value = await $api(`/lessors/analytics/${qs ? '?' + qs : ''}`)
  } catch (e) { console.error('Analytics error:', e) }
}

function resetFilter() {
  filterStartDate.value = ''
  filterEndDate.value = ''
  loadAnalytics()
}

// ---- Profit & Loss ----
const pnlData = ref<any>(null)
const pnlLoading = ref(false)
const pnlStartDate = ref('')
const pnlEndDate = ref('')

async function loadProfitLoss() {
  pnlLoading.value = true
  try {
    const params = new URLSearchParams()
    if (pnlStartDate.value) params.append('start_date', pnlStartDate.value)
    if (pnlEndDate.value) params.append('end_date', pnlEndDate.value)
    const qs = params.toString()
    pnlData.value = await $api(`/lessors/profit-loss/${qs ? '?' + qs : ''}`)
  } catch (e) {
    console.error('P&L error:', e)
  } finally {
    pnlLoading.value = false
  }
}

function resetPnlFilter() {
  pnlStartDate.value = ''
  pnlEndDate.value = ''
  loadProfitLoss()
}

// ---- Locations Analysis ----
const locData = ref<any>(null)
const locLoading = ref(false)
const locStartDate = ref('')
const locEndDate = ref('')

async function loadLocations() {
  locLoading.value = true
  try {
    const params = new URLSearchParams()
    if (locStartDate.value) params.append('start_date', locStartDate.value)
    if (locEndDate.value) params.append('end_date', locEndDate.value)
    const qs = params.toString()
    locData.value = await $api(`/lessors/locations-analysis/${qs ? '?' + qs : ''}`)
  } catch (e) {
    console.error('Locations analysis error:', e)
  } finally {
    locLoading.value = false
  }
}

function resetLocFilter() {
  locStartDate.value = ''
  locEndDate.value = ''
  loadLocations()
}

// Load P&L when tab first selected
watch(tab, (v) => {
  if (v === 'pnl' && !pnlData.value && !pnlLoading.value) loadProfitLoss()
  if (v === 'locations' && !locData.value && !locLoading.value) loadLocations()
})

const companyPct = computed(() => {
  const s = analytics.value?.summary
  if (!s || !s.total_lessors) return 0
  return (s.company_lessors / s.total_lessors) * 100
})

const monthlyChartOption = computed(() => {
  const series = analytics.value?.monthly_series || []
  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
    legend: { data: ['Collected', 'Paid to Lessors'], bottom: 0 },
    grid: { left: 50, right: 20, top: 30, bottom: 50 },
    xAxis: { type: 'category', data: series.map((s: any) => s.month) },
    yAxis: { type: 'value' },
    series: [
      {
        name: 'Collected',
        type: 'bar',
        data: series.map((s: any) => s.collected ?? s.paid ?? 0),
        itemStyle: { color: '#3b82f6', borderRadius: [6, 6, 0, 0] },
        barGap: '10%',
      },
      {
        name: 'Paid to Lessors',
        type: 'bar',
        data: series.map((s: any) => s.paid ?? 0),
        itemStyle: { color: '#16a34a', borderRadius: [6, 6, 0, 0] },
      },
    ],
  }
})

const monthlyLineChartOption = computed(() => {
  const series = analytics.value?.monthly_series || []
  if (!series.length) return null
  return {
    tooltip: { trigger: 'axis' },
    legend: { data: ['Collected', 'Paid to Lessors'], bottom: 0 },
    grid: { left: 50, right: 20, top: 30, bottom: 50 },
    xAxis: { type: 'category', boundaryGap: false, data: series.map((s: any) => s.month) },
    yAxis: { type: 'value' },
    series: [
      {
        name: 'Collected',
        type: 'line',
        data: series.map((s: any) => s.collected ?? s.paid ?? 0),
        smooth: true,
        symbol: 'circle',
        symbolSize: 7,
        itemStyle: { color: '#3b82f6' },
        lineStyle: { width: 3, color: '#3b82f6' },
        areaStyle: {
          color: {
            type: 'linear', x: 0, y: 0, x2: 0, y2: 1,
            colorStops: [
              { offset: 0, color: 'rgba(59,130,246,0.35)' },
              { offset: 1, color: 'rgba(59,130,246,0.02)' },
            ],
          },
        },
      },
      {
        name: 'Paid to Lessors',
        type: 'line',
        data: series.map((s: any) => s.paid ?? 0),
        smooth: true,
        symbol: 'circle',
        symbolSize: 7,
        itemStyle: { color: '#16a34a' },
        lineStyle: { width: 3, color: '#16a34a' },
        areaStyle: {
          color: {
            type: 'linear', x: 0, y: 0, x2: 0, y2: 1,
            colorStops: [
              { offset: 0, color: 'rgba(22,163,74,0.35)' },
              { offset: 1, color: 'rgba(22,163,74,0.02)' },
            ],
          },
        },
      },
    ],
  }
})

// ---- Lessors ----
const lessorSearch = ref('')
const lessorDlg = ref(false)
const editingLessor = ref<any>(null)
const lessorHeaders = [
  { title: 'Name', key: 'display_name', sortable: true },
  { title: 'Type', key: 'lessor_type', sortable: true, width: '110px' },
  { title: 'Vehicles', key: 'vehicle_count', sortable: true, width: '90px', align: 'center' },
  { title: 'Active Leases', key: 'active_lease_count', sortable: true, width: '100px', align: 'center' },
  { title: 'Monthly Earnings', key: 'monthly_earnings', sortable: true, width: '140px' },
  { title: 'Unpaid', key: 'unpaid_amount', sortable: true, width: '120px' },
  { title: 'Email', key: 'email', sortable: true, width: '200px' },
  { title: 'Status', key: 'is_active', sortable: true, width: '100px' },
  { title: '', key: 'actions', width: '120px', sortable: false },
]

const { data: lessorsData, pending: lessorsPending, refresh: refreshLessors } = useAsyncData('lessors-list', () =>
  $api('/lessors/?page_size=1000'), { default: () => ({ results: [], count: 0 }) }
)
const lessors = computed(() => lessorsData.value?.results || lessorsData.value || [])

function openLessorDlg(l?: any) {
  editingLessor.value = l || null
  lessorDlg.value = true
}

function goToDetail(l: any) {
  navigateTo(`/app/lessors/${l.id}`)
}

async function onLessorSaved() {
  await refreshLessors()
  await loadAnalytics()
}

async function deleteLessor(l: any) {
  const res = await $swal.fire({ icon: 'warning', title: 'Delete lessor?', text: l.display_name, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#dc2626' })
  if (!res.isConfirmed) return
  await $api(`/lessors/${l.id}/`, { method: 'DELETE' })
  await onLessorSaved()
}

// ---- Lessor detail drawer ----
const detailDrawer = ref(false)
const detailData = ref<any>(null)
async function openLessorDetail(l: any) {
  detailDrawer.value = true
  detailData.value = null
  try {
    const [summary, vehicles] = await Promise.all([
      $api(`/lessors/${l.id}/summary/`),
      $api(`/lessors/${l.id}/vehicles/`),
    ])
    detailData.value = { lessor: l, summary, vehicles: vehicles?.results || vehicles || [] }
  } catch (e) {
    console.error('Detail error:', e)
    detailData.value = { lessor: l, summary: {}, vehicles: [] }
  }
}

// ---- Contracts ----
const contractSearch = ref('')
const contractDlg = ref(false)
const editingContract = ref<any>(null)
const contractHeaders = [
  { title: 'Contract', key: 'title', sortable: true },
  { title: 'Lessor', key: 'lessor_name', sortable: true },
  { title: 'Status', key: 'status', sortable: true, width: '120px' },
  { title: 'Monthly', key: 'monthly_rate', sortable: true, width: '110px' },
  { title: 'Total Value', key: 'total_value', sortable: true, width: '120px' },
  { title: 'Days Left', key: 'days_remaining', sortable: true, width: '100px', align: 'center' },
  { title: '', key: 'actions', width: '130px', sortable: false },
]

const { data: contractsData, pending: contractsPending, refresh: refreshContracts } = useAsyncData('lessors-contracts', () =>
  $api('/lessors/contracts/?page_size=1000'), { default: () => ({ results: [], count: 0 }) }
)
const contracts = computed(() => contractsData.value?.results || contractsData.value || [])

function openContractDlg(c?: any) {
  editingContract.value = c || null
  contractDlg.value = true
}

async function onContractSaved() {
  await refreshContracts()
  await loadAnalytics()
}

async function activateContract(c: any) {
  await $api(`/lessors/contracts/${c.id}/activate/`, { method: 'POST' })
  await onContractSaved()
}

async function terminateContract(c: any) {
  const res = await $swal.fire({ icon: 'warning', title: 'Terminate contract?', text: c.title, showCancelButton: true, confirmButtonText: 'Terminate', confirmButtonColor: '#dc2626' })
  if (!res.isConfirmed) return
  await $api(`/lessors/contracts/${c.id}/terminate/`, { method: 'POST' })
  await onContractSaved()
}

async function deleteContract(c: any) {
  const res = await $swal.fire({ icon: 'warning', title: 'Delete contract?', text: c.title, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#dc2626' })
  if (!res.isConfirmed) return
  await $api(`/lessors/contracts/${c.id}/`, { method: 'DELETE' })
  await onContractSaved()
}

function contractStatusColor(s: string) {
  return { draft: 'grey', pending: 'warning', active: 'success', expired: 'error', terminated: 'error' }[s] || 'grey'
}

// ---- Payments ----
const paymentSearch = ref('')
const paymentStatusFilter = ref('')
const paymentDlg = ref(false)
const editingPayment = ref<any>(null)
const paymentHeaders = [
  { title: 'Lessor', key: 'lessor_name', sortable: true },
  { title: 'Amount', key: 'amount', sortable: true, width: '120px' },
  { title: 'Status', key: 'status', sortable: true, width: '100px' },
  { title: 'Due Date', key: 'due_date', sortable: true, width: '120px' },
  { title: 'Paid Date', key: 'paid_date', sortable: true, width: '120px' },
  { title: 'Method', key: 'payment_method', sortable: true, width: '120px' },
  { title: '', key: 'is_overdue', width: '60px', sortable: false },
  { title: '', key: 'actions', width: '120px', sortable: false },
]

const paymentStatuses = [
  { title: 'Pending', value: 'pending' },
  { title: 'Paid', value: 'paid' },
  { title: 'Overdue', value: 'overdue' },
  { title: 'Cancelled', value: 'cancelled' },
]

const { data: paymentsData, pending: paymentsPending, refresh: refreshPayments } = useAsyncData('lessors-payments', () =>
  $api('/lessors/payments/?page_size=1000'), { default: () => ({ results: [], count: 0 }) }
)
const allPayments = computed(() => paymentsData.value?.results || paymentsData.value || [])
const filteredPayments = computed(() => {
  if (!paymentStatusFilter.value) return allPayments.value
  return allPayments.value.filter((p: any) => p.status === paymentStatusFilter.value)
})

function openPaymentDlg(p?: any) {
  editingPayment.value = p || null
  paymentDlg.value = true
}

async function onPaymentSaved() {
  await refreshPayments()
  await loadAnalytics()
}

async function markPaid(p: any) {
  await $api(`/lessors/payments/${p.id}/mark-paid/`, { method: 'POST' })
  await onPaymentSaved()
}

async function markAllOverdue() {
  const res = await $swal.fire({ icon: 'warning', title: 'Mark all past-due as overdue?', showCancelButton: true, confirmButtonText: 'Yes', confirmButtonColor: '#dc2626' })
  if (!res.isConfirmed) return
  await $api('/lessors/payments/mark-overdue/', { method: 'POST' })
  await onPaymentSaved()
}

async function deletePayment(p: any) {
  const res = await $swal.fire({ icon: 'warning', title: 'Delete payment?', showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#dc2626' })
  if (!res.isConfirmed) return
  await $api(`/lessors/payments/${p.id}/`, { method: 'DELETE' })
  await onPaymentSaved()
}

function paymentStatusColor(s: string) {
  return { pending: 'warning', paid: 'success', overdue: 'error', cancelled: 'grey' }[s] || 'grey'
}

// ---- Documents ----
const docSearch = ref('')
const docDlg = ref(false)
const editingDoc = ref<any>(null)

const { data: docsData, refresh: refreshDocs } = useAsyncData('lessors-docs', () =>
  $api('/lessors/documents/?page_size=1000'), { default: () => ({ results: [], count: 0 }) }
)
const allDocuments = computed(() => docsData.value?.results || docsData.value || [])
const filteredDocuments = computed(() => {
  if (!docSearch.value) return allDocuments.value
  const q = docSearch.value.toLowerCase()
  return allDocuments.value.filter((d: any) =>
    d.name?.toLowerCase().includes(q) || d.lessor_name?.toLowerCase().includes(q) || d.document_type?.toLowerCase().includes(q)
  )
})

function openDocDlg(d?: any) {
  editingDoc.value = d || null
  docDlg.value = true
}

async function onDocSaved() {
  await refreshDocs()
}

async function deleteDocument(d: any) {
  const res = await $swal.fire({ icon: 'warning', title: 'Delete document?', text: d.name, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#dc2626' })
  if (!res.isConfirmed) return
  await $api(`/lessors/documents/${d.id}/`, { method: 'DELETE' })
  await onDocSaved()
}

function docTypeIcon(t: string) {
  return {
    contract: 'mdi-file-document-outline',
    insurance: 'mdi-shield-account-outline',
    registration: 'mdi-account-badge-outline',
    license: 'mdi-card-account-details-outline',
    tax: 'mdi-receipt-text-outline',
    bank: 'mdi-bank-outline',
    other: 'mdi-paperclip',
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

// ---- Helpers ----
function formatDate(d: string) {
  if (!d) return ''
  return new Date(d).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' })
}

// ---- Load all ----
async function reloadAll() {
  pending.value = true
  try {
    await Promise.all([loadAnalytics(), refreshLessors(), refreshContracts(), refreshPayments(), refreshDocs()])
  } finally {
    pending.value = false
  }
}

onMounted(() => { loadAnalytics() })
</script>
