// Mock: GET/POST /api/v1/consent (api.md §2).
import {
  actorUsername,
  handle,
  jsonResponse,
  MockApiError,
  readJson,
} from "@/mocks/http";
import { getStore } from "@/mocks/store";

export async function GET(request: Request) {
  return handle(() =>
    jsonResponse(getStore().consentFor(actorUsername(request))),
  );
}

export async function POST(request: Request) {
  return handle(async () => {
    const body = await readJson<{ document?: string; version?: string }>(
      request,
    );
    if (
      (body.document !== "tos" && body.document !== "privacy") ||
      !body.version
    ) {
      throw new MockApiError(
        "validation_failed",
        "document (tos|privacy) and version are required",
        422,
      );
    }
    return jsonResponse(
      getStore().recordConsent(
        actorUsername(request),
        body.document,
        body.version,
      ),
      201,
    );
  });
}
