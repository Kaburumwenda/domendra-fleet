import {
  bodyTypes as staticBodyTypes,
  bodyTypesForMake as staticBodyTypesForMake,
  catalogMakes as staticCatalogMakes,
  modelsForMakeBodyType as staticModelsForMakeBodyType,
  type BodyTypeOption,
} from './useVehicleCatalog'

function unwrap<T>(res: any): T[] {
  return (res?.results || res || []) as T[]
}

export function useTenantCatalog() {
  const { $api } = useNuxtApp()

  const tenantMakes = useState<any[]>('tc-makes', () => [])
  const tenantBodyTypes = useState<any[]>('tc-bodytypes', () => [])
  const tenantModels = useState<any[]>('tc-models', () => [])
  const loaded = useState<boolean>('tc-loaded', () => false)
  const loading = useState<boolean>('tc-loading', () => false)

  async function load() {
    if (loaded.value || loading.value) return
    loading.value = true
    try {
      const [mk, bt, md] = await Promise.all([
        $api('/vehicles/catalog/makes/'),
        $api('/vehicles/catalog/body-types/'),
        $api('/vehicles/catalog/models/'),
      ])
      tenantMakes.value = unwrap(mk)
      tenantBodyTypes.value = unwrap(bt)
      tenantModels.value = unwrap(md)
      loaded.value = true
    } catch (e) {
      console.error('Tenant catalog load failed:', e)
    } finally {
      loading.value = false
    }
  }

  async function reload() {
    loaded.value = false
    tenantMakes.value = []
    tenantBodyTypes.value = []
    tenantModels.value = []
    await load()
  }

  function hasTenantData() {
    return tenantMakes.value.length > 0
  }

  function makeOptions(): string[] {
    const set = new Set<string>(staticCatalogMakes())
    for (const m of tenantMakes.value) set.add(m.name)
    return Array.from(set).sort()
  }

  function bodyTypeOptionsForMake(make: string): BodyTypeOption[] {
    const result = new Map<string, BodyTypeOption>()
    for (const b of staticBodyTypesForMake(make)) result.set(b.value, b)
    const btIdsForMake = new Set(
      tenantModels.value.filter((m) => m.make_name === make).map((m) => m.body_type)
    )
    for (const bt of tenantBodyTypes.value) {
      if (btIdsForMake.has(bt.id)) {
        result.set(bt.value, { label: bt.label, value: bt.value, icon: bt.icon })
      }
    }
    return Array.from(result.values())
  }

  function allBodyTypes(): BodyTypeOption[] {
    const result = new Map<string, BodyTypeOption>()
    for (const b of staticBodyTypes) result.set(b.value, b)
    for (const bt of tenantBodyTypes.value) {
      result.set(bt.value, { label: bt.label, value: bt.value, icon: bt.icon })
    }
    return Array.from(result.values())
  }

  function modelsForMakeBodyType(make: string, bodyTypeValue: string): string[] {
    const set = new Set<string>(staticModelsForMakeBodyType(make, bodyTypeValue))
    for (const m of tenantModels.value) {
      if (m.make_name === make && m.body_type_value === bodyTypeValue) set.add(m.name)
    }
    return Array.from(set).sort()
  }

  return {
    load,
    reload,
    loading,
    hasTenantData,
    makeOptions,
    bodyTypeOptionsForMake,
    allBodyTypes,
    modelsForMakeBodyType,
  }
}
