export default defineNuxtPlugin((nuxtApp) => {
  const config = useRuntimeConfig()
  const base = config.public.apiBase

  const apiFetch = $fetch.create({
    baseURL: base,
    onRequest({ request, options }) {
      const auth = useAuthStore()
      if (auth.accessToken) {
        options.headers = {
          ...options.headers,
          Authorization: `Bearer ${auth.accessToken}`,
        }
      }
      if (auth.tenantSchema) {
        options.headers = {
          ...options.headers,
          'x-tenant-schema': auth.tenantSchema,
        }
      }
    },
    onResponseError({ response }) {
      if (response?.status === 401) {
        const auth = useAuthStore()
        auth.logout()
        navigateTo('/login')
      }
    },
  })

  return {
    provide: {
      api: apiFetch,
    },
  }
})
