import { requireFields, requireMethod, readJson, serveJson, stubResponse } from "../_shared/http.ts"
import { type BookingActionRequest } from "../_shared/marketplace.ts"
import { requireUser } from "../_shared/supabase.ts"

serveJson(async (request) => {
  requireMethod(request, "POST")
  const user = await requireUser(request)
  const payload = await readJson<BookingActionRequest>(request)
  requireFields(payload as unknown as Record<string, unknown>, ["bookingID"])

  return stubResponse("decline-booking", {
    userID: user.id,
    ...payload,
  }, [
    "Verify the authenticated user is the ride driver.",
    "Void the authorized Stripe PaymentIntent or refund if already captured.",
    "Set booking.status to canceled and canceled_at to now().",
    "Restore ride.seats_available and status when appropriate.",
    "Insert a booking_events audit row and enqueue rider notification.",
  ])
})

