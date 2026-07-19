// Mock: GET/DELETE /api/v1/posts/{id} (public permalink /p/{id}).
import { actorUsername, handle, jsonResponse, noContent } from "@/mocks/http";
import { getStore } from "@/mocks/store";

type Params = { params: Promise<{ id: string }> };

export async function GET(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    return jsonResponse(getStore().post(id, actorUsername(request)));
  });
}

export async function DELETE(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    getStore().deletePost(id, actorUsername(request));
    return noContent();
  });
}
