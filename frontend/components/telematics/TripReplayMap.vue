<template>
  <div class="position-relative">
    <div ref="mapEl" class="trip-replay-map" />

    <div v-if="loading" class="map-overlay">
      <v-progress-circular indeterminate color="primary" size="32" width="3" />
    </div>

    <div v-if="noApiKey" class="map-fallback">
      <v-icon size="48" class="mb-2">mdi-map-marker-path</v-icon>
      <p class="text-caption text-medium-emphasis">Set a Google Maps API key to render trip replay.</p>
    </div>

    <!-- Replay controls -->
    <div v-if="mapReady && path.length > 0" class="replay-controls">
      <div class="d-flex align-center ga-2">
        <v-btn
          icon
          size="x-small"
          variant="flat"
          :color="replayPlaying ? 'error' : 'primary'"
          @click="togglePlayback"
        >
          <v-icon>{{ replayPlaying ? 'mdi-pause' : 'mdi-play' }}</v-icon>
        </v-btn>
        <v-btn icon="mdi-skip-backward" size="x-small" variant="text" @click="resetReplay" />
        <div class="flex-grow-1">
          <v-slider
            v-model="replayProgress"
            :max="100"
            :step="0.5"
            color="primary"
            density="compact"
            hide-details
            @update:model-value="onProgress"
          />
        </div>
        <span class="text-caption text-medium-emphasis" style="min-width: 70px; text-align: right;">
          {{ currentPointIdx }} / {{ path.length }}
        </span>
      </div>
    </div>

    <!-- Trip stats overlay -->
    <div v-if="mapReady && trip && path.length > 0" class="trip-info">
      <div class="d-flex ga-4">
        <div>
          <p class="text-caption text-medium-emphasis">Distance</p>
          <p class="text-body-2 font-weight-bold">{{ trip.distance ? trip.distance.toFixed(1) : '—' }} km</p>
        </div>
        <div>
          <p class="text-caption text-medium-emphasis">Duration</p>
          <p class="text-body-2 font-weight-bold">{{ trip.duration_minutes ? Math.round(trip.duration_minutes) + 'm' : '—' }}</p>
        </div>
        <div>
          <p class="text-caption text-medium-emphasis">Max Speed</p>
          <p class="text-body-2 font-weight-bold">{{ trip.max_speed ? Math.round(trip.max_speed) : '—' }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  trip: any
  pathData: any[]
}>()

const config = useRuntimeConfig()
const apiKey = (config.public.googleMapsApiKey as string) || ''

const mapEl = ref<HTMLElement | null>(null)
const loading = ref(false)
const noApiKey = computed(() => !apiKey)
const mapReady = ref(false)

const { ensureGoogle } = useGoogleMaps()

const mapInstance = shallowRef<any>(null)
const polyline = shallowRef<any>(null)
const replayMarker = shallowRef<any>(null)
const startMarker = shallowRef<any>(null)
const endMarker = shallowRef<any>(null)
const infoWindow = shallowRef<any>(null)

const replayProgress = ref(0)
const currentPointIdx = ref(0)
const replayPlaying = ref(false)
let replayTimer: any = null

const path = computed(() => props.pathData || [])

const MAP_STYLES = [
  { featureType: 'all', elementType: 'labels.text.fill', stylers: [{ color: '#475569' }] },
  { featureType: 'road', elementType: 'geometry', stylers: [{ color: '#e2e8f0' }] },
  { featureType: 'water', elementType: 'geometry', stylers: [{ color: '#dbeafe' }] },
  { featureType: 'landscape', elementType: 'geometry', stylers: [{ color: '#f8fafc' }] },
]

async function initMap() {
  if (noApiKey.value) return

  let google: any
  try {
    google = await ensureGoogle()
  } catch { return }

  if (!mapEl.value) return

  const pts = path.value.map((p: any) => ({ lat: p.latitude, lng: p.longitude }))
  const center = pts[0] || { lat: 39.5, lng: -98.35 }

  mapInstance.value = new google.maps.Map(mapEl.value, {
    center,
    zoom: 13,
    mapTypeControl: true,
    streetViewControl: false,
    fullscreenControl: true,
    gestureHandling: 'greedy',
    styles: MAP_STYLES,
  })

  mapReady.value = true
  drawRoute()
  loading.value = false
}

function drawRoute() {
  if (!mapInstance.value || path.value.length === 0) return
  const google = (window as any).google
  const pts = path.value.map((p: any) => ({ lat: p.latitude, lng: p.longitude }))

  if (pts.length < 2) return

  // Polyline
  if (polyline.value) polyline.value.setMap(null)
  polyline.value = new google.maps.Polyline({
    path: pts,
    geodesic: true,
    strokeColor: '#6366f1',
    strokeOpacity: 0.85,
    strokeWeight: 4,
    map: mapInstance.value,
  })

  // Start marker (green)
  if (startMarker.value) startMarker.value.setMap(null)
  startMarker.value = new google.maps.Marker({
    position: pts[0],
    map: mapInstance.value,
    icon: {
      url: 'data:image/svg+xml;utf8,' + encodeURIComponent(
        '<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32"><circle cx="16" cy="16" r="14" fill="#10b981" stroke="#fff" stroke-width="2"/><text x="16" y="20" text-anchor="middle" font-size="12" fill="#fff" font-weight="700">S</text></svg>'
      ),
      scaledSize: new google.maps.Size(32, 32),
      anchor: new google.maps.Point(16, 16),
    },
    title: 'Start',
  })

  // End marker (red)
  if (endMarker.value) endMarker.value.setMap(null)
  endMarker.value = new google.maps.Marker({
    position: pts[pts.length - 1],
    map: mapInstance.value,
    icon: {
      url: 'data:image/svg+xml;utf8,' + encodeURIComponent(
        '<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32"><circle cx="16" cy="16" r="14" fill="#ef4444" stroke="#fff" stroke-width="2"/><text x="16" y="20" text-anchor="middle" font-size="12" fill="#fff" font-weight="700">E</text></svg>'
      ),
      scaledSize: new google.maps.Size(32, 32),
      anchor: new google.maps.Point(16, 16),
    },
    title: 'End',
  })

  // Replay marker
  if (replayMarker.value) replayMarker.value.setMap(null)
  replayMarker.value = new google.maps.Marker({
    position: pts[0],
    map: mapInstance.value,
    icon: {
      url: 'data:image/svg+xml;utf8,' + encodeURIComponent(
        '<svg xmlns="http://www.w3.org/2000/svg" width="36" height="36"><circle cx="18" cy="18" r="16" fill="#6366f1" stroke="#fff" stroke-width="2" opacity="0.3"/><circle cx="18" cy="18" r="11" fill="#6366f1" stroke="#fff" stroke-width="2"/></svg>'
      ),
      scaledSize: new google.maps.Size(36, 36),
      anchor: new google.maps.Point(18, 18),
    },
    zIndex: 999,
    title: 'Replay position',
  })

  // Fit bounds
  const bounds = new google.maps.LatLngBounds()
  for (const pt of pts) bounds.extend(pt)
  mapInstance.value.fitBounds(bounds, 60)
}

function togglePlayback() {
  if (replayPlaying.value) {
    pausePlayback()
  } else {
    playPlayback()
  }
}

function playPlayback() {
  if (path.value.length < 2) return
  replayPlaying.value = true
  replayTimer = setInterval(() => {
    if (currentPointIdx.value >= path.value.length - 1) {
      pausePlayback()
      return
    }
    currentPointIdx.value++
    updateReplayMarker()
    replayProgress.value = (currentPointIdx.value / (path.value.length - 1)) * 100
  }, 500)
}

function pausePlayback() {
  replayPlaying.value = false
  if (replayTimer) {
    clearInterval(replayTimer)
    replayTimer = null
  }
}

function resetReplay() {
  pausePlayback()
  currentPointIdx.value = 0
  replayProgress.value = 0
  updateReplayMarker()
}

function updateReplayMarker() {
  if (!replayMarker.value || path.value.length === 0) return
  const pt = path.value[currentPointIdx.value]
  if (pt) {
    replayMarker.value.setPosition({ lat: pt.latitude, lng: pt.longitude })
  }
}

function onProgress(val: number) {
  if (path.value.length < 2) return
  const idx = Math.round((val / 100) * (path.value.length - 1))
  currentPointIdx.value = idx
  updateReplayMarker()
}

watch(() => props.pathData, () => {
  if (mapReady.value) {
    drawRoute()
    resetReplay()
  }
}, { deep: true })

watch(() => props.trip, () => {
  if (!mapInstance.value) initMap()
  else if (mapReady.value) drawRoute()
})

onMounted(() => {
  if (path.value.length > 0) {
    initMap()
  } else {
    loading.value = false
  }
})

onUnmounted(() => {
  pausePlayback()
  if (polyline.value) polyline.value.setMap(null)
  if (replayMarker.value) replayMarker.value.setMap(null)
  if (startMarker.value) startMarker.value.setMap(null)
  if (endMarker.value) endMarker.value.setMap(null)
  mapInstance.value = null
})

defineExpose({ initMap })
</script>

<style scoped>
.trip-replay-map {
  width: 100%;
  height: 400px;
  border-radius: 12px;
  overflow: hidden;
  background: #f1f5f9;
  position: relative;
  z-index: 0;
}

.position-relative {
  position: relative;
}

.map-overlay {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(241, 245, 249, 0.7);
  z-index: 1;
}

.map-fallback {
  position: absolute;
  top: 50%; left: 50%;
  transform: translate(-50%, -50%);
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  z-index: 1;
}

.replay-controls {
  position: absolute;
  bottom: 12px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(255, 255, 255, 0.95);
  border-radius: 10px;
  padding: 8px 16px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.12);
  z-index: 1;
  min-width: 380px;
}

.trip-info {
  position: absolute;
  top: 12px;
  left: 12px;
  background: rgba(255, 255, 255, 0.95);
  border-radius: 10px;
  padding: 10px 16px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.12);
  z-index: 1;
}
</style>
