<template>
  <section class="fc-quote">
    <div class="fc-quote__inner reveal" data-reveal-type="fade">
      <v-icon size="48" color="#c7d2fe" class="fc-quote__mark">mdi-format-quote-open</v-icon>
      <transition name="fc-quote-fade" mode="out-in">
        <div :key="active" class="fc-quote__slide">
          <blockquote>{{ testimonials[active].quote }}</blockquote>
          <div class="fc-quote__by">
            <div class="fc-quote__avatar" :style="{ background: testimonials[active].gradient }">{{ testimonials[active].initials }}</div>
            <div>
              <p class="fc-quote__name">{{ testimonials[active].name }}</p>
              <p class="fc-quote__company">{{ testimonials[active].company }}</p>
            </div>
          </div>
        </div>
      </transition>
      <div class="fc-quote__dots">
        <button v-for="(t, i) in testimonials" :key="i" class="fc-quote__dot" :class="{ 'fc-quote__dot--active': i === active }" @click="active = i" />
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
const active = ref(0)
const testimonials = [
  {
    quote: 'If I was to ballpark it, DomendraFleet saves us $15,000 to $20,000 a year. Vehicles go out of here, they are dependable, they are reliable, and we do not have those extra non-essential costs coming back to us.',
    name: 'Dennis Winter', company: 'A&D Environmental', initials: 'DW',
    gradient: 'linear-gradient(135deg, #6366f1, #4f46e5)',
  },
  {
    quote: 'We reduced time spent on inspections by 70%. The mobile DVIR with photo capture means our drivers submit compliant forms every single time — no more paperwork delays.',
    name: 'Sarah Mitchell', company: 'Stanley Steemer', initials: 'SM',
    gradient: 'linear-gradient(135deg, #8b5cf6, #6366f1)',
  },
  {
    quote: 'The dashboards give us a level of visibility we never had before. We can see utilization, costs, and maintenance status across all locations in real time — it is a game changer.',
    name: 'Robert Chen', company: 'Newkirk Electric', initials: 'RC',
    gradient: 'linear-gradient(135deg, #0891b2, #06b6d4)',
  },
]

let timer: any = null
const { register } = useScrollReveal()
onMounted(() => {
  register('.reveal')
  timer = setInterval(() => { active.value = (active.value + 1) % testimonials.length }, 6000)
})
onUnmounted(() => { if (timer) clearInterval(timer) })
</script>

<style scoped>
.fc-quote { background: linear-gradient(180deg, #f8fafc, #fff); padding: 80px 0; }
.fc-quote__inner { max-width: 860px; margin: 0 auto; padding: 0 24px; text-align: center; }
.fc-quote__mark { margin-bottom: 8px; }
.fc-quote__inner blockquote {
  font-size: clamp(20px, 2.4vw, 28px); line-height: 1.5; font-weight: 600; color: #0f172a; margin: 0 0 28px; letter-spacing: -0.01em;
}
.fc-quote__by { display: inline-flex; align-items: center; gap: 14px; }
.fc-quote__avatar { width: 48px; height: 48px; border-radius: 50%; color: #fff; display: flex; align-items: center; justify-content: center; font-weight: 700; }
.fc-quote__name { font-weight: 700; color: #0f172a; margin: 0; } .fc-quote__company { color: #64748b; font-size: 14px; margin: 0; }
.fc-quote__dots { display: flex; justify-content: center; gap: 8px; margin-top: 32px; }
.fc-quote__dot { width: 8px; height: 8px; border-radius: 50%; border: none; background: #cbd5e1; cursor: pointer; transition: all .2s ease; }
.fc-quote__dot--active { width: 28px; border-radius: 999px; background: linear-gradient(90deg, #6366f1, #8b5cf6); }
.fc-quote-fade-enter-active, .fc-quote-fade-leave-active { transition: opacity .3s ease; }
.fc-quote-fade-enter-from, .fc-quote-fade-leave-to { opacity: 0; }
</style>
