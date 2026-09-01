<template>
  <div class="rav-page">
    <!-- Top bar -->
    <div class="rav-topbar">
      <v-btn variant="text" prepend-icon="mdi-arrow-left" @click="goBack">Back to Agreements</v-btn>
      <v-spacer />
      <v-btn variant="tonal" color="info" prepend-icon="mdi-download" :loading="loadingAgreement" @click="downloadAgree">Download</v-btn>
      <v-btn v-can="'rentals:update'" color="warning" prepend-icon="mdi-pencil" @click="editAgreement">Edit</v-btn>
    </div>

    <div v-if="loadingAgreement" class="d-flex justify-center align-center" style="min-height: 400px">
      <v-progress-circular indeterminate size="48" color="primary" />
    </div>

    <div v-else-if="agreement" class="rav-content">
      <!-- Hero -->
      <div class="rav-hero">
        <div class="rav-hero-bg" />
        <div class="rav-hero-content">
          <div class="rav-hero-icon">
            <v-icon size="28" color="white">mdi-file-document-outline</v-icon>
          </div>
          <div>
            <h2 class="rav-hero-title">Rental Agreement</h2>
            <p class="rav-hero-sub">{{ agreement.agreement_no }}</p>
          </div>
          <v-spacer />
          <div class="rav-hero-status" :class="`rav-status-badge--${agreement.status}`">
            {{ statusLabel }}
          </div>
        </div>
      </div>

      <!-- Status info bar -->
      <div class="rav-info-strip">
        <div class="rav-info-item">
          <v-icon size="18" color="primary">mdi-account</v-icon>
          <div>
            <span class="rav-cap">Customer</span>
            <span class="rav-val">{{ agreement.customer_name || '—' }}</span>
          </div>
        </div>
        <div class="rav-info-item">
          <v-icon size="18" color="primary">mdi-car</v-icon>
          <div>
            <span class="rav-cap">Vehicle</span>
            <span class="rav-val">{{ agreement.vehicle_display || '—' }}</span>
          </div>
        </div>
        <div class="rav-info-item">
          <v-icon size="18" color="primary">mdi-calendar-clock</v-icon>
          <div>
            <span class="rav-cap">Created</span>
            <span class="rav-val">{{ formatDate(agreement.created_at) }}</span>
          </div>
        </div>
      </div>

      <!-- Customer -->
      <p class="rav-section-title"><v-icon size="16" class="me-1" color="primary">mdi-account</v-icon> Customer</p>
      <v-row dense class="mb-2">
        <v-col cols="6" md="4"><div class="rav-field"><label>Name</label><div>{{ agreement.customer_name || '—' }}</div></div></v-col>
        <v-col cols="6" md="2"><div class="rav-field"><label>Type</label><div class="text-capitalize">{{ agreement.customer_type || '—' }}</div></div></v-col>
        <v-col cols="6" md="3"><div class="rav-field"><label>Phone</label><div>{{ agreement.customer_phone || '—' }}</div></div></v-col>
        <v-col cols="6" md="3"><div class="rav-field"><label>Email</label><div>{{ agreement.customer_email || '—' }}</div></div></v-col>
        <v-col cols="6" md="3"><div class="rav-field"><label>ID Number</label><div>{{ agreement.customer_id_number || '—' }}</div></div></v-col>
        <v-col cols="6" md="3"><div class="rav-field"><label>Driving License</label><div>{{ agreement.customer_driving_license || '—' }}</div></div></v-col>
        <v-col cols="12" md="6"><div class="rav-field"><label>Address</label><div>{{ agreement.customer_address || '—' }}</div></div></v-col>
      </v-row>

      <!-- Vehicle -->
      <p class="rav-section-title"><v-icon size="16" class="me-1" color="primary">mdi-car</v-icon> Vehicle</p>
      <v-row dense class="mb-2">
        <v-col cols="6" md="6"><div class="rav-field"><label>Vehicle</label><div>{{ agreement.vehicle_display || '—' }}</div></div></v-col>
        <v-col cols="6" md="6"><div class="rav-field"><label>License Plate</label><div>{{ agreement.vehicle_license_plate || '—' }}</div></div></v-col>
      </v-row>

      <!-- Period -->
      <p class="rav-section-title"><v-icon size="16" class="me-1" color="primary">mdi-calendar-clock</v-icon> Rental Period</p>
      <v-row dense class="mb-2">
        <v-col cols="6" md="4"><div class="rav-field"><label>Start</label><div>{{ formatDate(agreement.start_datetime) }}</div></div></v-col>
        <v-col cols="6" md="4"><div class="rav-field"><label>End</label><div>{{ formatDate(agreement.end_datetime) }}</div></div></v-col>
        <v-col cols="6" md="4"><div class="rav-field"><label>Actual Return</label><div>{{ agreement.actual_return_datetime ? formatDate(agreement.actual_return_datetime) : '—' }}</div></div></v-col>
        <v-col cols="6" md="3"><div class="rav-field"><label>Rate Period</label><div class="text-capitalize">{{ agreement.rate_period || '—' }}</div></div></v-col>
        <v-col cols="6" md="4"><div class="rav-field"><label>Pickup</label><div>{{ agreement.pickup_location || '—' }}</div></div></v-col>
        <v-col cols="6" md="5"><div class="rav-field"><label>Drop-off</label><div>{{ agreement.dropoff_location || '—' }}</div></div></v-col>
      </v-row>

      <!-- Rates & Add-ons -->
      <p class="rav-section-title"><v-icon size="16" class="me-1" color="primary">mdi-cash-multiple</v-icon> Rates and Add-ons</p>
      <v-row dense class="mb-2">
        <v-col cols="6" md="2"><div class="rav-field"><label>{{ activeRateLabel }}</label><div>{{ cur }}{{ activeRateValue }}</div></div></v-col>
        <v-col cols="6" md="3"><div class="rav-field"><label>Insurance</label><div>{{ agreement.insurance_type || '—' }} {{ cur }}{{ agreement.insurance_premium || 0 }}</div></div></v-col>
        <v-col cols="6" md="2"><div class="rav-field"><label>GPS</label><div>{{ cur }}{{ agreement.gps_fee || 0 }}</div></div></v-col>
        <v-col cols="6" md="2"><div class="rav-field"><label>Child Seat</label><div>{{ cur }}{{ agreement.child_seat_fee || 0 }}</div></div></v-col>
        <v-col cols="6" md="3"><div class="rav-field"><label>Add'l Driver</label><div>{{ cur }}{{ agreement.additional_driver_fee || 0 }}</div></div></v-col>
        <v-col cols="6" md="3"><div class="rav-field"><label>Delivery</label><div>{{ cur }}{{ agreement.delivery_fee || 0 }}</div></div></v-col>
        <v-col cols="6" md="3"><div class="rav-field"><label>Fuel Policy</label><div class="text-capitalize">{{ fuelPolicyLabel }}</div></div></v-col>
      </v-row>

      <!-- Deposits & Mileage -->
      <p class="rav-section-title"><v-icon size="16" class="me-1" color="primary">mdi-shield-account-outline</v-icon> Deposits and Mileage</p>
      <v-row dense class="mb-2">
        <v-col cols="6" md="3"><div class="rav-field"><label>Security Deposit</label><div>{{ cur }}{{ agreement.security_deposit || 0 }}</div></div></v-col>
        <v-col cols="6" md="3"><div class="rav-field"><label>Damage Deposit</label><div>{{ cur }}{{ agreement.damage_deposit || 0 }}</div></div></v-col>
        <v-col cols="6" md="3"><div class="rav-field"><label>Discount</label><div>{{ agreement.discount_percent || 0 }}% + {{ cur }}{{ agreement.discount_amount || 0 }}</div></div></v-col>
        <v-col cols="6" md="3"><div class="rav-field"><label>Tax Rate</label><div>{{ agreement.tax_percent || 0 }}%</div></div></v-col>
        <v-col cols="6" md="3"><div class="rav-field"><label>Free Mileage</label><div>{{ agreement.free_mileage || 0 }} km</div></div></v-col>
        <v-col cols="6" md="3"><div class="rav-field"><label>Excess / km</label><div>{{ cur }}{{ agreement.excess_mileage_rate || 0 }}</div></div></v-col>
        <v-col cols="6" md="3"><div class="rav-field"><label>Start Mileage</label><div>{{ agreement.start_mileage ?? '—' }} km</div></div></v-col>
        <v-col cols="6" md="3"><div class="rav-field"><label>End Mileage</label><div>{{ agreement.end_mileage ?? '—' }} km</div></div></v-col>
      </v-row>

      <!-- Fuel -->
      <p class="rav-section-title"><v-icon size="16" class="me-1" color="primary">mdi-gas-station-outline</v-icon> Fuel</p>
      <v-row dense class="mb-1">
        <v-col cols="12" md="4"><div class="rav-field"><label>Policy</label><div class="text-capitalize">{{ fuelPolicyLabel }}</div></div></v-col>
        <v-col cols="6" md="4">
          <div class="rav-field">
            <label>Start Fuel Level</label>
            <div class="d-flex align-center ga-2">
              <v-chip :color="fuelChipColor(startFuelPct)" size="small" label class="text-capitalize">{{ fuelLevelName(agreement.start_fuel_level) }}</v-chip>
            </div>
          </div>
        </v-col>
        <v-col cols="6" md="4">
          <div class="rav-field">
            <label>End Fuel Level</label>
            <div class="d-flex align-center ga-2">
              <v-chip :color="fuelChipColor(endFuelPct)" size="small" label class="text-capitalize">{{ fuelLevelName(agreement.end_fuel_level) }}</v-chip>
            </div>
          </div>
        </v-col>
      </v-row>
      <div class="rav-fuel-row">
        <div class="rav-fuel-block">
          <span class="rav-fuel-caption">Start gauge</span>
          <div class="rav-fuel-track">
            <div class="rav-fuel-fill" :style="{ width: startFuelPct + '%', background: fuelFillColor(startFuelPct) }">
              <span class="rav-fuel-pct">{{ startFuelPct }}%</span>
            </div>
          </div>
        </div>
        <div class="rav-fuel-block">
          <span class="rav-fuel-caption">End gauge</span>
          <div class="rav-fuel-track">
            <div class="rav-fuel-fill" :style="{ width: endFuelPct + '%', background: fuelFillColor(endFuelPct) }">
              <span class="rav-fuel-pct">{{ endFuelPct }}%</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Additional charges -->
      <p class="rav-section-title" v-if="agreement.charges?.length"><v-icon size="16" class="me-1" color="primary">mdi-receipt-text-outline</v-icon> Additional Charges</p>
      <v-table v-if="agreement.charges?.length" density="compact" class="mb-3 rav-data-table">
        <thead><tr><th>Type</th><th>Description</th><th>Qty</th><th>Unit</th><th>Total</th></tr></thead>
        <tbody>
          <tr v-for="(c, i) in agreement.charges" :key="i">
            <td class="text-capitalize">{{ (c.charge_type||'').replace('_', ' ') }}</td>
            <td>{{ c.description || '—' }}</td>
            <td>{{ c.quantity || 1 }}</td>
            <td>{{ cur }}{{ c.unit_amount || 0 }}</td>
            <td><b>{{ cur }}{{ c.total_amount || 0 }}</b></td>
          </tr>
        </tbody>
      </v-table>

      <!-- Damages -->
      <p class="rav-section-title" v-if="agreement.damages?.length"><v-icon size="16" class="me-1" color="primary">mdi-car-wrench</v-icon> Damages</p>
      <v-table v-if="agreement.damages?.length" density="compact" class="mb-3 rav-data-table">
        <thead><tr><th>Location</th><th>Description</th><th>Severity</th><th>Repair Cost</th></tr></thead>
        <tbody>
          <tr v-for="(d, i) in agreement.damages" :key="i">
            <td>{{ d.location || '—' }}</td>
            <td>{{ d.description || '—' }}</td>
            <td class="text-capitalize">{{ (d.severity || 'none').replace('_', ' ') }}</td>
            <td>{{ cur }}{{ d.repair_cost || 0 }}</td>
          </tr>
        </tbody>
      </v-table>

      <!-- Vehicle Extras Check -->
      <p class="rav-section-title" v-if="agreement.vehicle_checks?.length"><v-icon size="16" class="me-1" color="primary">mdi-checkbox-marked-circle-outline</v-icon> Vehicle Extras Check</p>
      <v-table v-if="agreement.vehicle_checks?.length" density="compact" class="mb-3 rav-data-table">
        <thead><tr><th>Item</th><th>Status</th><th>Stage</th><th>Notes</th></tr></thead>
        <tbody>
          <tr v-for="(vc, i) in agreement.vehicle_checks" :key="i">
            <td>{{ vc.item_name || '—' }}</td>
            <td>
              <v-chip
                :color="vc.status === 'present' ? 'success' : vc.status === 'missing' ? 'warning' : vc.status === 'damaged' ? 'error' : 'grey'"
                size="small"
                label
                class="text-capitalize"
              >{{ (vc.status || '').replace('_', '/') }}</v-chip>
            </td>
            <td class="text-capitalize">{{ vc.stage || 'pickup' }}</td>
            <td>{{ vc.notes || '—' }}</td>
          </tr>
        </tbody>
      </v-table>

      <!-- Vehicle Inspection -->
      <p class="rav-section-title" v-if="agreement.inspection_checks?.length"><v-icon size="16" class="me-1" color="primary">mdi-clipboard-check-outline</v-icon> Vehicle Inspection</p>
      <v-table v-if="agreement.inspection_checks?.length" density="compact" class="mb-3 rav-data-table">
        <thead><tr><th>Item</th><th>Status</th><th>Failed Parts</th><th>Notes</th></tr></thead>
        <tbody>
          <tr v-for="(ic, i) in agreement.inspection_checks" :key="'ic-' + i">
            <td>{{ ic.item_name || '—' }}</td>
            <td>
              <v-chip
                :color="ic.status === 'pass' ? 'success' : ic.status === 'fail' ? 'error' : ic.status === 'warning' ? 'warning' : 'grey'"
                size="small" label class="text-capitalize"
              >{{ (ic.status || '').replace('_', ' ') }}</v-chip>
            </td>
            <td>
              <template v-if="ic.failed_parts && ic.failed_parts.length">
                <v-chip v-for="fp in ic.failed_parts" :key="fp" size="x-small" color="error" variant="tonal" class="me-1 mb-1">{{ fp }}</v-chip>
              </template>
              <template v-else>—</template>
            </td>
            <td>{{ ic.notes || '—' }}</td>
          </tr>
        </tbody>
      </v-table>
      <div v-if="agreement.inspection_notes" class="mb-3" style="font-size:0.8rem;color:#64748b;background:#f8fafc;border-radius:8px;padding:10px 14px">
        <v-icon size="14" class="me-1" color="primary">mdi-note-text-outline</v-icon>{{ agreement.inspection_notes }}
      </div>

      <!-- Totals -->
      <div class="rav-totals-box">
        <div class="rav-totals-row"><span>Subtotal</span><span>{{ cur }}{{ Number(agreement.subtotal || 0).toLocaleString() }}</span></div>
        <div class="rav-totals-row"><span>Discount</span><span>- {{ cur }}{{ Number(agreement.discount_total || 0).toLocaleString() }}</span></div>
        <div class="rav-totals-row"><span>Taxes</span><span>{{ cur }}{{ Number(agreement.taxes || 0).toLocaleString() }}</span></div>
        <div class="rav-totals-row rav-totals-grand"><span>Total Amount</span><span>{{ cur }}{{ Number(agreement.total_amount || 0).toLocaleString() }}</span></div>
      </div>

      <!-- Notes -->
      <p class="rav-section-title" v-if="agreement.notes"><v-icon size="16" class="me-1" color="primary">mdi-note-text-outline</v-icon> Notes</p>
      <div v-if="agreement.notes" class="rav-notes">{{ agreement.notes }}</div>

      <!-- Signatures -->
      <p class="rav-section-title"><v-icon size="16" class="me-1" color="primary">mdi-draw</v-icon> Signatures</p>
      <v-row dense>
        <v-col cols="6">
          <div class="rav-sig-box">
            <div class="rav-sig-box-label">Renter</div>
            <div v-if="customerSig" class="rav-sig-image" v-html="customerSig.signature_data"></div>
            <div v-else class="rav-sig-empty">Not signed</div>
            <div class="rav-sig-meta">{{ customerSig?.signatory_name || '—' }} · {{ customerSig?.signed_at ? formatDate(customerSig.signed_at) : '' }}</div>
          </div>
        </v-col>
        <v-col cols="6">
          <div class="rav-sig-box">
            <div class="rav-sig-box-label">Company Representative</div>
            <div v-if="companySig" class="rav-sig-image" v-html="companySig.signature_data"></div>
            <div v-else class="rav-sig-empty">Not signed</div>
            <div class="rav-sig-meta">{{ companySig?.signatory_name || '—' }} · {{ companySig?.signed_at ? formatDate(companySig.signed_at) : '' }}</div>
          </div>
        </v-col>
      </v-row>
    </div>

    <div v-else class="d-flex justify-center align-center" style="min-height: 400px">
      <div class="text-center">
        <v-icon size="48" color="grey-lighten-1">mdi-alert-circle-outline</v-icon>
        <p class="text-grey mt-2">Agreement not found</p>
        <v-btn variant="text" color="primary" prepend-icon="mdi-arrow-left" class="mt-3" @click="goBack">Back to Agreements</v-btn>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'fullwidth' })

const route = useRoute()
const router = useRouter()
const { $api, $swal } = useNuxtApp()
const { currencySymbol: cur } = useCurrency()
const { tenant, load: loadTenant, logoUrl: tenantLogoUrl } = useTenant()

const agreementId = computed(() => Number(route.params.id))
const agreement = ref<any>(null)
const loadingAgreement = ref(true)

onMounted(async () => {
  loadTenant()
  await loadAgreement()
})

async function loadAgreement() {
  loadingAgreement.value = true
  try {
    agreement.value = await $api(`/rentals/agreements/${agreementId.value}/`)
  } catch {
    agreement.value = null
  } finally {
    loadingAgreement.value = false
  }
}

function goBack() {
  router.push('/app/rentals')
}

function editAgreement() {
  navigateTo(`/app/rentals/new?edit=${agreementId.value}`)
}

/* ---- Computed helpers ---- */
const statusLabel = computed(() => (agreement.value?.status || 'draft').replace('_', ' '))

const customerSig = computed(() => (agreement.value?.signatures || []).find((s: any) => s.party_type === 'customer'))
const companySig = computed(() => (agreement.value?.signatures || []).find((s: any) => s.party_type === 'company_rep'))

const ratePeriodLabels: Record<string, string> = { daily: 'Daily', weekly: 'Weekly', monthly: 'Monthly', weekend: 'Weekend' }
const activeRateLabel = computed(() => ratePeriodLabels[agreement.value?.rate_period] || 'Daily')
const activeRateKey = computed(() => (agreement.value?.rate_period || 'daily') + '_rate')
const activeRateValue = computed(() => agreement.value?.[activeRateKey.value] || 0)

/* ---- Fuel helpers ---- */
const fuelPolicyMap: Record<string, string> = {
  full_full: 'Full to Full',
  prepaid: 'Prepaid',
  half_tank: 'Half Tank',
}
const fuelLevelMap: Record<string, { pct: number; name: string }> = {
  empty: { pct: 0, name: 'Empty' },
  quarter: { pct: 25, name: '\u00bc Tank' },
  half: { pct: 50, name: 'Half' },
  three_quarter: { pct: 75, name: '\u00be Tank' },
  full: { pct: 100, name: 'Full' },
}
const fuelPolicyLabel = computed(() => fuelPolicyMap[agreement.value?.fuel_policy] || (agreement.value?.fuel_policy?.replace(/_/g, ' ') || '\u2014'))

function fuelPctOf(val: any): number {
  if (val === undefined || val === null || val === '') return 0
  const named = fuelLevelMap[val]
  if (named) return named.pct
  const num = Number(String(val).replace('%', ''))
  return isNaN(num) ? 0 : Math.max(0, Math.min(100, num))
}
const startFuelPct = computed(() => fuelPctOf(agreement.value?.start_fuel_level))
const endFuelPct = computed(() => fuelPctOf(agreement.value?.end_fuel_level))

function fuelLevelName(val: any): string {
  if (!val) return '\u2014'
  const named = fuelLevelMap[val]
  if (named) return named.name
  return String(val).replace('%', '%')
}
function fuelChipColor(pct: number): string {
  if (pct <= 0) return 'error'
  if (pct < 25) return 'warning'
  if (pct < 75) return 'info'
  return 'success'
}
function fuelFillColor(pct: number): string {
  if (pct <= 0) return 'linear-gradient(90deg, #ef4444, #f87171)'
  if (pct <= 25) return 'linear-gradient(90deg, #f59e0b, #fbbf24)'
  if (pct <= 50) return 'linear-gradient(90deg, #eab308, #facc15)'
  if (pct <= 75) return 'linear-gradient(90deg, #84cc16, #a3e635)'
  return 'linear-gradient(90deg, #22c55e, #4ade80)'
}

function formatDate(d: any) {
  if (!d) return '\u2014'
  return String(d).slice(0, 16).replace('T', ' ')
}

/* ---- Download (printable receipt) ---- */
function downloadAgree() {
  const a = agreement.value
  if (!a) return
  const html = buildAgreementHtml(a)
  const w = window.open('', '_blank', 'width=900,height=1100')
  if (!w) {
    $swal.fire({ icon: 'warning', title: 'Popup blocked', text: 'Allow popups to download the agreement.', toast: true, timer: 2500, position: 'top-end' })
    return
  }
  w.document.write(html)
  w.document.close()
  setTimeout(() => { w.focus(); w.print() }, 400)
}

function buildAgreementHtml(a: any): string {
  const charges = (a.charges || [])
  const damages = (a.damages || [])
  const vehicleChecks = (a.vehicle_checks || [])
  const inspectionChecks = (a.inspection_checks || [])
  const signatures = (a.signatures || [])
  const customerSig = signatures.find((s: any) => s.party_type === 'customer')
  const companySig = signatures.find((s: any) => s.party_type === 'company_rep')

  const rpLabels: Record<string, string> = { daily: 'Daily', weekly: 'Weekly', monthly: 'Monthly', weekend: 'Weekend' }
  const ratePeriodLabel = rpLabels[a.rate_period] || 'Daily'
  const activeRateValue = a[(a.rate_period || 'daily') + '_rate'] || 0

  const t = tenant.value
  const companyFullName = t?.full_name || t?.short_name || 'DomendraFleet'
  const companyEmail = t?.email || ''
  const companyTel = t?.mobile_number || ''
  const companyLogoUrl = tenantLogoUrl.value || ''
  const logoHtml = companyLogoUrl
    ? `<img src="${companyLogoUrl}" alt="logo" style="max-height:56px; max-width:200px; border-radius:6px;" />`
    : `<div class="logo">${(t?.short_name || 'Domendra')}</div>`

  return `<!DOCTYPE html><html><head><meta charset="utf-8"><title>${a.agreement_no} - Rental Agreement</title>
  <style>
    body { font-family: 'Segoe UI', Arial, sans-serif; color:#1e293b; padding:30px; max-width:820px; margin:0 auto; }
    .header { display:flex; justify-content:space-between; align-items:flex-start; border-bottom:3px solid #6366f1; padding-bottom:16px; margin-bottom:24px; }
    .header-left { display:flex; align-items:center; gap:14px; }
    .logo { font-size:28px; font-weight:800; color:#6366f1; }
    .company-name { font-size:18px; font-weight:700; color:#1e293b; line-height:1.3; }
    .company-contact { font-size:11px; color:#64748b; margin-top:3px; line-height:1.5; }
    .company-contact span { margin-right:12px; white-space:nowrap; }
    .meta { text-align:right; font-size:12px; color:#64748b; }
    .ref-badge { background:#eef2ff; color:#4f46e5; padding:6px 12px; border-radius:6px; font-weight:700; font-family: monospace; }
    h1 { font-size:22px; margin: 10px 0; }
    .section-title { font-size:12px; text-transform:uppercase; letter-spacing:0.05em; color:#4f46e5; font-weight:700; margin:18px 0 8px; border-left:3px solid #6366f1; padding-left:8px; }
    table { width:100%; border-collapse:collapse; margin-bottom:12px; }
    th { background:#f8fafc; text-align:left; padding:8px; border:1px solid #e2e8f0; font-size:12px; }
    td { padding:8px; border:1px solid #e2e8f0; font-size:12px; }
    .grid { display:grid; grid-template-columns: 1fr 1fr; gap:6px 24px; margin-bottom:8px; }
    .grid div { font-size:12px; padding:6px 0; border-bottom:1px dashed #e2e8f0; }
    .grid b { color:#475569; font-weight:600; display:block; font-size:10px; text-transform:uppercase; letter-spacing:0.05em; margin-bottom:2px; }
    .totals { margin-top:16px; }
    .totals .row { display:flex; justify-content:space-between; padding:6px 0; font-size:13px; }
    .totals .grand { background:#eef2ff; padding:10px 14px; border-radius:8px; font-weight:800; font-size:16px; color:#4f46e5; margin-top:6px; }
    .sigs { display:grid; grid-template-columns:1fr 1fr; gap:24px; margin-top:60px; }
    .sig-box { border-top:1.5px solid #1e293b; padding-top:10px; min-height:130px; position:relative; }
    .sig-box svg { width:100%; height:130px; }
    .sig-empty { text-align:center; color:#94a3b8; font-size:12px; padding-top:50px; }
    .foot { margin-top:30px; border-top:1px solid #e2e8f0; padding-top:14px; text-align:center; font-size:11px; color:#94a3b8; }
    @media print { body { padding: 14px; } }
  </style></head><body>
    <div class="header">
      <div class="header-left">
        ${logoHtml}
        <div>
          <div class="company-name">${companyFullName}</div>
          <div class="company-contact">
            ${companyEmail ? `<span>&#9993; ${companyEmail}</span>` : ''}
            ${companyTel ? `<span>&#9742; ${companyTel}</span>` : ''}
          </div>
        </div>
      </div>
      <div class="meta"><div class="ref-badge">${a.agreement_no}</div><div style="margin-top:6px">Date: ${new Date().toISOString().slice(0,10)}</div></div>
    </div>
    <h1>Vehicle Hire / Rental Agreement</h1>

    <p style="font-size:12px;color:#475569">
      This Vehicle Rental Agreement (the "Agreement") is made between <b>${companyFullName}</b> (the "Company") and the
      customer named below (the "Renter"). By signing, both parties accept the rates, terms, charges and
      conditions set out herein.
    </p>

    <div class="section-title">Renter (Customer)</div>
    <div class="grid">
      <div><b>Full Name</b>${a.customer_name || '\u2014'}</div>
      <div><b>Type</b>${(a.customer_type || '\u2014').replace('_', ' ')}</div>
      <div><b>Phone</b>${a.customer_phone || '\u2014'}</div>
      <div><b>Email</b>${a.customer_email || '\u2014'}</div>
      <div><b>ID Number</b>${a.customer_id_number || '\u2014'}</div>
      <div><b>Driving License</b>${a.customer_driving_license || '\u2014'}</div>
      <div><b>Address</b>${a.customer_address || '\u2014'}</div>
    </div>

    <div class="section-title">Vehicle</div>
    <div class="grid">
      <div><b>Vehicle</b>${a.vehicle_display || '\u2014'}</div>
      <div><b>License Plate</b>${a.vehicle_license_plate || '\u2014'}</div>
    </div>

    <div class="section-title">Rental Period</div>
    <div class="grid">
      <div><b>Start</b>${formatDate(a.start_datetime)}</div>
      <div><b>End</b>${formatDate(a.end_datetime)}</div>
      <div><b>Actual Return</b>${a.actual_return_datetime ? formatDate(a.actual_return_datetime) : '\u2014'}</div>
      <div><b>Rate Period</b>${(a.rate_period || 'daily').replace('_', ' ')}</div>
      <div><b>Pickup</b>${a.pickup_location || '\u2014'}</div>
      <div><b>Drop-off</b>${a.dropoff_location || '\u2014'}</div>
    </div>

    <div class="section-title">Rates and Add-ons</div>
    <div class="grid">
      <div><b>${ratePeriodLabel} Rate</b>${activeRateValue}</div>
      <div><b>Insurance</b>${a.insurance_type || '\u2014'} (${a.insurance_premium || 0})</div>
      <div><b>GPS Fee</b>${a.gps_fee || 0}</div>
      <div><b>Child Seat</b>${a.child_seat_fee || 0}</div>
      <div><b>Additional Driver</b>${a.additional_driver_fee || 0}</div>
      <div><b>Delivery Fee</b>${a.delivery_fee || 0}</div>
      <div><b>Fuel Policy</b>${(a.fuel_policy || '').replace('_', ' ')}</div>
    </div>

    <div class="section-title">Deposits, Discounts and Mileage</div>
    <div class="grid">
      <div><b>Security Deposit</b>${a.security_deposit || 0}</div>
      <div><b>Damage Deposit</b>${a.damage_deposit || 0}</div>
      <div><b>Discount %</b>${a.discount_percent || 0}%</div>
      <div><b>Discount Amount</b>${a.discount_amount || 0}</div>
      <div><b>Free Mileage</b>${a.free_mileage || 0} km</div>
      <div><b>Excess Rate</b>${a.excess_mileage_rate || 0} / km</div>
      <div><b>Start Mileage</b>${a.start_mileage ?? '\u2014'}</div>
      <div><b>End Mileage</b>${a.end_mileage ?? '\u2014'}</div>
    </div>

    <div class="section-title">Additional Charges</div>
    <table>
      <thead><tr><th>Type</th><th>Description</th><th>Qty</th><th>Unit</th><th>Total</th></tr></thead>
      <tbody>
        ${charges.length ? charges.map((c: any) => `
          <tr><td>${(c.charge_type || '').replace('_', ' ')}</td><td>${c.description || '\u2014'}</td><td>${c.quantity || 1}</td><td>${c.unit_amount || 0}</td><td><b>${c.total_amount || 0}</b></td></tr>`).join('') : '<tr><td colspan="5" style="text-align:center;color:#94a3b8">No additional charges.</td></tr>'}
      </tbody>
    </table>

    <div class="section-title">Vehicle Damages Recorded</div>
    <table>
      <thead><tr><th>Location</th><th>Description</th><th>Severity</th><th>Repair Cost</th></tr></thead>
      <tbody>
        ${damages.length ? damages.map((d: any) => `<tr><td>${d.location || '\u2014'}</td><td>${d.description || '\u2014'}</td><td>${(d.severity || 'none').replace('_', ' ')}</td><td>${d.repair_cost || 0}</td></tr>`).join('') : '<tr><td colspan="4" style="text-align:center;color:#94a3b8">No damages recorded.</td></tr>'}
      </tbody>
    </table>

    <div class="section-title">Vehicle Extras Checklist</div>
    <table>
      <thead><tr><th>Item</th><th>Status</th><th>Stage</th><th>Notes</th></tr></thead>
      <tbody>
        ${vehicleChecks.length ? vehicleChecks.map((vc: any) => `<tr><td>${vc.item_name || '\u2014'}</td><td style="text-transform:capitalize">${(vc.status || '').replace('_', '/')}</td><td style="text-transform:capitalize">${vc.stage || 'pickup'}</td><td>${vc.notes || '\u2014'}</td></tr>`).join('') : '<tr><td colspan="4" style="text-align:center;color:#94a3b8">No extras checklist recorded.</td></tr>'}
      </tbody>
    </table>

    <div class="section-title">Vehicle Inspection</div>
    <table>
      <thead><tr><th>Item</th><th>Status</th><th>Failed Parts</th><th>Notes</th></tr></thead>
      <tbody>
        ${inspectionChecks.length ? inspectionChecks.map((ic: any) => `<tr><td>${ic.item_name || '\u2014'}</td><td style="text-transform:capitalize">${(ic.status || '').replace('_', ' ')}</td><td>${(ic.failed_parts && ic.failed_parts.length) ? ic.failed_parts.map((fp: string) => fp).join(', ') : '\u2014'}</td><td>${ic.notes || '\u2014'}</td></tr>`).join('') : '<tr><td colspan="4" style="text-align:center;color:#94a3b8">No inspection recorded.</td></tr>'}
      </tbody>
    </table>
    ${a.inspection_notes ? `<p style="font-size:11px;color:#475569;margin:8px 0 16px;line-height:1.5"><b>Inspection Notes:</b> ${a.inspection_notes}</p>` : ''}

    <div class="totals">
      <div class="row"><span>Subtotal</span><span>${a.subtotal || 0}</span></div>
      <div class="row"><span>Discount</span><span>- ${a.discount_total || 0}</span></div>
      <div class="row"><span>Taxes</span><span>${a.taxes || 0}</span></div>
      <div class="row grand"><span>Total Amount</span><span>${a.total_amount || 0}</span></div>
    </div>

    <div class="sigs">
      <div>
        <div class="section-title" style="margin-top:0">Renter Signature</div>
        <div class="sig-box">${customerSig?.signature_data || '<div class="sig-empty">Not signed</div>'}</div>
        <div style="font-size:11px;color:#94a3b8;margin-top:6px">${customerSig?.signatory_name || '\u2014'} \u00b7 ${customerSig?.signed_at ? customerSig.signed_at.slice(0, 16).replace('T', ' ') : ''}</div>
      </div>
      <div>
        <div class="section-title" style="margin-top:0">Company Representative</div>
        <div class="sig-box">${companySig?.signature_data || '<div class="sig-empty">Not signed</div>'}</div>
        <div style="font-size:11px;color:#94a3b8;margin-top:6px">${companySig?.signatory_name || '\u2014'} \u00b7 ${companySig?.signed_at ? companySig.signed_at.slice(0, 16).replace('T', ' ') : ''}</div>
      </div>
    </div>

    <p style="font-size:11px;color:#475569;margin-top:30px;line-height:1.5">
      <b>Notes and Terms:</b> ${a.notes || '\u2014'}
    </p>

    ${(a.terms_and_conditions && a.terms_and_conditions.length) ? `
    <div class="section-title" style="margin-top:30px">Terms and Conditions</div>
    <div style="font-size:11px;color:#475569;line-height:1.6">
      ${a.terms_and_conditions.map((t: any) => `<p style="margin:8px 0"><b>${t.id}. ${t.title}</b><br/>${t.text}</p>`).join('')}
    </div>` : ''}

    <div class="foot">
      Generated by ${companyFullName} \u00b7 ${new Date().toISOString()} \u00b7 This is a system-generated document for internal record purposes.
    </div>
  </body></html>`
}
</script>

<style scoped>
.rav-page {
  width: 90%;
  max-width: 1400px;
  margin: 0 auto;
  padding: 24px;
}

.rav-topbar {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 16px;
}

.rav-content {
  animation: rav-fade-in 0.3s ease;
}
@keyframes rav-fade-in {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: translateY(0); }
}

/* ---- Hero ---- */
.rav-hero {
  position: relative;
  border-radius: 16px;
  overflow: hidden;
  margin-bottom: 16px;
}
.rav-hero-bg {
  position: absolute; inset: 0;
  background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 50%, #6366f1 100%);
}
.rav-hero-content {
  position: relative;
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 20px 24px;
}
.rav-hero-icon {
  width: 48px; height: 48px;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.2);
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0;
}
.rav-hero-title {
  color: #fff; font-size: 20px; font-weight: 800;
  margin: 0; line-height: 1.2;
}
.rav-hero-sub {
  color: rgba(255, 255, 255, 0.85); font-size: 13px; margin: 0;
}
.rav-hero-status {
  font-size: 12px; font-weight: 700;
  padding: 6px 14px; border-radius: 20px;
  background: rgba(255, 255, 255, 0.25);
  color: #fff;
  text-transform: capitalize;
}
.rav-status-badge--draft { background: rgba(100, 116, 139, 0.5); }
.rav-status-badge--active { background: rgba(16, 185, 129, 0.4); }
.rav-status-badge--completed { background: rgba(14, 165, 233, 0.4); }
.rav-status-badge--cancelled { background: rgba(239, 68, 68, 0.4); }
.rav-status-badge--overdue { background: rgba(245, 158, 11, 0.4); }

/* ---- Info strip ---- */
.rav-info-strip {
  display: flex;
  gap: 20px;
  flex-wrap: wrap;
  padding: 14px 20px;
  border-radius: 12px;
  background: rgb(var(--v-theme-surface));
  border: 1px solid rgba(var(--v-theme-on-surface), 0.12);
  margin-bottom: 12px;
}
.rav-info-item {
  display: flex; align-items: center; gap: 12px;
}
.rav-info-item > div {
  display: flex; flex-direction: column;
}
.rav-cap {
  font-size: 10px; font-weight: 600;
  color: rgb(var(--v-theme-on-surface)); opacity: 0.6;
  text-transform: uppercase; letter-spacing: 0.05em;
}
.rav-val {
  font-size: 13px; font-weight: 600;
  color: rgb(var(--v-theme-on-surface));
}

/* ---- Section titles ---- */
.rav-section-title {
  font-size: 12px; font-weight: 700; color: rgb(var(--v-theme-primary));
  text-transform: uppercase; letter-spacing: 0.05em;
  margin: 18px 0 8px;
  padding-left: 8px;
  border-left: 3px solid rgb(var(--v-theme-primary));
}

/* ---- Fields ---- */
.rav-field label {
  display: block; font-size: 10px;
  color: rgb(var(--v-theme-on-surface)); opacity: 0.6;
  text-transform: uppercase;
  letter-spacing: 0.05em; margin-bottom: 3px; font-weight: 600;
}
.rav-field > div {
  font-size: 13px; color: rgb(var(--v-theme-on-surface)); font-weight: 500;
  padding-bottom: 6px; border-bottom: 1px dashed rgba(var(--v-theme-on-surface), 0.15);
}

/* ---- Data tables ---- */
.rav-data-table :deep(th) {
  font-size: 11px; font-weight: 700;
  color: rgb(var(--v-theme-on-surface));
  text-transform: uppercase; letter-spacing: 0.03em;
}
.rav-data-table :deep(td) {
  font-size: 13px;
  color: rgb(var(--v-theme-on-surface));
}

/* ---- Totals ---- */
.rav-totals-box {
  margin-top: 18px; padding: 16px 18px;
  border-radius: 12px;
  background: rgba(var(--v-theme-on-surface), 0.05);
  border: 1px solid rgba(var(--v-theme-on-surface), 0.12);
}
.rav-totals-row {
  display: flex; justify-content: space-between;
  padding: 5px 0; font-size: 13px; color: rgb(var(--v-theme-on-surface));
  border-bottom: 1px dashed rgba(var(--v-theme-on-surface), 0.15);
}
.rav-totals-grand {
  font-size: 18px; font-weight: 800; color: rgb(var(--v-theme-primary));
  border-bottom: none; padding-top: 10px;
}

/* ---- Notes ---- */
.rav-notes {
  font-size: 12px; color: rgb(var(--v-theme-on-surface));
  padding: 12px; border-radius: 8px;
  background: rgba(var(--v-theme-on-surface), 0.05);
  border: 1px solid rgba(var(--v-theme-on-surface), 0.12);
  line-height: 1.5;
}

/* ---- Signatures ---- */
.rav-sig-box {
  border: 1px solid rgba(var(--v-theme-on-surface), 0.12);
  border-radius: 10px; padding: 14px;
  min-height: 160px;
  position: relative;
  background: rgba(var(--v-theme-on-surface), 0.05);
}
.rav-sig-box-label {
  font-size: 10px; font-weight: 700;
  color: rgb(var(--v-theme-on-surface)); opacity: 0.6;
  text-transform: uppercase;
  letter-spacing: 0.05em; margin-bottom: 8px;
}
.rav-sig-image :deep(svg) {
  width: 100%; height: 100px;
}
.rav-sig-empty {
  text-align: center; padding-top: 30px;
  color: rgb(var(--v-theme-on-surface)); opacity: 0.5; font-size: 12px;
}
.rav-sig-meta {
  margin-top: 8px; font-size: 11px; color: rgb(var(--v-theme-on-surface));
  opacity: 0.6;
  border-top: 1px dashed rgba(var(--v-theme-on-surface), 0.15); padding-top: 6px;
}

/* ---- Fuel gauges ---- */
.rav-fuel-row {
  display: flex;
  gap: 24px;
  margin: 4px 0 12px;
  flex-wrap: wrap;
}
.rav-fuel-block {
  flex: 1 1 200px;
  min-width: 200px;
}
.rav-fuel-caption {
  display: block;
  font-size: 10px; font-weight: 600;
  color: rgb(var(--v-theme-on-surface)); opacity: 0.6;
  text-transform: uppercase;
  letter-spacing: 0.05em; margin-bottom: 4px;
}
.rav-fuel-track {
  position: relative;
  width: 100%;
  height: 28px;
  background: rgba(var(--v-theme-on-surface), 0.08);
  border: 1px solid rgba(var(--v-theme-on-surface), 0.15);
  border-radius: 8px;
  overflow: hidden;
}
.rav-fuel-fill {
  position: relative;
  height: 100%;
  border-radius: 7px;
  transition: width 0.3s ease;
  min-width: 28px;
}
.rav-fuel-pct {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 11px;
  font-weight: 700;
  color: #ffffff;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.3);
  white-space: nowrap;
}
</style>
