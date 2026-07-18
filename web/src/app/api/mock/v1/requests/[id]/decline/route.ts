// Mock: POST /api/v1/requests/{id}/decline — reason required
// (flows/designer.md §2; decline sheet pages.md B3).
import {
  actorUsername,
  handle,
  jsonResponse,
  MockApiError,
  readJson,
} from "@/mocks/http";
import { getStore } from "@/mocks/store";
import type { DeclineReason } from "@/models";

type Params = { params: Promise<{ id: string }> };

export async function POST(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    const body = await readJson<{ reason?: DeclineReason; note?: string }>(
      request,
    );
    if (!body.reason) {
      throw new MockApiError(
        "validation_failed",
        "Decline reason is required",
        422,
      );
    }
    return jsonResponse(
      getStore().decline(id, actorUsername(request), body.reason),
    );
  });
}
