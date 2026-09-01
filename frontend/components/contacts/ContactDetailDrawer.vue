<template>
  <v-navigation-drawer :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" location="right" width="520" temporary style="top:0; height:100vh; z-index:1000">
    <div v-if="contact" class="d-flex flex-column h-100">
      <!-- Header -->
      <div class="drawer-head">
        <div class="d-flex align-center ga-3 mb-2">
          <div class="contact-avatar" :style="{ background: avatarColor }">
            <img v-if="contact.photo" :src="resolveMediaUrl(contact.photo)" :alt="contact.full_name" />
            <span v-else>{{ initials }}</span>
          </div>
          <div class="flex-grow-1">
            <h2 class="text-h6 font-weight-bold mb-0">{{ contact.full_name }}</h2>
            <div class="d-flex align-center ga-1 mt-1 flex-wrap">
              <v-chip :color="typeColor(contact.contact_type)" variant="tonal" size="small">
                <v-icon start size="14">{{ typeIcon(contact.contact_type) }}</v-icon>{{ typeLabel(contact.contact_type) }}
              </v-chip>
              <v-chip :color="contact.is_active ? 'success' : 'grey'" variant="flat" size="small">
                <v-icon start size="14">{{ contact.is_active ? 'mdi-check-circle' : 'mdi-pause-circle' }}</v-icon>
                {{ contact.is_active ? 'Active' : 'Inactive' }}
              </v-chip>
            </div>
          </div>
          <v-btn icon variant="text" size="small" @click="$emit('update:modelValue', false)"><v-icon>mdi-close</v-icon></v-btn>
        </div>
      </div>
      <v-divider />

      <div class="drawer-body">
        <!-- Contact Info -->
        <div class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-account-details-outline</v-icon>Contact Information</p>
          <div class="info-grid">
            <div class="info-item">
              <v-icon size="18" color="medium-emphasis">mdi-email-outline</v-icon>
              <div><p class="text-caption text-medium-emphasis">Email</p><p class="text-body-2 font-weight-medium">{{ contact.email || '—' }}</p></div>
            </div>
            <div class="info-item">
              <v-icon size="18" color="medium-emphasis">mdi-phone-outline</v-icon>
              <div><p class="text-caption text-medium-emphasis">Phone</p><p class="text-body-2 font-weight-medium">{{ contact.phone || '—' }}</p></div>
            </div>
            <div class="info-item">
              <v-icon size="18" color="medium-emphasis">mdi-map-marker-outline</v-icon>
              <div><p class="text-caption text-medium-emphasis">Location</p><p class="text-body-2 font-weight-medium">{{ locationStr }}</p></div>
            </div>
            <div class="info-item">
              <v-icon size="18" color="medium-emphasis">mdi-badge-account-outline</v-icon>
              <div><p class="text-caption text-medium-emphasis">Employee ID</p><p class="text-body-2 font-weight-medium">{{ contact.employee_id || '—' }}</p></div>
            </div>
            <div class="info-item">
              <v-icon size="18" color="medium-emphasis">mdi-domain</v-icon>
              <div><p class="text-caption text-medium-emphasis">Department</p><p class="text-body-2 font-weight-medium">{{ contact.department || '—' }}</p></div>
            </div>
            <div class="info-item" v-if="contact.date_of_birth">
              <v-icon size="18" color="medium-emphasis">mdi-cake-variant-outline</v-icon>
              <div><p class="text-caption text-medium-emphasis">Date of Birth</p><p class="text-body-2 font-weight-medium">{{ fmtDate(contact.date_of_birth) }}</p></div>
            </div>
          </div>
        </div>

        <!-- Address -->
        <div v-if="contact.address" class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-home-map-marker</v-icon>Address</p>
          <div class="notes-card">{{ fullAddress }}</div>
        </div>

        <!-- Vendor Profile -->
        <div v-if="contact.vendor_profile" class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-store-outline</v-icon>Vendor Profile</p>
          <div class="info-grid">
            <div class="info-item">
              <v-icon size="18" color="medium-emphasis">mdi-wrench-outline</v-icon>
              <div><p class="text-caption text-medium-emphasis">Service Type</p><p class="text-body-2 font-weight-medium">{{ contact.vendor_profile.service_type || '—' }}</p></div>
            </div>
            <div class="info-item">
              <v-icon size="18" color="warning">mdi-star</v-icon>
              <div>
                <p class="text-caption text-medium-emphasis">Rating</p>
                <div class="d-flex align-center ga-1">
                  <v-rating :model-value="contact.vendor_profile.rating || 0" color="warning" density="compact" half-increments readonly size="small" />
                  <span class="text-body-2 font-weight-medium">{{ contact.vendor_profile.rating || 0 }}</span>
                </div>
              </div>
            </div>
            <div class="info-item">
              <v-icon size="18" color="medium-emphasis">mdi-cash-clock</v-icon>
              <div><p class="text-caption text-medium-emphasis">Payment Terms</p><p class="text-body-2 font-weight-medium">{{ contact.vendor_profile.payment_terms || '—' }}</p></div>
            </div>
            <div class="info-item">
              <v-icon size="18" color="medium-emphasis">mdi-identifier</v-icon>
              <div><p class="text-caption text-medium-emphasis">Tax ID</p><p class="text-body-2 font-weight-medium">{{ contact.vendor_profile.tax_id || '—' }}</p></div>
            </div>
          </div>
        </div>

        <!-- Notes -->
        <div v-if="contact.notes" class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-text-box-outline</v-icon>Notes</p>
          <div class="notes-card">{{ contact.notes }}</div>
        </div>

        <!-- Metadata -->
        <div class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-information-outline</v-icon>Metadata</p>
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-key-variant</v-icon>
            <span class="text-caption text-medium-emphasis">ID:</span>
            <span class="text-body-2 font-weight-medium">#{{ contact.id }}</span>
          </div>
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-clock-outline</v-icon>
            <span class="text-caption text-medium-emphasis">Created:</span>
            <span class="text-body-2">{{ fmtDate(contact.created_at) }}</span>
          </div>
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-update</v-icon>
            <span class="text-caption text-medium-emphasis">Updated:</span>
            <span class="text-body-2">{{ fmtDate(contact.updated_at) }}</span>
          </div>
        </div>
      </div>

      <!-- Actions -->
      <div class="drawer-actions">
        <v-btn variant="text" prepend-icon="mdi-pencil-outline" @click="$emit('edit', contact)">Edit</v-btn>
        <v-spacer />
        <v-btn variant="tonal" color="error" prepend-icon="mdi-delete-outline" @click="$emit('delete', contact)">Delete</v-btn>
      </div>
    </div>
    <div v-else class="d-flex align-center justify-center h-100">
      <v-icon size="48" color="grey-lighten-2">mdi-card-account-details-outline</v-icon>
    </div>
  </v-navigation-drawer>
</template>

<script setup lang="ts">
import { useMediaUrl } from '~/composables/useMediaUrl'

const props = defineProps<{ modelValue: boolean; contact: any }>()
defineEmits<{ 'update:modelValue': [v: boolean]; edit: [c: any]; delete: [c: any] }>()

const { resolveMediaUrl } = useMediaUrl()

const initials = computed(() => {
  const c = props.contact
  if (c?.first_name || c?.last_name) return ((c.first_name?.[0] || '') + (c.last_name?.[0] || '')).toUpperCase() || '?'
  if (c?.company_name) return c.company_name.slice(0, 2).toUpperCase()
  return '?'
})
const avatarColor = computed(() => {
  const colors = ['#e0e7ff', '#dcfce7', '#fef9c3', '#fee2e2', '#f3e8ff', '#cffafe']
  return colors[(props.contact?.first_name?.charCodeAt(0) || props.contact?.company_name?.charCodeAt(0) || 0) % colors.length]
})
const locationStr = computed(() => {
  const c = props.contact
  return [c?.city, c?.state, c?.country].filter(Boolean).join(', ') || '—'
})
const fullAddress = computed(() => {
  const c = props.contact
  return [c?.address, c?.city, c?.state, c?.zip_code, c?.country].filter(Boolean).join(', ') || '—'
})

function fmtDate(v?: string) { return v ? new Date(v).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' }) : '—' }
function typeColor(t: string) {
  return ({ driver: 'primary', vendor: 'teal', mechanic: 'amber', manager: 'deep-purple', insurance_agent: 'cyan', towing: 'error' } as any)[t] || 'grey'
}
function typeIcon(t: string) {
  return ({ driver: 'mdi-steering', vendor: 'mdi-store-outline', mechanic: 'mdi-wrench', manager: 'mdi-account-tie', insurance_agent: 'mdi-shield-outline', towing: 'mdi-tow-truck' } as any)[t] || 'mdi-account'
}
function typeLabel(t: string) {
  return ({ driver: 'Driver', vendor: 'Vendor', mechanic: 'Mechanic', manager: 'Manager', insurance_agent: 'Insurance Agent', towing: 'Towing Company' } as any)[t] || t || '—'
}
</script>

<style scoped>
.drawer-head { padding: 16px 20px; }
.drawer-body { flex: 1; overflow-y: auto; padding: 16px 20px; }
.drawer-actions { padding: 12px 20px; border-top: 1px solid #e2e8f0; display: flex; align-items: center; gap: 8px; }
.section-block { margin-bottom: 20px; }
.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.info-item { display: flex; align-items: flex-start; gap: 8px; }
.info-row { display: flex; align-items: center; gap: 6px; padding: 4px 0; }
.contact-avatar { width: 56px; height: 56px; border-radius: 50%; display: flex; align-items: center; justify-content: center; overflow: hidden; flex-shrink: 0; font-weight: 700; font-size: 18px; }
.contact-avatar img { width: 100%; height: 100%; object-fit: cover; }
.notes-card { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 12px; font-size: 14px; color: #475569; line-height: 1.5; }
@media (max-width: 600px) { .info-grid { grid-template-columns: 1fr; } }
</style>
