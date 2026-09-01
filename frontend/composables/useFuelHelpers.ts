/**
 * Fuel & Energy shared helpers — chip colors, formatters, constants.
 */

const FUEL_TYPES = [
  'Petrol', 'Diesel',
  'Hybrid (Petrol)', 'Hybrid (Diesel)',
  'Plug-in Hybrid (Petrol)', 'Plug-in Hybrid (Diesel)',
  'Mild Hybrid',
  'Electric', 'Fuel Cell (Hydrogen)',
  'LPG', 'CNG', 'LNG',
  'Ethanol (E85)', 'Flex Fuel', 'Biodiesel',
]

const UNIT_OPTIONS = [
  { label: 'Gallons', value: 'gallons' },
  { label: 'Liters', value: 'liters' },
]

const STATION_OPTIONS = [
  'Shell', 'TotalEnergies', 'Stabex', 'Rubis', 'Vivo Energy', 'Oil Libya',
  'Ola Energy', 'Gulf Energy', 'Tosha', 'National Oil', 'Kenol', 'Kobil',
  'Hashi Energy', 'Galana Oil', 'Lake Oil', 'Engen', 'Delta Petroleum',
  'Astrol Petroleum', 'Be Energy', 'Gapco',
]

const CARD_PROVIDERS = [
  { label: 'WEX', value: 'WEX' },
  { label: 'Comdata', value: 'Comdata' },
  { label: 'Fleetcor', value: 'Fleetcor' },
  { label: 'BP', value: 'BP' },
  { label: 'Other', value: 'other' },
]

const CHARGING_NETWORKS = [
  { label: 'ChargePoint', value: 'chargepoint' },
  { label: 'Tesla Supercharger', value: 'tesla' },
  { label: 'EVgo', value: 'evgo' },
  { label: 'Electrify America', value: 'electrify_america' },
  { label: 'Other', value: 'other' },
]

const WEEKDAYS = [
  { label: 'Monday', value: 'mon' },
  { label: 'Tuesday', value: 'tue' },
  { label: 'Wednesday', value: 'wed' },
  { label: 'Thursday', value: 'thu' },
  { label: 'Friday', value: 'fri' },
  { label: 'Saturday', value: 'sat' },
  { label: 'Sunday', value: 'sun' },
]

export function useFuelHelpers() {
  function fuelChipColor(value: string) {
    if (!value) return 'default'
    const v = value.toLowerCase()
    if (v.includes('diesel')) return 'amber'
    if (v.includes('electric') || v.includes('hydrogen')) return 'success'
    if (v.includes('hybrid')) return 'purple'
    if (v.includes('cng') || v.includes('lpg') || v.includes('lng')) return 'teal'
    if (v.includes('ethanol') || v.includes('flex') || v.includes('biodiesel')) return 'deep-orange'
    return 'info'
  }

  function severityColor(severity: string) {
    const map: Record<string, string> = { critical: 'error', high: 'warning', medium: 'amber', low: 'info' }
    return map[severity] || 'default'
  }

  function statusChipColor(status: string) {
    const map: Record<string, string> = { open: 'error', under_review: 'info', resolved: 'success', dismissed: 'grey' }
    return map[status] || 'default'
  }

  function formatAlertType(type: string) {
    return type ? type.replace(/_/g, ' ').replace(/\b\w/g, (c: string) => c.toUpperCase()) : ''
  }

  function formatFuelDate(value: string) {
    const d = new Date(value)
    if (Number.isNaN(d.getTime())) return { date: '', time: '' }
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    const date = `${days[d.getDay()]}, ${months[d.getMonth()]} ${String(d.getDate()).padStart(2, '0')} ${d.getFullYear()}`
    let hours = d.getHours()
    const minutes = String(d.getMinutes()).padStart(2, '0')
    const ampm = hours >= 12 ? 'pm' : 'am'
    hours = hours % 12 || 12
    const time = `${String(hours).padStart(2, '0')}:${minutes}${ampm}`
    return { date, time }
  }

  function formatDate(value: string) {
    if (!value) return '—'
    const d = new Date(value)
    if (Number.isNaN(d.getTime())) return '—'
    return d.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' })
  }

  function networkLabel(value: string) {
    const item = CHARGING_NETWORKS.find((n) => n.value === value)
    return item?.label || value || 'Other'
  }

  function weekdayLabel(code: string) {
    const item = WEEKDAYS.find((d) => d.value === code)
    return item?.label || code
  }

  function maskCard(cardNumber: string) {
    if (!cardNumber || cardNumber.length <= 4) return cardNumber
    return `${cardNumber.slice(0, 4)}••••${cardNumber.slice(-4)}`
  }

  return {
    FUEL_TYPES,
    UNIT_OPTIONS,
    STATION_OPTIONS,
    CARD_PROVIDERS,
    CHARGING_NETWORKS,
    WEEKDAYS,
    fuelChipColor,
    severityColor,
    statusChipColor,
    formatAlertType,
    formatFuelDate,
    formatDate,
    networkLabel,
    weekdayLabel,
    maskCard,
  }
}
