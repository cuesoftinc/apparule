// Mock: POST /api/v1/sessions/{id}/save — "Save to vault" flips a capture
// session pending_save → complete (flows/vault.md §1). Mock-ahead-of-contract.
import { actorUsername, handle, jsonResponse } from "@/mocks/http";
import { getStore } from "@/mocks/store";

type Params = { params: Promise<{ id: string }> };

export async function POST(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    return jsonResponse(getStore().saveSession(id, actorUsername(request)));
  });
}
