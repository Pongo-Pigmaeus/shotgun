# Shotgun Supabase Scaffold

This folder is the backend contract for Shotgun. It is safe to commit because it contains schema, policies, and function code only. Keep real secrets in `supabase/functions/.env` locally or in Supabase project secrets.

## Local Setup

1. Install Docker Desktop and the Supabase CLI.
2. From the repo root, run `supabase start`.
3. Apply migrations with `supabase db reset` for a fresh local database.
4. Copy `supabase/functions/.env.example` to `supabase/functions/.env` and fill values from the `supabase start` output.
5. Serve functions with `supabase functions serve --env-file supabase/functions/.env`.

## Current Scope

- Database schema for profiles, rides, bookings, payments, messages, reviews, reports, support, saved routes, notification devices, and driver payouts.
- Row Level Security policies for authenticated marketplace access.
- Edge Function stubs for booking, approval, cancellation, checkout, payment capture/refund, messaging, and Stripe webhooks.
- No live Supabase project is linked yet.
- No real Stripe calls are made yet.

## Function Contract

The iOS app should eventually call these functions rather than directly mutating inventory or payment state:

- `book-ride`
- `approve-booking`
- `decline-booking`
- `cancel-booking`
- `create-checkout-session`
- `capture-payment`
- `refund-payment`
- `send-message`
- `stripe-webhook`

The stubs intentionally return `501 Not Implemented` until the live Supabase project and Stripe credentials are connected.

