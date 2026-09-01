const CURRENCY_SYMBOLS: Record<string, string> = {
  USD: '$', EUR: '€', GBP: '£', KES: 'KSh', NGN: '₦', ZAR: 'R',
  AED: 'AED', SAR: 'SAR', INR: '₹', CAD: 'C$', AUD: 'A$',
  JPY: '¥', CNY: '¥', BRL: 'R$', GHS: '₵', TZS: 'TSh',
  UGX: 'USh', RWF: 'FRw', ETB: 'Br',
}

let _loadPromise: Promise<any> | null = null

function symbolFor(code: string): string {
  return CURRENCY_SYMBOLS[code] || code
}

export function useCurrency() {
  const state = useState<{ code: string; symbol: string; loaded: boolean }>('fc-currency', () => ({
    code: 'USD',
    symbol: '$',
    loaded: false,
  }))
  const { $api } = useNuxtApp()

  async function load() {
    if (state.value.loaded) return state.value
    if (_loadPromise) return _loadPromise
    _loadPromise = (async () => {
      try {
        const data: any = await $api('/tenant/')
        const code = data?.currency || 'USD'
        state.value = { code, symbol: symbolFor(code), loaded: true }
      } catch {
        // Leave state as default ($); clear the promise so the next
        // navigation can retry instead of caching a failure forever.
        _loadPromise = null
      }
      return state.value
    })()
    return _loadPromise
  }

  function fmtMoney(v: any, decimals = 2): string | null {
    if (v == null || v === '') return null
    const n = Number(v)
    if (Number.isNaN(n)) return String(v)
    return `${state.value.symbol}${n.toLocaleString(undefined, {
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals,
    })}`
  }

  const currencySymbol = computed(() => state.value.symbol)
  const currencyCode = computed(() => state.value.code)

  return { currency: state, currencySymbol, currencyCode, fmtMoney, load }
}
