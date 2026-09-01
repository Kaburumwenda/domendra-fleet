<template>
  <div>
    <PageHero eyebrow="Contact" title="Let's talk fleet" subtitle="Book a personalized demo or reach our team. We typically respond within one business day." icon="mdi-email-outline" :cta="false" />

    <section class="fc-contact">
      <div class="fc-contact__grid">
        <div class="fc-contact__form">
          <h2>Book a demo</h2>
          <p class="fc-contact__sub">See DomendraFleet in action with a 30-minute walkthrough tailored to your operation.</p>
          <form class="fc-form" @submit.prevent="submit">
            <div class="fc-form__row">
              <div class="fc-field"><label>First name</label><input v-model="form.first_name" placeholder="John" /></div>
              <div class="fc-field"><label>Last name</label><input v-model="form.last_name" placeholder="Doe" /></div>
            </div>
            <div class="fc-field"><label>Work email</label><input v-model="form.email" type="email" placeholder="you@company.com" /></div>
            <div class="fc-form__row">
              <div class="fc-field"><label>Company</label><input v-model="form.company" placeholder="ACME Logistics" /></div>
              <div class="fc-field"><label>Fleet size</label>
                <select v-model="form.fleet_size"><option value="">Select…</option><option>1–10</option><option>11–50</option><option>51–200</option><option>200+</option></select>
              </div>
            </div>
            <div class="fc-field"><label>How can we help?</label><textarea v-model="form.message" rows="4" placeholder="Tell us about your fleet…" /></div>
            <button type="submit" class="fc-form__submit" :disabled="sent">{{ sent ? 'Thanks — we will be in touch!' : 'Request demo' }}</button>
          </form>
        </div>

        <aside class="fc-contact__side">
          <div class="fc-contact__card">
            <span class="fc-contact__ic" style="background:#eef2ff;color:#4f46e5"><v-icon>mdi-phone</v-icon></span>
            <h3>Sales</h3><p><a href="tel:+254739123995" style="color:inherit;text-decoration:none">+254 739 123 995</a></p><small>Mon–Fri, 8am–6pm EAT</small>
          </div>
          <div class="fc-contact__card">
            <span class="fc-contact__ic" style="background:#f0fdf4;color:#16a34a"><v-icon>mdi-lifebuoy</v-icon></span>
            <h3>Support</h3><p><a href="mailto:domendrafleet@tiktek-ex.com" style="color:inherit;text-decoration:none">domendrafleet@tiktek-ex.com</a></p><small>24/7 for Enterprise customers</small>
          </div>
          <div class="fc-contact__card">
            <span class="fc-contact__ic" style="background:#fff7ed;color:#ea580c"><v-icon>mdi-map-marker</v-icon></span>
            <h3>HQ</h3><p>Birmingham, AL</p><small>United States</small>
          </div>
        </aside>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'marketing' })
useHead({ title: 'Contact' })
const sent = ref(false)
const form = reactive({ first_name: '', last_name: '', email: '', company: '', fleet_size: '', message: '' })
function submit() { sent.value = true }
</script>

<style scoped>
.fc-contact { max-width: 1100px; margin: 0 auto; padding: 0 24px 64px; }
.fc-contact__grid { display: grid; grid-template-columns: 1.5fr 1fr; gap: 40px; align-items: start; }
.fc-contact__form h2 { font-size: 28px; font-weight: 800; color: #0f172a; }
.fc-contact__sub { color: #64748b; margin: 6px 0 28px; }
.fc-form { display: flex; flex-direction: column; gap: 16px; }
.fc-form__row { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
.fc-field { display: flex; flex-direction: column; gap: 6px; }
.fc-field label { font-size: 13px; font-weight: 600; color: #334155; }
.fc-field input, .fc-field select, .fc-field textarea {
  border: 1px solid #e2e8f0; border-radius: 10px; padding: 12px 14px; font: inherit; font-size: 15px;
  color: #0f172a; background: #fff; transition: border-color .15s ease, box-shadow .15s ease; outline: none; resize: vertical;
}
.fc-field input:focus, .fc-field select:focus, .fc-field textarea:focus { border-color: #6366f1; box-shadow: 0 0 0 3px rgba(99, 102, 241, .15); }
.fc-form__submit { margin-top: 8px; padding: 14px; border: none; border-radius: 12px; background: #4f46e5; color: #fff; font-weight: 600; font-size: 15px; cursor: pointer; transition: all .15s ease; box-shadow: 0 8px 24px rgba(79, 70, 229, .3); }
.fc-form__submit:hover:not(:disabled) { background: #4338ca; transform: translateY(-1px); }
.fc-form__submit:disabled { background: #dcfce7; color: #16a34a; box-shadow: none; cursor: default; }

.fc-contact__side { display: flex; flex-direction: column; gap: 16px; }
.fc-contact__card { padding: 26px; border: 1px solid #eef2f7; border-radius: 18px; transition: all .2s ease; background: #fff; }
.fc-contact__card:hover { border-color: #c7d2fe; box-shadow: 0 12px 32px rgba(79,70,229,.06); transform: translateY(-2px); }
.fc-contact__ic { width: 44px; height: 44px; border-radius: 12px; display: flex; align-items: center; justify-content: center; margin-bottom: 14px; }
.fc-contact__card h3 { font-size: 15px; font-weight: 700; color: #0f172a; margin: 0 0 4px; }
.fc-contact__card p { font-size: 16px; font-weight: 600; color: #334155; margin: 0 0 2px; }
.fc-contact__card small { color: #94a3b8; font-size: 13px; }

@media (max-width: 860px) { .fc-contact__grid { grid-template-columns: 1fr; } .fc-form__row { grid-template-columns: 1fr; } }
</style>
