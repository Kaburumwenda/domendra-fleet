<template>
  <div>
    <!-- Mobile logo -->
    <div class="d-flex align-center ga-2 mb-6 d-md-none">
      <div class="auth-mobile-logo">
        <img src="/logo.png" alt="DomendraFleet" style="width: 100%; height: 100%; object-fit: contain; border-radius: 8px;" />
      </div>
      <span class="text-h6 font-weight-bold" style="color: rgb(var(--v-theme-on-surface))">DomendraFleet</span>
    </div>

    <div class="mb-6">
      <h2 class="auth-page-title">Get started</h2>
      <p class="auth-page-subtitle">Create your DomendraFleet account in minutes</p>
    </div>

    <!-- Step indicator -->
    <div class="auth-steps mb-6">
      <div class="auth-step" :class="{ 'auth-step--active': step >= 1, 'auth-step--done': step > 1 }">
        <div class="auth-step-circle">1</div>
        <span class="auth-step-label">Company</span>
      </div>
      <div class="auth-step-connector" :class="{ 'auth-step-connector--active': step > 1 }" />
      <div class="auth-step" :class="{ 'auth-step--active': step >= 2 }">
        <div class="auth-step-circle">2</div>
        <span class="auth-step-label">Admin</span>
      </div>
    </div>

    <v-alert v-if="serverError" type="error" variant="tonal" density="comfortable" class="mb-5 rounded-lg">
      <template #prepend><v-icon>mdi-alert-circle-outline</v-icon></template>
      {{ serverError }}
    </v-alert>

    <form @submit.prevent="handleRegister" class="d-flex flex-column ga-5">
      <!-- Step 1: Company -->
      <template v-if="step === 1">
        <v-row dense class="ga-3">
          <v-col cols="12" sm="6">
            <label class="auth-field-label">Short Name <span class="auth-required">*</span></label>
            <v-text-field
              v-model="form.short_name"
              placeholder="ACME"
              prepend-inner-icon="mdi-tag-outline"
              variant="outlined"
              density="comfortable"
              color="primary"
              rounded="lg"
              hide-details="auto"
              :error-messages="errors.short_name"
              class="auth-input"
            />
          </v-col>
          <v-col cols="12" sm="6">
            <label class="auth-field-label">Full Name <span class="auth-required">*</span></label>
            <v-text-field
              v-model="form.full_name"
              placeholder="ACME Logistics Inc."
              prepend-inner-icon="mdi-domain"
              variant="outlined"
              density="comfortable"
              color="primary"
              rounded="lg"
              hide-details="auto"
              :error-messages="errors.full_name"
              class="auth-input"
            />
          </v-col>
        </v-row>

        <div>
          <label class="auth-field-label">Country <span class="auth-required">*</span></label>
          <CountrySelect v-model="form.country" density="comfortable" />
          <div v-if="errors.country" class="auth-field-error">{{ errors.country }}</div>
        </div>

        <div>
          <label class="auth-field-label">Mobile <span class="auth-required">*</span></label>
          <PhoneInput v-model="form.mobile_number" :country-name="form.country" density="comfortable" />
          <div v-if="errors.mobile_number" class="auth-field-error">{{ errors.mobile_number }}</div>
        </div>

        <div>
          <label class="auth-field-label">Address <span class="auth-required">*</span></label>
          <v-text-field
            ref="addressInput"
            v-model="form.address"
            placeholder="Search your address..."
            prepend-inner-icon="mdi-map-marker-outline"
            variant="outlined"
            density="comfortable"
            color="primary"
            rounded="lg"
            hide-details="auto"
            :error-messages="errors.address"
            class="auth-input"
            @update:model-value="onAddressInput"
          >
            <template #append-inner>
              <v-tooltip location="top" text="Use my current location">
                <template #activator="{ props: tooltipProps }">
                  <v-icon
                    v-bind="tooltipProps"
                    size="20"
                    color="#6366f1"
                    :class="{ 'mdi-spin': locating }"
                    :icon="locating ? 'mdi-loading' : 'mdi-crosshairs-gps'"
                    @click="useLiveLocation"
                  />
                </template>
              </v-tooltip>
              <v-tooltip location="top" text="Pick on map">
                <template #activator="{ props: tooltipProps }">
                  <v-icon
                    v-bind="tooltipProps"
                    size="20"
                    color="#6366f1"
                    icon="mdi-map-marker-radius-outline"
                    class="ml-2"
                    @click="openMapPicker"
                  />
                </template>
              </v-tooltip>
            </template>
          </v-text-field>
          <div v-if="addressCoords" class="auth-coords-hint">
            <v-icon size="14" color="#22c55e">mdi-check-circle</v-icon>
            {{ addressCoords.lat.toFixed(5) }}, {{ addressCoords.lng.toFixed(5) }}
          </div>
        </div>

        <v-btn
          class="auth-submit-btn mt-2"
          size="large"
          elevation="0"
          rounded="lg"
          block
          @click="goToStep2"
        >
          Continue
          <v-icon end>mdi-arrow-right</v-icon>
        </v-btn>
      </template>

      <!-- Step 2: Admin Account -->
      <template v-if="step === 2">
        <p class="auth-section-hint">
          <v-icon size="18" style="vertical-align: middle; margin-right: 4px">mdi-account-tie</v-icon>
          This will be your first administrator login.
        </p>

        <v-row dense class="ga-3">
          <v-col cols="6">
            <label class="auth-field-label">First Name <span class="auth-required">*</span></label>
            <v-text-field
              v-model="form.first_name"
              placeholder="John"
              prepend-inner-icon="mdi-account-outline"
              variant="outlined"
              density="comfortable"
              color="primary"
              rounded="lg"
              hide-details="auto"
              :error-messages="errors.first_name"
              class="auth-input"
            />
          </v-col>
          <v-col cols="6">
            <label class="auth-field-label">Last Name <span class="auth-required">*</span></label>
            <v-text-field
              v-model="form.last_name"
              placeholder="Doe"
              prepend-inner-icon="mdi-account-outline"
              variant="outlined"
              density="comfortable"
              color="primary"
              rounded="lg"
              hide-details="auto"
              :error-messages="errors.last_name"
              class="auth-input"
            />
          </v-col>
        </v-row>

        <div>
          <label class="auth-field-label">Email <span class="auth-required">*</span></label>
          <v-text-field
            v-model="form.email"
            type="email"
            placeholder="you@company.com"
            prepend-inner-icon="mdi-email-outline"
            variant="outlined"
            density="comfortable"
            color="primary"
            rounded="lg"
            hide-details="auto"
            :error-messages="errors.email"
            class="auth-input"
          />
        </div>

        <div>
          <label class="auth-field-label">Password <span class="auth-required">*</span></label>
          <v-text-field
            v-model="form.password"
            :type="showPassword ? 'text' : 'password'"
            :append-inner-icon="showPassword ? 'mdi-eye-off' : 'mdi-eye'"
            @click:append-inner="showPassword = !showPassword"
            placeholder="Min. 8 characters"
            prepend-inner-icon="mdi-lock-outline"
            variant="outlined"
            density="comfortable"
            color="primary"
            rounded="lg"
            hide-details="auto"
            :error-messages="errors.password"
            class="auth-input"
          />
        </div>

        <div class="d-flex ga-3 mt-2">
          <v-btn
            variant="text"
            size="large"
            rounded="lg"
            @click="step = 1"
            prepend-icon="mdi-arrow-left"
            class="auth-back-btn"
          >
            Back
          </v-btn>
          <v-btn
            type="submit"
            class="auth-submit-btn flex-grow-1"
            prepend-icon="mdi-account-plus"
            :loading="loading"
            :disabled="loading"
            size="large"
            elevation="0"
            rounded="lg"
            block
          >
            Create Account
          </v-btn>
        </div>
      </template>
    </form>

    <p class="text-center mt-7 auth-switch-link">
      Already have an account?
      <NuxtLink to="/login">Sign in</NuxtLink>
    </p>

    <!-- Map Picker Dialog -->
    <v-dialog v-model="mapDialog" max-width="700" persistent>
      <v-card rounded="xl" class="pa-0">
        <v-card-title class="d-flex align-center justify-space-between pa-4">
          <span class="text-h6 font-weight-bold">Pick your location</span>
          <v-btn icon variant="text" size="small" @click="mapDialog = false">
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-card-title>
        <v-card-text class="pa-4 pt-0">
          <v-text-field
            v-model="mapSearch"
            placeholder="Search for a place..."
            prepend-inner-icon="mdi-magnify"
            density="comfortable"
            variant="outlined"
            rounded="lg"
            hide-details
            class="mb-3"
            @keyup.enter="searchOnMap"
          >
            <template #append-inner>
              <v-icon color="#6366f1" icon="mdi-magnify" @click="searchOnMap" />
            </template>
          </v-text-field>
          <div ref="mapContainer" class="auth-map-container" />
          <div v-if="pickedAddress" class="auth-picked-address mt-3">
            <v-icon size="18" color="#6366f1">mdi-map-marker</v-icon>
            <span>{{ pickedAddress }}</span>
          </div>
        </v-card-text>
        <v-card-actions class="pa-4 pt-0">
          <v-btn variant="text" @click="useLiveLocationInMap" :loading="locating" prepend-icon="mdi-crosshairs-gps">
            My location
          </v-btn>
          <v-spacer />
          <v-btn variant="text" @click="mapDialog = false">Cancel</v-btn>
          <v-btn class="auth-submit-btn" size="default" rounded="lg" elevation="0" @click="confirmMapPick">
            Confirm
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'auth' })

const auth = useAuthStore()
const { attachAutocomplete, ensureGoogle, geocodeAddress, reverseGeocode, getCurrentPosition, createMap } = useGoogleMaps()
const showPassword = ref(false)
const loading = ref(false)
const serverError = ref('')
const step = ref(1)
const errors = reactive<Record<string, string>>({})

const form = reactive({
  short_name: '',
  full_name: '',
  country: '',
  mobile_number: '',
  address: '',
  latitude: null as number | null,
  longitude: null as number | null,
  first_name: '',
  last_name: '',
  email: '',
  password: '',
})

// ---- Address autocomplete ----
const addressInput = ref<any>(null)
const addressCoords = ref<{ lat: number; lng: number } | null>(null)
let addressAutocomplete: any = null

function getAddressInputEl(): HTMLInputElement | null {
  const inst: any = addressInput.value
  if (!inst) return null
  const el: HTMLElement = inst.$el || inst.el || inst
  return (el.querySelector?.('input') as HTMLInputElement) || (el as HTMLInputElement)
}

async function setupAddressAutocomplete() {
  try {
    await ensureGoogle()
    await nextTick()
    const inputEl = getAddressInputEl()
    if (!inputEl) return
    if (addressAutocomplete) {
      try { (window as any).google?.maps?.event?.clearInstanceListeners(addressAutocomplete) } catch {}
    }
    addressAutocomplete = await attachAutocomplete(inputEl, {
      types: ['geocode'],
      onPlace: handlePlaceSelected,
    })
  } catch (e) {
    // Autocomplete not available — manual entry still works
  }
}

function handlePlaceSelected(place: any) {
  if (!place || !place.geometry) return
  const lat = place.geometry.location.lat()
  const lng = place.geometry.location.lng()
  form.latitude = lat
  form.longitude = lng
  addressCoords.value = { lat, lng }
  form.address = place.formatted_address || place.name || ''
}

function onAddressInput(val: string) {
  // If user manually edits address after a place was picked, clear stored coords
  if (addressCoords.value && val !== form.address) {
    // v-model already updates form.address, so this covers manual typing
  }
}

// ---- Map picker ----
const mapDialog = ref(false)
const mapSearch = ref('')
const mapContainer = ref<HTMLElement | null>(null)
const pickedAddress = ref('')
const pickedPos = ref<{ lat: number; lng: number } | null>(null)
let mapInstance: any = null
let mapMarker: any = null

async function openMapPicker() {
  mapSearch.value = form.address || ''
  pickedAddress.value = ''
  pickedPos.value = null
  mapDialog.value = true
  await nextTick()
  await ensureGoogle()
  let center = { lat: form.latitude || 0, lng: form.longitude || 0 }
  if (!form.latitude && !form.longitude) {
    try {
      center = await getCurrentPosition()
    } catch {
      center = { lat: -1.2921, lng: 36.8219 } // Nairobi fallback
    }
  }
  if (!mapContainer.value) return
  mapInstance = createMap(mapContainer.value, center, 15)
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
  try {
    const addr = await reverseGeocode(pos.lat, pos.lng)
    pickedAddress.value = addr
  } catch {
    pickedAddress.value = ''
  }
}

async function searchOnMap() {
  if (!mapSearch.value || !mapInstance) return
  try {
    const res = await geocodeAddress(mapSearch.value)
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
  addressCoords.value = { lat: pickedPos.value.lat, lng: pickedPos.value.lng }
  if (pickedAddress.value) form.address = pickedAddress.value
  mapDialog.value = false
}

// ---- Live location ----
const locating = ref(false)

async function useLiveLocation() {
  locating.value = true
  try {
    const pos = await getCurrentPosition()
    form.latitude = pos.lat
    form.longitude = pos.lng
    addressCoords.value = pos
    const addr = await reverseGeocode(pos.lat, pos.lng)
    form.address = addr || `(${pos.lat.toFixed(5)}, ${pos.lng.toFixed(5)})`
  } catch (e: any) {
    errors.address = e?.message || 'Could not get your current location.'
  } finally {
    locating.value = false
  }
}

async function useLiveLocationInMap() {
  locating.value = true
  try {
    const pos = await getCurrentPosition()
    if (mapInstance && mapMarker) {
      mapInstance.setCenter(pos)
      setMarkerPos(pos)
      updatePickedAddress(pos)
    }
  } catch (e: any) {
    // ignore
  } finally {
    locating.value = false
  }
}

// Attach autocomplete when step 1 is shown
watch(step, (s) => {
  if (s === 1) nextTick(() => setupAddressAutocomplete())
})

onMounted(() => {
  nextTick(() => setupAddressAutocomplete())
})

function goToStep2() {
  errors.short_name = ''
  errors.full_name = ''
  errors.country = ''
  errors.mobile_number = ''
  errors.address = ''

  let valid = true
  if (!form.short_name.trim()) { errors.short_name = 'Short name is required'; valid = false }
  if (!form.full_name.trim()) { errors.full_name = 'Full name is required'; valid = false }
  if (!form.country.trim()) { errors.country = 'Country is required'; valid = false }
  if (!form.mobile_number.trim()) { errors.mobile_number = 'Mobile number is required'; valid = false }
  if (!form.address.trim()) { errors.address = 'Address is required'; valid = false }
  if (valid) step.value = 2
}

async function handleRegister() {
  errors.first_name = ''
  errors.last_name = ''
  errors.email = ''
  errors.password = ''
  serverError.value = ''

  let valid = true
  if (!form.first_name.trim()) { errors.first_name = 'First name is required'; valid = false }
  if (!form.last_name.trim()) { errors.last_name = 'Last name is required'; valid = false }
  if (!form.email.trim()) { errors.email = 'Email is required'; valid = false }
  else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) { errors.email = 'Enter a valid email'; valid = false }
  if (!form.password) { errors.password = 'Password is required'; valid = false }
  else if (form.password.length < 8) { errors.password = 'Password must be at least 8 characters'; valid = false }
  if (!valid) return

  loading.value = true
  try {
    await auth.register(form)
    await navigateTo('/app')
  } catch (e: any) {
    serverError.value = e?.data?.detail || e?.data?.email?.[0] || 'Registration failed. Please check your details.'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.auth-page-title {
  font-size: 26px;
  font-weight: 750;
  color: rgb(var(--v-theme-on-surface));
  letter-spacing: -0.02em;
  line-height: 1.2;
}

.auth-page-subtitle {
  font-size: 15px;
  color: rgba(var(--v-theme-on-surface), 0.6);
  margin-top: 4px;
}

.auth-field-label {
  display: block;
  font-size: 13px;
  font-weight: 600;
  color: rgba(var(--v-theme-on-surface), 0.7);
  margin-bottom: 8px;
}

.auth-required {
  color: #ef4444;
  margin-left: 2px;
}

.auth-field-error {
  font-size: 12px;
  color: #ef4444;
  margin-top: 6px;
  padding-left: 4px;
}

.auth-input :deep(.v-field--variant-outlined .v-field__outline__start),
.auth-input :deep(.v-field--variant-outlined .v-field__outline__notch),
.auth-input :deep(.v-field--variant-outlined .v-field__outline__end) {
  border-color: rgba(var(--v-theme-on-surface), 0.2);
}

.auth-input :deep(.v-field--variant-outlined:hover .v-field__outline__start),
.auth-input :deep(.v-field--variant-outlined:hover .v-field__outline__notch),
.auth-input :deep(.v-field--variant-outlined:hover .v-field__outline__end) {
  border-color: #c7d2fe;
}

.auth-input :deep(.v-field--variant-outlined .v-field__outline__start),
.auth-input :deep(.v-field--variant-outlined .v-field__outline__notch),
.auth-input :deep(.v-field--variant-outlined .v-field__outline__end),
.auth-input :deep(.v-field__input) {
  color: rgb(var(--v-theme-on-surface));
}

.auth-input :deep(.v-field--variant-outlined .v-field__input) {
  color: rgb(var(--v-theme-on-surface));
}

.auth-submit-btn {
  text-transform: none !important;
  font-weight: 600 !important;
  font-size: 15px !important;
  letter-spacing: 0.01em !important;
  height: 50px !important;
  background: linear-gradient(135deg, #6366f1, #4f46e5) !important;
  color: #fff !important;
  box-shadow: 0 4px 16px rgba(99, 102, 241, 0.3) !important;
  transition: transform 0.15s ease, box-shadow 0.15s ease !important;
}

.auth-submit-btn:hover:not(:disabled) {
  box-shadow: 0 8px 24px rgba(99, 102, 241, 0.4) !important;
  transform: translateY(-1px);
}

.auth-back-btn {
  text-transform: none !important;
  font-weight: 600 !important;
  color: rgba(var(--v-theme-on-surface), 0.6) !important;
}

.auth-switch-link {
  font-size: 14px;
  color: rgba(var(--v-theme-on-surface), 0.6);
}

.auth-switch-link a {
  color: #6366f1;
  font-weight: 600;
  text-decoration: none;
}

.auth-switch-link a:hover {
  text-decoration: underline;
}

.auth-mobile-logo {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: rgba(99, 102, 241, 0.08);
  display: flex;
  align-items: center;
  justify-content: center;
}

.auth-section-hint {
  font-size: 13px;
  color: rgba(var(--v-theme-on-surface), 0.7);
  background: rgba(var(--v-theme-on-surface), 0.06);
  border-radius: 10px;
  padding: 10px 14px;
  margin: 0;
}

/* ---- Stepper ---- */
.auth-steps {
  display: flex;
  align-items: center;
  gap: 8px;
}

.auth-step {
  display: flex;
  align-items: center;
  gap: 8px;
}

.auth-step-circle {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  border: 2px solid rgba(var(--v-theme-on-surface), 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 13px;
  font-weight: 700;
  color: rgba(var(--v-theme-on-surface), 0.4);
  transition: all 0.25s ease;
}

.auth-step-label {
  font-size: 13px;
  font-weight: 600;
  color: rgba(var(--v-theme-on-surface), 0.4);
  transition: color 0.25s ease;
}

.auth-step--active .auth-step-circle {
  border-color: #6366f1;
  color: #6366f1;
  background: #eef2ff;
}

.auth-step--active .auth-step-label {
  color: #6366f1;
}

.auth-step--done .auth-step-circle {
  background: #6366f1;
  border-color: #6366f1;
  color: #fff;
}

.auth-step--done .auth-step-label {
  color: rgba(var(--v-theme-on-surface), 0.7);
}

.auth-step-connector {
  flex: 1;
  height: 2px;
  background: rgba(var(--v-theme-on-surface), 0.2);
  border-radius: 1px;
  transition: background 0.25s ease;
}

.auth-step-connector--active {
  background: #6366f1;
}

/* ---- Address picker ---- */
.auth-coords-hint {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: #22c55e;
  margin-top: 6px;
  padding-left: 4px;
}

.auth-map-container {
  width: 100%;
  height: 320px;
  border-radius: 12px;
  border: 1px solid rgba(var(--v-theme-on-surface), 0.2);
  overflow: hidden;
}

.auth-picked-address {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 14px;
  color: rgba(var(--v-theme-on-surface), 0.7);
  background: rgba(var(--v-theme-on-surface), 0.06);
  border-radius: 8px;
  padding: 10px 12px;
}
</style>
