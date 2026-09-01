<template>
  <section class="fc-hero">
    <div class="fc-hero__bg">
      <div class="fc-hero__blob fc-hero__blob--1" />
      <div class="fc-hero__blob fc-hero__blob--2" />
      <div class="fc-hero__grid" />
    </div>

    <div class="fc-hero__inner">
      <div class="fc-hero__copy">
        <span class="fc-hero__pill">
          <v-icon size="14" color="#16a34a">mdi-circle-medium</v-icon>
          Powering 1,000,000+ fleet assets
        </span>
        <h1 class="fc-hero__title">Fleet maintenance<br>that <span class="fc-hero__accent">thinks ahead.</span></h1>
        <p class="fc-hero__sub">
          Run your fleet reliably, repair your assets quickly and optimize every aspect of your operation:
          vehicles, drivers, fuel, equipment, parts and more. Turn everyday data into actionable insights
          that keep your fleet on the move.
        </p>
        <div class="fc-hero__cta">
          <NuxtLink to="/register" class="fc-btn fc-btn--primary">Start a Free Trial</NuxtLink>
          <NuxtLink to="/contact" class="fc-btn fc-btn--ghost">
            <v-icon size="18">mdi-play-circle-outline</v-icon> Book a Demo
          </NuxtLink>
        </div>
        <div class="fc-hero__proof">
          <div class="fc-hero__stars">
            <v-icon v-for="i in 5" :key="i" size="16" color="#f59e0b">mdi-star</v-icon>
            <span>4.8/5 · Based on 100s of reviews</span>
          </div>
          <div class="fc-hero__logos">
            <span>G2</span><span>Capterra</span><span>Software Advice</span><span>GetApp</span>
          </div>
        </div>
      </div>

      <div class="fc-hero__visual">
        <div class="fc-hero__glow" />
        <div class="fc-hero__card fc-hero__card--main">
          <div class="fc-hero__cardbar">
            <span class="fc-dot fc-dot--r" /><span class="fc-dot fc-dot--y" /><span class="fc-dot fc-dot--g" />
            <b>Domendra · Dashboard</b>
            <span class="fc-hero__live"><span class="fc-hero__live-dot" />Live</span>
          </div>
          <div class="fc-hero__kpis">
            <div class="fc-kpi"><span class="fc-kpi__label">Fleet Utilization</span><span class="fc-kpi__val">87%</span><div class="fc-bar"><i style="width:87%;background:linear-gradient(90deg,#6366f1,#8b5cf6)" /></div></div>
            <div class="fc-kpi"><span class="fc-kpi__label">Active Vehicles</span><span class="fc-kpi__val">142</span><div class="fc-bar"><i style="width:72%;background:linear-gradient(90deg,#22c55e,#16a34a)" /></div></div>
            <div class="fc-kpi"><span class="fc-kpi__label">Open Work Orders</span><span class="fc-kpi__val">18</span><div class="fc-bar"><i style="width:24%;background:linear-gradient(90deg,#f59e0b,#d97706)" /></div></div>
          </div>
          <div class="fc-hero__chart">
            <div class="fc-chart__row" v-for="(h, i) in [62, 78, 54, 88, 70, 95, 68]" :key="i" :style="{ height: h + '%', animationDelay: i * 0.1 + 's' }" />
          </div>
          <div class="fc-hero__mini-stats">
            <div class="fc-hero__mini"><v-icon size="14" color="#16a34a">mdi-trending-up</v-icon><span>Costs down 12%</span></div>
            <div class="fc-hero__mini"><v-icon size="14" color="#6366f1">mdi-clock-outline</v-icon><span>Uptime 98.2%</span></div>
          </div>
        </div>
        <div class="fc-hero__card fc-hero__card--float">
          <div class="fc-hero__floaticon" style="background:#dcfce7;color:#16a34a"><v-icon size="18">mdi-check-decagram</v-icon></div>
          <div><b>Inspection passed</b><small>Ford Transit · #FC-2041</small></div>
        </div>
        <div class="fc-hero__card fc-hero__card--float fc-hero__card--float2">
          <div class="fc-hero__floaticon" style="background:#fef3c7;color:#d97706"><v-icon size="18">mdi-bell-alert</v-icon></div>
          <div><b>PM reminder due</b><small>Kenworth T680 · in 2 days</small></div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
</script>

<style scoped>
.fc-hero { position: relative; overflow: hidden; padding: 80px 0 72px; }
.fc-hero__bg { position: absolute; inset: 0; z-index: 0; }
.fc-hero__blob { position: absolute; border-radius: 50%; filter: blur(90px); animation: fcblob 20s ease-in-out infinite; }
.fc-hero__blob--1 { top: -180px; right: -120px; width: 460px; height: 460px; background: rgba(99, 102, 241, .14); }
.fc-hero__blob--2 { bottom: -200px; left: -120px; width: 420px; height: 420px; background: rgba(34, 197, 94, .1); animation-delay: 10s; }
@keyframes fcblob { 0%,100% { transform: translate(0,0) scale(1); } 50% { transform: translate(30px,-20px) scale(1.05); } }
.fc-hero__grid {
  position: absolute; inset: 0;
  background-image: linear-gradient(#f1f5f9 1px, transparent 1px), linear-gradient(90deg, #f1f5f9 1px, transparent 1px);
  background-size: 44px 44px;
  mask-image: radial-gradient(ellipse 80% 60% at 50% 30%, #000 40%, transparent 80%);
  -webkit-mask-image: radial-gradient(ellipse 80% 60% at 50% 30%, #000 40%, transparent 80%);
}
.fc-hero__inner {
  position: relative; z-index: 1; max-width: 1240px; margin: 0 auto; padding: 0 24px;
  display: grid; grid-template-columns: 1.05fr 1fr; gap: 56px; align-items: center;
}

.fc-hero__pill {
  display: inline-flex; align-items: center; gap: 4px;
  font-size: 12.5px; font-weight: 600; color: #334155;
  background: #fff; border: 1px solid #e2e8f0; padding: 6px 14px; border-radius: 999px;
  box-shadow: 0 1px 8px rgba(15, 23, 42, .04);
  animation: fcpill 0.6s ease backwards;
}
@keyframes fcpill { from { opacity: 0; transform: translateY(-10px); } }
.fc-hero__title {
  font-size: clamp(38px, 5vw, 60px); line-height: 1.04; font-weight: 800;
  letter-spacing: -0.03em; color: #0f172a; margin: 22px 0 20px;
  animation: fcfadeup 0.8s ease 0.1s backwards;
}
.fc-hero__accent { background: linear-gradient(120deg, #6366f1, #8b5cf6, #6366f1); background-size: 200% 100%; -webkit-background-clip: text; background-clip: text; -webkit-text-fill-color: transparent; animation: fcshine 4s linear infinite; }
@keyframes fcshine { to { background-position: 200% 0; } }
@keyframes fcfadeup { from { opacity: 0; transform: translateY(20px); } }
.fc-hero__sub { font-size: 17px; line-height: 1.65; color: #475569; max-width: 520px; margin-bottom: 32px; animation: fcfadeup 0.8s ease 0.2s backwards; }
.fc-hero__cta { display: flex; gap: 14px; flex-wrap: wrap; animation: fcfadeup 0.8s ease 0.3s backwards; }

.fc-btn { display: inline-flex; align-items: center; gap: 8px; font-weight: 600; font-size: 15px; padding: 13px 24px; border-radius: 12px; text-decoration: none; cursor: pointer; transition: all .2s ease; white-space: nowrap; }
.fc-btn--primary { background: linear-gradient(135deg, #6366f1, #4f46e5); color: #fff; box-shadow: 0 8px 24px rgba(79, 70, 229, .32); }
.fc-btn--primary:hover { transform: translateY(-2px); box-shadow: 0 12px 32px rgba(79, 70, 229, .42); }
.fc-btn--ghost { background: #fff; color: #0f172a; border: 1px solid #e2e8f0; }
.fc-btn--ghost:hover { border-color: #c7d2fe; background: #f8fafc; transform: translateY(-1px); }

.fc-hero__proof { margin-top: 28px; display: flex; flex-direction: column; gap: 12px; animation: fcfadeup 0.8s ease 0.4s backwards; }
.fc-hero__stars { display: flex; align-items: center; gap: 8px; font-size: 13px; color: #64748b; }
.fc-hero__logos { display: flex; gap: 22px; opacity: .6; font-weight: 700; font-size: 13px; color: #475569; }

.fc-hero__visual { position: relative; min-height: 420px; animation: fcfadeup 1s ease 0.3s backwards; }
.fc-hero__glow { position: absolute; inset: -20px; background: radial-gradient(circle at 60% 40%, rgba(99,102,241,.15), transparent 60%); border-radius: 30px; pointer-events: none; }
.fc-hero__card { background: #fff; border: 1px solid #eef2f7; border-radius: 18px; box-shadow: 0 30px 70px rgba(15, 23, 42, .12); }
.fc-hero__card--main { padding: 20px; position: relative; }
.fc-hero__cardbar { display: flex; align-items: center; gap: 6px; margin-bottom: 18px; }
.fc-hero__cardbar b { margin-left: 10px; font-size: 13px; color: #94a3b8; font-weight: 600; }
.fc-hero__live { margin-left: auto; display: flex; align-items: center; gap: 4px; font-size: 11px; font-weight: 700; color: #16a34a; }
.fc-hero__live-dot { width: 6px; height: 6px; border-radius: 50%; background: #22c55e; animation: fcpulse 2s ease-in-out infinite; }
@keyframes fcpulse { 0%,100% { opacity: 1; box-shadow: 0 0 0 0 rgba(34,197,94,.5); } 50% { opacity: .6; box-shadow: 0 0 0 6px rgba(34,197,94,0); } }
.fc-dot { width: 10px; height: 10px; border-radius: 50%; }
.fc-dot--r { background: #fca5a5; } .fc-dot--y { background: #fde68a; } .fc-dot--g { background: #bbf7d0; }
.fc-hero__kpis { display: grid; grid-template-columns: repeat(3, 1fr); gap: 14px; margin-bottom: 18px; }
.fc-kpi { display: flex; flex-direction: column; gap: 6px; }
.fc-kpi__label { font-size: 11px; color: #94a3b8; font-weight: 600; }
.fc-kpi__val { font-size: 22px; font-weight: 800; color: #0f172a; }
.fc-bar { height: 6px; background: #f1f5f9; border-radius: 999px; overflow: hidden; }
.fc-bar i { display: block; height: 100%; border-radius: 999px; transition: width .6s ease; }
.fc-hero__chart { display: flex; align-items: flex-end; gap: 8px; height: 120px; padding: 12px; background: #f8fafc; border-radius: 12px; }
.fc-chart__row { flex: 1; background: linear-gradient(180deg, #818cf8, #4f46e5); border-radius: 6px 6px 0 0; opacity: .9; animation: fcgrow 1.2s ease backwards; }
@keyframes fcgrow { from { height: 0; } }
.fc-hero__mini-stats { display: flex; gap: 16px; margin-top: 14px; padding-top: 14px; border-top: 1px solid #f1f5f9; }
.fc-hero__mini { display: flex; align-items: center; gap: 4px; font-size: 12px; font-weight: 600; color: #475569; }

.fc-hero__card--float {
  position: absolute; display: flex; align-items: center; gap: 12px;
  padding: 14px 18px; border-radius: 14px; max-width: 280px;
  animation: fcbob 4s ease-in-out infinite;
}
.fc-hero__card--float { right: -24px; top: 40%; }
.fc-hero__card--float2 { right: -8px; bottom: 8%; animation-delay: 1.5s; }
.fc-hero__floaticon { width: 38px; height: 38px; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.fc-hero__card--float b { display: block; font-size: 13.5px; color: #0f172a; }
.fc-hero__card--float small { display: block; font-size: 12px; color: #94a3b8; }
@keyframes fcbob { 0%,100% { transform: translateY(0); } 50% { transform: translateY(-8px); } }

@media (max-width: 980px) {
  .fc-hero__inner { grid-template-columns: 1fr; gap: 36px; }
  .fc-hero__visual { min-height: 380px; }
  .fc-hero__card--float { right: 0; }
}
</style>
