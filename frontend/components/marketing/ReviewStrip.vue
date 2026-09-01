<template>
  <section class="fc-rev">
    <div class="fc-rev__inner">
      <SectionEyebrow text="Top-rated everywhere" icon="mdi-star-outline" />
      <h2>Top choices on G2, Capterra and beyond</h2>
      <p class="fc-rev__sub">4.8/5 based on &gt;1,000 reviews</p>
      <div class="fc-rev__grid">
        <div v-for="r in reviews" :key="r.name" class="fc-rev__card">
          <p class="fc-rev__score">{{ r.score }}</p>
          <p class="fc-rev__name">{{ r.name }}</p>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
const reviews = [
  { name: 'Capterra', score: '4.8/5' },
  { name: 'Forbes Advisor', score: 'Top 10' },
  { name: 'Software Advice', score: '4.8/5' },
  { name: 'G2', score: '4.5/5' },
  { name: 'Software Reviews', score: '8.7/10' },
  { name: 'GetApp', score: '4.8/5' },
]
</script>

<style scoped>
.fc-rev { padding: 72px 0; background: linear-gradient(180deg, #fff, #f8fafc); }
.fc-rev__inner { max-width: 1240px; margin: 0 auto; padding: 0 24px; text-align: center; }
.fc-rev__inner h2 { font-size: clamp(26px, 3vw, 36px); font-weight: 800; letter-spacing: -0.02em; color: #0f172a; margin: 16px 0 6px; }
.fc-rev__sub { color: #64748b; margin-bottom: 40px; }
.fc-rev__grid { display: grid; grid-template-columns: repeat(6, 1fr); gap: 16px; }
.fc-rev__card { padding: 28px 16px; border: 1px solid #eef2f7; border-radius: 16px; transition: all .25s ease; background: #fff; }
.fc-rev__card:hover { border-color: #c7d2fe; box-shadow: 0 12px 32px rgba(79, 70, 229, .08); transform: translateY(-3px); }
.fc-rev__score { font-size: 26px; font-weight: 800; color: #4f46e5; margin-bottom: 6px; }
.fc-rev__name { font-size: 13px; font-weight: 600; color: #64748b; }
@media (max-width: 900px) { .fc-rev__grid { grid-template-columns: repeat(3, 1fr); } }
@media (max-width: 480px) { .fc-rev__grid { grid-template-columns: repeat(2, 1fr); } }
</style>
