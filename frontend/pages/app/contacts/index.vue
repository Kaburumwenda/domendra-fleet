<template>
  <div class="d-flex flex-column ga-4">
    <!-- Page header -->
    <div class="page-header">
      <div>
        <h1 class="text-h5 font-weight-bold d-flex align-center ga-2">
          <v-icon color="primary">mdi-card-account-details-outline</v-icon>
          Contacts
        </h1>
        <p class="text-caption text-medium-emphasis">Manage vendors, mechanics, insurance agents, towing companies, managers, and other contacts. Track vendor ratings, service types, and keep contact records organized.</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn variant="outlined" prepend-icon="mdi-refresh" @click="reloadAll" :loading="pending">Refresh</v-btn>
        <v-btn variant="tonal" color="deep-purple" prepend-icon="mdi-database-plus" @click="seedDemo" :loading="seeding" v-can="'contacts:create'">
          <span class="hidden-sm-and-down">Seed Demo Data</span>
        </v-btn>
        <v-btn v-can="'contacts:create'" color="primary" prepend-icon="mdi-plus" @click="openCreate">
          <span class="hidden-sm-and-down">Add Contact</span>
        </v-btn>
      </div>
    </div>

    <!-- Analytics -->
    <ContactsAnalytics
      :stats="contactStats"
      :active-type-filter="filterType || ''"
      :active-active-filter="filterActive || ''"
      @filter-type="setTypeFilter"
      @filter-active="setActiveFilter"
    />

    <!-- Filters bar -->
    <div class="d-flex flex-wrap align-center ga-2 filter-bar">
      <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Search contacts…" density="compact" hide-details variant="outlined" style="max-width:280px" clearable />
      <v-select v-model="filterType" :items="contactTypes" item-title="label" item-value="value" placeholder="All Types" density="compact" hide-details variant="outlined" clearable style="max-width:170px" />
      <v-select v-model="filterActive" :items="activeOptions" item-title="label" item-value="value" placeholder="All Status" density="compact" hide-details variant="outlined" clearable style="max-width:150px" />
      <v-btn v-if="hasFilters" variant="text" size="small" prepend-icon="mdi-filter-remove" @click="clearFilters">Clear</v-btn>
      <v-spacer />
      <div class="text-caption text-medium-emphasis">{{ filteredContacts.length }} of {{ contacts.length }} contacts</div>
    </div>

    <!-- Tabs -->
    <v-tabs v-model="tab" color="primary" density="compact" class="rem-tabs">
      <v-tab value="all" prepend-icon="mdi-account-group-outline">All Contacts</v-tab>
      <v-tab value="vendors" prepend-icon="mdi-store-outline">Vendors</v-tab>
      <v-tab value="staff" prepend-icon="mdi-account-hard-hat-outline">Staff</v-tab>
    </v-tabs>

    <v-window v-model="tab" class="flex-grow-1">
      <!-- ALL CONTACTS -->
      <v-window-item value="all">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="headers" :items="filteredContacts" :loading="pending" :search="search" hover density="compact" items-per-page="15">
            <template #item.full_name="{ item }">
              <div class="d-flex align-center ga-2 cursor-pointer" @click="openDetail(item)">
                <div class="contact-avatar" :style="{ background: avatarColor(item) }">
                  <img v-if="item.photo" :src="resolveMediaUrl(item.photo)" :alt="item.full_name" />
                  <span v-else>{{ initials(item) }}</span>
                </div>
                <div>
                  <p class="text-body-2 font-weight-medium" style="color: #1e293b">{{ item.full_name }}</p>
                  <p class="text-caption text-medium-emphasis">{{ item.email || item.phone || '—' }}</p>
                </div>
              </div>
            </template>

            <template #item.contact_type="{ item }">
              <v-chip :color="typeColor(item.contact_type)" variant="tonal" size="small">
                <v-icon start size="14">{{ typeIcon(item.contact_type) }}</v-icon>
                {{ typeLabel(item.contact_type) }}
              </v-chip>
            </template>

            <template #item.company_name="{ value }">
              <span class="text-body-2">{{ value || '—' }}</span>
            </template>

            <template #item.city="{ item }">
              <span class="text-body-2 text-medium-emphasis">{{ [item.city, item.state].filter(Boolean).join(', ') || '—' }}</span>
            </template>

            <template #item.is_active="{ item }">
              <v-chip :color="item.is_active ? 'success' : 'grey'" variant="flat" size="small">
                <v-icon start size="14">{{ item.is_active ? 'mdi-check-circle' : 'mdi-pause-circle' }}</v-icon>
                {{ item.is_active ? 'Active' : 'Inactive' }}
              </v-chip>
            </template>

            <template #item.vendor_rating="{ item }">
              <div v-if="item.contact_type === 'vendor' && item.vendor_profile" class="d-flex align-center ga-1">
                <v-rating :model-value="item.vendor_profile.rating || 0" color="warning" density="compact" half-increments readonly size="x-small" />
                <span class="text-caption font-weight-medium">{{ item.vendor_profile.rating || 0 }}</span>
              </div>
              <span v-else class="text-medium-emphasis">—</span>
            </template>

            <template #item.actions="{ item }">
              <v-menu>
                <template #activator="{ props: p }">
                  <v-btn icon="mdi-dots-vertical" variant="text" size="small" v-bind="p" />
                </template>
                <v-list density="compact">
                  <v-list-item prepend-icon="mdi-eye-outline" @click="openDetail(item)">View Details</v-list-item>
                  <v-list-item v-can="'contacts:update'" prepend-icon="mdi-pencil-outline" @click="openEdit(item)">Edit</v-list-item>
                  <v-list-item v-can="'contacts:delete'" prepend-icon="mdi-trash-can-outline" base-color="error" @click="deleteContact(item)">Delete</v-list-item>
                </v-list>
              </v-menu>
            </template>

            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-card-account-details-outline</v-icon>
                <p>No contacts yet. Click <b>Seed Demo Data</b> or <b>Add Contact</b> to get started.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>

      <!-- VENDORS TAB -->
      <v-window-item value="vendors">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="vendorHeaders" :items="vendorContacts" :loading="pending" :search="search" hover density="compact" items-per-page="15">
            <template #item.full_name="{ item }">
              <div class="d-flex align-center ga-2 cursor-pointer" @click="openDetail(item)">
                <div class="contact-avatar" :style="{ background: avatarColor(item) }">
                  <span>{{ initials(item) }}</span>
                </div>
                <div>
                  <p class="text-body-2 font-weight-medium" style="color: #1e293b">{{ item.company_name || item.full_name }}</p>
                  <p class="text-caption text-medium-emphasis">{{ item.email || item.phone || '—' }}</p>
                </div>
              </div>
            </template>
            <template #item.service_type="{ item }">
              <v-chip color="teal" variant="tonal" size="small" prepend-icon="mdi-wrench-outline">{{ item.vendor_profile?.service_type || '—' }}</v-chip>
            </template>
            <template #item.rating="{ item }">
              <div class="d-flex align-center ga-1">
                <v-rating :model-value="item.vendor_profile?.rating || 0" color="warning" density="compact" half-increments readonly size="x-small" />
                <span class="text-caption font-weight-medium">{{ item.vendor_profile?.rating || 0 }}</span>
              </div>
            </template>
            <template #item.payment_terms="{ item }">
              <span class="text-body-2">{{ item.vendor_profile?.payment_terms || '—' }}</span>
            </template>
            <template #item.actions="{ item }">
              <v-btn icon="mdi-eye-outline" variant="text" size="small" @click="openDetail(item)" />
              <v-btn v-can="'contacts:update'" icon="mdi-pencil-outline" variant="text" size="small" @click="openEdit(item)" />
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-store-outline</v-icon>
                <p>No vendor contacts found.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>

      <!-- STAFF TAB -->
      <v-window-item value="staff">
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="staffHeaders" :items="staffContacts" :loading="pending" :search="search" hover density="compact" items-per-page="15">
            <template #item.full_name="{ item }">
              <div class="d-flex align-center ga-2 cursor-pointer" @click="openDetail(item)">
                <div class="contact-avatar" :style="{ background: avatarColor(item) }">
                  <span>{{ initials(item) }}</span>
                </div>
                <div>
                  <p class="text-body-2 font-weight-medium" style="color: #1e293b">{{ item.full_name }}</p>
                  <p class="text-caption text-medium-emphasis">{{ item.employee_id || item.email || '—' }}</p>
                </div>
              </div>
            </template>
            <template #item.contact_type="{ item }">
              <v-chip :color="typeColor(item.contact_type)" variant="tonal" size="small">
                <v-icon start size="14">{{ typeIcon(item.contact_type) }}</v-icon>
                {{ typeLabel(item.contact_type) }}
              </v-chip>
            </template>
            <template #item.department="{ value }">
              <span class="text-body-2">{{ value || '—' }}</span>
            </template>
            <template #item.is_active="{ item }">
              <v-chip :color="item.is_active ? 'success' : 'grey'" variant="flat" size="small">
                <v-icon start size="14">{{ item.is_active ? 'mdi-check-circle' : 'mdi-pause-circle' }}</v-icon>
                {{ item.is_active ? 'Active' : 'Inactive' }}
              </v-chip>
            </template>
            <template #item.actions="{ item }">
              <v-btn icon="mdi-eye-outline" variant="text" size="small" @click="openDetail(item)" />
              <v-btn v-can="'contacts:update'" icon="mdi-pencil-outline" variant="text" size="small" @click="openEdit(item)" />
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-account-hard-hat-outline</v-icon>
                <p>No staff contacts found.</p>
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>
    </v-window>

    <!-- Form dialog -->
    <ContactFormDialog
      v-model="formDialog"
      :editing="editing"
      :saving="saving"
      :editing-contact="selectedContact"
      @save="saveContact"
    />

    <!-- Detail drawer -->
    <ContactDetailDrawer
      v-model="drawerOpen"
      :contact="selectedContact"
      @edit="openEdit"
      @delete="deleteContact"
    />
  </div>
</template>

<script setup lang="ts">
import ContactsAnalytics from '~/components/contacts/ContactsAnalytics.vue'
import ContactDetailDrawer from '~/components/contacts/ContactDetailDrawer.vue'
import ContactFormDialog from '~/components/contacts/ContactFormDialog.vue'
import { useMediaUrl } from '~/composables/useMediaUrl'

definePageMeta({ layout: 'default' })
const { $api, $swal } = useNuxtApp() as any
const { resolveMediaUrl } = useMediaUrl()

/* ─── state ─── */
const tab = ref<'all' | 'vendors' | 'staff'>('all')
const search = ref('')
const filterType = ref<string | null>(null)
const filterActive = ref<string | null>(null)
const seeding = ref(false)
const formDialog = ref(false)
const editing = ref(false)
const saving = ref(false)
const drawerOpen = ref(false)
const selectedContact = ref<any>(null)

const contactTypes = [
  { label: 'Driver', value: 'driver' },
  { label: 'Vendor', value: 'vendor' },
  { label: 'Mechanic', value: 'mechanic' },
  { label: 'Manager', value: 'manager' },
  { label: 'Insurance Agent', value: 'insurance_agent' },
  { label: 'Towing Company', value: 'towing' },
]
const activeOptions = [
  { label: 'Active', value: 'true' },
  { label: 'Inactive', value: 'false' },
]

const headers = [
  { title: 'Name', key: 'full_name', sortable: true },
  { title: 'Type', key: 'contact_type', sortable: true, width: '140px' },
  { title: 'Company', key: 'company_name', width: '150px' },
  { title: 'City', key: 'city', width: '120px' },
  { title: 'Vendor Rating', key: 'vendor_rating', width: '130px', sortable: false },
  { title: 'Status', key: 'is_active', width: '110px', sortable: true },
  { title: '', key: 'actions', width: '50px', sortable: false },
]
const vendorHeaders = [
  { title: 'Vendor', key: 'full_name', sortable: true },
  { title: 'Service Type', key: 'service_type', width: '180px' },
  { title: 'Rating', key: 'rating', width: '160px' },
  { title: 'Payment Terms', key: 'payment_terms', width: '120px' },
  { title: 'City', key: 'city', width: '120px' },
  { title: '', key: 'actions', width: '80px', sortable: false },
]
const staffHeaders = [
  { title: 'Name', key: 'full_name', sortable: true },
  { title: 'Type', key: 'contact_type', sortable: true, width: '150px' },
  { title: 'Department', key: 'department', width: '140px' },
  { title: 'Employee ID', key: 'employee_id', width: '120px' },
  { title: 'Phone', key: 'phone', width: '140px' },
  { title: 'Status', key: 'is_active', width: '110px', sortable: true },
  { title: '', key: 'actions', width: '80px', sortable: false },
]

/* ─── data ─── */
const { data: contactsData, pending, refresh } = useAsyncData('contacts-list', () =>
  $api('/contacts/', { query: { page_size: 1000 } }).catch(() => ({ results: [] })),
  { default: () => ({ results: [] as any[] }) },
)
const contacts = computed<any[]>(() => contactsData.value?.results || [])

const { data: statsData, refresh: refreshStats } = useAsyncData('contacts-stats', () =>
  $api('/contacts/stats/').catch(() => ({})),
  { default: () => ({}) },
)
const contactStats = computed(() => statsData.value || {})

/* ─── filters ─── */
const filteredContacts = computed(() => {
  return contacts.value.filter((c: any) => {
    if (filterType.value && c.contact_type !== filterType.value) return false
    if (filterActive.value === 'true' && !c.is_active) return false
    if (filterActive.value === 'false' && c.is_active) return false
    return true
  })
})

const hasFilters = computed(() => !!(search.value || filterType.value || filterActive.value))

const vendorContacts = computed(() => filteredContacts.value.filter((c: any) => c.contact_type === 'vendor'))
const staffContacts = computed(() => filteredContacts.value.filter((c: any) => ['mechanic', 'manager'].includes(c.contact_type)))

function clearFilters() { search.value = ''; filterType.value = null; filterActive.value = null }
function setTypeFilter(v: string) {
  if (v === '') { filterType.value = null; return }
  filterType.value = filterType.value === v ? null : v
  if (v === 'vendor') tab.value = 'vendors'
}
function setActiveFilter(v: string) {
  filterActive.value = filterActive.value === v ? null : v
}

/* ─── helpers ─── */
function initials(c: any) {
  if (c?.first_name || c?.last_name) return ((c.first_name?.[0] || '') + (c.last_name?.[0] || '')).toUpperCase() || '?'
  if (c?.company_name) return c.company_name.slice(0, 2).toUpperCase()
  return '?'
}
function avatarColor(c: any) {
  const colors = ['#e0e7ff', '#dcfce7', '#fef9c3', '#fee2e2', '#f3e8ff', '#cffafe']
  return colors[(c?.first_name?.charCodeAt(0) || c?.company_name?.charCodeAt(0) || 0) % colors.length]
}
function typeColor(t: string) {
  return ({ driver: 'primary', vendor: 'teal', mechanic: 'amber', manager: 'deep-purple', insurance_agent: 'cyan', towing: 'error' } as any)[t] || 'grey'
}
function typeIcon(t: string) {
  return ({ driver: 'mdi-steering', vendor: 'mdi-store-outline', mechanic: 'mdi-wrench', manager: 'mdi-account-tie', insurance_agent: 'mdi-shield-outline', towing: 'mdi-tow-truck' } as any)[t] || 'mdi-account'
}
function typeLabel(t: string) {
  return ({ driver: 'Driver', vendor: 'Vendor', mechanic: 'Mechanic', manager: 'Manager', insurance_agent: 'Insurance Agent', towing: 'Towing Company' } as any)[t] || t || '—'
}

/* ─── reload all ─── */
async function reloadAll() { await Promise.all([refresh(), refreshStats()]) }

/* ─── seed demo ─── */
async function seedDemo() {
  const r = await $swal?.fire?.({ icon: 'question', title: 'Seed contact demo data?', text: 'This will create 10 sample contacts (vendors, mechanics, insurance agents, towing, managers).', showCancelButton: true, confirmButtonText: 'Seed Data' })
  if (!r?.isConfirmed) return
  seeding.value = true
  try {
    const res = await $api('/contacts/seed_demo/', { method: 'POST' })
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: res?.detail || 'Demo data seeded', toast: true, timer: 2000, position: 'top-end' })
  } catch (e: any) {
    console.error(e)
    $swal?.fire?.({ icon: 'error', title: e?.response?._data?.detail || 'Failed to seed data', toast: true, timer: 3000, position: 'top-end' })
  } finally { seeding.value = false }
}

/* ─── actions ─── */
function openCreate() { editing.value = false; selectedContact.value = null; formDialog.value = true }
function openEdit(c: any) { editing.value = true; selectedContact.value = c; drawerOpen.value = false; formDialog.value = true }
function openDetail(c: any) { selectedContact.value = c; drawerOpen.value = true }

async function saveContact(body: any) {
  saving.value = true
  try {
    if (editing.value && selectedContact.value) {
      await $api(`/contacts/${selectedContact.value.id}/`, { method: 'PATCH', body })
      $swal?.fire?.({ icon: 'success', title: 'Contact updated', toast: true, timer: 1500, position: 'top-end' })
    } else {
      await $api('/contacts/', { method: 'POST', body })
      $swal?.fire?.({ icon: 'success', title: 'Contact created', toast: true, timer: 1500, position: 'top-end' })
    }
    formDialog.value = false
    await reloadAll()
  } catch (e: any) {
    console.error(e)
    $swal?.fire?.({ icon: 'error', title: 'Save failed', toast: true, timer: 2000, position: 'top-end' })
  } finally { saving.value = false }
}

async function deleteContact(c: any) {
  const res = await $swal?.fire?.({ icon: 'warning', title: 'Delete contact?', text: `"${c.full_name}" will be permanently removed.`, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444' })
  if (!res?.isConfirmed) return
  try {
    await $api(`/contacts/${c.id}/`, { method: 'DELETE' })
    drawerOpen.value = false
    await reloadAll()
    $swal?.fire?.({ icon: 'success', title: 'Contact deleted', toast: true, timer: 1500, position: 'top-end' })
  } catch (e: any) {
    console.error(e)
    $swal?.fire?.({ icon: 'error', title: 'Delete failed', toast: true, timer: 2000, position: 'top-end' })
  }
}
</script>

<style scoped>
.page-header { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
.filter-bar { flex-wrap: wrap; background: #f8fafc; padding: 8px 12px; border-radius: 12px; }
.rem-tabs :deep(.v-tab) { text-transform: none; font-weight: 600; }
.cursor-pointer { cursor: pointer; }
.contact-avatar { width: 38px; height: 38px; border-radius: 50%; display: flex; align-items: center; justify-content: center; overflow: hidden; flex-shrink: 0; font-weight: 700; font-size: 14px; }
.contact-avatar img { width: 100%; height: 100%; object-fit: cover; }
.contact-avatar span { font-size: 14px; font-weight: 700; color: #4338ca; }
</style>
