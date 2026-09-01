<template>
  <div class="d-flex flex-column ga-4">
    <div class="d-flex align-center ga-3 flex-wrap">
      <div class="d-flex align-center justify-center rounded-xl" style="width: 48px; height: 48px; background: linear-gradient(135deg, #22c55e, #16a34a)">
        <v-icon color="white">mdi-cash-check</v-icon>
      </div>
      <div>
        <h1 class="text-h5 font-weight-bold">Payments</h1>
        <p class="text-body-2 text-medium-emphasis mb-0">Recorded payments across all tenants</p>
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
        <template #item.amount="{ item }"><span class="font-weight-bold">{{ fmtUsd(item.amount) }}</span></template>
        <template #item.method="{ item }"><v-chip size="x-small" variant="flat" :color="methodColor(item.method)">{{ item.method }}</v-chip></template>
        <template #item.created_at="{ item }">{{ fmtDateTime(item.created_at) }}</template>
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
  { title: 'Bill', key: 'bill' },
  { title: 'Amount', key: 'amount', align: 'end' as const },
  { title: 'Method', key: 'method' },
  { title: 'Reference', key: 'reference' },
  { title: 'Notes', key: 'notes' },
  { title: 'Date', key: 'created_at' },
]

function methodColor(m: string) { return { card: 'primary', bank: 'info', cash: 'success', wallet: 'warning', other: 'grey' }[m] || 'grey' }

async function load() {
  loading.value = true
  try {
    const params: any = { page: page.value, page_size: perPage.value, ordering: '-created_at' }
    const data: any = await $api('/superadmin/payments/', { params })
    rows.value = data.results || data
    total.value = data.count || rows.value.length
  } catch (e) { console.error(e) } finally { loading.value = false }
}
onMounted(load)
watch(search, useDebounceFn(load, 400))
</script>
