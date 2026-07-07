<template>
  <div class="bg">
    <canvas ref="el" width="300" height="300" @touchmove="mv"></canvas>
    <div class="tx">X:{{ x.toFixed(1) }} Y:{{ y.toFixed(1) }} Z:{{ z.toFixed(1) }}</div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'

const el = ref(null), x = ref(0), y = ref(0), z = ref(0)
let c, g, h = [], t = 0, r = 0.8, p = 0.4 // Grid angles initialized to an offset tilt

const add = (X, Y, Z) => {
  h.push([X * 10, Y * 10, Z * 10])
  if (h.length > 40) h.shift()
}

// 3D Matrix Projection Transform
const pr = (X, Y, Z, cx, sx, cy, sy) => {
  let x1 = X * cx - Z * sx
  let z1 = X * sx + Z * cx
  let y2 = Y * cy - z1 * sy
  let z2 = Y * sy + z1 * cy
  let f = 200 / (210 + z2) // Shifted back slightly (+210) to keep bounds inside canvas frame
  return [150 + x1 * f, 150 + y2 * f]
}

const dr = () => {
  g.clearRect(0, 0, 300, 300)
  let cx = Math.cos(r), sx = Math.sin(r), cy = Math.cos(p), sy = Math.sin(p)

  // 1. Draw 3D Bounding Cage Grid (Size: -120 to +120 representing sensor bounds)
  g.strokeStyle = '#27272a'
  g.lineWidth = 1
  let b = [-120, 120]

  for (let X of b) {
    for (let Y of b) {
      // Draw Z-axis frame rails
      g.beginPath()
      let [x1, y1] = pr(X, Y, b[0], cx, sx, cy, sy)
      let [x2, y2] = pr(X, Y, b[1], cx, sx, cy, sy)
      g.moveTo(x1, y1); g.lineTo(x2, y2); g.stroke()
      
      // Draw Y-axis frame rails
      g.beginPath()
      let [x3, y3] = pr(X, b[0], Y, cx, sx, cy, sy)
      let [x4, y4] = pr(X, b[1], Y, cx, sx, cy, sy)
      g.moveTo(x3, y3); g.lineTo(x4, y4); g.stroke()

      // Draw X-axis frame rails
      g.beginPath()
      let [x5, y5] = pr(b[0], X, Y, cx, sx, cy, sy)
      let [x6, y6] = pr(b[1], X, Y, cx, sx, cy, sy)
      g.moveTo(x5, y5); g.lineTo(x6, y6); g.stroke()
    }
  }

  // 2. Draw Data Trails
  h.forEach(([X, Y, Z], i) => {
    let [sx_c, sy_c] = pr(X, Y, Z, cx, sx, cy, sy)
    g.fillStyle = i === h.length - 1 ? '#2ed573' : `rgba(255, 255, 255, ${i / 50})`
    g.beginPath()
    g.arc(sx_c, sy_c, i === h.length - 1 ? 5 : 2, 0, 7)
    g.fill()
  })
}

const mv = (e) => {
  let t = e.touches[0]
  r = (t.clientX / 300) * 6
  p = (t.clientY / 300) * 6
}

onMounted(() => {
  c = el.value; g = c.getContext('2d')
  t = setInterval(() => {
    x.value = 0.8 + Math.sin(Date.now()/500)*6
    y.value = 9.5 + Math.cos(Date.now()/500)*2
    z.value = -1.9 + Math.sin(Date.now()/300)*5
    
    add(x.value, y.value, z.value)
    dr()
  }, 40)
})
onUnmounted(() => clearInterval(t))
</script>

<style scoped>
.bg { background: #09090b; height: 100vh; display: flex; flex-direction: column; align-items: center; justify-content: center; }
canvas { background: #141416; border: 1px solid #27272a; border-radius: 12px; max-width: 90vw; }
.tx { color: #71717a; font-family: monospace; font-size: 12px; margin-top: 12px; letter-spacing: 1px; }
</style>