import { corsHeaders, handleCors } from "./cors.ts"

export class HttpError extends Error {
  status: number
  code: string
  details?: unknown

  constructor(status: number, code: string, message: string, details?: unknown) {
    super(message)
    this.status = status
    this.code = code
    this.details = details
  }
}

export type Handler = (request: Request) => Promise<Response>

export function serveJson(handler: Handler) {
  Deno.serve(async (request) => {
    const corsResponse = handleCors(request)
    if (corsResponse) {
      return corsResponse
    }

    try {
      return await handler(request)
    } catch (error) {
      return errorResponse(error)
    }
  })
}

export async function readJson<T>(request: Request): Promise<T> {
  try {
    return await request.json() as T
  } catch {
    throw new HttpError(400, "invalid_json", "Request body must be valid JSON.")
  }
}

export function requireMethod(request: Request, method: string) {
  if (request.method !== method) {
    throw new HttpError(405, "method_not_allowed", `Use ${method} for this endpoint.`)
  }
}

export function requireFields(payload: Record<string, unknown>, fields: string[]) {
  const missing = fields.filter((field) => payload[field] === undefined || payload[field] === null)
  if (missing.length > 0) {
    throw new HttpError(400, "missing_fields", "Required fields are missing.", { missing })
  }
}

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  })
}

export function stubResponse(endpoint: string, received: unknown, nextSteps: string[]): Response {
  return jsonResponse({
    status: "stub",
    endpoint,
    message: "This Supabase Edge Function scaffold is ready for implementation.",
    received,
    nextSteps,
  }, 501)
}

export function errorResponse(error: unknown): Response {
  if (error instanceof HttpError) {
    return jsonResponse({
      error: {
        code: error.code,
        message: error.message,
        details: error.details,
      },
    }, error.status)
  }

  console.error(error)
  return jsonResponse({
    error: {
      code: "internal_error",
      message: "Unexpected server error.",
    },
  }, 500)
}

