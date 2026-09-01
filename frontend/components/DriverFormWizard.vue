<template>
  <v-stepper v-model="step" editable flat min-height="280">
    <v-stepper-header>
      <v-stepper-item value="1" title="Personal" subtitle="Identity & contact" icon="mdi-account-outline" />
      <v-divider />
      <v-stepper-item value="2" title="License & Medical" subtitle="Credentials & documents" icon="mdi-card-bulleted-outline" />
      <v-divider />
      <v-stepper-item value="3" title="Employment" subtitle="Status & pay" icon="mdi-briefcase-outline" />
    </v-stepper-header>

    <v-stepper-window v-model="step">
      <!-- Step 1: Personal -->
      <v-stepper-window-item value="1">
        <v-row dense class="mt-2">
          <v-col cols="12" class="d-flex align-center ga-4 mb-2">
            <div class="driver-avatar-upload" :style="{ background: avatarBg }">
              <img v-if="photoPreview" :src="photoPreview" alt="preview" />
              <v-icon v-else size="32" color="primary">mdi-camera</v-icon>
            </div>
            <div>
              <v-btn size="small" variant="tonal" prepend-icon="mdi-upload" @click="$refs.photoInput.click()">Upload Photo</v-btn>
              <p class="text-caption text-medium-emphasis mt-1">JPG/PNG, max 5MB</p>
            </div>
            <input ref="photoInput" type="file" accept="image/*" class="d-none" @change="onPhotoChange" />
          </v-col>
          <v-col cols="6"><v-text-field v-model="form.first_name" label="First Name *" /></v-col>
          <v-col cols="6"><v-text-field v-model="form.last_name" label="Last Name *" /></v-col>
          <v-col cols="6"><v-text-field v-model="form.date_of_birth" type="date" label="Date of Birth" /></v-col>
          <v-col cols="6"><v-text-field v-model="form.employee_id" label="Employee ID" /></v-col>
          <v-col cols="6"><v-text-field v-model="form.email" label="Email" type="email" /></v-col>
          <v-col cols="6"><v-text-field v-model="form.phone" label="Phone" /></v-col>
          <v-col cols="6"><v-text-field v-model="form.department" label="Department" /></v-col>
          <v-col cols="6"><CountrySelect v-model="form.country" label="Country" density="compact" variant="outlined" hide-details /></v-col>
          <v-col cols="12">
            <v-text-field
              ref="addressInput"
              v-model="form.address"
              label="Address (start typing to search)"
              prepend-inner-icon="mdi-map-marker"
              autocomplete="off"
              @input="onAddressInput"
            />
          </v-col>
          <v-col cols="4"><v-text-field v-model="form.city" label="City" /></v-col>
          <v-col cols="4"><v-text-field v-model="form.state" label="State / Province" /></v-col>
          <v-col cols="4"><v-text-field v-model="form.zip_code" label="ZIP / Postal Code" /></v-col>
        </v-row>
      </v-stepper-window-item>

      <!-- Step 2: License & Medical -->
      <v-stepper-window-item value="2">
        <v-row dense class="mt-2">
          <v-col cols="6"><v-text-field v-model="profile.license_number" label="License Number" /></v-col>
          <v-col cols="6">
            <v-combobox
              v-model="profile.license_class"
              :items="licenseClasses"
              item-title="label"
              item-value="value"
              label="License Class"
              chips
              closable-chips
              hint="Select or type a custom class (e.g. AB)"
              persistent-hint
            />
          </v-col>
          <v-col cols="6"><CountrySelect v-model="profile.license_state" label="Issuing State / Country" density="compact" variant="outlined" hide-details /></v-col>
          <v-col cols="6"><v-text-field v-model="profile.license_expiry" type="date" label="License Expiry" /></v-col>
          <v-col cols="12"><v-select v-model="profile.license_endorsements" :items="endorsementOptions" item-title="label" item-value="value" label="Endorsements" multiple chips closable-chips /></v-col>
          <v-col cols="6"><v-text-field v-model="profile.medical_card_number" label="Medical Card #" /></v-col>
          <v-col cols="6"><v-text-field v-model="profile.medical_card_expiry" type="date" label="Medical Card Expiry" /></v-col>
          <v-col cols="6"><v-select v-model="profile.mvr_status" :items="mvrStatuses" item-title="label" item-value="value" label="MVR Status" /></v-col>
          <v-col cols="6"><v-text-field v-model="profile.mvr_last_checked" type="date" label="MVR Last Checked" /></v-col>
          <v-col cols="6"><v-text-field v-model="profile.mvr_next_due" type="date" label="MVR Next Due" /></v-col>
        </v-row>

        <!-- Document uploads: Driving License & National ID -->
        <v-row dense class="mt-4">
          <v-col cols="12">
            <span class="text-subtitle-2 font-weight-medium" style="color: #475569">Document Uploads</span>
            <p class="text-caption text-medium-emphasis">Upload or drag &amp; drop files (PDF, JPG, PNG). Saved to the document vault.</p>
          </v-col>
          <v-col cols="12" md="6">
            <FileDropZone
              label="Driving License"
              icon="mdi-card-account-details-outline"
              :file="licenseFile"
              accept=".pdf,.jpg,.jpeg,.png"
              @upload="(f: File) => onDocFile('license', f)"
              @remove="() => removeDoc('license')"
            />
          </v-col>
          <v-col cols="12" md="6">
            <FileDropZone
              label="National ID"
              icon="mdi-card-account-details-star-outline"
              :file="nationalIdFile"
              accept=".pdf,.jpg,.jpeg,.png"
              @upload="(f: File) => onDocFile('national_id', f)"
              @remove="() => removeDoc('national_id')"
            />
          </v-col>
        </v-row>
      </v-stepper-window-item>

      <!-- Step 3: Employment -->
      <v-stepper-window-item value="3">
        <v-row dense class="mt-2">
          <v-col cols="6"><v-select v-model="profile.employment_status" :items="employmentStatuses" item-title="label" item-value="value" label="Employment Status" /></v-col>
          <v-col cols="6"><v-text-field v-model="profile.hire_date" type="date" label="Hire Date" /></v-col>
          <v-col cols="6"><v-text-field v-model="profile.termination_date" type="date" label="Termination Date" /></v-col>
          <v-col cols="6"><v-text-field v-model="profile.home_terminal" label="Home Terminal" /></v-col>
          <v-col cols="4"><v-text-field v-model="profile.pay_rate" type="number" label="Pay Rate" /></v-col>
          <v-col cols="4"><v-select v-model="profile.pay_type" :items="payTypes" item-title="label" item-value="value" label="Pay Type" /></v-col>
          <v-divider class="my-3" />
          <v-col cols="12"><span class="text-subtitle-2 font-weight-medium" style="color: #475569">Emergency Contact</span></v-col>
          <v-col cols="6"><v-text-field v-model="profile.emergency_contact_name" label="Contact Name" /></v-col>
          <v-col cols="6"><v-text-field v-model="profile.emergency_contact_phone" label="Contact Phone" /></v-col>
          <v-col cols="6"><v-text-field v-model="profile.emergency_contact_relation" label="Relationship" /></v-col>
          <v-col cols="6"><v-text-field v-model="profile.blood_type" label="Blood Type" /></v-col>
          <v-col cols="12"><v-textarea v-model="form.notes" label="Notes" rows="3" /></v-col>
        </v-row>
      </v-stepper-window-item>
    </v-stepper-window>

    <div class="d-flex justify-space-between align-center mt-4 px-2">
      <v-btn variant="text" :disabled="step === '1'" @click="step = String(Math.max(1, Number(step) - 1))">Back</v-btn>
      <div class="d-flex ga-2">
        <v-btn v-if="step !== '3'" color="primary" @click="step = String(Number(step) + 1)">Continue</v-btn>
        <v-btn v-else color="primary" prepend-icon="mdi-check" :loading="saving" @click="submit">{{ props.driver ? 'Update Driver' : 'Create Driver' }}</v-btn>
      </div>
    </div>
  </v-stepper>
</template>

<script setup lang="ts">
const props = defineProps<{ driver?: any | null }>()
const emit = defineEmits<{ saved: [id: string | number]; cancel: [] }>()

const { $api } = useNuxtApp()
const { resolveMediaUrl } = useMediaUrl()
const gmaps = useGoogleMaps()

const step = ref('1')
const saving = ref(false)
const photoInput = ref<HTMLInputElement | null>(null)
const photoPreview = ref('')
let photoFile: File | null = null

// Address autocomplete
const addressInput = ref<any>(null)
let autocomplete: any = null

// Document uploads
const licenseFile = ref<File | null>(null)
const nationalIdFile = ref<File | null>(null)

const defaultForm = () => ({
  contact_type: 'driver', first_name: '', last_name: '', date_of_birth: '', employee_id: '',
  email: '', phone: '', department: '', country: '', address: '', city: '', state: '', zip_code: '',
  notes: '', is_active: true,
})
const form = reactive<any>(defaultForm())

const defaultProfile = () => ({
  license_number: '', license_class: '', license_state: '', license_expiry: '',
  license_endorsements: [], medical_card_number: '', medical_card_expiry: '',
  mvr_status: 'clean', mvr_last_checked: '', mvr_next_due: '', employment_status: 'active',
  hire_date: '', termination_date: '', home_terminal: '', pay_rate: 0, pay_type: 'hourly',
  emergency_contact_name: '', emergency_contact_phone: '', emergency_contact_relation: '', blood_type: '',
})
const profile = reactive<any>(defaultProfile())

const licenseClasses = [
  { label: 'Class A', value: 'A' }, { label: 'Class B', value: 'B' }, { label: 'Class C', value: 'C' },
  { label: 'Class AB', value: 'AB' }, { label: 'Class B Auto', value: 'B Auto' },
  { label: 'CDL-A', value: 'CDL-A' }, { label: 'CDL-B', value: 'CDL-B' }, { label: 'Class M', value: 'M' },
]
const endorsementOptions = [
  { label: 'Hazmat (H)', value: 'hazmat' }, { label: 'Tanker (N)', value: 'tanker' },
  { label: 'Passenger (P)', value: 'passenger' }, { label: 'School Bus (S)', value: 'school_bus' },
  { label: 'Air Brake (L)', value: 'airbrake' }, { label: 'Tanker + Hazmat (X)', value: 'comb_tanker_hazmat' },
]
const mvrStatuses = [
  { label: 'Clean', value: 'clean' }, { label: 'Warning', value: 'warning' },
  { label: 'Suspended', value: 'suspended' }, { label: 'Expired', value: 'expired' },
]
const employmentStatuses = [
  { label: 'Active', value: 'active' }, { label: 'On Leave', value: 'on_leave' },
  { label: 'Suspended', value: 'suspended' }, { label: 'Terminated', value: 'terminated' },
  { label: 'Probation', value: 'probation' },
]
const payTypes = [
  { label: 'Hourly', value: 'hourly' },
  { label: 'Daily', value: 'daily' },
  { label: 'Weekly', value: 'weekly' },
  { label: 'Mileage', value: 'mileage' },
  { label: 'Salary', value: 'salary' },
  { label: 'Percentage', value: 'percentage' },
  { label: 'Locum', value: 'locum' },
]

const avatarBg = computed(() => {
  const colors = ['#e0e7ff', '#dcfce7', '#fef9c3', '#fee2e2', '#f3e8ff', '#cffafe']
  const idx = (form.first_name?.charCodeAt(0) || 0) % colors.length
  return colors[idx]
})

// ---- Edit mode: populate from driver prop ----
watchEffect(() => {
  if (!props.driver) return
  const d = props.driver
  Object.keys(form).forEach(k => { if (d[k] !== undefined) form[k] = d[k] })
  if (d.photo) photoPreview.value = resolveMediaUrl(d.photo)
  if (d.driver_profile) {
    Object.keys(profile).forEach(k => {
      if (d.driver_profile[k] !== undefined && d.driver_profile[k] !== null) profile[k] = d.driver_profile[k]
    })
  }
})

// ---- Handlers ----
function onPhotoChange(e: Event) {
  const target = e.target as HTMLInputElement
  const file = target.files?.[0]
  if (!file) return
  photoFile = file
  photoPreview.value = URL.createObjectURL(file)
}

async function onAddressInput() {
  if (autocomplete || !addressInput.value) return
  try {
    const el = addressInput.value.$el?.querySelector?.('input') || addressInput.value.$el
    if (!el || !(el instanceof HTMLInputElement)) return
    autocomplete = await gmaps.attachAutocomplete(el, {
      types: ['geocode'],
      onPlace: (place: any) => {
        if (!place?.address_components) return
        form.address = place.formatted_address || form.address
        const get = (types: string[]) => place.address_components.find((c: any) => types.some((t) => c.types.includes(t)))
        const street = get(['street_number', 'route'])
        const city = get(['locality', 'postal_town', 'administrative_area_level_2'])
        const state = get(['administrative_area_level_1'])
        const zip = get(['postal_code'])
        const country = get(['country'])
        if (street) form.address = [street.long_name, ''].join(' ').trim() || form.address
        if (city) form.city = city.long_name
        if (state) form.state = state.long_name
        if (zip) form.zip_code = zip.long_name
        if (country) form.country = country.long_name
        if (place.formatted_address) form.address = place.formatted_address
      },
    })
  } catch (e) {
    console.warn('Google Places autocomplete unavailable, falling back to manual entry', e)
  }
}

function onDocFile(type: 'license' | 'national_id', file: File) {
  if (type === 'license') licenseFile.value = file
  else nationalIdFile.value = file
}
function removeDoc(type: 'license' | 'national_id') {
  if (type === 'license') licenseFile.value = null
  else nationalIdFile.value = null
}

// ---- Submit ----
function buildBody() {
  // Normalize combobox value: if license_class is an object, extract the value; keep string as-is
  const lc = profile.license_class
  const licenseClassVal = lc && typeof lc === 'object' ? (lc.value ?? lc.label ?? '') : (lc ?? '')

  const driverProfile: any = {
    license_number: profile.license_number,
    license_class: licenseClassVal,
    license_state: profile.license_state,
    license_expiry: profile.license_expiry,
    license_endorsements: profile.license_endorsements || [],
    medical_card_number: profile.medical_card_number,
    medical_card_expiry: profile.medical_card_expiry,
    mvr_status: profile.mvr_status,
    mvr_last_checked: profile.mvr_last_checked,
    mvr_next_due: profile.mvr_next_due,
    employment_status: profile.employment_status,
    hire_date: profile.hire_date,
    termination_date: profile.termination_date,
    home_terminal: profile.home_terminal,
    pay_rate: profile.pay_rate,
    pay_type: profile.pay_type,
    emergency_contact_name: profile.emergency_contact_name,
    emergency_contact_phone: profile.emergency_contact_phone,
    emergency_contact_relation: profile.emergency_contact_relation,
    blood_type: profile.blood_type,
  }
  // Clean empty date strings → null
  Object.keys(driverProfile).forEach(k => {
    if (driverProfile[k] === '' && ['license_expiry', 'medical_card_expiry', 'mvr_last_checked', 'mvr_next_due', 'hire_date', 'termination_date'].includes(k)) {
      driverProfile[k] = null
    }
  })

  const body: any = {
    contact_type: 'driver',
    first_name: form.first_name,
    last_name: form.last_name,
    date_of_birth: form.date_of_birth || null,
    employee_id: form.employee_id,
    email: form.email,
    phone: form.phone,
    department: form.department,
    country: form.country,
    address: form.address,
    city: form.city,
    state: form.state,
    zip_code: form.zip_code,
    notes: form.notes,
    is_active: form.is_active,
    driver_profile: driverProfile,
  }
  return body
}

async function submit() {
  if (!form.first_name || !form.last_name) { alert('First and last name are required.'); return }
  saving.value = true
  try {
    const body = buildBody()
    const isFormData = !!photoFile
    let payload: any = body
    if (isFormData) {
      payload = new FormData()
      Object.keys(body).forEach(k => {
        if (k === 'driver_profile') {
          payload.append('driver_profile', JSON.stringify(body.driver_profile))
        } else if (Array.isArray(body[k])) {
          payload.append(k, JSON.stringify(body[k]))
        } else if (body[k] !== null && body[k] !== undefined) {
          payload.append(k, body[k])
        }
      })
      payload.append('photo', photoFile!)
    }

    let driverId: string | number = props.driver?.id || ''
    if (props.driver) {
      await $api(`/contacts/drivers/${props.driver.id}/`, { method: 'PUT', body: payload })
    } else {
      const created = await $api('/contacts/drivers/', { method: 'POST', body: payload })
      driverId = created.id
    }
    // Upload documents to the document vault, linked to the driver (contact)
    await uploadDoc(licenseFile.value, 'license', 'Driving License', driverId)
    await uploadDoc(nationalIdFile.value, 'license', 'National ID', driverId, true)
    emit('saved', driverId)
  } catch (e) {
    console.error(e)
    alert('Failed to save driver. Check the console for details.')
  } finally { saving.value = false }
}

async function uploadDoc(file: File | null, docType: string, title: string, contactId: string | number, isNationalId = false) {
  if (!file || !contactId) return
  const fd = new FormData()
  fd.append('contact', String(contactId))
  fd.append('document_type', isNationalId ? 'other' : docType)
  fd.append('title', `${title}${isNationalId ? ' (National ID)' : ''}`)
  fd.append('file', file)
  try {
    await $api('/documents/', { method: 'POST', body: fd })
  } catch (e) {
    console.error(`Failed to upload ${title}:`, e)
  }
}
</script>

<style scoped>
.driver-avatar-upload {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  border: 2px dashed #c7d2fe;
}
.driver-avatar-upload img { width: 100%; height: 100%; object-fit: cover; }
</style>
