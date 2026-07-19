// Mock: POST /api/v1/sessions/{id}/exports — pdf/csv export → signed URL
// (api.md §2, PLAT-004). The mock returns an inline data URL.
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
    const body = await readJson<{ format?: string }>(request);
    const format = body.format ?? "csv";
    if (format !== "csv" && format !== "pdf") {
      throw new MockApiError(
        "validation_failed",
        "format must be csv or pdf",
        422,
      );
    }
    return jsonResponse(
      getStore().sessionExport(id, actorUsername(request), format),
      201,
    );
  });
}
