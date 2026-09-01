<template>
  <div class="d-flex flex-column ga-4">
    <!-- Fleet Health Score -->
    <v-row dense>
      <v-col cols="12" md="4">
        <v-card elevation="0" border class="pa-5 text-center h-100">
          <h3 class="text-subtitle-2 font-weight-medium d-flex align-center justify-center ga-2 mb-3 section-heading">
            <v-icon size="small" color="success">mdi-shield-check</v-icon> Fleet Health Score
          </h3>
          <v-progress-circular :model-value="healthScore" :color="healthColor" size="160" width="12" class="my-2">
            <div class="d-flex flex-column align-center">
              <span class="text-h4 font-weight-bold" :class="healthTextColor">{{ healthScore }}%</span>
              <span class="text-caption text-medium-emphasis">{{ healthLabel }}</span>
            </div>
          </v-progress-circular>
          <p class="text-caption text-medium-emphasis mt-2">Weighted: Utilization 30% + Inspections 30% + Active 40%</p>
        </v-card>
      </v-col>
      <v-col cols="12" md="8">
        <v-card elevation="0" border class="pa-5 h-100">
          <h3 class="text-subtitle-2 font-weight-medium d-flex align-center ga-2 mb-4 section-heading">
            <v-icon size="small" color="primary">mdi-chart-bar</v-icon> Health Indicators
          </h3>
          <div class="health-grid">
            <div class="health-indicator">
              <div class="d-flex align-center ga-2 mb-1">
                <v-icon size="20" color="success">mdi-check-circle</v-icon>
                <span class="text-body-2 font-weight-medium">Inspection Pass Rate</span>
              </div>
              <v-progress-linear :model-value="data?.fleet_health?.inspection_pass_rate ?? 0" color="success" height="10" rounded class="mb-1" />
              <div class="d-flex align-center justify-space-between">
                <span class="text-caption text-medium-emphasis">{{ data?.fleet_health?.pass_count ?? 0 }} pass / {{ data?.fleet_health?.fail_count ?? 0 }} fail</span>
                <span class="text-body-2 font-weight-bold">{{ data?.fleet_health?.inspection_pass_rate ?? 0 }}%</span>
              </div>
            </div>
            <div class="health-indicator">
              <div class="d-flex align-center ga-2 mb-1">
                <v-icon size="20" color="primary">mdi-gauge-full</v-icon>
                <span class="text-body-2 font-weight-medium">Utilization Rate</span>
              </div>
              <v-progress-linear :model-value="data?.utilization?.utilization_rate ?? 0" color="primary" height="10" rounded class="mb-1" />
              <div class="d-flex align-center justify-space-between">
                <span class="text-caption text-medium-emphasis">{{ data?.utilization?.vehicles_with_active_rentals ?? 0 }} on rent</span>
                <span class="text-body-2 font-weight-bold">{{ data?.utilization?.utilization_rate ?? 0 }}%</span>
              </div>
            </div>
            <div class="health-indicator">
              <div class="d-flex align-center ga-2 mb-1">
                <v-icon size="20" color="success">mdi-car-connected</v-icon>
                <span class="text-body-2 font-weight-medium">Active Fleet</span>
              </div>
              <v-progress-linear :model-value="activePct" color="success" height="10" rounded class="mb-1" />
              <div class="d-flex align-center justify-space-between">
                <span class="text-caption text-medium-emphasis">{{ data?.active ?? 0 }} active / {{ data?.total_vehicles ?? 0 }} total</span>
                <span class="text-body-2 font-weight-bold">{{ activePct }}%</span>
              </div>
            </div>
            <div class="health-indicator">
              <div class="d-flex align-center ga-2 mb-1">
                <v-icon size="20" color="warning">mdi-wrench</v-icon>
                <span class="text-body-2 font-weight-medium">Maintenance Ratio</span>
              </div>
              <v-progress-linear :model-value="data?.fleet_health?.maintenance_pct ?? 0" color="warning" height="10" rounded class="mb-1" />
              <div class="d-flex align-center justify-space-between">
                <span class="text-caption text-medium-emphasis">{{ data?.in_maintenance ?? 0 }} in service</span>
                <span class="text-body-2 font-weight-bold">{{ data?.fleet_health?.maintenance_pct ?? 0 }}%</span>
              </div>
            </div>
            <div class="health-indicator">
              <div class="d-flex align-center ga-2 mb-1">
                <v-icon size="20" color="error">mdi-car-off</v-icon>
                <span class="text-body-2 font-weight-medium">Out of Service</span>
              </div>
              <v-progress-linear :model-value="data?.fleet_health?.out_of_service_pct ?? 0" color="error" height="10" rounded class="mb-1" />
              <div class="d-flex align-center justify-space-between">
                <span class="text-caption text-medium-emphasis">{{ data?.out_of_service ?? 0 }} out</span>
                <span class="text-body-2 font-weight-bold">{{ data?.fleet_health?.out_of_service_pct ?? 0 }}%</span>
              </div>
            </div>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <!-- Attention and Inspection Cards -->
    <v-row dense>
      <v-col cols="12" md="6">
        <v-card elevation="0" border class="pa-5 h-100">
          <div class="d-flex align-center justify-space-between mb-3">
            <h3 class="text-subtitle-2 font-weight-medium d-flex align-center ga-2 section-heading">
              <v-icon size="small" color="error">mdi-alert-circle-outline</v-icon> Attention Required
            </h3>
            <v-chip :color="attentionCount > 0 ? 'error' : 'success'" variant="tonal" size="small">{{ attentionCount }} items</v-chip>
          </div>
          <div class="attention-list">
            <div class="attention-item">
              <v-icon color="warning" size="24">mdi-wrench</v-icon>
              <div class="flex-grow-1">
                <p class="text-body-2 font-weight-medium">In Maintenance</p>
                <p class="text-caption text-medium-emphasis">Vehicles currently undergoing repair or service</p>
              </div>
              <span class="text-h6 font-weight-bold" style="color: #d97706">{{ data?.in_maintenance ?? 0 }}</span>
            </div>
            <v-divider class="my-2" />
            <div class="attention-item">
              <v-icon color="error" size="24">mdi-car-off</v-icon>
              <div class="flex-grow-1">
                <p class="text-body-2 font-weight-medium">Out of Service</p>
                <p class="text-caption text-medium-emphasis">Vehicles removed from active duty</p>
              </div>
              <span class="text-h6 font-weight-bold" style="color: #dc2626">{{ data?.out_of_service ?? 0 }}</span>
            </div>
            <v-divider class="my-2" />
            <div class="attention-item">
              <v-icon color="red-darken-2" size="24">mdi-clipboard-alert</v-icon>
              <div class="flex-grow-1">
                <p class="text-body-2 font-weight-medium">Failed Inspections</p>
                <p class="text-caption text-medium-emphasis">Vehicles that failed their last inspection</p>
              </div>
              <span class="text-h6 font-weight-bold" style="color: #b91c1c">{{ data?.fleet_health?.fail_count ?? 0 }}</span>
            </div>
            <v-divider class="my-2" />
            <div class="attention-item">
              <v-icon color="grey" size="24">mdi-car-disabled</v-icon>
              <div class="flex-grow-1">
                <p class="text-body-2 font-weight-medium">Retired Vehicles</p>
                <p class="text-caption text-medium-emphasis">Vehicles no longer in the active fleet</p>
              </div>
              <span class="text-h6 font-weight-bold" style="color: #64748b">{{ data?.retired ?? 0 }}</span>
            </div>
          </div>
        </v-card>
      </v-col>
      <v-col cols="12" md="6">
        <v-card elevation="0" border class="pa-5 h-100">
          <div class="d-flex align-center justify-space-between mb-3">
            <h3 class="text-subtitle-2 font-weight-medium d-flex align-center ga-2 section-heading">
              <v-icon size="small" color="info">mdi-clipboard-check</v-icon> Inspection Results
            </h3>
            <v-chip size="small" variant="tonal" color="info">{{ data?.fleet_health?.total_inspections ?? 0 }} total</v-chip>
          </div>
          <div class="inspection-visual">
            <div class="pass-fail-bars">
              <div class="pf-bar pass">
                <div class="pf-bar-fill" :style="{ height: passBarPct + '%' }">
                  <span class="pf-count">{{ data?.fleet_health?.pass_count ?? 0 }}</span>
                </div>
                <span class="pf-label">Pass</span>
              </div>
              <div class="pf-bar fail">
                <div class="pf-bar-fill" :style="{ height: failBarPct + '%' }">
                  <span class="pf-count">{{ data?.fleet_health?.fail_count ?? 0 }}</span>
                </div>
                <span class="pf-label">Fail</span>
              </div>
            </div>
            <v-divider class="my-4" />
            <div class="d-flex flex-column ga-2">
              <div class="d-flex align-center justify-space-between">
                <span class="text-body-2 text-medium-emphasis">Total Inspections</span>
                <span class="text-body-1 font-weight-bold">{{ data?.fleet_health?.total_inspections ?? 0 }}</span>
              </div>
              <div class="d-flex align-center justify-space-between">
                <span class="text-body-2 text-medium-emphasis d-flex align-center ga-1"><v-icon size="16" color="success">mdi-check</v-icon>Passed</span>
                <span class="text-body-1 font-weight-bold" style="color: #16a34a">{{ data?.fleet_health?.pass_count ?? 0 }}</span>
              </div>
              <div class="d-flex align-center justify-space-between">
                <span class="text-body-2 text-medium-emphasis d-flex align-center ga-1"><v-icon size="16" color="error">mdi-close</v-icon>Failed</span>
                <span class="text-body-1 font-weight-bold" style="color: #dc2626">{{ data?.fleet_health?.fail_count ?? 0 }}</span>
              </div>
              <div class="d-flex align-center justify-space-between">
                <span class="text-body-2 text-medium-emphasis d-flex align-center ga-1"><v-icon size="16" color="success">mdi-percent</v-icon>Pass Rate</span>
                <span class="text-body-1 font-weight-bold" :style="{ color: passRateColor }">{{ data?.fleet_health?.inspection_pass_rate ?? 0 }}%</span>
              </div>
            </div>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <!-- Mileage and Value Stats -->
    <v-row dense>
      <v-col cols="12" md="6">
        <v-card elevation="0" border class="pa-5">
          <div class="d-flex align-center justify-space-between mb-3">
            <h3 class="text-subtitle-2 font-weight-medium d-flex align-center ga-2 section-heading">
              <v-icon size="small" color="secondary">mdi-speedometer</v-icon> Mileage and Engine Hours
            </h3>
          </div>
          <div class="d-flex flex-column ga-3">
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis">Total Mileage</span>
              <span class="text-body-1 font-weight-bold">{{ Number(data?.mileage_stats?.total_mileage ?? 0).toLocaleString() }} units</span>
            </div>
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis">Average Mileage</span>
              <span class="text-body-1 font-weight-bold">{{ Number(data?.mileage_stats?.avg_mileage ?? 0).toLocaleString() }} units</span>
            </div>
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis">Total Engine Hours</span>
              <span class="text-body-1 font-weight-bold">{{ Number(data?.mileage_stats?.total_engine_hours ?? 0).toLocaleString(undefined, { maximumFractionDigits: 0 }) }} hrs</span>
            </div>
            <v-divider />
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis">Cost per km</span>
              <span class="text-body-1 font-weight-bold" style="color: #a855f7">{{ currencySymbol }}{{ Number(data?.cost_analysis?.cost_per_km ?? 0).toLocaleString() }}</span>
            </div>
          </div>
        </v-card>
      </v-col>
      <v-col cols="12" md="6">
        <v-card elevation="0" border class="pa-5">
          <div class="d-flex align-center justify-space-between mb-3">
            <h3 class="text-subtitle-2 font-weight-medium d-flex align-center ga-2 section-heading">
              <v-icon size="small" color="success">mdi-cash</v-icon> Fleet Value
            </h3>
          </div>
          <div class="d-flex flex-column ga-3">
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis">Total Purchase Value</span>
              <span class="text-body-1 font-weight-bold">{{ currencySymbol }}{{ Number(data?.value_stats?.total_purchase_value ?? 0).toLocaleString() }}</span>
            </div>
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis">Avg Purchase Value</span>
              <span class="text-body-1 font-weight-bold">{{ currencySymbol }}{{ Number(data?.value_stats?.avg_purchase_value ?? 0).toLocaleString() }}</span>
            </div>
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis">Total Book Value</span>
              <span class="text-body-1 font-weight-bold" style="color: #16a34a">{{ currencySymbol }}{{ Number(data?.cost_analysis?.total_book_value ?? 0).toLocaleString() }}</span>
            </div>
            <v-divider />
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis">Total Depreciation Loss</span>
              <span class="text-body-1 font-weight-bold" style="color: #dc2626">{{ currencySymbol }}{{ Number(data?.cost_analysis?.total_depreciation_loss ?? 0).toLocaleString() }}</span>
            </div>
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis">Annual Depreciation</span>
              <span class="text-body-1 font-weight-bold" style="color: #d97706">{{ currencySymbol }}{{ Number(data?.cost_analysis?.total_annual_depreciation ?? 0).toLocaleString() }}</span>
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

const healthScore = computed(() => data.value?.fleet_health?.fleet_health_score ?? 0)
const healthColor = computed(() => {
  if (healthScore.value >= 75) return 'success'
  if (healthScore.value >= 50) return 'warning'
  return 'error'
})
const healthTextColor = computed(() => ({
  'text-success': healthScore.value >= 75,
  'text-warning': healthScore.value >= 50 && healthScore.value < 75,
  'text-error': healthScore.value < 50,
}))
const healthLabel = computed(() => {
  if (healthScore.value >= 75) return 'Excellent'
  if (healthScore.value >= 50) return 'Needs Attention'
  return 'Critical'
})

const activePct = computed(() => {
  const total = data.value?.total_vehicles ?? 0
  const active = data.value?.active ?? 0
  return total ? Math.round((active / total) * 100) : 0
})

const attentionCount = computed(() => data.value?.fleet_health?.vehicles_needing_attention ?? 0)

const passBarPct = computed(() => {
  const total = data.value?.fleet_health?.total_inspections ?? 0
  const pass = data.value?.fleet_health?.pass_count ?? 0
  return total ? Math.round((pass / total) * 100) : 0
})
const failBarPct = computed(() => {
  const total = data.value?.fleet_health?.total_inspections ?? 0
  const fail = data.value?.fleet_health?.fail_count ?? 0
  return total ? Math.round((fail / total) * 100) : 0
})
const passRateColor = computed(() => {
  const r = data.value?.fleet_health?.inspection_pass_rate ?? 0
  if (r >= 80) return '#16a34a'
  if (r >= 60) return '#d97706'
  return '#dc2626'
})
</script>

<style scoped>
.section-heading { color: #475569; }
.v-theme--dark .section-heading { color: #94a3b8; }
.health-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}
.health-indicator {
  padding: 12px;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  background: #f8fafc;
}
.v-theme--dark .health-indicator {
  background: rgb(var(--v-theme-surface));
  border-color: rgba(var(--v-theme-on-surface), 0.12);
}

.attention-list {
  display: flex;
  flex-direction: column;
}
.attention-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 4px 0;
}

.inspection-visual {
  display: flex;
  flex-direction: column;
}
.pass-fail-bars {
  display: flex;
  align-items: flex-end;
  justify-content: center;
  gap: 32px;
  height: 140px;
  padding: 0 20px;
}
.pf-bar {
  display: flex;
  flex-direction: column;
  align-items: center;
  height: 100%;
  justify-content: flex-end;
  min-width: 80px;
}
.pf-bar-fill {
  width: 100%;
  min-height: 4px;
  border-radius: 8px 8px 0 0;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding-top: 4px;
  transition: height 0.4s ease;
}
.pf-bar.pass .pf-bar-fill { background: linear-gradient(180deg, #10b981, #059669); }
.pf-bar.fail .pf-bar-fill { background: linear-gradient(180deg, #ef4444, #dc2626); }
.pf-count {
  color: white;
  font-size: 16px;
  font-weight: 800;
}
.pf-label {
  margin-top: 6px;
  font-size: 12px;
  font-weight: 600;
  color: #64748b;
}
.v-theme--dark .pf-label { color: #94a3b8; }

@media (max-width: 800px) {
  .health-grid { grid-template-columns: 1fr; }
}
</style>
