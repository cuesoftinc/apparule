// Mock: POST /api/v1/posts/{id}/requests — commission request, snapshot
// frozen server-side; Idempotency-Key honored (api.md §4).
import {
  actorUsername,
  handle,
  jsonResponse,
  readJson,
} from "@/mocks/http";
import { getStore } from "@/mocks/store";
import type { DeliveryAddress } from "@/models";

type Params = { params: Promise<{ id: string }> };

interface RequestBody {
  session_id?: string;
  notes?: string;
  budget_cents?: number;
  target_date?: string;
  delivery?: DeliveryAddress;
}

export async function POST(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    const body = await readJson<RequestBody>(request);
    const store = getStore();
    const actor = actorUsername(request);
    const key = request.headers.get("idempotency-key");
    const order = store.idempotent(
      key ? `${actor}:POST/posts/${id}/requests:${key}` : null,
      JSON.stringify(body),
      () =>
        store.createRequest(actor, id, {
          session_id: body.session_id ?? "",
          notes: body.notes,
          budget_cents: body.budget_cents,
          target_date: body.target_date,
          delivery: body.delivery as DeliveryAddress,
        }),
    );
    return jsonResponse(order, 201);
  });
}
