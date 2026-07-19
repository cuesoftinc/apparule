// Mock: GET /api/v1/me/export — "Download my data" (pages.md B7 Account &
// data; rights parity with expendit). Returns the full JSON export inline.
import { actorUsername, handle, jsonResponse } from "@/mocks/http";
import { getStore } from "@/mocks/store";

export async function GET(request: Request) {
  return handle(() =>
    jsonResponse(getStore().exportData(actorUsername(request))),
  );
}
