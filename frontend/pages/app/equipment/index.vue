<template>
  <div class="d-flex flex-column ga-4">
    <!-- ── Header ── -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-3">
      <div class="d-flex align-center ga-3">
        <div class="d-flex align-center justify-center rounded-xl" style="width: 48px; height: 48px; background: linear-gradient(135deg, #6366f1, #4f46e5)">
          <v-icon color="white">mdi-tools</v-icon>
        </div>
        <div>
          <h1 class="text-h5 font-weight-bold" style="color: #1e293b">Equipment Management</h1>
          <p class="text-body-2 text-medium-emphasis">Asset registry, checkouts, meter readings, calibrations and utilization</p>
        </div>
      </div>
      <div class="d-flex align-center ga-2 flex-wrap">
        <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Search equipment..." density="compact" variant="outlined" hide-details style="max-width: 240px" />
        <div class="d-flex">
          <v-btn variant="outlined" color="secondary" prepend-icon="mdi-database-plus-outline" :loading="seeding" class="hidden-sm-and-down" @click="confirmSeedDemo(false)"><span class="hidden-sm-and-down">Seed Demo Data</span></v-btn>
          <v-menu>
            <template #activator="{ props }">
              <v-btn variant="outlined" color="secondary" icon="$dropdown" density="compact" class="hidden-sm-and-down" v-bind="props" style="margin-left: 1px; height: 40px" />
            </template>
            <v-list density="compact">
              <v-list-item prepend-icon="mdi-database-plus-outline" title="Add demo data" subtitle="Keep existing data" @click="confirmSeedDemo(false)" />
              <v-list-item prepend-icon="mdi-database-refresh-outline" title="Replace all with demo data" subtitle="Delete existing data first" base-color="error" @click="confirmSeedDemo(true)" />
            </v-list>
          </v-menu>
        </div>
        <v-btn v-can="'equipment:create'" color="primary" prepend-icon="mdi-plus" @click="openCreate"><span class="hidden-sm-and-down">Add Equipment</span></v-btn>
      </div>
    </div>

    <!-- ── KPI Cards ── -->
    <v-row dense>
      <v-col cols="6" md="3">
        <StatCard label="Total Equipment" :value="items.length" icon="mdi-tools" iconBg="#eef2ff" iconColor="#6366f1" :subtitle="`${categories.length} categories`" />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard label="Available" :value="availableCount" icon="mdi-check-circle-outline" iconBg="#ecfdf5" iconColor="#16a34a" :subtitle="`${inUseCount} in use`" />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard label="Checked Out" :value="checkedOutCount" icon="mdi-swap-horizontal" iconBg="#dbeafe" iconColor="#2563eb" :subtitle="`${overdueCount} overdue`" />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard label="Calibration Due" :value="calibrationDueCount" icon="mdi-calculator-variant" iconBg="#fff7ed" iconColor="#ea580c" :subtitle="`${calibrationOverdueCount} overdue`" />
      </v-col>
    </v-row>

    <!-- ── Tabs ── -->
    <v-card elevation="0" border rounded="lg">
      <v-tabs v-model="tab" color="primary" density="compact">
        <v-tab value="inventory" prepend-icon="mdi-tools">Inventory</v-tab>
        <v-tab value="checkouts" prepend-icon="mdi-swap-horizontal">Checkouts</v-tab>
        <v-tab value="meter" prepend-icon="mdi-counter">Meter Entries</v-tab>
        <v-tab value="calibrations" prepend-icon="mdi-calculator-variant">Calibrations</v-tab>
        <v-tab value="analytics" prepend-icon="mdi-chart-box-outline">Analytics</v-tab>
      </v-tabs>
      <v-divider />

      <v-window v-model="tab">
        <!-- ═══════════════ INVENTORY ═══════════════ -->
        <v-window-item value="inventory" class="pa-4">
          <!-- Filter bar -->
          <div class="d-flex align-center ga-3 flex-wrap mb-4">
            <v-select v-model="filterStatus" :items="statusFilterOptions" item-title="label" item-value="value" label="Status" density="compact" variant="outlined" hide-details clearable style="max-width: 180px" />
            <v-select v-model="filterCategory" :items="categories" item-title="name" item-value="id" label="Category" density="compact" variant="outlined" hide-details clearable style="max-width: 200px" />
            <v-select v-model="filterCalibration" :items="calibrationFilterOptions" label="Calibration" density="compact" variant="outlined" hide-details clearable style="max-width: 180px" />
            <v-spacer />
            <v-btn v-if="calibrationDueCount > 0" variant="outlined" color="warning" size="small" prepend-icon="mdi-alert-circle-outline" @click="filterCalibrationOnly">Calibration Due ({{ calibrationDueCount }})</v-btn>
          </div>

          <v-data-table :headers="invHeaders" :items="filteredItems" :loading="pending" hover density="comfortable" :items-per-page="15">
            <template #item.name="{ item }">
              <div class="d-flex align-center ga-2">
                <v-avatar size="36" :color="statusAvatarColor(item.status)" variant="tonal">
                  <v-icon size="18">{{ item.requires_calibration ? 'mdi-calculator-variant' : 'mdi-tools' }}</v-icon>
                </v-avatar>
                <div>
                  <div class="text-body-2 font-weight-medium" style="color: #1e293b">{{ item.name }}</div>
                  <div class="text-caption text-medium-emphasis">{{ item.asset_number }}</div>
                </div>
              </div>
            </template>
            <template #item.status="{ value }">
              <v-chip size="small" :color="statusColor(value)" variant="tonal">{{ statusLabel(value) }}</v-chip>
            </template>
            <template #item.category_name="{ value }">
              <v-chip v-if="value" size="x-small" variant="tonal">{{ value }}</v-chip>
              <span v-else class="text-medium-emphasis">—</span>
            </template>
            <template #item.assigned_to_name="{ value }">
              <span v-if="value" class="text-body-2">{{ value }}</span>
              <span v-else class="text-medium-emphasis">—</span>
            </template>
            <template #item.assigned_vehicle_name="{ value }">
              <span v-if="value" class="text-body-2">{{ value }}</span>
              <span v-else class="text-medium-emphasis">—</span>
            </template>
            <template #item.calibration="{ item }">
              <v-chip v-if="!item.requires_calibration" size="x-small" color="grey" variant="text">N/A</v-chip>
              <v-chip v-else size="x-small" :color="calibrationColor(item)" variant="tonal">{{ calibrationLabel(item) }}</v-chip>
            </template>
            <template #item.current_hours="{ value }">{{ value ? value.toLocaleString() : 0 }}h</template>
            <template #item.actions="{ item }">
              <div class="d-flex ga-1">
                <v-btn :icon="item.is_checked_out ? 'mdi-arrow-u-left-bottom' : 'mdi-arrow-u-right-top'" variant="text" size="small" :title="item.is_checked_out ? 'Check In' : 'Check Out'" @click="openCheckout(item)" />
                <v-btn v-can="'equipment:update'" icon="mdi-counter" variant="text" size="small" title="Meter Entry" @click="openMeter(item)" />
                <v-btn v-can="'equipment:update'" icon="mdi-pencil-outline" variant="text" size="small" @click="openEdit(item)" />
                <v-btn v-can="'equipment:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deleteItem(item)" />
              </div>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-tools</v-icon>
                <p>No equipment found.</p>
              </div>
            </template>
          </v-data-table>
        </v-window-item>

        <!-- ═══════════════ CHECKOUTS ═══════════════ -->
        <v-window-item value="checkouts" class="pa-4">
          <div class="d-flex align-center ga-3 flex-wrap mb-4">
            <v-text-field v-model="checkoutSearch" prepend-inner-icon="mdi-magnify" placeholder="Search checkouts..." density="compact" variant="outlined" hide-details clearable style="max-width: 240px" />
            <v-select v-model="checkoutFilter" :items="checkoutFilterOptions" item-title="label" item-value="value" label="Filter" density="compact" variant="outlined" hide-details style="max-width: 160px" />
            <v-spacer />
            <v-chip size="small" variant="tonal" color="primary">{{ activeCheckouts.length }} active</v-chip>
            <v-chip size="small" variant="tonal" color="error">{{ overdueCheckouts.length }} overdue</v-chip>
          </div>

          <v-data-table :headers="checkoutHeaders" :items="filteredCheckouts" :loading="checkoutsPending" hover density="comfortable" :items-per-page="15">
            <template #item.equipment_name="{ value }"><span class="font-weight-medium">{{ value }}</span></template>
            <template #item.checked_out_to_name="{ value }">
              <v-avatar size="24" color="primary" variant="tonal" class="mr-1"><v-icon size="14">mdi-account</v-icon></v-avatar>{{ value }}
            </template>
            <template #item.checked_out_at="{ value }">{{ formatDate(value) }}</template>
            <template #item.expected_return_at="{ value }">{{ value ? formatDate(value) : '—' }}</template>
            <template #item.returned_at="{ value }">
              <v-chip v-if="value" size="x-small" color="success" variant="tonal">Returned</v-chip>
              <v-chip v-else size="x-small" color="warning" variant="tonal">Active</v-chip>
            </template>
            <template #item.is_overdue="{ value }">
              <v-chip v-if="value" size="x-small" color="error" variant="tonal">Overdue</v-chip>
            </template>
            <template #item.duration_hours="{ value }">{{ value }}h</template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis"><v-icon size="48" class="mb-3">mdi-swap-horizontal</v-icon><p>No checkout records.</p></div>
            </template>
          </v-data-table>
        </v-window-item>

        <!-- ═══════════════ METER ENTRIES ═══════════════ -->
        <v-window-item value="meter" class="pa-4">
          <div class="d-flex align-center justify-space-between mb-4">
            <v-text-field v-model="meterSearch" prepend-inner-icon="mdi-magnify" placeholder="Search meter entries..." density="compact" variant="outlined" hide-details clearable style="max-width: 240px" />
            <v-btn v-can="'equipment:update'" color="primary" size="small" prepend-icon="mdi-plus" @click="openMeter()">Add Meter Entry</v-btn>
          </div>
          <v-data-table :headers="meterHeaders" :items="filteredMeterEntries" :loading="meterPending" hover density="comfortable" :items-per-page="15">
            <template #item.equipment="{ item }">{{ getEquipmentName(item.equipment) }}</template>
            <template #item.hours="{ value }"><span class="font-weight-bold">{{ value.toLocaleString() }}</span></template>
            <template #item.recorded_at="{ value }">{{ formatDate(value) }}</template>
            <template #item.notes="{ value }"><span class="text-body-2">{{ value || '—' }}</span></template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis"><v-icon size="48" class="mb-3">mdi-counter</v-icon><p>No meter entries.</p></div>
            </template>
          </v-data-table>
        </v-window-item>

        <!-- ═══════════════ CALIBRATIONS ═══════════════ -->
        <v-window-item value="calibrations" class="pa-4">
          <div class="d-flex align-center justify-space-between mb-4">
            <v-text-field v-model="calibrationSearch" prepend-inner-icon="mdi-magnify" placeholder="Search calibrations..." density="compact" variant="outlined" hide-details clearable style="max-width: 240px" />
            <v-btn color="primary" size="small" prepend-icon="mdi-plus" @click="openCalibration">Add Calibration</v-btn>
          </div>
          <v-data-table :headers="calibrationHeaders" :items="filteredCalibrations" :loading="calibrationPending" hover density="comfortable" :items-per-page="15">
            <template #item.equipment="{ item }">{{ getEquipmentName(item.equipment) }}</template>
            <template #item.calibrated_at="{ value }">{{ value }}</template>
            <template #item.result="{ value }">
              <v-chip size="small" :color="calibrationResultColor(value)" variant="tonal">{{ value }}</v-chip>
            </template>
            <template #item.calibrated_by="{ value }"><span class="text-body-2">{{ value || '—' }}</span></template>
            <template #item.certificate_number="{ value }"><span class="text-body-2">{{ value || '—' }}</span></template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis"><v-icon size="48" class="mb-3">mdi-calculator-variant</v-icon><p>No calibration records.</p></div>
            </template>
          </v-data-table>
        </v-window-item>

        <!-- ═══════════════ ANALYTICS ═══════════════ -->
        <v-window-item value="analytics" class="pa-4">
          <div v-if="analyticsLoading" class="text-center py-12">
            <v-progress-circular indeterminate color="primary" />
          </div>
          <template v-else-if="analytics">
            <!-- Secondary KPIs -->
            <v-row dense class="mb-2">
              <v-col cols="6" md="3">
                <v-card elevation="0" border rounded="lg" class="pa-3 h-100">
                  <div class="d-flex align-center ga-2"><v-icon color="primary" size="20">mdi-chart-donut</v-icon><span class="text-caption text-medium-emphasis">Utilization</span></div>
                  <p class="text-h5 font-weight-bold mt-1" style="color: #2563eb">{{ analytics.summary.utilization_pct }}%</p>
                  <p class="text-caption text-medium-emphasis">{{ analytics.summary.in_use }} of {{ analytics.summary.total }} in use</p>
                </v-card>
              </v-col>
              <v-col cols="6" md="3">
                <v-card elevation="0" border rounded="lg" class="pa-3 h-100">
                  <div class="d-flex align-center ga-2"><v-icon color="success" size="20">mdi-cash-multiple</v-icon><span class="text-caption text-medium-emphasis">Asset Value</span></div>
                  <p class="text-h5 font-weight-bold mt-1" style="color: #16a34a">{{ fmtMoney(analytics.summary.total_value) }}</p>
                  <p class="text-caption text-medium-emphasis">Total purchase value</p>
                </v-card>
              </v-col>
              <v-col cols="6" md="3">
                <v-card elevation="0" border rounded="lg" class="pa-3 h-100">
                  <div class="d-flex align-center ga-2"><v-icon color="warning" size="20">mdi-wrench-clock</v-icon><span class="text-caption text-medium-emphasis">In Maintenance</span></div>
                  <p class="text-h5 font-weight-bold mt-1" style="color: #ea580c">{{ analytics.summary.in_maintenance }}</p>
                  <p class="text-caption text-medium-emphasis">{{ analytics.summary.retired }} retired</p>
                </v-card>
              </v-col>
              <v-col cols="6" md="3">
                <v-card elevation="0" border rounded="lg" class="pa-3 h-100">
                  <div class="d-flex align-center ga-2"><v-icon color="info" size="20">mdi-history</v-icon><span class="text-caption text-medium-emphasis">Recent Activity (30d)</span></div>
                  <p class="text-h5 font-weight-bold mt-1" style="color: #0891b2">{{ analytics.recent_activity.checkouts + analytics.recent_activity.meter_entries + analytics.recent_activity.calibrations }}</p>
                  <p class="text-caption text-medium-emphasis">{{ analytics.recent_activity.checkouts }} checkouts, {{ analytics.recent_activity.meter_entries }} meter, {{ analytics.recent_activity.calibrations }} calibrations</p>
                </v-card>
              </v-col>
            </v-row>

            <!-- Charts -->
            <v-row dense>
              <v-col cols="12" md="6">
                <DashboardChart :option="statusPieOption" title="Status Distribution" icon="mdi-chart-donut" height="300px" />
              </v-col>
              <v-col cols="12" md="6">
                <DashboardChart :option="categoryBarOption" title="Equipment by Category" icon="mdi-chart-bar" height="300px" />
              </v-col>
            </v-row>
          </template>
          <div v-else class="text-center py-12 text-medium-emphasis">
            <v-icon size="48" class="mb-3">mdi-chart-box-outline</v-icon>
            <p>No analytics data available.</p>
          </div>
        </v-window-item>
      </v-window>
    </v-card>

    <!-- ═══════════════ CREATE/EDIT DIALOG ═══════════════ -->
    <v-dialog v-model="dialogVisible" max-width="720">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-tools">{{ editing ? 'Edit Equipment' : 'Add Equipment' }}</AppModalHeader>
        <v-card-text>
          <v-row dense>
            <v-col cols="12" sm="6"><v-text-field v-model="form.name" label="Name *" density="compact" variant="outlined" /></v-col>
            <v-col cols="12" sm="6"><v-text-field v-model="form.asset_number" label="Asset Number *" density="compact" variant="outlined" /></v-col>
            <v-col cols="12" sm="6"><v-text-field v-model="form.serial_number" label="Serial Number" density="compact" variant="outlined" /></v-col>
            <v-col cols="12" sm="6"><v-text-field v-model="form.barcode" label="Barcode" density="compact" variant="outlined" /></v-col>
            <v-col cols="12" sm="6"><v-select v-model="form.category" :items="categories" item-title="name" item-value="id" label="Category" density="compact" variant="outlined" clearable /></v-col>
            <v-col cols="12" sm="6"><v-select v-model="form.status" :items="statusOptions" item-title="label" item-value="value" label="Status" density="compact" variant="outlined" /></v-col>
            <v-col cols="12" sm="6"><v-text-field v-model="form.location" label="Location" density="compact" variant="outlined" /></v-col>
            <v-col cols="12" sm="6"><v-select v-model="form.assigned_vehicle" :items="vehicles" item-title="display_name" item-value="id" label="Assigned Vehicle" density="compact" variant="outlined" clearable /></v-col>
            <v-col cols="12" sm="6"><v-text-field v-model.number="form.current_hours" label="Hour Meter" type="number" density="compact" variant="outlined" /></v-col>
            <v-col cols="12" sm="6"><v-text-field v-model="form.purchase_price" :label="`Purchase Price (${currencySymbol})`" density="compact" variant="outlined" /></v-col>
            <v-col cols="12" sm="6"><v-text-field v-model="form.purchase_date" label="Purchase Date" type="date" density="compact" variant="outlined" /></v-col>
            <v-col cols="12">
              <v-checkbox v-model="form.requires_calibration" label="Requires Calibration" density="compact" hide-details />
            </v-col>
            <template v-if="form.requires_calibration">
              <v-col cols="12" sm="6"><v-text-field v-model.number="form.calibration_interval_days" label="Calibration Interval (days)" type="number" density="compact" variant="outlined" /></v-col>
              <v-col cols="12" sm="6"><v-text-field v-model="form.next_calibration_due" label="Next Calibration Due" type="date" density="compact" variant="outlined" /></v-col>
            </template>
            <v-col cols="12"><v-textarea v-model="form.description" label="Description" rows="2" density="compact" variant="outlined" /></v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="dialogVisible = false">Cancel</v-btn>
          <v-btn color="primary" prepend-icon="mdi-check" :loading="saving" @click="save">{{ editing ? 'Update' : 'Create' }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- ═══════════════ CHECKOUT DIALOG ═══════════════ -->
    <v-dialog v-model="checkoutVisible" max-width="500">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-swap-horizontal">{{ activeItem?.is_checked_out ? 'Check In' : 'Check Out' }} — {{ activeItem?.name }}</AppModalHeader>
        <v-card-text>
          <template v-if="!activeItem?.is_checked_out">
            <v-row dense>
              <v-col cols="12"><v-select v-model="checkoutForm.checked_out_to" :items="drivers" item-title="full_name" item-value="id" label="Check Out To *" density="compact" variant="outlined" /></v-col>
              <v-col cols="12"><v-text-field v-model="checkoutForm.expected_return_at" label="Expected Return" type="datetime-local" density="compact" variant="outlined" /></v-col>
              <v-col cols="12"><v-textarea v-model="checkoutForm.notes" label="Notes" rows="2" density="compact" variant="outlined" /></v-col>
            </v-row>
          </template>
          <div v-else class="text-center py-4">
            <v-icon size="48" color="primary" class="mb-2">mdi-arrow-u-left-bottom</v-icon>
            <p class="text-body-1">Check in <b>{{ activeItem?.name }}</b>?</p>
            <p v-if="activeItem" class="text-caption text-medium-emphasis mt-1">Currently assigned to {{ activeItem.assigned_to_name }}</p>
          </div>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer /><v-btn variant="text" @click="checkoutVisible = false">Cancel</v-btn>
          <v-btn color="primary" :loading="saving" @click="submitCheckout">{{ activeItem?.is_checked_out ? 'Check In' : 'Check Out' }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- ═══════════════ METER ENTRY DIALOG ═══════════════ -->
    <v-dialog v-model="meterVisible" max-width="480">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-counter">Meter Entry{{ activeItem ? ' — ' + activeItem.name : '' }}</AppModalHeader>
        <v-card-text>
          <v-row dense>
            <v-col v-if="!activeItem" cols="12">
              <v-select v-model="meterForm.equipment" :items="items" item-title="display_name" item-value="id" label="Equipment *" density="compact" variant="outlined" />
            </v-col>
            <v-col cols="6"><v-text-field v-model.number="meterForm.hours" label="Hour Reading *" type="number" density="compact" variant="outlined" /></v-col>
            <v-col v-if="activeItem" cols="6"><v-text-field :model-value="activeItem.current_hours" label="Current" readonly density="compact" variant="outlined" /></v-col>
            <v-col cols="12"><v-text-field v-model="meterForm.notes" label="Notes" density="compact" variant="outlined" /></v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer /><v-btn variant="text" @click="meterVisible = false">Cancel</v-btn>
          <v-btn color="primary" :loading="saving" @click="submitMeter">Save</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- ═══════════════ CALIBRATION DIALOG ═══════════════ -->
    <v-dialog v-model="calibrationVisible" max-width="520">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-calculator-variant">Add Calibration Record</AppModalHeader>
        <v-card-text>
          <v-row dense>
            <v-col cols="12"><v-select v-model="calibrationForm.equipment" :items="calibratableItems" item-title="display_name" item-value="id" label="Equipment *" density="compact" variant="outlined" /></v-col>
            <v-col cols="12" sm="6"><v-text-field v-model="calibrationForm.calibrated_at" label="Calibration Date *" type="date" density="compact" variant="outlined" /></v-col>
            <v-col cols="12" sm="6"><v-select v-model="calibrationForm.result" :items="calibrationResultOptions" label="Result" density="compact" variant="outlined" /></v-col>
            <v-col cols="12" sm="6"><v-text-field v-model="calibrationForm.calibrated_by" label="Calibrated By" density="compact" variant="outlined" /></v-col>
            <v-col cols="12" sm="6"><v-text-field v-model="calibrationForm.certificate_number" label="Certificate #" density="compact" variant="outlined" /></v-col>
            <v-col cols="12"><v-textarea v-model="calibrationForm.notes" label="Notes" rows="2" density="compact" variant="outlined" /></v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer /><v-btn variant="text" @click="calibrationVisible = false">Cancel</v-btn>
          <v-btn color="primary" :loading="saving" @click="submitCalibration">Save</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
const { $api, $swal } = useNuxtApp()
const { currencySymbol, fmtMoney } = useCurrency()

const tab = ref('inventory')
const search = ref('')
const saving = ref(false)
const seeding = ref(false)

// ── Filters ──
const filterStatus = ref(null as string | null)
const filterCategory = ref(null as number | null)
const filterCalibration = ref(null as string | null)

// ── Dialogs ──
const dialogVisible = ref(false)
const checkoutVisible = ref(false)
const meterVisible = ref(false)
const calibrationVisible = ref(false)
const editing = ref(false)
const activeItem = ref<any>(null)

// ── Options ──
const statusOptions = [
  { label: 'Available', value: 'available' },
  { label: 'In Use', value: 'in_use' },
  { label: 'In Maintenance', value: 'in_maintenance' },
  { label: 'Retired', value: 'retired' },
]
const statusFilterOptions = statusOptions
const calibrationFilterOptions = ['Overdue', 'Due Soon', 'OK', 'Not Required']
const calibrationResultOptions = ['pass', 'fail', 'adjusted']
const checkoutFilterOptions = [
  { label: 'All', value: 'all' },
  { label: 'Active', value: 'active' },
  { label: 'Overdue', value: 'overdue' },
  { label: 'Returned', value: 'returned' },
]

// ── Forms ──
const defaultForm = () => ({
  name: '', asset_number: '', serial_number: '', barcode: '', category: null as any,
  status: 'available', location: '', assigned_vehicle: null as any, current_hours: 0,
  purchase_price: '', purchase_date: '', requires_calibration: false,
  calibration_interval_days: 365, next_calibration_due: '', description: '',
})
const form = reactive<any>(defaultForm())
const checkoutForm = reactive<any>({ checked_out_to: null, expected_return_at: '', notes: '' })
const meterForm = reactive<any>({ equipment: null, hours: null, notes: '' })
const calibrationForm = reactive<any>({ equipment: null, calibrated_at: new Date().toISOString().slice(0, 10), result: 'pass', calibrated_by: '', certificate_number: '', notes: '' })

// ── Headers ──
const invHeaders = [
  { title: 'Name', key: 'name', sortable: true },
  { title: 'Status', key: 'status', width: '120px', sortable: true },
  { title: 'Category', key: 'category_name', width: '140px' },
  { title: 'Assigned To', key: 'assigned_to_name', width: '140px' },
  { title: 'Vehicle', key: 'assigned_vehicle_name', width: '140px' },
  { title: 'Calibration', key: 'calibration', width: '110px' },
  { title: 'Hours', key: 'current_hours', width: '80px', align: 'end' as const },
  { title: '', key: 'actions', width: '160px', sortable: false },
]
const checkoutHeaders = [
  { title: 'Equipment', key: 'equipment_name', width: '180px' },
  { title: 'Out To', key: 'checked_out_to_name' },
  { title: 'Out At', key: 'checked_out_at', width: '140px' },
  { title: 'Expected Return', key: 'expected_return_at', width: '140px' },
  { title: 'Returned', key: 'returned_at', width: '100px' },
  { title: 'Overdue', key: 'is_overdue', width: '90px' },
  { title: 'Hours', key: 'duration_hours', width: '80px', align: 'end' as const },
]
const meterHeaders = [
  { title: 'Equipment', key: 'equipment', width: '200px' },
  { title: 'Hours', key: 'hours', width: '100px', align: 'end' as const },
  { title: 'Date', key: 'recorded_at', width: '150px' },
  { title: 'Notes', key: 'notes' },
]
const calibrationHeaders = [
  { title: 'Equipment', key: 'equipment', width: '180px' },
  { title: 'Date', key: 'calibrated_at', width: '120px' },
  { title: 'Result', key: 'result', width: '100px' },
  { title: 'Calibrated By', key: 'calibrated_by', width: '150px' },
  { title: 'Certificate', key: 'certificate_number' },
]

// ── Data Loading ──
const { data: itemData, pending, refresh: refreshItems } = useAsyncData(
  'equipment-items', () => $api('/equipment/items/', { query: { page_size: 100 } }), { default: () => ({ results: [] }) }
)
const { data: catData, refresh: refreshCats } = useAsyncData(
  'equipment-categories', () => $api('/equipment/categories/'), { default: () => ({ results: [] }) }
)
const { data: drvData } = useAsyncData(
  'equipment-drivers', () => $api('/contacts/', { query: { contact_type: 'driver' } }), { default: () => ({ results: [] }) }
)
const { data: vehData } = useAsyncData(
  'equipment-vehicles', () => $api('/vehicles/vehicles/', { query: { status: 'active' } }), { default: () => ({ results: [] }) }
)
const { data: checkoutData, pending: checkoutsPending, refresh: refreshCheckouts } = useAsyncData(
  'equipment-checkouts', () => $api('/equipment/checkouts/', { query: { page_size: 100 } }), { default: () => ({ results: [] }) }
)
const { data: meterData, pending: meterPending, refresh: refreshMeter } = useAsyncData(
  'equipment-meter', () => $api('/equipment/meter-entries/', { query: { page_size: 100 } }), { default: () => ({ results: [] }) }
)
const { data: calibrationData, pending: calibrationPending, refresh: refreshCalibrations } = useAsyncData(
  'equipment-calibrations', () => $api('/equipment/calibrations/', { query: { page_size: 100 } }), { default: () => ({ results: [] }) }
)
const { data: analyticsData, pending: analyticsLoading, refresh: refreshAnalytics } = useAsyncData(
  'equipment-analytics', () => $api('/equipment/items/analytics/').catch(() => null), { default: () => null, lazy: true }
)

// ── Computed ──
const items = computed(() => itemData.value?.results || itemData.value || [])
const categories = computed(() => catData.value?.results || [])
const drivers = computed(() => drvData.value?.results || [])
const vehicles = computed(() => vehData.value?.results || [])
const checkouts = computed(() => checkoutData.value?.results || checkoutData.value || [])
const meterEntries = computed(() => meterData.value?.results || meterData.value || [])
const calibrations = computed(() => calibrationData.value?.results || calibrationData.value || [])
const analytics = computed(() => analyticsData.value)

const availableCount = computed(() => items.value.filter(i => i.status === 'available').length)
const inUseCount = computed(() => items.value.filter(i => i.status === 'in_use').length)
const checkedOutCount = computed(() => items.value.filter(i => i.is_checked_out).length)
const calibrationDueCount = computed(() => items.value.filter(i => i.calibration_overdue || i.calibration_due_soon).length)
const calibrationOverdueCount = computed(() => items.value.filter(i => i.calibration_overdue).length)
const calibratableItems = computed(() => items.value.filter(i => i.requires_calibration))

const overdueCount = computed(() => checkouts.value.filter((c: any) => c.is_overdue).length)
const activeCheckouts = computed(() => checkouts.value.filter((c: any) => !c.returned_at))
const overdueCheckouts = computed(() => checkouts.value.filter((c: any) => c.is_overdue))

const filteredItems = computed(() => {
  let r = items.value
  if (search.value) {
    const s = search.value.toLowerCase()
    r = r.filter(i => i.name?.toLowerCase().includes(s) || i.asset_number?.toLowerCase().includes(s) || i.serial_number?.toLowerCase().includes(s))
  }
  if (filterStatus.value) r = r.filter(i => i.status === filterStatus.value)
  if (filterCategory.value) r = r.filter(i => i.category === filterCategory.value)
  if (filterCalibration.value) {
    if (filterCalibration.value === 'Overdue') r = r.filter(i => i.calibration_overdue)
    else if (filterCalibration.value === 'Due Soon') r = r.filter(i => i.calibration_due_soon)
    else if (filterCalibration.value === 'OK') r = r.filter(i => i.requires_calibration && !i.calibration_overdue && !i.calibration_due_soon)
    else if (filterCalibration.value === 'Not Required') r = r.filter(i => !i.requires_calibration)
  }
  return r
})

const checkoutSearch = ref('')
const checkoutFilter = ref('all')
const filteredCheckouts = computed(() => {
  let r = checkouts.value
  if (checkoutFilter.value === 'active') r = r.filter((c: any) => !c.returned_at)
  else if (checkoutFilter.value === 'overdue') r = r.filter((c: any) => c.is_overdue)
  else if (checkoutFilter.value === 'returned') r = r.filter((c: any) => c.returned_at)
  if (checkoutSearch.value) {
    const s = checkoutSearch.value.toLowerCase()
    r = r.filter((c: any) => c.equipment_name?.toLowerCase().includes(s) || c.checked_out_to_name?.toLowerCase().includes(s))
  }
  return r
})

const meterSearch = ref('')
const filteredMeterEntries = computed(() => {
  if (!meterSearch.value) return meterEntries.value
  const s = meterSearch.value.toLowerCase()
  return meterEntries.value.filter((m: any) => getEquipmentName(m.equipment).toLowerCase().includes(s) || m.notes?.toLowerCase().includes(s))
})

const calibrationSearch = ref('')
const filteredCalibrations = computed(() => {
  if (!calibrationSearch.value) return calibrations.value
  const s = calibrationSearch.value.toLowerCase()
  return calibrations.value.filter((c: any) => getEquipmentName(c.equipment).toLowerCase().includes(s) || c.calibrated_by?.toLowerCase().includes(s) || c.certificate_number?.toLowerCase().includes(s))
})

// ── Helpers ──
function statusColor(s: string) { return { available: 'success', in_use: 'primary', in_maintenance: 'warning', retired: 'grey' }[s] || 'grey' }
function statusLabel(s: string) { return statusOptions.find(o => o.value === s)?.label || s }
function statusAvatarColor(s: string) { return statusColor(s) }
function calibrationColor(i: any) { return i.calibration_overdue ? 'error' : i.calibration_due_soon ? 'warning' : 'success' }
function calibrationLabel(i: any) { return i.calibration_overdue ? 'Overdue' : i.calibration_due_soon ? 'Due Soon' : 'OK' }
function calibrationResultColor(r: string) { return { pass: 'success', fail: 'error', adjusted: 'warning' }[r] || 'grey' }
function formatDate(d: string) { if (!d) return '—'; const dt = new Date(d); return dt.toLocaleDateString() + ' ' + dt.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) }
function getEquipmentName(id: number) { return items.value.find(i => i.id === id)?.display_name || `#${id}` }

// ── Equipment CRUD ──
function openCreate() { editing.value = false; Object.assign(form, defaultForm()); dialogVisible.value = true }
function openEdit(i: any) { editing.value = true; Object.assign(form, defaultForm(), i); form._id = i.id; dialogVisible.value = true }
async function save() {
  if (!form.name || !form.asset_number) { $swal?.fire?.({ icon: 'warning', title: 'Name and Asset Number are required', toast: true, timer: 2000, position: 'top-end' }); return }
  saving.value = true
  try {
    const payload: any = { ...form }
    delete payload._id
    // Convert numeric strings and omit empty strings for nullable fields
    if (payload.purchase_price) payload.purchase_price = parseFloat(payload.purchase_price)
    else delete payload.purchase_price
    if (payload.current_hours) payload.current_hours = parseFloat(payload.current_hours)
    if (!payload.purchase_date) delete payload.purchase_date
    if (!payload.next_calibration_due) delete payload.next_calibration_due
    if (editing.value) await $api(`/equipment/items/${form._id}/`, { method: 'PATCH', body: payload })
    else await $api('/equipment/items/', { method: 'POST', body: payload })
    dialogVisible.value = false; await refreshAll()
  } catch (e: any) { console.error(e); $swal?.fire?.({ icon: 'error', title: e?.response?._data?.detail || 'Failed to save', toast: true, timer: 3000, position: 'top-end' }) }
  finally { saving.value = false }
}
async function deleteItem(i: any) {
  const r = await $swal?.fire?.({ icon: 'question', title: `Delete ${i.name}?`, text: 'This action cannot be undone.', showCancelButton: true, confirmButtonText: 'Delete' })
  if (!r?.isConfirmed) return
  await $api(`/equipment/items/${i.id}/`, { method: 'DELETE' })
  await refreshAll()
}

// ── Checkout ──
function openCheckout(i: any) { activeItem.value = i; Object.assign(checkoutForm, { checked_out_to: i.assigned_to, expected_return_at: '', notes: '' }); checkoutVisible.value = true }
async function submitCheckout() {
  if (!activeItem.value) return
  saving.value = true
  try {
    if (activeItem.value.is_checked_out) {
      await $api(`/equipment/items/${activeItem.value.id}/check-in/`, { method: 'POST' })
    } else {
      if (!checkoutForm.checked_out_to) { $swal?.fire?.({ icon: 'warning', title: 'Select a person', toast: true, timer: 2000, position: 'top-end' }); saving.value = false; return }
      await $api(`/equipment/items/${activeItem.value.id}/check-out/`, { method: 'POST', body: checkoutForm })
    }
    checkoutVisible.value = false; await refreshAll()
  } catch (e: any) { console.error(e); $swal?.fire?.({ icon: 'error', title: e?.response?._data?.detail || 'Failed', toast: true, timer: 3000, position: 'top-end' }) }
  finally { saving.value = false }
}

// ── Meter Entry ──
function openMeter(i?: any) { activeItem.value = i || null; Object.assign(meterForm, { equipment: i?.id || null, hours: i?.current_hours || null, notes: '' }); meterVisible.value = true }
async function submitMeter() {
  const eqId = activeItem.value?.id || meterForm.equipment
  if (!eqId || meterForm.hours == null) { $swal?.fire?.({ icon: 'warning', title: 'Equipment and hours are required', toast: true, timer: 2000, position: 'top-end' }); return }
  saving.value = true
  try {
    await $api(`/equipment/items/${eqId}/meter-entry/`, { method: 'POST', body: { hours: meterForm.hours, notes: meterForm.notes } })
    meterVisible.value = false; await refreshAll()
  } catch (e: any) { console.error(e); $swal?.fire?.({ icon: 'error', title: e?.response?._data?.detail || 'Failed', toast: true, timer: 3000, position: 'top-end' }) }
  finally { saving.value = false }
}

// ── Calibration ──
function openCalibration() {
  Object.assign(calibrationForm, { equipment: null, calibrated_at: new Date().toISOString().slice(0, 10), result: 'pass', calibrated_by: '', certificate_number: '', notes: '' })
  calibrationVisible.value = true
}
async function submitCalibration() {
  if (!calibrationForm.equipment || !calibrationForm.calibrated_at) { $swal?.fire?.({ icon: 'warning', title: 'Equipment and date are required', toast: true, timer: 2000, position: 'top-end' }); return }
  saving.value = true
  try {
    await $api('/equipment/calibrations/', { method: 'POST', body: calibrationForm })
    calibrationVisible.value = false; await refreshAll()
  } catch (e: any) { console.error(e); $swal?.fire?.({ icon: 'error', title: e?.response?._data?.detail || 'Failed', toast: true, timer: 3000, position: 'top-end' }) }
  finally { saving.value = false }
}

// ── Calibration filter button ──
function filterCalibrationOnly() { filterCalibration.value = 'Overdue'; filterStatus.value = null }

// ── Seed demo data ──
async function confirmSeedDemo(replace: boolean) {
  if (!replace && items.value.length > 0) {
    const r = await $swal?.fire?.({
      icon: 'question',
      title: 'Seed demo data?',
      text: 'This will add 50 sample equipment items with categories, checkouts, meter entries, and calibrations. Existing data will be kept.',
      showCancelButton: true,
      confirmButtonText: 'Seed Data',
    })
    if (!r?.isConfirmed) return
    await seedDemo(false)
  } else {
    const r = await $swal?.fire?.({
      icon: 'warning',
      title: 'Replace ALL equipment data?',
      text: 'This will DELETE all existing equipment, categories, checkouts, meter entries, and calibrations, then seed fresh demo data. This cannot be undone.',
      showCancelButton: true,
      confirmButtonText: 'Replace & Seed',
      confirmButtonColor: '#ef4444',
    })
    if (!r?.isConfirmed) return
    await seedDemo(true)
  }
}

async function seedDemo(clear: boolean) {
  seeding.value = true
  try {
    const res = await $api('/equipment/items/seed-demo/', { method: 'POST', body: { clear } })
    $swal?.fire?.({ icon: 'success', title: res.detail || 'Demo data seeded', toast: true, timer: 3000, position: 'top-end' })
    await refreshAll()
  } catch (e: any) {
    console.error(e)
    $swal?.fire?.({ icon: 'error', title: e?.response?._data?.detail || 'Failed to seed demo data', toast: true, timer: 4000, position: 'top-end' })
  } finally {
    seeding.value = false
  }
}

// ── Refresh all ──
async function refreshAll() {
  await Promise.all([refreshItems(), refreshCats(), refreshCheckouts(), refreshMeter(), refreshCalibrations(), refreshAnalytics()])
}

// ── Lazy load tab data ──
watch(tab, (v) => {
  if (v === 'analytics' && !analytics.value) refreshAnalytics()
  if (v === 'checkouts' && !checkouts.value.length) refreshCheckouts()
  if (v === 'meter' && !meterEntries.value.length) refreshMeter()
  if (v === 'calibrations' && !calibrations.value.length) refreshCalibrations()
})

// ── Analytics Charts ──
const statusPieOption = computed(() => {
  const data = (analytics.value?.status_chart || []).filter((d: any) => d.value > 0)
  if (!data.length) return {}
  return {
    tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
    legend: { bottom: 0, type: 'scroll' },
    series: [{
      type: 'pie', radius: ['40%', '70%'], center: ['50%', '45%'],
      itemStyle: { borderRadius: 6, borderColor: '#fff', borderWidth: 2 },
      label: { show: false }, emphasis: { label: { show: true, fontSize: 14, fontWeight: 'bold' } },
      data: data.map((d: any) => ({ name: d.name, value: d.value, itemStyle: { color: d.color } })),
    }],
  }
})

const categoryBarOption = computed(() => {
  const data = analytics.value?.by_category || []
  if (!data.length) return {}
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: 100, right: 30, top: 20, bottom: 20 },
    xAxis: { type: 'value' },
    yAxis: { type: 'category', data: data.map((c: any) => c.category), inverse: true },
    series: [{
      type: 'bar', data: data.map((c: any) => c.count), barMaxWidth: 24,
      itemStyle: { borderRadius: [0, 6, 6, 0], color: '#6366f1' },
      label: { show: true, position: 'right', formatter: '{c}' },
    }],
  }
})

useHead({ title: 'Equipment Management' })
</script>
