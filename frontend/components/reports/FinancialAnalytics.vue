<template>
  <div class="d-flex flex-column ga-4">
    <!-- KPI Cards Row -->
    <v-row dense>
      <v-col cols="12" sm="6" md="3">
        <v-card elevation="0" border rounded="lg" class="pa-4 h-100" style="background: linear-gradient(135deg, #f0fdf4, #ecfdf5); border-color: #bbf7d0">
          <div class="d-flex align-center justify-space-between mb-2">
            <div class="d-flex align-center ga-2">
              <div class="d-flex align-center justify-center rounded-lg" style="width: 36px; height: 36px; background: #dcfce7">
                <v-icon color="success" size="small">mdi-cash-multiple</v-icon>
              </div>
              <span class="text-caption font-weight-medium text-medium-emphasis">Total Revenue</span>
            </div>
            <v-chip v-if="trends.revenue_change_pct" size="x-small" :color="revenueUp ? 'success' : 'error'" variant="flat" class="text-caption">
              <v-icon size="x-small" start>{{ revenueUp ? 'mdi-trending-up' : 'mdi-trending-down' }}</v-icon>
              {{ Math.abs(trends.revenue_change_pct) }}%
            </v-chip>
          </div>
          <h2 class="text-h4 font-weight-bold" style="color: #166534">{{ currencySymbol }}{{ formatNum(summary.revenue) }}</h2>
          <p class="text-caption text-medium-emphasis mt-1">vs {{ currencySymbol }}{{ formatNum(trends.prev_revenue) }} last period</p>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="3">
        <v-card elevation="0" border rounded="lg" class="pa-4 h-100" style="background: linear-gradient(135deg, #fef2f2, #fef2f2); border-color: #fecaca">
          <div class="d-flex align-center justify-space-between mb-2">
            <div class="d-flex align-center ga-2">
              <div class="d-flex align-center justify-center rounded-lg" style="width: 36px; height: 36px; background: #fee2e2">
                <v-icon color="error" size="small">mdi-cash-off</v-icon>
              </div>
              <span class="text-caption font-weight-medium text-medium-emphasis">Total Costs</span>
            </div>
            <v-chip v-if="trends.cost_change_pct" size="x-small" :color="costUp ? 'error' : 'success'" variant="flat" class="text-caption">
              <v-icon size="x-small" start>{{ costUp ? 'mdi-trending-up' : 'mdi-trending-down' }}</v-icon>
              {{ Math.abs(trends.cost_change_pct) }}%
            </v-chip>
          </div>
          <h2 class="text-h4 font-weight-bold" style="color: #991b1b">{{ currencySymbol }}{{ formatNum(summary.total_costs) }}</h2>
          <p class="text-caption text-medium-emphasis mt-1">{{ currencySymbol }}{{ formatNum(summary.operating_costs) }} opex · {{ currencySymbol }}{{ formatNum(summary.fixed_costs) }} fixed</p>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="3">
        <v-card elevation="0" border rounded="lg" class="pa-4 h-100" style="background: linear-gradient(135deg, #eff6ff, #f0f9ff); border-color: #bfdbfe">
          <div class="d-flex align-center justify-space-between mb-2">
            <div class="d-flex align-center ga-2">
              <div class="d-flex align-center justify-center rounded-lg" style="width: 36px; height: 36px; background: #dbeafe">
                <v-icon :color="profitPositive ? 'primary' : 'error'" size="small">mdi-chart-line-variant</v-icon>
              </div>
              <span class="text-caption font-weight-medium text-medium-emphasis">Net Profit</span>
            </div>
            <v-chip size="x-small" :color="profitPositive ? 'primary' : 'error'" variant="flat" class="text-caption">
              {{ summary.net_margin }}% margin
            </v-chip>
          </div>
          <h2 class="text-h4 font-weight-bold" :style="{ color: profitPositive ? '#1e40af' : '#991b1b' }">
            {{ profitPositive ? '' : '-' }}{{ currencySymbol }}{{ formatNum(Math.abs(summary.net_profit)) }}
          </h2>
          <p class="text-caption text-medium-emphasis mt-1">Gross: {{ currencySymbol }}{{ formatNum(summary.gross_profit) }} ({{ summary.gross_margin }}%)</p>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="3">
        <v-card elevation="0" border rounded="lg" class="pa-4 h-100" style="background: linear-gradient(135deg, #faf5ff, #fdf4ff); border-color: #e9d5ff">
          <div class="d-flex align-center justify-space-between mb-2">
            <div class="d-flex align-center ga-2">
              <div class="d-flex align-center justify-center rounded-lg" style="width: 36px; height: 36px; background: #f3e8ff">
                <v-icon color="deep-purple" size="small">mdi-wallet</v-icon>
              </div>
              <span class="text-caption font-weight-medium text-medium-emphasis">Cash Collected</span>
            </div>
            <v-chip v-if="trends.cash_change_pct" size="x-small" :color="cashUp ? 'success' : 'warning'" variant="flat" class="text-caption">
              <v-icon size="x-small" start>{{ cashUp ? 'mdi-trending-up' : 'mdi-trending-down' }}</v-icon>
              {{ Math.abs(trends.cash_change_pct) }}%
            </v-chip>
          </div>
          <h2 class="text-h4 font-weight-bold" style="color: #6b21a8">{{ currencySymbol }}{{ formatNum(summary.cash_collected) }}</h2>
          <p class="text-caption text-medium-emphasis mt-1">Outstanding A/R: {{ currencySymbol }}{{ formatNum(summary.outstanding) }}</p>
        </v-card>
      </v-col>
    </v-row>

    <!-- ── EBITDA & Breakeven Cards ── -->
    <v-row dense>
      <v-col cols="6" md="3">
        <v-card variant="outlined" rounded="lg" class="kpi-card pa-3 h-100">
          <div class="d-flex align-center ga-2 mb-1">
            <v-icon color="indigo" size="small">mdi-finance</v-icon>
            <span class="text-caption text-medium-emphasis font-weight-medium">EBITDA</span>
          </div>
          <p class="text-h5 font-weight-bold kpi-value" :style="{ color: ebitdaPositive ? '#4338ca' : '#991b1b' }">
            {{ currencySymbol }}{{ formatNum(summary.ebitda) }}
          </p>
          <p class="text-caption kpi-sub">{{ summary.ebitda_margin }}% margin</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card variant="outlined" rounded="lg" class="kpi-card pa-3 h-100">
          <div class="d-flex align-center ga-2 mb-1">
            <v-icon color="warning" size="small">mdi-scale-balance</v-icon>
            <span class="text-caption text-medium-emphasis font-weight-medium">Breakeven Revenue</span>
          </div>
          <p class="text-h5 font-weight-bold kpi-value" style="color: #b45309">
            {{ currencySymbol }}{{ formatNum(summary.breakeven_revenue) }}
          </p>
          <p class="text-caption kpi-sub">Safety: {{ summary.margin_of_safety_pct }}%</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card variant="outlined" rounded="lg" class="kpi-card pa-3 h-100">
          <div class="d-flex align-center ga-2 mb-1">
            <v-icon color="info" size="small">mdi-trending-up</v-icon>
            <span class="text-caption text-medium-emphasis font-weight-medium">Return on Assets</span>
          </div>
          <p class="text-h5 font-weight-bold kpi-value" :style="{ color: roaPositive ? '#0284c7' : '#991b1b' }">
            {{ summary.roa }}%
          </p>
          <p class="text-caption kpi-sub">Book: {{ currencySymbol }}{{ formatNum(summary.total_book_value) }}</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card variant="outlined" rounded="lg" class="kpi-card pa-3 h-100">
          <div class="d-flex align-center ga-2 mb-1">
            <v-icon color="cyan-darken-1" size="small">mdi-clock-fast</v-icon>
            <span class="text-caption text-medium-emphasis font-weight-medium">Days Sales Outstanding</span>
          </div>
          <p class="text-h5 font-weight-bold kpi-value" style="color: #0e7490">
            {{ summary.dso }}
          </p>
          <p class="text-caption kpi-sub">days to collect</p>
        </v-card>
      </v-col>
    </v-row>

    <!-- P&L Statement + Margin Gauge -->
    <v-row dense>
      <v-col cols="12" md="8">
        <v-card elevation="0" border rounded="lg" class="pa-5 h-100 kpi-card">
          <div class="d-flex align-center ga-2 mb-4">
            <v-icon color="primary" size="small">mdi-file-chart</v-icon>
            <h3 class="text-subtitle-1 font-weight-bold section-heading">Profit and Loss Statement</h3>
          </div>
          <div class="d-flex flex-column ga-1">
            <!-- Revenue -->
            <div class="d-flex justify-space-between align-center py-2 px-3 rounded-lg" style="background: #f0fdf4">
              <span class="text-body-2 font-weight-medium" style="color: #166534">Rental Revenue</span>
              <span class="text-body-1 font-weight-bold" style="color: #166534">{{ currencySymbol }}{{ formatNum(summary.revenue) }}</span>
            </div>
            <!-- Minus: Variable Costs -->
            <div class="d-flex justify-space-between align-center py-1.5 px-3">
              <span class="text-body-2 text-medium-emphasis pl-4">Variable Costs (Fuel, Service, Damage)</span>
              <span class="text-body-2 font-weight-medium" style="color: #dc2626">-{{ currencySymbol }}{{ formatNum(summary.operating_costs) }}</span>
            </div>
            <v-divider class="my-1" />
            <!-- Gross Profit -->
            <div class="d-flex justify-space-between align-center py-2 px-3 rounded-lg" style="background: #eff6ff">
              <span class="text-body-2 font-weight-bold" style="color: #1e40af">Gross Profit</span>
              <div class="text-right">
                <span class="text-body-1 font-weight-bold" style="color: #1e40af">{{ currencySymbol }}{{ formatNum(summary.gross_profit) }}</span>
                <v-chip size="x-small" color="primary" variant="tonal" class="ml-2">{{ summary.gross_margin }}%</v-chip>
              </div>
            </div>
            <!-- Minus: Fixed Costs -->
            <div class="d-flex justify-space-between align-center py-1.5 px-3">
              <span class="text-body-2 text-medium-emphasis pl-4">Fixed Costs (Lease, Insurance, Depreciation)</span>
              <span class="text-body-2 font-weight-medium" style="color: #dc2626">-{{ currencySymbol }}{{ formatNum(summary.fixed_costs) }}</span>
            </div>
            <v-divider class="my-2 border-t-2" />
            <!-- Net Profit -->
            <div class="d-flex justify-space-between align-center py-3 px-3 rounded-lg" :style="{ background: profitPositive ? '#f0fdf4' : '#fef2f2' }">
              <span class="text-body-1 font-weight-bold" :style="{ color: profitPositive ? '#166534' : '#991b1b' }">Net Profit / (Loss)</span>
              <div class="text-right">
                <span class="text-h6 font-weight-bold" :style="{ color: profitPositive ? '#166534' : '#991b1b' }">
                  {{ profitPositive ? '' : '-' }}{{ currencySymbol }}{{ formatNum(Math.abs(summary.net_profit)) }}
                </span>
                <v-chip size="x-small" :color="profitPositive ? 'success' : 'error'" variant="flat" class="ml-2">{{ summary.net_margin }}%</v-chip>
              </div>
            </div>
          </div>
        </v-card>
      </v-col>

      <v-col cols="12" md="4">
        <v-card elevation="0" border rounded="lg" class="pa-5 h-100 d-flex flex-column">
          <div class="d-flex align-center ga-2 mb-4">
            <v-icon color="indigo" size="small">mdi-gauge</v-icon>
            <h3 class="text-subtitle-1 font-weight-bold section-heading">Margin Health</h3>
          </div>
          <div class="flex-grow-1 d-flex flex-column justify-center align-center ga-3">
            <div class="position-relative d-flex align-center justify-center" style="width: 160px; height: 160px">
              <v-progress-circular :model-value="marginValue" :size="160" :width="12" :color="marginColor" rounded>
                <div class="text-center">
                  <div class="text-h5 font-weight-bold kpi-value">{{ summary.net_margin }}%</div>
                  <div class="text-caption text-medium-emphasis">Net Margin</div>
                </div>
              </v-progress-circular>
            </div>
            <div class="d-flex ga-3 mt-2">
              <div class="text-center">
                <div class="text-caption text-medium-emphasis">Gross</div>
                <div class="text-subtitle-2 font-weight-bold kpi-value" style="color: #1e40af">{{ summary.gross_margin }}%</div>
              </div>
              <div class="text-center">
                <div class="text-caption text-medium-emphasis">EBITDA</div>
                <div class="text-subtitle-2 font-weight-bold kpi-value" style="color: #4338ca">{{ summary.ebitda_margin }}%</div>
              </div>
              <div class="text-center">
                <div class="text-caption text-medium-emphasis">Revenue</div>
                <div class="text-subtitle-2 font-weight-bold kpi-value" style="color: #166534">{{ currencySymbol }}{{ formatNum(summary.revenue) }}</div>
              </div>
            </div>
            <v-alert density="compact" variant="tonal" :type="marginAlertType" class="w-100 text-caption mt-2">
              {{ marginAlertText }}
            </v-alert>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <!-- ── Financial Ratios Grid ── -->
    <v-card elevation="0" border rounded="lg" class="kpi-card pa-5">
      <div class="d-flex align-center ga-2 mb-4">
        <v-icon color="primary" size="small">mdi-chart-bar</v-icon>
        <h3 class="text-subtitle-1 font-weight-bold section-heading">Financial Ratios</h3>
      </div>
      <v-row dense>
        <v-col cols="6" md="2">
          <div class="ratio-item">
            <p class="ratio-label">Current Ratio</p>
            <p class="ratio-value" :style="{ color: currentRatioColor }">{{ summary.current_ratio }}</p>
            <p class="ratio-desc">liquidity</p>
          </div>
        </v-col>
        <v-col cols="6" md="2">
          <div class="ratio-item">
            <p class="ratio-label">Quick Ratio</p>
            <p class="ratio-value" :style="{ color: currentRatioColor }">{{ summary.quick_ratio }}</p>
            <p class="ratio-desc">quick liquidity</p>
          </div>
        </v-col>
        <v-col cols="6" md="2">
          <div class="ratio-item">
            <p class="ratio-label">Op. Leverage</p>
            <p class="ratio-value" :style="{ color: operatingLeverageColor }">{{ summary.operating_leverage }}x</p>
            <p class="ratio-desc">profit sensitivity</p>
          </div>
        </v-col>
        <v-col cols="6" md="2">
          <div class="ratio-item">
            <p class="ratio-label">Margin of Safety</p>
            <p class="ratio-value" :style="{ color: marginOfSafetyColor }">{{ summary.margin_of_safety_pct }}%</p>
            <p class="ratio-desc">{{ currencySymbol }}{{ formatNum(summary.margin_of_safety) }}</p>
          </div>
        </v-col>
        <v-col cols="6" md="2">
          <div class="ratio-item">
            <p class="ratio-label">DSO</p>
            <p class="ratio-value" style="color: #0e7490">{{ summary.dso }}</p>
            <p class="ratio-desc">days to collect</p>
          </div>
        </v-col>
        <v-col cols="6" md="2">
          <div class="ratio-item">
            <p class="ratio-label">ROA</p>
            <p class="ratio-value" :style="{ color: roaPositive ? '#0284c7' : '#991b1b' }">{{ summary.roa }}%</p>
            <p class="ratio-desc">return on assets</p>
          </div>
        </v-col>
      </v-row>
    </v-card>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{ summary: any; trends: any }>()
const { currencySymbol } = useCurrency()

const revenueUp = computed(() => (props.trends?.revenue_change_pct || 0) >= 0)
const costUp = computed(() => (props.trends?.cost_change_pct || 0) >= 0)
const cashUp = computed(() => (props.trends?.cash_change_pct || 0) >= 0)
const profitPositive = computed(() => (props.summary?.net_profit || 0) >= 0)
const ebitdaPositive = computed(() => (props.summary?.ebitda || 0) >= 0)
const roaPositive = computed(() => (props.summary?.roa || 0) >= 0)

const currentRatioColor = computed(() => {
  const v = props.summary?.current_ratio || 0
  if (v >= 1.5) return '#16a34a'
  if (v >= 1.0) return '#f59e0b'
  return '#dc2626'
})
const operatingLeverageColor = computed(() => {
  const v = props.summary?.operating_leverage || 0
  if (v >= 2) return '#16a34a'
  if (v >= 1) return '#f59e0b'
  return '#dc2626'
})
const marginOfSafetyColor = computed(() => {
  const v = props.summary?.margin_of_safety_pct || 0
  if (v >= 30) return '#16a34a'
  if (v >= 10) return '#f59e0b'
  return '#dc2626'
})

const marginValue = computed(() => Math.max(0, Math.min(100, props.summary?.net_margin || 0)))
const marginColor = computed(() => {
  const m = props.summary?.net_margin || 0
  if (m >= 20) return 'success'
  if (m >= 10) return 'warning'
  if (m >= 0) return 'orange'
  return 'error'
})
const marginAlertType = computed(() => {
  const m = props.summary?.net_margin || 0
  if (m >= 10) return 'success'
  if (m >= 0) return 'info'
  return 'error'
})
const marginAlertText = computed(() => {
  const m = props.summary?.net_margin || 0
  if (m >= 20) return 'Excellent margin - fleet is profitable'
  if (m >= 10) return 'Healthy margin - room for growth'
  if (m >= 0) return 'Thin margin - monitor costs'
  return 'Negative margin - action needed'
})

function formatNum(n: number | undefined) {
  if (!n) return '0'
  return Math.round(n).toLocaleString()
}
</script>

<style scoped>
.section-heading { color: #1e293b; }
.kpi-card { background: #fff; }
.kpi-value { color: #1e293b; }
.kpi-sub { color: #64748b; }

.ratio-item {
  text-align: center;
  padding: 12px 8px;
  border-radius: 12px;
  background: #f8fafc;
}
.ratio-label { font-size: 0.75rem; font-weight: 600; color: #64748b; margin-bottom: 4px; text-transform: uppercase; letter-spacing: 0.5px; }
.ratio-value { font-size: 1.5rem; font-weight: 800; line-height: 1.2; }
.ratio-desc { font-size: 0.7rem; color: #94a3b8; margin-top: 2px; }

.v-theme--dark .section-heading { color: #e2e8f0; }
.v-theme--dark .kpi-card { background: rgb(var(--v-theme-surface)) !important; border-color: rgba(255,255,255,0.08) !important; }
.v-theme--dark .kpi-value { color: #f1f5f9 !important; }
.v-theme--dark .kpi-sub { color: #94a3b8 !important; }
.v-theme--dark .ratio-item { background: rgba(255,255,255,0.05); }
.v-theme--dark .ratio-label { color: #94a3b8; }
.v-theme--dark .ratio-desc { color: #64748b; }
</style>
