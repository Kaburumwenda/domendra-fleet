<template>
  <section class="fc-stats">
    <div class="fc-stats__bg">
      <div class="fc-stats__blob fc-stats__blob--1" />
      <div class="fc-stats__blob fc-stats__blob--2" />
      <div class="fc-stats__grid" />
    </div>
    <div class="fc-stats__inner">
      <div class="fc-stats__head reveal">
        <SectionEyebrow text="Real results" icon="mdi-trending-up" />
        <h2>Cut costs. Save time. Drive results.</h2>
        <p>Real numbers from real fleets. See the impact DomendraFleet has on operations like yours.</p>
      </div>
      <div class="fc-stats__grid">
        <div
          v-for="(s, i) in stats"
          :key="s.label"
          class="fc-stat reveal"
          :data-reveal-delay="i * 120"
        >
          <div class="fc-stat__ring-wrap">
            <svg class="fc-stat__ring" viewBox="0 0 120 120">
              <circle class="fc-stat__ring-bg" cx="60" cy="60" r="52" />
              <circle
                class="fc-stat__ring-fg"
                cx="60"
                cy="60"
                r="52"
                :stroke="s.ringColor"
                :style="ringStyle(s, i)"
              />
            </svg>
            <div class="fc-stat__ring-center">
              <span class="fc-stat__value">{{ s.prefix }}<Counter :to="s.value" :suffix="s.suffix" /></span>
            </div>
          </div>
          <p class="fc-stat__label">{{ s.label }}</p>
          <p class="fc-stat__company">{{ s.company }}</p>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { h, defineComponent, ref, onMounted, onBeforeUnmount } from 'vue'

const stats = [
  { value: 70, suffix: '%', prefix: '', label: 'Reduced time spent on inspections', company: 'Stanley Steemer', ringColor: '#818cf8', target: 70 },
  { value: 45, suffix: 'k', prefix: '$', label: 'Saved annually in avoided breakdowns', company: 'A&D Environmental', ringColor: '#34d399', target: 45 },
  { value: 6, suffix: 'x', prefix: '', label: 'Reduced time spent on fleet reports', company: 'Newkirk Electric', ringColor: '#fbbf24', target: 6 },
]

const ringProgress = ref<number[]>([0, 0, 0])

function ringStyle(s: typeof stats[0], i: number) {
  const circ = 2 * Math.PI * 52
  const pct = ringProgress.value[i] / 100
  return {
    strokeDasharray: `${circ}`,
    strokeDashoffset: `${circ * (1 - pct)}`,
    transition: 'stroke-dashoffset 1.6s cubic-bezier(0.22, 1, 0.36, 1)',
  }
}

const { register } = useScrollReveal()

let animTimer: ReturnType<typeof setTimeout> | null = null

onMounted(() => {
  register('.reveal')

  // Animate rings after a short delay
  animTimer = setTimeout(() => {
    stats.forEach((s, i) => {
      ringProgress.value[i] = s.target
    })
  }, 300)
})

onBeforeUnmount(() => {
  if (animTimer) clearTimeout(animTimer)
})

const Counter = defineComponent({
  props: { to: { type: Number, required: true }, suffix: { type: String, default: '' } },
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
    return () => h('span', n.value + props.suffix)
  },
})
</script>

<style scoped>
.fc-stats { background: linear-gradient(180deg, #0f172a, #1e293b); color: #fff; padding: 96px 0; position: relative; overflow: hidden; }
.fc-stats__bg { position: absolute; inset: 0; z-index: 0; }
.fc-stats__blob { position: absolute; border-radius: 50%; filter: blur(90px); animation: fcblob 20s ease-in-out infinite; }
.fc-stats__blob--1 { top: -100px; right: 10%; width: 400px; height: 400px; background: rgba(99,102,241,0.08); }
.fc-stats__blob--2 { bottom: -120px; left: 5%; width: 360px; height: 360px; background: rgba(34,197,94,0.06); animation-delay: 8s; }
@keyframes fcblob { 0%,100% { transform: translate(0,0) scale(1); } 50% { transform: translate(30px,-20px) scale(1.05); } }
.fc-stats__grid {
  position: absolute; inset: 0;
  background-image: linear-gradient(rgba(255,255,255,0.03) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.03) 1px, transparent 1px);
  background-size: 48px 48px;
  mask-image: radial-gradient(ellipse 80% 70% at 50% 50%, #000 30%, transparent 80%);
  -webkit-mask-image: radial-gradient(ellipse 80% 70% at 50% 50%, #000 30%, transparent 80%);
}

.fc-stats__inner { position: relative; z-index: 1; max-width: 1240px; margin: 0 auto; padding: 0 24px; text-align: center; }
.fc-stats__head :deep(.fc-eyebrow) { background: rgba(99, 102, 241, .15); color: #a5b4fc; }
.fc-stats__head h2 { font-size: clamp(28px, 3.5vw, 42px); font-weight: 800; letter-spacing: -0.02em; margin: 16px 0 12px; }
.fc-stats__head p { font-size: 16px; color: #94a3b8; max-width: 540px; margin: 0 auto 56px; }

.fc-stats__grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 32px; }

.fc-stat {
  padding: 40px 32px; border: 1px solid rgba(255,255,255,0.08); border-radius: 20px;
  background: rgba(255, 255, 255, 0.03); backdrop-filter: blur(4px);
  transition: all .3s ease;
}
.fc-stat:hover { background: rgba(255, 255, 255, 0.06); transform: translateY(-6px); border-color: rgba(99, 102, 241, 0.25); }

.fc-stat__ring-wrap { position: relative; width: 120px; height: 120px; margin: 0 auto 24px; }
.fc-stat__ring { width: 120px; height: 120px; transform: rotate(-90deg); }
.fc-stat__ring-bg { fill: none; stroke: rgba(255,255,255,0.06); stroke-width: 6; }
.fc-stat__ring-fg { fill: none; stroke-width: 6; stroke-linecap: round; }
.fc-stat__ring-center {
  position: absolute; inset: 0; display: flex; align-items: center; justify-content: center;
}
.fc-stat__value {
  font-size: clamp(32px, 3.5vw, 44px); font-weight: 800; letter-spacing: -0.03em;
  background: linear-gradient(120deg, #818cf8, #34d399);
  -webkit-background-clip: text; background-clip: text; -webkit-text-fill-color: transparent;
}

.fc-stat__label { font-size: 15px; color: #cbd5e1; line-height: 1.5; margin-bottom: 14px; }
.fc-stat__company { font-size: 13px; font-weight: 600; color: #64748b; text-transform: uppercase; letter-spacing: .06em; }

@media (max-width: 800px) { .fc-stats__grid { grid-template-columns: 1fr; gap: 20px; } }
</style>
