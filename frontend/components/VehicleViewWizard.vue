<template>
  <div class="vehicle-wizard vehicle-wizard--vertical">
    <div class="wizard-rail">
      <div class="wizard-header pa-5">
        <div class="d-flex align-center ga-2 mb-1">
          <v-icon size="20" color="white">mdi-car</v-icon>
          <span class="text-h6 font-weight-bold text-white">Vehicle Details</span>
        </div>
        <p class="text-caption text-white opacity-80 mb-0">
          Step {{ currentStep + 1 }} of {{ steps.length }} · {{ steps[currentStep].title }}
        </p>
      </div>
      <div class="step-list pa-3">
        <div
          v-for="(step, i) in steps"
          :key="i"
          class="step-item"
          :class="{ active: currentStep === i }"
          @click="currentStep = i"
        >
          <div class="step-icon"><v-icon size="18">{{ step.icon }}</v-icon></div>
          <div class="step-text">
            <div class="step-title">{{ step.title }}</div>
            <div class="step-num">Step {{ i + 1 }}</div>
          </div>
        </div>
      </div>
    </div>

    <div class="wizard-main">
      <div class="wizard-header d-flex align-center ga-4 pa-5">
        <div
          v-if="vehicleImageUrl"
          class="wizard-header__image"
          :style="{ backgroundImage: `url(${vehicleImageUrl})` }"
        />
        <div class="d-flex flex-column flex-grow-1">
          <div class="d-flex align-center ga-2 mb-1">
            <v-icon size="20" color="white">mdi-car</v-icon>
            <span class="text-h6 font-weight-bold text-white">{{ vehicle?.display_name || 'Vehicle' }}</span>
          </div>
          <p class="text-caption text-white opacity-80 mb-0">
            Step {{ currentStep + 1 }} of {{ steps.length }} · {{ steps[currentStep].title }}
          </p>
        </div>
      </div>
      <v-divider />

      <div class="wizard-body pa-6">
        <v-window v-model="currentStep" class="step-window">
          <v-window-item v-for="(step, i) in steps" :key="i" :value="i">
            <p class="step-title-lg">{{ step.title }}</p>
            <p class="step-subtitle">{{ step.subtitle }}</p>

            <div v-if="step.sections" class="d-flex flex-column ga-4">
              <div v-for="section in step.sections" :key="section.title">
                <p v-if="section.title" class="text-caption font-weight-bold text-uppercase mb-2" style="color: #94a3b8; letter-spacing: 0.08em">{{ section.title }}</p>
                <v-row dense>
                  <v-col v-for="f in section.fields" :key="f.label" :cols="f.cols || 6">
                    <div class="text-caption text-medium-emphasis mb-1">{{ f.label }}</div>
                    <div class="text-body-2 field-value">{{ f.value == null || f.value === '' ? '—' : f.value }}</div>
                  </v-col>
                </v-row>
              </div>
            </div>

            <div v-else-if="step.key === 'maintenance'">
              <div v-if="!reminders.length" class="text-center py-8 text-medium-emphasis">
                <v-icon size="40" class="mb-2">mdi-wrench-clock-outline</v-icon>
                <p class="text-body-2">No reminders set for this vehicle.</p>
              </div>
              <div v-for="(r, idx) in reminders" :key="idx" class="reminder-row pa-3 mb-3 rounded-lg" style="border: 1px solid #e2e8f0">
                <v-row dense>
                  <v-col cols="12">
                    <div class="text-caption text-medium-emphasis mb-1">Title</div>
                    <div class="text-body-2 field-value">{{ r.title || '—' }}</div>
                  </v-col>
                  <v-col cols="6">
                    <div class="text-caption text-medium-emphasis mb-1">Trigger</div>
                    <div class="text-body-2 field-value">{{ enumLabel(triggerTypes, r.trigger_type) || '—' }}</div>
                  </v-col>
                  <v-col cols="6">
                    <div class="text-caption text-medium-emphasis mb-1">Interval</div>
                    <div class="text-body-2 field-value">{{ r.trigger_interval ? `${r.trigger_interval} ${triggerSuffix(r.trigger_type)}` : '—' }}</div>
                  </v-col>
                  <v-col cols="12">
                    <div class="text-caption text-medium-emphasis mb-1">Escalation Level</div>
                    <div class="text-body-2 field-value">{{ enumLabel(escalationLevels, r.escalation_level) || '—' }}</div>
                  </v-col>
                  <v-col cols="6">
                    <div class="text-caption text-medium-emphasis mb-1">Active</div>
                    <div class="text-body-2 field-value">{{ r.is_active ? 'Yes' : 'No' }}</div>
                  </v-col>
                </v-row>
              </div>
            </div>

            <div v-else-if="step.key === 'tires'">
              <VehicleTireManagement :vehicle-id="props.vehicleId" />
            </div>

            <div v-else-if="step.key === 'pnl'">
              <VehicleProfitLoss :vehicle-id="props.vehicleId" />
            </div>

            <div v-else-if="step.key === 'tco'">
              <VehicleCostOfOwnership :vehicle-id="props.vehicleId" />
            </div>

            <div v-else-if="step.key === 'specs'">
              <!-- Powertrain & Drivetrain -->
              <p class="spec-section-title mb-3">Powertrain &amp; Drivetrain</p>
              <v-row dense class="mb-3">
                <v-col cols="6"><div class="text-caption text-medium-emphasis mb-1">Fuel Type</div><div class="text-body-2 field-value">{{ vehicle?.fuel_type || '—' }}</div></v-col>
                <v-col v-if="!viewIsElectric" cols="6"><div class="text-caption text-medium-emphasis mb-1">Engine Size</div><div class="text-body-2 field-value">{{ vehicle?.engine_size || '—' }}</div></v-col>
                <v-col v-if="viewIsMotorized" cols="6"><div class="text-caption text-medium-emphasis mb-1">Motors</div><div class="text-body-2 field-value">{{ vehicle?.motors || '—' }}</div></v-col>
                <v-col cols="6"><div class="text-caption text-medium-emphasis mb-1">Transmission</div><div class="text-body-2 field-value">{{ vehicle?.transmission || '—' }}</div></v-col>
                <v-col cols="6"><div class="text-caption text-medium-emphasis mb-1">Drivetrain</div><div class="text-body-2 field-value">{{ drivetrainLabel || '—' }}</div></v-col>
                <v-col cols="6"><div class="text-caption text-medium-emphasis mb-1">Steering</div><div class="text-body-2 field-value">{{ steeringLabel || '—' }}</div></v-col>
              </v-row>

              <!-- Dimensions & Meters -->
              <p class="spec-section-title mb-3">Dimensions &amp; Meters</p>
              <v-row dense class="mb-3">
                <v-col cols="6"><div class="text-caption text-medium-emphasis mb-1">Trim</div><div class="text-body-2 field-value">{{ vehicle?.trim || '—' }}</div></v-col>
                <v-col cols="6"><div class="text-caption text-medium-emphasis mb-1">Weight Rating (GVWR)</div><div class="text-body-2 field-value">{{ vehicle?.weight_rating || '—' }}</div></v-col>
                <v-col cols="6"><div class="text-caption text-medium-emphasis mb-1">GVW (lbs)</div><div class="text-body-2 field-value">{{ vehicle?.gross_vehicle_weight ?? '—' }}</div></v-col>
                <v-col cols="6"><div class="text-caption text-medium-emphasis mb-1">Tank Capacity (gal)</div><div class="text-body-2 field-value">{{ vehicle?.tank_capacity ?? '—' }}</div></v-col>
                <v-col cols="6"><div class="text-caption text-medium-emphasis mb-1">Current Mileage</div><div class="text-body-2 field-value">{{ mileage() || '—' }}</div></v-col>
                <v-col cols="6"><div class="text-caption text-medium-emphasis mb-1">Mileage Unit</div><div class="text-body-2 field-value">{{ enumLabel(mileageUnits, vehicle?.mileage_unit) || '—' }}</div></v-col>
                <v-col cols="6"><div class="text-caption text-medium-emphasis mb-1">Engine Hours</div><div class="text-body-2 field-value">{{ vehicle?.engine_hours ?? '—' }}</div></v-col>
              </v-row>

              <!-- Exterior Color -->
              <p class="spec-section-title mb-3">Exterior Color</p>
              <div class="d-flex align-center ga-3 mb-4">
                <span class="view-color-swatch" :style="{ background: exteriorColorSwatch, border: exteriorColorBorder ? `1px solid ${exteriorColorBorder}` : '1px solid rgba(15,23,42,0.12)' }" />
                <span class="text-body-2 field-value text-capitalize">{{ exteriorColorLabel || '—' }}</span>
              </div>

              <!-- Features & Options -->
              <p class="spec-section-title mb-3">Features &amp; Options</p>
              <div class="feature-group">
                <div class="feature-group-head"><v-icon size="18" class="me-2" color="primary">mdi-sofa-single-outline</v-icon><span class="text-subtitle-2 font-weight-bold">Comfort &amp; Convenience</span><v-chip size="x-small" variant="tonal" class="ms-2">{{ (vehicle?.comfort_convenience || []).length }}</v-chip></div>
                <div v-if="(vehicle?.comfort_convenience || []).length" class="view-chip-wrap">
                  <span v-for="f in (vehicle?.comfort_convenience || [])" :key="f" class="view-chip">{{ f }}</span>
                </div>
                <p v-else class="text-body-2 text-medium-emphasis">No items selected.</p>
              </div>
              <div class="feature-group">
                <div class="feature-group-head"><v-icon size="18" class="me-2" color="primary">mdi-car-shift-pattern</v-icon><span class="text-subtitle-2 font-weight-bold">Dress Up</span><v-chip size="x-small" variant="tonal" class="ms-2">{{ (vehicle?.dress_up || []).length }}</v-chip></div>
                <div v-if="(vehicle?.dress_up || []).length" class="view-chip-wrap">
                  <span v-for="f in (vehicle?.dress_up || [])" :key="f" class="view-chip">{{ f }}</span>
                </div>
                <p v-else class="text-body-2 text-medium-emphasis">No items selected.</p>
              </div>
              <div class="feature-group">
                <div class="feature-group-head"><v-icon size="18" class="me-2" color="primary">mdi-car-convertible</v-icon><span class="text-subtitle-2 font-weight-bold">Exterior</span><v-chip size="x-small" variant="tonal" class="ms-2">{{ (vehicle?.exterior_features || []).length }}</v-chip></div>
                <div v-if="(vehicle?.exterior_features || []).length" class="view-chip-wrap">
                  <span v-for="f in (vehicle?.exterior_features || [])" :key="f" class="view-chip">{{ f }}</span>
                </div>
                <p v-else class="text-body-2 text-medium-emphasis">No items selected.</p>
              </div>
              <div class="feature-group">
                <div class="feature-group-head"><v-icon size="18" class="me-2" color="primary">mdi-shield-car-variant-outline</v-icon><span class="text-subtitle-2 font-weight-bold">Safety</span><v-chip size="x-small" variant="tonal" class="ms-2">{{ (vehicle?.safety_features || []).length }}</v-chip></div>
                <div v-if="(vehicle?.safety_features || []).length" class="view-chip-wrap">
                  <span v-for="f in (vehicle?.safety_features || [])" :key="f" class="view-chip">{{ f }}</span>
                </div>
                <p v-else class="text-body-2 text-medium-emphasis">No items selected.</p>
              </div>

              <!-- Power & Battery -->
              <template v-if="viewIsMotorized">
                <p class="spec-section-title mt-4 mb-3">Power &amp; Battery</p>
                <v-row dense>
                  <v-col cols="4"><div class="text-caption text-medium-emphasis mb-1">Battery (kWh)</div><div class="text-body-2 field-value">{{ vehicle?.battery_capacity_kwh ?? '—' }}</div></v-col>
                  <v-col cols="4"><div class="text-caption text-medium-emphasis mb-1">SoC (%)</div><div class="text-body-2 field-value">{{ vehicle?.state_of_charge ?? '—' }}</div></v-col>
                  <v-col cols="4"><div class="text-caption text-medium-emphasis mb-1">SoH (%)</div><div class="text-body-2 field-value">{{ vehicle?.state_of_health ?? '—' }}</div></v-col>
                </v-row>
              </template>
            </div>

            <div v-else-if="step.key === 'custom'">
              <div v-if="!customValues.length" class="text-center py-8 text-medium-emphasis">
                <v-icon size="40" class="mb-2">mdi-form-textbox</v-icon>
                <p class="text-body-2">No custom field values recorded.</p>
              </div>
              <v-row v-else dense>
                <v-col v-for="cv in customValues" :key="cv.field" cols="12">
                  <div class="text-caption text-medium-emphasis mb-1">{{ cv.label }}</div>
                  <div class="text-body-2 field-value">{{ cv.display || '—' }}</div>
                </v-col>
              </v-row>
            </div>
          </v-window-item>
        </v-window>
      </div>

      <v-divider />
      <div class="d-flex align-center justify-space-between pa-4">
        <v-btn variant="text" :disabled="currentStep === 0" @click="currentStep--">
          <v-icon start>mdi-arrow-left</v-icon> Back
        </v-btn>
        <div class="d-flex ga-2">
          <v-btn variant="text" @click="$emit('back')">Back to Vehicles</v-btn>
          <v-btn color="primary" prepend-icon="mdi-pencil-outline" @click="$emit('edit')">Edit Vehicle</v-btn>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ vehicleId: string | number }>()
const emit = defineEmits<{ back: []; edit: [] }>()

const { $api } = useNuxtApp()
const { fmtMoney: moneyFmt, load: loadCurrency } = useCurrency()

const currentStep = ref(0)
const vehicle = ref<any>(null)
const reminders = ref<any[]>([])
const customValues = ref<any[]>([])

const vehicleImageUrl = computed(() => {
  const url = vehicle.value?.image
  if (!url) return ''
  if (/^https?:\/\//i.test(url)) return url
  const base = (useRuntimeConfig().public.apiBase || '').replace(/\/api\/?$/, '')
  return `${base}/${url.replace(/^\/+/, '')}`
})

const triggerTypes = [
  { label: 'Time (Months)', value: 'time' },
  { label: 'Mileage', value: 'mileage' },
  { label: 'Engine Hours', value: 'engine_hours' },
]
const escalationLevels = [
  { label: 'None', value: 0 },
  { label: 'Email Driver', value: 1 },
  { label: 'SMS Manager', value: 2 },
  { label: 'Block Dispatch', value: 3 },
]
const mileageUnits = [{ label: 'Miles', value: 'miles' }, { label: 'Kilometers', value: 'km' }]
const depreciationMethods = [
  { label: 'Straight-Line', value: 'straight_line' },
  { label: 'Declining Balance', value: 'declining_balance' },
  { label: 'None', value: 'none' },
]
const insuranceTypes = [
  { label: 'Comprehensive', value: 'comprehensive' },
  { label: 'Third-Party', value: 'third_party' },
  { label: 'Third-Party, Fire & Theft', value: 'third_party_fire_theft' },
  { label: 'Liability', value: 'liability' },
  { label: 'Collision', value: 'collision' },
  { label: 'Gap Insurance', value: 'gap' },
  { label: 'Commercial Fleet', value: 'commercial_fleet' },
]
const drivetrainOptions = [
  { label: '2WD', value: '2WD' },
  { label: '4WD', value: '4WD' },
  { label: '4x2', value: '4-2' },
  { label: '4x4', value: '4-4' },
  { label: '6x2', value: '6-2' },
  { label: '6x4', value: '6-4' },
  { label: '8x4', value: '8-4' },
]
const steeringOptions = [
  { label: 'Right Hand', value: 'right' },
  { label: 'Left Hand', value: 'left' },
]
const exteriorColors = [
  { name: 'white', label: 'White', swatch: '#ffffff', border: '#cbd5e1' },
  { name: 'gray', label: 'Gray', swatch: '#9ca3af' },
  { name: 'black', label: 'Black', swatch: '#1f2937' },
  { name: 'gold', label: 'Gold', swatch: '#d4af37' },
  { name: 'pearl', label: 'Pearl', swatch: '#eae6da', border: '#cbd5e1' },
  { name: 'silver', label: 'Silver', swatch: '#c4c8cc' },
  { name: 'red', label: 'Red', swatch: '#dc2626' },
  { name: 'yellow', label: 'Yellow', swatch: '#f59e0b' },
  { name: 'green', label: 'Green', swatch: '#16a34a' },
  { name: 'blue', label: 'Blue', swatch: '#2563eb' },
  { name: 'purple', label: 'Purple', swatch: '#7c3aed' },
  { name: 'beige', label: 'Beige', swatch: '#e7d8b1' },
  { name: 'brown', label: 'Brown', swatch: '#78350f' },
  { name: 'other', label: 'Other', swatch: 'linear-gradient(135deg,#ef4444,#f59e0b,#10b981,#3b82f6,#a855f7)' },
]

const tc = useTenantCatalog()
onMounted(() => { tc.load(); loadCurrency() })

const bodyTypeLabel = computed(() => {
  const v = vehicle.value
  if (!v?.make || !v?.body_type) return v?.body_type || null
  const opts = tc.bodyTypeOptionsForMake(v.make) as any[]
  return opts.find((o) => o.value === v.body_type)?.label || v.body_type
})

const drivetrainLabel = computed(() => enumLabel(drivetrainOptions, vehicle.value?.drivetrain))
const steeringLabel = computed(() => enumLabel(steeringOptions, vehicle.value?.steering))
const viewIsElectric = computed(() => {
  const f = (vehicle.value?.fuel_type || '').toString()
  return /electric/i.test(f) || /^ev$/i.test(f)
})
const viewIsMotorized = computed(() => {
  const f = (vehicle.value?.fuel_type || '').toString()
  return /electric/i.test(f) || /^ev$/i.test(f) || /hybrid/i.test(f)
})

const exteriorColorLabel = computed(() => {
  const v = vehicle.value
  if (!v?.color) return null
  if (v.color === 'other') return v.exterior_color_custom ? `Other · ${v.exterior_color_custom}` : 'Other'
  return v.color
})
const exteriorColorSwatch = computed(() => {
  const v = vehicle.value
  if (!v?.color) return 'transparent'
  if (v.color === 'other') return v.exterior_color_custom || 'linear-gradient(135deg,#ef4444,#f59e0b,#10b981,#3b82f6,#a855f7)'
  const c = exteriorColors.find((o) => o.name === v.color)
  return c?.swatch || 'transparent'
})
const exteriorColorBorder = computed(() => {
  const v = vehicle.value
  if (!v?.color) return null
  return exteriorColors.find((o) => o.name === v.color)?.border || null
})

function enumLabel(list: any[], value: any) {
  if (value == null || value === '') return null
  return list.find((o) => o.value === value)?.label || value
}
function triggerSuffix(type: string) {
  return { time: 'months', mileage: 'mi', engine_hours: 'hrs' }[type] || ''
}
function fmtDate(d: any) {
  if (!d) return null
  return String(d).slice(0, 10)
}
function fmtMoney(v: any) {
  return moneyFmt(v, 2)
}
function mileage() {
  const v = vehicle.value
  if (v?.current_mileage == null) return null
  return `${Number(v.current_mileage).toLocaleString()} ${v.mileage_unit === 'miles' ? 'mi' : 'km'}`
}

const steps = computed(() => {
  const v = vehicle.value || {}
  const isLease = v.ownership === 'lease'
  return [
    {
      title: 'Details',
      icon: 'mdi-car-information',
      subtitle: 'Core identity and classification of the asset.',
      sections: [{
        fields: [
          { label: 'VIN', value: v.vin, cols: 12 },
          { label: 'License Plate', value: v.license_plate },
          { label: 'Year', value: v.year },
          { label: 'Make', value: v.make },
          { label: 'Body Type', value: bodyTypeLabel.value },
          { label: 'Model', value: v.model },
          { label: 'Vehicle Type', value: enumLabel([{ label: 'Vehicle', value: 'vehicle' }, { label: 'Trailer', value: 'trailer' }, { label: 'Equipment', value: 'equipment' }, { label: 'Non-powered', value: 'non_powered' }], v.vehicle_type) },
          { label: 'Status', value: v.status ? v.status.replace('_', ' ') : null },
          { label: 'Group', value: v.group_name, cols: 12 },
          { label: 'Location / Yard', value: v.location },
          { label: 'Assigned Driver', value: v.assigned_driver_name },
        ],
      }],
    },
    { title: 'Maintenance', icon: 'mdi-wrench', key: 'maintenance', subtitle: 'Preventive maintenance reminders for this vehicle.' },
    {
      title: 'Lifecycle', icon: 'mdi-calendar-sync', subtitle: 'Ownership and service lifecycle of the asset.',
      sections: [
        { title: 'Ownership', fields: [{ label: 'Ownership', value: v.ownership === 'lease' ? 'Leased' : 'Owned (Self)', cols: 12 }] },
        ...(isLease ? [{
          fields: [
            { label: 'Lessor', value: v.lessor_name, cols: 12 },
            { label: 'Lease Start Date', value: fmtDate(v.lease_start_date) },
            { label: 'Lease End Date', value: fmtDate(v.lease_end_date) },
          ],
        }] : []),
        { title: 'Service Timeline', fields: [
          { label: 'In Service Date', value: fmtDate(v.in_service_date) },
          { label: 'Out of Service Date', value: fmtDate(v.out_of_service_date) },
          { label: 'Retired Date', value: fmtDate(v.retired_date) },
        ] },
      ],
    },
    {
      title: 'Financials', icon: 'mdi-currency-usd',
      subtitle: isLease ? 'Lease cost details for this leased asset.' : 'Acquisition cost, depreciation and recurring financials.',
      sections: isLease ? [{
        fields: [
          { label: 'Lease Monthly Rate', value: fmtMoney(v.lease_monthly_rate) },
          { label: 'Deposit', value: fmtMoney(v.deposit) },
        ],
      }] : [{
        fields: [
          { label: 'Purchase Price', value: fmtMoney(v.purchase_price) },
          { label: 'Purchase Date', value: fmtDate(v.purchase_date) },
          { label: 'Salvage Value', value: fmtMoney(v.salvage_value) },
          { label: 'Useful Life (years)', value: v.useful_life_years },
          { label: 'Depreciation Method', value: enumLabel(depreciationMethods, v.depreciation_method) },
          { label: 'Residual Value', value: fmtMoney(v.residual_value) },
          { label: 'Monthly Payment', value: fmtMoney(v.monthly_payment) },
          { label: 'Annual Depreciation', value: fmtMoney(v.annual_depreciation) },
          { label: 'Current Book Value', value: fmtMoney(v.current_book_value) },
        ],
      }],
    },
    {
      title: 'Insurance', icon: 'mdi-shield-car', subtitle: 'Coverage type, policy period and premium for this vehicle.',
      sections: [{
        fields: [
          { label: 'Insurance Type', value: enumLabel(insuranceTypes, v.insurance_type), cols: 12 },
          { label: 'Policy Start Date', value: fmtDate(v.insurance_start_date) },
          { label: 'Policy End Date', value: fmtDate(v.insurance_end_date) },
          { label: 'Insurance Cost', value: fmtMoney(v.insurance_premium) },
        ],
      }],
    },
    { title: 'Specifications', icon: 'mdi-car-cog', key: 'specs', subtitle: 'Comprehensive technical, exterior and feature configuration.' },
    { title: 'Custom Fields', icon: 'mdi-form-textbox', key: 'custom', subtitle: 'Organization-specific attributes for this vehicle.' },
    { title: 'Tire Management', icon: 'mdi-tire', key: 'tires', subtitle: 'Tire mounts, rotations, inspections and movement history for this vehicle.' },
    { title: 'Profit and Loss', icon: 'mdi-chart-arc', key: 'pnl', subtitle: 'Per-vehicle profit and loss statement with revenue, costs, margins and trends.' },
    { title: 'Cost of Ownership', icon: 'mdi-calculator', key: 'tco', subtitle: 'Total cost of ownership — acquisition, depreciation, financing, insurance, energy, maintenance and full cost ledger.' },
  ]
})

async function load() {
  vehicle.value = await $api(`/vehicles/vehicles/${props.vehicleId}/`)
  const remRes = await $api(`/reminders/?vehicle=${props.vehicleId}`).catch(() => ({ results: [] }))
  reminders.value = remRes.results || remRes || []

  const [defs, vals] = await Promise.all([
    $api('/vehicles/custom-fields/').catch(() => ({ results: [] })),
    $api(`/vehicles/custom-field-values/?vehicle=${props.vehicleId}`).catch(() => ({ results: [] })),
  ])
  const defsList = defs.results || defs || []
  const valsList = vals.results || vals || []
  const defMap: Record<number, any> = {}
  for (const d of defsList) defMap[d.id] = d
  customValues.value = valsList.map((ev: any) => {
    const def = defMap[ev.field]
    return {
      field: ev.field,
      label: def?.display_label || def?.label || def?.name || `Field ${ev.field}`,
      display: def?.field_type === 'boolean' ? (ev.value === 'true' || ev.value === true ? 'Yes' : 'No') : ev.value,
    }
  })
}

onMounted(load)
</script>

<style scoped>
.wizard-header {
  background: linear-gradient(135deg, #6366f1 0%, #4f46e5 100%);
}
.wizard-header__image {
  width: 88px;
  height: 64px;
  border-radius: 12px;
  background-size: cover;
  background-position: center;
  background-color: rgba(255, 255, 255, 0.2);
  border: 1px solid rgba(255, 255, 255, 0.3);
  box-shadow: 0 4px 12px rgba(15, 23, 42, 0.2);
  flex-shrink: 0;
}
.wizard-body {
  min-height: 320px;
}
.reminder-row {
  background: #f8fafc;
}
.vehicle-wizard--vertical {
  display: flex;
  min-height: 600px;
}
.wizard-rail {
  width: 280px;
  flex-shrink: 0;
  background: #f8fafc;
  border-right: 1px solid #e2e8f0;
  display: flex;
  flex-direction: column;
}
.step-list {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.step-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  border-radius: 10px;
  cursor: pointer;
  transition: background 0.15s ease;
}
.step-item:hover {
  background: #eef2ff;
}
.step-item .step-icon {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #ffffff;
  border: 2px solid #e2e8f0;
  color: #94a3b8;
  flex-shrink: 0;
  transition: all 0.15s ease;
}
.step-item.active .step-icon {
  background: #6366f1;
  border-color: #6366f1;
  color: #ffffff;
}
.step-item .step-title {
  font-size: 14px;
  font-weight: 600;
  color: #64748b;
  line-height: 1.2;
}
.step-item .step-num {
  font-size: 11px;
  color: #94a3b8;
}
.step-item.active .step-title {
  color: #4f46e5;
}
.wizard-main {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
}
.field-value {
  color: #0f172a;
  word-break: break-word;
}
.step-title-lg {
  font-size: 18px;
  font-weight: 700;
  color: #0f172a;
  margin-bottom: 4px;
  letter-spacing: -0.01em;
}
.step-subtitle {
  font-size: 14px;
  color: #64748b;
  margin-bottom: 22px;
}
.spec-section-title {
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: #4f46e5;
  display: flex;
  align-items: center;
  gap: 8px;
}
.spec-section-title::before {
  content: '';
  width: 3px;
  height: 14px;
  background: linear-gradient(180deg, #6366f1, #4f46e5);
  border-radius: 2px;
}
.view-color-swatch {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: inline-block;
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.4);
}
.feature-group {
  margin-top: 14px;
  padding: 16px;
  border: 1px solid #eef2f6;
  border-radius: 14px;
  background: linear-gradient(180deg, #ffffff, #fbfcfe);
}
.feature-group-head {
  display: flex;
  align-items: center;
  margin-bottom: 12px;
}
.view-chip-wrap {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}
.view-chip {
  display: inline-flex;
  align-items: center;
  padding: 6px 12px;
  font-size: 12.5px;
  font-weight: 500;
  color: #4f46e5;
  background: #eef2ff;
  border: 1px solid #e0e7ff;
  border-radius: 999px;
}
</style>
