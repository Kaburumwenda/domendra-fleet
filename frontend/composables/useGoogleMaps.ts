const _state = reactive<{ loaded: boolean; loading: boolean; error: any; google: any }>({
  loaded: false,
  loading: false,
  error: null,
  google: null,
})

let _loadPromise: Promise<any> | null = null

function loadScript(src: string): Promise<void> {
  return new Promise((resolve, reject) => {
    if (document.querySelector(`script[data-google-maps]`)) {
      resolve()
      return
    }
    const s = document.createElement('script')
    s.src = src
    s.async = true
    s.defer = true
    s.setAttribute('data-google-maps', 'true')
    s.onload = () => resolve()
    s.onerror = () => reject(new Error('Failed to load Google Maps script.'))
    document.head.appendChild(s)
  })
}

export function useGoogleMapsLoader(apiKey: string, libraries: string[] = ['places', 'marker']) {
  async function load(): Promise<any> {
    if (_state.loaded && _state.google) return _state.google
    if (_loadPromise) return _loadPromise
    _state.loading = true
    const src = `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(apiKey)}&libraries=${libraries.join(',')}&v=weekly`
    _loadPromise = loadScript(src)
      .then(() => {
        if (!window.google || !window.google.maps) {
          throw new Error('Google Maps global not found after script load.')
        }
        _state.google = window.google
        _state.loaded = true
        return _state.google
      })
      .catch((err) => {
        _state.error = err
        _loadPromise = null
        throw err
      })
      .finally(() => {
        _state.loading = false
      })
    return _loadPromise
  }

  return { load, state: _state }
}

export function useGoogleMaps() {
  const config = useRuntimeConfig()
  const apiKey = config.public.googleMapsApiKey as string
  const loader = useGoogleMapsLoader(apiKey)

  async function ensureGoogle(): Promise<any> {
    return loader.load()
  }

  async function attachAutocomplete(
    inputEl: HTMLInputElement,
    opts: { onPlace?: (place: any) => void; types?: string[]; componentRestrictions?: any } = {},
  ) {
    const google = await ensureGoogle()
    const ac = new google.maps.places.Autocomplete(inputEl, {
      types: opts.types || ['geocode', 'establishment'],
      componentRestrictions: opts.componentRestrictions || undefined,
      fields: ['address_components', 'formatted_address', 'geometry', 'name', 'place_id', 'types'],
    })
    ac.addListener('place_changed', () => {
      const place = ac.getPlace()
      opts.onPlace?.(place)
    })
    return ac
  }

  async function geocodeAddress(address: string): Promise<{ lat: number; lng: number; formatted: string } | null> {
    const google = await ensureGoogle()
    return new Promise((resolve, reject) => {
      const geocoder = new google.maps.Geocoder()
      geocoder.geocode({ address }, (results: any[], status: string) => {
        if (status !== 'OK' || !results || !results.length) {
          resolve(null)
          return
        }
        const r = results[0]
        resolve({
          lat: r.geometry.location.lat(),
          lng: r.geometry.location.lng(),
          formatted: r.formatted_address,
        })
      })
    })
  }

  async function reverseGeocode(lat: number, lng: number): Promise<string> {
    const google = await ensureGoogle()
    return new Promise((resolve, reject) => {
      const geocoder = new google.maps.Geocoder()
      geocoder.geocode({ location: { lat, lng } }, (results: any[], status: string) => {
        if (status !== 'OK' || !results || !results.length) {
          resolve('')
          return
        }
        resolve(results[0].formatted_address || '')
      })
    })
  }

  function getCurrentPosition(): Promise<{ lat: number; lng: number }> {
    return new Promise((resolve, reject) => {
      if (!navigator.geolocation) {
        reject(new Error('Geolocation not supported by browser.'))
        return
      }
      navigator.geolocation.getCurrentPosition(
        (pos) => resolve({ lat: pos.coords.latitude, lng: pos.coords.longitude }),
        (err) => reject(err),
        { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 },
      )
    })
  }

  function createMap(
    el: HTMLElement,
    center: { lat: number; lng: number },
    zoom = 15,
  ): any {
    const google = _state.google
    const map = new google.maps.Map(el, {
      center,
      zoom,
      mapTypeControl: true,
      streetViewControl: true,
      fullscreenControl: true,
    })
    return map
  }

  /* ---- Directions Service (road-following routes) ---- */
  async function getDirections(
    origin: { lat: number; lng: number },
    destination: { lat: number; lng: number },
    waypoints?: { lat: number; lng: number }[],
    opts: { travelMode?: string; avoidTolls?: boolean; avoidHighways?: boolean; trafficModel?: string; departureTime?: Date } = {},
  ): Promise<any> {
    const google = await ensureGoogle()
    return new Promise((resolve, reject) => {
      const service = new google.maps.DirectionsService()
      const wp = (waypoints || []).map(p => ({ location: new google.maps.LatLng(p.lat, p.lng), stopover: true }))
      service.route(
        {
          origin: new google.maps.LatLng(origin.lat, origin.lng),
          destination: new google.maps.LatLng(destination.lat, destination.lng),
          waypoints: wp,
          travelMode: opts.travelMode || google.maps.TravelMode.DRIVING,
          avoidTolls: opts.avoidTolls || false,
          avoidHighways: opts.avoidHighways || false,
          drivingOptions: opts.departureTime
            ? { departureTime: opts.departureTime, trafficModel: opts.trafficModel || google.maps.TrafficModel.BEST_GUESS }
            : undefined,
        },
        (result: any, status: string) => {
          if (status === google.maps.DirectionsStatus.OK && result) resolve(result)
          else reject(new Error(`Directions failed: ${status}`))
        },
      )
    })
  }

  /* ---- Distance Matrix Service (multi-stop ETA) ---- */
  async function getDistanceMatrix(
    origins: { lat: number; lng: number }[],
    destinations: { lat: number; lng: number }[],
    opts: { travelMode?: string; trafficModel?: string; departureTime?: Date } = {},
  ): Promise<any> {
    const google = await ensureGoogle()
    return new Promise((resolve, reject) => {
      const service = new google.maps.DistanceMatrixService()
      service.getDistanceMatrix(
        {
          origins: origins.map(p => new google.maps.LatLng(p.lat, p.lng)),
          destinations: destinations.map(p => new google.maps.LatLng(p.lat, p.lng)),
          travelMode: opts.travelMode || google.maps.TravelMode.DRIVING,
          drivingOptions: opts.departureTime
            ? { departureTime: opts.departureTime, trafficModel: opts.trafficModel || google.maps.TrafficModel.BEST_GUESS }
            : undefined,
        },
        (result: any, status: string) => {
          if (status === google.maps.DistanceMatrixStatus.OK && result) resolve(result)
          else reject(new Error(`Distance Matrix failed: ${status}`))
        },
      )
    })
  }

  /* ---- Traffic Layer on existing map ---- */
  function addTrafficLayer(map: any): any {
    const google = _state.google
    const trafficLayer = new google.maps.TrafficLayer()
    trafficLayer.setMap(map)
    return trafficLayer
  }

  /* ---- Weather via Google Maps Weather (Open-Meteo fallback) ---- */
  async function getWeather(lat: number, lng: number): Promise<{
    temperature: number
    windSpeed: number
    weatherCode: number
    description: string
    isDay: boolean
    precipitation: number
    cloudCover: number
  } | null> {
    try {
      const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lng}&current_weather=true&hourly=precipitation,cloudcover&timezone=auto`
      const res = await $fetch(url)
      const cw = res.current_weather
      if (!cw) return null
      const WMO: Record<number, string> = {
        0: 'Clear sky', 1: 'Mainly clear', 2: 'Partly cloudy', 3: 'Overcast',
        45: 'Fog', 48: 'Fog', 51: 'Light drizzle', 53: 'Moderate drizzle',
        55: 'Dense drizzle', 56: 'Freezing drizzle', 57: 'Freezing drizzle',
        61: 'Slight rain', 63: 'Moderate rain', 65: 'Heavy rain',
        66: 'Freezing rain', 67: 'Freezing rain', 71: 'Slight snow',
        73: 'Moderate snow', 75: 'Heavy snow', 77: 'Snow grains',
        80: 'Rain showers', 81: 'Rain showers', 82: 'Violent rain showers',
        85: 'Snow showers', 86: 'Snow showers', 95: 'Thunderstorm',
        96: 'Thunderstorm with hail', 99: 'Thunderstorm with hail',
      }
      return {
        temperature: cw.temperature,
        windSpeed: cw.windspeed,
        weatherCode: cw.weathercode,
        description: WMO[cw.weathercode] || 'Unknown',
        isDay: cw.is_day === 1,
        precipitation: res.hourly?.precipitation?.[0] || 0,
        cloudCover: res.hourly?.cloudcover?.[0] || 0,
      }
    } catch {
      return null
    }
  }

  return {
    state: _state,
    ensureGoogle,
    attachAutocomplete,
    geocodeAddress,
    reverseGeocode,
    getCurrentPosition,
    createMap,
    getDirections,
    getDistanceMatrix,
    addTrafficLayer,
    getWeather,
  }
}
