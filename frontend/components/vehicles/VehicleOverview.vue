<template>
  <div class="d-flex flex-column ga-4">
    <!-- KPI Row -->
    <v-row dense>
      <v-col cols="6" md="3">
        <StatCard label="Total Vehicles" :value="data?.total_vehicles ?? 0" icon="mdi-car-multiple" iconBg="#eef2ff" iconColor="primary" :subtitle="`${data?.active ?? 0} active`" />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard label="Fleet Value" :value="`${currencySymbol}${bookValueFmt}`" icon="mdi-cash-multiple" iconBg="#dbeafe" iconColor="info" :subtitle="`${currencySymbol}${depLossFmt} dep. loss`" />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard label="Utilization" :value="`${data?.utilization?.utilization_rate ?? 0}%`" icon="mdi-chart-line" iconBg="#dcfce7" iconColor="success" :subtitle="`${data?.utilization?.active_rentals ?? 0} active rentals`" />
      </v-col>
      <v-col cols="6" md="3">
        <StatCard label="Need Attention" :value="data?.fleet_health?.vehicles_needing_attention ?? 0" icon="mdi-alert-circle-outline" iconBg="#fee2e2" iconColor="error" :subtitle="`${data?.in_maintenance ?? 0} in maintenance`" />
      </v-col>
    </v-row>

    <!-- Fleet Health and Status -->
    <v-row dense>
      <v-col cols="12" md="5">
        <v-card elevation="0" border class="pa-5 h-100">
          <div class="d-flex align-center justify-space-between mb-3">
            <h3 class="text-subtitle-2 font-weight-medium d-flex align-center ga-2 section-heading">
              <v-icon size="small" color="success">mdi-shield-check</v-icon> Fleet Health
            </h3>
            <v-chip :color="healthColor" variant="tonal" size="small">{{ data?.fleet_health?.fleet_health_score ?? 0 }}%</v-chip>
          </div>
          <div class="text-center py-3">
            <v-progress-circular :model-value="data?.fleet_health?.fleet_health_score ?? 0" :color="healthColor" size="120" width="10">
              <div class="d-flex flex-column align-center">
                <span class="text-h5 font-weight-bold">{{ data?.fleet_health?.fleet_health_score ?? 0 }}%</span>
                <span class="text-caption text-medium-emphasis">Health</span>
              </div>
            </v-progress-circular>
          </div>
          <v-divider class="my-3" />
          <div class="d-flex flex-column ga-2">
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis d-flex align-center ga-1"><v-icon size="16" color="success">mdi-check-circle</v-icon>Inspection Pass Rate</span>
              <span class="text-body-2 font-weight-bold">{{ data?.fleet_health?.inspection_pass_rate ?? 0 }}%</span>
            </div>
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis d-flex align-center ga-1"><v-icon size="16" color="warning">mdi-wrench</v-icon>Maintenance Ratio</span>
              <span class="text-body-2 font-weight-bold">{{ data?.fleet_health?.maintenance_pct ?? 0 }}%</span>
            </div>
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis d-flex align-center ga-1"><v-icon size="16" color="error">mdi-car-off</v-icon>Out of Service</span>
              <span class="text-body-2 font-weight-bold">{{ data?.fleet_health?.out_of_service_pct ?? 0 }}%</span>
            </div>
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis d-flex align-center ga-1"><v-icon size="16" color="info">mdi-clipboard-check</v-icon>Total Inspections</span>
              <span class="text-body-2 font-weight-bold">{{ data?.fleet_health?.total_inspections ?? 0 }}</span>
            </div>
          </div>
        </v-card>
      </v-col>

      <v-col cols="12" md="7">
        <v-card elevation="0" border class="pa-5 h-100">
          <div class="d-flex align-center justify-space-between mb-3">
            <h3 class="text-subtitle-2 font-weight-medium d-flex align-center ga-2 section-heading">
              <v-icon size="small" color="primary">mdi-chart-donut</v-icon> Fleet Composition
            </h3>
          </div>
          <v-row dense>
            <v-col cols="6">
              <div class="comp-section">
                <p class="text-caption font-weight-medium mb-2 text-medium-emphasis">BY STATUS</p>
                <div v-for="s in statusRows" :key="s.key" class="d-flex align-center ga-2 mb-2">
                  <span class="dot" :class="s.dotClass" />
                  <span class="text-body-2 text-capitalize flex-grow-1">{{ s.key.replace('_', ' ') }}</span>
                  <v-chip size="x-small" variant="tonal" :color="s.color">{{ s.count }}</v-chip>
                </div>
              </div>
            </v-col>
            <v-col cols="6">
              <div class="comp-section">
                <p class="text-caption font-weight-medium mb-2 text-medium-emphasis">BY OWNERSHIP</p>
                <div v-for="o in ownershipRows" :key="o.key" class="d-flex align-center ga-2 mb-2">
                  <span class="dot" :class="o.dotClass" />
                  <span class="text-body-2 text-capitalize flex-grow-1">{{ o.label }}</span>
                  <v-chip size="x-small" variant="tonal" :color="o.color">{{ o.count }}</v-chip>
                </div>
              </div>
              <v-divider class="my-3" />
              <div class="d-flex align-center justify-space-between mb-1">
                <span class="text-body-2 text-medium-emphasis d-flex align-center ga-1"><v-icon size="16" color="success">mdi-ev-station</v-icon>Electric / Hydrogen</span>
                <span class="text-body-2 font-weight-bold">{{ data?.ev_stats?.count ?? 0 }}</span>
              </div>
              <div v-if="(data?.ev_stats?.count ?? 0) > 0" class="d-flex align-center justify-space-between">
                <span class="text-caption text-medium-emphasis ml-5">Avg SOC / SOH</span>
                <span class="text-caption font-weight-bold">{{ data?.ev_stats?.avg_state_of_charge?.toFixed(0) ?? 0 }}% / {{ data?.ev_stats?.avg_state_of_health?.toFixed(0) ?? 0 }}%</span>
              </div>
            </v-col>
          </v-row>
        </v-card>
      </v-col>
    </v-row>

    <!-- Mini charts -->
    <v-row dense>
      <v-col cols="12" md="6">
        <DashboardChart :option="acquisitionTrendOption" title="Acquisition Trend" icon="mdi-chart-line" height="240px" />
      </v-col>
      <v-col cols="12" md="6">
        <DashboardChart :option="revenueTrendOption" title="Revenue Trend" icon="mdi-chart-line-variant" height="240px" />
      </v-col>
    </v-row>

    <!-- Vehicles Needing Attention & Idle Vehicles -->
    <v-row dense>
      <v-col cols="12" md="6">
        <v-card elevation="0" border class="pa-5 h-100">
          <div class="d-flex align-center justify-space-between mb-3">
            <h3 class="text-subtitle-2 font-weight-medium d-flex align-center ga-2 section-heading">
              <v-icon size="small" color="error">mdi-alert-circle-outline</v-icon> Vehicles Needing Attention
            </h3>
          </div>
          <div class="attention-grid">
            <div class="attention-card attention-maintenance">
              <v-icon color="warning" size="28">mdi-wrench</v-icon>
              <div class="attention-val">{{ data?.in_maintenance ?? 0 }}</div>
              <div class="attention-lbl">In Maintenance</div>
            </div>
            <div class="attention-card attention-oos">
              <v-icon color="error" size="28">mdi-car-off</v-icon>
              <div class="attention-val">{{ data?.out_of_service ?? 0 }}</div>
              <div class="attention-lbl">Out of Service</div>
            </div>
            <div class="attention-card attention-fail">
              <v-icon color="red-darken-2" size="28">mdi-clipboard-alert</v-icon>
              <div class="attention-val">{{ data?.fleet_health?.fail_count ?? 0 }}</div>
              <div class="attention-lbl">Failed Inspections</div>
            </div>
            <div class="attention-card attention-retired">
              <v-icon color="grey" size="28">mdi-car-disabled</v-icon>
              <div class="attention-val">{{ data?.retired ?? 0 }}</div>
              <div class="attention-lbl">Retired</div>
            </div>
          </div>
        </v-card>
      </v-col>
      <v-col cols="12" md="6">
        <v-card elevation="0" border class="pa-5 h-100">
          <div class="d-flex align-center justify-space-between mb-3">
            <h3 class="text-subtitle-2 font-weight-medium d-flex align-center ga-2 section-heading">
              <v-icon size="small" color="info">mdi-chart-bar</v-icon> Utilization and Revenue
            </h3>
          </div>
          <div class="util-grid">
            <div class="util-card">
              <div class="util-val" style="color:#16a34a">{{ data?.utilization?.active_rentals ?? 0 }}</div>
              <div class="util-lbl">Active Rentals</div>
            </div>
            <div class="util-card">
              <div class="util-val" style="color:#0ea5e9">{{ data?.utilization?.completed_rentals ?? 0 }}</div>
              <div class="util-lbl">Completed</div>
            </div>
            <div class="util-card">
              <div class="util-val" style="color:#f59e0b">{{ data?.utilization?.overdue_rentals ?? 0 }}</div>
              <div class="util-lbl">Overdue</div>
            </div>
            <div class="util-card">
              <div class="util-val" style="color:#a855f7">{{ data?.utilization?.idle_vehicles ?? 0 }}</div>
              <div class="util-lbl">Idle Vehicles</div>
            </div>
          </div>
          <v-divider class="my-3" />
          <div class="d-flex flex-column ga-2">
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis">Total Revenue</span>
              <span class="text-body-1 font-weight-bold" style="color:#059669">{{ currencySymbol }}{{ revenueFmt }}</span>
            </div>
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis">Avg Revenue / Vehicle</span>
              <span class="text-body-2 font-weight-bold">{{ currencySymbol }}{{ avgRevFmt }}</span>
            </div>
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis">Max Revenue (single vehicle)</span>
              <span class="text-body-2 font-weight-bold">{{ currencySymbol }}{{ maxRevFmt }}</span>
            </div>
          </div>
        </v-card>
      </v-col>
    </v-row>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ data: any }>()
const { currencySymbol } = useCurrency()

const data = computed(() => props.data)

const healthColor = computed(() => {
  const s = data.value?.fleet_health?.fleet_health_score ?? 0
  if (s >= 75) return 'success'
  if (s >= 50) return 'warning'
  return 'error'
})

const bookValueFmt = computed(() => {
  const v = data.value?.cost_analysis?.total_book_value ?? 0
  return Number(v).toLocaleString(undefined, { maximumFractionDigits: 0 })
})
const depLossFmt = computed(() => {
  const v = data.value?.cost_analysis?.total_depreciation_loss ?? 0
  return Number(v).toLocaleString(undefined, { maximumFractionDigits: 0 })
})
const revenueFmt = computed(() => {
  const v = data.value?.utilization?.total_revenue ?? 0
  return Number(v).toLocaleString(undefined, { maximumFractionDigits: 0 })
})
const avgRevFmt = computed(() => {
  const v = data.value?.utilization?.avg_revenue_per_vehicle ?? 0
  return Number(v).toLocaleString(undefined, { maximumFractionDigits: 0 })
})
const maxRevFmt = computed(() => {
  const v = data.value?.utilization?.max_revenue ?? 0
  return Number(v).toLocaleString(undefined, { maximumFractionDigits: 0 })
})

const statusRows = computed(() => {
  const sb = data.value?.status_breakdown || []
  const colors: Record<string, string> = { active: 'success', in_maintenance: 'info', out_of_service: 'warning', retired: 'grey' }
  const dots: Record<string, string> = { active: 'dot-success', in_maintenance: 'dot-info', out_of_service: 'dot-warning', retired: 'dot-grey' }
  return sb.map((s: any) => ({ key: s.status, count: s.count, color: colors[s.status] || 'grey', dotClass: dots[s.status] || 'dot-grey' }))
})

const ownershipRows = computed(() => {
  const ob = data.value?.ownership_breakdown || []
  const labels: Record<string, string> = { self: 'Owned', lease: 'Leased' }
  const colors: Record<string, string> = { self: 'success', lease: 'purple' }
  const dots: Record<string, string> = { self: 'dot-success', lease: 'dot-purple' }
  return ob.map((o: any) => ({
    key: o.ownership, label: labels[o.ownership] || o.ownership,
    count: o.count, color: colors[o.ownership] || 'grey', dotClass: dots[o.ownership] || 'dot-grey',
  }))
})

const acquisitionTrendOption = computed(() => {
  const acq = data.value?.acquisition_trend || []
  const colors = ['#6366f1', '#10b981', '#f59e0b', '#0ea5e9', '#a855f7', '#06b6d4', '#ef4444']
  return {
    tooltip: { trigger: 'axis', backgroundColor: '#1e293b', borderColor: '#334155', textStyle: { color: '#f1f5f9' } },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: acq.map((a: any) => a.month), axisLabel: { fontSize: 10, rotate: 30 } },
    yAxis: { type: 'value', minInterval: 1 },
    series: [{
      type: 'bar',
      data: acq.map((a: any, i: number) => ({ value: a.count, itemStyle: { color: colors[i % colors.length] } })),
      barWidth: '55%',
      itemStyle: { borderRadius: [6, 6, 0, 0] },
    }],
  }
})

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
</script>

<style scoped>
.section-heading {
  color: #475569;
}
.v-theme--dark .section-heading {
  color: #94a3b8;
}
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
.dot-purple { background: #a855f7; }

.attention-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
}
.attention-card {
  padding: 16px 8px;
  border-radius: 12px;
  text-align: center;
  border: 1px solid #e2e8f0;
}
.attention-maintenance { background: #fffbeb; border-color: #fef3c7; }
.attention-oos { background: #fef2f2; border-color: #fecaca; }
.attention-fail { background: #fef2f2; border-color: #fecaca; }
.attention-retired { background: #f8fafc; border-color: #e2e8f0; }
.attention-val {
  font-size: 22px;
  font-weight: 800;
  color: #0f172a;
  margin-top: 4px;
}
.attention-lbl {
  font-size: 11px;
  font-weight: 600;
  color: #64748b;
  margin-top: 2px;
}
.v-theme--dark .attention-card { border-color: rgba(var(--v-theme-on-surface), 0.12); }
.v-theme--dark .attention-maintenance { background: rgba(251, 191, 36, 0.12); border-color: rgba(251, 191, 36, 0.25); }
.v-theme--dark .attention-oos { background: rgba(239, 68, 68, 0.12); border-color: rgba(239, 68, 68, 0.25); }
.v-theme--dark .attention-fail { background: rgba(239, 68, 68, 0.12); border-color: rgba(239, 68, 68, 0.25); }
.v-theme--dark .attention-retired { background: rgba(148, 163, 184, 0.1); border-color: rgba(148, 163, 184, 0.2); }
.v-theme--dark .attention-val { color: #f1f5f9; }
.v-theme--dark .attention-lbl { color: #94a3b8; }

.util-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
}
.util-card {
  padding: 14px 8px;
  border-radius: 12px;
  text-align: center;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
}
.util-val {
  font-size: 22px;
  font-weight: 800;
  line-height: 1.1;
}
.util-lbl {
  font-size: 11px;
  font-weight: 600;
  color: #64748b;
  margin-top: 2px;
}
.v-theme--dark .util-card {
  background: rgb(var(--v-theme-surface));
  border-color: rgba(var(--v-theme-on-surface), 0.12);
}
.v-theme--dark .util-lbl { color: #94a3b8; }

@media (max-width: 800px) {
  .attention-grid, .util-grid { grid-template-columns: repeat(2, 1fr); }
}
</style>
