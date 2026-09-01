<template>
  <v-app-bar flat color="surface" height="64">
    <v-app-bar-nav-icon @click="$emit('toggle')" />
    <v-toolbar-title class="text-h6 font-weight-semibold d-none d-sm-block text-on-surface">
      {{ pageTitleComputed }}
    </v-toolbar-title>
    <v-spacer />

    <v-chip size="small" variant="tonal" color="warning" prepend-icon="mdi-shield-crown" class="mr-2">
      Control Plane
    </v-chip>

    <v-btn variant="text" icon class="mr-1" @click="drawer = !drawer">
      <v-badge v-if="healthIssues" :content="healthIssues" color="error" floating>
        <v-icon>mdi-heart-pulse</v-icon>
      </v-badge>
      <v-icon v-else>mdi-heart-pulse</v-icon>
      <v-tooltip activator="parent" location="bottom">System Health</v-tooltip>
    </v-btn>

    <v-btn variant="text" icon class="mr-1" @click="openSearch = true">
      <v-icon>mdi-magnify</v-icon>
      <v-tooltip activator="parent" location="bottom">Quick Find</v-tooltip>
    </v-btn>

    <v-btn variant="text" icon class="mr-1" to="/app">
      <v-icon>mdi-view-dashboard-outline</v-icon>
      <v-tooltip activator="parent" location="bottom">Tenant App</v-tooltip>
    </v-btn>

    <!-- User Menu -->
    <v-menu offset-y>
      <template #activator="{ props }">
        <v-btn v-bind="props" variant="text" class="px-2">
          <div class="d-flex align-center justify-center mr-2" style="width: 32px; height: 32px; border-radius: 50%; background: linear-gradient(135deg, #6366f1, #4f46e5); flex-shrink: 0">
            <span class="text-white text-body-2 font-weight-semibold">{{ auth.initials || '?' }}</span>
          </div>
          <span class="text-body-2 font-weight-medium d-none d-sm-block">{{ auth.user?.email }}</span>
          <v-icon size="small" class="ml-1" color="grey-lighten-1">mdi-chevron-down</v-icon>
        </v-btn>
      </template>
      <v-list density="compact" min-width="220" nav>
        <v-list-item>
          <v-list-item-title class="text-body-2 font-weight-medium">{{ auth.fullName }}</v-list-item-title>
          <v-list-item-subtitle class="text-caption">Super Administrator</v-list-item-subtitle>
        </v-list-item>
        <v-divider />
        <v-list-item prepend-icon="mdi-cog-outline" title="System Health" to="/superadmin/system/health" />
        <v-list-item prepend-icon="mdi-history" title="Activity Log" to="/superadmin/system/audit" />
        <v-list-item prepend-icon="mdi-view-dashboard-outline" title="Tenant App" to="/app" />
        <v-divider />
        <v-list-item prepend-icon="mdi-logout" title="Logout" base-color="error" @click="handleLogout" />
      </v-list>
    </v-menu>

    <!-- Quick Find -->
    <v-dialog v-model="openSearch" max-width="600">
      <v-card rounded="lg" elevation="12">
        <v-card-text class="pa-0">
          <v-text-field
            v-model="searchQuery"
            label="Find a tenant, bill, user..."
            prepend-inner-icon="mdi-magnify"
            variant="solo"
            flat
            hide-details
            autofocus
            @keyup.enter="doSearch"
          />
          <v-list density="comfortable" v-if="searchResults.length">
            <v-list-item
              v-for="r in searchResults"
              :key="r.id"
              :prepend-icon="r.icon"
              :title="r.title"
              :subtitle="r.subtitle"
              @click="openSearch = false; navigateTo(r.to)"
            />
          </v-list>
          <div v-else-if="searchQuery && searchQuery.length > 1" class="text-center text-medium-emphasis py-6 text-body-2">
            No matches. Press Enter to search.
          </div>
        </v-card-text>
      </v-card>
    </v-dialog>
  </v-app-bar>
</template>

<script setup lang="ts">
defineProps<{ collapsed?: boolean }>()
const emit = defineEmits(['toggle'])

const auth = useAuthStore()
const route = useRoute()
const { $api } = useNuxtApp()
const openSearch = ref(false)
const searchQuery = ref('')
const searchResults = ref<{ id: string; icon: string; title: string; subtitle: string; to: string }[]>([])
const healthIssues = ref(0)

const pageTitles: Record<string, string> = {
  '/superadmin': 'Control Plane Overview',
  '/superadmin/tenants': 'Tenants',
  '/superadmin/billing/subscriptions': 'Subscriptions',
  '/superadmin/billing/bills': 'Bills',
  '/superadmin/billing/payments': 'Payments',
  '/superadmin/billing/plans': 'Billing Plans',
  '/superadmin/billing/rates': 'Exchange Rates',
  '/superadmin/usage': 'Usage Analytics',
  '/superadmin/system/audit': 'Activity Log',
  '/superadmin/system/health': 'System Health',
}

const pageTitleComputed = computed(() => {
  const exact = pageTitles[route.path]
  if (exact) return exact
  if (route.path.startsWith('/superadmin/tenants/')) return 'Tenant Detail'
  return 'SuperAdmin'
})

function handleLogout() {
  const rbac = useRbac()
  rbac.clearPermissions()
  auth.logout()
  navigateTo('/login')
}

async function doSearch() {
  const q = searchQuery.value.trim()
  if (q.length < 2) return
  try {
    const data: any = await $api('/superadmin/tenants/', { params: { search: q } })
    const results: any[] = data.results || data
    searchResults.value = results.slice(0, 8).map((t) => ({
      id: `tenant-${t.id}`,
      icon: 'mdi-domain',
      title: t.short_name,
      subtitle: `${t.schema_name} • ${t.email}`,
      to: `/superadmin/tenants/${t.schema_name}`,
    }))
  } catch {
    searchResults.value = []
  }
}

onMounted(async () => {
  try {
    const data: any = await $api('/superadmin/system-health/')
    for (const [k, v] of Object.entries(data.services || {})) {
      const ok = (v as any).ok
      if (!ok) healthIssues.value++
    }
  } catch {}
})
</script>
