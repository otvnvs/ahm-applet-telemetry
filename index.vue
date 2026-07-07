<template>
  <div class="bg" @click="A" @touchstart="A">
    <canvas ref="el" width="300" height="300" @touchmove="mv" @mousemove="mm" @mousedown="md" @mouseup="mu" @mouseleave="mu"></canvas>
    <div class="tx">X:{{ x.toFixed(1) }} Y:{{ y.toFixed(1) }} Z:{{ z.toFixed(1) }}</div>
    <div :class="['st', { cn }]">{{ cn ? '● Live' : '○ Offline' }}</div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
const el = ref(null), x = ref(0), y = ref(0), z = ref(0), cn = ref(false)
let c, g, h = [], r = 0.8, p = 0.4, ws, dr = false, raf, tx = 0, ty = 0, tz = 0, f = 0.15, ac, os, pn, wg, dg
const url = 'ws://192.168.1.100:8080/api/ws/telemetry/sensors'

const add = (X, Y, Z) => { h.push([X * 10, Y * 10, Z * 10]); if (h.length > 40) h.shift() }
const pr = (X, Y, Z, cx, sx, cy, sy) => {
  let x1 = X * cx - Z * sx, z1 = X * sx + Z * cx, y2 = Y * cy - z1 * sy, z2 = Y * sy + z1 * cy, s = 200 / (210 + z2)
  return [150 + x1 * s, 150 + y2 * s]
}
const render = () => {
  if (!g) return; g.clearRect(0, 0, 300, 300)
  let cx = Math.cos(r), sx = Math.sin(r), cy = Math.cos(p), sy = Math.sin(p), b = [-120, 120]
  g.strokeStyle = '#27272a'; g.lineWidth = 1
  for (let X of b) for (let Y of b) {
    let [x1, y1] = pr(X, Y, b[0], cx, sx, cy, sy), [x2, y2] = pr(X, Y, b[1], cx, sx, cy, sy)
    g.beginPath(); g.moveTo(x1, y1); g.lineTo(x2, y2); g.stroke()
    let [x3, y3] = pr(X, b[0], Y, cx, sx, cy, sy), [x4, y4] = pr(X, b[1], Y, cx, sx, cy, sy)
    g.beginPath(); g.moveTo(x3, y3); g.lineTo(x4, y4); g.stroke()
    let [x5, y5] = pr(b[0], X, Y, cx, sx, cy, sy), [x6, y6] = pr(b[1], X, Y, cx, sx, cy, sy)
    g.beginPath(); g.moveTo(x5, y5); g.lineTo(x6, y6); g.stroke()
  }
  h.forEach(([X, Y, Z], i) => {
    let [sx_c, sy_c] = pr(X, Y, Z, cx, sx, cy, sy)
    g.fillStyle = i === h.length - 1 ? '#2ed573' : `rgba(255, 255, 255, ${i / 50})`
    g.beginPath(); g.arc(sx_c, sy_c, i === h.length - 1 ? 5 : 2, 0, 7); g.fill()
  })
}
const A = () => {
  if (ac) return ac.state === 'suspended' && ac.resume()
  ac = new (window.AudioContext || window.webkitAudioContext)()
  os = ac.createOscillator(); os.type = 'triangle'; os.frequency.setValueAtTime(220, ac.currentTime)
  let gn = ac.createGain(); gn.gain.setValueAtTime(0.15, ac.currentTime)
  pn = ac.createPanner(); pn.panningModel = 'HRTF'
  let rv = ac.createConvolver(), l = ac.sampleRate * 2.5, bf = ac.createBuffer(2, l, ac.sampleRate)
  for (let ch = 0; ch < 2; ch++) {
    let d = bf.getChannelData(ch)
    for (let i = 0; i < l; i++) d[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / l, 2)
  }
  rv.buffer = bf; dg = ac.createGain(); wg = ac.createGain()
  dg.gain.setValueAtTime(0.7, ac.currentTime); wg.gain.setValueAtTime(0.4, ac.currentTime)
  os.connect(gn); gn.connect(pn); pn.connect(dg); dg.connect(ac.destination)
  pn.connect(rv); rv.connect(wg); wg.connect(ac.destination); os.start()
}
const loop = () => {
  x.value += (tx - x.value) * f; y.value += (ty - y.value) * f; z.value += (tz - z.value) * f
  add(x.value, y.value, z.value); render()
  if (ac && ac.state !== 'suspended' && pn) {
    let t = ac.currentTime, w = Math.min(0.8, Math.abs(z.value) / 30)
    os.frequency.setTargetAtTime(Math.max(80, Math.min(880, 220 + y.value * 25)), t, 0.05)
    wg.gain.setTargetAtTime(w, t, 0.1); dg.gain.setTargetAtTime(1 - w, t, 0.1)
    pn.positionX.setTargetAtTime(x.value / 10, t, 0.05)
    pn.positionY.setTargetAtTime(y.value / 10, t, 0.05)
    pn.positionZ.setTargetAtTime(z.value / 10, t, 0.05)
  }
  raf = requestAnimationFrame(loop)
}
const mv = (e) => { let t = e.touches[0]; r = (t.clientX / 300) * 6; p = (t.clientY / 300) * 6 }
const md = () => dr = true
const mu = () => dr = false
const mm = (e) => { if (!dr) return; let k = el.value.getBoundingClientRect(); r = ((e.clientX - k.left) / 300) * 6; p = ((e.clientY - k.top) / 300) * 6 }
const conn = () => {
  ws = new WebSocket(url); ws.onopen = () => cn.value = true
  ws.onmessage = (e) => {
    try {
      let d = JSON.parse(e.data)
      if (d.status === 'telemetry_update' && d.data) { tx = d.data.x ?? 0; ty = d.data.y ?? 0; tz = d.data.z ?? 0 }
    } catch {}
  }
  ws.onclose = () => { cn.value = false; setTimeout(conn, 3000) }; ws.onerror = () => ws.close()
}
onMounted(() => { c = el.value; g = c.getContext('2d'); conn(); loop() })
onUnmounted(() => { 
  if (ws) ws.close()
  cancelAnimationFrame(raf)
  if (os) { try { os.stop() } catch {} }
  if (ac) ac.close()
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