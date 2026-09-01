<template>
  <div class="d-flex flex-column ga-4">
    <!-- ── Date Filter Bar ── -->
    <v-card variant="outlined" rounded="lg" class="pa-3">
      <div class="d-flex align-center ga-4 flex-wrap">
        <div class="d-flex align-center ga-2">
          <v-icon icon="mdi-filter-calendar" color="primary" />
          <span class="text-body-2 font-weight-bold text-medium-emphasis">Date Range</span>
        </div>
        <div class="d-flex align-center ga-2 flex-wrap">
          <div class="d-flex flex-column">
            <span class="text-caption text-medium-emphasis mb-1">From</span>
            <v-text-field
              :model-value="startDate"
              type="date"
              density="compact"
              variant="outlined"
              hide-details
              style="max-width: 170px"
              @update:model-value="$emit('update:start-date', $event)"
            />
          </div>
          <v-icon icon="mdi-arrow-right" class="mt-4" color="medium-emphasis" />
          <div class="d-flex flex-column">
            <span class="text-caption text-medium-emphasis mb-1">To</span>
            <v-text-field
              :model-value="endDate"
              type="date"
              density="compact"
              variant="outlined"
              hide-details
              style="max-width: 170px"
              @update:model-value="$emit('update:end-date', $event)"
            />
          </div>
        </div>
        <v-btn variant="text" prepend-icon="mdi-refresh" size="small" color="primary" class="mt-4" @click="$emit('reset')">
          Reset
        </v-btn>
        <v-spacer />
        <v-chip v-if="data" size="small" variant="tonal" color="primary">
          {{ data.period.start }} — {{ data.period.end }}
        </v-chip>
      </div>
    </v-card>

    <!-- ── Loading ── -->
    <div v-if="loading" class="d-flex justify-center align-center py-12">
      <v-progress-circular indeterminate size="48" color="primary" />
    </div>

    <!-- ── Empty ── -->
    <div v-else-if="!data || !data.locations?.length" class="text-center text-medium-emphasis py-12">
      <v-icon size="48" class="mb-2">mdi-map-marker-off-outline</v-icon>
      <p>No leased vehicles with location data found.</p>
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
            :subtitle="`${data.summary.total_leased_vehicles} leased vehicles`"
          />
        </v-col>
        <v-col cols="6" md="3">
          <StatCard
            label="Monthly Lease Cost"
            :value="fmtMoney(data.summary.total_monthly_lease)"
            icon="mdi-cash-multiple"
            icon-bg="#ecfdf5"
            icon-color="success"
            :subtitle="`${data.summary.active_vehicles} active`"
          />
        </v-col>
        <v-col cols="6" md="3">
          <StatCard
            label="Total Net Profit"
            :value="fmtMoney(data.summary.total_net_profit)"
            icon="mdi-chart-line-variant"
            icon-bg="#fff7ed"
            icon-color="warning"
            :subtitle="`${data.summary.expiring_30d} leases expiring 30d`"
          />
        </v-col>
        <v-col cols="6" md="3">
          <StatCard
            label="Deposit Held"
            :value="fmtMoney(data.summary.total_deposit_held)"
            icon="mdi-shield-account-outline"
            icon-bg="#fef2f2"
            icon-color="error"
            :subtitle="fmtMoney(data.summary.total_revenue) + ' revenue'"
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

      <!-- ── Profit by Location Chart ── -->
      <v-row dense>
        <v-col cols="12" md="8">
          <v-card variant="outlined" rounded="lg" class="pa-4">
            <p class="text-subtitle-2 font-weight-bold mb-3" style="color: #1e293b">
              Revenue vs Costs by Location
            </p>
            <DashboardChart :option="locationChartOption" height="400px" />
          </v-card>
        </v-col>
        <v-col cols="12" md="4">
          <v-card variant="outlined" rounded="lg" class="pa-4">
            <p class="text-subtitle-2 font-weight-bold mb-3" style="color: #1e293b">
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
          <!-- Location name with type badge -->
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

          <!-- Vehicle count chip -->
          <template #item.vehicle_count="{ item }">
            <v-chip size="small" variant="tonal" color="primary">
              {{ item.vehicle_count }} total
            </v-chip>
            <div class="text-caption text-medium-emphasis mt-1">
              {{ item.active_vehicles }} active
            </div>
          </template>

          <!-- Status breakdown -->
          <template #item.status_breakdown="{ item }">
            <div class="d-flex flex-wrap ga-1">
              <v-chip
                v-for="(count, status) in item.status_breakdown"
                :key="status"
                x-small
                size="x-small"
                :color="statusColor(status)"
                variant="tonal"
              >
                {{ statusTitle(status) }}: {{ count }}
              </v-chip>
            </div>
          </template>

          <!-- Monthly lease -->
          <template #item.monthly_lease="{ item }">
            <span class="font-weight-medium">{{ fmtMoney(item.monthly_lease) }}</span>
            <div v-if="item.total_deposit" class="text-caption text-medium-emphasis">
              Deposit: {{ fmtMoney(item.total_deposit) }}
            </div>
          </template>

          <!-- Revenue -->
          <template #item.revenue="{ item }">
            <span class="font-weight-medium" style="color: #16a34a">{{ fmtMoney(item.revenue) }}</span>
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

          <!-- Net profit with color -->
          <template #item.net_profit="{ item }">
            <div :class="netProfitClass(item.net_profit)" class="font-weight-bold">
              <v-icon
                size="16"
                :color="item.net_profit >= 0 ? 'success' : 'error'"
                class="mr-1"
              >
                {{ item.net_profit >= 0 ? 'mdi-trending-up' : 'mdi-trending-down' }}
              </v-icon>
              {{ fmtMoney(item.net_profit) }}
            </div>
            <div v-if="item.expiring_30d" class="text-caption text-warning mt-1">
              {{ item.expiring_30d }} lease(s) expiring 30d
            </div>
          </template>

          <!-- Expandable detail -->
          <template #expanded-row="{ item }">
            <td colspan="7" class="pa-4" style="background: #f8fafc">
              <v-row dense>
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
                  <p class="text-caption text-medium-emphasis">COGS</p>
                  <p class="text-body-2">{{ fmtMoney(item.cogs) }}</p>
                </v-col>
                <v-col cols="6" sm="3">
                  <p class="text-caption text-medium-emphasis">Fixed Costs</p>
                  <p class="text-body-2">{{ fmtMoney(item.fixed_costs) }}</p>
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
  startDate: string
  endDate: string
}>()

defineEmits<{
  'update:start-date': [string]
  'update:end-date': [string]
  'reset': []
}>()

const { fmtMoney } = useCurrency()

const tableHeaders = [
  { title: 'Location', key: 'name', sortable: true },
  { title: 'Vehicles', key: 'vehicle_count', sortable: true, align: 'center' },
  { title: 'Status', key: 'status_breakdown', sortable: false },
  { title: 'Monthly Lease', key: 'monthly_lease', sortable: true, align: 'end' },
  { title: 'Revenue', key: 'revenue', sortable: true, align: 'end' },
  { title: 'Total Costs', key: 'total_costs', sortable: true, align: 'end' },
  { title: 'Net Profit', key: 'net_profit', sortable: true, align: 'end' },
]

function statusColor(s: string): string {
  const map: Record<string, string> = {
    active: 'success',
    in_maintenance: 'warning',
    out_of_service: 'error',
    retired: 'grey',
  }
  return map[s] || 'grey'
}

function statusTitle(s: string): string {
  return (s || '').replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())
}

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
          `Revenue: ${fmtMoney(loc.revenue)}<br/>` +
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
        data: locs.map((l: any) => l.revenue),
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
  const fixed = locs.reduce((s: number, l: any) => s + l.fixed_costs, 0)
  const data = [
    { name: 'Fuel', value: round(fuel) },
    { name: 'Charging', value: round(charging) },
    { name: 'Service', value: round(service) },
    { name: 'Idling', value: round(idling) },
    { name: 'Fixed Costs', value: round(fixed) },
  ].filter((d) => d.value > 0)
  return {
    tooltip: {
      trigger: 'item',
      formatter: (p: any) => `${p.name}: ${fmtMoney(p.value)} (${p.percent}%)`,
    },
    legend: { bottom: 0, type: 'scroll' },
    series: [{
      type: 'pie',
      radius: ['40%', '70%'],
      center: ['50%', '45%'],
      data,
      itemStyle: { borderRadius: 6, borderColor: '#fff', borderWidth: 2 },
      label: { show: false },
    }],
    color: ['#3b82f6', '#8b5cf6', '#f59e0b', '#ef4444', '#6366f1'],
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
</style>
