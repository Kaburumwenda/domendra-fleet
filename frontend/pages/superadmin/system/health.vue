<template>
  <div class="d-flex flex-column ga-4">
    <div class="d-flex align-center ga-3 flex-wrap">
      <div class="d-flex align-center justify-center rounded-xl" style="width: 48px; height: 48px; background: linear-gradient(135deg, #ec4899, #db2777)">
        <v-icon color="white">mdi-heart-pulse</v-icon>
      </div>
      <div>
        <h1 class="text-h5 font-weight-bold">System Health</h1>
        <p class="text-body-2 text-medium-emphasis mb-0">Platform services and resource counts</p>
      </div>
      <v-spacer />
      <v-btn icon="mdi-refresh" variant="tonal" :loading="pending" @click="refresh()" />
    </div>

    <v-row dense>
      <v-col cols="12" sm="6" md="3" v-for="(s, name) in services" :key="String(name)">
        <v-card elevation="0" border rounded="lg" class="pa-5 h-100 d-flex flex-column">
          <div class="d-flex align-center justify-space-between mb-3">
            <v-icon :color="s.ok ? 'success':'error'" size="large">{{ s.ok ? 'mdi-check-circle' : 'mdi-alert-circle' }}</v-icon>
            <v-chip :color="s.ok ? 'success':'error'" size="small" variant="tonal">{{ s.ok ? 'Operational' : 'Down' }}</v-chip>
          </div>
          <h3 class="text-subtitle-1 font-weight-bold text-capitalize">{{ name }}</h3>
          <p class="text-caption text-medium-emphasis mt-1">
            <span v-if="s.latency_ms != null">{{ s.latency_ms }}ms latency</span>
            <span v-else-if="s.workers != null">{{ s.workers }} workers</span>
            <span v-else-if="s.error" class="text-error">{{ s.error }}</span>
          </p>
        </v-card>
      </v-col>
    </v-row>

    <v-card elevation="0" border rounded="lg" class="pa-5">
      <div class="d-flex align-center ga-2 mb-3">
        <v-icon color="primary" size="small">mdi-database</v-icon>
        <h3 class="text-subtitle-1 font-weight-bold">Resource Counts</h3>
      </div>
      <v-row dense>
        <v-col cols="6" sm="4" md="2" v-for="(v, k) in counts" :key="String(k)">
          <div class="rounded-lg pa-3" style="background: #f8fafc; border: 1px solid #e2e8f0">
            <p class="text-caption text-capitalize text-medium-emphasis mb-0">{{ k }}</p>
            <p class="text-h6 font-weight-bold mb-0">{{ fmtNum(v) }}</p>
          </div>
        </v-col>
      </v-row>
    </v-card>

    <v-card elevation="0" border rounded="lg" class="pa-5">
      <div class="d-flex align-center ga-2 mb-3">
        <v-icon color="warning" size="small">mdi-domain</v-icon>
        <h3 class="text-subtitle-1 font-weight-bold">Recent Tenants</h3>
      </div>
      <v-table density="comfortable">
        <thead>
          <tr><th>Tenant</th><th>Schema</th><th>Status</th><th>Sub</th><th class="text-end">Requests</th></tr>
        </thead>
        <tbody>
          <tr v-for="t in recentTenants" :key="t.schema">
            <td><NuxtLink :to="`/superadmin/tenants/${t.schema}`" class="text-decoration-none text-on-surface font-weight-medium">{{ t.name }}</NuxtLink></td>
            <td class="text-body-2">{{ t.schema }}</td>
            <td><v-chip :color="t.is_active ? 'success':'error'" size="x-small" variant="flat">{{ t.is_active ? 'Active':'Suspended' }}</v-chip></td>
            <td><v-chip :color="subColor(t.subscription_status)" size="x-small" variant="tonal">{{ t.subscription_status }}</v-chip></td>
            <td class="text-right text-body-2">{{ fmtNum(t.requests) }}</td>
          </tr>
        </tbody>
      </v-table>
    </v-card>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'superadmin' })
const sa = useSuperAdmin()
const { data, pending, refresh } = await useAsyncData('sa-health', () => sa.systemHealth())

const services = computed(() => data.value?.services || {})
const counts = computed(() => data.value?.counts || {})
const recentTenants = computed(() => data.value?.recent_tenants || [])
function subColor(s: string) { return { active: 'success', past_due: 'warning', cancelled: 'error', none: 'grey', trialing: 'info' }[s] || 'grey' }
</script>
