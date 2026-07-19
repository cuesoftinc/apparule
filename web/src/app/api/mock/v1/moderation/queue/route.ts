// Mock: GET /api/v1/moderation/queue — open reports (staff only; the seeded
// TEST_MODE user carries is_staff so the B7a queue is walkable).
import { actorUsername, handle, jsonResponse, paginate } from "@/mocks/http";
import { getStore } from "@/mocks/store";

export async function GET(request: Request) {
  return handle(() =>
    jsonResponse(
      paginate(
        getStore().moderationQueue(actorUsername(request)),
        new URL(request.url),
      ),
    ),
  );
}
