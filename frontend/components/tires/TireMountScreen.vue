<template>
  <div class="d-flex flex-column ga-4">
    <!-- Header -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-2">
      <div class="d-flex align-center ga-2">
        <v-btn icon="mdi-arrow-left" size="small" variant="text" color="primary" @click="$emit('cancel')" />
        <div>
          <h1 class="text-h5 font-weight-bold" style="color: #1e293b">Mount Tire</h1>
          <p class="text-caption text-medium-emphasis">Select a vehicle, pick a wheel position on the 3D axle, then mount.</p>
        </div>
      </div>
      <v-btn variant="text" prepend-icon="mdi-close" @click="$emit('cancel')">Cancel</v-btn>
    </div>

    <v-card v-if="!tire && loading" elevation="0" border rounded="lg" class="pa-12 text-center text-medium-emphasis">
      <v-progress-circular indeterminate color="primary" class="mb-3" />
      <p class="text-body-2">Loading tire…</p>
    </v-card>

    <v-alert v-else-if="!tire" type="error" variant="tonal" title="Tire not found" text="No tire was specified. Go back and choose a tire to mount." />

    <template v-else>
      <!-- Tire being mounted summary -->
      <v-card elevation="0" border rounded="lg" class="pa-4">
        <div class="d-flex align-center ga-3">
          <div class="d-flex align-center justify-center" style="width: 52px; height: 52px; border-radius: 14px; background: #eef2ff; flex-shrink: 0">
            <v-icon color="primary" size="28">mdi-tire</v-icon>
          </div>
          <div class="flex-grow-1">
            <p class="text-h6 font-weight-bold" style="color: #1e293b; line-height: 1.2">{{ tire.serial_number }}</p>
            <p class="text-caption text-medium-emphasis">{{ tire.brand }} {{ tire.model || '' }} · {{ tire.size || '—' }} · {{ tire.type || 'Tire' }} · {{ tire.condition || '' }}</p>
          </div>
          <v-chip v-if="tire.latest_tread_depth != null" size="small" variant="tonal" :color="tire.needs_replacement ? 'error' : 'success'">{{ tire.latest_tread_depth }}/32″</v-chip>
        </div>
      </v-card>

      <v-card elevation="0" border rounded="lg" class="overflow-hidden">
        <v-row no-gutters>
          <!-- LEFT: 3D Axle Visualization -->
          <v-col cols="12" md="7" style="border-right: 1px solid #e2e8f0">
            <div class="pa-5">
              <!-- Vehicle selector + wheel count controls -->
              <div class="d-flex align-center justify-space-between flex-wrap ga-2 mb-3">
                <div style="min-width: 280px; flex: 1 1 280px">
                  <v-select
                    v-model="mountForm.vehicle"
                    :items="vehicles"
                    item-title="display_name"
                    item-value="id"
                    label="Select Vehicle"
                    prepend-inner-icon="mdi-car"
                    density="compact"
                    variant="outlined"
                    hide-details="auto"
                  />
                </div>
                <!-- Rear axle wheel count toggle -->
                <div v-if="selectedVehicle" class="d-flex align-center ga-1">
                  <span class="text-caption text-medium-emphasis mr-1">Rear wheels:</span>
                  <v-btn-toggle v-model="rearWheelMode" mandatory density="compact" color="primary" variant="outlined" divided>
                    <v-btn value="single" size="small"><v-icon size="small" class="mr-1">mdi-tire</v-icon>Single</v-btn>
                    <v-btn value="dual" size="small"><v-icon size="small" class="mr-1">mdi-tire</v-icon><v-icon size="small">mdi-tire</v-icon>Dual</v-btn>
                  </v-btn-toggle>
                </div>
              </div>

              <!-- 3D Stage -->
              <div
                class="axle-stage"
                :class="{ 'is-empty': !selectedVehicle }"
                @pointerdown.prevent="onStagePointerDown"
                @pointermove="onStagePointerMove"
                @pointerup="onStagePointerUp"
                @pointerleave="onStagePointerUp"
                @wheel.prevent="onStageWheel"
              >
                <div class="axle-floor"></div>

                <!-- View controls -->
                <div v-if="selectedVehicle" class="axle-controls">
                  <v-btn size="x-small" variant="flat" icon="mdi-rotate-left" title="Rotate left" @click.stop="rotateBy(-15)" />
                  <v-btn size="x-small" variant="flat" icon="mdi-rotate-right" title="Rotate right" @click.stop="rotateBy(15)" />
                  <v-btn size="x-small" variant="flat" icon="mdi-magnify-plus-outline" title="Zoom in" @click.stop="zoomBy(0.15)" />
                  <v-btn size="x-small" variant="flat" icon="mdi-magnify-minus-outline" title="Zoom out" @click.stop="zoomBy(-0.15)" />
                  <v-btn size="x-small" variant="flat" icon="mdi-autorenew" title="Reset view" @click.stop="resetView" />
                  <v-btn-toggle v-model="viewAngle" mandatory density="compact" color="primary" variant="outlined" class="ml-2">
                    <v-btn value="top" size="small"><v-icon size="small" class="mr-1">mdi-axis-arrow</v-icon>Top</v-btn>
                    <v-btn value="persp" size="small"><v-icon size="small" class="mr-1">mdi-cube-outline</v-icon>3D</v-btn>
                  </v-btn-toggle>
                </div>

                <!-- Hover tooltip -->
                <div
                  v-if="tooltip.show"
                  class="dt-tooltip"
                  :style="{ left: tooltip.x + 'px', top: tooltip.y + 'px' }"
                >
                  <div class="dt-tooltip-title">{{ tooltip.title }}</div>
                  <div v-if="tooltip.desc" class="dt-tooltip-desc">{{ tooltip.desc }}</div>
                </div>

                <div v-if="!selectedVehicle" class="axle-empty">
                  <v-icon size="56" class="mb-2" color="primary">mdi-car-truck</v-icon>
                  <p class="text-body-2 font-weight-medium" style="color: #475569">Select a vehicle to render its axle layout</p>
                  <p class="text-caption text-medium-emphasis">The 3D axle diagram adapts to the selected vehicle's drivetrain</p>
                </div>

                <div v-else class="axle-canvas-wrap" :style="{ transform: stageTransform }">
                  <svg ref="stageSvg" viewBox="0 0 640 540" class="axle-svg" xmlns="http://www.w3.org/2000/svg">
                    <defs>
                      <!-- Tire tread gradient -->
                      <radialGradient id="treadGrad" cx="40%" cy="36%" r="68%">
                        <stop offset="0%" stop-color="#2d3748" />
                        <stop offset="50%" stop-color="#1a202c" />
                        <stop offset="100%" stop-color="#0f141e" />
                      </radialGradient>
                      <!-- Sidewall gradient -->
                      <radialGradient id="sidewallGrad" cx="42%" cy="38%" r="70%">
                        <stop offset="0%" stop-color="#4a5568" />
                        <stop offset="60%" stop-color="#2d3748" />
                        <stop offset="100%" stop-color="#171c27" />
                      </radialGradient>
                      <!-- Rim metallic -->
                      <radialGradient id="rimMetal" cx="38%" cy="34%" r="70%">
                        <stop offset="0%" stop-color="#ffffff" />
                        <stop offset="30%" stop-color="#e2e8f0" />
                        <stop offset="65%" stop-color="#94a3b8" />
                        <stop offset="100%" stop-color="#475569" />
                      </radialGradient>
                      <!-- Brake drum -->
                      <radialGradient id="drumGrad" cx="40%" cy="36%" r="68%">
                        <stop offset="0%" stop-color="#6b7280" />
                        <stop offset="50%" stop-color="#374151" />
                        <stop offset="100%" stop-color="#1f2937" />
                      </radialGradient>
                      <!-- Axle tube gradient -->
                      <linearGradient id="axleGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stop-color="#4b5563" />
                        <stop offset="40%" stop-color="#9ca3af" />
                        <stop offset="100%" stop-color="#374151" />
                      </linearGradient>
                      <!-- Differential pumpkin -->
                      <radialGradient id="pumpkinGrad" cx="36%" cy="32%" r="72%">
                        <stop offset="0%" stop-color="#a78bfa" />
                        <stop offset="50%" stop-color="#7c3aed" />
                        <stop offset="100%" stop-color="#5b21b6" />
                      </radialGradient>
                      <!-- Frame rails -->
                      <linearGradient id="frameGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stop-color="#4b5563" />
                        <stop offset="40%" stop-color="#94a3b8" />
                        <stop offset="100%" stop-color="#374151" />
                      </linearGradient>
                      <!-- Transmission / diff body -->
                      <radialGradient id="diffGrad" cx="38%" cy="34%" r="70%">
                        <stop offset="0%" stop-color="#9ca3af" />
                        <stop offset="50%" stop-color="#6b7280" />
                        <stop offset="100%" stop-color="#374151" />
                      </radialGradient>
                      <!-- Transfer case -->
                      <radialGradient id="transferGrad" cx="36%" cy="32%" r="72%">
                        <stop offset="0%" stop-color="#cbd5e1" />
                        <stop offset="50%" stop-color="#64748b" />
                        <stop offset="100%" stop-color="#1e293b" />
                      </radialGradient>
                      <!-- Driveshaft tube -->
                      <linearGradient id="shaftGrad" x1="0" y1="0" x2="1" y2="0">
                        <stop offset="0%" stop-color="#6b7280" />
                        <stop offset="50%" stop-color="#d1d5db" />
                        <stop offset="100%" stop-color="#4b5563" />
                      </linearGradient>
                      <!-- Engine block -->
                      <linearGradient id="engineGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stop-color="#4b5563" />
                        <stop offset="40%" stop-color="#6b7280" />
                        <stop offset="100%" stop-color="#374151" />
                      </linearGradient>
                      <!-- Engine valve cover -->
                      <linearGradient id="valveGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stop-color="#fbbf24" />
                        <stop offset="50%" stop-color="#d97706" />
                        <stop offset="100%" stop-color="#b45309" />
                      </linearGradient>
                      <!-- Cab body -->
                      <linearGradient id="cabGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stop-color="#1e40af" />
                        <stop offset="50%" stop-color="#1d4ed8" />
                        <stop offset="100%" stop-color="#1e3a8a" />
                      </linearGradient>
                      <!-- Bed body -->
                      <linearGradient id="bedGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stop-color="#1e1b4b" />
                        <stop offset="100%" stop-color="#111827" />
                      </linearGradient>
                      <!-- Ground gradient -->
                      <radialGradient id="groundGrad" cx="50%" cy="50%" r="55%">
                        <stop offset="0%" stop-color="#e2e8f0" />
                        <stop offset="100%" stop-color="#cbd5e1" />
                      </radialGradient>
                      <!-- Leaf spring gradient -->
                      <linearGradient id="springGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stop-color="#6b7280" />
                        <stop offset="30%" stop-color="#9ca3af" />
                        <stop offset="100%" stop-color="#4b5563" />
                      </linearGradient>
                      <!-- Shock absorber -->
                      <linearGradient id="shockGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stop-color="#cbd5e1" />
                        <stop offset="50%" stop-color="#6b7280" />
                        <stop offset="100%" stop-color="#374151" />
                      </linearGradient>
                      <!-- Exhaust pipe -->
                      <linearGradient id="exhaustGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stop-color="#9ca3af" />
                        <stop offset="50%" stop-color="#6b7280" />
                        <stop offset="100%" stop-color="#4b5563" />
                      </linearGradient>
                      <!-- Muffler -->
                      <linearGradient id="mufflerGrad" x1="0" y1="0" x2="1" y2="0">
                        <stop offset="0%" stop-color="#9ca3af" />
                        <stop offset="50%" stop-color="#d1d5db" />
                        <stop offset="100%" stop-color="#6b7280" />
                      </linearGradient>
                      <!-- Filters -->
                      <filter id="glow" x="-80%" y="-80%" width="260%" height="260%">
                        <feGaussianBlur stdDeviation="6" result="b" />
                        <feMerge><feMergeNode in="b" /><feMergeNode in="SourceGraphic" /></feMerge>
                      </filter>
                      <filter id="softShadow" x="-60%" y="-60%" width="220%" height="220%">
                        <feGaussianBlur in="SourceAlpha" stdDeviation="5" />
                        <feOffset dy="6" result="o" />
                        <feComponentTransfer><feFuncA type="linear" slope="0.32" /></feComponentTransfer>
                        <feMerge><feMergeNode /><feMergeNode in="SourceGraphic" /></feMerge>
                      </filter>
                      <filter id="wheelShadow" x="-60%" y="-60%" width="220%" height="220%">
                        <feGaussianBlur in="SourceAlpha" stdDeviation="3" />
                        <feOffset dy="4" result="o" />
                        <feComponentTransfer><feFuncA type="linear" slope="0.4" /></feComponentTransfer>
                        <feMerge><feMergeNode /><feMergeNode in="SourceGraphic" /></feMerge>
                      </filter>
                      <filter id="metalFlare" x="-50%" y="-50%" width="200%" height="200%">
                        <feGaussianBlur stdDeviation="1.5" result="b" />
                        <feMerge><feMergeNode in="b" /><feMergeNode in="SourceGraphic" /></feMerge>
                      </filter>
                    </defs>

                    <!-- Ground plane with realistic workshop floor look -->
                    <ellipse cx="320" cy="492" rx="280" ry="38" fill="url(#groundGrad)" />
                    <ellipse cx="320" cy="492" rx="265" ry="32" fill="#000" opacity="0.08" />
                    <!-- Floor grid lines like a real workshop -->
                    <g stroke="#bfc9d4" stroke-width="0.8" opacity="0.4">
                      <line v-for="gx in [100, 180, 260, 320, 380, 460, 540]" :key="'gx'+gx" :x1="gx" :y1="478" :x2="gx - 35" :y2="512" />
                      <line v-for="gy in [462, 472, 484, 498, 510]" :key="'gy'+gy" :x1="80" :y1="gy" :x2="560" :y2="gy" />
                    </g>

                    <!-- Main rotatable assembly group -->
                    <g :transform="`rotate(${rotation.z} 320 256)`">
                      <!-- ====== LADDER FRAME CHASSIS ====== -->
                      <g filter="url(#softShadow)">
                        <!-- Main frame rails (C-channel) -->
                        <g v-for="(side, si) in [{x: bodyLeft - 16, flip: 1}, {x: bodyRight - 4, flip: -1}]" :key="'rail'+si">
                          <!-- Main rail body -->
                          <rect :x="side.x" :y="cabFrontY + 8" :width="12" :height="bedRearY - cabFrontY - 12" rx="3" fill="url(#frameGrad)" stroke="#1f2937" stroke-width="1" />
                          <!-- C-channel inner highlight -->
                          <rect :x="side.x + (side.flip > 0 ? 2 : 0)" :y="cabFrontY + 14" :width="8" :height="bedRearY - cabFrontY - 24" rx="2" fill="#cbd5e1" opacity="0.2" />
                          <!-- Frame rail holes (weight-saving) -->
                          <circle v-for="fh in frameHoles" :key="'fh'+si+fh.y" :cx="side.x + 6" :cy="fh.y" r="2.5" fill="#1e293b" opacity="0.5" />
                          <!-- Rail rivets -->
                          <circle v-for="fr in frameRivets" :key="'fr'+si+fr.y" :cx="side.x + (side.flip > 0 ? 3 : 9)" :cy="fr.y" r="1.2" fill="#64748b" opacity="0.7" />
                        </g>

                        <!-- Cross members between frame rails -->
                        <rect v-for="ax in layout.axles" :key="'cm' + ax.index" :x="bodyLeft - 16" :y="ax.y - 6" :width="bodyRight - bodyLeft + 24" :height="12" rx="4" fill="url(#frameGrad)" stroke="#374151" stroke-width="0.8" opacity="0.85" />
                        <!-- Extra cross members -->
                        <rect :x="bodyLeft - 16" :y="cabRearY + 10" :width="bodyRight - bodyLeft + 24" :height="10" rx="3" fill="url(#frameGrad)" stroke="#374151" stroke-width="0.6" opacity="0.7" />
                        <rect :x="bodyLeft - 16" :y="bedRearY - 16" :width="bodyRight - bodyLeft + 24" :height="10" rx="3" fill="url(#frameGrad)" stroke="#374151" stroke-width="0.6" opacity="0.7" />
                        
                        <!-- Cross member gusset plates -->
                        <polygon v-for="ax in layout.axles" :key="'guss'+ax.index" :points="`${bodyLeft - 16},${ax.y - 6} ${bodyLeft - 8},${ax.y - 6} ${bodyLeft - 16},${ax.y + 8}`" fill="#475569" opacity="0.5" />
                        <polygon v-for="ax in layout.axles" :key="'guss2'+ax.index" :points="`${bodyRight + 8},${ax.y - 6} ${bodyRight + 16},${ax.y - 6} ${bodyRight + 16},${ax.y + 8}`" fill="#475569" opacity="0.5" />
                      </g>

                      <!-- ====== TRUCK CAB (FRONT) ====== -->
                      <g filter="url(#softShadow)">
                        <!-- Cab body -->
                        <rect :x="cabLeft" :y="cabFrontY - 4" :width="cabWidth" :height="cabHeight" rx="12" fill="url(#cabGrad)" stroke="#1e3a8a" stroke-width="1" />
                        <!-- Cab roof -->
                        <rect :x="cabLeft + 8" :y="cabFrontY - 10" :width="cabWidth - 16" :height="14" rx="7" fill="#2563eb" opacity="0.6" />
                        <!-- Windshield -->
                        <rect :x="cabLeft + 18" :y="cabFrontY + 10" :width="cabWidth - 36" :height="22" rx="4" fill="#60a5fa" opacity="0.5" stroke="#93c5fd" stroke-width="0.6" />
                        <!-- Windshield reflection -->
                        <line :x1="cabLeft + 22" :y1="cabFrontY + 14" :x2="cabLeft + cabWidth - 22" :y2="cabFrontY + 14" stroke="#bfdbfe" stroke-width="1" opacity="0.6" />
                        <!-- Side windows -->
                        <rect :x="cabLeft + 4" :y="cabFrontY + 16" :width="16" :height="14" rx="3" fill="#60a5fa" opacity="0.35" stroke="#93c5fd" stroke-width="0.5" />
                        <rect :x="cabRight - 20" :y="cabFrontY + 16" :width="16" :height="14" rx="3" fill="#60a5fa" opacity="0.35" stroke="#93c5fd" stroke-width="0.5" />
                        <!-- Grille -->
                        <rect :x="cabLeft + 14" :y="cabFrontY + 36" :width="cabWidth - 28" :height="16" rx="3" fill="#1e293b" stroke="#0f172a" stroke-width="0.6" />
                        <!-- Grille slots -->
                        <line v-for="gs in 5" :key="'gs'+gs" :x1="cabLeft + 22" :y1="cabFrontY + 38 + gs * 3" :x2="cabRight - 22" :y2="cabFrontY + 38 + gs * 3" stroke="#334155" stroke-width="0.8" />
                        <!-- Headlights -->
                        <rect :x="cabLeft + 6" :y="cabFrontY + 38" width="12" height="8" rx="2" fill="#fef08a" stroke="#ca8a04" stroke-width="0.5" filter="url(#glow)" />
                        <rect :x="cabRight - 18" :y="cabFrontY + 38" width="12" height="8" rx="2" fill="#fef08a" stroke="#ca8a04" stroke-width="0.5" filter="url(#glow)" />
                        <!-- Bumper -->
                        <rect :x="cabLeft - 2" :y="cabFrontY + 54" :width="cabWidth + 4" :height="6" rx="2" fill="#475569" stroke="#1f2937" stroke-width="0.6" />
                      </g>

                      <!-- ====== TRUCK BED / FLATBED (REAR) ====== -->
                      <g filter="url(#softShadow)">
                        <!-- Bed floor -->
                        <rect :x="bedLeft" :y="bedTopY" :width="bedWidth" :height="bedHeight" rx="8" fill="url(#bedGrad)" stroke="#111827" stroke-width="0.8" />
                        <!-- Bed floor planks -->
                        <line v-for="bp in 6" :key="'bp'+bp" :x1="bedLeft + 6" :y1="bedTopY + 6 + bp * 6" :x2="bedRight - 6" :y2="bedTopY + 6 + bp * 6" stroke="#1f2937" stroke-width="0.6" opacity="0.5" />
                        <!-- Stake sides -->
                        <rect :x="bedLeft" :y="bedTopY - 14" :width="6" :height="bedHeight + 14" rx="2" fill="#374151" stroke="#111827" stroke-width="0.6" />
                        <rect :x="bedRight - 6" :y="bedTopY - 14" :width="6" :height="bedHeight + 14" rx="2" fill="#374151" stroke="#111827" stroke-width="0.6" />
                        <!-- Stake pockets -->
                        <rect v-for="sp in 3" :key="'sp'+sp" :x="bedLeft - 1" :y="bedTopY + 12 + sp * 18" width="8" height="8" rx="1" fill="#1f2937" stroke="#374151" stroke-width="0.5" />
                        <rect v-for="sp in 3" :key="'spr'+sp" :x="bedRight - 7" :y="bedTopY + 12 + sp * 18" width="8" height="8" rx="1" fill="#1f2937" stroke="#374151" stroke-width="0.5" />
                        <!-- Tail lights -->
                        <rect :x="bedRight - 8" :y="bedTopY + bedHeight - 16" width="6" height="10" rx="2" fill="#ef4444" stroke="#991b1b" stroke-width="0.5" filter="url(#glow)" />
                        <rect :x="bedLeft + 2" :y="bedTopY + bedHeight - 16" width="6" height="10" rx="2" fill="#ef4444" stroke="#991b1b" stroke-width="0.5" filter="url(#glow)" />
                      </g>

                      <!-- ====== ENGINE (between frame rails, under cab) ====== -->
                      <g filter="url(#softShadow)">
                        <!-- Engine block -->
                        <rect :x="bodyLeft + 8" :y="engineFrontY" :width="bodyRight - bodyLeft - 16" :height="engineHeight" rx="6" fill="url(#engineGrad)" stroke="#1f2937" stroke-width="1" />
                        <!-- Oil pan -->
                        <rect :x="bodyLeft + 14" :y="engineFrontY + engineHeight - 6" :width="bodyRight - bodyLeft - 28" :height="10" rx="3" fill="#374151" stroke="#1f2937" stroke-width="0.8" />
                        <!-- Valve covers (left and right bank) -->
                        <rect :x="bodyLeft + 12" :y="engineFrontY - 4" :width="bodyRight - bodyLeft - 60" :height="8" rx="3" fill="url(#valveGrad)" stroke="#92400e" stroke-width="0.6" />
                        <rect :x="bodyLeft + 48" :y="engineFrontY - 4" :width="bodyRight - bodyLeft - 60" :height="8" rx="3" fill="url(#valveGrad)" stroke="#92400e" stroke-width="0.6" />
                        <!-- Valve cover bolts -->
                        <circle v-for="vb in 4" :key="'vb'+vb" :cx="bodyLeft + 20 + vb * 20" :cy="engineFrontY" r="1.5" fill="#fbbf24" opacity="0.8" />
                        <!-- Air intake horn -->
                        <rect :x="bodyRight - 18" :y="engineFrontY - 8" :width="8" :height="14" rx="3" fill="#4b5563" stroke="#1f2937" stroke-width="0.5" />
                        <!-- Engine fan (front) -->
                        <circle cx="bodyRight - 6" cy="engineFrontY + engineHeight / 2" r="12" fill="none" stroke="#64748b" stroke-width="1.5" opacity="0.6" />
                        <circle cx="bodyRight - 6" cy="engineFrontY + engineHeight / 2" r="4" fill="#475569" />
                        <!-- Fan blades -->
                        <line v-for="fb in 5" :key="'fb'+fb" :x1="bodyRight - 6" :y1="engineFrontY + engineHeight / 2" :x2="bodyRight - 6 + Math.cos(fb * 1.256) * 12" :y2="engineFrontY + engineHeight / 2 + Math.sin(fb * 1.256) * 12" stroke="#94a3b8" stroke-width="1.5" opacity="0.5" />
                        <!-- Fuel filter -->
                        <circle cx="bodyLeft + 18" cy="engineFrontY + 4" r="3.5" fill="#fcd34d" stroke="#d97706" stroke-width="0.5" />
                        <!-- Engine label -->
                        <text :x="bodyLeft + 50" :y="engineFrontY + 16" font-size="7" font-weight="700" fill="#94a3b8" opacity="0.7">DIESEL ENGINE</text>
                      </g>

                      <!-- ====== TRANSMISSION (behind engine, under cab rear) ====== -->
                      <g filter="url(#softShadow)">
                        <!-- Bell housing -->
                        <ellipse :cx="transmissionCX" :cy="transmissionY + 4" rx="32" ry="14" fill="#4b5563" stroke="#1f2937" stroke-width="1" />
                        <!-- Transmission main body -->
                        <rect :x="transmissionCX - 20" :y="transmissionY - 6" :width="40" :height="28" rx="6" fill="url(#diffGrad)" stroke="#1f2937" stroke-width="0.8" />
                        <!-- Transmission pan -->
                        <rect :x="transmissionCX - 14" :y="transmissionY + 16" :width="28" :height="8" rx="3" fill="#374151" stroke="#1f2937" stroke-width="0.6" />
                        <!-- Output shaft flange -->
                        <circle :cx="transmissionCX" :cy="transmissionY + 4" r="6" fill="#64748b" stroke="#1f2937" stroke-width="0.6" />
                        <circle :cx="transmissionCX" :cy="transmissionY + 4" r="2.5" fill="#0f172a" />
                        <!-- Transmission cooler lines -->
                        <line :x1="transmissionCX + 20" :y1="transmissionY" :x2="transmissionCX + 32" :y2="transmissionY - 8" stroke="#cbd5e1" stroke-width="1.5" opacity="0.5" />
                        <line :x1="transmissionCX + 20" :y1="transmissionY + 8" :x2="transmissionCX + 32" :y2="transmissionY + 16" stroke="#cbd5e1" stroke-width="1.5" opacity="0.5" />
                        <!-- Transmission mount -->
                        <rect :x="transmissionCX - 10" :y="transmissionY + 24" width="20" height="6" rx="3" fill="#1f2937" />
                      </g>

                      <!-- ====== LONGITUDINAL DRIVESHAFT ====== -->
                      <g v-if="driveshaftSpan">
                        <!-- Driveshaft tube -->
                        <g class="dt-part" @mouseenter="showPartTooltip($event, { title: 'Driveshaft', desc: 'Rotating tube delivering torque from the transmission to the rear differential' })" @mouseleave="hidePartTooltip">
                          <!-- Main tube body -->
                          <line :x1="driveshaftSpan.x1" :y1="driveshaftSpan.y1" :x2="driveshaftSpan.x2" :y2="driveshaftSpan.y2" stroke="#4b5563" stroke-width="18" stroke-linecap="round" filter="url(#wheelShadow)" />
                          <!-- Tube highlight -->
                          <line :x1="driveshaftSpan.x1" :y1="driveshaftSpan.y1" :x2="driveshaftSpan.x2" :y2="driveshaftSpan.y2" stroke="#cbd5e1" stroke-width="10" stroke-linecap="round" />
                          <line :x1="driveshaftSpan.x1" :y1="driveshaftSpan.y1" :x2="driveshaftSpan.x2" :y2="driveshaftSpan.y2" stroke="#f1f5f9" stroke-width="4" stroke-linecap="round" opacity="0.5" />
                          <!-- Tube balance weights -->
                          <rect :x="(driveshaftSpan.x1 + driveshaftSpan.x2) / 2 - 6" :y="driveshaftSpan.y1 - 12" width="12" height="24" rx="2" fill="#374151" opacity="0.4" />

                          <!-- Front U-joint (at transmission) -->
                          <circle :cx="driveshaftSpan.x1" :cy="driveshaftSpan.y1" r="12" fill="#475569" stroke="#1f2937" stroke-width="1.2" />
                          <circle cx="0" cy="0" r="4" fill="#0f172a" />
                          <line :x1="driveshaftSpan.x1 - 10" :y1="driveshaftSpan.y1" :x2="driveshaftSpan.x1 + 10" :y2="driveshaftSpan.y1" stroke="#cbd5e1" stroke-width="3" stroke-linecap="round" opacity="0.7" />
                          <line :x1="driveshaftSpan.x1" :y1="driveshaftSpan.y1 - 10" :x2="driveshaftSpan.x1" :y2="driveshaftSpan.y1 + 10" stroke="#cbd5e1" stroke-width="3" stroke-linecap="round" opacity="0.7" />
                          <!-- U-joint bearing caps -->
                          <circle :cx="driveshaftSpan.x1 - 10" :cy="driveshaftSpan.y1" r="2.5" fill="#94a3b8" />
                          <circle :cx="driveshaftSpan.x1 + 10" :cy="driveshaftSpan.y1" r="2.5" fill="#94a3b8" />
                          <circle :cx="driveshaftSpan.x1" :cy="driveshaftSpan.y1 - 10" r="2.5" fill="#94a3b8" />
                          <circle :cx="driveshaftSpan.x1" :cy="driveshaftSpan.y1 + 10" r="2.5" fill="#94a3b8" />

                          <!-- Center bearing carrier (for long wheelbase) -->
                          <g v-if="hasCenterBearing">
                            <rect :x="centerBearingX - 8" :y="centerBearingY - 10" width="16" height="20" rx="4" fill="#374151" stroke="#1f2937" stroke-width="0.8" />
                            <circle :cx="centerBearingX" :cy="centerBearingY" r="5" fill="#475569" stroke="#1f2937" stroke-width="0.6" />
                            <circle :cx="centerBearingX" :cy="centerBearingY" r="2.5" fill="#0f172a" />
                            <!-- Center bearing mount bracket -->
                            <rect :x="centerBearingX - 4" :y="centerBearingY + 10" width="8" height="8" rx="2" fill="#1f2937" />
                          </g>

                          <!-- Rear U-joint (at differential) -->
                          <circle :cx="driveshaftSpan.x2" :cy="driveshaftSpan.y2" r="12" fill="#475569" stroke="#1f2937" stroke-width="1.2" />
                          <line :x1="driveshaftSpan.x2 - 10" :y1="driveshaftSpan.y2" :x2="driveshaftSpan.x2 + 10" :y2="driveshaftSpan.y2" stroke="#cbd5e1" stroke-width="3" stroke-linecap="round" opacity="0.7" />
                          <line :x1="driveshaftSpan.x2" :y1="driveshaftSpan.y2 - 10" :x2="driveshaftSpan.x2" :y2="driveshaftSpan.y2 + 10" stroke="#cbd5e1" stroke-width="3" stroke-linecap="round" opacity="0.7" />
                          <circle :cx="driveshaftSpan.x2 - 10" :cy="driveshaftSpan.y2" r="2.5" fill="#94a3b8" />
                          <circle :cx="driveshaftSpan.x2 + 10" :cy="driveshaftSpan.y2" r="2.5" fill="#94a3b8" />
                          <circle :cx="driveshaftSpan.x2" :cy="driveshaftSpan.y2 - 10" r="2.5" fill="#94a3b8" />
                          <circle :cx="driveshaftSpan.x2" :cy="driveshaftSpan.y2 + 10" r="2.5" fill="#94a3b8" />
                          <circle :cx="driveshaftSpan.x2" :cy="driveshaftSpan.y2" r="4" fill="#0f172a" />
                        </g>
                      </g>

                      <!-- ====== TRANSFER CASE (4WD only) ====== -->
                      <g v-if="hasMultiplePoweredAxles" :transform="`translate(320 ${transferCaseY})`" class="dt-part" @mouseenter="showPartTooltip($event, { title: 'Transfer Case', desc: 'Splits torque from the transmission to front and rear driveshafts' })" @mouseleave="hidePartTooltip">
                        <rect x="-22" y="-18" width="44" height="36" rx="8" fill="url(#transferGrad)" stroke="#1f2937" stroke-width="1.2" filter="url(#wheelShadow)" />
                        <rect x="-16" y="-12" width="32" height="10" rx="4" fill="#1e293b" opacity="0.4" />
                        <rect x="-16" y="4" width="32" height="8" rx="3" fill="#1e293b" opacity="0.3" />
                        <circle cx="0" cy="8" r="5" fill="#64748b" stroke="#1f2937" stroke-width="0.6" />
                        <circle cx="0" cy="8" r="2.5" fill="#0f172a" />
                        <!-- Transfer case shift linkage -->
                        <line x1="-22" y1="-8" x2="-34" y2="-14" stroke="#94a3b8" stroke-width="2" opacity="0.5" />
                      </g>

                      <!-- ====== EXHAUST SYSTEM ====== -->
                      <g opacity="0.7">
                        <!-- Downpipe from engine -->
                        <path :d="`M ${bodyRight - 6} ${engineFrontY + engineHeight} Q ${bodyRight + 20} ${engineFrontY + engineHeight + 10} ${bodyRight + 16} ${engineFrontY + engineHeight + 30}`" fill="none" stroke="url(#exhaustGrad)" stroke-width="5" stroke-linecap="round" />
                        <!-- Muffler -->
                        <rect :x="bodyRight + 8" :y="engineFrontY + engineHeight + 30" width="28" height="14" rx="6" fill="url(#mufflerGrad)" stroke="#4b5563" stroke-width="0.8" filter="url(#metalFlare)" />
                        <!-- Muffler seams -->
                        <line :x1="bodyRight + 14" :y1="engineFrontY + engineHeight + 30" :x2="bodyRight + 14" :y2="engineFrontY + engineHeight + 44" stroke="#64748b" stroke-width="0.6" />
                        <line :x1="bodyRight + 22" :y1="engineFrontY + engineHeight + 30" :x2="bodyRight + 22" :y2="engineFrontY + engineHeight + 44" stroke="#64748b" stroke-width="0.6" />
                        <!-- Tailpipe -->
                        <path :d="`M ${bodyRight + 36} ${engineFrontY + engineHeight + 37} Q ${bodyRight + 50} ${engineFrontY + engineHeight + 37} ${bodyRight + 48} ${engineFrontY + engineHeight + 50}`" fill="none" stroke="#6b7280" stroke-width="4" stroke-linecap="round" />
                        <!-- Exhaust hangers -->
                        <line :x1="bodyRight + 14" :y1="engineFrontY + engineHeight + 30" :x2="bodyRight + 14" :y2="engineFrontY + engineHeight + 28" stroke="#475569" stroke-width="1.5" />
                        <line :x1="bodyRight + 22" :y1="engineFrontY + engineHeight + 30" :x2="bodyRight + 22" :y2="engineFrontY + engineHeight + 28" stroke="#475569" stroke-width="1.5" />
                      </g>

                      <!-- ====== DIFFERENTIALS ====== -->
                      <g v-for="(ax, ai) in layout.axles" :key="'drv' + ai">
                        <template v-if="isPowered(ax.role)">
                          <g :transform="`translate(320 ${ax.y})`" class="dt-part" @mouseenter="showPartTooltip($event, { title: ax.label + ' Differential', desc: 'Final-drive gear set splitting torque between the left and right axle shafts' })" @mouseleave="hidePartTooltip">
                            <!-- Differential housing (pumpkin) -->
                            <ellipse rx="28" ry="18" fill="url(#pumpkinGrad)" stroke="#4c1d95" stroke-width="1.4" filter="url(#wheelShadow)" />
                            <!-- Housing cooling fins -->
                            <line v-for="fi in 6" :key="'fin'+fi" :x1="-22 + fi * 8" :y1="-16" :x2="-22 + fi * 8" :y2="16" stroke="#7c3aed" stroke-width="1.2" opacity="0.4" />
                            <!-- Housing highlight -->
                            <ellipse cx="-6" cy="-6" rx="14" ry="6" fill="#a78bfa" opacity="0.3" />
                            <!-- Differential cover bolts -->
                            <circle v-for="db in 8" :key="'db'+db" :cx="Math.cos(db * 0.785) * 18" :cy="Math.sin(db * 0.785) * 11" r="1.5" fill="#d8b4fe" opacity="0.6" />
                            <!-- Pinion flange -->
                            <circle cx="0" cy="0" r="8" fill="#64748b" stroke="#1f2937" stroke-width="0.8" />
                            <circle cx="0" cy="0" r="3" fill="#0f172a" />
                            <!-- Yoke -->
                            <circle cx="0" cy="0" r="6" fill="none" stroke="#cbd5e1" stroke-width="2" opacity="0.6" />
                            <!-- Axle tube connections (left and right) -->
                            <rect x="-30" y="-10" width="6" height="20" rx="2" fill="#374151" stroke="#1f2937" stroke-width="0.5" />
                            <rect x="24" y="-10" width="6" height="20" rx="2" fill="#374151" stroke="#1f2937" stroke-width="0.5" />
                          </g>
                        </template>
                      </g>

                      <!-- ====== AXLE TUBES, HALF-SHAFTS & SUSPENSION PER AXLE ====== -->
                      <g v-for="(axle, ai) in layout.axles" :key="'axle'+ai">
                        <!-- Axle tube (solid beam connecting left-right) -->
                        <g v-for="pos in axle.positions" :key="'tube'+pos.code">
                          <template v-if="pos.side === 'L'">
                            <!-- Main axle tube from center to hub -->
                            <line :x1="320" :y1="axle.y" :x2="pos.x" :y2="axle.y" stroke="url(#axleGrad)" stroke-width="14" stroke-linecap="round" />
                            <!-- Axle tube highlight -->
                            <line :x1="320" :y1="axle.y - 0" :x2="pos.x" :y2="axle.y" stroke="#cbd5e1" stroke-width="3" stroke-linecap="round" opacity="0.25" />
                          </template>
                        </g>

                        <!-- ====== LEAF SPRINGS (realistic multi-leaf) ====== -->
                        <g v-for="(side, si) in ['L', 'R']" :key="'spring'+ai+si">
                          <g :transform="`translate(${side === 'L' ? (axle.dual ? bodyLeft - 42 : bodyLeft - 28) : (axle.dual ? bodyRight + 42 : bodyRight + 28)}, ${axle.y})`">
                            <!-- Main leaf -->
                            <path :d="`M -8 -8 Q 0 -16 8 -8`" fill="none" stroke="url(#springGrad)" stroke-width="4" stroke-linecap="round" />
                            <!-- Second leaf -->
                            <path :d="`M -6 -5 Q 0 -12 6 -5`" fill="none" stroke="#64748b" stroke-width="3" stroke-linecap="round" opacity="0.8" />
                            <!-- Third leaf -->
                            <path :d="`M -4 -3 Q 0 -8 4 -3`" fill="none" stroke="#4b5563" stroke-width="2.5" stroke-linecap="round" opacity="0.7" />
                            <!-- Spring eyelets -->
                            <circle cx="-8" cy="-8" r="2.5" fill="#475569" stroke="#1f2937" stroke-width="0.5" />
                            <circle cx="8" cy="-8" r="2.5" fill="#475569" stroke="#1f2937" stroke-width="0.5" />
                            <!-- U-bolt clamping the spring to axle -->
                            <rect x="-4" y="-6" width="8" height="8" rx="1" fill="#374151" opacity="0.7" />
                          </g>
                        </g>

                        <!-- ====== SHOCK ABSORBERS ====== -->
                        <g v-for="(side, si) in ['L', 'R']" :key="'shock'+ai+si">
                          <g :transform="`translate(${side === 'L' ? bodyLeft - 10 : bodyRight + 10}, ${axle.y})`">
                            <!-- Shock body -->
                            <rect x="-2" y="-14" width="4" height="28" rx="2" fill="url(#shockGrad)" stroke="#1f2937" stroke-width="0.5" />
                            <!-- Shock rod -->
                            <line x1="0" y1="-18" x2="0" y2="-14" stroke="#cbd5e1" stroke-width="2" />
                            <!-- Shock bushing top -->
                            <circle cx="0" cy="-18" r="2.5" fill="#475569" stroke="#1f2937" stroke-width="0.5" />
                            <!-- Shock bushing bottom -->
                            <circle cx="0" cy="14" r="2.5" fill="#475569" stroke="#1f2937" stroke-width="0.5" />
                            <!-- Coil spring around shock -->
                            <path :d="`M -5 -10 Q -6 -6 -5 -2 Q -4 2 -5 6 Q -6 10 -5 12`" fill="none" stroke="#64748b" stroke-width="2.5" opacity="0.5" />
                            <path :d="`M 5 -10 Q 6 -6 5 -2 Q 4 2 5 6 Q 6 10 5 12`" fill="none" stroke="#64748b" stroke-width="2.5" opacity="0.5" />
                          </g>
                        </g>

                        <!-- ====== BRAKE DRUMS / CALIPERS ====== -->
                        <g v-for="pos in axle.positions" :key="'brake'+pos.code">
                          <g :transform="`translate(${pos.x} ${axle.y})`">
                            <circle r="pos.r * 0.35 + 3" fill="none" stroke="#b91c1c" stroke-width="3" opacity="0.6" />
                            <!-- Brake caliper (disc) -->
                            <rect :x="-pos.r * 0.1" :y="-pos.r * 0.22" width="pos.r * 0.2" height="pos.r * 0.44" rx="2" fill="#dc2626" stroke="#991b1b" stroke-width="0.5" opacity="0.7" />
                            <!-- Brake line -->
                            <line :x1="0" :y1="-pos.r * 0.3" :x2="0" :y2="-pos.r * 0.4" stroke="#cbd5e1" stroke-width="1" />
                          </g>
                        </g>
                      </g>

                      <!-- ====== LATERAL DRIVETRAIN PARTS (half-shafts, CV joints, steering) ====== -->
                      <g v-for="(part, pi) in drivetrainParts" :key="'part' + pi">
                        <!-- Steering tie rod -->
                        <g v-if="part.kind === 'steering-link'" :transform="`translate(${part.x} ${part.y})`" class="dt-part" @mouseenter="showPartTooltip($event, part)" @mouseleave="hidePartTooltip">
                          <!-- Tie rod tube -->
                          <line :x1="-24" :y1="0" :x2="24" :y2="0" stroke="#64748b" stroke-width="4" stroke-linecap="round" />
                          <!-- Tie rod ends -->
                          <circle cx="-24" cy="0" r="4" fill="#475569" stroke="#1f2937" stroke-width="0.5" />
                          <circle cx="24" cy="0" r="4" fill="#475569" stroke="#1f2937" stroke-width="0.5" />
                          <!-- Drag link (to steering arm) -->
                          <line x1="0" y1="0" x2="8" y2="-14" stroke="#475569" stroke-width="3" stroke-linecap="round" opacity="0.6" />
                          <circle cx="8" cy="-14" r="3" fill="#475569" stroke="#1f2937" stroke-width="0.5" />
                        </g>

                        <!-- CV Joints (at wheel hubs on driven axles) -->
                        <g v-else-if="part.kind === 'cv-joint'" :transform="`translate(${part.x} ${part.y})`" class="dt-part" @mouseenter="showPartTooltip($event, part)" @mouseleave="hidePartTooltip">
                          <!-- CV boot (rubber) -->
                          <path :d="`M -7 -1 Q -11 -4 -10 -8 Q -8 -12 -4 -12 Q 0 -12 3 -10 Q 7 -8 7 -4 Q 7 0 4 2 Z`" fill="#1e293b" stroke="#0f172a" stroke-width="0.6" />
                          <!-- CV boot ribs -->
                          <line x1="-8" y1="-8" x2="-2" y2="-10" stroke="#334155" stroke-width="0.8" opacity="0.5" />
                          <line x1="-7" y1="-5" x2="-1" y2="-7" stroke="#334155" stroke-width="0.8" opacity="0.5" />
                          <!-- Metal CV housing -->
                          <circle cx="0" cy="0" r="5" fill="#64748b" stroke="#1f2937" stroke-width="0.6" />
                          <circle cx="0" cy="0" r="2" fill="#0f172a" />
                        </g>
                      </g>

                      <!-- ====== WHEELS ====== -->
                      <g v-for="axle in layout.axles" :key="axle.index">
                        <text :x="axle.rightEdge + 10" :y="axle.y + 4" font-size="11" font-weight="700" fill="#64748b">{{ axle.label }}</text>

                        <g v-for="pos in axle.positions" :key="pos.code"
                           :transform="`translate(${pos.x} ${pos.y})`"
                           class="wheel-g"
                           :class="{ selected: selectedPosition === pos.code, occupied: pos.occupied, available: !pos.occupied }"
                           @click="pos.occupied ? null : selectPosition(pos.code)"
                           @mouseenter="hoveredPosition = pos.code"
                           @mouseleave="hoveredPosition = null"
                        >
                          <!-- Tire shadow on ground (standing tire, contact patch parallel to axle) -->
                          <ellipse :cx="0" :cy="pos.r * 1.58" :rx="pos.r * 0.6" :ry="pos.r * 0.14" fill="#000" opacity="0.25" />

                          <g v-if="pos.occupied" filter="url(#wheelShadow)">
                          <g transform="scale(1, 1.6)">
                            <!-- Main tire body (side-profile, standing upright) -->
                            <circle :r="pos.r" fill="url(#treadGrad)" stroke="#0f141e" stroke-width="1.2" />
                            <!-- Circumferential tread grooves (read as tread bands of a standing tire) -->
                            <circle :r="pos.r * 0.85" fill="none" stroke="#0f172a" stroke-width="1.2" opacity="0.4" />
                            <circle :r="pos.r * 0.75" fill="none" stroke="#0f172a" stroke-width="1.2" opacity="0.4" />
                            
                            <!-- Tread bevel -->
                            <path :d="treadBevelPath(pos.r)" fill="#475569" opacity="0.5" />
                            
                            <!-- Sidewall -->
                            <circle :r="pos.r * 0.78" fill="url(#sidewallGrad)" />
                            <circle :r="pos.r * 0.78" fill="none" stroke="#0f141e" stroke-width="1" opacity="0.5" />
                            
                            <!-- Sidewall text/markings (realistic tire branding) -->
                            <text :y="-pos.r * 0.42" text-anchor="middle" font-size="5" font-weight="700" fill="#64748b" opacity="0.6">{{ tire.brand?.substring(0, 8) || 'LT285' }}</text>
                            <text :y="pos.r * 0.58" text-anchor="middle" font-size="4.5" font-weight="600" fill="#4b5563" opacity="0.5">{{ tire.size || '75R16' }}</text>
                            
                            <!-- Rim -->
                            <circle :r="pos.r * 0.64" fill="url(#rimMetal)" stroke="#475569" stroke-width="0.8" />
                            <circle :r="pos.r * 0.64" fill="none" stroke="#64748b" stroke-width="1.2" opacity="0.4" />
                            
                            <!-- Rim lip -->
                            <circle :r="pos.r * 0.64" fill="none" stroke="#e2e8f0" stroke-width="0.8" opacity="0.5" />
                            
                            <!-- Wheel spokes (realistic truck steel rims) -->
                            <g stroke="#cbd5e1" stroke-width="2.6" stroke-linecap="round" opacity="0.85">
                              <line v-for="s in spokes(pos.r)" :key="s.i" :x1="s.x1" :y1="s.y1" :x2="s.x2" :y2="s.y2" />
                            </g>
                            
                            <!-- Lug nuts -->
                            <g fill="#334155" stroke="#1e293b" stroke-width="0.6">
                              <circle v-for="l in lugNuts(pos.r)" :key="l.i" :cx="l.x" :cy="l.y" r="2.6" />
                              <!-- Lug nut hex pattern -->
                              <circle v-for="l in lugNuts(pos.r)" :key="'lh'+l.i" :cx="l.x - 0.5" :cy="l.y - 0.5" r="1" fill="#64748b" opacity="0.4" />
                            </g>
                            
                            <!-- Hub center with spindle -->
                            <circle :r="pos.r * 0.16" fill="#1e293b" />
                            <!-- Hub highlight -->
                            <circle :cx="-pos.r * 0.04" :cy="-pos.r * 0.04" r="pos.r * 0.06" fill="#64748b" opacity="0.6" />
                            <!-- Wheel spindle / axle stub protruding from hub -->
                            <circle :r="pos.r * 0.08" fill="#94a3b8" stroke="#475569" stroke-width="0.5" />
                            <circle :r="pos.r * 0.04" fill="#1e293b" />
                            <!-- Hub-to-axle mounting flange -->
                            <circle :r="pos.r * 0.20" fill="none" stroke="#64748b" stroke-width="0.5" opacity="0.7" />
                          </g>

                            <!-- Tire serial number -->
                            <text :y="pos.r * 1.6 + 12" text-anchor="middle" font-size="8" font-weight="700" fill="#475569" font-family="monospace">{{ pos.tireSerial }}</text>
                          </g>

                          <g v-else filter="url(#wheelShadow)">
                          <g transform="scale(1, 1.6)">
                            <!-- Brake drum/hub for empty position -->
                            <circle :r="pos.r * 0.9" fill="url(#drumGrad)" stroke="#1f2937" stroke-width="1.2" />
                            <circle :r="pos.r * 0.9" fill="none" stroke="#64748b" stroke-width="0.8" opacity="0.3" />
                            
                            <!-- Drum cooling grooves -->
                            <g stroke="#1e293b" stroke-width="1.2" opacity="0.5">
                              <line v-for="a in drumGrooves(pos.r)" :key="a.i" :x1="a.x1" :y1="a.y1" :x2="a.x2" :y2="a.y2" />
                            </g>
                            
                            <!-- Hub center with spindle -->
                            <circle :r="pos.r * 0.24" fill="#1f2937" stroke="#374151" stroke-width="0.8" />
                            <!-- Wheel spindle / axle stub -->
                            <circle :r="pos.r * 0.12" fill="#64748b" stroke="#475569" stroke-width="0.5" />
                            <circle :r="pos.r * 0.06" fill="#1e293b" />
                            
                            <!-- Lug studs -->
                            <g fill="#64748b">
                              <circle v-for="l in lugNuts(pos.r * 0.9)" :key="l.i" :cx="l.x" :cy="l.y" r="2" />
                            </g>
                            
                            <!-- Selection ring -->
                            <circle :r="pos.r" fill="none" stroke="#6366f1" stroke-width="2" stroke-dasharray="6 4" opacity="0.7" />
                          </g>

                            <!-- Position label -->
                            <text :y="pos.r * 1.6 + 12" text-anchor="middle" font-size="8" font-weight="700" fill="#64748b">{{ pos.shortLabel }}</text>
                          </g>

                          <!-- Selection indicator (matches standing tire, parallel to axle) -->
                          <ellipse v-if="selectedPosition === pos.code" :rx="pos.r + 8" :ry="pos.r * 1.6 + 8" fill="none" stroke="#10b981" stroke-width="3.5" filter="url(#glow)" class="sel-ring" />
                          <ellipse v-else-if="hoveredPosition === pos.code && !pos.occupied" :rx="pos.r + 5" :ry="pos.r * 1.6 + 5" fill="none" stroke="#6366f1" stroke-width="2.6" opacity="0.75" />
                        </g>
                      </g>

                      <!-- ====== SPARE TIRE CARRIER ====== -->
                      <g v-if="layout.spare"
                         :transform="`translate(${layout.spare.x} ${layout.spare.y})`"
                         class="wheel-g"
                         :class="{ selected: selectedPosition === 'Spare', occupied: layout.spare.occupied, available: !layout.spare.occupied }"
                         @click="layout.spare.occupied ? null : selectPosition('Spare')"
                         @mouseenter="hoveredPosition = 'Spare'"
                         @mouseleave="hoveredPosition = null"
                      >
                        <!-- Spare carrier bracket -->
                        <rect x="-36" y="-36" width="72" height="72" rx="8" fill="#1e293b" opacity="0.15" />
                        <rect x="-36" y="-36" width="72" height="72" rx="8" fill="none" stroke="#374151" stroke-width="1" opacity="0.4" />
                        <!-- Carrier arm -->
                        <line x1="-20" y1="20" x2="20" y2="20" stroke="#475569" stroke-width="3" opacity="0.5" />
                        
                        <!-- Spare shadow -->
                        <ellipse cx="0" cy="28" rx="30" ry="8" fill="#000" opacity="0.22" />
                        
                        <g v-if="layout.spare.occupied" filter="url(#wheelShadow)">
                          <circle r="28" fill="url(#treadGrad)" stroke="#0f141e" stroke-width="1.2" />
                          <g stroke="#0f172a" stroke-width="2.4" stroke-linecap="round">
                            <line v-for="a in treadArcs(28)" :key="a.i" :x1="a.x1" :y1="a.y1" :x2="a.x2" :y2="a.y2" />
                          </g>
                          <circle r="22" fill="url(#sidewallGrad)" />
                          <circle r="18" fill="url(#rimMetal)" stroke="#475569" stroke-width="0.8" />
                          <g stroke="#cbd5e1" stroke-width="2.2" stroke-linecap="round" opacity="0.85">
                            <line v-for="s in spokes(28)" :key="s.i" :x1="s.x1" :y1="s.y1" :x2="s.x2" :y2="s.y2" />
                          </g>
                          <circle v-for="l in lugNuts(28)" :key="l.i" :cx="l.x" :cy="l.y" r="2" fill="#334155" />
                          <circle r="4.5" fill="#1e293b" />
                        </g>
                        <g v-else>
                          <circle r="26" fill="url(#drumGrad)" stroke="#1f2937" stroke-width="1.2" />
                          <circle r="7" fill="#1f2937" />
                          <g fill="#64748b">
                            <circle v-for="l in lugNuts(26)" :key="l.i" :cx="l.x" :cy="l.y" r="1.8" />
                          </g>
                          <circle r="30" fill="none" stroke="#6366f1" stroke-width="2" stroke-dasharray="6 4" opacity="0.7" />
                        </g>
                        <text y="46" text-anchor="middle" font-size="9" font-weight="700" fill="#64748b">Spare</text>
                        <circle v-if="selectedPosition === 'Spare'" r="36" fill="none" stroke="#10b981" stroke-width="3.5" filter="url(#glow)" class="sel-ring" />
                        <circle v-else-if="hoveredPosition === 'Spare' && !layout.spare.occupied" r="34" fill="none" stroke="#6366f1" stroke-width="2.6" opacity="0.75" />
                      </g>
                    </g>
                  </svg>
                </div>

                <!-- Legend -->
                <div v-if="selectedVehicle" class="d-flex align-center flex-wrap ga-4 mt-2">
                  <div class="d-flex align-center ga-1">
                    <span class="legend-dot" style="background: #1e293b"></span>
                    <span class="text-caption text-medium-emphasis">Mounted tire</span>
                  </div>
                  <div class="d-flex align-center ga-1">
                    <span class="legend-dot legend-dash"></span>
                    <span class="text-caption text-medium-emphasis">Available position</span>
                  </div>
                  <div class="d-flex align-center ga-1">
                    <span class="legend-dot" style="background: #10b981; box-shadow: 0 0 6px #10b981"></span>
                    <span class="text-caption text-medium-emphasis">Selected</span>
                  </div>
                  <v-spacer />
                  <v-chip size="x-small" variant="tonal" color="primary" label>
                    <v-icon size="x-small" start>mdi-axis-arrow-info</v-icon>{{ drivetrainLabel }} · {{ layout.axles.length }} axles · {{ totalWheels }} wheels
                  </v-chip>
                </div>

                <!-- Position chips (alternative selection) -->
                <div v-if="selectedVehicle" class="d-flex flex-wrap ga-1 mt-3">
                  <v-chip
                    v-for="pos in allPositions"
                    :key="pos.code"
                    size="small"
                    :color="selectedPosition === pos.code ? 'success' : (pos.occupied ? 'grey-lighten-1' : 'default')"
                    :variant="selectedPosition === pos.code ? 'flat' : (pos.occupied ? 'flat' : 'outlined')"
                    :disabled="pos.occupied"
                    label
                    @click="!pos.occupied && selectPosition(pos.code)"
                  >
                    <v-icon v-if="pos.occupied" size="x-small" start>mdi-tire</v-icon>
                    <v-icon v-else-if="selectedPosition === pos.code" size="x-small" start>mdi-check</v-icon>
                    {{ pos.label }}
                  </v-chip>
                </div>
              </div>
            </div>
          </v-col>

          <!-- RIGHT: Mount form / summary -->
          <v-col cols="12" md="5">
            <div class="pa-5">
              <h3 class="text-subtitle-1 font-weight-bold mb-3" style="color: #1e293b">
                <v-icon size="18" color="primary" class="mr-1">mdi-clipboard-list-outline</v-icon>Mount Details
              </h3>

              <v-card v-if="selectedVehicle" elevation="0" border rounded="lg" class="pa-4 mb-4" style="background: #f8fafc">
                <p class="text-caption text-medium-emphasis mb-1">Mounting position</p>
                <div class="d-flex align-center ga-2">
                  <v-icon color="success">mdi-crosshairs-gps</v-icon>
                  <p class="text-h6 font-weight-bold" style="color: #1e293b">{{ selectedPositionLabel || '— Not selected —' }}</p>
                </div>
                <p v-if="selectedVehicle" class="text-caption text-medium-emphasis mt-1">
                  on {{ selectedVehicle.display_name }}
                </p>
              </v-card>

              <v-alert
                v-if="selectedVehicle && !selectedPosition && touched"
                type="warning" variant="tonal" density="compact" class="mb-3"
                text="Select a wheel position on the axle diagram to mount this tire."
              />

              <v-row dense>
                <v-col cols="12">
                  <v-text-field
                    v-model="mountForm.performed_at"
                    type="date"
                    label="Date Mounted"
                    prepend-inner-icon="mdi-calendar"
                    hide-details="auto"
                  />
                </v-col>
                <v-col cols="12">
                  <v-text-field
                    v-model.number="mountForm.odometer"
                    :label="`Odometer (${selectedVehicle?.mileage_unit === 'miles' ? 'mi' : 'km'})`"
                    type="number" min="0"
                    prepend-inner-icon="mdi-counter"
                    hide-details="auto"
                    :placeholder="selectedVehicle ? String(selectedVehicle.current_mileage ?? '') : ''"
                  />
                </v-col>
                <v-col cols="12">
                  <v-textarea v-model="mountForm.notes" label="Notes" rows="3" prepend-inner-icon="mdi-note-text-outline" hide-details="auto" placeholder="Optional — e.g. mount reason, installer name…" />
                </v-col>
              </v-row>

              <div v-if="selectedVehicle && selectedPosition" class="mt-4 pa-3 rounded-lg" style="background: #ecfdf3; border: 1px solid #a7f3d0">
                <div class="d-flex align-center ga-2 mb-1">
                  <v-icon size="18" color="success">mdi-check-circle</v-icon>
                  <span class="text-body-2 font-weight-medium" style="color: #065f46">Ready to mount</span>
                </div>
                <p class="text-caption" style="color: #047857">
                  {{ tire.serial_number }} → {{ selectedVehicle.display_name }} · {{ selectedPositionLabel }}
                </p>
              </div>

              <v-divider class="my-5" />

              <div class="d-flex ga-2">
                <v-btn variant="text" prepend-icon="mdi-close" size="large" @click="$emit('cancel')">Cancel</v-btn>
                <v-spacer />
                <v-btn color="success" size="large" prepend-icon="mdi-arrow-up-bold-hexagon-outline" :loading="saving" :disabled="!selectedVehicle || !selectedPosition" @click="confirmMount">
                  <span class="font-weight-bold">Mount Tire</span>
                </v-btn>
              </div>
            </div>
          </v-col>
        </v-row>
      </v-card>

      <!-- Mount history -->
      <v-card v-if="movements.length" elevation="0" border rounded="lg" class="overflow-hidden">
        <v-toolbar flat density="compact" color="transparent">
          <v-icon size="small" color="primary" class="ml-4 mr-1">mdi-history</v-icon>
          <v-toolbar-title class="text-subtitle-2 font-weight-bold" style="color: #1e293b">Mount History</v-toolbar-title>
        </v-toolbar>
        <v-data-table :headers="historyHeaders" :items="movements" :loading="historyPending" hover items-per-page="10" density="compact">
          <template #item.performed_at="{ value }">{{ value ? new Date(value).toLocaleDateString() : '—' }}</template>
          <template #item.movement_type="{ value }">
            <v-chip size="small" :color="historyColor(value)" variant="flat">{{ value }}</v-chip>
          </template>
          <template #item.from_vehicle_name="{ value }">
            <span v-if="value" class="text-body-2">{{ value }}</span>
            <span v-else class="text-caption text-medium-emphasis">—</span>
          </template>
          <template #item.to_vehicle_name="{ value }">
            <span v-if="value" class="text-body-2">{{ value }}</span>
            <span v-else class="text-caption text-medium-emphasis">—</span>
          </template>
          <template #item.from_position="{ value }">
            <span class="text-body-2">{{ value || '—' }}</span>
          </template>
          <template #item.to_position="{ value }">
            <span class="text-body-2">{{ value || '—' }}</span>
          </template>
          <template #item.odometer="{ value }">{{ value != null ? Number(value).toLocaleString() : '—' }}</template>
          <template #no-data>
            <div class="text-center py-8 text-medium-emphasis">
              <v-icon size="36" class="mb-2">mdi-history</v-icon>
              <p class="text-body-2">No mount history recorded yet.</p>
            </div>
          </template>
        </v-data-table>
      </v-card>
    </template>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  tire: any | null
  vehicles: any[]
  tires: any[]
  loading?: boolean
}>()
const emit = defineEmits<{
  mounted: []
  cancel: []
}>()
const { $api, $swal } = useNuxtApp()

const mountForm = reactive<any>({ vehicle: null, position: '', odometer: null, notes: '', performed_at: new Date().toISOString().slice(0, 10) })
const saving = ref(false)
const touched = ref(false)
const selectedPosition = ref('')
const hoveredPosition = ref<string | null>(null)
const viewAngle = ref<'top' | 'persp'>('persp')
const rearWheelMode = ref<'single' | 'dual'>('dual')

const selectedVehicle = computed(() => props.vehicles.find((v: any) => v.id === mountForm.vehicle) || null)

// --- 3D interaction state (rotate / zoom / hover) ---
const stageSvg = ref<SVGSVGElement | null>(null)
const rotation = reactive({ x: 24, y: 0, z: 0 })
const scale = ref(1)
const dragging = ref(false)
const dragStart = reactive({ x: 0, y: 0, rx: 0, ry: 0 })
const tooltip = reactive({ show: false, x: 0, y: 0, title: '', desc: '' })

const MIN_SCALE = 0.5
const MAX_SCALE = 2.2

function clampScale(v: number) {
  return Math.min(MAX_SCALE, Math.max(MIN_SCALE, v))
}

const stageTransform = computed(() => {
  const persp = viewAngle.value === 'persp' ? `perspective(1500px) rotateX(${rotation.x}deg) ` : ''
  return `${persp}rotateZ(${rotation.z}deg) scale(${scale.value})`
})

function resetView() {
  rotation.x = viewAngle.value === 'persp' ? 24 : 0
  rotation.y = 0
  rotation.z = 0
  scale.value = 1
}

function rotateBy(dz: number) {
  rotation.z += dz
}

function zoomBy(delta: number) {
  scale.value = clampScale(scale.value + delta)
}

function onStagePointerDown(e: PointerEvent) {
  dragging.value = true
  dragStart.x = e.clientX
  dragStart.y = e.clientY
  dragStart.rx = rotation.z
  dragStart.ry = rotation.x
}

function onStagePointerMove(e: PointerEvent) {
  if (!dragging.value) return
  rotation.z = dragStart.rx + (e.clientX - dragStart.x) * 0.5
  if (viewAngle.value === 'persp') {
    rotation.x = Math.min(80, Math.max(-20, dragStart.ry - (e.clientY - dragStart.y) * 0.4))
  }
}

function onStagePointerUp() {
  dragging.value = false
}

function onStageWheel(e: WheelEvent) {
  scale.value = clampScale(scale.value + e.deltaY * -0.0015)
}

function showPartTooltip(e: MouseEvent, part: any) {
  const rect = stageSvg.value?.getBoundingClientRect() || { left: 0, top: 0 }
  tooltip.show = true
  tooltip.x = e.clientX - rect.left + 14
  tooltip.y = e.clientY - rect.top + 14
  tooltip.title = part.title || part.kind
  tooltip.desc = part.desc || ''
}

function hidePartTooltip() {
  tooltip.show = false
}

watch(viewAngle, (v) => {
  resetView()
})

// --- Mount history for this tire ---
const historyHeaders = [
  { title: 'Date', key: 'performed_at', width: '120px', sortable: true },
  { title: 'Type', key: 'movement_type', width: '100px' },
  { title: 'From Vehicle', key: 'from_vehicle_name', sortable: true },
  { title: 'From Pos.', key: 'from_position', width: '110px' },
  { title: 'To Vehicle', key: 'to_vehicle_name', sortable: true },
  { title: 'To Pos.', key: 'to_position', width: '100px' },
  { title: 'Odometer', key: 'odometer', width: '110px' },
  { title: 'Notes', key: 'notes' },
]
function historyColor(m: string) {
  return { mount: 'success', unmount: 'warning', transfer: 'info', retread: 'purple' }[m] || 'default'
}
const { data: movementData, pending: historyPending } = useAsyncData(
  'tire-mount-history',
  () => props.tire ? $api('/tires/movements/', { params: { tire: props.tire.id } }) : Promise.resolve({ results: [] }),
  { default: () => ({ results: [] }), watch: [() => props.tire] },
)
const movements: any = computed(() => (movementData.value as any)?.results || (movementData.value as any) || [])

watch(() => mountForm.vehicle, (val, old) => {
  if (val !== old) {
    selectedPosition.value = ''
    mountForm.position = ''
    const v = selectedVehicle.value
    if (v && (mountForm.odometer == null || mountForm.odometer === '')) {
      mountForm.odometer = v.current_mileage ?? null
    }
  }
})

// ---------- Axle + drivetrain layout derivation ----------
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

function deriveAxles(vehicle: any) {
  const dt = (vehicle?.drivetrain || '').toUpperCase().replace(/[Xx]/, '-')
  const vt = vehicle?.vehicle_type || 'vehicle'
  const dualMode = rearWheelMode.value === 'dual'
  if (vt === 'trailer') return [{ role: 'trailer', dual: dualMode }, { role: 'trailer', dual: dualMode }]
  if (vt === 'equipment' || vt === 'non_powered') return [{ role: 'tag', dual: false }, { role: 'tag', dual: false }]
  switch (dt) {
    case '6-2': return [{ role: 'steer', dual: false }, { role: 'drive', dual: dualMode }, { role: 'tag', dual: false }]
    case '6-4': return [{ role: 'steer', dual: false }, { role: 'drive', dual: dualMode }, { role: 'drive', dual: dualMode }]
    case '8-4':
      return [{ role: 'steer', dual: false }, { role: 'steer', dual: false }, { role: 'drive', dual: false }, { role: 'drive', dual: dualMode }]
    case '8-2':
      return [{ role: 'steer', dual: false }, { role: 'steer', dual: false }, { role: 'drive', dual: dualMode }, { role: 'tag', dual: false }]
    case '4WD':
      return [{ role: 'steer', dual: false }, { role: 'drive', dual: false }]
    case '4-4':
      return [{ role: 'steer', dual: false }, { role: 'drive', dual: dualMode }]
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

const layout = computed(() => {
  const vehicle = selectedVehicle.value
  if (!vehicle) return { axles: [], spare: null as any }

  const defs = deriveAxles(vehicle)
  const counts: Record<string, number> = { steer: 0, drive: 0, tag: 0, trailer: 0 }
  defs.forEach((a) => { counts[a.role] = (counts[a.role] || 0) + 1 })

  const n = defs.length
  const yRange = bedRearY - cabFrontY - 30
  const axles = defs.map((a, i) => {
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
        { code: `${tag}_L_Outer`, label: `${label} Left Outer`, side: 'L', wheel: 'Outer', x: bodyLeft - 66, y, r },
        { code: `${tag}_L_Inner`, label: `${label} Left Inner`, side: 'L', wheel: 'Inner', x: bodyLeft - 20, y, r },
        { code: `${tag}_R_Inner`, label: `${label} Right Inner`, side: 'R', wheel: 'Inner', x: bodyRight + 20, y, r },
        { code: `${tag}_R_Outer`, label: `${label} Right Outer`, side: 'R', wheel: 'Outer', x: bodyRight + 66, y, r },
      ]
    } else {
      positions = [
        { code: `${tag}_L`, label: `${label} Left`, side: 'L', wheel: null, x: bodyLeft - 46, y, r },
        { code: `${tag}_R`, label: `${label} Right`, side: 'R', wheel: null, x: bodyRight + 46, y, r },
      ]
    }
    return {
      index: i, role: a.role, dual, tag, label, y,
      leftEdge: dual ? bodyLeft - 70 : bodyLeft - 50,
      rightEdge: dual ? bodyRight + 70 : bodyRight + 50,
      positions,
    }
  })

  const mounted = props.tires.filter((t: any) => t.vehicle === vehicle.id && (t.status === 'mounted' || t.status === 'spare'))
  const occByCode: Record<string, any> = {}
  mounted.forEach((t: any) => { if (t.position) occByCode[t.position] = t })

  axles.forEach((ax) => {
    ax.positions.forEach((p) => {
      const t = occByCode[p.code]
      p.occupied = !!t
      p.tireSerial = t ? t.serial_number : null
      p.shortLabel = p.label.replace(ax.label + ' ', '')
    })
  })

  const spareTire = occByCode['Spare']
  const spare = {
    code: 'Spare', label: 'Spare', x: 560, y: bedRearY, r: 28,
    occupied: !!spareTire, tireSerial: spareTire ? spareTire.serial_number : null,
  }

  return { axles, spare }
})

const totalWheels = computed(() => {
  let c = 0
  layout.value.axles.forEach((a: any) => c += a.positions.length)
  if (layout.value.spare) c++
  return c
})

// --- Drivetrain parts ---
function isPowered(role: string) {
  return role === 'drive' || role === 'steer'
}

const drivetrainParts = computed(() => {
  const axles = layout.value.axles
  if (!axles.length) return [] as any[]
  const parts: any[] = []
  const cx = (bodyLeft + bodyRight) / 2

  axles.forEach((axle: any) => {
    const powered = isPowered(axle.role)

    axle.positions.forEach((pos: any) => {
      if (!powered) return
      const left = pos.x < cx
      const diffEdge = left ? cx - 20 : cx + 20
      const hubEdge = left ? pos.x + pos.r * 0.5 : pos.x - pos.r * 0.5
      if (Math.abs(hubEdge - diffEdge) > 10) {
        parts.push({
          kind: 'half-shaft',
          x: left ? diffEdge : diffEdge, y: axle.y,
          length: Math.abs(hubEdge - diffEdge),
          angle: left ? 180 : 0,
          title: 'Axle Shaft',
          desc: 'Rotating shaft delivering torque from the differential to the wheel hub',
        })
      }
      parts.push({
        kind: 'cv-joint',
        x: hubEdge, y: axle.y,
        desc: 'Constant-velocity joint allowing the wheel to articulate while spinning',
      })
    })

    if (axle.role === 'steer') {
      parts.push({
        kind: 'steering-link',
        x: cx, y: axle.y - 16,
        title: 'Tie Rod',
        desc: 'Links the steering arms so both front wheels turn together',
      })
    }
  })

  return parts
})

const poweredAxles = computed(() => layout.value.axles.filter((a: any) => isPowered(a.role)))
const hasPoweredAxles = computed(() => poweredAxles.value.length > 0)
const hasMultiplePoweredAxles = computed(() => poweredAxles.value.length > 1)

// Engine sits under the cab
const engineFrontY = computed(() => cabFrontY + 28)
const engineHeight = 28

// Transmission center X and Y
const transmissionCX = 320
const transmissionY = computed(() => {
  const ax = layout.value.axles
  if (!ax.length) return cabFrontY + 140
  return cabFrontY + 120
})

// Longitudinal driveshaft
const driveshaftSpan = computed(() => {
  if (!hasPoweredAxles.value) return null
  const last = poweredAxles.value[poweredAxles.value.length - 1]
  return { x1: 320, y1: transmissionY.value + 22, x2: 320, y2: last.y - 16 }
})

// Center bearing for longer driveshafts (when span > 180)
const hasCenterBearing = computed(() => {
  if (!driveshaftSpan.value) return false
  return Math.abs(driveshaftSpan.value.y2 - driveshaftSpan.value.y1) > 150
})
const centerBearingX = computed(() => 320)
const centerBearingY = computed(() => {
  if (!driveshaftSpan.value) return 0
  return (driveshaftSpan.value.y1 + driveshaftSpan.value.y2) / 2
})

// Transfer case
const transferCaseY = computed(() => {
  if (!hasMultiplePoweredAxles.value) return 0
  const first = poweredAxles.value[0]
  return (transmissionY.value + first.y) / 2
})

// Frame hole positions
const frameHoles = computed(() => {
  const holes: any[] = []
  for (let y = cabFrontY + 40; y < bedRearY - 20; y += 22) {
    holes.push({ y })
  }
  return holes
})

// Frame rivet positions
const frameRivets = computed(() => {
  const rivets: any[] = []
  for (let y = cabFrontY + 20; y < bedRearY - 10; y += 10) {
    rivets.push({ y })
  }
  return rivets
})

const drivetrainLabel = computed(() => {
  const v = selectedVehicle.value
  const dt = (v?.drivetrain || '').toUpperCase().replace(/[Xx]/, '-')
  if (dt) return dt
  const vt = v?.vehicle_type || 'vehicle'
  if (vt === 'trailer') return 'Trailer Axle'
  if (vt === 'equipment' || vt === 'non_powered') return 'Tag Axle'
  return '4x2'
})

const allPositions = computed(() => {
  const list: any[] = []
  layout.value.axles.forEach((a: any) => a.positions.forEach((p: any) => list.push(p)))
  if (layout.value.spare) list.push({ ...layout.value.spare, label: 'Spare' })
  return list
})

const selectedPositionLabel = computed(() => {
  if (!selectedPosition.value) return ''
  const p = allPositions.value.find((x: any) => x.code === selectedPosition.value)
  return p?.label || selectedPosition.value
})

function selectPosition(code: string) {
  selectedPosition.value = code
  mountForm.position = code
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

async function confirmMount() {
  touched.value = true
  if (!mountForm.vehicle) {
    $swal.fire({ icon: 'error', title: 'Vehicle required', text: 'Please select a vehicle.', timer: 2500, toast: true, position: 'top-end' })
    return
  }
  if (!selectedPosition.value) {
    $swal.fire({ icon: 'error', title: 'Position required', text: 'Select a wheel position on the axle diagram.', timer: 2800, toast: true, position: 'top-end' })
    return
  }
  saving.value = true
  try {
    const body: any = { vehicle: mountForm.vehicle, position: selectedPosition.value, notes: mountForm.notes || '', performed_at: mountForm.performed_at || new Date().toISOString().slice(0, 10) }
    if (mountForm.odometer != null && mountForm.odometer !== '') body.odometer = mountForm.odometer
    await $api(`/tires/${props.tire.id}/mount/`, { method: 'POST', body })
    emit('mounted')
    $swal.fire({ icon: 'success', title: 'Tire mounted', timer: 1600, toast: true, position: 'top-end' })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Mount failed', text: e?.data?.detail || e?.message || 'Could not mount tire' })
  } finally { saving.value = false }
}
</script>

<style scoped>
.axle-stage {
  position: relative;
  background: linear-gradient(180deg, #eef2f6 0%, #dce3ec 100%);
  border: 1px solid #cbd5e1;
  border-radius: 16px;
  min-height: 380px;
  padding: 16px;
  overflow: hidden;
  cursor: grab;
  user-select: none;
  touch-action: none;
}
.axle-stage:active {
  cursor: grabbing;
}
.axle-floor {
  position: absolute;
  inset: 0;
  background-image: radial-gradient(circle at 50% 90%, rgba(99, 102, 241, 0.05), transparent 60%);
  pointer-events: none;
}
.axle-empty {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
}
.axle-canvas-wrap {
  transition: transform 0.6s cubic-bezier(0.22, 1, 0.36, 1);
  transform-origin: 50% 60%;
}
.axle-svg {
  width: 100%;
  height: auto;
  display: block;
}
.wheel-g {
  cursor: pointer;
  transition: transform 0.25s ease;
  transform-box: fill-box;
}
.wheel-g.available:hover {
  transform: scale(1.06);
}
.wheel-g.occupied {
  cursor: not-allowed;
}
.wheel-g.selected {
  transform: scale(1.05);
}
.sel-ring {
  animation: pulse 1.6s ease-in-out infinite;
}
@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.45; }
}
.legend-dot {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  display: inline-block;
}
.legend-dash {
  background: transparent;
  border: 2px dashed #94a3b8;
}
.axle-controls {
  position: absolute;
  top: 12px;
  right: 12px;
  z-index: 4;
  display: flex;
  align-items: center;
  gap: 2px;
  background: rgba(255, 255, 255, 0.85);
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 4px 6px;
  box-shadow: 0 4px 10px rgba(15, 23, 42, 0.06);
}
.axle-controls .v-btn {
  color: #475569;
}
.dt-label {
  font-family: Arial, sans-serif;
  font-size: 10px;
  font-weight: 700;
  fill: #334155;
  pointer-events: none;
}
.dt-part {
  cursor: help;
  transition: opacity 0.2s ease;
}
.dt-part:hover {
  opacity: 0.8;
}
.dt-tooltip {
  position: absolute;
  z-index: 6;
  background: rgba(15, 23, 42, 0.95);
  color: #f8fafc;
  border-radius: 8px;
  padding: 8px 12px;
  box-shadow: 0 8px 20px rgba(15, 23, 42, 0.25);
  pointer-events: none;
  max-width: 240px;
}
.dt-tooltip-title {
  font-size: 12px;
  font-weight: 700;
}
.dt-tooltip-desc {
  font-size: 11px;
  margin-top: 2px;
  opacity: 0.82;
}
</style>
