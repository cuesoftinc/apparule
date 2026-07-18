// Mock: GET /api/v1/moderation/queue — open reports (moderator only; the
// mock treats every actor as staff for QA).
import { handle, jsonResponse, paginate } from "@/mocks/http";
import { getStore } from "@/mocks/store";

export async function GET(request: Request) {
  return handle(() =>
    jsonResponse(paginate(getStore().moderationQueue(), new URL(request.url))),
  );
}
