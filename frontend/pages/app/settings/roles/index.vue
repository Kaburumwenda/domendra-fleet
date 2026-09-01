<template>
  <div class="d-flex flex-column ga-6">
    <!-- Page header -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-3">
      <div class="d-flex align-center ga-3">
        <div class="rbac-header-icon">
          <v-icon color="white" size="24">mdi-shield-key-outline</v-icon>
        </div>
        <div>
          <h2 class="text-h6 font-weight-bold mb-0">Roles & Permissions</h2>
          <p class="text-caption text-medium-emphasis mb-0">Manage roles, define granular permissions, and control access across your fleet</p>
        </div>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn
          variant="outlined"
          prepend-icon="mdi-shield-account"
          @click="tab = 'users'"
          :class="{ 'rbac-tab-activator-active': tab === 'users' }"
          size="small"
          class="rbac-tab-activator"
        >
          Users
        </v-btn>
        <v-btn
          variant="outlined"
          prepend-icon="mdi-shield-key"
          @click="tab = 'roles'"
          :class="{ 'rbac-tab-activator-active': tab === 'roles' }"
          size="small"
          class="rbac-tab-activator"
        >
          Roles
        </v-btn>
        <v-btn
          color="primary"
          prepend-icon="mdi-plus"
          @click="openCreateRole"
          size="small"
          v-if="tab === 'roles' && rbac.isAdmin"
        >
          New Role
        </v-btn>
        <v-btn
          color="primary"
          prepend-icon="mdi-account-plus-outline"
          @click="openInviteUser"
          size="small"
          v-if="tab === 'users' && rbac.can('users', 'create')"
        >
          Invite User
        </v-btn>
      </div>
    </div>

    <!-- ── KPI strip ─────────────────────────────────────────────────── -->
    <div class="d-flex ga-3 flex-wrap">
      <div
        v-for="kpi in kpis"
        :key="kpi.label"
        class="rbac-kpi-card flex-1"
        :style="{ minWidth: '180px' }"
      >
        <div class="d-flex align-center ga-3">
          <div class="rbac-kpi-icon" :style="{ background: kpi.bg, color: kpi.color }">
            <v-icon :icon="kpi.icon" size="20" />
          </div>
          <div>
            <p class="text-h6 font-weight-bold mb-0">{{ kpi.value }}</p>
            <p class="text-caption text-medium-emphasis mb-0">{{ kpi.label }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- ── ROLES TAB ─────────────────────────────────────────────────── -->
    <template v-if="tab === 'roles'">
      <v-card elevation="0" border class="rbac-roles-card">
        <v-data-table
          :items="roles"
          :loading="loadingRoles"
          :headers="roleHeaders"
          item-value="id"
          hover
          density="comfortable"
          :items-per-page="-1"
          hide-default-footer
        >
          <!-- Role name & icon -->
          <template #item.name="{ item }">
            <div class="d-flex align-center ga-3 py-2">
              <div
                class="rbac-role-avatar"
                :style="{ background: roleBg(item.color) }"
              >
                <v-icon :icon="item.icon" size="20" :color="roleIconColor(item.color)" />
              </div>
              <div>
                <div class="d-flex align-center ga-2">
                  <span class="text-body-1 font-weight-bold">{{ item.name }}</span>
                  <v-chip v-if="item.is_system" size="x-small" variant="flat" color="primary" class="text-uppercase" label>System</v-chip>
                  <v-chip v-if="item.is_default" size="x-small" variant="tonal" color="success" class="text-uppercase" label>Default</v-chip>
                </div>
                <p class="text-caption text-medium-emphasis mb-0 text-truncate" style="max-width: 360px">{{ item.description }}</p>
              </div>
            </div>
          </template>

          <!-- Permissions count -->
          <template #item.permission_count="{ item }">
            <div class="d-flex align-center ga-2">
              <div class="rbac-perm-bar">
                <div class="rbac-perm-bar-fill" :style="{ width: permPercent(item) + '%' }" />
              </div>
              <span class="text-body-2 font-weight-medium">{{ item.permission_count || 0 }}</span>
              <span class="text-caption text-medium-emphasis">/ {{ totalPermissionCount }}</span>
            </div>
          </template>

          <!-- Users count -->
          <template #item.user_count="{ item }">
            <v-chip variant="tonal" size="small" :color="item.user_count > 0 ? 'primary' : 'default'">
              <v-icon start size="14">mdi-account-multiple</v-icon>
              {{ item.user_count }}
            </v-chip>
          </template>

          <!-- Key -->
          <template #item.key="{ item }">
            <code class="rbac-code">{{ item.key }}</code>
          </template>

          <!-- Actions -->
          <template #item.actions="{ item }">
            <div class="d-flex align-center ga-1">
              <v-tooltip text="Edit role" location="top">
                <template #activator="{ props }">
                  <v-btn
                    v-bind="props"
                    icon="mdi-pencil-outline"
                    size="x-small"
                    variant="text"
                    color="primary"
                    @click="openEditRole(item)"
                  />
                </template>
              </v-tooltip>
              <v-tooltip text="Clone role" location="top">
                <template #activator="{ props }">
                  <v-btn
                    v-bind="props"
                    icon="mdi-content-copy"
                    size="x-small"
                    variant="text"
                    color="info"
                    @click="openCloneRole(item)"
                  />
                </template>
              </v-tooltip>
              <v-tooltip text="Delete role" location="top">
                <template #activator="{ props }">
                  <v-btn
                    v-bind="props"
                    icon="mdi-trash-can-outline"
                    size="x-small"
                    variant="text"
                    color="error"
                    :disabled="item.is_system"
                    @click="confirmDeleteRole(item)"
                  />
                </template>
              </v-tooltip>
            </div>
          </template>

          <template #no-data>
            <div class="text-center py-12">
              <v-icon size="48" color="grey-lighten-1">mdi-shield-off-outline</v-icon>
              <p class="text-body-1 font-weight-medium mt-2 text-medium-emphasis">No roles found</p>
            </div>
          </template>
        </v-data-table>
      </v-card>

      <!-- Permission legend -->
      <v-card elevation="0" border class="pa-4">
        <div class="d-flex align-center ga-4 flex-wrap">
          <span class="text-caption text-medium-emphasis">Legend:</span>
          <div class="d-flex align-center ga-1">
            <v-chip size="x-small" variant="flat" color="primary" label>System</v-chip>
            <span class="text-caption text-medium-emphasis ml-1">Seeded & managed, cannot be deleted</span>
          </div>
          <div class="d-flex align-center ga-1">
            <v-chip size="x-small" variant="tonal" color="success" label>Default</v-chip>
            <span class="text-caption text-medium-emphasis ml-1">Auto-assigned to new users</span>
          </div>
          <span class="text-caption text-medium-emphasis ml-auto">
            <v-icon size="12" class="mb-1">mdi-information-outline</v-icon>
            System role permissions can be customized but roles cannot be deleted
          </span>
        </div>
      </v-card>
    </template>

    <!-- ── USERS TAB ─────────────────────────────────────────────────── -->
    <template v-if="tab === 'users'">
      <v-card elevation="0" border class="rbac-roles-card">
        <v-data-table
          :items="users"
          :loading="loadingUsers"
          :headers="userHeaders"
          item-value="id"
          hover
          density="comfortable"
          :items-per-page="-1"
          hide-default-footer
          :search="userSearch"
        >
          <!-- Search field in header -->
          <template #top>
            <div class="d-flex align-center pa-4 pb-2 ga-3">
              <v-text-field
                v-model="userSearch"
                prepend-inner-icon="mdi-magnify"
                placeholder="Search users by name or email..."
                variant="outlined"
                density="compact"
                hide-details
                class="flex-1"
                style="max-width: 400px"
              />
              <v-btn variant="text" prepend-icon="mdi-refresh" size="small" @click="loadUsers">Refresh</v-btn>
            </div>
          </template>

          <!-- User avatar + name -->
          <template #item.full_name="{ item }">
            <div class="d-flex align-center ga-3 py-2">
              <div class="rbac-user-avatar" :style="{ background: avatarGradient(item) }">
                <span class="text-white text-body-2 font-weight-bold">{{ initials(item) }}</span>
              </div>
              <div>
                <p class="text-body-1 font-weight-medium mb-0">{{ item.full_name }}</p>
                <p class="text-caption text-medium-emphasis mb-0">{{ item.email }}</p>
              </div>
            </div>
          </template>

          <!-- Role chips -->
          <template #item.roles="{ item }">
            <div class="d-flex flex-wrap ga-1 align-center">
              <v-chip
                v-for="r in item.roles || []"
                :key="r.id || r.key"
                :color="r.color"
                size="small"
                variant="tonal"
                label
                class="text-capitalize"
              >
                <v-icon start size="14">{{ r.icon }}</v-icon>
                {{ r.name }}
                <v-icon v-if="r.is_primary" size="10" class="ml-1">mdi-star</v-icon>
              </v-chip>
              <span v-if="!item.roles || item.roles.length === 0" class="text-caption text-medium-emphasis">No role assigned</span>
            </div>
          </template>

          <!-- Status -->
          <template #item.is_active="{ item }">
            <v-chip :color="item.is_active ? 'success' : 'default'" size="small" variant="tonal" label>
              {{ item.is_active ? 'Active' : 'Inactive' }}
            </v-chip>
          </template>

          <!-- Date joined -->
          <template #item.date_joined="{ item }">
            <span class="text-caption text-medium-emphasis">{{ formatDate(item.date_joined) }}</span>
          </template>

          <!-- Actions -->
          <template #item.actions="{ item }">
            <div class="d-flex align-center ga-1">
              <v-btn
                icon="mdi-shield-account-outline"
                size="x-small"
                variant="text"
                color="primary"
                @click="openAssignRole(item)"
                v-if="rbac.can('users', 'assign')"
              />
              <v-btn
                icon="mdi-pencil-outline"
                size="x-small"
                variant="text"
                color="info"
                @click="openEditUser(item)"
                v-if="rbac.can('users', 'update')"
              />
              <v-btn
                :icon="item.is_active ? 'mdi-account-cancel-outline' : 'mdi-account-check-outline'"
                size="x-small"
                variant="text"
                :color="item.is_active ? 'error' : 'success'"
                @click="toggleActive(item)"
                v-if="rbac.can('users', 'delete') && item.id !== auth.user?.id"
              />
            </div>
          </template>

          <template #no-data>
            <div class="text-center py-12">
              <v-icon size="48" color="grey-lighten-1">mdi-account-group-outline</v-icon>
              <p class="text-body-1 font-weight-medium mt-2 text-medium-emphasis">No users found</p>
            </div>
          </template>
        </v-data-table>
      </v-card>
    </template>

    <!-- ── Role form dialog ───────────────────────────────────────────── -->
    <RoleFormDialog
      v-model:open="roleDialogOpen"
      :role="editingRole"
      :permission-groups="permissionGroups"
      @saved="onRoleSaved"
    />

    <!-- ── Clone role dialog ──────────────────────────────────────────── -->
    <v-dialog v-model="cloneDialogOpen" max-width="520px">
      <v-card rounded="xl" elevation="0" border>
        <AppModalHeader
          icon="mdi-content-copy"
          :title="`Clone “${cloningRole?.name || ''}”`"
          color="info"
        />
        <v-card-text class="pa-6">
          <p class="text-body-2 text-medium-emphasis mb-4">
            Creates a new custom role that inherits all
            {{ cloningRole?.permission_count || 0 }} permissions from
            <strong>{{ cloningRole?.name }}</strong>. You can adjust them
            afterwards from the role editor.
          </p>
          <v-row dense>
            <v-col cols="12" sm="6">
              <v-text-field
                v-model="cloneForm.name"
                label="New Role Name"
                variant="outlined"
                density="comfortable"
                :error-messages="cloneErrors.name"
                @input="generateCloneKey"
              />
            </v-col>
            <v-col cols="12" sm="6">
              <v-text-field
                v-model="cloneForm.key"
                label="Role Key"
                variant="outlined"
                density="comfortable"
                hint="Unique identifier (auto-generated)"
                persistent-hint
                :error-messages="cloneErrors.key"
              />
            </v-col>
            <v-col cols="12">
              <v-textarea
                v-model="cloneForm.description"
                label="Description"
                variant="outlined"
                density="comfortable"
                rows="2"
                auto-grow
              />
            </v-col>
            <v-col cols="12" sm="6">
              <v-select
                v-model="cloneForm.color"
                :items="cloneColorOptions"
                item-title="label"
                item-value="value"
                label="Color Tag"
                variant="outlined"
                density="comfortable"
              />
            </v-col>
            <v-col cols="12" sm="6">
              <v-text-field
                v-model="cloneForm.icon"
                label="Icon (MDI)"
                variant="outlined"
                density="comfortable"
              >
                <template #append-inner>
                  <v-icon :icon="cloneForm.icon" />
                </template>
              </v-text-field>
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="pa-4 pt-0">
          <v-spacer />
          <v-btn variant="text" @click="cloneDialogOpen = false">Cancel</v-btn>
          <v-btn color="info" prepend-icon="mdi-content-save" :loading="cloning" @click="doCloneRole">
            Clone Role
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
            <div class="rbac-user-avatar" style="width: 48px; height: 48px" :style="{ background: avatarGradient(assigningUser) }">
              <span class="text-white text-body-1 font-weight-bold">{{ initials(assigningUser) }}</span>
            </div>
            <div>
              <p class="text-body-1 font-weight-medium mb-0">{{ assigningUser?.full_name }}</p>
              <p class="text-caption text-medium-emphasis mb-0">{{ assigningUser?.email }}</p>
            </div>
          </div>

          <v-select
            v-model="selectedRoleId"
            :items="roles"
            item-title="name"
            item-value="id"
            label="Select Role"
            variant="outlined"
            density="comfortable"
            class="mb-3"
          >
            <template #item="{ props, item }">
              <v-list-item v-bind="props" :prepend-avatar="item.raw.icon">
                <template #prepend>
                  <div class="rbac-role-avatar-sm" :style="{ background: roleBg(item.raw.color) }">
                    <v-icon :icon="item.raw.icon" size="16" :color="roleIconColor(item.raw.color)" />
                  </div>
                </template>
                <template #title>
                  <span class="text-body-2 font-weight-medium">{{ item.raw.name }}</span>
                </template>
                <template #subtitle>
                  <span class="text-caption">{{ item.raw.permission_count || 0 }} permissions</span>
                </template>
              </v-list-item>
            </template>
          </v-select>

          <v-checkbox
            v-model="assignIsPrimary"
            label="Set as primary role"
            hide-details
            density="compact"
            color="primary"
            class="mb-2"
          />
          <p class="text-caption text-medium-emphasis">
            The primary role determines the user's main access level and is shown in the sidebar.
          </p>
        </v-card-text>
        <v-card-actions class="pa-4 pt-0">
          <v-spacer />
          <v-btn variant="text" @click="assignDialogOpen = false">Cancel</v-btn>
          <v-btn color="primary" prepend-icon="mdi-check" :loading="assigning" @click="doAssignRole">Assign Role</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- ── Invite / Edit user dialog ──────────────────────────────────── -->
    <v-dialog v-model="userDialogOpen" max-width="560px">
      <v-card rounded="xl" elevation="0" border>
        <AppModalHeader
          :icon="editingUser ? 'mdi-account-edit-outline' : 'mdi-account-plus-outline'"
          :title="editingUser ? 'Edit User' : 'Invite User'"
          color="primary"
        />
        <v-card-text class="pa-6">
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
              <v-text-field v-model="userForm.phone" label="Phone" variant="outlined" density="comfortable" />
            </v-col>
            <v-col cols="12" v-if="!editingUser">
              <v-text-field v-model="userForm.password" label="Temporary Password" variant="outlined" density="comfortable" type="password" hint="User will be asked to change this on first login" persistent-hint />
            </v-col>
            <v-col cols="12" v-if="!editingUser">
              <v-select
                v-model="userForm.role"
                :items="roleOptions"
                item-title="name"
                item-value="key"
                label="Assign Role"
                variant="outlined"
                density="comfortable"
                hint="This determines the user's access level"
                persistent-hint
              />
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="pa-4 pt-0">
          <v-spacer />
          <v-btn variant="text" @click="userDialogOpen = false">Cancel</v-btn>
          <v-btn color="primary" prepend-icon="mdi-check" :loading="savingUser" @click="saveUser">
            {{ editingUser ? 'Save Changes' : 'Invite User' }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import type { RbacPermissionGroup, RbacRole, RbacUser, RbacRoleDetail } from '~/composables/useRbac'

definePageMeta({
  layout: 'default',
  permission: 'users:view',
})

const { $api, $swal } = useNuxtApp()
const auth = useAuthStore()
const rbac = useRbac()

const tab = ref<'roles' | 'users'>('roles')

// ── Data state ────────────────────────────────────────────────────────
const roles = ref<any[]>([])
const users = ref<any[]>([])
const permissionGroups = ref<RbacPermissionGroup[]>([])
const loadingRoles = ref(false)
const loadingUsers = ref(false)
const userSearch = ref('')

// ── Dialog state ──────────────────────────────────────────────────────
const roleDialogOpen = ref(false)
const editingRole = ref<RbacRoleDetail | null>(null)
const assignDialogOpen = ref(false)
const assigningUser = ref<any>(null)
const selectedRoleId = ref<number | null>(null)
const assignIsPrimary = ref(false)
const assigning = ref(false)
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

// ── Clone dialog state ────────────────────────────────────────────────
const cloneDialogOpen = ref(false)
const cloningRole = ref<any>(null)
const cloning = ref(false)
const cloneForm = reactive<any>({
  name: '', key: '', description: '', color: '#6366f1', icon: 'mdi-shield-account-outline',
})
const cloneErrors = reactive<any>({})

const cloneColorOptions = [
  { label: 'Indigo', value: '#6366f1' },
  { label: 'Blue', value: '#3b82f6' },
  { label: 'Green', value: '#22c55e' },
  { label: 'Orange', value: '#f59e0b' },
  { label: 'Red', value: '#ef4444' },
  { label: 'Purple', value: '#a855f7' },
  { label: 'Teal', value: '#14b8a6' },
  { label: 'Pink', value: '#ec4899' },
  { label: 'Cyan', value: '#06b6d4' },
  { label: 'Gray', value: '#6b7280' },
]

// ── Table headers ──────────────────────────────────────────────────────
const roleHeaders = [
  { title: 'Role', key: 'name', sortable: true, width: '45%' },
  { title: 'Key', key: 'key', sortable: false, width: '15%' },
  { title: 'Permissions', key: 'permission_count', sortable: true, width: '20%' },
  { title: 'Users', key: 'user_count', sortable: true, width: '10%' },
  { title: '', key: 'actions', sortable: false, width: '10%', align: 'end' as const },
]

const userHeaders = [
  { title: 'User', key: 'full_name', sortable: true, width: '30%' },
  { title: 'Roles', key: 'roles', sortable: false, width: '30%' },
  { title: 'Status', key: 'is_active', sortable: true, width: '15%' },
  { title: 'Joined', key: 'date_joined', sortable: true, width: '15%' },
  { title: '', key: 'actions', sortable: false, width: '10%', align: 'end' as const },
]

// ── Computed KPIs ──────────────────────────────────────────────────────
const kpis = computed(() => [
  { label: 'Total Roles', value: roles.value.length, icon: 'mdi-shield-key', color: '#6366f1', bg: 'rgba(99, 102, 241, 0.12)' },
  { label: 'System Roles', value: roles.value.filter(r => r.is_system).length, icon: 'mdi-shield-crown', color: '#f59e0b', bg: 'rgba(245, 158, 11, 0.12)' },
  { label: 'Custom Roles', value: roles.value.filter(r => !r.is_system).length, icon: 'mdi-shield-plus-outline', color: '#22c55e', bg: 'rgba(34, 197, 94, 0.12)' },
  { label: 'Total Users', value: users.value.length, icon: 'mdi-account-group', color: '#3b82f6', bg: 'rgba(59, 130, 246, 0.12)' },
])

const roleOptions = computed(() => roles.value.map(r => ({ name: r.name, key: r.key })))

// ── Data loading ──────────────────────────────────────────────────────
async function loadRoles() {
  loadingRoles.value = true
  try {
    const data = await rbac.fetchRoles() as any[]
    roles.value = data
  } catch (e) {
    console.error('Failed to load roles:', e)
    roles.value = []
  } finally {
    loadingRoles.value = false
  }
}

async function loadUsers() {
  loadingUsers.value = true
  try {
    const data = await rbac.fetchUsersList() as any[]
    // If the endpoint returns a simple array, enrich with roles via rbac users endpoint
    users.value = data
    // Also try to fetch enriched user data with roles
    try {
      const enriched = await rbac.fetchUsers() as any[]
      // Merge: if enriched data is available, use it; otherwise keep basic data
      if (enriched && enriched.length > 0) {
        users.value = enriched
      }
    } catch {
      // Fall back to basic user data
    }
  } catch (e) {
    console.error('Failed to load users:', e)
    users.value = []
  } finally {
    loadingUsers.value = false
  }
}

// ── Role CRUD ─────────────────────────────────────────────────────────
function openCreateRole() {
  editingRole.value = null
  roleDialogOpen.value = true
}

async function openEditRole(role: any) {
  try {
    editingRole.value = await rbac.fetchRole(role.id) as RbacRoleDetail
    roleDialogOpen.value = true
  } catch (e) {
    console.error('Failed to load role detail:', e)
    $swal.fire({ icon: 'error', title: 'Error', text: 'Could not load role details.' })
  }
}

function onRoleSaved() {
  roleDialogOpen.value = false
  loadRoles()
}

function confirmDeleteRole(role: any) {
  $swal.fire({
    icon: 'warning',
    title: 'Delete Role?',
    text: `Are you sure you want to delete the "${role.name}" role? This action cannot be undone.`,
    showCancelButton: true,
    confirmButtonText: 'Delete',
    confirmButtonColor: '#ef4444',
    cancelButtonText: 'Cancel',
  }).then(async (result: any) => {
    if (result.isConfirmed) {
      try {
        await rbac.deleteRole(role.id)
        $swal.fire({ icon: 'success', title: 'Deleted', text: 'Role deleted successfully.', timer: 2000, toast: true, position: 'top-end' })
        loadRoles()
      } catch (e: any) {
        const msg = e?.data?.detail || 'Could not delete role.'
        $swal.fire({ icon: 'error', title: 'Delete Failed', text: msg })
      }
    }
  })
}

// ── Role clone ────────────────────────────────────────────────────────
function openCloneRole(role: any) {
  cloningRole.value = role
  cloneForm.name = `${role.name} (Copy)`
  cloneForm.key = `${role.key}_copy`
  cloneForm.description = role.description || ''
  cloneForm.color = role.color && role.color.startsWith('#') ? role.color : '#6366f1'
  cloneForm.icon = role.icon || 'mdi-shield-account-outline'
  cloneErrors.name = ''
  cloneErrors.key = ''
  cloneDialogOpen.value = true
}

function generateCloneKey() {
  const slug = cloneForm.name.toLowerCase().trim().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '')
  cloneForm.key = slug ? `${slug}_${Math.random().toString(36).slice(2, 6)}` : ''
}

async function doCloneRole() {
  if (!cloningRole.value) return
  cloneErrors.name = ''
  cloneErrors.key = ''
  if (!cloneForm.name?.trim()) { cloneErrors.name = 'Role name is required.'; return }
  if (!cloneForm.key?.trim()) { cloneErrors.key = 'Role key is required.'; return }
  cloning.value = true
  try {
    const created = await rbac.cloneRole(cloningRole.value.id, {
      name: cloneForm.name,
      key: cloneForm.key,
      description: cloneForm.description,
      color: cloneForm.color,
      icon: cloneForm.icon,
    })
    $swal.fire({
      icon: 'success', title: 'Role Cloned',
      text: `"${created.name}" created with ${created.permission_codes?.length || 0} permissions.`,
      timer: 2400, toast: true, position: 'top-end',
    })
    cloneDialogOpen.value = false
    await loadRoles()
  } catch (e: any) {
    const msg = e?.data?.key?.[0] || e?.data?.name?.[0] || e?.data?.detail || 'Could not clone role.'
    $swal.fire({ icon: 'error', title: 'Clone Failed', text: msg })
  } finally {
    cloning.value = false
  }
}

// ── Role assignment ───────────────────────────────────────────────────
function openAssignRole(user: any) {
  assigningUser.value = user
  selectedRoleId.value = null
  assignIsPrimary.value = !user.roles || user.roles.length === 0
  assignDialogOpen.value = true
}

async function doAssignRole() {
  if (!selectedRoleId.value || !assigningUser.value) return
  assigning.value = true
  try {
    await rbac.assignRole(assigningUser.value.id, selectedRoleId.value, assignIsPrimary.value)
    $swal.fire({ icon: 'success', title: 'Role Assigned', text: 'Role has been assigned successfully.', timer: 2000, toast: true, position: 'top-end' })
    assignDialogOpen.value = false
    await loadUsers()
    // Refresh current user's permissions if they changed their own role
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
      $swal.fire({ icon: 'success', title: 'Saved', text: 'User updated successfully.', timer: 2000, toast: true, position: 'top-end' })
    } else {
      await rbac.createUser({
        email: userForm.email,
        first_name: userForm.first_name,
        last_name: userForm.last_name,
        role: userForm.role,
        phone: userForm.phone,
        password: userForm.password,
      })
      $swal.fire({ icon: 'success', title: 'User Created', text: 'User has been created successfully.', timer: 2000, toast: true, position: 'top-end' })
    }
    userDialogOpen.value = false
    await loadUsers()
  } catch (e: any) {
    const msg = e?.data?.detail || e?.data?.email?.[0] || 'Could not save user.'
    $swal.fire({ icon: 'error', title: 'Save Failed', text: msg })
  } finally {
    savingUser.value = false
  }
}

async function toggleActive(user: any) {
  const action = user.is_active ? 'deactivate' : 'activate'
  $swal.fire({
    icon: 'question',
    title: `${action.charAt(0).toUpperCase() + action.slice(1)} user?`,
    text: `Are you sure you want to ${action} ${user.full_name}?`,
    showCancelButton: true,
    confirmButtonText: action.charAt(0).toUpperCase() + action.slice(1),
    cancelButtonText: 'Cancel',
  }).then(async (result: any) => {
    if (result.isConfirmed) {
      try {
        await rbac.toggleUserActive(user.id)
        $swal.fire({ icon: 'success', title: 'Done', text: `User ${action}d.`, timer: 2000, toast: true, position: 'top-end' })
        await loadUsers()
      } catch (e: any) {
        $swal.fire({ icon: 'error', title: 'Action Failed', text: e?.data?.detail || 'Could not update user status.' })
      }
    }
  })
}

// ── Helpers ───────────────────────────────────────────────────────────
const roleKey = (role: any) => role?.key || role?.id || ''
const duplicateNameError = computed(() => '')
const totalPermissionCount = computed(() =>
  permissionGroups.value.reduce((sum, g) => sum + (g.permissions?.length || 0), 0)
)

function permPercent(role: any): number {
  const total = totalPermissionCount.value || 105
  return Math.round(((role.permission_count || 0) / total) * 100)
}
function roleBg(color: string): string {
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
function roleIconColor(color: string): string {
  if (!color || color === 'primary') return 'primary'
  return color
}
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
  await Promise.all([loadRoles(), loadUsers()])
  // Pre-load permission groups for the role dialog (visible to role editors)
  if (rbac.isAdmin.value || rbac.can('users', 'assign')) {
    try {
      permissionGroups.value = await rbac.fetchPermissionGroups()
    } catch (e) {
      console.error('Failed to load permission groups:', e)
    }
  }
})
</script>

<style scoped>
.rbac-header-icon {
  width: 48px;
  height: 48px;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #6366f1 0%, #4f46e5 100%);
  box-shadow: 0 4px 12px rgba(99, 102, 241, 0.35);
}

.rbac-tab-activator {
  transition: all 0.18s ease;
  border-color: rgba(var(--v-theme-on-surface), 0.12);
}
.rbac-tab-activator-active {
  color: #6366f1 !important;
  border-color: #6366f1 !important;
  background: rgba(99, 102, 241, 0.08);
}

.rbac-kpi-card {
  background: rgb(var(--v-theme-surface));
  border: 1px solid rgba(var(--v-theme-on-surface), 0.08);
  border-radius: 14px;
  padding: 16px 20px;
  transition: all 0.2s ease;
}
.rbac-kpi-card:hover {
  border-color: rgba(99, 102, 241, 0.2);
  box-shadow: 0 4px 20px rgba(var(--v-theme-on-surface), 0.06);
}
.rbac-kpi-icon {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.rbac-roles-card {
  border-radius: 14px;
  overflow: hidden;
}
.rbac-roles-card :deep(.v-data-table) {
  border-radius: 14px;
}
.rbac-roles-card :deep(.v-data-table-header) {
  background: rgba(var(--v-theme-on-surface), 0.02);
  font-weight: 600;
  font-size: 12px;
  letter-spacing: 0.5px;
  text-transform: uppercase;
  color: rgba(var(--v-theme-on-surface), 0.5);
}

.rbac-role-avatar {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  transition: transform 0.18s ease;
}
.rbac-role-avatar:hover {
  transform: scale(1.08);
}
.rbac-role-avatar-sm {
  width: 32px;
  height: 32px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.rbac-user-avatar {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.rbac-perm-bar {
  width: 80px;
  height: 6px;
  border-radius: 3px;
  background: rgba(var(--v-theme-on-surface), 0.1);
  overflow: hidden;
}
.rbac-perm-bar-fill {
  height: 100%;
  border-radius: 3px;
  background: linear-gradient(90deg, #6366f1, #4f46e5);
  transition: width 0.3s ease;
}

.rbac-code {
  font-family: 'JetBrains Mono', 'Fira Code', monospace;
  font-size: 12px;
  padding: 2px 8px;
  border-radius: 6px;
  background: rgba(var(--v-theme-on-surface), 0.06);
  color: rgba(var(--v-theme-on-surface), 0.7);
}
</style>
