<template>
  <div class="d-flex flex-column ga-4">
    <!-- Header -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-2">
      <div>
        <h1 class="text-h5 font-weight-bold" style="color: #1e293b">Battery Management</h1>
        <p class="text-caption text-medium-emphasis">Inventory, health testing, install/swap, charge cycles, and lifecycle tracking</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Search batteries…" density="compact" variant="outlined" hide-details style="max-width: 260px" />
        <v-btn v-can="'vehicles:create'" color="primary" prepend-icon="mdi-car-battery" size="small" @click="openBatteryDialog()">Add Battery</v-btn>
      </div>
    </div>

    <!-- KPI Row -->
    <v-row dense>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #6366f1 0%, #818cf8 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-car-battery</v-icon><span class="text-caption" style="color:#fff !important">Total Batteries</span></div>
          <p class="text-h4 font-weight-bold" style="color:#fff !important">{{ stats.total || 0 }}</p>
          <p class="text-caption" style="color:#fff !important; opacity: .85">{{ stats.brands || 0 }} brands · {{ stats.by_chemistry ? Object.keys(stats.by_chemistry).length : 0 }} chemistries</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #10b981 0%, #34d399 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-car-connected</v-icon><span class="text-caption" style="color:#fff !important">Installed</span></div>
          <p class="text-h4 font-weight-bold" style="color:#fff !important">{{ stats.installed || 0 }}</p>
          <p class="text-caption" style="color:#fff !important; opacity: .85">{{ stats.in_stock || 0 }} in stock · {{ stats.spare || 0 }} spare · {{ stats.charging || 0 }} charging</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-alert-circle-outline</v-icon><span class="text-caption" style="color:#fff !important">Needs Replacement</span></div>
          <p class="text-h4 font-weight-bold" style="color:#fff !important">{{ stats.needs_replacement || 0 }}</p>
          <p class="text-caption" style="color:#fff !important; opacity: .85">Avg health: {{ stats.avg_health || 0 }}%</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #ef4444 0%, #f87171 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-archive-outline</v-icon><span class="text-caption" style="color:#fff !important">Retired / Scrapped</span></div>
          <p class="text-h4 font-weight-bold" style="color:#fff !important">{{ stats.retired || 0 }}</p>
          <p class="text-caption" style="color:#fff !important; opacity: .85">{{ currencySymbol }}{{ (stats.inventory_value || 0).toFixed(0) }} active inventory value</p>
        </v-card>
      </v-col>
    </v-row>

    <!-- Tabs -->
    <v-card elevation="0" border rounded="lg">
      <v-tabs v-model="tab" color="primary" density="compact">
        <v-tab value="inventory" slider-color="primary"><v-icon size="small" class="mr-2">mdi-car-battery</v-icon> Inventory</v-tab>
        <v-tab value="readings" slider-color="primary"><v-icon size="small" class="mr-2">mdi-chart-line-variant</v-icon> Health Readings</v-tab>
        <v-tab value="movements" slider-color="primary"><v-icon size="small" class="mr-2">mdi-transit-transfer-variant</v-icon> Movements</v-tab>
        <v-tab value="cycles" slider-color="primary"><v-icon size="small" class="mr-2">mdi-battery-charging</v-icon> Charge Cycles</v-tab>
        <v-tab value="replacements" slider-color="primary"><v-icon size="small" class="mr-2">mdi-swap-vertical</v-icon> Replacements</v-tab>
        <v-tab value="analytics" slider-color="primary"><v-icon size="small" class="mr-2">mdi-chart-box-outline</v-icon> Analytics</v-tab>
      </v-tabs>
      <v-divider />

      <v-window v-model="tab">
        <!-- ── Inventory Tab ── -->
        <v-window-item value="inventory" class="pa-4">
          <div class="filter-toolbar">
            <v-select v-model="filterStatus" :items="statusOptions" item-title="label" item-value="value" label="Status" density="compact" variant="outlined" hide-details clearable class="filter-field filter-grow" />
            <v-select v-model="filterChemistry" :items="chemistryOptions" item-title="label" item-value="value" label="Chemistry" density="compact" variant="outlined" hide-details clearable class="filter-field filter-grow" />
            <v-select v-model="filterBrand" :items="catalogBrands" label="Brand" density="compact" variant="outlined" hide-details clearable class="filter-field filter-grow" />
            <v-btn v-if="activeFilterCount" variant="text" color="error" size="small" prepend-icon="mdi-filter-remove-outline" @click="clearFilters">Clear filters ({{ activeFilterCount }})</v-btn>
          </div>

          <v-data-table :headers="batteryHeaders" :items="filteredBatteries" :loading="pending" :search="search" hover items-per-page="15">
            <template #item.serial_number="{ item }">
              <div class="d-flex align-center ga-2">
                <div class="d-flex align-center justify-center" style="width: 32px; height: 32px; border-radius: 8px; background: #eef2ff; flex-shrink: 0">
                  <v-icon size="18" color="primary">mdi-car-battery</v-icon>
                </div>
                <div>
                  <p class="text-body-2 font-weight-medium" style="color: #1e293b">{{ item.serial_number }}</p>
                  <p class="text-caption text-medium-emphasis">{{ item.brand }} {{ item.model }}</p>
                </div>
              </div>
            </template>
            <template #item.voltage="{ item }">
              <span class="text-body-2">{{ item.voltage }}V</span>
              <div v-if="item.capacity_ah" class="text-caption text-medium-emphasis">{{ item.capacity_ah }}Ah</div>
            </template>
            <template #item.chemistry="{ value }">
              <v-chip v-if="value" size="small" variant="tonal" :color="chemistryColor(value)">{{ chemistryLabel(value) }}</v-chip>
            </template>
            <template #item.health_pct="{ value }">
              <div class="d-flex align-center ga-2">
                <div style="width: 70px">
                  <v-progress-linear :model-value="value" :color="healthColor(value)" height="6" rounded />
                </div>
                <span class="text-caption" :style="{ color: healthColor(value) }">{{ value }}%</span>
              </div>
            </template>
            <template #item.condition="{ value }">
              <v-chip size="small" :color="conditionColor(value)" variant="flat">{{ conditionLabel(value) }}</v-chip>
            </template>
            <template #item.status="{ value }">
              <v-chip size="small" :color="statusColor(value)" variant="flat">{{ statusLabel(value) }}</v-chip>
            </template>
            <template #item.vehicle_name="{ item }">
              <span v-if="item.vehicle_name" class="text-body-2">{{ item.vehicle_name }}</span>
              <div v-else class="text-caption text-medium-emphasis">—</div>
              <div v-if="item.vehicle_name" class="text-caption text-medium-emphasis">{{ item.position || '' }}</div>
            </template>
            <template #item.warranty_expiry="{ item }">
              <div v-if="item.warranty_expiry">
                <span class="text-body-2">{{ formatDate(item.warranty_expiry) }}</span>
                <div v-if="item.warranty_days_left" class="text-caption" :style="{ color: item.warranty_days_left < 30 ? '#ef4444' : '#6b7280' }">
                  {{ item.warranty_days_left }} days left
                </div>
              </div>
              <span v-else class="text-caption text-medium-emphasis">—</span>
            </template>
            <template #item.purchase_price="{ value }">{{ value ? `${currencySymbol}${Number(value).toLocaleString()}` : '—' }}</template>
            <template #item.actions="{ item }">
              <div class="d-flex justify-center">
                <v-menu location="bottom end" transition="scale-transition" origin="top end">
                  <template #activator="{ props }">
                    <v-btn v-bind="props" icon="mdi-dots-vertical" size="small" variant="text" color="medium-emphasis" title="Actions" />
                  </template>
                  <v-list density="compact" class="py-1" min-width="200">
                    <v-list-item prepend-icon="mdi-eye-outline" title="View" @click="viewBattery(item)" />
                    <v-list-item v-can="'vehicles:create'" prepend-icon="mdi-plus-circle-outline" title="Record Reading" @click="openReadingDialog(item)" />
                    <v-list-item v-if="item.status === 'installed'" prepend-icon="mdi-arrow-down-bold-hexagon-outline" title="Uninstall" @click="uninstallBattery(item)" />
                    <v-list-item v-else-if="item.status === 'in_stock' || item.status === 'spare' || item.status === 'charging'" prepend-icon="mdi-arrow-up-bold-hexagon-outline" title="Install" @click="openInstallDialog(item)" />
                    <v-list-item v-if="item.status === 'in_stock' || item.status === 'spare'" prepend-icon="mdi-battery-charging" title="Charge" @click="chargeBatteryItem(item)" />
                    <v-list-item v-can="'vehicles:update'" prepend-icon="mdi-pencil-outline" title="Edit" @click="openBatteryDialog(item)" />
                    <v-list-item v-if="item.status !== 'retired' && item.status !== 'scrapped'" prepend-icon="mdi-archive-outline" title="Retire" @click="retireBatteryItem(item)" />
                    <v-divider class="my-1" />
                    <v-list-item v-can="'vehicles:delete'" prepend-icon="mdi-trash-can-outline" title="Delete" base-color="error" @click="deleteBatteryItem(item)" />
                  </v-list>
                </v-menu>
              </div>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-car-battery</v-icon>
                <p>No batteries yet. Click "Add Battery" to start tracking.</p>
              </div>
            </template>
          </v-data-table>
        </v-window-item>

        <!-- ── Health Readings Tab ── -->
        <v-window-item value="readings" class="pa-4">
          <div class="d-flex justify-space-between align-center mb-3">
            <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">Voltage & Health Tests</h3>
            <v-btn v-can="'vehicles:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="openReadingDialog()">Record Reading</v-btn>
          </div>
          <v-data-table :headers="readingHeaders" :items="readings" :loading="readingsPending" hover items-per-page="15">
            <template #item.battery="{ item }">
              <span class="text-body-2 font-weight-medium" style="color: #1e293b">{{ item.battery_serial || `#${item.battery}` }}</span>
            </template>
            <template #item.vehicle="{ item }">
              <span v-if="item.vehicle_name">{{ item.vehicle_name }}</span>
              <span v-else-if="item.vehicle">Vehicle #{{ item.vehicle }}</span>
              <span v-else class="text-caption text-medium-emphasis">—</span>
            </template>
            <template #item.voltage="{ value }">
              <span :style="{ color: voltageColor(value) }" class="font-weight-medium">{{ value }}V</span>
            </template>
            <template #item.health_pct="{ value }">
              <v-chip size="small" :color="healthColor(value)" variant="flat">{{ value }}%</v-chip>
            </template>
            <template #item.test_result="{ value }">
              <v-chip size="small" :color="testResultColor(value)" variant="flat">{{ testResultLabel(value) }}</v-chip>
            </template>
            <template #item.measured_at="{ value }">{{ formatDate(value) }}</template>
            <template #item.actions="{ item }">
              <div class="d-flex ga-1">
                <v-btn v-can="'vehicles:update'" icon="mdi-pencil-outline" size="x-small" variant="text" color="warning" @click="openReadingDialog(item)" />
                <v-btn v-can="'vehicles:delete'" icon="mdi-trash-can-outline" size="x-small" variant="text" color="error" @click="deleteReadingItem(item)" />
              </div>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis"><v-icon size="48" class="mb-3">mdi-chart-line-variant</v-icon><p>No readings recorded yet.</p></div>
            </template>
          </v-data-table>
        </v-window-item>

        <!-- ── Movements Tab ── -->
        <v-window-item value="movements" class="pa-4">
          <h3 class="text-subtitle-1 font-weight-bold mb-3" style="color: #1e293b">Install / Uninstall / Charge / Retire Log</h3>
          <v-data-table :headers="movementHeaders" :items="movements" :loading="movementsPending" hover items-per-page="15">
            <template #item.battery="{ item }">
              <span class="text-body-2 font-weight-medium">{{ item.battery_serial || `#${item.battery}` }}</span>
            </template>
            <template #item.movement_type="{ value }">
              <v-chip :color="movementColor(value)" variant="flat" size="small">{{ movementLabel(value) }}</v-chip>
            </template>
            <template #item.from_vehicle="{ item }">
              <span v-if="item.from_vehicle_name">{{ item.from_vehicle_name }}</span>
              <span v-else class="text-caption text-medium-emphasis">—</span>
            </template>
            <template #item.to_vehicle="{ item }">
              <span v-if="item.to_vehicle_name">{{ item.to_vehicle_name }}</span>
              <span v-else class="text-caption text-medium-emphasis">—</span>
            </template>
            <template #item.performed_at="{ value }">{{ formatDate(value) }}</template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis"><v-icon size="48" class="mb-3">mdi-transit-transfer-variant</v-icon><p>No movements recorded yet.</p></div>
            </template>
          </v-data-table>
        </v-window-item>

        <!-- ── Charge Cycles Tab ── -->
        <v-window-item value="cycles" class="pa-4">
          <div class="d-flex justify-space-between align-center mb-3">
            <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">Charge Cycle History</h3>
            <v-btn v-can="'vehicles:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="openCycleDialog()">Record Cycle</v-btn>
          </div>
          <v-data-table :headers="cycleHeaders" :items="cyclesList" :loading="cyclesPending" hover items-per-page="15">
            <template #item.battery="{ item }">
              <span class="text-body-2 font-weight-medium">{{ item.battery_serial || `#${item.battery}` }}</span>
            </template>
            <template #item.charge_method="{ value }">
              <v-chip size="small" variant="tonal" color="info">{{ chargeMethodLabel(value) }}</v-chip>
            </template>
            <template #item.completed_at="{ value }">{{ value ? formatDate(value) : '—' }}</template>
            <template #item.energy_kwh="{ value }">{{ value != null ? `${value} kWh` : '—' }}</template>
            <template #item.actions="{ item }">
              <div class="d-flex ga-1">
                <v-btn v-can="'vehicles:update'" icon="mdi-pencil-outline" size="x-small" variant="text" color="warning" @click="openCycleDialog(item)" />
                <v-btn v-can="'vehicles:delete'" icon="mdi-trash-can-outline" size="x-small" variant="text" color="error" @click="deleteCycleItem(item)" />
              </div>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis"><v-icon size="48" class="mb-3">mdi-battery-charging</v-icon><p>No charge cycles recorded yet.</p></div>
            </template>
          </v-data-table>
        </v-window-item>

        <!-- ── Replacements Tab ── -->
        <v-window-item value="replacements" class="pa-4">
          <div class="d-flex justify-space-between align-center mb-3">
            <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">Battery Replacement Records</h3>
            <v-btn v-can="'vehicles:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="openReplacementDialog()">Schedule Replacement</v-btn>
          </div>
          <v-data-table :headers="replacementHeaders" :items="replacements" :loading="replacementsPending" hover items-per-page="15">
            <template #item.battery="{ item }">
              <span class="text-body-2 font-weight-medium">{{ item.battery_serial || `#${item.battery}` }}</span>
            </template>
            <template #item.vehicle="{ item }">
              <span v-if="item.vehicle_name">{{ item.vehicle_name }}</span>
              <span v-else class="text-caption text-medium-emphasis">—</span>
            </template>
            <template #item.status="{ value }">
              <v-chip size="small" :color="replacementStatusColor(value)" variant="flat">{{ value }}</v-chip>
            </template>
            <template #item.scheduled_date="{ value }">{{ value ? formatDate(value) : '—' }}</template>
            <template #item.completed_date="{ value }">{{ value ? formatDate(value) : '—' }}</template>
            <template #item.estimated_cost="{ value }">{{ value != null ? `${currencySymbol}${Number(value).toLocaleString()}` : '—' }}</template>
            <template #item.actions="{ item }">
              <div class="d-flex ga-1">
                <v-btn v-can="'vehicles:update'" icon="mdi-pencil-outline" size="x-small" variant="text" color="warning" @click="openReplacementDialog(item)" />
                <v-btn v-can="'vehicles:delete'" icon="mdi-trash-can-outline" size="x-small" variant="text" color="error" @click="deleteReplacementItem(item)" />
              </div>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis"><v-icon size="48" class="mb-3">mdi-swap-vertical</v-icon><p>No replacements recorded yet.</p></div>
            </template>
          </v-data-table>
        </v-window-item>

        <!-- ── Analytics Tab ── -->
        <v-window-item value="analytics" class="pa-4">
          <v-row>
            <v-col cols="12" md="6">
              <v-card elevation="0" border rounded="lg" class="pa-4">
                <h3 class="text-subtitle-1 font-weight-bold mb-3" style="color: #1e293b">By Chemistry</h3>
                <div v-if="stats.by_chemistry">
                  <div v-for="(count, chem) in stats.by_chemistry" :key="chem" class="d-flex align-center justify-space-between mb-2">
                    <v-chip size="small" variant="tonal" :color="chemistryColor(chem as string)">{{ chem }}</v-chip>
                    <span class="text-body-2 font-weight-medium">{{ count }}</span>
                    <div style="width: 120px">
                      <v-progress-linear :model-value="(count / Math.max(stats.total, 1)) * 100" :color="chemistryColor(chem as string)" height="6" rounded />
                    </div>
                  </div>
                </div>
                <div v-else class="text-center text-medium-emphasis py-4">No data</div>
              </v-card>
            </v-col>
            <v-col cols="12" md="6">
              <v-card elevation="0" border rounded="lg" class="pa-4">
                <h3 class="text-subtitle-1 font-weight-bold mb-3" style="color: #1e293b">By Condition</h3>
                <div v-if="stats.by_condition">
                  <div v-for="(count, cond) in stats.by_condition" :key="cond" class="d-flex align-center justify-space-between mb-2">
                    <v-chip size="small" :color="conditionColor(cond as string)" variant="flat">{{ cond }}</v-chip>
                    <span class="text-body-2 font-weight-medium">{{ count }}</span>
                    <div style="width: 120px">
                      <v-progress-linear :model-value="stats.total ? (count / stats.total) * 100 : 0" :color="conditionColor(cond as string)" height="6" rounded />
                    </div>
                  </div>
                </div>
                <div v-else class="text-center text-medium-emphasis py-4">No data</div>
              </v-card>
            </v-col>
          </v-row>
        </v-window-item>
      </v-window>
    </v-card>

    <!-- ── Battery Add/Edit Dialog ── -->
    <v-dialog v-model="batteryDialog" max-width="700" scrollable>
      <v-card rounded="lg">
        <v-card-title class="d-flex align-center ga-2">
          <v-icon color="primary">mdi-car-battery</v-icon>
          <span class="text-h6">{{ editingBattery ? 'Edit' : 'Add' }} Battery</span>
          <v-spacer />
          <v-btn icon="mdi-close" variant="text" size="small" @click="batteryDialog = false" />
        </v-card-title>
        <v-divider />
        <v-card-text class="pa-4">
          <v-row dense>
            <v-col cols="12" md="6">
              <v-text-field v-model="batteryForm.serial_number" label="Serial Number *" prepend-inner-icon="mdi-barcode" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="batteryForm.part_number" label="Part Number / SKU" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="12" md="6">
              <v-combobox v-model="batteryForm.brand" :items="catalogBrands" label="Brand" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="batteryForm.model" label="Model" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="12" md="4">
              <v-select v-model="batteryForm.chemistry" :items="chemistryOptions" item-title="label" item-value="value" label="Chemistry" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="4">
              <v-text-field v-model.number="batteryForm.voltage" type="number" label="Voltage (V)" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="4">
              <v-text-field v-model.number="batteryForm.capacity_ah" type="number" label="Capacity (Ah)" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="4">
              <v-text-field v-model.number="batteryForm.cca" type="number" label="CCA" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="4">
              <v-text-field v-model.number="batteryForm.rc_minutes" type="number" label="Reserve Cap (min)" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="4">
              <v-text-field v-model="batteryForm.group_code" label="BCI Group Code" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="4">
              <v-text-field v-model.number="batteryForm.weight_kg" type="number" label="Weight (kg)" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="12" md="6">
              <v-select v-model="batteryForm.condition" :items="conditionOptions" item-title="label" item-value="value" label="Condition" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="12" md="6">
              <v-select v-model="batteryForm.status" :items="statusOptions" item-title="label" item-value="value" label="Status" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="batteryForm.position" label="Position" placeholder="Starter, Aux-1, House..." density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="3">
              <v-text-field v-model="batteryForm.purchase_date" type="date" label="Purchase Date" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="3">
              <v-text-field v-model.number="batteryForm.purchase_price" type="number" label="Purchase Price" density="compact" variant="outlined" hide-details prefix="$" />
            </v-col>
            <v-col cols="6" md="3">
              <v-text-field v-model.number="batteryForm.warranty_months" type="number" label="Warranty (months)" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="3">
              <v-text-field v-model="batteryForm.warranty_expiry" type="date" label="Warranty Expiry" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="3">
              <v-text-field v-model.number="batteryForm.expected_lifespan_months" type="number" label="Expected Life (months)" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="12">
              <v-textarea v-model="batteryForm.notes" label="Notes" density="compact" variant="outlined" hide-details rows="2" />
            </v-col>
          </v-row>
        </v-card-text>
        <v-divider />
        <v-card-actions class="pa-4">
          <v-spacer />
          <v-btn variant="text" @click="batteryDialog = false">Cancel</v-btn>
          <v-btn color="primary" prepend-icon="mdi-content-save" :loading="saving" @click="saveBatteryItem">{{ editingBattery ? 'Save' : 'Create' }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- ── Reading Dialog ── -->
    <v-dialog v-model="readingDialog" max-width="600" scrollable>
      <v-card rounded="lg">
        <v-card-title class="d-flex align-center ga-2">
          <v-icon color="primary">mdi-chart-line-variant</v-icon>
          <span class="text-h6">{{ editingReading ? 'Edit' : 'Record' }} Battery Reading</span>
          <v-spacer />
          <v-btn icon="mdi-close" variant="text" size="small" @click="readingDialog = false" />
        </v-card-title>
        <v-divider />
        <v-card-text class="pa-4">
          <v-row dense>
            <v-col cols="12">
              <v-autocomplete v-model="readingForm.battery" :items="batteryOptions" item-title="label" item-value="value" label="Battery *" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="3">
              <v-text-field v-model="readingForm.measured_at" type="date" label="Date *" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="3">
              <v-text-field v-model.number="readingForm.voltage" type="number" step="0.01" label="Voltage (V) *" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="3">
              <v-text-field v-model.number="readingForm.specific_gravity" type="number" step="0.001" label="Specific Gravity" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="3">
              <v-text-field v-model.number="readingForm.internal_resistance" type="number" step="0.1" label="Resistance (mΩ)" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="3">
              <v-text-field v-model.number="readingForm.temperature_c" type="number" step="0.1" label="Temp (°C)" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="3">
              <v-text-field v-model.number="readingForm.soc_pct" type="number" step="0.1" label="SOC (%)" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="6">
              <v-select v-model="readingForm.test_result" :items="testResultOptions" item-title="label" item-value="value" label="Test Result" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="12">
              <v-textarea v-model="readingForm.notes" label="Notes" density="compact" variant="outlined" hide-details rows="2" />
            </v-col>
          </v-row>
        </v-card-text>
        <v-divider />
        <v-card-actions class="pa-4">
          <v-spacer />
          <v-btn variant="text" @click="readingDialog = false">Cancel</v-btn>
          <v-btn color="primary" prepend-icon="mdi-content-save" :loading="saving" @click="saveReadingItem">{{ editingReading ? 'Save' : 'Record' }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- ── Install Dialog ── -->
    <v-dialog v-model="installDialog" max-width="500">
      <v-card rounded="lg">
        <v-card-title class="d-flex align-center ga-2">
          <v-icon color="success">mdi-arrow-up-bold-hexagon-outline</v-icon>
          <span class="text-h6">Install Battery</span>
          <v-spacer />
          <v-btn icon="mdi-close" variant="text" size="small" @click="installDialog = false" />
        </v-card-title>
        <v-divider />
        <v-card-text class="pa-4">
          <p class="text-body-2 mb-3">Installing <b>{{ installBatteryItem?.serial_number }}</b> into a vehicle.</p>
          <v-alert v-if="selectedVehicleHasBattery && !installForm.allowAdditional" type="warning" density="compact" variant="tonal" class="mb-3">
            This vehicle already has a battery installed. Please uninstall it first or choose “Add Another” to install alongside.
          </v-alert>
          <v-alert v-if="selectedVehicleHasBattery && installForm.allowAdditional" type="info" density="compact" variant="tonal" class="mb-3">
            Installing an additional battery alongside the existing one. Use a different position (e.g. Aux, House).
          </v-alert>
          <v-row dense>
            <v-col cols="12">
              <v-autocomplete v-model="installForm.vehicle" :items="vehicleOptions" item-title="label" item-value="value" label="Vehicle *" density="compact" variant="outlined" hide-details return-object>
                <template #item="{ props, item }">
                  <v-list-item v-bind="props" :disabled="item.raw.disabled">
                    <template v-if="item.raw.existingBattery" #append>
                      <v-chip size="x-small" color="warning" variant="tonal">Battery installed</v-chip>
                    </template>
                  </v-list-item>
                </template>
              </v-autocomplete>
            </v-col>
            <v-col v-if="selectedVehicleHasBattery && !installForm.allowAdditional" cols="12" class="d-flex ga-2">
              <v-btn size="small" variant="outlined" color="warning" prepend-icon="mdi-arrow-down-bold-hexagon-outline" :loading="saving" @click="uninstallExistingBattery(selectedVehicleExistingBattery)">Uninstall Existing</v-btn>
              <v-btn size="small" variant="outlined" color="info" prepend-icon="mdi-battery-plus" @click="addAnotherBattery">Add Another</v-btn>
            </v-col>
            <v-col cols="12" md="8">
              <v-text-field v-model="installForm.position" label="Position" placeholder="Starter, Aux, House..." density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="12" md="4">
              <v-text-field v-model="installForm.performed_at" type="date" label="Date" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="12">
              <v-text-field v-model="installForm.notes" label="Notes" density="compact" variant="outlined" hide-details />
            </v-col>
          </v-row>
        </v-card-text>
        <v-divider />
        <v-card-actions class="pa-4">
          <v-spacer />
          <v-btn variant="text" @click="installDialog = false">Cancel</v-btn>
          <v-btn color="success" prepend-icon="mdi-check" :loading="saving" :disabled="!installForm.vehicle || (selectedVehicleHasBattery && !installForm.allowAdditional)" @click="confirmInstall">Install</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- ── Cycle Dialog ── -->
    <v-dialog v-model="cycleDialog" max-width="600" scrollable>
      <v-card rounded="lg">
        <v-card-title class="d-flex align-center ga-2">
          <v-icon color="primary">mdi-battery-charging</v-icon>
          <span class="text-h6">{{ editingCycle ? 'Edit' : 'Record' }} Charge Cycle</span>
          <v-spacer />
          <v-btn icon="mdi-close" variant="text" size="small" @click="cycleDialog = false" />
        </v-card-title>
        <v-divider />
        <v-card-text class="pa-4">
          <v-row dense>
            <v-col cols="12">
              <v-autocomplete v-model="cycleForm.battery" :items="batteryOptions" item-title="label" item-value="value" label="Battery *" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="6">
              <v-text-field v-model="cycleForm.started_at" type="datetime-local" label="Started At" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="6">
              <v-text-field v-model="cycleForm.completed_at" type="datetime-local" label="Completed At" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="4">
              <v-text-field v-model.number="cycleForm.start_voltage" type="number" step="0.01" label="Start V" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="4">
              <v-text-field v-model.number="cycleForm.end_voltage" type="number" step="0.01" label="End V" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="4">
              <v-text-field v-model.number="cycleForm.energy_kwh" type="number" step="0.01" label="Energy (kWh)" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="12" md="6">
              <v-select v-model="cycleForm.charge_method" :items="chargeMethodOptions" item-title="label" item-value="value" label="Charge Method" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="12">
              <v-text-field v-model="cycleForm.notes" label="Notes" density="compact" variant="outlined" hide-details />
            </v-col>
          </v-row>
        </v-card-text>
        <v-divider />
        <v-card-actions class="pa-4">
          <v-spacer />
          <v-btn variant="text" @click="cycleDialog = false">Cancel</v-btn>
          <v-btn color="primary" prepend-icon="mdi-content-save" :loading="saving" @click="saveCycleItem">{{ editingCycle ? 'Save' : 'Record' }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- ── Replacement Dialog ── -->
    <v-dialog v-model="replacementDialog" max-width="600" scrollable>
      <v-card rounded="lg">
        <v-card-title class="d-flex align-center ga-2">
          <v-icon color="primary">mdi-swap-vertical</v-icon>
          <span class="text-h6">{{ editingReplacement ? 'Edit' : 'Schedule' }} Replacement</span>
          <v-spacer />
          <v-btn icon="mdi-close" variant="text" size="small" @click="replacementDialog = false" />
        </v-card-title>
        <v-divider />
        <v-card-text class="pa-4">
          <v-row dense>
            <v-col cols="12">
              <v-autocomplete v-model="replacementForm.battery" :items="batteryOptions" item-title="label" item-value="value" label="Battery *" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="6">
              <v-text-field v-model="replacementForm.scheduled_date" type="date" label="Scheduled Date" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="6">
              <v-text-field v-model="replacementForm.completed_date" type="date" label="Completed Date" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="4">
              <v-select v-model="replacementForm.status" :items="replacementStatusOptions" label="Status" density="compact" variant="outlined" hide-details />
            </v-col>
            <v-col cols="6" md="8">
              <v-text-field v-model.number="replacementForm.estimated_cost" type="number" label="Estimated Cost" density="compact" variant="outlined" hide-details prefix="$" />
            </v-col>
            <v-col cols="12">
              <v-textarea v-model="replacementForm.reason" label="Reason" density="compact" variant="outlined" hide-details rows="2" />
            </v-col>
            <v-col cols="12">
              <v-text-field v-model="replacementForm.notes" label="Notes" density="compact" variant="outlined" hide-details />
            </v-col>
          </v-row>
        </v-card-text>
        <v-divider />
        <v-card-actions class="pa-4">
          <v-spacer />
          <v-btn variant="text" @click="replacementDialog = false">Cancel</v-btn>
          <v-btn color="primary" prepend-icon="mdi-content-save" :loading="saving" @click="saveReplacementItem">{{ editingReplacement ? 'Save' : 'Schedule' }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- ── View Detail Dialog ── -->
    <v-dialog v-model="viewDialog" max-width="700" scrollable>
      <v-card rounded="lg">
        <v-card-title class="d-flex align-center ga-2">
          <v-icon color="primary">mdi-car-battery</v-icon>
          <span class="text-h6">{{ viewItem?.serial_number }}</span>
          <v-spacer />
          <v-btn icon="mdi-close" variant="text" size="small" @click="viewDialog = false" />
        </v-card-title>
        <v-divider />
        <v-card-text class="pa-4" v-if="viewItem">
          <v-row dense>
            <v-col cols="6" md="3"><div class="text-caption text-medium-emphasis">Brand</div><div class="text-body-2 font-weight-medium">{{ viewItem.brand || '—' }}</div></v-col>
            <v-col cols="6" md="3"><div class="text-caption text-medium-emphasis">Model</div><div class="text-body-2 font-weight-medium">{{ viewItem.model || '—' }}</div></v-col>
            <v-col cols="6" md="3"><div class="text-caption text-medium-emphasis">Chemistry</div><div class="text-body-2"><v-chip size="small" variant="tonal" :color="chemistryColor(viewItem.chemistry)">{{ chemistryLabel(viewItem.chemistry) }}</v-chip></div></v-col>
            <v-col cols="6" md="3"><div class="text-caption text-medium-emphasis">Status</div><div><v-chip size="small" :color="statusColor(viewItem.status)" variant="flat">{{ statusLabel(viewItem.status) }}</v-chip></div></v-col>
            <v-col cols="6" md="3"><div class="text-caption text-medium-emphasis">Condition</div><div><v-chip size="small" :color="conditionColor(viewItem.condition)" variant="flat">{{ conditionLabel(viewItem.condition) }}</v-chip></div></v-col>
            <v-col cols="6" md="3"><div class="text-caption text-medium-emphasis">Voltage</div><div class="text-body-2">{{ viewItem.voltage }}V</div></v-col>
            <v-col cols="6" md="3"><div class="text-caption text-medium-emphasis">Capacity</div><div class="text-body-2">{{ viewItem.capacity_ah || '—' }} Ah</div></v-col>
            <v-col cols="6" md="3"><div class="text-caption text-medium-emphasis">CCA</div><div class="text-body-2">{{ viewItem.cca || '—' }}</div></v-col>
            <v-col cols="6" md="3"><div class="text-caption text-medium-emphasis">Health</div><div class="d-flex align-center ga-1"><v-progress-linear :model-value="viewItem.health_pct" :color="healthColor(viewItem.health_pct)" height="6" rounded style="width: 70px" /><span :style="{ color: healthColor(viewItem.health_pct) }">{{ viewItem.health_pct }}%</span></div></v-col>
            <v-col cols="6" md="3"><div class="text-caption text-medium-emphasis">Vehicle</div><div class="text-body-2">{{ viewItem.vehicle_name || '—' }}</div></v-col>
            <v-col cols="6" md="3"><div class="text-caption text-medium-emphasis">Position</div><div class="text-body-2">{{ viewItem.position || '—' }}</div></v-col>
            <v-col cols="6" md="3"><div class="text-caption text-medium-emphasis">Purchase Price</div><div class="text-body-2">{{ viewItem.purchase_price ? `${currencySymbol}${Number(viewItem.purchase_price).toLocaleString()}` : '—' }}</div></v-col>
            <v-col cols="6" md="3"><div class="text-caption text-medium-emphasis">Purchase Date</div><div class="text-body-2">{{ formatDate(viewItem.purchase_date) }}</div></v-col>
            <v-col cols="6" md="3"><div class="text-caption text-medium-emphasis">Warranty Expiry</div><div class="text-body-2">{{ formatDate(viewItem.warranty_expiry) }}</div></v-col>
            <v-col cols="6" md="3"><div class="text-caption text-medium-emphasis">Last Voltage</div><div class="text-body-2">{{ viewItem.last_voltage != null ? viewItem.last_voltage + 'V' : '—' }}</div></v-col>
            <v-col cols="6" md="3"><div class="text-caption text-medium-emphasis">Cycle Count</div><div class="text-body-2">{{ viewItem.cycle_count }}</div></v-col>
            <v-col cols="12"><div class="text-caption text-medium-emphasis">Notes</div><div class="text-body-2">{{ viewItem.notes || '—' }}</div></v-col>
          </v-row>
        </v-card-text>
      </v-card>
    </v-dialog>

    <!-- ── Snack bar ── -->
    <v-snackbar v-model="snack" :color="snackColor" timeout="3000">{{ snackText }}</v-snackbar>
    <v-dialog v-model="confirmDialog" max-width="400">
      <v-card rounded="lg">
        <v-card-title>{{ confirmTitle }}</v-card-title>
        <v-card-text>{{ confirmMessage }}</v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn variant="text" @click="confirmDialog = false">Cancel</v-btn>
          <v-btn :color="confirmColor" variant="tonal" @click="executeConfirm">Confirm</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { useBatteryApi } from '~/composables/useBatteryApi'
import { useCurrency } from '~/composables/useCurrency'

definePageMeta({ layout: 'default' })

const api = useBatteryApi()
const { symbol: currencySymbol } = useCurrency()

// ── State ──
const tab = ref('inventory')
const search = ref('')
const snack = ref(false)
const snackText = ref('')
const snackColor = ref('success')
const saving = ref(false)

const filterStatus = ref(null)
const filterChemistry = ref(null)
const filterBrand = ref(null)

// ── Data fetch ──
const { data: batteryData, pending, refresh: refreshBatteryData } = await useAsyncData('batteries-list', () => api.fetchBatteries())
const { data: statsData, refresh: refreshStats } = await useAsyncData('batteries-stats', () => api.fetchStats())
const { data: catalog } = await useAsyncData('batteries-catalog', () => api.fetchCatalog())
const { data: readingsData, pending: readingsPending, refresh: refreshReadings } = await useAsyncData('batteries-readings', () => api.fetchReadings())
const { data: movementsData, pending: movementsPending } = await useAsyncData('batteries-movements', () => api.fetchMovements())
const { data: cyclesData, pending: cyclesPending, refresh: refreshCycles } = await useAsyncData('batteries-cycles', () => api.fetchCycles())
const { data: replacementsData, pending: replacementsPending, refresh: refreshReplacements } = await useAsyncData('batteries-replacements', () => api.fetchReplacements())
const { data: vehiclesData } = await useAsyncData('batteries-vehicles', () => useNuxtApp().$api('/vehicles/vehicles/'))

// Unwrap paginated responses
const batteries = computed(() => batteryData.value?.results || batteryData.value || [])
const readings = computed(() => readingsData.value?.results || readingsData.value || [])
const movements = computed(() => movementsData.value?.results || movementsData.value || [])
const cyclesList = computed(() => cyclesData.value?.results || cyclesData.value || [])
const replacements = computed(() => replacementsData.value?.results || replacementsData.value || [])
const stats = computed(() => statsData.value || {})

function showSnack(text: string, color = 'success') {
  snackText.value = text
  snackColor.value = color
  snack.value = true
}

// ── Options ──
const statusOptions = [
  { label: 'In Stock', value: 'in_stock', color: '#10b981' },
  { label: 'Installed', value: 'installed', color: '#3b82f6' },
  { label: 'Spare', value: 'spare', color: '#f59e0b' },
  { label: 'Charging', value: 'charging', color: '#8b5cf6' },
  { label: 'Retired', value: 'retired', color: '#ef4444' },
  { label: 'Scrapped', value: 'scrapped', color: '#6b7280' },
]
const conditionOptions = [
  { label: 'New', value: 'new', color: '#10b981' },
  { label: 'Excellent', value: 'excellent', color: '#22c55e' },
  { label: 'Good', value: 'good', color: '#84cc16' },
  { label: 'Fair', value: 'fair', color: '#f59e0b' },
  { label: 'Poor', value: 'poor', color: '#ef4444' },
  { label: 'Damaged', value: 'damaged', color: '#dc2626' },
]
const chemistryOptions = [
  { label: 'Lead-Acid', value: 'lead_acid' },
  { label: 'AGM', value: 'agm' },
  { label: 'Gel', value: 'gel' },
  { label: 'Lithium-Ion', value: 'li_ion' },
  { label: 'LiFePO4', value: 'lifepo4' },
  { label: 'NiCd', value: 'nicd' },
  { label: 'NiMH', value: 'nimh' },
]
const testResultOptions = [
  { label: 'Pass', value: 'pass' },
  { label: 'Marginal', value: 'marginal' },
  { label: 'Fail', value: 'fail' },
  { label: 'Charge and Retest', value: 'charge' },
]
const chargeMethodOptions = [
  { label: 'AC', value: 'ac' },
  { label: 'DC', value: 'dc' },
  { label: 'Regen', value: 'regen' },
  { label: 'Alternator', value: 'alternator' },
  { label: 'Solar', value: 'solar' },
]
const replacementStatusOptions = ['Scheduled', 'Ordered', 'Completed', 'Cancelled']

const catalogBrands = computed(() => (catalog.value as any)?.brands || [])
const batteryOptions = computed(() => (batteries.value as any[] || []).map((b: any) => ({ label: `${b.serial_number} – ${b.brand}`, value: b.id })))

// Vehicles that already have a battery installed — these are disabled in the Install dialog
const installedVehicleIds = computed(() => {
  const list = batteries.value as any[] || []
  return new Set(list.filter((b) => b.status === 'installed' && b.vehicle).map((b) => b.vehicle))
})
const vehicleOptions = computed(() => ((vehiclesData.value?.results || vehiclesData.value || []) as any[]).map((v: any) => {
  const existingBattery = (batteries.value as any[] || []).find((b) => b.status === 'installed' && b.vehicle === v.id)
  return {
    label: `${v.display_name || v.license_plate || `#${v.id}`}`,
    value: v.id,
    disabled: false,
    existingBattery: existingBattery ? { id: existingBattery.id, serial_number: existingBattery.serial_number } : null,
  }
}))
const selectedVehicleHasBattery = computed(() => {
  if (!installForm.vehicle) return false
  const vid = typeof installForm.vehicle === 'object' ? installForm.vehicle?.value : installForm.vehicle
  return installedVehicleIds.value.has(vid)
})
const selectedVehicleExistingBattery = computed(() => {
  if (!installForm.vehicle) return null
  const vid = typeof installForm.vehicle === 'object' ? installForm.vehicle?.value : installForm.vehicle
  const arr = batteries.value as any[] || []
  return arr.find((b) => b.status === 'installed' && b.vehicle === vid) || null
})

// ── Tables ──
const batteryHeaders = [
  { title: '#', key: 'index', sortable: false, width: 40 },
  { title: 'Serial', key: 'serial_number', sortable: true },
  { title: 'Voltage', key: 'voltage', sortable: true },
  { title: 'Chemistry', key: 'chemistry', sortable: true },
  { title: 'Health', key: 'health_pct', sortable: true },
  { title: 'Condition', key: 'condition', sortable: true },
  { title: 'Status', key: 'status', sortable: true },
  { title: 'Vehicle', key: 'vehicle_name', sortable: false },
  { title: 'Warranty', key: 'warranty_expiry', sortable: true },
  { title: 'Price', key: 'purchase_price', sortable: true },
  { title: '', key: 'actions', sortable: false, width: 50, align: 'center' },
]
const readingHeaders = [
  { title: 'Battery', key: 'battery', sortable: false },
  { title: 'Vehicle', key: 'vehicle', sortable: false },
  { title: 'Date', key: 'measured_at', sortable: true },
  { title: 'Voltage', key: 'voltage', sortable: true },
  { title: 'Health', key: 'health_pct', sortable: true },
  { title: 'S.G.', key: 'specific_gravity' },
  { title: 'Result', key: 'test_result', sortable: true },
  { title: '', key: 'actions', sortable: false, width: 50 },
]
const movementHeaders = [
  { title: 'Battery', key: 'battery', sortable: false },
  { title: 'Type', key: 'movement_type', sortable: true },
  { title: 'From', key: 'from_vehicle', sortable: false },
  { title: 'To', key: 'to_vehicle', sortable: false },
  { title: 'Date', key: 'performed_at', sortable: true },
  { title: 'Notes', key: 'notes' },
]
const cycleHeaders = [
  { title: 'Battery', key: 'battery', sortable: false },
  { title: 'Method', key: 'charge_method', sortable: true },
  { title: 'Completed', key: 'completed_at', sortable: true },
  { title: 'Start V', key: 'start_voltage' },
  { title: 'End V', key: 'end_voltage' },
  { title: 'Energy', key: 'energy_kwh' },
  { title: '', key: 'actions', sortable: false, width: 50 },
]
const replacementHeaders = [
  { title: 'Battery', key: 'battery', sortable: false },
  { title: 'Vehicle', key: 'vehicle', sortable: false },
  { title: 'Scheduled', key: 'scheduled_date', sortable: true },
  { title: 'Completed', key: 'completed_date', sortable: true },
  { title: 'Cost', key: 'estimated_cost', sortable: true },
  { title: 'Reason', key: 'reason' },
  { title: 'Status', key: 'status', sortable: true },
  { title: '', key: 'actions', sortable: false, width: 50 },
]

// ── Computed ──
const filteredBatteries = computed(() => {
  const list = batteries.value as any[]
  if (!list || !Array.isArray(list)) return []
  return list.filter((b) => {
    if (filterStatus.value && b.status !== filterStatus.value) return false
    if (filterChemistry.value && b.chemistry !== filterChemistry.value) return false
    if (filterBrand.value && b.brand !== filterBrand.value) return false
    return true
  })
})
const activeFilterCount = computed(() => (filterStatus.value ? 1 : 0) + (filterChemistry.value ? 1 : 0) + (filterBrand.value ? 1 : 0))
function clearFilters() { filterStatus.value = null; filterChemistry.value = null; filterBrand.value = null }

// ── Helpers ──
function statusColor(v: string) { return statusOptions.find(s => s.value === v)?.color || '#6b7280' }
function statusLabel(v: string) { return statusOptions.find(s => s.value === v)?.label || v }
function conditionColor(v: string) { return conditionOptions.find(c => c.value === v)?.color || '#6b7280' }
function conditionLabel(v: string) { return conditionOptions.find(c => c.value === v)?.label || v }
function chemistryColor(v: string) {
  const m: Record<string, string> = { lead_acid: '#6366f1', agm: '#3b82f6', gel: '#8b5cf6', li_ion: '#10b981', lifepo4: '#22c55e', nicd: '#f59e0b', nimh: '#ec4899' }
  return m[v] || '#6b7280'
}
function chemistryLabel(v: string) { return chemistryOptions.find(c => c.value === v)?.label || v }
function healthColor(v: number) { if (v >= 80) return '#10b981'; if (v >= 60) return '#f59e0b'; return '#ef4444' }
function voltageColor(v: number) { if (v >= 12.5) return '#10b981'; if (v >= 12.0) return '#f59e0b'; return '#ef4444' }
function testResultColor(v: string) { const m: Record<string, string> = { pass: '#10b981', marginal: '#f59e0b', fail: '#ef4444', charge: '#3b82f6' }; return m[v] || '#6b7280' }
function testResultLabel(v: string) { return testResultOptions.find(t => t.value === v)?.label || v }
function movementColor(v: string) { const m: Record<string, string> = { install: '#10b981', uninstall: '#f59e0b', swap: '#3b82f6', charge: '#8b5cf6', retire: '#ef4444' }; return m[v] || '#6b7280' }
function movementLabel(v: string) { return v ? v.charAt(0).toUpperCase() + v.slice(1) : '' }
function chargeMethodLabel(v: string) { return chargeMethodOptions.find(c => c.value === v)?.label || v || '' }
function replacementStatusColor(v: string) { const m: Record<string, string> = { scheduled: '#f59e0b', ordered: '#3b82f6', completed: '#10b981', cancelled: '#ef4444' }; return (v && m[v.toLowerCase()]) || '#6b7280' }
function formatDate(d: any) { if (!d) return '—'; try { return new Date(d).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) } catch { return d } }

// ── Battery dialog ──
const batteryDialog = ref(false)
const editingBattery = ref(false)
const batteryForm = reactive<any>({})
function defaultBatteryForm() {
  return {
    serial_number: '', brand: '', model: '', part_number: '',
    chemistry: 'lead_acid', voltage: 12, capacity_ah: null, cca: null, rc_minutes: null,
    condition: 'new', status: 'in_stock', position: '',
    purchase_price: null, purchase_date: '', warranty_months: null, warranty_expiry: '',
    expected_lifespan_months: null, group_code: '', weight_kg: null, notes: '',
  }
}
function openBatteryDialog(b?: any) {
  if (b) { editingBattery.value = true; Object.assign(batteryForm, b) }
  else { editingBattery.value = false; Object.assign(batteryForm, defaultBatteryForm()) }
  batteryDialog.value = true
}
async function saveBatteryItem() {
  saving.value = true
  try {
    const payload = { ...batteryForm }
    for (const k of ['capacity_ah', 'cca', 'rc_minutes', 'purchase_price', 'weight_kg', 'warranty_months', 'expected_lifespan_months']) {
      if (payload[k] === '' || payload[k] === undefined) payload[k] = null
    }
    for (const k of ['purchase_date', 'warranty_expiry']) {
      if (payload[k] === '') payload[k] = null
    }
    await api.saveBattery(payload, editingBattery.value ? batteryForm.id : undefined)
    batteryDialog.value = false
    showSnack(`Battery ${editingBattery.value ? 'updated' : 'added'} successfully`)
    await refreshBatteries()
  } catch (e: any) {
    showSnack(e?.data?.detail || 'Error saving battery', 'error')
  } finally { saving.value = false }
}
async function refreshBatteries() {
  await refreshBatteryData()
  await refreshStats()
}

// ── Battery actions (confirm) ──
const confirmDialog = ref(false)
const confirmTitle = ref('')
const confirmMessage = ref('')
const confirmColor = ref('error')
const confirmCallback = ref<() => void>(() => {})
function openConfirm(title: string, msg: string, color = 'error', cb: () => void) {
  confirmTitle.value = title; confirmMessage.value = msg; confirmColor.value = color; confirmCallback.value = cb
  confirmDialog.value = true
}
function executeConfirm() { confirmDialog.value = false; confirmCallback.value() }

async function unlockBattery(b: any) {
  try { await api.uninstallBattery(b.id); showSnack('Battery uninstalled'); await refreshBatteries() }
  catch (e: any) { showSnack('Error uninstalling', 'error') }
}
function uninstallBattery(b: any) {
  openConfirm('Uninstall Battery', `Uninstall ${b.serial_number} from vehicle?`, 'warning', () => unlockBattery(b))
}
function retireBatteryItem(b: any) {
  openConfirm('Retire Battery', `Retire ${b.serial_number}? This will remove it from vehicle.`, 'error', async () => {
    try { await api.retireBattery(b.id); showSnack('Battery retired'); await refreshBatteries() }
    catch (e: any) { showSnack('Error retiring', 'error') }
  })
}
function deleteBatteryItem(b: any) {
  openConfirm('Delete Battery', `Delete ${b.serial_number}? This cannot be undone.`, 'error', async () => {
    try { await api.deleteBattery(b.id); showSnack('Battery deleted'); await refreshBatteries() }
    catch (e: any) { showSnack('Error deleting', 'error') }
  })
}
async function chargeBatteryItem(b: any) {
  try { await api.chargeBattery(b.id); showSnack('Battery set to charging'); await refreshBatteries() }
  catch (e: any) { showSnack('Error', 'error') }
}

// ── Install dialog ──
const installDialog = ref(false)
const installBatteryItem = ref<any>(null)
const installForm = reactive<any>({ vehicle: null, position: '', performed_at: new Date().toISOString().split('T')[0], notes: '', allowAdditional: false })
function openInstallDialog(b: any) {
  installBatteryItem.value = b
  installForm.vehicle = null; installForm.position = ''; installForm.notes = ''; installForm.allowAdditional = false
  installDialog.value = true
}
// Uninstall the existing battery from the selected vehicle
async function uninstallExistingBattery(existing: any) {
  if (!existing) return
  openConfirm(
    'Uninstall Existing Battery',
    `Uninstall ${existing.serial_number} from this vehicle? The vehicle will then be available for this install.`,
    'warning',
    async () => {
      saving.value = true
      try {
        await api.uninstallBattery(existing.id)
        showSnack(`Battery ${existing.serial_number} uninstalled`)
        await refreshBatteries()
        // Reset allowAdditional since the vehicle no longer has a battery
        installForm.allowAdditional = false
      } catch (e: any) {
        showSnack(e?.data?.detail || 'Error uninstalling battery', 'error')
      } finally { saving.value = false }
    },
  )
}
// Allow installing an additional battery alongside the existing one
function addAnotherBattery() {
  installForm.allowAdditional = true
  showSnack('Installing an additional battery — please choose a different position', 'info')
}
async function confirmInstall() {
  if (!installBatteryItem.value) return
  if (selectedVehicleHasBattery.value && !installForm.allowAdditional) {
    showSnack('This vehicle already has a battery installed. Please uninstall it first or choose “Add Another”.', 'warning')
    return
  }
  saving.value = true
  try {
    const vehicleId = typeof installForm.vehicle === 'object' ? installForm.vehicle?.value : installForm.vehicle
    await api.installBattery(installBatteryItem.value.id, {
      vehicle: vehicleId,
      position: installForm.position,
      performed_at: installForm.performed_at,
      notes: installForm.notes,
    })
    installDialog.value = false
    showSnack('Battery installed')
    await refreshBatteries()
  } catch (e: any) { showSnack(e?.data?.detail || 'Error installing', 'error') }
  finally { saving.value = false }
}

// ── Reading dialog ──
const readingDialog = ref(false)
const editingReading = ref(false)
const readingForm = reactive<any>({})
function defaultReadingForm() { return { battery: null, measured_at: new Date().toISOString().split('T')[0], voltage: 12.6, specific_gravity: null, internal_resistance: null, temperature_c: null, soc_pct: null, test_result: 'pass', notes: '' } }
function openReadingDialog(r?: any, preBattery?: any) {
  if (r) { editingReading.value = true; Object.assign(readingForm, r) }
  else { editingReading.value = false; Object.assign(readingForm, defaultReadingForm()); if (preBattery) readingForm.battery = preBattery.id }
  readingDialog.value = true
}
async function saveReadingItem() {
  saving.value = true
  try {
    const payload = { ...readingForm }
    for (const k of ['specific_gravity', 'internal_resistance', 'temperature_c', 'soc_pct']) {
      if (payload[k] === '' || payload[k] === undefined) payload[k] = null
    }
    await api.saveReading(payload, editingReading.value ? readingForm.id : undefined)
    readingDialog.value = false
    showSnack('Reading saved')
    await refreshReadings()
    await refreshBatteries()
  } catch (e: any) { showSnack(e?.data?.detail || 'Error', 'error') }
  finally { saving.value = false }
}
function deleteReadingItem(r: any) {
  openConfirm('Delete Reading', 'Delete this reading?', 'error', async () => {
    try { await api.deleteReading(r.id); showSnack('Reading deleted'); await refreshReadings() }
    catch (e: any) { showSnack('Error', 'error') }
  })
}

// ── Cycle dialog ──
const cycleDialog = ref(false)
const editingCycle = ref(false)
const cycleForm = reactive<any>({})
function defaultCycleForm() { return { battery: null, started_at: '', completed_at: '', start_voltage: null, end_voltage: null, energy_kwh: null, charge_method: 'ac', notes: '' } }
function openCycleDialog(c?: any) {
  if (c) { editingCycle.value = true; Object.assign(cycleForm, c) }
  else { editingCycle.value = false; Object.assign(cycleForm, defaultCycleForm()) }
  cycleDialog.value = true
}
async function saveCycleItem() {
  saving.value = true
  try {
    const payload = { ...cycleForm }
    for (const k of ['started_at', 'completed_at', 'start_voltage', 'end_voltage', 'energy_kwh']) {
      if (payload[k] === '' || payload[k] === undefined) payload[k] = null
    }
    await api.saveCycle(payload, editingCycle.value ? cycleForm.id : undefined)
    cycleDialog.value = false
    showSnack('Cycle saved')
    await refreshCycles()
  } catch (e: any) { showSnack('Error', 'error') }
  finally { saving.value = false }
}
function deleteCycleItem(c: any) {
  openConfirm('Delete Cycle', 'Delete this charge cycle?', 'error', async () => {
    try { await api.deleteCycle(c.id); showSnack('Cycle deleted'); await refreshCycles() }
    catch (e: any) { showSnack('Error', 'error') }
  })
}

// ── Replacement dialog ──
const replacementDialog = ref(false)
const editingReplacement = ref(false)
const replacementForm = reactive<any>({})
function defaultReplacementForm() { return { battery: null, vehicle: null, scheduled_date: '', completed_date: '', reason: '', estimated_cost: null, status: 'scheduled', notes: '' } }
function openReplacementDialog(r?: any) {
  if (r) { editingReplacement.value = true; Object.assign(replacementForm, r) }
  else { editingReplacement.value = false; Object.assign(replacementForm, defaultReplacementForm()) }
  replacementDialog.value = true
}
async function saveReplacementItem() {
  saving.value = true
  try {
    const payload = { ...replacementForm }
    for (const k of ['scheduled_date', 'completed_date', 'estimated_cost', 'vehicle']) {
      if (payload[k] === '' || payload[k] === undefined) payload[k] = null
    }
    payload.status = (payload.status || 'scheduled').toLowerCase()
    await api.saveReplacement(payload, editingReplacement.value ? replacementForm.id : undefined)
    replacementDialog.value = false
    showSnack('Replacement saved')
    await refreshReplacements()
  } catch (e: any) { showSnack('Error', 'error') }
  finally { saving.value = false }
}
function deleteReplacementItem(r: any) {
  openConfirm('Delete Replacement', 'Delete this replacement record?', 'error', async () => {
    try { await api.deleteReplacement(r.id); showSnack('Replacement deleted'); await refreshReplacements() }
    catch (e: any) { showSnack('Error', 'error') }
  })
}

// ── View dialog ──
const viewDialog = ref(false)
const viewItem = ref<any>(null)
function viewBattery(b: any) { viewItem.value = b; viewDialog.value = true }
</script>

<style scoped>
.filter-toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 16px;
  align-items: center;
}
.filter-field {
  max-width: 220px;
}
.filter-grow {
  flex: 1 1 200px;
}
</style>
