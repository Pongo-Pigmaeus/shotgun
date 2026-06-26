import { requireFields, requireMethod, readJson, serveJson, stubResponse } from "../_shared/http.ts"
import { type BookingActionRequest } from "../_shared/marketplace.ts"
import { requireUser } from "../_shared/supabase.ts"

serveJson(async (request) => {
  requireMethod(request, "POST")
  const user = await requireUser(request)
  const payload = await readJson<BookingActionRequest>(request)
  requireFields(payload as unknown as Record<string, unknown>, ["bookingID"])

  return stubResponse("approve-booking", {
    userID: user.id,
    ...payload,
  }, [
    "Verify the authenticated user is the ride driver.",
    "Capture the authorized Stripe PaymentIntent.",
    "Set booking.status to confirmed and approved_at to now().",
    "Create or update the driver_payouts row.",
    "Insert a booking_events audit row and enqueue rider notification.",
  ])
})

