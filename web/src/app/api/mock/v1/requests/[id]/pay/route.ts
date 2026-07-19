// Mock: POST /api/v1/requests/{id}/pay — escrow hold lands immediately in
// the mock (no provider redirect); Idempotency-Key honored.
import { actorUsername, handle, jsonResponse } from "@/mocks/http";
import { getStore } from "@/mocks/store";

type Params = { params: Promise<{ id: string }> };

export async function POST(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    const store = getStore();
    const actor = actorUsername(request);
    const key = request.headers.get("idempotency-key");
    const order = store.idempotent(
      key ? `${actor}:POST/requests/${id}/pay:${key}` : null,
      "{}",
      () => store.pay(id, actor),
    );
    return jsonResponse(order);
  });
}
