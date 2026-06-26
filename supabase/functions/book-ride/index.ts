import { requireFields, requireMethod, readJson, serveJson, stubResponse } from "../_shared/http.ts"
import { requireUser } from "../_shared/supabase.ts"
import { bookingImplementationSteps, type BookRideRequest } from "../_shared/marketplace.ts"

serveJson(async (request) => {
  requireMethod(request, "POST")
  const user = await requireUser(request)
  const payload = await readJson<BookRideRequest>(request)
  requireFields(payload as unknown as Record<string, unknown>, ["rideID", "seats"])

  return stubResponse("book-ride", {
    userID: user.id,
    ...payload,
  }, bookingImplementationSteps)
})

