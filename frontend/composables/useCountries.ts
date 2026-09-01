import allCountries from 'intl-tel-input/data'

export interface Country {
  name: string
  code: string // ISO 3166-1 alpha-2 (uppercased)
  dial: string // international dial code without '+'
}

let displayNames: Intl.DisplayNames | null = null
function getDisplayNames(): Intl.DisplayNames | null {
  if (displayNames) return displayNames
  try {
    displayNames = new Intl.DisplayNames(['en'], { type: 'region' })
  } catch {
    displayNames = null
  }
  return displayNames
}

export const COUNTRIES: Country[] = (allCountries as { iso2: string; dialCode: string }[])
  .map((c) => {
    const code = c.iso2.toUpperCase()
    const dn = getDisplayNames()
    const name = (dn?.of(code) as string) || code
    return { name, code, dial: c.dialCode }
  })
  .filter((c) => c.name && c.dial)
  .sort((a, b) => a.name.localeCompare(b.name))

const COUNTRY_BY_NAME = new Map(COUNTRIES.map((c) => [c.name.toLowerCase(), c]))
const COUNTRY_BY_CODE = new Map(COUNTRIES.map((c) => [c.code, c]))

export function flagEmoji(code: string): string {
  if (!code || code.length !== 2) return ''
  return code
    .toUpperCase()
    .split('')
    .map((c) => String.fromCodePoint(127397 + c.charCodeAt(0)))
    .join('')
}

export function useCountries() {
  return {
    countries: COUNTRIES,
    flagEmoji,
    findByName(name: string) {
      return name ? COUNTRY_BY_NAME.get(name.trim().toLowerCase()) : undefined
    },
    findByCode(code: string) {
      return code ? COUNTRY_BY_CODE.get(code.toUpperCase()) : undefined
    },
  }
}
