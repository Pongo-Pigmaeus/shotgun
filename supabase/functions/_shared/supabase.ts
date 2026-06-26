import { createClient, type SupabaseClient, type User } from "npm:@supabase/supabase-js@2"
import { HttpError } from "./http.ts"

type SupabaseKeyName = "default"

function getSupabaseUrl(): string {
  const value = Deno.env.get("SUPABASE_URL")
  if (!value) {
    throw new HttpError(500, "missing_supabase_url", "SUPABASE_URL is not configured.")
  }
  return value
}

function getKeyFromJsonDictionary(envName: string, keyName: SupabaseKeyName): string | null {
  const raw = Deno.env.get(envName)
  if (!raw) {
    return null
  }

  try {
    const keys = JSON.parse(raw) as Record<string, string>
    return keys[keyName] ?? null
  } catch {
    return null
  }
}

function getPublishableKey(): string {
  const value = getKeyFromJsonDictionary("SUPABASE_PUBLISHABLE_KEYS", "default") ??
    Deno.env.get("SUPABASE_ANON_KEY")
  if (!value) {
    throw new HttpError(500, "missing_supabase_publishable_key", "Supabase publishable key is not configured.")
  }
  return value
}

function getSecretKey(): string {
  const value = getKeyFromJsonDictionary("SUPABASE_SECRET_KEYS", "default") ??
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
  if (!value) {
    throw new HttpError(500, "missing_supabase_secret_key", "Supabase secret key is not configured.")
  }
  return value
}

export function createUserClient(request: Request): SupabaseClient {
  return createClient(getSupabaseUrl(), getPublishableKey(), {
    global: {
      headers: {
        Authorization: request.headers.get("Authorization") ?? "",
      },
    },
  })
}

export function createAdminClient(): SupabaseClient {
  return createClient(getSupabaseUrl(), getSecretKey(), {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  })
}

export async function requireUser(request: Request): Promise<User> {
  const authHeader = request.headers.get("Authorization")
  if (!authHeader?.startsWith("Bearer ")) {
    throw new HttpError(401, "missing_auth", "Sign in before calling this endpoint.")
  }

  const token = authHeader.replace("Bearer ", "")
  const userClient = createUserClient(request)
  const { data, error } = await userClient.auth.getUser(token)

  if (error || !data.user) {
    throw new HttpError(401, "invalid_auth", "Session is expired or invalid.")
  }

  return data.user
}

