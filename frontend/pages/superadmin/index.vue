<template>
  <div class="d-flex flex-column ga-4">
    <div class="d-flex align-center justify-space-between flex-wrap ga-3">
      <div class="d-flex align-center ga-3">
        <div class="d-flex align-center justify-center rounded-xl" style="width: 48px; height: 48px; background: linear-gradient(135deg, #0f172a, #1e293b)">
          <v-icon color="white">mdi-shield-crown-outline</v-icon>
        </div>
        <div>
          <h1 class="text-h5 font-weight-bold" style="color: #1e293b">Control Plane Overview</h1>
          <p class="text-body-2 text-medium-emphasis">Platform-wide metrics across all tenants and accounts</p>
        </div>
      </div>
      <div class="d-flex align-center ga-2">
        <v-btn icon="mdi-refresh" variant="tonal" :loading="pending" @click="refresh()" />
      </div>
    </div>

    <template v-if="!pending && data">
      <!-- KPI Cards -->
      <v-row dense>
        <v-col cols="12" sm="6" md="3" v-for="kpi in kpis" :key="kpi.label">
          <StatCard :label="kpi.label" :value="kpi.value" :icon="kpi.icon" :icon-bg="kpi.iconBg" :icon-color="kpi.iconColor" :trend="kpi.trend" :subtitle="kpi.subtitle" />
        </v-col>
      </v-row>

      <!-- Revenue + Usage series -->
      <v-row dense>
        <v-col cols="12" md="8">
          <v-card elevation="0" border rounded="lg" class="pa-5 h-100">
            <div class="d-flex align-center justify-space-between mb-4">
              <div class="d-flex align-center ga-2">
                <v-icon color="primary" size="small">mdi-chart-areaspline</v-icon>
                <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">API Requests & Errors (30d)</h3>
              </div>
              <v-chip size="x-small" variant="tonal" color="success">{{ fmtNum(totalRequests30d) }} requests</v-chip>
            </div>
            <DashboardChart :option="requestsOption" height="280px" />
          </v-card>
        </v-col>
        <v-col cols="12" md="4">
          <v-card elevation="0" border rounded="lg" class="pa-5 h-100">
            <div class="d-flex align-center ga-2 mb-4">
              <v-icon color="info" size="small">mdi-tune-variant</v-icon>
              <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">Subscription Status</h3>
            </div>
            <DashboardChart :option="subsOption" height="220px" />
            <div class="d-flex flex-wrap ga-2 mt-2">
              <v-chip
                v-for="(c, s) in subChips"
                :key="s"
                size="small"
                variant="flat"
                :color="statusColor(s)"
              >{{ s }}: {{ c }}</v-chip>
            </div>
          </v-card>
        </v-col>
      </v-row>

      <!-- Billing + Top Tenants -->
      <v-row dense>
        <v-col cols="12" md="4">
          <v-card elevation="0" border rounded="lg" class="pa-5 h-100">
            <div class="d-flex align-center ga-2 mb-4">
              <v-icon color="success" size="small">mdi-cash-multiple</v-icon>
              <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">Billing Health</h3>
            </div>
            <div class="d-flex flex-column ga-2">
              <div v-for="item in billingItems" :key="item.label" class="d-flex align-center justify-space-between rounded-lg pa-3" :style="{ background: item.bg }">
                <div class="d-flex align-center ga-2">
                  <v-icon size="small" :color="item.color">{{ item.icon }}</v-icon>
                  <span class="text-body-2 text-medium-emphasis">{{ item.label }}</span>
                </div>
                <span class="text-subtitle-1 font-weight-bold" :style="{ color: item.valueColor }">{{ item.value }}</span>
              </div>
            </div>
          </v-card>
        </v-col>
        <v-col cols="12" md="8">
          <v-card elevation="0" border rounded="lg" class="pa-5 h-100">
            <div class="d-flex align-center justify-space-between mb-3">
              <div class="d-flex align-center ga-2">
                <v-icon color="primary" size="small">mdi-trophy-variant</v-icon>
                <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">Top Tenants by Requests</h3>
              </div>
              <v-btn size="small" variant="text" to="/superadmin/usage" append-icon="mdi-chevron-right">Usage</v-btn>
            </div>
            <v-table density="comfortable">
              <thead>
                <tr>
                  <th>Tenant</th>
                  <th class="text-right">Requests</th>
                  <th class="text-right">Cost</th>
                  <th class="text-right">%</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(t, i) in topTenants" :key="t.schema">
                  <td>
                    <div class="d-flex align-center ga-2">
                      <v-avatar size="24" rounded color="indigo-lighten-5"><span class="text-caption font-weight-bold text-indigo">{{ i + 1 }}</span></v-avatar>
                      <NuxtLink :to="tenantUrlPath(t.schema)" class="text-body-2 font-weight-medium text-decoration-none text-on-surface">{{ t.name }}</NuxtLink>
                    </div>
                  </td>
                  <td class="text-right text-body-2">{{ fmtNum(t.requests) }}</td>
                  <td class="text-right text-body-2">{{ fmtUsd(t.cost) }}</td>
                  <td class="text-right">
                    <v-progress-linear :model-value="percent(t.requests)" rounded color="primary" height="6" style="max-width: 120px; display: inline-block" />
                  </td>
                </tr>
                <tr v-if="!topTenants.length"><td colspan="4" class="text-center text-medium-emphasis py-4">No usage recorded yet</td></tr>
              </tbody>
            </v-table>
          </v-card>
        </v-col>
      </v-row>

      <!-- Top Endpoints -->
      <v-card elevation="0" border rounded="lg" class="pa-5">
        <div class="d-flex align-center ga-2 mb-3">
          <v-icon color="warning" size="small">mdi-ray-start-end</v-icon>
          <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">Top Endpoints (30d)</h3>
        </div>
        <v-chip
          v-for="ep in topEndpoints"
          :key="ep.endpoint + ep.method"
          size="small"
          variant="tonal"
          color="primary"
          class="ma-1"
        >
          <v-icon start size="x-small">{{ methodIcon(ep.method) }}</v-icon>
          {{ ep.endpoint }} · {{ fmtNum(ep.total) }}
        </v-chip>
        <div v-if="!topEndpoints.length" class="text-center text-medium-emphasis py-4">No endpoint data</div>
      </v-card>
    </template>

    <template v-else>
      <div class="d-flex justify-center py-12">
        <v-progress-circular indeterminate color="primary" size="40" />
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'superadmin' })
const sa = useSuperAdmin()
const { data, pending, refresh } = await useAsyncData('sa-dashboard', () => sa.dashboard())

const totalRequests30d = computed(() => data.value?.usage_30d?.total_requests || 0)
const topTenants = computed(() => data.value?.top_tenants || [])
const topEndpoints = computed<any[]>(() => data.value?.top_endpoints || [])
const subChips = computed(() => data.value?.subscriptions?.by_status || {})

const requestsOption = computed(() => {
  const series = data.value?.daily_series || []
  return {
    tooltip: { trigger: 'axis' },
    legend: { data: ['Requests', 'Errors'], top: 0 },
    grid: { left: 40, right: 20, top: 40, bottom: 30 },
    xAxis: { type: 'category', data: series.map((s: any) => s.date.slice(5)), axisLabel: { fontSize: 10 } },
    yAxis: [
      { type: 'value', name: 'Requests' },
      { type: 'value', name: 'Errors', position: 'right' },
    ],
    series: [
      { name: 'Requests', type: 'line', smooth: true, areaStyle: { opacity: 0.15 }, data: series.map((s: any) => s.requests), itemStyle: { color: '#6366f1' } },
      { name: 'Errors', type: 'line', yAxisIndex: 1, smooth: true, data: series.map((s: any) => s.errors), itemStyle: { color: '#ef4444' } },
    ],
  }
})

const subsOption = computed(() => {
  const byStatus = data.value?.subscriptions?.by_status || {}
  return {
    tooltip: { trigger: 'item' },
    legend: { bottom: 0, type: 'scroll' },
    series: [{
      type: 'pie',
      radius: ['40%', '70%'],
      center: ['50%', '45%'],
      label: { show: false },
      data: Object.entries(byStatus).map(([name, value]) => ({
        name, value: value as number,
        itemStyle: { color: pieColor(name) },
      })),
    }],
  }
})

function pieColor(s: string) {
  return { success: '#22c55e', warning: '#f59e0b', error: '#ef4444', info: '#3b82f6' }[statusColor(s)] || '#6366f1'
}

const maxReq = computed(() => Math.max(1, ...topTenants.value.map((t: any) => t.requests)))
function percent(v: number) { return Math.round((v / maxReq.value) * 100) }
function tenantUrlPath(schema: string) { return `/superadmin/tenants/${encodeURIComponent(schema)}` }

const kpis = computed(() => {
  const d = data.value || {}
  return [
    { label: 'Total Tenants', value: fmtNum(d.tenants?.total), icon: 'mdi-domain', iconBg: '#eef2ff', iconColor: 'primary', trend: d.tenants?.new_30d ? 8 : null, subtitle: `${d.tenants?.new_30d || 0} new in 30d` },
    { label: 'Active Tenants', value: fmtNum(d.tenants?.active), icon: 'mdi-check-decagram', iconBg: '#dcfce7', iconColor: 'success', subtitle: `${d.tenants?.suspended || 0} suspended` },
    { label: 'Projected MRR', value: fmtUsd(d.billing?.projected_revenue), icon: 'mdi-cash-multiple', iconBg: '#fef3c7', iconColor: 'warning', subtitle: 'usage-based' },
    { label: 'Outstanding', value: fmtUsd(d.billing?.outstanding_usd), icon: 'mdi-alert-circle-outline', iconBg: '#fee2e2', iconColor: 'error', subtitle: `${(d.billing?.unpaid_bills || 0) + (d.billing?.overdue_bills || 0)} unpaid bills` },
  ]
})

const billingItems = computed(() => {
  const b = data.value?.billing || {}
  return [
    { label: 'Unpaid Bills', value: fmtNum(b.unpaid_bills), icon: 'mdi-file-clock', color: 'warning', bg: '#fffbeb', valueColor: '#92400e' },
    { label: 'Overdue Bills', value: fmtNum(b.overdue_bills), icon: 'mdi-alert', color: 'error', bg: '#fef2f2', valueColor: '#991b1b' },
    { label: 'Paid Bills', value: fmtNum(b.paid_bills), icon: 'mdi-check-circle', color: 'success', bg: '#f0fdf4', valueColor: '#166534' },
    { label: 'Total Requests', value: fmtNum(b.total_requests), icon: 'mdi-api', color: 'info', bg: '#eff6ff', valueColor: '#1e40af' },
    { label: 'Error Rate', value: (data.value?.usage_30d?.error_rate ?? 0) + '%', icon: 'mdi-bug', color: 'error', bg: '#fef2f2', valueColor: '#991b1b' },
    { label: 'Avg Response', value: (data.value?.usage_30d?.avg_response_ms ?? 0) + 'ms', icon: 'mdi-timer-sand', color: 'info', bg: '#eff6ff', valueColor: '#1e40af' },
  ]
})

function statusColor(s: string) {
  return { active: 'success', past_due: 'warning', cancelled: 'error', trialing: 'info' }[s] || 'grey'
}
function methodIcon(m: string) {
  return { GET: 'mdi-download', POST: 'mdi-upload', PATCH: 'mdi-pencil', PUT: 'mdi-update', DELETE: 'mdi-delete' }[m] || 'mdi-api'
}

</script>
