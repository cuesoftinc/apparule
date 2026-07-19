// Mock: GET /api/v1/profiles/{username} — public profile (designer or
// regular user, pages.md B6). No profile-read group exists in api.md §5 yet;
// mock-ahead-of-contract (stage-report deviation).
import { actorUsername, handle, jsonResponse } from "@/mocks/http";
import { getStore } from "@/mocks/store";

type Params = { params: Promise<{ username: string }> };

export async function GET(request: Request, { params }: Params) {
  return handle(async () => {
    const { username } = await params;
    return jsonResponse(
      getStore().profileFor(username, actorUsername(request)),
    );
  });
}
