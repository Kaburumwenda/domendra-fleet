<template>
  <div class="d-flex flex-column ga-4">
    <!-- Header bar -->
    <div class="page-header-bar">
      <div class="d-flex align-center ga-2">
        <v-btn icon="mdi-arrow-left" variant="text" size="small" @click="goBack" />
        <v-icon color="primary">mdi-car-side</v-icon>
        <span class="text-h6 font-weight-bold page-header-title">{{ transfer?.reference || 'Loading...' }}</span>
        <v-chip v-if="transfer" size="small" variant="flat" :color="statusColor(transfer.status)">{{ statusLabel(transfer.status) }}</v-chip>
      </div>
      <div class="d-flex ga-2">
        <v-btn v-can="'transfers:update'" size="small" variant="outlined" prepend-icon="mdi-pencil-outline" @click="navigateTo(`/app/transfers/${transfer?.id}/edit`)">Edit</v-btn>
        <v-btn size="small" variant="outlined" prepend-icon="mdi-printer-outline" @click="printTransfer">Print</v-btn>
      </div>
    </div>

    <div v-if="loading" class="text-center py-12">
      <v-progress-circular indeterminate size="48" color="primary" />
    </div>

    <template v-else-if="transfer">
      <v-row>
        <!-- Left column: Route, passenger, details -->
        <v-col cols="12" md="8">
          <!-- Route cards -->
          <v-card elevation="0" border rounded="lg" class="mb-4">
            <div class="pa-4 route-header">
              <v-icon color="white" class="mr-2">mdi-map-marker-route</v-icon>
              <span class="text-white font-weight-bold">Route Details</span>
            </div>
            <v-card-text>
              <div class="d-flex align-center ga-3 mb-3">
                <div class="route-dot bg-success"></div>
                <div class="flex-1">
                  <p class="text-caption text-medium-emphasis mb-0">PICKUP</p>
                  <p class="text-body-1 font-weight-medium mb-0">{{ transfer.pickup_name }}</p>
                  <p class="text-body-2 text-medium-emphasis mb-0">{{ transfer.pickup_address }}</p>
                </div>
                <div class="text-right">
                  <p class="text-caption text-medium-emphasis mb-0">{{ formatDate(transfer.pickup_datetime) }}</p>
                  <p class="text-h6 font-weight-bold text-primary">{{ formatTime(transfer.pickup_datetime) }}</p>
                  <v-chip v-if="transfer.pickup_flight_no" size="x-small" variant="tonal" color="info"><v-icon start size="12">mdi-airplane</v-icon>{{ transfer.pickup_flight_no }}</v-chip>
                </div>
              </div>

              <!-- Stops -->
              <div v-for="stop in transfer.stops" :key="stop.id" class="d-flex align-center ga-3 mb-2 ml-3">
                <div class="route-dot-stop"></div>
                <div class="flex-1">
                  <p class="text-caption text-medium-emphasis mb-0">STOP {{ stop.sequence }}</p>
                  <p class="text-body-2 font-weight-medium mb-0">{{ stop.place_name }}</p>
                  <p class="text-caption text-medium-emphasis mb-0">{{ stop.address }}</p>
                </div>
                <span v-if="stop.duration_min" class="text-caption text-medium-emphasis">+{{ stop.duration_min }}m</span>
              </div>

              <div class="route-line"></div>

              <div class="d-flex align-center ga-3">
                <div class="route-dot bg-error"></div>
                <div class="flex-1">
                  <p class="text-caption text-medium-emphasis mb-0">DROP-OFF</p>
                  <p class="text-body-1 font-weight-medium mb-0">{{ transfer.dropoff_name }}</p>
                  <p class="text-body-2 text-medium-emphasis mb-0">{{ transfer.dropoff_address }}</p>
                </div>
                <div class="text-right">
                  <p class="text-caption text-medium-emphasis mb-0">{{ transfer.dropoff_datetime ? formatDate(transfer.dropoff_datetime) : 'Est. ETA' }}</p>
                  <p class="text-h6 font-weight-bold text-error">{{ transfer.dropoff_datetime ? formatTime(transfer.dropoff_datetime) : '--' }}</p>
                </div>
              </div>

              <v-divider class="my-3" />
              <div class="d-flex flex-wrap ga-4">
                <div>
                  <p class="text-caption text-medium-emphasis mb-0">Distance</p>
                  <p class="text-body-1 font-weight-bold mb-0">{{ transfer.distance_km }} km</p>
                </div>
                <div>
                  <p class="text-caption text-medium-emphasis mb-0">Est. Duration</p>
                  <p class="text-body-1 font-weight-bold mb-0">{{ transfer.estimated_duration_min }} min</p>
                </div>
                <div>
                  <p class="text-caption text-medium-emphasis mb-0">Trip Type</p>
                  <p class="text-body-1 font-weight-bold mb-0">{{ tripLabel(transfer.trip_type) }}</p>
                </div>
                <div v-if="transfer.return_datetime">
                  <p class="text-caption text-medium-emphasis mb-0">Return</p>
                  <p class="text-body-1 font-weight-bold mb-0">{{ formatDateTime(transfer.return_datetime) }}</p>
                </div>
              </div>
            </v-card-text>
          </v-card>

          <!-- Passenger card -->
          <v-card elevation="0" border rounded="lg" class="mb-4">
            <div class="pa-4 passenger-header">
              <v-icon color="white" class="mr-2">mdi-account-circle-outline</v-icon>
              <span class="text-white font-weight-bold">Passenger Information</span>
            </div>
            <v-card-text>
              <v-row dense>
                <v-col cols="6"><v-text-field :model-value="transfer.passenger_name" label="Name" density="compact" variant="plain" readonly /></v-col>
                <v-col cols="3"><v-text-field :model-value="transfer.passenger_phone" label="Phone" density="compact" variant="plain" readonly /></v-col>
                <v-col cols="3"><v-text-field :model-value="transfer.passenger_email" label="Email" density="compact" variant="plain" readonly /></v-col>
                <v-col cols="3"><v-text-field :model-value="transfer.passenger_count" label="Passengers" density="compact" variant="plain" readonly /></v-col>
                <v-col cols="3"><v-text-field :model-value="transfer.luggage_count" label="Luggage" density="compact" variant="plain" readonly /></v-col>
                <v-col cols="3"><v-text-field :model-value="transfer.has_child_seat ? 'Yes' : 'No'" label="Child Seat" density="compact" variant="plain" readonly /></v-col>
                <v-col cols="3"><v-text-field :model-value="transfer.has_infant_seat ? 'Yes' : 'No'" label="Infant Seat" density="compact" variant="plain" readonly /></v-col>
                <v-col cols="12" v-if="transfer.passenger_notes">
                  <p class="text-caption text-medium-emphasis mb-0">Special Requests</p>
                  <p class="text-body-2">{{ transfer.passenger_notes }}</p>
                </v-col>
              </v-row>
            </v-card-text>
          </v-card>

          <!-- Lifecycle / timeline -->
          <v-card elevation="0" border rounded="lg" class="mb-4">
            <div class="pa-4 lifecycle-header">
              <v-icon color="white" class="mr-2">mdi-timeline-clock-outline</v-icon>
              <span class="text-white font-weight-bold">Trip Timeline</span>
            </div>
            <v-card-text>
              <v-timeline density="compact" align="start">
                <v-timeline-item dot-color="primary" size="small">
                  <div class="d-flex justify-space-between">
                    <span class="text-body-2 font-weight-medium">Transfer Created</span>
                    <span class="text-caption text-medium-emphasis">{{ formatDateTime(transfer.created_at) }}</span>
                  </div>
                </v-timeline-item>
                <v-timeline-item v-if="transfer.actual_pickup_time" dot-color="warning" size="small">
                  <div class="d-flex justify-space-between">
                    <span class="text-body-2 font-weight-medium">Passenger Picked Up</span>
                    <span class="text-caption text-medium-emphasis">{{ formatDateTime(transfer.actual_pickup_time) }}</span>
                  </div>
                </v-timeline-item>
                <v-timeline-item v-if="transfer.actual_dropoff_time" dot-color="success" size="small">
                  <div class="d-flex justify-space-between">
                    <span class="text-body-2 font-weight-medium">Dropped Off & Completed</span>
                    <span class="text-caption text-medium-emphasis">{{ formatDateTime(transfer.actual_dropoff_time) }}</span>
                  </div>
                </v-timeline-item>
              </v-timeline>
            </v-card-text>
          </v-card>

          <!-- Notes & feedback -->
          <v-card v-if="transfer.notes || transfer.feedback || transfer.rating" elevation="0" border rounded="lg" class="mb-4">
            <v-card-text>
              <div v-if="transfer.notes">
                <p class="text-caption text-medium-emphasis mb-0">Internal Notes</p>
                <p class="text-body-2">{{ transfer.notes }}</p>
              </div>
              <div v-if="transfer.rating || transfer.feedback" class="mt-3">
                <p class="text-caption text-medium-emphasis mb-0">Passenger Rating & Feedback</p>
                <v-rating v-if="transfer.rating" :model-value="transfer.rating" color="amber" readonly size="small" class="mt-1" />
                <p v-if="transfer.feedback" class="text-body-2 mt-1">{{ transfer.feedback }}</p>
              </div>
            </v-card-text>
          </v-card>
        </v-col>

        <!-- Right column: Status, assignment, pricing, actions -->
        <v-col cols="12" md="4">
          <!-- Status & lifecycle actions -->
          <v-card elevation="0" border rounded="lg" class="mb-4">
            <v-card-text>
              <p class="text-subtitle-2 font-weight-bold mb-3">Lifecycle Actions</p>
              <div class="d-flex flex-wrap ga-2">
                <v-btn v-if="canStart" color="warning" variant="tonal" size="small" prepend-icon="mdi-car-arrow-right" :loading="actionLoading" @click="doAction('start')">Start (En Route)</v-btn>
                <v-btn v-if="canPickup" color="orange-darken-2" variant="tonal" size="small" prepend-icon="mdi-account-check" :loading="actionLoading" @click="doAction('pickup')">Confirm Pickup</v-btn>
                <v-btn v-if="canComplete" color="success" variant="tonal" size="small" prepend-icon="mdi-check-circle" :loading="actionLoading" @click="doAction('complete')">Complete</v-btn>
                <v-btn v-if="canCancel" color="error" variant="tonal" size="small" prepend-icon="mdi-cancel" :loading="actionLoading" @click="doAction('cancel')">Cancel</v-btn>
                <v-btn v-if="canNoShow" color="grey-darken-1" variant="tonal" size="small" prepend-icon="mdi-account-remove" :loading="actionLoading" @click="doAction('no_show')">No Show</v-btn>
              </div>
            </v-card-text>
          </v-card>

          <!-- Assignment -->
          <v-card elevation="0" border rounded="lg" class="mb-4">
            <v-card-text>
              <p class="text-subtitle-2 font-weight-bold mb-3">Assignment</p>
              <v-select v-model="assignVehicle" :items="availableVehicles" item-title="label" item-value="value" label="Vehicle" density="compact" variant="outlined" class="mb-3" @update:model-value="doAssign" />
              <v-select v-model="assignDriver" :items="availableDrivers" item-title="label" item-value="value" label="Driver" density="compact" variant="outlined" @update:model-value="doAssign" />
            </v-card-text>
          </v-card>

          <!-- Pricing summary -->
          <v-card elevation="0" border rounded="lg" class="mb-4">
            <v-card-text>
              <p class="text-subtitle-2 font-weight-bold mb-3">Fare & Payment</p>
              <div class="d-flex justify-space-between mb-1"><span class="text-body-2">Base Fare</span><span class="text-body-2 font-weight-medium">{{ currencySymbol }}{{ Number(transfer.base_fare).toFixed(2) }}</span></div>
              <div v-if="Number(transfer.tolls_amount)" class="d-flex justify-space-between mb-1"><span class="text-body-2">Tolls</span><span class="text-body-2">{{ currencySymbol }}{{ Number(transfer.tolls_amount).toFixed(2) }}</span></div>
              <div v-if="Number(transfer.parking_amount)" class="d-flex justify-space-between mb-1"><span class="text-body-2">Parking</span><span class="text-body-2">{{ currencySymbol }}{{ Number(transfer.parking_amount).toFixed(2) }}</span></div>
              <div v-if="Number(transfer.meet_greet_fee)" class="d-flex justify-space-between mb-1"><span class="text-body-2">Meet & Greet</span><span class="text-body-2">{{ currencySymbol }}{{ Number(transfer.meet_greet_fee).toFixed(2) }}</span></div>
              <div v-if="Number(transfer.waiting_fee)" class="d-flex justify-space-between mb-1"><span class="text-body-2">Waiting</span><span class="text-body-2">{{ currencySymbol }}{{ Number(transfer.waiting_fee).toFixed(2) }}</span></div>
              <div v-if="Number(transfer.child_seat_fee)" class="d-flex justify-space-between mb-1"><span class="text-body-2">Child Seat</span><span class="text-body-2">{{ currencySymbol }}{{ Number(transfer.child_seat_fee).toFixed(2) }}</span></div>
              <div v-if="Number(transfer.driver_tip)" class="d-flex justify-space-between mb-1"><span class="text-body-2">Tip</span><span class="text-body-2">{{ currencySymbol }}{{ Number(transfer.driver_tip).toFixed(2) }}</span></div>
              <div v-if="Number(transfer.tax_amount)" class="d-flex justify-space-between mb-1"><span class="text-body-2">Tax</span><span class="text-body-2">{{ currencySymbol }}{{ Number(transfer.tax_amount).toFixed(2) }}</span></div>
              <div v-if="Number(transfer.discount_amount)" class="d-flex justify-space-between mb-1"><span class="text-body-2">Discount</span><span class="text-body-2 text-error">-{{ currencySymbol }}{{ Number(transfer.discount_amount).toFixed(2) }}</span></div>
              <v-divider class="my-2" />
              <div class="d-flex justify-space-between align-center mb-2">
                <span class="text-subtitle-2 font-weight-bold">Total</span>
                <span class="text-h6 font-weight-bold text-primary">{{ currencySymbol }}{{ Number(transfer.total_amount).toFixed(2) }}</span>
              </div>
              <div class="d-flex justify-space-between mb-1">
                <span class="text-body-2 text-success">Paid</span>
                <span class="text-body-2 text-success">{{ currencySymbol }}{{ Number(transfer.amount_paid).toFixed(2) }}</span>
              </div>
              <div class="d-flex justify-space-between mb-3">
                <span class="text-body-2 text-error">Balance</span>
                <span class="text-body-2 text-error font-weight-bold">{{ currencySymbol }}{{ Number(transfer.remaining_balance || 0).toFixed(2) }}</span>
              </div>
              <v-chip size="small" variant="flat" :color="paymentStatusColor">{{ paymentStatusLabel }}</v-chip>
              <div class="mt-3" v-can="'transfers:update'">
                <v-btn size="small" variant="tonal" color="primary" prepend-icon="mdi-cash-plus" @click="paymentDialog = true">Record Payment</v-btn>
              </div>
            </v-card-text>
          </v-card>

          <!-- Service class -->
          <v-card elevation="0" border rounded="lg">
            <v-card-text>
              <div class="d-flex justify-space-between align-center">
                <div>
                  <p class="text-caption text-medium-emphasis mb-0">Service Class</p>
                  <p class="text-body-1 font-weight-bold mb-0">{{ classLabel(transfer.service_class) }}</p>
                </div>
                <v-icon size="32" :color="classColor(transfer.service_class)">mdi-car-elite</v-icon>
              </div>
            </v-card-text>
          </v-card>
        </v-col>
      </v-row>

      <!-- Route map (full width at bottom) -->
      <v-card v-if="showMap" elevation="0" border rounded="lg">
        <div class="pa-4 map-header">
          <v-icon color="white" class="mr-2">mdi-map-outline</v-icon>
          <span class="text-white font-weight-bold">Route Map</span>
        </div>
        <v-card-text class="pa-0">
          <div ref="mapContainer" class="transfer-route-map"></div>
          <div v-if="routeDistance || routeDuration" class="d-flex ga-3 pa-3 flex-wrap">
            <v-chip v-if="routeDistance" size="small" variant="tonal" color="primary">
              <v-icon start size="14">mdi-map-marker-distance</v-icon>Distance: {{ routeDistance }}
            </v-chip>
            <v-chip v-if="routeDuration" size="small" variant="tonal" color="info">
              <v-icon start size="14">mdi-clock-outline</v-icon>Duration: {{ routeDuration }}
            </v-chip>
          </div>
        </v-card-text>
      </v-card>
    </template>

    <!-- Record payment dialog -->
    <v-dialog v-model="paymentDialog" max-width="440px">
      <v-card rounded="xl" elevation="0" border>
        <AppModalHeader icon="mdi-cash-plus" title="Record Payment" color="success" />
        <v-card-text class="pa-6">
          <p class="text-body-2 text-medium-emphasis mb-3">Outstanding balance: {{ currencySymbol }}{{ Number(transfer?.remaining_balance || 0).toFixed(2) }}</p>
          <v-text-field v-model.number="paymentAmount" type="number" prefix="$" label="Amount" density="comfortable" variant="outlined" class="mb-3" />
          <v-select v-model="paymentMethod" :items="paymentMethodOptions" item-title="title" item-value="value" label="Method" density="comfortable" variant="outlined" class="mb-3" />
          <v-text-field v-model="paymentReference" label="Reference / Txn ID" density="comfortable" variant="outlined" />
        </v-card-text>
        <v-card-actions class="pa-4 pt-0">
          <v-spacer />
          <v-btn variant="text" @click="paymentDialog = false">Cancel</v-btn>
          <v-btn color="success" prepend-icon="mdi-check" :loading="paying" @click="doRecordPayment">Record</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { useTransferApi } from '~/composables/useTransferApi'

definePageMeta({ layout: 'default', permission: 'transfers:view' })

const route = useRoute()
const { $swal } = useNuxtApp()
const api = useTransferApi()
const { symbol: currencySymbol } = useCurrency()
const gmaps = useGoogleMaps()

const transferId = computed(() => Number(route.params.id))
const loading = ref(true)
const transfer = ref<any>(null)

// Map state
const showMap = ref(false)
const mapContainer = ref<HTMLElement | null>(null)
const routeDistance = ref('')
const routeDuration = ref('')

const actionLoading = ref(false)
const assignVehicle = ref<any>(null)
const assignDriver = ref<any>(null)

const availableVehicles = ref<any[]>([])
const availableDrivers = ref<any[]>([])

const paymentDialog = ref(false)
const paymentAmount = ref(0)
const paymentMethod = ref('cash')
const paymentReference = ref('')
const paying = ref(false)

const paymentMethodOptions = [
  { title: 'Cash', value: 'cash' },
  { title: 'Card', value: 'card' },
  { title: 'PayPal', value: 'paypal' },
  { title: 'Bank Transfer', value: 'bank_transfer' },
]

const canStart = computed(() => ['scheduled', 'assigned'].includes(transfer.value?.status))
const canPickup = computed(() => transfer.value?.status === 'en_route')
const canComplete = computed(() => transfer.value?.status === 'picked_up')
const canCancel = computed(() => !['completed', 'cancelled', 'no_show'].includes(transfer.value?.status))
const canNoShow = computed(() => ['scheduled', 'assigned', 'en_route'].includes(transfer.value?.status))

const paymentStatusColor = computed(() => {
  const map: Record<string, string> = { unpaid: 'error', partial: 'warning', paid: 'success', refunded: 'info' }
  return map[transfer.value?.payment_status] || 'grey'
})
const paymentStatusLabel = computed(() => {
  const map: Record<string, string> = { unpaid: 'Unpaid', partial: 'Partially Paid', paid: 'Paid', refunded: 'Refunded' }
  return map[transfer.value?.payment_status] || '--'
})

async function loadTransfer() {
  loading.value = true
  try {
    transfer.value = await api.fetchTransfer(transferId.value)
    assignVehicle.value = transfer.value.vehicle
    assignDriver.value = transfer.value.driver
    // Build the map after data loads
    showMap.value = true
    await nextTick()
    setTimeout(buildMap, 100)
  } catch (e) {
    console.error('Failed to load transfer:', e)
    $swal.fire({ icon: 'error', title: 'Not Found', text: 'Transfer not found.' })
    navigateTo('/app/transfers')
  } finally { loading.value = false }
}

async function buildMap() {
  const t = transfer.value
  if (!t || !t.pickup_lat || !t.pickup_lng || !t.dropoff_lat || !t.dropoff_lng) return
  try {
    await gmaps.ensureGoogle()
    if (!mapContainer.value) return
    const map = gmaps.createMap(mapContainer.value, {
      zoom: 12,
      center: { lat: Number(t.pickup_lat), lng: Number(t.pickup_lng) },
    })
    // Pickup marker (green A)
    const pickupMarker = new google.maps.Marker({
      map, position: { lat: Number(t.pickup_lat), lng: Number(t.pickup_lng) },
      label: { text: 'A', color: '#fff', fontWeight: 'bold' },
      icon: { path: google.maps.SymbolPath.CIRCLE, scale: 14, fillColor: '#22c55e', fillOpacity: 1, strokeColor: '#fff', strokeWeight: 2, labelOrigin: new google.maps.Point(0, 0) },
    })
    // Dropoff marker (red B)
    const dropoffMarker = new google.maps.Marker({
      map, position: { lat: Number(t.dropoff_lat), lng: Number(t.dropoff_lng) },
      label: { text: 'B', color: '#fff', fontWeight: 'bold' },
      icon: { path: google.maps.SymbolPath.CIRCLE, scale: 14, fillColor: '#ef4444', fillOpacity: 1, strokeColor: '#fff', strokeWeight: 2, labelOrigin: new google.maps.Point(0, 0) },
    })
    const pickupInfo = new google.maps.InfoWindow({ content: `<div style="font-weight:600">${t.pickup_name || 'Pickup'}</div><div style="color:#666;font-size:12px">${t.pickup_address || ''}</div>` })
    const dropoffInfo = new google.maps.InfoWindow({ content: `<div style="font-weight:600">${t.dropoff_name || 'Drop-off'}</div><div style="color:#666;font-size:12px">${t.dropoff_address || ''}</div>` })
    pickupMarker.addListener('click', () => pickupInfo.open(map, pickupMarker))
    dropoffMarker.addListener('click', () => dropoffInfo.open(map, dropoffMarker))
    // Draw driving route
    const result = await gmaps.getDirections(
      { lat: Number(t.pickup_lat), lng: Number(t.pickup_lng) },
      { lat: Number(t.dropoff_lat), lng: Number(t.dropoff_lng) },
    )
    if (result) {
      const directionsRenderer = new google.maps.DirectionsRenderer({ suppressMarkers: true, polylineOptions: { strokeColor: '#3b82f6', strokeWeight: 4 } })
      directionsRenderer.setMap(map)
      directionsRenderer.setDirections(result)
      const leg = result.routes?.[0]?.legs?.[0]
      if (leg) {
        if (leg.distance?.text) {
          const km = (leg.distance.value / 1000).toFixed(2)
          routeDistance.value = `${km} km`
        }
        if (leg.duration?.text) routeDuration.value = leg.duration.text
      }
      // Fit bounds to show both markers
      const bounds = new google.maps.LatLngBounds()
      bounds.extend({ lat: Number(t.pickup_lat), lng: Number(t.pickup_lng) })
      bounds.extend({ lat: Number(t.dropoff_lat), lng: Number(t.dropoff_lng) })
      map.fitBounds(bounds, 60)
    }
  } catch (e) {
    console.error('Map build error:', e)
  }
}

async function loadOptions() {
  try {
    const { $api } = useNuxtApp()
    const [vData, dData]: any = await Promise.all([
      $api('/vehicles/vehicles/', { query: { page_size: 100 } }),
      $api('/contacts/drivers/', { query: { page_size: 100 } }),
    ])
    const vItems = vData.results || vData
    const dItems = dData.results || dData
    availableVehicles.value = vItems.map((v: any) => ({ label: v.display_name || v.license_plate, value: v.id }))
    availableDrivers.value = dItems.map((d: any) => ({ label: d.full_name, value: d.id }))
  } catch { /* ignore */ }
}

async function doAction(action: 'start' | 'pickup' | 'complete' | 'cancel' | 'no_show') {
  actionLoading.value = true
  try {
    let reason = ''
    if (action === 'cancel') {
      const res = await $swal.fire({ icon: 'warning', title: 'Cancel Transfer?', input: 'text', inputLabel: 'Reason (optional)', showCancelButton: true, confirmButtonText: 'Confirm Cancel', confirmButtonColor: '#ef4444' })
      if (!res.isConfirmed) { actionLoading.value = false; return }
      reason = res.value || ''
    }
    const fn = {
      start: api.startTransfer,
      pickup: api.pickupTransfer,
      complete: api.completeTransfer,
      cancel: (id: number) => api.cancelTransfer(id, reason),
      no_show: api.noShowTransfer,
    }[action]
    await fn(transferId.value)
    $swal.fire({ icon: 'success', title: 'Updated', timer: 1500, toast: true, position: 'top-end', showConfirmButton: false })
    await loadTransfer()
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Error', text: e?.data?.detail || 'Action failed.' })
  } finally { actionLoading.value = false }
}

async function doAssign() {
  try {
    await api.assignTransfer(transferId.value, assignVehicle.value, assignDriver.value)
    $swal.fire({ icon: 'success', title: 'Assigned', timer: 1500, toast: true, position: 'top-end', showConfirmButton: false })
    await loadTransfer()
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Assign Failed', text: e?.data?.detail || 'Failed.' })
  }
}

async function doRecordPayment() {
  if (!paymentAmount.value || paymentAmount.value <= 0) {
    $swal.fire({ icon: 'warning', title: 'Invalid', text: 'Enter a valid amount.' }); return
  }
  paying.value = true
  try {
    await api.recordPayment(transferId.value, paymentAmount.value, paymentMethod.value, paymentReference.value)
    $swal.fire({ icon: 'success', title: 'Payment Recorded', timer: 2000, toast: true, position: 'top-end', showConfirmButton: false })
    paymentDialog.value = false
    paymentAmount.value = 0; paymentReference.value = ''
    await loadTransfer()
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Payment Failed', text: e?.data?.detail || 'Failed.' })
  } finally { paying.value = false }
}

function printTransfer() { window.print() }
function goBack() { navigateTo('/app/transfers') }

// ── Helpers ──
function formatDate(d: string) { return d ? new Date(d).toLocaleDateString(undefined, { month: 'short', day: 'numeric' }) : '--' }
function formatTime(d: string) { return d ? new Date(d).toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' }) : '--' }
function formatDateTime(d: string) { return d ? new Date(d).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' }) : '--' }
function statusColor(s: string) { const m: Record<string,string> = { draft: 'grey', scheduled: 'info', assigned: 'primary', en_route: 'warning', picked_up: 'orange-darken-2', completed: 'success', cancelled: 'error', no_show: 'grey-darken-1' }; return m[s] || 'grey' }
function statusLabel(s: string) { const m: Record<string,string> = { draft: 'Draft', scheduled: 'Scheduled', assigned: 'Assigned', en_route: 'En Route', picked_up: 'Picked Up', completed: 'Completed', cancelled: 'Cancelled', no_show: 'No Show' }; return m[s] || s }
function classLabel(c: string) { const m: Record<string,string> = { economy: 'Economy', business: 'Business', premium: 'Premium', luxury: 'Luxury', van: 'Van / Minibus', executive: 'Executive' }; return m[c] || c }
function classColor(c: string) { const m: Record<string,string> = { economy: 'grey', business: 'primary', premium: 'info', luxury: 'purple', van: 'teal', executive: 'indigo-darken-2' }; return m[c] || 'grey' }
function tripLabel(t: string) { const m: Record<string,string> = { one_way: 'One-Way', round_trip: 'Round Trip', hourly: 'Hourly Hire' }; return m[t] || t }

onMounted(async () => { await Promise.all([loadTransfer(), loadOptions()]) })
</script>

<style scoped>
.page-header-bar { display: flex; align-items: center; justify-content: space-between; padding: 10px 16px; background: #ffffff; border: 1px solid #e2e8f0; border-radius: 12px; }
.page-header-title { color: #0f172a; letter-spacing: -0.01em; }
.route-header { background: linear-gradient(135deg, #3b82f6, #1d4ed8); border-radius: 8px 8px 0 0; }
.passenger-header { background: linear-gradient(135deg, #6366f1, #4338ca); border-radius: 8px 8px 0 0; }
.lifecycle-header { background: linear-gradient(135deg, #f59e0b, #d97706); border-radius: 8px 8px 0 0; }
.route-dot { width: 14px; height: 14px; border-radius: 50%; flex-shrink: 0; }
.route-dot-stop { width: 10px; height: 10px; border-radius: 50%; background: #3b82f6; flex-shrink: 0; border: 2px solid #fff; box-shadow: 0 0 0 1px #cbd5e1; }
.route-line { height: 2px; background: #e2e8f0; margin-left: 6px; margin: 4px 0 4px 6px; }
.transfer-route-map { width: 100%; height: 400px; border-radius: 0 0 8px 8px; }
.map-header { background: linear-gradient(135deg, #3b82f6, #1d4ed8); border-radius: 8px 8px 0 0; }
</style>
