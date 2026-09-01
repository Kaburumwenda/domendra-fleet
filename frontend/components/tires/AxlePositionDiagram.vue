<template>
  <div class="axle-diagram-wrap">
    <div class="axle-stage">
      <div class="axle-floor"></div>
      <div class="axle-canvas-wrap">
        <svg viewBox="0 0 640 540" class="axle-svg" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <!-- Tire tread gradient -->
            <radialGradient id="d-treadGrad" cx="40%" cy="36%" r="68%">
              <stop offset="0%" stop-color="#2d3748" />
              <stop offset="50%" stop-color="#1a202c" />
              <stop offset="100%" stop-color="#0f141e" />
            </radialGradient>
            <!-- Sidewall gradient -->
            <radialGradient id="d-sidewallGrad" cx="42%" cy="38%" r="70%">
              <stop offset="0%" stop-color="#4a5568" />
              <stop offset="60%" stop-color="#2d3748" />
              <stop offset="100%" stop-color="#171c27" />
            </radialGradient>
            <!-- Rim metallic -->
            <radialGradient id="d-rimMetal" cx="38%" cy="34%" r="70%">
              <stop offset="0%" stop-color="#ffffff" />
              <stop offset="30%" stop-color="#e2e8f0" />
              <stop offset="65%" stop-color="#94a3b8" />
              <stop offset="100%" stop-color="#475569" />
            </radialGradient>
            <!-- Brake drum -->
            <radialGradient id="d-drumGrad" cx="40%" cy="36%" r="68%">
              <stop offset="0%" stop-color="#6b7280" />
              <stop offset="50%" stop-color="#374151" />
              <stop offset="100%" stop-color="#1f2937" />
            </radialGradient>
            <!-- Axle tube gradient -->
            <linearGradient id="d-axleGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stop-color="#4b5563" />
              <stop offset="40%" stop-color="#9ca3af" />
              <stop offset="100%" stop-color="#374151" />
            </linearGradient>
            <!-- Differential pumpkin -->
            <radialGradient id="d-pumpkinGrad" cx="36%" cy="32%" r="72%">
              <stop offset="0%" stop-color="#a78bfa" />
              <stop offset="50%" stop-color="#7c3aed" />
              <stop offset="100%" stop-color="#5b21b6" />
            </radialGradient>
            <!-- Frame rails -->
            <linearGradient id="d-frameGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stop-color="#4b5563" />
              <stop offset="40%" stop-color="#94a3b8" />
              <stop offset="100%" stop-color="#374151" />
            </linearGradient>
            <!-- Transmission / diff body -->
            <radialGradient id="d-diffGrad" cx="38%" cy="34%" r="70%">
              <stop offset="0%" stop-color="#9ca3af" />
              <stop offset="50%" stop-color="#6b7280" />
              <stop offset="100%" stop-color="#374151" />
            </radialGradient>
            <!-- Transfer case -->
            <radialGradient id="d-transferGrad" cx="36%" cy="32%" r="72%">
              <stop offset="0%" stop-color="#cbd5e1" />
              <stop offset="50%" stop-color="#64748b" />
              <stop offset="100%" stop-color="#1e293b" />
            </radialGradient>
            <!-- Engine block -->
            <linearGradient id="d-engineGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stop-color="#4b5563" />
              <stop offset="40%" stop-color="#6b7280" />
              <stop offset="100%" stop-color="#374151" />
            </linearGradient>
            <!-- Engine valve cover -->
            <linearGradient id="d-valveGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stop-color="#fbbf24" />
              <stop offset="50%" stop-color="#d97706" />
              <stop offset="100%" stop-color="#b45309" />
            </linearGradient>
            <!-- Cab body -->
            <linearGradient id="d-cabGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stop-color="#1e40af" />
              <stop offset="50%" stop-color="#1d4ed8" />
              <stop offset="100%" stop-color="#1e3a8a" />
            </linearGradient>
            <!-- Bed body -->
            <linearGradient id="d-bedGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stop-color="#1e1b4b" />
              <stop offset="100%" stop-color="#111827" />
            </linearGradient>
            <!-- Ground gradient -->
            <radialGradient id="d-groundGrad" cx="50%" cy="50%" r="55%">
              <stop offset="0%" stop-color="#e2e8f0" />
              <stop offset="100%" stop-color="#cbd5e1" />
            </radialGradient>
            <!-- Leaf spring gradient -->
            <linearGradient id="d-springGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stop-color="#6b7280" />
              <stop offset="30%" stop-color="#9ca3af" />
              <stop offset="100%" stop-color="#4b5563" />
            </linearGradient>
            <!-- Shock absorber -->
            <linearGradient id="d-shockGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stop-color="#cbd5e1" />
              <stop offset="50%" stop-color="#6b7280" />
              <stop offset="100%" stop-color="#374151" />
            </linearGradient>
            <!-- Exhaust pipe -->
            <linearGradient id="d-exhaustGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stop-color="#9ca3af" />
              <stop offset="50%" stop-color="#6b7280" />
              <stop offset="100%" stop-color="#4b5563" />
            </linearGradient>
            <!-- Muffler -->
            <linearGradient id="d-mufflerGrad" x1="0" y1="0" x2="1" y2="0">
              <stop offset="0%" stop-color="#9ca3af" />
              <stop offset="50%" stop-color="#d1d5db" />
              <stop offset="100%" stop-color="#6b7280" />
            </linearGradient>
            <!-- Filters -->
            <filter id="d-glow" x="-80%" y="-80%" width="260%" height="260%">
              <feGaussianBlur stdDeviation="6" result="b" />
              <feMerge><feMergeNode in="b" /><feMergeNode in="SourceGraphic" /></feMerge>
            </filter>
            <filter id="d-softShadow" x="-60%" y="-60%" width="220%" height="220%">
              <feGaussianBlur in="SourceAlpha" stdDeviation="5" />
              <feOffset dy="6" />
              <feComponentTransfer><feFuncA type="linear" slope="0.32" /></feComponentTransfer>
              <feMerge><feMergeNode /><feMergeNode in="SourceGraphic" /></feMerge>
            </filter>
            <filter id="d-wheelShadow" x="-60%" y="-60%" width="220%" height="220%">
              <feGaussianBlur in="SourceAlpha" stdDeviation="3" />
              <feOffset dy="4" />
              <feComponentTransfer><feFuncA type="linear" slope="0.4" /></feComponentTransfer>
              <feMerge><feMergeNode /><feMergeNode in="SourceGraphic" /></feMerge>
            </filter>
            <filter id="d-metalFlare" x="-50%" y="-50%" width="200%" height="200%">
              <feGaussianBlur stdDeviation="1" />
            </filter>
          </defs>

          <!-- Ground plane -->
          <ellipse cx="320" cy="492" rx="280" ry="38" fill="url(#d-groundGrad)" />

          <!-- Floor grid lines like a real workshop -->
          <g stroke="#bfc9d4" stroke-width="0.8" opacity="0.4">
            <line v-for="gx in [100, 180, 260, 320, 380, 460, 540]" :key="'gx'+gx" :x1="gx" :y1="478" :x2="gx - 35" :y2="512" />
            <line v-for="gy in [462, 472, 484, 498, 510]" :key="'gy'+gy" :x1="80" :y1="gy" :x2="560" :y2="gy" />
          </g>

          <g v-if="axles.length">
            <!-- ====== LADDER FRAME CHASSIS ====== -->
            <g filter="url(#d-softShadow)">
              <g v-for="(side, si) in [{x: bodyLeft - 16, flip: 1}, {x: bodyRight - 4, flip: -1}]" :key="'rail'+si">
                <rect :x="side.x" :y="cabFrontY + 8" :width="12" :height="bedRearY - cabFrontY - 12" rx="3" fill="url(#d-frameGrad)" stroke="#1f2937" stroke-width="1" />
                <rect :x="side.x + (side.flip > 0 ? 2 : 0)" :y="cabFrontY + 14" :width="8" :height="bedRearY - cabFrontY - 24" rx="2" fill="#cbd5e1" opacity="0.2" />
                <circle v-for="fh in frameHoles" :key="'fh'+si+fh.y" :cx="side.x + 6" :cy="fh.y" r="2.5" fill="#1e293b" opacity="0.5" />
                <circle v-for="fr in frameRivets" :key="'fr'+si+fr.y" :cx="side.x + (side.flip > 0 ? 3 : 9)" :cy="fr.y" r="1.2" fill="#64748b" opacity="0.7" />
              </g>

              <rect v-for="(ax, ai) in axles" :key="'cm' + ai" :x="bodyLeft - 16" :y="ax.y - 6" :width="bodyRight - bodyLeft + 24" :height="12" rx="4" fill="url(#d-frameGrad)" stroke="#374151" stroke-width="0.8" opacity="0.85" />
              <rect :x="bodyLeft - 16" :y="cabRearY + 10" :width="bodyRight - bodyLeft + 24" :height="10" rx="3" fill="url(#d-frameGrad)" stroke="#374151" stroke-width="0.6" opacity="0.7" />
              <rect :x="bodyLeft - 16" :y="bedRearY - 16" :width="bodyRight - bodyLeft + 24" :height="10" rx="3" fill="url(#d-frameGrad)" stroke="#374151" stroke-width="0.6" opacity="0.7" />
              <polygon v-for="(ax, ai) in axles" :key="'guss'+ai" :points="`${bodyLeft - 16},${ax.y - 6} ${bodyLeft - 8},${ax.y - 6} ${bodyLeft - 16},${ax.y + 8}`" fill="#475569" opacity="0.5" />
              <polygon v-for="(ax, ai) in axles" :key="'guss2'+ai" :points="`${bodyRight + 8},${ax.y - 6} ${bodyRight + 16},${ax.y - 6} ${bodyRight + 16},${ax.y + 8}`" fill="#475569" opacity="0.5" />
            </g>

            <!-- ====== TRUCK CAB (FRONT) ====== -->
            <g filter="url(#d-softShadow)">
              <rect :x="cabLeft" :y="cabFrontY - 4" :width="cabWidth" :height="cabHeight" rx="12" fill="url(#d-cabGrad)" stroke="#1e3a8a" stroke-width="1" />
              <rect :x="cabLeft + 8" :y="cabFrontY - 10" :width="cabWidth - 16" :height="14" rx="7" fill="#2563eb" opacity="0.6" />
              <rect :x="cabLeft + 18" :y="cabFrontY + 10" :width="cabWidth - 36" :height="22" rx="4" fill="#60a5fa" opacity="0.5" stroke="#93c5fd" stroke-width="0.6" />
              <line :x1="cabLeft + 22" :y1="cabFrontY + 14" :x2="cabLeft + cabWidth - 22" :y2="cabFrontY + 14" stroke="#bfdbfe" stroke-width="1" opacity="0.6" />
              <rect :x="cabLeft + 4" :y="cabFrontY + 16" :width="16" :height="14" rx="3" fill="#60a5fa" opacity="0.35" stroke="#93c5fd" stroke-width="0.5" />
              <rect :x="cabRight - 20" :y="cabFrontY + 16" :width="16" :height="14" rx="3" fill="#60a5fa" opacity="0.35" stroke="#93c5fd" stroke-width="0.5" />
              <rect :x="cabLeft + 14" :y="cabFrontY + 36" :width="cabWidth - 28" :height="16" rx="3" fill="#1e293b" stroke="#0f172a" stroke-width="0.6" />
              <line v-for="gs in 5" :key="'gs'+gs" :x1="cabLeft + 22" :y1="cabFrontY + 38 + gs * 3" :x2="cabRight - 22" :y2="cabFrontY + 38 + gs * 3" stroke="#334155" stroke-width="0.8" />
              <rect :x="cabLeft + 6" :y="cabFrontY + 38" width="12" height="8" rx="2" fill="#fef08a" stroke="#ca8a04" stroke-width="0.5" filter="url(#d-glow)" />
              <rect :x="cabRight - 18" :y="cabFrontY + 38" width="12" height="8" rx="2" fill="#fef08a" stroke="#ca8a04" stroke-width="0.5" filter="url(#d-glow)" />
              <rect :x="cabLeft - 2" :y="cabFrontY + 54" :width="cabWidth + 4" :height="6" rx="2" fill="#475569" stroke="#1f2937" stroke-width="0.6" />
              <text :x="cabLeft + cabWidth / 2" :y="cabFrontY + 26" text-anchor="middle" font-size="10" font-weight="700" fill="#dbeafe" opacity="0.9">CAB</text>
            </g>

            <!-- ====== TRUCK BED / FLATBED (REAR) ====== -->
            <g filter="url(#d-softShadow)">
              <rect :x="bedLeft" :y="bedTopY" :width="bedWidth" :height="bedHeight" rx="8" fill="url(#d-bedGrad)" stroke="#111827" stroke-width="0.8" />
              <line v-for="bp in 6" :key="'bp'+bp" :x1="bedLeft + 6" :y1="bedTopY + 6 + bp * 6" :x2="bedRight - 6" :y2="bedTopY + 6 + bp * 6" stroke="#1f2937" stroke-width="0.6" opacity="0.5" />
              <rect :x="bedLeft" :y="bedTopY - 14" :width="6" :height="bedHeight + 14" rx="2" fill="#374151" stroke="#111827" stroke-width="0.6" />
              <rect :x="bedRight - 6" :y="bedTopY - 14" :width="6" :height="bedHeight + 14" rx="2" fill="#374151" stroke="#111827" stroke-width="0.6" />
              <rect v-for="sp in 3" :key="'sp'+sp" :x="bedLeft - 1" :y="bedTopY + 12 + sp * 18" width="8" height="8" rx="1" fill="#1f2937" stroke="#374151" stroke-width="0.5" />
              <rect v-for="sp in 3" :key="'spr'+sp" :x="bedRight - 7" :y="bedTopY + 12 + sp * 18" width="8" height="8" rx="1" fill="#1f2937" stroke="#374151" stroke-width="0.5" />
              <rect :x="bedRight - 8" :y="bedTopY + bedHeight - 16" width="6" height="10" rx="2" fill="#ef4444" stroke="#991b1b" stroke-width="0.5" filter="url(#d-glow)" />
              <rect :x="bedLeft + 2" :y="bedTopY + bedHeight - 16" width="6" height="10" rx="2" fill="#ef4444" stroke="#991b1b" stroke-width="0.5" filter="url(#d-glow)" />
            </g>

            <!-- ====== ENGINE (between frame rails, under cab) ====== -->
            <g filter="url(#d-softShadow)">
              <rect :x="bodyLeft + 8" :y="engineFrontY" :width="bodyRight - bodyLeft - 16" :height="engineHeight" rx="6" fill="url(#d-engineGrad)" stroke="#1f2937" stroke-width="1" />
              <rect :x="bodyLeft + 14" :y="engineFrontY + engineHeight - 6" :width="bodyRight - bodyLeft - 28" :height="10" rx="3" fill="#374151" stroke="#1f2937" stroke-width="0.8" />
              <rect :x="bodyLeft + 12" :y="engineFrontY - 4" :width="bodyRight - bodyLeft - 60" :height="8" rx="3" fill="url(#d-valveGrad)" stroke="#92400e" stroke-width="0.6" />
              <rect :x="bodyLeft + 48" :y="engineFrontY - 4" :width="bodyRight - bodyLeft - 60" :height="8" rx="3" fill="url(#d-valveGrad)" stroke="#92400e" stroke-width="0.6" />
              <circle v-for="vb in 4" :key="'vb'+vb" :cx="bodyLeft + 20 + vb * 20" :cy="engineFrontY" r="1.5" fill="#fbbf24" opacity="0.8" />
              <rect :x="bodyRight - 18" :y="engineFrontY - 8" :width="8" :height="14" rx="3" fill="#4b5563" stroke="#1f2937" stroke-width="0.5" />
              <circle :cx="bodyRight - 6" :cy="engineFrontY + engineHeight / 2" r="12" fill="none" stroke="#64748b" stroke-width="1.5" opacity="0.6" />
              <circle :cx="bodyRight - 6" :cy="engineFrontY + engineHeight / 2" r="4" fill="#475569" />
              <line v-for="fb in 5" :key="'fb'+fb" :x1="bodyRight - 6" :y1="engineFrontY + engineHeight / 2" :x2="bodyRight - 6 + Math.cos(fb * 1.256) * 12" :y2="engineFrontY + engineHeight / 2 + Math.sin(fb * 1.256) * 12" stroke="#94a3b8" stroke-width="1.5" opacity="0.5" />
              <circle :cx="bodyLeft + 18" :cy="engineFrontY + 4" r="3.5" fill="#fcd34d" stroke="#d97706" stroke-width="0.5" />
              <text :x="bodyLeft + 50" :y="engineFrontY + 16" font-size="7" font-weight="700" fill="#94a3b8" opacity="0.7">DIESEL ENGINE</text>
            </g>

            <!-- ====== TRANSMISSION ====== -->
            <g filter="url(#d-softShadow)">
              <ellipse :cx="transmissionCX" :cy="transmissionY + 4" rx="32" ry="14" fill="#4b5563" stroke="#1f2937" stroke-width="1" />
              <rect :x="transmissionCX - 20" :y="transmissionY - 6" :width="40" :height="28" rx="6" fill="url(#d-diffGrad)" stroke="#1f2937" stroke-width="0.8" />
              <rect :x="transmissionCX - 14" :y="transmissionY + 16" width="28" height="8" rx="3" fill="#374151" stroke="#1f2937" stroke-width="0.6" />
              <circle :cx="transmissionCX" :cy="transmissionY + 4" r="6" fill="#64748b" stroke="#1f2937" stroke-width="0.6" />
              <circle :cx="transmissionCX" :cy="transmissionY + 4" r="2.5" fill="#0f172a" />
              <line :x1="transmissionCX + 20" :y1="transmissionY" :x2="transmissionCX + 32" :y2="transmissionY - 8" stroke="#cbd5e1" stroke-width="1.5" opacity="0.5" />
              <line :x1="transmissionCX + 20" :y1="transmissionY + 8" :x2="transmissionCX + 32" :y2="transmissionY + 16" stroke="#cbd5e1" stroke-width="1.5" opacity="0.5" />
              <rect :x="transmissionCX - 10" :y="transmissionY + 24" width="20" height="6" rx="3" fill="#1f2937" />
            </g>

            <!-- ====== LONGITUDINAL DRIVESHAFT ====== -->
            <g v-if="driveshaftSpan">
              <line :x1="driveshaftSpan.x1" :y1="driveshaftSpan.y1" :x2="driveshaftSpan.x2" :y2="driveshaftSpan.y2" stroke="#4b5563" stroke-width="18" stroke-linecap="round" filter="url(#d-wheelShadow)" />
              <line :x1="driveshaftSpan.x1" :y1="driveshaftSpan.y1" :x2="driveshaftSpan.x2" :y2="driveshaftSpan.y2" stroke="#cbd5e1" stroke-width="10" stroke-linecap="round" />
              <line :x1="driveshaftSpan.x1" :y1="driveshaftSpan.y1" :x2="driveshaftSpan.x2" :y2="driveshaftSpan.y2" stroke="#f1f5f9" stroke-width="4" stroke-linecap="round" opacity="0.5" />
              <rect :x="(driveshaftSpan.x1 + driveshaftSpan.x2) / 2 - 6" :y="driveshaftSpan.y1 - 12" width="12" height="24" rx="2" fill="#374151" opacity="0.4" />
              <!-- Front U-joint -->
              <circle :cx="driveshaftSpan.x1" :cy="driveshaftSpan.y1" r="12" fill="#475569" stroke="#1f2937" stroke-width="1.2" />
              <line :x1="driveshaftSpan.x1 - 10" :y1="driveshaftSpan.y1" :x2="driveshaftSpan.x1 + 10" :y2="driveshaftSpan.y1" stroke="#cbd5e1" stroke-width="3" stroke-linecap="round" opacity="0.7" />
              <line :x1="driveshaftSpan.x1" :y1="driveshaftSpan.y1 - 10" :x2="driveshaftSpan.x1" :y2="driveshaftSpan.y1 + 10" stroke="#cbd5e1" stroke-width="3" stroke-linecap="round" opacity="0.7" />
              <circle :cx="driveshaftSpan.x1 - 10" :cy="driveshaftSpan.y1" r="2.5" fill="#94a3b8" />
              <circle :cx="driveshaftSpan.x1 + 10" :cy="driveshaftSpan.y1" r="2.5" fill="#94a3b8" />
              <circle :cx="driveshaftSpan.x1" :cy="driveshaftSpan.y1 - 10" r="2.5" fill="#94a3b8" />
              <circle :cx="driveshaftSpan.x1" :cy="driveshaftSpan.y1 + 10" r="2.5" fill="#94a3b8" />
              <!-- Center bearing -->
              <g v-if="hasCenterBearing">
                <rect :x="centerBearingX - 8" :y="centerBearingY - 10" width="16" height="20" rx="4" fill="#374151" stroke="#1f2937" stroke-width="0.8" />
                <circle :cx="centerBearingX" :cy="centerBearingY" r="5" fill="#475569" stroke="#1f2937" stroke-width="0.6" />
                <circle :cx="centerBearingX" :cy="centerBearingY" r="2.5" fill="#0f172a" />
                <rect :x="centerBearingX - 4" :y="centerBearingY + 10" width="8" height="8" rx="2" fill="#1f2937" />
              </g>
              <!-- Rear U-joint -->
              <circle :cx="driveshaftSpan.x2" :cy="driveshaftSpan.y2" r="12" fill="#475569" stroke="#1f2937" stroke-width="1.2" />
              <line :x1="driveshaftSpan.x2 - 10" :y1="driveshaftSpan.y2" :x2="driveshaftSpan.x2 + 10" :y2="driveshaftSpan.y2" stroke="#cbd5e1" stroke-width="3" stroke-linecap="round" opacity="0.7" />
              <line :x1="driveshaftSpan.x2" :y1="driveshaftSpan.y2 - 10" :x2="driveshaftSpan.x2" :y2="driveshaftSpan.y2 + 10" stroke="#cbd5e1" stroke-width="3" stroke-linecap="round" opacity="0.7" />
              <circle :cx="driveshaftSpan.x2 - 10" :cy="driveshaftSpan.y2" r="2.5" fill="#94a3b8" />
              <circle :cx="driveshaftSpan.x2 + 10" :cy="driveshaftSpan.y2" r="2.5" fill="#94a3b8" />
              <circle :cx="driveshaftSpan.x2" :cy="driveshaftSpan.y2 - 10" r="2.5" fill="#94a3b8" />
              <circle :cx="driveshaftSpan.x2" :cy="driveshaftSpan.y2 + 10" r="2.5" fill="#94a3b8" />
              <circle :cx="driveshaftSpan.x2" :cy="driveshaftSpan.y2" r="4" fill="#0f172a" />
            </g>

            <!-- ====== TRANSFER CASE (4WD only) ====== -->
            <g v-if="hasMultiplePoweredAxles" :transform="`translate(320 ${transferCaseY})`">
              <rect x="-22" y="-18" width="44" height="36" rx="8" fill="url(#d-transferGrad)" stroke="#1f2937" stroke-width="1.2" filter="url(#d-wheelShadow)" />
              <rect x="-16" y="-12" width="32" height="10" rx="4" fill="#1e293b" opacity="0.4" />
              <rect x="-16" y="4" width="32" height="8" rx="3" fill="#1e293b" opacity="0.3" />
              <circle cx="0" cy="8" r="5" fill="#64748b" stroke="#1f2937" stroke-width="0.6" />
              <circle cx="0" cy="8" r="2.5" fill="#0f172a" />
              <line x1="-22" y1="-8" x2="-34" y2="-14" stroke="#94a3b8" stroke-width="2" opacity="0.5" />
            </g>

            <!-- ====== EXHAUST SYSTEM ====== -->
            <g opacity="0.7">
              <path :d="`M ${bodyRight - 6} ${engineFrontY + engineHeight} Q ${bodyRight + 20} ${engineFrontY + engineHeight + 10} ${bodyRight + 16} ${engineFrontY + engineHeight + 30}`" fill="none" stroke="url(#d-exhaustGrad)" stroke-width="5" stroke-linecap="round" />
              <rect :x="bodyRight + 8" :y="engineFrontY + engineHeight + 30" width="28" height="14" rx="6" fill="url(#d-mufflerGrad)" stroke="#4b5563" stroke-width="0.8" filter="url(#d-metalFlare)" />
              <line :x1="bodyRight + 14" :y1="engineFrontY + engineHeight + 30" :x2="bodyRight + 14" :y2="engineFrontY + engineHeight + 44" stroke="#64748b" stroke-width="0.6" />
              <line :x1="bodyRight + 22" :y1="engineFrontY + engineHeight + 30" :x2="bodyRight + 22" :y2="engineFrontY + engineHeight + 44" stroke="#64748b" stroke-width="0.6" />
              <path :d="`M ${bodyRight + 36} ${engineFrontY + engineHeight + 37} Q ${bodyRight + 50} ${engineFrontY + engineHeight + 37} ${bodyRight + 48} ${engineFrontY + engineHeight + 50}`" fill="none" stroke="#6b7280" stroke-width="4" stroke-linecap="round" />
              <line :x1="bodyRight + 14" :y1="engineFrontY + engineHeight + 30" :x2="bodyRight + 14" :y2="engineFrontY + engineHeight + 28" stroke="#475569" stroke-width="1.5" />
              <line :x1="bodyRight + 22" :y1="engineFrontY + engineHeight + 30" :x2="bodyRight + 22" :y2="engineFrontY + engineHeight + 28" stroke="#475569" stroke-width="1.5" />
            </g>

            <!-- ====== DIFFERENTIALS ====== -->
            <g v-for="(ax, ai) in axles" :key="'drv' + ai">
              <template v-if="isPowered(ax.role)">
                <g :transform="`translate(320 ${ax.y})`">
                  <ellipse rx="28" ry="18" fill="url(#d-pumpkinGrad)" stroke="#4c1d95" stroke-width="1.4" filter="url(#d-wheelShadow)" />
                  <line v-for="fi in 6" :key="'fin'+fi" :x1="-22 + fi * 8" :y1="-16" :x2="-22 + fi * 8" :y2="16" stroke="#7c3aed" stroke-width="1.2" opacity="0.4" />
                  <ellipse cx="-6" cy="-6" rx="14" ry="6" fill="#a78bfa" opacity="0.3" />
                  <circle v-for="db in 8" :key="'db'+db" :cx="Math.cos(db * 0.785) * 18" :cy="Math.sin(db * 0.785) * 11" r="1.5" fill="#d8b4fe" opacity="0.6" />
                  <circle cx="0" cy="0" r="8" fill="#64748b" stroke="#1f2937" stroke-width="0.8" />
                  <circle cx="0" cy="0" r="3" fill="#0f172a" />
                  <circle cx="0" cy="0" r="6" fill="none" stroke="#cbd5e1" stroke-width="2" opacity="0.6" />
                  <rect x="-30" y="-10" width="6" height="20" rx="2" fill="#374151" stroke="#1f2937" stroke-width="0.5" />
                  <rect x="24" y="-10" width="6" height="20" rx="2" fill="#374151" stroke="#1f2937" stroke-width="0.5" />
                </g>
              </template>
            </g>

            <!-- ====== AXLE TUBES, HALF-SHAFTS & SUSPENSION PER AXLE ====== -->
            <g v-for="(axle, ai) in axles" :key="'axle'+ai">
              <!-- Axle tubes -->
              <g v-for="pos in axle.positions" :key="'tube'+pos.code">
                <template v-if="pos.side === 'L'">
                  <line :x1="320" :y1="axle.y" :x2="pos.x" :y2="axle.y" stroke="url(#d-axleGrad)" stroke-width="14" stroke-linecap="round" />
                  <line :x1="320" :y1="axle.y" :x2="pos.x" :y2="axle.y" stroke="#cbd5e1" stroke-width="3" stroke-linecap="round" opacity="0.25" />
                </template>
              </g>

              <!-- Leaf springs -->
              <g v-for="(side, si) in ['L', 'R']" :key="'spring'+ai+si">
                <g :transform="`translate(${side === 'L' ? (axle.dual ? bodyLeft - 42 : bodyLeft - 28) : (axle.dual ? bodyRight + 42 : bodyRight + 28)}, ${axle.y})`">
                  <path d="M -8 -8 Q 0 -16 8 -8" fill="none" stroke="url(#d-springGrad)" stroke-width="4" stroke-linecap="round" />
                  <path d="M -6 -5 Q 0 -12 6 -5" fill="none" stroke="#64748b" stroke-width="3" stroke-linecap="round" opacity="0.8" />
                  <path d="M -4 -3 Q 0 -8 4 -3" fill="none" stroke="#4b5563" stroke-width="2.5" stroke-linecap="round" opacity="0.7" />
                  <circle cx="-8" cy="-8" r="2.5" fill="#475569" stroke="#1f2937" stroke-width="0.5" />
                  <circle cx="8" cy="-8" r="2.5" fill="#475569" stroke="#1f2937" stroke-width="0.5" />
                  <rect x="-4" y="-6" width="8" height="8" rx="1" fill="#374151" opacity="0.7" />
                </g>
              </g>

              <!-- Shock absorbers -->
              <g v-for="(side, si) in ['L', 'R']" :key="'shock'+ai+si">
                <g :transform="`translate(${side === 'L' ? bodyLeft - 10 : bodyRight + 10}, ${axle.y})`">
                  <rect x="-2" y="-14" width="4" height="28" rx="2" fill="url(#d-shockGrad)" stroke="#1f2937" stroke-width="0.5" />
                  <line x1="0" y1="-18" x2="0" y2="-14" stroke="#cbd5e1" stroke-width="2" />
                  <circle cx="0" cy="-18" r="2.5" fill="#475569" stroke="#1f2937" stroke-width="0.5" />
                  <circle cx="0" cy="14" r="2.5" fill="#475569" stroke="#1f2937" stroke-width="0.5" />
                  <path d="M -5 -10 Q -6 -6 -5 -2 Q -4 2 -5 6 Q -6 10 -5 12" fill="none" stroke="#64748b" stroke-width="2.5" opacity="0.5" />
                  <path d="M 5 -10 Q 6 -6 5 -2 Q 4 2 5 6 Q 6 10 5 12" fill="none" stroke="#64748b" stroke-width="2.5" opacity="0.5" />
                </g>
              </g>

              <!-- Brake drums / calipers -->
              <g v-for="pos in axle.positions" :key="'brake'+pos.code">
                <g :transform="`translate(${pos.x} ${axle.y})`">
                  <circle :r="pos.r * 0.35 + 3" fill="none" stroke="#b91c1c" stroke-width="3" opacity="0.6" />
                  <rect :x="-pos.r * 0.1" :y="-pos.r * 0.22" :width="pos.r * 0.2" :height="pos.r * 0.44" rx="2" fill="#dc2626" stroke="#991b1b" stroke-width="0.5" opacity="0.7" />
                  <line :x1="0" :y1="-pos.r * 0.3" :x2="0" :y2="-pos.r * 0.4" stroke="#cbd5e1" stroke-width="1" />
                </g>
              </g>
            </g>

            <!-- ====== WHEELS ====== -->
            <g v-for="(axle, ai) in axles" :key="'wh'+ai">
              <text :x="axle.rightEdge + 10" :y="axle.y + 4" font-size="11" font-weight="700" fill="#64748b">{{ axle.label }}</text>

              <g v-for="pos in axle.positions" :key="pos.code"
                 :transform="`translate(${pos.x} ${pos.y})`"
                 class="wheel-g">
                <!-- Tire shadow on ground -->
                <ellipse :cx="0" :cy="pos.r * 1.58" :rx="pos.r * 0.6" :ry="pos.r * 0.14" fill="#000" opacity="0.25" />

                <!-- Mounted / highlighted tire (single-tire mode: this.position) -->
                <g v-if="!mountedTires && pos.code === position" filter="url(#d-wheelShadow)">
                  <g transform="scale(1, 1.6)">
                    <circle :r="pos.r" fill="url(#d-treadGrad)" stroke="#0f141e" stroke-width="1.2" />
                    <circle :r="pos.r * 0.85" fill="none" stroke="#0f172a" stroke-width="1.2" opacity="0.4" />
                    <circle :r="pos.r * 0.75" fill="none" stroke="#0f172a" stroke-width="1.2" opacity="0.4" />
                    <path :d="treadBevelPath(pos.r)" fill="#475569" opacity="0.5" />
                    <circle :r="pos.r * 0.78" fill="url(#d-sidewallGrad)" />
                    <circle :r="pos.r * 0.78" fill="none" stroke="#0f141e" stroke-width="1" opacity="0.5" />
                    <text :y="-pos.r * 0.42" text-anchor="middle" font-size="5" font-weight="700" fill="#64748b" opacity="0.6">{{ tireBrand }}</text>
                    <text :y="pos.r * 0.58" text-anchor="middle" font-size="4.5" font-weight="600" fill="#4b5563" opacity="0.5">{{ tireSize }}</text>
                    <circle :r="pos.r * 0.64" fill="url(#d-rimMetal)" stroke="#475569" stroke-width="0.8" />
                    <circle :r="pos.r * 0.64" fill="none" stroke="#64748b" stroke-width="1.2" opacity="0.4" />
                    <circle :r="pos.r * 0.64" fill="none" stroke="#e2e8f0" stroke-width="0.8" opacity="0.5" />
                    <g stroke="#cbd5e1" stroke-width="2.6" stroke-linecap="round" opacity="0.85">
                      <line v-for="s in spokes(pos.r)" :key="s.i" :x1="s.x1" :y1="s.y1" :x2="s.x2" :y2="s.y2" />
                    </g>
                    <g fill="#334155" stroke="#1e293b" stroke-width="0.6">
                      <circle v-for="l in lugNuts(pos.r)" :key="l.i" :cx="l.x" :cy="l.y" r="2.6" />
                      <circle v-for="l in lugNuts(pos.r)" :key="'lh'+l.i" :cx="l.x - 0.5" :cy="l.y - 0.5" r="1" fill="#64748b" opacity="0.4" />
                    </g>
                    <circle :r="pos.r * 0.16" fill="#1e293b" />
                    <circle :cx="-pos.r * 0.04" :cy="-pos.r * 0.04" :r="pos.r * 0.06" fill="#64748b" opacity="0.6" />
                    <circle :r="pos.r * 0.08" fill="#94a3b8" stroke="#475569" stroke-width="0.5" />
                    <circle :r="pos.r * 0.04" fill="#1e293b" />
                    <circle :r="pos.r * 0.20" fill="none" stroke="#64748b" stroke-width="0.5" opacity="0.7" />
                  </g>
                  <text :y="pos.r * 1.6 + 12" text-anchor="middle" font-size="8" font-weight="700" fill="#065f46" font-family="monospace">{{ tireSerial }}</text>
                </g>

                <!-- Mounted tire from vehicle-wide mountedTires map -->
                <g v-else-if="mountedTires && mountedAt(pos.code)" filter="url(#d-wheelShadow)">
                  <g transform="scale(1, 1.6)">
                    <circle :r="pos.r" fill="url(#d-treadGrad)" stroke="#0f141e" stroke-width="1.2" />
                    <circle :r="pos.r * 0.85" fill="none" stroke="#0f172a" stroke-width="1.2" opacity="0.4" />
                    <circle :r="pos.r * 0.75" fill="none" stroke="#0f172a" stroke-width="1.2" opacity="0.4" />
                    <path :d="treadBevelPath(pos.r)" fill="#475569" opacity="0.5" />
                    <circle :r="pos.r * 0.78" fill="url(#d-sidewallGrad)" />
                    <circle :r="pos.r * 0.78" fill="none" stroke="#0f141e" stroke-width="1" opacity="0.5" />
                    <text :y="-pos.r * 0.42" text-anchor="middle" font-size="5" font-weight="700" fill="#64748b" opacity="0.7">{{ (mountedAt(pos.code)?.brand || 'TIRE').substring(0, 8) }}</text>
                    <text :y="pos.r * 0.58" text-anchor="middle" font-size="4.5" font-weight="600" fill="#4b5563" opacity="0.55">{{ mountedAt(pos.code)?.size || '' }}</text>
                    <circle :r="pos.r * 0.64" fill="url(#d-rimMetal)" stroke="#475569" stroke-width="0.8" />
                    <circle :r="pos.r * 0.64" fill="none" stroke="#64748b" stroke-width="1.2" opacity="0.4" />
                    <circle :r="pos.r * 0.64" fill="none" stroke="#e2e8f0" stroke-width="0.8" opacity="0.5" />
                    <g stroke="#cbd5e1" stroke-width="2.6" stroke-linecap="round" opacity="0.85">
                      <line v-for="s in spokes(pos.r)" :key="s.i" :x1="s.x1" :y1="s.y1" :x2="s.x2" :y2="s.y2" />
                    </g>
                    <g fill="#334155" stroke="#1e293b" stroke-width="0.6">
                      <circle v-for="l in lugNuts(pos.r)" :key="l.i" :cx="l.x" :cy="l.y" r="2.6" />
                      <circle v-for="l in lugNuts(pos.r)" :key="'lh2'+l.i" :cx="l.x - 0.5" :cy="l.y - 0.5" r="1" fill="#64748b" opacity="0.4" />
                    </g>
                    <circle :r="pos.r * 0.16" fill="#1e293b" />
                    <circle :cx="-pos.r * 0.04" :cy="-pos.r * 0.04" :r="pos.r * 0.06" fill="#64748b" opacity="0.6" />
                    <circle :r="pos.r * 0.08" fill="#94a3b8" stroke="#475569" stroke-width="0.5" />
                    <circle :r="pos.r * 0.04" fill="#1e293b" />
                    <circle :r="pos.r * 0.20" fill="none" stroke="#64748b" stroke-width="0.5" opacity="0.7" />
                  </g>
                  <text :y="pos.r * 1.6 + 12" text-anchor="middle" font-size="7.5" font-weight="700" fill="#0f766e" font-family="monospace">{{ mountedAt(pos.code)?.serial || '' }}</text>
                </g>

                <!-- Empty / hub for other positions -->
                <g v-else filter="url(#d-wheelShadow)" opacity="0.55">
                  <g transform="scale(1, 1.6)">
                    <circle :r="pos.r * 0.9" fill="url(#d-drumGrad)" stroke="#1f2937" stroke-width="1.2" />
                    <circle :r="pos.r * 0.9" fill="none" stroke="#64748b" stroke-width="0.8" opacity="0.3" />
                    <g stroke="#1e293b" stroke-width="1.2" opacity="0.5">
                      <line v-for="a in drumGrooves(pos.r)" :key="a.i" :x1="a.x1" :y1="a.y1" :x2="a.x2" :y2="a.y2" />
                    </g>
                    <circle :r="pos.r * 0.24" fill="#1f2937" stroke="#374151" stroke-width="0.8" />
                    <circle :r="pos.r * 0.12" fill="#64748b" stroke="#475569" stroke-width="0.5" />
                    <circle :r="pos.r * 0.06" fill="#1e293b" />
                    <g fill="#64748b">
                      <circle v-for="l in lugNuts(pos.r * 0.9)" :key="l.i" :cx="l.x" :cy="l.y" r="2" />
                    </g>
                  </g>
                  <text :y="pos.r * 1.6 + 12" text-anchor="middle" font-size="8" font-weight="700" fill="#94a3b8">{{ pos.shortLabel }}</text>
                </g>

                <!-- Selection indicator -->
                <ellipse v-if="!mountedTires && pos.code === position" :rx="pos.r + 8" :ry="pos.r * 1.6 + 8" fill="none" stroke="#10b981" stroke-width="3.5" filter="url(#d-glow)" class="sel-ring" />
              </g>
            </g>

            <!-- ====== SPARE TIRE CARRIER ====== -->
            <g v-if="spare" :transform="`translate(${spare.x} ${spare.y})`" class="wheel-g">
              <rect x="-36" y="-36" width="72" height="72" rx="8" fill="#1e293b" opacity="0.15" />
              <rect x="-36" y="-36" width="72" height="72" rx="8" fill="none" stroke="#374151" stroke-width="1" opacity="0.4" />
              <line x1="-20" y1="20" x2="20" y2="20" stroke="#475569" stroke-width="3" opacity="0.5" />
              <ellipse cx="0" cy="28" rx="30" ry="8" fill="#000" opacity="0.22" />
              <g v-if="position === 'Spare'" filter="url(#d-wheelShadow)">
                <circle r="28" fill="url(#d-treadGrad)" stroke="#0f141e" stroke-width="1.2" />
                <g stroke="#0f172a" stroke-width="2.4" stroke-linecap="round">
                  <line v-for="a in treadArcs(28)" :key="a.i" :x1="a.x1" :y1="a.y1" :x2="a.x2" :y2="a.y2" />
                </g>
                <circle r="22" fill="url(#d-sidewallGrad)" />
                <circle r="18" fill="url(#d-rimMetal)" stroke="#475569" stroke-width="0.8" />
                <g stroke="#cbd5e1" stroke-width="2.2" stroke-linecap="round" opacity="0.85">
                  <line v-for="s in spokes(28)" :key="s.i" :x1="s.x1" :y1="s.y1" :x2="s.x2" :y2="s.y2" />
                </g>
                <circle v-for="l in lugNuts(28)" :key="l.i" :cx="l.x" :cy="l.y" r="2" fill="#334155" />
                <circle r="4.5" fill="#1e293b" />
              </g>
              <g v-else opacity="0.55">
                <circle r="26" fill="url(#d-drumGrad)" stroke="#1f2937" stroke-width="1.2" />
                <circle r="7" fill="#1f2937" />
                <g fill="#64748b">
                  <circle v-for="l in lugNuts(26)" :key="l.i" :cx="l.x" :cy="l.y" r="1.8" />
                </g>
              </g>
              <text y="46" text-anchor="middle" font-size="9" font-weight="700" :fill="position === 'Spare' ? '#065f46' : '#94a3b8'">Spare</text>
              <circle v-if="position === 'Spare'" r="36" fill="none" stroke="#10b981" stroke-width="3.5" filter="url(#d-glow)" class="sel-ring" />
            </g>
          </g>
        </svg>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  position?: string
  drivetrain?: string
  vehicleType?: string
  steering?: string
  vehicleName?: string
  tireSerial?: string
  tireBrand?: string
  tireSize?: string
  /** Map of position code → { serial, brand, size } for vehicle-wide mounted tires view. */
  mountedTires?: Record<string, { serial?: string; brand?: string; size?: string }>
}>()

// --- Geometry constants (match TireMountScreen) ---
const bodyLeft = 240
const bodyRight = 400
const cabFrontY = 36
const cabRearY = 130
const bedTopY = 142
const bedRearY = 396

const cabLeft = bodyLeft - 8
const cabRight = bodyRight + 8
const cabWidth = cabRight - cabLeft
const cabHeight = cabRearY - cabFrontY
const bedLeft = bodyLeft
const bedRight = bodyRight
const bedWidth = bedRight - bedLeft
const bedHeight = bedRearY - bedTopY

const tireSerial = computed(() => props.tireSerial || 'THIS TIRE')
const tireBrand = computed(() => (props.tireBrand || 'DOMENDRAFLEET').substring(0, 8))
const tireSize = computed(() => props.tireSize || 'TIRE')

/** Returns mounted tire info at a position code, if any. */
function mountedAt(code: string): { serial?: string; brand?: string; size?: string } | null {
  if (!props.mountedTires) return null
  return props.mountedTires[code] || null
}

function deriveAxles() {
  const dt = ((props.drivetrain) || '').toUpperCase().replace(/[Xx]/, '-')
  const vt = props.vehicleType || 'vehicle'
  const dualMode = ['6-4', '6-2', '8-4', '8-2', '4-4'].includes(dt) || vt === 'trailer'
  if (vt === 'trailer') return [{ role: 'trailer', dual: true }, { role: 'trailer', dual: true }]
  if (vt === 'equipment' || vt === 'non_powered') return [{ role: 'tag', dual: false }, { role: 'tag', dual: false }]
  switch (dt) {
    case '6-2': return [{ role: 'steer', dual: false }, { role: 'drive', dual: true }, { role: 'tag', dual: false }]
    case '6-4': return [{ role: 'steer', dual: false }, { role: 'drive', dual: true }, { role: 'drive', dual: true }]
    case '8-4':
      return [{ role: 'steer', dual: false }, { role: 'steer', dual: false }, { role: 'drive', dual: false }, { role: 'drive', dual: true }]
    case '8-2':
      return [{ role: 'steer', dual: false }, { role: 'steer', dual: false }, { role: 'drive', dual: true }, { role: 'tag', dual: false }]
    case '4WD':
      return [{ role: 'steer', dual: false }, { role: 'drive', dual: false }]
    case '4-4':
      return [{ role: 'steer', dual: false }, { role: 'drive', dual: true }]
    case '4-2':
    case '2WD':
    default:
      return [{ role: 'steer', dual: false }, { role: 'drive', dual: dualMode }]
  }
}

function rolePrefix(role: string) {
  return { steer: 'F', drive: 'D', tag: 'G', trailer: 'T' }[role] || 'A'
}
function roleLabel(role: string) {
  return { steer: 'Front', drive: 'Drive', tag: 'Tag', trailer: 'Trailer' }[role] || 'Axle'
}
function axleTag(role: string, occurrence: number, roleCount: number) {
  const prefix = rolePrefix(role)
  return roleCount > 1 ? `${prefix}${occurrence + 1}` : prefix
}

const axles = computed(() => {
  const defs = deriveAxles()
  const counts: Record<string, number> = { steer: 0, drive: 0, tag: 0, trailer: 0 }
  defs.forEach((a) => { counts[a.role] = (counts[a.role] || 0) + 1 })

  const n = defs.length
  const yRange = bedRearY - cabFrontY - 30
  return defs.map((a, i) => {
    const occurrence = (counts[a.role] > 1)
      ? defs.slice(0, i).filter((x) => x.role === a.role).length
      : 0
    const tag = axleTag(a.role, occurrence, counts[a.role])
    const label = counts[a.role] > 1 ? `${roleLabel(a.role)} ${occurrence + 1}` : roleLabel(a.role)
    const y = n > 1 ? cabFrontY + 40 + (yRange * i) / (n - 1) : cabFrontY + 40 + yRange / 2
    const dual = a.dual

    let positions: any[] = []
    const r = dual ? 28 : 36
    if (dual) {
      positions = [
        { code: `${tag}_L_Outer`, side: 'L', wheel: 'Outer', x: bodyLeft - 66, y, r, shortLabel: 'L-Outer' },
        { code: `${tag}_L_Inner`, side: 'L', wheel: 'Inner', x: bodyLeft - 20, y, r, shortLabel: 'L-Inner' },
        { code: `${tag}_R_Inner`, side: 'R', wheel: 'Inner', x: bodyRight + 20, y, r, shortLabel: 'R-Inner' },
        { code: `${tag}_R_Outer`, side: 'R', wheel: 'Outer', x: bodyRight + 66, y, r, shortLabel: 'R-Outer' },
      ]
    } else {
      positions = [
        { code: `${tag}_L`, side: 'L', wheel: null, x: bodyLeft - 46, y, r, shortLabel: 'Left' },
        { code: `${tag}_R`, side: 'R', wheel: null, x: bodyRight + 46, y, r, shortLabel: 'Right' },
      ]
    }
    return {
      index: i, role: a.role, dual, tag, label, y,
      leftEdge: dual ? bodyLeft - 70 : bodyLeft - 50,
      rightEdge: dual ? bodyRight + 70 : bodyRight + 50,
      positions,
    }
  })
})

const spare = computed(() => ({ x: 560, y: bedRearY }))

function isPowered(role: string) {
  return role === 'drive' || role === 'steer'
}

const poweredAxles = computed(() => axles.value.filter((a) => isPowered(a.role)))
const hasPoweredAxles = computed(() => poweredAxles.value.length > 0)
const hasMultiplePoweredAxles = computed(() => poweredAxles.value.length > 1)

const engineFrontY = computed(() => cabFrontY + 28)
const engineHeight = 28
const transmissionCX = 320
const transmissionY = computed(() => cabFrontY + 120)

const driveshaftSpan = computed(() => {
  if (!hasPoweredAxles.value) return null
  const last = poweredAxles.value[poweredAxles.value.length - 1]
  return { x1: 320, y1: transmissionY.value + 22, x2: 320, y2: last.y - 16 }
})

const hasCenterBearing = computed(() => {
  if (!driveshaftSpan.value) return false
  return Math.abs(driveshaftSpan.value.y2 - driveshaftSpan.value.y1) > 150
})
const centerBearingX = 320
const centerBearingY = computed(() => {
  if (!driveshaftSpan.value) return 0
  return (driveshaftSpan.value.y1 + driveshaftSpan.value.y2) / 2
})

const transferCaseY = computed(() => {
  if (!hasMultiplePoweredAxles.value) return 0
  const first = poweredAxles.value[0]
  return (transmissionY.value + first.y) / 2
})

const frameHoles = computed(() => {
  const holes: any[] = []
  for (let y = cabFrontY + 40; y < bedRearY - 20; y += 22) holes.push({ y })
  return holes
})
const frameRivets = computed(() => {
  const rivets: any[] = []
  for (let y = cabFrontY + 20; y < bedRearY - 10; y += 10) rivets.push({ y })
  return rivets
})

// --- Shape helpers (match TireMountScreen) ---
function spokes(r: number, n = 6) {
  const arr: any[] = []
  const inner = r * 0.18
  const outer = r * 0.6
  for (let i = 0; i < n; i++) {
    const ang = (i / n) * Math.PI * 2 + 0.4
    arr.push({
      i,
      x1: Math.cos(ang) * inner, y1: Math.sin(ang) * inner,
      x2: Math.cos(ang) * outer, y2: Math.sin(ang) * outer,
    })
  }
  return arr
}

function lugNuts(r: number, n = 6) {
  const arr: any[] = []
  const rad = r * 0.5
  for (let i = 0; i < n; i++) {
    const ang = (i / n) * Math.PI * 2 + Math.PI / n
    arr.push({ i, x: Math.cos(ang) * rad, y: Math.sin(ang) * rad })
  }
  return arr
}

function drumGrooves(r: number, n = 10) {
  const arr: any[] = []
  const r1 = r * 0.34
  const r2 = r * 0.78
  for (let i = 0; i < n; i++) {
    const ang = (i / n) * Math.PI * 2
    arr.push({
      i,
      x1: Math.cos(ang) * r1, y1: Math.sin(ang) * r1,
      x2: Math.cos(ang) * r2, y2: Math.sin(ang) * r2,
    })
  }
  return arr
}

function treadArcs(r: number) {
  const arr: any[] = []
  const count = 18
  for (let i = 0; i < count; i++) {
    const ang = (i / count) * Math.PI * 2
    const r1 = r * 0.83
    const r2 = r * 0.99
    arr.push({
      i,
      x1: Math.cos(ang) * r1, y1: Math.sin(ang) * r1,
      x2: Math.cos(ang) * r2, y2: Math.sin(ang) * r2,
    })
  }
  return arr
}

function treadBevelPath(r: number) {
  const a0 = -2.4
  const a1 = -0.7
  const R = r + 0.6
  const x0 = Math.cos(a0) * R
  const y0 = Math.sin(a0) * R
  const x1 = Math.cos(a1) * R
  const y1 = Math.sin(a1) * R
  const ix0 = Math.cos(a0) * r * 0.97
  const iy0 = Math.sin(a0) * r * 0.97
  const ix1 = Math.cos(a1) * r * 0.97
  const iy1 = Math.sin(a1) * r * 0.97
  return `M ${x0} ${y0} A ${R} ${R} 0 0 1 ${x1} ${y1} L ${ix1} ${iy1} A ${r * 0.97} ${r * 0.97} 0 0 0 ${ix0} ${iy0} Z`
}
</script>

<style scoped>
.axle-diagram-wrap {
  width: 100%;
}
.axle-stage {
  position: relative;
  background: linear-gradient(180deg, #eef2f6 0%, #dce3ec 100%);
  border: 1px solid #cbd5e1;
  border-radius: 16px;
  padding: 16px;
  overflow: hidden;
  user-select: none;
}
.axle-floor {
  position: absolute;
  inset: 0;
  background-image: radial-gradient(circle at 50% 90%, rgba(99, 102, 241, 0.05), transparent 60%);
  pointer-events: none;
}
.axle-canvas-wrap {
  transform-origin: 50% 60%;
}
.axle-svg {
  width: 100%;
  height: auto;
  display: block;
}
.wheel-g {
  transform-box: fill-box;
}
.sel-ring {
  animation: d-pulse 1.6s ease-in-out infinite;
}
@keyframes d-pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.45; }
}
</style>
