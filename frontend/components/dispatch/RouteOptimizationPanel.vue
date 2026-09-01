<template>
  <v-dialog v-model="dialog" max-width="900" scrollable>
    <v-card rounded="xl" class="pa-0">
      <!-- Header -->
      <v-card-title class="d-flex align-center ga-2 pa-5 border-b" style="gap: 12px">
        <v-avatar color="primary" size="40" rounded="lg">
          <v-icon>mdi-map-marker-path</v-icon>
        </v-avatar>
        <div class="flex-grow-1">
          <h3 class="text-h6 font-weight-bold">Route Optimization</h3>
          <p class="text-caption text-medium-emphasis">Select a job to optimize stop ordering via Google Directions</p>
        </div>
        <v-spacer />
        <v-btn icon variant="text" size="small" @click="dialog = false"><v-icon>mdi-close</v-icon></v-btn>
      </v-card-title>

      <!-- Job selector + Optimize bar -->
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
        <v-btn color="primary" variant="tonal" prepend-icon="mdi-routes" :loading="loading" :disabled="loading || !selectedJobId" @click="runOptimization">
          Optimize
        </v-btn>
      </div>

      <!-- Options bar -->
      <div class="d-flex flex-wrap align-center ga-3 pa-4 border-b">
        <v-switch v-model="avoidTolls" label="Avoid Tolls" density="compact" hide-details color="primary" inset />
        <v-switch v-model="avoidHighways" label="Avoid Highways" density="compact" hide-details color="primary" inset />
        <v-select
          v-model="travelMode"
          :items="travelModes"
          density="compact"
          hide-details
          variant="outlined"
          style="max-width: 160px"
          label="Travel Mode"
        />
        <v-spacer />
        <v-chip v-if="result" size="small" variant="tonal" color="success" prepend-icon="mdi-check-decagram">
          Optimized
        </v-chip>
      </div>

      <!-- Map -->
      <div ref="mapEl" class="route-opt-map" />

      <!-- Results -->
      <v-card-text class="pa-5">
        <div v-if="loading" class="d-flex justify-center align-center py-12">
          <v-progress-circular indeterminate color="primary" size="48" />
          <p class="text-caption text-medium-emphasis ml-4">Optimizing route with Google Maps…</p>
        </div>

        <div v-else-if="!result" class="text-center py-12 text-medium-emphasis">
          <v-icon size="56" class="mb-3">mdi-routes</v-icon>
          <p>Click <b>Optimize Route</b> to compute the most efficient stop order.</p>
        </div>

        <template v-else>
          <!-- KPI cards -->
          <div class="d-flex flex-wrap ga-3 mb-5">
            <StatCard label="Total Distance" :value="`${result.total_distance_km} km`" icon="mdi-map-marker-distance" icon-color="info" />
            <StatCard label="Drive Time" :value="result.total_duration_text" icon="mdi-clock-outline" icon-color="primary" />
            <StatCard label="Stops" :value="currentStops.length" icon="mdi-map-marker-multiple" icon-color="warning" />
            <StatCard label="Steps" :value="result.steps.length" icon="mdi-directions" icon-color="success" />
          </div>

          <!-- Optimized order -->
          <h4 class="text-subtitle-2 font-weight-bold mb-3">
            <v-icon size="18" color="primary" class="mr-1">mdi-sort-ascending</v-icon>
            Optimized Stop Sequence
          </h4>
          <v-timeline density="compact" side="end" class="mb-4">
            <v-timeline-item dot-color="success" size="x-small" icon="mdi-play">
              <div class="text-body-2 font-weight-medium">Origin: {{ activeJob?.pickup_address || 'Start' }}</div>
            </v-timeline-item>
            <v-timeline-item
              v-for="(s, i) in optimizedStopsList"
              :key="i"
              :dot-color="stopColor(i)"
              size="x-small"
            >
              <div class="d-flex align-center ga-2">
                <v-avatar size="24" :color="stopColor(i)" variant="tonal" class="text-body-2 font-weight-bold">{{ i + 1 }}</v-avatar>
                <span class="text-body-2">{{ s.address || `(${Number(s.latitude).toFixed(4)}, ${Number(s.longitude).toFixed(4)})` }}</span>
              </div>
            </v-timeline-item>
            <v-timeline-item dot-color="error" size="x-small" icon="mdi-flag-checkered">
              <div class="text-body-2 font-weight-medium">Destination: {{ activeJob?.dropoff_address || 'End' }}</div>
            </v-timeline-item>
          </v-timeline>

          <!-- Turn-by-turn directions -->
          <h4 class="text-subtitle-2 font-weight-bold mb-3 mt-4">
            <v-icon size="18" color="primary" class="mr-1">mdi-directions</v-icon>
            Turn-by-Turn Directions
          </h4>
          <v-list density="compact" class="route-steps-list" lines="one">
            <v-list-item v-for="(step, i) in result.steps" :key="i">
              <template #prepend>
                <v-avatar size="28" color="primary" variant="tonal" class="text-body-2">{{ i + 1 }}</v-avatar>
              </template>
              <v-list-item-title class="text-body-2">{{ step.instruction }}</v-list-item-title>
              <v-list-item-subtitle class="text-caption d-flex align-center ga-1 mt-1">
                <v-chip size="x-small" variant="flat" color="info">{{ step.distance }}</v-chip>
                <v-chip size="x-small" variant="tonal" color="primary">{{ step.duration }}</v-chip>
              </v-list-item-subtitle>
            </v-list-item>
          </v-list>

          <!-- Action bar -->
          <div class="d-flex ga-3 mt-5 flex-wrap">
            <v-btn variant="outlined" prepend-icon="mdi-swap-vertical" @click="applyOptimizedOrder">
              Apply Optimized Order
            </v-btn>
            <v-btn variant="outlined" prepend-icon="mdi-printer" @click="printDirections">
              Print Directions
            </v-btn>
          </div>
        </template>
      </v-card-text>

      <!-- Footer -->
      <v-card-actions class="pa-4 border-t">
        <v-spacer />
        <v-btn variant="text" @click="dialog = false">Close</v-btn>
        <v-btn color="primary" prepend-icon="mdi-routes" :loading="loading" :disabled="loading || currentStops.length === 0" @click="runOptimization">
          Optimize Route
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
  'apply-order': [order: number[]]
  'job-change': [jobId: number]
}>()

const { $api, $swal } = useNuxtApp() as any
const { ensureGoogle } = useGoogleMaps()

const dialog = computed({
  get: () => props.modelValue,
  set: (v) => emit('update:modelValue', v),
})

const selectedJobId = ref<number | null>(null)
const currentStops = ref<any[]>([])

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

const activeJob = computed(() =>
  selectedJobId.value
    ? geocodedJobs.value.find(g => g.id === selectedJobId.value) || props.job
    : props.job
)

const loading = ref(false)
const result = ref<any>(null)
const mapEl = ref<HTMLElement | null>(null)
const avoidTolls = ref(false)
const avoidHighways = ref(false)
const travelMode = ref('DRIVING')
const travelModes = [
  { title: 'Driving', value: 'DRIVING' },
  { title: 'Walking', value: 'WALKING' },
  { title: 'Bicycling', value: 'BICYCLING' },
]

const optimizedStopsList = computed(() => {
  if (!result.value?.optimized_order) return currentStops.value
  return result.value.optimized_order.map((i: number) => currentStops.value[i]).filter(Boolean)
})

function stopColor(i: number) {
  const colors = ['info', 'primary', 'indigo', 'purple']
  return colors[i % 4]
}

let map: any = null
let polylineRef: any = null
let stopMarkers: any[] = []

async function loadStopsForJob(jobId: number) {
  if (props.job?.id === jobId) {
    currentStops.value = props.stops
    return
  }
  const j = geocodedJobs.value.find(g => g.id === jobId)
  try {
    const data = await $api(`/dispatch/stops/for_job/${jobId}/`)
    currentStops.value = Array.isArray(data) ? data : (data?.results || [])
  } catch {
    currentStops.value = j?.stops || []
  }
}

async function runOptimization() {
  const j = activeJob.value
  if (!j) return
  if (j.pickup_lat == null || j.dropoff_lat == null) {
    $swal?.fire?.({ icon: 'warning', title: 'Pickup and dropoff need geocoding', toast: true, timer: 2500, position: 'top-end' })
    return
  }
  // Make sure stops are loaded for this job
  if (selectedJobId.value && props.job?.id !== selectedJobId.value) {
    await loadStopsForJob(selectedJobId.value)
  } else {
    currentStops.value = props.stops
  }
  const stops = currentStops.value
  if (!stops.length) {
    $swal?.fire?.({ icon: 'info', title: 'No stops for this job', toast: true, timer: 2500, position: 'top-end' })
    return
  }
  loading.value = true
  result.value = null
  try {
    const body = {
      origin: { lat: j.pickup_lat, lng: j.pickup_lng },
      destination: { lat: j.dropoff_lat, lng: j.dropoff_lng },
      stops: stops
        .filter(s => s.latitude != null && s.longitude != null)
        .map(s => ({ lat: s.latitude, lng: s.longitude })),
      travel_mode: travelMode.value,
      avoid_tolls: avoidTolls.value,
      avoid_highways: avoidHighways.value,
      departure_time: 'now',
    }
    const data = await $api('/dispatch/route/optimize/', { method: 'POST', body })
    result.value = data
    await nextTick()
    setTimeout(() => drawRouteMap(), 100)
    $swal?.fire?.({ icon: 'success', title: 'Route optimized', toast: true, timer: 1500, position: 'top-end' })
  } catch (e: any) {
    console.error(e)
    $swal?.fire?.({ icon: 'error', title: e?.data?.error || 'Optimization failed', toast: true, timer: 3000, position: 'top-end' })
  } finally {
    loading.value = false
  }
}

function makeIcon(google: any, color: string, text: string) {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="34" height="44" viewBox="0 0 24 32">
    <path fill="${color}" stroke="#fff" stroke-width="1.5" d="M12 0C5.4 0 0 5.4 0 12c0 9 12 20 12 20s12-11 12-20C24 5.4 18.6 0 12 0z"/>
    <circle cx="12" cy="12" r="8" fill="#fff"/>
    <text x="12" y="16" text-anchor="middle" font-size="10" font-family="Arial" font-weight="700" fill="${color}">${text}</text>
  </svg>`
  return {
    url: 'data:image/svg+xml;utf8,' + encodeURIComponent(svg),
    scaledSize: new google.maps.Size(34, 44),
    anchor: new google.maps.Point(17, 44),
  }
}

async function drawRouteMap() {
  if (!mapEl.value || !result.value?.polyline) return
  const google = await ensureGoogle()

  const j = activeJob.value
  if (!j) return
  if (!map) {
    map = new google.maps.Map(mapEl.value, {
      center: { lat: j.pickup_lat, lng: j.pickup_lng },
      zoom: 6,
      mapTypeControl: false,
      streetViewControl: false,
      fullscreenControl: true,
      gestureHandling: 'greedy',
    })
  }

  // Clear previous overlays
  if (polylineRef) { polylineRef.setMap(null); polylineRef = null }
  stopMarkers.forEach(m => m.setMap(null))
  stopMarkers = []

  // Decode and draw the overview polyline
  try {
    const path = google.maps.geometry.encoding.decodePath(result.value.polyline)
    polylineRef = new google.maps.Polyline({
      path,
      strokeColor: '#6366f1',
      strokeWeight: 6,
      strokeOpacity: 0.85,
      map,
    })
    const b = new google.maps.LatLngBounds()
    path.forEach((pt: any) => b.extend(pt))
    map.fitBounds(b, 60)
  } catch {
    if (result.value.bounds) {
      const b = new google.maps.LatLngBounds(
        new google.maps.LatLng(result.value.bounds.southwest.lat, result.value.bounds.southwest.lng),
        new google.maps.LatLng(result.value.bounds.northeast.lat, result.value.bounds.northeast.lng),
      )
      map.fitBounds(b, 60)
    }
  }

  // Origin marker
  stopMarkers.push(new google.maps.Marker({
    position: { lat: j.pickup_lat, lng: j.pickup_lng },
    map,
    icon: makeIcon(google, '#10b981', 'S'),
    title: 'Origin',
  }))

  // Optimized stop markers
  optimizedStopsList.value.forEach((s, i) => {
    stopMarkers.push(new google.maps.Marker({
      position: { lat: s.latitude, lng: s.longitude },
      map,
      icon: makeIcon(google, '#3b82f6', String(i + 1)),
      title: s.address || `Stop ${i + 1}`,
    }))
  })

  // Destination marker
  stopMarkers.push(new google.maps.Marker({
    position: { lat: j.dropoff_lat, lng: j.dropoff_lng },
    map,
    icon: makeIcon(google, '#ef4444', 'E'),
    title: 'Destination',
  }))
}

function applyOptimizedOrder() {
  if (!result.value?.optimized_order) {
    $swal?.fire?.({ icon: 'info', title: 'Nothing to apply', toast: true, timer: 1500, position: 'top-end' })
    return
  }
  emit('apply-order', [...result.value.optimized_order])
  $swal?.fire?.({ icon: 'success', title: 'Optimized order applied to stops', toast: true, timer: 1500, position: 'top-end' })
}

function printDirections() {
  if (!result.value) return
  const win = window.open('', '_blank', 'width=600,height=800')
  if (!win) return
  const stepsHtml = result.value.steps.map((s: any, i: number) =>
    `<tr><td>${i + 1}</td><td>${s.instruction}</td><td>${s.distance}</td><td>${s.duration}</td></tr>`
  ).join('')
  const j = activeJob.value
  win.document.write(`<html><head><title>Directions - ${j?.title || ''}</title>
    <style>body{font-family:Arial,sans-serif;padding:24px;color:#1e293b}
    h1{font-size:20px} table{width:100%;border-collapse:collapse;margin-top:16px}
    th,td{text-align:left;padding:8px 12px;border-bottom:1px solid #e2e8f0;font-size:14px}
    th{background:#f1f5f9;font-weight:700}.summary{display:flex;gap:24px;margin-top:12px}
    .summary div{background:#f8fafc;padding:12px 16px;border-radius:8px}</style></head><body>
    <h1>Route Directions — ${j?.title || ''}</h1>
    <div class="summary"><div><b>Total Distance:</b> ${result.value.total_distance_km} km</div>
    <div><b>Total Duration:</b> ${result.value.total_duration_text}</div>
    <div><b>Stops:</b> ${result.value.legs.length - 1}</div></div>
    <table><thead><tr><th>#</th><th>Instruction</th><th>Distance</th><th>Duration</th></tr></thead>
    <tbody>${stepsHtml}</tbody></table></body></html>`)
  win.document.close()
  win.print()
}

watch(dialog, (open) => {
  if (!open) {
    result.value = null
    if (polylineRef) { polylineRef.setMap(null); polylineRef = null }
    stopMarkers.forEach(m => m.setMap(null))
    stopMarkers = []
    map = null
  } else {
    selectedJobId.value = props.job?.id ?? null
    currentStops.value = props.stops
  }
})

watch(selectedJobId, (newId, oldId) => {
  if (!dialog.value || newId === oldId) return
  // Reset results and load stops for the new job
  result.value = null
  if (polylineRef) { polylineRef.setMap(null); polylineRef = null }
  stopMarkers.forEach(m => m.setMap(null))
  stopMarkers = []
  if (newId && props.job?.id !== newId) {
    loadStopsForJob(newId)
  } else if (newId === props.job?.id) {
    currentStops.value = props.stops
  }
})
</script>

<style scoped>
.route-opt-map { width: 100%; height: 300px; min-height: 260px; background: rgb(var(--v-theme-surface-variant)); }
.route-steps-list { max-height: 300px; overflow-y: auto; }
</style>
