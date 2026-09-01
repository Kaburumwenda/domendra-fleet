<template>
  <v-app-bar flat color="surface" height="64">
    <v-app-bar-nav-icon @click="$emit('toggle')" />
    <v-toolbar-title class="text-h6 font-weight-semibold d-none d-sm-block text-on-surface">
      {{ pageTitle }}
    </v-toolbar-title>
    <v-spacer />

    <!-- Dark Mode Toggle (dashboard only) -->
    <v-btn v-if="isDashboard" variant="text" icon class="mr-1" @click="toggleDark">
      <v-icon>{{ isDark ? 'mdi-white-balance-sunny' : 'mdi-weather-night' }}</v-icon>
      <v-tooltip activator="parent" location="bottom">
        {{ isDark ? 'Light Mode' : 'Dark Mode' }}
      </v-tooltip>
    </v-btn>

    <!-- Fullscreen Toggle -->
    <v-btn variant="text" icon class="mr-1" @click="toggleFullscreen">
      <v-icon>{{ isFullscreen ? 'mdi-fullscreen-exit' : 'mdi-fullscreen' }}</v-icon>
      <v-tooltip activator="parent" location="bottom">
        {{ isFullscreen ? 'Exit Fullscreen' : 'Enter Fullscreen' }}
      </v-tooltip>
    </v-btn>

    <!-- Notifications -->
    <v-btn variant="text" icon class="mr-1">
      <v-badge v-if="alertCount" :content="alertCount > 9 ? '9+' : alertCount" color="error" floating>
        <v-icon>mdi-bell-outline</v-icon>
      </v-badge>
      <v-icon v-else>mdi-bell-outline</v-icon>
    </v-btn>

    <!-- User Menu -->
    <v-menu offset-y>
      <template #activator="{ props }">
        <v-btn v-bind="props" variant="text" class="px-2">
          <div class="d-flex align-center justify-center mr-2" style="width: 32px; height: 32px; border-radius: 50%; background: #6366f1; flex-shrink: 0">
            <span class="text-white text-body-2 font-weight-semibold">{{ auth.initials || '?' }}</span>
          </div>
          <span class="text-body-2 font-weight-medium d-none d-sm-block text-on-surface-variant">{{ auth.fullName }}</span>
          <v-icon size="small" class="ml-1" color="grey-lighten-1">mdi-chevron-down</v-icon>
        </v-btn>
      </template>
      <v-list density="compact" min-width="220" nav>
        <v-list-item>
          <v-list-item-title class="text-body-2 font-weight-medium">{{ auth.fullName }}</v-list-item-title>
          <v-list-item-subtitle class="text-caption">{{ auth.user?.email }}</v-list-item-subtitle>
        </v-list-item>
        <v-divider />
        <v-list-item prepend-icon="mdi-view-dashboard-outline" title="Dashboard" to="/app" />
        <v-list-item v-if="auth.isAdmin" prepend-icon="mdi-shield-crown-outline" title="SuperAdmin" to="/superadmin" base-color="warning" />
        <v-list-item prepend-icon="mdi-home-outline" title="Back to site" to="/" />
        <v-list-item prepend-icon="mdi-logout" title="Logout" base-color="error" @click="handleLogout" />
      </v-list>
    </v-menu>
  </v-app-bar>
</template>

<script setup lang="ts">
defineProps<{ collapsed?: boolean }>()
defineEmits(['toggle'])

const auth = useAuthStore()
const route = useRoute()
const alertCount = ref(0)
const isFullscreen = ref(false)

const { isDark, toggle: toggleDark, init: initDark } = useDarkMode()
const isDashboard = computed(() => route.path.startsWith('/app'))

onMounted(() => {
  initDark()
})

function toggleFullscreen() {
  const doc = document as any
  const el = document.documentElement as any
  if (!doc.fullscreenElement && !doc.webkitFullscreenElement) {
    if (el.requestFullscreen) el.requestFullscreen()
    else if (el.webkitRequestFullscreen) el.webkitRequestFullscreen()
    isFullscreen.value = true
  } else {
    if (doc.exitFullscreen) doc.exitFullscreen()
    else if (doc.webkitExitFullscreen) doc.webkitExitFullscreen()
    isFullscreen.value = false
  }
}

function onFsChange() {
  const doc = document as any
  isFullscreen.value = !!(doc.fullscreenElement || doc.webkitFullscreenElement)
}

if (typeof document !== 'undefined') {
  document.addEventListener('fullscreenchange', onFsChange)
  document.addEventListener('webkitfullscreenchange', onFsChange)
}

onUnmounted(() => {
  if (typeof document !== 'undefined') {
    document.removeEventListener('fullscreenchange', onFsChange)
    document.removeEventListener('webkitfullscreenchange', onFsChange)
  }
})

const pageTitles: Record<string, string> = {
  '/app': 'Dashboard',
  '/app/vehicles': 'Vehicles & Assets',
  '/app/equipment': 'Equipment & Tools',
  '/app/lessors': 'Lessors',
  '/app/tires': 'Tire Management',
  '/app/contacts': 'Contacts & Drivers',
  '/app/drivers': 'Driver Management',
  '/app/dqf': 'Driver Qualification',
  '/app/documents': 'Document Vault',
  '/app/inspections': 'Inspections (DVIR)',
  '/app/issues': 'Issues',
  '/app/work-orders': 'Work Orders',
  '/app/reminders': 'Reminders',
  '/app/services': 'Services & Maintenance',
  '/app/garage': 'Garage & Workshop',
  '/app/recalls': 'Recalls & Campaigns',
  '/app/inventory': 'Parts & Inventory',
  '/app/fuel': 'Fuel & Energy',
  '/app/ifta': 'IFTA & Trip Logs',
  '/app/telematics': 'Telematics & GPS',
  '/app/locations': 'Locations & Geofences',
  '/app/dispatch': 'Dispatch & Routing',
  '/app/accidents': 'Accident Management',
  '/app/reports': 'Reports & Analytics',
  '/app/rentals/driver-hire-rates': 'Driver Hire Rates',
  '/app/notifications': 'Notifications',
  '/app/billing': 'Billing & Usage',
  '/app/settings': 'Settings',
}

const pageTitle = computed(() => {
  for (const key of Object.keys(pageTitles)) {
    if (route.path === key || route.path.startsWith(key + '/')) {
      return pageTitles[key]
    }
  }
  return 'Domendra'
})

function handleLogout() {
  const rbac = useRbac()
  rbac.clearPermissions()
  auth.logout()
  navigateTo('/login')
}

onMounted(async () => {
  if (auth.isAuthenticated) {
    try {
      const { $api } = useNuxtApp()
      const data = await $api('/dashboard/')
      alertCount.value = (data.alerts?.open_issues || 0) + (data.alerts?.overdue_reminders || 0) + (data.alerts?.expired_docs || 0)
    } catch {}
  }
})
</script>
