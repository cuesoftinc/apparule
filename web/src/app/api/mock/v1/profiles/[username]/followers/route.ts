// Mock: GET /api/v1/profiles/{username}/followers — B6 followers sheet
// (UserRow list, MI-7 morph state per row).
import { actorUsername, handle, jsonResponse, paginate } from "@/mocks/http";
import { getStore } from "@/mocks/store";

type Params = { params: Promise<{ username: string }> };

export async function GET(request: Request, { params }: Params) {
  return handle(async () => {
    const { username } = await params;
    const rows = getStore().followersOf(username, actorUsername(request));
    return jsonResponse(paginate(rows, new URL(request.url)));
  });
}
