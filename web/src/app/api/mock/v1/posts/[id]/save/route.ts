// Mock: POST/DELETE /api/v1/posts/{id}/save — idempotent toggle (MI-3/MI-18).
import { actorUsername, handle, noContent } from "@/mocks/http";
import { getStore } from "@/mocks/store";

type Params = { params: Promise<{ id: string }> };

export async function POST(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    getStore().setEngagement(id, actorUsername(request), "save", true);
    return noContent();
  });
}

export async function DELETE(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    getStore().setEngagement(id, actorUsername(request), "save", false);
    return noContent();
  });
}
