<template>
  <div class="pricing-details-page">
    <!-- Loading state -->
    <div v-if="loading" class="d-flex justify-center align-center" style="min-height: 400px">
      <v-progress-circular indeterminate size="48" color="primary" />
    </div>

    <!-- Error state -->
    <div v-else-if="error" class="text-center py-16">
      <v-icon size="56" color="error" class="mb-4">mdi-alert-circle-outline</v-icon>
      <h3 class="text-h6 mb-2">Unable to Load Pricing Plan</h3>
      <p class="text-body-2 text-medium-emphasis mb-4">{{ error }}</p>
      <v-btn variant="tonal" color="primary" prepend-icon="mdi-arrow-left" @click="goBack">Back to Pricing</v-btn>
    </div>

    <template v-else-if="plan">
      <!-- ============ Hero Header ============ -->
      <v-card rounded="xl" class="overflow-hidden mb-4 pd-hero-card" elevation="0" border>
        <div class="pd-hero">
          <div class="pd-hero-top">
            <div class="d-flex align-center ga-3">
              <v-btn icon variant="text" size="small" dark @click="goBack">
                <v-icon>mdi-arrow-left</v-icon>
              </v-btn>
              <v-avatar size="64" rounded="xl" class="pd-avatar">
                <v-icon size="32" color="white">{{ plan.apply_to === 'group' ? 'mdi-folder-multiple' : 'mdi-car-multiple' }}</v-icon>
              </v-avatar>
              <div>
                <h2 class="text-h5 font-weight-bold text-white" style="line-height: 1.2">
                  {{ plan.name }}
                </h2>
                <div class="d-flex align-center ga-2 mt-1">
                  <v-chip size="x-small" :color="plan.is_active ? 'success' : 'grey'" variant="flat">
                    <v-icon size="12" start>mdi-circle</v-icon>
                    {{ plan.is_active ? 'Active' : 'Inactive' }}
                  </v-chip>
                  <v-chip size="x-small" :color="plan.apply_to === 'group' ? 'warning' : 'info'" variant="flat" class="text-capitalize">
                    <v-icon size="12" start>{{ plan.apply_to === 'group' ? 'mdi-folder-multiple' : 'mdi-car-multiple' }}</v-icon>
                    {{ plan.apply_to === 'group' ? (plan.vehicle_group_name || 'All Groups') : `${(plan.vehicle_list || []).length} vehicle(s)` }}
                  </v-chip>
                  <span class="text-caption text-white" style="opacity: 0.75">{{ `Plan #${plan.id}` }}</span>
                </div>
              </div>
            </div>

            <div class="d-none d-md-flex align-center ga-2">
              <v-btn v-can="'rentals:update'" variant="outlined" color="white" size="small" prepend-icon="mdi-pencil-outline" @click="goEdit">
                Edit
              </v-btn>
              <v-btn v-can="'rentals:delete'" variant="outlined" color="white" size="small" prepend-icon="mdi-trash-can-outline" @click="deletePlan">
                Delete
              </v-btn>
            </div>
          </div>

          <!-- Quick stats row -->
          <div class="pd-hero-stats">
            <div class="pd-quick-stat">
              <v-icon size="18" color="white">mdi-calendar-today</v-icon>
              <div>
                <div class="text-caption text-white" style="opacity: 0.7">Daily Rate</div>
                <div class="text-body-2 font-weight-medium text-white">{{ symbol }}{{ Number(plan.daily_rate || 0).toLocaleString() }}</div>
              </div>
            </div>
            <div class="pd-quick-stat">
              <v-icon size="18" color="white">mdi-calendar-week</v-icon>
              <div>
                <div class="text-caption text-white" style="opacity: 0.7">Weekly Rate</div>
                <div class="text-body-2 font-weight-medium text-white">{{ symbol }}{{ Number(plan.weekly_rate || 0).toLocaleString() }}</div>
              </div>
            </div>
            <div class="pd-quick-stat">
              <v-icon size="18" color="white">mdi-calendar-month</v-icon>
              <div>
                <div class="text-caption text-white" style="opacity: 0.7">Monthly Rate</div>
                <div class="text-body-2 font-weight-medium text-white">{{ symbol }}{{ Number(plan.monthly_rate || 0).toLocaleString() }}</div>
              </div>
            </div>
            <div class="pd-quick-stat">
              <v-icon size="18" color="white">mdi-calendar-clock</v-icon>
              <div>
                <div class="text-caption text-white" style="opacity: 0.7">Weekend Rate</div>
                <div class="text-body-2 font-weight-medium text-white">{{ symbol }}{{ Number(plan.weekend_rate || 0).toLocaleString() }}</div>
              </div>
            </div>
          </div>
        </div>
      </v-card>

      <!-- ============ Main Content Grid ============ -->
      <v-row dense>
        <!-- LEFT: Base Rates + Discounts + Custom Rate -->
        <v-col cols="12" lg="8">
          <!-- Plan Overview -->
          <v-card rounded="xl" class="mb-4 pd-info-card" elevation="0" border>
            <div class="pd-card-header">
              <v-icon color="primary" size="20">mdi-information-outline</v-icon>
              <span>Plan Overview</span>
            </div>
            <v-card-text class="pa-5">
              <v-row dense>
                <v-col cols="12" sm="6" md="4">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-tag-text-outline</v-icon>Plan Name</div>
                    <div class="info-value">{{ plan.name || '—' }}</div>
                  </div>
                </v-col>
                <v-col cols="12" sm="6" md="4">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-toggle-switch-outline</v-icon>Status</div>
                    <div class="info-value">
                      <v-chip size="x-small" :color="plan.is_active ? 'success' : 'grey'" variant="flat">{{ plan.is_active ? 'Active' : 'Inactive' }}</v-chip>
                    </div>
                  </div>
                </v-col>
                <v-col cols="12" sm="6" md="4">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-shape-outline</v-icon>Applies To</div>
                    <div class="info-value text-capitalize">
                      <v-chip size="x-small" :color="plan.apply_to === 'group' ? 'warning' : 'info'" variant="flat">
                        <v-icon size="12" start>{{ plan.apply_to === 'group' ? 'mdi-folder-multiple' : 'mdi-car-multiple' }}</v-icon>
                        {{ plan.apply_to === 'group' ? (plan.vehicle_group_name || 'All Groups') : `${(plan.vehicle_list || []).length} vehicle(s)` }}
                      </v-chip>
                    </div>
                  </div>
                </v-col>
                <v-col cols="12" sm="6" md="4">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-calendar-start</v-icon>Valid From</div>
                    <div class="info-value">{{ formatDate(plan.valid_from) }}</div>
                  </div>
                </v-col>
                <v-col cols="12" sm="6" md="4">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-calendar-end</v-icon>Valid To</div>
                    <div class="info-value">{{ formatDate(plan.valid_to) }}</div>
                  </div>
                </v-col>
                <v-col cols="12">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-text-outline</v-icon>Description</div>
                    <div class="info-value" style="font-weight:400; line-height:1.5">{{ plan.description || '—' }}</div>
                  </div>
                </v-col>
              </v-row>
            </v-card-text>
          </v-card>

          <!-- Base Rates & Discounts -->
          <v-card rounded="xl" class="mb-4 pd-info-card" elevation="0" border>
            <div class="pd-card-header">
              <v-icon color="primary" size="20">mdi-cash-multiple</v-icon>
              <span>Base Rates &amp; Discounts</span>
            </div>
            <v-card-text class="pa-5">
              <v-row dense>
                <!-- Daily -->
                <v-col cols="12" sm="6" md="3">
                  <div class="rate-block">
                    <div class="rate-block-header">
                      <v-icon size="16" color="primary">mdi-calendar-today</v-icon>
                      <span class="rate-title">Daily Rate</span>
                    </div>
                    <div class="rate-value">{{ symbol }}{{ Number(plan.daily_rate || 0).toLocaleString() }}</div>
                    <div class="rate-badges">
                      <v-chip v-if="Number(plan.daily_discount_percent || 0) > 0" size="x-small" color="success" variant="flat">-{{ plan.daily_discount_percent }}% off</v-chip>
                      <v-chip v-if="Number(plan.daily_markup_percent || 0) > 0" size="x-small" color="error" variant="flat">+{{ plan.daily_markup_percent }}% markup</v-chip>
                    </div>
                  </div>
                </v-col>
                <!-- Weekly -->
                <v-col cols="12" sm="6" md="3">
                  <div class="rate-block">
                    <div class="rate-block-header">
                      <v-icon size="16" color="primary">mdi-calendar-week</v-icon>
                      <span class="rate-title">Weekly Rate</span>
                    </div>
                    <div class="rate-value">{{ symbol }}{{ Number(plan.weekly_rate || 0).toLocaleString() }}</div>
                    <div class="rate-badges">
                      <v-chip v-if="Number(plan.weekly_discount_percent || 0) > 0" size="x-small" color="success" variant="flat">-{{ plan.weekly_discount_percent }}% off</v-chip>
                      <v-chip v-if="Number(plan.weekly_markup_percent || 0) > 0" size="x-small" color="error" variant="flat">+{{ plan.weekly_markup_percent }}% markup</v-chip>
                    </div>
                  </div>
                </v-col>
                <!-- Weekend -->
                <v-col cols="12" sm="6" md="3">
                  <div class="rate-block">
                    <div class="rate-block-header">
                      <v-icon size="16" color="primary">mdi-calendar-clock</v-icon>
                      <span class="rate-title">Weekend Rate</span>
                    </div>
                    <div class="rate-value">{{ symbol }}{{ Number(plan.weekend_rate || 0).toLocaleString() }}</div>
                    <div class="rate-badges">
                      <v-chip v-if="Number(plan.weekend_discount_percent || 0) > 0" size="x-small" color="success" variant="flat">-{{ plan.weekend_discount_percent }}% off</v-chip>
                      <v-chip v-if="Number(plan.weekend_markup_percent || 0) > 0" size="x-small" color="error" variant="flat">+{{ plan.weekend_markup_percent }}% markup</v-chip>
                    </div>
                  </div>
                </v-col>
                <!-- Monthly -->
                <v-col cols="12" sm="6" md="3">
                  <div class="rate-block">
                    <div class="rate-block-header">
                      <v-icon size="16" color="primary">mdi-calendar-month</v-icon>
                      <span class="rate-title">Monthly Rate</span>
                    </div>
                    <div class="rate-value">{{ symbol }}{{ Number(plan.monthly_rate || 0).toLocaleString() }}</div>
                    <div class="rate-badges">
                      <v-chip v-if="Number(plan.monthly_discount_percent || 0) > 0" size="x-small" color="success" variant="flat">-{{ plan.monthly_discount_percent }}% off</v-chip>
                      <v-chip v-if="Number(plan.monthly_markup_percent || 0) > 0" size="x-small" color="error" variant="flat">+{{ plan.monthly_markup_percent }}% markup</v-chip>
                    </div>
                  </div>
                </v-col>
              </v-row>

              <!-- Custom Rate -->
              <v-divider class="my-4" />
              <div class="text-caption font-weight-bold text-primary mb-3">CUSTOM RATE</div>
              <v-row dense>
                <v-col cols="12" sm="4">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-tag-outline</v-icon>Label</div>
                    <div class="info-value">{{ plan.custom_rate_label || '—' }}</div>
                  </div>
                </v-col>
                <v-col cols="12" sm="4">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-cash</v-icon>Value</div>
                    <div class="info-value">{{ plan.custom_rate_value ? `${symbol}${Number(plan.custom_rate_value).toLocaleString()}` : '—' }}</div>
                  </div>
                </v-col>
                <v-col cols="12" sm="4">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-calendar-multiple</v-icon>Days Covered</div>
                    <div class="info-value">{{ plan.custom_rate_days ? `${plan.custom_rate_days} day(s)` : '—' }}</div>
                  </div>
                </v-col>
              </v-row>
            </v-card-text>
          </v-card>

          <!-- Add-On Fees -->
          <v-card rounded="xl" class="mb-4 pd-info-card" elevation="0" border>
            <div class="pd-card-header">
              <v-icon color="primary" size="20">mdi-plus-circle-outline</v-icon>
              <span>Add-On Fees</span>
            </div>
            <v-card-text class="pa-5">
              <v-row dense>
                <v-col cols="12" sm="6" md="4">
                  <div class="fee-item">
                    <div class="fee-icon" style="background:#eff6ff; color:#2563eb;"><v-icon size="18">mdi-shield-car</v-icon></div>
                    <div class="fee-meta">
                      <div class="fee-name">Insurance Premium</div>
                      <div class="fee-value">{{ symbol }}{{ Number(plan.insurance_premium || 0).toLocaleString() }}</div>
                    </div>
                  </div>
                </v-col>
                <v-col cols="12" sm="6" md="4">
                  <div class="fee-item">
                    <div class="fee-icon" style="background:#f0fdf4; color:#16a34a;"><v-icon size="18">mdi-crosshairs-gps</v-icon></div>
                    <div class="fee-meta">
                      <div class="fee-name">GPS Fee</div>
                      <div class="fee-value">{{ symbol }}{{ Number(plan.gps_fee || 0).toLocaleString() }}</div>
                    </div>
                  </div>
                </v-col>
                <v-col cols="12" sm="6" md="4">
                  <div class="fee-item">
                    <div class="fee-icon" style="background:#fff7ed; color:#ea580c;"><v-icon size="18">mdi-baby-carriage</v-icon></div>
                    <div class="fee-meta">
                      <div class="fee-name">Child Seat</div>
                      <div class="fee-value">{{ symbol }}{{ Number(plan.child_seat_fee || 0).toLocaleString() }}</div>
                    </div>
                  </div>
                </v-col>
                <v-col cols="12" sm="6" md="4">
                  <div class="fee-item">
                    <div class="fee-icon" style="background:#f5f3ff; color:#7c3aed;"><v-icon size="18">mdi-account-plus</v-icon></div>
                    <div class="fee-meta">
                      <div class="fee-name">Additional Driver</div>
                      <div class="fee-value">{{ symbol }}{{ Number(plan.additional_driver_fee || 0).toLocaleString() }}</div>
                    </div>
                  </div>
                </v-col>
                <v-col cols="12" sm="6" md="4">
                  <div class="fee-item">
                    <div class="fee-icon" style="background:#ecfdf5; color:#059669;"><v-icon size="18">mdi-account-tie</v-icon></div>
                    <div class="fee-meta">
                      <div class="fee-name">Driver Fee</div>
                      <div class="fee-value">{{ symbol }}{{ Number(plan.driver_fee || 0).toLocaleString() }}</div>
                    </div>
                  </div>
                </v-col>
                <v-col cols="12" sm="6" md="4">
                  <div class="fee-item">
                    <div class="fee-icon" style="background:#fef3c7; color:#d97706;"><v-icon size="18">mdi-truck-fast</v-icon></div>
                    <div class="fee-meta">
                      <div class="fee-name">Delivery Fee</div>
                      <div class="fee-value">{{ symbol }}{{ Number(plan.delivery_fee || 0).toLocaleString() }}</div>
                    </div>
                  </div>
                </v-col>
                <v-col cols="12" sm="6" md="4">
                  <div class="fee-item">
                    <div class="fee-icon" style="background:#e0f2fe; color:#0284c7;"><v-icon size="18">mdi-car-wash</v-icon></div>
                    <div class="fee-meta">
                      <div class="fee-name">Prep Fee</div>
                      <div class="fee-value">{{ symbol }}{{ Number(plan.prep_fee || 0).toLocaleString() }}</div>
                    </div>
                  </div>
                </v-col>
                <v-col cols="12" sm="6" md="4">
                  <div class="fee-item">
                    <div class="fee-icon" style="background:#f1f5f9; color:#475569;"><v-icon size="18">mdi-clock-time-nine</v-icon></div>
                    <div class="fee-meta">
                      <div class="fee-name">After Hours</div>
                      <div class="fee-value">{{ symbol }}{{ Number(plan.after_hours_fee || 0).toLocaleString() }}</div>
                    </div>
                  </div>
                </v-col>
                <v-col cols="12" sm="6" md="4">
                  <div class="fee-item">
                    <div class="fee-icon" style="background:#fef2f2; color:#ef4444;"><v-icon size="18">mdi-account-alert</v-icon></div>
                    <div class="fee-meta">
                      <div class="fee-name">Underage Fee</div>
                      <div class="fee-value">{{ symbol }}{{ Number(plan.underage_fee || 0).toLocaleString() }}</div>
                    </div>
                  </div>
                </v-col>
                <v-col cols="12" sm="6" md="4">
                  <div class="fee-item">
                    <div class="fee-icon" style="background:#fdf4ff; color:#c026d3;"><v-icon size="18">mdi-arrow-decision</v-icon></div>
                    <div class="fee-meta">
                      <div class="fee-name">One Way Fee</div>
                      <div class="fee-value">{{ symbol }}{{ Number(plan.one_way_fee || 0).toLocaleString() }}</div>
                    </div>
                  </div>
                </v-col>
              </v-row>
            </v-card-text>
          </v-card>
        </v-col>

        <!-- RIGHT: Deposits + Mileage & Tax + Applied Vehicles + Metadata -->
        <v-col cols="12" lg="4">
          <!-- Deposits -->
          <v-card rounded="xl" class="mb-4 pd-info-card" elevation="0" border>
            <div class="pd-card-header">
              <v-icon color="primary" size="20">mdi-cash-lock</v-icon>
              <span>Deposits</span>
            </div>
            <v-card-text class="pa-5">
              <div class="deposit-item">
                <div class="deposit-icon" style="background:#eff6ff; color:#2563eb;"><v-icon size="18">mdi-cash-multiple</v-icon></div>
                <div>
                  <div class="deposit-name">General Deposit</div>
                  <div class="deposit-value">{{ symbol }}{{ Number(plan.deposit_amount || 0).toLocaleString() }}</div>
                </div>
              </div>
              <div class="deposit-item">
                <div class="deposit-icon" style="background:#f0fdf4; color:#16a34a;"><v-icon size="18">mdi-shield-check-outline</v-icon></div>
                <div>
                  <div class="deposit-name">Security Deposit</div>
                  <div class="deposit-value">{{ symbol }}{{ Number(plan.security_deposit || 0).toLocaleString() }}</div>
                </div>
              </div>
              <div class="deposit-item">
                <div class="deposit-icon" style="background:#fef2f2; color:#ef4444;"><v-icon size="18">mdi-car-brake-alert</v-icon></div>
                <div>
                  <div class="deposit-name">Damage Deposit</div>
                  <div class="deposit-value">{{ symbol }}{{ Number(plan.damage_deposit || 0).toLocaleString() }}</div>
                </div>
              </div>
            </v-card-text>
          </v-card>

          <!-- Mileage & Tax -->
          <v-card rounded="xl" class="mb-4 pd-info-card" elevation="0" border>
            <div class="pd-card-header">
              <v-icon color="primary" size="20">mdi-speedometer</v-icon>
              <span>Mileage &amp; Tax</span>
            </div>
            <v-card-text class="pa-5">
              <v-row dense>
                <v-col cols="6">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-road-variant</v-icon>Free Mileage</div>
                    <div class="info-value">{{ plan.free_mileage ? `${Number(plan.free_mileage).toLocaleString()} / day` : 'Unlimited' }}</div>
                  </div>
                </v-col>
                <v-col cols="6">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-cash-fast</v-icon>Excess Rate</div>
                    <div class="info-value">{{ plan.excess_mileage_rate ? `${symbol}${Number(plan.excess_mileage_rate).toLocaleString()}` : '—' }}</div>
                  </div>
                </v-col>
                <v-col cols="6">
                  <div class="info-item">
                    <div class="info-label"><v-icon size="14">mdi-percent-outline</v-icon>Tax %</div>
                    <div class="info-value">{{ plan.tax_percent ? `${plan.tax_percent}%` : '—' }}</div>
                  </div>
                </v-col>
              </v-row>
            </v-card-text>
          </v-card>

          <!-- Applied Vehicles (if applicable) -->
          <v-card v-if="plan.apply_to === 'vehicles' && (plan.vehicle_list || []).length" rounded="xl" class="mb-4 pd-info-card" elevation="0" border>
            <div class="pd-card-header">
              <v-icon color="primary" size="20">mdi-car-multiple</v-icon>
              <span>Applied Vehicles ({{ plan.vehicle_list.length }})</span>
            </div>
            <v-card-text class="pa-5">
              <div v-for="v in plan.vehicle_list" :key="v.id" class="vehicle-pill">
                <v-icon size="16" color="info">mdi-car</v-icon>
                <span>{{ v.display_name || `Vehicle #${v.id}` }}</span>
              </div>
            </v-card-text>
          </v-card>

          <!-- Metadata -->
          <v-card rounded="xl" class="pd-info-card" elevation="0" border>
            <div class="pd-card-header">
              <v-icon color="primary" size="20">mdi-clock-outline</v-icon>
              <span>Metadata</span>
            </div>
            <v-card-text class="pa-5">
              <div class="info-item">
                <div class="info-label"><v-icon size="14">mdi-clock-plus-outline</v-icon>Created</div>
                <div class="info-value">{{ formatDateTime(plan.created_at) }}</div>
              </div>
              <div class="info-item">
                <div class="info-label"><v-icon size="14">mdi-clock-edit-outline</v-icon>Last Updated</div>
                <div class="info-value">{{ formatDateTime(plan.updated_at) }}</div>
              </div>
            </v-card-text>
          </v-card>
        </v-col>
      </v-row>
    </template>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

const { $api, $swal } = useNuxtApp()
const { symbol } = useCurrency()
const router = useRouter()
const route = useRoute()

const planId = computed(() => route.params.id ? Number(route.params.id) : null)

const loading = ref(true)
const error = ref('')
const plan = ref<any>(null)

function goBack() {
  router.push('/app/rentals?tab=pricing')
}

function goEdit() {
  router.push(`/app/rentals?tab=pricing&edit=${planId.value}`)
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

async function loadPlan() {
  if (!planId.value) {
    error.value = 'Invalid pricing plan ID'
    loading.value = false
    return
  }
  loading.value = true
  try {
    plan.value = await $api(`/rentals/pricing/${planId.value}/`)
  } catch (e: any) {
    error.value = e?.data?.detail || e?.message || 'Failed to load pricing plan'
  } finally {
    loading.value = false
  }
}

async function deletePlan() {
  if (!plan.value) return
  const name = plan.value.name
  const r = await $swal.fire({
    icon: 'warning',
    title: `Delete ${name}?`,
    text: 'This action cannot be undone.',
    showCancelButton: true,
    confirmButtonText: 'Delete',
    confirmButtonColor: '#ef4444',
  })
  if (!r.isConfirmed) return
  try {
    await $api(`/rentals/pricing/${planId.value}/`, { method: 'DELETE' })
    $swal.fire({ icon: 'success', title: 'Pricing plan deleted', toast: true, timer: 1500, position: 'top-end' })
    goBack()
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Delete failed', text: e?.data?.detail || e?.message || '', toast: true, timer: 2500, position: 'top-end' })
  }
}

onMounted(() => {
  loadPlan()
})
</script>

<style scoped>
.pricing-details-page {
  width: 100%;
}

/* ============ Hero Header ============ */
.pd-hero-card {
  border: none;
}
.pd-hero {
  background: linear-gradient(135deg, #4f46e5 0%, #6366f1 50%, #818cf8 100%);
  padding: 24px 28px 0;
}
.pd-hero-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
  padding-bottom: 8px;
}
.pd-avatar {
  background: rgba(255, 255, 255, 0.2);
  backdrop-filter: blur(4px);
  border: 2px solid rgba(255, 255, 255, 0.3);
}

/* Quick stats */
.pd-hero-stats {
  display: flex;
  flex-wrap: wrap;
  gap: 0;
  margin: 16px -28px 0;
  padding: 0 28px;
  border-top: 1px solid rgba(255, 255, 255, 0.15);
}
.pd-quick-stat {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 14px 20px 16px 0;
  flex: 1 1 180px;
  min-width: 180px;
}
.pd-quick-stat > .v-icon {
  background: rgba(255, 255, 255, 0.15);
  border-radius: 8px;
  padding: 6px;
}

/* ============ Info Cards ============ */
.pd-info-card {
  border: 1px solid #e2e8f0;
}
.pd-card-header {
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

/* ============ Rate Blocks ============ */
.rate-block {
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 16px;
  background: #f8fafc;
  height: 100%;
}
.rate-block-header {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 8px;
}
.rate-title {
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  color: #64748b;
}
.rate-value {
  font-size: 1.25rem;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 6px;
}
.rate-badges {
  display: flex;
  gap: 4px;
  flex-wrap: wrap;
}

/* ============ Fee Items ============ */
.fee-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 0;
}
.fee-icon {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.fee-meta {
  flex: 1;
  min-width: 0;
}
.fee-name {
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  color: #94a3b8;
}
.fee-value {
  font-size: 0.95rem;
  font-weight: 700;
  color: #1e293b;
}

/* ============ Deposit Items ============ */
.deposit-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 0;
  border-bottom: 1px dashed #e2e8f0;
}
.deposit-item:last-child {
  border-bottom: none;
  padding-bottom: 0;
}
.deposit-item:first-child {
  padding-top: 0;
}
.deposit-icon {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.deposit-name {
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  color: #94a3b8;
}
.deposit-value {
  font-size: 1rem;
  font-weight: 700;
  color: #1e293b;
}

/* ============ Vehicle Pills ============ */
.vehicle-pill {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  border-radius: 8px;
  background: #f1f5f9;
  font-size: 0.85rem;
  font-weight: 500;
  color: #1e293b;
  margin-bottom: 6px;
}
.vehicle-pill:last-child {
  margin-bottom: 0;
}
</style>
