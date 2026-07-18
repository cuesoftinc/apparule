// Mock: POST /api/v1/requests/{id}/dispute — either party; freezes payout.
import {
  actorUsername,
  handle,
  jsonResponse,
  MockApiError,
  readJson,
} from "@/mocks/http";
import { getStore } from "@/mocks/store";
import type { DisputeReason } from "@/models";

type Params = { params: Promise<{ id: string }> };

const REASONS: DisputeReason[] = [
  "not_received",
  "not_as_described",
  "size_wrong",
  "other",
];

export async function POST(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    const body = await readJson<{ reason?: DisputeReason; detail?: string }>(
      request,
    );
    if (!body.reason || !REASONS.includes(body.reason)) {
      throw new MockApiError(
        "validation_failed",
        "A valid dispute reason is required",
        422,
      );
    }
    return jsonResponse(
      getStore().dispute(id, actorUsername(request), body.reason, body.detail),
    );
  });
}
