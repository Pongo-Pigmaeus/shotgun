import { requireFields, requireMethod, readJson, serveJson, stubResponse } from "../_shared/http.ts"
import { type CheckoutSessionRequest } from "../_shared/marketplace.ts"
import { requireUser } from "../_shared/supabase.ts"

serveJson(async (request) => {
  requireMethod(request, "POST")
  const user = await requireUser(request)
  const payload = await readJson<CheckoutSessionRequest>(request)
  requireFields(payload as unknown as Record<string, unknown>, ["rideID", "seats", "amountCents"])

  return stubResponse("create-checkout-session", {
    userID: user.id,
    ...payload,
  }, [
    "Verify ride is active and has enough seats for the requested quantity.",
    "Create a Stripe PaymentIntent with manual capture for approval-required rides.",
    "Store checkout_sessions row with provider_payment_intent_id and client_secret.",
    "Return checkout session details to the app.",
  ])
})

