<template>
  <div class="position-relative">
    <div ref="mapEl" class="live-fleet-map" />

    <!-- Loading overlay -->
    <div v-if="loading" class="map-overlay">
      <v-progress-circular indeterminate color="primary" size="32" width="3" />
    </div>

    <!-- No API key fallback -->
    <div v-if="noApiKey" class="map-fallback">
      <v-icon size="56" class="mb-3">mdi-map-marker-multiple-outline</v-icon>
      <p class="text-body-1 font-weight-medium mb-1">Live GPS Tracking</p>
      <p class="text-caption text-medium-emphasis">
        {{ vehicles.length }} vehicles broadcasting. Set a Google Maps API key to render the interactive map.
      </p>
    </div>

    <!-- Floating legend -->
    <div v-if="mapReady && !noApiKey" class="map-legend">
      <div class="d-flex align-center ga-2 mb-1">
        <span class="legend-dot" style="background: #10b981"></span>
        <span class="text-caption">Moving ({{ movingCount }})</span>
      </div>
      <div class="d-flex align-center ga-2 mb-1">
        <span class="legend-dot" style="background: #f59e0b"></span>
        <span class="text-caption">Idle ({{ idleCount }})</span>
      </div>
      <div class="d-flex align-center ga-2">
        <span class="legend-dot" style="background: #ef4444"></span>
        <span class="text-caption">Stale ({{ staleCount }})</span>
      </div>
    </div>

    <!-- Auto-refresh toggle -->
    <div class="map-controls">
      <v-switch
        v-model="autoRefresh"
        density="compact"
        color="primary"
        hide-details
        inset
        label="Auto-refresh"
        @update:model-value="$emit('toggle-auto', autoRefresh)"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  devices: any[]
}>()

const emit = defineEmits<{
  (e: 'select', device: any): void
  (e: 'toggle-auto', val: boolean): void
}>()

const config = useRuntimeConfig()
const apiKey = (config.public.googleMapsApiKey as string) || ''

const mapEl = ref<HTMLElement | null>(null)
const loading = ref(true)
const noApiKey = computed(() => !apiKey)
const mapReady = ref(false)
const autoRefresh = ref(true)

const { ensureGoogle } = useGoogleMaps()

const mapInstance = shallowRef<any>(null)
const markers = shallowRef<any[]>([])
const infoWindows = shallowRef<any[]>([])

const vehicles = computed(() => props.devices || [])
const movingCount = computed(() => vehicles.value.filter((d) => d.last_speed && d.last_speed > 0).length)
const idleCount = computed(() => vehicles.value.filter((d) => (!d.last_speed || d.last_speed === 0) && d.last_ignition_on).length)
const staleCount = computed(() => vehicles.value.filter((d) => d.is_stale).length)

const VEHICLE_COLORS: Record<string, string> = {
  moving: '#10b981',
  idle: '#f59e0b',
  stale: '#ef4444',
  offline: '#94a3b8',
}

function vehicleColor(d: any): string {
  if (d.is_stale) return VEHICLE_COLORS.stale
  if (d.last_speed && d.last_speed > 0) return VEHICLE_COLORS.moving
  return VEHICLE_COLORS.idle
}

function vehicleSvg(d: any): string {
  const c = vehicleColor(d)
  const speedLabel = d.last_speed ? Math.round(d.last_speed) : '—'
  return `<svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
    <circle cx="18" cy="18" r="16" fill="${c}" stroke="#fff" stroke-width="2" opacity="0.3"/>
    <circle cx="18" cy="18" r="11" fill="${c}" stroke="#fff" stroke-width="2"/>
    <text x="18" y="22" text-anchor="middle" font-size="10" font-family="Arial,sans-serif" font-weight="700" fill="#fff">${speedLabel}</text>
  </svg>`
}

const MAP_STYLES = [
  { featureType: 'all', elementType: 'labels.text.fill', stylers: [{ color: '#475569' }] },
  { featureType: 'administrative', elementType: 'geometry', stylers: [{ visibility: 'simplified' }] },
  { featureType: 'road', elementType: 'geometry', stylers: [{ color: '#e2e8f0' }] },
  { featureType: 'water', elementType: 'geometry', stylers: [{ color: '#dbeafe' }] },
  { featureType: 'landscape', elementType: 'geometry', stylers: [{ color: '#f8fafc' }] },
  { featureType: 'poi', elementType: 'labels', stylers: [{ visibility: 'simplified' }] },
]

async function initMap() {
  if (noApiKey.value) {
    loading.value = false
    return
  }

  let google: any
  try {
    google = await ensureGoogle()
  } catch {
    loading.value = false
    return
  }

  if (!mapEl.value) {
    loading.value = false
    return
  }

  const center = vehicles.value[0]?.last_latitude
    ? { lat: vehicles.value[0].last_latitude, lng: vehicles.value[0].last_longitude }
    : { lat: 39.5, lng: -98.35 }

  if (!mapInstance.value) {
    mapInstance.value = new google.maps.Map(mapEl.value, {
      center,
      zoom: 6,
      mapTypeControl: true,
      streetViewControl: false,
      fullscreenControl: true,
      gestureHandling: 'greedy',
      styles: MAP_STYLES,
    })
  }

  mapReady.value = true
  updateMarkers()
  loading.value = false
}

function updateMarkers() {
  if (!mapInstance.value) return

  // Clear old markers
  infoWindows.value.forEach((iw) => iw.close())
  markers.value.forEach((m) => m.setMap(null))
  markers.value = []
  infoWindows.value = []

  const google = (window as any).google
  const bounds = new google.maps.LatLngBounds()

  for (const d of vehicles.value) {
    if (d.last_latitude == null || d.last_longitude == null) continue

    const icon: any = {
      url: 'data:image/svg+xml;utf8,' + encodeURIComponent(vehicleSvg(d)),
      scaledSize: new google.maps.Size(36, 36),
      anchor: new google.maps.Point(18, 18),
    }

    const marker = new google.maps.Marker({
      position: { lat: d.last_latitude, lng: d.last_longitude },
      map: mapInstance.value,
      icon,
      title: d.vehicle_name || d.serial_number,
    })

    const speedText = d.last_speed ? `${Math.round(d.last_speed)} km/h` : 'Stationary'
    const staleText = d.is_stale ? '<span style="color:#ef4444;font-weight:600">Stale</span> · ' : ''
    const statusColor = d.is_stale ? '#ef4444' : d.last_speed && d.last_speed > 0 ? '#10b981' : '#f59e0b'
    const headingText = d.last_heading != null ? `${Math.round(d.last_heading)}°` : '—'

    const content = `
      <div style="min-width:200px;padding:4px;">
        <div style="font-weight:700;font-size:13px;margin-bottom:4px;">${d.vehicle_name || d.serial_number}</div>
        <div style="font-size:12px;color:#64748b;margin-bottom:2px;">${d.provider} · ${d.serial_number}</div>
        <div style="font-size:12px;margin-bottom:2px;">
          <span style="color:${statusColor};font-weight:600">${staleText}</span>
          ${speedText}
        </div>
        <div style="font-size:11px;color:#94a3b8;">Heading: ${headingText}</div>
        ${d.last_reported_at ? `<div style="font-size:11px;color:#94a3b8;">Reported: ${formatTime(d.last_reported_at)}</div>` : ''}
      </div>
    `

    const infoWindow = new google.maps.InfoWindow({ content })
    marker.addListener('click', () => {
      infoWindows.value.forEach((iw) => iw.close())
      infoWindow.open({ anchor: marker, map: mapInstance.value })
      emit('select', d)
    })

    markers.value.push(marker)
    infoWindows.value.push(infoWindow)
    bounds.extend({ lat: d.last_latitude, lng: d.last_longitude })
  }

  if (vehicles.value.length > 1) {
    mapInstance.value.fitBounds(bounds, 60)
  } else if (vehicles.value.length === 1) {
    mapInstance.value.setCenter({
      lat: vehicles.value[0].last_latitude,
      lng: vehicles.value[0].last_longitude,
    })
    mapInstance.value.setZoom(14)
  }
}

function formatTime(dt: string): string {
  try {
    return new Date(dt).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })
  } catch {
    return ''
  }
}

function refresh() {
  if (mapInstance.value) {
    updateMarkers()
  }
}

watch(() => props.devices, () => {
  if (mapReady.value) updateMarkers()
}, { deep: true })

onMounted(() => {
  initMap()
})

onUnmounted(() => {
  infoWindows.value.forEach((iw) => iw.close())
  markers.value.forEach((m) => m.setMap(null))
  mapInstance.value = null
})

defineExpose({ refresh, initMap })
</script>

<style scoped>
.live-fleet-map {
  width: 100%;
  height: 500px;
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

.map-legend {
  position: absolute;
  bottom: 12px;
  left: 12px;
  background: rgba(255, 255, 255, 0.95);
  border-radius: 8px;
  padding: 10px 14px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  z-index: 1;
}

.legend-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  display: inline-block;
}

.map-controls {
  position: absolute;
  top: 12px;
  right: 12px;
  background: rgba(255, 255, 255, 0.95);
  border-radius: 8px;
  padding: 4px 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  z-index: 1;
}
</style>
