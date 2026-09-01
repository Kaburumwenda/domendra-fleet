<template>
  <v-navigation-drawer
    :rail="collapsed"
    permanent
    width="280"
    rail-width="76"
    class="sa-sidebar"
    elevation="0"
    border="0"
  >
    <!-- Brand -->
    <NuxtLink
      to="/superadmin"
      class="d-flex align-center ga-3 px-5 sa-brand"
      style="height: 72px; text-decoration: none"
    >
      <div class="sa-logo" style="flex-shrink: 0">
        <v-icon color="white" size="22">mdi-shield-crown-outline</v-icon>
      </div>
      <span
        v-if="!collapsed"
        class="text-subtitle-1 font-weight-bold sa-brand-name"
      >SuperAdmin</span>
    </NuxtLink>
    <div class="sa-brand-divider" />

    <!-- Navigation -->
    <v-list nav density="compact" class="sa-nav px-3 py-2" style="flex: 1; overflow-y: auto">
      <div v-if="!collapsed" class="sa-section-label">CONTROL PLANE</div>
      <v-list-item
        :to="item.path"
        :prepend-icon="item.icon"
        :title="item.label"
        color="primary"
        rounded="xl"
        class="sa-item"
        v-for="item in navItems"
        :key="item.path"
      />
    </v-list>

    <!-- User panel -->
    <template #append>
      <div class="sa-user-divider" />
      <div class="sa-user-panel">
        <div class="d-flex align-center ga-3 px-2 py-2">
          <div class="sa-avatar" style="flex-shrink: 0">
            <span class="text-white text-body-2 font-weight-bold">{{ auth.initials || '?' }}</span>
          </div>
          <div v-if="!collapsed" style="min-width: 0" class="flex-1">
            <p class="text-body-2 font-weight-medium text-truncate mb-0 sa-user-name">{{ auth.fullName || 'Super Admin' }}</p>
            <p class="text-caption mb-0 sa-user-role">Super Administrator</p>
          </div>
          <v-btn
            v-if="!collapsed"
            icon="mdi-logout-variant"
            size="x-small"
            variant="text"
            color="error"
            @click="logout"
          />
        </div>
      </div>
    </template>
  </v-navigation-drawer>
</template>

<script setup lang="ts">
defineProps<{ collapsed?: boolean }>()

const auth = useAuthStore()
const { $swal } = useNuxtApp()

const navItems = [
  { path: '/superadmin', label: 'Overview', icon: 'mdi-chart-box-outline' },
  { path: '/superadmin/tenants', label: 'Tenants', icon: 'mdi-domain' },
  { path: '/superadmin/billing/subscriptions', label: 'Subscriptions', icon: 'mdi-credit-card-clock-outline' },
  { path: '/superadmin/billing/bills', label: 'Bills', icon: 'mdi-file-document-multiple-outline' },
  { path: '/superadmin/billing/payments', label: 'Payments', icon: 'mdi-cash-check' },
  { path: '/superadmin/billing/plans', label: 'Plans', icon: 'mdi-package-variant-closed' },
  { path: '/superadmin/billing/rates', label: 'Exchange Rates', icon: 'mdi-currency-usd' },
  { path: '/superadmin/usage', label: 'Usage Analytics', icon: 'mdi-chart-areaspline' },
  { path: '/superadmin/system/audit', label: 'Activity Log', icon: 'mdi-history' },
  { path: '/superadmin/system/health', label: 'System Health', icon: 'mdi-heart-pulse' },
]

function logout() {
  const rbac = useRbac()
  rbac.clearPermissions()
  auth.logout()
  navigateTo('/login')
}
</script>

<style scoped>
.sa-sidebar {
  background: rgb(var(--v-theme-surface)) !important;
  border-right: 1px solid rgba(var(--v-theme-on-surface), 0.08) !important;
  box-shadow: 0 0 40px rgba(var(--v-theme-on-surface), 0.04);
}

.sa-brand { gap: 12px; }
.sa-logo {
  width: 42px; height: 42px; border-radius: 12px;
  display: flex; align-items: center; justify-content: center;
  background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
  box-shadow: 0 4px 12px rgba(15, 23, 42, 0.35);
}
.sa-brand-name {
  color: rgb(var(--v-theme-on-surface));
  letter-spacing: -0.3px;
}
.sa-brand-divider {
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(var(--v-theme-on-surface), 0.1), transparent);
  margin: 0 20px;
}

.sa-section-label {
  font-size: 10px;
  letter-spacing: 1.4px;
  font-weight: 700;
  color: rgba(var(--v-theme-on-surface), 0.45);
  padding: 10px 12px 4px;
  text-transform: uppercase;
}

.sa-nav :deep(.v-list-item) {
  min-height: 36px;
  margin-bottom: 1px;
  font-weight: 500;
  color: rgba(var(--v-theme-on-surface), 0.7);
  transition: all 0.18s ease;
}
.sa-nav :deep(.v-list-item:hover:not(.v-list-item--active)) {
  background: rgba(var(--v-theme-on-surface), 0.06);
  color: rgb(var(--v-theme-on-surface));
}
.sa-nav :deep(.v-list-item--active) {
  background: linear-gradient(135deg, #6366f1 0%, #4f46e5 100%);
  color: #fff !important;
  box-shadow: 0 4px 12px rgba(99, 102, 241, 0.3);
}
.sa-nav :deep(.v-list-item--active .v-icon) { color: #fff !important; }

.sa-user-divider {
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(var(--v-theme-on-surface), 0.1), transparent);
  margin: 0 16px 8px;
}
.sa-user-panel { padding: 4px 8px 12px; }
.sa-avatar {
  width: 36px; height: 36px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  background: linear-gradient(135deg, #6366f1, #4f46e5);
}
.sa-user-name { color: rgb(var(--v-theme-on-surface)); }
.sa-user-role { color: rgba(var(--v-theme-on-surface), 0.5); font-weight: 500; }
</style>
