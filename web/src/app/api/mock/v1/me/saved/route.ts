// Mock: GET /api/v1/me/saved — the viewer's saved looks (B6 saved tab).
import { actorUsername, handle, jsonResponse, paginate } from "@/mocks/http";
import { getStore } from "@/mocks/store";

export async function GET(request: Request) {
  return handle(() => {
    const posts = getStore().savedPosts(actorUsername(request));
    return jsonResponse(paginate(posts, new URL(request.url)));
  });
}
