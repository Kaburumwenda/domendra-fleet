<template>
  <section class="fc-trust">
    <p class="fc-trust__label">Trusted by top fleets around the world</p>
    <div class="fc-trust__row">
      <div class="fc-trust__track">
        <span v-for="(name, i) in [...logos, ...logos]" :key="i" class="fc-trust__logo">{{ name }}</span>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
const logos = ['1800 GOT JUNK', 'AAA', 'SUBARU', 'BIMBO', 'EMORY', 'TCU', 'ARTERA', 'WRIGHT', 'STANLEY', 'NEKWORK']
</script>

<style scoped>
.fc-trust { padding: 16px 0 40px; text-align: center; }
.fc-trust__label { font-size: 12.5px; font-weight: 600; letter-spacing: .06em; text-transform: uppercase; color: #94a3b8; margin-bottom: 22px; }
.fc-trust__row { overflow: hidden; -webkit-mask-image: linear-gradient(90deg, transparent, #000 12%, #000 88%, transparent); mask-image: linear-gradient(90deg, transparent, #000 12%, #000 88%, transparent); }
.fc-trust__track { display: flex; gap: 56px; width: max-content; animation: fcscroll 28s linear infinite; }
.fc-trust__logo { font-size: 19px; font-weight: 800; letter-spacing: .04em; color: #cbd5e1; white-space: nowrap; }
@keyframes fcscroll { to { transform: translateX(-50%); } }
</style>
