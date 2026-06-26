import { requireMethod, serveJson, stubResponse } from "../_shared/http.ts"

serveJson(async (request) => {
  requireMethod(request, "POST")
  const signature = request.headers.get("stripe-signature")
  const webhookSecretConfigured = Boolean(Deno.env.get("STRIPE_WEBHOOK_SECRET"))
  const body = await request.text()

  return stubResponse("stripe-webhook", {
    stripeSignaturePresent: Boolean(signature),
    webhookSecretConfigured,
    bodyBytes: body.length,
  }, [
    "Verify the Stripe signature with STRIPE_WEBHOOK_SECRET.",
    "Handle payment_intent.succeeded, payment_intent.payment_failed, charge.refunded, transfer.paid, and dispute events.",
    "Update payments, driver_payouts, and booking_events idempotently.",
    "Return 2xx only after the event is safely recorded.",
  ])
})

