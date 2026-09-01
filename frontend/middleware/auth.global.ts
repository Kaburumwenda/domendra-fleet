export default defineNuxtRouteMiddleware(async (to) => {
  const auth = useAuthStore()

  if (import.meta.client) {
    auth.init()
    if (auth.isAuthenticated && to.path.startsWith('/app')) {
      useCurrency().load()
      // Ensure RBAC permissions are loaded before evaluating route guards.
      const rbac = useRbac()
      await rbac.loadMyPermissions()
    }
  }

  const isAppRoute = to.path.startsWith('/app')
  const isSuperAdminRoute = to.path.startsWith('/superadmin')

  if ((isAppRoute || isSuperAdminRoute) && !auth.isAuthenticated) {
    return navigateTo('/login')
  }

  if (isSuperAdminRoute && !auth.isAdmin) {
    return navigateTo('/app')
  }

  // Per-route permission guard: pages may declare a required permission via
  // `definePageMeta({ permission: 'module:action' })`. Users lacking the
  // permission are redirected to the app home with a toast notice.
  if (isAppRoute && auth.isAuthenticated) {
    const rbac = useRbac()
    const required = to.meta?.permission as string | undefined
    if (required && !rbac.canCode(required)) {
      if (import.meta.client) {
        const { $swal } = useNuxtApp()
        $swal?.fire({
          icon: 'info',
          title: 'Access Restricted',
          text: 'You do not have permission to view that page.',
          toast: true,
          position: 'top-end',
          timer: 2500,
          showConfirmButton: false,
        })
      }
      return navigateTo('/app')
    }
  }

  if (auth.isAuthenticated && (to.path === '/login' || to.path === '/register')) {
    return navigateTo(auth.isAdmin ? '/superadmin' : '/app')
  }
})
