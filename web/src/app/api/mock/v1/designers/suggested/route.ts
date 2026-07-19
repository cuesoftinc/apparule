// Mock: GET /api/v1/designers/suggested — B1 right-column suggestions
// (designers the viewer doesn't follow yet).
import { actorUsername, handle, jsonResponse, paginate } from "@/mocks/http";
import { getStore } from "@/mocks/store";

export async function GET(request: Request) {
  return handle(() => {
    const rows = getStore().suggestedDesigners(actorUsername(request));
    return jsonResponse(paginate(rows, new URL(request.url)));
  });
}
