// Mock: GET /api/v1/requests/{id} — party-only; others get 404.
import { actorUsername, handle, jsonResponse } from "@/mocks/http";
import { getStore } from "@/mocks/store";

type Params = { params: Promise<{ id: string }> };

export async function GET(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    return jsonResponse(getStore().order(id, actorUsername(request)));
  });
}
