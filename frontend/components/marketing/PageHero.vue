<template>
  <section class="fc-pagehero">
    <div class="fc-pagehero__bg">
      <div class="fc-pagehero__blob" />
      <div class="fc-pagehero__grid" />
    </div>
    <div class="fc-pagehero__inner">
      <SectionEyebrow :text="eyebrow" :icon="icon" />
      <h1>{{ title }}</h1>
      <p>{{ subtitle }}</p>
      <div v-if="cta" class="fc-pagehero__cta">
        <NuxtLink to="/register" class="fc-btn fc-btn--primary">Start free trial</NuxtLink>
        <NuxtLink to="/contact" class="fc-btn fc-btn--ghost">Book a demo</NuxtLink>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
defineProps<{ eyebrow: string; title: string; subtitle: string; icon?: string; cta?: boolean }>()
</script>

<style scoped>
.fc-pagehero { position: relative; overflow: hidden; padding: 96px 0 64px; text-align: center; }
.fc-pagehero__bg { position: absolute; inset: 0; z-index: 0; }
.fc-pagehero__blob { position: absolute; top: -160px; left: 50%; transform: translateX(-50%); width: 520px; height: 520px; border-radius: 50%; background: rgba(99, 102, 241, .12); filter: blur(90px); animation: fcbreathe 10s ease-in-out infinite; }
@keyframes fcbreathe { 0%,100% { transform: translateX(-50%) scale(1); } 50% { transform: translateX(-50%) scale(1.08); } }
.fc-pagehero__grid { position: absolute; inset: 0; background-image: linear-gradient(#f1f5f9 1px, transparent 1px), linear-gradient(90deg, #f1f5f9 1px, transparent 1px); background-size: 44px 44px; mask-image: radial-gradient(ellipse 70% 60% at 50% 20%, #000 30%, transparent 75%); -webkit-mask-image: radial-gradient(ellipse 70% 60% at 50% 20%, #000 30%, transparent 75%); }
.fc-pagehero__inner { position: relative; z-index: 1; max-width: 760px; margin: 0 auto; padding: 0 24px; }
.fc-pagehero__inner h1 { font-size: clamp(34px, 5vw, 54px); font-weight: 800; letter-spacing: -0.03em; color: #0f172a; margin: 18px 0 16px; animation: fcfadeup 0.8s ease backwards; }
@keyframes fcfadeup { from { opacity: 0; transform: translateY(20px); } }
.fc-pagehero__inner p { font-size: 17px; line-height: 1.6; color: #64748b; animation: fcfadeup 0.8s ease 0.1s backwards; }
.fc-pagehero__cta { margin-top: 30px; display: flex; gap: 14px; justify-content: center; flex-wrap: wrap; animation: fcfadeup 0.8s ease 0.2s backwards; }
.fc-btn { display: inline-flex; align-items: center; font-weight: 600; font-size: 15px; padding: 13px 24px; border-radius: 12px; text-decoration: none; transition: all .2s ease; }
.fc-btn--primary { background: linear-gradient(135deg, #6366f1, #4f46e5); color: #fff; box-shadow: 0 8px 24px rgba(79, 70, 229, .3); }
.fc-btn--primary:hover { transform: translateY(-2px); box-shadow: 0 12px 32px rgba(79, 70, 229, .42); }
.fc-btn--ghost { background: #fff; color: #0f172a; border: 1px solid #e2e8f0; }
.fc-btn--ghost:hover { background: #f8fafc; border-color: #cbd5e1; transform: translateY(-1px); }
</style>
