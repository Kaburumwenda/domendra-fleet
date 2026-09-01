<template>
  <div class="d-flex flex-column ga-4">
    <!-- Page header -->
    <div class="page-header">
      <div>
        <h1 class="text-h5 font-weight-bold d-flex align-center ga-2">
          <v-icon color="primary">mdi-package-variant-closed</v-icon>
          Parts &amp; Inventory
        </h1>
        <p class="text-caption text-medium-emphasis">Track parts, manage stock levels across locations, process purchase orders, and keep your fleet well-stocked.</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn variant="outlined" prepend-icon="mdi-refresh" @click="reloadAll" :loading="pending">Refresh</v-btn>
        <v-btn variant="tonal" color="deep-purple" prepend-icon="mdi-database-plus" @click="seedDemo" :loading="seeding">
          <span class="hidden-sm-and-down">Seed Demo Data</span>
        </v-btn>
        <v-btn v-can="'inventory:create'" color="primary" prepend-icon="mdi-plus" @click="openCreateItem">
          <span class="hidden-sm-and-down">Add Part</span>
        </v-btn>
      </div>
    </div>

    <!-- Analytics -->
    <InventoryAnalytics :stats="invStats" @filter-tab="setTab" />

    <!-- Filters bar -->
    <div class="d-flex flex-wrap align-center ga-2 filter-bar">
      <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Search parts…" density="compact" hide-details variant="outlined" style="max-width:260px" clearable />
      <v-autocomplete v-model="locFilter" :items="locationOptions" item-title="name" item-value="id" placeholder="All Locations" density="compact" hide-details variant="outlined" clearable style="max-width:180px" />
      <v-select v-model="catFilter" :items="categoryOptions" placeholder="All Categories" density="compact" hide-details variant="outlined" clearable style="max-width:160px" />
      <v-checkbox v-if="tab !== 'locations' && tab !== 'orders'" v-model="lowStockOnly" label="Low stock only" density="compact" hide-details color="error" />
      <v-btn v-if="hasFilters" variant="text" size="small" prepend-icon="mdi-filter-remove" @click="clearFilters">Clear</v-btn>
      <v-spacer />
      <div class="text-caption text-medium-emphasis">{{ tabCount }}</div>
      <v-btn v-can="'inventory:create'" v-if="tab === 'orders'" variant="outlined" prepend-icon="mdi-plus" size="small" @click="openCreatePO">New Purchase Order</v-btn>
      <v-btn v-can="'inventory:create'" v-if="tab === 'locations'" variant="outlined" prepend-icon="mdi-plus" size="small" @click="openCreateLocation">Add Location</v-btn>
    </div>

    <!-- Tabs -->
    <v-tabs v-model="tab" color="primary" density="compact" class="inv-tabs">
      <v-tab value="items" prepend-icon="mdi-package-variant">Parts</v-tab>
      <v-tab value="orders" prepend-icon="mdi-clipboard-text-outline">Purchase Orders</v-tab>
      <v-tab value="locations" prepend-icon="mdi-warehouse">Locations</v-tab>
      <v-tab value="transactions" prepend-icon="mdi-swap-horizontal">Stock Movements</v-tab>
    </v-tabs>

    <v-window v-model="tab" class="flex-grow-1">
      <!-- PARTS TAB -->
      <v-window-item value="items">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="itemHeaders" :items="filteredItems" :loading="itemsPending" density="compact" hover :search="search">
            <template #item.sku="{ value }"><span class="font-weight-medium">{{ value }}</span></template>
            <template #item.name="{ value }"><span class="font-weight-medium">{{ value }}</span></template>
            <template #item.category="{ value }">
              <v-chip v-if="value" size="x-small" variant="tonal" color="primary">{{ value }}</v-chip>
              <span v-else class="text-medium-emphasis">—</span>
            </template>
            <template #item.quantity_on_hand="{ item }">
              <div class="d-flex align-center ga-1">
                <span :class="item.needs_reorder ? 'text-error font-weight-bold' : 'font-weight-medium'">{{ item.quantity_on_hand }}</span>
                <v-icon v-if="item.needs_reorder" color="error" size="14">mdi-alert</v-icon>
              </div>
            </template>
            <template #item.reorder_point="{ value }">{{ value || 0 }}</template>
            <template #item.unit_cost="{ value }">{{ fmtCur(value) }}</template>
            <template #item.total_value="{ value }">{{ fmtCur(value) }}</template>
            <template #item.is_active="{ value }">
              <v-icon :color="value ? 'success' : 'grey'" size="small">{{ value ? 'mdi-check-circle' : 'mdi-close-circle' }}</v-icon>
            </template>
            <template #item.actions="{ item }">
              <v-menu>
                <template #activator="{ props: p }">
                  <v-btn icon="mdi-dots-vertical" variant="text" size="small" v-bind="p" />
                </template>
                <v-list density="compact">
                  <v-list-item prepend-icon="mdi-swap-horizontal" @click="openStockAdj(item)">Stock Adjustment</v-list-item>
                  <v-list-item v-can="'inventory:update'" prepend-icon="mdi-pencil" @click="openEditItem(item)">Edit</v-list-item>
                  <v-list-item v-can="'inventory:delete'" prepend-icon="mdi-trash-can-outline" base-color="error" @click="deleteItem(item)">Delete</v-list-item>
                </v-list>
              </v-menu>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-package-variant-closed</v-icon>
                <p>No parts yet. Click <b>Seed Demo Data</b> or <b>Add Part</b> to get started.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>

      <!-- PURCHASE ORDERS TAB -->
      <v-window-item value="orders">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="poHeaders" :items="filteredPOs" :loading="poPending" density="compact" hover :search="search" @click:row="(_: any, r: any) => openPODetail(r.item)">
            <template #item.id="{ value }"><span class="font-weight-medium text-primary cursor-pointer">#{{ value }}</span></template>
            <template #item.vendor_name="{ value }"><span class="font-weight-medium">{{ value || '—' }}</span></template>
            <template #item.status="{ value }">
              <v-chip :color="poStatusColor(value)" variant="flat" size="small" class="text-capitalize">
                <v-icon start size="14">{{ poStatusIcon(value) }}</v-icon>{{ value.replace('_',' ') }}
              </v-chip>
            </template>
            <template #item.total_cost="{ value }"><span class="font-weight-medium">{{ fmtCur(value) }}</span></template>
            <template #item.created_at="{ value }">{{ fmtDate(value) }}</template>
            <template #item.actions="{ item }">
              <v-menu>
                <template #activator="{ props: p }">
                  <v-btn icon="mdi-dots-vertical" variant="text" size="small" v-bind="p" @click.stop />
                </template>
                <v-list density="compact">
                  <v-list-item prepend-icon="mdi-eye-outline" @click="openPODetail(item)">View Details</v-list-item>
                  <v-list-item prepend-icon="mdi-send" @click="submitPO(item)" v-if="item.status === 'draft'">Submit</v-list-item>
                  <v-list-item prepend-icon="mdi-cancel" base-color="error" @click="cancelPO(item)" v-if="item.status !== 'cancelled' && item.status !== 'received'">Cancel PO</v-list-item>
                  <v-list-item v-can="'inventory:update'" prepend-icon="mdi-pencil" @click="openEditPO(item)">Edit</v-list-item>
                  <v-list-item v-can="'inventory:delete'" prepend-icon="mdi-trash-can-outline" base-color="error" @click="deletePO(item)">Delete</v-list-item>
                </v-list>
              </v-menu>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-clipboard-text-outline</v-icon>
                <p>No purchase orders yet. Click <b>New Purchase Order</b> to get started.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>

      <!-- LOCATIONS TAB -->
      <v-window-item value="locations">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="locHeaders" :items="filteredLocations" :loading="locPending" density="compact" hover :search="search">
            <template #item.name="{ value }"><span class="font-weight-medium">{{ value }}</span></template>
            <template #item.is_active="{ value }">
              <v-icon :color="value ? 'success' : 'grey'" size="small">{{ value ? 'mdi-check-circle' : 'mdi-close-circle' }}</v-icon>
            </template>
            <template #item.item_count="{ value }"><v-chip size="small" variant="tonal" color="primary">{{ value || 0 }}</v-chip></template>
            <template #item.actions="{ item }">
              <v-menu>
                <template #activator="{ props: p }">
                  <v-btn icon="mdi-dots-vertical" variant="text" size="small" v-bind="p" />
                </template>
                <v-list density="compact">
                  <v-list-item v-can="'inventory:update'" prepend-icon="mdi-pencil" @click="openEditLocation(item)">Edit</v-list-item>
                  <v-list-item v-can="'inventory:delete'" prepend-icon="mdi-trash-can-outline" base-color="error" @click="deleteLocation(item)">Delete</v-list-item>
                </v-list>
              </v-menu>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-warehouse</v-icon>
                <p>No locations yet. Click <b>Add Location</b> to get started.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>

      <!-- STOCK MOVEMENTS TAB -->
      <v-window-item value="transactions">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="txnHeaders" :items="filteredTxns" :loading="txnPending" density="compact" hover :search="search">
            <template #item.transaction_type="{ value }">
              <v-chip :color="txnColor(value)" variant="tonal" size="x-small" class="text-capitalize">
                <v-icon start size="12">{{ txnIcon(value) }}</v-icon>{{ value }}
              </v-chip>
            </template>
            <template #item.quantity="{ value }">
              <span :class="value >= 0 ? 'text-success font-weight-medium' : 'text-error font-weight-medium'">{{ value >= 0 ? '+' : '' }}{{ value }}</span>
            </template>
            <template #item.unit_cost="{ value }">{{ value ? fmtCur(value) : '—' }}</template>
            <template #item.created_at="{ value }">{{ fmtDateTime(value) }}</template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-swap-horizontal</v-icon>
                <p>No stock movements yet. Use <b>Stock Adjustment</b> on a part to record one.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>
    </v-window>

    <!-- Item Form Dialog -->
    <ItemFormDialog
      ref="itemFormRef"
      v-model="itemDialog"
      :editing="editingItem"
      :saving="saving"
      :location-options="locationOptions"
      @save="saveItem"
    />

    <!-- Stock Adjustment Dialog -->
    <StockAdjustDialog
      ref="stockFormRef"
      v-model="stockDialog"
      :saving="saving"
      :item="stockItem"
      @save="saveStockAdj"
    />

    <!-- Purchase Order Form Dialog -->
    <PurchaseOrderFormDialog
      ref="poFormRef"
      v-model="poDialog"
      :editing="editingPO"
      :saving="saving"
      :vendor-options="vendorOptions"
      :location-options="locationOptions"
      :item-options="itemOptions"
      @save="savePO"
    />

    <!-- Location Dialog (inline) -->
    <v-dialog v-model="locDialog" max-width="480">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-warehouse">{{ editingLoc ? 'Edit Location' : 'Add Location' }}</AppModalHeader>
        <v-card-text>
          <v-text-field v-model="locForm.name" label="Name *" density="compact" variant="outlined" class="mb-2" />
          <v-textarea v-model="locForm.address" label="Address" rows="2" density="compact" variant="outlined" class="mb-2" />
          <v-textarea v-model="locForm.description" label="Description" rows="2" density="compact" variant="outlined" class="mb-2" />
          <v-switch v-model="locForm.is_active" label="Active" color="primary" density="compact" hide-details inset />
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="locDialog = false">Cancel</v-btn>
          <v-btn color="primary" @click="saveLocation" :loading="saving">{{ editingLoc ? 'Update' : 'Create' }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Purchase Order Detail Drawer -->
    <PurchaseOrderDetailDrawer
      v-model="poDrawer"
      :po="selectedPO"
      :saving="saving"
      @submit="submitPO"
      @cancel="cancelPO"
      @delete="deletePO"
      @receive="receivePO"
    />
  </div>
</template>

<script setup lang="ts">
import InventoryAnalytics from '~/components/inventory/InventoryAnalytics.vue'
import ItemFormDialog from '~/components/inventory/ItemFormDialog.vue'
import StockAdjustDialog from '~/components/inventory/StockAdjustDialog.vue'
import PurchaseOrderFormDialog from '~/components/inventory/PurchaseOrderFormDialog.vue'
import PurchaseOrderDetailDrawer from '~/components/inventory/PurchaseOrderDetailDrawer.vue'

definePageMeta({ layout: 'default' })
const { $api, $swal } = useNuxtApp() as any
const { currencySymbol } = useCurrency()

/* ─── state ─── */
const tab = ref<'items' | 'orders' | 'locations' | 'transactions'>('items')
const search = ref('')
const locFilter = ref<number | null>(null)
const catFilter = ref<string | null>(null)
const lowStockOnly = ref(false)
const saving = ref(false)
const seeding = ref(false)
const itemDialog = ref(false)
const stockDialog = ref(false)
const poDialog = ref(false)
const poDrawer = ref(false)
const locDialog = ref(false)
const editingItem = ref(false)
const editingPO = ref(false)
const editingLoc = ref(false)
const itemFormRef = ref<any>(null)
const stockFormRef = ref<any>(null)
const poFormRef = ref<any>(null)
const stockItem = ref<any>(null)
const selectedPO = ref<any>(null)
const locForm = reactive<any>({ _id: null, name: '', address: '', description: '', is_active: true })

/* ─── headers ─── */
const itemHeaders = [
  { title: 'SKU', key: 'sku', width: '110px', sortable: true },
  { title: 'Name', key: 'name', sortable: true },
  { title: 'Category', key: 'category', width: '120px', sortable: true },
  { title: 'On Hand', key: 'quantity_on_hand', width: '90px', sortable: true },
  { title: 'Reorder', key: 'reorder_point', width: '80px' },
  { title: 'Unit Cost', key: 'unit_cost', width: '100px', sortable: true },
  { title: 'Total Value', key: 'total_value', width: '110px', sortable: true },
  { title: 'Location', key: 'location_name', width: '120px' },
  { title: 'Active', key: 'is_active', width: '60px' },
  { title: '', key: 'actions', width: '50px', sortable: false },
]
const poHeaders = [
  { title: 'PO #', key: 'id', width: '70px', sortable: true },
  { title: 'Vendor', key: 'vendor_name', sortable: true },
  { title: 'Status', key: 'status', width: '130px', sortable: true },
  { title: 'Total', key: 'total_cost', width: '120px', sortable: true },
  { title: 'Created', key: 'created_at', width: '110px', sortable: true },
  { title: '', key: 'actions', width: '50px', sortable: false },
]
const locHeaders = [
  { title: 'Name', key: 'name', sortable: true },
  { title: 'Address', key: 'address' },
  { title: 'Items', key: 'item_count', width: '80px' },
  { title: 'Active', key: 'is_active', width: '60px' },
  { title: '', key: 'actions', width: '50px', sortable: false },
]
const txnHeaders = [
  { title: 'Type', key: 'transaction_type', width: '100px', sortable: true },
  { title: 'Item', key: 'item_name', sortable: true },
  { title: 'SKU', key: 'item_sku', width: '110px' },
  { title: 'Qty', key: 'quantity', width: '80px', sortable: true },
  { title: 'Unit Cost', key: 'unit_cost', width: '100px' },
  { title: 'Reference', key: 'reference' },
  { title: 'Date', key: 'created_at', width: '140px', sortable: true },
]

/* ─── data ─── */
const { data: itemData, pending: itemsPending, refresh: refreshItems } = useAsyncData('inv-items', () => $api('/inventory/items/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const items = computed(() => itemData.value?.results || [])

const { data: locData, pending: locPending, refresh: refreshLocs } = useAsyncData('inv-locs', () => $api('/inventory/locations/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const locationOptions = computed(() => locData.value?.results || [])
const filteredLocations = computed(() => locationOptions.value)

const { data: poData, pending: poPending, refresh: refreshPOs } = useAsyncData('inv-pos', () => $api('/inventory/purchase-orders/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const purchaseOrders = computed(() => poData.value?.results || [])

const { data: txnData, pending: txnPending, refresh: refreshTxns } = useAsyncData('inv-txns', () => $api('/inventory/transactions/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const transactions = computed(() => txnData.value?.results || [])

const { data: statsData, refresh: refreshStats } = useAsyncData('inv-stats', () => $api('/inventory/items/stats/').catch(() => ({})), { default: () => ({}) })
const invStats = computed(() => statsData.value || {})

const { data: vendorData } = useAsyncData('inv-vendors', () => $api('/contacts/', { query: { page_size: 1000, contact_type: 'vendor' } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const vendorOptions = computed(() => vendorData.value?.results || [])
const itemOptions = computed(() => items.value.filter(i => i.is_active))

const pending = computed(() => itemsPending.value || poPending.value || locPending.value || txnPending.value)

/* ─── filters ─── */
const categoryOptions = computed(() => { const s = new Set<string>(); items.value.forEach(i => { if (i.category) s.add(i.category) }); return [...s].sort() })

const filteredItems = computed(() => {
  let arr = items.value
  if (locFilter.value) arr = arr.filter(i => i.location === locFilter.value)
  if (catFilter.value) arr = arr.filter(i => i.category === catFilter.value)
  if (lowStockOnly.value) arr = arr.filter(i => i.needs_reorder)
  if (search.value) { const q = search.value.toLowerCase(); arr = arr.filter(i => (i.sku || '').toLowerCase().includes(q) || (i.name || '').toLowerCase().includes(q) || (i.barcode || '').toLowerCase().includes(q) || (i.category || '').toLowerCase().includes(q)) }
  return arr
})
const filteredPOs = computed(() => {
  let arr = purchaseOrders.value
  if (search.value) { const q = search.value.toLowerCase(); arr = arr.filter(p => (p.vendor_name || '').toLowerCase().includes(q) || String(p.id).includes(q)) }
  return arr
})
const filteredTxns = computed(() => {
  let arr = transactions.value
  if (search.value) { const q = search.value.toLowerCase(); arr = arr.filter(t => (t.item_name || '').toLowerCase().includes(q) || (t.item_sku || '').toLowerCase().includes(q) || (t.reference || '').toLowerCase().includes(q)) }
  return arr
})

const hasFilters = computed(() => !!(search.value || locFilter.value || catFilter.value || lowStockOnly.value))
function clearFilters() { search.value = ''; locFilter.value = null; catFilter.value = null; lowStockOnly.value = false }

const tabCount = computed(() => {
  if (tab.value === 'items') return `${filteredItems.value.length} of ${items.value.length} parts`
  if (tab.value === 'orders') return `${filteredPOs.value.length} purchase orders`
  if (tab.value === 'locations') return `${locationOptions.value.length} locations`
  return `${filteredTxns.value.length} stock movements`
})
function setTab(t: string) { tab.value = t as any }

/* ─── helpers ─── */
function poStatusColor(s: string) { return ({ draft: 'grey', submitted: 'primary', partially_received: 'warning', received: 'success', cancelled: 'error' } as any)[s] || 'grey' }
function poStatusIcon(s: string) { return ({ draft: 'mdi-pencil-outline', submitted: 'mdi-send', partially_received: 'mdi-progress-clock', received: 'mdi-check-circle', cancelled: 'mdi-close-circle' } as any)[s] || 'mdi-circle-outline' }
function txnColor(t: string) { return ({ in: 'success', out: 'error', adjust: 'warning', transfer: 'info' } as any)[t] || 'grey' }
function txnIcon(t: string) { return ({ in: 'mdi-arrow-down', out: 'mdi-arrow-up', adjust: 'mdi-pencil', transfer: 'mdi-swap-horizontal' } as any)[t] || 'mdi-circle-outline' }
function fmtCur(v?: number) { return v != null ? `${currencySymbol.value}${parseFloat(v).toLocaleString([], { minimumFractionDigits: 2, maximumFractionDigits: 2 })}` : `${currencySymbol.value}0.00` }
function fmtDate(v?: string) { return v ? new Date(v).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' }) : '—' }
function fmtDateTime(v?: string) { return v ? new Date(v).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : '—' }

/* ─── reload all ─── */
async function reloadAll() { await Promise.all([refreshItems(), refreshPOs(), refreshLocs(), refreshTxns(), refreshStats()]) }

/* ─── seed demo ─── */
async function seedDemo() {
  const r = await $swal?.fire?.({ icon: 'question', title: 'Seed inventory demo data?', text: 'This will create locations, parts, stock transactions, and purchase orders.', showCancelButton: true, confirmButtonText: 'Seed Data' })
  if (!r?.isConfirmed) return
  seeding.value = true
  try { const res = await $api('/inventory/items/seed-demo/', { method: 'POST' }); await reloadAll(); $swal?.fire?.({ icon: 'success', title: res?.detail || 'Demo data seeded', toast: true, timer: 3000, position: 'top-end' }) }
  catch (e: any) { console.error(e); $swal?.fire?.({ icon: 'error', title: e?.response?._data?.detail || 'Failed to seed', toast: true, timer: 3000, position: 'top-end' }) } finally { seeding.value = false }
}

/* ─── Item CRUD ─── */
function openCreateItem() { editingItem.value = false; itemFormRef.value?.reset(); itemDialog.value = true }
function openEditItem(i: any) { editingItem.value = true; itemFormRef.value?.reset(i); itemDialog.value = true }
async function saveItem(form: any) {
  saving.value = true
  try {
    const { _id, ...body } = form
    if (body.unit_cost != null) body.unit_cost = parseFloat(body.unit_cost)
    if (editingItem.value && form._id) await $api(`/inventory/items/${form._id}/`, { method: 'PATCH', body })
    else await $api('/inventory/items/', { method: 'POST', body })
    itemDialog.value = false; await Promise.all([refreshItems(), refreshStats()])
    $swal?.fire?.({ icon: 'success', title: editingItem.value ? 'Part updated' : 'Part created', toast: true, timer: 1500, position: 'top-end' })
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Save failed', toast: true, timer: 2000, position: 'top-end' }) } finally { saving.value = false }
}
async function deleteItem(i: any) {
  const res = await $swal?.fire?.({ icon: 'warning', title: `Delete ${i.name}?`, text: 'This item will be permanently removed.', showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!res?.isConfirmed) return
  await $api(`/inventory/items/${i.id}/`, { method: 'DELETE' }); await Promise.all([refreshItems(), refreshStats()])
  $swal?.fire?.({ icon: 'success', title: 'Part deleted', toast: true, timer: 1500, position: 'top-end' })
}

/* ─── Stock Adjustment ─── */
function openStockAdj(i: any) { stockItem.value = i; stockFormRef.value?.reset(i); stockDialog.value = true }
async function saveStockAdj(form: any) {
  if (!stockItem.value) return
  saving.value = true
  try {
    const body: any = { item: stockItem.value.id, transaction_type: form.transaction_type, quantity: form.quantity, reference: form.reference, notes: form.notes }
    if (form.unit_cost) body.unit_cost = parseFloat(form.unit_cost)
    await $api('/inventory/transactions/', { method: 'POST', body })
    stockDialog.value = false; await Promise.all([refreshItems(), refreshTxns(), refreshStats()])
    $swal?.fire?.({ icon: 'success', title: 'Stock adjusted', toast: true, timer: 1500, position: 'top-end' })
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Adjustment failed', toast: true, timer: 2000, position: 'top-end' }) } finally { saving.value = false }
}

/* ─── Location CRUD ─── */
function openCreateLocation() { editingLoc.value = false; Object.assign(locForm, { _id: null, name: '', address: '', description: '', is_active: true }); locDialog.value = true }
function openEditLocation(l: any) { editingLoc.value = true; Object.assign(locForm, { _id: l.id, name: l.name, address: l.address || '', description: l.description || '', is_active: l.is_active !== false }); locDialog.value = true }
async function saveLocation() {
  saving.value = true
  try {
    const { _id, ...body } = locForm
    if (editingLoc.value && locForm._id) await $api(`/inventory/locations/${locForm._id}/`, { method: 'PATCH', body })
    else await $api('/inventory/locations/', { method: 'POST', body })
    locDialog.value = false; await Promise.all([refreshLocs(), refreshStats()])
    $swal?.fire?.({ icon: 'success', title: editingLoc.value ? 'Location updated' : 'Location created', toast: true, timer: 1500, position: 'top-end' })
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Save failed', toast: true, timer: 2000, position: 'top-end' }) } finally { saving.value = false }
}
async function deleteLocation(l: any) {
  const res = await $swal?.fire?.({ icon: 'warning', title: `Delete ${l.name}?`, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!res?.isConfirmed) return
  await $api(`/inventory/locations/${l.id}/`, { method: 'DELETE' }); await Promise.all([refreshLocs(), refreshStats()])
  $swal?.fire?.({ icon: 'success', title: 'Location deleted', toast: true, timer: 1500, position: 'top-end' })
}

/* ─── Purchase Order CRUD ─── */
function openCreatePO() { editingPO.value = false; poFormRef.value?.reset(); poDialog.value = true }
function openEditPO(po: any) { editingPO.value = true; poFormRef.value?.reset(po); poDialog.value = true }
async function savePO(payload: any) {
  saving.value = true
  try {
    const { vendor, location, notes, lines } = payload
    if (editingPO.value) {
      await $api(`/inventory/purchase-orders/${payload._id}/`, { method: 'PATCH', body: { vendor, location, notes } })
    } else {
      const po = await $api('/inventory/purchase-orders/', { method: 'POST', body: { vendor, location, notes } })
      for (const line of lines) {
        await $api(`/inventory/purchase-orders/${po.id}/add-item/`, { method: 'POST', body: line })
      }
    }
    poDialog.value = false; await Promise.all([refreshPOs(), refreshStats()])
    $swal?.fire?.({ icon: 'success', title: editingPO.value ? 'PO updated' : 'PO created', toast: true, timer: 1500, position: 'top-end' })
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Save failed', toast: true, timer: 2000, position: 'top-end' }) } finally { saving.value = false }
}
async function openPODetail(po: any) { selectedPO.value = po; poDrawer.value = true }
async function submitPO(po: any) {
  try { await $api(`/inventory/purchase-orders/${po.id}/submit/`, { method: 'POST' }); await Promise.all([refreshPOs(), refreshStats()]); $swal?.fire?.({ icon: 'success', title: 'PO submitted', toast: true, timer: 1500, position: 'top-end' }) }
  catch (e: any) { console.error(e); $swal?.fire?.({ icon: 'error', title: e?.response?._data?.detail || 'Submit failed', toast: true, timer: 2000, position: 'top-end' }) }
}
async function cancelPO(po: any) {
  const res = await $swal?.fire?.({ icon: 'warning', title: `Cancel PO #${po.id}?`, showCancelButton: true, confirmButtonText: 'Cancel PO', confirmButtonColor: '#ef4444' })
  if (!res?.isConfirmed) return
  try { await $api(`/inventory/purchase-orders/${po.id}/`, { method: 'PATCH', body: { status: 'cancelled' } }); await Promise.all([refreshPOs(), refreshStats()]); poDrawer.value = false; $swal?.fire?.({ icon: 'success', title: 'PO cancelled', toast: true, timer: 1500, position: 'top-end' }) }
  catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Cancel failed', toast: true, timer: 2000, position: 'top-end' }) }
}
async function deletePO(po: any) {
  const res = await $swal?.fire?.({ icon: 'warning', title: `Delete PO #${po.id}?`, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!res?.isConfirmed) return
  await $api(`/inventory/purchase-orders/${po.id}/`, { method: 'DELETE' }); poDrawer.value = false; await Promise.all([refreshPOs(), refreshStats()])
  $swal?.fire?.({ icon: 'success', title: 'PO deleted', toast: true, timer: 1500, position: 'top-end' })
}
async function receivePO(qtyMap: Record<number, number>) {
  if (!selectedPO.value) return
  const lines = (selectedPO.value.items || []).filter((i: any) => (qtyMap[i.id] || 0) > 0).map((i: any) => ({ id: i.id, quantity: qtyMap[i.id] }))
  if (!lines.length) { $swal?.fire?.({ icon: 'info', title: 'No items to receive', toast: true, timer: 1500, position: 'top-end' }); return }
  saving.value = true
  try { await $api(`/inventory/purchase-orders/${selectedPO.value.id}/receive/`, { method: 'POST', body: { lines } }); await Promise.all([refreshPOs(), refreshItems(), refreshTxns(), refreshStats()]); $swal?.fire?.({ icon: 'success', title: 'Items received', toast: true, timer: 2000, position: 'top-end' }) }
  catch (e: any) { console.error(e); $swal?.fire?.({ icon: 'error', title: e?.response?._data?.detail || 'Receive failed', toast: true, timer: 2000, position: 'top-end' }) } finally { saving.value = false }
}
</script>

<style scoped>
.page-header { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
.filter-bar { flex-wrap: wrap; background: #f8fafc; padding: 8px 12px; border-radius: 12px; }
.inv-tabs :deep(.v-tab) { text-transform: none; font-weight: 600; }
.cursor-pointer { cursor: pointer; }
</style>
