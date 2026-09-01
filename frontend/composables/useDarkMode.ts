import { useTheme } from 'vuetify'

const STORAGE_KEY = 'domendra-theme'
const isDark = ref(false)
let initialized = false

export function useDarkMode() {
  const theme = useTheme()

  function apply(value: boolean) {
    isDark.value = value
    theme.global.name.value = value ? 'dark' : 'light'
    if (import.meta.client) {
      localStorage.setItem(STORAGE_KEY, value ? 'dark' : 'light')
    }
  }

  function toggle() {
    apply(!isDark.value)
  }

  function init() {
    if (initialized || !import.meta.client) return
    initialized = true
    const stored = localStorage.getItem(STORAGE_KEY)
    // Default to dark mode when no preference is stored
    apply(stored !== 'light')
  }

  return { isDark, toggle, init }
}
