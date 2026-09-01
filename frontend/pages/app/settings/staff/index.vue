<template>
  <div class="d-flex flex-column ga-6">
    <!-- Page header -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-3">
      <div class="d-flex align-center ga-3">
        <div class="staff-header-icon">
          <v-icon color="white" size="24">mdi-account-supervisor-outline</v-icon>
        </div>
        <div>
          <h2 class="text-h6 font-weight-bold mb-0">Staff Management</h2>
          <p class="text-caption text-medium-emphasis mb-0">Manage team members, roles, access, and account status</p>
        </div>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn
          variant="outlined"
          prepend-icon="mdi-shield-key"
          to="/app/settings/roles"
          size="small"
        >
          Roles
        </v-btn>
        <v-btn
          color="primary"
          prepend-icon="mdi-account-plus-outline"
          @click="openInviteUser"
          size="small"
          v-if="rbac.can('users', 'create')"
        >
          Invite Member
        </v-btn>
      </div>
    </div>

    <!-- ── KPI strip ─────────────────────────────────────────────────── -->
    <div class="d-flex ga-3 flex-wrap">
      <div
        v-for="kpi in kpis"
        :key="kpi.label"
        class="staff-kpi-card flex-1"
        :style="{ minWidth: '180px' }"
      >
        <div class="d-flex align-center ga-3">
          <div class="staff-kpi-icon" :style="{ background: kpi.bg, color: kpi.color }">
            <v-icon :icon="kpi.icon" size="20" />
          </div>
          <div>
            <p class="text-h6 font-weight-bold mb-0">{{ kpi.value }}</p>
            <p class="text-caption text-medium-emphasis mb-0">{{ kpi.label }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- ── Staff table ──────────────────────────────────────────────── -->
    <v-card elevation="0" border class="staff-card">
      <v-data-table
        :items="filteredUsers"
        :loading="loading"
        :headers="headers"
        item-value="id"
        hover
        density="comfortable"
        :items-per-page="-1"
        hide-default-footer
        :search="search"
      >
        <!-- Search field in header -->
        <template #top>
          <div class="d-flex align-center pa-4 pb-2 ga-3">
            <v-text-field
              v-model="search"
              name="staff-search-field"
              autocomplete="off"
              prepend-inner-icon="mdi-magnify"
              placeholder="Search staff by name or email..."
              variant="outlined"
              density="compact"
              hide-details
              class="flex-1"
              style="max-width: 400px"
            />
            <v-select
              v-model="roleFilter"
              :items="roleFilterOptions"
              item-title="label"
              item-value="value"
              placeholder="All Roles"
              variant="outlined"
              density="compact"
              hide-details
              clearable
              style="max-width: 200px"
            />
            <v-select
              v-model="statusFilter"
              :items="[{ label: 'Active', value: 'true' }, { label: 'Inactive', value: 'false' }]"
              item-title="label"
              item-value="value"
              placeholder="All Status"
              variant="outlined"
              density="compact"
              hide-details
              clearable
              style="max-width: 160px"
            />
            <v-btn variant="text" prepend-icon="mdi-refresh" size="small" @click="loadUsers">Refresh</v-btn>
          </div>
        </template>

        <!-- User avatar + name -->
        <template #item.full_name="{ item }">
          <div class="d-flex align-center ga-3 py-2">
            <div class="staff-avatar" :style="{ background: avatarGradient(item) }">
              <span class="text-white text-body-2 font-weight-bold">{{ initials(item) }}</span>
            </div>
            <div>
              <p class="text-body-1 font-weight-medium mb-0">
                {{ item.full_name }}
                <v-icon
                  v-if="item.id === auth.user?.id"
                  size="16"
                  color="primary"
                  class="ml-1"
                  title="This is you"
                >mdi-account-circle</v-icon>
              </p>
              <p class="text-caption text-medium-emphasis mb-0">{{ item.email }}</p>
            </div>
          </div>
        </template>

        <!-- Role chips -->
        <template #item.role="{ item }">
          <v-chip
            :color="roleColor(item.role)"
            size="small"
            variant="tonal"
            label
            class="text-capitalize"
          >
            <v-icon start size="14">{{ roleIcon(item.role) }}</v-icon>
            {{ roleLabel(item.role) }}
          </v-chip>
        </template>

        <!-- Status -->
        <template #item.is_active="{ item }">
          <v-chip :color="item.is_active ? 'success' : 'grey'" size="small" variant="tonal" label>
            {{ item.is_active ? 'Active' : 'Inactive' }}
          </v-chip>
        </template>

        <!-- Date joined -->
        <template #item.date_joined="{ item }">
          <span class="text-caption text-medium-emphasis">{{ formatDate(item.date_joined) }}</span>
        </template>

        <!-- Phone -->
        <template #item.phone="{ item }">
          <span class="text-body-2 text-medium-emphasis">{{ item.phone || '—' }}</span>
        </template>

        <!-- Actions -->
        <template #item.actions="{ item }">
          <div class="d-flex align-center ga-1">
            <v-tooltip text="Assign role" location="top">
              <template #activator="{ props }">
                <v-btn
                  v-bind="props"
                  icon="mdi-shield-account-outline"
                  size="x-small"
                  variant="text"
                  color="primary"
                  @click="openAssignRole(item)"
                  v-if="rbac.can('users', 'assign')"
                />
              </template>
            </v-tooltip>
            <v-tooltip text="Edit profile" location="top">
              <template #activator="{ props }">
                <v-btn
                  v-bind="props"
                  icon="mdi-pencil-outline"
                  size="x-small"
                  variant="text"
                  color="info"
                  @click="openEditUser(item)"
                  v-if="rbac.can('users', 'update')"
                />
              </template>
            </v-tooltip>
            <v-tooltip text="Reset password" location="top">
              <template #activator="{ props }">
                <v-btn
                  v-bind="props"
                  icon="mdi-lock-reset"
                  size="x-small"
                  variant="text"
                  color="warning"
                  @click="openResetPassword(item)"
                  v-if="rbac.can('users', 'update')"
                />
              </template>
            </v-tooltip>
            <v-tooltip :text="item.is_active ? 'Deactivate' : 'Activate'" location="top">
              <template #activator="{ props }">
                <v-btn
                  v-bind="props"
                  :icon="item.is_active ? 'mdi-account-cancel-outline' : 'mdi-account-check-outline'"
                  size="x-small"
                  variant="text"
                  :color="item.is_active ? 'error' : 'success'"
                  @click="toggleActive(item)"
                  v-if="rbac.can('users', 'delete') && item.id !== auth.user?.id"
                />
              </template>
            </v-tooltip>
          </div>
        </template>

        <template #no-data>
          <div class="text-center py-12">
            <v-icon size="48" color="grey-lighten-1">mdi-account-group-outline</v-icon>
            <p class="text-body-1 font-weight-medium mt-2 text-medium-emphasis">No staff members found</p>
          </div>
        </template>
      </v-data-table>
    </v-card>

    <!-- ── Invite / Edit user dialog ──────────────────────────────────── -->
    <v-dialog v-model="userDialogOpen" max-width="560px">
      <v-card rounded="xl" elevation="0" border>
        <AppModalHeader
          :icon="editingUser ? 'mdi-account-edit-outline' : 'mdi-account-plus-outline'"
          :title="editingUser ? 'Edit Staff Member' : 'Invite New Member'"
          color="primary"
        />
        <v-card-text class="pa-6">
          <!-- Decoy fields to absorb browser autofill so it doesn't pollute the real fields -->
          <input type="text" name="fake-username" autocomplete="username" style="display:none" aria-hidden="true" />
          <input type="password" name="fake-password" autocomplete="current-password" style="display:none" aria-hidden="true" />
          <v-row dense>
            <v-col cols="6">
              <v-text-field v-model="userForm.first_name" label="First Name" variant="outlined" density="comfortable" />
            </v-col>
            <v-col cols="6">
              <v-text-field v-model="userForm.last_name" label="Last Name" variant="outlined" density="comfortable" />
            </v-col>
            <v-col cols="12">
              <v-text-field v-model="userForm.email" label="Email" variant="outlined" density="comfortable" :disabled="!!editingUser" />
            </v-col>
            <v-col cols="12">
              <PhoneInput v-model="userForm.phone" :country-name="tenantState?.country || ''" label="Phone" variant="outlined" density="comfortable" />
            </v-col>
            <v-col cols="12" v-if="!editingUser">
              <v-text-field
              v-model="userForm.password"
              name="new-user-password"
              autocomplete="new-password"
              label="Temporary Password"
              variant="outlined"
              density="comfortable"
              :type="showUserPassword ? 'text' : 'password'"
              hint="User will be asked to change this on first login"
              persistent-hint
              :append-inner-icon="showUserPassword ? 'mdi-eye-off' : 'mdi-eye'"
              @click:append-inner="showUserPassword = !showUserPassword"
            />
            </v-col>
            <v-col cols="12" v-if="!editingUser">
              <v-select
                v-model="userForm.role"
                :items="systemRoleOptions"
                item-title="label"
                item-value="value"
                label="Assign Role"
                variant="outlined"
                density="comfortable"
                hint="Determines the user's access level"
                persistent-hint
              />
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="pa-4 pt-0">
          <v-spacer />
          <v-btn variant="text" @click="userDialogOpen = false">Cancel</v-btn>
          <v-btn color="primary" prepend-icon="mdi-check" :loading="savingUser" @click="saveUser">
            {{ editingUser ? 'Save Changes' : 'Invite Member' }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- ── Assign role dialog ────────────────────────────────────────── -->
    <v-dialog v-model="assignDialogOpen" max-width="520px">
      <v-card rounded="xl" elevation="0" border>
        <AppModalHeader icon="mdi-shield-account-outline" title="Assign Role" color="primary" />
        <v-card-text class="pa-6">
          <div class="d-flex align-center ga-3 mb-4">
            <div class="staff-avatar" style="width: 48px; height: 48px" :style="{ background: avatarGradient(assigningUser) }">
              <span class="text-white text-body-1 font-weight-bold">{{ initials(assigningUser) }}</span>
            </div>
            <div>
              <p class="text-body-1 font-weight-medium mb-0">{{ assigningUser?.full_name }}</p>
              <p class="text-caption text-medium-emphasis mb-0">{{ assigningUser?.email }}</p>
            </div>
          </div>

          <v-select
            v-model="selectedRoleKey"
            :items="roleSelectOptions"
            item-title="label"
            item-value="value"
            label="Select Role"
            variant="outlined"
            density="comfortable"
            class="mb-3"
          >
            <template #item="{ props, item }">
              <v-list-item v-bind="props">
                <template #prepend>
                  <div class="staff-role-avatar-sm" :style="{ background: roleChipBg(item.raw.color) }">
                    <v-icon :icon="item.raw.icon" size="16" />
                  </div>
                </template>
                <template #title>
                  <span class="text-body-2 font-weight-medium">{{ item.raw.label }}</span>
                </template>
              </v-list-item>
            </template>
          </v-select>

          <p class="text-caption text-medium-emphasis">
            The role determines the user's access level across the platform.
          </p>
        </v-card-text>
        <v-card-actions class="pa-4 pt-0">
          <v-spacer />
          <v-btn variant="text" @click="assignDialogOpen = false">Cancel</v-btn>
          <v-btn color="primary" prepend-icon="mdi-check" :loading="assigning" @click="doAssignRole">Assign Role</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- ── Reset password dialog ──────────────────────────────────────── -->
    <v-dialog v-model="resetDialogOpen" max-width="480px">
      <v-card rounded="xl" elevation="0" border>
        <AppModalHeader icon="mdi-lock-reset" :title="`Reset Password — ${resettingUser?.full_name || ''}`" color="warning" />
        <v-card-text class="pa-6">
          <p class="text-body-2 text-medium-emphasis mb-4">
            Set a new temporary password for <strong>{{ resettingUser?.full_name }}</strong>. The user should change it after their next login.
          </p>
          <!-- Decoy fields to absorb browser autofill -->
          <input type="text" name="reset-fake-username" autocomplete="username" style="display:none" aria-hidden="true" />
          <input type="password" name="reset-fake-password2" autocomplete="current-password" style="display:none" aria-hidden="true" />
          <v-text-field
            v-model="resetForm.password"
            name="reset-password-field"
            autocomplete="new-password"
            label="New Password"
            variant="outlined"
            density="comfortable"
            :type="showResetPassword ? 'text' : 'password'"
            min-length="8"
            hint="Minimum 8 characters"
            persistent-hint
            :error-messages="resetError"
            :append-inner-icon="showResetPassword ? 'mdi-eye-off' : 'mdi-eye'"
            @click:append-inner="showResetPassword = !showResetPassword"
          />
        </v-card-text>
        <v-card-actions class="pa-4 pt-0">
          <v-spacer />
          <v-btn variant="text" @click="resetDialogOpen = false">Cancel</v-btn>
          <v-btn color="warning" prepend-icon="mdi-lock-reset" :loading="resetting" @click="doResetPassword">Reset Password</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  layout: 'default',
  permission: 'users:view',
})

const { $api, $swal } = useNuxtApp()
const auth = useAuthStore()
const rbac = useRbac()
const { load: loadTenant, displayName: tenantDisplayName, tenant: tenantState } = useTenant()

// ── Data state ────────────────────────────────────────────────────────
const users = ref<any[]>([])
const roles = ref<any[]>([])
const loading = ref(false)
const search = ref('')
const roleFilter = ref<string | null>(null)
const statusFilter = ref<string | null>(null)

// ── Dialog state ──────────────────────────────────────────────────────
const userDialogOpen = ref(false)
const editingUser = ref<any>(null)
const userForm = reactive<any>({
  first_name: '',
  last_name: '',
  email: '',
  phone: '',
  password: '',
  role: 'driver',
})
const savingUser = ref(false)

const assignDialogOpen = ref(false)
const assigningUser = ref<any>(null)
const selectedRoleKey = ref<string | null>(null)
const assigning = ref(false)

const resetDialogOpen = ref(false)
const resettingUser = ref<any>(null)
const resetForm = reactive({ password: '' })
const resetError = ref('')
const resetting = ref(false)

// Password reveal toggles
const showUserPassword = ref(false)
const showResetPassword = ref(false)

// ── Table headers ──────────────────────────────────────────────────────
const headers = [
  { title: 'Member', key: 'full_name', sortable: true, width: '28%' },
  { title: 'Role', key: 'role', sortable: true, width: '15%' },
  { title: 'Phone', key: 'phone', sortable: false, width: '15%' },
  { title: 'Status', key: 'is_active', sortable: true, width: '10%' },
  { title: 'Joined', key: 'date_joined', sortable: true, width: '14%' },
  { title: '', key: 'actions', sortable: false, width: '18%', align: 'end' as const },
]

// ── Role display ──────────────────────────────────────────────────────
const SYSTEM_ROLES = [
  { value: 'admin', label: 'Administrator', color: '#ef4444', icon: 'mdi-shield-crown' },
  { value: 'manager', label: 'Fleet Manager', color: '#6366f1', icon: 'mdi-shield-account' },
  { value: 'dispatcher', label: 'Dispatcher', color: '#3b82f6', icon: 'mdi-map-marker-radius' },
  { value: 'mechanic', label: 'Mechanic', color: '#f59e0b', icon: 'mdi-wrench' },
  { value: 'driver', label: 'Driver', color: '#22c55e', icon: 'mdi-steering' },
]

const systemRoleOptions = SYSTEM_ROLES.map(r => ({ value: r.value, label: r.label }))

const roleSelectOptions = computed(() => {
  // Merge system roles with any custom roles fetched from the backend
  const custom = roles.value
    .filter(r => !SYSTEM_ROLES.some(sr => sr.value === r.key))
    .map(r => ({ value: r.key, label: r.name, color: r.color, icon: r.icon }))
  return [...SYSTEM_ROLES.map(r => ({ value: r.value, label: r.label, color: r.color, icon: r.icon })), ...custom]
})

const roleFilterOptions = computed(() => [
  { value: 'admin', label: 'Administrator' },
  { value: 'manager', label: 'Fleet Manager' },
  { value: 'dispatcher', label: 'Dispatcher' },
  { value: 'mechanic', label: 'Mechanic' },
  { value: 'driver', label: 'Driver' },
])

function roleLabel(key: string): string {
  return SYSTEM_ROLES.find(r => r.value === key)?.label || (key && key.charAt(0).toUpperCase() + key.slice(1)) || '—'
}
function roleColor(key: string): string {
  return SYSTEM_ROLES.find(r => r.value === key)?.color || '#6366f1'
}
function roleIcon(key: string): string {
  return SYSTEM_ROLES.find(r => r.value === key)?.icon || 'mdi-shield-account'
}
function roleChipBg(color: string): string {
  if (!color) return 'rgba(99, 102, 241, 0.12)'
  if (color.startsWith('#')) {
    const hex = color.replace('#', '')
    const r = parseInt(hex.substring(0, 2), 16)
    const g = parseInt(hex.substring(2, 4), 16)
    const b = parseInt(hex.substring(4, 6), 16)
    return `rgba(${r}, ${g}, ${b}, 0.15)`
  }
  return `var(--v-theme-${color})`
}

// ── Computed KPIs ──────────────────────────────────────────────────────
const kpis = computed(() => [
  { label: 'Total Staff', value: users.value.length, icon: 'mdi-account-group', color: '#6366f1', bg: 'rgba(99, 102, 241, 0.12)' },
  { label: 'Active', value: users.value.filter(u => u.is_active).length, icon: 'mdi-account-check', color: '#22c55e', bg: 'rgba(34, 197, 94, 0.12)' },
  { label: 'Inactive', value: users.value.filter(u => !u.is_active).length, icon: 'mdi-account-off', color: '#6b7280', bg: 'rgba(107, 114, 128, 0.12)' },
  { label: 'Administrators', value: users.value.filter(u => u.role === 'admin').length, icon: 'mdi-shield-crown', color: '#ef4444', bg: 'rgba(239, 68, 68, 0.12)' },
])

// ── Filtered list (role + status filters) ─────────────────────────────
const filteredUsers = computed(() => {
  return users.value.filter((u) => {
    if (roleFilter.value && u.role !== roleFilter.value) return false
    if (statusFilter.value === 'true' && !u.is_active) return false
    if (statusFilter.value === 'false' && u.is_active) return false
    return true
  })
})

// ── Data loading ──────────────────────────────────────────────────────
async function loadUsers() {
  loading.value = true
  try {
    // Try RBAC-enriched user endpoint first (includes roles)
    try {
      const enriched = await rbac.fetchUsers() as any[]
      if (enriched && enriched.length > 0) {
        users.value = enriched
      } else {
        const data = await rbac.fetchUsersList() as any[]
        users.value = data
      }
    } catch {
      const data = await rbac.fetchUsersList() as any[]
      users.value = data
    }
  } catch (e) {
    console.error('Failed to load staff:', e)
    users.value = []
  } finally {
    loading.value = false
  }
}

async function loadRoles() {
  try {
    const data = await rbac.fetchRoles() as any[]
    roles.value = data
  } catch (e) {
    console.error('Failed to load roles:', e)
    roles.value = []
  }
}

// ── User CRUD ─────────────────────────────────────────────────────────
function openInviteUser() {
  editingUser.value = null
  userForm.first_name = ''
  userForm.last_name = ''
  userForm.email = ''
  userForm.phone = ''
  userForm.password = ''
  userForm.role = 'driver'
  userDialogOpen.value = true
}

function openEditUser(user: any) {
  editingUser.value = user
  userForm.first_name = user.first_name || ''
  userForm.last_name = user.last_name || ''
  userForm.email = user.email || ''
  userForm.phone = user.phone || ''
  userDialogOpen.value = true
}

async function saveUser() {
  savingUser.value = true
  try {
    if (editingUser.value) {
      await rbac.updateUser(editingUser.value.id, {
        first_name: userForm.first_name,
        last_name: userForm.last_name,
        phone: userForm.phone,
      })
      $swal.fire({ icon: 'success', title: 'Saved', text: 'Staff member updated successfully.', timer: 2000, toast: true, position: 'top-end' })
    } else {
      await rbac.createUser({
        email: userForm.email,
        first_name: userForm.first_name,
        last_name: userForm.last_name,
        role: userForm.role,
        phone: userForm.phone,
        password: userForm.password,
      })
      $swal.fire({ icon: 'success', title: 'Member Invited', text: 'Staff member has been added successfully.', timer: 2000, toast: true, position: 'top-end' })
    }
    userDialogOpen.value = false
    await loadUsers()
  } catch (e: any) {
    const msg = e?.data?.detail || e?.data?.email?.[0] || 'Could not save staff member.'
    $swal.fire({ icon: 'error', title: 'Save Failed', text: msg })
  } finally {
    savingUser.value = false
  }
}

async function toggleActive(user: any) {
  const action = user.is_active ? 'deactivate' : 'activate'
  $swal.fire({
    icon: 'question',
    title: `${action.charAt(0).toUpperCase() + action.slice(1)} member?`,
    text: `Are you sure you want to ${action} ${user.full_name}?`,
    showCancelButton: true,
    confirmButtonText: action.charAt(0).toUpperCase() + action.slice(1),
    cancelButtonText: 'Cancel',
  }).then(async (result: any) => {
    if (result.isConfirmed) {
      try {
        await rbac.toggleUserActive(user.id)
        $swal.fire({ icon: 'success', title: 'Done', text: `Staff member ${action}d.`, timer: 2000, toast: true, position: 'top-end' })
        await loadUsers()
      } catch (e: any) {
        $swal.fire({ icon: 'error', title: 'Action Failed', text: e?.data?.detail || 'Could not update status.' })
      }
    }
  })
}

// ── Role assignment ───────────────────────────────────────────────────
function openAssignRole(user: any) {
  assigningUser.value = user
  selectedRoleKey.value = user.role || null
  assignDialogOpen.value = true
}

async function doAssignRole() {
  if (!selectedRoleKey.value || !assigningUser.value) return
  assigning.value = true
  try {
    // Find the role ID from roles list
    const role = roles.value.find((r: any) => r.key === selectedRoleKey.value)
    if (role && role.id) {
      await rbac.assignRole(assigningUser.value.id, role.id, true)
    } else {
      // Fallback: update the legacy role field via user endpoint
      await rbac.updateUser(assigningUser.value.id, { role: selectedRoleKey.value })
    }
    $swal.fire({ icon: 'success', title: 'Role Assigned', text: 'Role has been assigned successfully.', timer: 2000, toast: true, position: 'top-end' })
    assignDialogOpen.value = false
    await loadUsers()
    if (assigningUser.value.id === auth.user?.id) {
      await rbac.refreshMyPermissions()
    }
  } catch (e: any) {
    const msg = e?.data?.detail || 'Could not assign role.'
    $swal.fire({ icon: 'error', title: 'Assignment Failed', text: msg })
  } finally {
    assigning.value = false
  }
}

// ── Password reset ───────────────────────────────────────────────────
function openResetPassword(user: any) {
  resettingUser.value = user
  resetForm.password = ''
  resetError.value = ''
  resetDialogOpen.value = true
}

async function doResetPassword() {
  if (!resettingUser.value) return
  resetError.value = ''
  if (!resetForm.password || resetForm.password.length < 8) {
    resetError.value = 'Password must be at least 8 characters.'
    return
  }
  resetting.value = true
  try {
    await rbac.resetUserPassword(resettingUser.value.id, resetForm.password)
    $swal.fire({ icon: 'success', title: 'Password Reset', text: 'Password has been updated successfully.', timer: 2000, toast: true, position: 'top-end' })
    resetDialogOpen.value = false
  } catch (e: any) {
    const msg = e?.data?.detail || 'Could not reset password.'
    $swal.fire({ icon: 'error', title: 'Reset Failed', text: msg })
  } finally {
    resetting.value = false
  }
}

// ── Helpers ───────────────────────────────────────────────────────────
function avatarGradient(user: any): string {
  if (!user) return 'linear-gradient(135deg, #6366f1, #4f46e5)'
  const hue = (user.id || 0) * 47 % 360
  return `linear-gradient(135deg, hsl(${hue}, 65%, 55%), hsl(${(hue + 40) % 360}, 65%, 45%))`
}
function initials(user: any): string {
  if (!user) return '?'
  return ((user.first_name?.[0] || '') + (user.last_name?.[0] || '')).toUpperCase() || '?'
}
function formatDate(d: string): string {
  if (!d) return '—'
  return new Date(d).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' })
}

// ── Init ──────────────────────────────────────────────────────────────
onMounted(async () => {
  await rbac.loadMyPermissions()
  await Promise.all([loadUsers(), loadRoles()])
})
</script>

<style scoped>
.staff-header-icon {
  width: 48px;
  height: 48px;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #6366f1 0%, #4f46e5 100%);
  box-shadow: 0 4px 12px rgba(99, 102, 241, 0.35);
}

.staff-kpi-card {
  background: rgb(var(--v-theme-surface));
  border: 1px solid rgba(var(--v-theme-on-surface), 0.08);
  border-radius: 14px;
  padding: 16px 20px;
  transition: all 0.2s ease;
}
.staff-kpi-card:hover {
  border-color: rgba(99, 102, 241, 0.2);
  box-shadow: 0 4px 20px rgba(var(--v-theme-on-surface), 0.06);
}
.staff-kpi-icon {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.staff-card {
  border-radius: 14px;
  overflow: hidden;
}
.staff-card :deep(.v-data-table) {
  border-radius: 14px;
}
.staff-card :deep(.v-data-table-header) {
  background: rgba(var(--v-theme-on-surface), 0.02);
  font-weight: 600;
  font-size: 12px;
  letter-spacing: 0.5px;
  text-transform: uppercase;
  color: rgba(var(--v-theme-on-surface), 0.5);
}

.staff-avatar {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.staff-role-avatar-sm {
  width: 32px;
  height: 32px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
</style>
