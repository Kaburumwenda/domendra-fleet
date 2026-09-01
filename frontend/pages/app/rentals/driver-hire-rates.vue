<template>
  <div class="d-flex flex-column ga-4 driver-hire-page">
    <!-- Header -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-2">
      <div class="d-flex align-center ga-3">
        <div class="d-flex align-center justify-center rounded-xl dhr-header-icon">
          <v-icon color="white" size="26">mdi-account-cash-outline</v-icon>
        </div>
        <div>
          <h1 class="text-h5 font-weight-bold dhr-title">Driver Hire Rates</h1>
          <p class="text-caption text-medium-emphasis">Global driver pricing plans — hourly, daily, weekly, monthly &amp; weekend rates with discounts, markups &amp; cost calculator</p>
        </div>
      </div>
      <div class="d-flex align-center ga-2 flex-wrap">
        <v-btn variant="tonal" prepend-icon="mdi-refresh" size="small" @click="loadAll" :loading="pending">
          <span class="hidden-sm-and-down">Refresh</span>
        </v-btn>
        <v-btn variant="tonal" prepend-icon="mdi-calculator-variant" size="small" color="info" @click="openGlobalCalculator">
          <span class="hidden-sm-and-down">Calculator</span>
        </v-btn>
        <v-btn v-can="'rentals:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="openCreate">New Rate Plan</v-btn>
      </div>
    </div>

    <!-- KPI cards -->
    <v-row dense>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100 dhr-kpi-card dhr-kpi-indigo">
          <div class="d-flex align-center justify-space-between mb-2">
            <v-avatar color="rgba(255,255,255,0.2)" size="36" rounded="lg" variant="flat"><v-icon color="white" size="small">mdi-format-list-bulleted</v-icon></v-avatar>
            <v-chip size="x-small" variant="flat" color="rgba(255,255,255,0.25)" text-color="white">{{ activePlans }} active</v-chip>
          </div>
          <p class="text-h4 font-weight-bold dhr-kpi-value">{{ totalPlans }}</p>
          <p class="dhr-kpi-label">Total Plans</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100 dhr-kpi-card dhr-kpi-green">
          <div class="d-flex align-center justify-space-between mb-2">
            <v-avatar color="rgba(255,255,255,0.2)" size="36" rounded="lg" variant="flat"><v-icon color="white" size="small">mdi-cash-multiple</v-icon></v-avatar>
            <v-chip size="x-small" variant="flat" color="rgba(255,255,255,0.25)" text-color="white">avg</v-chip>
          </div>
          <p class="text-h4 font-weight-bold dhr-kpi-value">{{ currencySymbol }}{{ avgDailyRate }}</p>
          <p class="dhr-kpi-label">Avg Daily Rate</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100 dhr-kpi-card dhr-kpi-amber">
          <div class="d-flex align-center justify-space-between mb-2">
            <v-avatar color="rgba(255,255,255,0.2)" size="36" rounded="lg" variant="flat"><v-icon color="white" size="small">mdi-clock-outline</v-icon></v-avatar>
            <v-chip size="x-small" variant="flat" color="rgba(255,255,255,0.25)" text-color="white">avg</v-chip>
          </div>
          <p class="text-h4 font-weight-bold dhr-kpi-value">{{ currencySymbol }}{{ avgHourlyRate }}</p>
          <p class="dhr-kpi-label">Avg Hourly Rate</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100 dhr-kpi-card dhr-kpi-red">
          <div class="d-flex align-center justify-space-between mb-2">
            <v-avatar color="rgba(255,255,255,0.2)" size="36" rounded="lg" variant="flat"><v-icon color="white" size="small">mdi-account-tie</v-icon></v-avatar>
            <v-chip size="x-small" variant="flat" color="rgba(255,255,255,0.25)" text-color="white">{{ plansWithoutDriver }} unassigned</v-chip>
          </div>
          <p class="text-h4 font-weight-bold dhr-kpi-value">{{ driversWithPlans }}</p>
          <p class="dhr-kpi-label">Drivers with Plans</p>
        </v-card>
      </v-col>
    </v-row>

    <!-- Tabs -->
    <v-card elevation="0" border rounded="lg">
      <v-tabs v-model="tab" color="primary" density="compact">
        <v-tab value="plans" slider-color="primary"><v-icon size="small" class="mr-2">mdi-format-list-bulleted</v-icon> Rate Plans</v-tab>
        <v-tab value="drivers" slider-color="primary"><v-icon size="small" class="mr-2">mdi-account-group</v-icon> Drivers</v-tab>
        <v-tab value="rates" slider-color="primary"><v-icon size="small" class="mr-2">mdi-chart-bar</v-icon> Rate Comparison</v-tab>
        <v-tab value="analytics" slider-color="primary"><v-icon size="small" class="mr-2">mdi-chart-donut</v-icon> Analytics</v-tab>
      </v-tabs>
      <v-divider />

      <v-window v-model="tab">
        <!-- Rate Plans -->
        <v-window-item value="plans" class="pa-4">
          <div class="d-flex align-center flex-wrap ga-2 mb-4">
            <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Search plans…" density="compact" variant="outlined" hide-details clearable style="max-width: 280px; flex: 1 1 280px;" />
            <v-select v-model="filterStatus" :items="statusOpts" item-title="label" item-value="value" label="Status" density="compact" variant="outlined" hide-details clearable style="max-width: 160px;" />
            <v-select v-model="filterPeriod" :items="periodOpts" item-title="label" item-value="value" label="Period" density="compact" variant="outlined" hide-details clearable style="max-width: 160px;" />
            <v-spacer />
            <v-btn-toggle v-model="viewMode" mandatory density="compact" variant="outlined" color="primary">
              <v-btn value="grid" size="small" prepend-icon="mdi-view-grid">Grid</v-btn>
              <v-btn value="table" size="small" prepend-icon="mdi-table">Table</v-btn>
            </v-btn-toggle>
          </div>

          <div v-if="pending" class="d-flex justify-center align-center py-12">
            <v-progress-circular indeterminate size="48" color="primary" />
          </div>
          <div v-else-if="!filteredPlans.length" class="text-center py-12 text-medium-emphasis">
            <v-icon size="48" class="mb-3">mdi-account-cash-outline</v-icon>
            <p>No driver hire rate plans found. Click <strong>New Rate Plan</strong> to create one.</p>
          </div>

          <v-row v-else-if="viewMode === 'grid'" dense>
            <v-col v-for="plan in filteredPlans" :key="plan.id" cols="12" sm="6" md="4">
              <v-card elevation="0" border rounded="xl" class="h-100 dhr-plan-card" :class="plan.is_currently_active ? 'dhr-plan-active' : ''" @click="openView(plan)">
                <div class="dhr-plan-header">
                  <div class="d-flex align-center justify-space-between">
                    <v-avatar color="rgba(99,102,241,0.12)" size="40" rounded="lg" variant="flat">
                      <v-icon color="primary" size="20">{{ plan.driver ? 'mdi-account-tie' : 'mdi-account-multiple' }}</v-icon>
                    </v-avatar>
                    <v-chip size="x-small" :color="statusColor(plan.status)" variant="flat">
                      <v-icon size="12" start>mdi-circle-medium</v-icon>{{ statusLabel(plan.status) }}
                    </v-chip>
                  </div>
                  <h3 class="text-subtitle-1 font-weight-bold mt-2 dhr-plan-name">{{ plan.name || plan.driver_name || 'Default Rate' }}</h3>
                  <p class="text-caption text-medium-emphasis">{{ plan.driver ? 'Driver: ' + plan.driver_name : 'Applies to any driver' }}</p>
                </div>
                <v-card-text class="pa-4">
                  <div class="d-flex flex-wrap ga-1 mb-3">
                    <v-chip v-if="Number(plan.hourly_rate) > 0" size="x-small" variant="tonal" color="amber-darken-1">Hr: {{ currencySymbol }}{{ Number(plan.hourly_rate).toLocaleString() }}</v-chip>
                    <v-chip v-if="Number(plan.daily_rate) > 0" size="x-small" variant="tonal" color="primary">Day: {{ currencySymbol }}{{ Number(plan.daily_rate).toLocaleString() }}</v-chip>
                    <v-chip v-if="Number(plan.weekly_rate) > 0" size="x-small" variant="tonal" color="teal">Wk: {{ currencySymbol }}{{ Number(plan.weekly_rate).toLocaleString() }}</v-chip>
                    <v-chip v-if="Number(plan.monthly_rate) > 0" size="x-small" variant="tonal" color="indigo">Mo: {{ currencySymbol }}{{ Number(plan.monthly_rate).toLocaleString() }}</v-chip>
                    <v-chip v-if="Number(plan.weekend_rate) > 0" size="x-small" variant="tonal" color="pink">Wend: {{ currencySymbol }}{{ Number(plan.weekend_rate).toLocaleString() }}</v-chip>
                  </div>
                  <div class="dhr-eff-box">
                    <div class="d-flex align-center ga-1">
                      <v-icon size="14" color="success">mdi-check-circle</v-icon>
                      <span class="text-caption text-medium-emphasis">Effective {{ plan.default_rate_period }}</span>
                    </div>
                    <span class="text-subtitle-1 font-weight-bold text-success">{{ currencySymbol }}{{ Number(getEffectiveRate(plan)).toLocaleString() }}</span>
                  </div>
                  <div class="d-flex flex-wrap ga-1 mt-3">
                    <v-chip v-if="Number(maxDiscount(plan)) > 0" size="x-small" variant="flat" color="success"><v-icon size="10" start>mdi-tag</v-icon>-{{ maxDiscount(plan) }}% off</v-chip>
                    <v-chip v-if="Number(maxMarkup(plan)) > 0" size="x-small" variant="flat" color="warning"><v-icon size="10" start>mdi-arrow-up</v-icon>+{{ maxMarkup(plan) }}% markup</v-chip>
                    <v-chip v-if="Number(plan.security_deposit) > 0" size="x-small" variant="flat" color="info"><v-icon size="10" start>mdi-shield</v-icon>Dep: {{ currencySymbol }}{{ Number(plan.security_deposit).toLocaleString() }}</v-chip>
                    <v-chip v-if="plan.is_default" size="x-small" variant="flat" color="primary"><v-icon size="10" start>mdi-star</v-icon>Default</v-chip>
                  </div>
                  <div class="text-caption text-medium-emphasis mt-2">
                    <v-icon size="x-small">mdi-calendar</v-icon>
                    {{ plan.valid_from || '—' }} → {{ plan.valid_to || '∞' }}
                  </div>
                </v-card-text>
                <v-divider />
                <v-card-actions class="pa-2">
                  <v-btn variant="text" size="small" color="primary" prepend-icon="mdi-calculator-variant" @click.stop="openCalculator(plan)">Calculate</v-btn>
                  <v-spacer />
                  <v-btn v-can="'rentals:update'" icon="mdi-pencil-outline" variant="text" size="x-small" color="primary" @click.stop="openEdit(plan)" />
                  <v-btn v-can="'rentals:delete'" icon="mdi-trash-can-outline" variant="text" size="x-small" color="error" @click.stop="remove(plan)" />
                </v-card-actions>
              </v-card>
            </v-col>
          </v-row>

          <v-data-table v-else :headers="tableHeaders" :items="filteredPlans" :loading="pending" hover items-per-page="15">
            <template #item.name="{ item }">
              <div class="d-flex align-center ga-2">
                <v-avatar size="32" color="rgba(99,102,241,0.12)" rounded="lg" variant="flat">
                  <v-icon size="16" color="primary">{{ item.driver ? 'mdi-account-tie' : 'mdi-account-multiple' }}</v-icon>
                </v-avatar>
                <div>
                  <p class="text-body-2 font-weight-medium">{{ item.name || item.driver_name || 'Default Rate' }}</p>
                  <p class="text-caption text-medium-emphasis">{{ item.driver ? 'Driver: ' + item.driver_name : 'Any driver' }}</p>
                </div>
              </div>
            </template>
            <template #item.hourly_rate="{ value }"><span class="font-weight-medium">{{ currencySymbol }}{{ Number(value || 0).toLocaleString() }}</span></template>
            <template #item.daily_rate="{ value }"><span class="font-weight-medium">{{ currencySymbol }}{{ Number(value || 0).toLocaleString() }}</span></template>
            <template #item.weekly_rate="{ value }"><span class="font-weight-medium">{{ currencySymbol }}{{ Number(value || 0).toLocaleString() }}</span></template>
            <template #item.monthly_rate="{ value }"><span class="font-weight-medium">{{ currencySymbol }}{{ Number(value || 0).toLocaleString() }}</span></template>
            <template #item.effective="{ item }">
              <v-chip size="small" variant="flat" color="success">{{ currencySymbol }}{{ Number(getEffectiveRate(item)).toLocaleString() }}</v-chip>
            </template>
            <template #item.status="{ item }">
              <v-chip :color="statusColor(item.status)" variant="tonal" size="small">
                <v-icon size="x-small" start>{{ statusIcon(item.status) }}</v-icon>
                {{ statusLabel(item.status) }}
              </v-chip>
            </template>
            <template #item.actions="{ item }">
              <div class="d-flex ga-1">
                <v-btn icon="mdi-eye-outline" variant="text" size="small" color="info" @click="openView(item)" />
                <v-btn icon="mdi-calculator-variant-outline" variant="text" size="small" color="primary" @click="openCalculator(item)" />
                <v-btn v-can="'rentals:update'" icon="mdi-pencil-outline" variant="text" size="small" @click="openEdit(item)" />
                <v-btn v-can="'rentals:delete'" icon="mdi-trash-can-outline" variant="text" size="small" color="error" @click="remove(item)" />
              </div>
            </template>
          </v-data-table>
        </v-window-item>

        <!-- Drivers tab -->
        <v-window-item value="drivers" class="pa-4">
          <div v-if="!driverPlans.length" class="text-center py-12 text-medium-emphasis">
            <v-icon size="48" class="mb-3">mdi-account-group</v-icon>
            <p>No driver-specific plans yet. Assign a driver when creating a rate plan.</p>
          </div>
          <v-row v-else dense>
            <v-col v-for="d in driverPlans" :key="d.driver_id" cols="12" sm="6" md="4">
              <v-card elevation="0" border rounded="xl" class="pa-4 h-100 dhr-driver-card">
                <div class="d-flex align-center ga-3 mb-3">
                  <v-avatar size="48" color="rgba(99,102,241,0.12)" rounded="lg" variant="flat">
                    <v-icon color="primary">mdi-account-tie</v-icon>
                  </v-avatar>
                  <div>
                    <p class="text-subtitle-2 font-weight-bold">{{ d.driver_name }}</p>
                    <p class="text-caption text-medium-emphasis">{{ d.plans.length }} plan(s)</p>
                  </div>
                  <v-spacer />
                  <v-chip size="x-small" :color="d.active > 0 ? 'success' : 'grey'" variant="flat">{{ d.active }} active</v-chip>
                </div>
                <div class="d-flex flex-wrap ga-1">
                  <v-chip v-for="p in d.plans.slice(0, 4)" :key="p.id" size="x-small" variant="tonal" :color="statusColor(p.status)" @click="openView(p)">{{ p.name || 'Plan #' + p.id }}</v-chip>
                </div>
              </v-card>
            </v-col>
          </v-row>
        </v-window-item>

        <!-- Rate comparison -->
        <v-window-item value="rates" class="pa-4">
          <div v-if="!filteredPlans.length" class="text-center py-12 text-medium-emphasis">
            <v-icon size="48" class="mb-3">mdi-chart-bar</v-icon>
            <p>No plans to compare.</p>
          </div>
          <div v-else>
            <div class="d-flex align-center ga-2 mb-3 flex-wrap">
              <v-select v-model="comparePeriod" :items="periodOpts" item-title="label" item-value="value" label="Compare Period" density="compact" variant="outlined" hide-details style="max-width: 180px" />
              <v-select v-model="compareMetric" :items="[{label:'Base Rate', value:'base'}, {label:'Effective Rate', value:'effective'}]" item-title="label" item-value="value" label="Metric" density="compact" variant="outlined" hide-details style="max-width: 180px" />
            </div>
            <div ref="compareChartEl" style="height: 400px" />
          </div>
        </v-window-item>

        <!-- Analytics -->
        <v-window-item value="analytics" class="pa-4">
          <v-row dense v-if="plans.length">
            <v-col cols="12" md="6">
              <v-card elevation="0" border rounded="xl" class="pa-4 h-100">
                <div class="d-flex align-center ga-2 mb-3">
                  <v-icon color="primary" size="small">mdi-chart-donut</v-icon>
                  <h3 class="text-subtitle-2 font-weight-bold">Status Distribution</h3>
                </div>
                <div ref="statusChartEl" style="height: 280px" />
              </v-card>
            </v-col>
            <v-col cols="12" md="6">
              <v-card elevation="0" border rounded="xl" class="pa-4 h-100">
                <div class="d-flex align-center ga-2 mb-3">
                  <v-icon color="info" size="small">mdi-chart-pie</v-icon>
                  <h3 class="text-subtitle-2 font-weight-bold">Default Period Distribution</h3>
                </div>
                <div ref="periodChartEl" style="height: 280px" />
              </v-card>
            </v-col>
            <v-col cols="12">
              <v-card elevation="0" border rounded="xl" class="pa-4">
                <div class="d-flex align-center ga-2 mb-3">
                  <v-icon color="success" size="small">mdi-chart-bell-curve</v-icon>
                  <h3 class="text-subtitle-2 font-weight-bold">Average Base vs Effective Rates</h3>
                </div>
                <div ref="avgChartEl" style="height: 300px" />
              </v-card>
            </v-col>
          </v-row>
          <div v-else class="text-center py-12 text-medium-emphasis">
            <v-icon size="48" class="mb-3">mdi-chart-donut</v-icon>
            <p>No data for analytics.</p>
          </div>
        </v-window-item>
      </v-window>
    </v-card>

    <!-- ── View Plan Dialog ── -->
    <v-dialog v-model="viewDialog" max-width="700" scrollable>
      <v-card rounded="xl">
        <div class="dhr-view-hero">
          <div class="d-flex align-center justify-space-between pa-4">
            <div class="d-flex align-center ga-3">
              <v-avatar size="56" color="rgba(255,255,255,0.2)" rounded="lg" variant="flat">
                <v-icon color="white" size="28">mdi-account-cash</v-icon>
              </v-avatar>
              <div>
                <h2 class="text-h6 font-weight-bold text-white">{{ viewing?.name || viewing?.driver_name || 'Default Rate' }}</h2>
                <div class="d-flex align-center ga-2 mt-1">
                  <v-chip size="x-small" :color="viewing?.is_currently_active ? 'success' : 'grey'" variant="flat">{{ viewing?.is_currently_active ? 'Active' : 'Inactive' }}</v-chip>
                  <span class="text-caption text-white" style="opacity: 0.75">{{ viewing?.driver ? 'Driver: ' + viewing?.driver_name : 'Any driver' }}</span>
                </div>
              </div>
            </div>
            <v-btn icon="mdi-close" variant="text" color="white" size="small" @click="viewDialog = false" />
          </div>
        </div>
        <v-card-text class="pa-5" v-if="viewing">
          <v-row dense>
            <v-col cols="12" sm="6" md="4"><div class="dhr-info-item"><div class="dhr-info-label">Default Period</div><div class="dhr-info-value text-capitalize">{{ viewing.default_rate_period || '—' }}</div></div></v-col>
            <v-col cols="12" sm="6" md="4"><div class="dhr-info-item"><div class="dhr-info-label">Tax %</div><div class="dhr-info-value">{{ viewing.tax_percent || 0 }}%</div></div></v-col>
            <v-col cols="12" sm="6" md="4"><div class="dhr-info-item"><div class="dhr-info-label">Security Deposit</div><div class="dhr-info-value">{{ currencySymbol }}{{ Number(viewing.security_deposit || 0).toLocaleString() }}</div></div></v-col>
            <v-col cols="12" sm="6" md="4"><div class="dhr-info-item"><div class="dhr-info-label">Valid From</div><div class="dhr-info-value">{{ viewing.valid_from || '—' }}</div></div></v-col>
            <v-col cols="12" sm="6" md="4"><div class="dhr-info-item"><div class="dhr-info-label">Valid To</div><div class="dhr-info-value">{{ viewing.valid_to || '∞' }}</div></div></v-col>
            <v-col cols="12" sm="6" md="4"><div class="dhr-info-item"><div class="dhr-info-label">Is Default Plan</div><div class="dhr-info-value"><v-chip size="x-small" :color="viewing.is_default ? 'primary' : 'grey'" variant="flat">{{ viewing.is_default ? 'Yes' : 'No' }}</v-chip></div></div></v-col>
            <v-col cols="12"><div class="dhr-info-item"><div class="dhr-info-label">Description</div><div class="dhr-info-value" style="font-weight:400; line-height:1.5">{{ viewing.description || '—' }}</div></div></v-col>
          </v-row>
          <div class="dhr-rate-grid mt-4">
            <div v-for="p in periodOpts" :key="p.value" class="dhr-rate-block">
              <div class="d-flex align-center ga-1 mb-1"><v-icon size="14" color="primary">{{ periodIcon(p.value) }}</v-icon><span class="text-caption font-weight-medium text-capitalize">{{ p.label }}</span></div>
              <div class="d-flex align-center justify-space-between">
                <div>
                  <div class="text-caption text-medium-emphasis">Base</div>
                  <div class="text-body-2 font-weight-bold">{{ currencySymbol }}{{ Number(viewing[`${p.value}_rate`] || 0).toLocaleString() }}</div>
                </div>
                <v-icon size="16" color="success">mdi-arrow-right</v-icon>
                <div class="text-right">
                  <div class="text-caption text-medium-emphasis">Effective</div>
                  <div class="text-body-2 font-weight-bold text-success">{{ currencySymbol }}{{ Number(viewing[`${p.value}_effective_rate`] || 0).toLocaleString() }}</div>
                </div>
              </div>
              <div class="d-flex ga-1 mt-1">
                <v-chip v-if="Number(viewing[`${p.value}_discount_percent`]) > 0" size="x-small" variant="flat" color="success">-{{ viewing[`${p.value}_discount_percent`] }}%</v-chip>
                <v-chip v-if="Number(viewing[`${p.value}_markup_percent`]) > 0" size="x-small" variant="flat" color="warning">+{{ viewing[`${p.value}_markup_percent`] }}%</v-chip>
              </div>
            </div>
          </div>
        </v-card-text>
        <v-divider />
        <v-card-actions class="pa-4">
          <v-btn variant="text" prepend-icon="mdi-calculator-variant" @click="viewing && openCalculator(viewing); viewDialog = false">Calculate</v-btn>
          <v-spacer />
          <v-btn variant="text" @click="viewDialog = false">Close</v-btn>
          <v-btn v-can="'rentals:update'" color="primary" prepend-icon="mdi-pencil" @click="viewing && openEdit(viewing)">Edit Plan</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- ── Create / Edit Dialog ── -->
    <v-dialog v-model="dlgForm" max-width="920" scrollable>
      <v-card rounded="lg">
        <v-card-title class="d-flex align-center justify-space-between pa-4 dhr-form-header">
          <span class="text-h6 font-weight-bold">{{ editing ? 'Edit Rate Plan' : 'New Rate Plan' }}</span>
          <v-btn icon="mdi-close" variant="text" size="small" @click="dlgForm = false" />
        </v-card-title>
        <v-divider />
        <v-card-text class="pt-4">
          <v-row dense>
            <v-col cols="12" md="6">
              <v-select v-model="form.driver" :items="drivers" item-title="full_name" item-value="id" label="Specific Driver (optional)" density="compact" variant="outlined" hide-details clearable prepend-inner-icon="mdi-account-tie" />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="form.name" label="Plan Name" density="compact" variant="outlined" hide-details placeholder="e.g. Corporate Weekend Plan" prepend-inner-icon="mdi-tag-text-outline" />
            </v-col>
            <v-col cols="12" md="6">
              <v-select v-model="form.default_rate_period" :items="periodOpts" item-title="label" item-value="value" label="Default Billing Period" density="compact" variant="outlined" hide-details prepend-inner-icon="mdi-calendar-clock" />
            </v-col>
            <v-col cols="12">
              <v-textarea v-model="form.description" label="Description / Notes" density="compact" variant="outlined" hide-details rows="2" />
            </v-col>
          </v-row>

          <div class="dhr-section-label mt-5 mb-2"><v-icon size="16" color="primary">mdi-cash-multiple</v-icon> Base Rates ({{ currencySymbol }})</div>
          <v-row dense>
            <v-col cols="6" md="2"><v-text-field v-model="form.hourly_rate" type="number" label="Hourly" density="compact" variant="outlined" hide-details :prefix="currencySymbol" /></v-col>
            <v-col cols="6" md="2"><v-text-field v-model="form.daily_rate" type="number" label="Daily" density="compact" variant="outlined" hide-details :prefix="currencySymbol" /></v-col>
            <v-col cols="6" md="2"><v-text-field v-model="form.weekly_rate" type="number" label="Weekly" density="compact" variant="outlined" hide-details :prefix="currencySymbol" /></v-col>
            <v-col cols="6" md="3"><v-text-field v-model="form.monthly_rate" type="number" label="Monthly" density="compact" variant="outlined" hide-details :prefix="currencySymbol" /></v-col>
            <v-col cols="6" md="3"><v-text-field v-model="form.weekend_rate" type="number" label="Weekend" density="compact" variant="outlined" hide-details :prefix="currencySymbol" /></v-col>
          </v-row>
          <v-alert type="info" variant="tonal" density="compact" class="mt-3" v-if="hasAnyRate">
            <div class="d-flex flex-wrap ga-3">
              <template v-for="p in periodOpts" :key="p.value">
                <div v-if="Number(form[`${p.value}_rate`]) > 0" class="d-flex align-center ga-1">
                  <v-chip size="x-small" variant="flat" color="primary">{{ p.label }}</v-chip>
                  <span class="text-caption">{{ currencySymbol }}{{ effRate(p.value) }}</span>
                </div>
              </template>
            </div>
            <p class="text-caption text-medium-emphasis mt-1">Effective rate = base × (1 − discount%) × (1 + markup%)</p>
          </v-alert>

          <div class="dhr-section-label mt-5 mb-2"><v-icon size="16" color="success">mdi-tag</v-icon> Discounts (%)</div>
          <v-row dense>
            <v-col cols="6" md="2"><v-text-field v-model="form.hourly_discount_percent" type="number" label="Hourly %" density="compact" variant="outlined" hide-details suffix="%" /></v-col>
            <v-col cols="6" md="2"><v-text-field v-model="form.daily_discount_percent" type="number" label="Daily %" density="compact" variant="outlined" hide-details suffix="%" /></v-col>
            <v-col cols="6" md="2"><v-text-field v-model="form.weekly_discount_percent" type="number" label="Weekly %" density="compact" variant="outlined" hide-details suffix="%" /></v-col>
            <v-col cols="6" md="3"><v-text-field v-model="form.monthly_discount_percent" type="number" label="Monthly %" density="compact" variant="outlined" hide-details suffix="%" /></v-col>
            <v-col cols="6" md="3"><v-text-field v-model="form.weekend_discount_percent" type="number" label="Weekend %" density="compact" variant="outlined" hide-details suffix="%" /></v-col>
          </v-row>
          <v-row dense class="mt-1"><v-col cols="12" md="6"><v-text-field v-model="form.discount_flat_amount" type="number" :label="`Flat Discount Amount (${currencySymbol})`" density="compact" variant="outlined" hide-details :prefix="currencySymbol" /></v-col></v-row>

          <div class="dhr-section-label mt-5 mb-2"><v-icon size="16" color="warning">mdi-arrow-up-bold-box</v-icon> Markups (%)</div>
          <v-row dense>
            <v-col cols="6" md="2"><v-text-field v-model="form.hourly_markup_percent" type="number" label="Hourly %" density="compact" variant="outlined" hide-details suffix="%" /></v-col>
            <v-col cols="6" md="2"><v-text-field v-model="form.daily_markup_percent" type="number" label="Daily %" density="compact" variant="outlined" hide-details suffix="%" /></v-col>
            <v-col cols="6" md="2"><v-text-field v-model="form.weekly_markup_percent" type="number" label="Weekly %" density="compact" variant="outlined" hide-details suffix="%" /></v-col>
            <v-col cols="6" md="3"><v-text-field v-model="form.monthly_markup_percent" type="number" label="Monthly %" density="compact" variant="outlined" hide-details suffix="%" /></v-col>
            <v-col cols="6" md="3"><v-text-field v-model="form.weekend_markup_percent" type="number" label="Weekend %" density="compact" variant="outlined" hide-details suffix="%" /></v-col>
          </v-row>
          <v-row dense class="mt-1"><v-col cols="12" md="6"><v-text-field v-model="form.markup_flat_amount" type="number" :label="`Flat Markup Amount (${currencySymbol})`" density="compact" variant="outlined" hide-details :prefix="currencySymbol" /></v-col></v-row>

          <div class="dhr-section-label mt-5 mb-2"><v-icon size="16" color="info">mdi-shield-account</v-icon> Deposit &amp; Tax</div>
          <v-row dense>
            <v-col cols="12" md="4"><v-text-field v-model="form.security_deposit" type="number" :label="`Security Deposit (${currencySymbol})`" density="compact" variant="outlined" hide-details :prefix="currencySymbol" /></v-col>
            <v-col cols="12" md="4"><v-text-field v-model="form.tax_percent" type="number" label="Tax %" density="compact" variant="outlined" hide-details suffix="%" /></v-col>
          </v-row>

          <div class="dhr-section-label mt-5 mb-2"><v-icon size="16" color="secondary">mdi-calendar-range</v-icon> Validity &amp; Status</div>
          <v-row dense>
            <v-col cols="6" md="3"><v-text-field v-model="form.valid_from" type="date" label="Valid From" density="compact" variant="outlined" hide-details /></v-col>
            <v-col cols="6" md="3"><v-text-field v-model="form.valid_to" type="date" label="Valid To" density="compact" variant="outlined" hide-details /></v-col>
            <v-col cols="6" md="3"><v-select v-model="form.status" :items="statusOpts" item-title="label" item-value="value" label="Status" density="compact" variant="outlined" hide-details /></v-col>
            <v-col cols="6" md="3" class="d-flex align-center"><v-switch v-model="form.is_default" label="Set as default" density="compact" color="primary" hide-details /></v-col>
          </v-row>
        </v-card-text>
        <v-divider />
        <v-card-actions class="pa-4">
          <v-spacer />
          <v-btn variant="text" @click="dlgForm = false">Cancel</v-btn>
          <v-btn color="primary" :loading="saving" @click="savePlan">{{ editing ? 'Update' : 'Create' }} Plan</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- ── Cost Calculator Dialog ── -->
    <v-dialog v-model="dlgCalc" max-width="560">
      <v-card rounded="xl">
        <v-card-title class="d-flex align-center justify-space-between pa-4 dhr-form-header">
          <span class="text-h6 font-weight-bold"><v-icon class="mr-2">mdi-calculator-variant</v-icon>Cost Calculator</span>
          <v-btn icon="mdi-close" variant="text" size="small" @click="dlgCalc = false" />
        </v-card-title>
        <v-divider />
        <v-card-text class="pt-4">
          <v-alert v-if="!calcPlan" type="info" variant="tonal">Select a plan to calculate the billing.</v-alert>
          <template v-else>
            <p class="text-body-2 text-medium-emphasis mb-3">{{ calcPlan.name || calcPlan.driver_name || 'Default Rate' }}</p>
            <v-row dense>
              <v-col cols="12" md="6">
                <v-select v-model="calcPeriod" :items="periodOpts" item-title="label" item-value="value" label="Billing Period" density="compact" variant="outlined" hide-details />
              </v-col>
              <v-col cols="12" md="6">
                <v-text-field v-model="calcUnits" type="number" label="Units (hours/days/weeks)" density="compact" variant="outlined" hide-details prefix="1" />
              </v-col>
            </v-row>
            <v-btn color="primary" variant="tonal" class="mt-3" block :loading="calcLoading" @click="runCalc"><v-icon class="mr-2">mdi-calculator</v-icon>Calculate</v-btn>
            <v-card v-if="calcResult" variant="outlined" class="mt-4 pa-3 rounded-lg">
              <div class="d-flex flex-column ga-1">
                <div class="d-flex justify-space-between"><span class="text-body-2">Base ({{ calcUnits }} × rate):</span><strong class="text-body-2">{{ currencySymbol }}{{ Number(calcResult.base).toLocaleString() }}</strong></div>
                <div class="d-flex justify-space-between"><span class="text-body-2">Effective / unit:</span><strong class="text-body-2">{{ currencySymbol }}{{ Number(calcResult.effective_rate_per_unit).toLocaleString() }}</strong></div>
                <div class="d-flex justify-space-between"><span class="text-body-2">Discount ({{ calcResult.discount_percent }}%):</span><strong class="text-body-2 text-success">-{{ currencySymbol }}{{ Number(calcResult.discount_amount).toLocaleString() }}</strong></div>
                <div class="d-flex justify-space-between"><span class="text-body-2">Markup ({{ calcResult.markup_percent }}%):</span><strong class="text-body-2 text-warning">+{{ currencySymbol }}{{ Number(calcResult.markup_amount).toLocaleString() }}</strong></div>
                <div class="d-flex justify-space-between"><span class="text-body-2">Subtotal:</span><strong class="text-body-2">{{ currencySymbol }}{{ Number(calcResult.effective_subtotal).toLocaleString() }}</strong></div>
                <div class="d-flex justify-space-between"><span class="text-body-2">Tax ({{ calcResult.tax_percent }}%):</span><strong class="text-body-2">{{ currencySymbol }}{{ Number(calcResult.tax_amount).toLocaleString() }}</strong></div>
                <v-divider class="my-1" />
                <div class="d-flex justify-space-between align-center">
                  <span class="text-subtitle-1 font-weight-bold">Total:</span>
                  <strong class="text-h6 font-weight-bold text-primary">{{ currencySymbol }}{{ Number(calcResult.total).toLocaleString() }}</strong>
                </div>
              </div>
            </v-card>
          </template>
        </v-card-text>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import * as echarts from 'echarts/core'
import { setupECharts } from '~/utils/echarts'

setupECharts()

definePageMeta({ layout: 'default' })

const { $api, $swal } = useNuxtApp()
const { currencySymbol } = useCurrency()
const { isDark } = useDarkMode()

const pending = ref(true)
const plans = ref<any[]>([])
const drivers = ref<any[]>([])
const tab = ref('plans')
const viewMode = ref<'grid' | 'table'>('grid')

const search = ref('')
const filterStatus = ref<string | null>(null)
const filterPeriod = ref<string | null>(null)

const statusOpts = [
  { label: 'Active', value: 'active' },
  { label: 'Inactive', value: 'inactive' },
  { label: 'Expired', value: 'expired' },
]
const periodOpts = [
  { label: 'Hourly', value: 'hourly' },
  { label: 'Daily', value: 'daily' },
  { label: 'Weekly', value: 'weekly' },
  { label: 'Monthly', value: 'monthly' },
  { label: 'Weekend', value: 'weekend' },
]

const tableHeaders = [
  { title: 'Plan / Driver', key: 'name', sortable: true },
  { title: 'Hr', key: 'hourly_rate', align: 'end' as const },
  { title: 'Day', key: 'daily_rate', align: 'end' as const },
  { title: 'Wk', key: 'weekly_rate', align: 'end' as const },
  { title: 'Mo', key: 'monthly_rate', align: 'end' as const },
  { title: 'Effective', key: 'effective', align: 'center' as const },
  { title: 'Status', key: 'status', sortable: true },
  { title: 'Actions', key: 'actions', sortable: false, width: '160px' },
]

// ── Computed stats ──
const totalPlans = computed(() => plans.value.length)
const activePlans = computed(() => plans.value.filter(p => p.is_currently_active).length)
const driversWithPlans = computed(() => new Set(plans.value.filter(p => p.driver).map(p => p.driver)).size)
const plansWithoutDriver = computed(() => plans.value.filter(p => !p.driver).length)
const avgDailyRate = computed(() => {
  const arr = plans.value.filter(p => Number(p.daily_rate) > 0)
  if (!arr.length) return '0'
  return Math.round(arr.reduce((s, p) => s + Number(p.daily_rate), 0) / arr.length).toLocaleString()
})
const avgHourlyRate = computed(() => {
  const arr = plans.value.filter(p => Number(p.hourly_rate) > 0)
  if (!arr.length) return '0'
  return Math.round(arr.reduce((s, p) => s + Number(p.hourly_rate), 0) / arr.length).toLocaleString()
})

const driverPlans = computed(() => {
  const map: Record<number, any> = {}
  for (const p of plans.value) {
    if (!p.driver) continue
    if (!map[p.driver]) map[p.driver] = { driver_id: p.driver, driver_name: p.driver_name, plans: [], active: 0 }
    map[p.driver].plans.push(p)
    if (p.is_currently_active) map[p.driver].active++
  }
  return Object.values(map)
})

const filteredPlans = computed(() => {
  let arr = plans.value
  if (filterStatus.value) arr = arr.filter(p => p.status === filterStatus.value)
  if (filterPeriod.value) arr = arr.filter(p => p.default_rate_period === filterPeriod.value)
  if (search.value) {
    const q = search.value.toLowerCase()
    arr = arr.filter(p => (p.name || p.driver_name || '').toLowerCase().includes(q))
  }
  return arr
})

// ── Helpers ──
function getEffectiveRate(p: any) {
  const period = p.default_rate_period || 'daily'
  return p[`${period}_effective_rate`] || p[`${period}_rate`] || 0
}
function maxDiscount(p: any) {
  return Math.max(
    Number(p.hourly_discount_percent), Number(p.daily_discount_percent),
    Number(p.weekly_discount_percent), Number(p.monthly_discount_percent),
    Number(p.weekend_discount_percent)
  )
}
function maxMarkup(p: any) {
  return Math.max(
    Number(p.hourly_markup_percent), Number(p.daily_markup_percent),
    Number(p.weekly_markup_percent), Number(p.monthly_markup_percent),
    Number(p.weekend_markup_percent)
  )
}
function statusColor(s: string) { return s === 'active' ? 'success' : s === 'inactive' ? 'default' : 'error' }
function statusIcon(s: string) { return s === 'active' ? 'mdi-check-circle' : s === 'inactive' ? 'mdi-pause-circle' : 'mdi-alert-circle' }
function statusLabel(s: string) { return statusOpts.find(o => o.value === s)?.label || s }
function periodIcon(p: string) {
  return { hourly: 'mdi-clock-outline', daily: 'mdi-calendar-today', weekly: 'mdi-calendar-week', monthly: 'mdi-calendar-month', weekend: 'mdi-calendar-clock' }[p] || 'mdi-calendar'
}

// ── Load data ──
async function loadAll() {
  pending.value = true
  try {
    const [pl, dr] = await Promise.all([
      $api('/rentals/driver-hire-rates/?page_size=1000'),
      $api('/contacts/drivers/?page_size=1000'),
    ])
    plans.value = pl.results ?? pl ?? []
    drivers.value = dr.results ?? dr ?? []
  } catch (e) {
    console.error(e)
  } finally {
    pending.value = false
  }
}
onMounted(() => {
  loadAll()
  ro = new ResizeObserver(() => {
    compareChart?.resize()
    statusChart?.resize()
    periodChart?.resize()
    avgChart?.resize()
  })
})

// ── Form ──
const dlgForm = ref(false)
const editing = ref(false)
const saving = ref(false)
const form = reactive<any>(blankForm())

function blankForm() {
  return {
    driver: null, name: '', description: '',
    default_rate_period: 'daily',
    hourly_rate: 0, daily_rate: 0, weekly_rate: 0, monthly_rate: 0, weekend_rate: 0,
    hourly_discount_percent: 0, daily_discount_percent: 0, weekly_discount_percent: 0, monthly_discount_percent: 0, weekend_discount_percent: 0,
    hourly_markup_percent: 0, daily_markup_percent: 0, weekly_markup_percent: 0, monthly_markup_percent: 0, weekend_markup_percent: 0,
    markup_flat_amount: 0, discount_flat_amount: 0,
    security_deposit: 0, tax_percent: 0,
    valid_from: '', valid_to: '', status: 'active', is_default: false,
  }
}
function resetForm() { Object.assign(form, blankForm()) }

function openCreate() {
  editing.value = false
  resetForm()
  userEdited.weekly = false
  userEdited.monthly = false
  userEdited.weekend = false
  dlgForm.value = true
}

const userEdited = reactive({ weekly: false, monthly: false, weekend: false })
let skipWatch = false
function round2(n: number): number { return Math.round(n * 100) / 100 }

watch(() => Number(form.daily_rate), (d) => {
  if (d > 0) {
    skipWatch = true
    if (!userEdited.weekly) form.weekly_rate = round2(d * 7)
    if (!userEdited.monthly) form.monthly_rate = round2(d * 30)
    if (!userEdited.weekend) form.weekend_rate = round2(d * 2)
    nextTick(() => { skipWatch = false })
  }
})
watch(() => form.weekly_rate, () => { if (!skipWatch) userEdited.weekly = true })
watch(() => form.monthly_rate, () => { if (!skipWatch) userEdited.monthly = true })
watch(() => form.weekend_rate, () => { if (!skipWatch) userEdited.weekend = true })

const hasAnyRate = computed(() => periodOpts.some(p => Number(form[`${p.value}_rate`]) > 0))
function effRate(period: string): string {
  const base = Number(form[`${period}_rate`] || 0)
  if (base <= 0) return '0'
  const disc = Number(form[`${period}_discount_percent`] || 0)
  const markup = Number(form[`${period}_markup_percent`] || 0)
  return round2(base * (1 - disc / 100) * (1 + markup / 100)).toFixed(2)
}

function openEdit(item: any) {
  editing.value = true
  resetForm()
  Object.assign(form, item)
  userEdited.weekly = false
  userEdited.monthly = false
  userEdited.weekend = false
  dlgForm.value = true
  viewDialog.value = false
}

async function savePlan() {
  if (!form.name && !form.driver) {
    $swal?.fire?.({ icon: 'warning', title: 'Enter a plan name or select a driver', toast: true, timer: 2500, position: 'top-end' })
    return
  }
  saving.value = true
  try {
    const body = { ...form }
    if (!body.valid_from) body.valid_from = null
    if (!body.valid_to) body.valid_to = null
    if (editing.value) {
      await $api(`/rentals/driver-hire-rates/${form.id}/`, { method: 'PUT', body })
      $swal?.fire?.({ icon: 'success', title: 'Plan updated', toast: true, timer: 2000, position: 'top-end' })
    } else {
      delete body.id
      await $api('/rentals/driver-hire-rates/', { method: 'POST', body })
      $swal?.fire?.({ icon: 'success', title: 'Plan created', toast: true, timer: 2000, position: 'top-end' })
    }
    dlgForm.value = false
    await loadAll()
  } catch (e: any) {
    $swal?.fire?.({ icon: 'error', title: 'Failed to save', text: JSON.stringify(e?.data || e?.message || ''), toast: true, timer: 4000, position: 'top-end' })
  } finally {
    saving.value = false
  }
}

async function remove(item: any) {
  const r = await $swal?.fire?.({ icon: 'warning', title: 'Delete plan?', text: `"${item.name || item.driver_name || 'Plan'}" will be permanently deleted.`, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!r?.isConfirmed) return
  try {
    await $api(`/rentals/driver-hire-rates/${item.id}/`, { method: 'DELETE' })
    $swal?.fire?.({ icon: 'success', title: 'Plan deleted', toast: true, timer: 2000, position: 'top-end' })
    await loadAll()
  } catch (e) {
    $swal?.fire?.({ icon: 'error', title: 'Delete failed', toast: true, timer: 2500, position: 'top-end' })
  }
}

// ── View dialog ──
const viewDialog = ref(false)
const viewing = ref<any>(null)
function openView(item: any) {
  viewing.value = item
  viewDialog.value = true
}

// ── Calculator ──
const dlgCalc = ref(false)
const calcPlan = ref<any>(null)
const calcPeriod = ref('daily')
const calcUnits = ref(1)
const calcResult = ref<any>(null)
const calcLoading = ref(false)

function openCalculator(item: any) {
  calcPlan.value = item
  calcPeriod.value = item.default_rate_period || 'daily'
  calcUnits.value = 1
  calcResult.value = null
  dlgCalc.value = true
}
function openGlobalCalculator() {
  if (plans.value.length) openCalculator(plans.value[0])
  else { calcPlan.value = null; calcResult.value = null; dlgCalc.value = true }
}

async function runCalc() {
  if (!calcPlan.value) return
  calcLoading.value = true
  try {
    calcResult.value = await $api(`/rentals/driver-hire-rates/${calcPlan.value.id}/compute/`, {
      method: 'POST',
      body: { period: calcPeriod.value, units: Number(calcUnits.value) || 1 },
    })
  } catch (e) {
    $swal?.fire?.({ icon: 'error', title: 'Calculation failed', toast: true, timer: 2500, position: 'top-end' })
  } finally {
    calcLoading.value = false
  }
}

// ── Charts ──
const comparePeriod = ref('daily')
const compareMetric = ref('base')
const compareChartEl = ref<HTMLElement | null>(null)
let compareChart: echarts.ECharts | null = null

const statusChartEl = ref<HTMLElement | null>(null)
let statusChart: echarts.ECharts | null = null
const periodChartEl = ref<HTMLElement | null>(null)
let periodChart: echarts.ECharts | null = null
const avgChartEl = ref<HTMLElement | null>(null)
let avgChart: echarts.ECharts | null = null

const chartColors = ['#6366f1', '#10b981', '#f59e0b', '#ef4444', '#3b82f6', '#8b5cf6', '#ec4899', '#06b6d4']
const axisTextColor = computed(() => isDark.value ? '#cbd5e1' : '#475569')
const splitLineColor = computed(() => isDark.value ? 'rgba(148,163,184,0.12)' : 'rgba(226,232,240,0.7)')

function renderCompareChart() {
  if (!compareChartEl.value || !filteredPlans.value.length) return
  if (!compareChart) compareChart = echarts.init(compareChartEl.value)
  const items = filteredPlans.value
  const period = comparePeriod.value
  const metric = compareMetric.value
  const field = metric === 'effective' ? `${period}_effective_rate` : `${period}_rate`
  compareChart.setOption({
    tooltip: { trigger: 'axis', valueFormatter: (v: number) => `${currencySymbol.value}${Number(v || 0).toLocaleString()}` },
    grid: { left: 50, right: 20, top: 20, bottom: 60 },
    xAxis: { type: 'category', data: items.map(p => p.name || p.driver_name || 'Plan'), axisLabel: { rotate: 30, fontSize: 11, color: axisTextColor.value } },
    yAxis: { type: 'value', axisLabel: { formatter: (v: number) => `${currencySymbol.value}${v.toLocaleString()}`, color: axisTextColor.value }, splitLine: { lineStyle: { color: splitLineColor.value } } },
    series: [{ type: 'bar', data: items.map(p => Number(p[field] || 0)), itemStyle: { color: metric === 'effective' ? '#10b981' : '#6366f1', borderRadius: [6, 6, 0, 0] } }],
  })
}

function renderStatusChart() {
  if (!statusChartEl.value) return
  if (!statusChart) statusChart = echarts.init(statusChartEl.value)
  const counts: Record<string, number> = {}
  for (const p of plans.value) counts[p.status] = (counts[p.status] || 0) + 1
  const data = Object.entries(counts).map(([k, v], i) => ({ name: statusLabel(k), value: v, itemStyle: { color: chartColors[i % chartColors.length] } }))
  statusChart.setOption({
    tooltip: { trigger: 'item' },
    legend: { bottom: 0, textStyle: { color: axisTextColor.value } },
    series: [{ type: 'pie', radius: ['40%', '70%'], data, label: { color: axisTextColor.value } }],
  })
}

function renderPeriodChart() {
  if (!periodChartEl.value) return
  if (!periodChart) periodChart = echarts.init(periodChartEl.value)
  const counts: Record<string, number> = {}
  for (const p of plans.value) { const k = p.default_rate_period || 'daily'; counts[k] = (counts[k] || 0) + 1 }
  const data = Object.entries(counts).map(([k, v], i) => ({ name: k.charAt(0).toUpperCase() + k.slice(1), value: v, itemStyle: { color: chartColors[i % chartColors.length] } }))
  periodChart.setOption({
    tooltip: { trigger: 'item' },
    legend: { bottom: 0, textStyle: { color: axisTextColor.value } },
    series: [{ type: 'pie', radius: '65%', data, label: { color: axisTextColor.value } }],
  })
}

function renderAvgChart() {
  if (!avgChartEl.value) return
  if (!avgChart) avgChart = echarts.init(avgChartEl.value)
  const labels = periodOpts.map(p => p.label)
  const baseData = periodOpts.map(p => {
    const arr = plans.value.filter(pl => Number(pl[`${p.value}_rate`]) > 0)
    return arr.length ? Math.round(arr.reduce((s, pl) => s + Number(pl[`${p.value}_rate`]), 0) / arr.length) : 0
  })
  const effData = periodOpts.map(p => {
    const arr = plans.value.filter(pl => Number(pl[`${p.value}_effective_rate`]) > 0)
    return arr.length ? Math.round(arr.reduce((s, pl) => s + Number(pl[`${p.value}_effective_rate`]), 0) / arr.length) : 0
  })
  avgChart.setOption({
    tooltip: { trigger: 'axis', valueFormatter: (v: number) => `${currencySymbol.value}${Number(v || 0).toLocaleString()}` },
    legend: { data: ['Base Rate', 'Effective Rate'], textStyle: { color: axisTextColor.value } },
    grid: { left: 50, right: 20, top: 40, bottom: 30 },
    xAxis: { type: 'category', data: labels, axisLabel: { color: axisTextColor.value } },
    yAxis: { type: 'value', axisLabel: { formatter: (v: number) => `${currencySymbol.value}${v.toLocaleString()}`, color: axisTextColor.value }, splitLine: { lineStyle: { color: splitLineColor.value } } },
    series: [
      { name: 'Base Rate', type: 'bar', data: baseData, itemStyle: { color: '#6366f1', borderRadius: [4, 4, 0, 0] } },
      { name: 'Effective Rate', type: 'bar', data: effData, itemStyle: { color: '#10b981', borderRadius: [4, 4, 0, 0] } },
    ],
  })
}

let ro: ResizeObserver | null = null

watch([tab, filteredPlans, comparePeriod, compareMetric], () => {
  nextTick(() => {
    if (tab.value === 'rates') renderCompareChart()
    if (tab.value === 'analytics') { renderStatusChart(); renderPeriodChart(); renderAvgChart() }
  })
}, { immediate: false })

watch([plans], () => {
  nextTick(() => {
    if (tab.value === 'rates') renderCompareChart()
    if (tab.value === 'analytics') { renderStatusChart(); renderPeriodChart(); renderAvgChart() }
  })
})

onBeforeUnmount(() => {
  ro?.disconnect()
  compareChart?.dispose()
  statusChart?.dispose()
  periodChart?.dispose()
  avgChart?.dispose()
})

useHead({ title: 'Driver Hire Rates' })
</script>

<style scoped>
.text-success {
  color: rgb(var(--v-theme-success)) !important;
}

.dhr-title {
  color: rgb(var(--v-theme-on-surface)) !important;
  font-size: 1.25rem !important;
}

.dhr-header-icon {
  background: linear-gradient(135deg, #6366f1 0%, #4f46e5 100%) !important;
  width: 48px !important;
  height: 48px !important;
  flex-shrink: 0 !important;
}

/* KPI cards */
.dhr-kpi-card {
  border-radius: 16px !important;
  border: none !important;
  color: #fff !important;
  overflow: hidden;
  position: relative;
  transition: transform 0.2s ease;
}
.dhr-kpi-card:hover { transform: translateY(-2px); }

.dhr-kpi-card::before {
  content: '';
  position: absolute;
  top: -30px;
  right: -30px;
  width: 100px;
  height: 100px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.06);
}

.dhr-kpi-indigo {
  background: linear-gradient(135deg, #6366f1 0%, #4f46e5 100%) !important;
}
.dhr-kpi-green {
  background: linear-gradient(135deg, #10b981 0%, #059669 100%) !important;
}
.dhr-kpi-amber {
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%) !important;
}
.dhr-kpi-red {
  background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%) !important;
}

.dhr-kpi-value {
  color: #fff !important;
  font-weight: 800 !important;
  font-size: 1.75rem !important;
  line-height: 1.2;
}

.dhr-kpi-label {
  color: rgba(255, 255, 255, 0.75) !important;
  font-size: 0.8rem !important;
  font-weight: 500;
  margin-top: 4px;
}

/* Plan grid cards */
.dhr-plan-card {
  border-radius: 16px !important;
  transition: all 0.2s ease;
  cursor: pointer;
}
.dhr-plan-card:hover {
  border-color: rgb(var(--v-theme-primary)) !important;
  box-shadow: 0 4px 20px rgba(99, 102, 241, 0.15) !important;
}

.dhr-plan-active {
  border-color: rgb(var(--v-theme-success)) !important;
}

.dhr-plan-header {
  padding: 16px 16px 0 16px;
}

.dhr-plan-name {
  color: rgb(var(--v-theme-on-surface)) !important;
}

.dhr-eff-box {
  background: rgba(var(--v-theme-success), 0.06);
  border: 1px solid rgba(var(--v-theme-success), 0.2);
  border-radius: 10px;
  padding: 10px 14px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

/* Driver cards */
.dhr-driver-card {
  border-radius: 16px !important;
  cursor: pointer;
  transition: all 0.2s ease;
}
.dhr-driver-card:hover {
  border-color: rgb(var(--v-theme-primary)) !important;
  box-shadow: 0 2px 12px rgba(99, 102, 241, 0.1) !important;
}

/* View dialog */
.dhr-view-hero {
  background: linear-gradient(135deg, #6366f1 0%, #4f46e5 100%) !important;
}

.dhr-info-item {
  background: rgba(var(--v-theme-surface-variant), 0.5);
  border-radius: 10px;
  padding: 12px 14px;
}

.dhr-info-label {
  font-size: 0.7rem !important;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: rgba(var(--v-theme-on-surface), 0.5) !important;
  font-weight: 600;
  margin-bottom: 4px;
}

.dhr-info-value {
  font-weight: 700;
  color: rgb(var(--v-theme-on-surface)) !important;
}

.dhr-rate-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 12px;
}

.dhr-rate-block {
  background: rgba(var(--v-theme-surface-variant), 0.4);
  border: 1px solid rgba(var(--v-theme-on-surface), 0.08);
  border-radius: 12px;
  padding: 12px;
}

/* Form */
.dhr-form-header {
  background: linear-gradient(135deg, rgba(99, 102, 241, 0.06) 0%, rgba(99, 102, 241, 0.02) 100%) !important;
}

.dhr-section-label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 0.85rem !important;
  font-weight: 700;
  color: rgb(var(--v-theme-on-surface)) !important;
  padding: 6px 0;
  border-top: 1px solid rgba(var(--v-theme-on-surface), 0.08);
}
</style>
