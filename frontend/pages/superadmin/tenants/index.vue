<template>
  <div class="d-flex flex-column ga-4">
    <!-- Header -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-3">
      <div class="d-flex align-center ga-3">
        <div class="d-flex align-center justify-center rounded-xl" style="width: 48px; height: 48px; background: linear-gradient(135deg, #6366f1, #4f46e5)">
          <v-icon color="white">mdi-domain</v-icon>
        </div>
        <div>
          <h1 class="text-h5 font-weight-bold" style="color: #1e293b">Tenants</h1>
          <p class="text-body-2 text-medium-emphasis">All organizations on the platform</p>
        </div>
      </div>
      <div class="d-flex align-center ga-2 flex-wrap">
        <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Search tenants..." density="compact" variant="outlined" hide-details style="max-width: 240px" @keyup.enter="load" clearable @click:clear="search = ''; load()" />
        <v-select v-model="filterStatus" :items="statusOpts" density="compact" variant="outlined" hide-details style="max-width: 150px" />
        <v-btn variant="outlined" density="compact" prepend-icon="mdi-download" @click="exportCsv" :disabled="!rows.length">Export</v-btn>
        <v-btn color="primary" prepend-icon="mdi-plus" @click="openCreate = true">New Tenant</v-btn>
      </div>
    </div>

    <!-- KPI cards -->
    <div class="d-flex ga-3 flex-wrap">
      <StatCard label="Total Tenants" :value="String(kpis.total)" icon="mdi-domain-multiple" iconBg="#eef2ff" iconColor="primary" :trend="kpis.new30 ? 100 : null" :subtitle="`${kpis.new30} new in 30d`" />
      <StatCard label="Active" :value="String(kpis.active)" icon="mdi-check-circle" iconBg="#dcfce7" iconColor="success" />
      <StatCard label="Suspended" :value="String(kpis.suspended)" icon="mdi-pause-circle" iconBg="#fee2e2" iconColor="error" />
      <StatCard label="Total Requests" :value="fmtNum(kpis.totalRequests)" icon="mdi-api" iconBg="#fef3c7" iconColor="warning" />
      <StatCard label="Projected MRR" :value="fmtUsd(kpis.mrr)" icon="mdi-cash-multiple" iconBg="#e0e7ff" iconColor="indigo" />
    </div>

    <!-- Bulk action bar -->
    <Transition name="slide-y">
      <v-alert v-if="selected.length > 0" type="info" variant="tonal" density="compact" class="d-flex align-center ga-2 mb-0 py-2">
        <v-icon>mdi-checkbox-multiple-marked</v-icon>
        <span class="text-body-2 font-weight-medium">{{ selected.length }} selected</span>
        <v-spacer />
        <v-btn size="small" variant="text" color="success" prepend-icon="mdi-play-circle-outline" @click="bulkActivate">Activate</v-btn>
        <v-btn size="small" variant="text" color="error" prepend-icon="mdi-pause-circle-outline" @click="bulkSuspend">Suspend</v-btn>
        <v-btn size="small" variant="text" prepend-icon="mdi-close" @click="selected = []">Clear</v-btn>
      </v-alert>
    </Transition>

    <!-- Table -->
    <v-card elevation="0" border rounded="lg">
      <v-data-table-server
        v-model="selected"
        v-model:items-per-page="perPage"
        :items="rows"
        :items-length="total"
        :loading="loading"
        :headers="headers"
        :page="page"
        show-select
        item-value="id"
        @update:page="page = $event; load()"
        @update:items-per-page="perPage = $event; page = 1; load()"
        density="comfortable"
        hover
      >
        <template #item.short_name="{ item }">
          <NuxtLink :to="`/superadmin/tenants/${item.schema_name}`" class="text-decoration-none d-flex align-center ga-2">
            <v-avatar size="36" rounded color="grey-lighten-3">
              <v-img v-if="item.logo" :src="resolveMediaUrl(item.logo)" />
              <span v-else class="text-caption font-weight-bold text-indigo">{{ initials(item.short_name) }}</span>
            </v-avatar>
            <div>
              <p class="text-body-2 font-weight-medium text-on-surface mb-0">{{ item.short_name }}</p>
              <p class="text-caption text-medium-emphasis mb-0">{{ item.email }}</p>
            </div>
          </NuxtLink>
        </template>
        <template #item.country="{ item }">
          <span v-if="item.country" class="text-body-2">{{ flagEmoji(countryCode(item.country)) }} {{ item.country }}</span>
          <span v-else class="text-caption text-medium-emphasis">—</span>
        </template>
        <template #item.is_active="{ item }">
          <v-chip size="small" :color="item.is_active ? 'success' : 'error'" variant="flat">{{ item.is_active ? 'Active' : 'Suspended' }}</v-chip>
        </template>
        <template #item.subscription_status="{ item }">
          <v-chip size="small" :color="subStatusColor(item.subscription_status)" variant="tonal">{{ item.subscription_status }}</v-chip>
        </template>
        <template #item.request_count="{ item }">{{ fmtNum(item.request_count) }}</template>
        <template #item.current_cost_usd="{ item }">{{ fmtUsd(item.current_cost_usd) }}</template>
        <template #item.user_count="{ item }">{{ fmtNum(item.user_count) }}</template>
        <template #item.currency="{ item }">
          <v-chip size="x-small" variant="tonal">{{ item.currency }}</v-chip>
        </template>
        <template #item.created_at="{ item }">{{ fmtDate(item.created_at) }}</template>
        <template #item.actions="{ item }">
          <div class="d-flex ga-1">
            <v-btn size="small" variant="text" icon="mdi-eye-outline" :to="`/superadmin/tenants/${item.schema_name}`" />
            <v-btn size="small" variant="text" icon="mdi-pencil-outline" @click="openEditDialog(item)" />
            <v-btn v-if="item.is_active" size="small" variant="text" color="error" icon="mdi-pause-circle-outline" @click="suspend(item)" />
            <v-btn v-else size="small" variant="text" color="success" icon="mdi-play-circle-outline" @click="activate(item)" />
            <v-btn size="small" variant="text" icon="mdi-login" @click="loginAs(item)" />
            <v-btn size="small" variant="text" color="error" icon="mdi-delete-outline" @click="confirmDelete(item)" />
          </div>
        </template>
      </v-data-table-server>
    </v-card>

    <!-- Create dialog — 2-step wizard -->
    <v-dialog v-model="openCreate" max-width="640" persistent>
      <v-card rounded="lg" elevation="12">
        <v-card-title class="text-h6 font-weight-bold d-flex align-center ga-2">
          <v-icon color="primary">mdi-domain-plus</v-icon>
          Create New Tenant
        </v-card-title>

        <v-stepper v-model="createStep" :items="['Tenant Info', 'Admin & Login']" flat color="primary" class="px-4 pt-2" edit-mode="inc" hide-actions>
          <template #default>
            <!-- Step 1: Tenant Info -->
            <div v-show="createStep === 1">
              <v-row dense class="pb-4">
                 <v-col cols="12" sm="6"><v-text-field v-model="form.short_name" label="Short Name" hint="Brand name (used in URL)" persistent-hint density="comfortable" /></v-col>
                 <v-col cols="12" sm="6"><v-text-field v-model="form.full_name" label="Full Legal Name" density="comfortable" /></v-col>
                 <v-col cols="12" sm="6"><v-text-field v-model="form.email" label="Billing Email" type="email" density="comfortable" /></v-col>
                 <v-col cols="12" sm="6"><CountrySelect v-model="form.country" label="Country" density="comfortable" /></v-col>
                 <v-col cols="12" sm="6"><PhoneInput v-model="form.mobile_number" :country-name="form.country" label="Mobile" density="comfortable" /></v-col>
                 <v-col cols="12" sm="6"><v-select v-model="form.currency" :items="currencyOpts" label="Default Currency" density="comfortable" /></v-col>
                 <v-col cols="12"><v-text-field v-model="form.address" label="Address" density="comfortable" /></v-col>
              </v-row>
            </div>

            <!-- Step 2: Admin Info & Password -->
            <div v-show="createStep === 2">
              <p class="text-body-2 text-medium-emphasis mb-3">This user will be the tenant's first admin and can sign in to the tenant dashboard.</p>
              <v-row dense class="pb-4">
                 <v-col cols="12" sm="6"><v-text-field v-model="form.admin_first_name" label="Admin First Name" density="comfortable" /></v-col>
                 <v-col cols="12" sm="6"><v-text-field v-model="form.admin_last_name" label="Admin Last Name" density="comfortable" /></v-col>
                 <v-col cols="12" sm="6"><v-text-field v-model="form.admin_email" label="Admin Email" type="email" prepend-inner-icon="mdi-email-outline" density="comfortable" /></v-col>
                 <v-col cols="12" sm="6"><v-text-field v-model="form.admin_password" :type="showAdminPass ? 'text' : 'password'" label="Admin Password" prepend-inner-icon="mdi-lock-outline" :append-inner-icon="showAdminPass ? 'mdi-eye-off' : 'mdi-eye'" @click:append-inner="showAdminPass = !showAdminPass" density="comfortable" hint="Min 8 characters" persistent-hint /></v-col>
              </v-row>
              <v-alert type="info" variant="tonal" density="comfortable" class="text-body-2 mb-0">
                A free-plan subscription will be created for this tenant automatically. The admin can sign in using their email and password on the login page.
              </v-alert>
            </div>
          </template>
        </v-stepper>

        <v-divider />

        <v-card-actions class="px-6 pb-5 pt-4">
          <v-btn variant="text" @click="closeCreate">Cancel</v-btn>
          <v-spacer />
          <v-btn v-if="createStep > 1" variant="tonal" prepend-icon="mdi-arrow-left" @click="createStep = 1">Back</v-btn>
          <v-btn v-if="createStep < 2" color="primary" append-icon="mdi-arrow-right" @click="createStep = 2" :disabled="!form.short_name">Next</v-btn>
          <v-btn v-if="createStep === 2" color="primary" prepend-icon="mdi-content-save" :loading="creating" @click="create" :disabled="!form.short_name">Create Tenant</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Edit dialog -->
    <v-dialog v-model="openEdit" max-width="600" persistent>
      <v-card rounded="lg" elevation="12">
        <v-card-title class="text-h6 font-weight-bold d-flex align-center ga-2">
          <v-icon color="primary">mdi-pencil</v-icon>
          Edit Tenant
        </v-card-title>
        <v-card-text>
          <v-row dense>
            <v-col cols="12" sm="6"><v-text-field v-model="editForm.short_name" label="Short Name" density="comfortable" /></v-col>
            <v-col cols="12" sm="6"><v-text-field v-model="editForm.full_name" label="Full Legal Name" density="comfortable" /></v-col>
            <v-col cols="12" sm="6"><v-text-field v-model="editForm.email" label="Billing Email" type="email" density="comfortable" /></v-col>
            <v-col cols="12" sm="6"><CountrySelect v-model="editForm.country" label="Country" density="comfortable" /></v-col>
            <v-col cols="12" sm="6"><PhoneInput v-model="editForm.mobile_number" :country-name="editForm.country" label="Mobile" density="comfortable" /></v-col>
            <v-col cols="12" sm="6"><v-select v-model="editForm.currency" :items="currencyOpts" label="Currency" density="comfortable" /></v-col>
            <v-col cols="12"><v-text-field v-model="editForm.address" label="Address" density="comfortable" /></v-col>
            <v-col cols="12"><v-switch v-model="editForm.is_active" label="Active" color="success" density="comfortable" hide-details /></v-col>
          </v-row>
        </v-card-text>
        <v-divider />
        <v-card-actions class="px-6 pb-5 pt-4">
          <v-btn variant="text" @click="openEdit = false">Cancel</v-btn>
          <v-spacer />
          <v-btn color="primary" prepend-icon="mdi-content-save" :loading="saving" @click="saveEdit">Save Changes</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'superadmin' })
const sa = useSuperAdmin()
const { $api, $swal } = useNuxtApp()
const { resolveMediaUrl } = useMediaUrl()
const { flagEmoji, findByName } = useCountries()

const search = ref('')
const filterStatus = ref<'active' | 'suspended' | ''>('')
const statusOpts = [
  { title: 'All', value: '' },
  { title: 'Active', value: 'true' },
  { title: 'Suspended', value: 'false' },
]
const page = ref(1)
const perPage = ref(25)
const total = ref(0)
const rows = ref<any[]>([])
const loading = ref(false)
const selected = ref<any[]>([])

const kpis = reactive({ total: 0, active: 0, suspended: 0, totalRequests: 0, mrr: 0, new30: 0 })

const headers = [
  { title: 'Tenant', key: 'short_name' },
  { title: 'Country', key: 'country', sortable: false },
  { title: 'Status', key: 'is_active' },
  { title: 'Sub', key: 'subscription_status' },
  { title: 'Users', key: 'user_count', align: 'end' as const },
  { title: 'Requests', key: 'request_count', align: 'end' as const },
  { title: 'Cost', key: 'current_cost_usd', align: 'end' as const },
  { title: 'Currency', key: 'currency' },
  { title: 'Created', key: 'created_at' },
  { title: '', key: 'actions', align: 'end' as const, sortable: false },
]

const currencyOpts = ['USD', 'EUR', 'GBP', 'KES', 'NGN', 'ZAR', 'AED', 'SAR', 'INR', 'CAD', 'AUD', 'JPY', 'CNY', 'BRL', 'GHS', 'TZS', 'UGX', 'RWF', 'ETB']

const openCreate = ref(false)
const createStep = ref(1)
const showAdminPass = ref(false)
const creating = ref(false)
const form = reactive<any>({
  short_name: '', full_name: '', email: '', country: '', mobile_number: '', currency: 'USD', address: '',
  admin_first_name: '', admin_last_name: '', admin_email: '', admin_password: '',
})

const openEdit = ref(false)
const saving = ref(false)
const editForm = reactive<any>({ id: null, short_name: '', full_name: '', email: '', country: '', mobile_number: '', currency: 'USD', address: '', is_active: true })

function closeCreate() {
  openCreate.value = false
  createStep.value = 1
  Object.assign(form, {
    short_name: '', full_name: '', email: '', country: '', mobile_number: '', currency: 'USD', address: '',
    admin_first_name: '', admin_last_name: '', admin_email: '', admin_password: '',
  })
}

function initials(name: string) { return (name?.[0] || '?').toUpperCase() }
function subStatusColor(s: string) { return { active: 'success', past_due: 'warning', cancelled: 'error', none: 'grey', trialing: 'info' }[s] || 'grey' }
function countryCode(name: string) { return findByName(name)?.code || '' }

async function loadKpis() {
  try {
    const d: any = await sa.dashboard()
    kpis.total = d.tenants?.total || 0
    kpis.active = d.tenants?.active || 0
    kpis.suspended = d.tenants?.suspended || 0
    kpis.new30 = d.tenants?.new_30d || 0
    kpis.totalRequests = d.billing?.total_requests || 0
    kpis.mrr = d.usage_30d?.total_requests ? d.tenants?.total * 1.15 : 0
    // More accurate MRR from revenue endpoint
    try {
      const rev: any = await sa.revenue()
      kpis.mrr = rev.mrr || 0
    } catch { /* fallback already set */ }
  } catch { /* silent */ }
}

async function load() {
  loading.value = true
  try {
    const params: any = { page: page.value, page_size: perPage.value }
    if (search.value) params.search = search.value
    if (filterStatus.value === 'true') params.is_active = true
    if (filterStatus.value === 'false') params.is_active = false
    const data: any = await sa.listTenants(params)
    rows.value = data.results || data
    total.value = data.count || rows.value.length
  } catch (e) { console.error(e) } finally { loading.value = false }
}

onMounted(() => { load(); loadKpis() })
watch(search, useDebounceFn(load, 400))
watch(filterStatus, () => { page.value = 1; load() })

async function create() {
  creating.value = true
  try {
    await $api('/superadmin/tenants/', { method: 'POST', body: form })
    $swal.fire({ icon: 'success', title: 'Tenant created', timer: 1800, toast: true, position: 'top-end' })
    closeCreate()
    load()
    loadKpis()
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Failed', text: e?.data?.detail || e?.data?.admin_email?.[0] || e?.message || 'Could not create tenant' })
  } finally { creating.value = false }
}

function openEditDialog(t: any) {
  Object.assign(editForm, {
    id: t.id,
    short_name: t.short_name || '',
    full_name: t.full_name || '',
    email: t.email || '',
    country: t.country || '',
    mobile_number: t.mobile_number || '',
    currency: t.currency || 'USD',
    address: t.address || '',
    is_active: t.is_active,
  })
  openEdit.value = true
}

async function saveEdit() {
  saving.value = true
  try {
    await $api(`/superadmin/tenants/${editForm.id}/`, { method: 'PATCH', body: {
      short_name: editForm.short_name, full_name: editForm.full_name, email: editForm.email,
      country: editForm.country, mobile_number: editForm.mobile_number, currency: editForm.currency,
      address: editForm.address, is_active: editForm.is_active,
    }})
    $swal.fire({ icon: 'success', title: 'Tenant updated', timer: 1800, toast: true, position: 'top-end' })
    openEdit.value = false
    load()
    loadKpis()
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Failed', text: e?.data?.detail || e?.message || 'Could not update tenant' })
  } finally { saving.value = false }
}

async function confirmDelete(t: any) {
  const res = await $swal.fire({
    icon: 'warning', title: `Delete ${t.short_name}?`,
    html: `<p>The tenant schema <code>${t.schema_name}</code>, its users, and all data will be permanently deleted.</p><p class="text-error font-weight-medium mt-2">This action cannot be undone.</p>`,
    showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#ef4444',
  })
  if (!res.isConfirmed) return
  try {
    await $api(`/superadmin/tenants/${t.id}/`, { method: 'DELETE' })
    $swal.fire({ icon: 'success', title: 'Tenant deleted', timer: 1800, toast: true, position: 'top-end' })
    load()
    loadKpis()
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Failed', text: e?.data?.detail || e?.message || 'Could not delete tenant' })
  }
}

async function suspend(t: any) {
  const res = await $swal.fire({ icon: 'warning', title: `Suspend ${t.short_name}?`, text: 'The tenant will immediately lose access.', showCancelButton: true, confirmButtonText: 'Suspend', confirmButtonColor: '#ef4444' })
  if (!res.isConfirmed) return
  await sa.suspendTenant(t.id)
  load()
  loadKpis()
  $swal.fire({ icon: 'info', title: 'Suspended', timer: 1500, toast: true, position: 'top-end' })
}

async function activate(t: any) {
  await sa.activateTenant(t.id)
  load()
  loadKpis()
  $swal.fire({ icon: 'success', title: 'Activated', timer: 1500, toast: true, position: 'top-end' })
}

async function bulkSuspend() {
  const res = await $swal.fire({ icon: 'warning', title: `Suspend ${selected.value.length} tenants?`, text: 'All selected tenants will immediately lose access.', showCancelButton: true, confirmButtonText: 'Suspend All', confirmButtonColor: '#ef4444' })
  if (!res.isConfirmed) return
  for (const t of selected.value) {
    try { await sa.suspendTenant(t.id) } catch (e) { /* continue */ }
  }
  selected.value = []
  load()
  loadKpis()
  $swal.fire({ icon: 'info', title: 'Bulk suspend complete', timer: 1800, toast: true, position: 'top-end' })
}

async function bulkActivate() {
  for (const t of selected.value) {
    try { await sa.activateTenant(t.id) } catch (e) { /* continue */ }
  }
  selected.value = []
  load()
  loadKpis()
  $swal.fire({ icon: 'success', title: 'Bulk activate complete', timer: 1800, toast: true, position: 'top-end' })
}

async function loginAs(t: any) {
  const res = await $swal.fire({ icon: 'question', title: `Login as ${t.short_name}?`, text: 'You will be signed in as the tenant admin in a new tab.', showCancelButton: true, confirmButtonText: 'Login As' })
  if (!res.isConfirmed) return
  const data = await sa.loginAsTenant(t.id)
  const auth = useAuthStore()
  auth.setSession({ access: data.access, refresh: data.refresh, user: data.user }, data.tenant_schema)
  window.open('/app', '_blank')
  $swal.fire({ icon: 'success', title: `Switched to ${data.tenant_name}`, timer: 1800, toast: true, position: 'top-end' })
  load()
}

function exportCsv() {
  const head = ['Tenant', 'Email', 'Country', 'Status', 'Subscription', 'Users', 'Requests', 'Cost', 'Currency', 'Created']
  const lines = rows.value.map((t: any) => [
    t.short_name, t.email, t.country,
    t.is_active ? 'Active' : 'Suspended',
    t.subscription_status, t.user_count, t.request_count,
    t.current_cost_usd, t.currency, fmtDate(t.created_at),
  ].map((c: any) => `"${String(c ?? '').replace(/"/g, '""')}"`).join(','))
  const csv = [head.join(','), ...lines].join('\n')
  const blob = new Blob([csv], { type: 'text/csv' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `tenants-${new Date().toISOString().slice(0, 10)}.csv`
  a.click()
  URL.revokeObjectURL(url)
  $swal.fire({ icon: 'success', title: 'Export complete', timer: 1500, toast: true, position: 'top-end' })
}
</script>
