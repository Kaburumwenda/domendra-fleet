<template>
  <section class="fc-cta">
    <div class="fc-cta__inner reveal" data-reveal-type="scale">
      <span class="fc-cta__pill"><v-icon size="14" color="#16a34a">mdi-circle-medium</v-icon> {{ trialing }} companies trialing Domendra in the last 24 hours</span>
      <h2>Ready to get started?</h2>
      <p>Join thousands of satisfied customers running smarter fleets. Questions? Call us at +254 739 123 995.</p>
      <div class="fc-cta__btns">
        <NuxtLink to="/register" class="fc-btn fc-btn--primary">Start a free trial</NuxtLink>
        <NuxtLink to="/contact" class="fc-btn fc-btn--light">Book a demo</NuxtLink>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'

const trialing = ref(0)
const { register } = useScrollReveal()

onMounted(() => {
  register('.reveal')
  const dur = 1600; const target = 247; const start = performance.now()
  const tick = (t: number) => {
    const p = Math.min(1, (t - start) / dur)
    trialing.value = Math.round(target * (1 - Math.pow(1 - p, 3)))
    if (p < 1) requestAnimationFrame(tick)
  }
  requestAnimationFrame(tick)
})
</script>

<style scoped>
.fc-cta { background: linear-gradient(135deg, #4f46e5 0%, #4338ca 50%, #312e81 100%); padding: 88px 0; position: relative; overflow: hidden; }
.fc-cta::before { content: ''; position: absolute; inset: 0; background-image: radial-gradient(circle at 20% 20%, rgba(255,255,255,.1), transparent 40%), radial-gradient(circle at 80% 80%, rgba(255,255,255,.08), transparent 40%); }
.fc-cta::after { content: ''; position: absolute; inset: 0; background-image: linear-gradient(rgba(255,255,255,.04) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,.04) 1px, transparent 1px); background-size: 38px 38px; mask-image: radial-gradient(ellipse 70% 60% at 50% 50%, #000 20%, transparent 80%); -webkit-mask-image: radial-gradient(ellipse 70% 60% at 50% 50%, #000 20%, transparent 80%); }
.fc-cta__inner { position: relative; z-index: 1; max-width: 720px; margin: 0 auto; padding: 0 24px; text-align: center; color: #fff; }
.fc-cta__pill { display: inline-flex; align-items: center; gap: 4px; background: rgba(255, 255, 255, .12); backdrop-filter: blur(8px); border: 1px solid rgba(255, 255, 255, .2); padding: 7px 16px; border-radius: 999px; font-size: 13px; font-weight: 600; margin-bottom: 24px; }
.fc-cta__inner h2 { font-size: clamp(32px, 4vw, 48px); font-weight: 800; letter-spacing: -0.02em; margin: 0 0 14px; }
.fc-cta__inner p { font-size: 17px; opacity: .85; margin-bottom: 32px; }
.fc-cta__btns { display: flex; gap: 14px; justify-content: center; flex-wrap: wrap; }
.fc-btn { display: inline-flex; align-items: center; font-weight: 600; font-size: 15px; padding: 14px 28px; border-radius: 12px; text-decoration: none; transition: all .2s ease; }
.fc-btn--primary { background: #fff; color: #4f46e5; box-shadow: 0 4px 16px rgba(0,0,0,.15); } .fc-btn--primary:hover { transform: translateY(-2px); box-shadow: 0 12px 32px rgba(0,0,0,.25); }
.fc-btn--light { background: rgba(255, 255, 255, .12); backdrop-filter: blur(8px); color: #fff; border: 1px solid rgba(255, 255, 255, .25); } .fc-btn--light:hover { background: rgba(255, 255, 255, .2); transform: translateY(-1px); }
</style>
