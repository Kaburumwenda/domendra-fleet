import { useGoogleMapsLoader } from './useGoogleMaps'

export type MarkerKind = 'pickup' | 'dropoff' | 'stop' | 'driver' | 'depot'

export interface DispatchMarker {
  id: string
  lat: number
  lng: number
  kind: MarkerKind
  label?: string
  title?: string
  color?: string
  sequence?: number
  meta?: Record<string, any>
}

const ICONS: Record<MarkerKind, string> = {
  pickup: 'mdi-package-up',
  dropoff: 'mdi-package-down',
  stop: 'mdi-circle-medium',
  driver: 'mdi-truck-fast',
  depot: 'mdi-warehouse',
}

const COLORS: Record<MarkerKind, string> = {
  pickup: '#10b981',
  dropoff: '#ef4444',
  stop: '#3b82f6',
  driver: '#8b5cf6',
  depot: '#f59e0b',
}

export function useDispatchMap() {
  const config = useRuntimeConfig()
  const apiKey = config.public.googleMapsApiKey as string
  const loader = useGoogleMapsLoader(apiKey)
  const mapInstance = shallowRef<any>(null)
  const markers = shallowRef<google.maps.Marker[]>([])
  const polyline = shallowRef<any>(null)
  const bounds = shallowRef<any>(null)

  async function ensure() {
    return await loader.load()
  }

  async function render(
    el: HTMLElement,
    pts: DispatchMarker[],
    opts: { fit?: boolean; zoom?: number; drawRoute?: boolean; center?: { lat: number; lng: number } } = {},
  ) {
    const google = await ensure()
    const center = opts.center || (pts[0] ? { lat: pts[0].lat, lng: pts[0].lng } : { lat: 39.5, lng: -98.35 })
    if (!mapInstance.value) {
      mapInstance.value = new google.maps.Map(el, {
        center,
        zoom: opts.zoom ?? (pts.length ? 6 : 4),
        mapTypeControl: true,
        streetViewControl: false,
        fullscreenControl: true,
        gestureHandling: 'greedy',
        styles: MAP_STYLES,
      })
    } else {
      mapInstance.value.setCenter(center)
    }

    clearMarkers()
    const b = new google.maps.LatLngBounds()
    const created: any[] = []

    for (const p of pts) {
      if (p.lat == null || p.lng == null) continue
      const color = p.color || COLORS[p.kind]
      const isSeq = typeof p.sequence === 'number' && p.kind === 'stop'
      const glyph = isSeq ? String(p.sequence! + 1) : ''
      const svg = makePinSvg(color, ICONS[p.kind], glyph)
      const icon: google.maps.Icon = {
        url: 'data:image/svg+xml;utf8,' + encodeURIComponent(svg),
        scaledSize: new google.maps.Size(38, 38),
        anchor: new google.maps.Point(19, 38),
        labelOrigin: new google.maps.Point(19, 15),
      }
      const m = new google.maps.Marker({
        position: { lat: p.lat, lng: p.lng },
        map: mapInstance.value,
        icon,
        title: p.title || p.label || p.id,
        label: isSeq ? { text: String(p.sequence! + 1), color: '#fff', fontSize: '11px', fontWeight: '700' } : undefined,
      })
      if (p.title || p.label) {
        const iw = new google.maps.InfoWindow({ content: `<div style="font-weight:600">${p.title || p.label}</div>` })
        m.addListener('click', () => iw.open({ anchor: m, map: mapInstance.value }))
      }
      created.push(m)
      b.extend({ lat: p.lat, lng: p.lng })
    }
    markers.value = created
    bounds.value = b

    if (opts.drawRoute && pts.length >= 2) {
      const path = pts.filter(p => p.lat != null && p.lng != null).map(p => ({ lat: p.lat, lng: p.lng }))
      if (polyline.value) polyline.value.setMap(null)
      polyline.value = new google.maps.Polyline({
        path,
        geodesic: true,
        strokeColor: '#6366f1',
        strokeOpacity: 0.85,
        strokeWeight: 4,
        map: mapInstance.value,
      })
    }

    if (opts.fit !== false && pts.length > 1) {
      mapInstance.value.fitBounds(b, 60)
    } else if (pts.length === 1) {
      mapInstance.value.setCenter({ lat: pts[0].lat, lng: pts[0].lng })
      mapInstance.value.setZoom(opts.zoom ?? 13)
    }
  }

  function clearMarkers() {
    markers.value.forEach(m => m.setMap(null))
    markers.value = []
    if (polyline.value) { polyline.value.setMap(null); polyline.value = null }
  }

  function focusMarker(p: DispatchMarker) {
    if (!mapInstance.value || p.lat == null) return
    mapInstance.value.panTo({ lat: p.lat, lng: p.lng })
    mapInstance.value.setZoom(14)
  }

  onUnmounted(() => { clearMarkers(); mapInstance.value = null })

  return { render, clearMarkers, focusMarker, mapInstance, loading: loader.state.loading }
}

function makePinSvg(color: string, _icon: string, glyph = ''): string {
  if (glyph) {
    return `<svg xmlns="http://www.w3.org/2000/svg" width="38" height="48" viewBox="0 0 24 32">
      <path fill="${color}" stroke="#fff" stroke-width="1.5" d="M12 0C5.4 0 0 5.4 0 12c0 9 12 20 12 20s12-11 12-20C24 5.4 18.6 0 12 0z"/>
      <circle cx="12" cy="12" r="9" fill="#fff"/>
      <text x="12" y="16" text-anchor="middle" font-size="11" font-family="Arial,sans-serif" font-weight="700" fill="${color}">${glyph}</text>
    </svg>`
  }
  return `<svg xmlns="http://www.w3.org/2000/svg" width="38" height="48" viewBox="0 0 24 32">
    <path fill="${color}" stroke="#fff" stroke-width="1.5" d="M12 0C5.4 0 0 5.4 0 12c0 9 12 20 12 20s12-11 12-20C24 5.4 18.6 0 12 0z"/>
    <circle cx="12" cy="12" r="7" fill="#fff"/>
  </svg>`
}

const MAP_STYLES = [
  { featureType: 'all', elementType: 'labels.text.fill', stylers: [{ color: '#475569' }] },
  { featureType: 'administrative', elementType: 'geometry', stylers: [{ visibility: 'simplified' }] },
  { featureType: 'road', elementType: 'geometry', stylers: [{ color: '#e2e8f0' }] },
  { featureType: 'water', elementType: 'geometry', stylers: [{ color: '#dbeafe' }] },
  { featureType: 'landscape', elementType: 'geometry', stylers: [{ color: '#f8fafc' }] },
  { featureType: 'poi', elementType: 'labels', stylers: [{ visibility: 'simplified' }] },
]
