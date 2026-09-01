<template>
  <div class="d-flex flex-column ga-4">
    <v-card elevation="0" border class="pa-5">
      <div class="d-flex align-center justify-space-between mb-3">
        <h3 class="text-subtitle-2 font-weight-medium d-flex align-center ga-2 section-heading">
          <v-icon size="small" color="primary">mdi-shape</v-icon> Vehicle Type Analysis
        </h3>
        <v-chip size="small" variant="tonal" color="primary">{{ typeRows.length }} types</v-chip>
      </div>

      <!-- KPI mini-cards per type -->
      <v-row dense class="mb-3">
        <v-col cols="6" md="3" v-for="t in typeSummary" :key="t.label">
          <div class="type-kpi" :style="{ borderLeft: `4px solid ${t.color}` }">
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 font-weight-medium">{{ t.label }}</span>
              <v-icon size="16" :color="t.iconColor">{{ t.icon }}</v-icon>
            </div>
            <p class="text-h6 font-weight-bold mt-1 kpi-value">{{ t.value }}</p>
            <p class="text-caption text-medium-emphasis">{{ t.sub }}</p>
          </div>
        </v-col>
      </v-row>

      <!-- Charts -->
      <v-row dense>
        <v-col cols="12" md="6">
          <DashboardChart :option="typeCountOption" title="Vehicles by Type" icon="mdi-shape" height="260px" />
        </v-col>
        <v-col cols="12" md="6">
          <DashboardChart :option="typeRevenueOption" title="Revenue by Type" icon="mdi-cash" height="260px" />
        </v-col>
      </v-row>
      <v-row dense>
        <v-col cols="12" md="6">
          <DashboardChart :option="typeMileageOption" title="Avg Mileage by Type" icon="mdi-speedometer" height="260px" />
        </v-col>
        <v-col cols="12" md="6">
          <DashboardChart :option="typeServiceOption" title="Service Cost by Type" icon="mdi-wrench" height="260px" />
        </v-col>
      </v-row>

      <!-- Table -->
      <v-data-table
        :items="typeRows"
        :headers="typeHeaders"
        density="compact"
        :items-per-page="10"
        class="mt-3"
      >
        <template #item.vehicle_type="{ item }">
          <span class="font-weight-medium text-capitalize">{{ (item as any).vehicle_type }}</span>
        </template>
        <template #item.revenue="{ item }">
          <span class="font-weight-bold" style="color: #059669">{{ currencySymbol }}{{ Number((item as any).revenue || 0).toLocaleString() }}</span>
        </template>
        <template #item.service_cost="{ item }">
          <span style="color: #d97706">{{ currencySymbol }}{{ Number((item as any).service_cost || 0).toLocaleString() }}</span>
        </template>
        <template #item.total_purchase_value="{ item }">
          {{ currencySymbol }}{{ Number((item as any).total_purchase_value || 0).toLocaleString() }}
        </template>
        <template #item.avg_mileage="{ item }">
          {{ Number((item as any).avg_mileage || 0).toLocaleString() }}
        </template>
        <template #item.ev_count="{ item }">
          <v-chip v-if="(item as any).ev_count" size="x-small" variant="tonal" color="info">
            <v-icon start size="x-small">mdi-ev-station</v-icon>{{ (item as any).ev_count }}
          </v-chip>
          <span v-else class="text-medium-emphasis">—</span>
        </template>
        <template #item.status_breakdown="{ item }">
          <div class="d-flex align-center ga-1">
            <v-chip size="x-small" variant="tonal" color="success">{{ (item as any).active_count }}</v-chip>
            <v-chip v-if="(item as any).in_maintenance_count" size="x-small" variant="tonal" color="warning">{{ (item as any).in_maintenance_count }}</v-chip>
            <v-chip v-if="(item as any).out_of_service_count" size="x-small" variant="tonal" color="error">{{ (item as any).out_of_service_count }}</v-chip>
          </div>
        </template>
      </v-data-table>
    </v-card>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ data: any }>()
const { currencySymbol } = useCurrency()

const data = computed(() => props.data)

const typeRows = computed(() => {
  const rows = data.value?.type_analysis || []
  return rows.map((r: any) => ({
    ...r,
    avg_mileage: Math.round(r.avg_mileage || 0),
    total_purchase_value: Math.round(r.total_purchase_value || 0),
    revenue: Math.round(r.revenue || 0),
    service_cost: Math.round(r.service_cost || 0),
  }))
})

const typeSummary = computed(() => {
  const rows = typeRows.value
  const total = rows.reduce((s: number, r: any) => s + (r.count || 0), 0)
  const totalRev = rows.reduce((s: number, r: any) => s + (r.revenue || 0), 0)
  const totalActive = rows.reduce((s: number, r: any) => s + (r.active_count || 0), 0)
  const totalEv = rows.reduce((s: number, r: any) => s + (r.ev_count || 0), 0)
  return [
    { label: 'Vehicle Types', value: rows.length, sub: `${total} vehicles`, icon: 'mdi-shape', iconColor: 'primary', color: '#6366f1' },
    { label: 'Active Vehicles', value: totalActive, sub: `${Math.max(total - totalActive, 0)} inactive`, icon: 'mdi-car-connected', iconColor: 'success', color: '#10b981' },
    { label: 'Type Revenue', value: `${currencySymbol.value}${totalRev.toLocaleString(undefined, { maximumFractionDigits: 0 })}`, sub: 'total revenue', icon: 'mdi-cash', iconColor: 'warning', color: '#f59e0b' },
    { label: 'Electric/Hydrogen', value: totalEv, sub: 'across types', icon: 'mdi-ev-station', iconColor: 'info', color: '#0ea5e9' },
  ]
})

const typeHeaders = [
  { title: 'Vehicle Type', key: 'vehicle_type' },
  { title: 'Count', key: 'count', width: '70px' },
  { title: 'Revenue', key: 'revenue' },
  { title: 'Service Cost', key: 'service_cost' },
  { title: 'Fleet Value', key: 'total_purchase_value' },
  { title: 'Avg Mileage', key: 'avg_mileage' },
  { title: 'Status', key: 'status_breakdown' },
  { title: 'EV', key: 'ev_count', width: '70px' },
]

// ---- Chart helpers ----
const gradient = (c1: string, c2: string) => ({ type: 'linear', x: 0, y: 0, x2: 0, y2: 1, colorStops: [
  { offset: 0, color: c1 }, { offset: 1, color: c2 }] })

const tooltip = {
  trigger: 'axis', axisPointer: { type: 'shadow' },
  backgroundColor: '#1e293b', borderColor: '#334155', textStyle: { color: '#f1f5f9' },
}

const grid = { left: '3%', right: '4%', bottom: '3%', containLabel: true }

const typeCountOption = computed(() => {
  const rows = typeRows.value
  return {
    tooltip, grid,
    xAxis: { type: 'category', data: rows.map((r: any) => r.vehicle_type), axisLabel: { rotate: 30, fontSize: 10 } },
    yAxis: { type: 'value' },
    series: [{
      type: 'bar', data: rows.map((r: any) => r.count), barWidth: '55%',
      itemStyle: { color: gradient('#6366f1', '#4f46e5'), borderRadius: [6, 6, 0, 0] },
    }],
  }
})

const typeRevenueOption = computed(() => {
  const rows = typeRows.value
  return {
    tooltip: { ...tooltip,
      formatter: (params: any) => { const p = Array.isArray(params) ? params[0] : params; return `${p.name}<br/>Revenue: ${currencySymbol.value}${Number(p.value).toLocaleString()}` }
    },
    grid,
    xAxis: { type: 'category', data: rows.map((r: any) => r.vehicle_type), axisLabel: { rotate: 30, fontSize: 10 } },
    yAxis: { type: 'value', axisLabel: { formatter: (v: number) => currencySymbol.value + (v >= 1000 ? (v / 1000).toFixed(0) + 'k' : v) } },
    series: [{
      type: 'bar', data: rows.map((r: any) => r.revenue), barWidth: '55%',
      itemStyle: { color: gradient('#10b981', '#059669'), borderRadius: [6, 6, 0, 0] },
    }],
  }
})

const typeMileageOption = computed(() => {
  const rows = typeRows.value
  return {
    tooltip, grid,
    xAxis: { type: 'category', data: rows.map((r: any) => r.vehicle_type), axisLabel: { rotate: 30, fontSize: 10 } },
    yAxis: { type: 'value' },
    series: [{
      type: 'bar', data: rows.map((r: any) => r.avg_mileage), barWidth: '55%',
      itemStyle: { color: gradient('#0ea5e9', '#2563eb'), borderRadius: [6, 6, 0, 0] },
    }],
  }
})

const typeServiceOption = computed(() => {
  const rows = typeRows.value
  return {
    tooltip: { ...tooltip,
      formatter: (params: any) => { const p = Array.isArray(params) ? params[0] : params; return `${p.name}<br/>Service Cost: ${currencySymbol.value}${Number(p.value).toLocaleString()}` }
    },
    grid,
    xAxis: { type: 'category', data: rows.map((r: any) => r.vehicle_type), axisLabel: { rotate: 30, fontSize: 10 } },
    yAxis: { type: 'value', axisLabel: { formatter: (v: number) => currencySymbol.value + (v >= 1000 ? (v / 1000).toFixed(0) + 'k' : v) } },
    series: [{
      type: 'bar', data: rows.map((r: any) => r.service_cost), barWidth: '55%',
      itemStyle: { color: gradient('#f59e0b', '#d97706'), borderRadius: [6, 6, 0, 0] },
    }],
  }
})
</script>

<style scoped>
.type-kpi {
  padding: 14px 16px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(15, 23, 42, 0.03);
}
.section-heading { color: #475569; }
.kpi-value { color: #1e293b; }
.v-theme--dark .type-kpi {
  background: rgb(var(--v-theme-surface));
  border-color: rgba(var(--v-theme-on-surface), 0.12);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
}
.v-theme--dark .section-heading { color: #94a3b8; }
.v-theme--dark .kpi-value { color: #f1f5f9; }
</style>
