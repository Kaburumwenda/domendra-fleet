<template>
  <div class="d-flex flex-column ga-4">
    <!-- Filter bar -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-2">
      <div class="d-flex align-center ga-2 flex-wrap">
        <v-btn-toggle v-model="datePreset" mandatory density="compact" color="primary" divided rounded="lg">
          <v-btn value="today" size="small">Today</v-btn>
          <v-btn value="yesterday" size="small">Yesterday</v-btn>
          <v-btn value="7d" size="small">7d</v-btn>
          <v-btn value="30d" size="small">30d</v-btn>
          <v-btn value="all" size="small">All</v-btn>
          <v-btn value="custom" size="small" @click="openCustomDate">Custom…</v-btn>
        </v-btn-toggle>
        <v-select
          v-model="fuelTypeFilter"
          :items="fuelFilterOptions"
          item-title="label"
          item-value="value"
          label="Fuel Type"
          density="compact"
          hide-details
          clearable
          variant="solo-filled"
          flat
          rounded="lg"
          style="max-width: 170px"
          @update:model-value="refreshTransactions"
        />
        <span class="text-caption text-medium-emphasis ml-2">{{ transactions.length }} transactions</span>
      </div>
      <div class="d-flex ga-2">
        <v-btn v-can="'fuel:delete'" v-if="selected.length" color="error" variant="tonal" size="small" prepend-icon="mdi-delete-outline" @click="bulkDelete">Delete ({{ selected.length }})</v-btn>
        <v-btn v-can="'fuel:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="openDialog()">Add Fuel</v-btn>
      </div>
    </div>

    <v-card elevation="0" border rounded="lg">
      <v-data-table
        v-model="selected"
        :headers="headers"
        :items="transactions"
        :loading="pending"
        hover
        show-select
        v-model:page="page"
        v-model:items-per-page="perPage"
        :search="search"
      >
        <template #top>
          <div class="pa-4 pb-2">
            <v-text-field
              v-model="search"
              prepend-inner-icon="mdi-magnify"
              label="Search transactions..."
              density="compact"
              variant="solo-filled"
              flat
              rounded="lg"
              hide-details
              single-line
            />
          </div>
        </template>
        <template #item.index="{ index }">
          <span class="text-caption text-medium-emphasis">{{ (page - 1) * perPage + index + 1 }}</span>
        </template>
        <template #item.date="{ value }">
          <div class="d-flex flex-column">
            <span class="text-body-2 font-weight-medium" style="color: #1e293b">{{ formatFuelDate(value).date }}</span>
            <span class="text-caption text-medium-emphasis">{{ formatFuelDate(value).time }}</span>
          </div>
        </template>
        <template #item.fuel_type="{ value }">
          <v-chip :color="fuelChipColor(value)" variant="flat" size="small">{{ value }}</v-chip>
        </template>
        <template #item.total_cost="{ value }"><span class="font-weight-medium">{{ currencySymbol }}{{ parseFloat(value).toFixed(2) }}</span></template>
        <template #item.price_per_unit="{ value }">{{ currencySymbol }}{{ value?.toFixed(3) }}</template>
        <template #item.quantity="{ value, item }">{{ value }} {{ (item as any).unit?.[0] === 'l' ? 'L' : 'gal' }}</template>
        <template #item.mpg="{ value }">
          <span v-if="value" :class="{ 'text-success': value > 8, 'text-warning': value > 0 && value <= 8, 'text-medium-emphasis': !value }">{{ value }}</span>
          <span v-else class="text-medium-emphasis">—</span>
        </template>
        <template #item.station_name="{ value, item }">
          <div class="d-flex flex-column">
            <span class="text-body-2">{{ value || '—' }}</span>
            <span v-if="(item as any).station_location" class="text-caption text-medium-emphasis text-truncate" style="max-width: 160px">{{ (item as any).station_location }}</span>
          </div>
        </template>
        <template #item.receipt_image="{ value }">
          <v-icon v-if="value" color="success" size="small">mdi-receipt-text-check-outline</v-icon>
          <v-icon v-else color="grey-lighten-1" size="small">mdi-receipt-text-outline</v-icon>
        </template>
        <template #item.actions="{ item }">
          <div class="d-flex ga-1">
            <v-btn icon="mdi-eye-outline" size="x-small" variant="text" color="info" title="View" @click="viewTransaction(item)" />
            <v-btn v-can="'fuel:update'" icon="mdi-pencil-outline" size="x-small" variant="text" color="warning" title="Edit" @click="editTransaction(item)" />
            <v-btn v-can="'fuel:delete'" icon="mdi-delete-outline" size="x-small" variant="text" color="error" title="Delete" @click="deleteTransaction(item)" />
          </div>
        </template>
        <template #no-data>
          <div class="text-center py-12 text-medium-emphasis">
            <v-icon size="48" class="mb-3">mdi-gas-station</v-icon>
            <p>No fuel transactions yet.</p>
          </div>
        </template>
      </v-data-table>
    </v-card>

    <!-- Add/Edit Dialog -->
    <v-dialog v-model="dialogVisible" max-width="640" scroll-strategy="none">
      <v-card rounded="xl" class="overflow-hidden">
        <AppModalHeader icon="mdi-gas-station">{{ editingTx ? 'Edit' : 'Add' }} Fuel Transaction</AppModalHeader>
        <v-card-text class="pt-5">
          <div class="text-caption text-medium-emphasis mb-4">Record a fuel purchase. Fields marked <span class="text-error">*</span> are required.</div>
          <v-row dense>
            <v-col cols="12">
              <v-select v-model="form.vehicle" :items="vehicleOptions" item-title="display_name" item-value="id" label="Vehicle *" placeholder="Select vehicle" :rules="[v => !!v || 'Vehicle is required']" required />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="form.date" type="datetime-local" label="Date & Time *" prepend-inner-icon="mdi-calendar-clock" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="6">
              <v-combobox v-model="form.fuel_type" :items="FUEL_TYPES" label="Fuel Type *" prepend-inner-icon="mdi-fuel" hide-details="auto" />
            </v-col>
            <v-col cols="6" md="3">
              <v-text-field v-model.number="form.quantity" label="Quantity *" type="number" min="0" step="0.001" prepend-inner-icon="mdi-gauge" hide-details="auto" />
            </v-col>
            <v-col cols="6" md="3">
              <v-select v-model="form.unit" :items="UNIT_OPTIONS" item-title="label" item-value="value" label="Unit *" hide-details="auto" :rules="[v => !!v || 'Unit is required']" required />
            </v-col>
            <v-col cols="6" md="3">
              <v-text-field v-model="form.total_cost" :label="`Total Cost (${currencySymbol}) *`" type="number" min="0" step="0.01" prepend-inner-icon="mdi-apple-keyboard-option" hide-details="auto" :rules="[v => (v !== '' && v != null && Number(v) > 0) || 'Required']" />
            </v-col>
            <v-col cols="6" md="3">
              <v-text-field v-model.number="form.odometer_reading" label="Odometer" type="number" min="0" prepend-inner-icon="mdi-counter" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="6">
              <v-combobox v-model="form.station_name" :items="STATION_OPTIONS" label="Station *" prepend-inner-icon="mdi-store-marker-outline" hide-details="auto" placeholder="Select or type a station…" :rules="[v => !!v || 'Station is required']" required />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field
                ref="stationLocationRef"
                v-model="form.station_location"
                label="Station Location *"
                prepend-inner-icon="mdi-map-marker-outline"
                hide-details="auto"
                :rules="[v => !!v || 'Station location is required']"
                required
                placeholder="Start typing an address…"
                autocomplete="off"
              />
            </v-col>
            <v-col cols="12" md="6">
              <v-select v-model="form.fuel_card" :items="cardOptions" item-title="label" item-value="value" label="Fuel Card" clearable prepend-inner-icon="mdi-credit-card-outline" hide-details="auto" />
            </v-col>
            <v-col cols="12">
              <v-textarea v-model="form.notes" label="Notes" rows="2" prepend-inner-icon="mdi-note-text-outline" hide-details="auto" />
            </v-col>
            <v-col cols="12">
              <div class="text-caption text-medium-emphasis mb-1 d-flex align-center ga-1"><v-icon size="14">mdi-receipt-text-outline</v-icon> Receipt <span class="text-error">*</span></div>
              <div
                class="fuel-dropzone position-relative rounded-lg d-flex flex-column align-center justify-center text-center cursor-pointer transition-all"
                :class="{ 'fuel-dropzone--active': isDragging }"
                style="border: 2px dashed; border-color: #cbd5e1; min-height: 140px; padding: 16px;"
                @click="triggerFilePicker"
                @dragover.prevent="onDragOver"
                @dragenter.prevent="onDragOver"
                @dragleave.prevent="onDragLeave"
                @drop.prevent="onDrop"
              >
                <input ref="fileInputRef" type="file" accept="image/*" class="d-none" @change="onFilePicked" />
                <template v-if="receiptPreview">
                  <div class="position-relative rounded-lg overflow-hidden" style="max-width: 200px; width: 100%">
                    <v-img :src="receiptPreview" cover :aspect-ratio="16/10" class="bg-grey-lighten-2" />
                    <v-btn icon="mdi-close" size="small" color="error" variant="flat" class="position-absolute" style="top: 6px; right: 6px;" @click.stop="clearReceipt" />
                  </div>
                  <p class="text-caption text-medium-emphasis mt-2 mb-0 text-truncate" style="max-width: 240px">{{ receiptFile?.name }} ({{ fileSize }})</p>
                </template>
                <template v-else-if="existingReceiptUrl">
                  <div class="position-relative rounded-lg overflow-hidden" style="max-width: 200px; width: 100%">
                    <v-img :src="existingReceiptUrl" cover :aspect-ratio="16/10" class="bg-grey-lighten-2" />
                    <v-btn icon="mdi-close" size="small" color="error" variant="flat" class="position-absolute" style="top: 6px; right: 6px;" @click.stop="existingReceiptUrl = null" />
                  </div>
                  <p class="text-caption text-medium-emphasis mt-2 mb-0">Current receipt (upload new to replace)</p>
                </template>
                <template v-else>
                  <v-icon :color="isDragging ? 'primary' : 'medium-emphasis'" size="36" class="mb-2">{{ isDragging ? 'mdi-tray-arrow-down' : 'mdi-cloud-upload-outline' }}</v-icon>
                  <p class="text-body-2 font-weight-medium mb-0" style="color: #475569">{{ isDragging ? 'Drop image here' : 'Drag &amp; drop receipt image here' }}</p>
                  <p class="text-caption text-medium-emphasis mt-1 mb-0">or <span class="text-primary font-weight-medium">browse</span> from your device · PNG / JPG / WebP</p>
                </template>
              </div>
              <p v-if="receiptError" class="text-caption text-error mt-1 mb-0">{{ receiptError }}</p>
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="dialogVisible = false">Cancel</v-btn>
          <v-btn v-can="'fuel:update'" v-if="editingTx" color="primary" prepend-icon="mdi-check" @click="save" :loading="saving">Update</v-btn>
          <template v-else>
            <v-btn v-can="'fuel:create'" color="primary" variant="outlined" prepend-icon="mdi-plus" @click="saveAndAddAnother" :loading="saving">Save &amp; Add Another</v-btn>
            <v-btn v-can="'fuel:create'" color="primary" prepend-icon="mdi-check" @click="save" :loading="saving">Save</v-btn>
          </template>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- View Transaction Dialog -->
    <v-dialog v-model="viewDialogVisible" max-width="580" scroll-strategy="none">
      <v-card rounded="xl" class="overflow-hidden" v-if="viewTx">
        <AppModalHeader icon="mdi-eye-outline">Transaction Details</AppModalHeader>
        <v-card-text class="pt-4">
          <v-row dense>
            <v-col cols="6"><p class="text-caption text-medium-emphasis">Vehicle</p><p class="text-body-2 font-weight-medium">{{ viewTx.vehicle_name }}</p></v-col>
            <v-col cols="6"><p class="text-caption text-medium-emphasis">Date</p><p class="text-body-2 font-weight-medium">{{ formatFuelDate(viewTx.date).date }} {{ formatFuelDate(viewTx.date).time }}</p></v-col>
            <v-col cols="6"><p class="text-caption text-medium-emphasis">Fuel Type</p><v-chip :color="fuelChipColor(viewTx.fuel_type)" variant="flat" size="small">{{ viewTx.fuel_type }}</v-chip></v-col>
            <v-col cols="6"><p class="text-caption text-medium-emphasis">Quantity</p><p class="text-body-2">{{ viewTx.quantity }} {{ viewTx.unit === 'liters' ? 'L' : 'gal' }}</p></v-col>
            <v-col cols="6"><p class="text-caption text-medium-emphasis">Total Cost</p><p class="text-body-2 font-weight-medium">{{ currencySymbol }}{{ parseFloat(viewTx.total_cost).toFixed(2) }}</p></v-col>
            <v-col cols="6"><p class="text-caption text-medium-emphasis">Price / Unit</p><p class="text-body-2">{{ currencySymbol }}{{ viewTx.price_per_unit?.toFixed(3) || '—' }}</p></v-col>
            <v-col cols="6"><p class="text-caption text-medium-emphasis">Odometer</p><p class="text-body-2">{{ viewTx.odometer_reading?.toLocaleString() || '—' }}</p></v-col>
            <v-col cols="6"><p class="text-caption text-medium-emphasis">MPG</p><p class="text-body-2">{{ viewTx.mpg || '—' }}</p></v-col>
            <v-col cols="6"><p class="text-caption text-medium-emphasis">Station</p><p class="text-body-2">{{ viewTx.station_name || '—' }}</p></v-col>
            <v-col cols="6"><p class="text-caption text-medium-emphasis">Station Location</p><p class="text-body-2">{{ viewTx.station_location || '—' }}</p></v-col>
            <v-col cols="12" v-if="viewTx.notes"><p class="text-caption text-medium-emphasis">Notes</p><p class="text-body-2">{{ viewTx.notes }}</p></v-col>
            <v-col cols="12" v-if="viewTx.receipt_image">
              <p class="text-caption text-medium-emphasis mb-2">Receipt</p>
              <div class="rounded-lg bg-grey-lighten-2 d-flex align-center justify-center" style="max-height: 400px; overflow-y: auto; overflow-x: hidden;">
                <v-img :src="resolvedReceiptUrl" contain style="max-width: 100%;" />
              </div>
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="viewDialogVisible = false">Close</v-btn>
          <v-btn v-can="'fuel:update'" color="warning" prepend-icon="mdi-pencil-outline" variant="tonal" @click="viewDialogVisible = false; editTransaction(viewTx)">Edit</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Custom Date Range Dialog -->
    <v-dialog v-model="customDateDialogVisible" max-width="420">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-calendar-range">Custom Date Range</AppModalHeader>
        <v-card-text class="pt-4">
          <v-row dense>
            <v-col cols="12">
              <v-text-field v-model="customFrom" type="date" label="From" density="comfortable" variant="outlined" prepend-inner-icon="mdi-calendar-start" hide-details="auto" />
            </v-col>
            <v-col cols="12">
              <v-text-field v-model="customTo" type="date" label="To" density="comfortable" variant="outlined" prepend-inner-icon="mdi-calendar-end" hide-details="auto" />
            </v-col>
            <v-col cols="12" v-if="customDateError" class="pt-2">
              <p class="text-caption text-error">{{ customDateError }}</p>
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="cancelCustomDate">Cancel</v-btn>
          <v-btn color="primary" prepend-icon="mdi-magnify" @click="applyCustomDate">Apply</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Status Note Dialog -->
    <v-dialog v-model="noteDialogVisible" max-width="480">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-pencil-outline">{{ noteDialogTitle }}</AppModalHeader>
        <v-card-text class="pt-4">
          <v-textarea v-model="statusNote" label="Note (optional)" rows="3" placeholder="Add a note about this action..." hide-details="auto" variant="outlined" />
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="noteDialogVisible = false">Cancel</v-btn>
          <v-btn color="primary" @click="confirmAction" :loading="actionLoading">{{ confirmLabel }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
const { $api, $swal } = useNuxtApp()
const { currencySymbol } = useCurrency()
const { attachAutocomplete } = useGoogleMaps()
const { resolveMediaUrl } = useMediaUrl()
const {
  fetchTransactions, saveTransaction,
  deleteTransaction: apiDeleteTransaction,
  fetchFraud, resolveFraud, dismissFraud, reviewFraud, reopenFraud,
} = useFuelApi()
const {
  FUEL_TYPES, UNIT_OPTIONS, STATION_OPTIONS,
  fuelChipColor, formatAlertType, formatFuelDate,
} = useFuelHelpers()

const emit = defineEmits<{ refresh: [] }>()

const props = defineProps<{
  vehicleOptions: any[]
  cardOptions: any[]
  datePresetModule: { value: string }
  dateParams: Record<string, string>
}>()

// ---- State ----
const dialogVisible = ref(false)
const saving = ref(false)
const search = ref('')
const selected = ref<any[]>([])
const page = ref(1)
const perPage = ref(15)
const fuelTypeFilter = ref('')

const form = reactive<any>({
  vehicle: null, date: new Date().toISOString().slice(0, 16), fuel_type: 'Petrol',
  quantity: 0, unit: 'liters', total_cost: '0', odometer_reading: null,
  station_name: '', station_location: '', notes: '', fuel_card: null,
})

const receiptFile = ref<File | null>(null)
const receiptPreview = computed(() => receiptFile.value ? URL.createObjectURL(receiptFile.value) : null)
const isDragging = ref(false)
const dragCounter = ref(0)
const receiptError = ref('')
const fileInputRef = ref<HTMLInputElement | null>(null)
const stationLocationRef = ref<HTMLInputElement | null>(null)

const fileSize = computed(() => {
  if (!receiptFile.value) return ''
  const kb = receiptFile.value.size / 1024
  return kb >= 1024 ? `${(kb / 1024).toFixed(1)} MB` : `${Math.round(kb)} KB`
})

const viewTx = ref<any>(null)
const viewDialogVisible = ref(false)
const editingTx = ref<any>(null)
const existingReceiptUrl = ref<string | null>(null)

const resolvedReceiptUrl = computed(() => viewTx.value?.receipt_image ? resolveMediaUrl(viewTx.value.receipt_image) : '')

const fuelFilterOptions = FUEL_TYPES.map((f) => ({ label: f, value: f }))

// ---- Receipt handlers ----
function setReceipt(file: File | null | undefined) {
  receiptError.value = ''
  if (!file) { receiptFile.value = null; return }
  if (!file.type.startsWith('image/')) {
    receiptError.value = 'Only image files are allowed (PNG, JPG, WebP).'
    return
  }
  receiptFile.value = file
}
function triggerFilePicker() { receiptError.value = ''; fileInputRef.value?.click() }
function onFilePicked(e: Event) {
  const input = e.target as HTMLInputElement
  setReceipt(input.files?.[0])
  input.value = ''
}
function onDragOver() { if (!isDragging.value) isDragging.value = true }
function onDragLeave() {
  dragCounter.value = Math.max(0, dragCounter.value - 1)
  if (dragCounter.value === 0) isDragging.value = false
}
function onDrop(e: DragEvent) {
  isDragging.value = false
  dragCounter.value = 0
  setReceipt(e.dataTransfer?.files?.[0])
}
function clearReceipt() { receiptFile.value = null; receiptError.value = '' }

function resetForm() {
  Object.assign(form, {
    vehicle: null, date: new Date().toISOString().slice(0, 16), fuel_type: 'Petrol',
    quantity: 0, unit: 'liters', total_cost: '0', odometer_reading: null,
    station_name: '', station_location: '', notes: '', fuel_card: null,
  })
  clearReceipt()
}

// ---- Google Places autocomplete ----
let autocompleteCleanup: any = null
watch(dialogVisible, async (visible) => {
  if (autocompleteCleanup) {
    if (typeof autocompleteCleanup.remove === 'function') autocompleteCleanup.remove()
    autocompleteCleanup = null
  }
  if (!visible) return
  let attempts = 0
  let nativeInput: HTMLInputElement | null = null
  while (attempts < 20) {
    await new Promise(r => setTimeout(r, 50))
    nativeInput = (stationLocationRef.value as any)?.$el?.querySelector?.('input')
    if (nativeInput) break
    attempts++
  }
  if (!nativeInput) return
  try {
    autocompleteCleanup = await attachAutocomplete(nativeInput, {
      onPlace: (place: any) => { form.station_location = place.formatted_address || form.station_location },
    })
  } catch (err) {
    console.warn('[Fuel] Google Places autocomplete not available:', err)
  }
})

// ---- Date filters ----
const datePreset = ref('30d')
const customFrom = ref('')
const customTo = ref('')
const customDateDialogVisible = ref(false)
const customDateError = ref('')

watch(() => props.datePresetModule, (mod: any) => {
  if (mod) datePreset.value = mod.value
}, { deep: true, immediate: true })

function dateRangeQuery() {
  const now = new Date()
  const todayEnd = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59)
  const params: Record<string, string> = {}
  switch (datePreset.value) {
    case 'today': {
      const start = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0)
      params.date__gte = start.toISOString()
      params.date__lte = todayEnd.toISOString()
      break
    }
    case 'yesterday': {
      const start = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1, 0, 0, 0)
      const end = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1, 23, 59, 59)
      params.date__gte = start.toISOString()
      params.date__lte = end.toISOString()
      break
    }
    case '7d': {
      const start = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
      params.date__gte = start.toISOString()
      break
    }
    case '30d': {
      const start = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000)
      params.date__gte = start.toISOString()
      break
    }
    case 'custom': {
      if (customFrom.value) params.date__gte = new Date(customFrom.value + 'T00:00:00').toISOString()
      if (customTo.value) params.date__lte = new Date(customTo.value + 'T23:59:59').toISOString()
      break
    }
    case 'all':
    default: break
  }
  return params
}

// ---- Transactions ----
const { data: txData, pending, refresh: refreshTx } = useAsyncData(
  'fuel-transactions-tab',
  () => fetchTransactions(dateRangeQuery()).catch(() => ({ results: [] })) as Promise<any>,
  { default: () => ({ results: [] }), watch: [datePreset] }
)
const transactions = computed(() => txData.value?.results || [])

function refreshTransactions() { refreshTx() }
function openCustomDate() { customDateDialogVisible.value = true }
function applyCustomDate() {
  customDateError.value = ''
  if (!customFrom.value && !customTo.value) { customDateError.value = 'Please select at least one date.'; return }
  if (customFrom.value && customTo.value && customFrom.value > customTo.value) { customDateError.value = '"From" cannot be after "To".'; return }
  customDateDialogVisible.value = false
  refreshTx()
}
function cancelCustomDate() {
  customDateDialogVisible.value = false
  customDateError.value = ''
  if (!customFrom.value && !customTo.value) datePreset.value = '30d'
}

const headers = [
  { title: '#', key: 'index', width: '50px', sortable: false },
  { title: 'Vehicle', key: 'vehicle_name', sortable: true },
  { title: 'Date', key: 'date', sortable: true, width: '170px' },
  { title: 'Fuel', key: 'fuel_type', sortable: true, width: '90px' },
  { title: 'Qty', key: 'quantity', sortable: true, width: '90px' },
  { title: 'Cost', key: 'total_cost', sortable: true, width: '100px' },
  { title: `${currencySymbol.value}/Unit`, key: 'price_per_unit', width: '90px' },
  { title: 'MPG', key: 'mpg', width: '70px' },
  { title: 'Station', key: 'station_name', width: '160px' },
  { title: '', key: 'receipt_image', width: '50px', sortable: false },
  { title: '', key: 'actions', width: '110px', sortable: false },
]

function openDialog() {
  editingTx.value = null
  existingReceiptUrl.value = null
  resetForm()
  dialogVisible.value = true
}
function editTransaction(tx: any) {
  editingTx.value = tx
  existingReceiptUrl.value = tx.receipt_image || null
  Object.assign(form, {
    vehicle: tx.vehicle, date: tx.date ? new Date(tx.date).toISOString().slice(0, 16) : new Date().toISOString().slice(0, 16),
    fuel_type: tx.fuel_type || 'Petrol', quantity: tx.quantity || 0, unit: tx.unit || 'liters',
    total_cost: tx.total_cost ? String(tx.total_cost) : '0', odometer_reading: tx.odometer_reading ?? null,
    station_name: tx.station_name || '', station_location: tx.station_location || '',
    notes: tx.notes || '', fuel_card: tx.fuel_card ?? null,
  })
  clearReceipt()
  dialogVisible.value = true
}
function viewTransaction(tx: any) { viewTx.value = tx; viewDialogVisible.value = true }

async function bulkDelete() {
  const result = await $swal.fire({
    icon: 'warning', title: `Delete ${selected.value.length} transactions?`,
    text: 'This action cannot be undone.', showCancelButton: true,
    confirmButtonText: 'Delete', confirmButtonColor: '#ef4444',
  })
  if (!result.isConfirmed) return
  for (const tx of selected.value) {
    try { await apiDeleteTransaction(tx.id) } catch {}
  }
  selected.value = []
  refreshTx()
  emit('refresh')
}

async function deleteTransaction(tx: any) {
  const result = await $swal.fire({
    icon: 'warning', title: 'Delete transaction?',
    text: `Delete fuel transaction for ${tx.vehicle_name} on ${formatFuelDate(tx.date).date}?`,
    showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444',
  })
  if (!result.isConfirmed) return
  try {
    await apiDeleteTransaction(tx.id)
    refreshTx()
    emit('refresh')
    $swal.fire({ icon: 'success', title: 'Deleted', timer: 2000 })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Delete failed', text: e?.data?.detail || 'Could not delete', timer: 3000 })
  }
}

async function save() { const ok = await _doSave(); if (ok) { dialogVisible.value = false; resetForm() } }
async function saveAndAddAnother() {
  const ok = await _doSave()
  if (ok) {
    resetForm()
    $swal.fire({ icon: 'success', title: 'Saved', text: 'Transaction saved. Add another below.', timer: 1500, toast: true, position: 'top-end' })
  }
}

async function _doSave(): Promise<boolean> {
  if (!form.vehicle) { $swal.fire({ icon: 'error', title: 'Vehicle required', timer: 3000 }); return false }
  if (!form.quantity || Number(form.quantity) <= 0) { $swal.fire({ icon: 'error', title: 'Quantity required', timer: 3000 }); return false }
  if (form.total_cost === '' || form.total_cost == null || Number(form.total_cost) <= 0) { $swal.fire({ icon: 'error', title: 'Total cost required', timer: 3000 }); return false }
  if (!form.station_location?.trim()) { $swal.fire({ icon: 'error', title: 'Station location required', timer: 3000 }); return false }
  if (!form.station_name?.trim()) { $swal.fire({ icon: 'error', title: 'Station required', timer: 3000 }); return false }
  if (!receiptFile.value && !existingReceiptUrl.value) { receiptError.value = 'A receipt image is required.'; $swal.fire({ icon: 'error', title: 'Receipt required', timer: 3000 }); return false }
  saving.value = true
  try {
    const payload: any = { ...form }
    payload.date = new Date(payload.date).toISOString()
    const fd = new FormData()
    for (const [key, value] of Object.entries(payload)) {
      if (value === null || value === undefined || value === '') continue
      fd.append(key, String(value))
    }
    if (receiptFile.value) fd.append('receipt_image', receiptFile.value)
    const id = editingTx.value?.id
    await saveTransaction(fd, id)
    refreshTx()
    emit('refresh')
    return true
  } catch (e: any) {
    const detail = e?.data || e?.message || e
    const msg = typeof detail === 'object'
      ? Object.entries(detail).map(([k, v]) => `${k.replace(/_/g, ' ')}: ${Array.isArray(v) ? v.join(', ') : v}`).join('\n')
      : String(detail || 'Failed to save transaction')
    $swal.fire({ icon: 'error', title: 'Save failed', text: msg, timer: 4000 })
    return false
  } finally { saving.value = false }
}

// ---- Fraud alert actions ----
const noteDialogVisible = ref(false)
const noteDialogTitle = ref('')
const confirmLabel = ref('')
const statusNote = ref('')
const actionLoading = ref(false)
let pendingAction: (() => Promise<void>) | null = null

function openNoteDialog(title: string, label: string, action: () => Promise<void>) {
  noteDialogTitle.value = title
  confirmLabel.value = label
  statusNote.value = ''
  pendingAction = action
  noteDialogVisible.value = true
}
async function confirmAction() {
  if (!pendingAction) return
  actionLoading.value = true
  try { await pendingAction(); noteDialogVisible.value = false } finally { actionLoading.value = false }
}
</script>

<style scoped>
.cursor-pointer { cursor: pointer; transition: filter 0.15s ease; }
.cursor-pointer:hover { filter: brightness(0.96); }
.fuel-dropzone { background: #f8fafc; transition: background-color 0.15s ease, border-color 0.15s ease; }
.fuel-dropzone:hover { background: #f1f5f9; border-color: var(--v-theme-primary) !important; }
.fuel-dropzone--active { background: #eff6ff !important; border-color: var(--v-theme-primary) !important; }
</style>
