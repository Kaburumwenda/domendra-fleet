/**
 * Resolves a media path returned by the DRF backend to a fully-qualified URL
 * the browser can load.
 *
 * The backend serves files from MEDIA_URL='media/' (relative), so ImageField
 * values come back as e.g. `media/customers/photo.jpg` or sometimes
 * `/media/customers/photo.jpg`. This helper turns those into absolute URLs
 * against the API origin (everything before `/api`).
 *
 * Absolute URLs (http/https) are returned as-is.
 */
export function useMediaUrl() {
  const config = useRuntimeConfig()
  const origin = computed(
    () => config.public.apiBase.replace(/\/$/, '').replace(/\/api$/, ''),
  )

  function resolveMediaUrl(url: string | null | undefined): string {
    if (!url) return ''
    if (/^https?:\/\//i.test(url)) return url
    const cleaned = url.replace(/^\/+/, '')
    return `${origin.value}/${cleaned}`
  }

  return { resolveMediaUrl }
}
