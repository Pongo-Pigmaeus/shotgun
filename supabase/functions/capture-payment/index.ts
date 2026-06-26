import { requireFields, requireMethod, readJson, serveJson, stubResponse } from "../_shared/http.ts"
import { type PaymentActionRequest } from "../_shared/marketplace.ts"
import { requireUser } from "../_shared/supabase.ts"

serveJson(async (request) => {
  requireMethod(request, "POST")
  const user = await requireUser(request)
  const payload = await readJson<PaymentActionRequest>(request)
  requireFields(payload as unknown as Record<string, unknown>, ["paymentID", "bookingID"])

  return stubResponse("capture-payment", {
    userID: user.id,
    ...payload,
  }, [
    "Verify the authenticated user can approve/capture this booking.",
    "Capture the Stripe PaymentIntent using the stored provider_payment_intent_id.",
    "Set payments.status to succeeded, intent_status to captured, and captured_at to now().",
    "Create or update the related driver_payouts row.",
  ])
})

