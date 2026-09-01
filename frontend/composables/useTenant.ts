const CURRENCY_SYMBOLS: Record<string, string> = {
  USD: '$', EUR: '€', GBP: '£', KES: 'KSh', NGN: '₦', ZAR: 'R',
  AED: 'AED', SAR: 'SAR', INR: '₹', CAD: 'C$', AUD: 'A$',
  JPY: '¥', CNY: '¥', BRL: 'R$', GHS: '₵', TZS: 'TSh',
  UGX: 'USh', RWF: 'FRw', ETB: 'Br',
}

function symbolFor(code: string): string {
  return CURRENCY_SYMBOLS[code] || code
}

interface TenantProfile {
  short_name: string
  full_name: string
  logo: string
  currency: string
  email: string
  mobile_number: string
  address: string
  loaded: boolean
}

export function useTenant() {
  const state = useState<TenantProfile>('fc-tenant', () => ({
    short_name: '',
    full_name: '',
    logo: '',
    currency: 'USD',
    email: '',
    mobile_number: '',
    address: '',
    loaded: false,
  }))
  const { $api } = useNuxtApp()
  const config = useRuntimeConfig()
  const origin = config.public.apiBase.replace(/\/$/, '').replace(/\/api$/, '')

  let _loadPromise: Promise<any> | null = null

  async function load(force = false) {
    if (state.value.loaded && !force) return state.value
    if (_loadPromise && !force) return _loadPromise
    _loadPromise = (async () => {
      try {
        const data: any = await $api('/tenant/')
        state.value = {
          short_name: data.short_name || '',
          full_name: data.full_name || '',
          logo: data.logo || '',
          currency: data.currency || 'USD',
          email: data.email || '',
          mobile_number: data.mobile_number || '',
          address: data.address || '',
          loaded: true,
        }
      } catch {
        _loadPromise = null
      }
      return state.value
    })()
    return _loadPromise
  }

  function patch(partial: Partial<TenantProfile>) {
    state.value = { ...state.value, ...partial, loaded: true }
  }

  const logoUrl = computed(() => {
    const l = state.value.logo
    if (!l) return ''
    return l.startsWith('http') ? l : `${origin}${l}`
  })

  const displayName = computed(() => state.value.short_name || state.value.full_name || 'DomendraFleet')

  return { tenant: state, load, patch, logoUrl, displayName, currencySymbol: computed(() => symbolFor(state.value.currency)) }
}
