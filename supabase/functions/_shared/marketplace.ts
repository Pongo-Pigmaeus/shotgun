export type BookRideRequest = {
  rideID: string
  seats: number
  paymentMethodID?: string
  idempotencyKey?: string
}

export type BookingActionRequest = {
  bookingID: string
  reason?: string
}

export type CheckoutSessionRequest = {
  rideID: string
  seats: number
  amountCents: number
  paymentMethodID?: string
  idempotencyKey?: string
}

export type PaymentActionRequest = {
  paymentID: string
  bookingID: string
  reason?: string
  idempotencyKey?: string
}

export type SendMessageRequest = {
  conversationID: string
  body: string
}

export const bookingImplementationSteps = [
  "Validate the authenticated user and request payload.",
  "Create or confirm a Stripe PaymentIntent using an idempotency key.",
  "Run a Postgres transaction/RPC that locks the ride row, checks seats_available, creates the booking, updates seats, creates payment, and creates conversation rows.",
  "Return the hydrated booking, ride, payment, and conversation payload expected by the iOS app.",
]

