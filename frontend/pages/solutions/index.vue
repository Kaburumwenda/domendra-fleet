<template>
  <div>
    <PageHero eyebrow="Solutions" icon="mdi-shield-star-outline" title="Solutions for every fleet challenge" subtitle="From maintenance to fuel, tools, multi-location management and AI intelligence." :cta="true" />
    <section class="fc-sol">
      <div class="fc-sol__grid">
        <NuxtLink v-for="s in solutions" :key="s.path" :to="s.path" class="fc-sol__card">
          <span class="fc-sol__icon" :style="{ background: s.bg, color: s.color }"><v-icon size="24">{{ s.icon }}</v-icon></span>
          <h3>{{ s.title }}</h3>
          <p>{{ s.desc }}</p>
          <span class="fc-sol__link">Learn more <v-icon size="14">mdi-arrow-right</v-icon></span>
        </NuxtLink>
      </div>
    </section>
    <CtaBand />
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'marketing' })
useHead({ title: 'Solutions' })
const solutions = [
  { title: 'Fleet Management', desc: 'Know every detail about your vehicles.', icon: 'mdi-car-multiple', bg: '#eef2ff', color: '#4f46e5', path: '/solutions/fleet-management' },
  { title: 'Fleet Maintenance', desc: 'Stay on top of routines and repairs.', icon: 'mdi-wrench', bg: '#f0fdf4', color: '#16a34a', path: '/solutions/fleet-maintenance' },
  { title: 'Fuel Management', desc: 'Collect fuel data and control costs.', icon: 'mdi-gas-station', bg: '#fff7ed', color: '#ea580c', path: '/solutions/fuel-management' },
  { title: 'Tool Management', desc: 'Track equipment alongside your vehicles.', icon: 'mdi-toolbox', bg: '#faf5ff', color: '#9333ea', path: '/solutions/tool-management' },
  { title: 'Multi-Location', desc: 'Manage your fleet across locations.', icon: 'mdi-map-marker-multiple', bg: '#ecfeff', color: '#0891b2', path: '/solutions/multi-location' },
  { title: 'Intelligence', desc: 'Spend less time on repetitive tasks.', icon: 'mdi-brain', bg: '#fef2f2', color: '#dc2626', path: '/solutions/intelligence' },
]
</script>

<style scoped>
.fc-sol { max-width: 1240px; margin: 0 auto; padding: 0 24px 64px; }
.fc-sol__grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; }
.fc-sol__card { display: flex; flex-direction: column; gap: 10px; padding: 28px 24px; border-radius: 18px; background: #fff; border: 1px solid #eef2f7; text-decoration: none; transition: all .2s ease; }
.fc-sol__card:hover { border-color: #c7d2fe; box-shadow: 0 20px 44px rgba(79, 70, 229, .1); transform: translateY(-4px); }
.fc-sol__icon { width: 52px; height: 52px; border-radius: 14px; display: flex; align-items: center; justify-content: center; margin-bottom: 4px; }
.fc-sol__card h3 { font-size: 18px; font-weight: 700; color: #0f172a; margin: 0; }
.fc-sol__card p { font-size: 14.5px; line-height: 1.55; color: #64748b; margin: 0; flex: 1; }
.fc-sol__link { font-size: 13px; font-weight: 600; color: #4f46e5; display: inline-flex; align-items: center; gap: 4px; }
@media (max-width: 900px) { .fc-sol__grid { grid-template-columns: 1fr 1fr; } }
@media (max-width: 540px) { .fc-sol__grid { grid-template-columns: 1fr; } }
</style>
