<template>
  <section v-for="(group, gi) in groups" :key="gi" class="fc-pods" :class="{ 'fc-pods--rev': gi % 2 === 1 }">
    <div class="fc-pods__inner">
      <div class="fc-pods__copy reveal" :data-reveal-type="gi % 2 === 1 ? 'right' : 'left'">
        <SectionEyebrow :text="group.eyebrow" :icon="group.icon" />
        <h2>{{ group.title }}</h2>
        <p>{{ group.desc }}</p>
        <NuxtLink :to="group.path" class="fc-pods__cta">Explore <v-icon size="16">mdi-arrow-right</v-icon></NuxtLink>
      </div>
      <div class="fc-pods__grid">
        <div
          v-for="(pod, pi) in group.pods"
          :key="pod.title"
          class="fc-pod reveal"
          :data-reveal-delay="pi * 100"
          :data-reveal-type="gi % 2 === 1 ? 'left' : 'right'"
        >
          <div class="fc-pod__media" :style="{ background: pod.bg }">
            <v-icon size="40" :color="pod.color">{{ pod.icon }}</v-icon>
          </div>
          <h3>{{ pod.title }}</h3>
          <p>{{ pod.desc }}</p>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
const { register } = useScrollReveal()
onMounted(() => register('.reveal'))

const groups = [
  {
    eyebrow: 'Scale with control', icon: 'mdi-scale-balance', title: 'Apply consistent standards as you grow',
    desc: 'As your fleet grows, maintenance decisions multiply. DomendraFleet helps you apply consistent approval logic, cost guardrails, and prioritization across every vehicle, vendor and location — so quality improves as you scale.',
    path: '/features/reports',
    pods: [
      { title: 'Replacement analysis', desc: 'Find the right time to retire a vehicle.', icon: 'mdi-chart-timeline-variant', bg: '#eef2ff', color: '#4f46e5' },
      { title: 'Service Advisor', desc: 'Reinforces routine approvals and captures decisions.', icon: 'mdi-robot-outline', bg: '#fef2f2', color: '#dc2626' },
      { title: 'Utilization', desc: 'Identify over- or under-utilized assets.', icon: 'mdi-chart-bar', bg: '#ecfdf5', color: '#16a34a' },
      { title: 'Cost controls', desc: 'Set thresholds and report in real time.', icon: 'mdi-cash-lock', bg: '#fff7ed', color: '#ea580c' },
    ],
  },
  {
    eyebrow: 'Decide with confidence', icon: 'mdi-shield-check-outline', title: 'Fix it with a click, in-house or outsource',
    desc: 'AI Service Advisor evaluates repair orders, flags exceptions and keeps approvals within your guardrails — so every decision is backed by data.',
    path: '/solutions/intelligence',
    pods: [
      { title: 'Smart assessments', desc: 'Identify the outliers with AI-powered assessments.', icon: 'mdi-brain', bg: '#faf5ff', color: '#9333ea' },
      { title: 'OEM guidelines', desc: 'Automate maintenance programs by OEM spec.', icon: 'mdi-book-open-variant', bg: '#eff6ff', color: '#2563eb' },
      { title: 'VIN import', desc: 'Import assets by VIN to capture 90+ specs.', icon: 'mdi-database-import', bg: '#ecfeff', color: '#0891b2' },
      { title: 'Outsource network', desc: 'Approve outsourced work through 80,000+ shops.', icon: 'mdi-store', bg: '#fffbeb', color: '#d97706' },
    ],
  },
  {
    eyebrow: 'Capture work faster', icon: 'mdi-camera-burst', title: 'Reduce manual entry so your team can focus on decisions',
    desc: 'With more complete data, you get better team connection, safety and compliance without slowing down.',
    path: '/features/inspections',
    pods: [
      { title: 'Telematics data', desc: 'Auto-start maintenance from telematics.', icon: 'mdi-satellite-variant', bg: '#eef2ff', color: '#4f46e5' },
      { title: 'Vehicle inspections', desc: 'Track inspections and resolve issues fast.', icon: 'mdi-clipboard-check-outline', bg: '#f0fdf4', color: '#16a34a' },
      { title: 'Smart uploads', desc: 'Capture data from invoices instantly.', icon: 'mdi-upload', bg: '#fff7ed', color: '#ea580c' },
      { title: 'Fuel cards', desc: 'Gather fuel card data to monitor costs.', icon: 'mdi-credit-card-chip', bg: '#fef2f2', color: '#dc2626' },
    ],
  },
]
</script>

<style scoped>
.fc-pods { max-width: 1240px; margin: 0 auto; padding: 64px 24px; }
.fc-pods__inner { display: grid; grid-template-columns: 0.85fr 1.15fr; gap: 56px; align-items: center; }
.fc-pods--rev .fc-pods__inner { grid-template-columns: 1.15fr 0.85fr; }
.fc-pods--rev .fc-pods__copy { order: 2; }
.fc-pods__copy h2 { font-size: clamp(26px, 3vw, 36px); font-weight: 800; letter-spacing: -0.02em; color: #0f172a; margin: 14px 0 14px; }
.fc-pods__copy p { font-size: 16px; line-height: 1.6; color: #64748b; margin-bottom: 20px; }
.fc-pods__cta { display: inline-flex; align-items: center; gap: 4px; font-weight: 600; color: #4f46e5; text-decoration: none; transition: gap .15s ease; }
.fc-pods__cta:hover { gap: 8px; }
.fc-pods__grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
.fc-pod { padding: 26px; border-radius: 18px; background: #fff; border: 1px solid #eef2f7; transition: all .25s cubic-bezier(.4,0,.2,1); }
.fc-pod:hover { box-shadow: 0 20px 44px rgba(15, 23, 42, .1); transform: translateY(-4px); border-color: #c7d2fe; }
.fc-pod__media { width: 64px; height: 64px; border-radius: 16px; display: flex; align-items: center; justify-content: center; margin-bottom: 16px; transition: transform .25s ease; }
.fc-pod:hover .fc-pod__media { transform: scale(1.06) rotate(-3deg); }
.fc-pod h3 { font-size: 16px; font-weight: 700; color: #0f172a; margin: 0 0 6px; }
.fc-pod p { font-size: 13.5px; line-height: 1.5; color: #64748b; margin: 0; }
@media (max-width: 900px) {
  .fc-pods__inner, .fc-pods--rev .fc-pods__inner { grid-template-columns: 1fr; }
  .fc-pods--rev .fc-pods__copy { order: 0; }
  .fc-pods__grid { grid-template-columns: 1fr 1fr; }
}
@media (max-width: 540px) { .fc-pods__grid { grid-template-columns: 1fr; } }
</style>
