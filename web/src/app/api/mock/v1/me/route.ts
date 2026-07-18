// Mock: GET/PATCH /api/v1/me (api.md §2 — resolve/update the caller).
import { actorUsername, handle, jsonResponse, readJson } from "@/mocks/http";
import { getStore } from "@/mocks/store";
import type { ProfileLocation } from "@/models";

export async function GET(request: Request) {
  return handle(() => jsonResponse(getStore().me(actorUsername(request))));
}

export async function PATCH(request: Request) {
  return handle(async () => {
    const patch = await readJson<{
      username?: string;
      display_name?: string;
      profile_location?: ProfileLocation | null;
    }>(request);
    return jsonResponse(getStore().updateMe(actorUsername(request), patch));
  });
}
