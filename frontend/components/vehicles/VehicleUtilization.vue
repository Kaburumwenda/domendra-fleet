<template>
  <div class="d-flex flex-column ga-4">
    <!-- Utilization KPIs -->
    <v-row dense>
      <v-col cols="6" md="3">
        <StatCard label="Utilization Rate" :value="`${data?.utilization?.utilization_rate ?? 0}%`" icon="mdi-gauge-full" iconBg="#dcfce7" iconColor="success" :subtitle="`${data?.utilization?.vehicles_with_active_rentals ?? 0} vehicles on rent`" />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard label="Active Rentals" :value="data?.utilization?.active_rentals ?? 0" icon="mdi-key-variant" iconBg="#dbeafe" iconColor="info" :subtitle="`${data?.utilization?.completed_rentals ?? 0} completed`" />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard label="Total Revenue" :value="`${currencySymbol}${revenueFmt}`" icon="mdi-cash-multiple" iconBg="#fef3c7" iconColor="warning" :subtitle="`${currencySymbol}${avgRevFmt} avg / vehicle`" />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard label="Idle Vehicles" :value="data?.utilization?.idle_vehicles ?? 0" icon="mdi-car-parking-lights" iconBg="#fce7f3" iconColor="purple" :subtitle="`${data?.utilization?.overdue_rentals ?? 0} overdue rentals`" />
      </v-col>
    </v-row>

    <!-- Charts row 1 -->
    <v-row dense>
      <v-col cols="12" md="8">
        <DashboardChart :option="revenueTrendOption" title="Revenue Monthly Trend" icon="mdi-chart-line" height="300px" />
      </v-col>
      <v-col cols="12" md="4">
        <DashboardChart :option="rentalStatusOption" title="Rental Status" icon="mdi-chart-donut" height="300px" />
      </v-col>
    </v-row>

    <!-- Charts row 2 -->
    <v-row dense>
      <v-col cols="12" md="6">
        <DashboardChart :option="revenueByTypeOption" title="Revenue by Vehicle Type" icon="mdi-chart-bar" height="280px" />
      </v-col>
      <v-col cols="12" md="6">
        <DashboardChart :option="topVehiclesOption" title="Top 10 Revenue Vehicles" icon="mdi-trophy-variant" height="280px" />
      </v-col>
    </v-row>

    <!-- Top vehicles table -->
    <v-card elevation="0" border class="pa-5">
      <div class="d-flex align-center justify-space-between mb-3">
        <h3 class="text-subtitle-2 font-weight-medium d-flex align-center ga-2 section-heading">
          <v-icon size="small" color="warning">mdi-trophy-variant</v-icon> Top Revenue Vehicles
        </h3>
      </div>
      <v-data-table
        :items="topVehicles"
        :headers="topHeaders"
        density="compact"
        :items-per-page="10"
      >
        <template #item.display_name="{ item }">
          <span class="font-weight-medium">{{ (item as any).make }} {{ (item as any).model }}</span>
          <span class="text-caption text-medium-emphasis ml-1">{{ (item as any).license_plate }}</span>
        </template>
        <template #item.rev="{ item }">
          <span class="font-weight-bold" style="color: #059669">{{ currencySymbol }}{{ Number((item as any).rev || 0).toLocaleString() }}</span>
        </template>
        <template #item.rental_cnt="{ item }">
          <v-chip size="x-small" variant="tonal" color="primary">{{ (item as any).rental_cnt }} rentals</v-chip>
        </template>
        <template #item.status="{ item }">
          <v-chip size="x-small" :color="statusColor((item as any).status)" variant="tonal" class="text-capitalize">{{ ((item as any).status || '').replace('_', ' ') }}</v-chip>
        </template>
      </v-data-table>
    </v-card>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ data: any }>()
const { currencySymbol } = useCurrency()

const data = computed(() => props.data)

const revenueFmt = computed(() => fmt(data.value?.utilization?.total_revenue))
const avgRevFmt = computed(() => fmt(data.value?.utilization?.avg_revenue_per_vehicle))

function fmt(v: any) {
  return Number(v ?? 0).toLocaleString(undefined, { maximumFractionDigits: 0 })
}

function statusColor(s: string) {
  return { active: 'success', in_maintenance: 'info', out_of_service: 'warning', retired: 'grey' }[s] || 'grey'
}

const topVehicles = computed(() => data.value?.utilization?.top_vehicles || [])
const topHeaders = [
  { title: 'Vehicle', key: 'display_name' },
  { title: 'Revenue', key: 'rev' },
  { title: 'Rentals', key: 'rental_cnt' },
  { title: 'Status', key: 'status' },
]

const revenueTrendOption = computed(() => {
  const monthly = data.value?.utilization?.revenue_monthly || []
  return {
    tooltip: { trigger: 'axis', backgroundColor: '#1e293b', borderColor: '#334155', textStyle: { color: '#f1f5f9' } },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: monthly.map((m: any) => m.month), boundaryGap: false, axisLabel: { fontSize: 10, rotate: 30 } },
    yAxis: { type: 'value', axisLabel: { formatter: (v: number) => currencySymbol.value + (v >= 1000 ? (v / 1000).toFixed(0) + 'k' : v) } },
    series: [{
      type: 'line',
      smooth: true,
      data: monthly.map((m: any) => m.revenue),
      areaStyle: { color: { type: 'linear', x: 0, y: 0, x2: 0, y2: 1, colorStops: [
        { offset: 0, color: 'rgba(16,185,129,0.3)' }, { offset: 1, color: 'rgba(16,185,129,0.02)' }] } },
      lineStyle: { width: 3, color: '#10b981' },
      itemStyle: { color: '#10b981' },
      symbolSize: 6,
    }],
  }
})

const rentalStatusOption = computed(() => {
  const u = data.value?.utilization || {}
  return {
    tooltip: { trigger: 'item', backgroundColor: '#1e293b', borderColor: '#334155', textStyle: { color: '#f1f5f9' } },
    legend: { bottom: 0, textStyle: { fontSize: 10 }, icon: 'circle' },
    series: [{
      type: 'pie',
      radius: ['45%', '70%'],
      label: { show: false },
      data: [
        { value: u.active_rentals ?? 0, name: 'Active', itemStyle: { color: '#10b981' } },
        { value: u.completed_rentals ?? 0, name: 'Completed', itemStyle: { color: '#0ea5e9' } },
        { value: u.overdue_rentals ?? 0, name: 'Overdue', itemStyle: { color: '#ef4444' } },
        { value: u.cancelled_rentals ?? 0, name: 'Cancelled', itemStyle: { color: '#94a3b8' } },
      ],
    }],
  }
})

const revenueByTypeOption = computed(() => {
  const rbt = (data.value?.utilization?.revenue_by_type || []).filter((r: any) => r.vehicle_type)
  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, backgroundColor: '#1e293b', borderColor: '#334155', textStyle: { color: '#f1f5f9' },
      formatter: (params: any) => {
        const p = Array.isArray(params) ? params[0] : params
        return `${p.name}<br/>Revenue: ${currencySymbol.value}${Number(p.value).toLocaleString()}`
      }
    },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: rbt.map((r: any) => r.vehicle_type), axisLabel: { interval: 0, rotate: 25, fontSize: 10 } },
    yAxis: { type: 'value', axisLabel: { formatter: (v: number) => currencySymbol.value + (v >= 1000 ? (v / 1000).toFixed(0) + 'k' : v) } },
    series: [{
      type: 'bar',
      data: rbt.map((r: any) => r.revenue),
      barWidth: '55%',
      itemStyle: { color: { type: 'linear', x: 0, y: 0, x2: 0, y2: 1, colorStops: [
        { offset: 0, color: '#6366f1' }, { offset: 1, color: '#4f46e5' }] }, borderRadius: [6, 6, 0, 0] },
    }],
  }
})

const topVehiclesOption = computed(() => {
  const tv = (data.value?.utilization?.top_vehicles || []).slice(0, 10)
  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, backgroundColor: '#1e293b', borderColor: '#334155', textStyle: { color: '#f1f5f9' },
      formatter: (params: any) => {
        const p = Array.isArray(params) ? params[0] : params
        const v = tv[p.dataIndex]
        return `${v.make} ${v.model}<br/>Revenue: ${currencySymbol.value}${Number(p.value).toLocaleString()}<br/>Rentals: ${v.rental_cnt}`
      }
    },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'value', axisLabel: { formatter: (v: number) => currencySymbol.value + (v >= 1000 ? (v / 1000).toFixed(0) + 'k' : v) } },
    yAxis: { type: 'category', data: tv.map((v: any) => `${v.make} ${v.model}`).reverse(), axisLabel: { fontSize: 9 } },
    series: [{
      type: 'bar',
      data: tv.map((v: any) => v.rev).reverse(),
      barWidth: '55%',
      itemStyle: { color: { type: 'linear', x: 0, y: 0, x2: 1, y2: 0, colorStops: [
        { offset: 0, color: '#f59e0b' }, { offset: 1, color: '#d97706' }] }, borderRadius: [0, 6, 6, 0] },
    }],
  }
})
</script>

<style scoped>
.section-heading { color: #475569; }
.v-theme--dark .section-heading { color: #94a3b8; }
</style>
