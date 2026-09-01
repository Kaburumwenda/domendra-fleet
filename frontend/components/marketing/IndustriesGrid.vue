<template>
  <section class="fc-ind">
    <div class="fc-section__head">
      <SectionEyebrow text="Any industry, any size" icon="mdi-domain" />
      <h2>Built for fleets of every kind</h2>
      <p>From a handful of trucks to thousands of assets across multiple locations — Domendra scales with you.</p>
    </div>
    <div class="fc-ind__grid">
      <NuxtLink v-for="ind in industries" :key="ind.title" :to="ind.path" class="fc-ind__card">
        <span class="fc-ind__icon" :style="{ background: ind.bg, color: ind.color }"><v-icon size="26">{{ ind.icon }}</v-icon></span>
        <h3>{{ ind.title }}</h3>
        <p>{{ ind.desc }}</p>
        <span class="fc-ind__link">Learn more <v-icon size="14">mdi-arrow-right</v-icon></span>
      </NuxtLink>
    </div>
  </section>
</template>

<script setup lang="ts">
const industries = [
  { title: 'Service Providers', desc: 'Maximize fleet uptime and guarantee reliability.', icon: 'mdi-account-tie', bg: '#eef2ff', color: '#4f46e5', path: '/industries/service-providers' },
  { title: 'Construction', desc: 'Stay on time and on budget for every job.', icon: 'mdi-hard-hat', bg: '#fff7ed', color: '#ea580c', path: '/industries/construction' },
  { title: 'Trucking & Freight', desc: 'Integrate with ELD and improve efficiency.', icon: 'mdi-truck-fast', bg: '#f0fdf4', color: '#16a34a', path: '/industries/transportation' },
  { title: 'Government', desc: 'Improve compliance and reduce operating expenses.', icon: 'mdi-domain', bg: '#ecfeff', color: '#0891b2', path: '/industries/government' },
]
</script>

<style scoped>
.fc-ind { max-width: 1240px; margin: 0 auto; padding: 24px 24px 80px; }
.fc-section__head { text-align: center; max-width: 680px; margin: 0 auto 44px; }
.fc-section__head h2 { font-size: clamp(28px, 3.5vw, 42px); font-weight: 800; letter-spacing: -0.02em; color: #0f172a; margin: 16px 0 14px; }
.fc-section__head p { font-size: 16px; line-height: 1.6; color: #64748b; }
.fc-ind__grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; }
.fc-ind__card { display: flex; flex-direction: column; gap: 10px; padding: 30px 26px; border-radius: 18px; background: #fff; border: 1px solid #eef2f7; text-decoration: none; transition: all .25s cubic-bezier(.4,0,.2,1); position: relative; overflow: hidden; }
.fc-ind__card::before { content: ''; position: absolute; top: 0; left: 0; right: 0; height: 3px; background: linear-gradient(90deg, #6366f1, #8b5cf6); transform: scaleX(0); transform-origin: left; transition: transform .25s ease; }
.fc-ind__card:hover { border-color: #c7d2fe; box-shadow: 0 20px 48px rgba(79, 70, 229, .12); transform: translateY(-4px); }
.fc-ind__card:hover::before { transform: scaleX(1); }
.fc-ind__icon { width: 56px; height: 56px; border-radius: 16px; display: flex; align-items: center; justify-content: center; margin-bottom: 6px; transition: transform .25s ease; }
.fc-ind__card:hover .fc-ind__icon { transform: scale(1.08); }
.fc-ind__card h3 { font-size: 18px; font-weight: 700; color: #0f172a; margin: 0; }
.fc-ind__card p { font-size: 14px; line-height: 1.55; color: #64748b; margin: 0; flex: 1; }
.fc-ind__link { font-size: 13px; font-weight: 600; color: #4f46e5; display: inline-flex; align-items: center; gap: 4px; transition: gap .15s ease; }
.fc-ind__card:hover .fc-ind__link { gap: 8px; }
@media (max-width: 900px) { .fc-ind__grid { grid-template-columns: repeat(2, 1fr); } }
@media (max-width: 540px) { .fc-ind__grid { grid-template-columns: 1fr; } }
</style>
