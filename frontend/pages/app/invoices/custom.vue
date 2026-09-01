<template>
  <div class="custom-invoice-page" :style="brandVars">
    <!-- ── Hero Header ── -->
    <div class="hero-header">
      <div class="d-flex align-center ga-3 flex-wrap">
        <v-btn icon="mdi-arrow-left" size="small" variant="flat" class="hero-back-btn" @click="navigateTo('/app/invoices')" />
        <v-avatar size="48" rounded="lg" class="hero-icon">
          <v-icon size="26" color="white">mdi-file-document-edit</v-icon>
        </v-avatar>
        <div>
          <h1 class="text-h5 font-weight-bold mb-1" style="color:#fff;letter-spacing:0.01em">{{ isEditMode ? 'Edit Customized Invoice' : 'Customized Invoice' }}</h1>
          <p style="color:rgba(255,255,255,.82);font-size:0.8rem;line-height:1.4">{{ isEditMode ? 'Update your standalone invoice with new line items and billing details' : 'Create a standalone invoice with your own line items and billing details' }}</p>
        </div>
      </div>
    </div>

    <!-- ── Two-Column Layout ── -->
    <div class="d-flex ga-4 flex-wrap">
      <!-- LEFT: Form Steps -->
      <div style="min-width:0;flex:1 1 480px">
        <div class="d-flex flex-column ga-3">

          <!-- Step 1: Select Customer -->
          <v-card class="step-card" :class="{ 'step-card--active': stepFocus === 1 }" elevation="0" border rounded="lg" @click="stepFocus = 1">
            <div class="step-card__accent" />
            <div class="pa-5">
              <div class="d-flex align-center ga-2 mb-3">
                <div class="step-badge">
                  <v-icon size="18">mdi-account-search</v-icon>
                </div>
                <div>
                  <span class="text-subtitle-2 font-weight-bold" style="color:#1e293b">Select Customer</span>
                  <span class="text-caption text-medium-emphasis ml-1">— optional</span>
                </div>
              </div>
              <v-autocomplete
                v-model="customerId"
                :items="customerOptions"
                item-title="label"
                item-value="id"
                label="Search and select a customer (optional)"
                density="comfortable"
                variant="outlined"
                hide-details="auto"
                clearable
                :loading="customersLoading"
                prepend-inner-icon="mdi-account-search"
              />
              <v-alert
                v-if="!customerId"
                type="info"
                variant="tonal"
                density="compact"
                icon="mdi-information-outline"
                class="mt-3"
                style="background:#f0f9ff;border-color:#bae6fd"
              >
                No customer selected — fill in the <b>Invoice To</b> details manually below.
              </v-alert>
            </div>
          </v-card>

          <!-- Step 2: Invoice To -->
          <v-card class="step-card" :class="{ 'step-card--active': stepFocus === 2 }" elevation="0" border rounded="lg" @click="stepFocus = 2">
            <div class="step-card__accent" />
            <div class="pa-5">
              <div class="d-flex align-center ga-2 mb-3">
                <div class="step-badge">
                  <v-icon size="18">mdi-card-account-details-outline</v-icon>
                </div>
                <div>
                  <span class="text-subtitle-2 font-weight-bold" style="color:#1e293b">Invoice To</span>
                  <span class="text-caption text-medium-emphasis ml-1">— billing recipient</span>
                </div>
              </div>
              <v-row dense>
                <v-col cols="12" md="6">
                  <v-text-field
                    v-model="invoiceTo.name"
                    label="Name / Recipient"
                    density="comfortable"
                    variant="outlined"
                    hide-details="auto"
                    prepend-inner-icon="mdi-account-outline"
                    class="mb-3"
                  />
                  <v-text-field
                    v-model="invoiceTo.company"
                    label="Company (optional)"
                    density="comfortable"
                    variant="outlined"
                    hide-details="auto"
                    prepend-inner-icon="mdi-domain"
                    class="mb-3"
                  />
                  <v-text-field
                    v-model="invoiceTo.phone"
                    label="Phone (optional)"
                    density="comfortable"
                    variant="outlined"
                    hide-details="auto"
                    prepend-inner-icon="mdi-phone-outline"
                  />
                </v-col>
                <v-col cols="12" md="6">
                  <v-text-field
                    v-model="invoiceTo.email"
                    label="Email (optional)"
                    density="comfortable"
                    variant="outlined"
                    hide-details="auto"
                    prepend-inner-icon="mdi-email-outline"
                    class="mb-3"
                  />
                  <v-textarea
                    v-model="invoiceTo.address"
                    label="Address (optional)"
                    density="comfortable"
                    variant="outlined"
                    hide-details="auto"
                    rows="4"
                    prepend-inner-icon="mdi-map-marker-outline"
                  />
                </v-col>
              </v-row>
            </div>
          </v-card>

          <!-- Step 3: Line Items -->
          <v-card class="step-card" :class="{ 'step-card--active': stepFocus === 3 }" elevation="0" border rounded="lg" @click="stepFocus = 3">
            <div class="step-card__accent" />
            <div class="pa-5">
              <div class="d-flex align-center ga-2 mb-3">
                <div class="step-badge">
                  <v-icon size="18">mdi-format-list-bulleted</v-icon>
                </div>
                <span class="text-subtitle-2 font-weight-bold" style="color:#1e293b">Line Items</span>
                <v-spacer />
                <v-chip size="x-small" variant="tonal" :color="brandColor" class="font-weight-bold">{{ validLineItemsCount }} item{{ validLineItemsCount === 1 ? '' : 's' }}</v-chip>
                <v-btn size="small" :color="brandColor" variant="tonal" prepend-icon="mdi-plus" @click.stop="addLineItem">Add Item</v-btn>
              </div>

              <!-- Line items table -->
              <div class="line-items-table rounded-lg border">
                <!-- Header row -->
                <div class="li-row li-header">
                  <div class="li-col li-desc">Description</div>
                  <div class="li-col li-vehicle">Vehicle</div>
                  <div class="li-col li-qty text-center">Qty</div>
                  <div class="li-col li-unit text-end">Rate</div>
                  <div class="li-col li-total text-end">Amount</div>
                  <div class="li-col li-action"></div>
                </div>
                <!-- Body rows -->
                <div v-for="(item, i) in lineItems" :key="i" class="li-row li-body">
                  <div class="li-col li-desc">
                    <v-text-field
                      v-model="item.description"
                      placeholder="Enter description…"
                      density="compact"
                      variant="outlined"
                      hide-details
                      class="li-input"
                    />
                  </div>
                  <div class="li-col li-vehicle">
                    <v-autocomplete
                      v-model="item.vehicle_id"
                      :items="vehicleOptions"
                      item-title="label"
                      item-value="id"
                      placeholder="Select…"
                      density="compact"
                      variant="outlined"
                      hide-details
                      clearable
                      class="li-input li-input-vehicle"
                      :loading="vehiclesLoading"
                    />
                  </div>
                  <div class="li-col li-qty">
                    <v-text-field
                      v-model.number="item.quantity"
                      type="number"
                      min="1"
                      density="compact"
                      variant="outlined"
                      hide-details
                      class="li-input li-input-qty"
                      @input="recalcLine(i)"
                    />
                  </div>
                  <div class="li-col li-unit">
                    <div class="rate-cell">
                      <v-text-field
                        v-model.number="item.unit_amount"
                        type="number"
                        min="0"
                        density="compact"
                        variant="outlined"
                        hide-details
                        class="li-input li-input-unit"
                        :prefix="currencySymbol"
                        @input="recalcLine(i)"
                      />
                      <v-select
                        v-model="item.rate_period"
                        :items="ratePeriodOptions"
                        density="compact"
                        variant="outlined"
                        hide-details
                        class="li-input li-input-period"
                      />
                    </div>
                  </div>
                  <div class="li-col li-total text-end">
                    <span class="li-total-text">{{ currencySymbol }}{{ (Number(item.total_amount) || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) }}</span>
                  </div>
                  <div class="li-col li-action text-center">
                    <v-btn icon="mdi-delete-outline" size="x-small" variant="text" color="error" @click="removeLineItem(i)" :disabled="lineItems.length &lt;= 1" />
                  </div>
                </div>
              </div>
              <button v-if="lineItems.length" class="add-item-btn mt-3" @click.stop="addLineItem">
                <v-icon size="16" class="mr-1">mdi-plus-circle-outline</v-icon>
                <span class="text-caption font-weight-medium">Add another item</span>
              </button>
              <div v-else class="empty-items" @click.stop="addLineItem">
                <v-icon size="28" color="grey-lighten-1">mdi-package-variant-closed</v-icon>
                <p class="text-caption text-medium-emphasis mt-2">No line items yet. <span class="brand-text font-weight-bold">Click to add one.</span></p>
              </div>
            </div>
          </v-card>

          <!-- Step 4: Details + Branding -->
          <v-card class="step-card" :class="{ 'step-card--active': stepFocus === 4 }" elevation="0" border rounded="lg" @click="stepFocus = 4">
            <div class="step-card__accent" />
            <div class="pa-5">
              <div class="d-flex align-center ga-2 mb-3">
                <div class="step-badge">
                  <v-icon size="18">mdi-cog-outline</v-icon>
                </div>
                <span class="text-subtitle-2 font-weight-bold" style="color:#1e293b">Invoice Details</span>
              </div>

              <!-- Brand color picker -->
              <div class="brand-picker mb-4">
                <div class="d-flex align-center ga-2 mb-2">
                  <v-icon size="16" :color="brandColor">mdi-palette</v-icon>
                  <span class="text-caption font-weight-bold" style="color:#1e293b">BRANDING COLOR</span>
                  <span class="text-caption text-medium-emphasis">— appears on the invoice header, table header, and total</span>
                </div>
                <div class="d-flex align-center ga-2 flex-wrap">
                  <div
                    v-for="c in brandColorPresets"
                    :key="c.value"
                    class="brand-swatch"
                    :class="{ 'brand-swatch--active': brandColor === c.value }"
                    :style="{ background: c.value }"
                    :title="c.label"
                    @click="brandColor = c.value"
                  />
                  <v-divider vertical class="mx-1" />
                  <div class="d-flex align-center ga-1">
                    <v-icon size="16" color="medium-emphasis">mdi-eyedropper</v-icon>
                    <input
                      v-model="brandColor"
                      type="color"
                      class="brand-color-input"
                      title="Custom color"
                    />
                    <v-text-field
                      v-model="brandColor"
                      density="compact"
                      variant="outlined"
                      hide-details
                      class="brand-hex-input"
                      prefix="#"
                      style="max-width:100px"
                    />
                  </div>
                </div>
              </div>

              <v-row dense>
                <v-col cols="12" md="6">
                  <v-text-field
                    v-model="dueDate"
                    type="date"
                    label="Due Date (optional)"
                    density="comfortable"
                    variant="outlined"
                    hide-details="auto"
                    prepend-inner-icon="mdi-calendar-alert"
                    class="mb-3"
                  />
                  <v-row dense>
                    <v-col cols="6">
                      <v-text-field
                        v-model.number="discountTotal"
                        type="number"
                        min="0"
                        label="Discount"
                        density="comfortable"
                        variant="outlined"
                        hide-details="auto"
                        prepend-inner-icon="mdi-tag-minus-outline"
                        class="mb-3"
                      />
                    </v-col>
                    <v-col cols="6">
                      <v-text-field
                        v-model.number="taxPercent"
                        type="number"
                        min="0"
                        max="100"
                        label="Tax %"
                        density="comfortable"
                        variant="outlined"
                        hide-details="auto"
                        prepend-inner-icon="mdi-percent-outline"
                        class="mb-3"
                      />
                    </v-col>
                  </v-row>
                  <v-textarea
                    v-model="notes"
                    label="Notes (optional)"
                    density="comfortable"
                    variant="outlined"
                    hide-details="auto"
                    rows="2"
                  />
                </v-col>
                <v-col cols="12" md="6">
                  <div class="calc-box pa-4 rounded-lg h-100">
                    <div class="d-flex align-center ga-1 mb-3">
                      <v-icon size="16" class="brand-text">mdi-calculator-variant</v-icon>
                      <span class="text-caption font-weight-bold brand-text">BASIC CALCULATION</span>
                    </div>
                    <div class="calc-row">
                      <span class="calc-label">Subtotal</span>
                      <span class="calc-value">{{ currencySymbol }}{{ (subtotal ?? 0).toLocaleString() }}</span>
                    </div>
                    <div class="calc-row">
                      <span class="calc-label">Discount</span>
                      <span class="calc-value" style="color:#ef4444">- {{ currencySymbol }}{{ Number(discountTotal || 0).toLocaleString() }}</span>
                    </div>
                    <div class="calc-row">
                      <span class="calc-label">Taxes ({{ Number(taxPercent || 0) }}%)</span>
                      <span class="calc-value">{{ currencySymbol }}{{ taxAmount.toLocaleString() }}</span>
                    </div>
                    <v-divider class="my-3" />
                    <div class="calc-row calc-row--final">
                      <span class="text-subtitle-2 font-weight-bold">Total</span>
                      <span class="text-subtitle-1 font-weight-bold brand-text">{{ currencySymbol }}{{ grandTotal.toLocaleString() }}</span>
                    </div>
                  </div>
                </v-col>
              </v-row>
            </div>
          </v-card>

        </div>
      </div>

      <!-- RIGHT: Sticky Summary Sidebar -->
      <div style="flex:0 0 340px;min-width:340px;max-width:340px">
        <div class="sticky-wrap">
          <v-card class="summary-panel" elevation="0" border rounded="lg">
            <!-- Panel header -->
            <div class="summary-panel__header d-flex align-center ga-2">
              <v-avatar size="36" color="white" rounded="lg" class="summary-header-icon">
                <v-icon size="18" :color="brandColor">mdi-file-document</v-icon>
              </v-avatar>
              <div>
                <div class="text-caption font-weight-bold" style="color:#fff;letter-spacing:0.04em">LIVE PREVIEW</div>
                <div style="color:rgba(255,255,255,.7);font-size:0.7rem">Auto-updates as you type</div>
              </div>
            </div>

            <div class="pa-4">
              <!-- Recipient card -->
              <div class="recipient-box">
                <div class="text-caption" style="color:#94a3b8;font-weight:600">INVOICE TO</div>
                <div class="text-subtitle-1 mt-1 font-weight-bold" style="color:#1e293b">{{ invoiceTo.name || 'Unspecified' }}</div>
                <div v-if="invoiceTo.company" class="text-body-2 font-weight-medium" style="color:#4f46e5">{{ invoiceTo.company }}</div>
                <div v-if="invoiceTo.address" class="text-caption mt-1" style="color:#64748b;line-height:1.5">{{ invoiceTo.address }}</div>
                <div class="d-flex flex-column ga-1 mt-2">
                  <div v-if="invoiceTo.email" class="d-flex align-center ga-1">
                    <v-icon size="13" color="medium-emphasis">mdi-email-outline</v-icon>
                    <span class="text-caption" style="color:#64748b">{{ invoiceTo.email }}</span>
                  </div>
                  <div v-if="invoiceTo.phone" class="d-flex align-center ga-1">
                    <v-icon size="13" color="medium-emphasis">mdi-phone-outline</v-icon>
                    <span class="text-caption" style="color:#64748b">{{ invoiceTo.phone }}</span>
                  </div>
                </div>
                <div v-if="!invoiceTo.name && !invoiceTo.company && !invoiceTo.email && !invoiceTo.phone && !invoiceTo.address" class="d-flex align-center ga-2 mt-2">
                  <v-icon size="16" color="warning">mdi-alert-circle-outline</v-icon>
                  <span class="text-caption font-weight-medium" style="color:#f59e0b">Fill in Invoice To to identify the recipient</span>
                </div>
              </div>

              <!-- Line items mini preview -->
              <div class="mt-4">
                <div class="d-flex align-center justify-space-between mb-2">
                  <span class="text-caption font-weight-bold" style="color:#475569">ITEMS</span>
                  <v-chip size="x-small" variant="tonal" :color="brandColor">{{ validLineItemsCount }}</v-chip>
                </div>
                <div v-if="validLineItemsPreview.length" class="items-mini-list">
                  <div v-for="(item, i) in validLineItemsPreview" :key="i" class="mini-item py-1">
                    <div class="d-flex justify-space-between align-start">
                      <span class="text-body-2 text-truncate" style="color:#334155;max-width:170px">{{ item.description }}</span>
                      <span class="text-body-2 font-weight-medium" style="color:#1e293b;white-space:nowrap">{{ currencySymbol }}{{ item.amount.toLocaleString() }}</span>
                    </div>
                    <div v-if="item.vehicleName" class="text-caption" style="color:#94a3b8;margin-top:1px">
                      <v-icon size="11" class="mr-1">mdi-car-outline</v-icon>{{ item.vehicleName }}
                    </div>
                    <div v-if="item.rateDisplay" class="text-caption brand-text" style="margin-top:1px;font-weight:600">
                      {{ item.rateDisplay }}
                    </div>
                  </div>
                </div>
                <div v-else class="text-center py-4">
                  <v-icon size="24" color="grey-lighten-2">mdi-package-variant-closed</v-icon>
                  <p class="text-caption text-medium-emphasis mt-1">No items yet</p>
                </div>
              </div>

              <!-- Totals -->
              <v-divider class="my-3" />
              <div class="calc-row">
                <span class="calc-label">Subtotal</span>
                <span class="calc-value">{{ currencySymbol }}{{ (subtotal ?? 0).toLocaleString() }}</span>
              </div>
              <div class="calc-row">
                <span class="calc-label">Discount</span>
                <span class="calc-value" style="color:#ef4444">- {{ currencySymbol }}{{ Number(discountTotal || 0).toLocaleString() }}</span>
              </div>
              <div class="calc-row">
                  <span class="calc-label">Taxes ({{ Number(taxPercent || 0) }}%)</span>
                  <span class="calc-value">{{ currencySymbol }}{{ taxAmount.toLocaleString() }}</span>
              </div>
              <div class="summary-total">
                <span class="text-subtitle-1 font-weight-bold" style="color:#fff">Total</span>
                <span class="text-h6 font-weight-black" style="color:#fff">{{ currencySymbol }}{{ grandTotal.toLocaleString() }}</span>
              </div>

              <div v-if="dueDate" class="d-flex align-center ga-1 mt-3 pa-2 rounded" style="background:#fff7ed">
                <v-icon size="16" color="#ea580c">mdi-calendar-clock</v-icon>
                <span class="text-caption" style="color:#9a3412">Due <b>{{ formatDate(dueDate) }}</b></span>
              </div>

              <!-- Action buttons -->
              <div class="d-flex flex-column ga-2 mt-4">
                <v-btn :color="brandColor" size="large" :prepend-icon="isEditMode ? 'mdi-content-save-edit-outline' : 'mdi-file-document-plus-outline'" :loading="generating" :disabled="!canGenerate" @click="doGenerate" class="generate-btn">
                  {{ isEditMode ? 'Update Invoice' : 'Generate Invoice' }}
                </v-btn>
                <v-btn variant="text" size="small" prepend-icon="mdi-close" @click="navigateTo('/app/invoices')">Cancel</v-btn>
              </div>

              <v-alert
                v-if="!canGenerate && !generating"
                type="warning"
                variant="tonal"
                density="compact"
                icon="mdi-shield-alert-outline"
                class="mt-3"
                style="background:#fefce8;border-color:#fef08a"
              >
                {{ generationHint }}
              </v-alert>
            </div>
          </v-card>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

const { $api, $swal } = useNuxtApp()
const { currencySymbol } = useCurrency()
const route = useRoute()

/* ── Edit Mode ── */
const editId = computed(() => {
  const raw = route.query.edit
  return raw ? Number(raw) : null
})
const isEditMode = computed(() => editId.value !== null)
const existingInvoice = ref<any>(null)

/* ── UI: which step card is highlighted ── */
const stepFocus = ref(1)

/* ── Branding color ── */
const brandColorPresets = [
  { label: 'Teal', value: '#0d9488' },
  { label: 'Indigo', value: '#4f46e5' },
  { label: 'Blue', value: '#2563eb' },
  { label: 'Emerald', value: '#059669' },
  { label: 'Cyan', value: '#0891b2' },
  { label: 'Violet', value: '#7c3aed' },
  { label: 'Rose', value: '#e11d48' },
  { label: 'Orange', value: '#ea580c' },
  { label: 'Amber', value: '#d97706' },
  { label: 'Slate', value: '#334155' },
]
const brandColor = ref('#0d9488')

/** Parse a hex color (#rrggbb) into r,g,b integers */
function hexToRgb(hex: string): [number, number, number] {
  const h = hex.replace('#', '')
  const n = parseInt(h.length === 3 ? h.split('').map((c) => c + c).join('') : h, 16)
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255]
}

/** Darken a hex color by a factor (0..1, lower = darker) */
function darken(hex: string, factor: number): string {
  const [r, g, b] = hexToRgb(hex)
  return `#${Math.round(r * factor).toString(16).padStart(2, '0')}${Math.round(g * factor).toString(16).padStart(2, '0')}${Math.round(b * factor).toString(16).padStart(2, '0')}`
}

/** Mix a hex color with white by a ratio (0 = original, 1 = white) */
function tint(hex: string, ratio: number): string {
  const [r, g, b] = hexToRgb(hex)
  return `#${Math.round(r + (255 - r) * ratio).toString(16).padStart(2, '0')}${Math.round(g + (255 - g) * ratio).toString(16).padStart(2, '0')}${Math.round(b + (255 - b) * ratio).toString(16).padStart(2, '0')}`
}

const brandVars = computed(() => {
  const hex = brandColor.value
  return {
    '--brand': hex,
    '--brand-dark': darken(hex, 0.7),
    '--brand-darker': darken(hex, 0.5),
    '--brand-tint': tint(hex, 0.92),
    '--brand-tint-strong': tint(hex, 0.8),
    '--brand-outline': tint(hex, 0.6),
  } as Record<string, string>
})

/* ── Customer ── */
const customerId = ref<number | null>(null)
const customerOptions = ref<any[]>([])
const customersLoading = ref(false)

const selectedCustomerName = computed(() => {
  const c = customerOptions.value.find((c) => c.id === customerId.value)
  return c ? c.label.split(' (')[0] : '—'
})

/* ── Invoice To ── */
const invoiceTo = reactive({
  name: '',
  company: '',
  email: '',
  phone: '',
  address: '',
})

function resetInvoiceTo() {
  invoiceTo.name = ''
  invoiceTo.company = ''
  invoiceTo.email = ''
  invoiceTo.phone = ''
  invoiceTo.address = ''
}

function fillInvoiceToFromCustomer(c: any) {
  invoiceTo.name = c?.full_name || ''
  invoiceTo.company = ''
  invoiceTo.email = c?.email || ''
  invoiceTo.phone = c?.phone || ''
  invoiceTo.address = c?.address || ''
}

const customersRaw = ref<any[]>([])
let suppressCustomerWatch = false

watch(customerId, (newId) => {
  if (suppressCustomerWatch) return
  if (newId) {
    const c = customersRaw.value.find((x: any) => x.id === newId)
    fillInvoiceToFromCustomer(c)
  } else {
    resetInvoiceTo()
  }
})

async function loadCustomers() {
  customersLoading.value = true
  try {
    const res = await $api('/rentals/customers/', { query: { page_size: 200 } })
    const list = res?.results || res || []
    customersRaw.value = list
    customerOptions.value = list.map((c: any) => ({
      id: c.id,
      label: `${c.full_name} (${(c.customer_type || '').replace('_', ' ')})`,
    }))
  } catch {
    customerOptions.value = []
  } finally {
    customersLoading.value = false
  }
}

/* ── Vehicles ── */
const vehicleOptions = ref<any[]>([])
const vehiclesLoading = ref(false)
const vehiclesRaw = ref<any[]>([])

const vehiclesMap = computed(() => {
  const m = new Map<number, any>()
  for (const v of vehiclesRaw.value) m.set(v.id, v)
  return m
})

async function loadVehicles() {
  vehiclesLoading.value = true
  try {
    const res = await $api('/vehicles/vehicles/', { query: { page_size: 500 } })
    const list = res?.results || res || []
    vehiclesRaw.value = list
    vehicleOptions.value = list.map((v: any) => ({
      id: v.id,
      label: `${v.display_name || v.license_plate || `#${v.id}`}${v.license_plate ? ` · ${v.license_plate}` : ''}`,
    }))
  } catch {
    vehicleOptions.value = []
  } finally {
    vehiclesLoading.value = false
  }
}

/* ── Line items ── */
interface LineItem {
  description: string
  vehicle_id: number | null
  quantity: number
  unit_amount: number
  rate_period: string
  total_amount: number
}

const ratePeriodOptions = [
  { title: '/ Day', value: 'day' },
  { title: '/ Hour', value: 'hour' },
  { title: '/ Km', value: 'km' },
  { title: '/ Mile', value: 'mile' },
  { title: '/ Week', value: 'week' },
  { title: '/ Month', value: 'month' },
  { title: '/ Trip', value: 'trip' },
  { title: 'Flat', value: 'flat' },
]

function ratePeriodLabel(value: string): string {
  const opt = ratePeriodOptions.find((o) => o.value === value)
  return opt ? opt.title : ''
}

const lineItems = ref<LineItem[]>([
  { description: '', vehicle_id: null, quantity: 1, unit_amount: 0, rate_period: 'day', total_amount: 0 },
])

function addLineItem() {
  lineItems.value.push({ description: '', vehicle_id: null, quantity: 1, unit_amount: 0, rate_period: 'day', total_amount: 0 })
}

function removeLineItem(index: number) {
  if (lineItems.value.length > 1) {
    lineItems.value.splice(index, 1)
  }
}

function recalcLine(index: number) {
  const item = lineItems.value[index]
  item.total_amount = Number(item.quantity || 0) * Number(item.unit_amount || 0)
}

function vehicleLabel(id: number | null): string {
  if (!id) return ''
  const v = vehiclesMap.value.get(id)
  if (!v) return ''
  return v.display_name || v.license_plate || `#${id}`
}

const validLineItemsPreview = computed(() =>
  lineItems.value
    .filter((i) => i.description.trim())
    .map((i) => ({
      description: i.description.trim(),
      amount: Number(i.total_amount || 0),
      vehicleName: vehicleLabel(i.vehicle_id),
      rateDisplay: `${currencySymbol.value}${Number(i.unit_amount || 0).toLocaleString()} ${ratePeriodLabel(i.rate_period)}`,
    }))
    .slice(0, 5),
)

const validLineItemsCount = computed(() =>
  lineItems.value.filter((i) => i.description.trim()).length,
)

/* ── Totals ── */
const dueDate = ref('')
const discountTotal = ref(0)
const taxPercent = ref(0)
const notes = ref('')
const generating = ref(false)

const subtotal = computed(() =>
  lineItems.value.reduce((s, item) => s + (Number(item.quantity || 0) * Number(item.unit_amount || 0)), 0)
)

const taxAmount = computed(() =>
  subtotal.value * (Number(taxPercent.value || 0) / 100)
)

const grandTotal = computed(() =>
  subtotal.value - Number(discountTotal.value || 0) + taxAmount.value
)

const hasLineItems = computed(() => lineItems.value.some((i) => i.description.trim()))
const hasRecipient = computed(() => Boolean(customerId.value || invoiceTo.name.trim()))

const canGenerate = computed(() => hasLineItems.value && hasRecipient.value)

const generationHint = computed(() => {
  if (!hasLineItems.value && !hasRecipient.value) return 'Add at least one item and a recipient name.'
  if (!hasLineItems.value) return 'Add at least one line item with a description.'
  if (!hasRecipient.value) return 'Enter a recipient name in Invoice To or select a customer.'
  return ''
})

function formatDate(d: string) {
  if (!d) return '—'
  const date = new Date(d + 'T00:00:00')
  return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })
}

/* ── Generate / Update ── */
async function doGenerate() {
  if (!canGenerate.value) return
  generating.value = true
  try {
    const validItems = lineItems.value
      .filter((i) => i.description.trim())
      .map((i) => ({
        description: i.description.trim(),
        vehicle: i.vehicle_id || null,
        quantity: i.quantity,
        unit_amount: i.unit_amount,
        rate_period: i.rate_period,
        total_amount: i.total_amount,
      }))

    const payload: any = {
      customer: customerId.value || null,
      line_items: validItems,
      discount_total: Number(discountTotal.value || 0),
      tax_percent: Number(taxPercent.value || 0),
      taxes: Number(taxAmount.value.toFixed(2)),
      invoice_to: {
        name: invoiceTo.name.trim(),
        company: invoiceTo.company.trim(),
        email: invoiceTo.email.trim(),
        phone: invoiceTo.phone.trim(),
        address: invoiceTo.address.trim(),
      },
      branding_color: brandColor.value,
    }
    if (dueDate.value) payload.due_date = dueDate.value
    if (notes.value) payload.notes = notes.value
    if (isEditMode.value) {
      if (existingInvoice.value?.amount_paid !== undefined) {
        payload.amount_paid = Number(existingInvoice.value.amount_paid || 0)
      }
      payload.status = existingInvoice.value?.status || 'draft'
    }

    if (isEditMode.value && editId.value) {
      await $api(`/rentals/invoices/${editId.value}/update-custom/`, { method: 'PATCH', body: payload })
      $swal.fire({ icon: 'success', title: 'Custom invoice updated', toast: true, timer: 1800, position: 'top-end' })
    } else {
      await $api('/rentals/invoices/custom/', { method: 'POST', body: payload })
      $swal.fire({ icon: 'success', title: 'Custom invoice generated', toast: true, timer: 1800, position: 'top-end' })
    }
    navigateTo('/app/invoices')
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: isEditMode.value ? 'Failed to update' : 'Failed to generate', text: e?.data?.detail || '', toast: true, timer: 3000, position: 'top-end' })
  } finally {
    generating.value = false
  }
}

/* ── Load existing invoice for edit mode ── */
async function loadInvoiceForEdit() {
  if (!editId.value) return
  try {
    const inv = await $api(`/rentals/invoices/${editId.value}/`)
    existingInvoice.value = inv
    // Populate form fields from the invoice
    customerId.value = inv.customer || null
    const ito = inv.invoice_to || {}
    invoiceTo.name = ito.name || ''
    invoiceTo.company = ito.company || ''
    invoiceTo.email = ito.email || ''
    invoiceTo.phone = ito.phone || ''
    invoiceTo.address = ito.address || ''
    brandColor.value = inv.branding_color || '#0d9488'
    dueDate.value = inv.due_date || ''
    notes.value = inv.notes || ''
    discountTotal.value = Number(inv.discount_total || 0)
    // Reverse-compute tax_percent from stored taxes/subtotal if possible
    if (inv.subtotal && inv.taxes) {
      const pct = (Number(inv.taxes) / Number(inv.subtotal)) * 100
      taxPercent.value = Math.round(pct * 100) / 100
    } else {
      taxPercent.value = 0
    }
    // Populate line items
    const items = inv.line_items || []
    if (items.length) {
      lineItems.value = items.map((li: any) => ({
        description: li.description || '',
        vehicle_id: li.vehicle?.id || null,
        quantity: Number(li.quantity || 1),
        unit_amount: Number(li.unit_amount || 0),
        rate_period: li.rate_period || 'flat',
        total_amount: Number(li.total_amount || 0),
      }))
    }
  } catch {
    $swal.fire({ icon: 'error', title: 'Failed to load invoice', text: 'Invoice not found or access denied.', toast: true, timer: 3000, position: 'top-end' })
    navigateTo('/app/invoices')
  }
}

onMounted(async () => {
  await loadCustomers()
  await loadVehicles()
  if (isEditMode.value) {
    suppressCustomerWatch = true
    await loadInvoiceForEdit()
    await nextTick()
    suppressCustomerWatch = false
  }
})
</script>

<style scoped>
/* ── Hero header ── */
.hero-header {
  background: linear-gradient(135deg, var(--brand) 0%, var(--brand-dark) 50%, var(--brand-darker) 100%);
  border-radius: 16px;
  padding: 20px 24px;
  margin-bottom: 16px;
  position: relative;
  overflow: hidden;
  transition: background 0.3s ease;
}
.hero-header::after {
  content: '';
  position: absolute;
  top: -20px;
  right: -20px;
  width: 140px;
  height: 140px;
  background: rgba(255, 255, 255, 0.06);
  border-radius: 50%;
}
.hero-header::before {
  content: '';
  position: absolute;
  bottom: -30px;
  right: 60px;
  width: 80px;
  height: 80px;
  background: rgba(255, 255, 255, 0.04);
  border-radius: 50%;
}
.hero-icon {
  background: rgba(255, 255, 255, 0.15);
  border: 1px solid rgba(255, 255, 255, 0.25);
}
.hero-back-btn {
  background: rgba(255, 255, 255, 0.12) !important;
  color: #fff !important;
}
.hero-back-btn:hover {
  background: rgba(255, 255, 255, 0.2) !important;
}

/* ── Helper: brand-colored text ── */
.brand-text {
  color: var(--brand) !important;
}

/* ── Step cards ── */
.step-card {
  position: relative;
  overflow: visible;
  transition: box-shadow 0.2s ease, border-color 0.2s ease;
  cursor: pointer;
}
.step-card:hover {
  box-shadow: 0 4px 12px var(--brand-outline);
}
.step-card--active {
  border-color: var(--brand-outline) !important;
  box-shadow: 0 4px 16px var(--brand-tint-strong);
}
.step-card__accent {
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 4px;
  border-radius: 8px 0 0 8px;
  z-index: 1;
  background: linear-gradient(180deg, var(--brand), var(--brand-dark));
}
.step-badge {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  background: var(--brand-tint);
  color: var(--brand);
  outline: 1px solid var(--brand-outline);
}

/* ── Brand color picker ── */
.brand-picker {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 14px;
}
.brand-swatch {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  cursor: pointer;
  border: 2px solid transparent;
  transition: transform 0.15s ease, border-color 0.15s ease;
  position: relative;
}
.brand-swatch:hover {
  transform: scale(1.1);
}
.brand-swatch--active {
  border-color: #1e293b;
  transform: scale(1.05);
}
.brand-swatch--active::after {
  content: '';
  position: absolute;
  inset: -4px;
  border: 1px solid var(--brand);
  border-radius: 10px;
}
.brand-color-input {
  width: 40px;
  height: 36px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  cursor: pointer;
  padding: 2px;
  background: #fff;
}
.brand-color-input::-webkit-color-swatch-wrapper {
  padding: 0;
}
.brand-color-input::-webkit-color-swatch {
  border: none;
  border-radius: 6px;
}

/* ── Line items table ── */
.line-items-table {
  overflow: hidden;
  background: #fff;
}
.li-row {
  display: flex;
  align-items: center;
  min-height: 44px;
}
.li-row + .li-row {
  border-top: 1px solid #f1f5f9;
}
.li-header {
  background: var(--brand-tint);
  font-size: 0.7rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--brand);
  min-height: 38px;
}
.li-header .li-col {
  padding: 8px 10px;
}
.li-body .li-col {
  padding: 4px 10px;
}
.li-col {
  display: flex;
  align-items: center;
}
.li-desc { flex: 1 1 120px; min-width: 80px; }
.li-vehicle { width: 180px; min-width: 120px; }
.li-qty { width: 108px; justify-content: center; }
.li-unit { width: 280px; justify-content: flex-end; }
.li-total { width: 110px; justify-content: flex-end; }
.li-action { width: 40px; }
.li-input-qty :deep(input) { text-align: center; }
.li-input-unit :deep(input) { text-align: right; }
.li-input-vehicle :deep(.v-field__input) { font-size: 0.75rem; padding-top: 8px; min-height: 32px; }
.li-input-period :deep(.v-field__input) { font-size: 0.7rem; padding-top: 6px; min-height: 30px; }

/* Rate cell: number + period selector side by side */
.rate-cell {
  display: flex;
  gap: 6px;
}
.rate-cell .li-input-unit {
  flex: 1 1 0;
}
.li-input-period {
  flex: 0 0 110px;
}
.li-total-text {
  font-weight: 600;
  color: #1e293b;
  font-size: 0.875rem;
}

.empty-items {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 28px;
  border: 2px dashed #e2e8f0;
  border-radius: 12px;
  cursor: pointer;
  transition: border-color 0.2s, background 0.2s;
}
.empty-items:hover {
  border-color: var(--brand-outline);
  background: var(--brand-tint);
}
.add-item-btn {
  display: flex;
  align-items: center;
  background: none;
  border: none;
  cursor: pointer;
  color: var(--brand);
  transition: color 0.2s;
}
.add-item-btn:hover {
  color: var(--brand-dark);
}

/* ── Calculation box ── */
.calc-box {
  background: var(--brand-tint);
  border: 1px solid var(--brand-outline);
}
.calc-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 4px 0;
}
.calc-label {
  font-size: 0.8125rem;
  color: #64748b;
}
.calc-value {
  font-size: 0.8125rem;
  font-weight: 600;
  color: #1e293b;
}
.calc-row--final {
  background: var(--brand-tint);
  border-radius: 10px;
  padding: 10px 14px;
  margin-top: 4px;
}

/* ── Sticky sidebar ── */
.sticky-wrap {
  position: sticky;
  top: 88px;
}
.summary-panel {
  border-color: #e2e8f0 !important;
}
.summary-panel__header {
  background: linear-gradient(135deg, var(--brand) 0%, var(--brand-dark) 100%);
  padding: 16px 16px 14px;
  border-radius: 16px 16px 0 0;
  margin: -1px;
  margin-bottom: 0;
  transition: background 0.3s ease;
}
.summary-header-icon {
  border: 1px solid rgba(255, 255, 255, 0.25);
}

/* Recipient box in preview */
.recipient-box {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 14px;
}

/* Mini items list */
.items-mini-list {
  max-height: 180px;
  overflow-y: auto;
  padding-right: 4px;
}
.mini-item + .mini-item {
  border-top: 1px dashed #f1f5f9;
}

/* Summary total */
.summary-total {
  background: linear-gradient(135deg, var(--brand), var(--brand-dark));
  border-radius: 12px;
  padding: 12px 16px;
  margin-top: 8px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  transition: background 0.3s ease;
}

/* Generate button */
.generate-btn {
  border-radius: 10px !important;
  text-transform: none !important;
  font-weight: 700 !important;
  letter-spacing: 0.01em !important;
}

/* ── Responsive ── */
@media (max-width: 960px) {
  .sticky-wrap {
    position: static;
  }
}
</style>
