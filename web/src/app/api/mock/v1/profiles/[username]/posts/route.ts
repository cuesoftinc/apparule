// Mock: GET /api/v1/profiles/{username}/posts — the B6 profile grid.
import { actorUsername, handle, jsonResponse, paginate } from "@/mocks/http";
import { getStore } from "@/mocks/store";

type Params = { params: Promise<{ username: string }> };

export async function GET(request: Request, { params }: Params) {
  return handle(async () => {
    const { username } = await params;
    const posts = getStore().postsBy(username, actorUsername(request));
    return jsonResponse(paginate(posts, new URL(request.url)));
  });
}
