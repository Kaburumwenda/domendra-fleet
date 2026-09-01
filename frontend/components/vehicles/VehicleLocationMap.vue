<template>
  <v-card elevation="0" border rounded="lg" class="vehicle-map-card overflow-hidden">
    <div class="d-flex flex-wrap align-center justify-space-between pa-4 ga-3">
      <div class="d-flex align-center ga-2">
        <div class="vehicle-map-card__icon">
          <v-icon size="20" color="white">mdi-map-marker-multiple</v-icon>
        </div>
        <div>
          <h3 class="text-subtitle-1 font-weight-bold mb-0">Fleet Locations</h3>
          <p class="text-caption text-medium-emphasis mb-0">
            {{ locatedVehicles.length }} of {{ vehicles.length }} vehicles mapped
          </p>
        </div>
      </div>
      <div class="d-flex align-center ga-2">
        <v-text-field
          v-model="search"
          prepend-inner-icon="mdi-magnify"
          placeholder="Search a vehicle on the map..."
          density="compact"
          hide-details
          variant="outlined"
          style="min-width: 280px; max-width: 360px"
          @keyup.enter="findVehicle"
        />
        <v-btn
          color="primary"
          variant="flat"
          size="small"
          prepend-icon="mdi-target"
          :disabled="!canFind"
          @click="findVehicle"
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

    <div class="vehicle-map-wrapper">
      <div ref="mapEl" class="vehicle-map" />
      <div v-if="error" class="vehicle-map-overlay">
        <v-icon size="40" class="mb-2"> mdi-map-marker-off-outline </v-icon>
        <p class="text-body-2 mb-0">{{ error }}</p>
      </div>
      <div v-else-if="loading" class="vehicle-map-overlay">
        <v-progress-circular indeterminate color="primary" size="32" width="3" class="mb-2" />
        <p class="text-caption text-medium-emphasis mb-0">Loading map…</p>
      </div>
      <div v-else-if="!locatedVehicles.length" class="vehicle-map-overlay">
        <v-icon size="40" class="mb-2"> mdi-map-marker-question-outline </v-icon>
        <p class="text-body-2 font-weight-medium mb-1">No vehicles have mapped locations yet.</p>
        <p class="text-caption text-medium-emphasis mb-0">
          Open the <strong>Locations</strong> tab above and add latitude/longitude (or pick an address on the map)
          for each location — vehicles are mapped using the location name set on each vehicle.
        </p>
      </div>
    </div>

    <div v-if="selectedVehicle" class="vehicle-map-info">
      <div class="d-flex align-center ga-3">
        <div class="vehicle-map-info__thumb" :style="thumbStyle">
          <img v-if="selectedImageUrl" :src="selectedImageUrl" alt="Vehicle" />
          <v-icon v-else size="22" color="white">mdi-car</v-icon>
        </div>
        <div class="flex-grow-1">
          <p class="text-body-2 font-weight-bold mb-0">{{ selectedVehicle.display_name }}</p>
          <p class="text-caption text-medium-emphasis mb-0">
            {{ selectedVehicle.license_plate || selectedVehicle.vin }} ·
            {{ selectedVehicle.location || 'Unknown location' }}
          </p>
        </div>
        <v-btn icon="mdi-close" variant="text" size="small" @click="selectedVehicle = null" />
      </div>
    </div>
  </v-card>
</template>

<script setup lang="ts">
const { $api } = useNuxtApp()
const gmaps = useGoogleMaps()

interface VehicleMarker {
  vehicle: any
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
const markers = ref<VehicleMarker[]>([])
const locationCoordMap = ref<Map<string, { lat: number; lng: number; address?: string }>>(new Map())
const geocodeCache = ref<Map<string, { lat: number; lng: number } | null>>(new Map())
const selectedVehicle = ref<any | null>(null)

const apiBase = (useRuntimeConfig().public.apiBase || '').replace(/\/api\/?$/, '')

const { data: vehiclesData, pending: vehiclesPending } = await useAsyncData('vehicle-map-vehicles', () =>
  $api('/vehicles/vehicles/').catch(() => ({ results: [], count: 0 })),
)
const vehicles = computed<any[]>(() => vehiclesData.value?.results || vehiclesData.value || [])

const { data: locationsData, pending: locationsPending } = await useAsyncData('vehicle-map-locations', () =>
  $api('/locations/').catch(() => ({ results: [], count: 0 })),
)
const locations = computed<any[]>(() => locationsData.value?.results || locationsData.value || [])

const locatedVehicles = computed(() => markers.value.map(m => m.vehicle))

const canFind = computed(() => !!search.value.trim())

const selectedImageUrl = computed(() => resolveImageUrl(selectedVehicle.value?.image))
const thumbStyle = computed(() => selectedImageUrl.value
  ? { background: 'transparent' }
  : { background: 'linear-gradient(135deg,#6366f1,#4f46e5)' })

function resolveImageUrl(url?: string): string {
  if (!url) return ''
  if (/^https?:\/\//i.test(url)) return url
  return `${apiBase}/${url.replace(/^\/+/, '')}`
}

onMounted(() => {
  initMap()
})

// Re-place markers when underlying data changes after first init
watch([vehicles, locations], async () => {
  if (!mapInstance.value) return
  buildLocationCoordMap()
  await placeMarkers()
  fitBounds()
}, { deep: false })

onBeforeUnmount(() => {
  clearMarkers()
  mapInstance.value = null
})

async function initMap() {
  loading.value = true
  error.value = ''
  try {
    // Wait until both lists have loaded so markers can be placed accurately
    await untilResolved(vehiclesPending, locationsPending)
    await gmaps.ensureGoogle()
    await nextTick()
    if (!mapEl.value) return

    // Build a lookup of location name -> coords from the Locations API
    buildLocationCoordMap()

    const center = await defaultCenter()
    mapInstance.value = gmaps.createMap(mapEl.value, center, 3)
    await placeMarkers()
    fitBounds()
  } catch (e: any) {
    error.value = e?.message || 'Failed to load Google Maps.'
    console.error('[vehicle-map] init error:', e)
  } finally {
    loading.value = false
  }
}

function untilResolved(...pending: Ref<boolean>[]): Promise<void> {
  return new Promise((resolve) => {
    const allDone = () => pending.every(p => !p.value)
    if (allDone()) return resolve()
    const stop = watch(() => pending.map(p => p.value).join(','), () => {
      if (allDone()) { stop(); resolve() }
    })
  })
}

function buildLocationCoordMap() {
  const map = new Map<string, { lat: number; lng: number; address?: string }>()
  const locs = locations.value || []
  for (const l of locs) {
    const name = String(l.name || '').trim()
    if (!name) continue
    if (l.latitude != null && l.longitude != null) {
      map.set(name.toLowerCase(), { lat: l.latitude, lng: l.longitude, address: l.address })
    } else {
      // No coordinates yet — keep an entry so we can try geocoding its address later
      map.set(name.toLowerCase(), { lat: 0, lng: 0, address: l.address })
    }
  }
  locationCoordMap.value = map
}

async function defaultCenter(): Promise<{ lat: number; lng: number }> {
  // Prefer the first locatable vehicle, else first location, else a default
  const vehiclesList = vehicles.value
  for (const v of vehiclesList) {
    const c = await resolveCoords(v)
    if (c) return c
  }
  const locs = locations.value || []
  for (const l of locs) {
    if (l.latitude != null && l.longitude != null) return { lat: l.latitude, lng: l.longitude }
  }
  return { lat: 0, lng: 0 }
}

async function resolveCoords(vehicle: any): Promise<{ lat: number; lng: number } | null> {
  const locName = (vehicle.location || '').toString().trim()
  if (!locName) return null
  const key = locName.toLowerCase()

  // 1) known Location entry (may or may not have coordinates)
  const known = locationCoordMap.value.get(key)
  if (known) {
    if (known.lat !== 0 || known.lng !== 0) return { lat: known.lat, lng: known.lng }
    // Location exists but without coordinates — geocode its address instead of the name
    const cacheKey = `addr:${(known.address || locName).toLowerCase()}`
    if (geocodeCache.value.has(cacheKey)) return geocodeCache.value.get(cacheKey) || null
    try {
      const coords = await gmaps.geocodeAddress(known.address || locName)
      geocodeCache.value.set(cacheKey, coords)
      return coords
    } catch {
      geocodeCache.value.set(cacheKey, null)
      return null
    }
  }

  // 2) geocode cache by name (could be null = tried and failed)
  if (geocodeCache.value.has(key)) return geocodeCache.value.get(key) || null

  // 3) geocode the location name via Google
  try {
    const coords = await gmaps.geocodeAddress(locName)
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

  // Track unique location-name geocodes so we cap Google quota usage sensibly
  const geocodedKeys = new Set<string>(geocodeCache.value.keys())
  const maxGeocode = 30

  for (const v of vehicles.value) {
    const locName = (v.location || '').toString().trim()
    const key = locName.toLowerCase()
    // Decide whether this vehicle would trigger a fresh Google geocode
    const alreadyCached = geocodeCache.value.has(key) || geocodeCache.value.has(`addr:${key}`)
    const inLocationsWithCoords = locationCoordMap.value.has(key)
    const willGeocode = !inLocationsWithCoords && !alreadyCached
    if (willGeocode && geocodedKeys.size >= maxGeocode) continue

    const coords = await resolveCoords(v)
    if (!coords) continue
    if (willGeocode) {
      geocodedKeys.add(key)
      geocodedKeys.add(`addr:${key}`)
    }

    const marker = createMarker(google, v, coords)
    const info = new google.maps.InfoWindow({ content: buildInfoHtml(v) })
    marker.addListener('click', () => {
      info.open({ anchor: marker, map: mapInstance.value })
      selectedVehicle.value = v
    })
    markers.value.push({ vehicle: v, lat: coords.lat, lng: coords.lng, marker, info })
  }
}

function createMarker(google: any, vehicle: any, coords: { lat: number; lng: number }): any {
  const imageUrl = resolveImageUrl(vehicle.image)
  if (imageUrl) {
    // Image marker: use a small rounded thumbnail as the icon
    return new google.maps.Marker({
      position: coords,
      map: mapInstance.value,
      title: vehicle.display_name,
      icon: {
        url: imageUrl,
        scaledSize: new google.maps.Size(40, 40),
      },
    })
  }
  // Fallback: indigo pin with a white car glyph (self-contained SVG data URL)
  return new google.maps.Marker({
    position: coords,
    map: mapInstance.value,
    title: vehicle.display_name,
    icon: {
      url: carPinDataUrl(),
      scaledSize: new google.maps.Size(44, 44),
      anchor: new google.maps.Point(22, 44),
    },
  })
}

function carPinDataUrl(): string {
  // 44x44 pin: indigo drop with a white car silhouette
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="44" height="44" viewBox="0 0 44 44">
    <path d="M22 0C12.6 0 5 7.6 5 17c0 11 17 26 17 26s17-15 17-26C39 7.6 31.4 0 22 0z" fill="#4f46e5" stroke="#ffffff" stroke-width="2"/>
    <path d="M15 18l1.2-3.6A2 2 0 0 1 18.1 13h7.8a2 2 0 0 1 1.9 1.4L29 18h-14z" fill="#ffffff" opacity="0.95"/>
    <path d="M13 19h18a1 1 0 0 1 1 1v5a1 1 0 0 1-1 1h-1v1.5a1 1 0 0 1-2 0V26H16v1.5a1 1 0 0 1-2 0V26h-1a1 1 0 0 1-1-1v-5a1 1 0 0 1 1-1z" fill="#ffffff" opacity="0.95"/>
    <circle cx="16.5" cy="23" r="1.6" fill="#4f46e5"/>
    <circle cx="27.5" cy="23" r="1.6" fill="#4f46e5"/>
  </svg>`
  return 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(svg)
}

function buildInfoHtml(v: any): string {
  const img = resolveImageUrl(v.image)
  const imgTag = img
    ? `<img src="${img}" style="width:100%;height:96px;object-fit:cover;border-radius:8px;margin-bottom:8px" alt="vehicle"/>`
    : ''
  return `<div style="min-width:200px;max-width:240px">
    ${imgTag}
    <div style="font-weight:600;font-size:14px;color:#0f172a;margin-bottom:2px">${escapeHtml(v.display_name || '')}</div>
    <div style="font-size:12px;color:#64748b;margin-bottom:4px">${escapeHtml(v.license_plate || v.vin || '')}</div>
    <div style="font-size:12px;color:#64748b">${escapeHtml(v.location || 'Unknown location')}</div>
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
  // Access the shared google instance from the loader state
  return (gmaps as any)?.state?.google || (window as any).google
}

async function findVehicle() {
  const q = search.value.trim().toLowerCase()
  if (!q) return
  const match = markers.value.find(m => {
    const v = m.vehicle
    return [v.display_name, v.license_plate, v.vin, v.location]
      .filter(Boolean)
      .some(s => String(s).toLowerCase().includes(q))
  })
  if (!match) {
    error.value = `No vehicle found for "${search.value}".`
    setTimeout(() => { if (error.value) error.value = '' }, 3000)
    return
  }
  selectedVehicle.value = match.vehicle
  mapInstance.value?.panTo({ lat: match.lat, lng: match.lng })
  mapInstance.value?.setZoom(13)
  // Trigger the info window
  const g = _stateGoogle()
  try { g.maps.event.trigger(match.marker, 'click') } catch {}
}
</script>

<style scoped>
.vehicle-map-card {
  border-color: #e2e8f0 !important;
}
.vehicle-map-card__icon {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  background: linear-gradient(135deg, #6366f1, #4f46e5);
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 4px 12px rgba(99, 102, 241, 0.3);
  flex-shrink: 0;
}
.vehicle-map-wrapper {
  position: relative;
  height: 460px;
  background: #f1f5f9;
}
.vehicle-map {
  width: 100%;
  height: 100%;
  min-height: 460px;
}
.vehicle-map-overlay {
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
.vehicle-map-info {
  border-top: 1px solid #e2e8f0;
  padding: 12px 16px;
  background: #f8fafc;
}
.vehicle-map-info__thumb {
  width: 48px;
  height: 48px;
  border-radius: 10px;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  box-shadow: 0 2px 6px rgba(15, 23, 42, 0.12);
}
.vehicle-map-info__thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}
</style>
