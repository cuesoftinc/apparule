// Mock: POST /api/v1/me/deletion — "Delete all" with confirm (pages.md B7
// Account & data). Flags deletion_pending; the purge job is backend-side.
import { actorUsername, handle, jsonResponse } from "@/mocks/http";
import { getStore } from "@/mocks/store";

export async function POST(request: Request) {
  return handle(() =>
    jsonResponse(getStore().requestDeletion(actorUsername(request))),
  );
}
