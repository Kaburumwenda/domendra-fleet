<template>
  <div class="d-flex flex-column ga-4">
    <!-- Header -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-2">
      <div>
        <h1 class="text-h5 font-weight-bold" style="color: #1e293b">Fuel &amp; Energy Analytics</h1>
        <p class="text-caption text-medium-emphasis">Cost trends, consumption insights &amp; efficiency metrics</p>
      </div>
    </div>

    <!-- Filters Row -->
    <div class="d-flex flex-wrap align-center ga-3 analytics-filters">
      <v-select
        v-model="fuelFilter"
        :items="fuelOptions"
        label="Fuel Type"
        prepend-inner-icon="mdi-gas-station"
        density="compact"
        hide-details
        clearable
        variant="solo-filled"
        flat
        rounded="lg"
        style="min-width: 170px; max-width: 210px"
      />
      <v-select
        v-model="groupFilter"
        :items="groupOptions"
        item-title="label"
        item-value="value"
        label="Group"
        prepend-inner-icon="mdi-folder-outline"
        density="compact"
        hide-details
        clearable
        variant="solo-filled"
        flat
        rounded="lg"
        style="min-width: 170px; max-width: 210px"
      />
      <v-select
        v-model="locationFilter"
        :items="locationOptions"
        label="Location"
        prepend-inner-icon="mdi-map-marker-outline"
        density="compact"
        hide-details
        clearable
        variant="solo-filled"
        flat
        rounded="lg"
        style="min-width: 170px; max-width: 210px"
      />
      <v-btn
        v-if="hasActiveFilters"
        variant="tonal"
        color="error"
        size="small"
        icon="mdi-filter-remove"
        density="comfortable"
        @click="clearFilters"
      />
      <v-spacer />
      <v-btn-toggle v-model="period" mandatory density="compact" color="primary" divided rounded="lg">
        <v-btn value="7" size="small">7d</v-btn>
        <v-btn value="30" size="small">30d</v-btn>
        <v-btn value="90" size="small">90d</v-btn>
        <v-btn value="365" size="small">365d</v-btn>
        <v-btn value="custom" size="small" @click="openCustomDate">Custom…</v-btn>
      </v-btn-toggle>
    </div>

    <!-- Custom Date Range Dialog -->
    <v-dialog v-model="customDateDialogVisible" max-width="420">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-calendar-range">Custom Date Range</AppModalHeader>
        <v-card-text class="pt-4">
          <v-row dense>
            <v-col cols="12">
              <v-text-field v-model="customFrom" type="date" label="From" density="comfortable" variant="outlined" prepend-inner-icon="mdi-calendar-start" hide-details="auto" />
            </v-col>
            <v-col cols="12">
              <v-text-field v-model="customTo" type="date" label="To" density="comfortable" variant="outlined" prepend-inner-icon="mdi-calendar-end" hide-details="auto" />
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
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #6366f1 0%, #818cf8 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-currency-usd</v-icon><span class="text-caption" style="color:#fff !important">Total Cost</span></div>
          <p class="text-h4 font-weight-bold" style="color: #fff !important">{{ currencySymbol }}{{ formatNumber(data?.total_cost) }}</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-gauge</v-icon><span class="text-caption" style="color:#fff !important">Total Volume</span></div>
          <p class="text-h4 font-weight-bold" style="color: #fff !important">{{ formatNumber(data?.total_gallons) }}</p>
          <p class="text-caption" style="color:#fff !important; opacity:.7">gallons / liters</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #10b981 0%, #34d399 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-tag-outline</v-icon><span class="text-caption" style="color:#fff !important">Avg Price/Unit</span></div>
          <p class="text-h4 font-weight-bold" style="color: #fff !important">{{ currencySymbol }}{{ formatNumber(data?.avg_price_per_gallon, 3) }}</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border class="pa-5 h-100" style="background: linear-gradient(135deg, #8b5cf6 0%, #a78bfa 100%) !important; color: #fff !important">
          <div class="d-flex align-center ga-2 mb-2"><v-icon color="white" size="small">mdi-receipt</v-icon><span class="text-caption" style="color:#fff !important">Transactions</span></div>
          <p class="text-h4 font-weight-bold" style="color: #fff !important">{{ data?.transaction_count || 0 }}</p>
        </v-card>
      </v-col>
    </v-row>

    <!-- Tabs for detailed analytics -->
    <v-card elevation="0" border rounded="lg">
      <v-tabs v-model="tab" color="primary" density="compact">
        <v-tab value="trends" slider-color="primary"><v-icon size="small" class="mr-2">mdi-chart-line</v-icon> Trends</v-tab>
        <v-tab value="breakdown" slider-color="primary"><v-icon size="small" class="mr-2">mdi-chart-pie</v-icon> Breakdown</v-tab>
        <v-tab value="vehicles" slider-color="primary"><v-icon size="small" class="mr-2">mdi-car</v-icon> By Vehicle</v-tab>
      </v-tabs>
      <v-divider />
      <v-window v-model="tab" class="pa-5">
        <!-- Trends Tab -->
        <v-window-item value="trends">
          <v-row dense>
            <v-col cols="12">
              <DashboardChart v-if="tab === 'trends'" :option="dailyCostOption" title="Daily Fuel Cost" icon="mdi-chart-line" height="320px" :key="'dc' + (data?.daily_trend?.length || 0)" />
            </v-col>
            <v-col cols="12">
              <DashboardChart v-if="tab === 'trends'" :option="weekdayRaceOption" title="Fuel Cost by Day of Week" icon="mdi-chart-box" height="280px" :key="'wd' + (data?.daily_trend?.length || 0)" />
            </v-col>
            <v-col cols="12" md="6">
              <DashboardChart v-if="tab === 'trends'" :option="priceTrendOption" title="Price / Unit Trend" icon="mdi-chart-bell-curve" height="300px" :key="'pt' + (data?.price_trend?.length || 0)" />
            </v-col>
            <v-col cols="12" md="6">
              <DashboardChart v-if="tab === 'trends'" :option="monthlyTrendOption" title="Monthly Trend" icon="mdi-chart-line-variant" height="300px" :key="'mt' + (data?.monthly_trend?.length || 0)" />
            </v-col>
          </v-row>
        </v-window-item>

        <!-- Breakdown Tab -->
        <v-window-item value="breakdown">
          <v-row dense>
            <v-col cols="12" md="6" lg="4">
              <DashboardChart v-if="tab === 'breakdown'" :option="fuelTypeBreakdownOption" title="By Fuel Type" icon="mdi-fuel" height="300px" :key="'ft' + (data?.by_fuel_type?.length || 0)" />
            </v-col>
            <v-col cols="12" md="6" lg="4">
              <DashboardChart v-if="tab === 'breakdown'" :option="groupLineRaceOption" title="By Group" icon="mdi-folder-multiple" height="300px" :key="'grp' + (data?.by_group_daily?.length || 0)" />
            </v-col>
            <v-col cols="12" md="12" lg="4">
              <DashboardChart v-if="tab === 'breakdown'" :option="stationBreakdownOption" title="Top Stations by Cost" icon="mdi-store-marker-outline" height="300px" :key="'st' + (data?.by_station?.length || 0)" />
            </v-col>
            <v-col cols="6" md="3" class="pt-2">
              <v-card elevation="0" border class="pa-4 text-center h-100">
                <v-icon color="error" size="large">mdi-arrow-up-bold</v-icon>
                <p class="text-h6 font-weight-bold mt-2">{{ currencySymbol }}{{ formatNumber(data?.max_transaction_cost) }}</p>
                <p class="text-caption text-medium-emphasis">Max Transaction</p>
              </v-card>
            </v-col>
            <v-col cols="6" md="3" class="pt-2">
              <v-card elevation="0" border class="pa-4 text-center h-100">
                <v-icon color="success" size="large">mdi-arrow-down-bold</v-icon>
                <p class="text-h6 font-weight-bold mt-2">{{ currencySymbol }}{{ formatNumber(data?.min_transaction_cost) }}</p>
                <p class="text-caption text-medium-emphasis">Min Transaction</p>
              </v-card>
            </v-col>
            <v-col cols="6" md="3" class="pt-2">
              <v-card elevation="0" border class="pa-4 text-center h-100">
                <v-icon color="info" size="large">mdi-calculator</v-icon>
                <p class="text-h6 font-weight-bold mt-2">{{ currencySymbol }}{{ formatNumber(data?.avg_price_per_transaction) }}</p>
                <p class="text-caption text-medium-emphasis">Avg / Transaction</p>
              </v-card>
            </v-col>
            <v-col cols="6" md="3" class="pt-2">
              <v-card elevation="0" border class="pa-4 text-center h-100">
                <v-icon color="warning" size="large">mdi-trending-up</v-icon>
                <p class="text-h6 font-weight-bold mt-2">{{ currencySymbol }}{{ formatNumber(avgDailyCost) }}</p>
                <p class="text-caption text-medium-emphasis">Avg Daily Cost</p>
              </v-card>
            </v-col>
          </v-row>
        </v-window-item>

        <!-- By Vehicle Tab -->
        <v-window-item value="vehicles">
          <v-card elevation="0" border rounded="lg">
            <v-card-text class="pb-0">
              <v-text-field
                v-model="vehicleSearch"
                prepend-inner-icon="mdi-magnify"
                placeholder="Search by name or plate…"
                density="compact"
                variant="outlined"
                hide-details
                clearable
                style="max-width: 300px"
              />
            </v-card-text>
            <v-data-table :headers="vehicleHeaders" :items="filteredByVehicleItems" :search="vehicleSearch" hover density="comfortable" items-per-page="15">
              <template #item.vehicle_display="{ item }">
                <div class="d-flex align-center ga-3">
                  <div class="vehicle-avatar" :style="vehicleAvatarStyle(item)">
                    <img v-if="vehicleImageUrl(item)" :src="vehicleImageUrl(item)!" alt="Vehicle photo" class="vehicle-avatar__img" />
                    <v-icon v-else size="16" color="white">mdi-car</v-icon>
                  </div>
                  <div class="d-flex flex-column">
                    <span class="font-weight-medium" style="color: #1e293b">{{ item.name }}</span>
                    <span class="text-caption text-medium-emphasis">{{ item.vehicle__vin }}</span>
                  </div>
                </div>
              </template>
              <template #item.license_plate="{ value }">
                <v-chip variant="outlined" size="small" label class="font-weight-medium">{{ value || '—' }}</v-chip>
              </template>
              <template #item.total_cost="{ value }">{{ currencySymbol }}{{ formatNumber(value) }}</template>
              <template #item.total_gallons="{ value }">{{ formatNumber(value) }}</template>
              <template #item.avg_price="{ value }">{{ currencySymbol }}{{ formatNumber(value, 3) }}</template>
              <template #item.cum_pct="{ value }">
                <div class="d-flex align-center ga-2">
                  <div style="width: 90px">
                    <div class="text-caption font-weight-medium mb-1">{{ value }}%</div>
                    <v-progress-linear :model-value="value" color="#6366f1" height="6" rounded />
                  </div>
                </div>
              </template>
              <template #no-data>
                <div class="text-center py-8 text-medium-emphasis">
                  <v-icon size="36" class="mb-2">mdi-car</v-icon>
                  <p>No vehicle data for this period.</p>
                </div>
              </template>
            </v-data-table>
          </v-card>

          <!-- Charts below the table -->
          <v-row dense class="mt-3">
            <v-col cols="12" lg="7">
              <DashboardChart v-if="tab === 'vehicles'" :option="vehicleCostChartOption" title="Cost by Vehicle" icon="mdi-cash" height="320px" :key="'vCost' + byVehicleItems.length" />
            </v-col>
            <v-col cols="12" lg="5">
              <DashboardChart v-if="tab === 'vehicles'" :option="vehicleCumCostChartOption" title="Cumulative Cost (Pareto)" icon="mdi-chart-line-variant" height="320px" :key="'vCum' + byVehicleItems.length" />
            </v-col>
            <v-col cols="12" lg="6">
              <DashboardChart v-if="tab === 'vehicles'" :option="vehicleVolumeChartOption" title="Volume by Vehicle" icon="mdi-fuel" height="300px" :key="'vVol' + byVehicleItems.length" />
            </v-col>
            <v-col cols="12" lg="6">
              <DashboardChart v-if="tab === 'vehicles'" :option="vehicleFillsChartOption" title="Fill Count by Vehicle" icon="mdi-counter" height="300px" :key="'vFill' + byVehicleItems.length" />
            </v-col>
          </v-row>
        </v-window-item>
      </v-window>
    </v-card>

    <!-- Clustering Map: station refill locations -->
    <v-card elevation="0" border rounded="lg">
      <v-card-text class="pa-4">
        <div class="d-flex align-center ga-2 mb-3">
          <v-icon color="medium-emphasis" size="small">mdi-map-marker-multiple</v-icon>
          <span class="text-subtitle-2 font-weight-medium text-medium-emphasis">Refill Locations (Clustering)</span>
          <v-spacer />
          <span class="text-caption text-medium-emphasis" v-if="stationMapData.length">{{ stationMapData.length }} stations</span>
        </div>
        <div ref="clusterMapEl" style="width:100%; height:380px; border-radius:12px; background:#f1f5f9" />
        <p class="text-caption text-medium-emphasis mt-1">Markers sized by refill count; color intensity by total cost</p>
      </v-card-text>
    </v-card>
  </div>
</template>

<script setup lang="ts">
const { $api } = useNuxtApp()
const { currencySymbol } = useCurrency()
const tab = ref('trends')
const period = ref('30')
const customFrom = ref('')
const customTo = ref('')
const customDateDialogVisible = ref(false)
const customDateError = ref('')

// --- Filters ---
const fuelFilter = ref<string | null>(null)
const groupFilter = ref<number | null>(null)
const locationFilter = ref<string | null>(null)

const fuelOptions = [
  'Petrol',
  'Diesel',
  'Hybrid (Petrol)',
  'Hybrid (Diesel)',
  'Plug-in Hybrid (Petrol)',
  'Plug-in Hybrid (Diesel)',
  'Mild Hybrid',
  'Electric',
  'Fuel Cell (Hydrogen)',
  'LPG',
  'CNG',
  'LNG',
  'Ethanol (E85)',
  'Flex Fuel',
  'Biodiesel',
]

const { data: groupsData } = useAsyncData('analytics-groups-filter', () =>
  $api('/vehicles/groups/').catch(() => ({ results: [], count: 0 })),
  { default: () => ({ results: [], count: 0 }) }
)
const groupOptions = computed(() =>
  (groupsData.value?.results || []).map((g: any) => ({ label: g.name, value: g.id }))
)

const { data: locationsData } = useAsyncData('analytics-locations-filter', () =>
  $api('/locations/').catch(() => ({ results: [], count: 0 })),
  { default: () => ({ results: [], count: 0 }) }
)
const locationOptions = computed(() =>
  (locationsData.value?.results || []).map((l: any) => l.name)
)

const hasActiveFilters = computed(() =>
  Boolean(fuelFilter.value || groupFilter.value || locationFilter.value)
)

function clearFilters() {
  fuelFilter.value = null
  groupFilter.value = null
  locationFilter.value = null
}

/** Returns the query params for the analytics endpoint based on filters + selected period. */
function periodQuery() {
  const q: Record<string, string> = {}
  if (fuelFilter.value) q['fuel_type'] = fuelFilter.value
  if (groupFilter.value) q['vehicle_group'] = String(groupFilter.value)
  if (locationFilter.value) q['vehicle_location'] = locationFilter.value
  if (period.value === 'custom') {
    if (customFrom.value) q['date__gte'] = customFrom.value
    if (customTo.value) q['date__lte'] = customTo.value
    return q
  }
  q['days'] = period.value
  return q
}

function openCustomDate() {
  // Pre-fill with last-30-day range if empty
  if (!customFrom.value || !customTo.value) {
    const today = new Date()
    const past = new Date()
    past.setDate(past.getDate() - 29)
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
  // Revert to last-30-days if no custom dates saved yet
  if (!customFrom.value || !customTo.value) {
    const today = new Date()
    const past = new Date()
    past.setDate(past.getDate() - 29)
    customTo.value = today.toISOString().slice(0, 10)
    customFrom.value = past.toISOString().slice(0, 10)
  }
}

const { data, refresh } = useAsyncData(
  'fuel-energy-analytics',
  () => $api('/fuel/transactions/analytics/', { query: periodQuery() }).catch(() => null),
  { default: () => null, watch: [period, fuelFilter, groupFilter, locationFilter] }
)

// --- Clustering map ---
const clusterMapEl = ref<HTMLElement | null>(null)
const stationMapData = computed(() => {
  const items = (data.value?.by_station || []) as any[]
  return items.filter((s: any) => s.station_name && s.station_location)
})

let _clusterMap: any = null
let _clusterMarkers: any[] = []

async function initClusterMap() {
  if (!clusterMapEl.value || !stationMapData.value.length) return

  // Destroy previous map + markers
  _clusterMarkers.forEach((m: any) => m?.setMap?.(null))
  _clusterMarkers = []
  if (_clusterMap && typeof _clusterMap === 'object' && 'dispose' in _clusterMap) {
    // Google Maps dispose? We just unbind
  }
  _clusterMap = null

  // Use the custom composable only if Google Maps is loaded
  const { ensureGoogle, createMap, geocodeAddress } = useGoogleMaps()
  try {
    const google = await ensureGoogle()
    const map = createMap(clusterMapEl.value!, { lat: -1.2921, lng: 36.8219 }, 12) // Nairobi center
    _clusterMap = map

    // Geocode each station and add a circle marker sized by refill count
    const bounds = new google.maps.LatLngBounds()
    for (const station of stationMapData.value) {
      if (!station.station_location) continue
      try {
        const result = await geocodeAddress(station.station_location)
        if (!result) continue
        const latLng = result
        bounds.extend(latLng)

        const count = station.count || 1
        const cost = parseFloat(station.total_cost || 0)
        const radius = Math.min(30, Math.max(10, 8 + count * 1.5))
        const alpha = Math.min(1, Math.max(0.2, cost / 50000))
        const hue = cost > 50000 ? 0 : cost > 20000 ? 30 : cost > 10000 ? 50 : 200
        const color = `hsla(${hue}, 70%, 55%, ${alpha})`

        const marker = new google.maps.Circle({
          map,
          center: latLng,
          radius: radius,
          fillColor: color,
          fillOpacity: 0.7,
          strokeColor: '#fff',
          strokeWeight: 1.5,
          zIndex: Math.round(count),
        })
        _clusterMarkers.push(marker)

        // Info tooltip via click listener
        const infoContent = `
          <div style="font-family:Inter,sans-serif;font-size:13px;line-height:1.5;min-width:140px">
            <strong>${station.station_name}</strong><br/>
            Fills: <b>${count}</b><br/>
            Cost: <b>${currencySymbol.value}${Number(cost).toLocaleString()}</b>
          </div>`
        const info = new google.maps.InfoWindow({ content: infoContent })
        google.maps.event.addListener(marker, 'click', () => info.open({ map, anchor: marker }))
      } catch (_) {
        // skip stations that can't be geocoded
      }
    }

    if (bounds && !bounds.isEmpty()) {
      map.fitBounds(bounds, { left: 30, right: 30, top: 30, bottom: 30 })
    }
  } catch (_) {
    // Google Maps not available
  }
}

// Initialize map when data loads or tab changes
watch([data, tab], () => {
  if (stationMapData.value.length > 0) {
    nextTick(() => setTimeout(() => initClusterMap(), 100))
  }
})

onUnmounted(() => {
  _clusterMarkers.forEach((m: any) => m?.setMap?.(null))
  _clusterMarkers = []
  _clusterMap = null
})

function formatNumber(val: any, decimals = 0) {
  if (!val || isNaN(val)) return '0'
  return Number(val).toLocaleString('en-US', { maximumFractionDigits: decimals, minimumFractionDigits: 0 })
}

const avgDailyCost = computed(() => {
  const items = data.value?.daily_trend || []
  if (!items.length) return 0
  const total = items.reduce((sum: number, d: any) => sum + parseFloat(d.total_cost || 0), 0)
  return total / items.length
})

const vehicleSearch = ref('')

const byVehicleItems = computed(() => {
  const items = data.value?.by_vehicle || []
  const rows = items.map((v: any) => ({
    ...v,
    name: [v.vehicle__make, v.vehicle__model].filter(Boolean).join(' ') || v.vehicle__vin || 'Unknown',
    license_plate: v.vehicle__license_plate || '',
    image: v.vehicle__image || '',
    avg_price: v.total_gallons ? parseFloat(v.total_cost) / parseFloat(v.total_gallons) : 0,
  }))
  // Sort by total_cost desc for Pareto
  rows.sort((a: any, b: any) => parseFloat(b.total_cost) - parseFloat(a.total_cost))
  return rows
})

const filteredByVehicleItems = computed(() => {
  const rows = byVehicleItems.value
  const q = (vehicleSearch.value || '').trim().toLowerCase()
  const filtered = q
    ? rows.filter((r: any) => r.name.toLowerCase().includes(q) || (r.license_plate || '').toLowerCase().includes(q))
    : rows
  // Recalculate cum % on the visible/filtered set so total = 100%
  const grandTotal = filtered.reduce((sum: number, r: any) => sum + parseFloat(r.total_cost || 0), 0)
  for (const r of filtered) {
    r.cum_pct = grandTotal > 0 ? +((parseFloat(r.total_cost || 0) / grandTotal) * 100).toFixed(1) : 0
  }
  return filtered
})

// Re-trigger chart resize when switching tabs so ECharts get proper dimensions
watch(tab, () => {
  nextTick(() => window.dispatchEvent(new Event('resize')))
})

const vehicleHeaders = [
  { title: 'Vehicle', key: 'vehicle_display', sortable: false, width: '220px' },
  { title: 'Plate', key: 'license_plate', sortable: true, width: '120px' },
  { title: 'Fills', key: 'fill_count', sortable: true, width: '70px' },
  { title: 'Volume', key: 'total_gallons', sortable: true, width: '100px' },
  { title: 'Total Cost', key: 'total_cost', sortable: true, width: '120px' },
  { title: 'Avg Price/Unit', key: 'avg_price', width: '120px' },
  { title: 'Total %', key: 'cum_pct', sortable: true, width: '100px', align: 'center' as const },
]

// --- Vehicle avatar helpers ---
const _gradients = [
  'linear-gradient(135deg, #6366f1, #818cf8)',
  'linear-gradient(135deg, #10b981, #34d399)',
  'linear-gradient(135deg, #f59e0b, #fbbf24)',
  'linear-gradient(135deg, #ef4444, #f87171)',
  'linear-gradient(135deg, #8b5cf6, #a78bfa)',
  'linear-gradient(135deg, #06b6d4, #22d3ee)',
  'linear-gradient(135deg, #ec4899, #f472b6)',
  'linear-gradient(135deg, #84cc16, #a3e635)',
]

function vehicleImageUrl(item: any): string {
  const url = item?.image
  if (!url) return ''
  if (/^https?:\/\//i.test(url)) return url
  const base = (useRuntimeConfig().public.apiBase || '').replace(/\/api\/?$/, '')
  // Raw DB field is like 'vehicles/cx5.jpg'; prepend MEDIA_URL ('media/')
  const path = url.replace(/^\/+/, '')
  return `${base}/media/${path}`
}

function vehicleAvatarStyle(item: any) {
  return vehicleImageUrl(item)
    ? { background: 'transparent' }
    : { background: _gradients[(item?.vehicle__vin || '').length % _gradients.length] }
}

// --- Chart options ---
const palette = ['#6366f1', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4', '#ec4899', '#84cc16']

const dailyCostOption = computed(() => {
  const items = data.value?.daily_trend || []
  return {
    tooltip: { trigger: 'axis', formatter: (p: any) => `${p[0].axisValue}<br/>Cost: ${currencySymbol.value}${p[0].data}<br/>Fills: ${items[p[0].dataIndex]?.count || 0}` },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: items.map((d: any) => d.day), axisLabel: { fontSize: 10, rotate: 30 } },
    yAxis: [{ type: 'value', name: 'Cost', axisLabel: { formatter: `${currencySymbol.value}{value}` } }],
    color: ['#6366f1'],
    series: [{ type: 'bar', data: items.map((d: any) => parseFloat(d.total_cost || 0)), itemStyle: { borderRadius: [6, 6, 0, 0], color: '#6366f1' }, barWidth: '50%' }],
  }
})

const weekdayRaceOption = computed(() => {
  const items = (data.value?.daily_trend || []) as any[]
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
  const totals: Record<string, number> = { Mon: 0, Tue: 0, Wed: 0, Thu: 0, Fri: 0, Sat: 0, Sun: 0 }
  const counts: Record<string, number> = { Mon: 0, Tue: 0, Wed: 0, Thu: 0, Fri: 0, Sat: 0, Sun: 0 }
  for (const d of items) {
    if (!d.day) continue
    const dow = new Date(d.day).getDay() // 0=Sun … 6=Sat
    const label = weekdays[(dow + 6) % 7]
    totals[label] += parseFloat(d.total_cost || 0)
    counts[label] += d.count || 0
  }
  // Sort by total cost descending (highest first)
  const sorted = weekdays
    .map((w, i) => ({ label: w, cost: +totals[w].toFixed(2), fills: counts[w], idx: i }))
    .sort((a, b) => b.cost - a.cost)
  const colors = sorted.map((s) => {
    const hue = 235 + (s.idx * 18) % 120
    return `hsl(${hue}, 70%, 55%)`
  })
  return {
    tooltip: {
      trigger: 'axis',
      axisPointer: { type: 'shadow' },
      formatter: (p: any) => {
        const label = p[0].axisValue
        const cost = Number(p[0].data).toLocaleString()
        const fills = sorted[p[0].dataIndex]?.fills || 0
        return `${label}<br/>Cost: ${currencySymbol.value}${cost}<br/>Fills: ${fills}`
      },
    },
    grid: { left: '3%', right: '8%', bottom: '3%', top: '5%', containLabel: true },
    xAxis: { type: 'value', name: 'Cost', axisLabel: { formatter: `${currencySymbol.value}{value}` } },
    yAxis: { type: 'category', data: sorted.map((s) => s.label), axisLabel: { fontSize: 12, fontWeight: 'bold' }, inverse: true },
    series: [{
      type: 'bar',
      data: sorted.map((s) => s.cost),
      itemStyle: {
        borderRadius: [0, 8, 8, 0],
        color: (params: any) => colors[params.dataIndex],
      },
      barWidth: '55%',
      label: { show: true, position: 'right', formatter: (p: any) => sorted[p.dataIndex]?.fills ? `${sorted[p.dataIndex].fills} fills` : '', fontSize: 10, color: '#94a3b8' },
    }],
    animationDuration: 800,
    animationEasing: 'cubicOut',
  }
})

const priceTrendOption = computed(() => {
  const items = data.value?.price_trend || []
  return {
    tooltip: { trigger: 'axis', formatter: (p: any) => `${p[0].axisValue}<br/>Price/Unit: ${currencySymbol.value}${p[0].data}` },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: items.map((d: any) => d.day), axisLabel: { fontSize: 10, rotate: 30 } },
    yAxis: { type: 'value', name: 'Price/Unit', axisLabel: { formatter: `${currencySymbol.value}{value}` } },
    color: ['#10b981'],
    series: [{ type: 'line', data: items.map((d: any) => d.avg_price_per_gallon || 0), smooth: true, areaStyle: { opacity: 0.15 }, lineStyle: { width: 3 }, symbolSize: 6 }],
  }
})

const monthlyTrendOption = computed(() => {
  const items = data.value?.monthly_trend || []
  return {
    tooltip: { trigger: 'axis' },
    legend: { data: ['Cost', 'Volume'], bottom: 0, textStyle: { fontSize: 11 } },
    grid: { left: '3%', right: '4%', bottom: '10%', containLabel: true },
    xAxis: { type: 'category', data: items.map((m: any) => m.month), axisLabel: { fontSize: 11, rotate: 30 } },
    yAxis: [
      { type: 'value', name: 'Cost', axisLabel: { formatter: `${currencySymbol.value}{value}` } },
      { type: 'value', name: 'Volume' },
    ],
    color: ['#6366f1', '#f59e0b'],
    series: [
      { name: 'Cost', type: 'bar', data: items.map((m: any) => parseFloat(m.total_cost || 0)), itemStyle: { borderRadius: [6, 6, 0, 0] }, barWidth: '40%' },
      { name: 'Volume', type: 'line', yAxisIndex: 1, data: items.map((m: any) => parseFloat(m.total_gallons || 0)), smooth: true, lineStyle: { width: 3 }, symbolSize: 8 },
    ],
  }
})

const fuelTypeBreakdownOption = computed(() => {
  const items = data.value?.by_fuel_type || []
  return {
    tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
    legend: { bottom: 0, textStyle: { fontSize: 10 } },
    color: ['#6366f1', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4', '#ec4899', '#84cc16', '#f97316', '#14b8a6'],
    series: [{ type: 'pie', radius: ['40%', '70%'], itemStyle: { borderRadius: 8, borderColor: '#fff', borderWidth: 2 }, label: { show: false }, data: items.map((f: any) => ({ name: f.fuel_type, value: parseFloat(f.total_cost || 0) })) }],
  }
})

const groupLineRaceOption = computed(() => {
  const items = (data.value?.by_group_daily || []) as any[]
  // Build a map: { day -> { group -> cost } }
  const daySet = new Set<string>()
  const groupSet = new Set<string>()
  const dayGroupMap: Record<string, Record<string, number>> = {}
  for (const row of items) {
    const day = row.day || ''
    const group = row['vehicle__group__name'] || 'Unknown'
    const cost = parseFloat(row.total_cost || 0)
    daySet.add(day)
    groupSet.add(group)
    if (!dayGroupMap[day]) dayGroupMap[day] = {}
    dayGroupMap[day][group] = (dayGroupMap[day][group] || 0) + cost
  }
  const days = [...daySet].sort()
  const groups = [...groupSet]
  const colors = ['#6366f1', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4', '#ec4899', '#84cc16', '#f97316', '#14b8a6']

  // Build cumulative running totals per group (line race style)
  const series = groups.map((g, i) => {
    let running = 0
    const dataPoints = days.map((d) => {
      running += dayGroupMap[d]?.[g] || 0
      return +running.toFixed(2)
    })
    return {
      name: g,
      type: 'line',
      smooth: true,
      symbol: 'circle',
      symbolSize: 5,
      lineStyle: { width: 2.5 },
      itemStyle: { color: colors[i % colors.length] },
      data: dataPoints,
    }
  })

  return {
    tooltip: {
      trigger: 'axis',
      formatter: (p: any) => {
        let html = p[0]?.axisValue || ''
        for (const d of p) {
          html += `<br/>${d.marker} ${d.seriesName}: ${currencySymbol.value}${Number(d.data).toLocaleString()}`
        }
        return html
      },
    },
    legend: { bottom: 0, textStyle: { fontSize: 10 } },
    grid: { left: '3%', right: '4%', bottom: '15%', containLabel: true },
    xAxis: {
      type: 'category',
      data: days,
      axisLabel: { fontSize: 10, rotate: 30 },
      boundaryGap: false,
    },
    yAxis: {
      type: 'value',
      name: 'Cum Cost',
      axisLabel: { formatter: `${currencySymbol.value}{value}` },
    },
    color: colors,
    series,
  }
})

const stationBreakdownOption = computed(() => {
  const items = data.value?.by_station || []
  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'value', axisLabel: { formatter: `${currencySymbol.value}{value}` } },
    yAxis: { type: 'category', data: items.map((s: any) => s.station_name), axisLabel: { fontSize: 11 } },
    color: palette,
    series: [{ type: 'bar', data: items.map((s: any) => parseFloat(s.total_cost || 0)), itemStyle: { borderRadius: [0, 6, 6, 0], color: '#818cf8' }, barWidth: '60%' }],
  }
})

// --- By Vehicle charts ---
const vehicleCostChartOption = computed(() => {
  const items = byVehicleItems.value
  const top = items.slice(0, 15)
  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, formatter: (p: any) => `${p[0].name}<br/>Cost: ${currencySymbol.value}${Number(p[0].value).toLocaleString()}` },
    grid: { left: '3%', right: '4%', bottom: '10%', containLabel: true },
    xAxis: { type: 'category', data: top.map((v: any) => v.name), axisLabel: { fontSize: 10, rotate: 35, interval: 0 } },
    yAxis: { type: 'value', name: 'Cost', axisLabel: { formatter: `${currencySymbol.value}{value}` } },
    color: ['#6366f1'],
    series: [{ type: 'bar', name: 'Cost', data: top.map((v: any) => parseFloat(v.total_cost || 0)), itemStyle: { borderRadius: [6, 6, 0, 0], color: '#6366f1' }, barWidth: '50%' }],
  }
})

const vehicleCumCostChartOption = computed(() => {
  const items = byVehicleItems.value
  const top = items.slice(0, 15)
  return {
    tooltip: { trigger: 'axis', formatter: (p: any) => p.map((d: any) => `${d.seriesName}: ${d.seriesName === 'Cum %' ? d.value + '%' : currencySymbol.value + Number(d.value).toLocaleString()}`).join('<br/>') },
    legend: { data: ['Cost', 'Cum %'], bottom: 0, textStyle: { fontSize: 11 } },
    grid: { left: '3%', right: '6%', bottom: '10%', containLabel: true },
    xAxis: { type: 'category', data: top.map((v: any) => v.name), axisLabel: { fontSize: 10, rotate: 35, interval: 0 } },
    yAxis: [
      { type: 'value', name: 'Cost', axisLabel: { formatter: `${currencySymbol.value}{value}` } },
      { type: 'value', name: 'Cum %', max: 100, axisLabel: { formatter: '{value}%' } },
    ],
    color: ['#6366f1', '#ef4444'],
    series: [
      { name: 'Cost', type: 'bar', data: top.map((v: any) => parseFloat(v.total_cost || 0)), itemStyle: { borderRadius: [6, 6, 0, 0] }, barWidth: '45%' },
      { name: 'Cum %', type: 'line', yAxisIndex: 1, data: top.map((v: any) => v.cum_pct || 0), smooth: true, lineStyle: { width: 3, color: '#ef4444' }, itemStyle: { color: '#ef4444' }, symbolSize: 6 },
    ],
  }
})

const vehicleVolumeChartOption = computed(() => {
  const items = byVehicleItems.value
  const top = items.slice(0, 15)
  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, formatter: (p: any) => `${p[0].name}<br/>Volume: ${Number(p[0].value).toLocaleString()}` },
    grid: { left: '3%', right: '4%', bottom: '10%', containLabel: true },
    xAxis: { type: 'value', name: 'Volume' },
    yAxis: { type: 'category', data: top.map((v: any) => v.name).reverse(), axisLabel: { fontSize: 10 } },
    color: ['#f59e0b'],
    series: [{ type: 'bar', data: top.map((v: any) => parseFloat(v.total_gallons || 0)).reverse(), itemStyle: { borderRadius: [0, 6, 6, 0], color: '#fbbf24' }, barWidth: '55%' }],
  }
})

const vehicleFillsChartOption = computed(() => {
  const items = byVehicleItems.value
  const top = items.slice(0, 15)
  return {
    tooltip: { trigger: 'axis', formatter: (p: any) => `${p[0].name}<br/>Fills: ${p[0].value}` },
    grid: { left: '3%', right: '4%', bottom: '10%', containLabel: true },
    xAxis: { type: 'value', name: 'Fills', minInterval: 1 },
    yAxis: { type: 'category', data: top.map((v: any) => v.name).reverse(), axisLabel: { fontSize: 10 } },
    color: ['#10b981'],
    series: [{ type: 'bar', data: top.map((v: any) => v.fill_count || 0).reverse(), itemStyle: { borderRadius: [0, 6, 6, 0], color: '#34d399' }, barWidth: '55%' }],
  }
})
</script>

<style scoped>
.text-white-70 { opacity: 0.7; }

/* Filters inherit parent background with subtle rounded inset look */
.analytics-filters :deep(.v-field--solo-filled) {
  background: rgba(100, 116, 139, 0.08);
  box-shadow: none;
  border: 1px solid rgba(100, 116, 139, 0.12);
}
.analytics-filters :deep(.v-field--solo-filled:hover) {
  background: rgba(99, 102, 241, 0.06);
  border-color: rgba(99, 102, 241, 0.25);
}
.analytics-filters :deep(.v-field--solo-filled.v-field--focused) {
  background: rgba(99, 102, 241, 0.04);
  border-color: #6366f1;
  box-shadow: 0 0 0 1px rgba(99, 102, 241, 0.2);
}
/* Remove the default filled padding bottom */
.analytics-filters :deep(.v-field--solo-filled .v-field__outline) {
  --v-field-border-width: 0;
}
/* Smaller label text inside selects */
.analytics-filters :deep(.v-field-label) {
  font-size: 12px;
  opacity: 0.7;
}

.vehicle-avatar {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  box-shadow: 0 2px 6px rgba(15, 23, 42, 0.12);
  overflow: hidden;
}
.vehicle-avatar__img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}
</style>
