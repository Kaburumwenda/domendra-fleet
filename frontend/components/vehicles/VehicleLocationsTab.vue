<template>
  <div class="d-flex flex-column ga-4">
    <div class="d-flex align-center justify-space-between">
      <span class="text-body-2 text-medium-emphasis">{{ locations.length }} locations</span>
      <v-btn v-can="'vehicles:create'" color="primary" prepend-icon="mdi-map-marker-plus" size="small" @click="openCreate">Add Location</v-btn>
    </div>

    <v-card elevation="0" border rounded="lg">
      <v-data-table
        :headers="headers"
        :items="locations"
        :loading="pending"
        :items-per-page="20"
        :items-per-page-options="[10, 20, 50]"
        :search="search"
        hover
      >
        <template #top>
          <div class="d-flex align-center justify-space-between pa-4">
            <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Search locations..." density="compact" hide-details style="max-width: 300px" variant="outlined" />
          </div>
        </template>

        <template #item.name="{ item }">
          <div class="d-flex align-center ga-2">
            <v-icon :color="item.color">mdi-map-marker</v-icon>
            <span class="font-weight-medium" style="color: #1e293b">{{ item.name }}</span>
          </div>
        </template>

        <template #item.type="{ value }">
          <v-chip size="small" variant="tonal">{{ typeLabel(value) }}</v-chip>
        </template>

        <template #item.address="{ value }">
          <span class="text-body-2 text-medium-emphasis">{{ value || '—' }}</span>
        </template>

        <template #item.is_active="{ value }">
          <v-chip :color="value ? 'success' : 'grey'" size="small" variant="flat">{{ value ? 'Active' : 'Inactive' }}</v-chip>
        </template>

        <template #item.vehicle_count="{ value }">
          <v-chip size="small" variant="tonal">{{ value || 0 }}</v-chip>
        </template>

        <template #item.actions="{ item }">
          <div class="d-flex ga-1">
            <v-btn icon="mdi-eye-outline" variant="text" size="small" @click="openView(item)" />
            <v-btn v-can="'vehicles:update'" icon="mdi-pencil-outline" variant="text" size="small" @click="openEdit(item)" />
            <v-btn v-can="'vehicles:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deleteLocation(item)" />
          </div>
        </template>

        <template #no-data>
          <div class="text-center py-12 text-medium-emphasis">
            <v-icon size="48" class="mb-3">mdi-map-marker</v-icon>
            <p>No locations yet. Add a depot, yard or site.</p>
          </div>
        </template>
      </v-data-table>
    </v-card>

    <LocationLocationMap :locations="locations" />

    <v-dialog v-model="dialogVisible" max-width="640" scrollable>
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-map-marker-plus">{{ editing ? 'Edit Location' : 'Add Location' }}</AppModalHeader>
        <v-card-text>
          <v-row dense>
            <v-col cols="8"><v-text-field v-model="form.name" label="Name" density="comfortable" :error-messages="errors.name" /></v-col>
            <v-col cols="4">
              <v-combobox v-model="form.type" :items="locationTypes" item-title="label" item-value="value" label="Type" density="comfortable" />
            </v-col>
            <v-col cols="12">
              <div class="d-flex align-center ga-2 mb-2">
                <v-btn-toggle v-model="addressMode" mandatory density="compact" color="primary" variant="outlined" divided>
                  <v-btn value="places" size="x-small" prepend-icon="mdi-magnify">Google Places</v-btn>
                  <v-btn value="map" size="x-small" prepend-icon="mdi-map-marker-radius">Pick on Map</v-btn>
                  <v-btn value="live" size="x-small" prepend-icon="mdi-crosshairs-gps">Live</v-btn>
                </v-btn-toggle>
              </div>

              <template v-if="addressMode === 'places'">
                <v-text-field
                  ref="placesInput"
                  v-model="placesQuery"
                  label="Search address (Google Places)"
                  placeholder="Start typing an address..."
                  density="comfortable"
                  prepend-inner-icon="mdi-magnify"
                  :loading="mapsLoading"
                  :error-messages="mapsError"
                  clearable
                  @update:model-value="onPlacesQueryCleared"
                />
                <div v-if="selectedPlaceName" class="text-caption text-success mt-1">
                  <v-icon size="14" class="me-1">mdi-check-circle</v-icon>
                  {{ selectedPlaceName }}
                </div>
              </template>

              <template v-else-if="addressMode === 'map'">
                <v-textarea
                  v-model="form.address"
                  label="Address"
                  density="comfortable"
                  rows="2"
                  readonly
                  :placeholder="form.address ? '' : 'Open the map to pick a location...'"
                  append-inner-icon="mdi-map-search"
                  @click:append-inner="openMapPicker"
                />
                <v-btn size="small" variant="tonal" color="primary" prepend-icon="mdi-map-marker-radius" class="mt-2" @click="openMapPicker">
                  Open Map Picker
                </v-btn>
              </template>

              <template v-else-if="addressMode === 'live'">
                <v-textarea
                  v-model="form.address"
                  label="Address"
                  density="comfortable"
                  rows="2"
                  readonly
                  :placeholder="form.address ? '' : 'Use your current location...'"
                />
                <v-btn size="small" variant="tonal" color="primary" prepend-icon="mdi-crosshairs-gps" class="mt-2" :loading="locating" @click="useLiveLocation">
                  Use My Current Location
                </v-btn>
              </template>
            </v-col>
            <v-col cols="6"><v-text-field v-model.number="form.latitude" label="Latitude" type="number" density="comfortable" /></v-col>
            <v-col cols="6"><v-text-field v-model.number="form.longitude" label="Longitude" type="number" density="comfortable" /></v-col>
            <v-col cols="6">
              <v-text-field v-model="form.color" label="Color" density="comfortable" hide-details />
              <div class="d-flex flex-wrap ga-2 mt-2">
                <div v-for="c in colorPresets" :key="c" class="color-swatch" :style="{ background: c }" :title="c" @click="form.color = c">
                  <v-icon v-if="form.color === c" size="16" color="white">mdi-check</v-icon>
                </div>
              </div>
            </v-col>
            <v-col cols="6" class="d-flex align-center">
              <v-switch v-model="form.is_active" label="Active" density="compact" hide-details color="primary" />
            </v-col>
            <v-col cols="12"><v-textarea v-model="form.notes" label="Notes" density="comfortable" rows="2" /></v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="dialogVisible = false">Cancel</v-btn>
          <v-btn color="primary" :loading="saving" @click="save">{{ editing ? 'Update Location' : 'Create Location' }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="viewDialogVisible" max-width="720" scrollable>
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-map-marker">{{ viewItem?.name }}</AppModalHeader>
        <v-card-text>
          <div class="d-flex flex-column ga-3">
            <div class="d-flex flex-wrap ga-4">
              <div class="flex-grow-1">
                <div class="text-caption text-medium-emphasis mb-1">Type</div>
                <v-chip size="small" variant="tonal" :color="viewItem?.color">{{ typeLabel(viewItem?.type) }}</v-chip>
              </div>
              <div class="flex-grow-1">
                <div class="text-caption text-medium-emphasis mb-1">Status</div>
                <v-chip :color="viewItem?.is_active ? 'success' : 'grey'" size="small" variant="flat">{{ viewItem?.is_active ? 'Active' : 'Inactive' }}</v-chip>
              </div>
              <div class="flex-grow-1">
                <div class="text-caption text-medium-emphasis mb-1">Vehicles</div>
                <v-chip size="small" variant="tonal">{{ viewItem?.vehicle_count || 0 }}</v-chip>
              </div>
            </div>

            <div>
              <div class="text-caption text-medium-emphasis mb-1">Address</div>
              <div class="text-body-2">{{ viewItem?.address || '—' }}</div>
            </div>

            <div class="d-flex ga-4">
              <div>
                <div class="text-caption text-medium-emphasis mb-1">Latitude</div>
                <div class="text-body-2">{{ viewItem?.latitude ?? '—' }}</div>
              </div>
              <div>
                <div class="text-caption text-medium-emphasis mb-1">Longitude</div>
                <div class="text-body-2">{{ viewItem?.longitude ?? '—' }}</div>
              </div>
              <div>
                <div class="text-caption text-medium-emphasis mb-1">Color</div>
                <div class="d-flex align-center ga-2">
                  <span class="color-dot" :style="{ background: viewItem?.color }" />
                  <span class="text-body-2">{{ viewItem?.color }}</span>
                </div>
              </div>
            </div>

            <div v-if="viewItem?.notes">
              <div class="text-caption text-medium-emphasis mb-1">Notes</div>
              <div class="text-body-2">{{ viewItem?.notes }}</div>
            </div>

            <div v-if="hasCoords(viewItem)" class="mt-1">
              <div class="text-caption text-medium-emphasis mb-1">Map</div>
              <div ref="viewMapContainer" class="location-map" />
            </div>
            <div v-else class="text-center py-6 text-medium-emphasis">
              <v-icon size="36" class="mb-2">mdi-map-marker-off</v-icon>
              <p class="text-body-2">No coordinates set for this location.</p>
            </div>
          </div>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="viewDialogVisible = false">Close</v-btn>
          <v-btn v-can="'vehicles:update'" color="primary" variant="tonal" prepend-icon="mdi-pencil-outline" @click="openEditFromView">Edit</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="mapDialogVisible" max-width="720" scrollable>
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-map-marker-radius">Pick Location on Map</AppModalHeader>
        <v-card-text class="pa-0">
          <div class="pa-3 d-flex align-center ga-2">
            <v-text-field
              v-model="mapSearch"
              label="Search address"
              density="compact"
              prepend-inner-icon="mdi-magnify"
              hide-details
              variant="outlined"
              clearable
              @keyup.enter="searchOnMap"
            />
            <v-btn color="primary" variant="tonal" prepend-icon="mdi-magnify" @click="searchOnMap">Search</v-btn>
          </div>
          <div ref="mapContainer" class="location-map" />
          <div v-if="pickedAddress" class="pa-3 text-body-2">
            <v-icon size="16" class="me-1" color="primary">mdi-map-marker</v-icon>
            {{ pickedAddress }}
            <span class="text-medium-emphasis ms-2">({{ pickedPos?.lat.toFixed(5) }}, {{ pickedPos?.lng.toFixed(5) }})</span>
          </div>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="mapDialogVisible = false">Cancel</v-btn>
          <v-btn color="primary" @click="confirmMapPick">Use This Location</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
const { $api, $swal } = useNuxtApp()

const search = ref('')
const dialogVisible = ref(false)
const saving = ref(false)
const editing = ref(false)
const errors = reactive<any>({})

const addressMode = ref<'places' | 'map' | 'live'>('places')
const placesInput = ref<HTMLInputElement | null>(null)
const placesQuery = ref('')
const selectedPlaceName = ref('')
const mapsLoading = ref(false)
const mapsError = ref('')
let autocomplete: any = null

const mapDialogVisible = ref(false)
const mapContainer = ref<HTMLElement | null>(null)
const mapSearch = ref('')
const pickedAddress = ref('')
const pickedPos = ref<{ lat: number; lng: number } | null>(null)
let mapInstance: any = null
let mapMarker: any = null

const viewDialogVisible = ref(false)
const viewItem = ref<any>(null)
const viewMapContainer = ref<HTMLElement | null>(null)
let viewMapInstance: any = null
let viewMapMarker: any = null

const locating = ref(false)

let gmaps: ReturnType<typeof useGoogleMaps> | null = null
function ensureMaps() {
  if (!gmaps) gmaps = useGoogleMaps()
  return gmaps
}

function getInputEl(): HTMLInputElement | null {
  const inst: any = placesInput.value
  if (!inst) return null
  const el: HTMLElement = inst.$el || inst.el || inst
  return (el.querySelector?.('input') as HTMLInputElement) || (el as HTMLInputElement)
}

async function attachAutocomplete() {
  mapsError.value = ''
  mapsLoading.value = true
  try {
    const maps = ensureMaps()
    await maps.ensureGoogle()
    await nextTick()
    const inputEl = getInputEl()
    if (!inputEl) {
      mapsLoading.value = false
      return
    }
    if (autocomplete) {
      try { (window as any).google.maps.event.clearInstanceListeners(autocomplete) } catch {}
    }
    autocomplete = await maps.attachAutocomplete(inputEl, {
      onPlace: handlePlaceSelected,
    })
  } catch (e: any) {
    mapsError.value = e?.message || 'Failed to load Google Places.'
  } finally {
    mapsLoading.value = false
  }
}

function handlePlaceSelected(place: any) {
  if (!place || !place.geometry) {
    selectedPlaceName.value = ''
    return
  }
  const lat = place.geometry.location.lat()
  const lng = place.geometry.location.lng()
  form.latitude = lat
  form.longitude = lng
  form.address = place.formatted_address || place.name || ''
  selectedPlaceName.value = place.formatted_address || place.name || ''
}

function onPlacesQueryCleared(val: string) {
  if (!val) {
    selectedPlaceName.value = ''
  }
}

watch(dialogVisible, async (open) => {
  if (open && addressMode.value === 'places') {
    await nextTick()
    attachAutocomplete()
  }
})

watch(addressMode, async (mode) => {
  if (mode === 'places' && dialogVisible.value) {
    await nextTick()
    attachAutocomplete()
  }
})

async function openMapPicker() {
  pickedAddress.value = ''
  pickedPos.value = null
  mapSearch.value = form.address || ''
  mapDialogVisible.value = true
  await nextTick()
  const maps = ensureMaps()
  await maps.ensureGoogle()
  let center = { lat: form.latitude || 0, lng: form.longitude || 0 }
  if (!form.latitude && !form.longitude) {
    try {
      const pos = await maps.getCurrentPosition()
      center = pos
    } catch {
      center = { lat: 40.4171, lng: -3.7034 }
    }
  }
  if (!mapContainer.value) return
  mapInstance = maps.createMap(mapContainer.value, center, 15)
  const google = (window as any).google
  mapMarker = new google.maps.Marker({
    position: center,
    map: mapInstance,
    draggable: true,
  })
  mapMarker.addListener('dragend', () => updatePickedFromMarker())
  mapInstance.addListener('click', (e: any) => {
    const pos = { lat: e.latLng.lat(), lng: e.latLng.lng() }
    setMarkerPos(pos)
    updatePickedAddress(pos)
  })
  pickedPos.value = center
  if (form.address) {
    pickedAddress.value = form.address
  } else {
    updatePickedAddress(center)
  }
}

function setMarkerPos(pos: { lat: number; lng: number }) {
  if (!mapMarker) return
  mapMarker.setPosition(pos)
  pickedPos.value = pos
}

async function updatePickedFromMarker() {
  if (!mapMarker) return
  const p = mapMarker.getPosition()
  const pos = { lat: p.lat(), lng: p.lng() }
  pickedPos.value = pos
  updatePickedAddress(pos)
}

async function updatePickedAddress(pos: { lat: number; lng: number }) {
  const maps = ensureMaps()
  try {
    const addr = await maps.reverseGeocode(pos.lat, pos.lng)
    pickedAddress.value = addr
  } catch {
    pickedAddress.value = ''
  }
}

async function searchOnMap() {
  if (!mapSearch.value || !mapInstance) return
  const maps = ensureMaps()
  try {
    const res = await maps.geocodeAddress(mapSearch.value)
    if (!res) return
    const pos = { lat: res.lat, lng: res.lng }
    mapInstance.setCenter(pos)
    setMarkerPos(pos)
    pickedAddress.value = res.formatted
  } catch (e) {
    console.error(e)
  }
}

function confirmMapPick() {
  if (!pickedPos.value) return
  form.latitude = pickedPos.value.lat
  form.longitude = pickedPos.value.lng
  if (pickedAddress.value) form.address = pickedAddress.value
  mapDialogVisible.value = false
}

async function useLiveLocation() {
  const maps = ensureMaps()
  locating.value = true
  try {
    const pos = await maps.getCurrentPosition()
    form.latitude = pos.lat
    form.longitude = pos.lng
    const addr = await maps.reverseGeocode(pos.lat, pos.lng)
    form.address = addr || `(${pos.lat.toFixed(5)}, ${pos.lng.toFixed(5)})`
  } catch (e: any) {
    mapsError.value = e?.message || 'Could not get your current location.'
  } finally {
    locating.value = false
  }
}

function hasCoords(item: any) {
  return item && item.latitude != null && item.longitude != null
}

function openView(l: any) {
  viewItem.value = l
  viewDialogVisible.value = true
  if (hasCoords(l)) {
    nextTick(() => initViewMap(l))
  }
}

async function initViewMap(l: any) {
  const maps = ensureMaps()
  try {
    await maps.ensureGoogle()
  } catch (e: any) {
    console.error('[view-map] Google Maps failed to load:', e)
    return
  }
  await nextTick()
  if (!viewMapContainer.value) return
  const center = { lat: l.latitude, lng: l.longitude }
  if (viewMapInstance) {
    try { viewMapInstance.setCenter(center) } catch {}
  } else {
    viewMapInstance = maps.createMap(viewMapContainer.value, center, 14)
  }
  const google = (window as any).google
  if (viewMapMarker) {
    try { viewMapMarker.setMap(null) } catch {}
  }
  viewMapMarker = new google.maps.Marker({
    position: center,
    map: viewMapInstance,
    title: l.name,
  })
  if (l.color) {
    try {
      viewMapMarker.setIcon({
        path: google.maps.SymbolPath.CIRCLE,
        scale: 8,
        fillColor: l.color,
        fillOpacity: 1,
        strokeColor: '#ffffff',
        strokeWeight: 2,
      })
    } catch {}
  }
  google.maps.event.trigger(viewMapInstance, 'resize')
}

watch(viewDialogVisible, (open) => {
  if (!open) {
    if (viewMapMarker) { try { viewMapMarker.setMap(null) } catch {} viewMapMarker = null }
    viewMapInstance = null
    if (viewMapContainer.value) viewMapContainer.value.innerHTML = ''
  }
})

function openEditFromView() {
  viewDialogVisible.value = false
  if (viewItem.value) openEdit(viewItem.value)
}

const locationTypes = [
  { label: 'Depot / Yard', value: 'depot' },
  { label: 'Fuel Station', value: 'fuel_station' },
  { label: 'Charging Station', value: 'charging_station' },
  { label: 'Warehouse', value: 'warehouse' },
  { label: 'Customer Site', value: 'customer_site' },
  { label: 'Geofence Point', value: 'geopoint' },
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
const colorPresets = ['#6366f1', '#4f46e5', '#22c55e', '#10b981', '#f59e0b', '#ef4444', '#ec4899', '#06b6d4', '#64748b']

const headers = [
  { title: 'Name', key: 'name', sortable: true },
  { title: 'Type', key: 'type', sortable: true, width: '160px' },
  { title: 'Address', key: 'address', sortable: false },
  { title: 'Status', key: 'is_active', sortable: true, width: '120px' },
  { title: 'Vehicles', key: 'vehicle_count', sortable: false, width: '110px' },
  { title: '', key: 'actions', width: '100px', sortable: false },
]

const form = reactive<any>(defaultForm())

function defaultForm() {
  return {
    id: null, name: '', type: 'depot', address: '', latitude: null, longitude: null,
    color: '#6366f1', is_active: true, notes: '',
  }
}

const { data: locData, pending, refresh } = useAsyncData('locations', () =>
  $api('/locations/'), { default: () => ({ results: [], count: 0 }) }
)
const locations = computed(() => locData.value?.results || locData.value || [])

function typeLabel(value: string) {
  return locationTypes.find((t) => t.value === value)?.label || value
}

function openCreate() {
  editing.value = false
  Object.assign(form, defaultForm())
  errors.name = ''
  addressMode.value = 'places'
  placesQuery.value = ''
  selectedPlaceName.value = ''
  mapsError.value = ''
  dialogVisible.value = true
}

function openEdit(l: any) {
  editing.value = true
  Object.assign(form, {
    id: l.id, name: l.name, type: l.type || 'depot', address: l.address || '',
    latitude: l.latitude, longitude: l.longitude, color: l.color || '#6366f1',
    is_active: l.is_active !== false, notes: l.notes || '',
  })
  errors.name = ''
  addressMode.value = l.latitude && l.longitude ? 'map' : 'places'
  placesQuery.value = l.address || ''
  selectedPlaceName.value = ''
  mapsError.value = ''
  dialogVisible.value = true
}

async function save() {
  errors.name = ''
  if (!form.name) { errors.name = 'Name is required.'; return }
  saving.value = true
  try {
    const rawType: any = form.type
    const typeValue = typeof rawType === 'string'
      ? rawType
      : rawType?.value || rawType?.label || 'other'
    const body = {
      name: form.name, type: typeValue, address: form.address,
      latitude: form.latitude, longitude: form.longitude, color: form.color,
      is_active: form.is_active, notes: form.notes,
    }
    if (editing.value) {
      await $api(`/locations/${form.id}/`, { method: 'PATCH', body })
    } else {
      await $api('/locations/', { method: 'POST', body })
    }
    dialogVisible.value = false
    await refresh()
  } catch (e: any) {
    errors.name = e?.data?.name?.[0] || ''
    console.error('Location save failed:', e?.data || e)
  } finally {
    saving.value = false
  }
}

async function deleteLocation(l: any) {
  const { isConfirmed } = await $swal.fire({
    title: 'Delete Location',
    text: `Delete location "${l.name}"?`,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Delete',
    cancelButtonText: 'Cancel',
  })
  if (!isConfirmed) return
  await $api(`/locations/${l.id}/`, { method: 'DELETE' })
  await refresh()
}
</script>

<style scoped>
.color-swatch {
  width: 24px;
  height: 24px;
  border-radius: 6px;
  border: 2px solid transparent;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.1s ease;
}
.color-swatch:hover {
  transform: scale(1.1);
  border-color: #e2e8f0;
}
.location-map {
  width: 100%;
  height: 380px;
  background: #e2e8f0;
}
.color-dot {
  width: 16px;
  height: 16px;
  border-radius: 50%;
  border: 2px solid #e2e8f0;
  display: inline-block;
}
</style>
