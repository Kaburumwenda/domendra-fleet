<template>
  <v-card elevation="0" border rounded="lg" class="location-map-card overflow-hidden mt-4">
    <div class="d-flex flex-wrap align-center justify-space-between pa-4 ga-3">
      <div class="d-flex align-center ga-2">
        <div class="location-map-card__icon">
          <v-icon size="20" color="white">mdi-map-marker-multiple</v-icon>
        </div>
        <div>
          <h3 class="text-subtitle-1 font-weight-bold mb-0">Locations Map</h3>
          <p class="text-caption text-medium-emphasis mb-0">
            {{ plottedLocations.length }} of {{ locations.length }} locations mapped by address
          </p>
        </div>
      </div>
      <div class="d-flex align-center ga-2">
        <v-text-field
          v-model="search"
          prepend-inner-icon="mdi-magnify"
          placeholder="Search a location on the map..."
          density="compact"
          hide-details
          variant="outlined"
          style="min-width: 280px; max-width: 360px"
          @keyup.enter="findLocation"
        />
        <v-btn
          color="primary"
          variant="flat"
          size="small"
          prepend-icon="mdi-target"
          :disabled="!canFind"
          @click="findLocation"
        >Find</v-btn>
        <v-btn
          variant="text"
          size="small"
          prepend-icon="mdi-refresh"
          :loading="loading"
          @click="fitBounds"
        >Fit</v-btn>
      </div>
    </div>

    <div class="location-map-wrapper">
      <div ref="mapEl" class="location-map" />
      <div v-if="error" class="location-map-overlay">
        <v-icon size="40" class="mb-2">mdi-map-marker-off-outline</v-icon>
        <p class="text-body-2 mb-0">{{ error }}</p>
      </div>
      <div v-else-if="loading" class="location-map-overlay">
        <v-progress-circular indeterminate color="primary" size="32" width="3" class="mb-2" />
        <p class="text-caption text-medium-emphasis mb-0">Loading map…</p>
      </div>
      <div v-else-if="!plottedLocations.length" class="location-map-overlay">
        <v-icon size="40" class="mb-2">mdi-map-marker-question-outline</v-icon>
        <p class="text-body-2 font-weight-medium mb-1">No locations can be mapped yet.</p>
        <p class="text-caption text-medium-emphasis mb-0">
          Add an address (or pick a point on the map) to your locations so they can be plotted here.
        </p>
      </div>
    </div>

    <div v-if="selectedLocation" class="location-map-info">
      <div class="d-flex align-center ga-3">
        <div class="location-map-info__thumb" :style="{ background: selectedLocation.color || '#6366f1' }">
          <v-icon size="22" color="white">mdi-map-marker</v-icon>
        </div>
        <div class="flex-grow-1">
          <p class="text-body-2 font-weight-bold mb-0">{{ selectedLocation.name }}</p>
          <p class="text-caption text-medium-emphasis mb-0">
            {{ typeLabel(selectedLocation.type) }} · {{ selectedLocation.address || 'No address' }}
          </p>
        </div>
        <v-btn icon="mdi-close" variant="text" size="small" @click="selectedLocation = null" />
      </div>
    </div>
  </v-card>
</template>

<script setup lang="ts">
const gmaps = useGoogleMaps()

interface LocationMarker {
  location: any
  lat: number
  lng: number
  marker: any
  info: any
}

const mapEl = ref<HTMLElement | null>(null)
const search = ref('')
const loading = ref(true)
const error = ref('')
const mapInstance = ref<any>(null)
const markers = ref<LocationMarker[]>([])
const geocodeCache = ref<Map<string, { lat: number; lng: number } | null>>(new Map())
const selectedLocation = ref<any | null>(null)

const props = defineProps<{ locations: any[] }>()

const locationTypes = [
  { label: 'Depot / Yard', value: 'depot' },
  { label: 'Fuel Station', value: 'fuel_station' },
  { label: 'Charging Station', value: 'charging_station' },
  { label: 'Warehouse', value: 'warehouse' },
  { label: 'Customer Site', value: 'customer_site' },
  { label: 'Service Center', value: 'service_center' },
  { label: 'Parking Lot', value: 'parking_lot' },
  { label: 'Rest Stop', value: 'rest_stop' },
  { label: 'Border Crossing', value: 'border_crossing' },
  { label: 'Port / Terminal', value: 'port_terminal' },
  { label: 'Airport', value: 'airport' },
  { label: 'Rail Terminal', value: 'rail_terminal' },
  { label: 'Distribution Center', value: 'distribution_center' },
  { label: 'Drop-off Point', value: 'dropoff' },
  { label: 'Pick-up Point', value: 'pickup' },
  { label: 'Office', value: 'office' },
  { label: 'HQ', value: 'hq' },
  { label: 'Maintenance Bay', value: 'maintenance_bay' },
  { label: 'Toll Plaza', value: 'toll_plaza' },
  { label: 'Other', value: 'other' },
]

const plottedLocations = computed(() => markers.value.map(m => m.location))
const canFind = computed(() => !!search.value.trim())

function typeLabel(value: string) {
  return locationTypes.find((t) => t.value === value)?.label || value || 'Other'
}

onMounted(() => {
  initMap()
})

watch(() => props.locations, async () => {
  if (!mapInstance.value) return
  await placeMarkers()
  fitBounds()
})

onBeforeUnmount(() => {
  clearMarkers()
  mapInstance.value = null
})

async function initMap() {
  loading.value = true
  error.value = ''
  try {
    await gmaps.ensureGoogle()
    await nextTick()
    if (!mapEl.value) return

    const center = await defaultCenter()
    mapInstance.value = gmaps.createMap(mapEl.value, center, 3)
    await placeMarkers()
    fitBounds()
  } catch (e: any) {
    error.value = e?.message || 'Failed to load Google Maps.'
    console.error('[location-map] init error:', e)
  } finally {
    loading.value = false
  }
}

async function defaultCenter(): Promise<{ lat: number; lng: number }> {
  // Prefer the first plottable location, else a sensible default
  for (const l of props.locations || []) {
    const c = await resolveCoords(l)
    if (c) return c
  }
  return { lat: 0, lng: 0 }
}

async function resolveCoords(loc: any): Promise<{ lat: number; lng: number } | null> {
  if (loc.latitude != null && loc.longitude != null) {
    return { lat: Number(loc.latitude), lng: Number(loc.longitude) }
  }
  // Fall back to geocoding the address (or the name as a last resort)
  const query = (loc.address || loc.name || '').toString().trim()
  if (!query) return null
  const key = query.toLowerCase()
  if (geocodeCache.value.has(key)) return geocodeCache.value.get(key) || null
  try {
    const coords = await gmaps.geocodeAddress(query)
    geocodeCache.value.set(key, coords)
    return coords
  } catch {
    geocodeCache.value.set(key, null)
    return null
  }
}

async function placeMarkers() {
  if (!mapInstance.value) return
  const google = await gmaps.ensureGoogle()
  clearMarkers()

  // Cap live geocoding to protect Google quota (cached lookups don't count)
  const geocodedKeys = new Set(geocodeCache.value.keys())
  const maxGeocode = 30

  for (const l of props.locations || []) {
    const query = (l.address || l.name || '').toString().trim().toLowerCase()
    const hasCoords = l.latitude != null && l.longitude != null
    const willGeocode = !hasCoords && !geocodedKeys.has(query)
    if (willGeocode && geocodedKeys.size >= maxGeocode) continue

    const coords = await resolveCoords(l)
    if (!coords) continue
    if (willGeocode) geocodedKeys.add(query)

    const marker = createMarker(google, l, coords)
    const info = new google.maps.InfoWindow({ content: buildInfoHtml(l) })
    marker.addListener('click', () => {
      info.open({ anchor: marker, map: mapInstance.value })
      selectedLocation.value = l
    })
    markers.value.push({ location: l, lat: coords.lat, lng: coords.lng, marker, info })
  }
}

function createMarker(google: any, loc: any, coords: { lat: number; lng: number }): any {
  const color = (loc.color || '#6366f1').replace('#', '')
  return new google.maps.Marker({
    position: coords,
    map: mapInstance.value,
    title: loc.name,
    icon: {
      url: pinDataUrl(color),
      scaledSize: new google.maps.Size(36, 44),
      anchor: new google.maps.Point(18, 44),
    },
  })
}

function pinDataUrl(colorHex: string): string {
  // Colored pin with a white marker glyph
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="36" height="44" viewBox="0 0 36 44">
    <path d="M18 0C9.4 0 2.5 6.9 2.5 15.5C2.5 26 18 43 18 43S33.5 26 33.5 15.5C33.5 6.9 26.6 0 18 0z" fill="#${colorHex}" stroke="#ffffff" stroke-width="2"/>
    <circle cx="18" cy="15.5" r="6" fill="#ffffff"/>
  </svg>`
  return 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(svg)
}

function buildInfoHtml(l: any): string {
  return `<div style="min-width:200px;max-width:260px">
    <div style="font-weight:600;font-size:14px;color:#0f172a;margin-bottom:2px">${escapeHtml(l.name || '')}</div>
    <div style="font-size:12px;color:#64748b;margin-bottom:4px">${escapeHtml(typeLabel(l.type))}</div>
    <div style="font-size:12px;color:#64748b">${escapeHtml(l.address || 'No address')}</div>
  </div>`
}

function escapeHtml(s: string): string {
  return String(s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c] || c))
}

function clearMarkers() {
  for (const m of markers.value) {
    try { m.marker.setMap(null) } catch {}
    try { m.info.close() } catch {}
  }
  markers.value = []
}

function fitBounds() {
  if (!mapInstance.value || !markers.value.length) return
  const google = _stateGoogle()
  if (!google) return
  const bounds = new google.maps.LatLngBounds()
  for (const m of markers.value) bounds.extend({ lat: m.lat, lng: m.lng })
  mapInstance.value.fitBounds(bounds, 40)
}

function _stateGoogle(): any {
  return (gmaps as any)?.state?.google || (window as any).google
}

async function findLocation() {
  const q = search.value.trim().toLowerCase()
  if (!q) return
  const match = markers.value.find(m => {
    const l = m.location
    return [l.name, l.address, l.type]
      .filter(Boolean)
      .some(s => String(s).toLowerCase().includes(q))
  })
  if (!match) {
    error.value = `No location found for "${search.value}".`
    setTimeout(() => { if (error.value) error.value = '' }, 3000)
    return
  }
  selectedLocation.value = match.location
  mapInstance.value?.panTo({ lat: match.lat, lng: match.lng })
  mapInstance.value?.setZoom(13)
  const g = _stateGoogle()
  try { g.maps.event.trigger(match.marker, 'click') } catch {}
}
</script>

<style scoped>
.location-map-card {
  border-color: #e2e8f0 !important;
}
.location-map-card__icon {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  background: linear-gradient(135deg, #0ea5e9, #2563eb);
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 4px 12px rgba(14, 165, 233, 0.3);
  flex-shrink: 0;
}
.location-map-wrapper {
  position: relative;
  height: 440px;
  background: #f1f5f9;
}
.location-map {
  width: 100%;
  height: 100%;
  min-height: 440px;
}
.location-map-overlay {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  color: #64748b;
  background: rgb(255 255 255 / 80%);
  padding: 24px;
}
.location-map-info {
  border-top: 1px solid #e2e8f0;
  padding: 12px 16px;
  background: #f8fafc;
}
.location-map-info__thumb {
  width: 48px;
  height: 48px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  box-shadow: 0 2px 6px rgba(15, 23, 42, 0.12);
}
</style>
