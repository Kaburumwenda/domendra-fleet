<template>
  <div class="d-flex flex-column ga-4">
    <div class="d-flex align-center ga-3 flex-wrap">
      <v-btn variant="text" prepend-icon="mdi-arrow-left" to="/superadmin/tenants">Tenants</v-btn>
      <v-divider vertical />
      <v-avatar rounded color="indigo-lighten-5" size="40"><span class="text-h6 font-weight-bold text-indigo">{{ commission }}</span></v-avatar>
      <div>
        <h1 class="text-h6 font-weight-bold">{{ tenant?.short_name || '...' }}</h1>
        <p class="text-caption text-medium-emphasis mb-0">{{ schema }}</p>
      </div>
      <v-spacer />
      <div class="d-flex align-center ga-2">
        <v-btn variant="tonal" prepend-icon="mdi-login" @click="loginAs">Login As</v-btn>
        <v-btn v-if="tenant?.is_active" color="error" variant="outlined" prepend-icon="mdi-pause" @click="suspend">Suspend</v-btn>
        <v-btn v-else color="success" variant="outlined" prepend-icon="mdi-play" @click="activate">Activate</v-btn>
      </div>
    </div>

    <v-row dense>
      <v-col cols="12" sm="6" md="2"><StatCard label="Users" :value="fmtNum(stats?.users)" icon="mdi-account-group" icon-bg="#eef2ff" icon-color="primary" /></v-col>
      <v-col cols="12" sm="6" md="2"><StatCard label="Vehicles" :value="fmtNum(stats?.vehicles)" icon="mdi-car-multiple" icon-bg="#dcfce7" icon-color="success" /></v-col>
      <v-col cols="12" sm="6" md="2"><StatCard label="Equipment" :value="fmtNum(stats?.equipment)" icon="mdi-tools" icon-bg="#fef3c7" icon-color="warning" /></v-col>
      <v-col cols="12" sm="6" md="2"><StatCard label="Open Issues" :value="fmtNum(stats?.issues)" icon="mdi-alert" icon-bg="#fee2e2" icon-color="error" /></v-col>
      <v-col cols="12" sm="6" md="2"><StatCard label="Requests" :value="fmtNum(sub?.request_count)" icon="mdi-api" icon-bg="#eff6ff" icon-color="info" /></v-col>
      <v-col cols="12" sm="6" md="2"><StatCard label="Cost (USD)" :value="fmtUsd(sub?.estimated_cost_usd)" icon="mdi-cash" icon-bg="#f0fdf4" icon-color="success" /></v-col>
    </v-row>

    <v-card elevation="0" border rounded="lg" class="pa-5">
      <div class="d-flex align-center ga-2 mb-3">
        <v-icon color="primary" size="small">mdi-chart-areaspline</v-icon>
        <h3 class="text-subtitle-1 font-weight-bold">Usage ({{ days }}d)</h3>
        <v-spacer />
        <v-btn-toggle v-model="days" density="compact" color="primary" mandatory @update:model-value="loadUsage">
          <v-btn :value="7">7d</v-btn>
          <v-btn :value="30">30d</v-btn>
          <v-btn :value="90">90d</v-btn>
        </v-btn-toggle>
      </div>
      <DashboardChart :option="usageOption" height="280px" />
    </v-card>

    <v-row dense>
      <v-col cols="12" md="6">
        <v-card elevation="0" border rounded="lg" class="pa-5 h-100">
          <h3 class="text-subtitle-1 font-weight-bold mb-3">Organization</h3>
          <v-row dense>
            <v-col cols="6"><v-text-field v-model="tenant.short_name" label="Short Name" /></v-col>
            <v-col cols="6"><v-text-field v-model="tenant.full_name" label="Full Name" /></v-col>
            <v-col cols="6"><v-text-field v-model="tenant.email" label="Email" /></v-col>
            <v-col cols="6"><CountrySelect v-model="tenant.country" label="Country" /></v-col>
            <v-col cols="6"><v-text-field v-model="tenant.mobile_number" label="Mobile" /></v-col>
            <v-col cols="6"><v-select v-model="tenant.currency" :items="currencyOpts" label="Currency" /></v-col>
            <v-col cols="12"><v-text-field v-model="tenant.address" label="Address" /></v-col>
          </v-row>
          <div class="d-flex justify-end mt-3">
            <v-btn color="primary" variant="text" prepend-icon="mdi-content-save" :loading="savingTenant" @click="saveTenant">Save</v-btn>
          </div>
          <v-divider class="my-4" />
          <h3 class="text-subtitle-1 font-weight-bold mb-3">Billing Settings</h3>
          <v-row dense>
            <v-col cols="6"><v-text-field v-model="toggles.billing_email" label="Billing Email" /></v-col>
            <v-col cols="6"><v-select v-model="toggles.billing_currency" :items="currencyOpts" label="Billing Currency" /></v-col>
            <v-col cols="6"><v-text-field v-model.number="toggles.cycle_day" type="number" min="1" max="28" label="Cycle Day" /></v-col>
            <v-col cols="6" class="d-flex align-center"><v-switch v-model="toggles.auto_close" color="primary" label="Auto-close overdue bills" /></v-col>
          </v-row>
          <div class="d-flex justify-end mt-2">
            <v-btn color="primary" variant="text" prepend-icon="mdi-content-save" :loading="savingToggles" @click="saveToggles">Save Billing</v-btn>
          </div>
        </v-card>
      </v-col>
      <v-col cols="12" md="6">
        <v-card elevation="0" border rounded="lg" class="pa-5 h-100">
          <div class="d-flex align-center ga-2 mb-3">
            <h3 class="text-subtitle-1 font-weight-bold">Users in Tenant</h3>
            <v-spacer />
            <v-btn size="small" variant="text" prepend-icon="mdi-plus" @click="openUser = true">Add</v-btn>
          </div>
          <v-table density="comfortable">
            <thead>
              <tr><th>Name</th><th>Email</th><th>Role</th><th class="text-center">Active</th><th></th></tr>
            </thead>
            <tbody>
              <tr v-for="u in users" :key="u.id">
                <td class="font-weight-medium">{{ u.full_name }}</td>
                <td class="text-body-2">{{ u.email }}</td>
                <td><v-chip size="x-small" variant="flat" :color="roleColor(u.role)">{{ u.role }}</v-chip></td>
                <td class="text-center"><v-icon :color="u.is_active ? 'success' : 'grey'" size="small">{{ u.is_active ? 'mdi-check-circle' : 'mdi-circle-outline' }}</v-icon></td>
                <td class="text-end">
                  <v-btn size="small" variant="text" icon="mdi-pencil-outline" @click="editUser(u)" />
                  <v-btn size="small" variant="text" icon="mdi-account-arrow-right" @click="loginAsUser(u)" />
                </td>
              </tr>
              <tr v-if="!users.length"><td colspan="5" class="text-center text-medium-emphasis py-4">No users</td></tr>
            </tbody>
          </v-table>
        </v-card>
      </v-col>
    </v-row>

    <v-card elevation="0" border rounded="lg" class="pa-5">
      <h3 class="text-subtitle-1 font-weight-bold mb-3">Top Endpoints</h3>
      <v-chip v-for="ep in topEndpoints" :key="ep.endpoint + ep.method" size="small" variant="tonal" color="primary" class="ma-1">
        <v-icon start size="x-small">{{ methodIcon(ep.method) }}</v-icon>
        {{ ep.endpoint }} · {{ fmtNum(ep.total) }}
      </v-chip>
      <div v-if="!topEndpoints.length" class="text-center text-medium-emphasis py-4">No endpoint data</div>
    </v-card>

    <!-- User dialog -->
    <v-dialog v-model="openUser" max-width="560">
      <v-card rounded="lg" elevation="12">
        <v-card-title class="text-h6 font-weight-bold">{{ editingUser ? 'Edit User' : 'Add User' }}</v-card-title>
        <v-card-text>
          <v-row dense>
            <v-col cols="6"><v-text-field v-model="userForm.first_name" label="First Name" /></v-col>
            <v-col cols="6"><v-text-field v-model="userForm.last_name" label="Last Name" /></v-col>
            <v-col cols="6"><v-text-field v-model="userForm.email" label="Email" :disabled="!!editingUser" /></v-col>
            <v-col cols="6"><v-select v-model="userForm.role" :items="['admin', 'manager', 'mechanic', 'driver', 'dispatcher']" label="Role" /></v-col>
            <v-col cols="6"><v-text-field v-model="userForm.phone" label="Phone" /></v-col>
            <v-col cols="6"><v-text-field v-model="userForm.password" label="Password" :hint="editingUser ? 'Leave blank to keep current' : ''" /></v-col>
            <v-col cols="6" class="d-flex align-center"><v-switch v-model="userForm.is_active" color="primary" label="Active" /></v-col>
            <v-col cols="6" class="d-flex align-center"><v-switch v-model="userForm.is_staff" color="primary" label="Staff" /></v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-6 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="openUser = false">Cancel</v-btn>
          <v-btn color="primary" :loading="savingUser" @click="saveUser">{{ editingUser ? 'Save' : 'Create' }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'superadmin' })
const route = useRoute()
const sa = useSuperAdmin()
const { $api, $swal } = useNuxtApp()
const schema = computed(() => String(route.params.schema))

const days = ref(30)
const stats = ref<any>({})
const sub = ref<any>(null)
const topEndpoints = ref<any[]>([])
const tenant = reactive<any>({ short_name: '', full_name: '', email: '', country: '', mobile_number: '', currency: 'USD', address: '' })
const toggles = reactive<any>({ is_active: true, auto_close: false, billing_email: '', billing_currency: 'USD', cycle_day: 1 })
const users = ref<any[]>([])

const savingTenant = ref(false)
const savingToggles = ref(false)

const usageOption = computed(() => ({
  tooltip: { trigger: 'axis' },
  legend: { top: 0, data: ['Requests', 'Errors', 'Response (ms)'] },
  grid: { left: 40, right: 40, top: 40, bottom: 30 },
  xAxis: { type: 'category', data: daily.value.map((d: any) => d.date.slice(5)) },
  yAxis: [
    { type: 'value', name: 'Count' },
    { type: 'value', name: 'ms', position: 'right' },
  ],
  series: [
    { name: 'Requests', type: 'bar', data: daily.value.map((d: any) => d.requests), itemStyle: { color: '#6366f1' } },
    { name: 'Errors', type: 'line', data: daily.value.map((d: any) => d.errors), itemStyle: { color: '#ef4444' } },
    { name: 'Response (ms)', type: 'line', yAxisIndex: 1, data: daily.value.map((d: any) => d.avg_response_ms), itemStyle: { color: '#22c55e' } },
  ],
}))
const daily = ref<any[]>([])

const currencyOpts = ['USD', 'EUR', 'GBP', 'KES', 'NGN', 'ZAR', 'AED', 'SAR', 'INR', 'CAD', 'AUD', 'JPY', 'CNY', 'BRL', 'GHS', 'TZS', 'UGX', 'RWF', 'ETB']

const commission = computed(() => (tenant.short_name || '?')[0]?.toUpperCase() || '?')

function roleColor(r: string) { return { admin: 'error', manager: 'warning', mechanic: 'info', driver: 'success', dispatcher: 'primary' }[r] || 'grey' }
function methodIcon(m: string) { return { GET: 'mdi-download', POST: 'mdi-upload', PATCH: 'mdi-pencil', PUT: 'mdi-update', DELETE: 'mdi-delete' }[m] || 'mdi-api' }

async function loadTenant() {
  const data: any = await $api('/superadmin/tenants/', { params: { search: schema.value } })
  const list = data.results || data
  const t = list.find((x: any) => x.schema_name === schema.value)
  if (!t) return
  Object.assign(tenant, t)
  // toggles
  const tg = await sa.tenantToggles(schema.value)
  Object.assign(toggles, tg)
  // stats
  try { stats.value = await sa.tenantStats(t.id) } catch {}
}

async function loadUsage() {
  const d = await sa.tenantUsage(schema.value, days.value)
  daily.value = d.daily || []
  topEndpoints.value = d.top_endpoints || []
  sub.value = d.subscription
}

async function loadUsers() {
  try { const data: any = await sa.tenantUsers(schema.value); users.value = data.results || data } catch {}
}

onMounted(async () => {
  await loadTenant()
  await Promise.all([loadUsage(), loadUsers()])
})

async function saveTenant() {
  savingTenant.value = true
  try {
    const data: any = await $api('/superadmin/tenants/', { params: { search: schema.value } })
    const list = data.results || data
    const t = list.find((x: any) => x.schema_name === schema.value)
    await $api(`/superadmin/tenants/${t.id}/`, { method: 'PATCH', body: { ...tenant } })
    $swal.fire({ icon: 'success', title: 'Saved', timer: 1500, toast: true, position: 'top-end' })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Failed', text: e?.data?.detail || 'Could not save tenant' })
  } finally { savingTenant.value = false }
}

async function saveToggles() {
  savingToggles.value = true
  try {
    const data = await sa.tenantToggles(schema.value, { ...toggles })
    Object.assign(toggles, data)
    $swal.fire({ icon: 'success', title: 'Billing settings saved', timer: 1500, toast: true, position: 'top-end' })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Failed', text: e?.data?.detail || 'Could not save' })
  } finally { savingToggles.value = false }
}

async function suspend() {
  await $swal.fire({ icon: 'warning', title: `Suspend ${tenant.short_name}?`, showCancelButton: true, confirmButtonText: 'Suspend', confirmButtonColor: '#ef4444' })
  const data: any = await $api('/superadmin/tenants/', { params: { search: schema.value } })
  const list = data.results || data
  const t = list.find((x: any) => x.schema_name === schema.value)
  await sa.suspendTenant(t.id)
  tenant.is_active = false
}
async function activate() {
  const data: any = await $api('/superadmin/tenants/', { params: { search: schema.value } })
  const list = data.results || data
  const t = list.find((x: any) => x.schema_name === schema.value)
  await sa.activateTenant(t.id)
  tenant.is_active = true
}
async function loginAs() {
  const data: any = await $api('/superadmin/tenants/', { params: { search: schema.value } })
  const list = data.results || data
  const t = list.find((x: any) => x.schema_name === schema.value)
  const res = await sa.loginAsTenant(t.id)
  const auth = useAuthStore()
  auth.setSession({ access: res.access, refresh: res.refresh, user: res.user }, res.tenant_schema)
  window.open('/app', '_blank')
}

// User CRUD
const openUser = ref(false)
const editingUser = ref<any>(null)
const savingUser = ref(false)
const userForm = reactive<any>({ first_name: '', last_name: '', email: '', role: 'driver', phone: '', password: '', is_active: true, is_staff: false })

function editUser(u: any) {
  editingUser.value = u
  Object.assign(userForm, { first_name: u.first_name, last_name: u.last_name, email: u.email, role: u.role, phone: u.phone, password: '', is_active: u.is_active, is_staff: u.is_staff })
  openUser.value = true
}

async function saveUser() {
  savingUser.value = true
  try {
    if (editingUser.value) {
      const body: any = { ...userForm }
      if (!body.password) delete body.password
      delete body.email
      await sa.patchTenantUser(schema.value, editingUser.value.id, body)
    } else {
      await sa.createTenantUser(schema.value, { ...userForm })
    }
    openUser.value = false
    editingUser.value = null
    await loadUsers()
    $swal.fire({ icon: 'success', title: 'User saved', timer: 1500, toast: true, position: 'top-end' })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Failed', text: e?.data?.detail || 'Could not save user' })
  } finally { savingUser.value = false }
}

async function loginAsUser(u: any) {
  const res = await $swal.fire({ icon: 'question', title: `Login as ${u.full_name}?`, text: 'You will be signed in as this user in a new tab.', showCancelButton: true, confirmButtonText: 'Login As' })
  if (!res.isConfirmed) return
  const data = await sa.loginAsTenantUser(schema.value, u.id)
  const auth = useAuthStore()
  auth.setSession({ access: data.access, refresh: data.refresh, user: data.user }, data.tenant_schema)
  window.open('/app', '_blank')
  $swal.fire({ icon: 'success', title: `Switched to ${data.tenant_name}`, timer: 1800, toast: true, position: 'top-end' })
}
</script>
