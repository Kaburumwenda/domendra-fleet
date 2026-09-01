<template>
  <div>
    <PageHero :eyebrow="data.eyebrow" :icon="data.icon" :title="data.title" :subtitle="data.subtitle" :cta="true" />
    <section class="fc-detail">
      <div class="fc-detail__grid">
        <div v-for="s in data.sections" :key="s.title" class="fc-detail__card">
          <span class="fc-detail__icon" :style="{ background: s.bg, color: s.color }"><v-icon size="22">{{ s.icon }}</v-icon></span>
          <h3>{{ s.title }}</h3>
          <p>{{ s.desc }}</p>
        </div>
      </div>
    </section>
    <CtaBand />
  </div>
</template>

<script setup lang="ts">
defineProps<{ data: { eyebrow: string; title: string; subtitle: string; icon: string; sections: { title: string; desc: string; icon: string; bg: string; color: string }[] } }>()
definePageMeta({ layout: 'marketing' })
</script>

<style scoped>
.fc-detail { max-width: 1240px; margin: 0 auto; padding: 0 24px 64px; }
.fc-detail__grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; }
.fc-detail__card { padding: 28px 24px; border-radius: 18px; background: #fff; border: 1px solid #eef2f7; transition: all .2s ease; }
.fc-detail__card:hover { box-shadow: 0 16px 36px rgba(15, 23, 42, .08); transform: translateY(-3px); }
.fc-detail__icon { width: 48px; height: 48px; border-radius: 14px; display: flex; align-items: center; justify-content: center; margin-bottom: 16px; }
.fc-detail__card h3 { font-size: 17px; font-weight: 700; color: #0f172a; margin: 0 0 8px; }
.fc-detail__card p { font-size: 14.5px; line-height: 1.55; color: #64748b; margin: 0; }
@media (max-width: 900px) { .fc-detail__grid { grid-template-columns: 1fr 1fr; } }
@media (max-width: 560px) { .fc-detail__grid { grid-template-columns: 1fr; } }
</style>
