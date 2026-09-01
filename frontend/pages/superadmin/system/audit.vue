<template>
  <div class="d-flex flex-column ga-4">
    <div class="d-flex align-center ga-3 flex-wrap">
      <div class="d-flex align-center justify-center rounded-xl" style="width: 48px; height: 48px; background: linear-gradient(135deg, #64748b, #475569)">
        <v-icon color="white">mdi-history</v-icon>
      </div>
      <div>
        <h1 class="text-h5 font-weight-bold">Activity Log</h1>
        <p class="text-body-2 text-medium-emphasis mb-0">Cross-tenant audit log of all write operations</p>
      </div>
      <v-spacer />
      <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="User email, path..." density="compact" variant="outlined" hide-details style="width: 240px" @keyup.enter="load" clearable @click:clear="search=''; load()" />
      <v-select v-model="filterAction" :items="actionOpts" density="compact" variant="outlined" hide-details style="width: 160px" />
      <v-btn icon="mdi-refresh" variant="tonal" :loading="loading" @click="load" />
    </div>

    <v-row dense>
      <v-col cols="12" sm="6" md="2" v-for="(c, a) in byAction" :key="a">
        <v-card elevation="0" border rounded="lg" class="pa-3 d-flex align-center ga-2">
          <v-avatar size="28" rounded :color="actionColor(a)" variant="flat"><v-icon size="small" :icon="actionIcon(String(a))" /></v-avatar>
          <div><p class="text-h6 font-weight-bold mb-0">{{ c }}</p><p class="text-caption text-capitalize text-medium-emphasis mb-0">{{ a }}</p></div>
        </v-card>
      </v-col>
    </v-row>

    <v-card elevation="0" border rounded="lg">
      <div class="overflow-y-auto" style="max-height: 600px">
        <v-timeline density="compact" class="pa-4">
          <v-timeline-item v-for="log in rows" :key="log.id" :dot-color="actionColor(log.action)" size="x-small">
            <template #icon><v-icon size="x-small" :icon="actionIcon(log.action)" /></template>
            <div class="d-flex align-center justify-space-between flex-wrap ga-2">
              <div class="d-flex align-center ga-2 flex-wrap">
                <v-chip :color="actionColor(log.action)" size="x-small" variant="flat" class="text-capitalize">{{ log.action }}</v-chip>
                <span class="text-body-2 font-weight-medium">{{ log.resource_type || log.path }}</span>
                <v-chip v-if="log.tenant_name" size="x-small" variant="tonal" color="primary">{{ log.tenant_name }}</v-chip>
                <v-chip v-if="log.method" size="x-small" variant="tonal">{{ log.method }}</v-chip>
                <v-chip v-if="log.status_code" size="x-small" variant="tonal" :color="statusChip(log.status_code)">{{ log.status_code }}</v-chip>
              </div>
              <span class="text-caption text-medium-emphasis">{{ fmtDateTime(log.timestamp) }} · {{ log.user_name }}</span>
            </div>
            <p v-if="log.ip_address" class="text-caption text-medium-emphasis mb-0">{{ log.ip_address }}</p>
          </v-timeline-item>
        </v-timeline>
        <div v-if="!rows.length" class="text-center text-medium-emphasis py-8 text-body-2">No activity matches your filters</div>
      </div>
    </v-card>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'superadmin' })
const sa = useSuperAdmin()
const rows = ref<any[]>([])
const byAction = ref<Record<string, number>>({})
const loading = ref(false)
const search = ref('')
const filterAction = ref('')
const actionOpts = [{ title: 'All', value: '' }, { title: 'Create', value: 'create' }, { title: 'Update', value: 'update' }, { title: 'Delete', value: 'delete' }]

function actionColor(a: string) { return { create: 'success', update: 'info', delete: 'error', login: 'primary', logout: 'warning', view: 'grey', export: 'secondary' }[a] || 'grey' }
function actionIcon(a: string) { return { create: 'mdi-plus', update: 'mdi-pencil', delete: 'mdi-delete', login: 'mdi-login', logout: 'mdi-logout', view: 'mdi-eye', export: 'mdi-download' }[a] || 'mdi-circle-small' }
function statusChip(c: number) { return c < 300 ? 'success' : c < 400 ? 'info' : c < 500 ? 'warning' : 'error' }

async function load() {
  loading.value = true
  try {
    const filters: any = {}
    if (filterAction.value) filters.action = filterAction.value
    if (search.value) filters.search = search.value
    const data: any = await sa.audit(500, filters)
    rows.value = data.results || []
    byAction.value = data.by_action || {}
  } catch (e) { console.error(e) } finally { loading.value = false }
}
onMounted(load)
watch(filterAction, () => load())
</script>
