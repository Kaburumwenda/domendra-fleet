<template>
  <div class="d-flex flex-column ga-4">
    <!-- Premium Gradient KPI Row -->
    <v-row dense>
      <v-col cols="6" md="3" v-for="(kpi, i) in kpis" :key="i">
        <v-card elevation="0" border class="pa-5 h-100 position-relative overflow-hidden" style="cursor: pointer" @click="$emit('navigate', kpi.tab)">
          <div class="position-absolute" style="top: -20px; right: -20px; opacity: 0.06">
            <v-icon :icon="kpi.icon" size="96" :color="kpi.color" />
          </div>
          <div class="d-flex align-center ga-2 mb-2">
            <v-icon :color="kpi.color" size="small">{{ kpi.icon }}</v-icon>
            <span class="text-caption text-medium-emphasis">{{ kpi.label }}</span>
          </div>
          <p class="text-h5 font-weight-bold" :style="{ color: kpi.textColor }">{{ kpi.prefix }}{{ kpi.value }}</p>
          <div v-if="kpi.sub" class="d-flex align-center ga-1 mt-1">
            <v-icon v-if="kpi.trend !== null" :color="kpi.trend === 'up' ? 'error' : 'success'" size="x-small">
              {{ kpi.trend === 'up' ? 'mdi-trending-up' : 'mdi-trending-down' }}
            </v-icon>
            <span class="text-caption text-medium-emphasis">{{ kpi.sub }}</span>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <!-- Charts Row -->
    <v-row dense>
      <v-col cols="12" md="8">
        <DashboardChart :option="costTrendOption" title="Daily Fuel Cost Trend" icon="mdi-chart-line" height="300px" />
      </v-col>
      <v-col cols="12" md="4">
        <DashboardChart :option="fuelTypeOption" title="Fuel Type Breakdown" icon="mdi-chart-pie" height="300px" />
      </v-col>
    </v-row>

    <v-row dense>
      <v-col cols="12" md="6">
        <DashboardChart :option="priceTrendOption" title="Price / Unit Trend" icon="mdi-chart-bell-curve" height="260px" />
      </v-col>
      <v-col cols="12" md="6">
        <DashboardChart :option="topVehiclesOption" title="Top Vehicles by Cost" icon="mdi-car-multiple" height="260px" />
      </v-col>
    </v-row>

    <!-- Energy & Idling mini-dashboards -->
    <v-row dense>
      <v-col cols="12" md="6">
        <v-card elevation="0" border class="pa-5 h-100">
          <div class="d-flex align-center justify-space-between mb-3">
            <h3 class="text-subtitle-2 font-weight-medium d-flex align-center ga-2" style="color: #475569">
              <v-icon size="small" color="success">mdi-flash</v-icon> EV Charging Summary
            </h3>
            <v-chip size="x-small" color="success" variant="tonal">{{ chargingSummary?.session_count || 0 }} sessions</v-chip>
          </div>
          <v-row dense>
            <v-col cols="4">
              <p class="text-h5 font-weight-bold">{{ (chargingSummary?.total_kwh || 0).toFixed(1) }}</p>
              <p class="text-caption text-medium-emphasis">Total kWh</p>
            </v-col>
            <v-col cols="4">
              <p class="text-h5 font-weight-bold">{{ currencySymbol }}{{ Number(chargingSummary?.total_cost || 0).toFixed(0) }}</p>
              <p class="text-caption text-medium-emphasis">Total Cost</p>
            </v-col>
            <v-col cols="4">
              <p class="text-h5 font-weight-bold">{{ currencySymbol }}{{ chargingSummary?.avg_cost_per_kwh || '0' }}</p>
              <p class="text-caption text-medium-emphasis">Avg /kWh</p>
            </v-col>
          </v-row>
          <v-divider class="my-3" />
          <DashboardChart v-if="(chargingSummary?.by_network || []).length" :option="chargingNetworkOption" height="140px" />
        </v-card>
      </v-col>
      <v-col cols="12" md="6">
        <v-card elevation="0" border class="pa-5 h-100">
          <div class="d-flex align-center justify-space-between mb-3">
            <h3 class="text-subtitle-2 font-weight-medium d-flex align-center ga-2" style="color: #475569">
              <v-icon size="small" color="warning">mdi-clock-outline</v-icon> Idling Impact (30d)
            </h3>
            <v-chip size="x-small" color="warning" variant="tonal">{{ idlingSummary?.total_events || 0 }} events</v-chip>
          </div>
          <v-row dense>
            <v-col cols="4">
              <p class="text-h5 font-weight-bold">{{ idlingSummary?.total_hours || 0 }}h</p>
              <p class="text-caption text-medium-emphasis">Total Hours</p>
            </v-col>
            <v-col cols="4">
              <p class="text-h5 font-weight-bold">{{ idlingSummary?.total_fuel_burned || 0 }} gal</p>
              <p class="text-caption text-medium-emphasis">Fuel Burned</p>
            </v-col>
            <v-col cols="4">
              <p class="text-h5 font-weight-bold text-error">{{ currencySymbol }}{{ idlingSummary?.total_cost || 0 }}</p>
              <p class="text-caption text-medium-emphasis">Wasted</p>
            </v-col>
          </v-row>
          <v-divider class="my-3" />
          <DashboardChart v-if="(idlingSummary?.by_vehicle || []).length" :option="idlingByVehicleOption" height="140px" />
        </v-card>
      </v-col>
    </v-row>

    <!-- Budget Tracking -->
    <v-card v-if="budgetRows.length" elevation="0" border class="pa-5">
      <h3 class="text-subtitle-2 font-weight-medium d-flex align-center ga-2 mb-3" style="color: #475569">
        <v-icon size="small" color="primary">mdi-chart-arc</v-icon> Monthly Budget Tracking
      </h3>
      <div v-for="row in budgetRows" :key="row.id" class="mb-3">
        <div class="d-flex align-center justify-space-between mb-1">
          <span class="text-body-2 font-weight-medium text-capitalize">{{ row.scope }} {{ row.target_ref ? '· ' + row.target_ref : '' }}</span>
          <span class="text-caption text-medium-emphasis">{{ currencySymbol }}{{ row.actual.toFixed(0) }} / {{ currencySymbol }}{{ row.budget.toFixed(0) }} ({{ row.pct_used }}%)</span>
        </div>
        <v-progress-linear
          :model-value="Math.min(row.pct_used, 100)"
          :color="row.pct_used >= 100 ? 'error' : row.pct_used >= 80 ? 'warning' : 'success'"
          height="8"
          rounded
        />
      </div>
    </v-card>
  </div>
</template>

<script setup lang="ts">
import * as echarts from 'echarts/core'
import { setupECharts } from '~/utils/echarts'
import { useDarkMode } from '~/composables/useDarkMode'

setupECharts()

const props = defineProps<{
  analytics: any
  chargingSummary: any
  idlingSummary: any
  fraudSummary: any
  budgetSummary: any
}>()

defineEmits<{ navigate: [tab: string] }>()

const { currencySymbol } = useCurrency()
const { isDark } = useDarkMode()

const budgetRows = computed(() => props.budgetSummary?.rows || [])

const kpis = computed(() => {
  const a = props.analytics
  const trend = props.fraudSummary
  return [
    {
      label: 'Total Fuel Cost',
      value: Number(a?.total_cost || 0).toLocaleString(undefined, { maximumFractionDigits: 0 }),
      prefix: currencySymbol.value,
      icon: 'mdi-currency-usd',
      color: 'success',
      textColor: '',
      sub: `${a?.transaction_count || 0} transactions`,
      trend: null,
      tab: 'transactions',
    },
    {
      label: 'Total Volume',
      value: Number(a?.total_gallons || 0).toLocaleString(undefined, { maximumFractionDigits: 0 }),
      prefix: '',
      icon: 'mdi-gauge',
      color: 'info',
      textColor: '',
      sub: a?.by_unit?.map((u: any) => `${u.unit}: ${Number(u.total_qty || 0).toFixed(0)}`).join(' · ') || 'gallons',
      trend: null,
      tab: 'transactions',
    },
    {
      label: 'Avg Price / Unit',
      value: a?.avg_price_per_gallon || '0',
      prefix: currencySymbol.value,
      icon: 'mdi-tag-outline',
      color: 'purple',
      textColor: '',
      sub: `Max ${currencySymbol.value}${Number(a?.max_transaction_cost || 0).toFixed(0)}`,
      trend: null,
      tab: 'analytics',
    },
    {
      label: 'Fraud Alerts',
      value: String(trend?.unresolved || 0),
      prefix: '',
      icon: 'mdi-shield-alert-outline',
      color: 'error',
      textColor: 'rgb(var(--v-theme-error))',
      sub: `${trend?.critical || 0} critical`,
      trend: null,
      tab: 'fraud',
    },
  ]
})

// ---- Chart options ----
const axisLabelColor = computed(() => isDark.value ? '#94a3b8' : '#64748b')
const splitLineColor = computed(() => isDark.value ? '#334155' : '#f1f5f9')

const costTrendOption = computed(() => {
  const daily = props.analytics?.daily_trend || []
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: 50, right: 20, top: 20, bottom: 30 },
    xAxis: { type: 'category', data: daily.map((d: any) => d.day), axisLabel: { color: axisLabelColor.value, fontSize: 11 } },
    yAxis: { type: 'value', axisLabel: { color: axisLabelColor.value, fontSize: 11 }, splitLine: { lineStyle: { color: splitLineColor.value } } },
    series: [{
      type: 'line',
      smooth: true,
      data: daily.map((d: any) => Number(d.total_cost).toFixed(2)),
      symbol: 'circle',
      symbolSize: 6,
      lineStyle: { width: 3, color: '#6366f1' },
      itemStyle: { color: '#6366f1' },
      areaStyle: {
        color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
          { offset: 0, color: 'rgba(99,102,241,0.25)' },
          { offset: 1, color: 'rgba(99,102,241,0.02)' },
        ]),
      },
    }],
  }
})

const fuelTypeOption = computed(() => {
  const data = (props.analytics?.by_fuel_type || []).map((f: any) => ({
    name: f.fuel_type,
    value: Number(f.total_cost).toFixed(2),
  }))
  const colors = ['#6366f1', '#f59e0b', '#10b981', '#8b5cf6', '#ec4899', '#06b6d4', '#84cc16']
  return {
    tooltip: { trigger: 'item' },
    legend: { bottom: 0, textStyle: { color: axisLabelColor.value, fontSize: 11 } },
    color: colors,
    series: [{
      type: 'pie',
      radius: ['40%', '70%'],
      center: ['50%', '45%'],
      avoidLabelOverlap: true,
      label: { show: false },
      emphasis: { label: { show: true, fontSize: 14, fontWeight: 'bold' } },
      data,
    }],
  }
})

const priceTrendOption = computed(() => {
  const trend = props.analytics?.price_trend || []
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: 50, right: 20, top: 20, bottom: 30 },
    xAxis: { type: 'category', data: trend.map((t: any) => t.day), axisLabel: { color: axisLabelColor.value, fontSize: 11 } },
    yAxis: { type: 'value', axisLabel: { color: axisLabelColor.value, fontSize: 11 }, splitLine: { lineStyle: { color: splitLineColor.value } } },
    series: [{
      type: 'line',
      smooth: true,
      data: trend.map((t: any) => t.avg_price_per_gallon),
      symbol: 'none',
      lineStyle: { width: 2, color: '#f59e0b' },
      areaStyle: { color: 'rgba(245,158,11,0.15)' },
    }],
  }
})

const topVehiclesOption = computed(() => {
  const vehicles = (props.analytics?.by_vehicle || []).slice(0, 8)
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: 140, right: 20, top: 10, bottom: 30 },
    xAxis: { type: 'value', axisLabel: { color: axisLabelColor.value, fontSize: 11 }, splitLine: { lineStyle: { color: splitLineColor.value } } },
    yAxis: {
      type: 'category',
      data: vehicles.map((v: any) => `${v.vehicle__make || ''} ${v.vehicle__model || ''}`.trim() || v.vehicle__license_plate || '—'),
      axisLabel: { color: axisLabelColor.value, fontSize: 11 },
      inverse: true,
    },
    series: [{
      type: 'bar',
      data: vehicles.map((v: any) => Number(v.total_cost).toFixed(2)),
      barWidth: '50%',
      itemStyle: {
        borderRadius: [0, 4, 4, 0],
        color: new echarts.graphic.LinearGradient(0, 0, 1, 0, [
          { offset: 0, color: '#818cf8' },
          { offset: 1, color: '#6366f1' },
        ]),
      },
    }],
  }
})

const chargingNetworkOption = computed(() => {
  const data = (props.chargingSummary?.by_network || []).map((n: any) => ({
    name: n.station_network || 'Other',
    value: Number(n.total_cost).toFixed(2),
  }))
  return {
    tooltip: { trigger: 'item' },
    series: [{
      type: 'pie',
      radius: ['35%', '60%'],
      center: ['50%', '50%'],
      label: { fontSize: 10, color: axisLabelColor.value },
      data,
    }],
  }
})

const idlingByVehicleOption = computed(() => {
  const vehicles = (props.idlingSummary?.by_vehicle || []).slice(0, 6)
  return {
    tooltip: { trigger: 'axis' },
    grid: { left: 100, right: 20, top: 10, bottom: 20 },
    xAxis: { type: 'value', axisLabel: { color: axisLabelColor.value, fontSize: 10 }, splitLine: { lineStyle: { color: splitLineColor.value } } },
    yAxis: {
      type: 'category',
      data: vehicles.map((v: any) => v.vehicle || '—'),
      axisLabel: { color: axisLabelColor.value, fontSize: 10 },
      inverse: true,
    },
    series: [{
      type: 'bar',
      data: vehicles.map((v: any) => Number(v.cost).toFixed(2)),
      barWidth: '50%',
      itemStyle: { borderRadius: [0, 4, 4, 0], color: '#f59e0b' },
    }],
  }
})
</script>
