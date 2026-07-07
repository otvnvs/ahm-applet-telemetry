<template>
  <div class="bg">
    <canvas ref="el" width="300" height="300" @touchmove="mv" @mousemove="mm" @mousedown="md" @mouseup="mu" @mouseleave="mu"></canvas>
    <div class="tx">X:{{ x.toFixed(1) }} Y:{{ y.toFixed(1) }} Z:{{ z.toFixed(1) }}</div>
    <div :class="['st', { cn: isCn }]">{{ isCn ? '● Live' : '○ Offline' }}</div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'

const el = ref(null), x = ref(0), y = ref(0), z = ref(0), isCn = ref(false)
let c, g, h = [], r = 0.8, p = 0.4, ws = null, isDr = false, raf = null
const url = 'ws://192.168.1.100:8080/api/ws/telemetry/sensors' 

// Target variables hold raw values; x, y, z track the smooth animation frames
let tx = 0, ty = 0, tz = 0
const fct = 0.15 // Smoothing factor (0.01 = slow/smooth, 1.0 = instant/jittery)

const add = (X, Y, Z) => {
  h.push([X * 10, Y * 10, Z * 10])
  if (h.length > 40) h.shift()
}

const pr = (X, Y, Z, cx, sx, cy, sy) => {
  let x1 = X * cx - Z * sx, z1 = X * sx + Z * cx
  let y2 = Y * cy - z1 * sy, z2 = Y * sy + z1 * cy
  return [150 + x1 * (200 / (210 + z2)), 150 + y2 * (200 / (210 + z2))]
}

const dr = () => {
  if (!g) return
  g.clearRect(0, 0, 300, 300)
  let cx = Math.cos(r), sx = Math.sin(r), cy = Math.cos(p), sy = Math.sin(p), b = [-120, 120]
  g.strokeStyle = '#27272a'; g.lineWidth = 1

  for (let X of b) {
    for (let Y of b) {
      let [x1, y1] = pr(X, Y, b[0], cx, sx, cy, sy), [x2, y2] = pr(X, Y, b[1], cx, sx, cy, sy)
      g.beginPath(); g.moveTo(x1, y1); g.lineTo(x2, y2); g.stroke()
      let [x3, y3] = pr(X, b[0], Y, cx, sx, cy, sy), [x4, y4] = pr(X, b[1], Y, cx, sx, cy, sy)
      g.beginPath(); g.moveTo(x3, y3); g.lineTo(x4, y4); g.stroke()
      let [x5, y5] = pr(b[0], X, Y, cx, sx, cy, sy), [x6, y6] = pr(b[1], X, Y, cx, sx, cy, sy)
      g.beginPath(); g.moveTo(x5, y5); g.lineTo(x6, y6); g.stroke()
    }
  }
  h.forEach(([X, Y, Z], i) => {
    let [sx_c, sy_c] = pr(X, Y, Z, cx, sx, cy, sy)
    g.fillStyle = i === h.length - 1 ? '#2ed573' : `rgba(255, 255, 255, ${i / 50})`
    g.beginPath(); g.arc(sx_c, sy_c, i === h.length - 1 ? 5 : 2, 0, 7); g.fill()
  })
}

// Constant rendering loop aligned to screen refresh rate (typically 60Hz-120Hz)
const loop = () => {
  // Smoothly close the gap between current state and incoming target data
  x.value += (tx - x.value) * fct
  y.value += (ty - y.value) * fct
  z.value += (tz - z.value) * fct

  add(x.value, y.value, z.value)
  dr()
  raf = requestAnimationFrame(loop)
}

const mv = (e) => { let t = e.touches[0]; r = (t.clientX / 300) * 6; p = (t.clientY / 300) * 6 }
const md = () => { isDr = true }
const mu = () => { isDr = false }
const mm = (e) => {
  if (!isDr) return
  const rect = el.value.getBoundingClientRect()
  r = ((e.clientX - rect.left) / 300) * 6; p = ((e.clientY - rect.top) / 300) * 6
}

const conn = () => {
  ws = new WebSocket(url)
  ws.onopen = () => isCn.value = true
  ws.onmessage = (e) => {
    try {
      const d = JSON.parse(e.data)
      if (d.status === 'telemetry_update' && d.data) {
        // Cache the raw target values instead of direct rendering
        tx = d.data.x ?? 0; ty = d.data.y ?? 0; tz = d.data.z ?? 0
      }
    } catch (err) {}
  }
  ws.onclose = () => { isCn.value = false; setTimeout(conn, 3000) }
  ws.onerror = () => ws.close()
}

onMounted(() => { 
  c = el.value; g = c.getContext('2d')
  conn()
  loop() // Start the visual smoother
})
onUnmounted(() => { 
  if (ws) ws.close()
  cancelAnimationFrame(raf)
})
</script>

<style scoped>
.bg { background: #09090b; height: 100vh; display: flex; flex-direction: column; align-items: center; justify-content: center; }
canvas { background: #141416; border: 1px solid #27272a; border-radius: 12px; max-width: 90vw; cursor: grab; }
canvas:active { cursor: grabbing; }
.tx { color: #71717a; font-family: monospace; font-size: 14px; margin-top: 12px; letter-spacing: 1px; }
.st { font-family: monospace; font-size: 11px; margin-top: 6px; color: #ef4444; }
.st.cn { color: #2ed573; }
</style>