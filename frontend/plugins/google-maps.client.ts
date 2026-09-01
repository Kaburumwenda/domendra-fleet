declare global {
  interface Window {
    google?: any
  }
}

export default defineNuxtPlugin(async (nuxtApp) => {
  const config = useRuntimeConfig()
  const key = config.public.googleMapsApiKey as string
  if (!key) {
    console.warn('[google-maps] Missing NUXT_PUBLIC_GOOGLE_MAPS_API_KEY — Google Maps features disabled.')
    return
  }

  const loader = useGoogleMapsLoader(key)
  loader.load().then((google) => {
    nuxtApp.provide('google', google)
  }).catch((err) => {
    console.error('[google-maps] Failed to load Google Maps script:', err)
  })
})
