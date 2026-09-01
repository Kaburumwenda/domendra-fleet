<template>
  <div class="d-flex flex-column ga-4">
    <!-- Premium Header -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-2">
      <div>
        <h1 class="text-h4 font-weight-bold d-flex align-center ga-2" style="color: #1e293b">
          <v-icon color="primary" size="large">mdi-gas-station</v-icon>
          Fuel &amp; Energy
        </h1>
        <p class="text-caption text-medium-emphasis mt-1">Premium fuel management — transactions, cards, EV charging, idling, fraud detection &amp; analytics</p>
      </div>
      <div class="d-flex align-center ga-2">
        <v-chip v-if="fraudSummary?.unresolved" color="error" variant="tonal" size="small" @click="tab = 'fraud'" style="cursor: pointer">
          <v-icon start size="small">mdi-shield-alert-outline</v-icon>
          {{ fraudSummary.unresolved }} fraud alert{{ fraudSummary.unresolved === 1 ? '' : 's' }}
        </v-chip>
        <v-btn v-can="'fuel:create'" color="primary" prepend-icon="mdi-plus" @click="quickAddTx">
          <v-icon start>mdi-gas-station</v-icon>
          Quick Add
        </v-btn>
      </div>
    </div>

    <!-- Tabbed Interface -->
    <v-card elevation="0" border rounded="xl" class="overflow-hidden">
      <v-tabs v-model="tab" color="primary" density="comfortable" show-arrows>
        <v-tab value="overview" prepend-icon="mdi-view-dashboard-outline">Overview</v-tab>
        <v-tab value="transactions" prepend-icon="mdi-gas-station">Transactions</v-tab>
        <v-tab value="cards" prepend-icon="mdi-credit-card-multiple-outline">
          Cards
          <v-chip v-if="cardCount" size="x-small" class="ml-2" color="primary" variant="tonal">{{ cardCount }}</v-chip>
        </v-tab>
        <v-tab value="ev" prepend-icon="mdi-ev-station">EV Charging</v-tab>
        <v-tab value="idling" prepend-icon="mdi-engine-off">Idling</v-tab>
        <v-tab value="fraud" prepend-icon="mdi-shield-alert-outline">
          Fraud
          <v-chip v-if="fraudSummary?.unresolved" size="x-small" class="ml-2" color="error" variant="tonal">{{ fraudSummary.unresolved }}</v-chip>
        </v-tab>
        <v-tab value="budgets" prepend-icon="mdi-chart-arc">Budgets &amp; Schedules</v-tab>
        <v-tab value="analytics" prepend-icon="mdi-chart-box-outline">Analytics</v-tab>
      </v-tabs>
      <v-divider />
      <v-window v-model="tab" class="pa-5">
        <v-window-item value="overview">
          <FuelOverview
            :analytics="analytics"
            :charging-summary="chargingSummary"
            :idling-summary="idlingSummary"
            :fraud-summary="fraudSummary"
            :budget-summary="budgetSummary"
            @navigate="tab = $event"
          />
        </v-window-item>
        <v-window-item value="transactions">
          <FuelTransactions
            ref="txComponent"
            :vehicle-options="vehicleOptions"
            :card-options="cardOptions"
            :date-preset-module="datePresetModule"
            :date-params="dateParams"
            @refresh="refreshAll"
          />
        </v-window-item>
        <v-window-item value="cards">
          <FuelCards :vehicle-options="vehicleOptions" :driver-options="driverOptions" @refresh="refreshAll" />
        </v-window-item>
        <v-window-item value="ev">
          <FuelCharging :vehicle-options="vehicleOptions" @refresh="refreshAll" />
        </v-window-item>
        <v-window-item value="idling">
          <FuelIdling :vehicle-options="vehicleOptions" />
        </v-window-item>
        <v-window-item value="fraud">
          <FuelFraud />
        </v-window-item>
        <v-window-item value="budgets">
          <FuelBudgets :vehicle-options="vehicleOptions" @refresh="refreshAll" />
        </v-window-item>
        <v-window-item value="analytics">
          <FuelAnalytics :analytics="analytics" @update-period="refreshAnalytics" @custom-date-range="applyCustomDateRange" />
        </v-window-item>
      </v-window>
    </v-card>
  </div>
</template>

<script setup lang="ts">
const { $api } = useNuxtApp()
const { fetchAnalytics, fetchFraudSummary, fetchChargingSummary, fetchIdlingSummary, fetchBudgetSummary, fetchCards } = useFuelApi()

const tab = ref('overview')
const txComponent = ref<any>(null)

// ---- Shared data for overview & analytics ----
const periodDays = ref(30)
const analyticsParams = ref<Record<string, string>>({})

const { data: analytics, refresh: refreshAnalyticsData } = useAsyncData(
  'fuel-page-analytics',
  () => fetchAnalytics({ ...analyticsParams.value, days: periodDays.value }).catch(() => null) as Promise<any>,
  { default: () => null, watch: [periodDays, analyticsParams] }
)

const { data: fraudSummary, refresh: refreshFraudSummary } = useAsyncData(
  'fuel-page-fraud-summary',
  () => fetchFraudSummary().catch(() => null) as Promise<any>,
  { default: () => null }
)

const { data: chargingSummary, refresh: refreshChargingSummary } = useAsyncData(
  'fuel-page-charging-summary',
  () => fetchChargingSummary(30).catch(() => null) as Promise<any>,
  { default: () => null }
)

const { data: idlingSummary, refresh: refreshIdlingSummary } = useAsyncData(
  'fuel-page-idling-summary',
  () => fetchIdlingSummary(30).catch(() => null) as Promise<any>,
  { default: () => null }
)

const { data: budgetSummary, refresh: refreshBudgetSummary } = useAsyncData(
  'fuel-page-budget-summary',
  () => fetchBudgetSummary().catch(() => ({ rows: [] })) as Promise<any>,
  { default: () => ({ rows: [] }) }
)

// ---- Cards for card options & count ----
const { data: cardData } = useAsyncData(
  'fuel-page-cards',
  () => fetchCards().catch(() => ({ results: [] })) as Promise<any>,
  { default: () => ({ results: [] }) }
)
const cardCount = computed(() => cardData.value?.results?.length || 0)
const cardOptions = computed(() => (cardData.value?.results || []).map((c: any) => ({
  label: `${c.provider} ${c.card_number?.slice(-4) || ''}`,
  value: c.id,
})))

// ---- Vehicles & drivers ----
const { data: vehicleData } = useAsyncData(
  'fuel-page-vehicles',
  () => $api('/vehicles/vehicles/').catch(() => ({ results: [] })) as Promise<any>,
  { default: () => ({ results: [] }) }
)
const vehicleOptions = computed(() => vehicleData.value?.results || [])

const { data: driverData } = useAsyncData(
  'fuel-page-drivers',
  () => $api('/drivers/drivers/').catch(() => ({ results: [] })) as Promise<any>,
  { default: () => ({ results: [] }) }
)
const driverOptions = computed(() => driverData.value?.results || [])

// ---- Passthrough for transactions component ----
const datePresetModule = ref({ value: '30d' })
const dateParams = ref<Record<string, string>>({})

function refreshAnalytics(days: number) {
  analyticsParams.value = {}
  periodDays.value = days
  refreshAnalyticsData()
}

function applyCustomDateRange(range: { date__gte: string; date__lte: string } | null) {
  if (range) {
    analyticsParams.value = { date__gte: range.date__gte, date__lte: range.date__lte }
  } else {
    analyticsParams.value = {}
  }
  refreshAnalyticsData()
}

function refreshAll() {
  refreshAnalyticsData()
  refreshFraudSummary()
  refreshChargingSummary()
  refreshIdlingSummary()
  refreshBudgetSummary()
}

function quickAddTx() {
  tab.value = 'transactions'
  nextTick(() => {
    txComponent.value?.openDialog()
  })
}
</script>
