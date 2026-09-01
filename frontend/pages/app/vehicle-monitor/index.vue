<template>
  <div class="d-flex flex-column ga-5">
    <!-- Page header -->
    <div class="d-flex flex-wrap align-center justify-space-between ga-3">
      <div>
        <h2 class="text-h5 font-weight-bold d-flex align-center ga-2" style="color: #1e293b">
          <v-icon color="primary">mdi-monitor-dashboard</v-icon>
          Vehicle Monitor
        </h2>
        <p class="text-body-2 text-medium-emphasis">
          Real-time fleet activity &mdash; rental status, live location, mileage, fuel, EV battery, alerts and maintenance
        </p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-chip color="success" variant="tonal" size="small">
          <v-icon start size="x-small">mdi-broadcast</v-icon>
          {{ summary.moving ?? 0 }} moving
        </v-chip>
        <v-chip color="warning" variant="tonal" size="small">
          <v-icon start size="x-small">mdi-clock-alert-outline</v-icon>
          {{ summary.stale ?? 0 }} stale
        </v-chip>
        <v-btn variant="outlined" prepend-icon="mdi-refresh" :loading="pending" @click="reloadAll">Refresh</v-btn>
        <v-btn
          :variant="autoRefresh ? 'flat' : 'outlined'"
          :color="autoRefresh ? 'primary' : 'medium-emphasis'"
          prepend-icon="mdi-autorenew"
          @click="toggleAutoRefresh"
        >
          Auto {{ autoRefresh ? 'On' : 'Off' }}
        </v-btn>
      </div>
    </div>

    <!-- KPI Cards -->
    <v-row dense>
      <v-col cols="6" md="3">
        <StatCard
          label="Total Vehicles"
          :value="summary.total_vehicles ?? 0"
          icon="mdi-car-multiple"
          icon-bg="#eef2ff"
          icon-color="primary"
          :subtitle="`${summary.on_rent ?? 0} on rent · ${summary.available ?? 0} available`"
        />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard
          label="On Rent"
          :value="summary.on_rent ?? 0"
          icon="mdi-car-key"
          icon-bg="#ede9fe"
          icon-color="secondary"
          :subtitle="`${summary.active_rentals ?? 0} active agreements`"
        />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard
          label="Moving Now"
          :value="summary.moving ?? 0"
          icon="mdi-truck-fast"
          icon-bg="#ecfdf5"
          icon-color="success"
          :subtitle="`${summary.stale ?? 0} stale · ${summary.offline ?? 0} offline`"
        />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard
          label="Open Alerts"
          :value="summary.open_alerts ?? 0"
          icon="mdi-bell-alert-outline"
          icon-bg="#fef2f2"
          icon-color="error"
          :subtitle="`${summary.open_issues ?? 0} open issues`"
        />
      </v-col>
    </v-row>

    <!-- Secondary KPI row -->
    <v-row dense>
      <v-col cols="6" md="3">
        <StatCard
          label="Total Fuel Used"
          :value="formatFuel(summary.total_fuel_used ?? 0)"
          icon="mdi-gas-station"
          icon-bg="#fff7ed"
          icon-color="warning"
          :subtitle="fmtMoney(summary.total_fuel_cost ?? 0)"
        />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard
          label="EV Charging"
          :value="`${summary.total_charging_kwh ?? 0} kWh`"
          icon="mdi-ev-station"
          icon-bg="#eef2ff"
          icon-color="primary"
        />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard
          label="Fleet Mileage"
          :value="formatNumber(summary.total_mileage ?? 0)"
          icon="mdi-road-variant"
          icon-bg="#ecfdf5"
          icon-color="success"
          :subtitle="`${formatNumber(summary.total_engine_hours ?? 0)} engine hrs`"
        />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard
          label="Total Services"
          :value="summary.total_services ?? 0"
          icon="mdi-wrench-outline"
          icon-bg="#f0fdf4"
          icon-color="success"
        />
      </v-col>
    </v-row>

    <!-- Tabs -->
    <v-card elevation="0" border rounded="xl" class="overflow-hidden">
      <v-tabs v-model="tab" color="primary" density="compact" show-arrows>
        <v-tab value="overview" prepend-icon="mdi-view-dashboard-outline">Overview</v-tab>
        <v-tab value="live" prepend-icon="mdi-crosshairs-gps">Live Status</v-tab>
        <v-tab value="rentals" prepend-icon="mdi-car-key">Rentals</v-tab>
        <v-tab value="maintenance" prepend-icon="mdi-wrench">Maintenance</v-tab>
        <v-tab value="energy" prepend-icon="mdi-flash">Fuel &amp; Energy</v-tab>
      </v-tabs>
      <v-divider />

      <v-window v-model="tab" class="pa-5">
        <!-- ─────────────────────── OVERVIEW ─────────────────────── -->
        <v-window-item value="overview">
          <!-- Status Donut + Filter bar -->
          <div class="d-flex flex-wrap align-center justify-space-between ga-3 mb-4">
            <div class="d-flex align-center ga-4">
              <v-sheet rounded="lg" border class="pa-3 d-flex align-center ga-3" style="min-width: 260px;">
                <v-sheet width="80" height="80" rounded="circle" :style="statusDonutStyle">
                  <div class="d-flex flex-column align-center justify-center h-100">
                    <span class="text-caption text-medium-emphasis">Total</span>
                    <span class="text-h6 font-weight-bold">{{ summary.total_vehicles ?? 0 }}</span>
                  </div>
                </v-sheet>
                <div class="d-flex flex-column ga-1">
                  <div v-for="s in statusDistribution" :key="s.label" class="d-flex align-center ga-2">
                    <v-sheet :color="s.color" width="10" height="10" rounded="circle" />
                    <span class="text-body-2">{{ s.label }}: <b>{{ s.value }}</b></span>
                  </div>
                </div>
              </v-sheet>
            </div>
          </div>

          <!-- Filter bar -->
          <div class="d-flex align-center flex-wrap ga-2 mb-4">
            <v-text-field
              v-model="search"
              prepend-inner-icon="mdi-magnify"
              placeholder="Search vin, plate, make..."
              density="compact"
              variant="outlined"
              hide-details
              clearable
              style="max-width: 320px; flex: 1 1 300px;"
            />
            <v-select
              v-model="statusFilter"
              :items="statusOptions"
              density="compact"
              variant="outlined"
              hide-details
              label="Status"
              style="max-width: 160px;"
              clearable
            />
            <v-select
              v-model="rentalStatusFilter"
              :items="rentalStatusOptions"
              density="compact"
              variant="outlined"
              hide-details
              label="Rental"
              style="max-width: 160px;"
              clearable
            />
            <v-select
              v-model="groupFilter"
              :items="groupItems"
              item-title="name"
              item-value="id"
              density="compact"
              variant="outlined"
              hide-details
              label="Group"
              style="max-width: 180px;"
              clearable
            />
            <v-switch v-model="staleOnly" density="compact" label="Stale only" color="warning" hide-details />
            <v-btn v-if="hasActiveFilters" size="small" variant="text" color="primary" prepend-icon="mdi-filter-remove-outline" @click="clearFilters">Clear</v-btn>
            <v-spacer />
            <v-btn-toggle v-model="viewMode" mandatory density="compact" variant="outlined" color="primary">
              <v-btn value="table" size="small" prepend-icon="mdi-format-list-bulleted">Table</v-btn>
              <v-btn value="cards" size="small" prepend-icon="mdi-view-grid">Cards</v-btn>
            </v-btn-toggle>
          </div>

          <VehicleMonitorTable
            v-if="viewMode === 'table'"
            :vehicles="filteredVehicles"
            :loading="pending"
            :currency-symbol="currencySymbol"
            @select="openDetail"
          />
          <VehicleMonitorCards
            v-else
            :vehicles="filteredVehicles"
            :loading="pending"
            :currency-symbol="currencySymbol"
            @select="openDetail"
          />
        </v-window-item>

        <!-- ─────────────────────── LIVE STATUS ─────────────────────── -->
        <v-window-item value="live">
          <div class="d-flex align-center flex-wrap ga-2 mb-4">
            <v-chip color="primary" variant="tonal">
              <v-icon start size="x-small">mdi-crosshairs-gps</v-icon>
              {{ movingVehicles.length }} moving
            </v-chip>
            <v-chip color="warning" variant="tonal">
              <v-icon start size="x-small">mdi-clock-alert-outline</v-icon>
              {{ staleVehicles.length }} stale
            </v-chip>
            <v-chip color="error" variant="tonal">
              <v-icon start size="x-small">mdi-lan-disconnect</v-icon>
              {{ offlineVehicles.length }} offline
            </v-chip>
            <v-chip color="success" variant="tonal">
              <v-icon start size="x-small">mdi-parking</v-icon>
              {{ parkedVehicles.length }} parked
            </v-chip>
          </div>

          <v-data-table
            :headers="liveHeaders"
            :items="filteredVehicles"
            :loading="pending"
            hover
            items-per-page="15"
          >
            <template #item.display_name="{ item }">
              <div class="d-flex align-center ga-2">
                <v-avatar size="32" :color="monitorStatusColor(item.monitor_status)" variant="tonal">
                  <v-icon size="18">{{ monitorStatusIcon(item.monitor_status) }}</v-icon>
                </v-avatar>
                <div>
                  <div class="text-body-2 font-weight-medium">{{ item.display_name }}</div>
                  <div class="text-caption">{{ item.license_plate || '&mdash;' }}</div>
                </div>
              </div>
            </template>
            <template #item.live_signal="{ item }">
              <v-chip :color="liveStatusColor(item.telematics)" size="x-small" variant="tonal">
                <v-icon start size="x-small">{{ liveStatusIcon(item.telematics) }}</v-icon>
                {{ liveStatusLabel(item.telematics) }}
              </v-chip>
            </template>
            <template #item.speed="{ item }">
              <div v-if="item.telematics" class="d-flex align-center ga-1">
                <v-icon size="small" :color="(item.telematics.speed ?? 0) > 0 ? 'success' : 'medium-emphasis'">mdi-speedometer</v-icon>
                <span class="text-body-2">{{ item.telematics.speed ? item.telematics.speed.toFixed(0) : 0 }} {{ item.mileage_unit === 'miles' ? 'mph' : 'km/h' }}</span>
              </div>
              <span v-else class="text-medium-emphasis">&mdash;</span>
            </template>
            <template #item.heading="{ item }">
              <v-icon v-if="item.telematics && item.telematics.heading != null" :style="headingStyle(item.telematics.heading)">mdi-navigation</v-icon>
              <span v-else class="text-medium-emphasis">&mdash;</span>
            </template>
            <template #item.driver="{ item }">
              <span class="text-body-2">{{ item.assigned_driver_name || '&mdash;' }}</span>
            </template>
            <template #item.last_reported_at="{ item }">
              <span :class="item.telematics && item.telematics.is_stale ? 'text-warning' : ''">
                {{ timeAgo(item.telematics && item.telematics.last_reported_at) }}
              </span>
            </template>
            <template #item.alerts="{ item }">
              <v-chip v-if="item.open_alerts" color="error" size="x-small" variant="flat">{{ item.open_alerts }}</v-chip>
              <span v-else class="text-medium-emphasis">&mdash;</span>
            </template>
            <template #item.action="{ item }">
              <v-btn icon="mdi-eye-outline" size="x-small" variant="text" @click="openDetail(item)" />
            </template>
          </v-data-table>
        </v-window-item>

        <!-- ─────────────────────── RENTALS ─────────────────────── -->
        <v-window-item value="rentals">
          <div v-if="onRentVehicles.length === 0" class="text-center py-12 text-medium-emphasis">
            <v-icon size="48" class="mb-3">mdi-car-key-off</v-icon>
            <p>No vehicles currently on rent.</p>
          </div>
          <v-data-table
            v-else
            :headers="rentalHeaders"
            :items="onRentVehicles"
            :loading="pending"
            hover
            items-per-page="15"
          >
            <template #item.display_name="{ item }">
              <div class="d-flex align-center ga-2">
                <v-avatar color="primary" variant="tonal" size="32">
                  <v-icon size="18">mdi-car</v-icon>
                </v-avatar>
                <div>
                  <div class="text-body-2 font-weight-medium">{{ item.display_name }}</div>
                  <div class="text-caption">{{ item.license_plate || '&mdash;' }}</div>
                </div>
              </div>
            </template>
            <template #item.customer="{ item }">
              <span v-if="item.rental" class="text-body-2 font-weight-medium">{{ item.rental.customer_name }}</span>
              <span v-else class="text-medium-emphasis">&mdash;</span>
            </template>
            <template #item.agreement_no="{ item }">
              <span v-if="item.rental" class="font-weight-bold" style="color: #4f46e5">{{ item.rental.agreement_no }}</span>
              <span v-else class="text-medium-emphasis">&mdash;</span>
            </template>
            <template #item.start_datetime="{ item }">
              <span v-if="item.rental">{{ formatDate(item.rental.start_datetime) }}</span>
              <span v-else class="text-medium-emphasis">&mdash;</span>
            </template>
            <template #item.end_datetime="{ item }">
              <span v-if="item.rental" :class="isOverdue(item) ? 'text-error font-weight-medium' : ''">
                {{ formatDate(item.rental.end_datetime) }}
              </span>
            </template>
            <template #item.rental_mileage="{ item }">
              <span :class="item.rental_mileage != null ? '' : 'text-medium-emphasis'">
                {{ item.rental_mileage != null ? `${formatNumber(item.rental_mileage)} ${item.mileage_unit}` : '&mdash;' }}
              </span>
            </template>
            <template #item.daily_rate="{ item }">
              <span v-if="item.rental">{{ fmtMoney(item.rental.daily_rate) }}</span>
              <span v-else class="text-medium-emphasis">&mdash;</span>
            </template>
            <template #item.status="{ item }">
              <v-chip :color="isOverdue(item) ? 'error' : 'primary'" size="small" variant="flat">
                {{ isOverdue(item) ? 'Overdue' : item.monitor_status === 'on_rent' ? 'On Rent' : item.monitor_status }}
              </v-chip>
            </template>
          </v-data-table>
        </v-window-item>

        <!-- ─────────────────────── MAINTENANCE ─────────────────────── -->
        <v-window-item value="maintenance">
          <v-data-table
            :headers="maintenanceHeaders"
            :items="filteredVehicles"
            :loading="pending"
            hover
            items-per-page="15"
          >
            <template #item.display_name="{ item }">
              <div>
                <div class="text-body-2 font-weight-medium">{{ item.display_name }}</div>
                <div class="text-caption">{{ item.license_plate || '&mdash;' }}</div>
              </div>
            </template>
            <template #item.monitor_status="{ item }">
              <v-chip :color="monitorStatusColor(item.monitor_status)" size="small" variant="tonal">
                <v-icon start size="x-small">{{ monitorStatusIcon(item.monitor_status) }}</v-icon>
                {{ monitorStatusLabel(item.monitor_status) }}
              </v-chip>
            </template>
            <template #item.current_mileage="{ item }">
              <span class="text-body-2">{{ formatNumber(item.current_mileage) }} {{ item.mileage_unit }}</span>
            </template>
            <template #item.mileage_since_last_service="{ item }">
              <v-chip
                v-if="item.mileage_since_last_service != null"
                :color="milageServiceColor(item.mileage_since_last_service)"
                size="small"
                variant="tonal"
              >
                {{ formatNumber(item.mileage_since_last_service) }} {{ item.mileage_unit }}
              </v-chip>
              <span v-else>&mdash;</span>
            </template>
            <template #item.last_service_at="{ item }">
              <span :class="item.last_service_at ? '' : 'text-medium-emphasis'">
                {{ item.last_service_at ? formatDate(item.last_service_at) : 'Never' }}
              </span>
            </template>
            <template #item.open_issues="{ item }">
              <v-chip v-if="item.open_issues" color="error" size="small" variant="flat">{{ item.open_issues }}</v-chip>
              <span v-else class="text-medium-emphasis">0</span>
            </template>
            <template #item.service_count="{ item }">
              <span>{{ item.service_count }}</span>
            </template>
            <template #item.total_service_cost="{ item }">
              <span>{{ fmtMoney(item.total_service_cost) }}</span>
            </template>
          </v-data-table>
        </v-window-item>

        <!-- ─────────────────────── FUEL & ENERGY ─────────────────────── -->
        <v-window-item value="energy">
          <v-data-table
            :headers="energyHeaders"
            :items="filteredVehicles"
            :loading="pending"
            hover
            items-per-page="15"
          >
            <template #item.display_name="{ item }">
              <div class="d-flex align-center ga-2">
                <v-avatar size="32" :color="isElectric(item.fuel_type) ? 'primary' : 'warning'" variant="tonal">
                  <v-icon size="18">{{ isElectric(item.fuel_type) ? 'mdi-ev-station' : 'mdi-gas-station' }}</v-icon>
                </v-avatar>
                <div>
                  <div class="text-body-2 font-weight-medium">{{ item.display_name }}</div>
                  <div class="text-caption">{{ item.license_plate || '&mdash;' }}</div>
                </div>
              </div>
            </template>
            <template #item.fuel_type="{ item }">
              <v-chip size="x-small" :color="isElectric(item.fuel_type) ? 'primary' : 'warning'" variant="tonal">
                {{ item.fuel_type }}
              </v-chip>
            </template>
            <template #item.total_fuel_used="{ item }">
              <span v-if="item.total_fuel_used > 0" class="text-body-2 font-weight-medium">{{ formatFuel(item.total_fuel_used) }}</span>
              <span v-else class="text-medium-emphasis">&mdash;</span>
            </template>
            <template #item.total_fuel_cost="{ item }">
              <span v-if="item.total_fuel_cost > 0">{{ fmtMoney(item.total_fuel_cost) }}</span>
              <span v-else class="text-medium-emphasis">&mdash;</span>
            </template>
            <template #item.state_of_charge="{ item }">
              <div v-if="isElectric(item.fuel_type)" class="d-flex align-center ga-2">
                <v-progress-linear
                  :model-value="item.state_of_charge ?? 0"
                  :color="batteryColor(item.state_of_charge)"
                  height="6"
                  rounded
                  style="max-width: 100px;"
                />
                <span class="text-body-2">{{ item.state_of_charge ?? 0 }}%</span>
              </div>
              <div v-else-if="item.battery_summary" class="d-flex flex-column">
                <span class="text-body-2 font-weight-medium">{{ item.battery_summary.count }} batt{{ item.battery_summary.count === 1 ? '' : 's' }}</span>
                <span class="text-caption text-medium-emphasis">{{ item.battery_summary.brands || '&mdash;' }}</span>
              </div>
              <span v-else class="text-medium-emphasis">&mdash;</span>
            </template>
            <template #item.total_charging_kwh="{ item }">
              <span v-if="item.total_charging_kwh > 0" class="text-body-2 font-weight-medium">{{ formatNumber(item.total_charging_kwh) }} kWh</span>
              <span v-else class="text-medium-emphasis">&mdash;</span>
            </template>
            <template #item.last_fuel_date="{ item }">
              <span :class="item.last_fuel_date ? '' : 'text-medium-emphasis'">
                {{ item.last_fuel_date ? formatDate(item.last_fuel_date) : '&mdash;' }}
              </span>
            </template>
            <template #item.last_charging_date="{ item }">
              <span v-if="isElectric(item.fuel_type)" :class="item.last_charging_date ? '' : 'text-medium-emphasis'">
                {{ item.last_charging_date ? formatDate(item.last_charging_date) : '&mdash;' }}
              </span>
              <span v-else class="text-medium-emphasis">N/A</span>
            </template>
          </v-data-table>
        </v-window-item>
      </v-window>
    </v-card>

    <!-- ─────────────── Vehicle detail drawer ─────────────── -->
    <v-navigation-drawer
      v-model="drawerOpen"
      location="right"
      width="420"
      temporary
    >
      <v-card v-if="selectedVehicle" elevation="0" class="fill-height">
        <v-card-title class="d-flex align-center justify-space-between pa-4">
          <div class="d-flex align-center ga-2">
            <v-avatar :color="monitorStatusColor(selectedVehicle.monitor_status)" variant="tonal">
              <v-icon>{{ monitorStatusIcon(selectedVehicle.monitor_status) }}</v-icon>
            </v-avatar>
            <div>
              <div class="text-h6">{{ selectedVehicle.display_name }}</div>
              <div class="text-caption text-medium-emphasis">{{ selectedVehicle.license_plate || selectedVehicle.vin }}</div>
            </div>
          </div>
          <v-btn icon="mdi-close" size="small" variant="text" @click="drawerOpen = false" />
        </v-card-title>
        <v-divider />
        <v-card-text class="d-flex flex-column ga-4" style="overflow-y: auto; max-height: calc(100vh - 180px);">
          <div>
            <div class="text-overline mb-1">Status</div>
            <div class="d-flex ga-2 flex-wrap">
              <v-chip :color="monitorStatusColor(selectedVehicle.monitor_status)" size="small" variant="flat">
                {{ monitorStatusLabel(selectedVehicle.monitor_status) }}
              </v-chip>
              <v-chip v-if="selectedVehicle.status" color="primary" size="small" variant="tonal">{{ selectedVehicle.status }}</v-chip>
              <v-chip color="secondary" size="small" variant="tonal">{{ selectedVehicle.fuel_type }}</v-chip>
            </div>
          </div>

          <!-- Rental details -->
          <v-alert
            v-if="selectedVehicle.rental"
            type="info"
            variant="tonal"
            border="start"
            density="compact"
          >
            <div class="text-body-2 font-weight-medium">{{ selectedVehicle.rental.agreement_no }}</div>
            <div class="text-caption">Customer: {{ selectedVehicle.rental.customer_name }}</div>
            <div class="text-caption">Period: {{ formatDate(selectedVehicle.rental.start_datetime) }} to {{ formatDate(selectedVehicle.rental.end_datetime) }}</div>
            <div class="text-caption">Daily rate: {{ fmtMoney(selectedVehicle.rental.daily_rate) }}</div>
            <div class="text-caption">Pickup: {{ selectedVehicle.rental.pickup_location || '&mdash;' }}</div>
          </v-alert>

          <!-- Telematics -->
          <div v-if="selectedVehicle.telematics">
            <div class="text-overline mb-1">Live Telematics</div>
            <v-chip :color="liveStatusColor(selectedVehicle.telematics)" size="small" variant="tonal" class="mb-2">
              <v-icon start size="x-small">{{ liveStatusIcon(selectedVehicle.telematics) }}</v-icon>
              {{ liveStatusLabel(selectedVehicle.telematics) }}
            </v-chip>
            <div class="text-body-2">Speed: {{ selectedVehicle.telematics.speed ? selectedVehicle.telematics.speed.toFixed(0) : 0 }} {{ selectedVehicle.mileage_unit === 'miles' ? 'mph' : 'km/h' }}</div>
            <div class="text-body-2">Ignition: {{ selectedVehicle.telematics.ignition_on ? 'On' : 'Off' }}</div>
            <div class="text-body-2">Last reported: {{ timeAgo(selectedVehicle.telematics.last_reported_at) }}</div>
            <div v-if="selectedVehicle.telematics.latitude" class="text-body-2">
              GPS: {{ selectedVehicle.telematics.latitude.toFixed(4) }}, {{ selectedVehicle.telematics.longitude.toFixed(4) }}
            </div>
          </div>

          <!-- Mileage -->
          <div>
            <div class="text-overline mb-1">Mileage & Engine</div>
            <v-list density="compact" class="pa-0">
              <v-list-item>
                <template #prepend><v-icon size="small">mdi-road-variant</v-icon></template>
                <v-list-item-title>Current: {{ formatNumber(selectedVehicle.current_mileage) }} {{ selectedVehicle.mileage_unit }}</v-list-item-title>
              </v-list-item>
              <v-list-item>
                <template #prepend><v-icon size="small">mdi-engine-outline</v-icon></template>
                <v-list-item-title>Engine: {{ formatNumber(selectedVehicle.engine_hours) }} hrs</v-list-item-title>
              </v-list-item>
              <v-list-item v-if="selectedVehicle.mileage_since_last_service != null">
                <template #prepend><v-icon size="small">mdi-wrench-clock</v-icon></template>
                <v-list-item-title>Since service: {{ formatNumber(selectedVehicle.mileage_since_last_service) }} {{ selectedVehicle.mileage_unit }}</v-list-item-title>
              </v-list-item>
            </v-list>
          </div>

          <!-- Fuel/Energy -->
          <div>
            <div class="text-overline mb-1">Fuel &amp; Energy</div>
            <v-list density="compact" class="pa-0">
              <v-list-item v-if="!isElectric(selectedVehicle.fuel_type)">
                <template #prepend><v-icon size="small">mdi-gas-station</v-icon></template>
                <v-list-item-title>
                  Total fuel: {{ formatFuel(selectedVehicle.total_fuel_used) }} ({{ fmtMoney(selectedVehicle.total_fuel_cost) }})
                </v-list-item-title>
              </v-list-item>
              <v-list-item v-if="isElectric(selectedVehicle.fuel_type)">
                <template #prepend><v-icon size="small">mdi-battery-charging</v-icon></template>
                <v-list-item-title>
                  SOC: {{ selectedVehicle.state_of_charge ?? 0 }}% · SoH: {{ selectedVehicle.state_of_health ?? 0 }}%
                </v-list-item-title>
              </v-list-item>
              <v-list-item v-if="selectedVehicle.total_charging_kwh > 0">
                <template #prepend><v-icon size="small">mdi-ev-station</v-icon></template>
                <v-list-item-title>
                  Charging: {{ formatNumber(selectedVehicle.total_charging_kwh) }} kWh ({{ fmtMoney(selectedVehicle.total_charging_cost) }})
                </v-list-item-title>
              </v-list-item>
            </v-list>
          </div>

          <!-- Installed batteries -->
          <div v-if="selectedVehicle.batteries && selectedVehicle.batteries.length > 0">
            <div class="text-overline mb-1">
              Batteries ({{ selectedVehicle.batteries.length }})
              <v-chip v-if="selectedVehicle.battery_summary && selectedVehicle.battery_summary.warranty_expired > 0" size="x-small" color="error" variant="tonal" class="ml-2">
                {{ selectedVehicle.battery_summary.warranty_expired }} warranty expired
              </v-chip>
            </div>
            <v-list density="compact" class="pa-0">
              <v-list-item v-for="b in selectedVehicle.batteries" :key="b.id">
                <template #prepend><v-icon size="small" color="primary">mdi-car-battery</v-icon></template>
                <v-list-item-title class="text-body-2">
                  {{ b.brand || 'Unknown' }} {{ b.model }} &middot; {{ b.voltage }}V
                  <span v-if="b.capacity_ah"> &middot; {{ b.capacity_ah }}Ah</span>
                </v-list-item-title>
                <v-list-item-subtitle class="text-caption">
                  {{ b.position || 'Main' }} &middot; {{ b.serial_number }}
                  <span v-if="b.warranty_expiry">&middot; Warranty {{ formatDate(b.warranty_expiry) }}</span>
                </v-list-item-subtitle>
              </v-list-item>
            </v-list>
          </div>

          <!-- Maintenance & alerts -->
          <div>
            <div class="text-overline mb-1">Maintenance &amp; Alerts</div>
            <v-list density="compact" class="pa-0">
              <v-list-item>
                <template #prepend><v-icon size="small">mdi-wrench</v-icon></template>
                <v-list-item-title>
                  Services: {{ selectedVehicle.service_count }} ({{ fmtMoney(selectedVehicle.total_service_cost) }})
                </v-list-item-title>
              </v-list-item>
              <v-list-item>
                <template #prepend><v-icon size="small">mdi-clock-outline</v-icon></template>
                <v-list-item-title>Last service: {{ selectedVehicle.last_service_at ? formatDate(selectedVehicle.last_service_at) : 'None' }}</v-list-item-title>
              </v-list-item>
              <v-list-item>
                <template #prepend><v-icon size="small" :color="selectedVehicle.open_issues ? 'error' : ''">mdi-alert-circle-outline</v-icon></template>
                <v-list-item-title>Open issues: {{ selectedVehicle.open_issues }}</v-list-item-title>
              </v-list-item>
              <v-list-item>
                <template #prepend><v-icon size="small" :color="selectedVehicle.open_alerts ? 'error' : ''">mdi-bell-alert-outline</v-icon></template>
                <v-list-item-title>Open alerts: {{ selectedVehicle.open_alerts }}</v-list-item-title>
              </v-list-item>
            </v-list>
          </div>

          <div class="d-flex ga-2 mt-2">
            <v-btn color="primary" variant="outlined" size="small" @click="navigateTo(`/app/vehicles/${selectedVehicle.id}`)">
              View Vehicle
            </v-btn>
            <v-btn
              v-if="selectedVehicle.rental"
              color="secondary"
              variant="outlined"
              size="small"
              @click="navigateTo(`/app/rentals/${selectedVehicle.rental.agreement_no}`)"
            >
              View Rental
            </v-btn>
          </div>
        </v-card-text>
      </v-card>
    </v-navigation-drawer>
  </div>
</template>

<script setup lang="ts">
import VehicleMonitorTable from '~/components/vehicles/VehicleMonitorTable.vue'
import VehicleMonitorCards from '~/components/vehicles/VehicleMonitorCards.vue'

definePageMeta({ layout: 'default', permission: 'vehicles:view' })

const { $api } = useNuxtApp() as any
const { fmtMoney, currencySymbol } = useCurrency()

const tab = ref('overview')
const viewMode = ref<'table' | 'cards'>('table')
const pending = ref(false)
const drawerOpen = ref(false)
const selectedVehicle = ref<any>(null)
const autoRefresh = ref(false)
let refreshTimer: ReturnType<typeof setInterval> | null = null

// ── Filter state ─────────────────────────────────
const search = ref('')
const statusFilter = ref<string | null>(null)
const rentalStatusFilter = ref<string | null>(null)
const groupFilter = ref<number | null>(null)
const staleOnly = ref(false)

// ── Static data ─────────────────────────────────
const monitorData = ref<any>({ summary: {}, status_distribution: [], vehicles: [] })

const summary = computed(() => monitorData.value.summary || {})
const statusDistribution = computed(() => monitorData.value.status_distribution || [])
const vehicles = computed(() => monitorData.value.vehicles || [])

// ── Groups for filter ─────────────────────────────────
const groupItems = ref<any[]>([])
onMounted(async () => {
  try {
    const groups = await $api('/vehicles/groups/')
    groupItems.value = (groups?.results || groups || []) as any[]
  } catch { /* ignore */ }
})

// ── Fetch monitor data ─────────────────────────────────
async function loadMonitor() {
  pending.value = true
  try {
    const params: Record<string, any> = {}
    if (search.value) params.search = search.value
    if (statusFilter.value) params.status = statusFilter.value
    if (rentalStatusFilter.value) params.rental_status = rentalStatusFilter.value
    if (groupFilter.value) params.group = groupFilter.value
    if (staleOnly.value) params.stale_only = 'true'
    const data = await $api('/vehicles/vehicles/vehicle-monitor/', { query: params })
    monitorData.value = data
  } catch (e) {
    console.error('Failed to load monitor data:', e)
  } finally {
    pending.value = false
  }
}

function reloadAll() { loadMonitor() }

// Debounced search
let searchDebounce: ReturnType<typeof setTimeout> | null = null
watch(search, () => {
  if (searchDebounce) clearTimeout(searchDebounce)
  searchDebounce = setTimeout(loadMonitor, 350)
})
watch([statusFilter, rentalStatusFilter, groupFilter, staleOnly], () => loadMonitor())

// Auto refresh
function toggleAutoRefresh() {
  autoRefresh.value = !autoRefresh.value
  if (autoRefresh.value) {
    refreshTimer = setInterval(loadMonitor, 30000)
  } else if (refreshTimer) {
    clearInterval(refreshTimer)
    refreshTimer = null
  }
}
onBeforeUnmount(() => {
  if (refreshTimer) clearInterval(refreshTimer)
})

onMounted(loadMonitor)

// ── Filters & helpers ─────────────────────────────────
const statusOptions = [
  { title: 'Active', value: 'active' },
  { title: 'In Maintenance', value: 'in_maintenance' },
  { title: 'Out of Service', value: 'out_of_service' },
]
const rentalStatusOptions = [
  { title: 'On Rent', value: 'on_rent' },
  { title: 'Available', value: 'available' },
]

const hasActiveFilters = computed(() =>
  search.value || statusFilter.value || rentalStatusFilter.value || groupFilter.value || staleOnly.value
)
function clearFilters() {
  search.value = ''
  statusFilter.value = null
  rentalStatusFilter.value = null
  groupFilter.value = null
  staleOnly.value = false
}

const filteredVehicles = computed(() => vehicles.value)

// ── Tab subsets ─────────────────────────────────
const movingVehicles = computed(() => vehicles.value.filter((v: any) => v.telematics && (v.telematics.speed ?? 0) > 0 && !v.telematics.is_stale))
const staleVehicles = computed(() => vehicles.value.filter((v: any) => v.telematics && v.telematics.is_stale))
const offlineVehicles = computed(() => vehicles.value.filter((v: any) => v.telematics && v.telematics.device_status === 'offline'))
const parkedVehicles = computed(() => vehicles.value.filter((v: any) => v.telematics && (v.telematics.speed ?? 0) === 0 && !v.telematics.is_stale))
const onRentVehicles = computed(() => vehicles.value.filter((v: any) => v.monitor_status === 'on_rent'))

// ── Detail drawer ─────────────────────────────────
function openDetail(item: any) {
  selectedVehicle.value = item
  drawerOpen.value = true
}

// ── Status colors & labels ─────────────────────────────────
function monitorStatusColor(s: string) {
  return { on_rent: 'primary', available: 'success', in_maintenance: 'warning', out_of_service: 'error' }[s] || 'medium-emphasis'
}
function monitorStatusIcon(s: string) {
  return { on_rent: 'mdi-car-key', available: 'mdi-parking', in_maintenance: 'mdi-wrench', out_of_service: 'mdi-cancel' }[s] || 'mdi-car'
}
function monitorStatusLabel(s: string) {
  return (s || '').replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
}

// ── Live signal helpers ─────────────────────────────────
function liveStatusColor(t: any) {
  if (!t) return 'grey'
  if (t.device_status === 'offline') return 'error'
  if (t.is_stale) return 'warning'
  if ((t.speed ?? 0) > 0) return 'success'
  return 'primary'
}
function liveStatusIcon(t: any) {
  if (!t) return 'mdi-help-circle-outline'
  if (t.device_status === 'offline') return 'mdi-lan-disconnect'
  if (t.is_stale) return 'mdi-clock-alert-outline'
  if ((t.speed ?? 0) > 0) return 'mdi-truck-fast'
  return 'mdi-parking'
}
function liveStatusLabel(t: any) {
  if (!t) return 'No Device'
  if (t.device_status === 'offline') return 'Offline'
  if (t.is_stale) return 'Stale'
  if ((t.speed ?? 0) > 0) return 'Moving'
  return 'Parked'
}

// ── Battery color ─────────────────────────────────
function batteryColor(soc: number | null | undefined) {
  const v = soc ?? 0
  if (v < 20) return 'error'
  if (v < 50) return 'warning'
  return 'success'
}

// ── Fuel formatting ─────────────────────────────────
function formatFuel(qty: number) {
  if (!qty) return '0'
  return `${formatNumber(qty)} gal`
}

// ── Number formatting ─────────────────────────────────
function formatNumber(v: any, decimals = 1) {
  const n = Number(v ?? 0)
  if (Number.isNaN(n)) return v
  return n.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: decimals })
}

// ── Date helpers ─────────────────────────────────
function formatDate(d: string | null): string {
  if (!d) return '&mdash;'
  return new Date(d).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
}
function timeAgo(d: string | null) {
  if (!d) return '&mdash;'
  const now = Date.now()
  const then = new Date(d).getTime()
  const diff = Math.max(0, now - then)
  const mins = Math.floor(diff / 60000)
  if (mins < 1) return 'Just now'
  if (mins < 60) return `${mins}m ago`
  const hrs = Math.floor(mins / 60)
  if (hrs < 24) return `${hrs}h ${mins % 60}m ago`
  const days = Math.floor(hrs / 24)
  return `${days}d ago`
}
function isOverdue(item: any) {
  if (!item.rental || !item.rental.end_datetime) return false
  return new Date(item.rental.end_datetime).getTime() < Date.now()
}

// ── Electric ─────────────────────────────────
function isElectric(fuelType: string) {
  return fuelType === 'Electric' || fuelType === 'Fuel Cell (Hydrogen)'
}

// ── Heading icon ─────────────────────────────────
function headingStyle(heading: number) {
  return { transform: `rotate(${heading}deg)` }
}

// ── Mileage since service color ─────────────────────────────────
function milageServiceColor(km: number) {
  if (km > 20000) return 'error'
  if (km > 10000) return 'warning'
  return 'success'
}

// ── Status donut style ─────────────────────────────────
const statusDonutStyle = computed(() => {
  const dist = statusDistribution.value
  if (!dist.length) return {}
  const total = dist.reduce((a: number, s: any) => a + (s.value || 0), 0) || 1
  const c = dist.map((s: any) => `${s.color} 0 ${((s.value / total) * 100).toFixed(1)}%`).join(', ')
  let acc = 0
  const stops = dist.map((s: any) => {
    const start = acc
    acc += (s.value / total) * 100
    return `${s.color} ${start.toFixed(1)}% ${acc.toFixed(1)}%`
  }).join(', ')
  return {
    background: `conic-gradient(${stops || c})`,
  }
})

// ── Table headers ─────────────────────────────────
const liveHeaders = [
  { title: 'Vehicle', key: 'display_name', align: 'start' as const },
  { title: 'Signal', key: 'live_signal' },
  { title: 'Speed', key: 'speed' },
  { title: 'Heading', key: 'heading' },
  { title: 'Driver', key: 'driver' },
  { title: 'Last Report', key: 'last_reported_at' },
  { title: 'Alerts', key: 'alerts' },
  { title: '', key: 'action', sortable: false },
]
const rentalHeaders = [
  { title: 'Vehicle', key: 'display_name', align: 'start' as const },
  { title: 'Agreement', key: 'agreement_no' },
  { title: 'Customer', key: 'customer' },
  { title: 'Started', key: 'start_datetime' },
  { title: 'Due Back', key: 'end_datetime' },
  { title: 'Mileage', key: 'rental_mileage' },
  { title: 'Rate', key: 'daily_rate' },
  { title: 'Status', key: 'status' },
]
const maintenanceHeaders = [
  { title: 'Vehicle', key: 'display_name', align: 'start' as const },
  { title: 'Status', key: 'monitor_status' },
  { title: 'Current Mileage', key: 'current_mileage' },
  { title: 'Since Service', key: 'mileage_since_last_service' },
  { title: 'Last Service', key: 'last_service_at' },
  { title: 'Issues', key: 'open_issues' },
  { title: 'Services', key: 'service_count' },
  { title: 'Cost', key: 'total_service_cost' },
]
const energyHeaders = [
  { title: 'Vehicle', key: 'display_name', align: 'start' as const },
  { title: 'Fuel Type', key: 'fuel_type' },
  { title: 'Total Fuel', key: 'total_fuel_used' },
  { title: 'Fuel Cost', key: 'total_fuel_cost' },
  { title: 'Last Fuel', key: 'last_fuel_date' },
  { title: 'Battery', key: 'state_of_charge' },
  { title: 'EV kWh', key: 'total_charging_kwh' },
  { title: 'Last Charge', key: 'last_charging_date' },
]
</script>
