<template>
  <v-app>
    <v-main class="auth-main">
      <div class="auth-container">
        <!-- Left: Branding Panel -->
        <div class="auth-brand">
          <div class="auth-brand-bg">
            <div class="auth-blob auth-blob-1" />
            <div class="auth-blob auth-blob-2" />
            <div class="auth-grid-pattern" />
          </div>

          <!-- Fleet Management Animated Visual -->
          <div class="auth-fleet-anim" aria-hidden="true">
            <!-- Stylized map + vehicle routes -->
            <svg class="auth-fleet-svg" viewBox="0 0 360 200" preserveAspectRatio="xMidYMid slice">
              <defs>
                <linearGradient id="routeGrad1" x1="0" y1="0" x2="1" y2="0">
                  <stop offset="0%" stop-color="rgba(129,140,248,0)" />
                  <stop offset="50%" stop-color="rgba(129,140,248,0.55)" />
                  <stop offset="100%" stop-color="rgba(129,140,248,0)" />
                </linearGradient>
                <linearGradient id="routeGrad2" x1="0" y1="1" x2="1" y2="0">
                  <stop offset="0%" stop-color="rgba(165,180,252,0)" />
                  <stop offset="50%" stop-color="rgba(165,180,252,0.45)" />
                  <stop offset="100%" stop-color="rgba(165,180,252,0)" />
                </linearGradient>
              </defs>
              <!-- hub circles (city points) -->
              <circle cx="40" cy="50" r="3" fill="rgba(255,255,255,0.25)" />
              <circle cx="320" cy="40" r="3" fill="rgba(255,255,255,0.25)" />
              <circle cx="290" cy="160" r="3" fill="rgba(255,255,255,0.25)" />
              <circle cx="60" cy="150" r="3" fill="rgba(255,255,255,0.25)" />
              <!-- route 1: zigzag -->
              <path
                d="M40,50 C110,70 120,20 190,55 C250,85 260,30 320,40"
                class="auth-fleet-path auth-fleet-path-1"
              />
              <path
                d="M40,50 C110,70 120,20 190,55 C250,85 260,30 320,40"
                class="auth-fleet-trace auth-fleet-trace-1"
              />
              <path
                d="M60,150 C140,130 170,180 240,140 C280,120 280,170 290,160"
                class="auth-fleet-path auth-fleet-path-2"
              />
              <path
                d="M60,150 C140,130 170,180 240,140 C280,120 280,170 290,160"
                class="auth-fleet-trace auth-fleet-trace-2"
              />
              <!-- moving vehicle markers along route 1 -->
              <g class="auth-fleet-vehicle auth-fleet-vehicle-1">
                <circle r="4" fill="#fff" opacity="0.9" />
                <circle r="6" fill="#fff" opacity="0.25" class="auth-fleet-ping" />
              </g>
              <g class="auth-fleet-vehicle auth-fleet-vehicle-2">
                <circle r="4" fill="#a5b4fc" opacity="0.9" />
                <circle r="6" fill="#a5b4fc" opacity="0.25" class="auth-fleet-ping" />
              </g>
            </svg>

            <!-- Floating mini stats cards -->
            <div class="auth-float-card auth-float-card-1">
              <v-icon size="16" class="auth-float-icon">mdi-truck-fast</v-icon>
              <div>
                <div class="auth-float-value">248</div>
                <div class="auth-float-label">Active vehicles</div>
              </div>
            </div>
            <div class="auth-float-card auth-float-card-2">
              <v-icon size="16" class="auth-float-icon">mdi-chart-line</v-icon>
              <div>
                <div class="auth-float-value">96.4%</div>
                <div class="auth-float-label">On-time delivery</div>
              </div>
            </div>

            <!-- Mini animated bar chart -->
            <div class="auth-mini-chart">
              <div class="auth-chart-bar" style="--bar-h: 40%" />
              <div class="auth-chart-bar" style="--bar-h: 65%" />
              <div class="auth-chart-bar" style="--bar-h: 50%" />
              <div class="auth-chart-bar" style="--bar-h: 82%" />
              <div class="auth-chart-bar" style="--bar-h: 60%" />
              <div class="auth-chart-bar" style="--bar-h: 90%" />
              <div class="auth-chart-bar" style="--bar-h: 72%" />
            </div>
          </div>

          <div class="auth-brand-content">
            <NuxtLink to="/" class="auth-logo-link">
              <div class="auth-logo-badge">
                <img src="/logo.png" alt="DomendraFleet" style="width: 100%; height: 100%; object-fit: contain; border-radius: 10px;" />
              </div>
              <span class="auth-logo-text">DomendraFleet</span>
            </NuxtLink>

            <h2 class="auth-headline">
              Manage your entire<br />fleet ecosystem
            </h2>
            <p class="auth-subline">
              Everything from dispatch, fuel, maintenance, billing, and telematics —
              all in one unified, premium platform.
            </p>

            <ul class="auth-features">
              <li>
                <v-icon size="20" class="auth-feature-icon">mdi-shield-check-outline</v-icon>
                <span>Multi-tenant secure architecture</span>
              </li>
              <li>
                <v-icon size="20" class="auth-feature-icon">mdi-chart-line</v-icon>
                <span>Real-time analytics and reporting</span>
              </li>
              <li>
                <v-icon size="20" class="auth-feature-icon">mdi-truck-fast</v-icon>
                <span>Dispatch, IFTA, and DVIR compliance</span>
              </li>
            </ul>

            <div class="auth-brand-footer">
              <div class="auth-avatars">
                <div class="auth-mini-avatar">A</div>
                <div class="auth-mini-avatar" style="margin-left: -10px">B</div>
                <div class="auth-mini-avatar" style="margin-left: -10px">C</div>
              </div>
              <p>Trusted by fleet operators worldwide</p>
            </div>
          </div>
        </div>

        <!-- Right: Form Panel -->
        <div class="auth-form-panel">
          <NuxtLink to="/" class="auth-back-link">
            <v-icon size="16">mdi-arrow-left</v-icon> Back to site
          </NuxtLink>

          <div class="auth-form-wrapper auth-form-enter">
            <slot />
          </div>
        </div>
      </div>
    </v-main>
  </v-app>
</template>

<style scoped>
.auth-main {
  background: rgb(var(--v-theme-background));
  min-height: 100vh;
}

.auth-container {
  display: flex;
  min-height: 100vh;
}

/* ---- Brand Panel ---- */
.auth-brand {
  position: relative;
  flex: 0 0 46%;
  overflow: hidden;
  background: linear-gradient(135deg, #4f46e5 0%, #4338ca 50%, #312e81 100%);
  display: none;
}

.auth-brand-bg {
  position: absolute;
  inset: 0;
  overflow: hidden;
}

.auth-blob {
  position: absolute;
  border-radius: 50%;
  filter: blur(80px);
}

.auth-blob-1 {
  top: -160px;
  right: -120px;
  width: 360px;
  height: 360px;
  background: rgba(129, 140, 248, 0.18);
}

.auth-blob-2 {
  bottom: -180px;
  left: -100px;
  width: 380px;
  height: 380px;
  background: rgba(165, 180, 252, 0.14);
}

/* ---- Fleet Animation ---- */
.auth-fleet-anim {
  position: absolute;
  inset: 0;
  z-index: 1;
  pointer-events: none;
  overflow: hidden;
}

.auth-fleet-svg {
  position: absolute;
  top: 55%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 118%;
  max-width: 600px;
  opacity: 0.55;
}

.auth-fleet-path {
  fill: none;
  stroke-width: 1;
  stroke-dasharray: 5 7;
}

.auth-fleet-path-1 { stroke: rgba(129,140,248,0.4); }
.auth-fleet-path-2 { stroke: rgba(195,197,255,0.32); }

.auth-fleet-svg .auth-fleet-trace {
  fill: none;
  stroke-width: 2;
  stroke-linecap: round;
  stroke-dasharray: 120 1000;
  animation: auth-fleet-draw 5s ease-in-out infinite;
}
.auth-fleet-trace-1 { stroke: url(#routeGrad1); animation-delay: 0s; }
.auth-fleet-trace-2 { stroke: url(#routeGrad2); animation-delay: 1.4s; }

@keyframes auth-fleet-draw {
  0%   { stroke-dashoffset: 200; opacity: 0; }
  20%  { opacity: 1; }
  80%  { opacity: 1; }
  100% { stroke-dashoffset: -680; opacity: 0; }
}

.auth-fleet-vehicle {
  animation-fill-mode: both;
  animation-timing-function: ease-in-out;
  animation-iteration-count: infinite;
  will-change: transform;
}
.auth-fleet-vehicle-1 {
  offset-path: path('M40,50 C110,70 120,20 190,55 C250,85 260,30 320,40');
  animation-name: auth-fleet-move, auth-fleet-fade;
  animation-duration: 5s, 5s;
  animation-delay: 0s, 0s;
}
.auth-fleet-vehicle-2 {
  offset-path: path('M60,150 C140,130 170,180 240,140 C280,120 280,170 290,160');
  animation-name: auth-fleet-move, auth-fleet-fade;
  animation-duration: 6.5s, 6.5s;
  animation-delay: 1.2s, 1.2s;
}

@keyframes auth-fleet-move {
  from { offset-distance: 0%; }
  to   { offset-distance: 100%; }
}
@keyframes auth-fleet-fade {
  0%   { opacity: 0; }
  10%  { opacity: 1; }
  90%  { opacity: 1; }
  100% { opacity: 0; }
}

.auth-fleet-ping {
  transform-box: fill-box;
  transform-origin: center;
  animation: auth-fleet-ping 1.6s ease-out infinite;
}
@keyframes auth-fleet-ping {
  0%   { transform: scale(1); opacity: 0.5; }
  100% { transform: scale(2.6); opacity: 0; }
}

/* Floating stats cards */
.auth-float-card {
  position: absolute;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 16px;
  border-radius: 14px;
  background: rgba(255,255,255,0.1);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255,255,255,0.18);
  color: #fff;
  box-shadow: 0 8px 32px rgba(30, 27, 75, 0.25);
  will-change: transform;
}
.auth-float-card-1 {
  top: 14%;
  right: 8%;
  animation: auth-float-a 7s ease-in-out infinite;
}
.auth-float-card-2 {
  bottom: 26%;
  left: 6%;
  animation: auth-float-b 8s ease-in-out infinite;
}
.auth-float-icon { color: #a5b4fc; }
.auth-float-value { font-size: 18px; font-weight: 750; line-height: 1.1; }
.auth-float-label { font-size: 11px; color: rgba(255,255,255,0.62); }

@keyframes auth-float-a {
  0%, 100% { transform: translateY(0) rotate(-1deg); }
  50%      { transform: translateY(-12px) rotate(1deg); }
}
@keyframes auth-float-b {
  0%, 100% { transform: translateY(0) rotate(1deg); }
  50%      { transform: translateY(-10px) rotate(-1deg); }
}

/* Mini bar chart at bottom */
.auth-mini-chart {
  position: absolute;
  bottom: 7%;
  right: 10%;
  display: flex;
  align-items: flex-end;
  gap: 5px;
  height: 54px;
  opacity: 0.85;
}
.auth-chart-bar {
  width: 7px;
  height: var(--bar-h);
  border-radius: 3px 3px 0 0;
  background: linear-gradient(180deg, #818cf8, #4f46e5);
  transform-origin: bottom;
  animation: auth-bar-bounce 2.8s ease-in-out infinite;
}
.auth-chart-bar:nth-child(1) { animation-delay: 0s; }
.auth-chart-bar:nth-child(2) { animation-delay: 0.15s; }
.auth-chart-bar:nth-child(3) { animation-delay: 0.3s; }
.auth-chart-bar:nth-child(4) { animation-delay: 0.45s; }
.auth-chart-bar:nth-child(5) { animation-delay: 0.6s; }
.auth-chart-bar:nth-child(6) { animation-delay: 0.75s; }
.auth-chart-bar:nth-child(7) { animation-delay: 0.9s; }

@keyframes auth-bar-bounce {
  0%, 100% { transform: scaleY(1); opacity: 0.9; }
  50%      { transform: scaleY(0.55); opacity: 0.6; }
}

.auth-grid-pattern {
  position: absolute;
  inset: 0;
  background-image:
    linear-gradient(rgba(255,255,255,0.05) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255,255,255,0.05) 1px, transparent 1px);
  background-size: 40px 40px;
  mask-image: radial-gradient(ellipse at center, rgba(0,0,0,0.6), transparent 75%);
  -webkit-mask-image: radial-gradient(ellipse at center, rgba(0,0,0,0.6), transparent 75%);
}

.auth-brand-content {
  position: relative;
  z-index: 2;
  padding: 48px 56px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  height: 100%;
  color: #fff;
}

@keyframes auth-fade-up {
  from { opacity: 0; transform: translateY(18px); }
  to   { opacity: 1; transform: translateY(0); }
}
.auth-logo-link   { animation: auth-fade-up 0.6s ease 0.05s both; }
.auth-headline   { animation: auth-fade-up 0.6s ease 0.15s both; }
.auth-subline    { animation: auth-fade-up 0.6s ease 0.25s both; }
.auth-features   { animation: auth-fade-up 0.6s ease 0.35s both; }
.auth-brand-footer { animation: auth-fade-up 0.6s ease 0.45s both; }

.auth-logo-link {
  display: inline-flex;
  align-items: center;
  gap: 12px;
  text-decoration: none;
  margin-bottom: 48px;
}

.auth-logo-badge {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  background: rgba(255,255,255,0.12);
  backdrop-filter: blur(8px);
  border: 1px solid rgba(255,255,255,0.2);
  display: flex;
  align-items: center;
  justify-content: center;
}

.auth-logo-text {
  font-size: 20px;
  font-weight: 700;
  color: #fff;
  letter-spacing: -0.01em;
}

.auth-headline {
  font-size: 30px;
  font-weight: 750;
  line-height: 1.25;
  margin-bottom: 16px;
  letter-spacing: -0.02em;
}

.auth-subline {
  font-size: 15px;
  line-height: 1.6;
  color: rgba(255,255,255,0.72);
  margin-bottom: 40px;
  max-width: 400px;
}

.auth-features {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.auth-features li {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 14px;
  font-weight: 500;
  color: rgba(255,255,255,0.88);
}

.auth-feature-icon {
  color: #a5b4fc;
}

.auth-brand-footer {
  margin-top: 64px;
  padding-top: 24px;
  border-top: 1px solid rgba(255,255,255,0.12);
  display: flex;
  align-items: center;
  gap: 12px;
}

.auth-brand-footer p {
  font-size: 13px;
  color: rgba(255,255,255,0.6);
  margin: 0;
}

.auth-avatars {
  display: flex;
}

.auth-mini-avatar {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  background: linear-gradient(135deg, #818cf8, #6366f1);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 700;
  color: #fff;
  border: 2px solid rgba(255,255,255,0.25);
}

/* ---- Form Panel ---- */
.auth-form-panel {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px;
  position: relative;
  background: rgb(var(--v-theme-surface));
}

.auth-back-link {
  position: absolute;
  top: 32px;
  left: 40px;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  color: rgba(var(--v-theme-on-surface), 0.6);
  font-size: 13px;
  font-weight: 500;
  text-decoration: none;
  transition: color 0.15s ease;
}

.auth-back-link:hover {
  color: #6366f1;
}

.auth-form-wrapper {
  width: 100%;
  max-width: 420px;
}

/* ---- Responsive ---- */
@media (min-width: 960px) {
  .auth-brand {
    display: block;
  }
}

/* Reduced motion: keep visuals static, no movement */
@media (prefers-reduced-motion: reduce) {
  .auth-fleet-svg .auth-fleet-trace,
  .auth-fleet-vehicle,
  .auth-fleet-ping,
  .auth-float-card,
  .auth-chart-bar,
  .auth-form-enter {
    animation: none !important;
  }
  .auth-fleet-trace { stroke-dashoffset: 0; opacity: 1; }
  .auth-fleet-vehicle { opacity: 1; }
}

/* Form entrance */
@keyframes auth-form-in {
  from { opacity: 0; transform: translateY(16px); }
  to   { opacity: 1; transform: translateY(0); }
}
.auth-form-enter {
  animation: auth-form-in 0.6s ease both;
}
</style>

