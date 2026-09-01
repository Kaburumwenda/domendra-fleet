<template>
  <div class="d-flex flex-column ga-4">
    <!-- ABC Summary Cards -->
    <v-row dense>
      <v-col cols="12" md="4">
        <v-card elevation="0" border class="pa-5 abc-card abc-a h-100">
          <div class="d-flex align-center justify-space-between mb-2">
            <div>
              <p class="text-h4 font-weight-bold text-white">A</p>
              <p class="text-caption text-white" style="opacity: 0.9">High-value (top 80%)</p>
            </div>
            <v-icon size="36" color="white">mdi-trophy</v-icon>
          </div>
          <div class="d-flex align-center justify-space-between">
            <div>
              <p class="text-h5 font-weight-bold text-white">{{ abcA.count }}</p>
              <p class="text-caption text-white" style="opacity: 0.9">vehicles</p>
            </div>
            <div class="text-right">
              <p class="text-subtitle-1 font-weight-bold text-white">{{ currencySymbol }}{{ abcARevenueFmt }}</p>
              <p class="text-caption text-white" style="opacity: 0.9">{{ abcA.pct }}% of fleet</p>
            </div>
          </div>
        </v-card>
      </v-col>
      <v-col cols="12" md="4">
        <v-card elevation="0" border class="pa-5 abc-card abc-b h-100">
          <div class="d-flex align-center justify-space-between mb-2">
            <div>
              <p class="text-h4 font-weight-bold text-white">B</p>
              <p class="text-caption text-white" style="opacity: 0.9">Medium (next 15%)</p>
            </div>
            <v-icon size="36" color="white">mdi-medal</v-icon>
          </div>
          <div class="d-flex align-center justify-space-between">
            <div>
              <p class="text-h5 font-weight-bold text-white">{{ abcB.count }}</p>
              <p class="text-caption text-white" style="opacity: 0.9">vehicles</p>
            </div>
            <div class="text-right">
              <p class="text-subtitle-1 font-weight-bold text-white">{{ currencySymbol }}{{ abcBRevenueFmt }}</p>
              <p class="text-caption text-white" style="opacity: 0.9">{{ abcB.pct }}% of fleet</p>
            </div>
          </div>
        </v-card>
      </v-col>
      <v-col cols="12" md="4">
        <v-card elevation="0" border class="pa-5 abc-card abc-c h-100">
          <div class="d-flex align-center justify-space-between mb-2">
            <div>
              <p class="text-h4 font-weight-bold text-white">C</p>
              <p class="text-caption text-white" style="opacity: 0.9">Low (bottom 5%)</p>
            </div>
            <v-icon size="36" color="white">mdi-trophy-award</v-icon>
          </div>
          <div class="d-flex align-center justify-space-between">
            <div>
              <p class="text-h5 font-weight-bold text-white">{{ abcC.count }}</p>
              <p class="text-caption text-white" style="opacity: 0.9">vehicles</p>
            </div>
            <div class="text-right">
              <p class="text-subtitle-1 font-weight-bold text-white">{{ currencySymbol }}{{ abcCRevenueFmt }}</p>
              <p class="text-caption text-white" style="opacity: 0.9">{{ abcC.pct }}% of fleet</p>
            </div>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <!-- Chart -->
    <v-row dense>
      <v-col cols="12" md="7">
        <DashboardChart :option="paretoOption" title="ABC Pareto Analysis" icon="mdi-chart-bar" height="320px" />
      </v-col>
      <v-col cols="12" md="5">
        <v-card elevation="0" border class="pa-5 h-100">
          <div class="d-flex align-center justify-space-between mb-3">
            <h3 class="text-subtitle-2 font-weight-medium d-flex align-center ga-2 section-heading">
              <v-icon size="small" color="primary">mdi-chart-pie</v-icon> Summary
            </h3>
          </div>
          <div class="d-flex flex-column ga-3">
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis">Total Revenue</span>
              <span class="text-body-1 font-weight-bold" style="color: #059669">{{ currencySymbol }}{{ totalRevFmt }}</span>
            </div>
            <v-divider />
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis">Classified Vehicles</span>
              <span class="text-body-1 font-weight-bold">{{ abcSummary.total_vehicles }}</span>
            </div>
            <v-divider />
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis d-flex align-center ga-1">
                <v-icon size="16" color="grey">mdi-car-multiple</v-icon>No Revenue (Excluded)
              </span>
              <span class="text-body-1 font-weight-bold">{{ data?.abc_analysis?.no_revenue_count ?? 0 }}</span>
            </div>
            <v-divider />
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis d-flex align-center ga-1">
                <v-icon size="16" color="#059669">mdi-trophy</v-icon>Class A Revenue
              </span>
              <span class="text-body-1 font-weight-bold">{{ currencySymbol }}{{ abcARevenueFmt }}</span>
            </div>
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis d-flex align-center ga-1">
                <v-icon size="16" color="#0ea5e9">mdi-medal</v-icon>Class B Revenue
              </span>
              <span class="text-body-1 font-weight-bold">{{ currencySymbol }}{{ abcBRevenueFmt }}</span>
            </div>
            <div class="d-flex align-center justify-space-between">
              <span class="text-body-2 text-medium-emphasis d-flex align-center ga-1">
                <v-icon size="16" color="#94a3b8">mdi-trophy-award</v-icon>Class C Revenue
              </span>
              <span class="text-body-1 font-weight-bold">{{ currencySymbol }}{{ abcCRevenueFmt }}</span>
            </div>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <!-- ABC Vehicles Table -->
    <v-card elevation="0" border class="pa-5">
      <div class="d-flex align-center justify-space-between mb-3">
        <h3 class="text-subtitle-2 font-weight-medium d-flex align-center ga-2 section-heading">
          <v-icon size="small" color="primary">mdi-format-list-bulleted</v-icon> Vehicle Classification
        </h3>
        <v-chip size="small" variant="tonal" color="primary">{{ abcVehicles.length }} vehicles</v-chip>
      </div>
      <v-data-table
        :items="abcVehicles"
        :headers="abcHeaders"
        density="compact"
        :items-per-page="15"
      >
        <template #item.display_name="{ item }">
          <span class="font-weight-medium">{{ (item as any).make }} {{ (item as any).model }}</span>
          <span class="text-caption text-medium-emphasis ml-1">{{ (item as any).license_plate || (item as any).vin }}</span>
        </template>
        <template #item.abc_class="{ item }">
          <v-chip size="x-small" :color="abcClassColor((item as any).abc_class)" variant="flat" class="font-weight-bold">{{ (item as any).abc_class }}</v-chip>
        </template>
        <template #item.total_rev="{ item }">
          <span class="font-weight-bold" style="color: #059669">{{ currencySymbol }}{{ Number((item as any).total_rev || 0).toLocaleString() }}</span>
        </template>
        <template #item.revenue_pct="{ item }">
          {{ (item as any).revenue_pct }}%
        </template>
        <template #item.cumulative_pct="{ item }">
          <div class="d-flex align-center ga-2">
            <v-progress-linear :model-value="(item as any).cumulative_pct" color="primary" height="5" rounded style="max-width: 60px" />
            <span class="text-body-2 font-weight-medium">{{ (item as any).cumulative_pct }}%</span>
          </div>
        </template>
        <template #item.rental_count="{ item }">
          <v-chip size="x-small" variant="tonal" color="primary">{{ (item as any).rental_count }}</v-chip>
        </template>
      </v-data-table>
    </v-card>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ data: any }>()
const { currencySymbol } = useCurrency()

const data = computed(() => props.data)

const abcSummary = computed(() => data.value?.abc_analysis?.summary || {})
const abcA = computed(() => abcSummary.value?.A || { count: 0, revenue: 0, pct: 0 })
const abcB = computed(() => abcSummary.value?.B || { count: 0, revenue: 0, pct: 0 })
const abcC = computed(() => abcSummary.value?.C || { count: 0, revenue: 0, pct: 0 })

const abcARevenueFmt = computed(() => fmt(abcA.value.revenue))
const abcBRevenueFmt = computed(() => fmt(abcB.value.revenue))
const abcCRevenueFmt = computed(() => fmt(abcC.value.revenue))
const totalRevFmt = computed(() => fmt(abcSummary.value.total_revenue))

function fmt(v: any) {
  return Number(v ?? 0).toLocaleString(undefined, { maximumFractionDigits: 0 })
}

function abcClassColor(c: string) {
  return { A: 'success', B: 'info', C: 'grey' }[c] || 'grey'
}

const abcVehicles = computed(() => data.value?.abc_analysis?.vehicles || [])

const abcHeaders = [
  { title: 'Vehicle', key: 'display_name' },
  { title: 'Class', key: 'abc_class', width: '70px' },
  { title: 'Revenue', key: 'total_rev' },
  { title: 'Revenue %', key: 'revenue_pct' },
  { title: 'Cumulative %', key: 'cumulative_pct', width: '140px' },
  { title: 'Rentals', key: 'rental_count' },
]

const paretoOption = computed(() => {
  const vehicles = abcVehicles.value.slice(0, 50)
  return {
    tooltip: { trigger: 'axis', backgroundColor: '#1e293b', borderColor: '#334155', textStyle: { color: '#f1f5f9' },
      formatter: (params: any) => {
        const items = Array.isArray(params) ? params : [params]
        let html = items[0].name
        for (const p of items) {
          if (p.seriesName === 'Revenue') {
            html += `<br/>${p.marker} Revenue: ${currencySymbol.value}${Number(p.value).toLocaleString()}`
          } else {
            html += `<br/>${p.marker} Cumulative: ${p.value}%`
          }
        }
        return html
      }
    },
    legend: { bottom: 0, textStyle: { fontSize: 11 }, icon: 'circle' },
    grid: { left: '3%', right: '6%', bottom: '14%', containLabel: true },
    xAxis: { type: 'category', data: vehicles.map((v: any, i: number) => `#${i + 1}`), axisLabel: { fontSize: 9, interval: Math.floor(vehicles.length / 12) } },
    yAxis: [
      { type: 'value', name: 'Revenue', axisLabel: { formatter: (v: number) => currencySymbol.value + (v >= 1000 ? (v / 1000).toFixed(0) + 'k' : v) } },
      { type: 'value', name: 'Cumulative %', max: 100, axisLabel: { formatter: (v: number) => v + '%' } },
    ],
    series: [
      {
        name: 'Revenue',
        type: 'bar',
        data: vehicles.map((v: any) => ({
          value: v.total_rev,
          itemStyle: { color: abcClassColor(v.abc_class) === 'success' ? '#10b981' : abcClassColor(v.abc_class) === 'info' ? '#0ea5e9' : '#94a3b8' }
        })),
        barWidth: '60%',
      },
      {
        name: 'Cumulative %',
        type: 'line',
        yAxisIndex: 1,
        smooth: true,
        data: vehicles.map((v: any) => v.cumulative_pct),
        lineStyle: { width: 2, color: '#f59e0b' },
        itemStyle: { color: '#f59e0b' },
        symbolSize: 4,
      },
    ],
  }
})
</script>

<style scoped>
.section-heading { color: #475569; }
.v-theme--dark .section-heading { color: #94a3b8; }
.abc-card {
  border: none;
  color: white;
}
.abc-a { background: linear-gradient(135deg, #10b981, #059669); }
.abc-b { background: linear-gradient(135deg, #0ea5e9, #2563eb); }
.abc-c { background: linear-gradient(135deg, #94a3b8, #64748b); }
</style>
