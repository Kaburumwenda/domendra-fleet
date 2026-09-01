<template>
  <v-card elevation="0" border rounded="lg" class="pa-5">
    <div class="d-flex align-center justify-space-between mb-4 flex-wrap ga-2">
      <div class="d-flex align-center ga-2">
        <v-icon color="error" size="small">mdi-cash-off</v-icon>
        <h3 class="text-subtitle-1 font-weight-bold section-heading">Cost Analysis</h3>
      </div>
      <div class="d-flex ga-1">
        <v-chip size="small" variant="tonal" color="error">Variable: {{ currencySymbol }}{{ formatNum(data?.total_variable) }}</v-chip>
        <v-chip size="small" variant="tonal" color="secondary">Fixed: {{ currencySymbol }}{{ formatNum(data?.total_fixed) }}</v-chip>
        <v-chip size="small" variant="tonal" color="grey">Total: {{ currencySymbol }}{{ formatNum(data?.total) }}</v-chip>
        <v-btn variant="text" size="small" prepend-icon="mdi-download" color="primary" @click="exportCsv">Export</v-btn>
      </div>
    </div>

    <v-row dense>
      <!-- Cost by Category -->
      <v-col cols="12" md="5">
        <div class="mb-2 text-caption font-weight-medium text-medium-emphasis">Cost by Category</div>
        <div class="d-flex flex-column ga-1">
          <div v-for="cat in data?.by_category || []" :key="cat.category" class="d-flex align-center justify-space-between rounded-lg px-3 py-2" :style="{ background: cat.color + '08' }">
            <div class="d-flex align-center ga-2">
              <div class="d-flex align-center justify-center rounded" style="width: 28px; height: 28px; background: cat.color + '15">
                <v-icon size="x-small" :color="cat.color.replace('#', '')">{{ cat.icon }}</v-icon>
              </div>
              <div>
                <div class="text-body-2 font-weight-medium">{{ cat.category }}</div>
                <div class="text-caption text-medium-emphasis">{{ cat.type }}</div>
              </div>
            </div>
            <div class="text-right">
              <div class="text-subtitle-2 font-weight-bold" :style="{ color: cat.color }">{{ currencySymbol }}{{ formatNum(cat.amount) }}</div>
              <div class="text-caption text-medium-emphasis">{{ pct(cat.amount, data?.total) }}%</div>
            </div>
          </div>
        </div>
      </v-col>

      <!-- Cost by Vehicle -->
      <v-col cols="12" md="7">
        <div class="mb-2 text-caption font-weight-medium text-medium-emphasis">Cost by Vehicle (Top 10)</div>
        <v-data-table
          :headers="vehicleHeaders"
          :items="(data?.by_vehicle || []).slice(0, 10)"
          density="compact"
          hide-default-footer
          class="rounded-lg"
        >
          <template #item.fuel_cost="{ value }"><span style="color: #d97706">{{ currencySymbol }}{{ formatNum(value) }}</span></template>
          <template #item.charging_cost="{ value }"><span style="color: #059669">{{ currencySymbol }}{{ formatNum(value) }}</span></template>
          <template #item.service_cost="{ value }"><span style="color: #2563eb">{{ currencySymbol }}{{ formatNum(value) }}</span></template>
          <template #item.fixed_cost="{ value }"><span style="color: #6b7280">{{ currencySymbol }}{{ formatNum(value) }}</span></template>
          <template #item.total_cost="{ value }"><span class="font-weight-bold" style="color: #991b1b">{{ currencySymbol }}{{ formatNum(value) }}</span></template>
        </v-data-table>
      </v-col>
    </v-row>

    <v-divider class="my-4" />

    <!-- Service Cost by Type -->
    <div class="mb-2 text-caption font-weight-medium text-medium-emphasis">Service Cost by Type</div>
    <div class="d-flex flex-wrap ga-2">
      <v-chip v-for="st in data?.by_service_type || []" :key="st.type" size="small" variant="tonal" color="blue-grey">
        {{ st.type.replace(/_/g, ' ') }}: {{ currencySymbol }}{{ formatNum(st.cost) }} ({{ st.count }}x)
      </v-chip>
    </div>
  </v-card>
</template>

<script setup lang="ts">
defineProps<{ data: any }>()
const { currencySymbol } = useCurrency()

const vehicleHeaders = [
  { title: 'Vehicle', key: 'vehicle', width: '25%' },
  { title: 'Fuel', key: 'fuel_cost', align: 'end' as const },
  { title: 'EV Charge', key: 'charging_cost', align: 'end' as const },
  { title: 'Service', key: 'service_cost', align: 'end' as const },
  { title: 'Fixed', key: 'fixed_cost', align: 'end' as const },
  { title: 'Total', key: 'total_cost', align: 'end' as const },
]

function formatNum(n: number | undefined) {
  if (!n) return '0'
  return Math.round(n).toLocaleString()
}
function pct(val: number, total: number | undefined) {
  if (!val || !total) return 0
  return Math.round(val / total * 100)
}

function exportCsv() {
  if (!props.data?.by_vehicle?.length) return
  const rows = ['Vehicle,Fuel,Charging,Service,Fixed,Total']
  for (const v of props.data.by_vehicle) {
    rows.push(`"${v.vehicle}",${v.fuel_cost},${v.charging_cost},${v.service_cost},${v.fixed_cost},${v.total_cost}`)
  }
  const blob = new Blob([rows.join('\n')], { type: 'text/csv' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `cost-analysis-${new Date().toISOString().slice(0, 10)}.csv`
  a.click()
  URL.revokeObjectURL(url)
}
</script>

<style scoped>
.section-heading { color: #1e293b; }
.v-theme--dark .section-heading { color: #e2e8f0; }
</style>
