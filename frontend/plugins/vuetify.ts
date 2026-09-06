import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'

export default defineNuxtPlugin((nuxtApp) => {
  const vuetify = createVuetify({
    components: {
      ...components,
    },
    directives,
    icons: {
      defaultSet: 'mdi',
    },
    theme: {
      defaultTheme: 'light',
      themes: {
        light: {
          dark: false,
          colors: {
            primary: '#6366f1',
            'primary-darken-1': '#4f46e5',
            'on-primary': '#ffffff',
            secondary: '#818cf8',
            'on-secondary': '#ffffff',
            accent: '#a5b4fc',
            error: '#ef4444',
            warning: '#f59e0b',
            info: '#3b82f6',
            success: '#22c55e',
            background: '#ffffff',
            surface: '#ffffff',
            'surface-variant': '#f8fafc',
            'on-surface-variant': '#475569',
            'on-background': '#1e293b',
            'on-surface': '#1e293b',
          },
        },
        dark: {
          dark: true,
          colors: {
            primary: '#818cf8',
            'primary-darken-1': '#6366f1',
            'on-primary': '#0f172a',
            secondary: '#a5b4fc',
            'on-secondary': '#0f172a',
            accent: '#c7d2fe',
            error: '#f87171',
            warning: '#fbbf24',
            info: '#60a5fa',
            success: '#4ade80',
            background: '#0f172a',
            surface: '#1e293b',
            'surface-variant': '#334155',
            'on-surface-variant': '#cbd5e1',
            'on-background': '#f1f5f9',
            'on-surface': '#f1f5f9',
          },
        },
      },
    },
    defaults: {
      VBtn: { rounded: 'lg' },
      VCard: { rounded: 'lg' },
      VTextField: { variant: 'outlined', density: 'comfortable', hideDetails: 'auto' },
      VSelect: { variant: 'outlined', density: 'comfortable', hideDetails: 'auto' },
      VTextarea: { variant: 'outlined', density: 'comfortable', hideDetails: 'auto' },
      VChip: { size: 'small' },
      VDataTable: { hover: true, itemsPerPage: 20 },
    },
  })

  nuxtApp.vueApp.use(vuetify)
})
