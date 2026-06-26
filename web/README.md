# Shotgun Web

Next.js web app for the Shotgun Northeast rideshare marketplace.

## Local Development

```bash
cd web
npm install
npm run dev
```

Open `http://localhost:3000`.

## Vercel

Use `web` as the Vercel project root directory when connecting the GitHub repo.

Environment variables:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `NEXT_PUBLIC_APP_ENV`

The app currently uses local mock data and is structured so Supabase services can replace the mock store later.

Keep Stripe secret keys, Supabase service-role keys, and webhook signing secrets out of public environment variables. Those belong in Supabase Edge Functions or Vercel server-side functions.
