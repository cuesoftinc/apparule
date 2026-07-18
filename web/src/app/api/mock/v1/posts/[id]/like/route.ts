// Mock: POST/DELETE /api/v1/posts/{id}/like — idempotent toggle (MI-18).
import { actorUsername, handle, noContent } from "@/mocks/http";
import { getStore } from "@/mocks/store";

type Params = { params: Promise<{ id: string }> };

export async function POST(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    getStore().setEngagement(id, actorUsername(request), "like", true);
    return noContent();
  });
}

export async function DELETE(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    getStore().setEngagement(id, actorUsername(request), "like", false);
    return noContent();
  });
}
