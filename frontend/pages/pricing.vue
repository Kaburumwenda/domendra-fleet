<template>
  <div>
    <PageHero eyebrow="Pricing" title="Simple, transparent pricing" subtitle="Start free, then pick the plan that fits your fleet. No hidden fees, cancel anytime." icon="mdi-tag-outline" :cta="false" />

    <section class="fc-pricing">
      <div class="fc-pricing__toggle">
        <button :class="{ active: !annual }" @click="annual = false">Monthly</button>
        <button :class="{ active: annual }" @click="annual = true">Annual <span class="fc-pricing__save">Save 20%</span></button>
      </div>

      <div class="fc-pricing__grid">
        <div v-for="plan in plans" :key="plan.name" class="fc-plan" :class="{ 'fc-plan--feat': plan.featured }">
          <div v-if="plan.featured" class="fc-plan__badge">Most popular</div>
          <h3>{{ plan.name }}</h3>
          <p class="fc-plan__desc">{{ plan.desc }}</p>
          <p class="fc-plan__price"><span class="fc-plan__curr">$</span>{{ annual ? Math.round(plan.price * 0.8) : plan.price }}<span class="fc-plan__per">/mo</span></p>
          <p class="fc-plan__sub">{{ plan.assets }}</p>
          <NuxtLink :to="plan.cta" class="fc-plan__btn" :class="plan.featured ? 'fc-plan__btn--primary' : ''">{{ plan.ctaLabel }}</NuxtLink>
          <ul class="fc-plan__feats">
            <li v-for="f in plan.features" :key="f"><v-icon size="16" color="#16a34a">mdi-check-circle</v-icon> {{ f }}</li>
          </ul>
        </div>
      </div>

      <div class="fc-pricing__note">
        <v-icon color="#4f46e5">mdi-information-outline</v-icon>
        <p>All plans include the full feature set. API overage billed at $0.007 per 1,000 requests beyond your included quota.</p>
      </div>
    </section>

    <section class="fc-faq">
      <h2>Frequently asked questions</h2>
      <div class="fc-faq__list">
        <div v-for="(f, i) in faqs" :key="i" class="fc-faq__item" :class="{ open: openFaq === i }" @click="openFaq = openFaq === i ? -1 : i">
          <p class="fc-faq__q">{{ f.q }} <v-icon size="18">{{ openFaq === i ? 'mdi-minus' : 'mdi-plus' }}</v-icon></p>
          <p class="fc-faq__a">{{ f.a }}</p>
        </div>
      </div>
    </section>

    <CtaBand />
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'marketing' })
useHead({ title: 'Pricing' })
const annual = ref(true)
const openFaq = ref(0)
const plans = [
  {
    name: 'Starter', desc: 'For small fleets getting organized.', price: 49, assets: 'Up to 25 assets',
    cta: '/register', ctaLabel: 'Start free trial', featured: false,
    features: ['Vehicle & asset management', 'Inspections (DVIR)', 'Work orders & issues', 'Basic reports', '5 user seats', 'Email support'],
  },
  {
    name: 'Professional', desc: 'For growing fleets that need more.', price: 149, assets: 'Up to 100 assets',
    cta: '/register', ctaLabel: 'Start free trial', featured: true,
    features: ['Everything in Starter', 'Preventive maintenance & reminders', 'Parts & inventory', 'Fuel & energy tracking', 'Fraud detection', 'Scheduled reports (PDF/Excel)', '20 user seats', 'Priority support'],
  },
  {
    name: 'Enterprise', desc: 'For large, multi-location operations.', price: 399, assets: 'Unlimited assets',
    cta: '/contact', ctaLabel: 'Contact sales', featured: false,
    features: ['Everything in Professional', 'Multi-location management', 'Garage & workshop module', 'Accident management', 'Dispatch & routing', 'SSO & advanced RBAC', 'Audit logs & white-labeling', 'Dedicated success manager'],
  },
]
const faqs = [
  { q: 'Is there a free trial?', a: 'Yes — every plan starts with a 14-day free trial. No credit card required to get started.' },
  { q: 'Can I change plans later?', a: 'Absolutely. You can upgrade or downgrade at any time and we will prorate the difference.' },
  { q: 'How is API usage billed?', a: 'Each plan includes a monthly API request quota. Overage beyond that is billed at $0.007 per 1,000 requests.' },
  { q: 'Do you offer onboarding?', a: 'Professional and Enterprise plans include guided onboarding. Enterprise includes a dedicated success manager.' },
  { q: 'Is my data secure?', a: 'Yes. We use schema-based multi-tenant isolation, JWT auth, full audit logging and TLS encryption in transit.' },
]
</script>

<style scoped>
.fc-pricing { max-width: 1180px; margin: -16px auto 0; padding: 0 24px 48px; }
.fc-pricing__toggle { display: inline-flex; gap: 4px; padding: 4px; background: #f1f5f9; border-radius: 12px; margin: 0 auto 40px; }
.fc-pricing__toggle { display: flex; width: max-content; }
.fc-pricing__toggle button { border: none; background: none; padding: 10px 22px; border-radius: 9px; font-weight: 600; font-size: 14px; color: #64748b; cursor: pointer; transition: all .2s ease; }
.fc-pricing__toggle button.active { background: #fff; color: #0f172a; box-shadow: 0 2px 8px rgba(15, 23, 42, .08); }
.fc-pricing__save { background: #dcfce7; color: #16a34a; font-size: 11px; font-weight: 700; padding: 2px 7px; border-radius: 999px; margin-left: 4px; }
.fc-pricing__grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 22px; align-items: start; }
.fc-plan { position: relative; padding: 36px 30px; border-radius: 20px; background: #fff; border: 1px solid #eef2f7; transition: all .25s ease; }
.fc-plan:hover { border-color: #c7d2fe; box-shadow: 0 16px 40px rgba(79, 70, 229, .08); }
.fc-plan--feat { border-color: #6366f1; box-shadow: 0 30px 70px rgba(79, 70, 229, .18); transform: scale(1.03); background: linear-gradient(180deg, #fff, #fafbff); }
.fc-plan__badge { position: absolute; top: -13px; left: 50%; transform: translateX(-50%); background: linear-gradient(135deg, #6366f1, #4f46e5); color: #fff; font-size: 12px; font-weight: 700; padding: 6px 18px; border-radius: 999px; box-shadow: 0 4px 14px rgba(79, 70, 229, .3); }
.fc-plan h3 { font-size: 22px; font-weight: 800; color: #0f172a; }
.fc-plan__desc { font-size: 14px; color: #64748b; margin: 6px 0 22px; min-height: 40px; }
.fc-plan__price { font-size: 52px; font-weight: 800; color: #0f172a; letter-spacing: -0.03em; }
.fc-plan__curr { font-size: 26px; vertical-align: top; margin-right: 2px; }
.fc-plan__per { font-size: 17px; font-weight: 500; color: #94a3b8; }
.fc-plan__sub { font-size: 14px; font-weight: 600; color: #4f46e5; margin: 6px 0 24px; }
.fc-plan__btn { display: flex; align-items: center; justify-content: center; width: 100%; padding: 14px; border-radius: 12px; font-weight: 600; font-size: 15px; text-decoration: none; border: 1px solid #e2e8f0; color: #0f172a; transition: all .2s ease; margin-bottom: 28px; }
.fc-plan__btn:hover { background: #f8fafc; border-color: #cbd5e1; transform: translateY(-1px); }
.fc-plan__btn--primary { background: linear-gradient(135deg, #6366f1, #4f46e5); color: #fff; border-color: #4f46e5; box-shadow: 0 8px 24px rgba(79, 70, 229, .3); }
.fc-plan__btn--primary:hover { box-shadow: 0 12px 32px rgba(79, 70, 229, .4); }
.fc-plan__feats { list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 12px; }
.fc-plan__feats li { display: flex; align-items: center; gap: 10px; font-size: 14px; color: #475569; }
.fc-pricing__note { display: flex; align-items: center; gap: 10px; max-width: 760px; margin: 40px auto 0; padding: 16px 20px; background: #eef2ff; border-radius: 14px; color: #4338ca; font-size: 14px; }
.fc-pricing__note p { margin: 0; }

.fc-faq { max-width: 760px; margin: 0 auto; padding: 64px 24px; }
.fc-faq h2 { text-align: center; font-size: clamp(26px, 3vw, 36px); font-weight: 800; color: #0f172a; margin-bottom: 36px; }
.fc-faq__list { display: flex; flex-direction: column; gap: 12px; }
.fc-faq__item { border: 1px solid #eef2f7; border-radius: 14px; overflow: hidden; cursor: pointer; transition: border-color .15s ease; }
.fc-faq__item:hover { border-color: #c7d2fe; }
.fc-faq__item.open { border-color: #6366f1; }
.fc-faq__q { display: flex; align-items: center; justify-content: space-between; padding: 18px 22px; font-weight: 600; color: #0f172a; margin: 0; }
.fc-faq__a { padding: 0 22px; max-height: 0; overflow: hidden; color: #64748b; font-size: 15px; line-height: 1.6; transition: all .25s ease; margin: 0; }
.fc-faq__item.open .fc-faq__a { padding: 0 22px 18px; max-height: 200px; }

@media (max-width: 900px) { .fc-pricing__grid { grid-template-columns: 1fr; } .fc-plan--feat { transform: none; } }
</style>
