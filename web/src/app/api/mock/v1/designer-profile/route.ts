// Mock: POST /api/v1/designer-profile — enable + start KYC (flows/designer §1).
import {
  actorUsername,
  handle,
  jsonResponse,
  MockApiError,
  readJson,
} from "@/mocks/http";
import { getStore } from "@/mocks/store";

export async function POST(request: Request) {
  return handle(async () => {
    const body = await readJson<{ display_name?: string; bio?: string }>(
      request,
    );
    if (!body.display_name) {
      throw new MockApiError(
        "validation_failed",
        "display_name is required",
        422,
      );
    }
    return jsonResponse(
      getStore().enableDesigner(
        actorUsername(request),
        body.display_name,
        body.bio,
      ),
      201,
    );
  });
}
