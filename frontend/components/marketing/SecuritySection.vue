<template>
  <section class="fc-sec">
    <div class="fc-sec__bg">
      <div class="fc-sec__blob" />
    </div>
    <div class="fc-sec__inner">
      <div class="fc-sec__head">
        <SectionEyebrow text="Security & compliance" icon="mdi-shield-check" />
        <h2>Your data is safe with us</h2>
        <p>Enterprise-grade security baked into every layer — from schema-based isolation to full audit trails.</p>
      </div>

      <div class="fc-sec__grid">
        <div v-for="item in items" :key="item.title" class="fc-sec__card">
          <span class="fc-sec__icon" :style="{ background: item.bg, color: item.color }">
            <v-icon size="22">{{ item.icon }}</v-icon>
          </span>
          <h3>{{ item.title }}</h3>
          <p>{{ item.desc }}</p>
        </div>
      </div>

      <div class="fc-sec__badges">
        <div v-for="badge in badges" :key="badge" class="fc-sec__badge">
          <v-icon size="18" color="#16a34a">mdi-shield-check-outline</v-icon>
          <span>{{ badge }}</span>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
const items = [
  { title: 'Multi-tenant isolation', desc: 'Every tenant gets a dedicated PostgreSQL schema — your data is never shared.', icon: 'mdi-database-lock', bg: '#eef2ff', color: '#4f46e5' },
  { title: 'JWT authentication', desc: 'Stateless tokens with refresh rotation and device tracking for secure access.', icon: 'mdi-key-chain', bg: '#ecfeff', color: '#0891b2' },
  { title: 'Full audit logging', desc: 'Every action is logged with actor, timestamp, and before/after values.', icon: 'mdi-file-clock', bg: '#fff7ed', color: '#ea580c' },
  { title: 'TLS encryption', desc: 'All data in transit is encrypted with industry-standard TLS 1.3.', icon: 'mdi-lock', bg: '#f0fdf4', color: '#16a34a' },
]

const badges = ['SOC 2 Type II', 'GDPR Ready', 'ISO 27001 Path', 'Data residency options', '24/7 monitoring']
</script>

<style scoped>
.fc-sec { position: relative; overflow: hidden; background: linear-gradient(180deg, #0f172a, #1e293b); color: #fff; padding: 80px 0; }
.fc-sec__bg { position: absolute; inset: 0; z-index: 0; }
.fc-sec__blob { position: absolute; top: -100px; right: 10%; width: 360px; height: 360px; border-radius: 50%; background: rgba(99, 102, 241, .08); filter: blur(80px); }
.fc-sec__inner { position: relative; z-index: 1; max-width: 1240px; margin: 0 auto; padding: 0 24px; }
.fc-sec__head { text-align: center; max-width: 640px; margin: 0 auto 48px; }
.fc-sec__head :deep(.fc-eyebrow) { background: rgba(99, 102, 241, .15); color: #a5b4fc; }
.fc-sec__head h2 { font-size: clamp(28px, 3.5vw, 42px); font-weight: 800; letter-spacing: -0.02em; margin: 16px 0 14px; }
.fc-sec__head p { font-size: 16px; line-height: 1.6; color: #cbd5e1; }

.fc-sec__grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin-bottom: 48px; }
.fc-sec__card { padding: 28px 24px; border-radius: 18px; background: rgba(255, 255, 255, .03); border: 1px solid rgba(255, 255, 255, .06); transition: all .2s ease; }
.fc-sec__card:hover { background: rgba(255, 255, 255, .06); transform: translateY(-3px); border-color: rgba(99, 102, 241, .2); }
.fc-sec__icon { width: 48px; height: 48px; border-radius: 14px; display: flex; align-items: center; justify-content: center; margin-bottom: 16px; }
.fc-sec__card h3 { font-size: 17px; font-weight: 700; margin: 0 0 8px; color: #fff; }
.fc-sec__card p { font-size: 14px; line-height: 1.55; color: #94a3b8; margin: 0; }

.fc-sec__badges { display: flex; flex-wrap: wrap; justify-content: center; gap: 12px; }
.fc-sec__badge { display: flex; align-items: center; gap: 6px; font-size: 13px; font-weight: 600; color: #cbd5e1; padding: 10px 18px; border-radius: 999px; background: rgba(255, 255, 255, .04); border: 1px solid rgba(255, 255, 255, .08); }

@media (max-width: 900px) { .fc-sec__grid { grid-template-columns: repeat(2, 1fr); } }
@media (max-width: 560px) { .fc-sec__grid { grid-template-columns: 1fr; } }
</style>
