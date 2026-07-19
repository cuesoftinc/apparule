// Mock: GET /api/v1/profiles/{username}/following — B6 following sheet.
import { actorUsername, handle, jsonResponse, paginate } from "@/mocks/http";
import { getStore } from "@/mocks/store";

type Params = { params: Promise<{ username: string }> };

export async function GET(request: Request, { params }: Params) {
  return handle(async () => {
    const { username } = await params;
    const rows = getStore().followingOf(username, actorUsername(request));
    return jsonResponse(paginate(rows, new URL(request.url)));
  });
}
