// Mock: GET /api/v1/designers?q= — designer search for the B2 explore
// search-results Designers section (UserRow list).
import { actorUsername, handle, jsonResponse, paginate } from "@/mocks/http";
import { getStore } from "@/mocks/store";

export async function GET(request: Request) {
  return handle(() => {
    const url = new URL(request.url);
    const q = url.searchParams.get("q") ?? "";
    const rows = getStore().searchDesigners(q, actorUsername(request));
    return jsonResponse(paginate(rows, url));
  });
}
