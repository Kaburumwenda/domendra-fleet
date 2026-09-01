<template>
  <div class="vrm-page">
    <!-- Top bar -->
    <div class="vrm-topbar">
      <v-btn variant="text" prepend-icon="mdi-arrow-left" @click="goBack">Back to Agreements</v-btn>
      <v-spacer />
      <v-btn variant="tonal" color="info" prepend-icon="mdi-download" :loading="loadingAgreement" @click="downloadAgree">Download</v-btn>
      <v-btn color="success" prepend-icon="mdi-check-circle" :loading="saving" @click="submitReturn">
        Complete Return
      </v-btn>
    </div>

    <v-progress-linear v-if="loadingAgreement" indeterminate color="primary" />

    <div v-if="agreement" class="vrm-content">
      <v-card rounded="xl" class="overflow-hidden" elevation="0" border>
        <!-- Premium header -->
        <div class="vrm-hero">
          <div class="vrm-hero-bg" />
          <div class="vrm-hero-content">
            <div class="vrm-hero-icon">
              <v-icon size="28" color="white">mdi-key-arrow-right</v-icon>
            </div>
            <div>
              <h2 class="vrm-hero-title">Vehicle Return</h2>
              <p class="vrm-hero-sub">{{ agreement.agreement_no }} · {{ agreement.vehicle_display || '—' }}</p>
            </div>
            <v-spacer />
            <v-chip v-if="agreement.status" :color="statusColor(agreement.status)" size="small" variant="flat" class="text-capitalize">
              {{ statusLabel(agreement.status) }}
            </v-chip>
          </div>
        </div>

        <div class="pa-5 pt-2">
          <!-- Summary strip -->
          <div class="vrm-summary">
            <div class="vrm-summary-item">
              <v-icon size="16" color="primary">mdi-account-outline</v-icon>
              <div>
                <span class="vrm-cap">Customer</span>
                <span class="vrm-val">{{ agreement.customer_name || '—' }}</span>
              </div>
            </div>
            <div class="vrm-summary-item">
              <v-icon size="16" color="primary">mdi-calendar-clock</v-icon>
              <div>
                <span class="vrm-cap">Rented</span>
                <span class="vrm-val">{{ fmtDate(agreement.start_datetime) }}</span>
              </div>
            </div>
            <div class="vrm-summary-item">
              <v-icon size="16" color="primary">mdi-calendar-end</v-icon>
              <div>
                <span class="vrm-cap">Due Back</span>
                <span class="vrm-val">{{ fmtDate(agreement.end_datetime) }}</span>
              </div>
            </div>
            <div class="vrm-summary-item">
              <v-icon size="16" color="primary">mdi-counter</v-icon>
              <div>
                <span class="vrm-cap">Start Mileage</span>
                <span class="vrm-val">{{ agreement.start_mileage ?? '—' }} km</span>
              </div>
            </div>
            <div class="vrm-summary-item">
              <v-icon size="16" color="primary">mdi-gauge</v-icon>
              <div>
                <span class="vrm-cap">Start Fuel</span>
                <span class="vrm-val">{{ fuelLevelName(agreement.start_fuel_level) }}</span>
              </div>
            </div>
          </div>

          <!-- § Return details -->
          <p class="vrm-section-title">
            <v-icon size="16" class="me-1" color="primary">mdi-clipboard-text-clock-outline</v-icon>
            Return Details
          </p>
          <v-row dense class="mb-1">
            <v-col cols="12" md="4">
              <v-text-field
                v-model="form.actual_return_datetime"
                type="datetime-local"
                label="Actual Return Date &amp; Time *"
                prepend-inner-icon="mdi-calendar-check"
                density="compact" variant="outlined" hide-details="auto"
              />
            </v-col>
            <v-col cols="12" md="4">
              <v-text-field
                v-model.number="form.end_mileage"
                type="number" label="End Mileage (km) *"
                :hint="mileageHint" persistent-hint
                prepend-inner-icon="mdi-counter" density="compact" variant="outlined" hide-details="auto"
              />
            </v-col>
            <v-col cols="12" md="4">
              <div class="vrm-fuel-pick">
                <label class="vrm-fuel-label">End Fuel Level *</label>
                <div class="vrm-fuel-chips">
                  <button
                    v-for="lvl in fuelLevels"
                    :key="lvl.value"
                    class="vrm-fuel-chip"
                    :class="{ 'vrm-fuel-chip--active': form.end_fuel_level === lvl.value }"
                    @click="form.end_fuel_level = lvl.value"
                  >{{ lvl.label }}</button>
                </div>
              </div>
            </v-col>
          </v-row>
          <v-row dense class="mb-2">
            <v-col cols="12" md="6">
              <div class="vrm-fuel-bar-wrap">
                <span class="vrm-fuel-caption">Start Gauge (pickup)</span>
                <div class="vrm-fuel-bar-track">
                  <div class="vrm-fuel-bar-fill" :style="{ width: startFuelPct + '%', background: fuelFillColor(startFuelPct) }">
                    <span class="vrm-fuel-bar-pct">{{ startFuelPct }}%</span>
                  </div>
                </div>
              </div>
            </v-col>
          </v-row>
          <v-row dense class="mb-2">
            <v-col cols="12">
              <div class="vrm-fuel-bar-wrap">
                <span class="vrm-fuel-caption">End Gauge (return) — drag to adjust</span>
                <div
                  ref="endFuelTrackRef"
                  class="vrm-fuel-bar-track vrm-fuel-bar-track--draggable"
                  @pointerdown="onEndFuelPointerDown"
                >
                  <div class="vrm-fuel-bar-ticks">
                    <div v-for="t in fuelTicks" :key="t" class="vrm-fuel-bar-tick" :class="{ 'vrm-fuel-bar-tick--major': t % 25 === 0 }" :style="{ left: t + '%' }"></div>
                  </div>
                  <div class="vrm-fuel-bar-fill" :style="{ width: endFuelPct + '%', background: fuelFillColor(endFuelPct) }"></div>
                  <div class="vrm-fuel-bar-knob" :style="{ left: endFuelPct + '%' }"></div>
                </div>
                <span class="vrm-fuel-hint">{{ fuelLevelName(form.end_fuel_level) }} · {{ endFuelPct }}%</span>
              </div>
            </v-col>
          </v-row>

          <!-- § Late / Excess summary -->
          <v-alert
            v-if="lateDays > 0 || excessKm > 0"
            type="warning" density="compact" variant="tonal" class="mb-3 mt-1"
            icon="mdi-alert-circle-outline"
          >
            <span v-if="lateDays > 0"><b>{{ lateDays }}</b> day(s) late · </span>
            <span v-if="excessKm > 0"><b>{{ excessKm.toLocaleString() }}</b> km excess</span>
          </v-alert>

          <!-- § Vehicle extras return check -->
          <p class="vrm-section-title">
            <v-icon size="16" class="me-1" color="primary">mdi-checkbox-marked-circle-outline</v-icon>
            Vehicle Extras — Return Check
          </p>
          <div class="vrm-extras-toolbar mb-2">
            <v-btn size="x-small" variant="tonal" color="success" prepend-icon="mdi-check-all" @click="markAllExtras('present')">All Present</v-btn>
            <v-btn size="x-small" variant="tonal" color="warning" prepend-icon="mdi-alert-circle-outline" @click="markAllExtras('missing')">All Missing</v-btn>
            <v-spacer />
            <span class="text-caption text-medium-emphasis">{{ form.vehicle_checks.length }} item(s)</span>
          </div>
          <v-table density="compact" class="vrm-extras-table mb-3">
            <thead>
              <tr><th style="width: 32%">Item</th><th style="width: 18%">Status</th><th>Notes</th></tr>
            </thead>
            <tbody>
              <tr v-for="(vc, i) in form.vehicle_checks" :key="vc.item_key">
                <td>
                  <v-icon size="14" class="me-1" :color="statusColor(vc.status)">{{ statusIcon(vc.status) }}</v-icon>
                  {{ vc.item_name }}
                </td>
                <td>
                  <v-select
                    v-model="vc.status" :items="checkStatusOptions"
                    item-title="label" item-value="value" density="compact"
                    variant="outlined" hide-details class="vrm-status-select"
                  />
                </td>
                <td>
                  <v-text-field v-model="vc.notes" density="compact" variant="outlined" hide-details placeholder="Notes…" />
                </td>
              </tr>
            </tbody>
          </v-table>

          <!-- § Vehicle inspection return check -->
          <p class="vrm-section-title" v-if="form.inspection_checks.length">
            <v-icon size="16" class="me-1" color="primary">mdi-clipboard-check-outline</v-icon>
            Vehicle Inspection — Return Check
          </p>
          <div v-if="form.inspection_checks.length" class="vrm-extras-toolbar mb-2">
            <v-btn size="x-small" variant="tonal" color="success" prepend-icon="mdi-check-all" @click="markAllInspection('pass')">All Pass</v-btn>
            <v-btn size="x-small" variant="tonal" color="error" prepend-icon="mdi-close-circle" @click="markAllInspection('fail')">All Fail</v-btn>
            <v-spacer />
            <span class="text-caption text-medium-emphasis">{{ form.inspection_checks.length }} item(s)</span>
          </div>
          <v-row v-if="form.inspection_checks.length" dense class="mb-3">
            <v-col v-for="(ic, i) in form.inspection_checks" :key="ic.item_key" cols="12" md="6" lg="4">
              <v-card variant="outlined" class="pa-3" :class="{ 'border-success': ic.status === 'pass', 'border-error': ic.status === 'fail', 'border-warning': ic.status === 'warning' }">
                <div class="text-body-2 font-weight-medium mb-2">{{ ic.item_name }}</div>
                <v-select v-model="ic.status" :items="inspectionStatusOptions" item-title="label" item-value="value" density="compact" variant="outlined" hide-details />
                <v-text-field v-model="ic.notes" label="Notes" density="compact" variant="outlined" hide-details class="mt-2" placeholder="e.g. Left headlight dim" />
                <div v-if="ic.item_key === 'headlights' && ic.status === 'fail'" class="mt-2">
                  <div class="text-caption font-weight-medium mb-1">Which headlights failed?</div>
                  <div class="d-flex flex-wrap ga-2">
                    <v-checkbox v-for="part in headlightParts" :key="part" v-model="ic.failed_parts" :value="part" density="compact" hide-details :label="part" />
                  </div>
                </div>
                <div v-if="ic.item_key === 'indicators' && ic.status === 'fail'" class="mt-2">
                  <div class="text-caption font-weight-medium mb-1">Which indicators failed?</div>
                  <div class="d-flex flex-wrap ga-2">
                    <v-checkbox v-for="part in indicatorParts" :key="part" v-model="ic.failed_parts" :value="part" density="compact" hide-details :label="part" />
                  </div>
                </div>
              </v-card>
            </v-col>
          </v-row>

          <!-- § Damages -->
          <p class="vrm-section-title">
            <v-icon size="16" class="me-1" color="primary">mdi-car-wrench</v-icon>
            Return Damages
            <v-btn size="x-small" variant="text" color="primary" prepend-icon="mdi-plus" class="ms-2" @click="addDamage">Add Damage</v-btn>
          </p>
          <v-alert v-if="!form.damages.length" type="info" density="compact" variant="tonal" class="mb-3">
            No damages recorded at return. Click "Add Damage" to log any new damage.
          </v-alert>
          <v-table v-else density="compact" class="mb-3 vrm-damages-table">
            <thead>
              <tr><th style="width: 24%">Location</th><th style="width: 24%">Severity</th><th>Description</th><th style="width: 14%">Repair Cost</th><th style="width: 40px"></th></tr>
            </thead>
            <tbody>
              <tr v-for="(d, i) in form.damages" :key="i">
                <td><v-text-field v-model="d.location" density="compact" variant="outlined" hide-details placeholder="e.g. Front bumper" /></td>
                <td>
                  <v-select v-model="d.severity" :items="severityOptions" density="compact" variant="outlined" hide-details class="vrm-status-select" />
                </td>
                <td><v-text-field v-model="d.description" density="compact" variant="outlined" hide-details placeholder="Description…" /></td>
                <td>
                  <v-text-field
                    v-model.number="d.repair_cost" type="number"
                    :prefix="currencySymbol" density="compact" variant="outlined" hide-details
                  />
                </td>
                <td><v-btn icon="mdi-close" size="x-small" variant="text" color="error" @click="form.damages.splice(i, 1)" /></td>
              </tr>
            </tbody>
          </v-table>

          <!-- § Additional charges -->
          <p class="vrm-section-title">
            <v-icon size="16" class="me-1" color="primary">mdi-receipt-text-outline</v-icon>
            Additional Return Charges
            <v-btn size="x-small" variant="text" color="primary" prepend-icon="mdi-plus" class="ms-2" @click="addCharge">Add Charge</v-btn>
          </p>
          <v-alert v-if="!form.charges.length" type="info" density="compact" variant="tonal" class="mb-3">
            No additional charges. Use "Add Charge" for late return, excess mileage, fuel refill, cleaning, etc.
          </v-alert>
          <v-table v-else density="compact" class="mb-3 vrm-charges-table">
            <thead>
              <tr><th style="width: 22%">Type</th><th>Description</th><th style="width: 10%">Qty</th><th style="width: 16%">Unit</th><th style="width: 16%">Total</th><th style="width: 40px"></th></tr>
            </thead>
            <tbody>
              <tr v-for="(c, i) in form.charges" :key="i">
                <td>
                  <v-select v-model="c.charge_type" :items="returnChargeTypes" item-title="label" item-value="value" density="compact" variant="outlined" hide-details class="vrm-status-select" />
                </td>
                <td><v-text-field v-model="c.description" density="compact" variant="outlined" hide-details placeholder="Description…" /></td>
                <td><v-text-field v-model.number="c.quantity" type="number" density="compact" variant="outlined" hide-details @update:model-value="c.total_amount = Number(c.quantity||0) * Number(c.unit_amount||0)" /></td>
                <td><v-text-field v-model.number="c.unit_amount" type="number" :prefix="currencySymbol" density="compact" variant="outlined" hide-details @update:model-value="c.total_amount = Number(c.quantity||0) * Number(c.unit_amount||0)" /></td>
                <td><v-text-field v-model.number="c.total_amount" type="number" :prefix="currencySymbol" density="compact" variant="outlined" hide-details /></td>
                <td><v-btn icon="mdi-close" size="x-small" variant="text" color="error" @click="form.charges.splice(i, 1)" /></td>
              </tr>
            </tbody>
          </v-table>

          <!-- § Quick add common charges -->
          <div class="vrm-quick-charges mb-4">
            <v-btn size="small" variant="tonal" color="warning" prepend-icon="mdi-clock-alert-outline" :disabled="lateDays <= 0" @click="addLateReturnCharge">
              Add Late Return ({{ lateDays }}d)
            </v-btn>
            <v-btn size="small" variant="tonal" color="info" prepend-icon="mdi-road-variant" :disabled="excessKm <= 0" @click="addExcessMileageCharge">
              Add Excess Mileage ({{ excessKm.toLocaleString() }}km)
            </v-btn>
            <v-btn size="small" variant="tonal" color="error" prepend-icon="mdi-gas-station" :disabled="fuelShort" @click="addFuelRefillCharge">
              Add Fuel Refill
            </v-btn>
            <v-btn size="small" variant="tonal" prepend-icon="mdi-car-wash" @click="addCleaningCharge">
              Add Cleaning
            </v-btn>
          </div>

          <!-- § Summary totals -->
          <div class="vrm-summary-box">
            <div class="vrm-summary-row"><span>Return Damages Cost</span><span>{{ currencySymbol }}{{ damagesTotal.toFixed(2) }}</span></div>
            <div class="vrm-summary-row"><span>Additional Charges</span><span>{{ currencySymbol }}{{ chargesTotal.toFixed(2) }}</span></div>
            <div class="vrm-summary-row vrm-summary-grand"><span>Total Return Adjustments</span><span>{{ currencySymbol }}{{ (damagesTotal + chargesTotal).toFixed(2) }}</span></div>
          </div>
        </div>
      </v-card>
    </div>

    <div v-if="!loadingAgreement && !agreement" class="text-center pa-10">
      <v-icon size="48" color="grey-lighten-1">mdi-alert-circle-outline</v-icon>
      <p class="text-body-1 text-medium-emphasis mt-2">Agreement not found.</p>
      <v-btn variant="text" color="primary" prepend-icon="mdi-arrow-left" @click="goBack">Back to Agreements</v-btn>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'fullwidth' })

const route = useRoute()
const router = useRouter()
const { $api, $swal } = useNuxtApp()
const { currencySymbol } = useCurrency()

const agreementId = computed(() => Number(route.params.id))
const agreement = ref<any>(null)
const loadingAgreement = ref(true)
const saving = ref(false)

/* ---- Load agreement ---- */
onMounted(async () => {
  try {
    agreement.value = await $api(`/rentals/agreements/${agreementId.value}/`)
  } catch {
    agreement.value = null
  } finally {
    loadingAgreement.value = false
  }
  if (!agreement.value) return
  seedForm()
})

/* ---- Constants (mirrored from VehicleReturnModal) ---- */
const fuelLevels = [
  { value: 'empty', label: 'E', percent: 0, name: 'Empty' },
  { value: 'quarter', label: '¼', percent: 25, name: '¼ Tank' },
  { value: 'half', label: 'H', percent: 50, name: 'Half' },
  { value: 'three_quarter', label: '¾', percent: 75, name: '¾ Tank' },
  { value: 'full', label: 'F', percent: 100, name: 'Full' },
]
const checkStatusOptions = [
  { label: 'Present', value: 'present', color: 'success' },
  { label: 'Missing', value: 'missing', color: 'warning' },
  { label: 'Damaged', value: 'damaged', color: 'error' },
  { label: 'N/A', value: 'n_a', color: 'grey' },
]
const inspectionStatusOptions = [
  { label: 'Pass', value: 'pass', color: 'success' },
  { label: 'Fail', value: 'fail', color: 'error' },
  { label: 'Warning', value: 'warning', color: 'warning' },
  { label: 'N/A', value: 'n_a', color: 'grey' },
]
const severityOptions = ['none', 'minor', 'moderate', 'severe']
const returnChargeTypes = [
  { label: 'Late Return', value: 'late_return' },
  { label: 'Excess Mileage', value: 'excess_mileage' },
  { label: 'Fuel Refill', value: 'fuel_refill' },
  { label: 'Cleaning', value: 'cleaning' },
  { label: 'Damage', value: 'damage' },
  { label: 'Other', value: 'other' },
]

/* ---- Form state ---- */
const form = reactive({
  actual_return_datetime: toLocalInput(new Date()),
  end_mileage: null as number | null,
  end_fuel_level: 'full',
  vehicle_checks: [] as Array<{ item_key: string; item_name: string; status: string; notes: string }>,
  inspection_checks: [] as Array<{ item_key: string; item_name: string; status: string; notes: string; failed_parts: string[] }>,
  damages: [] as Array<{ location: string; description: string; severity: string; repair_cost: number }>,
  charges: [] as Array<{ charge_type: string; description: string; quantity: number; unit_amount: number; total_amount: number }>,
})

function seedForm() {
  const a = agreement.value
  if (!a) return
  form.end_mileage = a.end_mileage ?? null
  form.end_fuel_level = a.end_fuel_level || 'full'
  // Seed return checks from pickup checks (same items, blank for return)
  const pickupChecks = (a.vehicle_checks || []).filter((vc: any) => vc.stage === 'pickup')
  form.vehicle_checks = pickupChecks.map((vc: any) => ({
    item_key: vc.item_key,
    item_name: vc.item_name,
    status: 'present',
    notes: '',
  }))
  // Seed return inspection checks from pickup inspection checks
  form.inspection_checks = (a.inspection_checks || []).map((ic: any) => ({
    item_key: ic.item_key,
    item_name: ic.item_name,
    status: 'pass',
    notes: '',
    failed_parts: [],
  }))
}

/* ---- Helpers ---- */
function toLocalInput(d: Date) {
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
}
function fmtDate(d: any) {
  if (!d) return '—'
  return String(d).slice(0, 16).replace('T', ' ')
}
function statusLabel(s: string) { return (s || 'draft').replace('_', ' ') }
function statusColor(s: string) {
  const map: Record<string, string> = { draft: 'default', active: 'success', completed: 'info', cancelled: 'error', overdue: 'warning' }
  return map[s] || 'default'
}
function statusIcon(s: string) {
  const map: Record<string, string> = { present: 'mdi-check-circle', missing: 'mdi-alert-circle', damaged: 'mdi-car-wrench', n_a: 'mdi-minus-circle' }
  return map[s] || 'mdi-help-circle'
}
const headlightParts = ['All', 'Left Headlight', 'Right Headlight', 'High Beam Left', 'High Beam Right', 'Low Beam Left', 'Low Beam Right']
const indicatorParts = ['All', 'Front Left', 'Front Right', 'Rear Left', 'Rear Right', 'Side Left', 'Side Right']

/* ---- Fuel ---- */
function fuelPctOf(val: any): number {
  if (!val) return 0
  const named = fuelLevels.find((l) => l.value === val)
  if (named) return named.percent
  const num = Number(String(val).replace('%', ''))
  return isNaN(num) ? 0 : Math.max(0, Math.min(100, num))
}
const endFuelPct = computed(() => fuelPctOf(form.end_fuel_level))
const startFuelPct = computed(() => fuelPctOf(agreement.value?.start_fuel_level))

/* ---- Draggable end fuel gauge ---- */
const fuelTicks = Array.from({ length: 21 }, (_, i) => i * 5)
const FUEL_SNAP_PCT = 5
const endFuelTrackRef = ref<HTMLElement | null>(null)
let _fuelDragTrack: HTMLElement | null = null

function snapAndSetEndFuel(pct: number) {
  const snapped = Math.round(pct / FUEL_SNAP_PCT) * FUEL_SNAP_PCT
  const named = fuelLevels.find((l) => l.percent === snapped)
  form.end_fuel_level = named ? named.value : `${snapped}%`
}

function onEndFuelPointerDown(e: PointerEvent) {
  _fuelDragTrack = e.currentTarget as HTMLElement
  updateFromPointer(e)
  window.addEventListener('pointermove', _onEndFuelPointerMove)
  window.addEventListener('pointerup', _onEndFuelPointerUp, { once: true })
}

function updateFromPointer(e: PointerEvent) {
  if (!_fuelDragTrack) return
  const rect = _fuelDragTrack.getBoundingClientRect()
  const pct = Math.max(0, Math.min(100, ((e.clientX - rect.left) / rect.width) * 100))
  snapAndSetEndFuel(pct)
}

function _onEndFuelPointerMove(e: PointerEvent) { updateFromPointer(e) }
function _onEndFuelPointerUp() {
  _fuelDragTrack = null
  window.removeEventListener('pointermove', _onEndFuelPointerMove)
}

onUnmounted(() => {
  window.removeEventListener('pointermove', _onEndFuelPointerMove)
  window.removeEventListener('pointerup', _onEndFuelPointerUp)
})
function fuelLevelName(val: any) {
  if (!val) return '—'
  const named = fuelLevels.find((l) => l.value === val)
  return named ? named.name : String(val)
}
function fuelFillColor(pct: number) {
  if (pct <= 0) return 'linear-gradient(90deg, #ef4444, #f87171)'
  if (pct <= 25) return 'linear-gradient(90deg, #f59e0b, #fbbf24)'
  if (pct <= 50) return 'linear-gradient(90deg, #eab308, #facc15)'
  if (pct <= 75) return 'linear-gradient(90deg, #84cc16, #a3e635)'
  return 'linear-gradient(90deg, #22c55e, #4ade80)'
}

/* ---- Late / excess computed ---- */
const dueDate = computed(() => new Date(agreement.value?.end_datetime || new Date()))
const returnDate = computed(() => {
  if (!form.actual_return_datetime) return new Date()
  return new Date(form.actual_return_datetime)
})
const lateDays = computed(() => {
  const ms = returnDate.value.getTime() - dueDate.value.getTime()
  if (ms <= 0) return 0
  return Math.floor(ms / (24 * 60 * 60 * 1000))
})
const excessKm = computed(() => {
  const free = Number(agreement.value?.free_mileage || 0)
  if (!free) return 0
  const end = Number(form.end_mileage || 0)
  const start = Number(agreement.value?.start_mileage || 0)
  const used = end - start
  return used > free ? used - free : 0
})
const mileageHint = computed(() => {
  const start = Number(agreement.value?.start_mileage || 0)
  const end = Number(form.end_mileage || 0)
  return `${Math.max(0, end - start).toLocaleString()} km used`
})
const fuelShort = computed(() => {
  const policy = agreement.value?.fuel_policy
  const endPct = endFuelPct.value
  if (policy === 'full_full') return endPct < 100
  if (policy === 'half_tank') return endPct < 50
  return false
})

/* ---- Mutations ---- */
function markAllExtras(status: string) {
  form.vehicle_checks.forEach((vc) => { vc.status = status })
}
function markAllInspection(status: string) {
  form.inspection_checks.forEach((ic) => { ic.status = status })
}
function addDamage() {
  form.damages.push({ location: '', description: '', severity: 'minor', repair_cost: 0 })
}
function addCharge() {
  form.charges.push({ charge_type: 'other', description: '', quantity: 1, unit_amount: 0, total_amount: 0 })
}
function addLateReturnCharge() {
  if (lateDays.value <= 0) return
  const rate = Number(agreement.value?.daily_rate || 0)
  form.charges.push({
    charge_type: 'late_return',
    description: `${lateDays.value} day(s) late return`,
    quantity: lateDays.value,
    unit_amount: rate,
    total_amount: lateDays.value * rate,
  })
}
function addExcessMileageCharge() {
  if (excessKm.value <= 0) return
  const rate = Number(agreement.value?.excess_mileage_rate || 0)
  form.charges.push({
    charge_type: 'excess_mileage',
    description: `${excessKm.value.toLocaleString()} km excess mileage`,
    quantity: excessKm.value,
    unit_amount: rate,
    total_amount: excessKm.value * rate,
  })
}
function addFuelRefillCharge() {
  const startPct = fuelPctOf(agreement.value?.start_fuel_level)
  const endPct = endFuelPct.value
  const diff = Math.max(0, startPct - endPct)
  if (diff <= 0) return
  form.charges.push({
    charge_type: 'fuel_refill',
    description: `Fuel refill (${diff}% short of ${fuelLevelName(agreement.value?.start_fuel_level)})`,
    quantity: 1,
    unit_amount: diff * 50,
    total_amount: diff * 50,
  })
}
function addCleaningCharge() {
  form.charges.push({
    charge_type: 'cleaning',
    description: 'Vehicle cleaning fee',
    quantity: 1,
    unit_amount: 500,
    total_amount: 500,
  })
}

/* ---- Computed totals ---- */
const damagesTotal = computed(() => form.damages.reduce((s, d) => s + Number(d.repair_cost || 0), 0))
const chargesTotal = computed(() => form.charges.reduce((s, c) => s + Number(c.total_amount || 0), 0))

/* ---- Navigation ---- */
function goBack() {
  router.push('/app/rentals')
}

/* ---- Download (simple invoice-style pop-up) ---- */
async function downloadAgree() {
  if (!agreement.value) return
  const a = agreement.value
  const w = window.open('', '_blank', 'width=900,height=1100')
  if (!w) {
    $swal.fire({ icon: 'warning', title: 'Popup blocked', text: 'Allow popups to download the agreement.', toast: true, timer: 2500, position: 'top-end' })
    return
  }
  const chargesHtml = form.charges.length
    ? form.charges.map((c: any) => `<tr><td>${(c.charge_type || '').replace('_', ' ')}</td><td>${c.description || '—'}</td><td>${c.quantity || 1}</td><td>${c.unit_amount || 0}</td><td><b>${c.total_amount || 0}</b></td></tr>`).join('')
    : '<tr><td colspan="5" style="text-align:center;color:#94a3b8">No additional charges.</td></tr>'
  const damagesHtml = form.damages.length
    ? form.damages.map((d: any) => `<tr><td>${d.location || '—'}</td><td>${d.description || '—'}</td><td>${(d.severity || 'none').replace('_', ' ')}</td><td>${d.repair_cost || 0}</td></tr>`).join('')
    : '<tr><td colspan="4" style="text-align:center;color:#94a3b8">No damages recorded.</td></tr>'
  const inspectionHtml = form.inspection_checks.length
    ? form.inspection_checks.map((ic: any) => `<tr><td>${ic.item_name || '—'}</td><td style="text-transform:capitalize">${(ic.status || '').replace('_', ' ')}</td><td>${(ic.failed_parts && ic.failed_parts.length) ? ic.failed_parts.join(', ') : '—'}</td><td>${ic.notes || '—'}</td></tr>`).join('')
    : '<tr><td colspan="4" style="text-align:center;color:#94a3b8">No inspection recorded.</td></tr>'
  w.document.write(`<!DOCTYPE html><html><head><meta charset="utf-8"><title>${a.agreement_no} Return</title>
  <style>body{font-family:'Segoe UI',Arial,sans-serif;color:#1e293b;padding:30px;max-width:820px;margin:0 auto}
  h1{font-size:22px;margin:10px 0}
  .ref-badge{background:#eef2ff;color:#4f46e5;padding:6px 12px;border-radius:6px;font-weight:700;font-family:monospace}
  .section-title{font-size:12px;text-transform:uppercase;letter-spacing:0.05em;color:#4f46e5;font-weight:700;margin:18px 0 8px;border-left:3px solid #6366f1;padding-left:8px}
  table{width:100%;border-collapse:collapse;margin-bottom:12px}
  th{background:#f8fafc;text-align:left;padding:8px;border:1px solid #e2e8f0;font-size:12px}
  td{padding:8px;border:1px solid #e2e8f0;font-size:12px}
  .grid{display:grid;grid-template-columns:1fr 1fr;gap:6px 24px;margin-bottom:8px}
  .grid div{font-size:12px;padding:6px 0;border-bottom:1px dashed #e2e8f0}
  .grid b{color:#475569;font-weight:600;display:block;font-size:10px;text-transform:uppercase;letter-spacing:0.05em;margin-bottom:2px}
  </style></head><body>
  <div style="display:flex;justify-content:space-between;align-items:center;border-bottom:3px solid #6366f1;padding-bottom:16px;margin-bottom:24px">
    <div><h1 style="margin:0">Vehicle Return Receipt</h1></div>
    <div class="ref-badge">${a.agreement_no}</div>
  </div>
  <div class="grid">
    <div><b>Customer</b>${a.customer_name || '—'}</div>
    <div><b>Vehicle</b>${a.vehicle_display || '—'}</div>
    <div><b>Rented</b>${fmtDate(a.start_datetime)}</div>
    <div><b>Due Back</b>${fmtDate(a.end_datetime)}</div>
    <div><b>Actual Return</b>${form.actual_return_datetime || '—'}</div>
    <div><b>End Mileage</b>${form.end_mileage || '—'} km</div>
    <div><b>End Fuel</b>${fuelLevelName(form.end_fuel_level)}</div>
  </div>
  <div class="section-title">Damages</div>
  <table><thead><tr><th>Location</th><th>Description</th><th>Severity</th><th>Repair Cost</th></tr></thead><tbody>${damagesHtml}</tbody></table>
  <div class="section-title">Vehicle Inspection</div>
  <table><thead><tr><th>Item</th><th>Status</th><th>Failed Parts</th><th>Notes</th></tr></thead><tbody>${inspectionHtml}</tbody></table>
  <div class="section-title">Additional Charges</div>
  <table><thead><tr><th>Type</th><th>Description</th><th>Qty</th><th>Unit</th><th>Total</th></tr></thead><tbody>${chargesHtml}</tbody></table>
  ${(a.terms_and_conditions && a.terms_and_conditions.length) ? `
  <div class="section-title">Terms &amp; Conditions</div>
  <div style="font-size:11px;color:#475569;line-height:1.6">
    ${a.terms_and_conditions.map((t:any) => `<p style="margin:8px 0"><b>${t.id}. ${t.title}</b><br/>${t.text}</p>`).join('')}
  </div>` : ''}
  </body></html>`)
  w.document.close()
  setTimeout(() => { w.focus(); w.print() }, 400)
}

/* ---- Submit ---- */
async function submitReturn() {
  if (!form.actual_return_datetime) {
    $swal.fire({ icon: 'warning', title: 'Actual return date is required', toast: true, timer: 2000, position: 'top-end' })
    return
  }
  if (form.end_mileage === null || form.end_mileage === undefined || form.end_mileage === '') {
    $swal.fire({ icon: 'warning', title: 'End mileage is required', toast: true, timer: 2000, position: 'top-end' })
    return
  }
  if (!form.end_fuel_level) {
    $swal.fire({ icon: 'warning', title: 'End fuel level is required', toast: true, timer: 2000, position: 'top-end' })
    return
  }

  const confirm = await $swal.fire({
    icon: 'question',
    title: 'Complete vehicle return?',
    html: `This will mark <b>${agreement.value.agreement_no}</b> as completed and record the return details.<br><br>
      <small>End Mileage: ${form.end_mileage} km · End Fuel: ${fuelLevelName(form.end_fuel_level)}<br>
      Damages: ${form.damages.length} · Charges: ${form.charges.length}</small>`,
    showCancelButton: true,
    confirmButtonText: 'Complete Return',
    confirmButtonColor: '#10b981',
  })
  if (!confirm.isConfirmed) return

  saving.value = true
  try {
    const payload: any = {
      actual_return_datetime: form.actual_return_datetime.length === 16 ? form.actual_return_datetime + ':00' : form.actual_return_datetime,
      end_mileage: form.end_mileage,
      end_fuel_level: form.end_fuel_level,
      damages: form.damages,
      vehicle_checks: form.vehicle_checks,      inspection_checks: form.inspection_checks,      charges: form.charges,
    }
    await $api(`/rentals/agreements/${agreement.value.id}/complete/`, {
      method: 'POST', body: payload,
    })
    $swal.fire({ icon: 'success', title: 'Return completed', toast: true, timer: 1800, position: 'top-end' })
    router.push('/app/rentals')
  } catch (e: any) {
    $swal.fire({
      icon: 'error',
      title: 'Failed to complete return',
      text: e?.data?.detail || e?.message || 'Unknown error',
      toast: true, timer: 2500, position: 'top-end',
    })
  } finally {
    saving.value = false
  }
}
</script>

<style scoped>
.vrm-page {
  width: 90%;
  max-width: 1400px;
  margin: 0 auto;
  padding: 24px;
}

.vrm-topbar {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 16px;
}

.vrm-content {
  /* card container */
}

/* Hero header */
.vrm-hero {
  position: relative;
  padding: 18px 22px;
  overflow: hidden;
  border-radius: 16px 16px 0 0;
}
.vrm-hero-bg {
  position: absolute; inset: 0;
  background: linear-gradient(135deg, #4f46e5 0%, #6366f1 50%, #818cf8 100%);
}
.vrm-hero-content {
  position: relative;
  display: flex; align-items: center; gap: 14px;
}
.vrm-hero-icon {
  width: 48px; height: 48px;
  border-radius: 12px;
  background: rgba(255,255,255,0.18);
  display: flex; align-items: center; justify-content: center;
  backdrop-filter: blur(4px);
}
.vrm-hero-title {
  color: #fff; font-size: 19px; font-weight: 700;
  margin: 0; line-height: 1.2;
}
.vrm-hero-sub {
  color: rgba(255,255,255,0.85); font-size: 12px; margin: 0;
}

/* Summary strip */
.vrm-summary {
  display: flex; flex-wrap: wrap;
  gap: 0;
  padding: 12px 0;
  background: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
  border-radius: 8px;
  margin-bottom: 12px;
}
.vrm-summary-item {
  display: flex; align-items: center; gap: 8px;
  padding: 4px 16px 4px 0;
  flex: 1 1 180px;
  min-width: 180px;
}
.vrm-summary-item > div { display: flex; flex-direction: column; }
.vrm-cap {
  font-size: 9px; color: #94a3b8; text-transform: uppercase;
  letter-spacing: 0.06em; font-weight: 600;
}
.vrm-val {
  font-size: 13px; color: #1e293b; font-weight: 600;
}

.vrm-section-title {
  font-size: 12px; font-weight: 700; color: #4f46e5;
  text-transform: uppercase; letter-spacing: 0.05em;
  margin: 16px 0 8px;
  padding-left: 8px;
  border-left: 3px solid #6366f1;
  display: flex; align-items: center;
  flex-wrap: wrap;
}

/* Fuel picker */
.vrm-fuel-pick { padding-top: 4px; }
.vrm-fuel-label {
  display: block; font-size: 11px; color: #64748b;
  font-weight: 600; margin-bottom: 6px;
}
.vrm-fuel-chips { display: flex; gap: 6px; }
.vrm-fuel-chip {
  width: 38px; height: 38px;
  border: 1.5px solid #cbd5e1; border-radius: 8px;
  background: #fff; cursor: pointer;
  font-size: 13px; font-weight: 700; color: #64748b;
  transition: all 0.15s;
}
.vrm-fuel-chip:hover { border-color: #6366f1; color: #4f46e5; }
.vrm-fuel-chip--active {
  border-color: #4f46e5; background: #4f46e5; color: #fff;
  transform: scale(1.05);
  box-shadow: 0 2px 8px rgba(79, 70, 229, 0.3);
}
.vrm-fuel-bar-wrap { padding: 6px 0; }
.vrm-fuel-caption {
  display: block; font-size: 10px; color: #94a3b8;
  text-transform: uppercase; letter-spacing: 0.05em; font-weight: 600;
  margin-bottom: 4px;
}
.vrm-fuel-bar-track {
  position: relative; width: 100%; height: 28px;
  background: linear-gradient(180deg, #ffffff, #f1f5f9);
  border: 1px solid #cbd5e1; border-radius: 8px; overflow: hidden;
}
.vrm-fuel-bar-track--draggable {
  cursor: pointer; overflow: visible; touch-action: none;
  height: 34px; margin-top: 4px; margin-bottom: 6px;
  border-radius: 10px;
}
.vrm-fuel-bar-track--draggable:hover .vrm-fuel-bar-knob {
  transform: translate(-50%, -50%) scale(1.25);
}
.vrm-fuel-bar-fill {
  position: relative; height: 100%;
  border-radius: 7px; transition: width 0.2s cubic-bezier(0.4,0,0.2,1), background 0.3s ease;
  min-width: 0; pointer-events: none; z-index: 2;
}
.vrm-fuel-bar-track--draggable .vrm-fuel-bar-fill { border-radius: 10px; }
.vrm-fuel-bar-pct {
  position: absolute; top: 50%; left: 50%;
  transform: translate(-50%, -50%);
  font-size: 11px; font-weight: 700; color: #fff;
  text-shadow: 0 1px 2px rgba(0,0,0,0.3);
}
.vrm-fuel-bar-ticks {
  position: absolute; inset: 0; pointer-events: none; z-index: 3;
}
.vrm-fuel-bar-tick {
  position: absolute; top: 0; bottom: 0; width: 1px;
  background: rgba(100, 116, 139, 0.25);
  transform: translateX(-50%);
}
.vrm-fuel-bar-tick--major {
  width: 2px; background: rgba(71, 85, 105, 0.5);
}
.vrm-fuel-bar-knob {
  position: absolute; top: 50%;
  width: 18px; height: 18px; border-radius: 50%;
  background: #fff; border: 3px solid #6366f1;
  box-shadow: 0 2px 8px rgba(99, 102, 241, 0.35);
  transform: translate(-50%, -50%);
  transition: transform 0.15s ease, left 0.2s cubic-bezier(0.4,0,0.2,1);
  pointer-events: none; z-index: 4;
}
.vrm-fuel-hint {
  display: block; font-size: 10px; color: #64748b;
  text-align: center; margin-top: 2px;
}

/* Extras toolbar */
.vrm-extras-toolbar {
  display: flex; align-items: center; gap: 8px;
}
.vrm-extras-table :deep(th),
.vrm-damages-table :deep(th),
.vrm-charges-table :deep(th) {
  font-size: 11px; text-transform: uppercase; letter-spacing: 0.04em;
  color: #64748b; font-weight: 700;
  padding: 6px 8px;
}
.vrm-extras-table :deep(td),
.vrm-damages-table :deep(td),
.vrm-charges-table :deep(td) {
  padding: 4px 8px;
  vertical-align: middle;
}
.vrm-status-select {
  min-width: 120px;
}

/* Quick charges */
.vrm-quick-charges {
  display: flex; flex-wrap: wrap; gap: 8px;
}

/* Summary box */
.vrm-summary-box {
  background: linear-gradient(180deg, #ffffff, #f8fafc);
  border: 1px solid #eef2f6;
  border-radius: 12px;
  padding: 14px 18px;
  margin-top: 12px;
}
.vrm-summary-row {
  display: flex; justify-content: space-between;
  padding: 5px 0; font-size: 13px; color: #475569;
  border-bottom: 1px dashed #e2e8f0;
}
.vrm-summary-grand {
  font-size: 15px; font-weight: 800; color: #4f46e5;
  border-bottom: none; padding-top: 10px;
}
</style>
