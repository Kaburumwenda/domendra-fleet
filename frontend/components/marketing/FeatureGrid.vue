<template>
  <section class="fc-features">
    <div class="fc-section__head">
      <SectionEyebrow text="Everything you need" icon="mdi-view-grid-outline" />
      <h2>The modern way to<br>manage your fleet</h2>
      <p>Everything you need to manage vehicles, maintenance, compliance and spend — with practical intelligence built into the workflows your team uses every day.</p>
    </div>
    <div class="fc-features__grid">
      <NuxtLink v-for="f in features" :key="f.title" :to="f.path" class="fc-feature">
        <span class="fc-feature__icon" :style="{ background: f.bg, color: f.color }"><v-icon size="22">{{ f.icon }}</v-icon></span>
        <h3>{{ f.title }}</h3>
        <p>{{ f.desc }}</p>
        <span class="fc-feature__link">Explore <v-icon size="14">mdi-arrow-right</v-icon></span>
      </NuxtLink>
    </div>
  </section>
</template>

<script setup lang="ts">
const features = [
  { title: 'Track fleet spend', desc: 'Total cost of ownership per asset with real-time reporting.', icon: 'mdi-cash-multiple', bg: '#ecfdf5', color: '#16a34a', path: '/features/reports' },
  { title: 'Stick to PM schedules', desc: 'Automated preventive maintenance by time, mileage or hours.', icon: 'mdi-calendar-clock', bg: '#eef2ff', color: '#4f46e5', path: '/features/preventive-maintenance' },
  { title: 'Never miss inspections', desc: 'Mobile-first DVIR with offline mode and photo capture.', icon: 'mdi-clipboard-check-outline', bg: '#eff6ff', color: '#2563eb', path: '/features/inspections' },
  { title: 'Automate workflows', desc: 'Convert reminders into work orders and escalate automatically.', icon: 'mdi-robot', bg: '#fef2f2', color: '#dc2626', path: '/features/work-orders' },
  { title: 'Enhance visibility', desc: 'Dashboards that show your whole operation at a glance.', icon: 'mdi-view-dashboard-outline', bg: '#ecfeff', color: '#0891b2', path: '/features/dashboards' },
  { title: 'Receive relevant alerts', desc: 'Smart notifications for issues, expirations and stockouts.', icon: 'mdi-bell-alert', bg: '#fff7ed', color: '#ea580c', path: '/features/work-orders' },
  { title: 'Get AI-powered insights', desc: 'Service Advisor flags exceptions and keeps approvals on track.', icon: 'mdi-brain', bg: '#faf5ff', color: '#9333ea', path: '/solutions/intelligence' },
  { title: 'Act on asset data', desc: 'VIN decoding, depreciation and lifecycle estimates.', icon: 'mdi-database-search', bg: '#fffbeb', color: '#d97706', path: '/features/preventive-maintenance' },
]
</script>

<style scoped>
.fc-features { max-width: 1240px; margin: 0 auto; padding: 24px 24px 80px; }
.fc-section__head { text-align: center; max-width: 680px; margin: 0 auto 48px; }
.fc-section__head h2 { font-size: clamp(28px, 3.5vw, 42px); font-weight: 800; letter-spacing: -0.02em; color: #0f172a; margin: 16px 0 14px; }
.fc-section__head p { font-size: 16px; line-height: 1.6; color: #64748b; }

.fc-features__grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 18px; }
.fc-feature {
  display: flex; flex-direction: column; gap: 10px;
  padding: 28px 24px; border-radius: 18px; text-decoration: none;
  background: #fff; border: 1px solid #eef2f7;
  transition: all .25s cubic-bezier(.4,0,.2,1);
  position: relative; overflow: hidden;
}
.fc-feature::before { content: ''; position: absolute; inset: 0; background: linear-gradient(135deg, rgba(99,102,241,.03), transparent 50%); opacity: 0; transition: opacity .25s ease; }
.fc-feature:hover { border-color: #c7d2fe; box-shadow: 0 20px 48px rgba(79, 70, 229, .12); transform: translateY(-4px); }
.fc-feature:hover::before { opacity: 1; }
.fc-feature__icon { width: 48px; height: 48px; border-radius: 14px; display: flex; align-items: center; justify-content: center; margin-bottom: 4px; transition: transform .25s ease; position: relative; z-index: 1; }
.fc-feature:hover .fc-feature__icon { transform: scale(1.08) rotate(-3deg); }
.fc-feature h3 { font-size: 16.5px; font-weight: 700; color: #0f172a; margin: 0; position: relative; z-index: 1; }
.fc-feature p { font-size: 14px; line-height: 1.55; color: #64748b; margin: 0; flex: 1; position: relative; z-index: 1; }
.fc-feature__link { font-size: 13px; font-weight: 600; color: #4f46e5; display: inline-flex; align-items: center; gap: 4px; margin-top: 4px; transition: gap .15s ease; position: relative; z-index: 1; }
.fc-feature:hover .fc-feature__link { gap: 8px; }

@media (max-width: 1024px) { .fc-features__grid { grid-template-columns: repeat(2, 1fr); } }
@media (max-width: 600px) { .fc-features__grid { grid-template-columns: 1fr; } }
</style>
