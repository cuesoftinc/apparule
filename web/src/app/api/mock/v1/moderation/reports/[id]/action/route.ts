// Mock: POST /api/v1/moderation/reports/{id}/action — hide_post |
// suspend_account | dismiss (A-6; audit via actioned_by).
import {
  actorUsername,
  handle,
  jsonResponse,
  MockApiError,
  readJson,
} from "@/mocks/http";
import { getStore } from "@/mocks/store";
import type { ModerationAction } from "@/models";

type Params = { params: Promise<{ id: string }> };

const ACTIONS: ModerationAction[] = ["hide_post", "suspend_account", "dismiss"];

export async function POST(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    const body = await readJson<{ action?: ModerationAction }>(request);
    if (!body.action || !ACTIONS.includes(body.action)) {
      throw new MockApiError(
        "validation_failed",
        "action must be hide_post, suspend_account or dismiss",
        422,
      );
    }
    return jsonResponse(
      getStore().actOnReport(id, actorUsername(request), body.action),
    );
  });
}
