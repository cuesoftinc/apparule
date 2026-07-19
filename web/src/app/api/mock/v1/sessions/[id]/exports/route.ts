// Mock: POST /api/v1/sessions/{id}/exports — pdf/csv export → signed URL
// (api.md §2, PLAT-004). The mock returns an inline data URL.
import {
  actorUsername,
  handle,
  jsonResponse,
  readJson,
} from "@/mocks/http";
import { getStore } from "@/mocks/store";

type Params = { params: Promise<{ id: string }> };

export async function POST(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    const body = await readJson<{ format?: "csv" | "pdf" }>(request);
    return jsonResponse(
      getStore().sessionExport(id, actorUsername(request), body.format ?? "csv"),
      201,
    );
  });
}
