<template>
  <section class="fc-hero">
    <div class="fc-hero__bg">
      <div class="fc-hero__blob fc-hero__blob--1" />
      <div class="fc-hero__blob fc-hero__blob--2" />
      <div class="fc-hero__blob fc-hero__blob--3" />
      <div class="fc-hero__grid" />
    </div>

    <div class="fc-hero__inner">
      <!-- ── Left: copy ── -->
      <div class="fc-hero__copy">
        <span class="fc-hero__pill">
          <span class="fc-hero__pill-dot" />
          Powering 1,000,000+ fleet assets
        </span>
        <h1 class="fc-hero__title">
          Fleet maintenance<br>
          that <span class="fc-hero__accent">thinks ahead.</span>
        </h1>
        <p class="fc-hero__sub">
          Run your fleet reliably, repair your assets quickly and optimize every aspect of your operation:
          vehicles, drivers, fuel, equipment, parts and more. Turn everyday data into actionable insights
          that keep your fleet on the move.
        </p>
        <div class="fc-hero__cta">
          <NuxtLink to="/register" class="fc-btn fc-btn--primary" @click="track('hero_trial')">
            Start a Free Trial
            <v-icon size="18" class="fc-btn__icon">mdi-arrow-right</v-icon>
          </NuxtLink>
          <NuxtLink to="/contact" class="fc-btn fc-btn--ghost">
            <v-icon size="18">mdi-play-circle-outline</v-icon> Book a Demo
          </NuxtLink>
        </div>
        <div class="fc-hero__proof">
          <div class="fc-hero__stars">
            <div class="fc-hero__star-row">
              <v-icon v-for="i in 5" :key="i" size="16" color="#f59e0b">mdi-star</v-icon>
            </div>
            <span>4.8/5 · Based on 100s of reviews</span>
          </div>
          <div class="fc-hero__logos">
            <span>G2</span><span>Capterra</span><span>Software Advice</span><span>GetApp</span>
          </div>
        </div>
      </div>

      <!-- ── Right: animated dashboard visual ── -->
      <div class="fc-hero__visual">
        <div class="fc-hero__glow" />

        <!-- Main dashboard card -->
        <div class="fc-hero__card fc-hero__card--main">
          <div class="fc-hero__cardbar">
            <span class="fc-dot fc-dot--r" />
            <span class="fc-dot fc-dot--y" />
            <span class="fc-dot fc-dot--g" />
            <b>Domendra · Dashboard</b>
            <span class="fc-hero__live">
              <span class="fc-hero__live-dot" />
              Live
            </span>
          </div>

          <!-- KPI row -->
          <div class="fc-hero__kpis">
            <div
              v-for="(kpi, i) in kpis"
              :key="kpi.label"
              class="fc-kpi"
              :style="{ animationDelay: i * 0.12 + 's' }"
            >
              <span class="fc-kpi__label">{{ kpi.label }}</span>
              <div class="fc-kpi__row">
                <span class="fc-kpi__val" :style="{ color: kpi.color }">{{ kpi.display }}</span>
                <span class="fc-kpi__delta" :class="kpi.delta >= 0 ? 'is-up' : 'is-down'">
                  <v-icon size="12">{{ kpi.delta >= 0 ? 'mdi-trending-up' : 'mdi-trending-down' }}</v-icon>
                  {{ Math.abs(kpi.delta) }}%
                </span>
              </div>
              <div class="fc-bar">
                <i :style="{ width: kpi.bar + '%', background: kpi.gradient }" />
              </div>
            </div>
          </div>

          <!-- Animated area chart -->
          <div class="fc-hero__chart-wrap">
            <div class="fc-hero__chart-header">
              <span class="fc-hero__chart-title">Fleet Cost — Last 7 Days</span>
              <div class="fc-hero__chart-legend">
                <span class="fc-legend"><i style="background:#6366f1" />Fuel</span>
                <span class="fc-legend"><i style="background:#22c55e" />Maintenance</span>
              </div>
            </div>
            <div ref="chartEl" class="fc-hero__chart" />
          </div>
        </div>

        <!-- Floating notification cards -->
        <div class="fc-hero__card fc-hero__card--float">
          <div class="fc-hero__floaticon" style="background: #dcfce7; color: #16a34a">
            <v-icon size="18">mdi-check-decagram</v-icon>
          </div>
          <div>
            <b>Inspection passed</b>
            <small>Ford Transit · #FC-2041</small>
          </div>
        </div>
        <div class="fc-hero__card fc-hero__card--float fc-hero__card--float2">
          <div class="fc-hero__floaticon" style="background: #fef3c7; color: #d97706">
            <v-icon size="18">mdi-bell-alert</v-icon>
          </div>
          <div>
            <b>PM reminder due</b>
            <small>Kenworth T680 · in 2 days</small>
          </div>
        </div>
        <div class="fc-hero__card fc-hero__card--float fc-hero__card--float3">
          <div class="fc-hero__floaticon" style="background: #eef2ff; color: #4f46e5">
            <v-icon size="18">mdi-chart-timeline-variant</v-icon>
          </div>
          <div>
            <b>Uptime at 98.2%</b>
            <small>All 142 vehicles operational</small>
          </div>
        </div>
      </div>
    </div>

    <!-- Scroll indicator -->
    <div class="fc-hero__scroll">
      <span>Scroll to explore</span>
      <div class="fc-hero__scroll-line" />
    </div>
  </section>
</template>

<script setup lang="ts">
import * as echarts from 'echarts/core'
import { LineChart } from 'echarts/charts'
import { GridComponent, TooltipComponent } from 'echarts/components'
import { CanvasRenderer } from 'echarts/renderers'

echarts.use([LineChart, GridComponent, TooltipComponent, CanvasRenderer])

const chartEl = ref<HTMLElement | null>(null)
let chartInstance: echarts.ECharts | null = null

// Animated KPIs
const kpis = reactive([
  { label: 'Fleet Utilization', value: 87, display: '87%', delta: 4, bar: 87, color: '#6366f1', gradient: 'linear-gradient(90deg,#6366f1,#8b5cf6)' },
  { label: 'Active Vehicles', value: 142, display: '142', delta: 6, bar: 72, color: '#16a34a', gradient: 'linear-gradient(90deg,#22c55e,#16a34a)' },
  { label: 'Open Work Orders', value: 18, display: '18', delta: -12, bar: 24, color: '#f59e0b', gradient: 'linear-gradient(90deg,#f59e0b,#d97706)' },
])

// Chart data that updates every 3s for "live" feel
const fuelData = ref([320, 290, 340, 310, 380, 360, 420])
const maintData = ref([180, 220, 190, 240, 210, 260, 230])
const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']

function buildChartOption() {
  return {
    grid: { top: 8, right: 8, bottom: 24, left: 32 },
    tooltip: {
      trigger: 'axis',
      backgroundColor: 'rgba(15,23,42,0.92)',
      borderColor: 'transparent',
      textStyle: { color: '#f1f5f9', fontSize: 11 },
      axisPointer: { type: 'line', lineStyle: { color: '#cbd5e1', type: 'dashed' } },
    },
    xAxis: {
      type: 'category',
      data: days,
      axisLine: { lineStyle: { color: '#e2e8f0' } },
      axisLabel: { color: '#94a3b8', fontSize: 10, fontWeight: 600 },
      axisTick: { show: false },
    },
    yAxis: {
      type: 'value',
      splitLine: { lineStyle: { color: '#f1f5f9' } },
      axisLabel: { color: '#94a3b8', fontSize: 9, formatter: (v: number) => `$${v}` },
    },
    series: [
      {
        name: 'Fuel',
        type: 'line',
        smooth: true,
        data: fuelData.value,
        symbol: 'circle',
        symbolSize: 6,
        lineStyle: { width: 3, color: '#6366f1' },
        itemStyle: { color: '#6366f1', borderColor: '#fff', borderWidth: 2 },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(99,102,241,0.25)' },
            { offset: 1, color: 'rgba(99,102,241,0.01)' },
          ]),
        },
      },
      {
        name: 'Maintenance',
        type: 'line',
        smooth: true,
        data: maintData.value,
        symbol: 'circle',
        symbolSize: 6,
        lineStyle: { width: 3, color: '#22c55e' },
        itemStyle: { color: '#22c55e', borderColor: '#fff', borderWidth: 2 },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(34,197,94,0.22)' },
            { offset: 1, color: 'rgba(34,197,94,0.01)' },
          ]),
        },
      },
    ],
  }
}

let liveTimer: ReturnType<typeof setInterval> | null = null

function startLiveUpdates() {
  liveTimer = setInterval(() => {
    // Shift data: drop first, push new
    fuelData.value = [...fuelData.value.slice(1), Math.max(200, Math.round(fuelData.value[fuelData.value.length - 1] + (Math.random() - 0.4) * 50))]
    maintData.value = [...maintData.value.slice(1), Math.max(120, Math.round(maintData.value[maintData.value.length - 1] + (Math.random() - 0.4) * 40))]
    chartInstance?.setOption(buildChartOption())

    // Update KPI displays
    kpis[0].value = Math.min(99, kpis[0].value + (Math.random() > 0.5 ? 1 : -1))
    kpis[0].display = kpis[0].value + '%'
    kpis[0].bar = kpis[0].value
    kpis[1].value = Math.max(100, kpis[1].value + (Math.random() > 0.5 ? 1 : -1))
    kpis[1].display = String(kpis[1].value)
    kpis[2].value = Math.max(5, Math.min(40, kpis[2].value + (Math.random() > 0.5 ? 2 : -2)))
    kpis[2].display = String(kpis[2].value)
    kpis[2].bar = (kpis[2].value / 50) * 100
  }, 3000)
}

function track(_event: string) {
  // placeholder for analytics
}

onMounted(() => {
  if (chartEl.value) {
    chartInstance = echarts.init(chartEl.value)
    chartInstance.setOption(buildChartOption())

    const ro = new ResizeObserver(() => chartInstance?.resize())
    ro.observe(chartEl.value)
  }
  startLiveUpdates()
})

onBeforeUnmount(() => {
  if (liveTimer) clearInterval(liveTimer)
  chartInstance?.dispose()
  chartInstance = null
})
</script>

<style scoped>
.fc-hero { position: relative; overflow: hidden; padding: 80px 0 64px; }
.fc-hero__bg { position: absolute; inset: 0; z-index: 0; }
.fc-hero__blob { position: absolute; border-radius: 50%; filter: blur(90px); animation: fcblob 20s ease-in-out infinite; }
.fc-hero__blob--1 { top: -180px; right: -120px; width: 460px; height: 460px; background: rgba(99, 102, 241, .14); }
.fc-hero__blob--2 { bottom: -200px; left: -120px; width: 420px; height: 420px; background: rgba(34, 197, 94, .1); animation-delay: 10s; }
.fc-hero__blob--3 { top: 40%; left: 45%; width: 300px; height: 300px; background: rgba(139, 92, 246, .08); animation-delay: 5s; }
@keyframes fcblob { 0%,100% { transform: translate(0,0) scale(1); } 50% { transform: translate(30px,-20px) scale(1.05); } }

.fc-hero__grid {
  position: absolute; inset: 0;
  background-image: linear-gradient(#f1f5f9 1px, transparent 1px), linear-gradient(90deg, #f1f5f9 1px, transparent 1px);
  background-size: 44px 44px;
  mask-image: radial-gradient(ellipse 80% 60% at 50% 30%, #000 40%, transparent 80%);
  -webkit-mask-image: radial-gradient(ellipse 80% 60% at 50% 30%, #000 40%, transparent 80%);
}

.fc-hero__inner {
  position: relative; z-index: 1; max-width: 1240px; margin: 0 auto; padding: 0 24px;
  display: grid; grid-template-columns: 1.05fr 1fr; gap: 56px; align-items: center;
}

/* ── Copy ── */
.fc-hero__pill {
  display: inline-flex; align-items: center; gap: 6px;
  font-size: 12.5px; font-weight: 600; color: #334155;
  background: #fff; border: 1px solid #f1f5f9; padding: 6px 14px; border-radius: 999px;
  box-shadow: 0 1px 8px rgba(15, 23, 42, .04);
  animation: fcfadeup 0.6s ease backwards;
}
.fc-hero__pill-dot {
  width: 8px; height: 8px; border-radius: 50%; background: #22c55e;
  animation: fcpulse 2s ease-in-out infinite;
}
@keyframes fcfadeup { from { opacity: 0; transform: translateY(20px); } }

.fc-hero__title {
  font-size: clamp(38px, 5vw, 60px); line-height: 1.04; font-weight: 800;
  letter-spacing: -0.03em; color: #0f172a; margin: 22px 0 20px;
  animation: fcfadeup 0.8s ease 0.1s backwards;
}
.fc-hero__accent {
  background: linear-gradient(120deg, #6366f1, #8b5cf6, #6366f1);
  background-size: 200% 100%;
  -webkit-background-clip: text; background-clip: text;
  -webkit-text-fill-color: transparent;
  animation: fcshine 4s linear infinite;
}
@keyframes fcshine { to { background-position: 200% 0; } }

.fc-hero__sub {
  font-size: 17px; line-height: 1.65; color: #475569; max-width: 520px;
  margin-bottom: 32px;
  animation: fcfadeup 0.8s ease 0.2s backwards;
}

.fc-hero__cta { display: flex; gap: 14px; flex-wrap: wrap; animation: fcfadeup 0.8s ease 0.3s backwards; }

.fc-btn {
  display: inline-flex; align-items: center; gap: 8px;
  font-weight: 600; font-size: 15px; padding: 13px 24px; border-radius: 12px;
  text-decoration: none; cursor: pointer; white-space: nowrap;
  transition: all 0.25s cubic-bezier(0.22, 1, 0.36, 1);
}
.fc-btn--primary {
  background: linear-gradient(135deg, #6366f1, #4f46e5); color: #fff;
  box-shadow: 0 8px 24px rgba(79, 70, 229, 0.32);
}
.fc-btn--primary:hover { transform: translateY(-2px); box-shadow: 0 14px 36px rgba(79, 70, 229, 0.42); }
.fc-btn--primary .fc-btn__icon { transition: transform 0.25s ease; }
.fc-btn--primary:hover .fc-btn__icon { transform: translateX(4px); }
.fc-btn--ghost { background: #fff; color: #0f172a; border: 1.5px solid #e2e8f0; }
.fc-btn--ghost:hover { border-color: #c7d2fe; background: #f8fafc; transform: translateY(-1px); }

.fc-hero__proof { margin-top: 28px; display: flex; flex-direction: column; gap: 12px; animation: fcfadeup 0.8s ease 0.4s backwards; }
.fc-hero__stars { display: flex; align-items: center; gap: 8px; font-size: 13px; color: #64748b; }
.fc-hero__star-row { display: flex; }
.fc-hero__logos { display: flex; gap: 22px; opacity: 0.6; font-weight: 700; font-size: 13px; color: #475569; }

/* ── Visual ── */
.fc-hero__visual { position: relative; min-height: 440px; animation: fcfadeup 1s ease 0.3s backwards; }
.fc-hero__glow {
  position: absolute; inset: -20px;
  background: radial-gradient(circle at 60% 40%, rgba(99,102,241,0.15), transparent 60%);
  border-radius: 30px; pointer-events: none;
}

.fc-hero__card {
  background: rgba(255, 255, 255, 0.92);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(238, 242, 247, 0.8);
  border-radius: 18px;
  box-shadow: 0 30px 70px rgba(15, 23, 42, 0.1), 0 1px 0 rgba(255, 255, 255, 0.8) inset;
}
.fc-hero__card--main { padding: 20px; position: relative; }

.fc-hero__cardbar { display: flex; align-items: center; gap: 6px; margin-bottom: 18px; }
.fc-hero__cardbar b { margin-left: 10px; font-size: 13px; color: #94a3b8; font-weight: 600; }
.fc-hero__live { margin-left: auto; display: flex; align-items: center; gap: 4px; font-size: 11px; font-weight: 700; color: #16a34a; }
.fc-hero__live-dot { width: 6px; height: 6px; border-radius: 50%; background: #22c55e; animation: fcpulse 2s ease-in-out infinite; }
@keyframes fcpulse { 0%,100% { opacity: 1; box-shadow: 0 0 0 0 rgba(34,197,94,0.5); } 50% { opacity: 0.6; box-shadow: 0 0 0 6px rgba(34,197,94,0); } }
.fc-dot { width: 10px; height: 10px; border-radius: 50%; }
.fc-dot--r { background: #fca5a5; } .fc-dot--y { background: #fde68a; } .fc-dot--g { background: #bbf7d0; }

/* ── KPI cards ── */
.fc-hero__kpis { display: grid; grid-template-columns: repeat(3, 1fr); gap: 14px; margin-bottom: 18px; }
.fc-kpi { display: flex; flex-direction: column; gap: 6px; animation: fcfadeup 0.6s ease backwards; }
.fc-kpi__label { font-size: 11px; color: #94a3b8; font-weight: 600; }
.fc-kpi__row { display: flex; align-items: center; gap: 8px; }
.fc-kpi__val { font-size: 22px; font-weight: 800; color: #0f172a; transition: color 0.3s ease; }
.fc-kpi__delta { display: flex; align-items: center; gap: 2px; font-size: 11px; font-weight: 700; padding: 2px 6px; border-radius: 6px; }
.fc-kpi__delta.is-up { color: #16a34a; background: #dcfce7; }
.fc-kpi__delta.is-down { color: #dc2626; background: #fee2e2; }
.fc-bar { height: 5px; background: #f1f5f9; border-radius: 999px; overflow: hidden; }
.fc-bar i { display: block; height: 100%; border-radius: 999px; transition: width 0.8s cubic-bezier(0.22, 1, 0.36, 1); }

/* ── Chart ── */
.fc-hero__chart-wrap { background: #f8fafc; border-radius: 12px; padding: 14px; }
.fc-hero__chart-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 4px; }
.fc-hero__chart-title { font-size: 11px; font-weight: 700; color: #64748b; }
.fc-hero__chart-legend { display: flex; gap: 12px; }
.fc-legend { display: flex; align-items: center; gap: 4px; font-size: 10px; color: #94a3b8; font-weight: 600; }
.fc-legend i { width: 10px; height: 3px; border-radius: 2px; }
.fc-hero__chart { width: 100%; height: 140px; }

/* ── Floating cards ── */
.fc-hero__card--float {
  position: absolute; display: flex; align-items: center; gap: 12px;
  padding: 14px 18px; border-radius: 14px; max-width: 280px;
  animation: fcbob 4s ease-in-out infinite;
}
.fc-hero__card--float { right: -24px; top: 28%; z-index: 2; }
.fc-hero__card--float2 { right: -8px; bottom: 42%; animation-delay: 1.5s; z-index: 2; }
.fc-hero__card--float3 { left: -20px; bottom: 8%; animation-delay: 2.5s; z-index: 2; }
.fc-hero__floaticon { width: 38px; height: 38px; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.fc-hero__card--float b { display: block; font-size: 13.5px; color: #0f172a; }
.fc-hero__card--float small { display: block; font-size: 12px; color: #94a3b8; }
@keyframes fcbob { 0%,100% { transform: translateY(0); } 50% { transform: translateY(-8px); } }

/* ── Scroll indicator ── */
.fc-hero__scroll {
  position: absolute; bottom: 16px; left: 50%; transform: translateX(-50%);
  display: flex; flex-direction: column; align-items: center; gap: 6px;
  font-size: 11px; font-weight: 600; color: #94a3b8;
  animation: fcfadeup 1s ease 1s backwards;
}
.fc-hero__scroll-line {
  width: 1px; height: 32px; border-radius: 2px;
  background: linear-gradient(to bottom, #cbd5e1, transparent);
  animation: fcscrolldown 2s ease-in-out infinite;
  transform-origin: top;
}
@keyframes fcscrolldown { 0% { transform: scaleY(0); } 50% { transform: scaleY(1); } 100% { transform: scaleY(0); transform-origin: bottom; } }

@media (max-width: 980px) {
  .fc-hero__inner { grid-template-columns: 1fr; gap: 36px; }
  .fc-hero__visual { min-height: 380px; }
  .fc-hero__card--float { right: 0; }
  .fc-hero__card--float3 { left: 8px; }
  .fc-hero__scroll { display: none; }
}
</style>
