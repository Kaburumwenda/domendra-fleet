<template>
  <v-card elevation="0" border class="pa-5">
    <div class="d-flex align-center justify-space-between mb-4">
      <span class="text-subtitle-2 font-weight-medium text-medium-emphasis">{{ title }}</span>
      <v-icon v-if="icon" :icon="icon" color="medium-emphasis" size="small" />
    </div>
    <div ref="chartEl" :style="{ height: height || '240px' }" />
  </v-card>
</template>

<script setup lang="ts">
import * as echarts from 'echarts/core'
import { setupECharts } from '~/utils/echarts'
import { useDarkMode } from '~/composables/useDarkMode'

setupECharts()

// Register a dark theme with light text colors (idempotent — registerTheme overwrites safely)
echarts.registerTheme('domendra-dark', {
  backgroundColor: 'transparent',
  textStyle:  { color: '#cbd5e1' },
  title:      { textStyle: { color: '#f1f5f9' }, subtextStyle: { color: '#94a3b8' } },
  legend:     { textStyle: { color: '#cbd5e1' } },
  tooltip:    { backgroundColor: '#1e293b', borderColor: '#334155', textStyle: { color: '#f1f5f9' } },
  xAxis:      { axisLabel: { color: '#94a3b8' }, axisLine: { lineStyle: { color: '#475569' } }, splitLine: { lineStyle: { color: '#1e293b' } } },
  yAxis:      { axisLabel: { color: '#94a3b8' }, axisLine: { lineStyle: { color: '#475569' } }, splitLine: { lineStyle: { color: '#334155' } } },
})

const props = defineProps<{
  option: Record<string, any>
  title?: string
  icon?: string
  height?: string
}>()

const { isDark } = useDarkMode()

const chartEl = ref<HTMLElement | null>(null)
let chart: echarts.ECharts | null = null
let resizeObserver: ResizeObserver | null = null

function ensureInit() {
  if (chart || !chartEl.value) return
  // Skip init while the container is still hidden (no dimensions)
  if (chartEl.value.clientWidth === 0 || chartEl.value.clientHeight === 0) return
  chart = echarts.init(chartEl.value, isDark.value ? 'domendra-dark' : undefined)
  chart.setOption(props.option)
}

function resize() {
  if (chart) {
    chart.resize()
  } else {
    // First time the container becomes visible — lazy init
    ensureInit()
  }
}

onMounted(() => {
  ensureInit()
  window.addEventListener('resize', resize)
  // Watch container size changes (e.g. v-window-item becoming active)
  if (chartEl.value && typeof ResizeObserver !== 'undefined') {
    resizeObserver = new ResizeObserver(() => resize())
    resizeObserver.observe(chartEl.value)
  }
})

onUnmounted(() => {
  window.removeEventListener('resize', resize)
  resizeObserver?.disconnect()
  chart?.dispose()
})

watch(() => props.option, (val) => {
  if (chart) {
    chart.setOption(val, true)
  } else {
    // Chart not yet initialised (hidden container) — try now
    ensureInit()
  }
}, { deep: true })

// Re-init chart with the correct theme when dark mode toggles
watch(isDark, () => {
  if (chart) {
    chart.dispose()
    chart = null
    ensureInit()
  }
})
</script>
