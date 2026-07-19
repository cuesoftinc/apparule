// Mock: POST /api/v1/requests/{id}/quote — designer quotes (7d expiry).
import {
  actorUsername,
  handle,
  jsonResponse,
  MockApiError,
  readJson,
} from "@/mocks/http";
import { getStore } from "@/mocks/store";

type Params = { params: Promise<{ id: string }> };

export async function POST(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    const body = await readJson<{ quote_cents?: number; due_at?: string }>(
      request,
    );
    if (!body.quote_cents || !body.due_at) {
      throw new MockApiError(
        "validation_failed",
        "quote_cents and due_at are required",
        422,
      );
    }
    return jsonResponse(
      getStore().quote(
        id,
        actorUsername(request),
        body.quote_cents,
        body.due_at,
      ),
    );
  });
}
