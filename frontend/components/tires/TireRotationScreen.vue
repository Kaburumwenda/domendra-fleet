<template>
  <div class="d-flex flex-column ga-4">
    <!-- Header -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-2">
      <div class="d-flex align-center ga-2">
        <v-btn icon="mdi-arrow-left" size="small" variant="text" color="primary" @click="$emit('cancel')" />
        <div>
          <h1 class="text-h5 font-weight-bold" style="color: #1e293b">{{ props.editingRotation ? 'Edit Rotation' : 'Record Rotation' }}</h1>
          <p class="text-caption text-medium-emphasis">{{ props.editingRotation ? 'Adjust the swap plan and fields, then update the rotation.' : 'Select a vehicle, pick two wheel positions to swap on the 3D axle, then confirm.' }}</p>
        </div>
      </div>
      <v-btn variant="text" prepend-icon="mdi-close" @click="$emit('cancel')">Cancel</v-btn>
    </div>

    <!-- No vehicle selected yet -->
    <v-card v-if="!vehicles.length && loading" elevation="0" border rounded="lg" class="pa-12 text-center text-medium-emphasis">
      <v-progress-circular indeterminate color="primary" class="mb-3" />
      <p class="text-body-2">Loading vehicles…</p>
    </v-card>

    <v-card v-else-if="!vehicles.length" type="error" variant="tonal" elevation="0" border rounded="lg" class="pa-12 text-center">
      <v-icon size="40" class="mb-2"> mdi-car-off </v-icon>
      <p class="text-body-2 font-weight-medium">No vehicles available</p>
      <p class="text-caption text-medium-emphasis">Add a vehicle before recording a rotation.</p>
    </v-card>

    <template v-else>
      <v-card elevation="0" border rounded="lg" class="overflow-hidden">
        <v-row no-gutters>
          <!-- LEFT: 3D Axle Visualization -->
          <v-col cols="12" md="7" style="border-right: 1px solid #e2e8f0">
            <div class="pa-5">
              <!-- Vehicle selector + rear wheel count controls -->
              <div class="d-flex align-center justify-space-between flex-wrap ga-2 mb-3">
                <div style="min-width: 280px; flex: 1 1 280px">
                  <v-select
                    v-model="rotationForm.vehicle"
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
                <div v-if="tooltip.show" class="dt-tooltip" :style="{ left: tooltip.x + 'px', top: tooltip.y + 'px' }">
                  <div class="dt-tooltip-title">{{ tooltip.title }}</div>
                  <div v-if="tooltip.desc" class="dt-tooltip-desc">{{ tooltip.desc }}</div>
                </div>

                <div v-if="!selectedVehicle" class="axle-empty">
                  <v-icon size="56" class="mb-2" color="primary">mdi-car-truck</v-icon>
                  <p class="text-body-2 font-weight-medium" style="color: #475569">Select a vehicle to render its axle layout</p>
                  <p class="text-caption text-medium-emphasis">The 3D axle diagram adapts to the selected vehicle's drivetrain</p>
                </div>

                <div v-else-if="mountedTires.length < 2" class="axle-empty">
                  <v-icon size="56" class="mb-2" color="warning">mdi-tire</v-icon>
                  <p class="text-body-2 font-weight-medium" style="color: #475569">Not enough mounted tires</p>
                  <p class="text-caption text-medium-emphasis">At least two tires must be mounted on this vehicle to rotate.</p>
                </div>

                <div v-else class="axle-canvas-wrap" :style="{ transform: stageTransform }">
                  <svg ref="stageSvg" viewBox="0 0 640 540" class="axle-svg" xmlns="http://www.w3.org/2000/svg">
                    <defs>
                      <radialGradient id="rTreadGrad" cx="40%" cy="36%" r="68%">
                        <stop offset="0%" stop-color="#2d3748" />
                        <stop offset="50%" stop-color="#1a202c" />
                        <stop offset="100%" stop-color="#0f141e" />
                      </radialGradient>
                      <radialGradient id="rSidewallGrad" cx="42%" cy="38%" r="70%">
                        <stop offset="0%" stop-color="#4a5568" />
                        <stop offset="60%" stop-color="#2d3748" />
                        <stop offset="100%" stop-color="#171c27" />
                      </radialGradient>
                      <radialGradient id="rRimMetal" cx="38%" cy="34%" r="70%">
                        <stop offset="0%" stop-color="#ffffff" />
                        <stop offset="30%" stop-color="#e2e8f0" />
                        <stop offset="65%" stop-color="#94a3b8" />
                        <stop offset="100%" stop-color="#475569" />
                      </radialGradient>
                      <radialGradient id="rDrumGrad" cx="40%" cy="36%" r="68%">
                        <stop offset="0%" stop-color="#6b7280" />
                        <stop offset="50%" stop-color="#374151" />
                        <stop offset="100%" stop-color="#1f2937" />
                      </radialGradient>
                      <linearGradient id="rAxleGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stop-color="#4b5563" />
                        <stop offset="40%" stop-color="#9ca3af" />
                        <stop offset="100%" stop-color="#374151" />
                      </linearGradient>
                      <radialGradient id="rPumpkinGrad" cx="36%" cy="32%" r="72%">
                        <stop offset="0%" stop-color="#a78bfa" />
                        <stop offset="50%" stop-color="#7c3aed" />
                        <stop offset="100%" stop-color="#5b21b6" />
                      </radialGradient>
                      <linearGradient id="rFrameGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stop-color="#4b5563" />
                        <stop offset="40%" stop-color="#94a3b8" />
                        <stop offset="100%" stop-color="#374151" />
                      </linearGradient>
                      <radialGradient id="rDiffGrad" cx="38%" cy="34%" r="70%">
                        <stop offset="0%" stop-color="#9ca3af" />
                        <stop offset="50%" stop-color="#6b7280" />
                        <stop offset="100%" stop-color="#374151" />
                      </radialGradient>
                      <radialGradient id="rTransferGrad" cx="36%" cy="32%" r="72%">
                        <stop offset="0%" stop-color="#cbd5e1" />
                        <stop offset="50%" stop-color="#64748b" />
                        <stop offset="100%" stop-color="#1e293b" />
                      </radialGradient>
                      <linearGradient id="rEngineGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stop-color="#4b5563" />
                        <stop offset="40%" stop-color="#6b7280" />
                        <stop offset="100%" stop-color="#374151" />
                      </linearGradient>
                      <linearGradient id="rValveGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stop-color="#fbbf24" />
                        <stop offset="50%" stop-color="#d97706" />
                        <stop offset="100%" stop-color="#b45309" />
                      </linearGradient>
                      <linearGradient id="rCabGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stop-color="#1e40af" />
                        <stop offset="50%" stop-color="#1d4ed8" />
                        <stop offset="100%" stop-color="#1e3a8a" />
                      </linearGradient>
                      <linearGradient id="rBedGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stop-color="#1e1b4b" />
                        <stop offset="100%" stop-color="#111827" />
                      </linearGradient>
                      <radialGradient id="rGroundGrad" cx="50%" cy="50%" r="55%">
                        <stop offset="0%" stop-color="#e2e8f0" />
                        <stop offset="100%" stop-color="#cbd5e1" />
                      </radialGradient>
                      <linearGradient id="rSpringGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stop-color="#6b7280" />
                        <stop offset="30%" stop-color="#9ca3af" />
                        <stop offset="100%" stop-color="#475569" />
                      </linearGradient>
                      <linearGradient id="rShockGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stop-color="#cbd5e1" />
                        <stop offset="50%" stop-color="#6b7280" />
                        <stop offset="100%" stop-color="#374151" />
                      </linearGradient>
                      <linearGradient id="rExhaustGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stop-color="#9ca3af" />
                        <stop offset="50%" stop-color="#6b7280" />
                        <stop offset="100%" stop-color="#475569" />
                      </linearGradient>
                      <linearGradient id="rMufflerGrad" x1="0" y1="0" x2="1" y2="0">
                        <stop offset="0%" stop-color="#9ca3af" />
                        <stop offset="50%" stop-color="#d1d5db" />
                        <stop offset="100%" stop-color="#6b7280" />
                      </linearGradient>
                      <linearGradient id="rShaftGrad" x1="0" y1="0" x2="1" y2="0">
                        <stop offset="0%" stop-color="#6b7280" />
                        <stop offset="50%" stop-color="#d1d5db" />
                        <stop offset="100%" stop-color="#4b5563" />
                      </linearGradient>
                      <filter id="rGlow" x="-80%" y="-80%" width="260%" height="260%">
                        <feGaussianBlur stdDeviation="6" result="b" />
                        <feMerge><feMergeNode in="b" /><feMergeNode in="SourceGraphic" /></feMerge>
                      </filter>
                      <filter id="rSoftShadow" x="-60%" y="-60%" width="220%" height="220%">
                        <feGaussianBlur in="SourceAlpha" stdDeviation="5" />
                        <feOffset dy="6" result="o" />
                        <feComponentTransfer><feFuncA type="linear" slope="0.32" /></feComponentTransfer>
                        <feMerge><feMergeNode /><feMergeNode in="SourceGraphic" /></feMerge>
                      </filter>
                      <filter id="rWheelShadow" x="-60%" y="-60%" width="220%" height="220%">
                        <feGaussianBlur in="SourceAlpha" stdDeviation="3" />
                        <feOffset dy="4" result="o" />
                        <feComponentTransfer><feFuncA type="linear" slope="0.4" /></feComponentTransfer>
                        <feMerge><feMergeNode /><feMergeNode in="SourceGraphic" /></feMerge>
                      </filter>
                      <filter id="rMetalFlare" x="-50%" y="-50%" width="200%" height="200%">
                        <feGaussianBlur stdDeviation="1.5" result="b" />
                        <feMerge><feMergeNode in="b" /><feMergeNode in="SourceGraphic" /></feMerge>
                      </filter>
                      <linearGradient id="rSwapGrad" x1="0" y1="0" x2="1" y2="0">
                        <stop offset="0%" stop-color="#6366f1" />
                        <stop offset="100%" stop-color="#8b5cf6" />
                      </linearGradient>
                    </defs>

                    <!-- Ground -->
                    <ellipse cx="320" cy="492" rx="280" ry="38" fill="url(#rGroundGrad)" />
                    <ellipse cx="320" cy="492" rx="265" ry="32" fill="#000" opacity="0.08" />
                    <g stroke="#bfc9d4" stroke-width="0.8" opacity="0.4">
                      <line v-for="gx in [100, 180, 260, 320, 380, 460, 540]" :key="'gx'+gx" :x1="gx" :y1="478" :x2="gx - 35" :y2="512" />
                      <line v-for="gy in [462, 472, 484, 498, 510]" :key="'gy'+gy" :x1="80" :y1="gy" :x2="560" :y2="gy" />
                    </g>

                    <g :transform="`rotate(${rotation.z} 320 256)`">
                      <!-- Frame chassis -->
                      <g filter="url(#rSoftShadow)">
                        <g v-for="(side, si) in [{x: bodyLeft - 16, flip: 1}, {x: bodyRight - 4, flip: -1}]" :key="'rail'+si">
                          <rect :x="side.x" :y="cabFrontY + 8" :width="12" :height="bedRearY - cabFrontY - 12" rx="3" fill="url(#rFrameGrad)" stroke="#1f2937" stroke-width="1" />
                          <rect :x="side.x + (side.flip > 0 ? 2 : 0)" :y="cabFrontY + 14" :width="8" :height="bedRearY - cabFrontY - 24" rx="2" fill="#cbd5e1" opacity="0.2" />
                          <circle v-for="fh in frameHoles" :key="'fh'+si+fh.y" :cx="side.x + 6" :cy="fh.y" r="2.5" fill="#1e293b" opacity="0.5" />
                        </g>
                        <rect v-for="ax in layout.axles" :key="'cm' + ax.index" :x="bodyLeft - 16" :y="ax.y - 6" :width="bodyRight - bodyLeft + 24" :height="12" rx="4" fill="url(#rFrameGrad)" stroke="#374151" stroke-width="0.8" opacity="0.85" />
                        <rect :x="bodyLeft - 16" :y="cabRearY + 10" :width="bodyRight - bodyLeft + 24" :height="10" rx="3" fill="url(#rFrameGrad)" stroke="#374151" stroke-width="0.6" opacity="0.7" />
                        <rect :x="bodyLeft - 16" :y="bedRearY - 16" :width="bodyRight - bodyLeft + 24" :height="10" rx="3" fill="url(#rFrameGrad)" stroke="#374151" stroke-width="0.6" opacity="0.7" />
                      </g>

                      <!-- Cab -->
                      <g filter="url(#rSoftShadow)">
                        <rect :x="cabLeft" :y="cabFrontY - 4" :width="cabWidth" :height="cabHeight" rx="12" fill="url(#rCabGrad)" stroke="#1e3a8a" stroke-width="1" />
                        <rect :x="cabLeft + 8" :y="cabFrontY - 10" :width="cabWidth - 16" :height="14" rx="7" fill="#2563eb" opacity="0.6" />
                        <rect :x="cabLeft + 18" :y="cabFrontY + 10" :width="cabWidth - 36" :height="22" rx="4" fill="#60a5fa" opacity="0.5" stroke="#93c5fd" stroke-width="0.6" />
                        <line :x1="cabLeft + 22" :y1="cabFrontY + 14" :x2="cabLeft + cabWidth - 22" :y2="cabFrontY + 14" stroke="#bfdbfe" stroke-width="1" opacity="0.6" />
                        <rect :x="cabLeft + 4" :y="cabFrontY + 16" :width="16" :height="14" rx="3" fill="#60a5fa" opacity="0.35" stroke="#93c5fd" stroke-width="0.5" />
                        <rect :x="cabRight - 20" :y="cabFrontY + 16" :width="16" :height="14" rx="3" fill="#60a5fa" opacity="0.35" stroke="#93c5fd" stroke-width="0.5" />
                        <rect :x="cabLeft + 14" :y="cabFrontY + 36" :width="cabWidth - 28" :height="16" rx="3" fill="#1e293b" stroke="#0f172a" stroke-width="0.6" />
                        <line v-for="gs in 5" :key="'gs'+gs" :x1="cabLeft + 22" :y1="cabFrontY + 38 + gs * 3" :x2="cabRight - 22" :y2="cabFrontY + 38 + gs * 3" stroke="#334155" stroke-width="0.8" />
                        <rect :x="cabLeft + 6" :y="cabFrontY + 38" width="12" height="8" rx="2" fill="#fef08a" stroke="#ca8a04" stroke-width="0.5" filter="url(#rGlow)" />
                        <rect :x="cabRight - 18" :y="cabFrontY + 38" width="12" height="8" rx="2" fill="#fef08a" stroke="#ca8a04" stroke-width="0.5" filter="url(#rGlow)" />
                        <rect :x="cabLeft - 2" :y="cabFrontY + 54" :width="cabWidth + 4" :height="6" rx="2" fill="#475569" stroke="#1f2937" stroke-width="0.6" />
                      </g>

                      <!-- Bed -->
                      <g filter="url(#rSoftShadow)">
                        <rect :x="bedLeft" :y="bedTopY" :width="bedWidth" :height="bedHeight" rx="8" fill="url(#rBedGrad)" stroke="#111827" stroke-width="0.8" />
                        <line v-for="bp in 6" :key="'bp'+bp" :x1="bedLeft + 6" :y1="bedTopY + 6 + bp * 6" :x2="bedRight - 6" :y2="bedTopY + 6 + bp * 6" stroke="#1f2937" stroke-width="0.6" opacity="0.5" />
                        <rect :x="bedLeft" :y="bedTopY - 14" :width="6" :height="bedHeight + 14" rx="2" fill="#374151" stroke="#111827" stroke-width="0.6" />
                        <rect :x="bedRight - 6" :y="bedTopY - 14" :width="6" :height="bedHeight + 14" rx="2" fill="#374151" stroke="#111827" stroke-width="0.6" />
                        <rect :x="bedRight - 8" :y="bedTopY + bedHeight - 16" width="6" height="10" rx="2" fill="#ef4444" stroke="#991b1b" stroke-width="0.5" filter="url(#rGlow)" />
                        <rect :x="bedLeft + 2" :y="bedTopY + bedHeight - 16" width="6" height="10" rx="2" fill="#ef4444" stroke="#991b1b" stroke-width="0.5" filter="url(#rGlow)" />
                      </g>

                      <!-- Engine -->
                      <g filter="url(#rSoftShadow)">
                        <rect :x="bodyLeft + 8" :y="engineFrontY" :width="bodyRight - bodyLeft - 16" :height="engineHeight" rx="6" fill="url(#rEngineGrad)" stroke="#1f2937" stroke-width="1" />
                        <rect :x="bodyLeft + 14" :y="engineFrontY + engineHeight - 6" :width="bodyRight - bodyLeft - 28" :height="10" rx="3" fill="#374151" stroke="#1f2937" stroke-width="0.8" />
                        <rect :x="bodyLeft + 12" :y="engineFrontY - 4" :width="bodyRight - bodyLeft - 60" :height="8" rx="3" fill="url(#rValveGrad)" stroke="#92400e" stroke-width="0.6" />
                        <rect :x="bodyLeft + 48" :y="engineFrontY - 4" :width="bodyRight - bodyLeft - 60" :height="8" rx="3" fill="url(#rValveGrad)" stroke="#92400e" stroke-width="0.6" />
                        <text :x="bodyLeft + 50" :y="engineFrontY + 16" font-size="7" font-weight="700" fill="#94a3b8" opacity="0.7">DIESEL ENGINE</text>
                      </g>

                      <!-- Transmission -->
                      <g filter="url(#rSoftShadow)">
                        <ellipse :cx="transmissionCX" :cy="transmissionY + 4" rx="32" ry="14" fill="#4b5563" stroke="#1f2937" stroke-width="1" />
                        <rect :x="transmissionCX - 20" :y="transmissionY - 6" :width="40" :height="28" rx="6" fill="url(#rDiffGrad)" stroke="#1f2937" stroke-width="0.8" />
                      </g>

                      <!-- Swap connector arcs (drawn behind wheels for depth) -->
                      <g v-for="(sw, i) in swapArcs" :key="'arc'+i">
                        <path :d="sw.path" fill="none" stroke="url(#rSwapGrad)" stroke-width="3.5" stroke-linecap="round" stroke-dasharray="7 5" class="swap-arc" :opacity="sw.opacity" />
                        <polygon :points="sw.arrow" fill="#8b5cf6" :opacity="sw.opacity" />
                      </g>

                      <!-- Axle tubes -->
                      <g v-for="(axle, ai) in layout.axles" :key="'axle'+ai">
                        <g v-for="pos in axle.positions" :key="'tube'+pos.code">
                          <template v-if="pos.side === 'L'">
                            <line :x1="320" :y1="axle.y" :x2="pos.x" :y2="axle.y" stroke="url(#rAxleGrad)" stroke-width="14" stroke-linecap="round" />
                          </template>
                        </g>
                      </g>

                      <!-- Differentials -->
                      <g v-for="(ax, ai) in layout.axles" :key="'drv'+ai">
                        <template v-if="isPowered(ax.role)">
                          <g :transform="`translate(320 ${ax.y})`">
                            <ellipse rx="28" ry="18" fill="url(#rPumpkinGrad)" stroke="#4c1d95" stroke-width="1.4" filter="url(#rWheelShadow)" />
                            <circle cx="0" cy="0" r="8" fill="#64748b" stroke="#1f2937" stroke-width="0.8" />
                            <circle cx="0" cy="0" r="3" fill="#0f172a" />
                          </g>
                        </template>
                      </g>

                      <!-- WHEELS -->
                      <g v-for="axle in layout.axles" :key="axle.index">
                        <text :x="axle.rightEdge + 10" :y="axle.y + 4" font-size="11" font-weight="700" fill="#64748b">{{ axle.label }}</text>

                        <g v-for="pos in axle.positions" :key="pos.code"
                           :transform="`translate(${pos.x} ${pos.y})`"
                           class="wheel-g"
                           :class="{ selectable: pos.occupied, selected: isSelected(pos.code), swapTarget: isSwapTarget(pos.code), empty: !pos.occupied }"
                           @click="onWheelClick(pos)"
                           @mouseenter="hoveredPosition = pos.code"
                           @mouseleave="hoveredPosition = null"
                        >
                          <ellipse :cx="0" :cy="pos.r * 0.92" :rx="pos.r * 1.1" :ry="pos.r * 0.28" fill="#000" opacity="0.2" />

                          <g v-if="pos.occupied" filter="url(#rWheelShadow)">
                            <circle :r="pos.r" fill="url(#rTreadGrad)" stroke="#0f141e" stroke-width="1.2" />
                            <g stroke="#0f172a" stroke-width="2.8" stroke-linecap="round">
                              <line v-for="a in treadArcs(pos.r)" :key="a.i" :x1="a.x1" :y1="a.y1" :x2="a.x2" :y2="a.y2" />
                            </g>
                            <circle :r="pos.r * 0.85" fill="none" stroke="#0f172a" stroke-width="1.2" opacity="0.4" />
                            <circle :r="pos.r * 0.75" fill="none" stroke="#0f172a" stroke-width="1.2" opacity="0.4" />
                            <path :d="treadBevelPath(pos.r)" fill="#475569" opacity="0.5" />
                            <circle :r="pos.r * 0.78" fill="url(#rSidewallGrad)" />
                            <circle :r="pos.r * 0.78" fill="none" stroke="#0f141e" stroke-width="1" opacity="0.5" />
                            <text :y="-pos.r * 0.42" text-anchor="middle" font-size="5" font-weight="700" fill="#64748b" opacity="0.6">{{ tireBrand(pos.tireId)?.substring(0, 8) || 'LT285' }}</text>
                            <text :y="pos.r * 0.58" text-anchor="middle" font-size="4.5" font-weight="600" fill="#4b5563" opacity="0.5">{{ tireSize(pos.tireId) || '75R16' }}</text>
                            <circle :r="pos.r * 0.64" fill="url(#rRimMetal)" stroke="#475569" stroke-width="0.8" />
                            <g stroke="#cbd5e1" stroke-width="2.6" stroke-linecap="round" opacity="0.85">
                              <line v-for="s in spokes(pos.r)" :key="s.i" :x1="s.x1" :y1="s.y1" :x2="s.x2" :y2="s.y2" />
                            </g>
                            <g fill="#334155" stroke="#1e293b" stroke-width="0.6">
                              <circle v-for="l in lugNuts(pos.r)" :key="l.i" :cx="l.x" :cy="l.y" r="2.6" />
                            </g>
                            <circle :r="pos.r * 0.16" fill="#1e293b" />
                            <circle :r="pos.r * 0.08" fill="#94a3b8" stroke="#475569" stroke-width="0.5" />
                            <text :y="pos.r + 14" text-anchor="middle" font-size="8" font-weight="700" fill="#475569" font-family="monospace">{{ pos.tireSerial }}</text>
                          </g>

                          <g v-else filter="url(#rWheelShadow)">
                            <circle :r="pos.r * 0.9" fill="url(#rDrumGrad)" stroke="#1f2937" stroke-width="1.2" />
                            <circle :r="pos.r * 0.24" fill="#1e293b" stroke="#374151" stroke-width="0.8" />
                            <circle :r="pos.r * 0.08" fill="#94a3b8" stroke="#475569" stroke-width="0.5" />
                            <text :y="pos.r + 14" text-anchor="middle" font-size="8" font-weight="700" fill="#94a3b8">{{ pos.shortLabel }}</text>
                            <text :y="pos.r * 0.2" text-anchor="middle" font-size="9" fill="#94a3b8" opacity="0.6">empty</text>
                          </g>

                          <!-- Selection ring -->
                          <circle v-if="isSelected(pos.code)" :r="pos.r + 8" fill="none" stroke="#6366f1" stroke-width="3.5" filter="url(#rGlow)" class="sel-ring" />
                          <circle v-else-if="isSwapTarget(pos.code)" :r="pos.r + 6" fill="none" stroke="#8b5cf6" stroke-width="3" stroke-dasharray="6 4" filter="url(#rGlow)" class="sel-ring" />
                          <circle v-else-if="hoveredPosition === pos.code && pos.occupied" :r="pos.r + 5" fill="none" stroke="#10b981" stroke-width="2.6" opacity="0.75" />
                        </g>
                      </g>
                    </g>
                  </svg>
                </div>

                <!-- Legend -->
                <div v-if="selectedVehicle && mountedTires.length >= 2" class="d-flex align-center flex-wrap ga-4 mt-2">
                  <div class="d-flex align-center ga-1">
                    <span class="legend-dot" style="background: #1e293b"></span>
                    <span class="text-caption text-medium-emphasis">Mounted tire</span>
                  </div>
                  <div class="d-flex align-center ga-1">
                    <span class="legend-dot" style="background: #6366f1; box-shadow: 0 0 6px #6366f1"></span>
                    <span class="text-caption text-medium-emphasis">First pick</span>
                  </div>
                  <div class="d-flex align-center ga-1">
                    <span class="legend-dot legend-dash" style="border-color: #8b5cf6"></span>
                    <span class="text-caption text-medium-emphasis">Swap target</span>
                  </div>
                  <v-spacer />
                  <v-chip size="x-small" variant="tonal" color="primary" label>
                    <v-icon size="x-small" start>mdi-axis-arrow-info</v-icon>{{ drivetrainLabel }} · {{ layout.axles.length }} axles · {{ mountedTires.length }} mounted
                  </v-chip>
                </div>

                <!-- Position chips -->
                <div v-if="selectedVehicle && allPositions.length" class="d-flex flex-wrap ga-1 mt-3">
                  <v-chip
                    v-for="pos in allPositions"
                    :key="pos.code"
                    size="small"
                    :color="isSelected(pos.code) ? 'primary' : (isSwapTarget(pos.code) ? 'purple' : (pos.occupied ? 'default' : 'grey-lighten-2'))"
                    :variant="isSelected(pos.code) || isSwapTarget(pos.code) ? 'flat' : (pos.occupied ? 'tonal' : 'outlined')"
                    :disabled="!pos.occupied"
                    label
                    @click="onWheelClick(pos)"
                  >
                    <v-icon v-if="isSelected(pos.code)" size="x-small" start>mdi-numeric-1-circle</v-icon>
                    <v-icon v-else-if="isSwapTarget(pos.code)" size="x-small" start>mdi-numeric-2-circle</v-icon>
                    <v-icon v-else-if="pos.occupied" size="x-small" start>mdi-tire</v-icon>
                    {{ pos.shortLabel }}
                  </v-chip>
                </div>

                <!-- Hint banner -->
                <v-alert
                  v-if="selectedVehicle && mountedTires.length >= 2"
                  :type="hintType"
                  variant="tonal"
                  density="compact"
                  class="mt-3"
                >
                  <span class="text-body-2">{{ hintMessage }}</span>
                </v-alert>
              </div>
            </div>
          </v-col>

          <!-- RIGHT: Rotation form / swap plan -->
          <v-col cols="12" md="5">
            <div class="pa-5">
              <h3 class="text-subtitle-1 font-weight-bold mb-3" style="color: #1e293b">
                <v-icon size="18" color="primary" class="mr-1">mdi-swap-horizontal-bold</v-icon>Rotation Details
              </h3>

              <v-card v-if="selectedVehicle" elevation="0" border rounded="lg" class="pa-4 mb-4" style="background: #f8fafc">
                <div class="d-flex align-center ga-2 mb-1">
                  <v-icon color="primary" size="small">mdi-car</v-icon>
                  <span class="text-body-2 font-weight-medium" style="color: #1e293b">{{ selectedVehicle.display_name }}</span>
                </div>
                <p class="text-caption text-medium-emphasis mb-0">{{ selectedVehicle.vin || 'No VIN' }} · {{ drivetrainLabel }}</p>
              </v-card>

              <!-- Swap plan list -->
              <div v-if="swapPlan.length" class="mb-4">
                <div class="d-flex align-center justify-space-between mb-2">
                  <p class="text-subtitle-2 font-weight-medium mb-0" style="color: #475569">Swap Plan ({{ swapPlan.length }})</p>
                  <v-btn size="x-small" variant="text" color="error" prepend-icon="mdi-delete-sweep" @click="clearSwapPlan">Clear all</v-btn>
                </div>
                <div class="d-flex flex-column ga-2">
                  <div v-for="(sw, i) in swapPlan" :key="i" class="swap-row pa-3 rounded-lg" style="background: #f8fafc; border: 1px solid #e2e8f0">
                    <div class="d-flex align-center ga-2">
                      <v-avatar size="28" color="primary" variant="tonal" class="text-body-2 font-weight-bold">{{ i + 1 }}</v-avatar>
                      <div class="flex-grow-1">
                        <div class="d-flex align-center ga-2 flex-wrap">
                          <div>
                            <p class="text-caption text-medium-emphasis mb-0">{{ sw.fromLabel }}</p>
                            <p class="text-body-2 font-weight-medium mb-0" style="color: #1e293b">{{ sw.fromSerial }}</p>
                          </div>
                          <v-icon color="primary" size="18">mdi-swap-horizontal-bold</v-icon>
                          <div>
                            <p class="text-caption text-medium-emphasis mb-0">{{ sw.toLabel }}</p>
                            <p class="text-body-2 font-weight-medium mb-0" style="color: #1e293b">{{ sw.toSerial }}</p>
                          </div>
                        </div>
                      </div>
                      <v-btn icon="mdi-close" size="x-small" variant="text" color="error" @click="removeSwap(i)" />
                    </div>
                  </div>
                </div>
              </div>

              <v-alert v-else type="info" variant="tonal" density="compact" class="mb-4">
                <span class="text-body-2">Click a mounted tire, then click another mounted tire to add a swap. Add as many swaps as needed.</span>
              </v-alert>

              <v-row dense>
                <v-col cols="12">
                  <v-select
                    v-model="rotationForm.rotation_pattern"
                    :items="rotationPatterns"
                    label="Rotation Pattern"
                    prepend-inner-icon="mdi-swap-horizontal-bold"
                    hide-details="auto"
                    clearable
                    hint="Optional — describes the standard pattern applied"
                    persistent-hint
                  />
                </v-col>
                <v-col cols="12" md="6">
                  <v-text-field
                    v-model="rotationForm.performed_at"
                    type="date"
                    label="Date Performed"
                    prepend-inner-icon="mdi-calendar"
                    hide-details="auto"
                  />
                </v-col>
                <v-col cols="12" md="6">
                  <v-text-field
                    v-model.number="rotationForm.odometer"
                    :label="`Odometer (${selectedVehicle?.mileage_unit === 'miles' ? 'mi' : 'km'})`"
                    type="number" min="0"
                    prepend-inner-icon="mdi-counter"
                    hide-details="auto"
                    :placeholder="selectedVehicle ? String(selectedVehicle.current_mileage ?? '') : ''"
                  />
                </v-col>
                <v-col cols="12">
                  <v-textarea v-model="rotationForm.notes" label="Notes" rows="2" prepend-inner-icon="mdi-note-text-outline" hide-details="auto" placeholder="Optional — e.g. rotation reason, technician name…" />
                </v-col>
              </v-row>

              <div v-if="swapPlan.length >= 1 && selectedFirst" class="mt-4 pa-3 rounded-lg" style="background: #eef2ff; border: 1px solid #c7d2fe">
                <div class="d-flex align-center ga-2 mb-1">
                  <v-icon size="18" color="primary">mdi-cursor-default-click</v-icon>
                  <span class="text-body-2 font-weight-medium" style="color: #3730a3">Pick a target to swap with</span>
                </div>
                <p class="text-caption mb-0" style="color: #4338ca">
                  {{ selectedFirst.serial }} ({{ selectedFirst.positionLabel }}) is selected. Click another mounted tire to form a swap.
                </p>
                <v-btn size="small" variant="text" color="primary" class="mt-1" prepend-icon="mdi-close" @click="clearSelection">Cancel selection</v-btn>
              </div>

              <div v-if="swapPlan.length" class="mt-4 pa-3 rounded-lg" style="background: #ecfdf3; border: 1px solid #a7f3d0">
                <div class="d-flex align-center ga-2 mb-1">
                  <v-icon size="18" color="success">mdi-check-circle</v-icon>
                  <span class="text-body-2 font-weight-medium" style="color: #065f46">Ready to rotate</span>
                </div>
                <p class="text-caption mb-0" style="color: #047857">
                  {{ swapPlan.length }} swap{{ swapPlan.length === 1 ? '' : 's' }} will be applied to {{ selectedVehicle?.display_name }}.
                </p>
              </div>

              <v-divider class="my-5" />

              <div class="d-flex ga-2">
                <v-btn variant="text" prepend-icon="mdi-close" size="large" @click="$emit('cancel')">Cancel</v-btn>
                <v-spacer />
                <v-btn color="primary" size="large" prepend-icon="mdi-swap-horizontal" :loading="saving" :disabled="!canConfirm" @click="confirmRotation">
                  <span class="font-weight-bold">{{ props.editingRotation ? 'Update Rotation' : 'Confirm Rotation' }}</span>
                </v-btn>
              </div>
            </div>
          </v-col>
        </v-row>
      </v-card>
    </template>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  vehicles: any[]
  tires: any[]
  loading?: boolean
  presets?: { vehicle?: number | null }
  editingRotation?: any | null
}>()
const emit = defineEmits<{
  rotated: []
  cancel: []
}>()
const { $api, $swal } = useNuxtApp()

const rotationForm = reactive<any>({
  vehicle: props?.presets?.vehicle ?? null,
  rotation_pattern: '',
  odometer: null,
  performed_at: new Date().toISOString().slice(0, 10),
  notes: '',
})
const saving = ref(false)
const selectedFirst = ref<{ code: string; tireId: number; serial: string; positionLabel: string } | null>(null)
const hoveredPosition = ref<string | null>(null)
const viewAngle = ref<'top' | 'persp'>('persp')
const rearWheelMode = ref<'single' | 'dual'>('dual')

// Swap plan: list of {tireId, fromCode, toCode, fromLabel, toLabel, fromSerial, toSerial}
const swapPlan = ref<any[]>([])

const rotationPatterns = ['Front-to-Rear', 'Rear-to-Front', 'X-Pattern', 'Forward Cross', 'Rearward Cross', 'Side-to-Side', 'Dual-to-Single']

const selectedVehicle = computed(() => props.vehicles.find((v: any) => v.id === rotationForm.vehicle) || null)
const mountedTires = computed(() =>
  props.tires.filter((t: any) => t.vehicle === rotationForm.vehicle && (t.status === 'mounted' || t.status === 'spare')),
)

const canConfirm = computed(() => !!rotationForm.vehicle && swapPlan.value.length >= 1)
// Note: a single swap is effectively a 2-tire rotation; backend enforces >= 2 swaps, but
// we allow a single swap pair on the UI. If only 1 swap, we still send >= 2 entries by
// including the reciprocal direction for safety.
const hintType = computed(() => {
  if (swapPlan.value.length) return 'success'
  if (selectedFirst.value) return 'info'
  return 'info'
})
const hintMessage = computed(() => {
  if (swapPlan.value.length) return 'Review the swap plan on the right, then confirm the rotation.'
  if (selectedFirst.value) return `Click another mounted tire to swap with ${selectedFirst.value.serial}.`
  return 'Click any mounted tire on the diagram to start building a swap.'
})

// --- 3D stage interaction ---
const stageSvg = ref<SVGSVGElement | null>(null)
const rotation = reactive({ x: 24, y: 0, z: 0 })
const scale = ref(1)
const dragging = ref(false)
const dragStart = reactive({ x: 0, y: 0, rx: 0, ry: 0 })
const tooltip = reactive({ show: false, x: 0, y: 0, title: '', desc: '' })

const MIN_SCALE = 0.5
const MAX_SCALE = 2.2
function clampScale(v: number) { return Math.min(MAX_SCALE, Math.max(MIN_SCALE, v)) }

const stageTransform = computed(() => {
  const persp = viewAngle.value === 'persp' ? `perspective(1500px) rotateX(${rotation.x}deg) ` : ''
  return `${persp}rotateZ(${rotation.z}deg) scale(${scale.value})`
})

function resetView() { rotation.x = viewAngle.value === 'persp' ? 24 : 0; rotation.y = 0; rotation.z = 0; scale.value = 1 }
function rotateBy(dz: number) { rotation.z += dz }
function zoomBy(delta: number) { scale.value = clampScale(scale.value + delta) }
function onStagePointerDown(e: PointerEvent) {
  dragging.value = true; dragStart.x = e.clientX; dragStart.y = e.clientY
  dragStart.rx = rotation.z; dragStart.ry = rotation.x
}
function onStagePointerMove(e: PointerEvent) {
  if (!dragging.value) return
  rotation.z = dragStart.rx + (e.clientX - dragStart.x) * 0.5
  if (viewAngle.value === 'persp') rotation.x = Math.min(80, Math.max(-20, dragStart.ry - (e.clientY - dragStart.y) * 0.4))
}
function onStagePointerUp() { dragging.value = false }
function onStageWheel(e: WheelEvent) { scale.value = clampScale(scale.value + e.deltaY * -0.0015) }

watch(viewAngle, () => resetView())

let seeding = false

watch(() => rotationForm.vehicle, (val, old) => {
  if (val !== old) {
    selectedFirst.value = null
    if (!seeding) swapPlan.value = []
    const v = selectedVehicle.value
    if (v && !seeding && (rotationForm.odometer == null || rotationForm.odometer === '')) {
      rotationForm.odometer = v.current_mileage ?? null
    }
  }
})

// --- Editing: preload form + seed swap plan from an existing rotation ---
function seedFromRotation(rot: any) {
  if (!rot) return
  seeding = true
  rotationForm.vehicle = rot.vehicle
  rotationForm.rotation_pattern = rot.rotation_pattern || ''
  rotationForm.odometer = rot.odometer ?? null
  rotationForm.performed_at = rot.performed_at ? rot.performed_at.slice(0, 10) : new Date().toISOString().slice(0, 10)
  rotationForm.notes = rot.notes || ''
  // Resolve swap entries (prefer swaps_detail, fallback to swaps, fallback to JSON in notes)
  let entries: any[] = []
  if (Array.isArray(rot.swaps_detail) && rot.swaps_detail.length) entries = rot.swaps_detail
  else if (Array.isArray(rot.swaps) && rot.swaps.length) entries = rot.swaps
  else if (typeof rot.notes === 'string') {
    const m = rot.notes.match(/\[[\s\S]*\]/)
    if (m) { try { const p = JSON.parse(m[0]); if (Array.isArray(p)) entries = p } catch { /* ignore */ } }
  }
  // Pair entries: each pair of entries (from_position <-> to_position) forms one swap.
  // An entry's counterpart is the one whose from_position equals this entry's to_position.
  const used = new Set<number>()
  const plan: any[] = []
  for (let i = 0; i < entries.length; i++) {
    if (used.has(i)) continue
    const a = entries[i]
    // find counterpart j where b.from_position === a.to_position and b.to_position === a.from_position
    let j = -1
    for (let k = i + 1; k < entries.length; k++) {
      if (used.has(k)) continue
      const b = entries[k]
      if (b.from_position === a.to_position && b.to_position === a.from_position) { j = k; break }
    }
    if (j >= 0) {
      const b = entries[j]
      used.add(i); used.add(j)
      plan.push({
        tireA: a.tire, serialA: a.tire_serial || props.tires.find((t) => t.id === a.tire)?.serial_number || `#${a.tire}`,
        fromA: a.from_position, fromALabel: a.from_position,
        toA: a.to_position, toALabel: a.to_position,
        tireB: b.tire, serialB: b.tire_serial || props.tires.find((t) => t.id === b.tire)?.serial_number || `#${b.tire}`,
        fromB: b.from_position, fromBLabel: b.from_position,
        toB: b.to_position, toBLabel: b.to_position,
      })
    } else {
      // Single-sided swap (no paired counterpart) — add as a one-way move
      used.add(i)
      plan.push({
        tireA: a.tire, serialA: a.tire_serial || props.tires.find((t) => t.id === a.tire)?.serial_number || `#${a.tire}`,
        fromA: a.from_position, fromALabel: a.from_position,
        toA: a.to_position, toALabel: a.to_position,
        tireB: null, serialB: '—', fromB: a.to_position, fromBLabel: a.to_position, toB: a.from_position, toBLabel: a.from_position,
      })
    }
  }
  swapPlan.value = plan
  // Release the seeding guard after the vehicle-watcher has drained for this assignment.
  nextTick(() => { seeding = false })
}
watch(() => props.editingRotation, (rot) => { if (rot) seedFromRotation(rot) }, { immediate: true })

// ---------- Axle layout ----------
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
const transmissionCX = 320
const engineFrontY = cabFrontY + 28
const engineHeight = 28
const transmissionY = cabFrontY + 120

function deriveAxles(vehicle: any) {
  const dt = (vehicle?.drivetrain || '').toUpperCase().replace(/[Xx]/, '-')
  const vt = vehicle?.vehicle_type || 'vehicle'
  const dualMode = rearWheelMode.value === 'dual'
  if (vt === 'trailer') return [{ role: 'trailer', dual: dualMode }, { role: 'trailer', dual: dualMode }]
  if (vt === 'equipment' || vt === 'non_powered') return [{ role: 'tag', dual: false }, { role: 'tag', dual: false }]
  switch (dt) {
    case '6-2': return [{ role: 'steer', dual: false }, { role: 'drive', dual: dualMode }, { role: 'tag', dual: false }]
    case '6-4': return [{ role: 'steer', dual: false }, { role: 'drive', dual: dualMode }, { role: 'drive', dual: dualMode }]
    case '8-4': return [{ role: 'steer', dual: false }, { role: 'steer', dual: false }, { role: 'drive', dual: false }, { role: 'drive', dual: dualMode }]
    case '8-2': return [{ role: 'steer', dual: false }, { role: 'steer', dual: false }, { role: 'drive', dual: dualMode }, { role: 'tag', dual: false }]
    case '4WD': return [{ role: 'steer', dual: false }, { role: 'drive', dual: false }]
    case '4-4': return [{ role: 'steer', dual: false }, { role: 'drive', dual: dualMode }]
    case '4-2':
    case '2WD':
    default: return [{ role: 'steer', dual: false }, { role: 'drive', dual: dualMode }]
  }
}
function rolePrefix(role: string) { return { steer: 'F', drive: 'D', tag: 'G', trailer: 'T' }[role] || 'A' }
function roleLabel(role: string) { return { steer: 'Front', drive: 'Drive', tag: 'Tag', trailer: 'Trailer' }[role] || 'Axle' }
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
    const occurrence = counts[a.role] > 1 ? defs.slice(0, i).filter((x) => x.role === a.role).length : 0
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
    return { index: i, role: a.role, dual, tag, label, y, leftEdge: dual ? bodyLeft - 70 : bodyLeft - 50, rightEdge: dual ? bodyRight + 70 : bodyRight + 50, positions }
  })

  // Map mounted tires onto positions by position code
  const occByCode: Record<string, any> = {}
  mountedTires.value.forEach((t: any) => { if (t.position) occByCode[t.position] = t })

  axles.forEach((ax) => {
    ax.positions.forEach((p) => {
      const t = occByCode[p.code]
      p.occupied = !!t
      p.tireId = t ? t.id : null
      p.tireSerial = t ? t.serial_number : null
      p.shortLabel = p.label.replace(ax.label + ' ', '')
    })
  })

  return { axles, spare: null }
})

const allPositions = computed(() => {
  const list: any[] = []
  layout.value.axles.forEach((a: any) => a.positions.forEach((p: any) => list.push(p)))
  return list
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

function isPowered(role: string) { return role === 'drive' || role === 'steer' }

const frameHoles = computed(() => {
  const holes: any[] = []
  for (let y = cabFrontY + 40; y < bedRearY - 20; y += 22) holes.push({ y })
  return holes
})

// --- Tire metadata helpers ---
function tireBrand(id: number | null) { return id ? props.tires.find((t: any) => t.id === id)?.brand : null }
function tireSize(id: number | null) { return id ? props.tires.find((t: any) => t.id === id)?.size : null }

// --- Selection + swap logic ---
function isSelected(code: string) { return !!selectedFirst.value && selectedFirst.value.code === code }

function isSwapTarget(code: string) {
  // A position becomes a "target" once a first pick exists and it's a different occupied position
  if (!selectedFirst.value) return false
  if (code === selectedFirst.value.code) return false
  const pos = allPositions.value.find((p: any) => p.code === code)
  return !!pos?.occupied
}

function onWheelClick(pos: any) {
  if (!pos.occupied) return
  if (!selectedFirst.value) {
    selectedFirst.value = { code: pos.code, tireId: pos.tireId, serial: pos.tireSerial, positionLabel: pos.shortLabel }
    return
  }
  if (selectedFirst.value.code === pos.code) {
    // toggle off
    selectedFirst.value = null
    return
  }
  // Second pick -> form a swap
  addSwap(selectedFirst.value, { code: pos.code, tireId: pos.tireId, serial: pos.tireSerial, positionLabel: pos.shortLabel })
  selectedFirst.value = null
}

function addSwap(a: { code: string; tireId: number; serial: string; positionLabel: string }, b: { code: string; tireId: number; serial: string; positionLabel: string }) {
  const aPos = allPositions.value.find((p: any) => p.code === a.code)
  const bPos = allPositions.value.find((p: any) => p.code === b.code)
  swapPlan.value.push({
    tireA: a.tireId, serialA: a.serial, fromA: a.code, fromALabel: aPos?.shortLabel || a.code,
    toA: b.code, toALabel: bPos?.shortLabel || b.code,
    tireB: b.tireId, serialB: b.serial, fromB: b.code, fromBLabel: bPos?.shortLabel || b.code,
    toB: a.code, toBLabel: aPos?.shortLabel || a.code,
  })
}

function removeSwap(i: number) { swapPlan.value.splice(i, 1) }
function clearSwapPlan() { swapPlan.value = []; selectedFirst.value = null }
function clearSelection() { selectedFirst.value = null }

// --- Swap connector arcs on the SVG ---
const swapArcs = computed(() => {
  return swapPlan.value.map((sw: any) => {
    const a = allPositions.value.find((p: any) => p.code === sw.fromA)
    const b = allPositions.value.find((p: any) => p.code === sw.fromB)
    if (!a || !b) return { path: '', arrow: '', opacity: 0 }
    const x1 = a.x, y1 = a.y - a.r - 6
    const x2 = b.x, y2 = b.y - b.r - 6
    const mx = (x1 + x2) / 2
    const my = Math.min(y1, y2) - Math.max(40, Math.abs(x2 - x1) * 0.35)
    const path = `M ${x1} ${y1} Q ${mx} ${my} ${x2} ${y2}`
    // arrowhead at b
    const ang = Math.atan2(y2 - my, x2 - mx)
    const ax = x2, ay = y2
    const ah = 7
    const arrow = `${ax} ${ay} ${ax - Math.cos(ang - 0.4) * ah} ${ay - Math.sin(ang - 0.4) * ah} ${ax - Math.cos(ang + 0.4) * ah} ${ay - Math.sin(ang + 0.4) * ah}`
    return { path, arrow, opacity: 0.85 }
  })
})

// --- SVG helpers (tread/spokes/lugs) ---
function treadArcs(r: number) {
  const arr: any[] = []
  const count = 18
  for (let i = 0; i < count; i++) {
    const ang = (i / count) * Math.PI * 2
    arr.push({ i, x1: Math.cos(ang) * r * 0.83, y1: Math.sin(ang) * r * 0.83, x2: Math.cos(ang) * r * 0.99, y2: Math.sin(ang) * r * 0.99 })
  }
  return arr
}
function treadBevelPath(r: number) {
  const a0 = -2.4, a1 = -0.7
  const R = r + 0.6
  return `M ${Math.cos(a0) * R} ${Math.sin(a0) * R} A ${R} ${R} 0 0 1 ${Math.cos(a1) * R} ${Math.sin(a1) * R} L ${Math.cos(a1) * r * 0.97} ${Math.sin(a1) * r * 0.97} A ${r * 0.97} ${r * 0.97} 0 0 0 ${Math.cos(a0) * r * 0.97} ${Math.sin(a0) * r * 0.97} Z`
}
function spokes(r: number, n = 6) {
  const arr: any[] = []
  for (let i = 0; i < n; i++) {
    const ang = (i / n) * Math.PI * 2 + 0.4
    arr.push({ i, x1: Math.cos(ang) * r * 0.18, y1: Math.sin(ang) * r * 0.18, x2: Math.cos(ang) * r * 0.6, y2: Math.sin(ang) * r * 0.6 })
  }
  return arr
}
function lugNuts(r: number, n = 6) {
  const arr: any[] = []
  for (let i = 0; i < n; i++) {
    const ang = (i / n) * Math.PI * 2 + Math.PI / n
    arr.push({ i, x: Math.cos(ang) * r * 0.5, y: Math.sin(ang) * r * 0.5 })
  }
  return arr
}

// --- Submit ---
async function confirmRotation() {
  if (!rotationForm.vehicle) {
    $swal.fire({ icon: 'error', title: 'Vehicle required', text: 'Please select a vehicle.', timer: 2500, toast: true, position: 'top-end' })
    return
  }
  if (!swapPlan.value.length) {
    $swal.fire({ icon: 'error', title: 'No swaps', text: 'Build at least one swap before confirming.', timer: 2800, toast: true, position: 'top-end' })
    return
  }
  // Build per-tire swap entries (two entries per pair so each tire moves to the other's position)
  const swaps: any[] = []
  swapPlan.value.forEach((sw) => {
    swaps.push({ tire: sw.tireA, from_position: sw.fromA, to_position: sw.toA })
    swaps.push({ tire: sw.tireB, from_position: sw.fromB, to_position: sw.toB })
  })

  saving.value = true
  try {
    const body: any = {
      vehicle: rotationForm.vehicle,
      performed_at: rotationForm.performed_at || new Date().toISOString().slice(0, 10),
      swaps,
    }
    if (rotationForm.rotation_pattern) body.rotation_pattern = rotationForm.rotation_pattern
    if (rotationForm.odometer != null && rotationForm.odometer !== '') body.odometer = rotationForm.odometer
    if (rotationForm.notes) body.notes = rotationForm.notes
    if (props.editingRotation) {
      await $api(`/tires/rotations/${props.editingRotation.id}/`, { method: 'PATCH', body })
      emit('rotated')
      $swal.fire({ icon: 'success', title: 'Rotation updated', timer: 1600, toast: true, position: 'top-end' })
    } else {
      await $api('/tires/rotate/', { method: 'POST', body })
      emit('rotated')
      $swal.fire({ icon: 'success', title: 'Rotation recorded', timer: 1600, toast: true, position: 'top-end' })
    }
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: props.editingRotation ? 'Update failed' : 'Rotation failed', text: e?.data?.detail || e?.message || 'Could not save rotation' })
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
.axle-stage:active { cursor: grabbing; }
.axle-floor {
  position: absolute; inset: 0;
  background-image: radial-gradient(circle at 50% 90%, rgba(99, 102, 241, 0.05), transparent 60%);
  pointer-events: none;
}
.axle-empty {
  position: absolute; inset: 0;
  display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center;
}
.axle-canvas-wrap {
  transition: transform 0.6s cubic-bezier(0.22, 1, 0.36, 1);
  transform-origin: 50% 60%;
}
.axle-svg { width: 100%; height: auto; display: block; }
.wheel-g { cursor: pointer; transition: transform 0.25s ease; transform-box: fill-box; }
.wheel-g.selectable:hover { transform: scale(1.06); }
.wheel-g.empty { cursor: not-allowed; }
.wheel-g.selected { transform: scale(1.08); }
.wheel-g.swapTarget:hover { transform: scale(1.05); }
.sel-ring { animation: pulse 1.6s ease-in-out infinite; }
@keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.45; } }
.swap-arc { animation: dash 1s linear infinite; }
@keyframes dash { to { stroke-dashoffset: -24; } }
.legend-dot { width: 14px; height: 14px; border-radius: 50%; display: inline-block; }
.legend-dash { background: transparent; border: 2px dashed #94a3b8; }
.axle-controls {
  position: absolute; top: 12px; right: 12px; z-index: 4;
  display: flex; align-items: center; gap: 2px;
  background: rgba(255, 255, 255, 0.85);
  border: 1px solid #e2e8f0; border-radius: 10px; padding: 4px 6px;
  box-shadow: 0 4px 10px rgba(15, 23, 42, 0.06);
}
.axle-controls .v-btn { color: #475569; }
.dt-tooltip {
  position: absolute; z-index: 6;
  background: rgba(15, 23, 42, 0.95); color: #f8fafc;
  border-radius: 8px; padding: 8px 12px;
  box-shadow: 0 8px 20px rgba(15, 23, 42, 0.25);
  pointer-events: none; max-width: 240px;
}
.dt-tooltip-title { font-size: 12px; font-weight: 700; }
.dt-tooltip-desc { font-size: 11px; opacity: 0.85; }
</style>
