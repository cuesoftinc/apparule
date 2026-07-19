// Mock: POST /api/v1/notifications/read — clears badges (MI-16).
import { actorUsername, handle, noContent, readJson } from "@/mocks/http";
import { getStore } from "@/mocks/store";

export async function POST(request: Request) {
  return handle(async () => {
    const body = await readJson<{ ids?: string[] }>(request).catch(
      () => ({}) as { ids?: string[] },
    );
    getStore().markNotificationsRead(actorUsername(request), body.ids);
    return noContent();
  });
}
