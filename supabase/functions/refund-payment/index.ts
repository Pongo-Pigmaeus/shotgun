import { requireFields, requireMethod, readJson, serveJson, stubResponse } from "../_shared/http.ts"
import { type PaymentActionRequest } from "../_shared/marketplace.ts"
import { requireUser } from "../_shared/supabase.ts"

serveJson(async (request) => {
  requireMethod(request, "POST")
  const user = await requireUser(request)
  const payload = await readJson<PaymentActionRequest>(request)
  requireFields(payload as unknown as Record<string, unknown>, ["paymentID", "bookingID"])

  return stubResponse("refund-payment", {
    userID: user.id,
    ...payload,
  }, [
    "Verify the authenticated user can refund or void this payment.",
    "Void uncaptured PaymentIntents or create a Stripe refund for captured payments.",
    "Set payments.status to voided or refunded.",
    "Cancel pending driver_payouts rows.",
  ])
})

