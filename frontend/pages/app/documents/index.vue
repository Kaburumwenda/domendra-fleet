<template>
  <div class="d-flex flex-column ga-4">
    <!-- Page header -->
    <div class="page-header">
      <div>
        <h1 class="text-h5 font-weight-bold d-flex align-center ga-2">
          <v-icon color="primary">mdi-file-document-multiple</v-icon>
          Documents
        </h1>
        <p class="text-caption text-medium-emphasis">Manage vehicle documents, driver licenses, insurance certificates, registrations, warranties, and more. Track expirations and stay compliant.</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn variant="outlined" prepend-icon="mdi-refresh" @click="reloadAll" :loading="pending">Refresh</v-btn>
        <v-btn v-can="'documents:create'" variant="tonal" color="deep-purple" prepend-icon="mdi-database-plus" @click="seedDemo" :loading="seeding">
          <span class="hidden-sm-and-down">Seed Demo Data</span>
        </v-btn>
        <v-btn v-can="'documents:create'" color="primary" prepend-icon="mdi-upload" @click="openCreate">
          <span class="hidden-sm-and-down">Upload Document</span>
        </v-btn>
      </div>
    </div>

    <!-- Analytics -->
    <DocumentsAnalytics
      :stats="docStats"
      :active-type-filter="typeFilter"
      :active-expiry-filter="expiryFilter"
      @filter-type="setTypeFilter"
      @filter-expiry="setExpiryFilter"
    />

    <!-- Filters bar -->
    <div class="d-flex flex-wrap align-center ga-2 filter-bar">
      <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Search documents…" density="compact" hide-details variant="outlined" style="max-width:280px" clearable />
      <v-select v-model="typeFilter" :items="typeOptions" item-title="label" item-value="value" placeholder="All Types" density="compact" hide-details variant="outlined" clearable style="max-width:170px" />
      <v-select v-model="expiryFilter" :items="expiryOptions" item-title="label" item-value="value" placeholder="All Expiry" density="compact" hide-details variant="outlined" clearable style="max-width:160px" />
      <v-select v-model="vehicleFilter" :items="vehicleOptions" item-title="display_name" item-value="id" placeholder="All Vehicles" density="compact" hide-details variant="outlined" clearable style="max-width:180px" />
      <v-btn v-if="hasFilters" variant="text" size="small" prepend-icon="mdi-filter-remove" @click="clearFilters">Clear</v-btn>
      <v-spacer />
      <div class="text-caption text-medium-emphasis">{{ filteredDocs.length }} of {{ docs.length }} documents</div>
    </div>

    <!-- Tabs -->
    <v-tabs v-model="tab" color="primary" density="compact" class="rem-tabs">
      <v-tab value="grid" prepend-icon="mdi-view-grid-outline">Grid</v-tab>
      <v-tab value="table" prepend-icon="mdi-format-list-bulleted">Table</v-tab>
      <v-tab value="expiring" prepend-icon="mdi-clock-alert-outline">Expiring Soon</v-tab>
    </v-tabs>

    <v-window v-model="tab" class="flex-grow-1">
      <!-- GRID VIEW -->
      <v-window-item value="grid">
        <div v-if="filteredDocs.length === 0" class="text-center py-12 text-medium-emphasis">
          <v-icon size="48" class="mb-3">mdi-file-document-outline</v-icon>
          <p>No documents yet. Click <b>Seed Demo Data</b> or <b>Upload Document</b> to get started.</p>
        </div>
        <v-row v-else dense>
          <v-col v-for="doc in paginatedDocs" :key="doc.id" cols="6" md="3" lg="2">
            <v-card
              elevation="0"
              border
              rounded="lg"
              class="doc-card h-100 cursor-pointer"
              @click="openDetail(doc)"
            >
              <div class="doc-card-header" :style="{ background: typeBg(doc.document_type) }">
                <v-icon size="28" :color="typeColorRaw(doc.document_type)">{{ typeIcon(doc.document_type) }}</v-icon>
                <v-chip
                  v-if="doc.is_expired"
                  color="error"
                  variant="flat"
                  size="x-small"
                  class="doc-status-chip"
                >Expired</v-chip>
                <v-chip
                  v-else-if="doc.is_expiring_soon"
                  color="warning"
                  variant="flat"
                  size="x-small"
                  class="doc-status-chip"
                >Soon</v-chip>
              </div>
              <v-card-text class="pa-3">
                <p class="text-body-2 font-weight-medium text-truncate">{{ doc.title }}</p>
                <p class="text-caption text-medium-emphasis text-truncate">{{ doc.vehicle_name || doc.contact_name || 'General' }}</p>
                <div class="d-flex align-center justify-space-between mt-2">
                  <span class="text-caption text-medium-emphasis">{{ doc.file_size_display || '—' }}</span>
                  <span v-if="doc.expiry_date" class="text-caption font-weight-medium" :style="{ color: doc.is_expired ? '#ef4444' : doc.is_expiring_soon ? '#f59e0b' : '#64748b' }">
                    {{ doc.is_expired ? 'Exp ' : doc.is_expiring_soon ? 'Soon ' : '' }}{{ fmtDate(doc.expiry_date) }}
                  </span>
                  <span v-else class="text-caption text-medium-emphasis">No expiry</span>
                </div>
              </v-card-text>
            </v-card>
          </v-col>
        </v-row>
        <div class="d-flex justify-center mt-4" v-if="filteredDocs.length > gridPageSize">
          <v-pagination v-model="gridPage" :length="gridTotalPages" density="compact" total-visible="7" />
        </div>
      </v-window-item>

      <!-- TABLE VIEW -->
      <v-window-item value="table">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="headers" :items="filteredDocs" :loading="pending" hover density="compact" :search="search">
            <template #item.title="{ item }">
              <div class="cursor-pointer" @click="openDetail(item)">
                <div class="d-flex align-center ga-2">
                  <v-icon size="small" :color="typeColorRaw(item.document_type)">{{ typeIcon(item.document_type) }}</v-icon>
                  <span class="font-weight-medium">{{ item.title }}</span>
                </div>
              </div>
            </template>
            <template #item.document_type="{ value }">
              <v-chip :color="typeColorRaw(value)" variant="tonal" size="small" class="text-capitalize">
                <v-icon start size="14">{{ typeIcon(value) }}</v-icon>{{ typeLabel(value) }}
              </v-chip>
            </template>
            <template #item.entity="{ item }">
              <div class="d-flex flex-column">
                <span v-if="item.vehicle_name" class="text-body-2"><v-icon size="14" class="mr-1">mdi-car</v-icon>{{ item.vehicle_name }}</span>
                <span v-if="item.contact_name" class="text-caption text-medium-emphasis"><v-icon size="12" class="mr-1">mdi-account</v-icon>{{ item.contact_name }}</span>
                <span v-if="!item.vehicle_name && !item.contact_name" class="text-medium-emphasis">—</span>
              </div>
            </template>
            <template #item.expiry_date="{ item }">
              <div v-if="item.expiry_date">
                <span :style="{ color: item.is_expired ? '#ef4444' : item.is_expiring_soon ? '#f59e0b' : '#475569', fontWeight: 500 }">
                  {{ item.is_expired ? 'Expired ' : item.is_expiring_soon ? 'Expiring ' : '' }}{{ fmtDate(item.expiry_date) }}
                </span>
                <p v-if="item.days_to_expiry != null" class="text-caption" :style="{ color: item.is_expired ? '#ef4444' : '#94a3b8' }">
                  {{ item.days_to_expiry >= 0 ? `${item.days_to_expiry} days left` : `${Math.abs(item.days_to_expiry)} days overdue` }}
                </p>
              </div>
              <span v-else class="text-medium-emphasis">No expiry</span>
            </template>
            <template #item.file_size_display="{ value }">
              <span class="text-caption text-medium-emphasis">{{ value || '—' }}</span>
            </template>
            <template #item.uploaded_by_name="{ value }">
              <span class="text-body-2">{{ value || '—' }}</span>
            </template>
            <template #item.created_at="{ value }">{{ fmtDate(value) }}</template>
            <template #item.actions="{ item }">
              <v-menu>
                <template #activator="{ props: p }">
                  <v-btn icon="mdi-dots-vertical" variant="text" size="small" v-bind="p" />
                </template>
                <v-list density="compact">
                  <v-list-item prepend-icon="mdi-eye-outline" @click="openDetail(item)">View Details</v-list-item>
                  <v-list-item prepend-icon="mdi-download" :href="resolveFileUrl(item.file)" target="_blank">Download</v-list-item>
                  <v-list-item v-can="'documents:update'" prepend-icon="mdi-pencil" @click="openEdit(item)">Edit</v-list-item>
                  <v-list-item v-can="'documents:delete'" prepend-icon="mdi-trash-can-outline" base-color="error" @click="deleteDoc(item)">Delete</v-list-item>
                </v-list>
              </v-menu>
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-file-document-outline</v-icon>
                <p>No documents yet. Click <b>Seed Demo Data</b> or <b>Upload Document</b> to get started.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>

      <!-- EXPIRING SOON TAB -->
      <v-window-item value="expiring">
        <v-card elevation="0" border rounded="lg">
          <v-card-text>
            <div v-if="!expiringDocs.length" class="text-center py-12 text-medium-emphasis">
              <v-icon size="48" class="mb-3">mdi-check-circle-outline</v-icon>
              <p>No documents expiring soon. All good!</p>
            </div>
            <v-timeline v-else side="end" density="compact">
              <v-timeline-item
                v-for="doc in expiringDocs"
                :key="doc.id"
                :dot-color="doc.is_expired ? 'error' : 'warning'"
                size="small"
                fill-dot
              >
                <template #opposite>
                  <span class="text-caption text-medium-emphasis">{{ fmtDate(doc.expiry_date) }}</span>
                </template>
                <v-card elevation="0" border class="pa-3 cursor-pointer" @click="openDetail(doc)">
                  <div class="d-flex align-start justify-space-between">
                    <div class="flex-grow-1">
                      <div class="d-flex align-center ga-2 mb-1">
                        <v-icon size="16" :color="typeColorRaw(doc.document_type)">{{ typeIcon(doc.document_type) }}</v-icon>
                        <p class="font-weight-medium">{{ doc.title }}</p>
                        <v-chip v-if="doc.is_expired" color="error" variant="flat" size="x-small">Expired</v-chip>
                      </div>
                      <p class="text-caption text-medium-emphasis">{{ doc.vehicle_name || doc.contact_name || 'General' }} · {{ typeLabel(doc.document_type) }}</p>
                      <div class="d-flex align-center ga-2 mt-1">
                        <span class="text-caption" :style="{ color: doc.is_expired ? '#ef4444' : '#f59e0b', fontWeight: 600 }">
                          {{ doc.is_expired ? `${Math.abs(doc.days_to_expiry || 0)} days overdue` : `${doc.days_to_expiry} days remaining` }}
                        </span>
                      </div>
                    </div>
                  </div>
                </v-card>
              </v-timeline-item>
            </v-timeline>
          </v-card-text>
        </v-card>
      </v-window-item>
    </v-window>

    <!-- Upload dialog -->
    <DocumentUploadDialog
      ref="formRef"
      v-model="formDialog"
      :editing="editing"
      :saving="saving"
      :vehicle-options="vehicleOptions"
      :contact-options="contactOptions"
      @save="saveDoc"
    />

    <!-- Detail drawer -->
    <DocumentDetailDrawer
      v-model="drawerOpen"
      :doc="selectedDoc"
      @edit="openEdit"
      @delete="deleteDoc"
    />
  </div>
</template>

<script setup lang="ts">
import DocumentsAnalytics from '~/components/documents/DocumentsAnalytics.vue'
import DocumentUploadDialog from '~/components/documents/DocumentUploadDialog.vue'
import DocumentDetailDrawer from '~/components/documents/DocumentDetailDrawer.vue'
import { useMediaUrl } from '~/composables/useMediaUrl'

definePageMeta({ layout: 'default' })
const { $api, $swal } = useNuxtApp() as any
const { resolveMediaUrl } = useMediaUrl()

/* ─── state ─── */
const tab = ref<'grid' | 'table' | 'expiring'>('grid')
const search = ref('')
const typeFilter = ref<string | null>(null)
const expiryFilter = ref<string | null>(null)
const vehicleFilter = ref<number | null>(null)
const formRef = ref<any>(null)
const formDialog = ref(false)
const editing = ref(false)
const saving = ref(false)
const seeding = ref(false)
const drawerOpen = ref(false)
const selectedDoc = ref<any>(null)
const gridPage = ref(1)
const gridPageSize = 12

const typeOptions = [
  { label: 'Insurance', value: 'insurance' },
  { label: 'Registration', value: 'registration' },
  { label: 'Title', value: 'title' },
  { label: 'Inspection', value: 'inspection' },
  { label: 'License', value: 'license' },
  { label: 'Medical Card', value: 'medical_card' },
  { label: 'Warranty', value: 'warranty' },
  { label: 'Contract', value: 'contract' },
  { label: 'Permit', value: 'permit' },
  { label: 'Maintenance', value: 'maintenance' },
  { label: 'Other', value: 'other' },
]
const expiryOptions = [
  { label: 'Expired', value: 'expired' },
  { label: 'Expiring Soon', value: 'expiring' },
  { label: 'No Expiry', value: 'none' },
]

const headers = [
  { title: 'Document', key: 'title', sortable: true },
  { title: 'Type', key: 'document_type', width: '140px', sortable: true },
  { title: 'Vehicle / Contact', key: 'entity', width: '180px' },
  { title: 'Size', key: 'file_size_display', width: '90px' },
  { title: 'Expiry', key: 'expiry_date', width: '160px', sortable: true },
  { title: 'Uploaded By', key: 'uploaded_by_name', width: '130px' },
  { title: 'Date', key: 'created_at', width: '110px', sortable: true },
  { title: '', key: 'actions', width: '50px', sortable: false },
]

/* ─── data ─── */
const { data: docData, pending, refresh } = useAsyncData('documents-page', () =>
  $api('/documents/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const docs = computed<any[]>(() => docData.value?.results || [])

const { data: statsData, refresh: refreshStats } = useAsyncData('documents-stats', () =>
  $api('/documents/stats/').catch(() => ({})), { default: () => ({}) })
const docStats = computed(() => statsData.value || {})

const { data: vehicleData } = useAsyncData('documents-vehicles', () =>
  $api('/vehicles/vehicles/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const vehicleOptions = computed<any[]>(() => vehicleData.value?.results || [])

const { data: contactData } = useAsyncData('documents-contacts', () =>
  $api('/contacts/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })), { default: () => ({ results: [] }) })
const contactOptions = computed<any[]>(() => contactData.value?.results || [])

/* ─── filters ─── */
const filteredDocs = computed(() => {
  let arr = docs.value
  if (typeFilter.value) arr = arr.filter(d => d.document_type === typeFilter.value)
  if (vehicleFilter.value) arr = arr.filter(d => d.vehicle === vehicleFilter.value)
  if (expiryFilter.value === 'expired') arr = arr.filter(d => d.is_expired)
  else if (expiryFilter.value === 'expiring') arr = arr.filter(d => d.is_expiring_soon)
  else if (expiryFilter.value === 'none') arr = arr.filter(d => !d.expiry_date)
  if (search.value) {
    const q = search.value.toLowerCase()
    arr = arr.filter(d =>
      (d.title || '').toLowerCase().includes(q) ||
      (d.notes || '').toLowerCase().includes(q) ||
      (d.vehicle_name || '').toLowerCase().includes(q) ||
      (d.contact_name || '').toLowerCase().includes(q)
    )
  }
  return arr
})

const hasFilters = computed(() => !!(search.value || typeFilter.value || expiryFilter.value || vehicleFilter.value))
const expiringDocs = computed(() => {
  return filteredDocs.value
    .filter(d => d.expiry_date && (d.is_expired || d.is_expiring_soon))
    .sort((a, b) => (a.days_to_expiry || 0) - (b.days_to_expiry || 0))
})
const gridTotalPages = computed(() => Math.ceil(filteredDocs.value.length / gridPageSize))
const paginatedDocs = computed(() => {
  const start = (gridPage.value - 1) * gridPageSize
  return filteredDocs.value.slice(start, start + gridPageSize)
})

function clearFilters() { search.value = ''; typeFilter.value = null; expiryFilter.value = null; vehicleFilter.value = null }
function setTypeFilter(v: string) { typeFilter.value = typeFilter.value === v ? null : v; gridPage.value = 1 }
function setExpiryFilter(v: string) { expiryFilter.value = expiryFilter.value === v ? null : v; gridPage.value = 1; if (v === 'expired' || v === 'expiring') tab.value = 'table' }

/* ─── helpers ─── */
function typeColorRaw(t: string) {
  return ({
    insurance: '#3b82f6', registration: '#06b6d4', title: '#22c55e', inspection: '#f59e0b',
    license: '#8b5cf6', medical_card: '#ec4899', warranty: '#14b8a6', contract: '#6366f1',
    permit: '#f97316', maintenance: '#06b6d4', other: '#94a3b8',
  } as any)[t] || '#94a3b8'
}
function typeColor(t: string) {
  return ({
    insurance: 'primary', registration: 'info', title: 'success', inspection: 'warning',
    license: 'deep-purple', medical_card: 'pink', warranty: 'teal', contract: 'indigo',
    permit: 'orange', maintenance: 'cyan', other: 'grey',
  } as any)[t] || 'grey'
}
function typeBg(t: string) {
  const colors: Record<string, string> = {
    insurance: '#eff6ff', registration: '#ecfeff', title: '#f0fdf4', inspection: '#fffbeb',
    license: '#faf5ff', medical_card: '#fdf2f8', warranty: '#f0fdfa', contract: '#eef2ff',
    permit: '#fff7ed', maintenance: '#ecfeff', other: '#f8fafc',
  }
  return colors[t] || '#f8fafc'
}
function typeIcon(t: string) {
  return ({
    insurance: 'mdi-shield-outline', registration: 'mdi-file-document-outline',
    title: 'mdi-bookmark-outline', inspection: 'mdi-clipboard-check-outline',
    license: 'mdi-card-account-details-outline', medical_card: 'mdi-heart-pulse',
    warranty: 'mdi-shield-home-outline', contract: 'mdi-file-sign',
    permit: 'mdi-ticket-confirmation', maintenance: 'mdi-wrench-check',
    other: 'mdi-file-document-outline',
  } as any)[t] || 'mdi-file-document-outline'
}
function typeLabel(t: string) {
  return ({
    insurance: 'Insurance', registration: 'Registration', title: 'Title',
    inspection: 'Inspection', license: 'License', medical_card: 'Medical Card',
    warranty: 'Warranty', contract: 'Contract', permit: 'Permit',
    maintenance: 'Maintenance', other: 'Other',
  } as any)[t] || t
}
function fmtDate(v?: string) { return v ? new Date(v).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' }) : '—' }
function resolveFileUrl(url: string) { return resolveMediaUrl(url) }

/* ─── reload all ─── */
async function reloadAll() { await Promise.all([refresh(), refreshStats()]) }

/* ─── seed demo ─── */
async function seedDemo() {
  const r = await $swal?.fire?.({ icon: 'question', title: 'Seed document demo data?', text: 'This will create sample documents linked to vehicles and contacts.', showCancelButton: true, confirmButtonText: 'Seed Data' })
  if (!r?.isConfirmed) return
  seeding.value = true
  try {
    const res = await $api('/documents/seed-demo/', { method: 'POST' })
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: res?.detail || 'Demo data seeded', toast: true, timer: 2000, position: 'top-end' })
  } catch (e: any) { console.error(e); $swal?.fire?.({ icon: 'error', title: e?.response?._data?.detail || 'Failed to seed data', toast: true, timer: 3000, position: 'top-end' }) } finally { seeding.value = false }
}

/* ─── CRUD ─── */
function openCreate() { editing.value = false; formRef.value?.reset(); formDialog.value = true }

function openEdit(doc: any) { editing.value = true; formRef.value?.reset(doc); formDialog.value = true; drawerOpen.value = false }

function openDetail(doc: any) { selectedDoc.value = doc; drawerOpen.value = true }

async function saveDoc(payload: any) {
  saving.value = true
  try {
    if (editing.value && payload._id) {
      // Update metadata (no new file)
      const { _id, file, ...body } = payload
      await $api(`/documents/${_id}/`, { method: 'PATCH', body })
    } else {
      // Create with FormData (file upload)
      const formData = new FormData()
      formData.append('file', payload.file)
      formData.append('title', payload.title)
      formData.append('document_type', payload.document_type)
      if (payload.expiry_date) formData.append('expiry_date', payload.expiry_date)
      if (payload.vehicle) formData.append('vehicle', String(payload.vehicle))
      if (payload.contact) formData.append('contact', String(payload.contact))
      if (payload.notes) formData.append('notes', payload.notes)
      await $api('/documents/', { method: 'POST', body: formData })
    }
    formDialog.value = false
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: editing.value ? 'Document updated' : 'Document uploaded', toast: true, timer: 1500, position: 'top-end' })
  } catch (e: any) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Save failed', toast: true, timer: 2000, position: 'top-end' }) } finally { saving.value = false }
}

async function deleteDoc(doc: any) {
  const res = await $swal?.fire?.({ icon: 'warning', title: 'Delete document?', text: `"${doc.title}" will be permanently removed.`, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!res?.isConfirmed) return
  try {
    await $api(`/documents/${doc.id}/`, { method: 'DELETE' })
    drawerOpen.value = false
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: 'Document deleted', toast: true, timer: 1500, position: 'top-end' })
  } catch (e: any) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Delete failed', toast: true, timer: 2000, position: 'top-end' }) }
}
</script>

<style scoped>
.page-header { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
.filter-bar { flex-wrap: wrap; background: #f8fafc; padding: 8px 12px; border-radius: 12px; }
.rem-tabs :deep(.v-tab) { text-transform: none; font-weight: 600; }
.cursor-pointer { cursor: pointer; }
.doc-card { transition: all .2s; }
.doc-card:hover { border-color: #c7d2fe; box-shadow: 0 4px 12px rgba(99,102,241,.1); transform: translateY(-2px); }
.doc-card-header { display: flex; align-items: center; justify-content: center; height: 88px; border-radius: 8px 8px 0 0; position: relative; }
.doc-status-chip { position: absolute; top: 8px; right: 8px; }
</style>
