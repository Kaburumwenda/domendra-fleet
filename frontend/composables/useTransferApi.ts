/** Transfer booking API composable. */

export interface TransferStop {
  id?: number
  sequence: number
  place_name: string
  address: string
  latitude?: number
  longitude?: number
  duration_min?: number
  notes?: string
}

export interface Transfer {
  id?: number
  reference?: string
  status: string
  trip_type: string
  service_class: string
  payment_status: string
  passenger_name: string
  passenger_email: string
  passenger_phone: string
  passenger_count: number
  luggage_count: number
  has_child_seat: boolean
  has_infant_seat: boolean
  passenger_notes: string
  pickup_name: string
  pickup_address: string
  pickup_lat?: number
  pickup_lng?: number
  pickup_datetime: string
  pickup_flight_no: string
  dropoff_name: string
  dropoff_address: string
  dropoff_lat?: number
  dropoff_lng?: number
  dropoff_datetime?: string
  vehicle?: number | null
  vehicle_name?: string
  driver?: number | null
  driver_name?: string
  base_fare: number
  distance_km: number
  estimated_duration_min: number
  tolls_amount: number
  parking_amount: number
  meet_greet_fee: number
  waiting_fee: number
  child_seat_fee: number
  discount_amount: number
  driver_tip: number
  tax_amount: number
  total_amount: number
  currency: string
  return_datetime?: string
  amount_paid: number
  payment_method: string
  payment_reference: string
  actual_pickup_time?: string
  actual_dropoff_time?: string
  driver_current_lat?: number
  driver_current_lng?: number
  rating?: number
  feedback: string
  notes: string
  stops?: TransferStop[]
  remaining_balance?: number
  is_upcoming?: boolean
  is_active?: boolean
  created_at?: string
  updated_at?: string
}

export const TRANSFER_STATUS_OPTIONS = [
  { title: 'All', value: '' },
  { title: 'Draft', value: 'draft' },
  { title: 'Scheduled', value: 'scheduled' },
  { title: 'Assigned', value: 'assigned' },
  { title: 'En Route', value: 'en_route' },
  { title: 'Picked Up', value: 'picked_up' },
  { title: 'Completed', value: 'completed' },
  { title: 'Cancelled', value: 'cancelled' },
  { title: 'No Show', value: 'no_show' },
]

export const TRANSFER_SERVICE_CLASS_OPTIONS = [
  { title: 'Economy', value: 'economy' },
  { title: 'Business', value: 'business' },
  { title: 'Premium', value: 'premium' },
  { title: 'Luxury', value: 'luxury' },
  { title: 'Van / Minibus', value: 'van' },
  { title: 'Executive', value: 'executive' },
]

export const TRANSFER_TRIP_TYPE_OPTIONS = [
  { title: 'One-Way', value: 'one_way' },
  { title: 'Round Trip', value: 'round_trip' },
  { title: 'Hourly Hire', value: 'hourly' },
]

export const TRANSFER_PAYMENT_STATUS_OPTIONS = [
  { title: 'Unpaid', value: 'unpaid' },
  { title: 'Partially Paid', value: 'partial' },
  { title: 'Paid', value: 'paid' },
  { title: 'Refunded', value: 'refunded' },
]

export function useTransferApi() {
  const { $api } = useNuxtApp()

  async function fetchTransfers(params?: Record<string, any>): Promise<Transfer[]> {
    return await $api('/transfers/bookings/', { query: params })
  }

  async function fetchTransfer(id: number): Promise<Transfer> {
    return await $api(`/transfers/bookings/${id}/`)
  }

  async function fetchStats(): Promise<any> {
    return await $api('/transfers/bookings/stats/')
  }

  async function createTransfer(payload: Partial<Transfer>): Promise<Transfer> {
    return await $api('/transfers/bookings/', { method: 'POST', body: payload })
  }

  async function updateTransfer(id: number, payload: Partial<Transfer>): Promise<Transfer> {
    return await $api(`/transfers/bookings/${id}/`, { method: 'PATCH', body: payload })
  }

  async function deleteTransfer(id: number): Promise<void> {
    await $api(`/transfers/bookings/${id}/`, { method: 'DELETE' })
  }

  async function assignTransfer(id: number, vehicle?: number, driver?: number): Promise<Transfer> {
    return await $api(`/transfers/bookings/${id}/assign/`, { method: 'POST', body: { vehicle, driver } })
  }

  async function startTransfer(id: number): Promise<Transfer> {
    return await $api(`/transfers/bookings/${id}/start/`, { method: 'POST' })
  }

  async function pickupTransfer(id: number): Promise<Transfer> {
    return await $api(`/transfers/bookings/${id}/pickup/`, { method: 'POST' })
  }

  async function completeTransfer(id: number): Promise<Transfer> {
    return await $api(`/transfers/bookings/${id}/complete/`, { method: 'POST' })
  }

  async function cancelTransfer(id: number, reason?: string): Promise<Transfer> {
    return await $api(`/transfers/bookings/${id}/cancel/`, { method: 'POST', body: { reason } })
  }

  async function noShowTransfer(id: number): Promise<Transfer> {
    return await $api(`/transfers/bookings/${id}/no-show/`, { method: 'POST' })
  }

  async function recordPayment(id: number, amount: number, method: string, reference?: string): Promise<Transfer> {
    return await $api(`/transfers/bookings/${id}/record-payment/`, { method: 'POST', body: { amount, method, reference } })
  }

  async function rateTransfer(id: number, rating: number, feedback: string): Promise<Transfer> {
    return await $api(`/transfers/bookings/${id}/rate/`, { method: 'POST', body: { rating, feedback } })
  }

  return {
    fetchTransfers,
    fetchTransfer,
    fetchStats,
    createTransfer,
    updateTransfer,
    deleteTransfer,
    assignTransfer,
    startTransfer,
    pickupTransfer,
    completeTransfer,
    cancelTransfer,
    noShowTransfer,
    recordPayment,
    rateTransfer,
  }
}
