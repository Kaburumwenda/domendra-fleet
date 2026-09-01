<template>
  <div class="sig-pad-wrap">
    <div class="sig-toolbar">
      <span class="sig-label">{{ label }}</span>
      <div class="d-flex ga-2">
        <v-btn size="x-small" variant="text" color="warning" prepend-icon="mdi-eraser" :disabled="!hasInk" @click="clear">Clear</v-btn>
        <v-btn size="x-small" variant="text" color="error" prepend-icon="mdi-undo" :disabled="!strokes.length" @click="undo">Undo</v-btn>
      </div>
    </div>
    <canvas
      ref="canvasEl"
      class="sig-canvas"
      :class="{ 'sig-empty': !hasInk }"
      :style="{ '--signatory': signatoryName }"
      @pointerdown="onDown"
      @pointermove="onMove"
      @pointerup="onUp"
      @pointerleave="onUp"
    />
    <div v-if="!hasInk" class="sig-placeholder">
      <v-icon size="22" class="me-2">mdi-draw</v-icon>
      <span>Sign here with your finger or mouse</span>
    </div>
    <div class="sig-foot">
      <v-text-field
        v-model="signatoryName"
        density="compact"
        variant="outlined"
        hide-details
        placeholder="Print full name"
        class="sig-name-input"
        prepend-inner-icon="mdi-account-outline"
      />
      <span class="sig-date">{{ today }}</span>
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  label?: string
  modelValue?: string
  name?: string
}>()
const emit = defineEmits<{ 'update:modelValue': [val: string]; 'update:name': [val: string] }>()

const canvasEl = ref<HTMLCanvasElement | null>(null)
const strokes = ref<Array<Array<{ x: number; y: number; pressure: number }>>>([])
const drawing = ref(false)
const currentStroke: Array<{ x: number; y: number; pressure: number }> = []
const signatoryName = ref(props.name || '')
const today = new Date().toISOString().slice(0, 10)
const penColor = '#2563eb'

const hasInk = computed(() => strokes.value.length > 0)

watch(() => props.name, (v) => { if (v && v !== signatoryName.value) signatoryName.value = v })

watch(signatoryName, (v) => emit('update:name', v))

let ctx: CanvasRenderingContext2D | null = null

let resizeObserver: ResizeObserver | null = null

onMounted(() => {
  ctx = canvasEl.value?.getContext('2d') || null
  nextTick(() => resizeCanvas())
  window.addEventListener('resize', resizeCanvas)
  if (canvasEl.value && 'ResizeObserver' in window) {
    resizeObserver = new ResizeObserver(() => resizeCanvas())
    resizeObserver.observe(canvasEl.value)
  }
})

onUnmounted(() => {
  window.removeEventListener('resize', resizeCanvas)
  resizeObserver?.disconnect()
})

function resizeCanvas() {
  const canvas = canvasEl.value
  if (!canvas) return
  const rect = canvas.getBoundingClientRect()
  const dpr = window.devicePixelRatio || 1
  canvas.width = rect.width * dpr
  canvas.height = rect.height * dpr
  ctx = canvas.getContext('2d')
  if (!ctx) return
  ctx.scale(dpr, dpr)
  ctx.lineCap = 'round'
  ctx.lineJoin = 'round'
  redraw()
}

function getPos(e: PointerEvent) {
  const rect = canvasEl.value?.getBoundingClientRect()
  if (!rect) return { x: 0, y: 0 }
  return { x: e.clientX - rect.left, y: e.clientY - rect.top }
}

function onDown(e: PointerEvent) {
  if (!ctx) return
  drawing.value = true
  currentStroke.length = 0
  const pos = getPos(e)
  currentStroke.push({ ...pos, pressure: e.pressure || 0.5 })
  ctx.beginPath()
  ctx.moveTo(pos.x, pos.y)
}

function onMove(e: PointerEvent) {
  if (!drawing.value || !ctx) return
  const pos = getPos(e)
  currentStroke.push({ ...pos, pressure: e.pressure || 0.5 })
  ctx.lineWidth = 2.4
  ctx.strokeStyle = penColor
  ctx.lineTo(pos.x, pos.y)
  ctx.stroke()
}

function onUp() {
  if (!drawing.value) return
  drawing.value = false
  if (currentStroke.length) strokes.value.push([...currentStroke])
  currentStroke.length = 0
  emitSvg()
}

function clear() {
  strokes.value = []
  redraw()
  emitSvg()
}

function undo() {
  strokes.value.pop()
  redraw()
  emitSvg()
}

function redraw() {
  const canvas = canvasEl.value
  if (!canvas || !ctx) return
  ctx.clearRect(0, 0, canvas.width, canvas.height)
  for (const stroke of strokes.value) {
    ctx.beginPath()
    stroke.forEach((pt, i) => {
      if (i === 0) ctx.moveTo(pt.x, pt.y)
      else ctx.lineTo(pt.x, pt.y)
    })
    ctx.lineWidth = 2.4
    ctx.strokeStyle = penColor
    ctx.lineCap = 'round'
    ctx.lineJoin = 'round'
    ctx.stroke()
  }
}

function emitSvg() {
  const canvas = canvasEl.value
  if (!canvas) return
  const w = canvas.getBoundingClientRect().width
  const h = canvas.getBoundingClientRect().height
  let svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">`
  svg += `<rect x="0" y="0" width="${w}" height="${h}" fill="#ffffff"/>`
  // signature line
  svg += `<line x1="12" y1="${h - 22}" x2="${w - 12}" y2="${h - 22}" stroke="#e2e8f0" stroke-width="1"/>`
  svg += `<text x="${w - 12}" y="${h - 6}" text-anchor="end" font-size="10" fill="#94a3b8" font-family="sans-serif">Signed by: ${signatoryName.value || '—'}</text>`
  svg += `<text x="14" y="${h - 6}" font-size="10" fill="#94a3b8" font-family="sans-serif">Date: ${today}</text>`
  for (const stroke of strokes.value) {
    if (!stroke.length) continue
    let d = `M ${stroke[0].x} ${stroke[0].y}`
    for (let i = 1; i < stroke.length; i++) d += ` L ${stroke[i].x} ${stroke[i].y}`
    svg += `<path d="${d}" stroke="${penColor}" stroke-width="2.4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`
  }
  svg += `</svg>`
  emit('update:modelValue', svg)
}

watch(() => props.modelValue, (v) => {
  // intentional: parent feeds back; we draw from strokes only
  if (!v) clear()
})
</script>

<style scoped>
.sig-pad-wrap {
  border: 1px solid #cbd5e1;
  border-radius: 12px;
  background: linear-gradient(180deg, #ffffff, #f8fafc);
  padding: 12px;
  user-select: none;
}
.sig-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
}
.sig-label {
  font-size: 12px;
  font-weight: 700;
  color: #475569;
  letter-spacing: 0.05em;
  text-transform: uppercase;
}
.sig-canvas {
  width: 100%;
  height: 200px;
  background: #ffffff;
  border: 1.5px dashed #cbd5e1;
  border-radius: 10px;
  display: block;
  touch-action: none;
  cursor: crosshair;
}
.sig-empty {
  background: linear-gradient(180deg, #ffffff, #f8fafc);
}
.sig-placeholder {
  position: absolute;
  left: 50%;
  top: calc(50% + 6px);
  transform: translate(-50%, -50%);
  display: flex;
  align-items: center;
  font-size: 12px;
  color: #94a3b8;
  pointer-events: none;
}
.sig-foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-top: 8px;
}
.sig-name-input {
  max-width: 260px;
  flex: 1;
}
.sig-date {
  font-size: 12px;
  color: #94a3b8;
  font-weight: 600;
}
</style>
