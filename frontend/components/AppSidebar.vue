<template>
  <v-navigation-drawer
    :rail="collapsed"
    permanent
    width="280"
    rail-width="76"
    class="premium-sidebar"
    elevation="0"
    border="0"
  >
    <!-- Brand -->
    <NuxtLink
      to="/app"
      class="d-flex align-center ga-3 px-5 premium-brand"
      style="height: 72px; text-decoration: none"
    >
      <div class="premium-logo" style="flex-shrink: 0">
        <img
          v-if="tenantLogo"
          :src="tenantLogo"
          alt="logo"
          style="width: 100%; height: 100%; object-fit: contain"
        />
        <img v-else src="/logo.png" alt="logo" style="width: 100%; height: 100%; object-fit: contain" />
      </div>
      <span
        v-if="!collapsed"
        class="text-subtitle-1 font-weight-bold text-truncate premium-brand-name"
      >{{ tenantDisplayName }}</span>
    </NuxtLink>
    <div class="premium-brand-divider" />

    <!-- Navigation -->
    <v-list nav density="compact" class="premium-nav px-3 py-2" style="flex: 1; overflow-y: auto">
      <template v-for="(item, groupIdx) in filteredNavItems" :key="item.path || item.label">
        <!-- Section label (when expanded) -->
        <div
          v-if="!collapsed && showSectionLabel(item)"
          class="premium-section-label"
        >
          {{ item.sectionLabel }}
        </div>

        <!-- Group with submenu -->
        <v-list-group
          v-if="item.children"
          :value="item.label"
          fluid
          class="premium-group"
        >
          <template #activator="{ props: activatorProps, isOpen }">
            <v-list-item
              v-bind="activatorProps"
              :prepend-icon="item.icon"
              :title="item.label"
              color="primary"
              rounded="xl"
              class="premium-item premium-group-activator"
              :class="{ 'premium-group-open': isOpen }"
            />
          </template>

          <div class="premium-group-items pb-1">
            <v-list-item
              v-for="child in item.children"
              :key="child.path"
              :to="child.path"
              :prepend-icon="child.icon"
              :title="child.label"
              color="primary"
              rounded="xl"
              class="premium-item premium-child-item"
            />
          </div>
        </v-list-group>

        <!-- Single item -->
        <v-list-item
          v-else
          :to="item.path"
          :prepend-icon="item.icon"
          :title="item.label"
          color="primary"
          rounded="xl"
          class="premium-item"
        />
      </template>
    </v-list>

    <!-- User panel -->
    <template #append>
      <div class="premium-user-divider" />
      <div class="premium-user-panel">
        <div class="d-flex align-center ga-3 px-2 py-2">
          <div class="premium-avatar" style="flex-shrink: 0">
            <span class="text-white text-body-2 font-weight-bold">{{ auth.initials || '?' }}</span>
          </div>
          <div v-if="!collapsed" style="min-width: 0" class="flex-1">
            <p class="text-body-2 font-weight-medium text-truncate mb-0 premium-user-name">{{ auth.fullName || 'User' }}</p>
            <p class="text-caption text-capitalize mb-0 premium-user-role">{{ rbac.primaryRole?.name || (rbac.myRoles.length ? rbac.myRoles[0]?.name : auth.role) }}</p>
          </div>
          <v-btn
            v-if="!collapsed"
            icon="mdi-logout-variant"
            size="x-small"
            variant="text"
            color="error"
            class="premium-logout-btn"
            @click="auth.logout()"
          />
        </div>
      </div>
    </template>
  </v-navigation-drawer>
</template>

<script setup lang="ts">
defineProps<{ collapsed?: boolean }>()

const auth = useAuthStore()
const rbac = useRbac()
const { load: loadTenant, logoUrl: tenantLogo, displayName: tenantDisplayName } = useTenant()

onMounted(() => { if (auth.isAuthenticated) loadTenant() })

function handleLogout() {
  rbac.clearPermissions()
  auth.logout()
  navigateTo('/login')
}

const sectionMap: Record<string, string> = {
  Dashboard: 'MAIN',
  Assets: 'ASSETS',
  Maintenance: 'MAINTENANCE',
  'Fuel & Energy': 'FLEET',
  Analytics: 'INSIGHTS',
  Operations: 'OPERATIONS',
  'Contacts & Drivers': 'OPERATIONS',
  'Driver Qualification': 'OPS',
  Documents: 'OPS',
  'Parts & Inventory': 'OPS',
  Notifications: 'BUSINESS',
  Reports: 'INSIGHTS',
  Billing: 'BUSINESS',
  Expenses: 'BUSINESS',
  Settings: 'SYSTEM',
  'IAM & Security': 'SECURITY',
}

const showSectionLabel = (item: { label?: string; sectionLabel?: string }) => {
  const sec = getSection(item)
  if (!sec) return false
  // Show only on the first item of a section; skip duplicates
  const idx = filteredNavItems.value.findIndex(n => getSection(n) === sec)
  return idx !== -1 && filteredNavItems.value[idx] === item
}

const getSection = (item: { label?: string; sectionLabel?: string }): string | undefined => {
  if (item.sectionLabel) return item.sectionLabel
  return item.label ? sectionMap[item.label] : undefined
}

/** A nav item may carry a `perm: 'module:action'` requirement; the item (or
 *  group) is hidden when the current user lacks that permission. Children
 *  without an explicit perm inherit visibility; children with their own perm
 *  are filtered individually. */
interface NavChild { path?: string; label: string; icon: string; perm?: string }
interface NavItem { path?: string; label: string; icon: string; sectionLabel?: string; children?: NavChild[]; perm?: string }

const navItems: NavItem[] = [
  { path: '/app', label: 'Dashboard', icon: 'mdi-chart-bar', sectionLabel: 'MAIN' },
  {
    label: 'Assets',
    icon: 'mdi-view-list-outline',
    sectionLabel: 'ASSETS',
    children: [
      { path: '/app/vehicles', label: 'Vehicles', icon: 'mdi-car', perm: 'vehicles:view' },
      { path: '/app/equipment', label: 'Equipment', icon: 'mdi-tools', perm: 'equipment:view' },
      { path: '/app/lessors', label: 'Lessors', icon: 'mdi-handshake-outline', perm: 'lessors:view' },
      { path: '/app/financing', label: 'Financing Monitor', icon: 'mdi-cash-multiple', perm: 'financing:view' },
      { path: '/app/tires', label: 'Tires', icon: 'mdi-tire', perm: 'tires:view' },
      { path: '/app/batteries', label: 'Batteries', icon: 'mdi-car-battery', perm: 'vehicles:view' },
    ],
  },
  {
    label: 'Maintenance',
    icon: 'mdi-wrench-outline',
    sectionLabel: 'MAINTENANCE',
    perm: 'maintenance:view',
    children: [
      { path: '/app/issues', label: 'Issues', icon: 'mdi-alert', perm: 'maintenance:view' },
      { path: '/app/work-orders', label: 'Work Orders', icon: 'mdi-wrench', perm: 'maintenance:view' },
      { path: '/app/services', label: 'Services', icon: 'mdi-wrench', perm: 'maintenance:view' },
      { path: '/app/reminders', label: 'Reminders', icon: 'mdi-bell-outline', perm: 'reminders:view' },
      { path: '/app/inspections', label: 'Inspections', icon: 'mdi-clipboard-check-outline', perm: 'inspections:view' },
      { path: '/app/garage', label: 'Garage', icon: 'mdi-sitemap', perm: 'garage:view' },
      { path: '/app/recalls', label: 'Recalls', icon: 'mdi-car-info', perm: 'recalls:view' },
    ],
  },
  {
    label: 'Fuel & Energy',
    icon: 'mdi-flash',
    sectionLabel: 'FLEET',
    children: [
      { path: '/app/fuel', label: 'Fuel & Energy', icon: 'mdi-gas-station', perm: 'fuel:view' },
      { path: '/app/ifta', label: 'IFTA & Trip Logs', icon: 'mdi-map-marker-path', perm: 'ifta:view' },
    ],
  },
  {
    label: 'Analytics',
    icon: 'mdi-chart-box-outline',
    sectionLabel: 'INSIGHTS',
    perm: 'reports:view',
    children: [
      { path: '/app/analytics/vehicles', label: 'Vehicles', icon: 'mdi-car-multiple', perm: 'reports:view' },
      { path: '/app/analytics/fuel-energy', label: 'Fuel & Energy', icon: 'mdi-flash', perm: 'reports:view' },
      { path: '/app/analytics/rentals', label: 'Car Hire & Rental', icon: 'mdi-car-key', perm: 'reports:view' },
    ],
  },
  { path: '/app/reports', label: 'Reports', icon: 'mdi-chart-line', perm: 'reports:view' },
  {
    label: 'Operations',
    icon: 'mdi-map-marker-radius',
    sectionLabel: 'OPERATIONS',
    children: [
      { path: '/app/telematics', label: 'Telematics & GPS', icon: 'mdi-crosshairs-gps', perm: 'telematics:view' },
      { path: '/app/locations', label: 'Locations & Geofences', icon: 'mdi-map-marker-multiple', perm: 'locations:view' },
      { path: '/app/dispatch', label: 'Dispatch', icon: 'mdi-map-outline', perm: 'dispatch:view' },
      { path: '/app/vehicle-monitor', label: 'Vehicle Monitor', icon: 'mdi-monitor-dashboard', perm: 'vehicles:view' },
      { path: '/app/rentals', label: 'Car Hire & Rental', icon: 'mdi-car-key', perm: 'rentals:view' },
      { path: '/app/rentals/driver-hire-rates', label: 'Driver Hire Rates', icon: 'mdi-account-cash-outline', perm: 'rentals:view' },
      { path: '/app/invoices', label: 'Invoices', icon: 'mdi-file-document-edit-outline', perm: 'billing:view' },
      { path: '/app/accidents', label: 'Accidents', icon: 'mdi-alert-circle-outline', perm: 'accidents:view' },
    ],
  },
  {
    label: 'Contacts & Drivers',
    icon: 'mdi-card-account-details-outline',
    children: [
      { path: '/app/contacts', label: 'Contacts', icon: 'mdi-card-account-details-outline', perm: 'contacts:view' },
      { path: '/app/drivers', label: 'Drivers', icon: 'mdi-steering', perm: 'drivers:view' },
    ],
  },
  { path: '/app/dqf', label: 'Driver Qualification', icon: 'mdi-account-check-outline', perm: 'dqf:view' },
  { path: '/app/documents', label: 'Documents', icon: 'mdi-file-document-outline', perm: 'documents:view' },
  { path: '/app/inventory', label: 'Parts & Inventory', icon: 'mdi-package-variant-closed', perm: 'inventory:view' },
  { path: '/app/notifications', label: 'Notifications', icon: 'mdi-bell-ring-outline', perm: 'notifications:view' },
  { path: '/app/billing', label: 'Billing', icon: 'mdi-currency-usd', perm: 'billing:view' },
  { path: '/app/expenses', label: 'Expenses', icon: 'mdi-receipt-text-outline', perm: 'reports:view' },
  {
    label: 'Settings',
    icon: 'mdi-cog-outline',
    sectionLabel: 'SYSTEM',
    perm: 'settings:view',
    children: [
      { path: '/app/settings', label: 'Company Profile', icon: 'mdi-office-building-outline', perm: 'settings:view' },
      { path: '/app/settings/currency', label: 'Currency', icon: 'mdi-cash', perm: 'settings:view' },
    ],
  },
  {
    label: 'IAM & Security',
    icon: 'mdi-shield-check-outline',
    sectionLabel: 'IAM & SECURITY',
    perm: 'users:view',
    children: [
      { path: '/app/settings/staff', label: 'Staff Management', icon: 'mdi-account-supervisor-outline', perm: 'users:view' },
      { path: '/app/settings/roles', label: 'Roles & Permissions', icon: 'mdi-shield-key-outline', perm: 'users:view' },
      { path: '/app/audit', label: 'Audit Logs', icon: 'mdi-history', perm: 'users:view' },
    ],
  },
]

const filteredNavItems = computed<NavItem[]>(() => {
  // Use ``rbac.canCode()`` / ``rbac.can()`` directly rather than a local
  // wrapper that reads ``rbac.isAdmin`` — accessing a ComputedRef as a
  // plain-object property (``rbac.isAdmin``) yields the ref object which
  // is always truthy, so the wrapper would grant everything.  The can/
  // canCode helpers on the composable correctly unwrap via ``.value``.
  const canCode = (code?: string) => {
    if (!code) return true
    return rbac.canCode(code)
  }
  return navItems
    .map((item) => {
      if (item.children) {
        // Filter children individually. Children with their own `perm`
        // are checked independently so a user with e.g. `inspections:view`
        // sees that child even if the group-level perm (e.g.
        // `maintenance:view`) is not granted.  Children without an
        // explicit `perm` inherit the group's `perm` (or are unguarded
        // if the group has none either).
        const kids = item.children.filter((c) => {
          if (c.perm) return canCode(c.perm)
          return canCode(item.perm)
        })
        if (kids.length === 0) return null
        return { ...item, children: kids }
      }
      return canCode(item.perm) ? item : null
    })
    .filter((i): i is NavItem => i !== null)
})
</script>

<style scoped>
.premium-sidebar {
  background: rgb(var(--v-theme-surface)) !important;
  border-right: 1px solid rgba(var(--v-theme-on-surface), 0.08) !important;
  box-shadow: 0 0 40px rgba(var(--v-theme-on-surface), 0.04);
}

/* Brand */
.premium-brand {
  gap: 12px;
}
.premium-logo {
  width: 42px;
  height: 42px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #6366f1 0%, #4f46e5 100%);
  box-shadow: 0 4px 12px rgba(99, 102, 241, 0.35);
}
.premium-brand-name {
  color: rgb(var(--v-theme-on-surface));
  letter-spacing: -0.3px;
}
.premium-brand-divider {
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(var(--v-theme-on-surface), 0.1), transparent);
  margin: 0 20px;
}

/* Section labels */
.premium-section-label {
  font-size: 10px;
  letter-spacing: 1.4px;
  font-weight: 700;
  color: rgba(var(--v-theme-on-surface), 0.45);
  padding: 10px 12px 4px;
  text-transform: uppercase;
}

/* Nav items */
.premium-nav :deep(.v-list-item) {
  min-height: 36px;
  margin-bottom: 1px;
  font-weight: 500;
  color: rgba(var(--v-theme-on-surface), 0.7);
  transition: all 0.18s ease;
}
.premium-item {
  letter-spacing: -0.1px !important;
}
.premium-nav :deep(.v-list-item:hover:not(.v-list-item--active)) {
  background: rgba(var(--v-theme-on-surface), 0.06);
  color: rgb(var(--v-theme-on-surface));
}
.premium-nav :deep(.v-list-item--active) {
  background: linear-gradient(135deg, #6366f1 0%, #4f46e5 100%);
  color: #fff !important;
  box-shadow: 0 4px 12px rgba(99, 102, 241, 0.3);
}
.premium-nav :deep(.v-list-item--active .v-icon) {
  color: #fff !important;
}

/* Group */
.premium-group-activator {
  font-weight: 600 !important;
}
.premium-group :deep(.v-list-item--active > .v-list-item__append > .v-icon) {
  color: #6366f1;
}
.premium-group :deep(.v-icon) {
  transition: transform 0.2s ease, color 0.18s ease;
}
.premium-group-open {
  color: rgb(var(--v-theme-on-surface));
}

/* Submenu children */
.premium-group-items {
  padding-left: 16px;
  margin-left: 18px;
  border-left: 1.5px solid rgba(var(--v-theme-on-surface), 0.12);
}
.premium-child-item {
  font-size: 13px !important;
  min-height: 34px !important;
}
.premium-child-dot {
  opacity: 0;
  transition: opacity 0.18s ease;
}
.premium-child-item:hover .premium-child-dot {
  opacity: 0.6;
}
.premium-child-item.v-list-item--active .premium-child-dot {
  opacity: 1;
  color: #6366f1;
}

/* User panel */
.premium-user-divider {
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(var(--v-theme-on-surface), 0.12), transparent);
  margin: 0 20px 10px;
}
.premium-user-panel {
  padding-bottom: 12px;
}
.premium-avatar {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #6366f1 0%, #4f46e5 100%);
  box-shadow: 0 4px 10px rgba(99, 102, 241, 0.3);
}
.premium-user-name {
  color: rgb(var(--v-theme-on-surface));
  font-weight: 600;
}
.premium-user-role {
  color: rgba(var(--v-theme-on-surface), 0.5);
  letter-spacing: 0.3px;
}
.premium-logout-btn {
  opacity: 0;
  transition: opacity 0.18s ease;
}
.premium-user-panel:hover .premium-logout-btn {
  opacity: 1;
}

/* Scrollbar */
.premium-nav::-webkit-scrollbar {
  width: 6px;
}
.premium-nav::-webkit-scrollbar-track {
  background: transparent;
}
.premium-nav::-webkit-scrollbar-thumb {
  background: rgba(var(--v-theme-on-surface), 0.18);
  border-radius: 3px;
}
.premium-nav::-webkit-scrollbar-thumb:hover {
  background: rgba(var(--v-theme-on-surface), 0.32);
}
</style>
