<template>
  <div class="d-flex flex-column ga-4">
    <!-- Cost KPIs -->
    <v-row dense>
      <v-col cols="6" md="3">
        <StatCard label="Total Book Value" :value="`${currencySymbol}${bookValueFmt}`" icon="mdi-cash-check" iconBg="#dcfce7" iconColor="success" :subtitle="`${currencySymbol}${depLossFmt} dep. loss`" />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard label="Annual Depreciation" :value="`${currencySymbol}${annualDepFmt}`" icon="mdi-trending-down" iconBg="#fef3c7" iconColor="warning" :subtitle="`${currencySymbol}${costPerKmFmt} / km`" />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard label="Total Service Cost" :value="`${currencySymbol}${serviceCostFmt}`" icon="mdi-wrench" iconBg="#dbeafe" iconColor="info" :subtitle="`${data?.cost_analysis?.total_services ?? 0} services`" />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard label="Downtime Hours" :value="`${data?.cost_analysis?.total_downtime_hours ?? 0}h`" icon="mdi-clock-alert" iconBg="#fee2e2" iconColor="error" :subtitle="`${currencySymbol}${avgServiceCostFmt} avg / service`" />
      </v-col>
    </v-row>

    <!-- Charts -->
    <v-row dense>
      <v-col cols="12" md="7">
        <DashboardChart :option="depreciationOption" title="Depreciation Analysis (Top 20)" icon="mdi-chart-line" height="320px" />
      </v-col>
      <v-col cols="12" md="5">
        <DashboardChart :option="serviceByTypeOption" title="Service Cost by Type" icon="mdi-wrench" height="320px" />
      </v-col>
    </v-row>

    <!-- Detailed Depreciation Table -->
    <v-card elevation="0" border class="pa-5">
      <div class="d-flex align-center justify-space-between mb-3">
        <h3 class="text-subtitle-2 font-weight-medium d-flex align-center ga-2 section-heading">
          <v-icon size="small" color="warning">mdi-chart-line</v-icon> Depreciation Detail
        </h3>
      </div>
      <v-data-table
        :items="depVehicles"
        :headers="depHeaders"
        density="compact"
        :items-per-page="10"
      >
        <template #item.display_name="{ item }">
          <span class="font-weight-medium">{{ (item as any).make }} {{ (item as any).model }} ({{ (item as any).year }})</span>
        </template>
        <template #item.purchase_price="{ item }">
          {{ currencySymbol }}{{ Number((item as any).purchase_price || 0).toLocaleString() }}
        </template>
        <template #item.book_value="{ item }">
          <span class="font-weight-bold" style="color: #059669">{{ currencySymbol }}{{ Number((item as any).book_value || 0).toLocaleString() }}</span>
        </template>
        <template #item.annual_depreciation="{ item }">
          {{ currencySymbol }}{{ Number((item as any).annual_depreciation || 0).toLocaleString() }}
        </template>
        <template #item.depreciation_pct="{ item }">
          <div class="d-flex align-center ga-2">
            <v-progress-linear :model-value="(item as any).depreciation_pct" :color="depColor((item as any).depreciation_pct)" height="6" rounded style="max-width: 80px" />
            <span class="text-body-2 font-weight-medium">{{ (item as any).depreciation_pct }}%</span>
          </div>
        </template>
        <template #item.age_years="{ item }">
          {{ Number((item as any).age_years).toFixed(1) }} yrs
        </template>
      </v-data-table>
    </v-card>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ data: any }>()
const { currencySymbol } = useCurrency()

const data = computed(() => props.data)

const bookValueFmt = computed(() => fmt(data.value?.cost_analysis?.total_book_value))
const depLossFmt = computed(() => fmt(data.value?.cost_analysis?.total_depreciation_loss))
const annualDepFmt = computed(() => fmt(data.value?.cost_analysis?.total_annual_depreciation))
const serviceCostFmt = computed(() => fmt(data.value?.cost_analysis?.total_service_cost))
const avgServiceCostFmt = computed(() => fmt(data.value?.cost_analysis?.avg_service_cost))
const costPerKmFmt = computed(() => fmt(data.value?.cost_analysis?.cost_per_km))

function fmt(v: any) {
  return Number(v ?? 0).toLocaleString(undefined, { maximumFractionDigits: 0 })
}

function depColor(pct: number) {
  if (pct >= 75) return 'error'
  if (pct >= 50) return 'warning'
  if (pct >= 25) return 'info'
  return 'success'
}

const depVehicles = computed(() => data.value?.cost_analysis?.vehicles || [])

const depHeaders = [
  { title: 'Vehicle', key: 'display_name' },
  { title: 'Purchase', key: 'purchase_price' },
  { title: 'Book Value', key: 'book_value' },
  { title: 'Annual Dep.', key: 'annual_depreciation' },
  { title: 'Depreciated', key: 'depreciation_pct', width: '160px' },
  { title: 'Age', key: 'age_years' },
]

const depreciationOption = computed(() => {
  const vehicles = (data.value?.cost_analysis?.vehicles || []).slice(0, 20)
  return {
    tooltip: { trigger: 'axis', backgroundColor: '#1e293b', borderColor: '#334155', textStyle: { color: '#f1f5f9' },
      formatter: (params: any) => {
        const items = Array.isArray(params) ? params : [params]
        let html = items[0].name
        for (const p of items) {
          html += `<br/>${p.marker} ${p.seriesName}: ${currencySymbol.value}${Number(p.value).toLocaleString()}`
        }
        return html
      }
    },
    legend: { bottom: 0, textStyle: { fontSize: 11 }, icon: 'circle' },
    grid: { left: '3%', right: '4%', bottom: '14%', containLabel: true },
    xAxis: { type: 'category', data: vehicles.map((v: any) => `${v.make} ${v.model}`), axisLabel: { fontSize: 9, rotate: 40, interval: 0 } },
    yAxis: { type: 'value', axisLabel: { formatter: (v: number) => currencySymbol.value + (v >= 1000 ? (v / 1000).toFixed(0) + 'k' : v) } },
    series: [
      {
        name: 'Purchase Price',
        type: 'bar',
        data: vehicles.map((v: any) => v.purchase_price),
        itemStyle: { color: '#0ea5e9', borderRadius: [4, 4, 0, 0] },
        barGap: '10%',
      },
      {
        name: 'Book Value',
        type: 'bar',
        data: vehicles.map((v: any) => v.book_value),
        itemStyle: { color: '#10b981', borderRadius: [4, 4, 0, 0] },
      },
    ],
  }
})

const serviceByTypeOption = computed(() => {
  const sbt = data.value?.cost_analysis?.service_by_type || []
  const labels: Record<string, string> = {
    oil_change: 'Oil Change', tire_rotation: 'Tire Rotation', brake_service: 'Brake Service',
    inspection: 'Inspection', repair: 'Repair', preventive: 'Preventive', other: 'Other',
  }
  const colors: Record<string, string> = {
    oil_change: '#10b981', tire_rotation: '#0ea5e9', brake_service: '#ef4444',
    inspection: '#a855f7', repair: '#f59e0b', preventive: '#6366f1', other: '#94a3b8',
  }
  return {
    tooltip: { trigger: 'item', backgroundColor: '#1e293b', borderColor: '#334155', textStyle: { color: '#f1f5f9' },
      formatter: (p: any) => `${labels[p.name] || p.name}<br/>Cost: ${currencySymbol.value}${Number(p.value).toLocaleString()}` },
    legend: { bottom: 0, textStyle: { fontSize: 10 }, icon: 'circle' },
    series: [{
      type: 'pie',
      radius: ['40%', '70%'],
      label: { show: false },
      data: sbt.map((s: any) => ({
        value: s.cost, name: s.service_type,
        itemStyle: { color: colors[s.service_type] || '#94a3b8' },
      })),
    }],
  }
})
</script>

<style scoped>
.section-heading { color: #475569; }
.v-theme--dark .section-heading { color: #94a3b8; }
</style>
