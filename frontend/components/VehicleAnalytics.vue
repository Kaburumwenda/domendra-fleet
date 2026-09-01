<template>
  <div class="vehicle-analytics">
    <!-- Premium KPI cards -->
    <div class="kpi-grid">
      <div class="kpi-card">
        <div class="kpi-icon" style="background: linear-gradient(135deg,#6366f1,#4f46e5)">
          <v-icon size="22" color="white">mdi-car-multiple</v-icon>
        </div>
        <div class="kpi-body">
          <div class="kpi-value">{{ data?.total_vehicles ?? 0 }}</div>
          <div class="kpi-label">Total Vehicles</div>
          <div class="kpi-sub">
            <span class="dot dot-success" /> {{ data?.active ?? 0 }} active
            <span class="dot dot-info ml-2" /> {{ data?.in_maintenance ?? 0 }} in service
          </div>
        </div>
      </div>

      <div class="kpi-card">
        <div class="kpi-icon" style="background: linear-gradient(135deg,#10b981,#059669)">
          <v-icon size="22" color="white">mdi-gauge-full</v-icon>
        </div>
        <div class="kpi-body">
          <div class="kpi-value" :class="healthColor">{{ data?.fleet_health?.fleet_health_score ?? 0 }}<span class="kpi-unit">%</span></div>
          <div class="kpi-label">Fleet Health Score</div>
          <div class="kpi-bar">
            <div class="kpi-bar-fill" :class="healthColor" :style="{ width: (data?.fleet_health?.fleet_health_score ?? 0) + '%' }" />
          </div>
        </div>
      </div>

      <div class="kpi-card">
        <div class="kpi-icon" style="background: linear-gradient(135deg,#f59e0b,#d97706)">
          <v-icon size="22" color="white">mdi-chart-line</v-icon>
        </div>
        <div class="kpi-body">
          <div class="kpi-value">{{ data?.utilization?.utilization_rate ?? 0 }}<span class="kpi-unit">%</span></div>
          <div class="kpi-label">Utilization Rate</div>
          <div class="kpi-sub">
            <span class="dot dot-success" /> {{ data?.utilization?.active_rentals ?? 0 }} active rentals
          </div>
        </div>
      </div>

      <div class="kpi-card">
        <div class="kpi-icon" style="background: linear-gradient(135deg,#0ea5e9,#2563eb)">
          <v-icon size="22" color="white">mdi-cash-multiple</v-icon>
        </div>
        <div class="kpi-body">
          <div class="kpi-value">{{ currencySymbol }}{{ totalRevenueFmt }}</div>
          <div class="kpi-label">Total Revenue</div>
          <div class="kpi-sub">
            <span class="dot dot-info" /> Avg {{ currencySymbol }}{{ avgRevenueFmt }} / vehicle
          </div>
        </div>
      </div>
    </div>

    <!-- Secondary KPIs -->
    <div class="kpi-grid-secondary">
      <div class="mini-kpi">
        <v-icon size="18" color="success">mdi-cash-check</v-icon>
        <div>
          <div class="mini-kpi-val">{{ currencySymbol }}{{ bookValueFmt }}</div>
          <div class="mini-kpi-lbl">Total Book Value</div>
        </div>
      </div>
      <div class="mini-kpi">
        <v-icon size="18" color="warning">mdi-trending-down</v-icon>
        <div>
          <div class="mini-kpi-val">{{ currencySymbol }}{{ annualDepFmt }}</div>
          <div class="mini-kpi-lbl">Annual Depreciation</div>
        </div>
      </div>
      <div class="mini-kpi">
        <v-icon size="18" color="info">mdi-wrench</v-icon>
        <div>
          <div class="mini-kpi-val">{{ currencySymbol }}{{ serviceCostFmt }}</div>
          <div class="mini-kpi-lbl">Service Costs</div>
        </div>
      </div>
      <div class="mini-kpi">
        <v-icon size="18" color="primary">mdi-ev-station</v-icon>
        <div>
          <div class="mini-kpi-val">{{ data?.ev_stats?.count ?? 0 }}</div>
          <div class="mini-kpi-lbl">EV / Hydrogen</div>
        </div>
      </div>
      <div class="mini-kpi">
        <v-icon size="18" color="error">mdi-alert-circle-outline</v-icon>
        <div>
          <div class="mini-kpi-val">{{ data?.fleet_health?.vehicles_needing_attention ?? 0 }}</div>
          <div class="mini-kpi-lbl">Need Attention</div>
        </div>
      </div>
      <div class="mini-kpi">
        <v-icon size="18" color="secondary">mdi-speedometer</v-icon>
        <div>
          <div class="mini-kpi-val">{{ avgMileageFmt }}</div>
          <div class="mini-kpi-lbl">Avg Mileage</div>
        </div>
      </div>
    </div>

    <!-- Charts row 1 -->
    <v-row dense>
      <v-col cols="12" md="8">
        <DashboardChart :option="revenueTrendOption" title="Revenue Trend (Last 12 Months)" icon="mdi-chart-line" height="300px" />
      </v-col>
      <v-col cols="12" md="4">
        <DashboardChart :option="statusDonutOption" title="Status Distribution" icon="mdi-chart-donut" height="300px" />
      </v-col>
    </v-row>

    <!-- Charts row 2 -->
    <v-row dense>
      <v-col cols="12" md="6">
        <DashboardChart :option="fuelMixOption" title="Fuel Type Breakdown" icon="mdi-fuel" height="280px" />
      </v-col>
      <v-col cols="12" md="6">
        <DashboardChart :option="vehicleTypeOption" title="Vehicle Type Distribution" icon="mdi-shape" height="280px" />
      </v-col>
    </v-row>

    <!-- Charts row 3 -->
    <v-row dense>
      <v-col cols="12" md="6">
        <DashboardChart :option="ageDistOption" title="Fleet Age Distribution" icon="mdi-calendar-clock" height="260px" />
      </v-col>
      <v-col cols="12" md="6">
        <DashboardChart :option="topMakesOption" title="Top Makes" icon="mdi-car-info" height="260px" />
      </v-col>
    </v-row>

    <!-- Charts row 4 -->
    <v-row dense>
      <v-col cols="12" md="7">
        <DashboardChart :option="revenueByTypeOption" title="Revenue by Vehicle Type" icon="mdi-chart-bar" height="280px" />
      </v-col>
      <v-col cols="12" md="5">
        <DashboardChart :option="serviceByTypeOption" title="Service Cost by Type" icon="mdi-wrench" height="280px" />
      </v-col>
    </v-row>

    <!-- Top revenue vehicles table -->
    <v-card elevation="0" border class="pa-5">
      <div class="d-flex align-center justify-space-between mb-3">
        <span class="text-subtitle-2 font-weight-medium text-medium-emphasis">Top Revenue Vehicles</span>
        <v-icon color="medium-emphasis" size="small">mdi-trophy-variant</v-icon>
      </div>
      <v-data-table
        :items="topVehicles"
        :headers="topVehicleHeaders"
        density="compact"
        hide-default-footer
        :items-per-page="5"
      >
        <template #item.display_name="{ item }">
          <span class="font-weight-medium">{{ (item as any).make }} {{ (item as any).model }}</span>
          <span class="text-caption text-medium-emphasis ml-1">{{ (item as any).license_plate }}</span>
        </template>
        <template #item.revenue="{ item }">
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

const healthColor = computed(() => {
  const s = data.value?.fleet_health?.fleet_health_score ?? 0
  if (s >= 75) return 'success-bar'
  if (s >= 50) return 'warning-bar'
  return 'error-bar'
})

const totalRevenueFmt = computed(() => {
  const v = data.value?.utilization?.total_revenue ?? 0
  return Number(v).toLocaleString(undefined, { maximumFractionDigits: 0 })
})
const avgRevenueFmt = computed(() => {
  const v = data.value?.utilization?.avg_revenue_per_vehicle ?? 0
  return Number(v).toLocaleString(undefined, { maximumFractionDigits: 0 })
})
const bookValueFmt = computed(() => {
  const v = data.value?.cost_analysis?.total_book_value ?? 0
  return Number(v).toLocaleString(undefined, { maximumFractionDigits: 0 })
})
const annualDepFmt = computed(() => {
  const v = data.value?.cost_analysis?.total_annual_depreciation ?? 0
  return Number(v).toLocaleString(undefined, { maximumFractionDigits: 0 })
})
const serviceCostFmt = computed(() => {
  const v = data.value?.cost_analysis?.total_service_cost ?? 0
  return Number(v).toLocaleString(undefined, { maximumFractionDigits: 0 })
})
const avgMileageFmt = computed(() => {
  const v = data.value?.mileage_stats?.avg_mileage ?? 0
  return Number(v).toLocaleString(undefined, { maximumFractionDigits: 0 })
})

const topVehicleHeaders = [
  { title: 'Vehicle', key: 'display_name' },
  { title: 'Revenue', key: 'revenue' },
  { title: 'Rentals', key: 'rental_cnt' },
  { title: 'Status', key: 'status' },
]
const topVehicles = computed(() => data.value?.utilization?.top_vehicles || [])

function statusColor(s: string) {
  return { active: 'success', in_maintenance: 'info', out_of_service: 'warning', retired: 'grey' }[s] || 'grey'
}

// ---- Chart Options ----
const revenueTrendOption = computed(() => {
  const monthly = data.value?.utilization?.revenue_monthly || []
  return {
    tooltip: {
      trigger: 'axis',
      backgroundColor: '#1e293b',
      borderColor: '#334155',
      borderWidth: 1,
      textStyle: { color: '#f1f5f9' },
      axisPointer: { type: 'cross', crossStyle: { color: '#6366f1', width: 1, type: 'dashed' }, label: { backgroundColor: '#6366f1' } },
      formatter: (params: any) => {
        const p = Array.isArray(params) ? params[0] : params
        return `<span style="font-weight:600">${p.axisValue}</span><br/>${p.marker} Revenue: ${currencySymbol.value}${Number(p.value || 0).toLocaleString()}`
      },
    },
    grid: { left: '3%', right: '5%', top: '5%', bottom: '3%', containLabel: true },
    xAxis: {
      type: 'category',
      data: monthly.map((m: any) => m.month),
      boundaryGap: false,
      axisLine: { lineStyle: { color: '#e2e8f0' } },
      axisLabel: { color: '#94a3b8', fontSize: 11 },
    },
    yAxis: {
      type: 'value',
      axisLabel: { color: '#94a3b8', fontSize: 11, formatter: (v: number) => currencySymbol.value + (v >= 1000 ? (v / 1000).toFixed(0) + 'k' : v) },
      splitLine: { lineStyle: { color: '#f1f5f9', type: 'dashed' } },
    },
    series: [{
      type: 'line',
      smooth: true,
      data: monthly.map((m: any) => m.revenue),
      areaStyle: {
        color: {
          type: 'linear', x: 0, y: 0, x2: 0, y2: 1,
          colorStops: [
            { offset: 0, color: 'rgba(99,102,241,0.45)' },
            { offset: 0.5, color: 'rgba(99,102,241,0.15)' },
            { offset: 1, color: 'rgba(99,102,241,0.01)' },
          ],
        },
      },
      lineStyle: { width: 3, color: '#6366f1', shadowColor: 'rgba(99,102,241,0.3)', shadowBlur: 8 },
      itemStyle: { color: '#6366f1', borderColor: '#fff', borderWidth: 2 },
      symbol: 'circle',
      symbolSize: 7,
      emphasis: { focus: 'series', itemStyle: { color: '#4f46e5', borderColor: '#fff', borderWidth: 2, shadowBlur: 10, shadowColor: 'rgba(99,102,241,0.5)' }, lineStyle: { width: 4 } },
    }],
  }
})

const statusDonutOption = computed(() => {
  const status = data.value?.status_breakdown || []
  const colors: Record<string, string> = { active: '#10b981', in_maintenance: '#0ea5e9', out_of_service: '#f59e0b', retired: '#94a3b8' }
  return {
    tooltip: { trigger: 'item', backgroundColor: '#1e293b', borderColor: '#334155', textStyle: { color: '#f1f5f9' } },
    legend: { bottom: 0, textStyle: { fontSize: 11 }, icon: 'circle' },
    series: [{
      type: 'pie',
      radius: ['45%', '70%'],
      avoidLabelOverlap: true,
      label: { show: false },
      data: status.map((s: any) => ({
        value: s.count, name: s.status.replace('_', ' '),
        itemStyle: { color: colors[s.status] || '#94a3b8' },
      })),
    }],
  }
})

const fuelMixOption = computed(() => {
  const fuel = data.value?.fuel_type_breakdown || []
  const colors = ['#6366f1', '#f59e0b', '#10b981', '#0ea5e9', '#a855f7', '#06b6d4', '#ef4444', '#94a3b8', '#ec4899', '#84cc16']
  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, backgroundColor: '#1e293b', borderColor: '#334155', textStyle: { color: '#f1f5f9' } },
    grid: { left: '3%', right: '4%', bottom: '14%', containLabel: true },
    xAxis: { type: 'category', data: ['Fuel'] },
    yAxis: { type: 'value' },
    series: [{
      type: 'bar',
      stack: 'total',
      barWidth: '50%',
      data: fuel.map((f: any, i: number) => ({ value: f.count, name: f.fuel_type, itemStyle: { color: colors[i % colors.length] } })),
    }],
    legend: { bottom: 0, textStyle: { fontSize: 10 }, icon: 'circle' },
  }
})

const vehicleTypeOption = computed(() => {
  const vtypes = (data.value?.vehicle_type_breakdown || []).filter((v: any) => v.vehicle_type)
  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, backgroundColor: '#1e293b', borderColor: '#334155', textStyle: { color: '#f1f5f9' } },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: vtypes.map((v: any) => v.vehicle_type), axisLabel: { interval: 0, rotate: 30, fontSize: 10 } },
    yAxis: { type: 'value' },
    series: [{
      type: 'bar',
      data: vtypes.map((v: any) => v.count),
      barWidth: '55%',
      itemStyle: { color: { type: 'linear', x: 0, y: 0, x2: 0, y2: 1, colorStops: [
        { offset: 0, color: '#0ea5e9' }, { offset: 1, color: '#2563eb' }] }, borderRadius: [6, 6, 0, 0] },
    }],
  }
})

const ageDistOption = computed(() => {
  const dist = data.value?.age_distribution || {}
  const keys = ['0-2', '3-5', '6-10', '11-15', '15+', 'Unknown']
  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, backgroundColor: '#1e293b', borderColor: '#334155', textStyle: { color: '#f1f5f9' } },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: keys },
    yAxis: { type: 'value' },
    series: [{
      type: 'bar',
      data: keys.map(k => dist[k] || 0),
      barWidth: '50%',
      itemStyle: { color: { type: 'linear', x: 0, y: 0, x2: 0, y2: 1, colorStops: [
        { offset: 0, color: '#f59e0b' }, { offset: 1, color: '#d97706' }] }, borderRadius: [6, 6, 0, 0] },
    }],
  }
})

const topMakesOption = computed(() => {
  const makes = data.value?.top_makes || []
  return {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, backgroundColor: '#1e293b', borderColor: '#334155', textStyle: { color: '#f1f5f9' } },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'value' },
    yAxis: { type: 'category', data: makes.map((m: any) => m.make).reverse(), axisLabel: { fontSize: 10 } },
    series: [{
      type: 'bar',
      data: makes.map((m: any) => m.count).reverse(),
      barWidth: '55%',
      itemStyle: { color: { type: 'linear', x: 0, y: 0, x2: 1, y2: 0, colorStops: [
        { offset: 0, color: '#a855f7' }, { offset: 1, color: '#7c3aed' }] }, borderRadius: [0, 6, 6, 0] },
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
      barWidth: '50%',
      itemStyle: { color: { type: 'linear', x: 0, y: 0, x2: 0, y2: 1, colorStops: [
        { offset: 0, color: '#10b981' }, { offset: 1, color: '#059669' }] }, borderRadius: [6, 6, 0, 0] },
    }],
  }
})

const serviceByTypeOption = computed(() => {
  const sbt = data.value?.cost_analysis?.service_by_type || []
  const labels: Record<string, string> = {
    oil_change: 'Oil Change', tire_rotation: 'Tire Rotation', brake_service: 'Brake Service',
    inspection: 'Inspection', repair: 'Repair', preventive: 'Preventive', other: 'Other',
  }
  return {
    tooltip: { trigger: 'item', backgroundColor: '#1e293b', borderColor: '#334155', textStyle: { color: '#f1f5f9' },
      formatter: (p: any) => `${labels[p.name] || p.name}<br/>Cost: ${currencySymbol.value}${Number(p.value).toLocaleString()}` },
    legend: { bottom: 0, textStyle: { fontSize: 10 }, icon: 'circle' },
    series: [{
      type: 'pie',
      radius: ['40%', '65%'],
      label: { show: false },
      data: sbt.map((s: any) => ({
        value: s.cost, name: s.service_type,
        itemStyle: { color: { oil_change: '#10b981', tire_rotation: '#0ea5e9', brake_service: '#ef4444',
          inspection: '#a855f7', repair: '#f59e0b', preventive: '#6366f1', other: '#94a3b8' }[s.service_type] || '#94a3b8' },
      })),
    }],
  }
})
</script>

<style scoped lang="scss">
.vehicle-analytics {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.kpi-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}
.kpi-card {
  display: flex;
  align-items: flex-start;
  gap: 16px;
  padding: 20px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  box-shadow: 0 4px 14px rgba(15, 23, 42, 0.04);
  transition: transform 0.15s ease, box-shadow 0.15s ease;
  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 10px 24px rgba(15, 23, 42, 0.08);
  }
}
.v-theme--dark .kpi-card {
  background: rgb(var(--v-theme-surface));
  border-color: rgba(var(--v-theme-on-surface), 0.12);
  box-shadow: 0 4px 14px rgba(0, 0, 0, 0.25);
  &:hover {
    box-shadow: 0 10px 24px rgba(0, 0, 0, 0.35);
  }
}
.kpi-icon {
  width: 48px;
  height: 48px;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  box-shadow: 0 6px 14px rgba(15, 23, 42, 0.14);
}
.kpi-body {
  flex: 1;
  min-width: 0;
}
.kpi-value {
  font-size: 26px;
  font-weight: 800;
  color: #0f172a;
  line-height: 1.1;
  letter-spacing: -0.02em;
  &.success-bar { color: #059669; }
  &.warning-bar { color: #d97706; }
  &.error-bar { color: #dc2626; }
}
.v-theme--dark .kpi-value {
  color: #f1f5f9;
  &.success-bar { color: #34d399; }
  &.warning-bar { color: #fbbf24; }
  &.error-bar { color: #f87171; }
}
.kpi-unit {
  font-size: 18px;
  font-weight: 700;
  margin-left: 1px;
}
.kpi-label {
  font-size: 13px;
  font-weight: 600;
  color: #64748b;
  margin-top: 2px;
}
.v-theme--dark .kpi-label { color: #94a3b8; }
.kpi-sub {
  font-size: 12px;
  color: #94a3b8;
  margin-top: 6px;
  display: flex;
  align-items: center;
  gap: 6px;
}
.v-theme--dark .kpi-sub { color: #64748b; }
.kpi-bar {
  margin-top: 8px;
  height: 6px;
  border-radius: 999px;
  background: #e2e8f0;
  overflow: hidden;
}
.v-theme--dark .kpi-bar { background: rgba(255,255,255,0.1); }
.kpi-bar-fill {
  height: 100%;
  border-radius: 999px;
  transition: width 0.4s ease;
  &.success-bar { background: linear-gradient(90deg, #10b981, #059669); }
  &.warning-bar { background: linear-gradient(90deg, #f59e0b, #d97706); }
  &.error-bar { background: linear-gradient(90deg, #ef4444, #dc2626); }
}

.kpi-grid-secondary {
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  gap: 12px;
}
.mini-kpi {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 14px 16px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(15, 23, 42, 0.03);
  transition: transform 0.15s ease;
  &:hover { transform: translateY(-1px); }
}
.v-theme--dark .mini-kpi {
  background: rgb(var(--v-theme-surface));
  border-color: rgba(var(--v-theme-on-surface), 0.12);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
}
.mini-kpi-val {
  font-size: 18px;
  font-weight: 800;
  color: #0f172a;
  line-height: 1.1;
}
.v-theme--dark .mini-kpi-val { color: #f1f5f9; }
.mini-kpi-lbl {
  font-size: 11px;
  font-weight: 600;
  color: #64748b;
  margin-top: 2px;
}
.v-theme--dark .mini-kpi-lbl { color: #94a3b8; }

.dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  display: inline-block;
  flex-shrink: 0;
}
.dot-success { background: #16a34a; }
.dot-info { background: #0ea5e9; }
.dot-warning { background: #f59e0b; }
.dot-grey { background: #94a3b8; }

@media (max-width: 1100px) {
  .kpi-grid { grid-template-columns: repeat(2, 1fr); }
  .kpi-grid-secondary { grid-template-columns: repeat(3, 1fr); }
}
@media (max-width: 640px) {
  .kpi-grid { grid-template-columns: 1fr; }
  .kpi-grid-secondary { grid-template-columns: repeat(2, 1fr); }
}
</style>
