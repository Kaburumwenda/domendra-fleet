<template>
  <div class="d-flex flex-column ga-4">
    <!-- Header -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-2">
      <div class="d-flex align-center ga-3">
        <div class="d-flex align-center justify-center rounded-xl va-header-icon">
          <v-icon color="white" size="26">mdi-chart-box-outline</v-icon>
        </div>
        <div>
          <h1 class="text-h5 font-weight-bold" style="color: rgb(var(--v-theme-on-surface))">Vehicle Analytics</h1>
          <p class="text-caption text-medium-emphasis">Comprehensive fleet composition, utilization, cost, depreciation, health &amp; ABC revenue analysis</p>
        </div>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn-toggle v-model="period" mandatory density="compact" color="primary">
          <v-btn value="all" size="small">All Time</v-btn>
          <v-btn value="y" size="small">This Year</v-btn>
          <v-btn value="365" size="small">365d</v-btn>
          <v-btn value="90" size="small">90d</v-btn>
          <v-btn value="custom" size="small" @click="openCustomDate">Custom…</v-btn>
        </v-btn-toggle>
        <v-btn variant="tonal" prepend-icon="mdi-download" @click="exportCsv" size="small">
          <span class="hidden-sm-and-down">Export</span>
        </v-btn>
        <v-btn variant="tonal" prepend-icon="mdi-refresh" @click="refresh()" :loading="pending" size="small">
          <span class="hidden-sm-and-down">Refresh</span>
        </v-btn>
      </div>
    </div>

    <!-- Custom Date Range Dialog -->
    <v-dialog v-model="customDateDialogVisible" max-width="420">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-calendar-range">Custom Date Range</AppModalHeader>
        <v-card-text class="pt-4">
          <v-row dense>
            <v-col cols="12">
              <v-text-field v-model="customFrom" type="date" label="From (Purchase Date)" density="comfortable" variant="outlined" prepend-inner-icon="mdi-calendar-start" hide-details="auto" />
            </v-col>
            <v-col cols="12">
              <v-text-field v-model="customTo" type="date" label="To (Purchase Date)" density="comfortable" variant="outlined" prepend-inner-icon="mdi-calendar-end" hide-details="auto" />
            </v-col>
            <v-col cols="12" v-if="customDateError" class="pt-2">
              <p class="text-caption text-error">{{ customDateError }}</p>
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="cancelCustomDate">Cancel</v-btn>
          <v-btn color="primary" prepend-icon="mdi-magnify" @click="applyCustomDate">Apply</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- KPI Row -->
    <v-row dense>
      <v-col cols="6" md="2">
        <v-card elevation="0" border class="pa-4 h-100 va-kpi-card va-kpi-indigo" style="color: #fff !important">
          <div class="d-flex align-center justify-space-between mb-2">
            <v-avatar color="rgba(255,255,255,0.2)" size="36" rounded="lg" variant="flat"><v-icon color="white" size="small">mdi-car-multiple</v-icon></v-avatar>
            <v-icon color="white" size="x-small" style="opacity:.5">mdi-trending-up</v-icon>
          </div>
          <p class="text-h4 font-weight-bold" style="color: #fff !important">{{ data?.total_vehicles || 0 }}</p>
          <p class="text-caption" style="color: #fff !important; opacity:.85">Total Vehicles</p>
          <div class="d-flex align-center ga-1 mt-2">
            <v-chip size="x-small" variant="flat" color="rgba(255,255,255,0.25)" style="color: #fff !important">{{ data?.active || 0 }} active</v-chip>
          </div>
        </v-card>
      </v-col>
      <v-col cols="6" md="2">
        <v-card elevation="0" border class="pa-4 h-100 va-kpi-card va-kpi-green" style="color: #fff !important">
          <div class="d-flex align-center justify-space-between mb-2">
            <v-avatar color="rgba(255,255,255,0.2)" size="36" rounded="lg" variant="flat"><v-icon color="white" size="small">mdi-cash-multiple</v-icon></v-avatar>
            <v-icon color="white" size="x-small" style="opacity:.5">mdi-chart-line</v-icon>
          </div>
          <p class="text-h5 font-weight-bold" style="color: #fff !important">{{ currencySymbol }}{{ formatNumberShort(data?.value_stats?.total_purchase_value) }}</p>
          <p class="text-caption" style="color: #fff !important; opacity:.85">Fleet Value</p>
          <div class="d-flex align-center ga-1 mt-2">
            <v-chip size="x-small" variant="flat" color="rgba(255,255,255,0.25)" style="color: #fff !important">Avg {{ currencySymbol }}{{ formatNumberShort(data?.value_stats?.avg_purchase_value) }}</v-chip>
          </div>
        </v-card>
      </v-col>
      <v-col cols="6" md="2">
        <v-card elevation="0" border class="pa-4 h-100 va-kpi-card va-kpi-amber" style="color: #fff !important">
          <div class="d-flex align-center justify-space-between mb-2">
            <v-avatar color="rgba(255,255,255,0.2)" size="36" rounded="lg" variant="flat"><v-icon color="white" size="small">mdi-counter</v-icon></v-avatar>
            <v-icon color="white" size="x-small" style="opacity:.5">mdi-trending-up</v-icon>
          </div>
          <p class="text-h5 font-weight-bold" style="color: #fff !important">{{ formatNumberShort(data?.mileage_stats?.total_mileage) }}</p>
          <p class="text-caption" style="color: #fff !important; opacity:.85">Total Mileage</p>
          <div class="d-flex align-center ga-1 mt-2">
            <v-chip size="x-small" variant="flat" color="rgba(255,255,255,0.25)" style="color: #fff !important">Avg {{ formatNumberShort(data?.mileage_stats?.avg_mileage) }}</v-chip>
          </div>
        </v-card>
      </v-col>
      <v-col cols="6" md="2">
        <v-card elevation="0" border class="pa-4 h-100 va-kpi-card va-kpi-blue" style="color: #fff !important">
          <div class="d-flex align-center justify-space-between mb-2">
            <v-avatar color="rgba(255,255,255,0.2)" size="36" rounded="lg" variant="flat"><v-icon color="white" size="small">mdi-chart-arrows</v-icon></v-avatar>
            <v-icon :color="utilizationTrendUp ? '#10b981' : '#f59e0b'" size="x-small">{{ utilizationTrendUp ? 'mdi-trending-up' : 'mdi-trending-neutral' }}</v-icon>
          </div>
          <p class="text-h5 font-weight-bold" style="color: #fff !important">{{ data?.utilization?.utilization_rate || 0 }}%</p>
          <p class="text-caption" style="color: #fff !important; opacity:.85">Utilization Rate</p>
          <div class="d-flex align-center ga-1 mt-2">
            <v-chip size="x-small" variant="flat" color="rgba(255,255,255,0.25)" style="color: #fff !important">{{ data?.utilization?.active_rentals || 0 }} active rentals</v-chip>
          </div>
        </v-card>
      </v-col>
      <v-col cols="6" md="2">
        <v-card elevation="0" border class="pa-4 h-100 va-kpi-card va-kpi-purple" style="color: #fff !important">
          <div class="d-flex align-center justify-space-between mb-2">
            <v-avatar color="rgba(255,255,255,0.2)" size="36" rounded="lg" variant="flat"><v-icon color="white" size="small">mdi-shield-check</v-icon></v-avatar>
            <v-icon :color="fleetHealthGood ? '#10b981' : '#f59e0b'" size="x-small">{{ fleetHealthGood ? 'mdi-heart-pulse' : 'mdi-alert' }}</v-icon>
          </div>
          <p class="text-h5 font-weight-bold" style="color: #fff !important">{{ data?.fleet_health?.fleet_health_score || 0 }}</p>
          <p class="text-caption" style="color: #fff !important; opacity:.85">Fleet Health Score</p>
          <div class="d-flex align-center ga-1 mt-2">
            <v-chip size="x-small" variant="flat" color="rgba(255,255,255,0.25)" style="color: #fff !important">{{ data?.fleet_health?.vehicles_needing_attention || 0 }} need attention</v-chip>
          </div>
        </v-card>
      </v-col>
      <v-col cols="6" md="2">
        <v-card elevation="0" border class="pa-4 h-100 va-kpi-card va-kpi-red" style="color: #fff !important">
          <div class="d-flex align-center justify-space-between mb-2">
            <v-avatar color="rgba(255,255,255,0.2)" size="36" rounded="lg" variant="flat"><v-icon color="white" size="small">mdi-chart-bell-curve</v-icon></v-avatar>
            <v-icon color="white" size="x-small" style="opacity:.5">mdi-chart-bell-curve-cumulative</v-icon>
          </div>
          <p class="text-h5 font-weight-bold" style="color: #fff !important">{{ currencySymbol }}{{ formatNumberShort(abcSummary.total_revenue) }}</p>
          <p class="text-caption" style="color: #fff !important; opacity:.85">ABC Revenue</p>
          <div class="d-flex align-center ga-1 mt-2">
            <v-chip size="x-small" variant="flat" color="rgba(255,255,255,0.25)" style="color: #fff !important">{{ abcSummary.total_vehicles || 0 }} vehicles ranked</v-chip>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <!-- Quick Insight Banner -->
    <v-card elevation="0" border rounded="lg" class="pa-3 va-insight-bar">
      <div class="d-flex align-center justify-space-between flex-wrap ga-3">
        <div class="d-flex align-center ga-2">
          <v-icon color="primary" size="small">mdi-lightbulb-on-outline</v-icon>
          <span class="text-body-2 font-weight-medium" style="color: rgb(var(--v-theme-on-surface))">Key Insights</span>
        </div>
        <div class="d-flex align-center ga-4 flex-wrap">
          <div class="d-flex align-center ga-1">
            <v-icon color="success" size="small">mdi-check-circle</v-icon>
            <span class="text-body-2 text-medium-emphasis">{{ data?.utilization?.total_rentals || 0 }} total rentals</span>
          </div>
          <div class="d-flex align-center ga-1">
            <v-icon color="info" size="small">mdi-cash</v-icon>
            <span class="text-body-2 text-medium-emphasis">{{ currencySymbol }}{{ formatNumberShort(data?.utilization?.total_revenue) }} revenue</span>
          </div>
          <div class="d-flex align-center ga-1">
            <v-icon color="warning" size="small">mdi-wrench</v-icon>
            <span class="text-body-2 text-medium-emphasis">{{ currencySymbol }}{{ formatNumberShort(data?.cost_analysis?.total_service_cost) }} service cost</span>
          </div>
          <div class="d-flex align-center ga-1">
            <v-icon color="error" size="small">mdi-chart-line-down</v-icon>
            <span class="text-body-2 text-medium-emphasis">{{ currencySymbol }}{{ formatNumberShort(data?.cost_analysis?.total_depreciation_loss) }} depreciation</span>
          </div>
        </div>
      </div>
    </v-card>

    <!-- Tabs for detailed analytics -->
    <v-card elevation="0" border rounded="lg">
      <v-tabs v-model="tab" color="primary" density="compact" show-arrows>
        <v-tab value="composition" slider-color="primary"><v-icon size="small" class="mr-2">mdi-chart-pie</v-icon> Composition</v-tab>
        <v-tab value="value" slider-color="primary"><v-icon size="small" class="mr-2">mdi-cash-multiple</v-icon> Value &amp; Mileage</v-tab>
        <v-tab value="utilization" slider-color="primary"><v-icon size="small" class="mr-2">mdi-chart-arrows</v-icon> Utilization</v-tab>
        <v-tab value="cost" slider-color="primary"><v-icon size="small" class="mr-2">mdi-cash-remove</v-icon> Cost &amp; Depreciation</v-tab>
        <v-tab value="health" slider-color="primary"><v-icon size="small" class="mr-2">mdi-shield-check</v-icon> Fleet Health</v-tab>
        <v-tab value="lifecycle" slider-color="primary"><v-icon size="small" class="mr-2">mdi-chart-line-variant</v-icon> Lifecycle</v-tab>
        <v-tab value="abc" slider-color="primary"><v-icon size="small" class="mr-2">mdi-chart-bell-curve</v-icon> ABC Analysis</v-tab>
      </v-tabs>
      <v-divider />
      <v-window v-model="tab" class="pa-5">
        <!-- Composition Tab -->
        <v-window-item value="composition">
          <v-row dense>
            <v-col cols="12" md="6" lg="4">
              <DashboardChart :option="statusChartOption" title="Status Distribution" icon="mdi-chart-pie" height="280px" />
            </v-col>
            <v-col cols="12" md="6" lg="4">
              <DashboardChart :option="fuelChartOption" title="Fuel Type Breakdown" icon="mdi-fuel" height="280px" />
            </v-col>
            <v-col cols="12" md="6" lg="4">
              <DashboardChart :option="vehicleTypeChartOption" title="Vehicle Type" icon="mdi-car-estate" height="280px" />
            </v-col>
            <v-col cols="12" md="6" lg="4">
              <DashboardChart :option="ownershipChartOption" title="Ownership" icon="mdi-handshake-outline" height="280px" />
            </v-col>
            <v-col cols="12" md="6" lg="8">
              <DashboardChart :option="makeChartOption" title="Top Makes" icon="mdi-factory" height="280px" />
            </v-col>
          </v-row>
        </v-window-item>

        <!-- Value & Mileage Tab -->
        <v-window-item value="value">
          <v-row dense>
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 text-center va-mini-stat">
                <v-icon color="primary" size="large">mdi-cash</v-icon>
                <p class="text-h6 font-weight-bold mt-2">{{ currencySymbol }}{{ formatNumber(data?.value_stats?.total_purchase_value) }}</p>
                <p class="text-caption text-medium-emphasis">Total Purchase Value</p>
              </v-card>
            </v-col>
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 text-center va-mini-stat">
                <v-icon color="info" size="large">mdi-cash-check</v-icon>
                <p class="text-h6 font-weight-bold mt-2">{{ currencySymbol }}{{ formatNumber(data?.value_stats?.avg_purchase_value) }}</p>
                <p class="text-caption text-medium-emphasis">Avg Purchase Value</p>
              </v-card>
            </v-col>
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 text-center va-mini-stat">
                <v-icon color="success" size="large">mdi-counter</v-icon>
                <p class="text-h6 font-weight-bold mt-2">{{ formatNumber(data?.mileage_stats?.total_mileage) }}</p>
                <p class="text-caption text-medium-emphasis">Total Fleet Mileage</p>
              </v-card>
            </v-col>
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 text-center va-mini-stat">
                <v-icon color="warning" size="large">mdi-speedometer</v-icon>
                <p class="text-h6 font-weight-bold mt-2">{{ formatNumber(data?.mileage_stats?.avg_mileage) }}</p>
                <p class="text-caption text-medium-emphasis">Avg Mileage / Vehicle</p>
              </v-card>
            </v-col>
            <v-col cols="12" class="pt-2">
              <DashboardChart :option="mileageByStatusOption" title="Vehicle Count by Status" icon="mdi-chart-bar" height="300px" />
            </v-col>
            <v-col cols="12" md="6">
              <DashboardChart :option="mileageByTypeOption" title="Vehicle Count by Type" icon="mdi-chart-bar" height="300px" />
            </v-col>
            <v-col cols="12" md="6">
              <DashboardChart :option="valueByMakeOption" title="Top Makes by Count" icon="mdi-cash-multiple" height="300px" />
            </v-col>
          </v-row>
        </v-window-item>

        <!-- Utilization Tab -->
        <v-window-item value="utilization">
          <v-row dense>
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 text-center va-mini-stat">
                <v-icon color="primary" size="large">mdi-chart-arrows</v-icon>
                <p class="text-h5 font-weight-bold mt-2">{{ data?.utilization?.utilization_rate || 0 }}%</p>
                <p class="text-caption text-medium-emphasis">Utilization Rate</p>
              </v-card>
            </v-col>
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 text-center va-mini-stat">
                <v-icon color="success" size="large"> mdi-car-connected</v-icon>
                <p class="text-h5 font-weight-bold mt-2">{{ data?.utilization?.active_rentals || 0 }}</p>
                <p class="text-caption text-medium-emphasis">Active Rentals</p>
              </v-card>
            </v-col>
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 text-center va-mini-stat">
                <v-icon color="info" size="large">mdi-check-all</v-icon>
                <p class="text-h5 font-weight-bold mt-2">{{ data?.utilization?.completed_rentals || 0 }}</p>
                <p class="text-caption text-medium-emphasis">Completed</p>
              </v-card>
            </v-col>
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 text-center va-mini-stat">
                <v-icon color="warning" size="large">mdi-car-off</v-icon>
                <p class="text-h5 font-weight-bold mt-2">{{ data?.utilization?.idle_vehicles || 0 }}</p>
                <p class="text-caption text-medium-emphasis">Idle Vehicles</p>
              </v-card>
            </v-col>
            <v-col cols="12" md="8">
              <DashboardChart :option="revenueTrendChartOption" title="Revenue Trend (Last 12 Months)" icon="mdi-chart-line" height="320px" />
            </v-col>
            <v-col cols="12" md="4">
              <DashboardChart :option="rentalGaugeOption" title="Fleet Utilization" icon="mdi-gauge" height="320px" />
            </v-col>
            <v-col cols="12" md="6">
              <DashboardChart :option="revenueByTypeOption" title="Revenue by Vehicle Type" icon="mdi-chart-bar" height="300px" />
            </v-col>
            <v-col cols="12" md="6">
              <v-card elevation="0" border class="pa-5 h-100">
                <div class="d-flex align-center ga-2 mb-4">
                  <v-icon size="small" color="primary">mdi-trophy-variant</v-icon>
                  <h3 class="text-subtitle-1 font-weight-bold" style="color: rgb(var(--v-theme-on-surface))">Top Revenue Vehicles</h3>
                </div>
                <div v-for="(v, i) in (data?.utilization?.top_vehicles || []).slice(0, 5)" :key="v.id" class="d-flex align-center justify-space-between pa-2 rounded-lg mb-1 va-rank-row">
                  <div class="d-flex align-center ga-2">
                    <v-avatar size="28" rounded="sm" :color="i === 0 ? '#f59e0b' : i === 1 ? '#94a3b8' : i === 2 ? '#cd7f32' : 'primary'" variant="flat"><span class="text-caption font-weight-bold text-white">{{ i + 1 }}</span></v-avatar>
                    <div>
                      <p class="text-body-2 font-weight-medium" style="color: rgb(var(--v-theme-on-surface))">{{ v.make }} {{ v.model }}</p>
                      <p class="text-caption text-medium-emphasis">{{ v.year }} · {{ v.license_plate || '—' }} · {{ v.rental_cnt }} rentals</p>
                    </div>
                  </div>
                  <span class="text-body-2 font-weight-bold text-success">{{ currencySymbol }}{{ formatNumberShort(v.rev) }}</span>
                </div>
                <p v-if="!(data?.utilization?.top_vehicles?.length)" class="text-caption text-medium-emphasis text-center pa-4">No rental data available</p>
              </v-card>
            </v-col>
          </v-row>
        </v-window-item>

        <!-- Cost & Depreciation Tab -->
        <v-window-item value="cost">
          <v-row dense>
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 text-center va-mini-stat">
                <v-icon color="error" size="large">mdi-wrench</v-icon>
                <p class="text-h5 font-weight-bold mt-2">{{ currencySymbol }}{{ formatNumberShort(data?.cost_analysis?.total_service_cost) }}</p>
                <p class="text-caption text-medium-emphasis">Total Service Cost</p>
              </v-card>
            </v-col>
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 text-center va-mini-stat">
                <v-icon color="warning" size="large">mdi-chart-line-down</v-icon>
                <p class="text-h5 font-weight-bold mt-2">{{ currencySymbol }}{{ formatNumberShort(data?.cost_analysis?.total_depreciation_loss) }}</p>
                <p class="text-caption text-medium-emphasis">Total Depreciation</p>
              </v-card>
            </v-col>
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 text-center va-mini-stat">
                <v-icon color="info" size="large">mdi-book-open-variant</v-icon>
                <p class="text-h5 font-weight-bold mt-2">{{ currencySymbol }}{{ formatNumberShort(data?.cost_analysis?.total_book_value) }}</p>
                <p class="text-caption text-medium-emphasis">Total Book Value</p>
              </v-card>
            </v-col>
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 text-center va-mini-stat">
                <v-icon color="success" size="large">mdi-speedometer</v-icon>
                <p class="text-h5 font-weight-bold mt-2">{{ currencySymbol }}{{ formatNumberShort(data?.cost_analysis?.cost_per_km) }}</p>
                <p class="text-caption text-medium-emphasis">Cost per Km</p>
              </v-card>
            </v-col>
            <v-col cols="12" md="6">
              <DashboardChart :option="serviceCostByTypeOption" title="Service Cost by Type" icon="mdi-chart-bar" height="300px" />
            </v-col>
            <v-col cols="12" md="6">
              <DashboardChart :option="depreciationChartOption" title="Depreciation by Vehicle" icon="mdi-chart-bar" height="300px" />
            </v-col>
            <v-col cols="12">
              <v-card elevation="0" border class="pa-5">
                <div class="d-flex align-center ga-2 mb-4">
                  <v-icon size="small" color="primary">mdi-table-large</v-icon>
                  <h3 class="text-subtitle-1 font-weight-bold" style="color: rgb(var(--v-theme-on-surface))">Depreciation Detail</h3>
                </div>
                <v-data-table
                  :headers="depreciationHeaders"
                  :items="data?.cost_analysis?.vehicles || []"
                  density="compact"
                  hide-default-footer
                  :items-per-page="-1"
                  class="rounded-lg"
                >
                  <template #item.vehicle="{ item }">
                    <span class="font-weight-medium" style="color: rgb(var(--v-theme-on-surface))">{{ item.make }} {{ item.model }}</span>
                    <span class="text-caption text-medium-emphasis ml-1">· {{ item.year }}</span>
                  </template>
                  <template #item.purchase_price="{ item }">
                    {{ currencySymbol }}{{ formatNumber(item.purchase_price) }}
                  </template>
                  <template #item.book_value="{ item }">
                    <v-chip :color="item.depreciation_pct > 50 ? 'error' : item.depreciation_pct > 20 ? 'warning' : 'success'" variant="tonal" size="small">{{ currencySymbol }}{{ formatNumber(item.book_value) }}</v-chip>
                  </template>
                  <template #item.annual_depreciation="{ item }">
                    {{ currencySymbol }}{{ formatNumber(item.annual_depreciation) }}
                  </template>
                  <template #item.depreciation_pct="{ item }">
                    <div class="d-flex align-center ga-2">
                      <span style="min-width: 45px" :class="item.depreciation_pct > 50 ? 'text-error' : item.depreciation_pct > 20 ? 'text-warning' : 'text-success'">{{ item.depreciation_pct }}%</span>
                      <v-progress-linear :model-value="item.depreciation_pct" :color="item.depreciation_pct > 50 ? 'error' : item.depreciation_pct > 20 ? 'warning' : 'success'" height="6" rounded style="max-width: 80px" />
                    </div>
                  </template>
                </v-data-table>
              </v-card>
            </v-col>
          </v-row>
        </v-window-item>

        <!-- Fleet Health Tab -->
        <v-window-item value="health">
          <v-row dense>
            <v-col cols="12" md="4">
              <v-card elevation="0" border class="pa-5 h-100 text-center va-health-score-card">
                <div class="d-flex align-center justify-center ga-2 mb-3">
                  <v-avatar :color="fleetHealthGood ? '#10b981' : '#f59e0b'" size="56" rounded="xl" variant="flat"><v-icon color="white" size="large">mdi-heart-pulse</v-icon></v-avatar>
                </div>
                <p class="text-h2 font-weight-bold mb-1" :style="{ color: fleetHealthGood ? '#10b981' : '#f59e0b' }">{{ data?.fleet_health?.fleet_health_score || 0 }}</p>
                <p class="text-caption text-medium-emphasis mb-3">Fleet Health Score / 100</p>
                <v-progress-linear :model-value="data?.fleet_health?.fleet_health_score || 0" :color="fleetHealthGood ? 'success' : 'warning'" height="10" rounded />
                <div class="d-flex justify-space-around mt-4">
                  <div class="text-center">
                    <p class="text-h6 font-weight-bold text-success">{{ data?.fleet_health?.pass_count || 0 }}</p>
                    <p class="text-caption text-medium-emphasis">Passed</p>
                  </div>
                  <div class="text-center">
                    <p class="text-h6 font-weight-bold text-error">{{ data?.fleet_health?.fail_count || 0 }}</p>
                    <p class="text-caption text-medium-emphasis">Failed</p>
                  </div>
                  <div class="text-center">
                    <p class="text-h6 font-weight-bold text-info">{{ data?.fleet_health?.total_inspections || 0 }}</p>
                    <p class="text-caption text-medium-emphasis">Total</p>
                  </div>
                </div>
              </v-card>
            </v-col>
            <v-col cols="12" md="4">
              <v-card elevation="0" border class="pa-5 h-100">
                <div class="d-flex align-center ga-2 mb-4">
                  <v-icon size="small" color="warning">mdi-alert-circle-outline</v-icon>
                  <h3 class="text-subtitle-1 font-weight-bold" style="color: rgb(var(--v-theme-on-surface))">Maintenance & Status</h3>
                </div>
                <div class="d-flex align-center justify-space-between pa-3 rounded-lg mb-2" style="background: rgba(245, 158, 11, 0.08)">
                  <div class="d-flex align-center ga-2">
                    <v-avatar color="#f59e0b" size="32" rounded="lg" variant="flat"><v-icon size="small" color="white">mdi-wrench</v-icon></v-avatar>
                    <span class="text-body-2 font-weight-medium" style="color: rgb(var(--v-theme-on-surface))">In Maintenance</span>
                  </div>
                  <div class="text-right">
                    <span class="text-h6 font-weight-bold text-warning">{{ data?.in_maintenance || 0 }}</span>
                    <span class="text-caption text-medium-emphasis ml-1">({{ data?.fleet_health?.maintenance_pct || 0 }}%)</span>
                  </div>
                </div>
                <div class="d-flex align-center justify-space-between pa-3 rounded-lg mb-2" style="background: rgba(239, 68, 68, 0.08)">
                  <div class="d-flex align-center ga-2">
                    <v-avatar color="#ef4444" size="32" rounded="lg" variant="flat"><v-icon size="small" color="white">mdi-car-off</v-icon></v-avatar>
                    <span class="text-body-2 font-weight-medium" style="color: rgb(var(--v-theme-on-surface))">Out of Service</span>
                  </div>
                  <div class="text-right">
                    <span class="text-h6 font-weight-bold text-error">{{ data?.out_of_service || 0 }}</span>
                    <span class="text-caption text-medium-emphasis ml-1">({{ data?.fleet_health?.out_of_service_pct || 0 }}%)</span>
                  </div>
                </div>
                <div class="d-flex align-center justify-space-between pa-3 rounded-lg" style="background: rgba(239, 68, 68, 0.06)">
                  <div class="d-flex align-center ga-2">
                    <v-avatar color="#ef4444" size="32" rounded="lg" variant="flat"><v-icon size="small" color="white">mdi-bell-alert</v-icon></v-avatar>
                    <span class="text-body-2 font-weight-medium" style="color: rgb(var(--v-theme-on-surface))">Needs Attention</span>
                  </div>
                  <span class="text-h6 font-weight-bold text-error">{{ data?.fleet_health?.vehicles_needing_attention || 0 }}</span>
                </div>
              </v-card>
            </v-col>
            <v-col cols="12" md="4">
              <DashboardChart :option="inspectionStatusOption" title="Inspection Results" icon="mdi-clipboard-check-outline" height="340px" />
            </v-col>
            <v-col cols="12" md="6">
              <DashboardChart :option="fleetStatusRadialOption" title="Fleet Status Overview" icon="mdi-chart-donut" height="320px" />
            </v-col>
            <v-col cols="12" md="6">
              <v-card elevation="0" border class="pa-5 h-100">
                <div class="d-flex align-center ga-2 mb-4">
                  <v-icon size="small" color="primary">mdi-shield-account-outline</v-icon>
                  <h3 class="text-subtitle-1 font-weight-bold" style="color: rgb(var(--v-theme-on-surface))">Health Indicators</h3>
                </div>
                <div class="d-flex align-center justify-space-between mb-3">
                  <span class="text-body-2 text-medium-emphasis">Utilization Rate</span>
                  <div class="d-flex align-center ga-2" style="min-width: 140px">
                    <v-progress-linear :model-value="data?.utilization?.utilization_rate || 0" color="primary" height="8" rounded />
                    <span style="min-width: 38px" class="text-body-2 font-weight-bold text-right">{{ data?.utilization?.utilization_rate || 0 }}%</span>
                  </div>
                </div>
                <div class="d-flex align-center justify-space-between mb-3">
                  <span class="text-body-2 text-medium-emphasis">Inspection Pass Rate</span>
                  <div class="d-flex align-center ga-2" style="min-width: 140px">
                    <v-progress-linear :model-value="data?.fleet_health?.inspection_pass_rate || 0" color="success" height="8" rounded />
                    <span style="min-width: 38px" class="text-body-2 font-weight-bold text-right">{{ data?.fleet_health?.inspection_pass_rate || 0 }}%</span>
                  </div>
                </div>
                <div class="d-flex align-center justify-space-between mb-3">
                  <span class="text-body-2 text-medium-emphasis">Active Fleet</span>
                  <div class="d-flex align-center ga-2" style="min-width: 140px">
                    <v-progress-linear :model-value="activePercent" color="success" height="8" rounded />
                    <span style="min-width: 38px" class="text-body-2 font-weight-bold text-right">{{ activePercent }}%</span>
                  </div>
                </div>
                <div class="d-flex align-center justify-space-between mb-3">
                  <span class="text-body-2 text-medium-emphasis">Maintenance Ratio</span>
                  <div class="d-flex align-center ga-2" style="min-width: 140px">
                    <v-progress-linear :model-value="data?.fleet_health?.maintenance_pct || 0" color="warning" height="8" rounded />
                    <span style="min-width: 38px" class="text-body-2 font-weight-bold text-right">{{ data?.fleet_health?.maintenance_pct || 0 }}%</span>
                  </div>
                </div>
                <div class="d-flex align-center justify-space-between">
                  <span class="text-body-2 text-medium-emphasis">Out of Service</span>
                  <div class="d-flex align-center ga-2" style="min-width: 140px">
                    <v-progress-linear :model-value="data?.fleet_health?.out_of_service_pct || 0" color="error" height="8" rounded />
                    <span style="min-width: 38px" class="text-body-2 font-weight-bold text-right">{{ data?.fleet_health?.out_of_service_pct || 0 }}%</span>
                  </div>
                </div>
              </v-card>
            </v-col>
          </v-row>
        </v-window-item>

        <!-- Lifecycle Tab -->
        <v-window-item value="lifecycle">
          <v-row dense>
            <v-col cols="12" md="6">
              <DashboardChart :option="ageChartOption" title="Fleet Age Distribution" icon="mdi-calendar-clock" height="300px" />
            </v-col>
            <v-col cols="12" md="6">
              <DashboardChart :option="acquisitionChartOption" title="Acquisition Trend" icon="mdi-chart-line" height="300px" />
            </v-col>
            <v-col cols="12" md="6">
              <v-card elevation="0" border class="pa-5 h-100 va-info-card">
                <h3 class="text-subtitle-1 font-weight-medium mb-4"><v-icon size="small" color="success" class="mr-2">mdi-battery-charging</v-icon> Electric Vehicle Stats</h3>
                <v-row dense>
                  <v-col cols="4" class="text-center">
                    <p class="text-h5 font-weight-bold text-success">{{ data?.ev_stats?.count || 0 }}</p>
                    <p class="text-caption text-medium-emphasis">EV Count</p>
                  </v-col>
                  <v-col cols="4" class="text-center">
                    <p class="text-h5 font-weight-bold">{{ (data?.ev_stats?.avg_state_of_charge || 0).toFixed(0) }}%</p>
                    <p class="text-caption text-medium-emphasis">Avg Charge</p>
                  </v-col>
                  <v-col cols="4" class="text-center">
                    <p class="text-h5 font-weight-bold text-info">{{ (data?.ev_stats?.avg_state_of_health || 0).toFixed(0) }}%</p>
                    <p class="text-caption text-medium-emphasis">Avg Health</p>
                  </v-col>
                </v-row>
                <v-progress-linear :model-value="data?.ev_stats?.avg_state_of_charge || 0" color="success" height="10" rounded class="mt-4" />
                <p class="text-caption text-medium-emphasis mt-1">State of Charge</p>
                <v-progress-linear :model-value="data?.ev_stats?.avg_state_of_health || 0" color="info" height="10" rounded class="mt-3" />
                <p class="text-caption text-medium-emphasis mt-1">State of Health</p>
              </v-card>
            </v-col>
            <v-col cols="12" md="6">
              <v-card elevation="0" border class="pa-5 h-100 va-info-card">
                <h3 class="text-subtitle-1 font-weight-medium mb-4"><v-icon size="small" color="primary" class="mr-2">mdi-chart-donut</v-icon> Status Summary</h3>
                <div v-for="item in statusList" :key="item.status" class="d-flex align-center justify-space-between pa-3 rounded-lg mb-2 va-status-row" :style="{ background: item.color + '08' }">
                  <div class="d-flex align-center ga-2">
                    <v-avatar :color="item.color" size="32" rounded="lg" variant="flat">
                      <v-icon size="small" color="white">{{ item.icon }}</v-icon>
                    </v-avatar>
                    <span class="text-body-2 font-weight-medium" style="color: rgb(var(--v-theme-on-surface))">{{ item.label }}</span>
                  </div>
                  <span class="text-body-1 font-weight-bold" :style="{ color: item.color }">{{ item.count }}</span>
                </div>
              </v-card>
            </v-col>
          </v-row>
        </v-window-item>

        <!-- ABC Analysis Tab -->
        <v-window-item value="abc">
          <!-- ABC Date Filter Bar -->
          <v-card variant="outlined" rounded="lg" class="pa-3 mb-4">
            <div class="d-flex align-center ga-3 flex-wrap">
              <div class="d-flex align-center ga-2">
                <v-icon icon="mdi-filter-calendar" color="primary" size="small" />
                <span class="text-body-2 font-weight-bold text-medium-emphasis">ABC Period (Rental Date)</span>
              </div>
              <v-btn-group density="compact" variant="outlined" color="primary">
                <v-btn
                  v-for="opt in abcPresetOptions"
                  :key="opt.value"
                  size="small"
                  :variant="abcPeriod === opt.value ? 'flat' : 'text'"
                  :color="abcPeriod === opt.value ? 'primary' : undefined"
                  @click="applyAbcPreset(opt.value)"
                >
                  {{ opt.label }}
                </v-btn>
              </v-btn-group>
              <template v-if="abcPeriod === 'custom'">
                <v-text-field
                  v-model="abcCustomFrom"
                  type="date"
                  density="compact"
                  variant="outlined"
                  label="Start"
                  hide-details
                  style="max-width: 150px"
                  @update:model-value="onAbcCustomDateChange"
                />
                <v-text-field
                  v-model="abcCustomTo"
                  type="date"
                  density="compact"
                  variant="outlined"
                  label="End"
                  hide-details
                  style="max-width: 150px"
                  @update:model-value="onAbcCustomDateChange"
                />
                <v-btn size="small" color="primary" variant="flat" @click="refreshAbc" :loading="abcPending">Apply</v-btn>
              </template>
              <v-spacer />
              <v-chip v-if="abcPeriodLabel" size="small" variant="tonal" color="primary" prepend-icon="mdi-calendar">
                {{ abcPeriodLabel }}
              </v-chip>
            </div>
          </v-card>

          <!-- ABC Summary Cards -->
          <v-row dense class="mb-2">
            <v-col cols="12" md="3">
              <v-card elevation="0" border class="pa-5 h-100 abc-class-card abc-class-a-card">
                <div class="d-flex align-center justify-space-between mb-3">
                  <div class="abc-class-badge">A</div>
                  <v-icon color="white" size="large">mdi-star-circle</v-icon>
                </div>
                <p class="text-h3 font-weight-bold text-white mb-1">{{ abcSummary.A?.count || 0 }}</p>
                <p class="text-caption text-white" style="opacity:.85">Class A — Top Performers</p>
                <v-divider class="my-3" style="border-color: rgba(255,255,255,0.2)" />
                <div class="d-flex justify-space-between text-white">
                  <span class="text-caption" style="opacity:.85">Revenue</span>
                  <span class="text-body-2 font-weight-bold">{{ currencySymbol }}{{ formatNumber(abcSummary.A?.revenue) }}</span>
                </div>
                <div class="d-flex justify-space-between text-white mt-1">
                  <span class="text-caption" style="opacity:.85">% of Fleet</span>
                  <span class="text-body-2 font-weight-bold">{{ abcSummary.A?.pct || 0 }}%</span>
                </div>
              </v-card>
            </v-col>
            <v-col cols="12" md="3">
              <v-card elevation="0" border class="pa-5 h-100 abc-class-card abc-class-b-card">
                <div class="d-flex align-center justify-space-between mb-3">
                  <div class="abc-class-badge">B</div>
                  <v-icon color="white" size="large">mdi-trending-up</v-icon>
                </div>
                <p class="text-h3 font-weight-bold text-white mb-1">{{ abcSummary.B?.count || 0 }}</p>
                <p class="text-caption text-white" style="opacity:.85">Class B — Steady Performers</p>
                <v-divider class="my-3" style="border-color: rgba(255,255,255,0.2)" />
                <div class="d-flex justify-space-between text-white">
                  <span class="text-caption" style="opacity:.85">Revenue</span>
                  <span class="text-body-2 font-weight-bold">{{ currencySymbol }}{{ formatNumber(abcSummary.B?.revenue) }}</span>
                </div>
                <div class="d-flex justify-space-between text-white mt-1">
                  <span class="text-caption" style="opacity:.85">% of Fleet</span>
                  <span class="text-body-2 font-weight-bold">{{ abcSummary.B?.pct || 0 }}%</span>
                </div>
              </v-card>
            </v-col>
            <v-col cols="12" md="3">
              <v-card elevation="0" border class="pa-5 h-100 abc-class-card abc-class-c-card">
                <div class="d-flex align-center justify-space-between mb-3">
                  <div class="abc-class-badge">C</div>
                  <v-icon color="white" size="large">mdi-package-variant-closed</v-icon>
                </div>
                <p class="text-h3 font-weight-bold text-white mb-1">{{ abcSummary.C?.count || 0 }}</p>
                <p class="text-caption text-white" style="opacity:.85">Class C — Low Contributors</p>
                <v-divider class="my-3" style="border-color: rgba(255,255,255,0.2)" />
                <div class="d-flex justify-space-between text-white">
                  <span class="text-caption" style="opacity:.85">Revenue</span>
                  <span class="text-body-2 font-weight-bold">{{ currencySymbol }}{{ formatNumber(abcSummary.C?.revenue) }}</span>
                </div>
                <div class="d-flex justify-space-between text-white mt-1">
                  <span class="text-caption" style="opacity:.85">% of Fleet</span>
                  <span class="text-body-2 font-weight-bold">{{ abcSummary.C?.pct || 0 }}%</span>
                </div>
              </v-card>
            </v-col>
            <v-col cols="12" md="3">
              <v-card elevation="0" border class="pa-5 h-100 abc-total-card">
                <div class="d-flex align-center justify-space-between mb-3">
                  <div class="abc-class-badge">Σ</div>
                  <v-icon color="white" size="large">mdi-chart-bell-curve-cumulative</v-icon>
                </div>
                <p class="text-h3 font-weight-bold text-white mb-1">{{ currencySymbol }}{{ formatNumber(abcSummary.total_revenue) }}</p>
                <p class="text-caption text-white" style="opacity:.85">Total Revenue (All Classes)</p>
                <v-divider class="my-3" style="border-color: rgba(255,255,255,0.2)" />
                <div class="d-flex justify-space-between text-white">
                  <span class="text-caption" style="opacity:.85">Ranked Vehicles</span>
                  <span class="text-body-2 font-weight-bold">{{ abcSummary.total_vehicles || 0 }}</span>
                </div>
                <div class="d-flex justify-space-between text-white mt-1">
                  <span class="text-caption" style="opacity:.85">No Rentals</span>
                  <span class="text-body-2 font-weight-bold">{{ abcData.no_revenue_count || 0 }}</span>
                </div>
              </v-card>
            </v-col>
          </v-row>

          <!-- Pareto Chart + Distribution -->
          <v-row dense>
            <v-col cols="12" md="8">
              <DashboardChart :option="paretoChartOption" title="Pareto Chart — Revenue vs Cumulative %" icon="mdi-chart-bell-curve-cumulative" height="380px" />
            </v-col>
            <v-col cols="12" md="4">
              <DashboardChart :option="abcPieOption" title="Revenue Share by Class" icon="mdi-chart-pie" height="380px" />
            </v-col>
          </v-row>

          <!-- ABC Vehicle Table -->
          <v-row dense>
            <v-col cols="12">
              <v-card elevation="0" border class="pa-5">
                <div class="d-flex align-center justify-space-between mb-4 flex-wrap ga-2">
                  <div class="d-flex align-center ga-2">
                    <v-icon size="small" color="primary">mdi-format-list-numbered</v-icon>
                    <h3 class="text-subtitle-1 font-weight-bold" style="color: rgb(var(--v-theme-on-surface))">Vehicle Ranking (Revenue-Based)</h3>
                  </div>
                  <div class="d-flex align-center ga-2">
                    <v-chip size="small" variant="flat" color="#10b981" text-color="white">A: {{ abcSummary.A?.count || 0 }}</v-chip>
                    <v-chip size="small" variant="flat" color="#3b82f6" text-color="white">B: {{ abcSummary.B?.count || 0 }}</v-chip>
                    <v-chip size="small" variant="flat" color="#f59e0b" text-color="white">C: {{ abcSummary.C?.count || 0 }}</v-chip>
                  </div>
                </div>
                <v-data-table
                  :headers="abcHeaders"
                  :items="abcData.vehicles || []"
                  density="compact"
                  hide-default-footer
                  :items-per-page="-1"
                  class="rounded-lg"
                >
                  <template #item.rank="{ index }">
                    <span class="font-weight-bold" :class="abcRankClass(index)">#{{ index + 1 }}</span>
                  </template>
                  <template #item.vehicle="{ item }">
                    <div class="d-flex align-center ga-2">
                      <v-avatar size="32" rounded="lg" :color="abcClassColor(item.abc_class)" variant="flat">
                        <span class="text-body-2 font-weight-bold text-white">{{ item.abc_class }}</span>
                      </v-avatar>
                      <div>
                        <p class="text-body-2 font-weight-medium" style="color: rgb(var(--v-theme-on-surface))">{{ item.make }} {{ item.model }}</p>
                        <p class="text-caption text-medium-emphasis">{{ item.year || '—' }} · {{ item.license_plate || (item.vin && item.vin.length >= 6 ? item.vin.slice(-6) : '—') }}</p>
                      </div>
                    </div>
                  </template>
                  <template #item.abc_class="{ item }">
                    <v-chip size="small" :color="abcClassColor(item.abc_class)" variant="flat" text-color="white">
                      Class {{ item.abc_class }}
                    </v-chip>
                  </template>
                  <template #item.total_rev="{ item }">
                    <span class="font-weight-bold" :style="{ color: abcClassColor(item.abc_class) }">{{ currencySymbol }}{{ formatNumber(item.total_rev) }}</span>
                  </template>
                  <template #item.revenue_pct="{ item }">
                    <div class="d-flex align-center ga-2">
                      <span style="min-width: 45px">{{ item.revenue_pct }}%</span>
                      <v-progress-linear :model-value="item.revenue_pct" :color="abcClassColor(item.abc_class)" height="6" rounded style="max-width: 80px" />
                    </div>
                  </template>
                  <template #item.cumulative_pct="{ item }">
                    <div class="d-flex align-center ga-2">
                      <span style="min-width: 50px">{{ item.cumulative_pct }}%</span>
                      <v-progress-linear :model-value="item.cumulative_pct" color="primary" height="6" rounded style="max-width: 80px" />
                    </div>
                  </template>
                  <template #item.rental_count="{ item }">
                    <v-chip size="small" variant="tonal">{{ item.rental_count }} rentals</v-chip>
                  </template>
                </v-data-table>
              </v-card>
            </v-col>
          </v-row>

          <!-- ABC Strategy Info -->
          <v-row dense class="mt-2">
            <v-col cols="12" md="4">
              <v-card elevation="0" border class="pa-4 abc-strategy-card abc-strategy-a">
                <div class="d-flex align-center ga-2 mb-2">
                  <v-avatar color="#10b981" size="36" rounded="lg" variant="flat"><v-icon color="white" size="small">mdi-alpha-a</v-icon></v-avatar>
                  <div>
                    <p class="text-body-1 font-weight-bold mb-0" style="color: rgb(var(--v-theme-on-surface))">Class A Strategy</p>
                    <p class="text-caption text-medium-emphasis">80% of revenue</p>
                  </div>
                </div>
                <p class="text-body-2 text-medium-emphasis">High-value, mission-critical vehicles. Prioritise maintenance, ensure availability, and maximise utilisation. Consider acquiring similar vehicles.</p>
              </v-card>
            </v-col>
            <v-col cols="12" md="4">
              <v-card elevation="0" border class="pa-4 abc-strategy-card abc-strategy-b">
                <div class="d-flex align-center ga-2 mb-2">
                  <v-avatar color="#3b82f6" size="36" rounded="lg" variant="flat"><v-icon color="white" size="small">mdi-alpha-b</v-icon></v-avatar>
                  <div>
                    <p class="text-body-1 font-weight-bold mb-0" style="color: rgb(var(--v-theme-on-surface))">Class B Strategy</p>
                    <p class="text-caption text-medium-emphasis">Next 15% of revenue</p>
                  </div>
                </div>
                <p class="text-body-2 text-medium-emphasis">Steady contributors. Monitor performance, improve marketing efforts, and consider upgrading utilisation to move them to Class A.</p>
              </v-card>
            </v-col>
            <v-col cols="12" md="4">
              <v-card elevation="0" border class="pa-4 abc-strategy-card abc-strategy-c">
                <div class="d-flex align-center ga-2 mb-2">
                  <v-avatar color="#f59e0b" size="36" rounded="lg" variant="flat"><v-icon color="white" size="small">mdi-alpha-c</v-icon></v-avatar>
                  <div>
                    <p class="text-body-1 font-weight-bold mb-0" style="color: rgb(var(--v-theme-on-surface))">Class C Strategy</p>
                    <p class="text-caption text-medium-emphasis">Bottom 5% of revenue</p>
                  </div>
                </div>
                <p class="text-body-2 text-medium-emphasis">Underperforming assets. Evaluate profitability, consider redeployment, price adjustment, or disposal. Identify reasons for low utilisation.</p>
              </v-card>
            </v-col>
          </v-row>
        </v-window-item>
      </v-window>
    </v-card>
  </div>
</template>

<script setup lang="ts">
const { $api } = useNuxtApp()
const { currencySymbol } = useCurrency()
const tab = ref('composition')
const period = ref('all')
const customFrom = ref('')
const customTo = ref('')
const customDateDialogVisible = ref(false)
const customDateError = ref('')

/** Returns the query params for the analytics endpoint based on selected period. */
function periodQuery() {
  if (period.value === 'custom') {
    const q: Record<string, string> = {}
    if (customFrom.value) q['date__gte'] = customFrom.value
    if (customTo.value) q['date__lte'] = customTo.value
    return q
  }
  if (period.value === 'y') {
    return { date__gte: `${new Date().getFullYear()}-01-01` }
  }
  if (period.value === '365' || period.value === '90') {
    const past = new Date()
    past.setDate(past.getDate() - Number(period.value))
    return { date__gte: past.toISOString().slice(0, 10) }
  }
  return {}
}

function openCustomDate() {
  if (!customFrom.value || !customTo.value) {
    const today = new Date()
    const past = new Date()
    past.setFullYear(past.getFullYear() - 1)
    customTo.value = today.toISOString().slice(0, 10)
    customFrom.value = past.toISOString().slice(0, 10)
  }
  customDateError.value = ''
  customDateDialogVisible.value = true
}

function applyCustomDate() {
  if (!customFrom.value || !customTo.value) {
    customDateError.value = 'Please select both from and to dates.'
    return
  }
  if (new Date(customFrom.value) > new Date(customTo.value)) {
    customDateError.value = 'From date must be before To date.'
    return
  }
  customDateDialogVisible.value = false
  refresh()
}

function cancelCustomDate() {
  customDateDialogVisible.value = false
  if (!customFrom.value || !customTo.value) period.value = 'all'
  else period.value = 'custom'
}

const { data, refresh, pending } = useAsyncData(
  'vehicle-analytics',
  () => $api('/vehicles/vehicles/analytics/', { query: periodQuery() }).catch(() => null),
  { default: () => null, watch: [period] }
)

function formatNumber(val: any) {
  if (!val || isNaN(val)) return '0'
  return Number(val).toLocaleString('en-US', { maximumFractionDigits: 0 })
}

function formatNumberShort(val: any) {
  if (!val || isNaN(val)) return '0'
  const n = Number(val)
  if (n >= 1_000_000) return (n / 1_000_000).toFixed(1) + 'M'
  if (n >= 1_000) return (n / 1_000).toFixed(1) + 'K'
  return n.toLocaleString('en-US', { maximumFractionDigits: 0 })
}

// --- KPI helpers ---
const utilizationTrendUp = computed(() => (data.value?.utilization?.utilization_rate || 0) >= 25)
const fleetHealthGood = computed(() => (data.value?.fleet_health?.fleet_health_score || 0) >= 70)
const activePercent = computed(() => {
  const t = data.value?.total_vehicles || 0
  const a = data.value?.active || 0
  return t ? Math.round((a / t) * 100) : 0
})

// --- Chart options ---
const palette = ['#6366f1', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4', '#ec4899', '#84cc16']

const statusChartOption = computed(() => {
  const items = data.value?.status_breakdown || []
  return {
    tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
    legend: { bottom: 0, textStyle: { fontSize: 11 } },
    color: palette,
    series: [{ type: 'pie', radius: ['40%', '70%'], avoidLabelOverlap: false, itemStyle: { borderRadius: 8, borderColor: '#fff', borderWidth: 2 }, label: { show: false }, emphasis: { label: { show: true, fontSize: 14, fontWeight: 'bold' } }, data: items.map((s: any) => ({ name: s.status, value: s.count })) }],
  }
})

const fuelChartOption = computed(() => {
  const items = data.value?.fuel_type_breakdown || []
  return {
    tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
    legend: { bottom: 0, textStyle: { fontSize: 11 } },
    color: ['#6366f1', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4', '#ec4899', '#84cc16', '#f97316', '#14b8a6', '#a855f7', '#3b82f6'],
    series: [{ type: 'pie', radius: ['40%', '70%'], itemStyle: { borderRadius: 8, borderColor: '#fff', borderWidth: 2 }, label: { show: false }, data: items.map((f: any) => ({ name: f.fuel_type, value: f.count })) }],
  }
})

const vehicleTypeChartOption = computed(() => {
  const items = data.value?.vehicle_type_breakdown || []
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: items.map((v: any) => v.vehicle_type), axisLabel: { fontSize: 11 } },
    yAxis: { type: 'value' },
    color: palette,
    series: [{ type: 'bar', data: items.map((v: any) => v.count), itemStyle: { borderRadius: [6, 6, 0, 0], color: '#6366f1' }, barWidth: '40%' }],
  }
})

const ownershipChartOption = computed(() => {
  const items = data.value?.ownership_breakdown || []
  return {
    tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
    legend: { bottom: 0, textStyle: { fontSize: 11 } },
    color: palette,
    series: [{ type: 'pie', radius: ['35%', '65%'], itemStyle: { borderRadius: 8, borderColor: '#fff', borderWidth: 2 }, label: { show: false }, data: items.map((o: any) => ({ name: o.ownership, value: o.count })) }],
  }
})

const makeChartOption = computed(() => {
  const items = data.value?.top_makes || []
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: items.map((m: any) => m.make), axisLabel: { fontSize: 11, rotate: 30 } },
    yAxis: { type: 'value' },
    color: palette,
    series: [{ type: 'bar', data: items.map((m: any) => m.count), itemStyle: { borderRadius: [6, 6, 0, 0], color: '#818cf8' }, barWidth: '50%' }],
  }
})

const ageChartOption = computed(() => {
  const dist = data.value?.age_distribution || {}
  const labels = Object.keys(dist)
  const values: number[] = Object.values(dist) as number[]
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: labels, axisLabel: { fontSize: 11 } },
    yAxis: { type: 'value' },
    color: ['#6366f1'],
    series: [{ type: 'bar', data: values, itemStyle: { borderRadius: [6, 6, 0, 0], color: '#6366f1' }, barWidth: '40%' }],
  }
})

const acquisitionChartOption = computed(() => {
  const items = data.value?.acquisition_trend || []
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: items.map((a: any) => a.month), axisLabel: { fontSize: 11, rotate: 30 } },
    yAxis: { type: 'value' },
    color: ['#10b981'],
    series: [{ type: 'line', data: items.map((a: any) => a.count), smooth: true, areaStyle: { opacity: 0.15 }, lineStyle: { width: 3 }, symbolSize: 8 }],
  }
})

const mileageByStatusOption = computed(() => {
  const items = data.value?.status_breakdown || []
  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: items.map((s: any) => s.status), axisLabel: { fontSize: 11 } },
    yAxis: { type: 'value' },
    color: palette,
    series: [{ type: 'bar', data: items.map((s: any) => s.count), itemStyle: { borderRadius: [6, 6, 0, 0], color: '#6366f1' }, barWidth: '30%' }],
  }
})

const mileageByTypeOption = computed(() => {
  const vtypes = data.value?.vehicle_type_breakdown || []
  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: vtypes.map((v: any) => v.vehicle_type || '—'), axisLabel: { fontSize: 11 } },
    yAxis: { type: 'value' },
    color: ['#f59e0b'],
    series: [{ type: 'bar', data: vtypes.map((v: any) => v.count), itemStyle: { borderRadius: [6, 6, 0, 0], color: '#f59e0b' }, barWidth: '40%' }],
  }
})

const valueByMakeOption = computed(() => {
  const makes = data.value?.top_makes || []
  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: makes.map((m: any) => m.make || '—'), axisLabel: { fontSize: 11, rotate: 30 } },
    yAxis: { type: 'value' },
    color: ['#10b981'],
    series: [{ type: 'bar', data: makes.map((m: any) => m.count), itemStyle: { borderRadius: [6, 6, 0, 0], color: '#10b981' }, barWidth: '40%' }],
  }
})

// --- Utilization Charts ---
const revenueTrendChartOption = computed(() => {
  const items = data.value?.utilization?.revenue_monthly || []
  return {
    tooltip: { trigger: 'axis', formatter: (p: any) => {
      const r = items[p[0].dataIndex]
      return `${r?.month || ''}<br/>Revenue: ${currencySymbol.value}${Number(p[0].value).toLocaleString()}<br/>Rentals: ${r?.count || 0}`
    }},
    grid: { left: 60, right: 20, top: 20, bottom: 30 },
    xAxis: { type: 'category', data: items.map((r: any) => r.month), axisLabel: { fontSize: 11, rotate: 30 } },
    yAxis: { type: 'value', axisLabel: { formatter: (v: number) => `${(v / 1000).toFixed(0)}k` } },
    color: ['#6366f1'],
    series: [
      {
        name: 'Revenue',
        type: 'bar',
        data: items.map((r: any) => r.revenue),
        itemStyle: { borderRadius: [6, 6, 0, 0], color: '#6366f1' },
        barWidth: '40%',
      },
      {
        name: 'Rentals',
        type: 'line',
        data: items.map((r: any) => r.count),
        smooth: true,
        symbol: 'circle',
        symbolSize: 6,
        lineStyle: { width: 2, color: '#10b981' },
        itemStyle: { color: '#10b981' },
        yAxisIndex: 0,
      },
    ],
  }
})

const rentalGaugeOption = computed(() => {
  const rate = data.value?.utilization?.utilization_rate || 0
  return {
    series: [{
      type: 'gauge',
      startAngle: 200,
      endAngle: -20,
      min: 0, max: 100,
      radius: '90%',
      splitNumber: 5,
      progress: { show: true, width: 14, roundCap: true, color: rate >= 50 ? '#10b981' : rate >= 25 ? '#f59e0b' : '#ef4444' },
      axisLine: { lineStyle: { width: 14, color: [[1, 'rgba(100,116,139,0.12)']] } },
      pointer: { length: '60%', width: 4, itemStyle: { color: rate >= 50 ? '#10b981' : rate >= 25 ? '#f59e0b' : '#ef4444' } },
      axisTick: { show: false },
      splitLine: { show: true, distance: -4, lineStyle: { width: 2, color: '#94a3b8' } },
      axisLabel: { color: '#94a3b8', fontSize: 11, distance: 10 },
      detail: {
        valueAnimation: true,
        formatter: '{value}%',
        fontSize: 28,
        fontWeight: 'bold',
        color: '#334155',
        offsetCenter: [0, '70%'],
      },
      title: { show: true, offsetCenter: [0, '95%'], fontSize: 12, color: '#94a3b8' },
      data: [{ value: rate, name: 'Utilized' }],
    }],
  }
})

const revenueByTypeOption = computed(() => {
  const items = data.value?.utilization?.revenue_by_type || []
  return {
    tooltip: { trigger: 'axis', formatter: (p: any) => `${p[0].name}<br/>Revenue: ${currencySymbol.value}${Number(p[0].value).toLocaleString()}` },
    grid: { left: 60, right: 20, top: 20, bottom: 30 },
    xAxis: { type: 'category', data: items.map((r: any) => r.vehicle_type || '—'), axisLabel: { fontSize: 11 } },
    yAxis: { type: 'value', axisLabel: { formatter: (v: number) => `${(v / 1000).toFixed(0)}k` } },
    color: ['#8b5cf6'],
    series: [{ type: 'bar', data: items.map((r: any) => r.revenue), itemStyle: { borderRadius: [6, 6, 0, 0], color: '#8b5cf6' }, barWidth: '40%' }],
  }
})

// --- Cost & Depreciation Charts ---
const serviceCostByTypeOption = computed(() => {
  const items = data.value?.cost_analysis?.service_by_type || []
  const labels = items.map((s: any) => {
    const map: Record<string, string> = {
      oil_change: 'Oil Change', tire_rotation: 'Tire Rotation', brake_service: 'Brake',
      inspection: 'Inspection', repair: 'Repair', preventive: 'Preventive', other: 'Other',
    }
    return map[s.service_type] || s.service_type
  })
  return {
    tooltip: { trigger: 'axis', formatter: (p: any) => `${p[0].name}<br/>Cost: ${currencySymbol.value}${Number(p[0].value).toLocaleString()}<br/>Count: ${items[p[0].dataIndex]?.count || 0}` },
    grid: { left: 60, right: 20, top: 20, bottom: 30 },
    xAxis: { type: 'category', data: labels, axisLabel: { fontSize: 11, rotate: 30 } },
    yAxis: { type: 'value', axisLabel: { formatter: (v: number) => `${(v / 1000).toFixed(0)}k` } },
    color: ['#ef4444', '#f59e0b', '#f97316', '#8b5cf6', '#3b82f6', '#10b981', '#94a3b8'],
    series: [{ type: 'bar', data: items.map((s: any) => s.cost), itemStyle: { borderRadius: [6, 6, 0, 0] }, barWidth: '40%' }],
  }
})

const depreciationChartOption = computed(() => {
  const items = data.value?.cost_analysis?.vehicles || []
  const labels = items.map((v: any) => `${(v.make || '')} ${(v.model || '')}`.trim().slice(0, 12))
  return {
    tooltip: { trigger: 'axis', formatter: (p: any) => {
      const v = items[p[0].dataIndex]
      return `${v.make} ${v.model}<br/>Depreciation: ${v.depreciation_pct}%<br/>Book Value: ${currencySymbol.value}${Number(v.book_value).toLocaleString()}`
    }},
    legend: { data: ['Book Value', 'Depreciated'], top: 0, textStyle: { fontSize: 11 } },
    grid: { left: 60, right: 20, top: 30, bottom: 50 },
    xAxis: { type: 'category', data: labels, axisLabel: { fontSize: 10, rotate: 35, interval: 0 } },
    yAxis: { type: 'value', axisLabel: { formatter: (v: number) => `${(v / 1000).toFixed(0)}k` } },
    color: ['#10b981', '#ef4444'],
    series: [
      { name: 'Book Value', type: 'bar', stack: 'cost', data: items.map((v: any) => v.book_value), itemStyle: { borderRadius: [0, 0, 4, 4] } },
      { name: 'Depreciated', type: 'bar', stack: 'cost', data: items.map((v: any) => v.purchase_price - v.book_value), itemStyle: { borderRadius: [4, 4, 0, 0], color: '#ef4444' } },
    ],
  }
})

const depreciationHeaders = [
  { title: 'Vehicle', key: 'vehicle', sortable: false },
  { title: 'Age (Yrs)', key: 'age_years', sortable: true, width: 90 },
  { title: 'Purchase Price', key: 'purchase_price', sortable: true, align: 'end' as const, width: 130 },
  { title: 'Book Value', key: 'book_value', sortable: true, align: 'end' as const, width: 130 },
  { title: 'Annual Dep.', key: 'annual_depreciation', sortable: true, align: 'end' as const, width: 120 },
  { title: 'Dep. %', key: 'depreciation_pct', sortable: true, width: 160 },
]

// --- Fleet Health Charts ---
const inspectionStatusOption = computed(() => {
  const passCount = data.value?.fleet_health?.pass_count || 0
  const failCount = data.value?.fleet_health?.fail_count || 0
  const draft = (data.value?.fleet_health?.total_inspections || 0) - passCount - failCount
  return {
    tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
    legend: { bottom: 0, textStyle: { fontSize: 11 } },
    color: ['#10b981', '#ef4444', '#94a3b8'],
    series: [{
      type: 'pie',
      radius: ['45%', '70%'],
      itemStyle: { borderRadius: 8, borderColor: '#fff', borderWidth: 2 },
      label: { show: true, formatter: '{b}\n{c}', fontSize: 11 },
      data: [
        { name: 'Passed', value: passCount },
        { name: 'Failed', value: failCount },
        { name: 'Other', value: draft > 0 ? draft : 0 },
      ],
    }],
  }
})

const fleetStatusRadialOption = computed(() => {
  const items = data.value?.status_breakdown || []
  const labels = items.map((s: any) => {
    const map: Record<string, string> = { active: 'Active', in_maintenance: 'Maintenance', out_of_service: 'Out of Service', retired: 'Retired' }
    return map[s.status] || s.status
  })
  const colorMap: Record<string, string> = { active: '#10b981', in_maintenance: '#f59e0b', out_of_service: '#ef4444', retired: '#64748b' }
  return {
    tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
    legend: { bottom: 0, textStyle: { fontSize: 11 } },
    color: items.map((s: any) => colorMap[s.status] || '#6366f1'),
    series: [{
      type: 'pie',
      radius: ['38%', '68%'],
      itemStyle: { borderRadius: 8, borderColor: '#fff', borderWidth: 2 },
      label: { show: true, formatter: '{b}\n{d}%', fontSize: 11 },
      data: items.map((s: any) => ({ name: labels[items.indexOf(s)], value: s.count })),
    }],
  }
})

// --- Export ---
function exportCsv() {
  const rows: string[][] = []
  rows.push(['Vehicle Analytics Export'])
  rows.push([])
  // Fleet summary
  rows.push(['Metric', 'Value'])
  rows.push(['Total Vehicles', String(data.value?.total_vehicles || 0)])
  rows.push(['Active', String(data.value?.active || 0)])
  rows.push(['In Maintenance', String(data.value?.in_maintenance || 0)])
  rows.push(['Out of Service', String(data.value?.out_of_service || 0)])
  rows.push(['Utilization Rate', `${data.value?.utilization?.utilization_rate || 0}%`])
  rows.push(['Total Revenue', `${currencySymbol.value}${data.value?.utilization?.total_revenue || 0}`])
  rows.push(['Fleet Health Score', String(data.value?.fleet_health?.fleet_health_score || 0)])
  rows.push(['Total Service Cost', `${currencySymbol.value}${data.value?.cost_analysis?.total_service_cost || 0}`])
  rows.push(['Total Depreciation', `${currencySymbol.value}${data.value?.cost_analysis?.total_depreciation_loss || 0}`])
  rows.push([])
  // ABC vehicles
  rows.push(['ABC Analysis - Vehicle Ranking'])
  rows.push(['Rank', 'Vehicle', 'Class', 'Revenue', '% Share', 'Cumulative %', 'Rentals'])
  for (const v of (abcData.value as any).vehicles || []) {
    rows.push([
      String((abcData.value as any).vehicles.indexOf(v) + 1),
      `${v.make} ${v.model} (${v.year || '—'})`,
      v.abc_class,
      `${currencySymbol.value}${v.total_rev}`,
      `${v.revenue_pct}%`,
      `${v.cumulative_pct}%`,
      String(v.rental_count),
    ])
  }
  rows.push([])
  // Depreciation
  rows.push(['Depreciation Detail'])
  rows.push(['Vehicle', 'Year', 'Purchase Price', 'Book Value', 'Annual Dep.', 'Dep. %', 'Age (Yrs)'])
  for (const v of data.value?.cost_analysis?.vehicles || []) {
    rows.push([
      `${v.make} ${v.model}`,
      String(v.year || ''),
      `${currencySymbol.value}${v.purchase_price}`,
      `${currencySymbol.value}${v.book_value}`,
      `${currencySymbol.value}${v.annual_depreciation}`,
      `${v.depreciation_pct}%`,
      String(v.age_years),
    ])
  }
  const csv = rows.map(r => r.map(c => `"${c}"`).join(',')).join('\n')
  const blob = new Blob([csv], { type: 'text/csv' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `vehicle-analytics-${new Date().toISOString().slice(0, 10)}.csv`
  a.click()
  URL.revokeObjectURL(url)
}

// --- ABC Analysis ---
// ABC-specific date filter state (separate from top-level period which filters by purchase date)
type AbcPreset = 'this_week' | 'last_week' | 'this_month' | 'last_month' | 'this_year' | 'last_year' | 'custom'
const abcPeriod = ref<AbcPreset>('this_year')
const abcCustomFrom = ref('')
const abcCustomTo = ref('')
const abcPending = ref(false)

const abcPresetOptions = [
  { label: 'This Week', value: 'this_week' as AbcPreset },
  { label: 'Last Week', value: 'last_week' as AbcPreset },
  { label: 'This Month', value: 'this_month' as AbcPreset },
  { label: 'Last Month', value: 'last_month' as AbcPreset },
  { label: 'This Year', value: 'this_year' as AbcPreset },
  { label: 'Last Year', value: 'last_year' as AbcPreset },
  { label: 'Custom', value: 'custom' as AbcPreset },
]

function fmtDate(d: Date): string {
  // Use local date (not UTC) to avoid timezone offset issues
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const dd = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${dd}`
}

const abcDateRange = computed(() => {
  const now = new Date()
  let start = ''
  let end = ''
  switch (abcPeriod.value) {
    case 'this_week': {
      const day = now.getDay() || 7
      start = fmtDate(new Date(now.getFullYear(), now.getMonth(), now.getDate() - day + 1))
      end = fmtDate(now)
      break
    }
    case 'last_week': {
      const day = now.getDay() || 7
      const thisMon = new Date(now.getFullYear(), now.getMonth(), now.getDate() - day + 1)
      const lastMon = new Date(thisMon)
      lastMon.setDate(lastMon.getDate() - 7)
      const lastSun = new Date(thisMon)
      lastSun.setDate(lastSun.getDate() - 1)
      start = fmtDate(lastMon)
      end = fmtDate(lastSun)
      break
    }
    case 'this_month': {
      start = fmtDate(new Date(now.getFullYear(), now.getMonth(), 1))
      end = fmtDate(now)
      break
    }
    case 'last_month': {
      start = fmtDate(new Date(now.getFullYear(), now.getMonth() - 1, 1))
      end = fmtDate(new Date(now.getFullYear(), now.getMonth(), 0))
      break
    }
    case 'this_year': {
      start = fmtDate(new Date(now.getFullYear(), 0, 1))
      end = fmtDate(now)
      break
    }
    case 'last_year': {
      start = fmtDate(new Date(now.getFullYear() - 1, 0, 1))
      end = fmtDate(new Date(now.getFullYear() - 1, 11, 31))
      break
    }
    case 'custom': {
      start = abcCustomFrom.value
      end = abcCustomTo.value
      break
    }
  }
  return { start, end }
})

const abcPeriodLabel = computed(() => {
  const { start, end } = abcDateRange.value
  if (!start || !end) return ''
  const fmt = (d: string) => {
    const dt = new Date(d)
    return dt.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
  }
  return `${fmt(start)} \u2014 ${fmt(end)}`
})

function applyAbcPreset(p: AbcPreset) {
  abcPeriod.value = p
  if (p !== 'custom') refreshAbc()
}

function onAbcCustomDateChange() {
  if (abcPeriod.value !== 'custom') return
  if (abcCustomFrom.value && abcCustomTo.value) {
    if (new Date(abcCustomFrom.value) > new Date(abcCustomTo.value)) return
    refreshAbc()
  }
}

async function refreshAbc() {
  abcPending.value = true
  try {
    const { start, end } = abcDateRange.value
    const params: Record<string, string> = {}
    if (start) params['abc_start'] = start + 'T00:00:00'
    if (end) params['abc_end'] = end + 'T23:59:59'
    const res = await $api('/vehicles/vehicles/analytics/', { query: { ...periodQuery(), ...params } }).catch(() => null)
    abcRawData.value = res
  } finally {
    abcPending.value = false
  }
}

const abcRawData = ref<any>(null)

const abcData = computed(() => {
  // Prefer ABC-specific fetch; fall back to main data
  const source = abcRawData.value ?? data.value
  return source?.abc_analysis || { summary: {}, vehicles: [] as any[], no_revenue_count: 0 }
})
const abcSummary = computed(() => (abcData.value as any).summary || {})

const abcHeaders = [
  { title: 'Rank', key: 'rank', sortable: false, width: 60 },
  { title: 'Vehicle', key: 'vehicle', sortable: false },
  { title: 'Class', key: 'abc_class', sortable: false, width: 90 },
  { title: 'Revenue', key: 'total_rev', sortable: false, align: 'end' as const },
  { title: '% Share', key: 'revenue_pct', sortable: false, width: 160 },
  { title: 'Cumulative %', key: 'cumulative_pct', sortable: false, width: 180 },
  { title: 'Rentals', key: 'rental_count', sortable: false, width: 100 },
]

function abcClassColor(cls: string): string {
  return ({ A: '#10b981', B: '#3b82f6', C: '#f59e0b' } as Record<string, string>)[cls] || '#94a3b8'
}

function abcRankClass(index: number): string {
  if (index < 3) return 'text-primary'
  return 'text-medium-emphasis'
}

// Pareto Chart: bars (revenue) + line (cumulative %)
const paretoChartOption = computed(() => {
  const vehicles = (abcData.value as any).vehicles || []
  const labels = vehicles.map((v: any) => {
    const name = `${v.make || ''} ${v.model || ''}`.trim() || (v.vin && v.vin.length >= 6 ? v.vin.slice(-6) : '—')
    const plate = v.license_plate ? ` (${v.license_plate})` : ''
    return name.length > 18 ? name.slice(0, 16) + '…' + plate : name + plate
  })
  return {
    tooltip: {
      trigger: 'axis',
      axisPointer: { type: 'cross' },
      formatter: (params: any) => {
        const v = vehicles[params[0].dataIndex]
        if (!v) return ''
        return `<b>${v.make} ${v.model}</b><br/>` +
          `Revenue: ${currencySymbol.value}${Number(v.total_rev).toLocaleString()}<br/>` +
          `Share: ${v.revenue_pct}%<br/>` +
          `Cumulative: ${v.cumulative_pct}%<br/>` +
          `Class: ${v.abc_class}`
      },
    },
    legend: { data: ['Revenue', 'Cumulative %'], top: 0, textStyle: { fontSize: 11 } },
    grid: { left: 60, right: 60, top: 35, bottom: 60 },
    xAxis: {
      type: 'category',
      data: labels,
      axisLabel: { fontSize: 10, rotate: 35, interval: 0, width: 100, overflow: 'truncate', ellipsis: '…' },
    },
    yAxis: [
      {
        type: 'value',
        name: 'Revenue',
        position: 'left',
        axisLabel: { formatter: (v: number) => `${(v / 1000).toFixed(0)}k` },
      },
      {
        type: 'value',
        name: 'Cumulative %',
        position: 'right',
        min: 0,
        max: 100,
        axisLabel: { formatter: '{value}%' },
      },
    ],
    series: [
      {
        name: 'Revenue',
        type: 'bar',
        data: vehicles.map((v: any) => ({
          value: v.total_rev,
          itemStyle: { color: abcClassColor(v.abc_class), borderRadius: [6, 6, 0, 0] },
        })),
        barWidth: '50%',
      },
      {
        name: 'Cumulative %',
        type: 'line',
        yAxisIndex: 1,
        data: vehicles.map((v: any) => v.cumulative_pct),
        smooth: false,
        symbol: 'circle',
        symbolSize: 6,
        lineStyle: { width: 2.5, color: '#ef4444' },
        itemStyle: { color: '#ef4444' },
        markLine: {
          symbol: 'none',
          data: [
            { yAxis: 80, lineStyle: { color: '#10b981', type: 'dashed', width: 1.5 }, label: { formatter: '80% (A)', position: 'end', fontSize: 10, color: '#10b981' } },
            { yAxis: 95, lineStyle: { color: '#3b82f6', type: 'dashed', width: 1.5 }, label: { formatter: '95% (A+B)', position: 'end', fontSize: 10, color: '#3b82f6' } },
          ],
        },
      },
    ],
  }
})

// ABC Pie: revenue share by class
const abcPieOption = computed(() => {
  const s = abcSummary.value as any
  return {
    tooltip: {
      trigger: 'item',
      formatter: (p: any) => {
        const cls = p.name
        const rev = cls === 'A' ? s.A?.revenue : cls === 'B' ? s.B?.revenue : s.C?.revenue
        return `<b>Class ${cls}</b><br/>Revenue: ${currencySymbol.value}${Number(rev || 0).toLocaleString()}<br/>Vehicles: ${p.value}`
      },
    },
    legend: { bottom: 0, textStyle: { fontSize: 11 } },
    color: ['#10b981', '#3b82f6', '#f59e0b'],
    series: [{
      type: 'pie',
      radius: ['45%', '70%'],
      itemStyle: { borderRadius: 8, borderColor: '#fff', borderWidth: 2 },
      label: { show: true, formatter: 'Class {b}\n{d}%', fontSize: 11 },
      data: [
        { name: 'A', value: s.A?.count || 0 },
        { name: 'B', value: s.B?.count || 0 },
        { name: 'C', value: s.C?.count || 0 },
      ],
    }],
  }
})

// --- Status card data ---
const statusList = computed(() => {
  const items = data.value?.status_breakdown || []
  const map: Record<string, { color: string; icon: string; label: string }> = {
    active: { color: '#10b981', icon: 'mdi-check-circle', label: 'Active' },
    in_maintenance: { color: '#f59e0b', icon: 'mdi-wrench', label: 'In Maintenance' },
    out_of_service: { color: '#ef4444', icon: 'mdi-car-off', label: 'Out of Service' },
    retired: { color: '#64748b', icon: 'mdi-archive', label: 'Retired' },
  }
  return items.map((s: any) => ({
    status: s.status,
    count: s.count,
    color: map[s.status]?.color || '#6366f1',
    icon: map[s.status]?.icon || 'mdi-circle',
    label: map[s.status]?.label || s.status,
  }))
})

// Fetch ABC data on mount (default: this year)
onMounted(() => {
  refreshAbc()
})
</script>

<style scoped>
.va-header-icon {
  width: 48px;
  height: 48px;
  background: linear-gradient(135deg, #6366f1, #4f46e5);
}
.va-kpi-card {
  transition: transform 0.15s ease, box-shadow 0.15s ease;
  position: relative;
  overflow: hidden;
}
.va-kpi-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 24px rgba(99, 102, 241, 0.15);
}
.va-kpi-indigo { background: linear-gradient(135deg, #6366f1 0%, #818cf8 100%) !important; }
.va-kpi-green { background: linear-gradient(135deg, #10b981 0%, #34d399 100%) !important; }
.va-kpi-amber { background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%) !important; }
.va-kpi-blue { background: linear-gradient(135deg, #3b82f6 0%, #60a5fa 100%) !important; }
.va-kpi-purple { background: linear-gradient(135deg, #8b5cf6 0%, #a78bfa 100%) !important; }
.va-kpi-red { background: linear-gradient(135deg, #ef4444 0%, #f87171 100%) !important; }

.va-insight-bar {
  background: rgba(var(--v-theme-primary), 0.04);
  border-left: 3px solid rgb(var(--v-theme-primary));
}
.va-mini-stat {
  transition: transform 0.15s ease;
}
.va-mini-stat:hover {
  transform: translateY(-2px);
}
.va-info-card {
  transition: box-shadow 0.15s ease;
}
.va-info-card:hover {
  box-shadow: 0 4px 14px rgba(15, 23, 42, 0.06);
}
.va-status-row {
  transition: background 0.15s ease;
}
.va-rank-row:hover {
  background: rgba(var(--v-theme-primary), 0.04);
}
.va-health-score-card {
  transition: box-shadow 0.15s ease;
}
.va-health-score-card:hover {
  box-shadow: 0 4px 14px rgba(15, 23, 42, 0.06);
}

/* ABC Analysis Cards */
.abc-class-card {
  transition: transform 0.15s ease, box-shadow 0.15s ease;
  position: relative;
  overflow: hidden;
}
.abc-class-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 12px 28px rgba(15, 23, 42, 0.12);
}
.abc-class-a-card { background: linear-gradient(135deg, #10b981 0%, #059669 100%); }
.abc-class-b-card { background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%); }
.abc-class-c-card { background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); }
.abc-total-card { background: linear-gradient(135deg, #6366f1 0%, #4f46e5 100%); }

.abc-class-badge {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 22px;
  font-weight: 800;
  color: white;
  background: rgba(255, 255, 255, 0.2);
  backdrop-filter: blur(8px);
}

.abc-strategy-card {
  border-left: 4px solid;
  transition: box-shadow 0.15s ease;
}
.abc-strategy-card:hover {
  box-shadow: 0 4px 14px rgba(15, 23, 42, 0.06);
}
.abc-strategy-a { border-left-color: #10b981; }
.abc-strategy-b { border-left-color: #3b82f6; }
.abc-strategy-c { border-left-color: #f59e0b; }
</style>
