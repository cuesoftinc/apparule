// Mock: GET /api/v1/feed — followed + recency-ranked (api.md §5), cursor
// pages served from a rank snapshot frozen per scroll session ([Decided]
// ranked pagination — never duplicates or skips mid-scroll).
import { actorUsername, handle, jsonResponse, parseLimit } from "@/mocks/http";
import { getStore } from "@/mocks/store";

export async function GET(request: Request) {
  return handle(() => {
    const url = new URL(request.url);
    const actor = actorUsername(request);
    const store = getStore();
    return jsonResponse(
      store.rankedPage(
        actor,
        "feed",
        () => store.feed(actor),
        url.searchParams.get("cursor"),
        parseLimit(url),
      ),
    );
  });
}
