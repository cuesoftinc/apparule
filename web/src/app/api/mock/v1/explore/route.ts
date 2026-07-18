// Mock: GET /api/v1/explore?q&tags&price_band (api.md §5 — bands: budget
// <25k, mid 25–100k, premium >100k NGN).
import { actorUsername, handle, jsonResponse, paginate } from "@/mocks/http";
import { getStore } from "@/mocks/store";

export async function GET(request: Request) {
  return handle(() => {
    const url = new URL(request.url);
    const q = url.searchParams.get("q") ?? undefined;
    const tags = url.searchParams.get("tags")?.split(",").filter(Boolean);
    const bandRaw = url.searchParams.get("price_band");
    const priceBand =
      bandRaw === "budget" || bandRaw === "mid" || bandRaw === "premium"
        ? bandRaw
        : undefined;
    const posts = getStore().explore(actorUsername(request), q, tags, priceBand);
    return jsonResponse(paginate(posts, url));
  });
}
