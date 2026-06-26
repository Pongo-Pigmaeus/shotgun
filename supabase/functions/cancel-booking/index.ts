import { requireFields, requireMethod, readJson, serveJson, stubResponse } from "../_shared/http.ts"
import { type BookingActionRequest } from "../_shared/marketplace.ts"
import { requireUser } from "../_shared/supabase.ts"

serveJson(async (request) => {
  requireMethod(request, "POST")
  const user = await requireUser(request)
  const payload = await readJson<BookingActionRequest>(request)
  requireFields(payload as unknown as Record<string, unknown>, ["bookingID"])

  return stubResponse("cancel-booking", {
    userID: user.id,
    ...payload,
  }, [
    "Verify the authenticated user is the rider or ride driver.",
    "Apply cancellation rules based on departure time and booking status.",
    "Void authorization or refund captured payment through Stripe.",
    "Restore ride.seats_available and update ride.status if it was sold out.",
    "Insert a booking_events audit row and enqueue counterparty notification.",
  ])
})

