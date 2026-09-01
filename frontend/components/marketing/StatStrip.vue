<template>
  <section class="fc-stats">
    <div class="fc-stats__inner">
      <SectionEyebrow text="Real results" icon="mdi-trending-up" />
      <h2>Cut costs. Save time. Drive results.</h2>
      <div class="fc-stats__grid">
        <div v-for="s in stats" :key="s.label" class="fc-stat">
          <p class="fc-stat__value"><span>{{ s.prefix }}</span><Counter :to="s.value" :suffix="s.suffix" /></p>
          <p class="fc-stat__label">{{ s.label }}</p>
          <p class="fc-stat__company">{{ s.company }}</p>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
const stats = [
  { value: 70, suffix: '%', prefix: '', label: 'Reduced time spent on inspections', company: 'Stanley Steemer' },
  { value: 45, suffix: 'k', prefix: '$', label: 'Saved annually in avoided breakdowns', company: 'A&D Environmental' },
  { value: 6, suffix: 'x', prefix: '', label: 'Reduced time spent on fleet reports', company: 'Newkirk Electric' },
]
</script>

<script lang="ts">
const Counter = defineComponent({
  props: { to: { type: Number, required: true }, suffix: { type: String, default: '' } },
  setup(props) {
    const n = ref(0)
    onMounted(() => {
      const dur = 1400; const start = performance.now()
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
.fc-stats { background: linear-gradient(180deg, #0f172a, #1e293b); color: #fff; padding: 88px 0; position: relative; overflow: hidden; }
.fc-stats::before { content: ''; position: absolute; inset: 0; background-image: radial-gradient(circle at 30% 50%, rgba(99,102,241,.08), transparent 50%), radial-gradient(circle at 70% 50%, rgba(34,197,94,.06), transparent 50%); }
.fc-stats__inner { position: relative; z-index: 1; max-width: 1240px; margin: 0 auto; padding: 0 24px; text-align: center; }
.fc-stats__inner :deep(.fc-eyebrow) { background: rgba(99, 102, 241, .15); color: #a5b4fc; }
.fc-stats__inner h2 { font-size: clamp(28px, 3.5vw, 42px); font-weight: 800; letter-spacing: -0.02em; margin: 16px 0 48px; }
.fc-stats__grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 32px; }
.fc-stat { padding: 36px 32px; border: 1px solid rgba(255,255,255,.08); border-radius: 20px; background: rgba(255, 255, 255, .03); backdrop-filter: blur(4px); transition: all .25s ease; }
.fc-stat:hover { background: rgba(255, 255, 255, .06); transform: translateY(-4px); border-color: rgba(99, 102, 241, .2); }
.fc-stat__value { font-size: clamp(44px, 5vw, 64px); font-weight: 800; letter-spacing: -0.03em; margin-bottom: 12px; background: linear-gradient(120deg, #818cf8, #34d399); -webkit-background-clip: text; background-clip: text; -webkit-text-fill-color: transparent; }
.fc-stat__label { font-size: 15px; color: #cbd5e1; line-height: 1.5; margin-bottom: 16px; }
.fc-stat__company { font-size: 13px; font-weight: 600; color: #94a3b8; text-transform: uppercase; letter-spacing: .06em; }
@media (max-width: 800px) { .fc-stats__grid { grid-template-columns: 1fr; gap: 18px; } }
</style>
