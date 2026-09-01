<template>
  <div class="customer-new-page">
    <!-- Premium header bar -->
    <v-card rounded="xl" class="overflow-hidden customer-new-card" elevation="0" border>
      <div class="cn-page-header">
        <div class="cn-header-top">
          <div class="d-flex align-center ga-3">
            <v-btn icon variant="text" size="small" dark @click="goBack">
              <v-icon>mdi-arrow-left</v-icon>
            </v-btn>
            <div class="header-icon">
              <v-icon size="26" color="white">mdi-account-plus-outline</v-icon>
            </div>
            <div>
              <h2 class="text-h6 font-weight-bold text-white" style="line-height: 1.2">
                {{ editingId ? 'Edit Customer' : 'New Customer' }}
              </h2>
              <p class="text-caption text-white" style="opacity: 0.85">
                Capture personal details &amp; verify documents
              </p>
            </div>
          </div>

          <!-- Progress stepper -->
          <div class="stepper-row stepper-row--inline d-none d-lg-flex mt-0">
            <div
              v-for="(step, i) in steps"
              :key="i"
              class="stepper-item"
              :class="{ active: activeStep >= i, done: activeStep > i, 'flex-grow-1': i < steps.length - 1 }"
              @click="activeStep = i"
            >
              <div class="step-badge" :class="{ active: activeStep >= i, done: activeStep > i }">
                <v-icon size="14">{{ activeStep > i ? 'mdi-check' : `mdi-numeric-${i + 1}` }}</v-icon>
              </div>
              <span class="step-label">{{ step }}</span>
              <div v-if="i < steps.length - 1" class="step-connector" :class="{ filled: activeStep > i }" />
            </div>
          </div>
        </div>

        <!-- Progress stepper (stacked on mobile) -->
        <div class="stepper-row mt-5 d-flex d-lg-none">
          <div
            v-for="(step, i) in steps"
            :key="i"
            class="stepper-item"
            :class="{ active: activeStep >= i, done: activeStep > i, 'flex-grow-1': i < steps.length - 1 }"
            @click="activeStep = i"
          >
            <div class="step-badge" :class="{ active: activeStep >= i, done: activeStep > i }">
              <v-icon size="14">{{ activeStep > i ? 'mdi-check' : `mdi-numeric-${i + 1}` }}</v-icon>
            </div>
            <span class="step-label">{{ step }}</span>
            <div v-if="i < steps.length - 1" class="step-connector" :class="{ filled: activeStep > i }" />
          </div>
        </div>
      </div>

      <v-card-text class="pa-6 pa-md-8" style="max-height: 72vh; overflow-y: auto;">
        <!-- Step 0: Personal Information -->
        <div v-show="activeStep === 0">
          <div class="section-label">
            <v-icon size="18" color="primary">mdi-account-details-outline</v-icon>
            Personal Information
          </div>
          <v-row dense class="mt-2">
            <v-col cols="12" md="6" lg="4">
              <v-select
                v-model="form.customer_type"
                :items="customerTypeOptions"
                item-title="label" item-value="value"
                label="Customer Type *" density="comfortable" variant="outlined"
                prepend-inner-icon="mdi-account-eye-outline"
                hide-details="auto"
              />
            </v-col>
            <v-col cols="12" md="6" lg="4">
              <v-text-field
                v-model="form.full_name"
                label="Full Name *" density="comfortable" variant="outlined"
                prepend-inner-icon="mdi-account"
                hide-details="auto"
                :rules="[v => !!v || 'Full name is required']"
              />
            </v-col>
            <v-col cols="12" md="6" lg="4">
              <v-text-field
                v-model="form.email"
                label="Email" density="comfortable" variant="outlined"
                prepend-inner-icon="mdi-email-outline"
                hide-details="auto"
              />
            </v-col>
            <v-col cols="12" md="6" lg="4">
              <v-text-field
                v-model="form.phone"
                label="Phone *" density="comfortable" variant="outlined"
                prepend-inner-icon="mdi-phone-outline"
                hide-details="auto"
                :rules="[v => !!v || 'Phone number is required']"
              />
            </v-col>
            <v-col cols="12" md="6" lg="4">
              <v-text-field
                v-model="form.date_of_birth"
                type="date" label="Date of Birth" density="comfortable" variant="outlined"
                prepend-inner-icon="mdi-cake-variant-outline"
                hide-details="auto"
              />
            </v-col>
            <v-col cols="12" md="6" lg="4">
              <CountrySelect
                v-model="form.country"
                label="Country of Residence *"
                density="comfortable"
                variant="outlined"
                :rules="[v => !!v || 'Country is required']"
                @update:code="(c: string) => (form.country_code = c)"
              />
            </v-col>
            <v-col cols="12">
              <v-text-field
                ref="addressInputRef"
                v-model="form.address"
                label="Address *" density="comfortable" variant="outlined"
                prepend-inner-icon="mdi-map-marker-outline"
                hide-details="auto"
                autocomplete="off"
                placeholder="Start typing an address…"
                :rules="[v => !!v || 'Address is required']"
              >
                <template #append-inner>
                  <v-progress-circular v-if="addressLoading" indeterminate size="16" width="2" color="primary" />
                </template>
              </v-text-field>
              <div v-if="form.latitude && form.longitude" class="text-caption text-medium-emphasis mt-1 ml-1">
                <v-icon size="12" class="mb-1">mdi-crosshairs-gps</v-icon>
                {{ form.latitude }}, {{ form.longitude }}
              </div>
            </v-col>
          </v-row>

          <div class="section-label mt-6">
            <v-icon size="18" color="primary">mdi-shield-account-outline</v-icon>
            Emergency Contact
          </div>
          <v-row dense class="mt-2">
            <v-col cols="12" md="6" lg="4">
              <v-text-field
                v-model="form.emergency_contact_name"
                label="Emergency Contact Name" density="comfortable" variant="outlined"
                prepend-inner-icon="mdi-account-alert-outline"
                hide-details="auto"
              />
            </v-col>
            <v-col cols="12" md="6" lg="4">
              <v-text-field
                v-model="form.emergency_contact_phone"
                label="Emergency Contact Phone" density="comfortable" variant="outlined"
                prepend-inner-icon="mdi-phone-alert-outline"
                hide-details="auto"
              />
            </v-col>
          </v-row>
        </div>

        <!-- Step 1: Identification -->
        <div v-show="activeStep === 1">
          <div class="section-label">
            <v-icon size="18" color="primary">mdi-card-account-details-outline</v-icon>
            Identification Details
          </div>
          <v-row dense class="mt-2">
            <v-col cols="12" md="6" lg="4">
              <v-select
                v-model="form.id_type"
                :items="idTypeOptions"
                item-title="label" item-value="value"
                label="ID Type *" density="comfortable" variant="outlined"
                prepend-inner-icon="mdi-card-account-details-outline"
                hide-details="auto"
              />
            </v-col>
            <v-col cols="12" md="6" lg="4">
              <v-text-field
                v-model="form.id_number"
                label="ID Number *" density="comfortable" variant="outlined"
                prepend-inner-icon="mdi-identifier"
                hide-details="auto"
                :rules="[v => !!v || 'ID number is required']"
              />
            </v-col>
            <v-col cols="12" md="6" lg="4">
              <v-text-field
                v-model="form.driving_license_no"
                label="Driving License No. *" density="comfortable" variant="outlined"
                prepend-inner-icon="mdi-card-bulleted-outline"
                hide-details="auto"
                :rules="[v => !!v || 'Driving license number is required']"
              />
            </v-col>
            <v-col cols="12" md="6" lg="4">
              <CountrySelect
                v-model="form.license_issued_country"
                label="License Issued Country *"
                density="comfortable"
                variant="outlined"
                :rules="[v => !!v || 'License issued country is required']"
                @update:code="(c: string) => (form.license_country_code = c)"
              />
            </v-col>
            <v-col cols="12" md="6" lg="4">
              <v-text-field
                v-model="form.license_expiry"
                type="date" label="License Expiry *" density="comfortable" variant="outlined"
                prepend-inner-icon="mdi-calendar-clock-outline"
                hide-details="auto"
                :rules="[v => !!v || 'License expiry date is required']"
              />
            </v-col>
          </v-row>

          <!-- Document image uploads -->
          <div class="section-label mt-6">
            <v-icon size="18" color="primary">mdi-image-multiple-outline</v-icon>
            Document Images
          </div>
          <p class="text-caption text-medium-emphasis mb-3">
            Drag &amp; drop or click to upload. Supported: JPG, PNG (max 5MB each).
          </p>
          <v-row dense>
            <v-col cols="12" sm="6" md="3" lg="3" xl="3">
              <ImageDropZone
                v-model="files.passport_photo"
                :existing-url="resolveMediaUrl(form.passport_photo)"
                label="Passport Photo"
                icon="mdi-face-recognition-outline"
                hint="Passport-size portrait"
                aspect="portrait"
                @remove-existing="onRemoveExisting('passport_photo')"
              />
            </v-col>
            <v-col cols="12" sm="6" md="3" lg="3" xl="3">
              <ImageDropZone
                v-model="files.id_front_image"
                :existing-url="resolveMediaUrl(form.id_front_image)"
                label="ID — Front"
                icon="mdi-card-bulleted-outline"
                hint="Front side of ID"
                aspect="landscape"
                @remove-existing="onRemoveExisting('id_front_image')"
              />
            </v-col>
            <v-col cols="12" sm="6" md="3" lg="3" xl="3">
              <ImageDropZone
                v-model="files.id_back_image"
                :existing-url="resolveMediaUrl(form.id_back_image)"
                label="ID — Back"
                icon="mdi-card-bulleted-off-outline"
                hint="Back side of ID"
                aspect="landscape"
                @remove-existing="onRemoveExisting('id_back_image')"
              />
            </v-col>
            <v-col cols="12" sm="6" md="3" lg="3" xl="3">
              <ImageDropZone
                v-model="files.driving_license_image"
                :existing-url="resolveMediaUrl(form.driving_license_image)"
                label="Driving License"
                icon="mdi-license-outline"
                hint="Both sides in one image"
                aspect="landscape"
                @remove-existing="onRemoveExisting('driving_license_image')"
              />
            </v-col>
          </v-row>
        </div>

        <!-- Step 2: Review -->
        <div v-show="activeStep === 2">
          <div class="section-label">
            <v-icon size="18" color="primary">mdi-clipboard-check-outline</v-icon>
            Review &amp; Confirm
          </div>
          <v-row dense class="mt-2">
            <v-col cols="12" md="6" lg="4">
              <div class="review-card">
                <div class="review-title">
                  <v-icon size="16" color="primary">mdi-account-details-outline</v-icon>
                  Personal
                </div>
                <div v-if="hasDoc('passport_photo')" class="d-flex align-center ga-3 mb-3 pb-3" style="border-bottom: 1px dashed #e2e8f0;">
                  <v-avatar size="48" rounded="lg" color="primary" variant="tonal">
                    <img v-if="docPreviews.find(d => d.key === 'passport_photo')" :src="docPreviews.find(d => d.key === 'passport_photo')?.url" style="width:100%; height:100%; object-fit:cover; border-radius:8px;" />
                    <span v-else style="opacity: 0.5;">N/A</span>
                  </v-avatar>
                  <div>
                    <div class="text-body-2 font-weight-bold">{{ form.full_name || '—' }}</div>
                    <div class="text-caption text-medium-emphasis text-capitalize">{{ form.customer_type }} customer</div>
                  </div>
                </div>
                <div class="review-row" v-if="!hasDoc('passport_photo')"><span>Name</span><b>{{ form.full_name || '—' }}</b></div>
                <div class="review-row" v-if="!hasDoc('passport_photo')"><span>Type</span><b class="text-capitalize">{{ form.customer_type }}</b></div>
                <div class="review-row"><span>Phone</span><b>{{ form.phone || '—' }}</b></div>
                <div class="review-row"><span>Email</span><b>{{ form.email || '—' }}</b></div>
                <div class="review-row"><span>Address</span><b class="text-right">{{ form.address || '—' }}</b></div>
                <div class="review-row"><span>Country</span><b>{{ form.country || '—' }}</b></div>
                <div class="review-row"><span>DOB</span><b>{{ form.date_of_birth || '—' }}</b></div>
                <div class="review-row"><span>Emergency</span><b>{{ form.emergency_contact_name || '—' }}</b></div>
              </div>
            </v-col>
            <v-col cols="12" md="6" lg="4">
              <div class="review-card">
                <div class="review-title">
                  <v-icon size="16" color="primary">mdi-card-account-details-outline</v-icon>
                  Identification
                </div>
                <div class="review-row"><span>ID Type</span><b class="text-capitalize">{{ (form.id_type || '').replace('_', ' ') }}</b></div>
                <div class="review-row"><span>ID Number</span><b>{{ form.id_number || '—' }}</b></div>
                <div class="review-row"><span>License No.</span><b>{{ form.driving_license_no || '—' }}</b></div>
                <div class="review-row"><span>Issued Country</span><b>{{ form.license_issued_country || '—' }}</b></div>
                <div class="review-row"><span>Expiry</span><b>{{ form.license_expiry || '—' }}</b></div>
              </div>
            </v-col>
            <v-col cols="12" md="6" lg="4">
              <div class="review-card">
                <div class="review-title">
                  <v-icon size="16" color="primary">mdi-image-multiple-outline</v-icon>
                  Documents
                </div>
                <div class="review-row">
                  <span>Passport</span>
                  <v-chip size="x-small" :color="hasDoc('passport_photo') ? 'success' : 'grey'" variant="flat">
                    {{ hasDoc('passport_photo') ? 'Uploaded' : 'None' }}
                  </v-chip>
                </div>
                <div class="review-row">
                  <span>ID Front</span>
                  <v-chip size="x-small" :color="hasDoc('id_front_image') ? 'success' : 'grey'" variant="flat">
                    {{ hasDoc('id_front_image') ? 'Uploaded' : 'None' }}
                  </v-chip>
                </div>
                <div class="review-row">
                  <span>ID Back</span>
                  <v-chip size="x-small" :color="hasDoc('id_back_image') ? 'success' : 'grey'" variant="flat">
                    {{ hasDoc('id_back_image') ? 'Uploaded' : 'None' }}
                  </v-chip>
                </div>
                <div class="review-row">
                  <span>License</span>
                  <v-chip size="x-small" :color="hasDoc('driving_license_image') ? 'success' : 'grey'" variant="flat">
                    {{ hasDoc('driving_license_image') ? 'Uploaded' : 'None' }}
                  </v-chip>
                </div>
              </div>
            </v-col>
          </v-row>

          <!-- Document preview thumbnails -->
          <div v-if="docPreviews.length" class="d-flex ga-3 mt-4 flex-wrap">
            <div
              v-for="doc in docPreviews"
              :key="doc.key"
              class="preview-thumb"
              :style="{ backgroundImage: `url(${doc.url})` }"
            >
              <div class="preview-label">{{ doc.label }}</div>
            </div>
          </div>
        </div>
      </v-card-text>

      <v-divider />
      <div class="cn-footer px-6 py-4 d-flex align-center">
        <v-btn variant="text" :disabled="activeStep === 0" @click="activeStep--">
          <v-icon start>mdi-arrow-left</v-icon> Back
        </v-btn>
        <v-spacer />
        <v-btn variant="text" @click="goBack">Cancel</v-btn>
        <v-btn
          v-if="activeStep < steps.length - 1"
          color="primary" variant="flat" class="ml-2"
          @click="nextStep"
        >
          Continue <v-icon end>mdi-arrow-right</v-icon>
        </v-btn>
        <v-btn
          v-else
          color="primary" variant="flat" class="ml-2"
          prepend-icon="mdi-check"
          :loading="saving"
          @click="save"
        >
          Save Customer
        </v-btn>
      </div>
    </v-card>
  </div>
</template>

<script setup lang="ts">
import ImageDropZone from '~/components/rentals/ImageDropZone.vue'

definePageMeta({ layout: 'default' })

const { $api, $swal } = useNuxtApp()
const { resolveMediaUrl } = useMediaUrl()
const { attachAutocomplete } = useGoogleMaps()
const router = useRouter()

const route = useRoute()
const editingId = computed(() => route.query.edit ? Number(route.query.edit) : null)

const steps = ['Personal', 'Identification', 'Review']
const activeStep = ref(0)
const saving = ref(false)

const formDefault = {
  customer_type: 'local', full_name: '', email: '', phone: '',
  address: '', place_name: '', latitude: null as number | null, longitude: null as number | null,
  country: 'Kenya', country_code: 'KE',
  id_type: 'national_id', id_number: '', driving_license_no: '',
  license_issued_country: '', license_country_code: '',
  license_expiry: null as string | null, date_of_birth: null as string | null,
  emergency_contact_name: '', emergency_contact_phone: '',
  passport_photo: '', id_front_image: '', id_back_image: '', driving_license_image: '',
}
const form = reactive<any>({ ...formDefault })
const files = reactive<any>({ passport_photo: null, id_front_image: null, id_back_image: null, driving_license_image: null })
const removedImages = reactive<Record<string, boolean>>({ passport_photo: false, id_front_image: false, id_back_image: false, driving_license_image: false })

const customerTypeOptions = [
  { label: 'Local', value: 'local' },
  { label: 'Foreigner', value: 'foreigner' },
]
const idTypeOptions = [
  { label: 'National ID', value: 'national_id' },
  { label: 'Passport', value: 'passport' },
  { label: "Driver's License", value: 'driver_license' },
  { label: 'Alien Card', value: 'alien_card' },
]

const addressInputRef = ref<any>(null)
const addressLoading = ref(false)
let addressAutocomplete: any = null

function goBack() {
  router.push('/app/rentals?tab=customers')
}

function onRemoveExisting(key: string) {
  form[key] = ''
  removedImages[key] = true
}

function hasDoc(key: string) {
  return !!(files[key] || form[key])
}

const docPreviews = computed(() => {
  const docs = [
    { key: 'passport_photo', label: 'Passport' },
    { key: 'id_front_image', label: 'ID Front' },
    { key: 'id_back_image', label: 'ID Back' },
    { key: 'driving_license_image', label: 'License' },
  ]
  return docs
    .filter((d) => files[d.key] || form[d.key])
    .map((d) => {
      const file = files[d.key]
      const url = file ? URL.createObjectURL(file) : resolveMediaUrl(form[d.key])
      return { ...d, url }
    })
})

function nextStep() {
  if (activeStep.value === 0) {
    const missing = [
      { key: 'full_name', label: 'Full name' },
      { key: 'phone', label: 'Phone number' },
      { key: 'address', label: 'Address' },
      { key: 'country', label: 'Country of residence' },
    ].filter((f) => !form[f.key])
    if (missing.length) {
      $swal.fire({ icon: 'warning', title: `${missing[0].label} is required`, toast: true, timer: 1800, position: 'top-end' })
      return
    }
    if (!/^\S+@\S+\.\S+$/.test(form.email) && !form.email) {
      // email optional but if provided validate format
    }
  }
  if (activeStep.value === 1) {
    const missing = [
      { key: 'id_number', label: 'ID number' },
      { key: 'driving_license_no', label: 'Driving license number' },
      { key: 'license_issued_country', label: 'License issued country' },
      { key: 'license_expiry', label: 'License expiry date' },
    ].filter((f) => !form[f.key])
    if (missing.length) {
      $swal.fire({ icon: 'warning', title: `${missing[0].label} is required`, toast: true, timer: 1800, position: 'top-end' })
      return
    }
  }
  activeStep.value = Math.min(activeStep.value + 1, steps.length - 1)
}

async function save() {
  const missing = [
    { key: 'full_name', label: 'Full name' },
    { key: 'phone', label: 'Phone number' },
    { key: 'address', label: 'Address' },
    { key: 'country', label: 'Country of residence' },
    { key: 'id_number', label: 'ID number' },
    { key: 'driving_license_no', label: 'Driving license number' },
    { key: 'license_issued_country', label: 'License issued country' },
    { key: 'license_expiry', label: 'License expiry date' },
  ].filter((f) => !form[f.key])
  if (missing.length) {
    $swal.fire({ icon: 'warning', title: `${missing[0].label} is required`, toast: true, timer: 1800, position: 'top-end' })
    return
  }
  saving.value = true
  try {
    const fd = new FormData()
    const scalarFields = [
      'customer_type', 'full_name', 'email', 'phone', 'address', 'place_name',
      'latitude', 'longitude', 'country', 'country_code',
      'id_type', 'id_number', 'driving_license_no', 'license_issued_country', 'license_country_code',
      'license_expiry', 'date_of_birth', 'emergency_contact_name', 'emergency_contact_phone',
    ]
    for (const key of scalarFields) {
      const val = form[key]
      if (val !== null && val !== undefined && val !== '') {
        fd.append(key, String(val))
      }
    }
    const imageFields = ['passport_photo', 'id_front_image', 'id_back_image', 'driving_license_image']
    for (const key of imageFields) {
      const f = files[key] as File | null
      if (f) {
        fd.append(key, f)
      } else if (editingId.value && removedImages[key]) {
        fd.append(key, '')
      }
    }
    if (editingId.value) {
      await $api(`/rentals/customers/${editingId.value}/`, { method: 'PATCH', body: fd })
    } else {
      await $api('/rentals/customers/', { method: 'POST', body: fd })
    }
    $swal.fire({ icon: 'success', title: 'Customer saved', toast: true, timer: 1500, position: 'top-end' })
    goBack()
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Save failed', text: e?.data?.detail || e?.message || '', toast: true, timer: 2500, position: 'top-end' })
  } finally {
    saving.value = false
  }
}

// Load existing customer if editing
async function loadExisting() {
  if (!editingId.value) return
  try {
    const c = await $api(`/rentals/customers/${editingId.value}/`)
    Object.assign(form, c)
  } catch {
    $swal.fire({ icon: 'error', title: 'Failed to load customer', toast: true, timer: 2000, position: 'top-end' })
    goBack()
  }
}

onMounted(async () => {
  await loadExisting()

  // Attach Google Places autocomplete to the address input
  await nextTick()
  try {
    addressLoading.value = true
    const nativeInput = (addressInputRef.value as any)?.$el?.querySelector?.('input') as HTMLInputElement | null
    if (nativeInput) {
      addressAutocomplete = await attachAutocomplete(nativeInput, {
        types: ['geocode'],
        onPlace: (place: any) => {
          if (place?.formatted_address) {
            form.address = place.formatted_address
          }
          if (place?.name) {
            form.place_name = place.name
          } else if (place?.formatted_address) {
            form.place_name = place.formatted_address
          }
          if (place?.geometry?.location) {
            form.latitude = place.geometry.location.lat()
            form.longitude = place.geometry.location.lng()
          }
        },
      })
    }
  } catch {
    // Google Maps not available — address still works as a manual text field
  } finally {
    addressLoading.value = false
  }
})

onBeforeUnmount(() => {
  if (addressAutocomplete && typeof addressAutocomplete.remove === 'function') {
    addressAutocomplete.remove()
  }
})
</script>

<style scoped>
.customer-new-page {
  width: 100%;
}

.cn-page-header {
  background: linear-gradient(135deg, #4f46e5 0%, #6366f1 50%, #818cf8 100%);
  padding: 22px 28px;
}

.cn-header-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
  flex-wrap: wrap;
}

.stepper-row--inline {
  min-width: 320px;
  flex: 1;
  max-width: 520px;
}

.header-icon {
  width: 46px;
  height: 46px;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.15);
  display: flex;
  align-items: center;
  justify-content: center;
  backdrop-filter: blur(4px);
}

.stepper-row {
  display: flex;
  align-items: center;
  gap: 0;
}
.stepper-item {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
}
.stepper-item.flex-grow-1 {
  flex: 1;
}

.step-badge {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.15);
  color: white;
  transition: all 0.3s;
  flex-shrink: 0;
}
.step-badge.active {
  background: white;
  color: #4f46e5;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
}
.step-badge.done {
  background: #10b981;
  color: white;
}
.step-label {
  font-size: 0.8rem;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.9);
  white-space: nowrap;
}
.step-connector {
  flex: 1;
  height: 2px;
  background: rgba(255, 255, 255, 0.2);
  margin-left: 10px;
  border-radius: 2px;
  transition: all 0.3s;
}
.step-connector.filled {
  background: rgba(255, 255, 255, 0.6);
}

.section-label {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.82rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #475569;
  margin-bottom: 4px;
  padding-bottom: 6px;
  border-bottom: 1px solid #f1f5f9;
}

.review-card {
  border: 1px solid #e2e8f0;
  border-radius: 14px;
  padding: 16px;
  background: #f8fafc;
  height: 100%;
  transition: box-shadow 0.2s;
}
.review-card:hover {
  box-shadow: 0 2px 12px rgba(79, 70, 229, 0.08);
}
.review-title {
  display: flex;
  align-items: center;
  gap: 6px;
  font-weight: 700;
  font-size: 0.85rem;
  margin-bottom: 12px;
  color: #1e293b;
}
.review-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.82rem;
  padding: 5px 0;
  border-bottom: 1px dashed #e2e8f0;
  gap: 8px;
}
.review-row:last-child {
  border-bottom: none;
}
.review-row span {
  color: #94a3b8;
  white-space: nowrap;
}

.preview-thumb {
  width: 130px;
  height: 100px;
  border-radius: 10px;
  background-size: cover;
  background-position: center;
  border: 1px solid #e2e8f0;
  position: relative;
  overflow: hidden;
  transition: transform 0.2s, box-shadow 0.2s;
}
.preview-thumb:hover {
  transform: scale(1.04);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}
.preview-label {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  background: rgba(0, 0, 0, 0.55);
  color: white;
  font-size: 0.65rem;
  padding: 2px 6px;
  text-align: center;
}

.cn-footer {
  background: #f8fafc;
}

/* Sticky footer within the card */
.customer-new-card {
  display: flex;
  flex-direction: column;
}
.customer-new-card > .v-card-text {
  flex: 1 1 auto;
}

/* Wider spacing on large screens */
@media (min-width: 1280px) {
  .section-label {
    font-size: 0.85rem;
  }
}
</style>
