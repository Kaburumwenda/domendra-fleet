<template>
  <div class="d-flex flex-column ga-4">
    <!-- ── Loading ── -->
    <div v-if="loading" class="d-flex justify-center align-center py-12">
      <v-progress-circular indeterminate size="48" color="primary" />
    </div>

    <!-- ── Empty ── -->
    <div v-else-if="!data || !data.locations?.length" class="text-center text-medium-emphasis py-12">
      <v-icon size="48" class="mb-2">mdi-map-marker-off-outline</v-icon>
      <p>No location data found for the selected period.</p>
    </div>

    <template v-else>
      <!-- ── KPI Cards ── -->
      <v-row dense>
        <v-col cols="6" md="3">
          <StatCard
            label="Locations"
            :value="data.summary.total_locations"
            icon="mdi-map-marker-multiple-outline"
            icon-bg="#eef2ff"
            icon-color="primary"
            :subtitle="`${data.summary.total_vehicles} vehicles (${data.summary.leased_vehicles} leased, ${data.summary.owned_vehicles} owned)`"
          />
        </v-col>
        <v-col cols="6" md="3">
          <StatCard
            label="Total Revenue"
            :value="fmtMoney(data.summary.total_revenue)"
            icon="mdi-cash-multiple"
            icon-bg="#ecfdf5"
            icon-color="success"
            :subtitle="`Cash: ${fmtMoney(data.summary.total_cash_collected)}`"
          />
        </v-col>
        <v-col cols="6" md="3">
          <StatCard
            label="Total Costs"
            :value="fmtMoney(data.summary.total_costs)"
            icon="mdi-cash-off"
            icon-bg="#fef2f2"
            icon-color="error"
            :subtitle="`Variable: ${fmtMoney(data.summary.total_variable_costs)} · Fixed: ${fmtMoney(data.summary.total_fixed_costs)}`"
          />
        </v-col>
        <v-col cols="6" md="3">
          <StatCard
            label="Net Profit"
            :value="fmtMoney(data.summary.net_profit)"
            icon="mdi-chart-line-variant"
            icon-bg="#fff7ed"
            icon-color="warning"
            :subtitle="`Margin: ${data.summary.net_margin}%`"
          />
        </v-col>
      </v-row>

      <!-- ── Top / Bottom location alerts ── -->
      <v-row dense v-if="data.locations.length > 1">
        <v-col cols="12" md="6">
          <v-alert variant="tonal" color="success" density="comfortable" rounded="lg">
            <template #prepend><v-icon>mdi-trending-up</v-icon></template>
            <strong>{{ data.summary.top_profit_location }}</strong> is the most profitable location
            with <strong>{{ fmtMoney(data.summary.top_profit_value) }}</strong> net profit.
          </v-alert>
        </v-col>
        <v-col cols="12" md="6">
          <v-alert variant="tonal" color="error" density="comfortable" rounded="lg">
            <template #prepend><v-icon>mdi-trending-down</v-icon></template>
            <strong>{{ data.summary.top_loss_location }}</strong> needs attention with
            <strong>{{ fmtMoney(data.summary.top_loss_value) }}</strong> net profit.
          </v-alert>
        </v-col>
      </v-row>

      <!-- ── Charts ── -->
      <v-row dense>
        <v-col cols="12" md="8">
          <v-card variant="outlined" rounded="lg" class="pa-4">
            <p class="text-subtitle-2 font-weight-bold mb-3 section-heading">
              Revenue vs Costs by Location
            </p>
            <DashboardChart :option="locationChartOption" height="400px" />
          </v-card>
        </v-col>
        <v-col cols="12" md="4">
          <v-card variant="outlined" rounded="lg" class="pa-4">
            <p class="text-subtitle-2 font-weight-bold mb-3 section-heading">
              Cost Distribution
            </p>
            <DashboardChart :option="costPieOption" height="400px" />
          </v-card>
        </v-col>
      </v-row>

      <!-- ── Locations Table ── -->
      <v-card variant="outlined" rounded="lg" class="overflow-hidden">
        <v-data-table
          :headers="tableHeaders"
          :items="data.locations"
          :items-per-page="10"
          density="comfortable"
          class="locations-table"
        >
          <!-- Location name -->
          <template #item.name="{ item }">
            <div class="d-flex align-center ga-2">
              <div
                class="location-dot"
                :style="{ background: item.color || '#6366f1' }"
              />
              <div>
                <p class="font-weight-medium" style="color: #1e293b">{{ item.name }}</p>
                <p class="text-caption text-medium-emphasis">{{ item.address || 'No address' }}</p>
              </div>
            </div>
          </template>

          <!-- Vehicle count -->
          <template #item.vehicles="{ item }">
            <v-chip size="small" variant="tonal" color="primary">
              {{ item.vehicle_count }} total
            </v-chip>
            <div class="text-caption text-medium-emphasis mt-1">
              {{ item.leased_vehicles }} leased · {{ item.owned_vehicles }} owned
            </div>
          </template>

          <!-- Revenue -->
          <template #item.total_revenue="{ item }">
            <span class="font-weight-medium" style="color: #16a34a">{{ fmtMoney(item.total_revenue) }}</span>
            <div class="text-caption text-medium-emphasis">
              Cash: {{ fmtMoney(item.cash_collected) }}
            </div>
          </template>

          <!-- Total costs -->
          <template #item.total_costs="{ item }">
            <span class="font-weight-medium" style="color: #dc2626">{{ fmtMoney(item.total_costs) }}</span>
            <div class="text-caption text-medium-emphasis">
              Fixed: {{ fmtMoney(item.fixed_costs) }}
            </div>
          </template>

          <!-- Net profit -->
          <template #item.net_profit="{ item }">
            <div :class="netProfitClass(item.net_profit)" class="font-weight-bold">
              <v-icon
                size="16"
                :color="isPositive(item.net_profit) ? 'success' : 'error'"
                class="mr-1"
              >
                {{ isPositive(item.net_profit) ? 'mdi-trending-up' : 'mdi-trending-down' }}
              </v-icon>
              {{ fmtMoney(item.net_profit) }}
            </div>
            <div class="text-caption text-medium-emphasis mt-1">
              Margin: {{ item.net_margin }}%
            </div>
          </template>

          <!-- Expandable detail -->
          <template #expanded-row="{ item }">
            <td colspan="6" class="pa-4" style="background: #f8fafc">
              <v-row dense>
                <v-col cols="6" sm="3">
                  <p class="text-caption text-medium-emphasis">Revenue</p>
                  <p class="text-body-2 font-weight-medium" style="color: #16a34a">{{ fmtMoney(item.total_revenue) }}</p>
                </v-col>
                <v-col cols="6" sm="3">
                  <p class="text-caption text-medium-emphasis">Rental Charges</p>
                  <p class="text-body-2">{{ fmtMoney(item.rental_charges) }}</p>
                </v-col>
                <v-col cols="6" sm="3">
                  <p class="text-caption text-medium-emphasis">Cash Collected</p>
                  <p class="text-body-2">{{ fmtMoney(item.cash_collected) }}</p>
                </v-col>
                <v-col cols="6" sm="3">
                  <p class="text-caption text-medium-emphasis">Monthly Lease</p>
                  <p class="text-body-2">{{ fmtMoney(item.monthly_lease) }}</p>
                </v-col>
                <v-col cols="6" sm="3">
                  <p class="text-caption text-medium-emphasis">Fuel</p>
                  <p class="text-body-2">{{ fmtMoney(item.fuel_cost) }}</p>
                </v-col>
                <v-col cols="6" sm="3">
                  <p class="text-caption text-medium-emphasis">Charging</p>
                  <p class="text-body-2">{{ fmtMoney(item.charging_cost) }}</p>
                </v-col>
                <v-col cols="6" sm="3">
                  <p class="text-caption text-medium-emphasis">Service</p>
                  <p class="text-body-2">{{ fmtMoney(item.service_cost) }}</p>
                </v-col>
                <v-col cols="6" sm="3">
                  <p class="text-caption text-medium-emphasis">Idling</p>
                  <p class="text-body-2">{{ fmtMoney(item.idling_cost) }}</p>
                </v-col>
                <v-col cols="6" sm="3">
                  <p class="text-caption text-medium-emphasis">Accidents</p>
                  <p class="text-body-2">{{ fmtMoney(item.accident_cost) }}</p>
                </v-col>
                <v-col cols="6" sm="3">
                  <p class="text-caption text-medium-emphasis">Damage</p>
                  <p class="text-body-2">{{ fmtMoney(item.damage_cost) }}</p>
                </v-col>
                <v-col cols="6" sm="3">
                  <p class="text-caption text-medium-emphasis">COGS</p>
                  <p class="text-body-2">{{ fmtMoney(item.cogs) }}</p>
                </v-col>
                <v-col cols="6" sm="3">
                  <p class="text-caption text-medium-emphasis">OpEx</p>
                  <p class="text-body-2">{{ fmtMoney(item.opex) }}</p>
                </v-col>
                <v-col cols="6" sm="3">
                  <p class="text-caption text-medium-emphasis">Lease Cost</p>
                  <p class="text-body-2">{{ fmtMoney(item.lease_cost) }}</p>
                </v-col>
                <v-col cols="6" sm="3">
                  <p class="text-caption text-medium-emphasis">Insurance</p>
                  <p class="text-body-2">{{ fmtMoney(item.insurance_cost) }}</p>
                </v-col>
                <v-col cols="6" sm="3">
                  <p class="text-caption text-medium-emphasis">Financing</p>
                  <p class="text-body-2">{{ fmtMoney(item.financing_cost) }}</p>
                </v-col>
                <v-col cols="6" sm="3">
                  <p class="text-caption text-medium-emphasis">Depreciation</p>
                  <p class="text-body-2">{{ fmtMoney(item.depreciation_cost) }}</p>
                </v-col>
                <v-col cols="6" sm="3">
                  <p class="text-caption text-medium-emphasis">Gross Profit</p>
                  <p class="text-body-2" :class="netProfitClass(item.gross_profit)">
                    {{ fmtMoney(item.gross_profit) }}
                  </p>
                </v-col>
                <v-col cols="6" sm="3">
                  <p class="text-caption text-medium-emphasis">Variable Costs</p>
                  <p class="text-body-2">{{ fmtMoney(item.variable_costs) }}</p>
                </v-col>
              </v-row>
            </td>
          </template>
        </v-data-table>
      </v-card>
    </template>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  data: any
  loading: boolean
}>()

const { fmtMoney } = useCurrency()

const tableHeaders = [
  { title: 'Location', key: 'name', sortable: true },
  { title: 'Vehicles', key: 'vehicles', sortable: false, align: 'center' },
  { title: 'Revenue', key: 'total_revenue', sortable: true, align: 'end' },
  { title: 'Total Costs', key: 'total_costs', sortable: true, align: 'end' },
  { title: 'Net Profit', key: 'net_profit', sortable: true, align: 'end' },
]

// Computed to avoid Vue SFC template >= quirk
const isPositive = computed(() => (val: number) => val >= 0)

const netProfitClass = computed(() => (val: number) => ({
  'text-success': val >= 0,
  'text-error': val < 0,
}))

const locationChartOption = computed(() => {
  const locs = props.data?.locations || []
  const names = locs.map((l: any) => l.name)
  return {
    tooltip: {
      trigger: 'axis',
      axisPointer: { type: 'shadow' },
      formatter: (params: any) => {
        const idx = params[0]?.dataIndex ?? 0
        const loc = locs[idx]
        if (!loc) return ''
        return `<strong>${loc.name}</strong><br/>` +
          `Revenue: ${fmtMoney(loc.total_revenue)}<br/>` +
          `Costs: ${fmtMoney(loc.total_costs)}<br/>` +
          `Profit: ${fmtMoney(loc.net_profit)}`
      },
    },
    legend: { data: ['Revenue', 'Costs', 'Net Profit'], bottom: 0 },
    grid: { left: 80, right: 20, top: 30, bottom: 50 },
    xAxis: {
      type: 'category',
      data: names,
      axisLabel: { rotate: names.length > 4 ? 30 : 0, interval: 0 },
    },
    yAxis: { type: 'value' },
    series: [
      {
        name: 'Revenue',
        type: 'bar',
        data: locs.map((l: any) => l.total_revenue),
        itemStyle: { color: '#3b82f6', borderRadius: [6, 6, 0, 0] },
      },
      {
        name: 'Costs',
        type: 'bar',
        data: locs.map((l: any) => l.total_costs),
        itemStyle: { color: '#ef4444', borderRadius: [6, 6, 0, 0] },
      },
      {
        name: 'Net Profit',
        type: 'bar',
        data: locs.map((l: any) => l.net_profit),
        itemStyle: {
          color: (p: any) => p.value >= 0 ? '#22c55e' : '#dc2626',
          borderRadius: [6, 6, 0, 0],
        },
      },
    ],
  }
})

const costPieOption = computed(() => {
  const locs = props.data?.locations || []
  const fuel = locs.reduce((s: number, l: any) => s + l.fuel_cost, 0)
  const charging = locs.reduce((s: number, l: any) => s + l.charging_cost, 0)
  const service = locs.reduce((s: number, l: any) => s + l.service_cost, 0)
  const idling = locs.reduce((s: number, l: any) => s + l.idling_cost, 0)
  const accident = locs.reduce((s: number, l: any) => s + l.accident_cost, 0)
  const damage = locs.reduce((s: number, l: any) => s + l.damage_cost, 0)
  const lease = locs.reduce((s: number, l: any) => s + l.lease_cost, 0)
  const insurance = locs.reduce((s: number, l: any) => s + l.insurance_cost, 0)
  const financing = locs.reduce((s: number, l: any) => s + l.financing_cost, 0)
  const depreciation = locs.reduce((s: number, l: any) => s + l.depreciation_cost, 0)
  const data = [
    { name: 'Fuel', value: round(fuel) },
    { name: 'Charging', value: round(charging) },
    { name: 'Service', value: round(service) },
    { name: 'Idling', value: round(idling) },
    { name: 'Accidents', value: round(accident) },
    { name: 'Damage', value: round(damage) },
    { name: 'Lease', value: round(lease) },
    { name: 'Insurance', value: round(insurance) },
    { name: 'Financing', value: round(financing) },
    { name: 'Depreciation', value: round(depreciation) },
  ].filter((d) => d.value > 0)
  return {
    tooltip: {
      trigger: 'item',
      formatter: (p: any) => `${p.name}: ${fmtMoney(p.value)} (${p.percent}%)`,
    },
    legend: { bottom: 0, type: 'scroll' },
    series: [{
      type: 'pie',
      radius: ['35%', '70%'],
      center: ['50%', '45%'],
      data,
      itemStyle: { borderRadius: 6, borderColor: '#fff', borderWidth: 2 },
      label: { show: false },
    }],
    color: ['#3b82f6', '#8b5cf6', '#f59e0b', '#ef4444', '#dc2626',
            '#f97316', '#6366f1', '#14b8a6', '#64748b', '#78716c'],
  }
})

function round(v: number): number {
  return Math.round(v * 100) / 100
}
</script>

<style scoped>
.location-dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  flex-shrink: 0;
}
.section-heading { color: #1e293b; }
.v-theme--dark .section-heading { color: #e2e8f0; }
</style>
