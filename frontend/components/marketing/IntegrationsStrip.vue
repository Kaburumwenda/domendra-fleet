<template>
  <section class="fc-int">
    <div class="fc-int__inner">
      <SectionEyebrow text="Works with your stack" icon="mdi-link-variant" class="reveal" data-reveal-type="fade" />
      <h2 class="reveal" data-reveal-type="fade" data-reveal-delay="60">Connect everything. Sync automatically.</h2>
      <p class="fc-int__sub reveal" data-reveal-type="fade" data-reveal-delay="120">Domendra integrates with the tools your fleet already uses — from telematics providers to accounting software — so your data flows seamlessly without manual entry.</p>

      <div class="fc-int__grid">
        <div
          v-for="(int, i) in integrations"
          :key="int.name"
          class="fc-int__item reveal"
          :data-reveal-delay="i * 60"
          :data-reveal-type="i % 2 ? 'right' : 'left'"
        >
          <div class="fc-int__icon" :style="{ background: int.bg, color: int.color }">
            <v-icon size="24">{{ int.icon }}</v-icon>
          </div>
          <div class="fc-int__info">
            <p class="fc-int__name">{{ int.name }}</p>
            <p class="fc-int__cat">{{ int.category }}</p>
          </div>
          <span class="fc-int__badge"><span class="fc-int__badge-dot" />Connected</span>
        </div>
      </div>

      <div class="fc-int__bottom">
        <p>Plus 50+ more integrations including custom API webhooks</p>
        <NuxtLink to="/contact" class="fc-int__link">See all integrations <v-icon size="16">mdi-arrow-right</v-icon></NuxtLink>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
const { register } = useScrollReveal()
onMounted(() => register('.reveal'))

const integrations = [
  { name: 'Geotab', category: 'Telematics', icon: 'mdi-map-marker', bg: '#eef2ff', color: '#4f46e5' },
  { name: 'Samsara', category: 'Telematics', icon: 'mdi-truck', bg: '#f0fdf4', color: '#16a34a' },
  { name: 'QuickBooks', category: 'Accounting', icon: 'mdi-calculator', bg: '#ecfeff', color: '#0891b2' },
  { name: 'Stripe', category: 'Payments', icon: 'mdi-credit-card', bg: '#fef2f2', color: '#dc2626' },
  { name: 'Twilio', category: 'Notifications', icon: 'mdi-message-text', bg: '#fff7ed', color: '#ea580c' },
  { name: 'AWS S3', category: 'Storage', icon: 'mdi-cloud-upload', bg: '#faf5ff', color: '#9333ea' },
  { name: 'Google Maps', category: 'Routing', icon: 'mdi-google-maps', bg: '#eff6ff', color: '#2563eb' },
  { name: 'Zapier', category: 'Automation', icon: 'mdi-flash', bg: '#fffbeb', color: '#d97706' },
  { name: 'Slack', category: 'Alerts', icon: 'mdi-slack', bg: '#fee2e2', color: '#e11d48' },
  { name: 'Microsoft 365', category: 'Productivity', icon: 'mdi-microsoft-office', bg: '#dbeafe', color: '#2563eb' },
  { name: 'Samsara DVIR', category: 'Inspections', icon: 'mdi-clipboard-check', bg: '#dcfce7', color: '#16a34a' },
  { name: 'IFTA', category: 'Compliance', icon: 'mdi-file-document', bg: '#cffafe', color: '#0891b2' },
]
</script>

<style scoped>
.fc-int { background: linear-gradient(180deg, #fff, #f8fafc); padding: 80px 0; }
.fc-int__inner { max-width: 1100px; margin: 0 auto; padding: 0 24px; text-align: center; }
.fc-int__inner h2 { font-size: clamp(28px, 3.5vw, 42px); font-weight: 800; letter-spacing: -0.02em; color: #0f172a; margin: 16px 0 14px; }
.fc-int__sub { font-size: 16px; line-height: 1.6; color: #64748b; max-width: 640px; margin: 0 auto 48px; }

.fc-int__grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 14px; }
.fc-int__item {
  display: flex; align-items: center; gap: 12px;
  padding: 18px 16px; border-radius: 16px;
  background: #fff; border: 1px solid #eef2f7;
  transition: all .2s ease; text-align: left;
  position: relative;
}
.fc-int__item:hover { border-color: #c7d2fe; box-shadow: 0 12px 28px rgba(79, 70, 229, .08); transform: translateY(-2px); }
.fc-int__icon { width: 44px; height: 44px; border-radius: 12px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.fc-int__info { flex: 1; min-width: 0; }
.fc-int__name { font-size: 14px; font-weight: 700; color: #0f172a; margin: 0; }
.fc-int__cat { font-size: 12px; color: #94a3b8; margin: 2px 0 0; }
.fc-int__badge { display: flex; align-items: center; gap: 4px; font-size: 10px; font-weight: 700; color: #16a34a; flex-shrink: 0; }
.fc-int__badge-dot { width: 6px; height: 6px; border-radius: 50%; background: #22c55e; }

.fc-int__bottom { margin-top: 40px; display: flex; flex-direction: column; align-items: center; gap: 12px; }
.fc-int__bottom p { font-size: 15px; color: #64748b; }
.fc-int__link { display: inline-flex; align-items: center; gap: 4px; font-size: 15px; font-weight: 600; color: #4f46e5; text-decoration: none; transition: gap .15s ease; }
.fc-int__link:hover { gap: 8px; }

@media (max-width: 900px) { .fc-int__grid { grid-template-columns: repeat(2, 1fr); } }
@media (max-width: 500px) { .fc-int__grid { grid-template-columns: 1fr; } }
</style>
