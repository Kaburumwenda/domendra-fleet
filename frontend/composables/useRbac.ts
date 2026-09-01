/**
 * RBAC (Role-Based Access Control) composable.
 *
 * Provides reactive access to the current user's permissions and roles,
 * plus API helpers for the Roles & Permissions management UI.
 *
 * Usage:
 *   const { can, roles, myPermissions } = useRbac()
 *   if (can('vehicles', 'delete')) { ... }
 */

export interface RbacPermission {
  id: number
  module: string
  action: string
  label: string
  description: string
  code: string
}

export interface RbacPermissionGroup {
  module: string
  label: string
  icon: string
  permissions: RbacPermission[]
}

export interface RbacRole {
  id: number
  name: string
  key: string
  description: string
  color: string
  icon: string
  is_system: boolean
  is_default: boolean
  user_count: number
  permission_count?: number
  permission_codes: string[]
  created_at: string
  updated_at: string
}

export interface RbacRoleDetail extends RbacRole {
  permission_groups: {
    module: string
    label: string
    icon: string
    permissions: (RbacPermission & { granted: boolean })[]
  }[]
}

export interface RbacRoleAssignment {
  id: number
  user: {
    id: number
    email: string
    first_name: string
    last_name: string
    full_name: string
    role: string
    is_active: boolean
    avatar: string | null
  }
  role: RbacRole
  is_primary: boolean
  assigned_by_name: string
  created_at: string
}

export interface RbacUser {
  id: number
  email: string
  first_name: string
  last_name: string
  full_name: string
  role: string
  phone: string
  avatar: string | null
  is_active: boolean
  is_staff: boolean
  is_superuser: boolean
  date_joined: string
  roles: {
    id: number | null
    name: string
    key: string
    color: string
    icon: string
    is_primary: boolean
  }[]
  primary_role_name: string | null
}

export interface MyPermissionsResponse {
  permissions: string[]
  is_admin: boolean
  roles: { key: string; name: string }[]
}

export interface MyRolesResponse {
  roles: {
    id: number | null
    name: string
    key: string
    color: string
    icon: string
    is_primary: boolean
  }[]
  primary_role: {
    id: number | null
    name: string
    key: string
    color: string
    icon: string
  } | null
}

export interface CloneRolePayload {
  name: string
  key: string
  description?: string
  color?: string
  icon?: string
}

// ── Permission hierarchy (must mirror backend ``_IMPLIES``) ─────────
// Higher-impact actions imply lower-impact ones so the frontend ``can()``
// check agrees with the server even when only the broader permission was
// explicitly granted.
const _IMPLIES: Record<string, Set<string>> = {
  delete: new Set(['update', 'create', 'view']),
  update: new Set(['view']),
  create: new Set(['view']),
  approve: new Set(['view']),
  assign: new Set(['view']),
  export: new Set(['view']),
}

function _expandCodes(codes: string[]): string[] {
  const out = new Set(codes)
  for (const code of codes) {
    const idx = code.indexOf(':')
    if (idx === -1) continue
    const module = code.slice(0, idx)
    const action = code.slice(idx + 1)
    for (const implied of _IMPLIES[action] ?? []) {
      out.add(`${module}:${implied}`)
    }
  }
  return Array.from(out)
}

// ── Singleton state (shared across all components) ──────────────────
// useState must be called inside a function, not at module scope, so
// we lazily initialise them on first useRbac() call.

export function useRbac() {
  const { $api } = useNuxtApp()
  // useState is safe here — inside a composable function called from setup/middleware/plugin
  const _myPermissions = useState<string[]>('rbac-permissions', () => [])
  const _myRoles = useState<{ key: string; name: string }[]>('rbac-roles', () => [])
  const _primaryRole = useState<{ key: string; name: string; color: string; icon: string } | null>('rbac-primary-role', () => null)
  const _isAdmin = useState<boolean>('rbac-is-admin', () => false)
  const _loaded = useState<boolean>('rbac-loaded', () => false)
  const _loadedUserId = useState<number | null>('rbac-loaded-user-id', () => null)

  // ── Getters ───────────────────────────────────────────────────────
  const myPermissions = computed(() => _myPermissions.value)
  const myRoles = computed(() => _myRoles.value)
  const primaryRole = computed(() => _primaryRole.value)
  const isAdmin = computed(() => _isAdmin.value)

  /**
   * Check if the current user has a specific permission.
   * Honours the permission hierarchy: granting ``delete`` implicitly
   * grants ``update``, ``create`` and ``view`` for the same module.
   * @param module e.g. 'vehicles'
   * @param action e.g. 'delete'
   * @returns boolean
   */
  function can(module: string, action: string): boolean {
    if (_isAdmin.value) return true
    return _myPermissions.value.includes(`${module}:${action}`)
  }

  /** Check by permission code string: canCode('vehicles:delete') */
  function canCode(code: string): boolean {
    if (_isAdmin.value) return true
    return _myPermissions.value.includes(code)
  }

  // ── Actions ────────────────────────────────────────────────────────

  /** Fetch current user's permissions and roles from the API. */
  async function loadMyPermissions() {
    // Determine the current user's ID so we can detect user switches
    // (e.g. admin logs out, driver logs in on the same browser session).
    // Without this, the useState singleton _loaded flag would prevent
    // re-fetching and the new user would see the previous user's permissions.
    const auth = useAuthStore()
    const currentUserId = auth.user?.id ?? null
    if (_loaded.value && _loadedUserId.value === currentUserId && currentUserId !== null) return

    // If the user changed, reset stale state before re-hydrating
    if (_loadedUserId.value !== null && _loadedUserId.value !== currentUserId) {
      _myPermissions.value = []
      _myRoles.value = []
      _primaryRole.value = null
      _isAdmin.value = false
      _loaded.value = false
      if (import.meta.client) {
        localStorage.removeItem('fc_permissions')
      }
    }

    // Hydrate from localStorage first so UI can render immediately
    if (import.meta.client) {
      const cached = localStorage.getItem('fc_permissions')
      if (cached) {
        try {
          const parsed = JSON.parse(cached)
          // Only hydrate if the cached permissions belong to the current user
          if (parsed.user_id === currentUserId || currentUserId === null) {
            _myPermissions.value = _expandCodes(parsed.permissions || [])
            _myRoles.value = parsed.roles || []
            _isAdmin.value = parsed.is_admin || false
            if (parsed.primary_role) _primaryRole.value = parsed.primary_role
          }
        } catch { /* ignore */ }
      }
    }
    // Fetch fresh from API
    try {
      const data: MyPermissionsResponse = await $api('/rbac/me/permissions/')
        _myPermissions.value = _expandCodes(data.permissions || [])
      _myRoles.value = data.roles || []
      _isAdmin.value = data.is_admin || false
      _loaded.value = true
      _loadedUserId.value = currentUserId
      if (import.meta.client) {
        localStorage.setItem('fc_permissions', JSON.stringify({
          permissions: data.permissions,
          roles: data.roles,
          is_admin: data.is_admin,
          user_id: currentUserId,
        }))
      }
    } catch (e) {
      console.error('[RBAC] Failed to load permissions:', e)
      _loaded.value = true // Mark as loaded to prevent retry loops
      _loadedUserId.value = currentUserId
    }
  }

  /** Force refresh permissions (e.g., after role change). */
  async function refreshMyPermissions() {
    _loaded.value = false
    await loadMyPermissions()
  }

  /** Reset state (on logout). */
  function clearPermissions() {
    _myPermissions.value = []
    _myRoles.value = []
    _primaryRole.value = null
    _isAdmin.value = false
    _loaded.value = false
    _loadedUserId.value = null
    if (import.meta.client) {
      localStorage.removeItem('fc_permissions')
    }
  }

  // ── API: Permission catalog ────────────────────────────────────────
  async function fetchPermissionGroups(): Promise<RbacPermissionGroup[]> {
    return await $api('/rbac/permissions/')
  }

  // ── API: Roles ─────────────────────────────────────────────────────
  async function fetchRoles(): Promise<RbacRole[]> {
    return await $api('/rbac/roles/')
  }

  async function fetchRole(id: number): Promise<RbacRoleDetail> {
    return await $api(`/rbac/roles/${id}/`)
  }

  async function createRole(payload: {
    name: string
    key: string
    description: string
    color: string
    icon: string
    permissions: number[]
  }): Promise<RbacRole> {
    return await $api('/rbac/roles/', { method: 'POST', body: payload })
  }

  async function updateRole(id: number, payload: Partial<{
    name: string
    description: string
    color: string
    icon: string
    permissions: number[]
  }>): Promise<RbacRoleDetail> {
    return await $api(`/rbac/roles/${id}/`, { method: 'PATCH', body: payload })
  }

  async function deleteRole(id: number): Promise<void> {
    await $api(`/rbac/roles/${id}/`, { method: 'DELETE' })
  }

  async function cloneRole(sourceId: number, payload: CloneRolePayload): Promise<RbacRoleDetail> {
    return await $api(`/rbac/roles/${sourceId}/clone/`, { method: 'POST', body: payload })
  }

  // ── API: Role assignments ──────────────────────────────────────────
  async function fetchAssignments(): Promise<RbacRoleAssignment[]> {
    return await $api('/rbac/assignments/')
  }

  async function assignRole(userId: number, roleId: number, isPrimary = false): Promise<RbacRoleAssignment> {
    return await $api('/rbac/assign/', {
      method: 'POST',
      body: { user_id: userId, role_id: roleId, is_primary: isPrimary },
    })
  }

  async function deleteAssignment(id: number): Promise<void> {
    await $api(`/rbac/assignments/${id}/`, { method: 'DELETE' })
  }

  // ── API: Users (with roles) ────────────────────────────────────────
  async function fetchUsers(): Promise<RbacUser[]> {
    return await $api('/rbac/users/')
  }

  async function fetchUser(id: number): Promise<RbacUser> {
    return await $api(`/rbac/users/${id}/`)
  }

  async function createUser(payload: {
    email: string
    first_name: string
    last_name: string
    role: string
    phone: string
    password: string
  }): Promise<any> {
    return await $api('/auth/users/create/', { method: 'POST', body: payload })
  }

  async function updateUser(id: number, payload: Partial<{
    first_name: string
    last_name: string
    phone: string
    role: string
    is_active: boolean
  }>): Promise<any> {
    return await $api(`/auth/users/${id}/`, { method: 'PATCH', body: payload })
  }

  async function toggleUserActive(id: number): Promise<any> {
    return await $api(`/auth/users/${id}/`, { method: 'DELETE' })
  }

  async function fetchUserDetail(id: number): Promise<any> {
    return await $api(`/auth/users/${id}/`)
  }

  async function resetUserPassword(id: number, password: string): Promise<any> {
    return await $api(`/auth/users/${id}/reset-password/`, { method: 'POST', body: { password } })
  }

  async function fetchUsersList(): Promise<any[]> {
    return await $api('/auth/users/')
  }

  async function fetchMyRoles(): Promise<MyRolesResponse> {
    return await $api('/rbac/me/roles/')
  }

  return {
    // State
    myPermissions,
    myRoles,
    primaryRole,
    isAdmin,
    // Getters
    can,
    canCode,
    // Actions
    loadMyPermissions,
    refreshMyPermissions,
    clearPermissions,
    // Permission catalog
    fetchPermissionGroups,
    // Roles CRUD
    fetchRoles,
    fetchRole,
    createRole,
    updateRole,
    deleteRole,
    cloneRole,
    // Assignments
    fetchAssignments,
    assignRole,
    deleteAssignment,
    // Users
    fetchUsers,
    fetchUser,
    fetchUserDetail,
    createUser,
    updateUser,
    toggleUserActive,
    resetUserPassword,
    fetchUsersList,
    // My roles
    fetchMyRoles,
  }
}
