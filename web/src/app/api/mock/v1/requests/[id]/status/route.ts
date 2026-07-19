// Mock: POST /api/v1/requests/{id}/status — designer progress:
// in_progress | shipped only (delivered is customer/system-only).
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
    const body = await readJson<{ status?: string; tracking?: string }>(
      request,
    );
    if (body.status !== "in_progress" && body.status !== "shipped") {
      throw new MockApiError(
        "validation_failed",
        "status must be in_progress or shipped",
        422,
      );
    }
    return jsonResponse(
      getStore().setStatus(
        id,
        actorUsername(request),
        body.status,
        body.tracking,
      ),
    );
  });
}
