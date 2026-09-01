<template>
  <div class="customer-details-page">
    <!-- Loading state -->
    <div v-if="loading" class="d-flex justify-center align-center" style="min-height: 400px">
      <v-progress-circular indeterminate size="48" color="primary" />
    </div>

    <!-- Error state -->
    <div v-else-if="error" class="text-center py-16">
      <v-icon size="56" color="error" class="mb-4">mdi-alert-circle-outline</v-icon>
      <h3 class="text-h6 mb-2">Unable to Load Customer</h3>
      <p class="text-body-2 text-medium-emphasis mb-4">{{ error }}</p>
      <v-btn variant="tonal" color="primary" prepend-icon="mdi-arrow-left" @click="goBack">Back to Customers</v-btn>
    </div>

    <template v-else-if="customer">
      <!-- ============ Hero Header ============ -->
      <v-card rounded="xl" class="overflow-hidden mb-4 cd-hero-card" elevation="0" border>
        <div class="cd-hero">
          <div class="cd-hero-top">
            <div class="d-flex align-center ga-3">
              <v-btn icon variant="text" size="small" dark @click="goBack">
                <v-icon>mdi-arrow-left</v-icon>
              </v-btn>
              <v-avatar size="64" rounded="xl" class="cd-avatar">
                <img v-if="customer.passport_photo" :src="resolveMediaUrl(customer.passport_photo)" :alt="customer.full_name" style="width:100%; height:100%; object-fit:cover; border-radius:12px;" />
                <v-icon v-else size="32" color="white">mdi-account</v-icon>
              </v-avatar>
              <div>
                <h2 class="text-h5 font-weight-bold text-white" style="line-height: 1.2">
                  {{ customer.full_name }}
                </h2>
                <div class="d-flex align-center ga-2 mt-1">
                  <v-chip size="x-small" :color="customer.customer_type === 'foreigner' ? 'info' : 'success'" variant="flat" class="text-capitalize">
                    <v-icon size="12" start>mdi-account-eye-outline</v-icon>
                    {{ customer.customer_type }}
                  </v-chip>
                  <span class="text-caption text-white" style="opacity: 0.75">{{ `Customer #${customer.id}` }}</span>
                </div>
              </div>
            </div>

            <div class="d-none d-md-flex align-center ga-2">
              <v-btn v-can="'rentals:update'" variant="outlined" color="white" size="small" prepend-icon="mdi-pencil-outline" @click="navigateTo(`/app/rentals/customers/new?edit=${customer.id}`)">
                Edit
              </v-btn>
              <v-btn v-can="'rentals:delete'" variant="outlined" color="white" size="small" prepend-icon="mdi-trash-can-outline" @click="deleteCustomer">
                Delete
              </v-btn>
            </div>
          </div>

          <!-- Quick stats row -->
          <div class="cd-hero-stats">
            <div class="cd-quick-stat">
              <v-icon size="18" color="white">mdi-phone-outline</v-icon>
              <div>
                <div class="text-caption text-white" style="opacity: 0.7">Phone</div>
                <div class="text-body-2 font-weight-medium text-white">{{ customer.phone || '—' }}</div>
              </div>
            </div>
            <div class="cd-quick-stat">
              <v-icon size="18" color="white">mdi-email-outline</v-icon>
              <div>
                <div class="text-caption text-white" style="opacity: 0.7">Email</div>
                <div class="text-body-2 font-weight-medium text-white text-truncate" style="max-width: 200px">{{ customer.email || '—' }}</div>
              </div>
            </div>
            <div class="cd-quick-stat">
              <v-icon size="18" color="white">mdi-map-marker-outline</v-icon>
              <div>
                <div class="text-caption text-white" style="opacity: 0.7">Country</div>
                <div class="text-body-2 font-weight-medium text-white">{{ customer.country || '—' }}</div>
              </div>
            </div>
            <div class="cd-quick-stat">
              <v-icon size="18" color="white">mdi-card-account-details-outline</v-icon>
              <div>
                <div class="text-caption text-white" style="opacity: 0.7">ID</div>
                <div class="text-body-2 font-weight-medium text-white text-capitalize">{{ (customer.id_type || '').replace('_', ' ') }} · {{ customer.id_number || '—' }}</div>
              </div>
            </div>
          </div>
        </div>
      </v-card>

      <!-- ============ Main Content Grid ============ -->
      <v-row dense>
        <!-- LEFT: Personal Info + Emergency Contact + Address -->
        <v-col cols="12" lg="8">
          <!-- Personal Information -->
          <v-card rounded="xl" class="mb-4 cd-info-card" elevation="0" border>
            <div class="cd-card-header">
              <v-icon color="primary" size="20">mdi-account-details-outline</v-icon>
              <span>Personal Information</span>
            </div>
            <v-card-text class="pa-5">
              <v-row dense>
                <v-col cols="12" sm="6" md="4">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-account</v-icon>Full Name</div>
                    <div class="info-value">{{ customer.full_name || '—' }}</div>
                  </div>
                </v-col>
                <v-col cols="12" sm="6" md="4">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-account-eye-outline</v-icon>Customer Type</div>
                    <div class="info-value text-capitalize">{{ customer.customer_type || '—' }}</div>
                  </div>
                </v-col>
                <v-col cols="12" sm="6" md="4">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-phone-outline</v-icon>Phone</div>
                    <div class="info-value">{{ customer.phone || '—' }}</div>
                  </div>
                </v-col>
                <v-col cols="12" sm="6" md="4">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-email-outline</v-icon>Email</div>
                    <div class="info-value">{{ customer.email || '—' }}</div>
                  </div>
                </v-col>
                <v-col cols="12" sm="6" md="4">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-cake-variant-outline</v-icon>Date of Birth</div>
                    <div class="info-value">{{ formatDate(customer.date_of_birth) }}</div>
                  </div>
                </v-col>
                <v-col cols="12" sm="6" md="4">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-flag-outline</v-icon>Country</div>
                    <div class="info-value">{{ customer.country || '—' }}</div>
                  </div>
                </v-col>
                <v-col cols="12">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-map-marker-outline</v-icon>Address</div>
                    <div class="info-value">{{ customer.address || '—' }}</div>
                  </div>
                  <div v-if="customer.place_name" class="text-caption text-medium-emphasis ml-7 mt-1">
                    <v-icon size="12">mdi-location-enter</v-icon>
                    {{ customer.place_name }}
                  </div>
                </v-col>
              </v-row>
            </v-card-text>
          </v-card>

          <!-- Identification Details -->
          <v-card rounded="xl" class="mb-4 cd-info-card" elevation="0" border>
            <div class="cd-card-header">
              <v-icon color="primary" size="20">mdi-card-account-details-outline</v-icon>
              <span>Identification Details</span>
            </div>
            <v-card-text class="pa-5">
              <v-row dense>
                <v-col cols="12" sm="6" md="4">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-card-account-details-outline</v-icon>ID Type</div>
                    <div class="info-value text-capitalize">{{ (customer.id_type || '').replace('_', ' ') || '—' }}</div>
                  </div>
                </v-col>
                <v-col cols="12" sm="6" md="4">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-identifier</v-icon>ID Number</div>
                    <div class="info-value">{{ customer.id_number || '—' }}</div>
                  </div>
                </v-col>
                <v-col cols="12" sm="6" md="4">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-card-bulleted-outline</v-icon>Driving License No.</div>
                    <div class="info-value">{{ customer.driving_license_no || '—' }}</div>
                  </div>
                </v-col>
                <v-col cols="12" sm="6" md="4">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-flag-outline</v-icon>License Issued Country</div>
                    <div class="info-value">{{ customer.license_issued_country || '—' }}</div>
                  </div>
                </v-col>
                <v-col cols="12" sm="6" md="4">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-calendar-clock-outline</v-icon>License Expiry</div>
                    <div class="info-value">
                      {{ formatDate(customer.license_expiry) }}
                      <v-chip
                        v-if="customer.license_expiry"
                        size="x-small"
                        :color="expiryChipColor"
                        variant="flat"
                        class="ml-1"
                      >
                        {{ expiryLabel }}
                      </v-chip>
                    </div>
                  </div>
                </v-col>
              </v-row>
            </v-card-text>
          </v-card>

          <!-- Emergency Contact -->
          <v-card rounded="xl" class="cd-info-card" elevation="0" border>
            <div class="cd-card-header">
              <v-icon color="primary" size="20">mdi-shield-account-outline</v-icon>
              <span>Emergency Contact</span>
            </div>
            <v-card-text class="pa-5">
              <v-row dense>
                <v-col cols="12" sm="6" md="4">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-account-alert-outline</v-icon>Contact Name</div>
                    <div class="info-value">{{ customer.emergency_contact_name || '—' }}</div>
                  </div>
                </v-col>
                <v-col cols="12" sm="6" md="4">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-phone-alert-outline</v-icon>Contact Phone</div>
                    <div class="info-value">{{ customer.emergency_contact_phone || '—' }}</div>
                  </div>
                </v-col>
              </v-row>
            </v-card-text>
          </v-card>
        </v-col>

        <!-- RIGHT: Document gallery + meta -->
        <v-col cols="12" lg="4">
          <!-- Document Images -->
          <v-card rounded="xl" class="mb-4 cd-info-card" elevation="0" border>
            <div class="cd-card-header">
              <v-icon color="primary" size="20">mdi-image-multiple-outline</v-icon>
              <span>Documents</span>
            </div>
            <v-card-text class="pa-5">
              <div class="doc-item">
                <div class="doc-thumb" :class="{ filled: customer.passport_photo }">
                  <img v-if="customer.passport_photo" :src="resolveMediaUrl(customer.passport_photo)" @click="openImage(customer.passport_photo, 'Passport Photo')" />
                  <v-icon v-else size="28" color="grey-lighten-1">mdi-face-recognition-outline</v-icon>
                </div>
                <div class="doc-meta">
                  <div class="doc-name">Passport Photo</div>
                  <v-chip size="x-small" :color="customer.passport_photo ? 'success' : 'grey'" variant="flat">
                    {{ customer.passport_photo ? 'Uploaded' : 'None' }}
                  </v-chip>
                </div>
              </div>

              <div class="doc-item">
                <div class="doc-thumb" :class="{ filled: customer.id_front_image }">
                  <img v-if="customer.id_front_image" :src="resolveMediaUrl(customer.id_front_image)" @click="openImage(customer.id_front_image, 'ID — Front')" />
                  <v-icon v-else size="28" color="grey-lighten-1">mdi-card-bulleted-outline</v-icon>
                </div>
                <div class="doc-meta">
                  <div class="doc-name">ID — Front</div>
                  <v-chip size="x-small" :color="customer.id_front_image ? 'success' : 'grey'" variant="flat">
                    {{ customer.id_front_image ? 'Uploaded' : 'None' }}
                  </v-chip>
                </div>
              </div>

              <div class="doc-item">
                <div class="doc-thumb" :class="{ filled: customer.id_back_image }">
                  <img v-if="customer.id_back_image" :src="resolveMediaUrl(customer.id_back_image)" @click="openImage(customer.id_back_image, 'ID — Back')" />
                  <v-icon v-else size="28" color="grey-lighten-1">mdi-card-bulleted-off-outline</v-icon>
                </div>
                <div class="doc-meta">
                  <div class="doc-name">ID — Back</div>
                  <v-chip size="x-small" :color="customer.id_back_image ? 'success' : 'grey'" variant="flat">
                    {{ customer.id_back_image ? 'Uploaded' : 'None' }}
                  </v-chip>
                </div>
              </div>

              <div class="doc-item">
                <div class="doc-thumb" :class="{ filled: customer.driving_license_image }">
                  <img v-if="customer.driving_license_image" :src="resolveMediaUrl(customer.driving_license_image)" @click="openImage(customer.driving_license_image, 'Driving License')" />
                  <v-icon v-else size="28" color="grey-lighten-1">mdi-license-outline</v-icon>
                </div>
                <div class="doc-meta">
                  <div class="doc-name">Driving License</div>
                  <v-chip size="x-small" :color="customer.driving_license_image ? 'success' : 'grey'" variant="flat">
                    {{ customer.driving_license_image ? 'Uploaded' : 'None' }}
                  </v-chip>
                </div>
              </div>
            </v-card-text>
          </v-card>

          <!-- Metadata -->
          <v-card rounded="xl" class="cd-info-card" elevation="0" border>
            <div class="cd-card-header">
              <v-icon color="primary" size="20">mdi-information-outline</v-icon>
              <span>Metadata</span>
            </div>
            <v-card-text class="pa-5">
              <div class="info-item">
                <div class="info-label"><v-icon size="14">mdi-identifier</v-icon>Customer ID</div>
                <div class="info-value">{{ customer.id }}</div>
              </div>
              <div class="info-item">
                <div class="info-label"><v-icon size="14">mdi-calendar-plus</v-icon>Created</div>
                <div class="info-value">{{ formatDateTime(customer.created_at) }}</div>
              </div>
              <div class="info-item">
                <div class="info-label"><v-icon size="14">mdi-calendar-edit</v-icon>Last Updated</div>
                <div class="info-value">{{ formatDateTime(customer.updated_at) }}</div>
              </div>
              <div v-if="customer.latitude && customer.longitude" class="info-item">
                <div class="info-label"><v-icon size="14">mdi-crosshairs-gps</v-icon>Coordinates</div>
                <div class="info-value">{{ customer.latitude }}, {{ customer.longitude }}</div>
              </div>
            </v-card-text>
          </v-card>
        </v-col>
      </v-row>
    </template>

    <!-- ============ Image Lightbox ============ -->
    <v-dialog v-model="lightbox.open" max-width="700" content-class="cd-lightbox">
      <v-card rounded="xl" class="pa-0">
        <div class="d-flex align-center justify-space-between pa-3">
          <span class="text-body-1 font-weight-bold">{{ lightbox.title }}</span>
          <v-btn icon variant="text" size="small" @click="lightbox.open = false">
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </div>
        <v-divider />
        <div class="d-flex justify-center pa-3" style="background: #0f172a;">
          <img :src="lightbox.url" :alt="lightbox.title" style="max-width: 100%; max-height: 60vh; border-radius: 8px;" />
        </div>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

const { $api, $swal } = useNuxtApp()
const { resolveMediaUrl } = useMediaUrl()
const router = useRouter()
const route = useRoute()

const customerId = computed(() => route.params.id ? Number(route.params.id) : null)

const loading = ref(true)
const error = ref('')
const customer = ref<any>(null)

const lightbox = reactive({ open: false, url: '', title: '' })

// License expiry status
const expiryChipColor = computed(() => {
  if (!customer.value?.license_expiry) return 'grey'
  const expiry = new Date(customer.value.license_expiry)
  const now = new Date()
  const daysLeft = Math.ceil((expiry.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
  if (daysLeft < 0) return 'error'
  if (daysLeft <= 30) return 'warning'
  return 'success'
})
const expiryLabel = computed(() => {
  if (!customer.value?.license_expiry) return ''
  const expiry = new Date(customer.value.license_expiry)
  const now = new Date()
  const daysLeft = Math.ceil((expiry.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
  if (daysLeft < 0) return 'Expired'
  if (daysLeft <= 30) return `${daysLeft}d left`
  return 'Valid'
})

function goBack() {
  router.push('/app/rentals?tab=customers')
}

function formatDate(d: any) {
  if (!d) return '—'
  try {
    return new Date(d).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
  } catch {
    return d
  }
}

function formatDateTime(d: any) {
  if (!d) return '—'
  try {
    return new Date(d).toLocaleString('en-GB', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })
  } catch {
    return d
  }
}

function openImage(path: string, title: string) {
  lightbox.url = resolveMediaUrl(path)
  lightbox.title = title
  lightbox.open = true
}

async function loadCustomer() {
  if (!customerId.value) {
    error.value = 'Invalid customer ID'
    loading.value = false
    return
  }
  loading.value = true
  try {
    customer.value = await $api(`/rentals/customers/${customerId.value}/`)
  } catch (e: any) {
    error.value = e?.data?.detail || e?.message || 'Failed to load customer'
  } finally {
    loading.value = false
  }
}

async function deleteCustomer() {
  if (!customer.value) return
  const c = customer.value

  // Check if the customer is linked to any agreements
  let links: any = null
  try {
    links = await $api(`/rentals/customers/${c.id}/check-links/`)
  } catch {
    // If check fails, proceed with normal delete below
  }

  if (links && links.has_agreements) {
    // Customer has linked agreements — show warning and ask for cascade confirmation
    const agreementsList = (links.agreements || [])
      .slice(0, 5)
      .map((a: any) => `<li><b>${a.agreement_no}</b> — ${a.vehicle_display || 'N/A'} (${a.status})</li>`)
      .join('')
    const more = links.agreements_count > 5 ? `<li><i>...and ${links.agreements_count - 5} more</i></li>` : ''

    const r = await $swal.fire({
      icon: 'warning',
      title: `Delete ${c.full_name}?`,
      html: `<div style="text-align:left; font-size:0.85rem;">
        <p style="color:#b91c1c; font-weight:600; margin-bottom:8px;">
          ⚠️ This customer is linked to <b>${links.agreements_count}</b> rental agreement(s):
        </p>
        <ul style="margin:0 0 12px 20px; padding:0;">${agreementsList}${more}</ul>
        <p style="margin:0;">Deleting will also permanently delete <b>all linked agreements</b> and their charges, damages, and signatures. This cannot be undone.</p>
      </div>`,
      showCancelButton: true,
      confirmButtonText: 'Delete Customer & All Agreements',
      confirmButtonColor: '#ef4444',
      cancelButtonText: 'Cancel',
      width: 520,
    })
    if (!r.isConfirmed) return

    try {
      await $api(`/rentals/customers/${c.id}/?cascade=true`, { method: 'DELETE' })
      $swal.fire({ icon: 'success', title: 'Customer and agreements deleted', toast: true, timer: 1500, position: 'top-end' })
      goBack()
    } catch (e: any) {
      $swal.fire({ icon: 'error', title: 'Delete failed', text: e?.data?.detail || e?.message || '', toast: true, timer: 2500, position: 'top-end' })
    }
    return
  }

  // No linked agreements — simple confirm
  const r = await $swal.fire({
    icon: 'warning',
    title: `Delete ${c.full_name}?`,
    text: 'This action cannot be undone.',
    showCancelButton: true,
    confirmButtonText: 'Delete',
    confirmButtonColor: '#ef4444',
  })
  if (!r.isConfirmed) return
  try {
    await $api(`/rentals/customers/${c.id}/`, { method: 'DELETE' })
    $swal.fire({ icon: 'success', title: 'Customer deleted', toast: true, timer: 1500, position: 'top-end' })
    goBack()
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Delete failed', text: e?.data?.detail || e?.message || '', toast: true, timer: 2500, position: 'top-end' })
  }
}

onMounted(() => {
  loadCustomer()
})
</script>

<style scoped>
.customer-details-page {
  width: 100%;
}

/* ============ Hero Header ============ */
.cd-hero-card {
  border: none;
}
.cd-hero {
  background: linear-gradient(135deg, #4f46e5 0%, #6366f1 50%, #818cf8 100%);
  padding: 24px 28px 0;
}
.cd-hero-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
  padding-bottom: 8px;
}
.cd-avatar {
  background: rgba(255, 255, 255, 0.2);
  backdrop-filter: blur(4px);
  border: 2px solid rgba(255, 255, 255, 0.3);
}

/* Quick stats */
.cd-hero-stats {
  display: flex;
  flex-wrap: wrap;
  gap: 0;
  margin: 16px -28px 0;
  padding: 0 28px;
  border-top: 1px solid rgba(255, 255, 255, 0.15);
}
.cd-quick-stat {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 14px 20px 16px 0;
  flex: 1 1 180px;
  min-width: 180px;
}
.cd-quick-stat > .v-icon {
  background: rgba(255, 255, 255, 0.15);
  border-radius: 8px;
  padding: 6px;
}

/* ============ Info Cards ============ */
.cd-info-card {
  border: 1px solid #e2e8f0;
}
.cd-card-header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 16px 20px 12px;
  font-size: 0.85rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: #475569;
  border-bottom: 1px solid #f1f5f9;
}

/* Info items */
.info-item {
  padding: 6px 0;
}
.info-label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 0.7rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  color: #94a3b8;
  margin-bottom: 3px;
}
.info-label .v-icon {
  opacity: 0.6;
}
.info-value {
  font-size: 0.9rem;
  font-weight: 600;
  color: #1e293b;
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
  word-break: break-word;
}

/* ============ Document Gallery ============ */
.doc-item {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 10px 0;
  border-bottom: 1px dashed #e2e8f0;
}
.doc-item:last-child {
  border-bottom: none;
  padding-bottom: 0;
}
.doc-item:first-child {
  padding-top: 0;
}
.doc-thumb {
  width: 64px;
  height: 64px;
  border-radius: 10px;
  overflow: hidden;
  border: 1px solid #e2e8f0;
  background: #f8fafc;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  cursor: default;
  transition: box-shadow 0.2s;
}
.doc-thumb.filled {
  cursor: pointer;
}
.doc-thumb.filled:hover {
  box-shadow: 0 4px 12px rgba(79, 70, 229, 0.2);
}
.doc-thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.doc-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}
.doc-name {
  font-size: 0.85rem;
  font-weight: 600;
  color: #1e293b;
}

/* ============ Lightbox ============ */
:deep(.cd-lightbox) {
  overflow: hidden;
}
</style>
