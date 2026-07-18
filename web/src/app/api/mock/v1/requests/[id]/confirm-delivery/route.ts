// Mock: POST /api/v1/requests/{id}/confirm-delivery — customer confirms,
// payout releases (quote − 10% fee, A-1).
import { actorUsername, handle, jsonResponse } from "@/mocks/http";
import { getStore } from "@/mocks/store";

type Params = { params: Promise<{ id: string }> };

export async function POST(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    return jsonResponse(getStore().confirmDelivery(id, actorUsername(request)));
  });
}
