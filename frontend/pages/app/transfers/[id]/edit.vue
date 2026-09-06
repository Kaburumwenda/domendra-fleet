<template>
  <div class="d-flex flex-column ga-4">
    <div class="page-header-bar">
      <div class="d-flex align-center ga-2">
        <v-btn icon="mdi-arrow-left" variant="text" size="small" @click="navigateTo(`/app/transfers/${transferId}`)" />
        <v-icon color="primary">mdi-pencil-outline</v-icon>
        <span class="text-h6 font-weight-bold page-header-title">Edit Transfer {{ transfer?.reference }}</span>
      </div>
    </div>

    <v-card elevation="0" border rounded="lg">
      <v-card-text class="pa-6">
        <v-row dense>
          <v-col cols="4">
            <v-text-field v-model="form.passenger_name" label="Passenger Name" density="comfortable" variant="outlined" hide-details />
          </v-col>
          <v-col cols="4"><v-text-field v-model="form.passenger_phone" label="Phone" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="4"><v-text-field v-model="form.passenger_email" label="Email" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="3"><v-text-field v-model.number="form.passenger_count" type="number" min="1" label="Passengers" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="3"><v-text-field v-model.number="form.luggage_count" type="number" min="0" label="Luggage" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="3"><v-checkbox v-model="form.has_child_seat" label="Child Seat" density="compact" hide-details /></v-col>
          <v-col cols="3"><v-checkbox v-model="form.has_infant_seat" label="Infant Seat" density="compact" hide-details /></v-col>
          <v-col cols="12"><v-textarea v-model="form.passenger_notes" label="Special Requests" rows="1" density="comfortable" variant="outlined" hide-details /></v-col>
        </v-row>

        <v-divider class="my-4" />

        <v-row dense>
          <v-col cols="6"><v-text-field v-model="form.pickup_name" label="Pickup Place Name" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="6"><v-text-field v-model="form.pickup_flight_no" label="Flight / Train No" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="8"><v-text-field v-model="form.pickup_address" label="Pickup Address" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="4"><v-text-field v-model="form.pickup_datetime" type="datetime-local" label="Pickup Date/Time" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="6"><v-text-field v-model="form.pickup_lat" type="number" label="Pickup Lat" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="6"><v-text-field v-model="form.pickup_lng" type="number" label="Pickup Lng" density="comfortable" variant="outlined" hide-details /></v-col>
        </v-row>

        <v-divider class="my-4" />

        <v-row dense>
          <v-col cols="8"><v-text-field v-model="form.dropoff_name" label="Drop-off Place Name" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="4"><v-text-field v-model="form.dropoff_datetime" type="datetime-local" label="Drop-off Time" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="12"><v-text-field v-model="form.dropoff_address" label="Drop-off Address" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="6"><v-text-field v-model="form.dropoff_lat" type="number" label="Drop-off Lat" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="6"><v-text-field v-model="form.dropoff_lng" type="number" label="Drop-off Lng" density="comfortable" variant="outlined" hide-details /></v-col>
        </v-row>

        <v-divider class="my-4" />

        <v-row dense>
          <v-col cols="3"><v-select v-model="form.service_class" :items="TRANSFER_SERVICE_CLASS_OPTIONS" item-title="title" item-value="value" label="Service Class" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="3"><v-select v-model="form.trip_type" :items="TRANSFER_TRIP_TYPE_OPTIONS" item-title="title" item-value="value" label="Trip Type" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="3">
            <v-select v-model="form.vehicle" :items="availableVehicles" item-title="label" item-value="value" label="Vehicle" density="comfortable" variant="outlined" hide-details clearable />
          </v-col>
          <v-col cols="3">
            <v-select v-model="form.driver" :items="availableDrivers" item-title="label" item-value="value" label="Driver" density="comfortable" variant="outlined" hide-details clearable />
          </v-col>
        </v-row>

        <v-divider class="my-4" />

        <v-row dense>
          <v-col cols="3"><v-text-field v-model.number="form.base_fare" type="number" label="Base Fare" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="3"><v-text-field v-model.number="form.distance_km" type="number" label="Distance (km)" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="3"><v-text-field v-model.number="form.estimated_duration_min" type="number" label="Duration (min)" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="3"><v-text-field v-model.number="form.tolls_amount" type="number" label="Tolls" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="3"><v-text-field v-model.number="form.parking_amount" type="number" label="Parking" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="3"><v-text-field v-model.number="form.meet_greet_fee" type="number" label="Meet & Greet" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="3"><v-text-field v-model.number="form.waiting_fee" type="number" label="Waiting Fee" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="3"><v-text-field v-model.number="form.child_seat_fee" type="number" label="Child Seat Fee" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="3"><v-text-field v-model.number="form.tax_amount" type="number" label="Tax" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="3"><v-text-field v-model.number="form.discount_amount" type="number" label="Discount" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="3"><v-text-field v-model.number="form.driver_tip" type="number" label="Tip" density="comfortable" variant="outlined" hide-details /></v-col>
          <v-col cols="3"><v-text-field v-model.number="form.amount_paid" type="number" label="Amount Paid" density="comfortable" variant="outlined" hide-details /></v-col>
        </v-row>

        <v-divider class="my-4" />

        <v-row dense>
          <v-col cols="6">
            <v-select v-model="form.status" :items="statusOptions" item-title="title" item-value="value" label="Status" density="comfortable" variant="outlined" hide-details />
          </v-col>
          <v-col cols="6">
            <v-select v-model="form.payment_method" :items="paymentMethodOptions" item-title="title" item-value="value" label="Payment Method" density="comfortable" variant="outlined" hide-details clearable />
          </v-col>
          <v-col cols="12"><v-textarea v-model="form.notes" label="Internal Notes" rows="2" density="comfortable" variant="outlined" hide-details /></v-col>
        </v-row>
      </v-card-text>
      <v-divider />
      <v-card-actions class="pa-4">
        <v-spacer />
        <v-btn variant="text" @click="navigateTo(`/app/transfers/${transferId}`)">Cancel</v-btn>
        <v-btn color="primary" prepend-icon="mdi-content-save" :loading="saving" @click="save">Save Changes</v-btn>
      </v-card-actions>
    </v-card>
  </div>
</template>

<script setup lang="ts">
import { TRANSFER_SERVICE_CLASS_OPTIONS, TRANSFER_TRIP_TYPE_OPTIONS, useTransferApi } from '~/composables/useTransferApi'

// Edit page for a transfer — editable form with Save Changes button
definePageMeta({ layout: 'default', permission: 'transfers:update' })

const route = useRoute()
const { $swal } = useNuxtApp()
const api = useTransferApi()

const transferId = computed(() => Number(route.params.id))
const transfer = ref<any>(null)
const saving = ref(false)

const availableVehicles = ref<any[]>([])
const availableDrivers = ref<any[]>([])

const statusOptions = [
  { title: 'Draft', value: 'draft' },
  { title: 'Scheduled', value: 'scheduled' },
  { title: 'Assigned', value: 'assigned' },
  { title: 'En Route', value: 'en_route' },
  { title: 'Picked Up', value: 'picked_up' },
  { title: 'Completed', value: 'completed' },
  { title: 'Cancelled', value: 'cancelled' },
  { title: 'No Show', value: 'no_show' },
]

const paymentMethodOptions = [
  { title: 'Cash', value: 'cash' },
  { title: 'Card', value: 'card' },
  { title: 'PayPal', value: 'paypal' },
  { title: 'Bank Transfer', value: 'bank_transfer' },
]

const form = reactive<any>({})

async function loadTransfer() {
  try {
    transfer.value = await api.fetchTransfer(transferId.value)
    Object.assign(form, transfer.value)
  } catch (e) {
    $swal.fire({ icon: 'error', title: 'Not Found', text: 'Transfer not found.' })
    navigateTo('/app/transfers')
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

async function save() {
  saving.value = true
  try {
    await api.updateTransfer(transferId.value, form)
    $swal.fire({ icon: 'success', title: 'Saved', timer: 2000, toast: true, position: 'top-end', showConfirmButton: false })
    navigateTo(`/app/transfers/${transferId.value}`)
  } catch (e: any) {
    let msg = 'Failed to save.'
    if (e?.data) {
      msg = typeof e.data === 'string' ? e.data : (e.data.detail || JSON.stringify(e.data))
    }
    $swal.fire({ icon: 'error', title: 'Error', text: msg })
  } finally { saving.value = false }
}

onMounted(async () => { await Promise.all([loadTransfer(), loadOptions()]) })
</script>

<style scoped>
.page-header-bar { display: flex; align-items: center; justify-content: space-between; padding: 10px 16px; background: #ffffff; border: 1px solid #e2e8f0; border-radius: 12px; }
.page-header-title { color: #0f172a; letter-spacing: -0.01em; }
</style>
