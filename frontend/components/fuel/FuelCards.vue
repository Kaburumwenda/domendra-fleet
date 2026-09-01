<template>
  <div class="d-flex flex-column ga-4">
    <!-- Header -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-2">
      <div class="d-flex align-center ga-2">
        <v-btn color="primary" variant="tonal" size="small" prepend-icon="mdi-sync" :loading="syncingAll" @click="syncAll">Sync All Cards</v-btn>
        <v-chip size="small" variant="tonal" color="success">{{ activeCount }} active</v-chip>
        <v-chip size="small" variant="tonal" color="grey">{{ inactiveCount }} inactive</v-chip>
      </div>
      <v-btn v-can="'fuel:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="openDialog()">Add Card</v-btn>
    </div>

    <!-- Cards Grid -->
    <v-row dense>
      <v-col cols="12" md="6" lg="4" v-for="card in cards" :key="card.id">
        <v-card elevation="0" border class="pa-5 h-100 position-relative overflow-hidden" :class="{ 'border-success': card.is_active, 'border-grey': !card.is_active }">
          <div class="d-flex align-center justify-space-between mb-3">
            <v-chip :color="card.provider_color || 'primary'" variant="flat" size="small">{{ card.provider }}</v-chip>
            <v-chip :color="card.is_active ? 'success' : 'grey'" variant="tonal" size="x-small">{{ card.is_active ? 'Active' : 'Inactive' }}</v-chip>
          </div>
          <div class="d-flex align-center ga-2 mb-3">
            <v-icon color="primary" size="large">mdi-credit-card-chip-outline</v-icon>
            <p class="text-h6 font-weight-bold tracking-widest" style="letter-spacing: 2px">{{ maskCard(card.card_number) }}</p>
          </div>
          <div class="text-caption text-medium-emphasis mb-1">{{ card.card_holder_name || '—' }}</div>
          <v-divider class="my-3" />
          <div class="d-flex align-center justify-space-between">
            <div>
              <p v-if="card.vehicle_name" class="text-caption text-medium-emphasis">{{ card.vehicle_name }}</p>
              <p v-else class="text-caption text-medium-emphasis">No vehicle linked</p>
              <p v-if="card.expiry_date" class="text-caption text-medium-emphasis">Exp: {{ formatDate(card.expiry_date) }}</p>
            </div>
            <div class="d-flex ga-1">
              <v-btn v-if="card.provider_account_id" icon="mdi-sync" size="x-small" variant="text" color="info" title="Sync" :loading="syncingId === card.id" @click="syncCard(card)" />
              <v-btn v-can="'fuel:update'" icon="mdi-pencil-outline" size="x-small" variant="text" color="warning" title="Edit" @click="editCard(card)" />
              <v-btn v-can="'fuel:delete'" icon="mdi-delete-outline" size="x-small" variant="text" color="error" title="Delete" @click="removeCard(card)" />
            </div>
          </div>
          <p v-if="card.last_synced_at" class="text-caption text-medium-emphasis mt-2">Last synced {{ formatFuelDate(card.last_synced_at).date }}</p>
        </v-card>
      </v-col>
      <v-col v-if="!cards.length && !pending" cols="12">
        <v-card elevation="0" border class="pa-12 text-center text-medium-emphasis">
          <v-icon size="48" class="mb-3">mdi-credit-card-outline</v-icon>
          <p>No fuel cards yet. Add one to get started.</p>
        </v-card>
      </v-col>
    </v-row>

    <!-- Add/Edit Dialog -->
    <v-dialog v-model="dialogVisible" max-width="500" scroll-strategy="none">
      <v-card rounded="xl" class="overflow-hidden">
        <AppModalHeader icon="mdi-credit-card-outline">{{ editingCard ? 'Edit' : 'Add' }} Fuel Card</AppModalHeader>
        <v-card-text class="pt-5">
          <v-row dense>
            <v-col cols="12">
              <v-select v-model="form.provider" :items="CARD_PROVIDERS" item-title="label" item-value="value" label="Provider *" hide-details="auto" />
            </v-col>
            <v-col cols="12">
              <v-text-field v-model="form.card_number" label="Card Number *" prepend-inner-icon="mdi-credit-card-outline" hide-details="auto" />
            </v-col>
            <v-col cols="12">
              <v-text-field v-model="form.card_holder_name" label="Card Holder Name" prepend-inner-icon="mdi-account-outline" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="6">
              <v-select v-model="form.vehicle" :items="vehicleOptions" item-title="display_name" item-value="id" label="Linked Vehicle" clearable hide-details="auto" />
            </v-col>
            <v-col cols="12" md="6">
              <v-select v-model="form.driver" :items="driverOptions" item-title="display_name" item-value="id" label="Linked Driver" clearable hide-details="auto" />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="form.expiry_date" type="date" label="Expiry Date" prepend-inner-icon="mdi-calendar" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="form.provider_account_id" label="Provider Account ID" prepend-inner-icon="mdi-identifier" hide-details="auto" />
            </v-col>
            <v-col cols="12">
              <v-text-field v-model="form.api_key" label="API Key (encrypted)" type="password" prepend-inner-icon="mdi-key-outline" hide-details="auto" />
            </v-col>
            <v-col cols="12">
              <v-switch v-model="form.is_active" label="Active" color="success" hide-details="auto" density="compact" />
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="dialogVisible = false">Cancel</v-btn>
          <v-btn color="primary" prepend-icon="mdi-check" @click="save" :loading="saving">Save</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
const { $swal } = useNuxtApp()
const { fetchCards, saveCard, deleteCard, syncCard: apiSyncCard, syncAllCards } = useFuelApi()
const { CARD_PROVIDERS, maskCard, formatDate, formatFuelDate } = useFuelHelpers()

const props = defineProps<{
  vehicleOptions: any[]
  driverOptions: any[]
}>()

const emit = defineEmits<{ refresh: [] }>()

const dialogVisible = ref(false)
const saving = ref(false)
const editingCard = ref<any>(null)
const syncingAll = ref(false)
const syncingId = ref<number | null>(null)

const form = reactive<any>({
  provider: 'other', card_number: '', card_holder_name: '',
  vehicle: null, driver: null, expiry_date: '', provider_account_id: '', api_key: '', is_active: true,
})

const { data: cardData, pending, refresh } = useAsyncData(
  'fuel-cards',
  () => fetchCards().catch(() => ({ results: [] })) as Promise<any>,
  { default: () => ({ results: [] }) }
)
const cards = computed(() => cardData.value?.results || [])
const activeCount = computed(() => cards.value.filter((c: any) => c.is_active).length)
const inactiveCount = computed(() => cards.value.filter((c: any) => !c.is_active).length)

function resetForm() {
  Object.assign(form, {
    provider: 'other', card_number: '', card_holder_name: '',
    vehicle: null, driver: null, expiry_date: '', provider_account_id: '', api_key: '', is_active: true,
  })
}
function openDialog() { editingCard.value = null; resetForm(); dialogVisible.value = true }
function editCard(card: any) {
  editingCard.value = card
  Object.assign(form, {
    provider: card.provider, card_number: card.card_number, card_holder_name: card.card_holder_name,
    vehicle: card.vehicle, driver: card.driver,
    expiry_date: card.expiry_date ? card.expiry_date.slice(0, 10) : '',
    provider_account_id: card.provider_account_id, api_key: '', is_active: card.is_active,
  })
  dialogVisible.value = true
}

async function save() {
  if (!form.card_number?.trim()) { $swal.fire({ icon: 'error', title: 'Card number required', timer: 3000 }); return }
  saving.value = true
  try {
    const payload = { ...form }
    if (!payload.expiry_date) delete payload.expiry_date
    if (!payload.api_key) delete payload.api_key
    await saveCard(payload, editingCard.value?.id)
    refresh()
    dialogVisible.value = false
    $swal.fire({ icon: 'success', title: 'Saved', timer: 1500 })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Save failed', text: e?.data?.detail || 'Could not save card', timer: 3000 })
  } finally { saving.value = false }
}

async function removeCard(card: any) {
  const result = await $swal.fire({ icon: 'warning', title: 'Delete card?', text: `Delete ${card.provider} card?`, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!result.isConfirmed) return
  try { await deleteCard(card.id); refresh() } catch {}
}

async function syncCard(card: any) {
  syncingId.value = card.id
  try {
    const res: any = await apiSyncCard(card.id)
    refresh(); emit('refresh')
    $swal.fire({ icon: 'success', title: 'Synced', text: res?.detail || 'Card synced successfully', timer: 2500 })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Sync failed', text: e?.data?.detail || 'Could not sync card', timer: 3000 })
  } finally { syncingId.value = null }
}

async function syncAll() {
  syncingAll.value = true
  try {
    const res: any = await syncAllCards()
    refresh(); emit('refresh')
    $swal.fire({ icon: 'success', title: 'Sync complete', text: `Processed ${Array.isArray(res) ? res.length : 0} card(s)`, timer: 2500 })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Sync failed', text: e?.data?.detail || 'Could not sync cards', timer: 3000 })
  } finally { syncingAll.value = false }
}
</script>
