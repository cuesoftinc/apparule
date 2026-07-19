// Mock: GET /api/v1/sessions/{id} + DELETE (history-sheet delete, pages.md
// B4 — DELETE is ahead of openapi.yaml; noted as a stage deviation).
import { actorUsername, handle, jsonResponse, noContent } from "@/mocks/http";
import { getStore } from "@/mocks/store";

type Params = { params: Promise<{ id: string }> };

export async function GET(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    return jsonResponse(getStore().session(id, actorUsername(request)));
  });
}

export async function DELETE(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    getStore().deleteSession(id, actorUsername(request));
    return noContent();
  });
}
