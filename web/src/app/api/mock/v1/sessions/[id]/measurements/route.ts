// Mock: PATCH /api/v1/sessions/{id}/measurements — append-only manual
// corrections (source: manual_correction).
import {
  actorUsername,
  handle,
  jsonResponse,
  MockApiError,
  readJson,
} from "@/mocks/http";
import { getStore } from "@/mocks/store";

type Params = { params: Promise<{ id: string }> };

export async function PATCH(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    const body = await readJson<{
      measurements?: { name: string; value_cm: number }[];
    }>(request);
    if (!body.measurements || body.measurements.length === 0) {
      throw new MockApiError(
        "validation_failed",
        "measurements[] is required",
        422,
      );
    }
    return jsonResponse(
      getStore().appendCorrections(
        id,
        actorUsername(request),
        body.measurements,
      ),
    );
  });
}
