export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, stripe-signature",
  "Access-Control-Allow-Methods": "GET, POST, PATCH, DELETE, OPTIONS",
}

export function handleCors(request: Request): Response | null {
  if (request.method !== "OPTIONS") {
    return null
  }

  return new Response("ok", {
    status: 200,
    headers: corsHeaders,
  })
}

