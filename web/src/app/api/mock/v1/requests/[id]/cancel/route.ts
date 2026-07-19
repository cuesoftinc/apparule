// Mock: POST /api/v1/requests/{id}/cancel — customer withdraws (requested)
// or rejects the quote (quoted), order-lifecycle.md §1. Not yet in api.md §5;
// mock-ahead-of-contract (stage-report deviation).
import { actorUsername, handle, jsonResponse } from "@/mocks/http";
import { getStore } from "@/mocks/store";

type Params = { params: Promise<{ id: string }> };

export async function POST(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    return jsonResponse(getStore().cancel(id, actorUsername(request)));
  });
}
