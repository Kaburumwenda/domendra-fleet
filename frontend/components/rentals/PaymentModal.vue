<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="600" persistent>
    <v-card rounded="xl" class="pa-0" style="overflow: hidden;">
      <!-- Hero header -->
      <div class="pm-hero" style="background: linear-gradient(135deg, #059669 0%, #10b981 100%);">
        <div class="d-flex align-center justify-space-between pa-5">
          <div>
            <div class="d-flex align-center ga-2 mb-1">
              <v-icon size="20" color="white">mdi-cash-plus</v-icon>
              <span class="text-overline text-white" style="opacity: .9; letter-spacing: 0.1em;">Record Payment</span>
            </div>
            <h2 class="text-h6 font-weight-bold text-white mb-0">{{ activeAgreement?.agreement_no || '—' }}</h2>
            <p class="text-caption text-white mt-1" style="opacity: .85;">
              {{ activeAgreement?.customer_name || '—' }} · {{ activeAgreement?.vehicle_display || '—' }}
            </p>
          </div>
          <v-btn icon="mdi-close" size="small" variant="text" color="white" @click="$emit('update:modelValue', false)" />
        </div>
        <!-- Summary strip -->
        <div class="pm-summary-strip">
          <div class="pm-ss-item">
            <span class="pm-ss-label">Total</span>
            <span class="pm-ss-value">{{ currencySymbol }}{{ Number(activeAgreement?.total_amount || 0).toLocaleString() }}</span>
          </div>
          <div class="pm-ss-divider" />
          <div class="pm-ss-item">
            <span class="pm-ss-label">Paid</span>
            <span class="pm-ss-value">{{ currencySymbol }}{{ Number(activeAgreement?.amount_paid || 0).toLocaleString() }}</span>
          </div>
          <div class="pm-ss-divider" />
          <div class="pm-ss-item">
            <span class="pm-ss-label">Balance</span>
            <span class="pm-ss-value" :class="{ 'text-amber-lighten-4': balanceDue > 0 }">
              {{ currencySymbol }}{{ Number(balanceDue).toLocaleString() }}
            </span>
          </div>
        </div>
      </div>

      <v-card-text class="pa-5">
        <!-- Agreement selector (only when opened from Payments tab) -->
        <div v-if="showAgreementSelect" class="mb-4 pm-agreement-select">
          <p class="text-caption font-weight-bold text-uppercase text-medium-emphasis mb-2">Select Agreement *</p>
          <!-- Display selected or search trigger -->
          <div
            v-if="!agreementMenuOpen"
            class="pm-agreement-trigger"
            :class="{ 'pm-agreement-trigger--active': selectedAgreementId }"
            @click="openAgreementMenu"
          >
            <v-icon size="16" :color="selectedAgreementId ? 'white' : 'primary'">mdi-file-document</v-icon>
            <div class="pm-agreement-info">
              <div v-if="selectedAgreementId" class="text-body-2 font-weight-medium text-truncate">{{ selectedAgreementLabel.split(' — ')[0] }}</div>
              <div v-if="selectedAgreementId" class="text-caption text-truncate" style="opacity:.85;">{{ selectedAgreementLabel.split(' — ').slice(1).join(' — ') }}</div>
              <div v-else class="text-body-2 text-medium-emphasis">Search and select an agreement…</div>
            </div>
            <v-icon v-if="selectedAgreementId" size="16" color="white" class="ml-auto">mdi-check-circle</v-icon>
            <v-icon v-else size="20" class="ml-auto text-medium-emphasis">mdi-magnify</v-icon>
          </div>
          <!-- Search dropdown panel -->
          <div v-if="agreementMenuOpen" class="pm-agreement-panel">
            <div class="pm-agreement-input-wrap">
              <v-icon size="18" class="text-medium-emphasis">mdi-magnify</v-icon>
              <input
                v-model="agreementSearch"
                type="text"
                class="pm-agreement-search-input"
                placeholder="Search by agreement no, customer, vehicle…"
                @keydown.enter.prevent="filteredAgreementItems.length ? selectAgreement(filteredAgreementItems[0].value) : null"
              />
              <v-btn icon="mdi-close" size="x-small" variant="text" @click="closeAgreementMenu" />
            </div>
            <v-divider />
            <div class="pm-agreement-list">
              <div
                v-for="a in filteredAgreementItems"
                :key="a.value"
                class="pm-agreement-item"
                :class="{ 'pm-agreement-item--active': selectedAgreementId === a.value }"
                @click="selectAgreementAndClose(a.value)"
              >
                <v-icon size="16" :color="selectedAgreementId === a.value ? 'white' : 'primary'">mdi-file-document</v-icon>
                <div class="pm-agreement-info">
                  <div class="text-body-2 font-weight-medium">{{ a.title.split(' — ')[0] }}</div>
                  <div class="text-caption text-medium-emphasis">{{ a.title.split(' — ').slice(1).join(' — ') }}</div>
                </div>
                <v-icon v-if="selectedAgreementId === a.value" size="16" color="white">mdi-check-circle</v-icon>
              </div>
              <div v-if="!filteredAgreementItems.length" class="text-center text-caption text-medium-emphasis pa-4">
                No agreements found
              </div>
            </div>
          </div>
        </div>
        <!-- Existing payments -->
        <div v-if="existingPayments.length" class="mb-4">
          <p class="text-caption font-weight-bold text-uppercase text-medium-emphasis mb-2">Payment History</p>
          <div class="pm-history-list">
            <div v-for="p in existingPayments" :key="p.id" class="pm-history-item">
              <div class="d-flex align-center ga-2">
                <div class="pm-method-icon" :class="`pm-method-icon--${p.payment_method}`">
                  <v-icon size="16">{{ methodIcon(p.payment_method) }}</v-icon>
                </div>
                <div>
                  <div class="text-body-2 font-weight-medium">{{ currencySymbol }}{{ Number(p.amount).toLocaleString() }}</div>
                  <div class="text-caption text-medium-emphasis">
                    {{ methodLabel(p.payment_method) }}
                    <span v-if="p.reference"> · {{ p.reference }}</span>
                    · {{ formatDate(p.paid_at) }}
                  </div>
                </div>
              </div>
              <v-chip :color="payStatusColor(p.status)" size="x-small" variant="flat" class="text-capitalize">
                {{ p.status }}
              </v-chip>
            </div>
          </div>
        </div>

        <v-divider v-if="existingPayments.length" class="mb-4" />

        <!-- Payment form -->
        <p class="text-caption font-weight-bold text-uppercase text-medium-emphasis mb-3">New Payment</p>
        <v-row dense>
          <v-col cols="12" md="6">
            <v-text-field
              v-model="form.amount"
              type="number"
              label="Amount *"
              :prefix="currencySymbol"
              prepend-inner-icon="mdi-cash"
              density="compact"
              variant="outlined"
              hide-details="auto"
              :hint="`Max: ${currencySymbol}${balanceDue.toLocaleString()}`"
              persistent-hint
            />
          </v-col>
          <v-col cols="12" md="6">
            <v-text-field
              v-model="form.paid_at"
              type="datetime-local"
              label="Date & Time *"
              prepend-inner-icon="mdi-calendar-clock"
              density="compact"
              variant="outlined"
              hide-details="auto"
              :rules="[v => !!v || 'Date & time is required']"
            />
          </v-col>
          <v-col cols="12" md="6">
            <v-select
              v-model="form.payment_method"
              :items="methodOptions"
              label="Payment Method *"
              density="compact"
              variant="outlined"
              hide-details="auto"
              :rules="[v => !!v || 'Payment method is required']"
            />
          </v-col>
          <v-col cols="12" md="6">
            <v-text-field
              v-model="form.reference"
              label="Reference / M-Pesa Code"
              prepend-inner-icon="mdi-identifier"
              density="compact"
              variant="outlined"
              hide-details="auto"
              placeholder="e.g. QKV3X7K2B"
            />
          </v-col>
          <v-col cols="12" md="6">
            <v-select
              v-model="form.status"
              :items="statusOptions"
              label="Status *"
              density="compact"
              variant="outlined"
              hide-details="auto"
              :rules="[v => !!v || 'Status is required']"
            />
          </v-col>
          <v-col cols="12" md="6">
            <v-text-field
              :model-value="currentUser"
              label="Recorded By"
              prepend-inner-icon="mdi-account"
              density="compact"
              variant="outlined"
              hide-details="auto"
              disabled
            />
          </v-col>
          <v-col cols="12">
            <v-textarea
              v-model="form.notes"
              label="Notes"
              prepend-inner-icon="mdi-note-text"
              density="compact"
              variant="outlined"
              hide-details="auto"
              rows="2"
              auto-grow
            />
          </v-col>
        </v-row>

        <!-- Quick add buttons -->
        <div class="d-flex align-center ga-2 mt-3 flex-wrap">
          <v-btn size="x-small" variant="tonal" color="primary" @click="form.amount = balanceDue">Full Balance</v-btn>
          <v-btn size="x-small" variant="tonal" color="primary" @click="form.amount = Math.round(balanceDue / 2)">Half Balance</v-btn>
          <v-btn size="x-small" variant="tonal" color="primary" @click="form.amount = Math.round(balanceDue * 0.25)">25%</v-btn>
          <v-btn size="x-small" variant="tonal" color="primary" @click="form.amount = Math.round(balanceDue * 0.75)">75%</v-btn>
        </div>
      </v-card-text>

      <v-divider />
      <v-card-actions class="pa-4">
        <v-spacer />
        <v-btn variant="text" @click="$emit('update:modelValue', false)">Cancel</v-btn>
        <v-btn color="success" size="large" prepend-icon="mdi-check-circle" :loading="saving" @click="submit">
          Record Payment
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
const props = defineProps<{
  modelValue: boolean
  agreement: any
  agreements?: any[]
}>()
const emit = defineEmits<{ 'update:modelValue': [boolean]; saved: [] }>()

const { $api, $swal } = useNuxtApp()
const { currencySymbol } = useCurrency()
const authStore = useAuthStore()

const currentUser = computed(() => {
  if (authStore.user?.full_name) return authStore.user.full_name
  if (authStore.user?.email) return authStore.user.email
  // Fallback: read directly from localStorage in case store isn't initialized yet
  if (import.meta.client) {
    try {
      const userStr = localStorage.getItem('fc_user')
      const user = userStr ? JSON.parse(userStr) : null
      return user?.full_name || user?.email || 'Staff'
    } catch { return 'Staff' }
  }
  return 'Staff'
})

const saving = ref(false)
const existingPayments = ref<any[]>([])
const selectedAgreementId = ref<number | null>(null)
const agreementSearch = ref('')
const agreementMenuOpen = ref(false)
const showAgreementSelect = computed(() => !props.agreement && (props.agreements?.length || 0) > 0)

const activeAgreement = computed(() => {
  if (props.agreement) return props.agreement
  if (selectedAgreementId.value && props.agreements) {
    return props.agreements.find(a => a.id === selectedAgreementId.value) || null
  }
  return null
})

const agreementSelectItems = computed(() => {
  return (props.agreements || []).filter(a => a.status !== 'draft' && a.status !== 'cancelled').map(a => ({
    title: `${a.agreement_no} — ${a.customer_name || '—'} (Bal: ${currencySymbol.value}${Number(a.balance_due || 0).toLocaleString()})`,
    value: a.id,
  }))
})

const filteredAgreementItems = computed(() => {
  const q = agreementSearch.value.trim().toLowerCase()
  if (!q) return agreementSelectItems.value
  return agreementSelectItems.value.filter(a => a.title.toLowerCase().includes(q))
})

const selectedAgreementLabel = computed(() => {
  if (!selectedAgreementId.value) return ''
  const item = agreementSelectItems.value.find(a => a.value === selectedAgreementId.value)
  return item?.title || ''
})

function openAgreementMenu() {
  agreementMenuOpen.value = true
  agreementSearch.value = ''
  nextTick(() => {
    const input = document.querySelector('.pm-agreement-search-input') as HTMLInputElement | null
    input?.focus()
  })
}

function closeAgreementMenu() {
  agreementMenuOpen.value = false
  agreementSearch.value = ''
}

const balanceDue = computed(() => {
  const total = Number(activeAgreement.value?.total_amount || 0)
  const paid = Number(activeAgreement.value?.amount_paid || 0)
  return Math.max(0, total - paid)
})

const form = reactive({
  amount: 0,
  payment_method: 'mpesa',
  reference: '',
  status: 'completed',
  paid_at: new Date().toISOString().slice(0, 16),
  notes: '',
})

const methodOptions = [
  { title: 'M-Pesa', value: 'mpesa' },
  { title: 'Cash', value: 'cash' },
  { title: 'Card', value: 'card' },
  { title: 'Bank Transfer', value: 'bank_transfer' },
  { title: 'Cheque', value: 'cheque' },
  { title: 'Other', value: 'other' },
]

const statusOptions = [
  { title: 'Completed', value: 'completed' },
  { title: 'Pending', value: 'pending' },
  { title: 'Failed', value: 'failed' },
  { title: 'Refunded', value: 'refunded' },
]

function methodIcon(m: string) {
  const map: Record<string, string> = {
    mpesa: 'mdi-cellphone',
    cash: 'mdi-cash',
    card: 'mdi-credit-card',
    bank_transfer: 'mdi-bank',
    cheque: 'mdi-checkbook',
    other: 'mdi-swap-horizontal',
  }
  return map[m] || 'mdi-cash'
}

function methodLabel(m: string) {
  return methodOptions.find(o => o.value === m)?.title || m
}

function payStatusColor(s: string) {
  const map: Record<string, string> = {
    completed: 'success',
    pending: 'warning',
    failed: 'error',
    refunded: 'info',
  }
  return map[s] || 'default'
}

function formatDate(d: any) {
  if (!d) return '—'
  return String(d).slice(0, 16).replace('T', ' ')
}

async function loadPayments() {
  if (!activeAgreement.value?.id) { existingPayments.value = []; return }
  try {
    const res = await $api(`/rentals/payments/?agreement=${activeAgreement.value.id}`)
    existingPayments.value = res
  } catch {
    existingPayments.value = []
  }
}

async function selectAgreement(id: number) {
  selectedAgreementId.value = id
  await onAgreementSelected()
}

async function selectAgreementAndClose(id: number) {
  await selectAgreement(id)
  closeAgreementMenu()
}

async function onAgreementSelected() {
  if (!showAgreementSelect.value) return
  // Fetch full agreement to get amount_paid, balance due, etc.
  if (selectedAgreementId.value) {
    try {
      const full = await $api(`/rentals/agreements/${selectedAgreementId.value}/`)
      // Update the object in the agreements array so activeAgreement computed picks it up
      if (props.agreements) {
        const idx = props.agreements.findIndex(a => a.id === selectedAgreementId.value)
        if (idx >= 0) Object.assign(props.agreements[idx], full)
      }
      form.amount = balanceDue.value
      await loadPayments()
    } catch { /* ignore */ }
  }
}

watch(() => props.modelValue, async (v) => {
  if (v) {
    selectedAgreementId.value = props.agreement?.id || null
    agreementMenuOpen.value = false
    agreementSearch.value = ''
    form.amount = balanceDue.value
    form.paid_at = new Date().toISOString().slice(0, 16)
    form.reference = ''
    form.notes = ''
    form.status = 'completed'
    form.payment_method = 'mpesa'
    if (activeAgreement.value?.id || selectedAgreementId.value) await loadPayments()
  }
})

async function submit() {
  const amt = Number(form.amount)
  if (!amt || amt <= 0) {
    $swal.fire({ icon: 'warning', title: 'Enter payment amount', toast: true, timer: 1800, position: 'top-end' })
    return
  }

  saving.value = true
  try {
    if (!activeAgreement.value?.id) {
      $swal.fire({ icon: 'warning', title: 'Select an agreement first', toast: true, timer: 1800, position: 'top-end' })
      saving.value = false
      return
    }
    await $api('/rentals/payments/', {
      method: 'POST',
      body: {
        agreement: activeAgreement.value.id,
        amount: amt,
        payment_method: form.payment_method,
        reference: form.reference,
        status: form.status,
        paid_at: form.paid_at ? new Date(form.paid_at).toISOString() : undefined,
        notes: form.notes,
        recorded_by: currentUser.value,
      },
    })
    // Refresh agreement to get updated payment summary
    const updated = await $api(`/rentals/agreements/${activeAgreement.value.id}/`)
    if (props.agreements) {
      const idx = props.agreements.findIndex(a => a.id === activeAgreement.value!.id)
      if (idx >= 0) Object.assign(props.agreements[idx], updated)
    }
    if (props.agreement) Object.assign(props.agreement, updated)
    await loadPayments()
    $swal.fire({ icon: 'success', title: 'Payment recorded', toast: true, timer: 1500, position: 'top-end' })
    emit('saved')
    if (balanceDue.value <= 0) {
      emit('update:modelValue', false)
    } else {
      form.amount = balanceDue.value
    }
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Failed to record payment', text: e?.data?.detail || '', toast: true, timer: 2500, position: 'top-end' })
  } finally {
    saving.value = false
  }
}
</script>

<style scoped>
.pm-hero {
  padding: 0;
}
.pm-summary-strip {
  display: flex;
  align-items: stretch;
  background: rgba(0, 0, 0, 0.15);
  padding: 12px 20px;
  gap: 0;
}
.pm-ss-item {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}
.pm-ss-label {
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: rgba(255, 255, 255, 0.7);
  font-weight: 600;
}
.pm-ss-value {
  font-size: 16px;
  font-weight: 700;
  color: #fff;
}
.pm-ss-divider {
  width: 1px;
  background: rgba(255, 255, 255, 0.2);
  margin: 0 8px;
}
.pm-history-list {
  max-height: 160px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.pm-history-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 12px;
  border-radius: 8px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
}
.pm-method-icon {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #eef2ff;
  color: #4f46e5;
  flex-shrink: 0;
}
.pm-method-icon--mpesa { background: #ecfdf5; color: #059669; }
.pm-method-icon--cash { background: #fefce8; color: #ca8a04; }
.pm-method-icon--card { background: #eff6ff; color: #2563eb; }
.pm-method-icon--bank_transfer { background: #f8fafc; color: #475569; }
.pm-method-icon--cheque { background: #fdf2f8; color: #db2777; }
.pm-method-icon--other { background: #f1f5f9; color: #64748b; }

.pm-agreement-select {
  position: relative;
}
.pm-agreement-trigger {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 14px;
  border: 1.5px solid #e2e8f0;
  border-radius: 10px;
  cursor: pointer;
  transition: all .15s ease;
  background: #f8fafc;
}
.pm-agreement-trigger:hover {
  border-color: #94a3b8;
  background: #f1f5f9;
}
.pm-agreement-trigger--active {
  background: linear-gradient(135deg, #059669, #10b981);
  border-color: #059669;
}
.pm-agreement-trigger--active:hover {
  background: linear-gradient(135deg, #059669, #10b981);
  border-color: #059669;
}
.pm-agreement-trigger--active .pm-agreement-info .text-body-2,
.pm-agreement-trigger--active .pm-agreement-info .text-caption {
  color: white !important;
  opacity: .95;
}
.pm-agreement-trigger--active .text-medium-emphasis {
  color: rgba(255,255,255,.85) !important;
}
.pm-agreement-panel {
  position: relative;
  z-index: 100;
  border: 1.5px solid #10b981;
  border-radius: 10px;
  background: white;
  box-shadow: 0 10px 25px -5px rgba(0,0,0,.15);
  overflow: hidden;
}
.pm-agreement-input-wrap {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 10px;
  background: #f0fdf4;
}
.pm-agreement-search-input {
  flex: 1;
  border: none;
  outline: none;
  font-size: 14px;
  background: transparent;
  color: #1e293b;
}
.pm-agreement-search-input::placeholder {
  color: #94a3b8;
}
.pm-agreement-list {
  max-height: 200px;
  overflow-y: auto;
  padding: 4px;
}
.pm-agreement-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  border-radius: 8px;
  cursor: pointer;
  transition: all .15s ease;
  border: 1px solid transparent;
}
.pm-agreement-item:hover {
  background: #f0f9ff;
  border-color: #bae6fd;
}
.pm-agreement-item--active {
  background: linear-gradient(135deg, #059669, #10b981);
  border-color: #059669;
}
.pm-agreement-item--active:hover {
  background: linear-gradient(135deg, #059669, #10b981);
  border-color: #059669;
}
.pm-agreement-item--active .pm-agreement-info .text-body-2,
.pm-agreement-item--active .pm-agreement-info .text-caption {
  color: white !important;
  opacity: .95;
}
.pm-agreement-info {
  flex: 1;
  min-width: 0;
}
</style>
