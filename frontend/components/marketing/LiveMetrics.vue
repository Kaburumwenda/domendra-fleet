<template>
  <section class="fc-live">
    <div class="fc-live__inner">
      <div class="fc-live__head reveal">
        <SectionEyebrow text="Live operations" icon="mdi-pulse" />
        <h2>Your entire fleet at a glance</h2>
        <p>Real-time dashboards that surface what matters. No more spreadsheet hunting — just clarity.</p>
      </div>

      <div class="fc-live__grid">
        <!-- Active fleet gauge -->
        <div class="fc-live__card reveal" data-reveal-delay="0">
          <div class="fc-live__card-top">
            <div class="fc-live__icon" style="background:#eef2ff; color:#4f46e5">
              <v-icon size="20">mdi-car-multiple</v-icon>
            </div>
            <span class="fc-live__trend is-up"><v-icon size="14">mdi-trending-up</v-icon>+4.2%</span>
          </div>
          <p class="fc-live__label">Active Fleet</p>
          <p class="fc-live__num"><Counter :to="142" /></p>
          <div ref="gaugeEl" class="fc-live__gauge" />
        </div>

        <!-- Fuel cost trend -->
        <div class="fc-live__card reveal" data-reveal-delay="100">
          <div class="fc-live__card-top">
            <div class="fc-live__icon" style="background:#fff7ed; color:#ea580c">
              <v-icon size="20">mdi-gas-station</v-icon>
            </div>
            <span class="fc-live__trend is-down"><v-icon size="14">mdi-trending-down</v-icon>-8.1%</span>
          </div>
          <p class="fc-live__label">Weekly Fuel Cost</p>
          <p class="fc-live__num">$<Counter :to="8420" /></p>
          <div ref="fuelEl" class="fc-live__spark" />
        </div>

        <!-- Maintenance cost -->
        <div class="fc-live__card reveal" data-reveal-delay="200">
          <div class="fc-live__card-top">
            <div class="fc-live__icon" style="background:#f0fdf4; color:#16a34a">
              <v-icon size="20">mdi-wrench</v-icon>
            </div>
            <span class="fc-live__trend is-up"><v-icon size="14">mdi-trending-up</v-icon>+2.3%</span>
          </div>
          <p class="fc-live__label">Maintenance Spend</p>
          <p class="fc-live__num">$<Counter :to="3180" /></p>
          <div ref="maintEl" class="fc-live__spark" />
        </div>

        <!-- Uptime donut -->
        <div class="fc-live__card reveal" data-reveal-delay="300">
          <div class="fc-live__card-top">
            <div class="fc-live__icon" style="background:#ecfeff; color:#0891b2">
              <v-icon size="20">mdi-speedometer</v-icon>
            </div>
            <span class="fc-live__trend is-up"><v-icon size="14">mdi-trending-up</v-icon>98.2%</span>
          </div>
          <p class="fc-live__label">Fleet Uptime</p>
          <div class="fc-live__uptime-row">
            <p class="fc-live__num"><Counter :to="98" />%</p>
            <div ref="donutEl" class="fc-live__donut" />
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { h, defineComponent, ref, onMounted, onBeforeUnmount } from 'vue'
import * as echarts from 'echarts/core'
import { GaugeChart, BarChart, PieChart, LineChart } from 'echarts/charts'
import { GridComponent, TooltipComponent } from 'echarts/components'
import { CanvasRenderer } from 'echarts/renderers'

echarts.use([GaugeChart, BarChart, LineChart, PieChart, GridComponent, TooltipComponent, CanvasRenderer])

const gaugeEl = ref<HTMLElement | null>(null)
const fuelEl = ref<HTMLElement | null>(null)
const maintEl = ref<HTMLElement | null>(null)
const donutEl = ref<HTMLElement | null>(null)

const charts: echarts.ECharts[] = []

const { register } = useScrollReveal()

function makeChart(el: HTMLElement): echarts.ECharts {
  const inst = echarts.init(el)
  charts.push(inst)
  return inst
}

onMounted(() => {
  register('.reveal')

  // Gauge — active fleet
  if (gaugeEl.value) {
    makeChart(gaugeEl.value).setOption({
      series: [{
        type: 'gauge', radius: '92%', startAngle: 200, endAngle: -20,
        min: 0, max: 200, splitNumber: 5,
        progress: { show: true, width: 10, roundCap: true, itemStyle: { color: { type: 'linear', x: 0, y: 0, x2: 1, y2: 0, colorStops: [{ offset: 0, color: '#6366f1' }, { offset: 1, color: '#8b5cf6' }] } } },
        axisLine: { lineStyle: { width: 10, color: [[1, '#f1f5f9']] } },
        axisTick: { show: false },
        splitLine: { show: false },
        axisLabel: { show: false },
        pointer: { show: false },
        detail: { show: false },
        data: [{ value: 142 }],
      }],
    })
  }

  // Fuel sparkline
  if (fuelEl.value) {
    const fuelChart = makeChart(fuelEl.value)
    const fuelSeed = [820, 880, 760, 910, 840, 790, 8420]
    fuelChart.setOption({
      grid: { top: 4, right: 4, bottom: 4, left: 4 },
      xAxis: { type: 'category', show: false, data: [...Array(7).keys()] },
      yAxis: { type: 'value', show: false, min: 0, max: 10000 },
      series: [{
        type: 'bar', barWidth: 10, data: fuelSeed,
        itemStyle: { borderRadius: [4, 4, 0, 0], color: { type: 'linear', x: 0, y: 0, x2: 0, y2: 1, colorStops: [{ offset: 0, color: '#fb923c' }, { offset: 1, color: 'rgba(251,146,60,0.3)' }] } },
      }],
    })
  }

  // Maint sparkline
  if (maintEl.value) {
    const maintChart = makeChart(maintEl.value)
    maintChart.setOption({
      grid: { top: 4, right: 4, bottom: 4, left: 4 },
      xAxis: { type: 'category', show: false, data: [...Array(7).keys()] },
      yAxis: { type: 'value', show: false, min: 0, max: 5000 },
      series: [{
        type: 'line', smooth: true, symbol: 'none',
        data: [2400, 2800, 2200, 3100, 2900, 3400, 3180],
        lineStyle: { width: 2.5, color: '#22c55e' },
        areaStyle: { color: { type: 'linear', x: 0, y: 0, x2: 0, y2: 1, colorStops: [{ offset: 0, color: 'rgba(34,197,94,0.25)' }, { offset: 1, color: 'rgba(34,197,94,0.01)' }] } },
      }],
    })
  }

  // Donut — uptime
  if (donutEl.value) {
    makeChart(donutEl.value).setOption({
      series: [{
        type: 'pie', radius: ['68%', '92%'], center: ['50%', '50%'],
        silent: true,
        label: { show: false },
        data: [
          { value: 98.2, itemStyle: { color: { type: 'linear', x: 0, y: 0, x2: 1, y2: 0, colorStops: [{ offset: 0, color: '#0891b2' }, { offset: 1, color: '#06b6d4' }] } } },
          { value: 1.8, itemStyle: { color: '#f1f5f9' } },
        ],
      }],
    })
  }

  // Resize all charts on window resize
  window.addEventListener('resize', resizeAll)
})

function resizeAll() {
  charts.forEach((c) => c.resize())
}

onBeforeUnmount(() => {
  window.removeEventListener('resize', resizeAll)
  charts.forEach((c) => c.dispose())
})

const Counter = defineComponent({
  props: { to: { type: Number, required: true } },
  setup(props) {
    const n = ref(0)
    onMounted(() => {
      const dur = 1800
      const start = performance.now()
      const tick = (t: number) => {
        const p = Math.min(1, (t - start) / dur)
        n.value = Math.round(props.to * (1 - Math.pow(1 - p, 3)))
        if (p < 1) requestAnimationFrame(tick)
      }
      requestAnimationFrame(tick)
    })
    return () => h('span', String(n.value))
  },
})
</script>

<style scoped>
.fc-live { background: linear-gradient(180deg, #fff, #f8fafc); padding: 88px 0 80px; }
.fc-live__inner { max-width: 1240px; margin: 0 auto; padding: 0 24px; }

.fc-live__head { text-align: center; max-width: 640px; margin: 0 auto 52px; }
.fc-live__head h2 { font-size: clamp(28px, 3.5vw, 42px); font-weight: 800; letter-spacing: -0.02em; color: #0f172a; margin: 16px 0 14px; }
.fc-live__head p { font-size: 16px; line-height: 1.6; color: #64748b; }

.fc-live__grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; }
.fc-live__card {
  background: #fff; border: 1px solid #eef2f7; border-radius: 20px; padding: 24px;
  transition: all 0.3s cubic-bezier(0.22, 1, 0.36, 1);
}
.fc-live__card:hover { border-color: #c7d2fe; box-shadow: 0 24px 56px rgba(79, 70, 229, 0.1); transform: translateY(-6px); }

.fc-live__card-top { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.fc-live__icon { width: 44px; height: 44px; border-radius: 12px; display: flex; align-items: center; justify-content: center; }
.fc-live__trend { display: flex; align-items: center; gap: 2px; font-size: 12px; font-weight: 700; padding: 3px 8px; border-radius: 8px; }
.fc-live__trend.is-up { color: #16a34a; background: #dcfce7; }
.fc-live__trend.is-down { color: #dc2626; background: #fee2e2; }

.fc-live__label { font-size: 12px; font-weight: 600; color: #94a3b8; margin-bottom: 6px; }
.fc-live__num { font-size: 30px; font-weight: 800; color: #0f172a; letter-spacing: -0.02em; margin-bottom: 12px; }

.fc-live__gauge { width: 100%; height: 80px; }
.fc-live__spark { width: 100%; height: 50px; }

.fc-live__uptime-row { display: flex; align-items: center; gap: 12px; }
.fc-live__donut { width: 56px; height: 56px; flex-shrink: 0; }

@media (max-width: 1024px) { .fc-live__grid { grid-template-columns: repeat(2, 1fr); } }
@media (max-width: 540px) { .fc-live__grid { grid-template-columns: 1fr; } }
</style>
