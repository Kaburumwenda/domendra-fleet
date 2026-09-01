<template>
  <div class="d-flex flex-column ga-6">
    <h2 class="text-h6 font-weight-bold">Settings</h2>

    <v-card elevation="0" border class="pa-6">
      <h3 class="text-subtitle-1 font-weight-bold mb-4 d-flex align-center ga-2">
        <v-icon color="primary">mdi-office-building</v-icon> Organization
      </h3>
      <v-row dense>
        <v-col cols="6"><v-text-field v-model="tenant.short_name" label="Company Short Name" hint="Used in headers, sidebar & branding" persistent-hint /></v-col>
        <v-col cols="6"><v-text-field v-model="tenant.full_name" label="Company Full Name" hint="Legal / registered name" persistent-hint /></v-col>
        <v-col cols="6"><v-text-field v-model="tenant.email" label="Email" /></v-col>
        <v-col cols="6"><CountrySelect v-model="tenant.country" label="Country" /></v-col>
        <v-col cols="6"><PhoneInput v-model="tenant.mobile_number" :country-name="tenant.country" label="Mobile" /></v-col>
        <v-col cols="12"><v-text-field v-model="tenant.address" label="Address" /></v-col>
      </v-row>
      <div class="mt-4 d-flex align-center ga-3">
        <div class="d-flex align-center justify-center rounded-lg overflow-hidden" style="width: 64px; height: 64px; background: rgb(99 102 241 / 0.12)">
          <img v-if="logoUrl" :src="logoUrl" alt="logo" style="width: 100%; height: 100%; object-fit: contain" />
          <v-icon v-else color="primary" size="32">mdi-image</v-icon>
        </div>
        <div>
          <p class="text-body-2 font-weight-medium">White-labeling: Logo Upload</p>
          <p class="text-caption text-medium-emphasis mb-1">Upload your company logo for a branded experience</p>
          <div class="d-flex align-center ga-2">
            <v-btn size="small" variant="outlined" prepend-icon="mdi-upload" :loading="uploadingLogo" @click="pickLogo">Upload Logo</v-btn>
            <v-btn v-if="tenant.logo" size="small" variant="text" color="error" prepend-icon="mdi-delete-outline" @click="removeLogo">Remove</v-btn>
          </div>
          <input ref="logoInput" type="file" accept="image/*" class="d-none" @change="onLogoPicked" />
        </div>
      </div>
      <div class="d-flex justify-end mt-4">
        <v-btn color="primary" size="small" prepend-icon="mdi-content-save" @click="saveTenant" :loading="savingTenant">Save Organization</v-btn>
      </div>
    </v-card>

    <v-card elevation="0" border class="pa-6">
      <h3 class="text-subtitle-1 font-weight-bold mb-4 d-flex align-center ga-2">
        <v-icon color="info">mdi-account</v-icon> Your Profile
      </h3>
      <v-row dense>
        <v-col cols="6"><v-text-field v-model="profile.first_name" label="First Name" /></v-col>
        <v-col cols="6"><v-text-field v-model="profile.last_name" label="Last Name" /></v-col>
        <v-col cols="6"><v-text-field v-model="profile.email" label="Email" disabled /></v-col>
        <v-col cols="6"><v-text-field v-model="profile.phone" label="Phone" /></v-col>
      </v-row>
      <v-btn color="primary" size="small" class="mt-4" prepend-icon="mdi-check" @click="saveProfile" :loading="saving">Save Profile</v-btn>
    </v-card>
  </div>
</template>

<script setup lang="ts">
const { $api, $swal } = useNuxtApp()
const auth = useAuthStore()
const { patch: patchTenant } = useTenant()
const saving = ref(false)
const savingTenant = ref(false)

const profile = reactive<any>({
  first_name: auth.user?.first_name || '',
  last_name: auth.user?.last_name || '',
  email: auth.user?.email || '',
  phone: auth.user?.phone || '',
})

const tenant = reactive<any>({ short_name: '', full_name: '', email: '', country: '', mobile_number: '', address: '', currency: '', logo: '' })

const logoInput = ref<HTMLInputElement | null>(null)
const uploadingLogo = ref(false)
const apiBase = useRuntimeConfig().public.apiBase.replace(/\/$/, '')
const logoUrl = computed(() => tenant.logo ? (tenant.logo.startsWith('http') ? tenant.logo : `${apiBase.replace('/api', '')}${tenant.logo}`) : '')

function pickLogo() {
  logoInput.value?.click()
}

async function onLogoPicked(e: Event) {
  const input = e.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) return
  uploadingLogo.value = true
  try {
    const formData = new FormData()
    formData.append('logo', file)
    const data: any = await $api('/tenant/', { method: 'PATCH', body: formData })
    tenant.logo = data.logo
    patchTenant({ logo: data.logo || '' })
  } catch (err) { console.error(err) } finally {
    uploadingLogo.value = false
    input.value = ''
  }
}

async function removeLogo() {
  uploadingLogo.value = true
  try {
    const data: any = await $api('/tenant/', { method: 'PATCH', body: { logo: '' } })
    tenant.logo = data.logo || ''
    patchTenant({ logo: '' })
  } catch (err) { console.error(err) } finally {
    uploadingLogo.value = false
  }
}

useAsyncData('tenant-settings', () => $api('/tenant/').then((d: any) => {
  Object.assign(tenant, {
    short_name: d.short_name || '',
    full_name: d.full_name || '',
    email: d.email || '',
    country: d.country || '',
    mobile_number: d.mobile_number || '',
    address: d.address || '',
    currency: d.currency || '',
    logo: d.logo || '',
  })
  return d
}).catch(() => null))

async function saveTenant() {
  savingTenant.value = true
  try {
    await $api('/tenant/', {
      method: 'PATCH',
      body: {
        short_name: tenant.short_name,
        full_name: tenant.full_name,
        email: tenant.email,
        country: tenant.country,
        mobile_number: tenant.mobile_number,
        address: tenant.address,
      },
    })
    $swal.fire({ icon: 'success', title: 'Saved', text: 'Organization details updated.', timer: 1800, toast: true, position: 'top-end' })
    patchTenant({ short_name: tenant.short_name, full_name: tenant.full_name, logo: tenant.logo, loaded: true })
  } catch (e: any) {
    console.error(e)
    const msg = e?.data?.detail || e?.data?.name || e?.message || 'Could not save organization details.'
    $swal.fire({ icon: 'error', title: 'Save failed', text: typeof msg === 'string' ? msg : 'Please check your input and try again.' })
  } finally { savingTenant.value = false }
}

async function saveProfile() {
  saving.value = true
  try {
    await $api('/auth/me/', { method: 'PATCH', body: profile })
    auth.user = { ...auth.user, ...profile } as any
    if (import.meta.client) localStorage.setItem('fc_user', JSON.stringify(auth.user))
  } catch (e) { console.error(e) } finally { saving.value = false }
}
</script>
