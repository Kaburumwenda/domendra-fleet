<template>
  <div class="d-flex flex-column ga-4">
    <div class="d-flex align-center ga-3 flex-wrap">
      <div class="d-flex align-center justify-center rounded-xl" style="width: 48px; height: 48px; background: linear-gradient(135deg, #0ea5e9, #0284c7)">
        <v-icon color="white">mdi-chart-areaspline</v-icon>
      </div>
      <div>
        <h1 class="text-h5 font-weight-bold">Usage &amp; Revenue Analytics</h1>
        <p class="text-body-2 text-medium-emphasis mb-0">Cross-tenant API usage, revenue trends and per-tenant breakdowns</p>
      </div>
      <v-spacer />
      <v-select v-model="months" :items="monthOpts" density="compact" variant="outlined" hide-details style="width: 140px" />
      <v-btn icon="mdi-refresh" variant="tonal" :loading="pending" @click="refresh()" />
    </div>

    <v-row dense>
      <v-col cols="12" sm="6" md="3"><StatCard label="MRR (projected)" :value="fmtUsd(rev?.mrr)" icon="mdi-chart-line-variant" icon-bg="#dcfce7" icon-color="success" /></v-col>
      <v-col cols="12" sm="6" md="3"><StatCard label="ARPU" :value="fmtUsd(rev?.arpu)" icon="mdi-account-cash" icon-bg="#eef2ff" icon-color="primary" /></v-col>
      <v-col cols="12" sm="6" md="3"><StatCard label="Months analyzed" :value="String(months)" icon="mdi-calendar-range" icon-bg="#fef3c7" icon-color="warning" /></v-col>
      <v-col cols="12" sm="6" md="3"><StatCard label="Bills in period" :value="fmtNum(totalBills)" icon="mdi-file-document-multiple" icon-bg="#eff6ff" icon-color="info" /></v-col>
    </v-row>

    <v-card elevation="0" border rounded="lg" class="pa-5">
      <div class="d-flex align-center ga-2 mb-3">
        <v-icon color="primary" size="small">mdi-chart-bar</v-icon>
        <h3 class="text-subtitle-1 font-weight-bold">Monthly Revenue &amp; Requests</h3>
      </div>
      <DashboardChart :option="monthlyOption" height="300px" />
    </v-card>

    <v-card elevation="0" border rounded="lg" class="pa-5">
      <div class="d-flex align-center ga-2 mb-3">
        <v-icon color="warning" size="small">mdi-format-list-group</v-icon>
        <h3 class="text-subtitle-1 font-weight-bold">Monthly Breakdown</h3>
      </div>
      <v-table density="comfortable">
        <thead>
          <tr><th>Month</th><th class="text-end">Bills</th><th class="text-end">Requests</th><th class="text-end">Revenue</th></tr>
        </thead>
        <tbody>
          <tr v-for="m in rev?.monthly_series || []" :key="m.month">
            <td class="font-weight-medium">{{ m.month }}</td>
            <td class="text-right">{{ fmtNum(m.bills) }}</td>
            <td class="text-right">{{ fmtNum(m.requests) }}</td>
            <td class="text-right font-weight-bold">{{ fmtUsd(m.revenue) }}</td>
          </tr>
          <tr v-if="!rev?.monthly_series?.length"><td colspan="4" class="text-center text-medium-emphasis py-4">No data</td></tr>
        </tbody>
      </v-table>
    </v-card>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'superadmin' })
const sa = useSuperAdmin()
const months = ref(6)
const { data: rev, pending, refresh } = await useAsyncData('sa-revenue', () => sa.revenue(months.value))

watch(months, () => refresh())

const monthOpts = [3, 6, 9, 12].map((n) => ({ title: `Last ${n} months`, value: n }))
const totalBills = computed(() => (rev.value?.monthly_series || []).reduce((s: number, m: any) => s + (m.bills || 0), 0))

const monthlyOption = computed(() => {
  const series = rev.value?.monthly_series || []
  return {
    tooltip: { trigger: 'axis' },
    legend: { top: 0, data: ['Revenue', 'Requests'] },
    grid: { left: 50, right: 50, top: 40, bottom: 30 },
    xAxis: { type: 'category', data: series.map((s: any) => s.month) },
    yAxis: [
      { type: 'value', name: 'Revenue', axisLabel: { formatter: '${value}' } },
      { type: 'value', name: 'Requests', position: 'right' },
    ],
    series: [
      { name: 'Revenue', type: 'bar', data: series.map((s: any) => s.revenue), itemStyle: { color: '#22c55e' } },
      { name: 'Requests', type: 'line', yAxisIndex: 1, data: series.map((s: any) => s.requests), itemStyle: { color: '#6366f1' } },
    ],
  }
})
</script>
