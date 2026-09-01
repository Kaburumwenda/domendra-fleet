<template>
  <div class="d-flex flex-column ga-4">
    <div class="d-flex align-center ga-3 flex-wrap">
      <div class="d-flex align-center justify-center rounded-xl" style="width: 48px; height: 48px; background: linear-gradient(135deg, #f59e0b, #d97706)">
        <v-icon color="white">mdi-file-document-multiple-outline</v-icon>
      </div>
      <div>
        <h1 class="text-h5 font-weight-bold">Bills</h1>
        <p class="text-body-2 text-medium-emphasis mb-0">Invoices issued across all tenants</p>
      </div>
      <v-spacer />
      <v-select v-model="filterStatus" :items="statusOpts" density="compact" variant="outlined" hide-details style="width: 180px" />
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
        <template #item.invoice_number="{ item }">
          <span class="text-body-2 font-weight-medium">{{ item.invoice_number || '—' }}</span>
        </template>
        <template #item.tenant_name="{ item }">
          <NuxtLink :to="`/superadmin/tenants/${item.tenant_schema}`" class="text-body-2 font-weight-medium text-decoration-none text-on-surface">{{ item.tenant_name }}</NuxtLink>
        </template>
        <template #item.status="{ item }">
          <v-chip size="small" :color="statusColor(item.status)" variant="flat">{{ item.status }}</v-chip>
        </template>
        <template #item.billing_month="{ item }">{{ fmtDate(item.billing_month) }}</template>
        <template #item.total_requests="{ item }">{{ fmtNum(item.total_requests) }}</template>
        <template #item.usage_cost_usd="{ item }">{{ fmtUsd(item.usage_cost_usd) }}</template>
        <template #item.grand_total_usd="{ item }"><span class="font-weight-bold">{{ fmtUsd(item.grand_total_usd) }}</span></template>
        <template #item.grand_total_local="{ item }">{{ symbolFor(item.billing_currency) }}{{ fmtNum(item.grand_total_local) }}</template>
        <template #item.due_date="{ item }">{{ fmtDate(item.due_date) }}</template>
        <template #item.paid_at="{ item }">{{ fmtDate(item.paid_at) }}</template>
      </v-data-table-server>
    </v-card>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'superadmin' })
const { $api } = useNuxtApp()
const search = ref('')
const filterStatus = ref('')
const statusOpts = [{ title: 'All', value: '' }, { title: 'Paid', value: 'paid' }, { title: 'Unpaid', value: 'unpaid' }, { title: 'Overdue', value: 'overdue' }, { title: 'Void', value: 'void' }]
const page = ref(1)
const perPage = ref(25)
const total = ref(0)
const rows = ref<any[]>([])
const loading = ref(false)

const headers = [
  { title: 'Invoice', key: 'invoice_number' },
  { title: 'Tenant', key: 'tenant_name' },
  { title: 'Status', key: 'status' },
  { title: 'Month', key: 'billing_month' },
  { title: 'Requests', key: 'total_requests', align: 'end' as const },
  { title: 'Usage', key: 'usage_cost_usd', align: 'end' as const },
  { title: 'Grand Total (USD)', key: 'grand_total_usd', align: 'end' as const },
  { title: 'Local', key: 'grand_total_local', align: 'end' as const },
  { title: 'Due', key: 'due_date' },
  { title: 'Paid', key: 'paid_at' },
]

function statusColor(s: string) { return { paid: 'success', unpaid: 'warning', overdue: 'error', void: 'grey' }[s] || 'grey' }

async function load() {
  loading.value = true
  try {
    const params: any = { page: page.value, page_size: perPage.value, ordering: '-billing_month' }
    if (search.value) params.search = search.value
    if (filterStatus.value) params.status = filterStatus.value
    const data: any = await $api('/superadmin/bills/', { params })
    rows.value = data.results || data
    total.value = data.count || rows.value.length
  } catch (e) { console.error(e) } finally { loading.value = false }
}
onMounted(load)
watch(search, useDebounceFn(load, 400))
watch(filterStatus, () => { page.value = 1; load() })
</script>
