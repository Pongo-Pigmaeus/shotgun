import { createBrowserClient } from "@supabase/ssr"

function supabaseKey() {
  return process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ?? process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
}

export function hasSupabaseConfig() {
  return Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL && supabaseKey())
}

export function createSupabaseBrowserClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL
  const key = supabaseKey()

  if (!url || !key) {
    throw new Error("Missing Supabase environment variables.")
  }

  return createBrowserClient(url, key)
}
