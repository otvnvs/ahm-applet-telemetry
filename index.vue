<template>
  <div class="app-container">
    <header class="header">
      <div class="status-badge" :class="{ connected: isConnected }">
        <span class="dot"></span> {{ isConnected ? 'LIVE' : 'DISCONNECTED' }}
      </div>
      <p class="session-id">ID: {{ sessionId || 'Connecting...' }}</p>
    </header>

    <div class="graph-card">
      <svg viewBox="0 0 300 120" class="sparkline">
        <line x1="0" y1="20" x2="300" y2="20" stroke="#222" />
        <line x1="0" y1="60" x2="300" y2="60" stroke="#333" stroke-dasharray="4" />
        <line x1="0" y1="100" x2="300" y2="100" stroke="#222" />
        
        <path :d="getXPath" stroke="#ff4757" stroke-width="2" fill="none" stroke-linecap="round"/>
        <path :d="getYPath" stroke="#2ed573" stroke-width="2" fill="none" stroke-linecap="round"/>
        <path :d="getZPath" stroke="#1e90ff" stroke-width="2" fill="none" stroke-linecap="round"/>
      </svg>
    </div>

    <div class="metrics-grid">
      <div class="metric-box border-x">
        <span class="label">X-AXIS</span>
        <span class="value color-x">{{ currentData.x.toFixed(2) }}</span>
      </div>
      <div class="metric-box border-y">
        <span class="label">Y-AXIS</span>
        <span class="value color-y">{{ currentData.y.toFixed(2) }}</span>
      </div>
      <div class="metric-box border-z">
        <span class="label">Z-AXIS</span>
        <span class="value color-z">{{ currentData.z.toFixed(2) }}</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'

const isConnected = ref(false)
const sessionId = ref('')
const history = ref([])
const maxHistory = 20

const currentData = ref({ x: 0, y: 0, z: 0 })

// Map continuous acceleration values (-12 to +12 m/s²) to SVG space (height: 120px)
const mapToSvgY = (val) => {
  const minSrc = -12, maxSrc = 12
  const minDst = 110, maxDst = 10
  return minDst + ((val - minSrc) * (maxDst - minDst)) / (maxSrc - minSrc)
}

// Generate SVG Path Strings dynamically
const generatePath = (axis) => {
  if (history.value.length < 2) return ''
  return history.value.map((point, index) => {
    const xCoord = (index / (maxHistory - 1)) * 300
    const yCoord = mapToSvgY(point[axis])
    return `${index === 0 ? 'M' : 'L'} ${xCoord} ${yCoord}`
  }).join(' ')
}

const getXPath = computed(() => generatePath('x'))
const getYPath = computed(() => generatePath('y'))
const getZPath = computed(() => generatePath('z'))

// Mock WebSocket Telemetry Stream Loop
let mockInterval = null
onMounted(() => {
  isConnected.value = true
  sessionId.value = "po4weal" + Math.random().toString().slice(2, 10)

  mockInterval = setInterval(() => {
    // Generate slight variants around your logged portrait profile baseline
    const sample = {
      x: 0.7 + (Math.random() * 0.3 - 0.15),
      y: 9.6 + (Math.random() * 0.4 - 0.2),
      z: -1.9 + (Math.random() * 0.3 - 0.15)
    }
    
    currentData.value = sample
    history.value.push(sample)
    if (history.value.length > maxHistory) history.value.shift()
  }, 150) // High-frequency ~7Hz ticks
})

onUnmounted(() => {
  if (mockInterval) clearInterval(mockInterval)
})
</script>

<style scoped>
.app-container {
  background: #09090b;
  color: #f4f4f5;
  font-family: system-ui, sans-serif;
  min-height: 100vh;
  padding: 16px;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.status-badge {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.05em;
  color: #71717a;
  display: flex;
  align-items: center;
  gap: 6px;
}

.status-badge.connected { color: #2ed573; }
.dot { width: 6px; height: 6px; background: currentColor; border-radius: 50%; }
.session-id { font-size: 11px; color: #71717a; margin: 0; }

.graph-card {
  background: #141416;
  border: 1px solid #27272a;
  border-radius: 12px;
  padding: 12px;
  display: flex;
  align-items: center;
}

.sparkline {
  width: 100%;
  height: auto;
  overflow: visible;
}

.metrics-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 10px;
}

.metric-box {
  background: #141416;
  border-radius: 8px;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.label { font-size: 10px; color: #71717a; font-weight: 600; letter-spacing: 0.05em; }
.value { font-size: 18px; font-weight: 700; font-family: monospace; }

.border-x { border-left: 3px solid #ff4757; }
.border-y { border-left: 3px solid #2ed573; }
.border-z { border-left: 3px solid #1e90ff; }

.color-x { color: #ff4757; }
.color-y { color: #2ed573; }
.color-z { color: #1e90ff; }
</style>