<template>
  <header
    class="fc-nav"
    :class="{ 'fc-nav--scrolled': scrolled }"
  >
    <div class="fc-nav__inner">
      <NuxtLink to="/" class="fc-brand">
        <img src="/logo.png" alt="DomendraFleet" class="fc-brand__logo-img" />
        <span class="fc-brand__name">DomendraFleet</span>
      </NuxtLink>

      <nav class="fc-nav__links">
        <div
          v-for="menu in menus"
          :key="menu.label"
          class="fc-mega"
          @mouseenter="activeMenu = menu.label"
          @mouseleave="activeMenu = ''"
        >
          <button class="fc-mega__trigger">
            {{ menu.label }}
            <v-icon size="14" class="fc-mega__chevron" :class="{ 'fc-mega__chevron--open': activeMenu === menu.label }">mdi-chevron-down</v-icon>
          </button>
          <transition name="fc-dropdown">
            <div v-if="activeMenu === menu.label" class="fc-mega__panel" :class="menu.columns ? 'fc-mega__panel--wide' : ''">
              <NuxtLink
                v-for="item in menu.items"
                :key="item.path"
                :to="item.path"
                class="fc-mega__item"
              >
                <span class="fc-mega__icon" :style="{ background: item.bg, color: item.color }"><v-icon size="18">{{ item.icon }}</v-icon></span>
                <span class="fc-mega__text">
                  <span class="fc-mega__title">{{ item.title }}</span>
                  <span v-if="item.desc" class="fc-mega__desc">{{ item.desc }}</span>
                </span>
              </NuxtLink>
            </div>
          </transition>
        </div>
        <NuxtLink to="/pricing" class="fc-nav__link">Pricing</NuxtLink>
        <NuxtLink to="/contact" class="fc-nav__link">Contact</NuxtLink>
      </nav>

      <div class="fc-nav__actions">
        <NuxtLink to="/login" class="fc-btn fc-btn--ghost">Log in</NuxtLink>
        <NuxtLink to="/register" class="fc-btn fc-btn--primary">Start free trial</NuxtLink>
        <button class="fc-nav__burger" @click="mobileOpen = !mobileOpen">
          <v-icon>{{ mobileOpen ? 'mdi-close' : 'mdi-menu' }}</v-icon>
        </button>
      </div>
    </div>

    <transition name="fc-slide">
      <div v-if="mobileOpen" class="fc-nav__mobile">
        <div v-for="menu in menus" :key="menu.label" class="fc-mobile__group">
          <p class="fc-mobile__label">{{ menu.label }}</p>
          <NuxtLink v-for="item in menu.items" :key="item.path" :to="item.path" class="fc-mobile__link" @click="mobileOpen = false">
            <v-icon size="18" :color="item.color">{{ item.icon }}</v-icon>
            {{ item.title }}
          </NuxtLink>
        </div>
        <div class="fc-mobile__group">
          <NuxtLink to="/pricing" class="fc-mobile__link" @click="mobileOpen = false"><v-icon size="18">mdi-tag-outline</v-icon> Pricing</NuxtLink>
          <NuxtLink to="/contact" class="fc-mobile__link" @click="mobileOpen = false"><v-icon size="18">mdi-email-outline</v-icon> Contact</NuxtLink>
        </div>
        <div class="fc-mobile__cta">
          <NuxtLink to="/login" class="fc-btn fc-btn--ghost fc-btn--block">Log in</NuxtLink>
          <NuxtLink to="/register" class="fc-btn fc-btn--primary fc-btn--block">Start free trial</NuxtLink>
        </div>
      </div>
    </transition>
  </header>
</template>

<script setup lang="ts">
const scrolled = ref(false)
const mobileOpen = ref(false)
const activeMenu = ref('')

const menus = [
  {
    label: 'Solutions',
    columns: true,
    items: [
      { path: '/solutions/fleet-management', title: 'Fleet Management', desc: 'Know every detail about your vehicles', icon: 'mdi-car-multiple', bg: '#eef2ff', color: '#4f46e5' },
      { path: '/solutions/fleet-maintenance', title: 'Fleet Maintenance', desc: 'Stay on top of routines and repairs', icon: 'mdi-wrench', bg: '#f0fdf4', color: '#16a34a' },
      { path: '/solutions/fuel-management', title: 'Fuel Management', desc: 'Collect fuel data and control costs', icon: 'mdi-gas-station', bg: '#fff7ed', color: '#ea580c' },
      { path: '/solutions/tool-management', title: 'Tool Management', desc: 'Track equipment alongside your vehicles', icon: 'mdi-toolbox', bg: '#faf5ff', color: '#9333ea' },
      { path: '/solutions/multi-location', title: 'Multi-Location', desc: 'Manage your fleet across locations', icon: 'mdi-map-marker-multiple', bg: '#ecfeff', color: '#0891b2' },
      { path: '/solutions/intelligence', title: 'Intelligence', desc: 'Spend less time on repetitive tasks', icon: 'mdi-brain', bg: '#fef2f2', color: '#dc2626' },
    ],
  },
  {
    label: 'Features',
    columns: true,
    items: [
      { path: '/features/inspections', title: 'Inspections', desc: 'Compliant, complete forms every time', icon: 'mdi-clipboard-check-outline', bg: '#eff6ff', color: '#2563eb' },
      { path: '/features/work-orders', title: 'Work Orders', desc: 'Plan, schedule and approve service', icon: 'mdi-clipboard-list-outline', bg: '#f0fdf4', color: '#16a34a' },
      { path: '/features/parts-inventory', title: 'Parts Inventory', desc: 'Control costs and avoid stockouts', icon: 'mdi-package-variant-closed', bg: '#fff7ed', color: '#ea580c' },
      { path: '/features/preventive-maintenance', title: 'Preventive Maintenance', desc: 'Increase uptime, reduce breakdowns', icon: 'mdi-calendar-clock', bg: '#eef2ff', color: '#4f46e5' },
      { path: '/features/driver-assignments', title: 'Driver Assignments', desc: 'Assign and manage schedules', icon: 'mdi-account-group', bg: '#faf5ff', color: '#9333ea' },
      { path: '/features/reports', title: 'Fleet Reports', desc: 'Track every metric that matters', icon: 'mdi-chart-line', bg: '#fef2f2', color: '#dc2626' },
      { path: '/features/dashboards', title: 'Fleet Dashboards', desc: 'See your operation at a glance', icon: 'mdi-view-dashboard-outline', bg: '#ecfeff', color: '#0891b2' },
      { path: '/features/smart-uploads', title: 'Smart Uploads', desc: 'Turn invoices into actionable data', icon: 'mdi-upload', bg: '#fffbeb', color: '#d97706' },
    ],
  },
  {
    label: 'Industries',
    columns: true,
    items: [
      { path: '/industries/construction', title: 'Construction', desc: 'Stay on time and on budget', icon: 'mdi-hard-hat', bg: '#fff7ed', color: '#ea580c' },
      { path: '/industries/service-providers', title: 'Service Providers', desc: 'Maximize fleet uptime', icon: 'mdi-account-tie', bg: '#eef2ff', color: '#4f46e5' },
      { path: '/industries/transportation', title: 'Transportation & Logistics', desc: 'Integrate with ELD, improve efficiency', icon: 'mdi-truck-fast', bg: '#f0fdf4', color: '#16a34a' },
      { path: '/industries/government', title: 'Government', desc: 'Improve compliance, reduce costs', icon: 'mdi-domain', bg: '#ecfeff', color: '#0891b2' },
    ],
  },
]

function onScroll() {
  scrolled.value = window.scrollY > 12
}

onMounted(() => {
  window.addEventListener('scroll', onScroll, { passive: true })
  onScroll()
})
onUnmounted(() => window.removeEventListener('scroll', onScroll))
</script>

<style scoped>
.fc-nav {
  position: sticky;
  top: 0;
  z-index: 100;
  background: rgba(255, 255, 255, 0.85);
  backdrop-filter: saturate(180%) blur(12px);
  border-bottom: 1px solid transparent;
  transition: border-color .2s ease, background .2s ease, box-shadow .2s ease;
}
.fc-nav--scrolled {
  border-bottom-color: #eef2f7;
  box-shadow: 0 1px 24px rgba(15, 23, 42, .04);
}
.fc-nav__inner {
  max-width: 1240px;
  margin: 0 auto;
  height: 68px;
  padding: 0 24px;
  display: flex;
  align-items: center;
  gap: 32px;
}
.fc-brand { display: flex; align-items: center; gap: 10px; text-decoration: none; flex-shrink: 0; }
.fc-brand__logo-img { width: 34px; height: 34px; border-radius: 10px; object-fit: contain; }
.fc-brand__mark {
  width: 34px; height: 34px; border-radius: 10px;
  display: flex; align-items: center; justify-content: center;
  background: linear-gradient(135deg, #6366f1, #4f46e5);
  box-shadow: 0 4px 14px rgba(79, 70, 229, .35);
}
.fc-brand__name { font-size: 20px; font-weight: 800; color: #0f172a; letter-spacing: -0.02em; }

.fc-nav__links { display: flex; align-items: center; gap: 4px; flex: 1; }

.fc-mega { position: relative; }
.fc-mega__trigger {
  background: none; border: none; cursor: pointer;
  font: inherit; font-weight: 500; color: #475569;
  padding: 8px 14px; border-radius: 8px;
  display: flex; align-items: center; gap: 4px;
  transition: background .15s ease, color .15s ease;
}
.fc-mega__trigger:hover { background: #f1f5f9; color: #0f172a; }
.fc-mega__chevron { transition: transform .2s ease; }
.fc-mega__chevron--open { transform: rotate(180deg); }

.fc-mega__panel {
  position: absolute; top: calc(100% + 10px); left: 0;
  background: #fff; border: 1px solid #eef2f7; border-radius: 16px;
  box-shadow: 0 24px 60px rgba(15, 23, 42, .12);
  padding: 12px; min-width: 280px;
  display: grid; gap: 4px;
}
.fc-mega__panel--wide { min-width: 620px; grid-template-columns: 1fr 1fr; }
.fc-mega__item {
  display: flex; align-items: flex-start; gap: 12px;
  padding: 12px; border-radius: 12px;
  text-decoration: none; transition: background .15s ease;
}
.fc-mega__item:hover { background: #f8fafc; }
.fc-mega__icon {
  width: 40px; height: 40px; border-radius: 10px; flex-shrink: 0;
  display: flex; align-items: center; justify-content: center;
}
.fc-mega__text { display: flex; flex-direction: column; gap: 2px; min-width: 0; }
.fc-mega__title { font-weight: 600; font-size: 14px; color: #0f172a; }
.fc-mega__desc { font-size: 12.5px; color: #94a3b8; line-height: 1.4; }

.fc-nav__link {
  padding: 8px 14px; border-radius: 8px;
  font-weight: 500; color: #475569; text-decoration: none;
  transition: background .15s ease, color .15s ease;
}
.fc-nav__link:hover { background: #f1f5f9; color: #0f172a; }

.fc-nav__actions { display: flex; align-items: center; gap: 8px; flex-shrink: 0; }
.fc-nav__burger { display: none; background: none; border: none; cursor: pointer; padding: 8px; border-radius: 8px; }
.fc-nav__burger:hover { background: #f1f5f9; }

.fc-btn {
  display: inline-flex; align-items: center; justify-content: center;
  font-weight: 600; font-size: 14px; padding: 10px 18px;
  border-radius: 10px; text-decoration: none; cursor: pointer;
  transition: all .15s ease; white-space: nowrap;
}
.fc-btn--ghost { color: #475569; }
.fc-btn--ghost:hover { background: #f1f5f9; color: #0f172a; }
.fc-btn--primary {
  background: linear-gradient(135deg, #6366f1, #4f46e5); color: #fff;
  box-shadow: 0 4px 14px rgba(79, 70, 229, .3);
}
.fc-btn--primary:hover { box-shadow: 0 6px 20px rgba(79, 70, 229, .4); transform: translateY(-1px); }
.fc-btn--block { width: 100%; }

.fc-nav__mobile { display: none; }

.fc-dropdown-enter-active, .fc-dropdown-leave-active { transition: opacity .15s ease, transform .15s ease; }
.fc-dropdown-enter-from, .fc-dropdown-leave-to { opacity: 0; transform: translateY(8px); }

@media (max-width: 1024px) {
  .fc-nav__links { display: none; }
  .fc-btn--ghost { display: none; }
  .fc-nav__burger { display: block; }
  .fc-nav__mobile {
    display: block; position: absolute; top: 68px; left: 0; right: 0;
    background: #fff; border-bottom: 1px solid #eef2f7;
    box-shadow: 0 24px 40px rgba(15, 23, 42, .1);
    padding: 16px 24px 24px; max-height: 75vh; overflow-y: auto;
  }
  .fc-mobile__group { padding: 10px 0; border-bottom: 1px solid #f1f5f9; }
  .fc-mobile__label { font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: .06em; color: #94a3b8; margin-bottom: 8px; }
  .fc-mobile__link { display: flex; align-items: center; gap: 10px; padding: 10px 4px; text-decoration: none; color: #334155; font-weight: 500; font-size: 15px; }
  .fc-mobile__cta { display: flex; flex-direction: column; gap: 10px; margin-top: 16px; }
}
</style>
