<template>
  <v-dialog :model-value="true" max-width="900" scroll-strategy="none" @update:model-value="$emit('close')">
    <v-card rounded="xl" class="overflow-hidden">
      <AppModalHeader icon="mdi-file-document-outline">Rental Agreement · {{ agreement.agreement_no }}</AppModalHeader>

      <v-card-text class="pa-0" style="max-height: 70vh; overflow: auto">
        <!-- Status banner -->
        <div class="rav-status-bar" :class="`rav-status--${agreement.status}`">
          <v-icon size="20" class="me-2">mdi-circle-medium</v-icon>
          <span class="text-capitalize font-weight-bold">{{ statusLabel }}</span>
          <v-spacer />
          <span class="text-caption" style="opacity:.85">Created {{ formatDate(agreement.created_at) }}</span>
        </div>

        <div class="pa-5">
          <!-- Customer -->
          <p class="rav-section-title"><v-icon size="16" class="me-1" color="primary">mdi-account</v-icon> Customer</p>
          <v-row dense class="mb-2">
            <v-col cols="6"><div class="rav-field"><label>Name</label><div>{{ agreement.customer_name || '—' }}</div></div></v-col>
            <v-col cols="6"><div class="rav-field"><label>Type</label><div class="text-capitalize">{{ agreement.customer_type || '—' }}</div></div></v-col>
          </v-row>

          <!-- Vehicle -->
          <p class="rav-section-title"><v-icon size="16" class="me-1" color="primary">mdi-car</v-icon> Vehicle</p>
          <v-row dense class="mb-2">
            <v-col cols="6"><div class="rav-field"><label>Vehicle</label><div>{{ agreement.vehicle_display || '—' }}</div></div></v-col>
            <v-col cols="6"><div class="rav-field"><label>License Plate</label><div>{{ agreement.vehicle_license_plate || '—' }}</div></div></v-col>
          </v-row>

          <!-- Period -->
          <p class="rav-section-title"><v-icon size="16" class="me-1" color="primary">mdi-calendar-clock</v-icon> Rental Period</p>
          <v-row dense class="mb-2">
            <v-col cols="6"><div class="rav-field"><label>Start</label><div>{{ formatDate(agreement.start_datetime) }}</div></div></v-col>
            <v-col cols="6"><div class="rav-field"><label>End</label><div>{{ formatDate(agreement.end_datetime) }}</div></div></v-col>
            <v-col cols="6"><div class="rav-field"><label>Actual Return</label><div>{{ agreement.actual_return_datetime ? formatDate(agreement.actual_return_datetime) : '—' }}</div></div></v-col>
            <v-col cols="6"><div class="rav-field"><label>Rate Period</label><div class="text-capitalize">{{ agreement.rate_period || '—' }}</div></div></v-col>
            <v-col cols="6"><div class="rav-field"><label>Pickup</label><div>{{ agreement.pickup_location || '—' }}</div></div></v-col>
            <v-col cols="6"><div class="rav-field"><label>Drop-off</label><div>{{ agreement.dropoff_location || '—' }}</div></div></v-col>
          </v-row>

          <!-- Rates -->
          <p class="rav-section-title"><v-icon size="16" class="me-1" color="primary">mdi-cash-multiple</v-icon> Rates &amp; Add-ons</p>
          <v-row dense class="mb-2">
            <v-col cols="6" md="3"><div class="rav-field"><label>{{ activeRateLabel }}</label><div>{{ cur }}{{ activeRateValue }}</div></div></v-col>
            <v-col cols="6" md="4"><div class="rav-field"><label>Insurance</label><div>{{ agreement.insurance_type || '—' }} {{ cur }}{{ agreement.insurance_premium || 0 }}</div></div></v-col>
            <v-col cols="6" md="2"><div class="rav-field"><label>GPS</label><div>{{ cur }}{{ agreement.gps_fee || 0 }}</div></div></v-col>
            <v-col cols="6" md="2"><div class="rav-field"><label>Child Seat</label><div>{{ cur }}{{ agreement.child_seat_fee || 0 }}</div></div></v-col>
            <v-col cols="6" md="2"><div class="rav-field"><label>Add'l Driver</label><div>{{ cur }}{{ agreement.additional_driver_fee || 0 }}</div></div></v-col>
            <v-col cols="6" md="2"><div class="rav-field"><label>Delivery</label><div>{{ cur }}{{ agreement.delivery_fee || 0 }}</div></div></v-col>
          </v-row>

          <!-- Deposits -->
          <p class="rav-section-title"><v-icon size="16" class="me-1" color="primary">mdi-shield-account-outline</v-icon> Deposits &amp; Mileage</p>
          <v-row dense class="mb-2">
            <v-col cols="6" md="3"><div class="rav-field"><label>Security Deposit</label><div>{{ cur }}{{ agreement.security_deposit || 0 }}</div></div></v-col>
            <v-col cols="6" md="3"><div class="rav-field"><label>Damage Deposit</label><div>{{ cur }}{{ agreement.damage_deposit || 0 }}</div></div></v-col>
            <v-col cols="6" md="3"><div class="rav-field"><label>Discount</label><div>{{ agreement.discount_percent || 0 }}% + {{ cur }}{{ agreement.discount_amount || 0 }}</div></div></v-col>
            <v-col cols="6" md="3"><div class="rav-field"><label>Tax Rate</label><div>{{ agreement.tax_percent || 0 }}%</div></div></v-col>
            <v-col cols="6" md="3"><div class="rav-field"><label>Free Mileage</label><div>{{ agreement.free_mileage || 0 }} km</div></div></v-col>
            <v-col cols="6" md="3"><div class="rav-field"><label>Excess / km</label><div>{{ cur }}{{ agreement.excess_mileage_rate || 0 }}</div></div></v-col>
            <v-col cols="6" md="3"><div class="rav-field"><label>Start Mileage</label><div>{{ agreement.start_mileage ?? '—' }}</div></div></v-col>
            <v-col cols="6" md="3"><div class="rav-field"><label>End Mileage</label><div>{{ agreement.end_mileage ?? '—' }}</div></div></v-col>
          </v-row>

          <!-- Fuel -->
          <p class="rav-section-title"><v-icon size="16" class="me-1" color="primary">mdi-gas-station-outline</v-icon> Fuel</p>
          <v-row dense class="mb-2">
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
          <v-table v-if="agreement.charges?.length" density="compact" class="mb-3">
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
          <v-table v-if="agreement.damages?.length" density="compact" class="mb-3">
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
          <v-table v-if="agreement.vehicle_checks?.length" density="compact" class="mb-3">
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
          <v-table v-if="agreement.inspection_checks?.length" density="compact" class="mb-3">
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
            <div class="rav-totals-row"><span>Subtotal</span><span>{{ cur }}{{ agreement.subtotal || 0 }}</span></div>
            <div class="rav-totals-row"><span>Discount</span><span>- {{ cur }}{{ agreement.discount_total || 0 }}</span></div>
            <div class="rav-totals-row"><span>Taxes</span><span>{{ cur }}{{ agreement.taxes || 0 }}</span></div>
            <div class="rav-totals-row rav-totals-grand"><span>Total Amount</span><span>{{ cur }}{{ agreement.total_amount || 0 }}</span></div>
          </div>

          <!-- Notes -->
          <p class="rav-section-title" v-if="agreement.notes"><v-icon size="16" class="me-1" color="primary">mdi-note-text-outline</v-icon> Notes</p>
          <div v-if="agreement.notes" class="rav-notes">{{ agreement.notes }}</div>

          <!-- Terms & Conditions -->
          <template v-if="agreement.terms_and_conditions && agreement.terms_and_conditions.length">
            <p class="rav-section-title"><v-icon size="16" class="me-1" color="primary">mdi-file-document-check-outline</v-icon> Terms &amp; Conditions</p>
            <div class="rav-terms">
              <div v-for="term in agreement.terms_and_conditions" :key="term.id" class="rav-terms-clause">
                <span class="rav-terms-num">{{ term.id }}.</span>
                <span class="rav-terms-body">
                  <strong>{{ term.title }}</strong>
                  <span class="rav-terms-text">{{ term.text }}</span>
                </span>
              </div>
            </div>
          </template>

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
      </v-card-text>

      <v-divider />
      <v-card-actions class="pa-4">
        <v-btn variant="text" color="error" prepend-icon="mdi-close" @click="$emit('close')">Close</v-btn>
        <v-spacer />
        <v-btn variant="tonal" color="info" prepend-icon="mdi-download" @click="$emit('download')">Download</v-btn>
        <v-btn color="warning" prepend-icon="mdi-pencil" @click="$emit('edit')">Edit</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
const props = defineProps<{ agreement: any }>()
const emit = defineEmits<{ close: []; edit: []; download: [] }>()

const { currencySymbol: cur } = useCurrency()

const statusLabel = computed(() => (props.agreement?.status || 'draft').replace('_', ' '))

const customerSig = computed(() => (props.agreement?.signatures || []).find((s:any) => s.party_type === 'customer'))

const ratePeriodLabels: Record<string, string> = { daily: 'Daily', weekly: 'Weekly', monthly: 'Monthly', weekend: 'Weekend' }
const activeRateLabel = computed(() => ratePeriodLabels[props.agreement?.rate_period] || 'Daily')
const activeRateKey = computed(() => props.agreement?.rate_period + '_rate')
const activeRateValue = computed(() => props.agreement?.[activeRateKey.value] || 0)
const companySig = computed(() => (props.agreement?.signatures || []).find((s:any) => s.party_type === 'company_rep'))

function formatDate(d:any) {
  if (!d) return '—'
  return String(d).slice(0, 16).replace('T', ' ')
}

/* ---- Fuel helpers ---- */
const fuelPolicyMap: Record<string, string> = {
  full_full: 'Full to Full',
  prepaid: 'Prepaid',
  half_tank: 'Half Tank',
}
const fuelLevelMap: Record<string, { pct: number; name: string }> = {
  empty: { pct: 0, name: 'Empty' },
  quarter: { pct: 25, name: '¼ Tank' },
  half: { pct: 50, name: 'Half' },
  three_quarter: { pct: 75, name: '¾ Tank' },
  full: { pct: 100, name: 'Full' },
}
const fuelPolicyLabel = computed(() => fuelPolicyMap[props.agreement?.fuel_policy] || (props.agreement?.fuel_policy?.replace(/_/g, ' ') || '—'))
function fuelPctOf(val: any): number {
  if (val === undefined || val === null || val === '') return 0
  const named = fuelLevelMap[val]
  if (named) return named.pct
  const num = Number(String(val).replace('%', ''))
  return isNaN(num) ? 0 : Math.max(0, Math.min(100, num))
}
const startFuelPct = computed(() => fuelPctOf(props.agreement?.start_fuel_level))
const endFuelPct = computed(() => fuelPctOf(props.agreement?.end_fuel_level))
function fuelLevelName(val: any): string {
  if (!val) return '—'
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
</script>

<style scoped>
.rav-status-bar {
  display: flex; align-items: center; gap: 6px;
  padding: 8px 18px;
  font-size: 13px; color: #ffffff;
}
.rav-status--draft { background: #64748b; }
.rav-status--active { background: #10b981; }
.rav-status--completed { background: #0ea5e9; }
.rav-status--cancelled { background: #ef4444; }
.rav-status--overdue { background: #f59e0b; }

.rav-section-title {
  font-size: 12px; font-weight: 700; color: rgb(var(--v-theme-primary));
  text-transform: uppercase; letter-spacing: 0.05em;
  margin: 18px 0 8px;
  padding-left: 8px;
  border-left: 3px solid rgb(var(--v-theme-primary));
}
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
.rav-notes {
  font-size: 12px; color: rgb(var(--v-theme-on-surface));
  padding: 12px; border-radius: 8px;
  background: rgba(var(--v-theme-on-surface), 0.05);
  border: 1px solid rgba(var(--v-theme-on-surface), 0.12);
  line-height: 1.5;
}
.rav-terms {
  max-height: 320px; overflow-y: auto;
  border: 1px solid rgba(var(--v-theme-on-surface), 0.12);
  border-radius: 8px; padding: 12px 16px;
  background: rgba(var(--v-theme-on-surface), 0.03);
}
.rav-terms-clause {
  display: flex; gap: 8px;
  padding: 8px 0;
  border-bottom: 1px dashed rgba(var(--v-theme-on-surface), 0.10);
  font-size: 12px; line-height: 1.5;
  color: rgb(var(--v-theme-on-surface));
}
.rav-terms-clause:last-child { border-bottom: none; }
.rav-terms-num {
  font-weight: 700; color: rgb(var(--v-theme-primary));
  min-width: 24px; flex: 0 0 24px;
}
.rav-terms-body { flex: 1; }
.rav-terms-text {
  display: block; margin-top: 2px;
  opacity: 0.82;
}
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
