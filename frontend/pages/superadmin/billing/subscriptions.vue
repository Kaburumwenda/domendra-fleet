<template>
  <div class="d-flex flex-column ga-4">
    <div class="d-flex align-center ga-3 flex-wrap">
      <div class="d-flex align-center justify-center rounded-xl" style="width: 48px; height: 48px; background: linear-gradient(135deg, #6366f1, #4f46e5)">
        <v-icon color="white">mdi-credit-card-clock-outline</v-icon>
      </div>
      <div>
        <h1 class="text-h5 font-weight-bold">Subscriptions</h1>
        <p class="text-body-2 text-medium-emphasis mb-0">Billing subscriptions across all tenants</p>
      </div>
      <v-spacer />
      <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" density="compact" variant="outlined" hide-details style="width: 240px" @keyup.enter="load" clearable @click:clear="search=''; load()" />
    </div>

    <v-card elevation="0" border rounded="lg">
      <v-data-table-server
        :items="rows" :items-length="total" :loading="loading" :headers="headers"
        :page="page" :items-per-page="perPage"
        @update:page="page=$event; load()"
        @update:items-per-page="perPage=$event; page=1; load()"
        density="comfortable" hover
      >
        <template #item.tenant_name="{ item }">
          <NuxtLink :to="`/superadmin/tenants/${item.tenant_schema}`" class="text-body-2 font-weight-medium text-decoration-none text-on-surface">{{ item.tenant_name }}</NuxtLink>
        </template>
        <template #item.status="{ item }">
          <v-chip size="small" :color="statusColor(item.status)" variant="tonal">{{ item.status }}</v-chip>
        </template>
        <template #item.request_count="{ item }">{{ fmtNum(item.request_count) }}</template>
        <template #item.estimated_cost_usd="{ item }">{{ fmtUsd(item.estimated_cost_usd) }}</template>
        <template #item.projected_cost_usd="{ item }">{{ fmtUsd(item.projected_cost_usd) }}</template>
        <template #item.monthly_average="{ item }">{{ fmtNum(item.monthly_average) }}/day</template>
        <template #item.billing_currency="{ item }"><v-chip size="x-small" variant="tonal">{{ item.billing_currency }}</v-chip></template>
        <template #item.auto_close="{ item }"><v-icon :color="item.auto_close ? 'success':'grey'" size="small">{{ item.auto_close ? 'mdi-lock-check':'mdi-lock-open' }}</v-icon></template>
        <template #item.current_period_end="{ item }">{{ fmtDate(item.current_period_end) }}</template>
      </v-data-table-server>
    </v-card>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'superadmin' })
const { $api } = useNuxtApp()
const search = ref('')
const page = ref(1)
const perPage = ref(25)
const total = ref(0)
const rows = ref<any[]>([])
const loading = ref(false)

const headers = [
  { title: 'Tenant', key: 'tenant_name' },
  { title: 'Status', key: 'status' },
  { title: 'Requests', key: 'request_count', align: 'end' as const },
  { title: 'Cost', key: 'estimated_cost_usd', align: 'end' as const },
  { title: 'Projected', key: 'projected_cost_usd', align: 'end' as const },
  { title: 'Avg/day', key: 'monthly_average', align: 'end' as const },
  { title: 'Currency', key: 'billing_currency' },
  { title: 'Auto-close', key: 'auto_close', align: 'center' as const },
  { title: 'Period End', key: 'current_period_end' },
]

function statusColor(s: string) { return { active: 'success', past_due: 'warning', cancelled: 'error', trialing: 'info' }[s] || 'grey' }

async function load() {
  loading.value = true
  try {
    const params: any = { page: page.value, page_size: perPage.value, ordering: '-created_at' }
    if (search.value) params.search = search.value
    const data: any = await $api('/superadmin/subscriptions/', { params })
    rows.value = data.results || data
    total.value = data.count || rows.value.length
  } catch (e) { console.error(e) } finally { loading.value = false }
}
onMounted(load)
watch(search, useDebounceFn(load, 400))
</script>
