<template>
  <footer class="fc-foot">
    <div class="fc-foot__top">
      <div class="fc-foot__brand">
        <NuxtLink to="/" class="fc-brand">
          <img src="/logo.png" alt="DomendraFleet" class="fc-brand__logo-img" />
          <span class="fc-brand__name">DomendraFleet</span>
        </NuxtLink>
        <p class="fc-foot__tagline">The modern way to manage your fleet. Track vehicles, maintenance, fuel, drivers and costs — all in one premium platform.</p>
        <div class="fc-foot__contact">
          <a href="mailto:domendrafleet@tiktek-ex.com" class="fc-foot__contact-link"><v-icon size="16">mdi-email-outline</v-icon> domendrafleet@tiktek-ex.com</a>
          <a href="tel:+254739123995" class="fc-foot__contact-link"><v-icon size="16">mdi-phone-outline</v-icon> +254 739 123 995</a>
        </div>
        <div class="fc-foot__stores">
          <a href="#" class="fc-store"><v-icon size="20">mdi-apple</v-icon><span><small>Download on the</small><b>App Store</b></span></a>
          <a href="#" class="fc-store"><v-icon size="20">mdi-google-play</v-icon><span><small>Get it on</small><b>Google Play</b></span></a>
        </div>
      </div>

      <div class="fc-foot__cols">
        <div v-for="col in columns" :key="col.title" class="fc-foot__col">
          <h4>{{ col.title }}</h4>
          <NuxtLink v-for="l in col.links" :key="l.path" :to="l.path">{{ l.label }}</NuxtLink>
        </div>
      </div>
    </div>

    <div class="fc-foot__bar">
      <p class="fc-foot__copy">© {{ year }} DomendraFleet, Inc. · Fleet Management & Maintenance Software</p>
      <div class="fc-foot__legal">
        <NuxtLink to="/legal/privacy">Privacy</NuxtLink>
        <NuxtLink to="/legal/terms">Terms</NuxtLink>
        <a href="#" class="fc-foot__social"><v-icon size="18">mdi-linkedin</v-icon></a>
        <a href="#" class="fc-foot__social"><v-icon size="18">mdi-twitter</v-icon></a>
        <a href="#" class="fc-foot__social"><v-icon size="18">mdi-youtube</v-icon></a>
      </div>
    </div>
  </footer>
</template>

<script setup lang="ts">
const year = new Date().getFullYear()
const columns = [
  {
    title: 'Solutions',
    links: [
      { label: 'Fleet Management', path: '/solutions/fleet-management' },
      { label: 'Fleet Maintenance', path: '/solutions/fleet-maintenance' },
      { label: 'Fuel Management', path: '/solutions/fuel-management' },
      { label: 'Tool Management', path: '/solutions/tool-management' },
      { label: 'Intelligence', path: '/solutions/intelligence' },
    ],
  },
  {
    title: 'Features',
    links: [
      { label: 'Inspections', path: '/features/inspections' },
      { label: 'Work Orders', path: '/features/work-orders' },
      { label: 'Parts Inventory', path: '/features/parts-inventory' },
      { label: 'Preventive Maintenance', path: '/features/preventive-maintenance' },
      { label: 'Reports & Dashboards', path: '/features/reports' },
    ],
  },
  {
    title: 'Industries',
    links: [
      { label: 'Construction', path: '/industries/construction' },
      { label: 'Service Providers', path: '/industries/service-providers' },
      { label: 'Transportation', path: '/industries/transportation' },
      { label: 'Government', path: '/industries/government' },
    ],
  },
  {
    title: 'Company',
    links: [
      { label: 'Pricing', path: '/pricing' },
      { label: 'Contact', path: '/contact' },
      { label: 'Log in', path: '/login' },
      { label: 'Start free trial', path: '/register' },
    ],
  },
]
</script>

<style scoped>
.fc-foot { background: #0b1120; color: #cbd5e1; margin-top: 0; position: relative; overflow: hidden; }
.fc-foot::before { content: ''; position: absolute; top: 0; left: 0; right: 0; height: 1px; background: linear-gradient(90deg, transparent, rgba(99,102,241,.3), transparent); }
.fc-foot__top {
  max-width: 1240px; margin: 0 auto; padding: 72px 24px 48px;
  display: grid; grid-template-columns: 1.2fr 2fr; gap: 56px;
}
.fc-brand { display: flex; align-items: center; gap: 10px; text-decoration: none; }
.fc-brand__logo-img { width: 36px; height: 36px; border-radius: 10px; object-fit: contain; background: rgba(255,255,255,0.95); padding: 2px; }
.fc-brand__name { font-size: 20px; font-weight: 800; color: #fff; letter-spacing: -0.02em; }
.fc-foot__tagline { margin: 18px 0 24px; font-size: 14px; line-height: 1.6; color: #94a3b8; max-width: 340px; }
.fc-foot__contact { display: flex; flex-direction: column; gap: 8px; margin-bottom: 24px; }
.fc-foot__contact-link { display: inline-flex; align-items: center; gap: 6px; color: #94a3b8; font-size: 13.5px; text-decoration: none; transition: color .15s ease; }
.fc-foot__contact-link:hover { color: #fff; }
.fc-foot__stores { display: flex; gap: 10px; flex-wrap: wrap; }
.fc-store { display: flex; align-items: center; gap: 8px; padding: 10px 16px; border-radius: 12px; border: 1px solid #1e293b; text-decoration: none; color: #cbd5e1; transition: all .15s ease; }
.fc-store:hover { border-color: #475569; background: #0f172a; transform: translateY(-1px); }
.fc-store span { display: flex; flex-direction: column; line-height: 1.1; }
.fc-store small { font-size: 10px; color: #94a3b8; }
.fc-store b { font-size: 13px; color: #fff; }

.fc-foot__cols { display: grid; grid-template-columns: repeat(4, 1fr); gap: 32px; }
.fc-foot__col { display: flex; flex-direction: column; gap: 12px; }
.fc-foot__col h4 { color: #fff; font-size: 14px; font-weight: 700; margin: 0 0 4px; }
.fc-foot__col a { color: #94a3b8; font-size: 13.5px; text-decoration: none; transition: color .15s ease, transform .15s ease; }
.fc-foot__col a:hover { color: #fff; transform: translateX(2px); }

.fc-foot__bar { border-top: 1px solid #1e293b; }
.fc-foot__bar {
  max-width: 1240px; margin: 0 auto; padding: 20px 24px;
  display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 16px;
}
.fc-foot__copy { font-size: 13px; color: #64748b; }
.fc-foot__legal { display: flex; align-items: center; gap: 20px; }
.fc-foot__legal a { color: #94a3b8; font-size: 13px; text-decoration: none; transition: color .15s ease; }
.fc-foot__legal a:hover { color: #fff; }
.fc-foot__social { display: inline-flex !important; width: 36px; height: 36px; align-items: center; justify-content: center; border-radius: 10px; border: 1px solid #1e293b; transition: all .15s ease; }
.fc-foot__social:hover { border-color: #475569; background: #0f172a; color: #fff; }

@media (max-width: 900px) {
  .fc-foot__top { grid-template-columns: 1fr; gap: 36px; }
  .fc-foot__cols { grid-template-columns: repeat(2, 1fr); gap: 28px; }
}
</style>
