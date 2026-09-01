<template>
  <v-dialog v-model="dialog" max-width="800" scrollable>
    <v-card rounded="xl" class="pa-0">
      <!-- Header -->
      <v-card-title class="d-flex align-center ga-2 pa-5 border-b" style="gap: 12px">
        <v-avatar color="warning" size="40" rounded="lg">
          <v-icon>mdi-traffic-cone</v-icon>
        </v-avatar>
        <div class="flex-grow-1">
          <h3 class="text-h6 font-weight-bold">Traffic Alerts &amp; Weather</h3>
          <p class="text-caption text-medium-emphasis">Select a job to view real-time road conditions</p>
        </div>
        <v-spacer />
        <v-btn icon variant="text" size="small" @click="dialog = false"><v-icon>mdi-close</v-icon></v-btn>
      </v-card-title>

      <!-- Job selector + refresh bar -->
      <div class="d-flex align-center ga-3 pa-4 border-b">
        <v-autocomplete
          v-model="selectedJobId"
          :items="jobItems"
          label="Select Job"
          density="compact"
          variant="outlined"
          hide-details
          rounded="lg"
          prepend-inner-icon="mdi-map-marker-path"
          class="flex-grow-1"
          :style="{ maxWidth: '380px' }"
        />
        <v-spacer />
        <v-btn color="primary" variant="tonal" prepend-icon="mdi-refresh" :loading="loading" :disabled="loading || !selectedJobId" @click="fetchData">
          Refresh
        </v-btn>
      </div>

      <!-- Alerts banner -->
      <div v-if="trafficData?.has_traffic_data && trafficDelayChip" class="pa-4 border-b">
        <v-alert
          :type="trafficDelayChip.type"
          variant="tonal"
          density="comfortable"
          rounded="lg"
          class="mb-0"
        >
          <template #prepend><v-icon :icon="trafficDelayChip.icon" /></template>
          <div class="d-flex align-center ga-3">
            <div>
              <p class="font-weight-bold mb-0">{{ trafficDelayChip.title }}</p>
              <p class="text-caption mb-0">{{ trafficDelayChip.subtitle }}</p>
            </div>
          </div>
        </v-alert>
      </div>

      <!-- Weather alert if adverse -->
      <div v-if="adverseWeatherAlert" class="pa-4 border-b">
        <v-alert type="error" variant="tonal" density="comfortable" rounded="lg">
          <template #prepend><v-icon icon="mdi-weather-pouring" /></template>
          <p class="font-weight-bold mb-0">{{ adverseWeatherAlert }}</p>
        </v-alert>
      </div>

      <!-- Loading -->
      <div v-if="loading" class="d-flex justify-center align-center py-12">
        <v-progress-circular indeterminate color="primary" size="48" />
        <p class="text-caption text-medium-emphasis ml-4">Fetching live traffic and weather…</p>
      </div>

      <template v-else>
        <!-- Traffic comparison cards -->
        <div v-if="trafficData" class="pa-4">
          <h4 class="text-subtitle-2 font-weight-bold mb-3">
            <v-icon size="18" color="warning" class="mr-1">mdi-traffic-cone</v-icon>
            Traffic vs. Free-Flow
          </h4>
          <div class="d-flex flex-wrap ga-3 mb-4">
            <StatCard
              label="Normal Drive Time"
              :value="trafficData.total_duration_text"
              icon="mdi-clock-outline"
              icon-color="info"
            />
            <StatCard
              label="Traffic-Adjusted"
              :value="trafficData.total_duration_in_traffic_text"
              icon="mdi-traffic-cone"
              :icon-color="trafficData.total_delay_s > 300 ? 'error' : 'warning'"
            />
            <StatCard
              label="Delay"
              :value="`+${trafficData.total_delay_text}`"
              icon="mdi-timer-alert"
              :icon-color="trafficData.total_delay_s > 300 ? 'error' : 'success'"
            />
            <StatCard
              label="Total Distance"
              :value="`${trafficData.total_distance_km} km`"
              icon="mdi-map-marker-distance"
              icon-color="primary"
            />
          </div>

          <!-- Leg-by-leg breakdown -->
          <h4 class="text-subtitle-2 font-weight-bold mb-3">
            <v-icon size="18" color="primary" class="mr-1">mdi-chart-timeline-variant</v-icon>
            Leg-by-Leg Breakdown
          </h4>
          <v-data-table
            :items="trafficLegs"
            :headers="legHeaders"
            density="compact"
            hide-default-footer
            class="border rounded-lg mb-4"
          >
            <template #item.leg="{ item, index }">
              <span class="font-weight-medium">Leg {{ index + 1 }}</span>
            </template>
            <template #item.delay="{ item }">
              <v-chip
                :color="(item.delay_s || 0) > 180 ? 'error' : (item.delay_s || 0) > 60 ? 'warning' : 'success'"
                size="small"
                variant="tonal"
              >
                {{ item.delay_text }}
              </v-chip>
            </template>
            <template #item.traffic="{ item }">
              <v-icon v-if="(item.delay_s || 0) > 180" color="error" size="small">mdi-traffic-cone</v-icon>
              <v-icon v-else-if="(item.delay_s || 0) > 60" color="warning" size="small">mdi-alert</v-icon>
              <v-icon v-else color="success" size="small">mdi-check-circle</v-icon>
            </template>
          </v-data-table>
        </div>

        <!-- Weather conditions -->
        <div v-if="weatherData" class="pa-4 border-t">
          <h4 class="text-subtitle-2 font-weight-bold mb-3">
            <v-icon size="18" color="info" class="mr-1">mdi-weather-partly-cloudy</v-icon>
            Weather Along Route
          </h4>
          <div class="weather-grid">
            <div v-for="(w, i) in weatherData.results" :key="i" class="weather-card">
              <div class="d-flex align-center ga-3 mb-2">
                <v-avatar size="40" :color="weatherColorClass(w).color" variant="tonal" rounded>
                  <v-icon :icon="weatherIcon(w)" />
                </v-avatar>
                <div>
                  <p class="font-weight-bold mb-0 text-body-2">{{ pointLabel(i) }}</p>
                  <p class="text-caption mb-0">{{ w.description }}</p>
                </div>
              </div>
              <div class="d-flex flex-wrap ga-2">
                <v-chip size="x-small" variant="tonal" color="warning" prepend-icon="mdi-thermometer">{{ w.temperature ?? '—' }}°C</v-chip>
                <v-chip size="x-small" variant="tonal" color="info" prepend-icon="mdi-weather-windy">{{ w.wind_speed ?? '—' }} km/h</v-chip>
                <v-chip v-if="w.precipitation != null" size="x-small" variant="tonal" color="primary" prepend-icon="mdi-weather-pouring">{{ w.precipitation }}mm</v-chip>
                <v-chip v-if="w.cloud_cover != null" size="x-small" variant="flat" prepend-icon="mdi-cloud">{{ w.cloud_cover }}%</v-chip>
                <v-chip v-if="w.visibility != null" size="x-small" variant="tonal" color="success" prepend-icon="mdi-eye">{{ w.visibility }}km</v-chip>
              </div>
            </div>
          </div>
        </div>
      </template>

      <!-- Footer -->
      <v-card-actions class="pa-4 border-t">
        <v-spacer />
        <v-btn variant="text" @click="dialog = false">Close</v-btn>
        <v-btn color="primary" prepend-icon="mdi-refresh" :loading="loading" :disabled="loading" @click="fetchData">
          Refresh
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
const props = defineProps<{
  modelValue: boolean
  job: any
  stops: any[]
  jobs: any[]
}>()
const emit = defineEmits<{
  'update:modelValue': [val: boolean]
  'job-change': [jobId: number]
}>()

const { $api } = useNuxtApp() as any

const dialog = computed({
  get: () => props.modelValue,
  set: (v) => emit('update:modelValue', v),
})

const selectedJobId = ref<number | null>(null)

const geocodedJobs = computed(() =>
  (props.jobs || []).filter(j => j.pickup_lat != null && j.dropoff_lat != null)
)

const jobItems = computed(() =>
  geocodedJobs.value.map(j => ({
    title: j.title || `Job #${j.id}`,
    value: j.id,
    props: { subtitle: `${j.pickup_address || ''} → ${j.dropoff_address || ''}` },
  }))
)

const loading = ref(false)
const trafficData = ref<any>(null)
const weatherData = ref<any>(null)

const legHeaders = [
  { title: 'Leg', key: 'leg', sortable: false, width: '80px' },
  { title: 'Distance', key: 'distance_text', sortable: false, width: '100px' },
  { title: 'Normal', key: 'duration_text', sortable: false, width: '100px' },
  { title: 'Traffic', key: 'duration_in_traffic_text', sortable: false, width: '100px' },
  { title: 'Delay', key: 'delay', sortable: false, width: '100px' },
  { title: '', key: 'traffic', sortable: false, width: '50px' },
]

const trafficLegs = computed(() => trafficData.value?.legs?.filter(l => !l.error) || [])

const trafficDelayChip = computed(() => {
  if (!trafficData.value?.has_traffic_data) return null
  const delay = trafficData.value.total_delay_s || 0
  if (delay > 600) return { type: 'error', icon: 'mdi-traffic-cone', title: 'Severe Traffic Delay', subtitle: `+${trafficData.value.total_delay_text} above normal — consider rerouting` }
  if (delay > 300) return { type: 'warning', icon: 'mdi-alert', title: 'Significant Traffic Delay', subtitle: `+${trafficData.value.total_delay_text} above normal` }
  if (delay > 60) return { type: 'info', icon: 'mdi-information', title: 'Light Traffic', subtitle: `+${trafficData.value.total_delay_text} above normal` }
  return { type: 'success', icon: 'mdi-check-circle', title: 'Clear Traffic', subtitle: 'Route is flowing normally' }
})

const adverseWeatherAlert = computed(() => {
  if (!weatherData.value?.results) return null
  const adverse = weatherData.value.results.find(w => {
    const c = w.weather_code
    return c != null && (c >= 61 && c <= 67 || c >= 80 && c <= 82 || c >= 85 && c <= 86 || c >= 95 && c <= 99 || c >= 45 && c <= 48)
  })
  return adverse ? `${adverse.description || 'Adverse weather'} detected along route — drive cautiously` : null
})

function pointLabel(i: number) {
  if (i === 0) return 'Origin'
  if (i === weatherData.value.results.length - 1) return 'Destination'
  return `Stop ${i}`
}

function weatherIcon(w: any) {
  const c = w.weather_code
  if (w.is_day === false) {
    if (c === 0) return 'mdi-weather-night'
    if (c >= 61 && c <= 82) return 'mdi-weather-pouring'
    if (c >= 71 && c <= 86) return 'mdi-weather-snowy-heavy'
    if (c >= 95) return 'mdi-weather-lightning'
    return 'mdi-weather-night-cloudy'
  }
  if (c === 0 || c === 1) return 'mdi-weather-sunny'
  if (c === 2) return 'mdi-weather-partly-cloudy'
  if (c === 3) return 'mdi-weather-cloudy'
  if (c >= 45 && c <= 48) return 'mdi-weather-fog'
  if (c >= 51 && c <= 57) return 'mdi-weather-rainy'
  if (c >= 61 && c <= 67) return 'mdi-weather-pouring'
  if (c >= 71 && c <= 77) return 'mdi-weather-snowy'
  if (c >= 80 && c <= 82) return 'mdi-weather-pouring'
  if (c >= 85 && c <= 86) return 'mdi-weather-snowy-heavy'
  if (c >= 95) return 'mdi-weather-lightning'
  return 'mdi-weather-cloudy'
}

function weatherColorClass(w: any) {
  const c = w.weather_code
  if (c == null) return { color: 'grey' }
  if (c === 0 || c === 1) return { color: 'warning' }
  if (c >= 45 && c <= 48) return { color: 'grey' }
  if (c >= 51 && c <= 67) return { color: 'info' }
  if (c >= 80 && c <= 82) return { color: 'info' }
  if (c >= 71 && c <= 86) return { color: 'primary' }
  if (c >= 95) return { color: 'error' }
  return { color: 'secondary' }
}

async function fetchData() {
  const j = selectedJobId.value
    ? geocodedJobs.value.find(g => g.id === selectedJobId.value) || props.job
    : props.job
  if (!j) return
  loading.value = true
  trafficData.value = null
  weatherData.value = null
  try {
    // Fetch stops for the selected job if different from props.job
    let stops = props.stops
    if (selectedJobId.value && props.job?.id !== selectedJobId.value) {
      try {
        const data = await $api(`/dispatch/stops/for_job/${selectedJobId.value}/`)
        stops = Array.isArray(data) ? data : (data?.results || [])
      } catch { stops = j.stops || [] }
    }
    const points: { lat: number; lng: number }[] = []
    if (j.pickup_lat != null) points.push({ lat: j.pickup_lat, lng: j.pickup_lng })
    for (const s of stops) {
      if (s.latitude != null && s.longitude != null) points.push({ lat: s.latitude, lng: s.longitude })
    }
    if (j.dropoff_lat != null) points.push({ lat: j.dropoff_lat, lng: j.dropoff_lng })
    if (points.length < 2) return

    const origin = points[0]
    const destination = points[points.length - 1]
    const routeStops = points.slice(1, -1)

    const [traffic, weather] = await Promise.all([
      $api('/dispatch/traffic/', { method: 'POST', body: { origin, destination, stops: routeStops } }),
      $api('/dispatch/weather/', { method: 'POST', body: { points } }),
    ])
    trafficData.value = traffic
    weatherData.value = weather
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
}

watch(dialog, (open) => {
  if (open) {
    const newId = props.job?.id ?? null
    if (newId !== selectedJobId.value) {
      selectedJobId.value = newId // triggers watch(selectedJobId) → fetchData()
    } else {
      fetchData() // same job, watcher won't fire
    }
  } else {
    trafficData.value = null
    weatherData.value = null
  }
})

watch(selectedJobId, () => {
  if (dialog.value) fetchData()
})
</script>

<style scoped>
.weather-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 12px;
}
.weather-card {
  background: rgba(var(--v-theme-on-surface), 0.04);
  border: 1px solid rgba(var(--v-theme-on-surface), 0.12);
  border-radius: 12px;
  padding: 14px;
}
</style>
