// SuperAdmin helper composable — thin wrapper around the global $api
// that returns api helper functions tailored for the control plane.
export function useSuperAdmin() {
  const { $api } = useNuxtApp()

  async function listTenants(params: Record<string, any> = {}) {
    return $api<any>('/superadmin/tenants/', { params })
  }
  function tenantUrl(schema: string, sub = '') {
    return `/superadmin/tenants/${encodeURIComponent(schema)}${sub}`
  }

  async function dashboard() {
    return $api<any>('/superadmin/dashboard/')
  }
  async function revenue(months = 6) {
    return $api<any>('/superadmin/revenue/', { params: { months } })
  }
  async function systemHealth() {
    return $api<any>('/superadmin/system-health/')
  }
  async function audit(limit = 200, filters: Record<string, any> = {}) {
    return $api<any>('/superadmin/audit/', { params: { limit, ...filters } })
  }
  async function tenantUsage(schema: string, days = 30) {
    return $api<any>(tenantUrl(schema, '/usage/') + `?days=${days}`)
  }
  async function tenantStats(id: number) {
    return $api<any>(`/superadmin/tenants/${id}/stats/`)
  }
  async function suspendTenant(id: number) {
    return $api<any>(`/superadmin/tenants/${id}/suspend/`, { method: 'POST' })
  }
  async function activateTenant(id: number) {
    return $api<any>(`/superadmin/tenants/${id}/activate/`, { method: 'POST' })
  }
  async function loginAsTenant(id: number) {
    return $api<any>(`/superadmin/tenants/${id}/login-as/`, { method: 'POST' })
  }
  async function tenantToggles(schema: string, body?: Record<string, any>) {
    const url = `/superadmin/tenants/${encodeURIComponent(schema)}/toggles/`
    return $api<any>(url, body ? { method: 'PATCH', body } : {})
  }
  async function tenantUsers(schema: string, params: Record<string, any> = {}) {
    return $api<any>(`/superadmin/tenants/${encodeURIComponent(schema)}/users/`, { params })
  }
  async function createTenantUser(schema: string, body: Record<string, any>) {
    return $api<any>(`/superadmin/tenants/${encodeURIComponent(schema)}/users/`, { method: 'POST', body })
  }
  async function patchTenantUser(schema: string, id: number, body: Record<string, any>) {
    return $api<any>(`/superadmin/tenants/${encodeURIComponent(schema)}/users/${id}/`, { method: 'PATCH', body })
  }
  async function deleteTenantUser(schema: string, id: number) {
    return $api<any>(`/superadmin/tenants/${encodeURIComponent(schema)}/users/${id}/`, { method: 'DELETE' })
  }
  async function loginAsTenantUser(schema: string, id: number) {
    return $api<any>(`/superadmin/tenants/${encodeURIComponent(schema)}/users/${id}/login-as/`, { method: 'POST' })
  }

  return {
    listTenants, tenantUrl, dashboard, revenue, systemHealth, audit,
    tenantUsage, tenantStats, suspendTenant, activateTenant, loginAsTenant,
    tenantToggles, tenantUsers, createTenantUser, patchTenantUser, deleteTenantUser, loginAsTenantUser,
  }
}

const CURRENCY_SYMBOLS: Record<string, string> = {
  USD: '$', EUR: '€', GBP: '£', KES: 'KSh', NGN: '₦', ZAR: 'R',
  AED: 'AED', SAR: 'SAR', INR: '₹', CAD: 'C$', AUD: 'A$',
  JPY: '¥', CNY: '¥', BRL: 'R$', GHS: '₵', TZS: 'TSh',
  UGX: 'USh', RWF: 'FRw', ETB: 'Br',
}

export function symbolFor(code: string): string {
  return CURRENCY_SYMBOLS[code] || code
}

export function fmtUsd(v: any): string {
  if (v == null) return '$0.00'
  const n = Number(v)
  if (Number.isNaN(n)) return String(v)
  return '$' + n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

export function fmtNum(v: any): string {
  if (v == null) return '0'
  const n = Number(v)
  if (Number.isNaN(n)) return String(v)
  return n.toLocaleString()
}

export function fmtDate(v: any): string {
  if (!v) return '—'
  const d = new Date(v)
  if (Number.isNaN(d.getTime())) return String(v)
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}

export function fmtDateTime(v: any): string {
  if (!v) return '—'
  const d = new Date(v)
  if (Number.isNaN(d.getTime())) return String(v)
  return d.toLocaleString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
}
