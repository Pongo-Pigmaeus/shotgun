import { requireFields, requireMethod, readJson, serveJson, stubResponse } from "../_shared/http.ts"
import { type SendMessageRequest } from "../_shared/marketplace.ts"
import { requireUser } from "../_shared/supabase.ts"

serveJson(async (request) => {
  requireMethod(request, "POST")
  const user = await requireUser(request)
  const payload = await readJson<SendMessageRequest>(request)
  requireFields(payload as unknown as Record<string, unknown>, ["conversationID", "body"])

  return stubResponse("send-message", {
    userID: user.id,
    ...payload,
  }, [
    "Verify the authenticated user is a conversation participant.",
    "Insert messages row with sender_id equal to the authenticated user.",
    "Update conversations.last_updated_at.",
    "Enqueue push notification for other participants.",
  ])
})

