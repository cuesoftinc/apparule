// Mock: GET /api/v1/notifications — activity list (90d retention).
import { actorUsername, handle, jsonResponse, paginate } from "@/mocks/http";
import { getStore } from "@/mocks/store";

export async function GET(request: Request) {
  return handle(() => {
    const notifications = getStore().notificationsFor(actorUsername(request));
    return jsonResponse(paginate(notifications, new URL(request.url)));
  });
}
