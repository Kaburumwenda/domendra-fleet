import { defineStore } from 'pinia'

interface User {
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
}

export const useAuthStore = defineStore('auth', {
  state: () => ({
    accessToken: '' as string,
    refreshToken: '' as string,
    user: null as User | null,
    tenantSchema: '' as string,
  }),

  getters: {
    isAuthenticated: (state) => !!state.accessToken,
    fullName: (state) => state.user?.full_name || '',
    role: (state) => state.user?.role || '',
    isAdmin: (state) => !!(state.user?.is_staff && state.user?.is_superuser),
    initials: (state) => {
      if (!state.user) return ''
      return (state.user.first_name[0] || '') + (state.user.last_name[0] || '')
    },
  },

  actions: {
    init() {
      if (import.meta.client) {
        this.accessToken = localStorage.getItem('fc_access') || ''
        this.refreshToken = localStorage.getItem('fc_refresh') || ''
        this.tenantSchema = localStorage.getItem('fc_tenant') || ''
        const userStr = localStorage.getItem('fc_user')
        this.user = userStr ? JSON.parse(userStr) : null
      }
    },

    async login(email: string, password: string) {
      const { $api } = useNuxtApp()
      const data = await $api('/auth/login/', {
        method: 'POST',
        body: { email, password },
      })
      this.setSession(data, data.tenant_schema)
      return data
    },

    async register(payload: Record<string, any>) {
      const { $api } = useNuxtApp()
      const data = await $api('/auth/register/', {
        method: 'POST',
        body: payload,
      })
      this.setSession(data, data.tenant_schema)
      return data
    },

    setSession(data: Record<string, any>, tenantSchema: string) {
      this.accessToken = data.access
      this.refreshToken = data.refresh
      this.user = data.user
      this.tenantSchema = tenantSchema
      if (import.meta.client) {
        localStorage.setItem('fc_access', data.access)
        localStorage.setItem('fc_refresh', data.refresh)
        localStorage.setItem('fc_tenant', tenantSchema)
        localStorage.setItem('fc_user', JSON.stringify(data.user))
      }
    },

    async fetchMe() {
      try {
        const { $api } = useNuxtApp()
        const data = await $api('/auth/me/')
        this.user = data
        if (import.meta.client) {
          localStorage.setItem('fc_user', JSON.stringify(data))
        }
        // Permissions are loaded separately by useRbac() in middleware/setup —
        // calling useRbac() here would break because Nuxt instance context
        // may not be available inside a Pinia action.
      } catch {
        this.logout()
      }
    },

    logout() {
      this.accessToken = ''
      this.refreshToken = ''
      this.user = null
      this.tenantSchema = ''
      if (import.meta.client) {
        localStorage.removeItem('fc_access')
        localStorage.removeItem('fc_refresh')
        localStorage.removeItem('fc_tenant')
        localStorage.removeItem('fc_user')
        // Clear RBAC permission cache from localStorage so useRbac re-fetches on next login
        localStorage.removeItem('fc_permissions')
        localStorage.removeItem('fc_permissions_loaded')
      }
    },
  },
})
