<template>
  <section class="fc-cmp">
    <div class="fc-cmp__inner">
      <div class="reveal" data-reveal-type="fade">
        <SectionEyebrow text="Why switch" icon="mdi-scale-balance" />
        <h2>See the Domendra difference</h2>
        <p class="fc-cmp__sub">Stop juggling spreadsheets, bloated legacy systems, and disconnected tools. Domendra brings it all together — beautifully.</p>
      </div>

      <div class="fc-cmp__table-wrap reveal" data-reveal-type="scale" data-reveal-delay="100">
        <table class="fc-cmp__table">
          <thead>
            <tr>
              <th class="fc-cmp__feature">Feature</th>
              <th class="fc-cmp__brand">
                <div class="fc-cmp__brand-tag">
                  <img src="/logo.png" alt="Domendra" class="fc-cmp__brand-logo" />
                  <span>Domendra</span>
                </div>
              </th>
              <th class="fc-cmp__other">Spreadsheets</th>
              <th class="fc-cmp__other">Legacy Software</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in rows" :key="row.label">
              <td class="fc-cmp__feature">{{ row.label }}</td>
              <td class="fc-cmp__cell fc-cmp__cell--best"><v-icon size="20" color="#16a34a">mdi-check-circle</v-icon></td>
              <td class="fc-cmp__cell"><v-icon v-if="row.sheets === true" size="20" color="#94a3b8">mdi-check</v-icon><v-icon v-else size="20" color="#cbd5e1">mdi-close</v-icon><span v-if="row.sheetsText" class="fc-cmp__note">{{ row.sheetsText }}</span></td>
              <td class="fc-cmp__cell"><v-icon v-if="row.legacy === true" size="20" color="#94a3b8">mdi-check</v-icon><v-icon v-else size="20" color="#cbd5e1">mdi-close</v-icon><span v-if="row.legacyText" class="fc-cmp__note">{{ row.legacyText }}</span></td>
            </tr>
          </tbody>
          <tfoot>
            <tr>
              <td></td>
              <td class="fc-cmp__cell"><NuxtLink to="/register" class="fc-cmp__btn">Start free</NuxtLink></td>
              <td class="fc-cmp__cell"><span class="fc-cmp__muted">Free</span></td>
              <td class="fc-cmp__cell"><span class="fc-cmp__muted">Quote-based</span></td>
            </tr>
          </tfoot>
        </table>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
const { register } = useScrollReveal()
onMounted(() => register('.reveal'))

const rows = [
  { label: 'Real-time dashboards', sheets: false, legacy: true },
  { label: 'Automated PM schedules', sheets: false, sheetsText: 'Manual', legacy: true },
  { label: 'Mobile DVIR with photos', sheets: false, legacy: false },
  { label: 'Parts & inventory tracking', sheets: true, legacy: true },
  { label: 'Fuel & cost analytics', sheets: false, legacy: true },
  { label: 'AI-powered insights', sheets: false, legacy: false },
  { label: 'VIN decoding & lifecycle', sheets: false, legacy: false },
  { label: 'Multi-location management', sheets: false, legacy: true, legacyText: 'Linear', legacyText2: 'Add-ons' },
  { label: 'Audit logging & RBAC', sheets: false, legacy: true },
  { label: 'Open REST API & webhooks', sheets: false, legacy: false },
  { label: '14-day free trial, no card', sheets: true, legacy: false },
  { label: 'Setup in under 1 hour', sheets: true, legacy: false },
]
</script>

<style scoped>
.fc-cmp { padding: 80px 0; background: #fff; }
.fc-cmp__inner { max-width: 1100px; margin: 0 auto; padding: 0 24px; text-align: center; }
.fc-cmp__inner h2 { font-size: clamp(28px, 3.5vw, 42px); font-weight: 800; letter-spacing: -0.02em; color: #0f172a; margin: 16px 0 14px; }
.fc-cmp__sub { font-size: 16px; line-height: 1.6; color: #64748b; max-width: 620px; margin: 0 auto 48px; }

.fc-cmp__table-wrap { overflow-x: auto; border-radius: 20px; border: 1px solid #eef2f7; }
.fc-cmp__table { width: 100%; border-collapse: collapse; min-width: 680px; }
.fc-cmp__table th, .fc-cmp__table td { padding: 18px 24px; border-bottom: 1px solid #eef2f7; }
.fc-cmp__table thead th { background: #f8fafc; font-size: 14px; font-weight: 700; color: #0f172a; }
.fc-cmp__table tbody tr:hover { background: #fcfcfd; }

.fc-cmp__feature { text-align: left; font-size: 15px; font-weight: 600; color: #334155; }
.fc-cmp__brand { width: 160px; }
.fc-cmp__brand-tag { display: flex; align-items: center; gap: 8px; justify-content: center; }
.fc-cmp__brand-logo { width: 26px; height: 26px; border-radius: 6px; object-fit: contain; }
.fc-cmp__brand-tag span { font-weight: 800; color: #4f46e5; }
.fc-cmp__other { width: 160px; font-weight: 600; color: #94a3b8; }
.fc-cmp__cell { text-align: center; }
.fc-cmp__cell--best { background: rgba(99, 102, 241, .03); }
.fc-cmp__note { display: block; font-size: 11px; color: #cbd5e1; margin-top: 2px; }
.fc-cmp__btn {
  display: inline-block; padding: 10px 24px; border-radius: 10px;
  background: linear-gradient(135deg, #6366f1, #4f46e5); color: #fff;
  font-size: 14px; font-weight: 600; text-decoration: none;
  box-shadow: 0 6px 20px rgba(79, 70, 229, .25); transition: all .2s ease;
}
.fc-cmp__btn:hover { transform: translateY(-2px); box-shadow: 0 10px 28px rgba(79, 70, 229, .35); }
.fc-cmp__muted { font-size: 13px; color: #94a3b8; }
.fc-cmp__table tfoot td { border-bottom: none; padding-top: 24px; }

@media (max-width: 760px) {
  .fc-cmp__table th, .fc-cmp__table td { padding: 14px 16px; }
  .fc-cmp__feature { font-size: 14px; }
}
</style>
