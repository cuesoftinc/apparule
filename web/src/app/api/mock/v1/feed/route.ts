// Mock: GET /api/v1/feed — followed + recency-ranked (api.md §5).
import { actorUsername, handle, jsonResponse, paginate } from "@/mocks/http";
import { getStore } from "@/mocks/store";

export async function GET(request: Request) {
  return handle(() => {
    const posts = getStore().feed(actorUsername(request));
    return jsonResponse(paginate(posts, new URL(request.url)));
  });
}
