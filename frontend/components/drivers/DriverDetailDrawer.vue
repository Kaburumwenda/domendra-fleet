<template>
  <v-navigation-drawer :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" location="right" width="560" temporary style="top:0; height:100vh; z-index:1000">
    <div v-if="driver" class="d-flex flex-column h-100">
      <!-- Header -->
      <div class="drawer-head">
        <div class="d-flex align-center ga-3 mb-2">
          <div class="driver-avatar" :style="{ background: avatarColor }">
            <img v-if="driver.photo" :src="resolveMediaUrl(driver.photo)" :alt="driver.full_name" />
            <span v-else>{{ initials }}</span>
          </div>
          <div class="flex-grow-1">
            <h2 class="text-h6 font-weight-bold mb-0">{{ driver.full_name }}</h2>
            <div class="d-flex align-center ga-1 mt-1 flex-wrap">
              <v-chip :color="employmentColor" variant="tonal" size="small">
                <v-icon start size="14">{{ employmentIcon }}</v-icon>{{ employmentLabel }}
              </v-chip>
              <v-chip :color="mvrColor" variant="flat" size="small">{{ mvrLabel }}</v-chip>
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
              <div><p class="text-caption text-medium-emphasis">Email</p><p class="text-body-2 font-weight-medium">{{ driver.email || '—' }}</p></div>
            </div>
            <div class="info-item">
              <v-icon size="18" color="medium-emphasis">mdi-phone-outline</v-icon>
              <div><p class="text-caption text-medium-emphasis">Phone</p><p class="text-body-2 font-weight-medium">{{ driver.phone || '—' }}</p></div>
            </div>
            <div class="info-item">
              <v-icon size="18" color="medium-emphasis">mdi-map-marker-outline</v-icon>
              <div><p class="text-caption text-medium-emphasis">Location</p><p class="text-body-2 font-weight-medium">{{ locationStr }}</p></div>
            </div>
            <div class="info-item">
              <v-icon size="18" color="medium-emphasis">mdi-badge-account-outline</v-icon>
              <div><p class="text-caption text-medium-emphasis">Employee ID</p><p class="text-body-2 font-weight-medium">{{ driver.employee_id || '—' }}</p></div>
            </div>
            <div class="info-item">
              <v-icon size="18" color="medium-emphasis">mdi-domain</v-icon>
              <div><p class="text-caption text-medium-emphasis">Department</p><p class="text-body-2 font-weight-medium">{{ driver.department || '—' }}</p></div>
            </div>
          </div>
        </div>

        <!-- License & Medical -->
        <div v-if="driver.driver_profile" class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-card-account-details-outline</v-icon>License & Medical</p>
          <div class="info-grid">
            <div class="info-item">
              <v-icon size="18" color="medium-emphasis">mdi-card-text-outline</v-icon>
              <div><p class="text-caption text-medium-emphasis">License Number</p><p class="text-body-2 font-weight-medium">{{ profile.license_number || '—' }}</p></div>
            </div>
            <div class="info-item">
              <v-icon size="18" color="medium-emphasis">mdi-card-bulleted-outline</v-icon>
              <div><p class="text-caption text-medium-emphasis">License Class</p><p class="text-body-2 font-weight-medium">{{ profile.license_class_label || profile.license_class || '—' }}</p></div>
            </div>
            <div class="info-item">
              <v-icon size="18" color="medium-emphasis">mdi-map</v-icon>
              <div><p class="text-caption text-medium-emphasis">Issuing State</p><p class="text-body-2 font-weight-medium">{{ profile.license_state || '—' }}</p></div>
            </div>
            <div class="info-item">
              <v-icon size="18" :color="expiryColor(profile.license_expiry)">mdi-calendar-clock</v-icon>
              <div>
                <p class="text-caption text-medium-emphasis">License Expiry</p>
                <p class="text-body-2 font-weight-medium" :class="expiryClass(profile.license_expiry)">{{ fmtDate(profile.license_expiry) }}</p>
              </div>
            </div>
            <div class="info-item">
              <v-icon size="18" :color="expiryColor(profile.medical_card_expiry)">mdi-heart-pulse</v-icon>
              <div>
                <p class="text-caption text-medium-emphasis">Medical Card Expiry</p>
                <p class="text-body-2 font-weight-medium" :class="expiryClass(profile.medical_card_expiry)">{{ fmtDate(profile.medical_card_expiry) }}</p>
              </div>
            </div>
            <div class="info-item">
              <v-icon size="18" color="medium-emphasis">mdi-card-account-details-star-outline</v-icon>
              <div><p class="text-caption text-medium-emphasis">Med Card #</p><p class="text-body-2 font-weight-medium">{{ profile.medical_card_number || '—' }}</p></div>
            </div>
          </div>
          <div v-if="profile.license_endorsements?.length" class="mt-2">
            <p class="text-caption text-medium-emphasis mb-1">Endorsements</p>
            <div class="d-flex flex-wrap ga-1">
              <v-chip v-for="e in profile.license_endorsements" :key="e" size="small" variant="tonal" color="deep-purple">{{ endorsementLabel(e) }}</v-chip>
            </div>
          </div>
        </div>

        <!-- Employment -->
        <div v-if="driver.driver_profile" class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-briefcase-outline</v-icon>Employment</p>
          <div class="info-grid">
            <div class="info-item">
              <v-icon size="18" color="medium-emphasis">mdi-calendar-start</v-icon>
              <div><p class="text-caption text-medium-emphasis">Hire Date</p><p class="text-body-2 font-weight-medium">{{ fmtDate(profile.hire_date) }}</p></div>
            </div>
            <div class="info-item">
              <v-icon size="18" color="medium-emphasis">mdi-map-marker-radius-outline</v-icon>
              <div><p class="text-caption text-medium-emphasis">Home Terminal</p><p class="text-body-2 font-weight-medium">{{ profile.home_terminal || '—' }}</p></div>
            </div>
            <div class="info-item">
              <v-icon size="18" color="medium-emphasis">mdi-cash</v-icon>
              <div><p class="text-caption text-medium-emphasis">Pay Rate</p><p class="text-body-2 font-weight-medium">{{ profile.pay_rate ? `${currencySymbol}${profile.pay_rate} / ${profile.pay_type}` : '—' }}</p></div>
            </div>
            <div class="info-item">
              <v-icon size="18" color="medium-emphasis">mdi-account-supervisor-outline</v-icon>
              <div><p class="text-caption text-medium-emphasis">MVR Last Checked</p><p class="text-body-2 font-weight-medium">{{ fmtDate(profile.mvr_last_checked) }}</p></div>
            </div>
            <div class="info-item">
              <v-icon size="18" :color="expiryColor(profile.mvr_next_due)">mdi-shield-sync-outline</v-icon>
              <div>
                <p class="text-caption text-medium-emphasis">MVR Next Due</p>
                <p class="text-body-2 font-weight-medium" :class="expiryClass(profile.mvr_next_due)">{{ fmtDate(profile.mvr_next_due) }}</p>
              </div>
            </div>
            <div class="info-item" v-if="profile.termination_date">
              <v-icon size="18" color="medium-emphasis">mdi-calendar-end</v-icon>
              <div><p class="text-caption text-medium-emphasis">Termination Date</p><p class="text-body-2 font-weight-medium">{{ fmtDate(profile.termination_date) }}</p></div>
            </div>
          </div>
        </div>

        <!-- Emergency Contact -->
        <div v-if="profile.emergency_contact_name" class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-account-alert-outline</v-icon>Emergency Contact</p>
          <div class="info-grid">
            <div class="info-item">
              <v-icon size="18" color="medium-emphasis">mdi-account-outline</v-icon>
              <div><p class="text-caption text-medium-emphasis">Name</p><p class="text-body-2 font-weight-medium">{{ profile.emergency_contact_name }}</p></div>
            </div>
            <div class="info-item">
              <v-icon size="18" color="medium-emphasis">mdi-phone-outline</v-icon>
              <div><p class="text-caption text-medium-emphasis">Phone</p><p class="text-body-2 font-weight-medium">{{ profile.emergency_contact_phone || '—' }}</p></div>
            </div>
            <div class="info-item">
              <v-icon size="18" color="medium-emphasis">mdi-link-variant</v-icon>
              <div><p class="text-caption text-medium-emphasis">Relationship</p><p class="text-body-2 font-weight-medium">{{ profile.emergency_contact_relation || '—' }}</p></div>
            </div>
            <div class="info-item" v-if="profile.blood_type">
              <v-icon size="18" color="medium-emphasis">mdi-water</v-icon>
              <div><p class="text-caption text-medium-emphasis">Blood Type</p><p class="text-body-2 font-weight-medium">{{ profile.blood_type }}</p></div>
            </div>
          </div>
        </div>

        <!-- Violations -->
        <div v-if="violations.length" class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-alert-octagon-outline</v-icon>Violations ({{ violations.length }})</p>
          <v-expansion-panels variant="accordion">
            <v-expansion-panel v-for="v in violations" :key="v.id">
              <v-expansion-panel-title class="text-body-2">
                <div class="d-flex align-center ga-2 flex-grow-1">
                  <v-chip :color="severityColor(v.severity)" variant="tonal" size="x-small">{{ v.severity_label || v.severity }}</v-chip>
                  <span class="font-weight-medium">{{ v.violation_type_label || v.violation_type }}</span>
                  <span class="text-caption text-medium-emphasis ml-auto">{{ fmtDate(v.date) }}</span>
                </div>
              </v-expansion-panel-title>
              <v-expansion-panel-text>
                <p class="text-body-2">{{ v.description || 'No description' }}</p>
                <div class="d-flex ga-3 mt-1 text-caption text-medium-emphasis">
                  <span v-if="v.state"><v-icon size="12">mdi-map-marker</v-icon> {{ v.state }}</span>
                  <span><v-icon size="12">mdi-counter</v-icon> {{ v.points }} pts</span>
                  <span v-if="v.fine_amount"><v-icon size="12">mdi-cash</v-icon> {{ currencySymbol }}{{ v.fine_amount }}</span>
                  <v-chip size="x-small" :color="v.paid ? 'success' : 'error'" variant="tonal">{{ v.paid ? 'Paid' : 'Unpaid' }}</v-chip>
                </div>
              </v-expansion-panel-text>
            </v-expansion-panel>
          </v-expansion-panels>
        </div>

        <!-- Drug Tests -->
        <div v-if="drugTests.length" class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-flask-outline</v-icon>Drug Tests ({{ drugTests.length }})</p>
          <v-list density="compact" lines="two" class="bg-transparent">
            <v-list-item v-for="t in drugTests" :key="t.id">
              <template #prepend>
                <v-icon :color="resultColor(t.result)">{{ resultIcon(t.result) }}</v-icon>
              </template>
              <v-list-item-title class="text-body-2 font-weight-medium">{{ t.test_type_label || t.test_type }}</v-list-item-title>
              <v-list-item-subtitle class="text-caption">{{ fmtDate(t.test_date) }} · {{ t.lab_name || '—' }} · {{ t.result_label || t.result }}</v-list-item-subtitle>
            </v-list-item>
          </v-list>
        </div>

        <!-- Training -->
        <div v-if="trainings.length" class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-school-outline</v-icon>Training ({{ trainings.length }})</p>
          <v-list density="compact" lines="two" class="bg-transparent">
            <v-list-item v-for="t in trainings" :key="t.id">
              <template #prepend>
                <v-icon :color="trainingColor(t.status)">{{ trainingIcon(t.status) }}</v-icon>
              </template>
              <v-list-item-title class="text-body-2 font-weight-medium">{{ t.course_name }}</v-list-item-title>
              <v-list-item-subtitle class="text-caption">
                {{ t.status_label || t.status }} · {{ t.provider || '—' }}
                <span v-if="t.score"> · Score: {{ t.score }}%</span>
                <span v-if="t.expiry_date"> · Expires {{ fmtDate(t.expiry_date) }}</span>
              </v-list-item-subtitle>
            </v-list-item>
          </v-list>
        </div>

        <!-- Assignments -->
        <div v-if="assignments.length" class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-car-connected</v-icon>Vehicle Assignments ({{ assignments.length }})</p>
          <v-list density="compact" class="bg-transparent">
            <v-list-item v-for="a in assignments" :key="a.id">
              <template #prepend>
                <v-icon :color="a.is_active ? 'success' : 'grey'">{{ a.is_active ? 'mdi-car-key' : 'mdi-car-off' }}</v-icon>
              </template>
              <v-list-item-title class="text-body-2 font-weight-medium">{{ a.vehicle_label || 'Unassigned' }}</v-list-item-title>
              <v-list-item-subtitle class="text-caption">{{ fmtDate(a.assigned_at) }}{{ a.unassigned_at ? ' → ' + fmtDate(a.unassigned_at) : ' · Active' }}</v-list-item-subtitle>
            </v-list-item>
          </v-list>
        </div>

        <!-- Notes -->
        <div v-if="notes.length" class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-note-text-outline</v-icon>Notes ({{ notes.length }})</p>
          <div class="d-flex flex-column ga-2">
            <v-card v-for="n in notes" :key="n.id" elevation="0" border rounded="lg" class="pa-3">
              <div class="d-flex align-center ga-2 mb-1">
                <v-chip size="x-small" variant="tonal" :color="noteColor(n.category)">{{ n.category_label || n.category }}</v-chip>
                <span class="text-caption text-medium-emphasis ml-auto">{{ n.author || '—' }} · {{ fmtDate(n.created_at) }}</span>
              </div>
              <p class="text-body-2 mb-0">{{ n.body }}</p>
            </v-card>
          </div>
        </div>
      </div>

      <!-- Actions -->
      <div class="drawer-actions">
        <v-btn v-can="'drivers:update'" variant="text" prepend-icon="mdi-pencil-outline" @click="$emit('edit', driver)">Edit</v-btn>
        <v-btn v-can="'drivers:delete'" variant="tonal" color="error" prepend-icon="mdi-delete-outline" @click="$emit('delete', driver)">Delete</v-btn>
        <v-spacer />
        <v-btn variant="tonal" color="primary" prepend-icon="mdi-open-in-new" @click="$emit('viewFull', driver)">Full Page</v-btn>
      </div>
    </div>
    <div v-else class="d-flex align-center justify-center h-100">
      <v-icon size="48" color="grey-lighten-2">mdi-steering</v-icon>
    </div>
  </v-navigation-drawer>
</template>

<script setup lang="ts">
import { useMediaUrl } from '~/composables/useMediaUrl'
import { useCurrency } from '~/composables/useCurrency'

const props = defineProps<{ modelValue: boolean; driver: any }>()
defineEmits<{ 'update:modelValue': [v: boolean]; edit: [d: any]; delete: [d: any]; viewFull: [d: any] }>()

const { resolveMediaUrl } = useMediaUrl()
const { currencySymbol } = useCurrency()

const profile = computed(() => props.driver?.driver_profile || {})
const violations = computed(() => profile.value?.violations || [])
const drugTests = computed(() => profile.value?.drug_tests || [])
const trainings = computed(() => profile.value?.trainings || [])
const assignments = computed(() => profile.value?.assignments || [])
const notes = computed(() => profile.value?.notes_log || [])

const initials = computed(() => {
  const d = props.driver
  return ((d?.first_name?.[0] || '') + (d?.last_name?.[0] || '')).toUpperCase() || '?'
})
const avatarColor = computed(() => {
  const colors = ['#e0e7ff', '#dcfce7', '#fef9c3', '#fee2e2', '#f3e8ff', '#cffafe']
  return colors[(props.driver?.first_name?.charCodeAt(0) || 0) % colors.length]
})
const locationStr = computed(() => {
  const d = props.driver
  return [d?.city, d?.state, d?.country].filter(Boolean).join(', ') || '—'
})
const employmentColor = computed(() => {
  const s = profile.value?.employment_status
  return ({ active: 'success', on_leave: 'info', suspended: 'warning', terminated: 'grey', probation: 'amber' } as any)[s] || 'grey'
})
const employmentIcon = computed(() => {
  const s = profile.value?.employment_status
  return ({ active: 'mdi-check-circle', on_leave: 'mdi-pause-circle', suspended: 'mdi-alert-circle', terminated: 'mdi-close-circle', probation: 'mdi-clock-alert' } as any)[s] || 'mdi-help-circle'
})
const employmentLabel = computed(() => {
  const s = profile.value?.employment_status
  return ({ active: 'Active', on_leave: 'On Leave', suspended: 'Suspended', terminated: 'Terminated', probation: 'Probation' } as any)[s] || s || '—'
})
const mvrColor = computed(() => {
  const s = profile.value?.mvr_status
  return ({ clean: 'success', warning: 'warning', suspended: 'error', expired: 'grey' } as any)[s] || 'grey'
})
const mvrLabel = computed(() => {
  const s = profile.value?.mvr_status
  const label = s ? s.charAt(0).toUpperCase() + s.slice(1) : '—'
  return label
})

function fmtDate(v?: string) { return v ? new Date(v).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' }) : '—' }

function expiryClass(dateStr?: string) {
  if (!dateStr) return ''
  const d = new Date(dateStr)
  const now = new Date()
  const days = (d.getTime() - now.getTime()) / 86400000
  if (days < 0) return 'text-error font-weight-bold'
  if (days < 30) return 'text-warning font-weight-bold'
  return ''
}
function expiryColor(dateStr?: string) {
  if (!dateStr) return 'medium-emphasis'
  const d = new Date(dateStr)
  const now = new Date()
  const days = (d.getTime() - now.getTime()) / 86400000
  if (days < 0) return 'error'
  if (days < 30) return 'warning'
  return 'medium-emphasis'
}
function endorsementLabel(e: string) {
  return ({ hazmat: 'Hazmat (H)', tanker: 'Tanker (N)', passenger: 'Passenger (P)', school_bus: 'School Bus (S)', airbrake: 'Air Brake (L)', comb_tanker_hazmat: 'Tanker + Hazmat (X)' } as any)[e] || e
}
function severityColor(s: string) {
  return ({ minor: 'info', major: 'warning', critical: 'error' } as any)[s] || 'grey'
}
function resultColor(r: string) {
  return ({ negative: 'success', positive: 'error', refused: 'warning', pending: 'info' } as any)[r] || 'grey'
}
function resultIcon(r: string) {
  return ({ negative: 'mdi-check-circle', positive: 'mdi-alert-circle', refused: 'mdi-close-circle', pending: 'mdi-clock-outline' } as any)[r] || 'mdi-help-circle'
}
function trainingColor(s: string) {
  return ({ scheduled: 'info', in_progress: 'warning', completed: 'success', expired: 'error', failed: 'error' } as any)[s] || 'grey'
}
function trainingIcon(s: string) {
  return ({ scheduled: 'mdi-calendar-clock', in_progress: 'mdi-progress-clock', completed: 'mdi-check-circle', expired: 'mdi-alert-circle', failed: 'mdi-close-circle' } as any)[s] || 'mdi-school'
}
function noteColor(c: string) {
  return ({ general: 'grey', performance: 'info', incident: 'error', commendation: 'success', warning: 'warning', other: 'grey' } as any)[c] || 'grey'
}
</script>

<style scoped>
.drawer-head { padding: 16px 20px; }
.drawer-body { flex: 1; overflow-y: auto; padding: 16px 20px; }
.drawer-actions { padding: 12px 20px; border-top: 1px solid #e2e8f0; display: flex; align-items: center; gap: 8px; }
.section-block { margin-bottom: 20px; }
.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.info-item { display: flex; align-items: flex-start; gap: 8px; }
.driver-avatar { width: 56px; height: 56px; border-radius: 50%; display: flex; align-items: center; justify-content: center; overflow: hidden; flex-shrink: 0; font-weight: 700; font-size: 18px; }
.driver-avatar img { width: 100%; height: 100%; object-fit: cover; }
@media (max-width: 600px) { .info-grid { grid-template-columns: 1fr; } }
</style>
