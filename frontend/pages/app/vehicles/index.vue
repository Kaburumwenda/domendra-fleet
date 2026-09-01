<template>
  <div class="d-flex flex-column ga-4">
    <!-- Premium Header -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-2">
      <div>
        <h1 class="text-h4 font-weight-bold d-flex align-center ga-2" style="color: #1e293b">
          <v-icon color="primary" size="large">mdi-car-multiple</v-icon>
          Vehicle Management
        </h1>
        <p class="text-caption text-medium-emphasis mt-1">Premium fleet management â€” overview, fleet health, utilization, cost analysis and ABC Pareto classification</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-tooltip text="Refresh">
          <template #activator="{ props }">
            <v-btn v-bind="props" icon="mdi-refresh" size="small" variant="text" color="medium-emphasis" :loading="analyticsPending" @click="refreshAnalytics" />
          </template>
        </v-tooltip>
        <v-btn v-can="'vehicles:create'" color="primary" prepend-icon="mdi-plus" to="/app/vehicles/new">
          <v-icon start>mdi-car</v-icon>
          Add Vehicle
        </v-btn>
      </div>
    </div>

    <!-- Tabbed Interface -->
    <v-card elevation="0" border rounded="xl" class="overflow-hidden">
      <v-tabs v-model="tab" color="primary" density="comfortable" show-arrows>
        <v-tab value="overview" prepend-icon="mdi-view-dashboard-outline">Overview</v-tab>
        <v-tab value="vehicles" prepend-icon="mdi-car-multiple">
          Vehicles
          <v-chip v-if="counts.vehicles" size="x-small" class="ml-2" color="primary" variant="tonal">{{ counts.vehicles }}</v-chip>
        </v-tab>
        <v-tab value="health" prepend-icon="mdi-shield-check">Fleet Health</v-tab>
        <v-tab value="utilization" prepend-icon="mdi-chart-line">Utilization</v-tab>
        <v-tab value="analytics" prepend-icon="mdi-chart-box-outline">Analytics</v-tab>
        <v-tab value="catalog" prepend-icon="mdi-book-open-variant">
          Catalog
          <v-chip v-if="counts.catalog" size="x-small" class="ml-2" color="primary" variant="tonal">{{ counts.catalog }}</v-chip>
        </v-tab>
        <v-tab value="groups" prepend-icon="mdi-folder-multiple">
          Groups
          <v-chip v-if="counts.groups" size="x-small" class="ml-2" color="primary" variant="tonal">{{ counts.groups }}</v-chip>
        </v-tab>
        <v-tab value="types" prepend-icon="mdi-shape">
          Vehicle Types
          <v-chip v-if="counts.types" size="x-small" class="ml-2" color="primary" variant="tonal">{{ counts.types }}</v-chip>
        </v-tab>
        <v-tab value="locations" prepend-icon="mdi-map-marker-multiple">
          Locations
          <v-chip v-if="counts.locations" size="x-small" class="ml-2" color="primary" variant="tonal">{{ counts.locations }}</v-chip>
        </v-tab>
      </v-tabs>
      <v-divider />
      <v-window v-model="tab" class="pa-5">
        <v-window-item value="overview">
          <!-- Overview Date Filter Bar -->
          <v-card elevation="0" border class="pa-4 mb-4">
            <div class="d-flex align-center flex-wrap ga-3">
              <div class="d-flex align-center ga-2">
                <v-icon size="small" color="medium-emphasis">mdi-filter-variant</v-icon>
                <span class="text-body-2 font-weight-medium text-medium-emphasis">Date Range</span>
              </div>
              <v-btn-group density="compact" variant="outlined" color="primary">
                <v-btn
                  v-for="preset in datePresets"
                  :key="preset.key"
                  :variant="analyticsPresetKey === preset.key ? 'flat' : 'text'"
                  :color="analyticsPresetKey === preset.key ? 'primary' : 'medium-emphasis'"
                  size="small"
                  @click="applyPreset(preset.key)"
                >
                  {{ preset.label }}
                </v-btn>
              </v-btn-group>
              <v-spacer />
              <div class="d-flex align-center ga-2">
                <v-text-field
                  v-model="analyticsFilters.startDate"
                  type="date"
                  label="From"
                  density="compact"
                  variant="outlined"
                  hide-details
                  style="max-width: 170px;"
                  @update:model-value="onCustomDate"
                />
                <v-text-field
                  v-model="analyticsFilters.endDate"
                  type="date"
                  label="To"
                  density="compact"
                  variant="outlined"
                  hide-details
                  style="max-width: 170px;"
                  @update:model-value="onCustomDate"
                />
              </div>
            </div>
          </v-card>
          <VehicleAnalytics :data="analytics" />
        </v-window-item>
        <v-window-item value="vehicles">
          <VehiclesTab />
          <VehicleLocationMap class="mt-4" />
        </v-window-item>
        <v-window-item value="health">
          <!-- Fleet Health Date Filter Bar -->
          <v-card elevation="0" border class="pa-4 mb-4">
            <div class="d-flex align-center flex-wrap ga-3">
              <div class="d-flex align-center ga-2">
                <v-icon size="small" color="medium-emphasis">mdi-filter-variant</v-icon>
                <span class="text-body-2 font-weight-medium text-medium-emphasis">Date Range</span>
              </div>
              <v-btn-group density="compact" variant="outlined" color="primary">
                <v-btn
                  v-for="preset in datePresets"
                  :key="preset.key"
                  :variant="analyticsPresetKey === preset.key ? 'flat' : 'text'"
                  :color="analyticsPresetKey === preset.key ? 'primary' : 'medium-emphasis'"
                  size="small"
                  @click="applyPreset(preset.key)"
                >
                  {{ preset.label }}
                </v-btn>
              </v-btn-group>
              <v-spacer />
              <div class="d-flex align-center ga-2">
                <v-text-field
                  v-model="analyticsFilters.startDate"
                  type="date"
                  label="From"
                  density="compact"
                  variant="outlined"
                  hide-details
                  style="max-width: 170px;"
                  @update:model-value="onCustomDate"
                />
                <v-text-field
                  v-model="analyticsFilters.endDate"
                  type="date"
                  label="To"
                  density="compact"
                  variant="outlined"
                  hide-details
                  style="max-width: 170px;"
                  @update:model-value="onCustomDate"
                />
              </div>
            </div>
          </v-card>
          <VehicleFleetHealth :data="analytics" />
        </v-window-item>
        <v-window-item value="utilization">
          <VehicleUtilization :data="analytics" />
        </v-window-item>
        <v-window-item value="analytics">
          <!-- Analytics Date Filter Bar -->
          <v-card elevation="0" border class="pa-4 mb-4">
            <div class="d-flex align-center flex-wrap ga-3">
              <div class="d-flex align-center ga-2">
                <v-icon size="small" color="medium-emphasis">mdi-filter-variant</v-icon>
                <span class="text-body-2 font-weight-medium text-medium-emphasis">Date Range</span>
              </div>
              <v-btn-group density="compact" variant="outlined" color="primary">
                <v-btn
                  v-for="preset in datePresets"
                  :key="preset.key"
                  :variant="analyticsPresetKey === preset.key ? 'flat' : 'text'"
                  :color="analyticsPresetKey === preset.key ? 'primary' : 'medium-emphasis'"
                  size="small"
                  @click="applyPreset(preset.key)"
                >
                  {{ preset.label }}
                </v-btn>
              </v-btn-group>
              <v-spacer />
              <div class="d-flex align-center ga-2">
                <v-text-field
                  v-model="analyticsFilters.startDate"
                  type="date"
                  label="From"
                  density="compact"
                  variant="outlined"
                  hide-details
                  style="max-width: 170px;"
                  @update:model-value="onCustomDate"
                />
                <v-text-field
                  v-model="analyticsFilters.endDate"
                  type="date"
                  label="To"
                  density="compact"
                  variant="outlined"
                  hide-details
                  style="max-width: 170px;"
                  @update:model-value="onCustomDate"
                />
              </div>
            </div>
          </v-card>

          <v-tabs v-model="analyticsTab" color="primary" density="compact" grow class="mb-4">
            <v-tab value="cost" prepend-icon="mdi-cash-multiple">Cost Analysis</v-tab>
            <v-tab value="abc" prepend-icon="mdi-chart-bar">ABC Analysis</v-tab>
            <v-tab value="type" prepend-icon="mdi-shape">Vehicle Type Analysis</v-tab>
            <v-tab value="location" prepend-icon="mdi-map-marker-multiple">Location Analysis</v-tab>
          </v-tabs>
          <v-window v-model="analyticsTab">
            <v-window-item value="cost">
              <VehicleCostAnalysis :data="analytics" />
            </v-window-item>
            <v-window-item value="abc">
              <VehicleAbcAnalysis :data="analytics" />
            </v-window-item>
            <v-window-item value="type">
              <VehicleTypeAnalysis :data="analytics" />
            </v-window-item>
            <v-window-item value="location">
              <VehicleLocationAnalysis :data="analytics" />
            </v-window-item>
          </v-window>
        </v-window-item>
        <v-window-item value="catalog">
          <VehicleCatalogTab />
        </v-window-item>
        <v-window-item value="groups">
          <GroupsTab />
        </v-window-item>
        <v-window-item value="types">
          <VehicleTypesTab />
        </v-window-item>
        <v-window-item value="locations">
          <VehicleLocationsTab />
        </v-window-item>
      </v-window>
    </v-card>
  </div>
</template>

<script setup lang="ts">
import VehicleLocationsTab from '~/components/vehicles/VehicleLocationsTab.vue'
const { $api } = useNuxtApp()
const { fetchAnalytics } = useVehicleApi()
const tab = ref('overview')
const analyticsTab = ref('cost')

const counts = reactive({ vehicles: 0, catalog: 0, groups: 0, types: 0, locations: 0 })

// ---- Analytics Date Filters ----
const datePresets = [
  { key: 'month', label: 'This Month' },
  { key: 'quarter', label: 'This Quarter' },
  { key: 'year', label: 'This Year' },
  { key: '12m', label: 'Last 12 Months' },
  { key: 'all', label: 'All Time' },
] as const
const analyticsPresetKey = ref('all')
const analyticsFilters = reactive({ startDate: '', endDate: '' })

function dateRange(key: string): { start: string; end: string } {
  const now = new Date()
  const fmt = (d: Date) => {
    const y = d.getFullYear()
    const m = String(d.getMonth() + 1).padStart(2, '0')
    const day = String(d.getDate()).padStart(2, '0')
    return `${y}-${m}-${day}`
  }
  const end = fmt(now)
  let start: string
  switch (key) {
    case 'month':
      start = fmt(new Date(now.getFullYear(), now.getMonth(), 1))
      break
    case 'quarter':
      start = fmt(new Date(now.getFullYear(), Math.floor(now.getMonth() / 3) * 3, 1))
      break
    case 'year':
      start = fmt(new Date(now.getFullYear(), 0, 1))
      break
    case '12m':
      const d = new Date(now)
      d.setFullYear(d.getFullYear() - 1)
      start = fmt(d)
      break
    default:
      start = ''
  }
  return { start, end }
}

function applyPreset(key: string) {
  analyticsPresetKey.value = key
  if (key === 'all') {
    analyticsFilters.startDate = ''
    analyticsFilters.endDate = ''
  } else {
    const { start, end } = dateRange(key)
    analyticsFilters.startDate = start
    analyticsFilters.endDate = end
  }
}

function onCustomDate() {
  analyticsPresetKey.value = 'custom'
  refreshAnalytics()
}

// ---- Analytics ----
const { data: analytics, pending: analyticsPending, refresh: refreshAnalytics } = useAsyncData(
  'vehicle-page-analytics',
  () => fetchAnalytics({
    rev_start: analyticsFilters.startDate || undefined,
    rev_end: analyticsFilters.endDate || undefined,
  }).catch(() => null) as Promise<any>,
  {
    default: () => null,
    watch: [() => analyticsFilters.startDate, () => analyticsFilters.endDate],
  }
)

// ---- Tab counts ----
useAsyncData('vehicles-tab-counts', async () => {
  const [v, c, g, t, l] = await Promise.all([
    fetchAnalytics().catch(() => ({ total_vehicles: 0 })),
    $api('/vehicles/catalog/makes/?page_size=1').catch(() => ({ count: 0 })),
    $api('/vehicles/groups/').catch(() => ({ count: 0 })),
    $api('/vehicles/vehicle-types/').catch(() => ({ count: 0 })),
    $api('/locations/').catch(() => ({ count: 0 })),
  ])
  counts.vehicles = (v as any)?.total_vehicles ?? 0
  counts.catalog = (c as any)?.count ?? (c as any)?.results?.length ?? 0
  counts.groups = (g as any)?.count ?? (g as any)?.results?.length ?? 0
  counts.types = (t as any)?.count ?? (t as any)?.results?.length ?? 0
  counts.locations = (l as any)?.count ?? (l as any)?.results?.length ?? 0
  return counts
})
</script>
