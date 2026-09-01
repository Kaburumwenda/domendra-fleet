<template>
  <div class="d-flex flex-column ga-4">
    <!-- Header -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-2">
      <div>
        <h1 class="text-h5 font-weight-bold" style="color: #1e293b">Tire Management</h1>
        <p class="text-caption text-medium-emphasis">Inventory, tread health, mounting, rotations & lifecycle</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Search tires…" density="compact" variant="outlined" hide-details style="max-width: 240px" />
        <v-btn v-can="'tires:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="openTireDialog()">Add Tire</v-btn>
      </div>
    </div>

    <!-- KPI Row -->
    <v-row dense>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #6366f1 0%, #818cf8 100%)">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-tire</v-icon><span class="text-caption text-white">Total Tires</span></div>
          <p class="text-h4 font-weight-bold text-white">{{ stats.total }}</p>
          <p class="text-caption text-white" style="opacity: .85">{{ stats.brands }} brands · {{ stats.sizes }} sizes</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #10b981 0%, #34d399 100%)">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-car-connected</v-icon><span class="text-caption text-white">Mounted</span></div>
          <p class="text-h4 font-weight-bold text-white">{{ stats.mounted }}</p>
          <p class="text-caption text-white" style="opacity: .85">{{ stats.inStock }} in stock · {{ stats.spare }} spare</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%)">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-alert-circle-outline</v-icon><span class="text-caption text-white">Needs Replacement</span></div>
          <p class="text-h4 font-weight-bold text-white">{{ stats.needsReplacement }}</p>
          <p class="text-caption text-white" style="opacity: .85">Tread at or below threshold</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #ef4444 0%, #f87171 100%)">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-archive-outline</v-icon><span class="text-caption text-white">Retired / Scrapped</span></div>
          <p class="text-h4 font-weight-bold text-white">{{ stats.retired }}</p>
          <p class="text-caption text-white" style="opacity: .85">{{ currencySymbol }}{{ stats.inventoryValue.toFixed(0) }} inventory value</p>
        </v-card>
      </v-col>
    </v-row>

    <!-- Tabs -->
    <v-card elevation="0" border rounded="lg">
      <v-tabs v-model="tab" color="primary" density="compact">
        <v-tab value="inventory" slider-color="primary"><v-icon size="small" class="mr-2">mdi-tire</v-icon> Inventory</v-tab>
        <v-tab value="inspections" slider-color="primary"><v-icon size="small" class="mr-2">mdi-clipboard-check-outline</v-icon> Inspections</v-tab>
        <v-tab value="rotations" slider-color="primary"><v-icon size="small" class="mr-2">mdi-swap-horizontal</v-icon> Rotations</v-tab>
        <v-tab value="movements" slider-color="primary"><v-icon size="small" class="mr-2">mdi-transit-transfer-variant</v-icon> Movements</v-tab>
        <v-tab value="analytics" slider-color="primary"><v-icon size="small" class="mr-2">mdi-chart-box-outline</v-icon> Analytics</v-tab>
      </v-tabs>
      <v-divider />

      <v-window v-model="tab">
        <!-- Inventory -->
        <v-window-item value="inventory" class="pa-4">
          <!-- Filter bar -->
          <div class="filter-toolbar">
            <v-text-field
              v-model="search"
              prepend-inner-icon="mdi-magnify"
              placeholder="Search tires…"
              density="compact"
              variant="outlined"
              hide-details
              clearable
              class="filter-field filter-grow"
            />
            <v-select
              v-model="filterStatus"
              :items="filterStatusOptions"
              item-title="label"
              item-value="value"
              label="Status"
              density="compact"
              variant="outlined"
              hide-details
              multiple
              chips
              closable-chips
              clearable
              class="filter-field filter-grow"
            >
              <template #item="{ props, item }">
                <v-list-item v-bind="props">
                  <template #prepend>
                    <v-icon :color="item.raw.color" size="10">mdi-circle</v-icon>
                  </template>
                </v-list-item>
              </template>
            </v-select>
            <v-select
              v-model="filterCondition"
              :items="filterConditionOptions"
              item-title="label"
              item-value="value"
              label="Condition"
              density="compact"
              variant="outlined"
              hide-details
              multiple
              chips
              closable-chips
              clearable
              class="filter-field filter-grow"
            >
              <template #item="{ props, item }">
                <v-list-item v-bind="props">
                  <template #prepend>
                    <v-icon :color="item.raw.color" size="10">mdi-circle</v-icon>
                  </template>
                </v-list-item>
              </template>
            </v-select>
            <v-select
              v-model="filterBrand"
              :items="brandOptions"
              label="Brand"
              density="compact"
              variant="outlined"
              hide-details
              clearable
              class="filter-field filter-grow"
            />
            <v-text-field
              v-model="filterVehicle"
              prepend-inner-icon="mdi-truck-fast-outline"
              placeholder="Search by license plate…"
              density="compact"
              variant="outlined"
              hide-details
              clearable
              class="filter-field filter-grow"
            />
            <v-btn
              v-if="activeFilterCount"
              variant="text"
              color="error"
              size="small"
              prepend-icon="mdi-filter-remove-outline"
              @click="clearFilters"
            >
              Clear filters ({{ activeFilterCount }})
            </v-btn>
          </div>

          <v-data-table :headers="tireHeaders" :items="filteredTires" :loading="tiresPending" :search="search" hover items-per-page="15" v-model:page="tirePage" v-model:items-per-page="tirePerPage">
            <template #item.index="{ index }">
              <span class="text-caption text-medium-emphasis">{{ (tirePage - 1) * tirePerPage + index + 1 }}</span>
            </template>
            <template #item.serial_number="{ item }">
              <div class="d-flex align-center ga-2">
                <div class="d-flex align-center justify-center" style="width: 32px; height: 32px; border-radius: 8px; background: #eef2ff; flex-shrink: 0">
                  <v-icon size="18" color="primary">mdi-tire</v-icon>
                </div>
                <div>
                  <p class="text-body-2 font-weight-medium" style="color: #1e293b">{{ item.serial_number }}</p>
                  <p class="text-caption text-medium-emphasis">{{ item.brand }} {{ item.model }} · {{ item.size || '—' }}</p>
                </div>
              </div>
            </template>
            <template #item.type="{ value }">
              <v-chip v-if="value" size="small" variant="tonal" color="info">{{ value }}</v-chip>
              <span v-else class="text-caption text-medium-emphasis">—</span>
            </template>
            <template #item.condition="{ value }">
              <v-chip v-if="value" size="small" :color="conditionChipColor(value)" variant="flat">{{ conditionLabel(value) }}</v-chip>
              <span v-else class="text-caption text-medium-emphasis">—</span>
            </template>
            <template #item.status="{ value }">
              <v-chip size="small" :color="statusColor(value)" variant="flat">{{ statusLabel(value) }}</v-chip>
            </template>
            <template #item.vehicle_name="{ item }">
              <span v-if="item.vehicle_name" class="text-body-2">{{ item.vehicle_name }}</span>
              <div v-else class="text-caption text-medium-emphasis">—</div>
              <div v-if="item.vehicle_name" class="text-caption text-medium-emphasis">{{ item.position || '' }}</div>
            </template>
            <template #item.purchase_price="{ value }">{{ value ? `${currencySymbol}${Number(value).toLocaleString()}` : '—' }}</template>
            <template #item.mounted_on="{ item }">
              <span v-if="tireMountedAt[item.id]" class="text-body-2">{{ formatOrdinalDate(tireMountedAt[item.id]) }}</span>
              <span v-else class="text-caption text-medium-emphasis">—</span>
            </template>
            <template #item.days_used="{ item }">
              <v-chip v-if="daysBetween(tireMountedAt[item.id], tireRetiredAt[item.id]) != null" size="small" color="info" variant="tonal">
                {{ daysBetween(tireMountedAt[item.id], tireRetiredAt[item.id]) }} day{{ daysBetween(tireMountedAt[item.id], tireRetiredAt[item.id]) === 1 ? '' : 's' }}
              </v-chip>
              <span v-else-if="tireMountedAt[item.id] && !tireRetiredAt[item.id]" class="text-caption text-medium-emphasis">
                {{ daysBetween(tireMountedAt[item.id], new Date().toISOString()) }} day{{ daysBetween(tireMountedAt[item.id], new Date().toISOString()) === 1 ? '' : 's' }} (ongoing)
              </span>
              <span v-else class="text-caption text-medium-emphasis">—</span>
            </template>
            <template #item.actions="{ item }">
              <div class="d-flex justify-center">
                <v-menu location="bottom end" transition="scale-transition" origin="top end">
                  <template #activator="{ props }">
                    <v-btn v-bind="props" icon="mdi-dots-vertical" size="small" variant="text" color="medium-emphasis" title="Actions" />
                  </template>
                  <v-list density="compact" class="py-1" min-width="180">
                    <v-list-item prepend-icon="mdi-eye-outline" title="View" @click="viewTire(item)" />
                    <v-list-item v-can="'tires:update'" prepend-icon="mdi-pencil-outline" title="Edit" @click="openTireDialog(item)" />
                    <v-list-item v-if="item.status === 'mounted'" v-can="'tires:update'" prepend-icon="mdi-arrow-down-bold-hexagon-outline" title="Unmount" @click="unmountTire(item)" />
                    <v-list-item v-else-if="item.status === 'in_stock' || item.status === 'spare'" v-can="'tires:create'" prepend-icon="mdi-arrow-up-bold-hexagon-outline" title="Mount" @click="openMountDialog(item)" />
                    <v-list-item v-if="item.status !== 'retired' && item.status !== 'scrapped'" v-can="'tires:update'" prepend-icon="mdi-archive-outline" title="Retire" @click="retireTire(item)" />
                    <v-divider v-if="item.status !== 'retired' && item.status !== 'scrapped'" class="my-1" />
                    <v-list-item v-can="'tires:delete'" prepend-icon="mdi-trash-can-outline" title="Delete" base-color="error" @click="deleteTire(item)" />
                  </v-list>
                </v-menu>
              </div>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-tire</v-icon>
                <p>No tires yet. Click “Add Tire” to start tracking.</p>
              </div>
            </template>
          </v-data-table>
        </v-window-item>

        <!-- Inspections -->
        <v-window-item value="inspections" class="pa-4">
          <div class="d-flex justify-end mb-3">
            <v-btn v-can="'tires:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="openInspectionDialog()">Record Inspection</v-btn>
          </div>
          <v-data-table :headers="inspectionHeaders" :items="inspections" :loading="inspectionsPending" hover items-per-page="15">
            <template #item.tire="{ item }">
              <span class="text-body-2 font-weight-medium" style="color: #1e293b">{{ item.tire_serial || `#${item.tire}` }}</span>
            </template>
            <template #item.vehicle="{ item }">
              <span v-if="item.vehicle_name">{{ item.vehicle_name }}</span>
              <span v-else-if="item.vehicle">Vehicle #{{ item.vehicle }}</span>
              <span v-else class="text-caption text-medium-emphasis">—</span>
            </template>
            <template #item.tread_depth="{ value }">{{ value }} /32″</template>
            <template #item.pressure_psi="{ value }">{{ value != null ? `${value} psi` : '—' }}</template>
            <template #item.condition="{ value }">
              <v-chip size="small" :color="conditionColor(value)" variant="flat">{{ value }}</v-chip>
            </template>
            <template #item.measured_at="{ value }">{{ value ? formatOrdinalDate(value) : '—' }}</template>
            <template #item.actions="{ item }">
              <div class="d-flex ga-1">
                <v-btn v-can="'tires:update'" icon="mdi-pencil-outline" size="x-small" variant="text" color="warning" @click="openInspectionDialog(item)" />
                <v-btn v-can="'tires:delete'" icon="mdi-trash-can-outline" size="x-small" variant="text" color="error" @click="deleteInspection(item)" />
              </div>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis"><v-icon size="48" class="mb-3">mdi-clipboard-check-outline</v-icon><p>No inspections recorded yet.</p></div>
            </template>
          </v-data-table>
        </v-window-item>

        <!-- Rotations -->
        <v-window-item value="rotations" class="pa-4">
          <div class="d-flex justify-end mb-3">
            <v-btn v-can="'tires:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="navigateTo('/app/tires/rotate')">Record Rotation</v-btn>
          </div>
          <v-data-table :headers="rotationHeaders" :items="rotations" :loading="rotationsPending" hover items-per-page="15">
            <template #item.vehicle="{ item }">
              <div class="d-flex align-center ga-2">
                <div class="d-flex align-center justify-center" style="width: 36px; height: 36px; border-radius: 10px; background: #eef2ff; flex-shrink: 0">
                  <v-icon size="20" color="primary">mdi-truck-outline</v-icon>
                </div>
                <div>
                  <p class="text-body-2 font-weight-medium" style="color: #1e293b">{{ item.vehicle_name || `#${item.vehicle}` }}</p>
                  <p v-if="item.vehicle_license_plate" class="text-caption text-medium-emphasis">{{ item.vehicle_license_plate }}</p>
                </div>
              </div>
            </template>
            <template #item.rotation_pattern="{ value }">
              <v-chip v-if="value" size="small" variant="tonal" color="primary" prepend-icon="mdi-swap-horizontal-bold">{{ value }}</v-chip>
              <span v-else class="text-caption text-medium-emphasis">—</span>
            </template>
            <template #item.odometer="{ value }">{{ value ? Number(value).toLocaleString() : '—' }}</template>
            <template #item.performed_at="{ value }">
              <div class="d-flex align-center ga-1">
                <v-icon size="small" color="medium-emphasis">mdi-calendar</v-icon>
                <span class="text-body-2">{{ value ? formatOrdinalDate(value) : '—' }}</span>
              </div>
            </template>
            <template #item.swaps="{ item }">
              <v-chip v-if="item.swaps?.length" size="small" variant="flat" color="purple" prepend-icon="mdi-arrow-u-left-right">
                {{ item.swaps.length }} swap{{ item.swaps.length === 1 ? '' : 's' }}
              </v-chip>
              <span v-else class="text-caption text-medium-emphasis">—</span>
            </template>
            <template #item.notes="{ item }">
              <span v-if="item.notes" class="text-caption text-medium-emphasis text-truncate d-inline-block" style="max-width: 160px">{{ item.notes }}</span>
              <span v-else class="text-caption text-medium-emphasis">—</span>
            </template>
            <template #item.actions="{ item }">
              <div class="d-flex ga-1">
                <v-btn icon="mdi-eye-outline" size="x-small" variant="text" color="info" title="View" @click="viewRotation(item)" />
                <v-btn v-can="'tires:update'" icon="mdi-pencil-outline" size="x-small" variant="text" color="warning" title="Edit" @click="navigateTo(`/app/tires/rotate/${item.id}`)" />
                <v-btn v-can="'tires:delete'" icon="mdi-trash-can-outline" size="x-small" variant="text" color="error" title="Delete" @click="deleteRotation(item)" />
              </div>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis"><v-icon size="48" class="mb-3">mdi-swap-horizontal</v-icon><p>No rotations logged yet.</p></div>
            </template>
          </v-data-table>
        </v-window-item>

        <!-- Movements -->
        <v-window-item value="movements" class="pa-4">
          <v-data-table :headers="movementHeaders" :items="movements" :loading="movementsPending" hover items-per-page="15">
            <template #item.tire_serial="{ value }">
              <span class="text-body-2 font-weight-medium" style="color: #1e293b">{{ value }}</span>
            </template>
            <template #item.movement_type="{ value }">
              <v-chip size="small" :color="movementColor(value)" variant="flat">{{ value }}</v-chip>
            </template>
            <template #item.from="{ item }">
              <span v-if="item.from_vehicle_name" class="text-body-2">{{ item.from_vehicle_name }}</span>
              <span v-else class="text-caption text-medium-emphasis">—</span>
              <div v-if="item.from_position" class="text-caption text-medium-emphasis">{{ item.from_position }}</div>
            </template>
            <template #item.to="{ item }">
              <span v-if="item.to_vehicle_name" class="text-body-2">{{ item.to_vehicle_name }}</span>
              <span v-else class="text-caption text-medium-emphasis">—</span>
              <div v-if="item.to_position" class="text-caption text-medium-emphasis">{{ item.to_position }}</div>
            </template>
            <template #item.performed_at="{ value }">{{ value ? formatOrdinalDate(value) : '—' }}</template>
            <template #item.odometer="{ value }">{{ value ? Number(value).toLocaleString() : '—' }}</template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis"><v-icon size="48" class="mb-3">mdi-transit-transfer-variant</v-icon><p>No movement history yet.</p></div>
            </template>
          </v-data-table>
        </v-window-item>

        <!-- Analytics -->
        <v-window-item value="analytics" class="pa-4">
          <v-row dense>
            <v-col cols="12" md="6" lg="4">
              <DashboardChart :option="statusChartOption" title="Status Distribution" icon="mdi-chart-pie" height="280px" />
            </v-col>
            <v-col cols="12" md="6" lg="4">
              <DashboardChart :option="typeChartOption" title="Tire Type Breakdown" icon="mdi-car-estate" height="280px" />
            </v-col>
            <v-col cols="12" md="6" lg="4">
              <DashboardChart :option="brandChartOption" title="Top Brands" icon="mdi-factory" height="280px" />
            </v-col>
            <v-col cols="12" md="6">
              <DashboardChart :option="treadHealthOption" title="Tread Health Distribution" icon="mdi-chart-bar" height="280px" />
            </v-col>
            <v-col cols="12" md="6">
              <v-card elevation="0" border class="pa-5 h-100">
                <h3 class="text-subtitle-1 font-weight-medium mb-4 d-flex align-center ga-2" style="color: #1e293b"><v-icon size="small" color="error">mdi-alert-circle-outline</v-icon> Needs Replacement</h3>
                <div v-if="needsReplacementTires.length" class="d-flex flex-column ga-2 overflow-y-auto" style="max-height: 240px">
                  <div v-for="t in needsReplacementTires" :key="t.id" class="d-flex align-center justify-space-between pa-3 rounded-lg" style="background: #fef2f2">
                    <div>
                      <p class="text-body-2 font-weight-medium" style="color: #1e293b">{{ t.serial_number }}</p>
                      <p class="text-caption text-medium-emphasis">{{ t.brand }} {{ t.size }} · {{ t.vehicle_name || 'In stock' }}</p>
                    </div>
                    <v-chip size="small" color="error" variant="flat">{{ t.latest_tread_depth }}/32″</v-chip>
                  </div>
                </div>
                <div v-else class="text-center py-8 text-medium-emphasis">
                  <v-icon size="36" class="mb-2 text-success">mdi-check-circle-outline</v-icon>
                  <p class="text-body-2">All tires are within safe tread depth.</p>
                </div>
              </v-card>
            </v-col>
          </v-row>
        </v-window-item>
      </v-window>
    </v-card>

    <!-- Add / Edit Tire Dialog -->
    <v-dialog v-model="tireDialogVisible" max-width="680" scroll-strategy="none">
      <v-card rounded="xl" class="overflow-hidden">
        <AppModalHeader icon="mdi-tire">{{ editingTire ? 'Edit Tire' : 'Add Tire' }}</AppModalHeader>
        <v-card-text class="pt-5">
          <v-alert
            v-if="tireErrors.length"
            type="error"
            variant="tonal"
            density="compact"
            class="mb-4"
            closable
            @click:close="tireErrors = []"
          >
            <div class="text-body-2 font-weight-medium mb-1">Please fix the following before saving:</div>
            <ul class="text-body-2 pl-4 mb-0">
              <li v-for="(err, i) in tireErrors" :key="i" class="text-wrap">{{ err }}</li>
            </ul>
          </v-alert>
          <div class="text-caption text-medium-emphasis mb-4">Track an individual tire by serial number. Fields marked <span class="text-error">*</span> are required.</div>
          <v-row dense>
            <v-col cols="12" md="6"><v-text-field v-model="tireForm.serial_number" label="Serial Number *" prepend-inner-icon="mdi-barcode" hide-details="auto" :rules="[v => !!v || 'Required']" /></v-col>
            <v-col cols="12" md="6">
              <v-combobox v-model="tireForm.brand" :items="brandOptions" label="Brand" prepend-inner-icon="mdi-factory" hide-details="auto" clearable />
            </v-col>
            <v-col cols="12" md="6">
              <v-combobox v-model="tireForm.model" :items="modelOptions" label="Model" hide-details="auto" clearable />
            </v-col>
            <v-col cols="12" md="6">
              <v-combobox v-model="tireForm.size" :items="sizeOptions" label="Size" placeholder="e.g. 11R22.5" prepend-inner-icon="mdi-ruler" hide-details="auto" clearable />
            </v-col>
            <v-col cols="12" md="6">
              <v-select v-model="tireForm.type" :items="tireTypeOptions" label="Type" prepend-inner-icon="mdi-car-tire-alert" hide-details="auto" clearable />
            </v-col>
            <v-col cols="12" md="6">
              <v-select v-model="tireForm.condition" :items="tireConditionOptions" item-title="label" item-value="value" label="Condition" prepend-inner-icon="mdi-circle-slice-8" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="6">
              <v-select v-model="tireForm.status" :items="statusOptions" item-title="label" item-value="value" label="Status" prepend-inner-icon="mdi-arrow-decision-outline" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="6"><v-text-field v-model.number="tireForm.purchase_price" :label="`Purchase Price (${currencySymbol})`" type="number" min="0" step="0.01" prepend-inner-icon="mdi-cash" hide-details="auto" /></v-col>
            <v-col cols="12" md="6"><v-text-field v-model="tireForm.purchase_date" type="date" label="Purchase Date" prepend-inner-icon="mdi-calendar" hide-details="auto" /></v-col>
            <v-col cols="12" md="6">
              <v-select v-model="tireForm.warranty_miles" :items="warrantyMilesOptions" label="Warranty Miles" prepend-inner-icon="mdi-shield-check-outline" hide-details="auto" clearable />
            </v-col>
            <v-col cols="12" md="6">
              <v-select v-model="tireForm.min_tread_depth" :items="minTreadDepthOptions" label="Min Tread Depth (/32″)" prepend-inner-icon="mdi-ruler" hide-details="auto" />
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="tireDialogVisible = false">Cancel</v-btn>
          <v-btn v-if="!editingTire" color="primary" variant="outlined" prepend-icon="mdi-plus" :loading="tireSaving" @click="saveTire(true)">Save &amp; Add Another</v-btn>
          <v-btn color="primary" prepend-icon="mdi-check" :loading="tireSaving" @click="saveTire(false)">{{ editingTire ? 'Update' : 'Save' }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Inspection Dialog -->
    <v-dialog v-model="inspectionDialogVisible" max-width="620" scroll-strategy="none">
      <v-card rounded="xl" class="overflow-hidden">
        <AppModalHeader icon="mdi-clipboard-check-outline">{{ editingInspection ? 'Edit Inspection' : 'Record Inspection' }}</AppModalHeader>
        <v-card-text class="pt-5">
          <v-row dense>
            <v-col cols="12" md="6">
              <v-select v-model="inspectionForm.tire" :items="tireSelectOptions" item-title="label" item-value="id" label="Tire *" prepend-inner-icon="mdi-tire" hide-details="auto" :rules="[v => !!v || 'Required']" />
            </v-col>
            <v-col cols="12" md="6">
              <v-select v-model="inspectionForm.vehicle" :items="vehicleOptions" item-title="display_name" item-value="id" label="Vehicle" prepend-inner-icon="mdi-car" hide-details="auto" clearable />
            </v-col>
            <v-col cols="6" md="3">
              <v-text-field v-model.number="inspectionForm.tread_depth" label="Tread (/32″) *" type="number" min="0" step="0.5" prepend-inner-icon="mdi-ruler" hide-details="auto" :rules="[v => v !== '' && v != null || 'Required']" />
            </v-col>
            <v-col cols="6" md="3">
              <v-text-field v-model.number="inspectionForm.pressure_psi" label="Pressure (psi)" type="number" min="0" step="0.1" prepend-inner-icon="mdi-gauge" hide-details="auto" />
            </v-col>
            <v-col cols="6" md="3">
              <v-text-field v-model.number="inspectionForm.odometer" label="Odometer" type="number" min="0" prepend-inner-icon="mdi-counter" hide-details="auto" />
            </v-col>
            <v-col cols="6" md="3">
              <v-select v-model="inspectionForm.condition" :items="conditionOptions" label="Condition" prepend-inner-icon="mdi-circle-outline" hide-details="auto" />
            </v-col>
            <v-col cols="12">
              <v-select v-model="inspectionForm.position" :items="positionOptions" label="Position" prepend-inner-icon="mdi-crosshairs-gps" hide-details="auto" clearable />
            </v-col>
            <v-col cols="12">
              <v-text-field v-model="inspectionForm.measured_at" type="date" label="Measured On *" prepend-inner-icon="mdi-calendar" hide-details="auto" :rules="[v => !!v || 'Required']" />
            </v-col>
            <v-col cols="12">
              <v-textarea v-model="inspectionForm.notes" label="Notes" rows="2" hide-details="auto" />
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="inspectionDialogVisible = false">Cancel</v-btn>
          <v-btn color="primary" prepend-icon="mdi-check" :loading="inspectionSaving" @click="saveInspection">{{ editingInspection ? 'Update' : 'Save' }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Rotation Dialog -->
    <v-dialog v-model="rotationDialogVisible" :max-width="editingRotation && rotationEditTirePositions.length ? 1100 : 540" scroll-strategy="none">
      <v-card rounded="xl" class="overflow-hidden rotation-edit-card">
        <v-card-title class="bg-primary text-white d-flex align-center ga-2 pr-3">
          <v-icon size="20" color="white">mdi-swap-horizontal</v-icon>
          <span class="text-h6 font-weight-bold">{{ editingRotation ? 'Edit Rotation' : 'Record Rotation' }}</span>
          <v-spacer />
          <v-btn icon="mdi-close" size="small" variant="text" color="white" title="Cancel" @click="rotationDialogVisible = false" />
        </v-card-title>
        <v-card-text class="pa-0">
          <v-row no-gutters class="rotation-edit-row">
            <!-- Left column: form fields -->
            <v-col :cols="editingRotation && rotationEditTirePositions.length ? 5 : 12" class="pa-5">
              <v-row dense>
                <v-col cols="12">
                  <v-select v-model="rotationForm.vehicle" :items="vehicleOptions" item-title="display_name" item-value="id" label="Vehicle *" prepend-inner-icon="mdi-car" hide-details="auto" :rules="[v => !!v || 'Required']" />
                </v-col>
                <v-col cols="12" md="6">
                  <v-select v-model="rotationForm.rotation_pattern" :items="rotationPatterns" label="Rotation Pattern" prepend-inner-icon="mdi-swap-horizontal-bold" hide-details="auto" />
                </v-col>
                <v-col cols="12" md="6">
                  <v-text-field v-model.number="rotationForm.odometer" label="Odometer" type="number" min="0" prepend-inner-icon="mdi-counter" hide-details="auto" />
                </v-col>
                <v-col cols="12">
                  <v-text-field v-model="rotationForm.performed_at" type="date" label="Performed On *" prepend-inner-icon="mdi-calendar" hide-details="auto" :rules="[v => !!v || 'Required']" />
                </v-col>
                <v-col cols="12">
                  <v-textarea v-model="rotationForm.notes" label="Notes" rows="2" hide-details="auto" />
                </v-col>
              </v-row>
            </v-col>

            <!-- Right column: previous-rotation axle diagram + swap editor (only in edit mode) -->
            <v-col v-if="editingRotation && rotationEditTirePositions.length" cols="7" class="rotation-edit-right">
              <div class="d-flex flex-column h-100">
                <div class="d-flex align-center ga-1 pa-4 pb-2">
                  <v-icon size="18" color="purple">mdi-crosshairs-gps</v-icon>
                  <span class="text-subtitle-2 font-weight-bold" style="color: #334155">Vehicle Axle — Adjust Positions</span>
                  <v-spacer />
                  <v-chip size="small" color="purple" variant="flat" prepend-icon="mdi-swap-horizontal">{{ rotationEditTirePositions.length }} tire{{ rotationEditTirePositions.length === 1 ? '' : 's' }}</v-chip>
                </div>
                <div class="rotation-axle-wrap">
                  <AxlePositionDiagram
                    :position="rotationEditSelectedPosition || (rotationEditTirePositions[0]?.to_position || '')"
                    :drivetrain="rotationEditVehicle?.drivetrain"
                    :vehicle-type="rotationEditVehicle?.vehicle_type"
                    :steering="rotationEditVehicle?.steering"
                    :vehicle-name="rotationEditVehicle?.display_name"
                    :tire-serial="rotationEditSelectedTire?.tire_serial"
                    :tire-brand="rotationEditSelectedTire?.tire_brand"
                    :tire-size="rotationEditSelectedTire?.tire_size"
                  />
                </div>
                <div class="pa-3">
                  <p class="text-caption text-medium-emphasis mb-2">Select a tire to view and update its destination position:</p>
                  <v-chip-group v-model="rotationEditSelected" mandatory>
                    <v-chip
                      v-for="(s, i) in rotationEditTirePositions"
                      :key="i"
                      size="small"
                      variant="outlined"
                      :color="rotationEditSelected === i ? 'primary' : undefined"
                    >
                      <v-icon start size="small">mdi-tire</v-icon>
                      {{ s.tire_serial || `#${s.tire}` }}
                    </v-chip>
                  </v-chip-group>
                  <div v-if="rotationEditSelectedTire" class="d-flex align-center ga-2 mt-3">
                    <v-chip size="small" variant="tonal" color="info" prepend-icon="mdi-arrow-left">
                      {{ formatPosition(rotationEditSelectedTire.from_position) || '—' }}
                    </v-chip>
                    <v-icon size="16" color="medium-emphasis">mdi-arrow-right</v-icon>
                    <v-select
                      v-model="rotationEditSelectedTire.to_position"
                      :items="positionOptions"
                      label="New position"
                      density="compact"
                      variant="outlined"
                      hide-details
                      style="max-width: 200px"
                      prepend-inner-icon="mdi-crosshairs-gps"
                    />
                  </div>
                </div>
              </div>
            </v-col>
          </v-row>
        </v-card-text>
        <v-divider />
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="rotationDialogVisible = false">Cancel</v-btn>
          <v-btn color="primary" prepend-icon="mdi-check" :loading="rotationSaving" @click="saveRotation">{{ editingRotation ? 'Update' : 'Save' }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- View Rotation Dialog -->
    <v-dialog v-model="viewRotationDialogVisible" :max-width="viewRotationItem && viewRotationItem.swaps_detail?.length ? 1100 : 720" scroll-strategy="none">
      <v-card v-if="viewRotationItem" rounded="xl" class="overflow-hidden rotation-detail-card">
        <v-card-title class="bg-primary text-white d-flex align-center ga-2 pr-3">
          <v-icon size="20" color="white">mdi-swap-horizontal</v-icon>
          <span class="text-h6 font-weight-bold">Rotation Details</span>
          <v-spacer />
          <v-btn icon="mdi-close" size="small" variant="text" color="white" title="Close" @click="viewRotationDialogVisible = false" />
        </v-card-title>
        <v-card-text class="pa-0">
          <v-row no-gutters class="rotation-detail-row">
            <!-- Left column: details + swap cards -->
            <v-col :cols="viewRotationItem.swaps_detail?.length ? 6 : 12" class="rotation-detail-left">
              <div class="pa-5">
                <div class="d-flex align-center ga-3 mb-4">
                  <div class="d-flex align-center justify-center rotation-avatar">
                    <v-icon color="primary" size="32">mdi-swap-horizontal</v-icon>
                  </div>
                  <div>
                    <p class="text-h6 font-weight-bold mb-0" style="color: #1e293b">{{ viewRotationItem.vehicle_name || `Vehicle #${viewRotationItem.vehicle}` }}</p>
                    <p class="text-caption text-medium-emphasis mb-0">
                      <v-chip v-if="viewRotationItem.rotation_pattern" size="x-small" variant="tonal" color="primary" class="mr-1">{{ viewRotationItem.rotation_pattern }}</v-chip>
                      {{ formatOrdinalDate(viewRotationItem.performed_at) }}
                    </p>
                  </div>
                  <v-spacer />
                  <v-chip size="small" variant="flat" color="purple" prepend-icon="mdi-swap-horizontal">
                    Rotation #{{ viewRotationItem.id }}
                  </v-chip>
                </div>
                <v-row dense class="spec-grid mb-2">
                  <v-col cols="6"><p class="spec-label">Vehicle</p><p class="spec-value">{{ viewRotationItem.vehicle_name || `#${viewRotationItem.vehicle}` }}</p></v-col>
                  <v-col cols="6"><p class="spec-label">License Plate</p><p class="spec-value">{{ viewRotationItem.vehicle_license_plate || '—' }}</p></v-col>
                  <v-col cols="6"><p class="spec-label">Rotation Pattern</p><p class="spec-value"><v-chip v-if="viewRotationItem.rotation_pattern" size="small" variant="tonal" color="primary">{{ viewRotationItem.rotation_pattern }}</v-chip><span v-else>—</span></p></v-col>
                  <v-col cols="6"><p class="spec-label">Odometer</p><p class="spec-value">{{ viewRotationItem.odometer ? Number(viewRotationItem.odometer).toLocaleString() : '—' }}</p></v-col>
                  <v-col cols="6"><p class="spec-label">Date Performed</p><p class="spec-value">{{ formatOrdinalDate(viewRotationItem.performed_at) }}</p></v-col>
                  <v-col cols="6"><p class="spec-label">Swaps</p><p class="spec-value font-weight-medium">{{ viewRotationItem.swaps?.length || 0 }}</p></v-col>
                  <v-col v-if="viewRotationItem.notes" cols="12"><p class="spec-label">Notes</p><p class="spec-value">{{ viewRotationItem.notes }}</p></v-col>
                </v-row>

                <div v-if="viewRotationItem.swaps_detail?.length" class="mt-2">
                  <p class="text-subtitle-2 font-weight-medium mb-2 d-flex align-center ga-1" style="color: #475569">
                    <v-icon size="16" color="purple">mdi-arrow-u-left-right</v-icon>Swap Details
                  </p>
                  <div v-for="(s, i) in viewRotationItem.swaps_detail" :key="i" class="swap-card mb-2">
                    <div class="d-flex align-center ga-2">
                      <div class="d-flex align-center justify-center swap-num">{{ i + 1 }}</div>
                      <div class="d-flex align-center ga-1 flex-grow-1 min-width-0">
                        <v-icon size="18" color="primary">mdi-tire</v-icon>
                        <div class="min-width-0">
                          <p class="text-body-2 font-weight-medium text-truncate" style="color: #1e293b">{{ s.tire_serial || `#${s.tire}` }}</p>
                          <p class="text-caption text-medium-emphasis text-truncate">{{ s.tire_brand || '' }} {{ s.tire_size || '' }}</p>
                        </div>
                      </div>
                      <v-chip size="x-small" variant="tonal" color="info" prepend-icon="mdi-arrow-left">{{ formatPosition(s.from_position) || '—' }}</v-chip>
                      <v-icon size="16" color="medium-emphasis">mdi-arrow-right</v-icon>
                      <v-chip size="x-small" variant="tonal" color="success" prepend-icon="mdi-arrow-right">{{ formatPosition(s.to_position) || '—' }}</v-chip>
                    </div>
                  </div>
                </div>
              </div>
            </v-col>
            <!-- Right column: axle diagram -->
            <v-col v-if="viewRotationItem.swaps_detail?.length" cols="6" class="rotation-detail-right">
              <div class="d-flex flex-column h-100">
                <div class="d-flex align-center ga-1 pa-4 pb-2">
                  <v-icon size="18" color="purple">mdi-crosshairs-gps</v-icon>
                  <span class="text-subtitle-2 font-weight-bold" style="color: #334155">Vehicle Axle Positions</span>
                  <v-spacer />
                  <v-chip size="small" color="purple" variant="flat" prepend-icon="mdi-swap-horizontal">{{ viewRotationItem.swaps_detail.length }} swap{{ viewRotationItem.swaps_detail.length === 1 ? '' : 's' }}</v-chip>
                </div>
                <div class="rotation-axle-wrap">
                  <AxlePositionDiagram
                    :position="viewRotationItem.swaps_detail[0]?.to_position || ''"
                    :drivetrain="viewRotationItem.vehicle_drivetrain"
                    :vehicle-type="viewRotationItem.vehicle_type"
                    :steering="viewRotationItem.vehicle_steering"
                    :vehicle-name="viewRotationItem.vehicle_name"
                    :tire-serial="viewRotationItem.swaps_detail[0]?.tire_serial || ''"
                    :tire-brand="viewRotationItem.swaps_detail[0]?.tire_brand || ''"
                    :tire-size="viewRotationItem.swaps_detail[0]?.tire_size || ''"
                  />
                </div>
                <div class="pa-3 text-caption text-medium-emphasis text-center">
                  <v-icon size="small" color="success">mdi-circle-medium</v-icon> Destination positions after rotation
                </div>
              </div>
            </v-col>
          </v-row>
        </v-card-text>
        <v-divider />
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="viewRotationDialogVisible = false">Close</v-btn>
          <v-btn
            color="warning"
            prepend-icon="mdi-pencil-outline"
            variant="tonal"
            @click="viewRotationDialogVisible = false; navigateTo(`/app/tires/rotate/${viewRotationItem.id}`)"
          >Edit</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- View Tire Dialog -->
    <v-dialog v-model="viewDialogVisible" :max-width="viewTireItem && viewTireItem.position ? 1100 : 720" scroll-strategy="none">
      <v-card v-if="viewTireItem" rounded="xl" class="overflow-hidden tire-detail-card">
        <v-card-title class="bg-primary text-white d-flex align-center ga-2 pr-3">
          <v-icon size="20" color="white">mdi-tire</v-icon>
          <span class="text-h6 font-weight-bold">Tire Details</span>
          <v-spacer />
          <v-btn icon="mdi-close" size="small" variant="text" color="white" title="Close" @click="viewDialogVisible = false" />
        </v-card-title>
        <v-card-text class="pa-0">
          <v-row no-gutters class="tire-detail-row">
            <!-- Left column: specs + inspections -->
            <v-col :cols="viewTireItem.position ? 6 : 12" :md="viewTireItem.position ? 6 : 12" class="tire-detail-left">
              <div class="pa-5">
                <div class="d-flex align-center ga-3 mb-4">
                  <div class="d-flex align-center justify-center tire-avatar">
                    <v-icon color="primary" size="32">mdi-tire</v-icon>
                  </div>
                  <div>
                    <p class="text-h6 font-weight-bold mb-0" style="color: #1e293b">{{ viewTireItem.serial_number }}</p>
                    <p class="text-caption text-medium-emphasis mb-0">{{ viewTireItem.brand }} {{ viewTireItem.model }} · {{ viewTireItem.size || '—' }}</p>
                  </div>
                  <v-spacer />
                  <v-chip :color="statusColor(viewTireItem.status)" variant="flat" size="small">{{ statusLabel(viewTireItem.status) }}</v-chip>
                </div>
                <v-row dense class="spec-grid">
                  <v-col cols="6"><p class="spec-label">Type</p><p class="spec-value">{{ viewTireItem.type || '—' }}</p></v-col>
                  <v-col cols="6"><p class="spec-label">Condition</p><p class="spec-value"><v-chip v-if="viewTireItem.condition" size="small" :color="conditionChipColor(viewTireItem.condition)" variant="flat">{{ conditionLabel(viewTireItem.condition) }}</v-chip><span v-else>—</span></p></v-col>
                  <v-col cols="6"><p class="spec-label">Mounted On</p><p class="spec-value">{{ viewTireItem.vehicle_name || 'In stock / unmounted' }}</p></v-col>
                  <v-col cols="6"><p class="spec-label">Axle Position</p><p class="spec-value d-flex align-center ga-1"><v-icon v-if="viewTireItem.position" size="small" :color="positionIconColor(viewTireItem.position)">{{ positionIcon(viewTireItem.position) }}</v-icon>{{ viewTireItem.position ? formatPosition(viewTireItem.position) : '—' }}</p></v-col>
                  <v-col cols="6"><p class="spec-label">Latest Tread</p><p class="spec-value font-weight-medium" :class="viewTireItem.needs_replacement ? 'text-error' : 'text-success'">{{ viewTireItem.latest_tread_depth != null ? `${viewTireItem.latest_tread_depth} /32″` : '—' }}</p></v-col>
                  <v-col cols="6"><p class="spec-label">Total Miles</p><p class="spec-value">{{ Number(viewTireItem.total_miles || 0).toLocaleString() }}</p></v-col>
                  <v-col cols="6"><p class="spec-label">Purchase Date</p><p class="spec-value">{{ viewTireItem.purchase_date ? formatOrdinalDate(viewTireItem.purchase_date) : '—' }}</p></v-col>
                  <v-col cols="6"><p class="spec-label">Purchase Price</p><p class="spec-value">{{ viewTireItem.purchase_price ? `${currencySymbol}${Number(viewTireItem.purchase_price).toLocaleString()}` : '—' }}</p></v-col>
                  <v-col cols="6"><p class="spec-label">Warranty Miles</p><p class="spec-value">{{ viewTireItem.warranty_miles ? Number(viewTireItem.warranty_miles).toLocaleString() : '—' }}</p></v-col>
                  <v-col cols="6"><p class="spec-label">Min Tread Threshold</p><p class="spec-value">{{ viewTireItem.min_tread_depth }} /32″</p></v-col>
                </v-row>
                <div v-if="viewTireInspections.length" class="mt-4">
                  <p class="text-subtitle-2 font-weight-medium mb-2" style="color: #475569">Recent Inspections</p>
                  <div v-for="ins in viewTireInspections" :key="ins.id" class="d-flex align-center justify-space-between pa-2 rounded-lg mb-1" style="background: #f8fafc">
                    <div class="d-flex align-center ga-2">
                      <v-chip size="x-small" :color="conditionColor(ins.condition)" variant="flat">{{ ins.condition }}</v-chip>
                      <span class="text-body-2">{{ ins.tread_depth }}/32″ {{ ins.pressure_psi != null ? `· ${ins.pressure_psi} psi` : '' }}</span>
                    </div>
                    <span class="text-caption text-medium-emphasis">{{ formatOrdinalDate(ins.measured_at) }}</span>
                  </div>
                </div>
              </div>
            </v-col>
            <!-- Right column: 3D axle diagram (only when mounted) -->
            <v-col v-if="viewTireItem.position" cols="6" md="6" class="tire-detail-right">
              <div class="d-flex flex-column h-100">
                <div class="d-flex align-center ga-1 pa-4 pb-2">
                  <v-icon size="18" color="success">mdi-crosshairs-gps</v-icon>
                  <span class="text-subtitle-2 font-weight-bold" style="color: #334155">Mount Position on Vehicle Axle</span>
                  <v-spacer />
                  <v-chip size="small" color="success" variant="flat" prepend-icon="mdi-crosshairs-gps">
                    {{ formatPosition(viewTireItem.position) }}
                  </v-chip>
                </div>
                <div class="axle-preview-wrap">
                  <AxlePositionDiagram
                    :position="viewTireItem.position"
                    :drivetrain="viewTireItem.vehicle_drivetrain"
                    :vehicle-type="viewTireItem.vehicle_type"
                    :steering="viewTireItem.vehicle_steering"
                    :vehicle-name="viewTireItem.vehicle_name"
                    :tire-serial="viewTireItem.serial_number"
                    :tire-brand="viewTireItem.brand"
                    :tire-size="viewTireItem.size"
                  />
                </div>
                <div class="pa-3 text-caption text-medium-emphasis text-center">
                  Highlighted position shows where this tire is mounted
                </div>
              </div>
            </v-col>
          </v-row>
        </v-card-text>
        <v-divider />
        <div v-if="viewTireMountedLabel || viewTireRetiredLabel || viewTireServiceDays != null" class="d-flex flex-wrap align-center ga-2 pa-4" style="background: #f8fafc">
          <v-chip v-if="viewTireMountedLabel" size="small" variant="flat" color="primary" prepend-icon="mdi-calendar-arrow-right">
            Mounted {{ viewTireMountedLabel }}
          </v-chip>
          <v-chip v-if="viewTireRetiredLabel" size="small" variant="flat" color="error" class="font-weight-bold" prepend-icon="mdi-archive-outline">
            Retired {{ viewTireRetiredLabel }}
          </v-chip>
          <v-chip v-if="viewTireServiceDays != null" size="small" variant="outlined" color="secondary" prepend-icon="mdi-calendar-clock">
            {{ viewTireServiceDays }} day{{ viewTireServiceDays === 1 ? '' : 's' }} in service
          </v-chip>
        </div>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="viewDialogVisible = false">Close</v-btn>
          <v-btn color="warning" prepend-icon="mdi-pencil-outline" variant="tonal" @click="viewDialogVisible = false; openTireDialog(viewTireItem)">Edit</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Reason dialog (Unmount / Retire) -->
    <v-dialog v-model="reasonDialogVisible" max-width="520" scroll-strategy="none">
      <v-card rounded="xl" class="overflow-hidden">
        <v-card-title class="bg-primary text-white d-flex align-center ga-2 pr-3">
          <v-icon size="20" color="white">{{ reasonDialog.icon }}</v-icon>
          <span class="text-h6 font-weight-bold">{{ reasonDialog.title }}</span>
          <v-spacer />
          <v-btn icon="mdi-close" size="small" variant="text" color="white" title="Cancel" @click="reasonDialogVisible = false" />
        </v-card-title>
        <v-card-text class="pt-5">
          <p v-if="reasonDialog.tire" class="text-body-2 text-medium-emphasis mb-3">
            {{ reasonDialog.tire.serial_number }} — {{ reasonDialog.tire.brand }} {{ reasonDialog.tire.model || '' }}
          </p>
          <v-alert v-if="reasonDialog.alert" :type="reasonDialog.alertType" variant="tonal" density="compact" class="mb-4">
            {{ reasonDialog.alert }}
          </v-alert>
          <v-textarea
            v-model="reasonDialog.reason"
            :label="reasonDialog.reasonLabel"
            rows="3"
            prepend-inner-icon="mdi-note-text-outline"
            hide-details="auto"
            :rules="[v => !!v && v.trim().length > 0 || 'Reason is required']"
            autofocus
          />
          <div class="mt-3">
            <p class="text-caption text-medium-emphasis mb-2">Quick select</p>
            <div class="d-flex flex-wrap ga-1">
              <v-chip
                v-for="opt in reasonOptions"
                :key="opt"
                size="small"
                :color="reasonDialog.reason === opt ? reasonDialog.confirmColor : 'default'"
                :variant="reasonDialog.reason === opt ? 'flat' : 'outlined'"
                label
                @click="reasonDialog.reason = opt"
              >
                {{ opt }}
              </v-chip>
            </div>
          </div>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="reasonDialogVisible = false">Cancel</v-btn>
          <v-btn :color="reasonDialog.confirmColor" prepend-icon="mdi-check" :loading="reasonDialog.loading" :disabled="!reasonDialog.reason || !reasonDialog.reason.trim()" @click="confirmReasonAction">
            {{ reasonDialog.confirmText }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
const { $api, $swal } = useNuxtApp()
const { currencySymbol } = useCurrency()
const tab = ref('inventory')
const search = ref('')
const filterCondition = ref<string[]>([])
const filterStatus = ref<string[]>([])
const filterBrand = ref<string>('')
const filterVehicle = ref<string>('')

const filterStatusOptions = [
  { value: 'in_stock', label: 'In Stock', color: 'grey' },
  { value: 'mounted', label: 'Mounted', color: 'success' },
  { value: 'spare', label: 'Spare', color: 'info' },
  { value: 'retired', label: 'Retired', color: 'error' },
  { value: 'scrapped', label: 'Scrapped', color: 'grey-darken-1' },
]
const filterConditionOptions = [
  { value: 'new', label: 'New', color: 'success' },
  { value: 'second_hand', label: 'Second Hand', color: 'amber' },
  { value: 'retreaded', label: 'Retreaded', color: 'purple' },
  { value: 'reclaimed', label: 'Reclaimed', color: 'teal' },
  { value: 'used', label: 'Used', color: 'warning' },
]

// --- Vehicles ---
const { data: vehicleData } = useAsyncData('tire-vehicles', () => $api('/vehicles/vehicles/'), { default: () => ({ results: [] }) })
const vehicleOptions = computed(() => vehicleData.value?.results || [])

// --- Tire catalog (brand / size / model options) ---
const { data: catalogData } = useAsyncData('tire-catalog', () => $api('/tires/catalog/').catch(() => ({ brands: [], sizes: [], models: [] })), { default: () => ({ brands: [], sizes: [], models: [] }) })
const brandOptions = computed(() => catalogData.value?.brands || [])
const sizeOptions = computed(() => catalogData.value?.sizes || [])
const modelOptions = computed(() => {
  const brand = tireForm.brand
  const models = catalogData.value?.models || []
  if (!brand) return models.map((m: any) => m.model)
  return models.filter((m: any) => m.brand === brand).map((m: any) => m.model)
})
const minTreadDepthOptions = computed(() => catalogData.value?.min_tread_depth_options || [2, 3, 4, 5, 6, 8])
const warrantyMilesOptions = computed(() => catalogData.value?.warranty_miles_options || [30000, 50000, 70000, 100000, 125000, 150000, 200000])

// --- Tires ---
const { data: tireData, pending: tiresPending, refresh: refreshTires } = useAsyncData(
  'tires-list',
  () => $api('/tires/'),
  { default: () => ({ results: [] }) }
)
const tires = computed(() => tireData.value?.results || tireData.value || [])
const filteredTires = computed(() => {
  let list = tires.value as any[]
  if (filterCondition.value.length) list = list.filter((t) => filterCondition.value.includes(t.condition))
  if (filterStatus.value.length) list = list.filter((t) => filterStatus.value.includes(t.status))
  if (filterBrand.value) list = list.filter((t) => (t.brand || '') === filterBrand.value)
  if (filterVehicle.value.trim()) {
    const q = filterVehicle.value.trim().toLowerCase()
    list = list.filter((t) => (t.vehicle_license_plate || '').toLowerCase().includes(q) || (t.vehicle_name || '').toLowerCase().includes(q))
  }
  return list
})
const activeFilterCount = computed(() =>
  filterCondition.value.length + filterStatus.value.length + (filterBrand.value ? 1 : 0) + (filterVehicle.value.trim() ? 1 : 0)
)
function clearFilters() {
  filterCondition.value = []
  filterStatus.value = []
  filterBrand.value = ''
  filterVehicle.value = ''
}
const tirePage = ref(1)
const tirePerPage = ref(15)

// Map tire id -> latest mount performed_at (so the table can show it)
const tireMountedAt = computed(() => {
  // Prefer backend last_mount_date from each tire row when present.
  const map: Record<number, string> = {}
  ;(tires.value as any[]).forEach((t: any) => {
    if (t.last_mount_date) map[t.id] = t.last_mount_date
  })
  // Fill from movements for rows missing the field.
  ;(movements.value as any[])
    .filter((m: any) => m.movement_type === 'mount' && m.performed_at && m.tire)
    .forEach((m: any) => {
      const cur = map[m.tire]
      if (!cur || new Date(m.performed_at).getTime() > new Date(cur).getTime()) map[m.tire] = m.performed_at
    })
  return map
})

// Map tire id -> retire performed_at (the unmount that ended its service life).
// Prefer backend retired_date on the tire row, fall back to movement analysis.
const tireRetiredAt = computed(() => {
  const map: Record<number, string> = {}
  ;(tires.value as any[]).forEach((t: any) => {
    if (t.retired_date) map[t.id] = t.retired_date
  })
  const byTire: Record<number, any[]> = {}
  ;(movements.value as any[])
    .filter((m: any) => (m.movement_type === 'mount' || m.movement_type === 'unmount') && m.performed_at && m.tire)
    .forEach((m: any) => {
      (byTire[m.tire] ||= []).push(m)
    })
  for (const [tid, ms] of Object.entries(byTire)) {
    ms.sort((a: any, b: any) => new Date(a.performed_at).getTime() - new Date(b.performed_at).getTime())
    let lastMount: string | null = null
    for (const m of ms) {
      if (m.movement_type === 'mount') lastMount = m.performed_at
      else if (m.movement_type === 'unmount') {
        // Pattern: mount ... unmount → unmount that has no following mount is the retire
        map[Number(tid)] = m.performed_at
      }
    }
    // If still mounted, the last record is a mount → not retired
    if (lastMount && ms[ms.length - 1].movement_type === 'mount') delete map[Number(tid)]
  }
  return map
})

// Whole days between two dates (b - a), or null if either is missing.
function daysBetween(a: any, b: any): number | null {
  if (!a || !b) return null
  const da = new Date(a), db = new Date(b)
  if (Number.isNaN(da.getTime()) || Number.isNaN(db.getTime())) return null
  return Math.max(0, Math.round((db.getTime() - da.getTime()) / 86400000))
}

const tireHeaders = [
  { title: '#', key: 'index', width: '50px', sortable: false },
  { title: 'Serial / Brand', key: 'serial_number', sortable: true },
  { title: 'Type', key: 'type', width: '110px' },
  { title: 'Condition', key: 'condition', width: '120px', sortable: true },
  { title: 'Status', key: 'status', width: '120px', sortable: true },
  { title: 'Vehicle', key: 'vehicle_name', sortable: true },
  { title: 'Mounted On', key: 'mounted_on', width: '170px', sortable: true },
  { title: 'Days Used', key: 'days_used', width: '110px', sortable: true },
  { title: 'Price', key: 'purchase_price', width: '100px', sortable: true },
  { title: '', key: 'actions', width: '60px', align: 'end' as const, sortable: false },
]

// --- Stats ---
const stats = computed(() => {
  const list = tires.value
  const brands = new Set(list.map(t => t.brand).filter(Boolean))
  const sizes = new Set(list.map(t => t.size).filter(Boolean))
  const countOf = (s: string) => list.filter(t => t.status === s).length
  return {
    total: list.length,
    mounted: countOf('mounted'),
    inStock: countOf('in_stock'),
    spare: countOf('spare'),
    needsReplacement: list.filter(t => t.needs_replacement).length,
    retired: list.filter(t => t.status === 'retired' || t.status === 'scrapped').length,
    brands: brands.size,
    sizes: sizes.size,
    inventoryValue: list.reduce((sum, t) => sum + Number(t.purchase_price || 0), 0),
  }
})

// --- Inspections ---
const { data: inspectionData, pending: inspectionsPending, refresh: refreshInspections } = useAsyncData(
  'tire-inspections',
  () => $api('/tires/inspections/'),
  { default: () => ({ results: [] }) }
)
const inspections = computed(() => inspectionData.value?.results || inspectionData.value || [])
const inspectionHeaders = [
  { title: 'Tire', key: 'tire', sortable: true },
  { title: 'Vehicle', key: 'vehicle', sortable: true },
  { title: 'Tread', key: 'tread_depth', width: '100px' },
  { title: 'Pressure', key: 'pressure_psi', width: '100px' },
  { title: 'Condition', key: 'condition', width: '110px' },
  { title: 'Odometer', key: 'odometer', width: '110px' },
  { title: 'Measured', key: 'measured_at', width: '120px', sortable: true },
  { title: '', key: 'actions', width: '90px', sortable: false },
]

// --- Rotations ---
const { data: rotationData, pending: rotationsPending, refresh: refreshRotations } = useAsyncData(
  'tire-rotations',
  () => $api('/tires/rotations/'),
  { default: () => ({ results: [] }) }
)
const rotations = computed(() => rotationData.value?.results || rotationData.value || [])
const rotationHeaders = [
  { title: 'Vehicle', key: 'vehicle', sortable: true },
  { title: 'Pattern', key: 'rotation_pattern', width: '160px' },
  { title: 'Swaps', key: 'swaps', width: '100px', sortable: false },
  { title: 'Odometer', key: 'odometer', width: '110px' },
  { title: 'Performed', key: 'performed_at', width: '170px', sortable: true },
  { title: 'Notes', key: 'notes', width: '200px' },
  { title: '', key: 'actions', width: '110px', sortable: false },
]

// --- Movements ---
const { data: movementData, pending: movementsPending } = useAsyncData(
  'tire-movements',
  () => $api('/tires/movements/'),
  { default: () => ({ results: [] }) }
)
const movements = computed(() => movementData.value?.results || movementData.value || [])
const movementHeaders = [
  { title: 'Tire', key: 'tire_serial', width: '140px', sortable: true },
  { title: 'Type', key: 'movement_type', width: '110px', sortable: true },
  { title: 'From', key: 'from' },
  { title: 'To', key: 'to' },
  { title: 'Odometer', key: 'odometer', width: '110px' },
  { title: 'Performed', key: 'performed_at', width: '120px', sortable: true },
  { title: 'Notes', key: 'notes' },
]

// --- Options ---
const tireTypeOptions = ['Steer', 'Drive', 'Trailer', 'All-Position', 'Spare']
const tireConditionOptions = [
  { label: 'New', value: 'new' },
  { label: 'Second Hand', value: 'second_hand' },
  { label: 'Retreaded', value: 'retreaded' },
  { label: 'Reclaimed', value: 'reclaimed' },
  { label: 'Used', value: 'used' },
]
const statusOptions = [
  { label: 'In Stock', value: 'in_stock' },
  { label: 'Mounted', value: 'mounted' },
  { label: 'Spare', value: 'spare' },
  { label: 'Retired', value: 'retired' },
  { label: 'Scrapped', value: 'scrapped' },
]
const positionOptions = ['FL_Outer', 'FL_Inner', 'FR_Outer', 'FR_Inner', 'RL_Outer', 'RL_Inner', 'RR_Outer', 'RR_Inner', 'Spare']
const conditionOptions = ['good', 'ok', 'worn', 'damaged']
const rotationPatterns = ['Front-to-Rear', 'Rear-to-Front', 'X-Pattern', 'Forward Cross', 'Rearward Cross', 'Side-to-Side']

const tireSelectOptions = computed(() => tires.value.map((t: any) => ({ id: t.id, label: `${t.serial_number} · ${t.brand} ${t.size || ''}`.trim() })))

// --- Helpers ---
function statusColor(s: string) {
  return { in_stock: 'grey', mounted: 'success', spare: 'info', retired: 'error', scrapped: 'grey-darken-1' }[s] || 'default'
}
function statusLabel(s: string) {
  return ({ in_stock: 'In Stock', mounted: 'Mounted', spare: 'Spare', retired: 'Retired', scrapped: 'Scrapped' }[s] || s)
}
function conditionLabel(c: string) {
  return ({ new: 'New', second_hand: 'Second Hand', retreaded: 'Retreaded', reclaimed: 'Reclaimed', used: 'Used' }[c] || c)
}
function conditionChipColor(c: string) {
  return { new: 'success', second_hand: 'amber', retreaded: 'purple', reclaimed: 'teal', used: 'warning' }[c] || 'default'
}
function conditionColor(c: string) {
  return { good: 'success', ok: 'info', worn: 'warning', damaged: 'error' }[c] || 'default'
}
function movementColor(m: string) {
  return { mount: 'success', unmount: 'warning', transfer: 'info', retread: 'purple' }[m] || 'default'
}

function treadPercent(t: any) {
  if (t.latest_tread_depth == null) return 0
  const fresh = 14
  const pct = Math.max(0, Math.min(100, (t.latest_tread_depth / fresh) * 100))
  return Math.round(pct)
}
function treadColor(t: any) {
  if (t.latest_tread_depth == null) return 'grey'
  if (t.needs_replacement) return 'error'
  if (t.latest_tread_depth <= (t.min_tread_depth || 4) + 2) return 'warning'
  return 'success'
}
function treadColorHex(t: any) {
  if (t.latest_tread_depth == null) return '#94a3b8'
  if (t.needs_replacement) return '#ef4444'
  if (t.latest_tread_depth <= (t.min_tread_depth || 4) + 2) return '#f59e0b'
  return '#10b981'
}

// --- Tire dialog ---
const tireDialogVisible = ref(false)
const editingTire = ref<any>(null)
const tireSaving = ref(false)
const tireErrors = ref<string[]>([])
const tireForm = reactive<any>({
  serial_number: '', brand: '', model: '', size: '', type: '', condition: 'new', status: 'in_stock',
  purchase_price: null, purchase_date: '', warranty_miles: null, min_tread_depth: 4,
})

function resetTireForm() {
  Object.assign(tireForm, {
    serial_number: '', brand: '', model: '', size: '', type: '', condition: 'new', status: 'in_stock',
    purchase_price: null, purchase_date: '', warranty_miles: null, min_tread_depth: 4,
  })
}
function openTireDialog(tire?: any) {
  tireErrors.value = []
  editingTire.value = tire || null
  if (tire) {
    Object.assign(tireForm, {
      serial_number: tire.serial_number || '', brand: tire.brand || '', model: tire.model || '',
      size: tire.size || '', type: tire.type || '', condition: tire.condition || 'new', status: tire.status || 'in_stock',
      purchase_price: tire.purchase_price ?? null, purchase_date: tire.purchase_date || '',
      warranty_miles: tire.warranty_miles ?? null, min_tread_depth: tire.min_tread_depth ?? 4,
    })
  } else {
    resetTireForm()
  }
  tireDialogVisible.value = true
}

async function saveTire(keepOpen = false) {
  tireErrors.value = []
  if (!tireForm.serial_number) {
    tireErrors.value = ['Serial number is required.']
    return
  }
  tireSaving.value = true
  try {
    const payload: any = { ...tireForm }
    if (editingTire.value) {
      await $api(`/tires/${editingTire.value.id}/`, { method: 'PATCH', body: payload })
    } else {
      delete payload.id
      await $api('/tires/', { method: 'POST', body: payload })
    }
    await refreshTires()
    $swal.fire({ icon: 'success', title: editingTire.value ? 'Updated' : 'Tire added', timer: 1600, toast: true, position: 'top-end' })
    if (keepOpen && !editingTire.value) {
      resetTireForm()
    } else {
      tireDialogVisible.value = false
    }
  } catch (e: any) {
    console.error(e)
    const data = e?.data
    if (data && typeof data === 'object') {
      tireErrors.value = Object.entries(data).map(([k, v]) => {
        const label = k.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())
        const val = Array.isArray(v) ? v.join(', ') : String(v)
        return `${label}: ${val}`
      })
    } else {
      tireErrors.value = [data?.detail || e?.message || 'Could not save tire.']
    }
  } finally { tireSaving.value = false }
}

async function deleteTire(tire: any) {
  const r = await $swal.fire({ icon: 'warning', title: 'Delete tire?', text: `Delete ${tire.serial_number}? This cannot be undone.`, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!r.isConfirmed) return
  try {
    await $api(`/tires/${tire.id}/`, { method: 'DELETE' })
    await refreshTires()
    $swal.fire({ icon: 'success', title: 'Deleted', timer: 1500, toast: true, position: 'top-end' })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Delete failed', text: e?.data?.detail || e?.message || 'Could not delete' })
  }
}

// --- Mount / Unmount / Retire ---
function openMountDialog(tire: any) {
  navigateTo(`/app/tires/mount?tire=${tire.id}`)
}

// Reason dialog (shared by unmount + retire)
const reasonDialogVisible = ref(false)
const reasonDialog = reactive<any>({
  action: '', title: '', icon: '', reasonLabel: 'Reason',
  confirmText: 'Confirm', confirmColor: 'primary', alert: '', alertType: 'warning',
  tire: null as any, reason: '', loading: false,
})

// Common selectable reasons
const unmountReasonOptions = [
  'Seasonal changeover',
  'Rotation',
  'Tread below threshold',
  'Damage / puncture',
  'Repair needed',
  'Vehicle change',
  'Storage',
]
const retireReasonOptions = [
  'Tread worn out',
  'Sidewall damage',
  'Beyond repair',
  'Age / dry rot',
  'Irreparable puncture',
  'Failed inspection',
  'End of lifecycle',
  'Scrap for recycling',
]
const reasonOptions = computed(() => reasonDialog.action === 'retire' ? retireReasonOptions : unmountReasonOptions)

function openReasonDialog(action: 'unmount' | 'retire', tire: any) {
  reasonDialog.action = action
  reasonDialog.tire = tire
  reasonDialog.reason = ''
  reasonDialog.loading = false
  if (action === 'unmount') {
    reasonDialog.title = 'Unmount Tire'
    reasonDialog.icon = 'mdi-arrow-down-bold-hexagon-outline'
    reasonDialog.reasonLabel = 'Reason for unmounting'
    reasonDialog.confirmText = 'Unmount'
    reasonDialog.confirmColor = 'warning'
    reasonDialog.alert = `${tire.serial_number} will be removed from its vehicle and returned to in-stock inventory.`
    reasonDialog.alertType = 'warning'
  } else {
    reasonDialog.title = 'Retire Tire'
    reasonDialog.icon = 'mdi-archive-outline'
    reasonDialog.reasonLabel = 'Reason for retiring'
    reasonDialog.confirmText = 'Retire'
    reasonDialog.confirmColor = 'error'
    reasonDialog.alert = `${tire.serial_number} will be marked retired, removed from its vehicle and no longer tracked.`
    reasonDialog.alertType = 'error'
  }
  reasonDialogVisible.value = true
}

async function confirmReasonAction() {
  const action = reasonDialog.action
  const tire = reasonDialog.tire
  if (!tire) return
  const reason = (reasonDialog.reason || '').trim()
  if (!reason) {
    $swal.fire({ icon: 'warning', title: 'Reason required', text: 'Please provide a reason before continuing.', timer: 2200, toast: true, position: 'top-end' })
    return
  }
  reasonDialog.loading = true
  const payload: any = { notes: reason }
  try {
    if (action === 'unmount') {
      await $api(`/tires/${tire.id}/unmount/`, { method: 'POST', body: payload })
      $swal.fire({ icon: 'success', title: 'Unmounted', timer: 1500, toast: true, position: 'top-end' })
    } else if (action === 'retire') {
      await $api(`/tires/${tire.id}/retire/`, { method: 'POST', body: payload })
      $swal.fire({ icon: 'success', title: 'Retired', timer: 1500, toast: true, position: 'top-end' })
    }
    await refreshTires()
    reasonDialogVisible.value = false
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: action === 'unmount' ? 'Unmount failed' : 'Retire failed', text: e?.data?.detail || e?.message || 'Could not complete' })
  } finally {
    reasonDialog.loading = false
  }
}

function unmountTire(tire: any) {
  openReasonDialog('unmount', tire)
}

function retireTire(tire: any) {
  openReasonDialog('retire', tire)
}

// --- View dialogs ---
const viewDialogVisible = ref(false)
const viewTireItem = ref<any>(null)
const viewTireInspections = computed(() => {
  if (!viewTireItem.value) return []
  return inspections.value.filter((i: any) => i.tire === viewTireItem.value.id).slice(0, 5)
})
function viewTire(tire: any) {
  viewTireItem.value = tire
  viewDialogVisible.value = true
}

// Latest mount date for the tire being viewed.
// Prefer the backend-exposed last_mount_date (always populated when the tire is mounted),
// and fall back to the movements list if the field is missing.
const viewTireMountedAt = computed(() => {
  const tire = viewTireItem.value
  if (!tire) return null
  if (tire.last_mount_date) return tire.last_mount_date
  const ms = (movements.value as any[])
    .filter((m: any) => m.tire === tire.id && m.movement_type === 'mount' && m.performed_at)
    .sort((a: any, b: any) => new Date(b.performed_at).getTime() - new Date(a.performed_at).getTime())
  return ms.length ? ms[0].performed_at : null
})
const viewTireMountedLabel = computed(() => {
  const d = viewTireMountedAt.value
  if (!d) return ''
  try { return formatOrdinalDate(d) } catch { return String(d) }
})

// Retire date for the tire being viewed. Prefer backend retired_date field.
const viewTireRetiredAt = computed(() => {
  const tire = viewTireItem.value
  if (!tire) return null
  if (tire.retired_date) return tire.retired_date
  const ms = (movements.value as any[])
    .filter((m: any) => m.tire === tire.id && (m.movement_type === 'mount' || m.movement_type === 'unmount') && m.performed_at)
    .sort((a: any, b: any) => new Date(a.performed_at).getTime() - new Date(b.performed_at).getTime())
  let lastMountWasLast = false
  for (const m of ms) if (m.movement_type === 'mount') lastMountWasLast = true; else lastMountWasLast = false
  if (lastMountWasLast || !ms.length) return null
  return ms[ms.length - 1].performed_at
})
const viewTireRetiredLabel = computed(() => {
  const d = viewTireRetiredAt.value
  if (!d) return ''
  try { return formatOrdinalDate(d) } catch { return String(d) }
})
const viewTireServiceDays = computed(() => {
  const m = viewTireMountedAt.value, r = viewTireRetiredAt.value
  if (!m) return null
  return daysBetween(m, r || new Date().toISOString().slice(0, 10))
})

// Date formatter: "Wed, June 24th, 2026"
function formatOrdinalDate(value: any): string {
  if (!value) return ''
  const d = new Date(value)
  if (Number.isNaN(d.getTime())) return String(value)
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
  const months = ['January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December']
  const ord = (n: number) => {
    const s = ['th', 'st', 'nd', 'rd']
    const v = n % 100
    return n + (s[(v - 20) % 10] || s[v] || s[0])
  }
  return `${days[d.getDay()]}, ${months[d.getMonth()]} ${ord(d.getDate())}, ${d.getFullYear()}`
}

// Axle position helpers
const positionLabels: Record<string, string> = { FL: 'Front Left', FR: 'Front Right', RL: 'Rear Left', RR: 'Rear Right', Spare: 'Spare' }
function formatPosition(pos: string): string {
  if (!pos) return '—'
  if (pos === 'Spare') return 'Spare'
  const [axle, side] = pos.split('_')
  const axleLabel = positionLabels[axle] || axle
  return side ? `${axleLabel} – ${side}` : axleLabel
}
function positionIcon(pos: string): string {
  if (!pos) return 'mdi-crosshairs-gps'
  if (pos === 'Spare') return 'mdi-spare'
  return pos.startsWith('F') ? 'mdi-steering' : 'mdi-tire'
}
function positionIconColor(pos: string): string {
  if (pos === 'Spare') return 'grey'
  return pos.startsWith('F') ? 'primary' : 'info'
}

// --- Rotation view dialog ---
const viewRotationDialogVisible = ref(false)
const viewRotationItem = ref<any>(null)
// Resolve swaps for display, falling back to JSON embedded in notes.
function resolveRotationSwaps(rot: any): any[] {
  if (Array.isArray(rot.swaps_detail) && rot.swaps_detail.length) return rot.swaps_detail
  if (Array.isArray(rot.swaps) && rot.swaps.length) return rot.swaps
  if (typeof rot.notes === 'string') {
    const m = rot.notes.match(/\[[\s\S]*\]/)
    if (m) { try { const p = JSON.parse(m[0]); if (Array.isArray(p)) return p } catch { /* ignore */ } }
  }
  return []
}
function viewRotation(rot: any) {
  const resolved = resolveRotationSwaps(rot)
  viewRotationItem.value = { ...rot, swaps_detail: resolved }
  viewRotationDialogVisible.value = true
}

// --- Inspection dialog ---
const inspectionDialogVisible = ref(false)
const editingInspection = ref<any>(null)
const inspectionSaving = ref(false)
const inspectionForm = reactive<any>({
  tire: null, vehicle: null, tread_depth: null, pressure_psi: null, odometer: null, position: '', condition: 'ok', measured_at: new Date().toISOString().slice(0, 10), notes: '',
})

function resetInspectionForm() {
  Object.assign(inspectionForm, { tire: null, vehicle: null, tread_depth: null, pressure_psi: null, odometer: null, position: '', condition: 'ok', measured_at: new Date().toISOString().slice(0, 10), notes: '' })
}
function openInspectionDialog(ins?: any) {
  editingInspection.value = ins || null
  if (ins) {
    Object.assign(inspectionForm, {
      tire: ins.tire, vehicle: ins.vehicle, tread_depth: ins.tread_depth, pressure_psi: ins.pressure_psi,
      odometer: ins.odometer, position: ins.position || '', condition: ins.condition || 'ok',
      measured_at: ins.measured_at ? ins.measured_at.slice(0, 10) : '', notes: ins.notes || '',
    })
  } else {
    resetInspectionForm()
  }
  inspectionDialogVisible.value = true
}

async function saveInspection() {
  if (!inspectionForm.tire || inspectionForm.tread_depth == null) {
    $swal.fire({ icon: 'error', title: 'Fields required', text: 'Tire and tread depth are required.', timer: 2500, toast: true, position: 'top-end' })
    return
  }
  inspectionSaving.value = true
  try {
    const payload = { ...inspectionForm }
    Object.keys(payload).forEach((k) => { if (payload[k] === '' || payload[k] === null) delete payload[k] })
    if (editingInspection.value) {
      await $api(`/tires/inspections/${editingInspection.value.id}/`, { method: 'PATCH', body: payload })
    } else {
      await $api('/tires/inspections/', { method: 'POST', body: payload })
    }
    await refreshInspections()
    await refreshTires()
    inspectionDialogVisible.value = false
    $swal.fire({ icon: 'success', title: 'Inspection saved', timer: 1600, toast: true, position: 'top-end' })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Save failed', text: e?.data?.detail || e?.message || 'Could not save inspection' })
  } finally { inspectionSaving.value = false }
}

async function deleteInspection(ins: any) {
  const r = await $swal.fire({ icon: 'warning', title: 'Delete inspection?', showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!r.isConfirmed) return
  try {
    await $api(`/tires/inspections/${ins.id}/`, { method: 'DELETE' })
    await refreshInspections()
    await refreshTires()
    $swal.fire({ icon: 'success', title: 'Deleted', timer: 1500, toast: true, position: 'top-end' })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Delete failed', text: e?.data?.detail || e?.message || 'Could not delete' })
  }
}

// --- Rotation dialog ---
const rotationDialogVisible = ref(false)
const editingRotation = ref<any>(null)
const rotationSaving = ref(false)
const rotationForm = reactive<any>({
  vehicle: null, rotation_pattern: '', odometer: null, performed_at: new Date().toISOString().slice(0, 10), notes: '',
})
// Edit-mode rotation axle diagram state
const rotationEditTirePositions = ref<any[]>([])
const rotationEditSelected = ref(0)
const rotationEditSelectedPosition = computed(() => rotationEditTirePositions.value[rotationEditSelected.value]?.to_position || '')
const rotationEditSelectedTire = computed(() => rotationEditTirePositions.value[rotationEditSelected.value] || null)
const rotationEditVehicle = computed(() => {
  const vid = rotationForm.vehicle
  if (!vid) return null
  return (vehicleOptions.value as any[]).find((v) => v.id === vid) || null
})

function resetRotationForm() {
  Object.assign(rotationForm, { vehicle: null, rotation_pattern: '', odometer: null, performed_at: new Date().toISOString().slice(0, 10), notes: '' })
  rotationEditTirePositions.value = []
  rotationEditSelected.value = 0
}
function openRotationDialog(rot?: any) {
  editingRotation.value = rot || null
  if (rot) {
    Object.assign(rotationForm, {
      vehicle: rot.vehicle, rotation_pattern: rot.rotation_pattern || '', odometer: rot.odometer,
      performed_at: rot.performed_at ? rot.performed_at.slice(0, 10) : '', notes: rot.notes || '',
    })
    // Resolve the swap list. Prefer the structured swaps_detail / swaps field.
    // When those are missing, the swap info may be embedded as a JSON array in the
    // notes string (e.g. "Swaps: [{...}]") — parse it out so the axle editor still works.
    let swaps: any[] = []
    if (Array.isArray(rot.swaps_detail) && rot.swaps_detail.length) swaps = rot.swaps_detail
    else if (Array.isArray(rot.swaps) && rot.swaps.length) swaps = rot.swaps
    else if (typeof rot.notes === 'string') {
      const m = rot.notes.match(/\[[\s\S]*\]/)
      if (m) {
        try {
          const parsed = JSON.parse(m[0])
          if (Array.isArray(parsed)) swaps = parsed
        } catch { /* ignore parse failures */ }
      }
    }
    rotationEditTirePositions.value = swaps.map((s: any) => ({
      tire: s.tire, tire_serial: s.tire_serial, tire_brand: s.tire_brand, tire_size: s.tire_size,
      from_position: s.from_position || '', to_position: s.to_position || '',
    }))
    rotationEditSelected.value = 0
  } else {
    resetRotationForm()
  }
  rotationDialogVisible.value = true
}

async function saveRotation() {
  if (!rotationForm.vehicle) {
    $swal.fire({ icon: 'error', title: 'Vehicle required', text: 'Please select a vehicle.', timer: 2500, toast: true, position: 'top-end' })
    return
  }
  rotationSaving.value = true
  try {
    const payload: any = { ...rotationForm }
    // When editing, push updated swap positions from the axle editor
    if (editingRotation.value && rotationEditTirePositions.value.length) {
      payload.swaps = rotationEditTirePositions.value.map((s) => ({
        tire: s.tire, from_position: s.from_position, to_position: s.to_position,
      }))
    }
    Object.keys(payload).forEach((k) => { if (payload[k] === '' || payload[k] === null) delete payload[k] })
    if (editingRotation.value) {
      await $api(`/tires/rotations/${editingRotation.value.id}/`, { method: 'PATCH', body: payload })
    } else {
      await $api('/tires/rotations/', { method: 'POST', body: payload })
    }
    await refreshRotations()
    rotationDialogVisible.value = false
    $swal.fire({ icon: 'success', title: 'Rotation saved', timer: 1600, toast: true, position: 'top-end' })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Save failed', text: e?.data?.detail || e?.message || 'Could not save rotation' })
  } finally { rotationSaving.value = false }
}

async function deleteRotation(rot: any) {
  const r = await $swal.fire({ icon: 'warning', title: 'Delete rotation?', showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!r.isConfirmed) return
  try {
    await $api(`/tires/rotations/${rot.id}/`, { method: 'DELETE' })
    await refreshRotations()
    $swal.fire({ icon: 'success', title: 'Deleted', timer: 1500, toast: true, position: 'top-end' })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Delete failed', text: e?.data?.detail || e?.message || 'Could not delete' })
  }
}

// --- Analytics charts ---
const palette = ['#6366f1', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4', '#ec4899', '#84cc16']

const statusChartOption = computed(() => {
  const items = (['in_stock', 'mounted', 'spare', 'retired', 'scrapped'] as string[])
    .map((s) => ({ name: statusLabel(s), value: tires.value.filter((t: any) => t.status === s).length }))
    .filter((s) => s.value > 0)
  return {
    tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
    legend: { bottom: 0, textStyle: { fontSize: 11 } },
    color: ['#94a3b8', '#10b981', '#06b6d4', '#ef4444', '#64748b'],
    series: [{ type: 'pie', radius: ['42%', '70%'], avoidLabelOverlap: false, itemStyle: { borderRadius: 8, borderColor: '#fff', borderWidth: 2 }, label: { show: false }, emphasis: { label: { show: true, fontSize: 14, fontWeight: 'bold' } }, data: items }],
  }
})

const typeChartOption = computed(() => {
  const counts: Record<string, number> = {}
  tires.value.forEach((t: any) => { const k = t.type || 'Unspecified'; counts[k] = (counts[k] || 0) + 1 })
  const items = Object.entries(counts).map(([name, value]) => ({ name, value }))
  return {
    tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
    legend: { bottom: 0, textStyle: { fontSize: 11 } },
    color: palette,
    series: [{ type: 'pie', radius: ['40%', '68%'], itemStyle: { borderRadius: 8, borderColor: '#fff', borderWidth: 2 }, label: { show: false }, data: items }],
  }
})

const brandChartOption = computed(() => {
  const counts: Record<string, number> = {}
  tires.value.forEach((t: any) => { if (t.brand) counts[t.brand] = (counts[t.brand] || 0) + 1 })
  const items = Object.entries(counts).sort((a, b) => b[1] - a[1]).slice(0, 10)
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: items.map((i) => i[0]), axisLabel: { fontSize: 11, rotate: 25 } },
    yAxis: { type: 'value' },
    color: ['#818cf8'],
    series: [{ type: 'bar', data: items.map((i) => i[1]), itemStyle: { borderRadius: [6, 6, 0, 0], color: '#818cf8' }, barWidth: '50%' }],
  }
})

const treadHealthOption = computed(() => {
  const buckets = { 'Critical (<4)': 0, 'Low (4-6)': 0, 'Fair (6-9)': 0, 'Good (9+)': 0, 'No Reading': 0 }
  tires.value.forEach((t: any) => {
    const d = t.latest_tread_depth
    if (d == null) buckets['No Reading']++
    else if (d < 4) buckets['Critical (<4)']++
    else if (d < 6) buckets['Low (4-6)']++
    else if (d < 9) buckets['Fair (6-9)']++
    else buckets['Good (9+)']++
  })
  const labels = Object.keys(buckets)
  const values = Object.values(buckets)
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: labels, axisLabel: { fontSize: 11 } },
    yAxis: { type: 'value' },
    color: ['#6366f1'],
    series: [{ type: 'bar', data: values.map((v, i) => ({ value: v, itemStyle: { color: ['#ef4444', '#f59e0b', '#facc15', '#10b981', '#94a3b8'][i] } })), itemStyle: { borderRadius: [6, 6, 0, 0] }, barWidth: '45%' }],
  }
})

const needsReplacementTires = computed(() => tires.value.filter((t: any) => t.needs_replacement))
</script>

<style scoped>
/* Premium filter toolbar */
.filter-toolbar {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
  padding: 14px 16px;
  margin-bottom: 16px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
}
.filter-field {
  flex: 0 0 auto;
}
.filter-grow {
  flex: 1 1 0;
  min-width: 160px;
}
.filter-field :deep(.v-field__outline__start),
.filter-field :deep(.v-field__outline__end) {
  border-color: #cbd5e1;
}
.filter-field :deep(.v-field--variant-outlined .v-field__outline__notch::before) {
  border-color: #cbd5e1;
}

/* Scrollable, vertically constrained preview area for the 3D axle SVG.
   The embedded SVG is rendered as a compact visual reference. */
.axle-preview-wrap {
  flex: 1 1 auto;
  overflow: auto;
  padding: 8px 12px;
  background: linear-gradient(180deg, #f1f5f9 0%, #e2e8f0 100%);
  border-top: 1px solid #e2e8f0;
  border-bottom: 1px solid #e2e8f0;
  min-height: 280px;
}
.axle-preview-wrap :deep(.axle-stage) {
  padding: 10px;
  border-radius: 12px;
  pointer-events: none;
  box-shadow: none;
}
.axle-preview-wrap :deep(.axle-svg) {
  width: 100%;
  max-width: 520px;
  margin: 0 auto;
  display: block;
}
/* Tire detail dialog premium layout */
.tire-detail-card {
  background: #ffffff;
}
.tire-detail-row {
  min-height: 100%;
}
.tire-detail-left {
  border-right: 1px solid #e2e8f0;
}
.tire-detail-right {
  background: #f8fafc;
  display: flex;
}
.tire-detail-right > div {
  width: 100%;
}
.tire-avatar {
  width: 52px;
  height: 52px;
  border-radius: 14px;
  background: #eef2ff;
  flex-shrink: 0;
}
/* Rotation detail / edit dialogs */
.rotation-detail-card,
.rotation-edit-card {
  background: #ffffff;
}
.rotation-detail-row,
.rotation-edit-row {
  min-height: 100%;
}
.rotation-detail-left {
  border-right: 1px solid #e2e8f0;
}
.rotation-detail-right,
.rotation-edit-right {
  background: #f8fafc;
  display: flex;
}
.rotation-detail-right > div,
.rotation-edit-right > div {
  width: 100%;
}
.rotation-axle-wrap {
  flex: 1 1 auto;
  overflow: auto;
  padding: 8px 12px;
  background: linear-gradient(180deg, #f1f5f9 0%, #e2e8f0 100%);
  border-top: 1px solid #e2e8f0;
  border-bottom: 1px solid #e2e8f0;
  min-height: 240px;
}
.rotation-axle-wrap :deep(.axle-stage) {
  padding: 10px;
  border-radius: 12px;
  pointer-events: none;
  box-shadow: none;
}
.rotation-axle-wrap :deep(.axle-svg) {
  width: 100%;
  max-width: 480px;
  margin: 0 auto;
  display: block;
}
.rotation-avatar {
  width: 52px;
  height: 52px;
  border-radius: 14px;
  background: #f3e8ff;
  flex-shrink: 0;
}
.swap-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 10px 12px;
  transition: border-color 0.15s ease;
}
.swap-card:hover {
  border-color: #c4b5fd;
}
.swap-num {
  width: 26px;
  height: 26px;
  border-radius: 8px;
  background: #ede9fe;
  color: #7c3aed;
  font-size: 12px;
  font-weight: 700;
  flex-shrink: 0;
}
.min-width-0 {
  min-width: 0;
}
.spec-grid .spec-label {
  font-size: 11px;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: #94a3b8;
  margin-bottom: 2px;
  font-weight: 600;
}
.spec-grid .spec-value {
  font-size: 14px;
  color: #1e293b;
  line-height: 1.4;
}
</style>
