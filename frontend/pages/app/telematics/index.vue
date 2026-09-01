<template>
  <div class="d-flex flex-column ga-5">
    <!-- Page header -->
    <div class="d-flex flex-wrap align-center justify-space-between ga-3">
      <div>
        <h2 class="text-h5 font-weight-bold d-flex align-center ga-2" style="color: #1e293b">
          <v-icon color="primary">mdi-crosshairs-gps</v-icon>
          Telematics & GPS
        </h2>
        <p class="text-body-2 text-medium-emphasis">Live fleet tracking, trip management, driver behavior, and geofence monitoring</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-chip v-if="analytics" color="primary" variant="tonal" size="small">
          <v-icon start size="x-small">mdi-broadcast</v-icon>
          {{ analytics.summary?.moving_devices || 0 }} moving now
        </v-chip>
        <v-btn variant="outlined" prepend-icon="mdi-refresh" :loading="pending" @click="reloadAll">Refresh</v-btn>
      </div>
    </div>

    <!-- KPI Cards -->
    <v-row dense>
      <v-col cols="6" md="3">
        <StatCard
          label="Active Devices"
          :value="analytics?.summary?.active_devices ?? 0"
          icon="mdi-crosshairs-gps"
          icon-bg="#ecfdf5"
          icon-color="success"
          :subtitle="`${analytics?.summary?.total_devices ?? 0} total`"
        />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard
          label="Moving Now"
          :value="analytics?.summary?.moving_devices ?? 0"
          icon="mdi-truck-fast"
          icon-bg="#eef2ff"
          icon-color="primary"
          :subtitle="`${analytics?.summary?.stale_devices ?? 0} stale`"
        />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard
          label="Active Trips"
          :value="analytics?.summary?.active_trips ?? 0"
          icon="mdi-route"
          icon-bg="#fff7ed"
          icon-color="warning"
          :subtitle="`${analytics?.summary?.completed_trips ?? 0} completed`"
        />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard
          label="Unack Alerts"
          :value="analytics?.summary?.unack_alerts ?? 0"
          icon="mdi-bell-alert-outline"
          icon-bg="#fef2f2"
          icon-color="error"
          :subtitle="`${analytics?.summary?.critical_alerts ?? 0} critical`"
        />
      </v-col>
    </v-row>

    <!-- Tabs -->
    <v-tabs v-model="tab" color="primary" density="compact">
      <v-tab value="map" prepend-icon="mdi-map">Live Map</v-tab>
      <v-tab value="devices" prepend-icon="mdi-crosshairs-gps">Devices</v-tab>
      <v-tab value="trips" prepend-icon="mdi-route">Trips</v-tab>
      <v-tab value="alerts" prepend-icon="mdi-bell-alert-outline">
        Alerts
        <v-badge v-if="analytics?.summary?.unack_alerts" :content="analytics.summary.unack_alerts" color="error" offset-x="6" offset-y="6" inline />
      </v-tab>
      <v-tab value="geofences" prepend-icon="mdi-shield-map-outline">Geofences</v-tab>
      <v-tab value="analytics" prepend-icon="mdi-chart-line">Analytics</v-tab>
    </v-tabs>

    <v-window v-model="tab" class="flex-grow-1">
      <!-- LIVE MAP TAB -->
      <v-window-item value="map">
        <div class="d-flex flex-column ga-4">
          <LiveFleetMap
            v-if="liveDevices.length > 0 || mapInitialized"
            ref="liveMapRef"
            :devices="liveDevices"
            @select="onDeviceSelectFromMap"
            @toggle-auto="onToggleAutoRefresh"
          />

          <v-card v-if="liveDevices.length === 0 && !mapInitialized" elevation="0" border rounded="lg">
            <div class="d-flex flex-column align-center justify-center pa-12 text-medium-emphasis">
              <v-icon size="56" class="mb-3">mdi-crosshairs-gps</v-icon>
              <p class="text-body-1 font-weight-medium mb-1">No active devices</p>
              <p class="text-caption">Add and activate telematics devices to see live GPS tracking.</p>
            </div>
          </v-card>

          <!-- Quick device cards -->
          <v-row v-if="liveDevices.length > 0" dense>
            <v-col v-for="d in liveDevices.slice(0, 6)" :key="d.id" cols="12" sm="6" md="4">
              <v-card elevation="0" border class="pa-3" rounded="lg" @click="onDeviceSelectFromMap(d)" style="cursor: pointer">
                <div class="d-flex align-center justify-space-between">
                  <div>
                    <p class="text-body-2 font-weight-bold">{{ d.vehicle_name || d.serial_number }}</p>
                    <p class="text-caption text-medium-emphasis">{{ d.provider }}</p>
                  </div>
                  <div class="text-right">
                    <v-chip
                      :color="d.is_stale ? 'error' : d.last_speed && d.last_speed > 0 ? 'success' : 'warning'"
                      size="x-small"
                      variant="tonal"
                    >
                      {{ d.is_stale ? 'Stale' : d.last_speed && d.last_speed > 0 ? `${Math.round(d.last_speed)} km/h` : 'Idle' }}
                    </v-chip>
                  </div>
                </div>
                <div v-if="d.last_reported_at" class="text-caption text-medium-emphasis mt-2">
                  <v-icon size="11">mdi-clock-outline</v-icon>
                  {{ fmtTimeAgo(d.last_reported_at) }}
                </div>
              </v-card>
            </v-col>
          </v-row>
        </div>
      </v-window-item>

      <!-- DEVICES TAB -->
      <v-window-item value="devices">
        <div class="d-flex flex-column ga-4">
          <div class="d-flex flex-wrap align-center ga-2">
            <v-text-field
              v-model="deviceSearch"
              prepend-inner-icon="mdi-magnify"
              placeholder="Search devices..."
              density="compact"
              variant="outlined"
              hide-details
              style="max-width: 280px"
              clearable
            />
            <v-select
              v-model="deviceProviderFilter"
              :items="providerOptions"
              item-title="label"
              item-value="value"
              placeholder="All Providers"
              density="compact"
              variant="outlined"
              hide-details
              clearable
              style="max-width: 170px"
            />
            <v-select
              v-model="deviceStatusFilter"
              :items="['active', 'inactive', 'offline']"
              placeholder="All Statuses"
              density="compact"
              variant="outlined"
              hide-details
              clearable
              style="max-width: 150px"
            />
            <v-spacer />
            <v-btn v-can="'telematics:create'" color="primary" prepend-icon="mdi-plus" @click="openDeviceDialog()">Add Device</v-btn>
          </div>

          <v-card elevation="0" border rounded="lg">
            <v-data-table
              :headers="deviceHeaders"
              :items="filteredDevices"
              :loading="devicePending"
              density="comfortable"
              hover
            >
              <template #[`item.serial_number`]="{ item }">
                <span class="font-mono font-weight-medium">{{ item.serial_number }}</span>
              </template>
              <template #[`item.provider`]="{ value }">
                <v-chip size="small" variant="tonal" class="text-capitalize">{{ providerLabel(value) }}</v-chip>
              </template>
              <template #[`item.is_stale`]="{ value }">
                <v-icon :color="value ? 'error' : 'success'" size="small">
                  {{ value ? 'mdi-alert' : 'mdi-check-circle' }}
                </v-icon>
              </template>
              <template #[`item.last_speed`]="{ value }">
                {{ value != null ? `${Math.round(value)} km/h` : '—' }}
              </template>
              <template #[`item.status`]="{ value }">
                <v-chip
                  :color="value === 'active' ? 'success' : value === 'offline' ? 'error' : 'grey'"
                  size="small"
                  variant="tonal"
                  class="text-capitalize"
                >
                  {{ value }}
                </v-chip>
              </template>
              <template #[`item.speed_limit`]="{ value }">
                {{ value != null ? `${value} km/h` : '—' }}
              </template>
              <template #[`item.actions`]="{ item }">
                <div class="d-flex ga-1">
                  <v-btn v-can="'telematics:update'" icon="mdi-pencil" variant="text" size="small" @click="openDeviceDialog(item)" />
                  <v-btn v-can="'telematics:delete'" icon="mdi-delete" variant="text" size="small" color="error" @click="confirmDeleteDevice(item)" />
                </div>
              </template>
            </v-data-table>
          </v-card>
        </div>
      </v-window-item>

      <!-- TRIPS TAB -->
      <v-window-item value="trips">
        <div class="d-flex flex-column ga-4">
          <div class="d-flex flex-wrap align-center ga-2">
            <v-select
              v-model="tripStatusFilter"
              :items="['active', 'completed', 'cancelled']"
              placeholder="All Statuses"
              density="compact"
              variant="outlined"
              hide-details
              clearable
              style="max-width: 150px"
            />
            <v-select
              v-model="tripVehicleFilter"
              :items="vehicles"
              item-title="display_name"
              item-value="id"
              placeholder="All Vehicles"
              density="compact"
              variant="outlined"
              hide-details
              clearable
              style="max-width: 200px"
            />
            <v-spacer />
            <v-btn v-can="'telematics:create'" color="primary" prepend-icon="mdi-plus" @click="openTripDialog()">New Trip</v-btn>
          </div>

          <v-card elevation="0" border rounded="lg">
            <v-data-table
              :headers="tripHeaders"
              :items="filteredTrips"
              :loading="tripPending"
              density="comfortable"
              hover
              @click:row="onTripRowClick"
            >
              <template #[`item.status`]="{ value }">
                <v-chip
                  :color="value === 'active' ? 'primary' : value === 'completed' ? 'success' : 'grey'"
                  size="small"
                  variant="tonal"
                  class="text-capitalize"
                >
                  {{ value }}
                </v-chip>
              </template>
              <template #[`item.distance`]="{ value }">
                {{ value != null ? `${value.toFixed(1)} km` : '—' }}
              </template>
              <template #[`item.duration_minutes`]="{ value }">
                {{ value ? `${Math.round(value)}m` : '—' }}
              </template>
              <template #[`item.started_at`]="{ value }">
                {{ value ? fmtDateTime(value) : '—' }}
              </template>
              <template #[`item.actions`]="{ item }">
                <div class="d-flex ga-1">
                  <v-btn
                    v-if="item.status === 'active'"
                    icon="mdi-flag-checkered"
                    variant="text"
                    size="small"
                    color="success"
                    @click.stop="endTrip(item)"
                  />
                  <v-btn
                    icon="mdi-map-marker-path"
                    variant="text"
                    size="small"
                    color="primary"
                    @click.stop="showTripPath(item)"
                  />
                </div>
              </template>
            </v-data-table>
          </v-card>

          <!-- Trip replay dialog -->
          <v-dialog v-model="replayDialog" max-width="900">
            <v-card rounded="lg">
              <AppModalHeader title="Trip Replay" icon="mdi-map-marker-path" />
              <v-card-text class="pa-5">
                <TripReplayMap
                  v-if="selectedTrip"
                  :trip="selectedTrip"
                  :path-data="tripPath"
                />
              </v-card-text>
              <v-card-actions class="pa-4 pt-0">
                <v-spacer />
                <v-btn variant="text" @click="replayDialog = false">Close</v-btn>
              </v-card-actions>
            </v-card>
          </v-dialog>
        </div>
      </v-window-item>

      <!-- ALERTS TAB -->
      <v-window-item value="alerts">
        <div class="d-flex flex-column ga-4">
          <div class="d-flex flex-wrap align-center ga-2">
            <v-select
              v-model="alertTypeFilter"
              :items="alertTypeOptions"
              item-title="label"
              item-value="value"
              placeholder="All Types"
              density="compact"
              variant="outlined"
              hide-details
              clearable
              style="max-width: 200px"
            />
            <v-select
              v-model="alertSeverityFilter"
              :items="['info', 'warning', 'critical']"
              placeholder="All Severities"
              density="compact"
              variant="outlined"
              hide-details
              clearable
              style="max-width: 150px"
            />
            <v-spacer />
            <v-btn
              v-if="alerts.some((a) => !a.acknowledged)"
              color="primary"
              variant="flat"
              size="small"
              prepend-icon="mdi-check-all"
              :loading="ackingAll"
              @click="acknowledgeAll"
            >
              Acknowledge All
            </v-btn>
          </div>

          <v-card elevation="0" border rounded="lg">
            <v-data-table
              :headers="alertHeaders"
              :items="filteredAlerts"
              :loading="alertPending"
              density="comfortable"
              hover
              :items-per-page="15"
            >
              <template #[`item.severity`]="{ value }">
                <v-chip
                  :color="value === 'critical' ? 'error' : value === 'warning' ? 'warning' : 'info'"
                  size="small"
                  variant="tonal"
                  class="text-capitalize"
                >
                  {{ value }}
                </v-chip>
              </template>
              <template #[`item.alert_type`]="{ value }">
                <v-icon start size="small" :icon="alertTypeIcon(value)" />
                {{ alertTypeLabel(value) }}
              </template>
              <template #[`item.acknowledged`]="{ value }">
                <v-chip
                  :color="value ? 'success' : 'error'"
                  size="small"
                  variant="tonal"
                >
                  {{ value ? 'Acked' : 'Open' }}
                </v-chip>
              </template>
              <template #[`item.triggered_at`]="{ value }">
                {{ fmtDateTime(value) }}
              </template>
              <template #[`item.actions`]="{ item }">
                <v-btn
                  v-if="!item.acknowledged"
                  icon="mdi-check"
                  variant="text"
                  size="small"
                  color="success"
                  @click="acknowledgeAlert(item)"
                />
              </template>
            </v-data-table>
          </v-card>
        </div>
      </v-window-item>

      <!-- GEOFENCES TAB -->
      <v-window-item value="geofences">
        <GeofenceTab
          v-model:event-type-filter="geoTypeFilter"
          v-model:vehicle-filter="geoVehicleFilter"
          :events="geofenceEvents"
          :vehicles="vehicles"
          :loading="geoPending"
          @refresh="reloadGeofence"
        />
      </v-window-item>

      <!-- ANALYTICS TAB -->
      <v-window-item value="analytics">
        <div class="d-flex flex-column ga-4">
          <v-row dense>
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 text-center" rounded="lg">
                <p class="text-h4 font-weight-bold text-primary">{{ analytics?.summary?.month_total_distance ?? 0 }}</p>
                <p class="text-caption text-medium-emphasis">km this month</p>
              </v-card>
            </v-col>
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 text-center" rounded="lg">
                <p class="text-h4 font-weight-bold text-success">{{ analytics?.summary?.month_total_duration ?? 0 }}</p>
                <p class="text-caption text-medium-emphasis">total minutes</p>
              </v-card>
            </v-col>
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 text-center" rounded="lg">
                <p class="text-h4 font-weight-bold text-warning">{{ analytics?.summary?.geofence_enter ?? 0 }}</p>
                <p class="text-caption text-medium-emphasis">geofence entries</p>
              </v-card>
            </v-col>
            <v-col cols="6" md="3">
              <v-card elevation="0" border class="pa-4 text-center" rounded="lg">
                <p class="text-h4 font-weight-bold text-error">{{ analytics?.summary?.geofence_exit ?? 0 }}</p>
                <p class="text-caption text-medium-emphasis">geofence exits</p>
              </v-card>
            </v-col>
          </v-row>

          <v-row dense>
            <v-col cols="12" md="8">
              <DashboardChart
                :option="dailyTripsChart"
                title="Daily Trips (Last 7 Days)"
                icon="mdi-chart-line"
                height="320px"
              />
            </v-col>
            <v-col cols="12" md="4">
              <DashboardChart
                :option="alertsDistChart"
                title="Alert Distribution"
                icon="mdi-chart-donut"
                height="320px"
              />
            </v-col>
          </v-row>
        </div>
      </v-window-item>
    </v-window>

    <!-- Device Dialog -->
    <DeviceFormDialog
      v-model="deviceDialog"
      :edit-item="deviceEditItem"
      :vehicles="vehicles"
      @saved="onDeviceSaved"
    />

    <!-- Trip Dialog -->
    <TripFormDialog
      v-model="tripDialog"
      :edit-item="tripEditItem"
      :vehicles="vehicles"
      :drivers="drivers"
      :devices="allDevices"
      @saved="onTripSaved"
    />
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

const { $api, $swal } = useNuxtApp() as any

const tab = ref('map')
const pending = ref(false)
const mapInitialized = ref(false)

// ── Analytics ───────────────────────────────────────────
const { data: analyticsData, refresh: refreshAnalytics } = useAsyncData(
  'telematics-analytics',
  () => $api('/telematics/analytics/'),
  { default: () => ({ summary: {}, daily_series: [], alert_distribution: [] }) },
)
const analytics = computed(() => analyticsData.value)

// ── Live devices (for map) ──────────────────────────────
const { data: liveData, refresh: refreshLive } = useAsyncData(
  'telematics-live',
  () => $api('/telematics/devices/live/'),
  { default: () => [] },
)
const liveDevices = computed(() => liveData.value || [])
const liveMapRef = ref<any>(null)
let liveTimer: any = null

// ── All devices (for table) ─────────────────────────────
const { data: devData, pending: devicePending, refresh: refreshDevices } = useAsyncData(
  'telematics-devices',
  () => $api('/telematics/devices/', { query: { page_size: 100 } }),
  { default: () => ({ results: [] }) },
)
const allDevices = computed(() => devData.value?.results || [])

const deviceSearch = ref('')
const deviceProviderFilter = ref(null)
const deviceStatusFilter = ref(null)

const filteredDevices = computed(() => {
  let items = allDevices.value
  if (deviceSearch.value) {
    const q = deviceSearch.value.toLowerCase()
    items = items.filter((d: any) =>
      d.serial_number?.toLowerCase().includes(q) || d.imei?.toLowerCase().includes(q),
    )
  }
  if (deviceProviderFilter.value) items = items.filter((d: any) => d.provider === deviceProviderFilter.value)
  if (deviceStatusFilter.value) items = items.filter((d: any) => d.status === deviceStatusFilter.value)
  return items
})

// ── Trips ───────────────────────────────────────────────
const { data: tripData, pending: tripPending, refresh: refreshTrips } = useAsyncData(
  'telematics-trips',
  () => $api('/telematics/trips/', { query: { page_size: 100 } }),
  { default: () => ({ results: [] }) },
)
const trips = computed(() => tripData.value?.results || [])
const tripStatusFilter = ref(null)
const tripVehicleFilter = ref(null)
const filteredTrips = computed(() => {
  let items = trips.value
  if (tripStatusFilter.value) items = items.filter((t: any) => t.status === tripStatusFilter.value)
  if (tripVehicleFilter.value) items = items.filter((t: any) => t.vehicle === tripVehicleFilter.value)
  return items
})

// ── Alerts ──────────────────────────────────────────────
const { data: alertData, pending: alertPending, refresh: refreshAlerts } = useAsyncData(
  'telematics-alerts',
  () => $api('/telematics/alerts/', { query: { page_size: 200 } }),
  { default: () => ({ results: [] }) },
)
const alerts = computed(() => alertData.value?.results || [])
const alertTypeFilter = ref(null)
const alertSeverityFilter = ref(null)
const ackingAll = ref(false)

const filteredAlerts = computed(() => {
  let items = alerts.value
  if (alertTypeFilter.value) items = items.filter((a: any) => a.alert_type === alertTypeFilter.value)
  if (alertSeverityFilter.value) items = items.filter((a: any) => a.severity === alertSeverityFilter.value)
  return items
})

// ── Geofence events ─────────────────────────────────────
const { data: geoData, pending: geoPending, refresh: refreshGeofence } = useAsyncData(
  'telematics-geofence',
  () => $api('/telematics/geofence-events/', { query: { page_size: 100 } }),
  { default: () => ({ results: [] }) },
)
const geofenceEvents = computed(() => geoData.value?.results || [])
const geoTypeFilter = ref(null)
const geoVehicleFilter = ref(null)

// ── Vehicles & drivers ──────────────────────────────────
const { data: vehData } = useAsyncData(
  'telematics-vehicles',
  () => $api('/vehicles/vehicles/', { query: { page_size: 200 } }),
  { default: () => ({ results: [] }) },
)
const vehicles = computed(() => vehData.value?.results || [])

const { data: driverData } = useAsyncData(
  'telematics-drivers',
  () => $api('/contacts/contacts/', { query: { is_driver: true, page_size: 200 } }),
  { default: () => ({ results: [] }) },
)
const drivers = computed(() => driverData.value?.results || [])

// ── Dialogs ─────────────────────────────────────────────
const deviceDialog = ref(false)
const deviceEditItem = ref<any>(null)
const tripDialog = ref(false)
const tripEditItem = ref<any>(null)
const replayDialog = ref(false)
const selectedTrip = ref<any>(null)
const tripPath = ref<any[]>([])

// ── Device table headers ───────────────────────────────
const deviceHeaders = [
  { title: 'Serial', key: 'serial_number', sortable: true },
  { title: 'Provider', key: 'provider', sortable: true, width: '130px' },
  { title: 'Vehicle', key: 'vehicle_name', sortable: true, width: '150px' },
  { title: 'Speed', key: 'last_speed', sortable: true, width: '90px' },
  { title: 'Speed Limit', key: 'speed_limit', sortable: true, width: '100px' },
  { title: 'Stale', key: 'is_stale', sortable: true, width: '70px' },
  { title: 'Status', key: 'status', sortable: true, width: '90px' },
  { title: '', key: 'actions', sortable: false, align: 'end' as const, width: '100px' },
]

const tripHeaders = [
  { title: 'Vehicle', key: 'vehicle_name', sortable: true },
  { title: 'Driver', key: 'driver_name', sortable: true, width: '140px' },
  { title: 'Started', key: 'started_at', sortable: true, width: '170px' },
  { title: 'Distance', key: 'distance', sortable: true, align: 'end' as const, width: '100px' },
  { title: 'Duration', key: 'duration_minutes', sortable: true, align: 'end' as const, width: '100px' },
  { title: 'Status', key: 'status', sortable: true, width: '100px' },
  { title: '', key: 'actions', sortable: false, align: 'end' as const, width: '100px' },
]

const alertHeaders = [
  { title: 'Alert', key: 'alert_type', sortable: true, width: '180px' },
  { title: 'Severity', key: 'severity', sortable: true, width: '100px' },
  { title: 'Vehicle', key: 'vehicle_name', sortable: true, width: '140px' },
  { title: 'Message', key: 'message', sortable: false },
  { title: 'Triggered', key: 'triggered_at', sortable: true, width: '170px' },
  { title: 'Acked', key: 'acknowledged', sortable: true, width: '80px' },
  { title: '', key: 'actions', sortable: false, align: 'end' as const, width: '60px' },
]

// ── Helper functions ────────────────────────────────────
const providerOptions = [
  { label: 'Geotab', value: 'geotab' },
  { label: 'Samsara', value: 'samsara' },
  { label: 'KeepTruckin (Motive)', value: 'keeptruckin' },
  { label: 'Verizon Connect', value: 'verizon' },
  { label: 'Generic / Custom', value: 'generic' },
]

function providerLabel(v: string): string {
  return providerOptions.find((p) => p.value === v)?.label || v
}

const alertTypeOptions = [
  { label: 'Speeding', value: 'speeding' },
  { label: 'Excessive Idle', value: 'idle' },
  { label: 'Harsh Braking', value: 'harsh_braking' },
  { label: 'Harsh Acceleration', value: 'harsh_acceleration' },
  { label: 'Geofence Violation', value: 'geofence_violation' },
  { label: 'Device Offline', value: 'device_offline' },
  { label: 'Low Battery', value: 'low_battery' },
  { label: 'Odometer Tamper', value: 'odometer_tamper' },
  { label: 'Ignition Off', value: 'ignition_off' },
  { label: 'Low Fuel', value: 'low_fuel' },
]

function alertTypeLabel(v: string): string {
  return alertTypeOptions.find((a) => a.value === v)?.label || v
}

function alertTypeIcon(v: string): string {
  const map: Record<string, string> = {
    speeding: 'mdi-speedometer',
    idle: 'mdi-engine-off-outline',
    harsh_braking: 'mdi-car-brake-alert',
    harsh_acceleration: 'mdi-car-shift-pattern',
    geofence_violation: 'mdi-shield-alert-outline',
    device_offline: 'mdi-wifi-off',
    low_battery: 'mdi-battery-alert',
    odometer_tamper: 'mdi-counter',
    ignition_off: 'mdi-power-plug-off',
    low_fuel: 'mdi-gas-station-outline',
  }
  return map[v] || 'mdi-bell-alert-outline'
}

function fmtDateTime(d: any): string {
  if (!d) return '—'
  try {
    return new Date(d).toLocaleString('en-US', {
      month: 'short', day: 'numeric', year: 'numeric',
      hour: '2-digit', minute: '2-digit',
    })
  } catch { return String(d) }
}

function fmtTimeAgo(d: any): string {
  if (!d) return '—'
  try {
    const diff = Date.now() - new Date(d).getTime()
    const mins = Math.floor(diff / 60000)
    if (mins < 60) return `${mins}m ago`
    const hours = Math.floor(mins / 60)
    if (hours < 24) return `${hours}h ago`
    return `${Math.floor(hours / 24)}d ago`
  } catch { return String(d) }
}

// ── Device actions ─────────────────────────────────────
function openDeviceDialog(item?: any) {
  deviceEditItem.value = item || null
  deviceDialog.value = true
}

function onDeviceSaved() {
  refreshDevices()
  refreshLive()
  refreshAnalytics()
}

async function confirmDeleteDevice(item: any) {
  $swal?.fire?.({
    icon: 'warning',
    title: 'Delete device?',
    text: `Remove ${item.serial_number}? This cannot be undone.`,
    showCancelButton: true,
    confirmButtonColor: '#ef4444',
    confirmButtonText: 'Delete',
    cancelButtonText: 'Cancel',
  }).then(async (res: any) => {
    if (res?.isConfirmed) {
      try {
        await $api(`/telematics/devices/${item.id}/`, { method: 'DELETE' })
        $swal?.fire?.({ icon: 'success', title: 'Device deleted', toast: true, timer: 1500, position: 'top-end' })
        onDeviceSaved()
      } catch {
        $swal?.fire?.({ icon: 'error', title: 'Delete failed', toast: true, timer: 2000, position: 'top-end' })
      }
    }
  })
}

// ── Trip actions ───────────────────────────────────────
function openTripDialog(item?: any) {
  tripEditItem.value = item || null
  tripDialog.value = true
}

function onTripSaved() {
  refreshTrips()
  refreshAnalytics()
}

function onTripRowClick(_e: any, row: any) {
  showTripPath(row.item)
}

async function showTripPath(trip: any) {
  selectedTrip.value = trip
  replayDialog.value = true
  tripPath.value = []
  try {
    tripPath.value = await $api(`/telematics/trips/${trip.id}/path/`)
  } catch {
    $swal?.fire?.({ icon: 'error', title: 'Failed to load trip path', toast: true, timer: 2000, position: 'top-end' })
  }
}

async function endTrip(trip: any) {
  $swal?.fire?.({
    icon: 'question',
    title: 'End this trip?',
    text: `End trip for ${trip.vehicle_name}?`,
    showCancelButton: true,
    confirmButtonColor: '#10b981',
    confirmButtonText: 'End Trip',
    cancelButtonText: 'Cancel',
  }).then(async (res: any) => {
    if (res?.isConfirmed) {
      try {
        await $api(`/telematics/trips/${trip.id}/end/`, { method: 'POST', body: {} })
        $swal?.fire?.({ icon: 'success', title: 'Trip ended', toast: true, timer: 1500, position: 'top-end' })
        onTripSaved()
      } catch {
        $swal?.fire?.({ icon: 'error', title: 'Failed to end trip', toast: true, timer: 2000, position: 'top-end' })
      }
    }
  })
}

// ── Alert actions ───────────────────────────────────────
async function acknowledgeAlert(alert: any) {
  try {
    await $api(`/telematics/alerts/${alert.id}/acknowledge/`, { method: 'POST' })
    $swal?.fire?.({ icon: 'success', title: 'Alert acknowledged', toast: true, timer: 1500, position: 'top-end' })
    refreshAlerts()
    refreshAnalytics()
  } catch {
    $swal?.fire?.({ icon: 'error', title: 'Failed to acknowledge', toast: true, timer: 2000, position: 'top-end' })
  }
}

async function acknowledgeAll() {
  ackingAll.value = true
  try {
    await $api('/telematics/alerts/acknowledge-all/', { method: 'POST', body: {} })
    $swal?.fire?.({ icon: 'success', title: 'All alerts acknowledged', toast: true, timer: 1500, position: 'top-end' })
    refreshAlerts()
    refreshAnalytics()
  } catch {
    $swal?.fire?.({ icon: 'error', title: 'Failed', toast: true, timer: 2000, position: 'top-end' })
  } finally {
    ackingAll.value = false
  }
}

// ── Map interaction ─────────────────────────────────────
function onDeviceSelectFromMap(_d: any) {
  // Could open detail drawer in future
}

// ── Auto-refresh polling ────────────────────────────────
function onToggleAutoRefresh(val: boolean) {
  if (val) startAutoRefresh()
  else stopAutoRefresh()
}

function startAutoRefresh() {
  if (liveTimer) return
  liveTimer = setInterval(async () => {
    await refreshLive()
    liveMapRef.value?.refresh()
  }, 15000)
}

function stopAutoRefresh() {
  if (liveTimer) {
    clearInterval(liveTimer)
    liveTimer = null
  }
}

// ── Reload all ──────────────────────────────────────────
async function reloadAll() {
  pending.value = true
  await Promise.all([
    refreshAnalytics(),
    refreshLive(),
    refreshDevices(),
    refreshTrips(),
    refreshAlerts(),
    refreshGeofence(),
  ])
  pending.value = false
}

async function reloadGeofence() {
  await refreshGeofence()
}

// ── Lifecycle ───────────────────────────────────────────
watch(tab, (v) => {
  if (v === 'map') {
    mapInitialized.value = true
    startAutoRefresh()
  } else {
    stopAutoRefresh()
  }
})

onMounted(async () => {
  mapInitialized.value = true
  startAutoRefresh()
})

onUnmounted(() => {
  stopAutoRefresh()
})

// ── Charts ──────────────────────────────────────────────
const dailyTripsChart = computed(() => ({
  tooltip: { trigger: 'axis' },
  legend: { data: ['Trips', 'Distance'], bottom: 0 },
  grid: { left: '3%', right: '4%', bottom: '15%', top: '5%', containLabel: true },
  xAxis: {
    type: 'category',
    data: (analytics.value?.daily_series || []).map((d: any) => d.date.slice(5)),
    axisLabel: { fontSize: 11 },
  },
  yAxis: [
    { type: 'value', name: 'Trips' },
    { type: 'value', name: 'km', position: 'right' },
  ],
  series: [
    {
      name: 'Trips',
      type: 'bar',
      data: (analytics.value?.daily_series || []).map((d: any) => d.trips),
      itemStyle: { color: '#6366f1', borderRadius: [4, 4, 0, 0] },
    },
    {
      name: 'Distance',
      type: 'line',
      smooth: true,
      symbol: 'circle',
      symbolSize: 6,
      yAxisIndex: 1,
      data: (analytics.value?.daily_series || []).map((d: any) => d.distance),
      itemStyle: { color: '#10b981' },
    },
  ],
}))

const alertsDistChart = computed(() => ({
  tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
  legend: { bottom: 0, type: 'scroll' },
  series: [{
    type: 'pie',
    radius: ['40%', '70%'],
    center: ['50%', '45%'],
    data: (analytics.value?.alert_distribution || []).map((a: any) => ({
      name: alertTypeLabel(a.alert_type),
      value: a.count,
    })),
    itemStyle: { borderRadius: 6, borderColor: '#fff', borderWidth: 2 },
    label: { show: false },
  }],
  color: ['#6366f1', '#ef4444', '#f59e0b', '#10b981', '#3b82f6', '#8b5cf6', '#ec4899', '#14b8a6', '#06b6d4', '#a78bfa'],
}))

useHead({ title: 'Telematics & GPS' })
</script>

<style scoped>
.font-mono {
  font-family: 'Courier New', monospace;
}
</style>
