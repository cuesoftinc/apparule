// Mock: GET /api/v1/explore?q&tags&price_band&max_turnaround_days&near_me
// (api.md §5 — bands: budget <25k, mid 25–100k, premium >100k NGN;
// max_turnaround_days + near_me are the 2026-07-19 filter-chip extension —
// near_me proximity-ranks by designer profile_location vs the caller's).
import { actorUsername, handle, jsonResponse, parseLimit } from "@/mocks/http";
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
    const turnaroundRaw = Number(
      url.searchParams.get("max_turnaround_days") ?? "",
    );
    const maxTurnaroundDays =
      Number.isFinite(turnaroundRaw) && turnaroundRaw > 0
        ? Math.floor(turnaroundRaw)
        : undefined;
    const nearRaw = url.searchParams.get("near_me");
    const nearMe = nearRaw === "1" || nearRaw === "true";
    const actor = actorUsername(request);
    const store = getStore();
    // Ranked endpoint — cursor pages come from a frozen rank snapshot
    // ([Decided] ranked pagination), same as /feed.
    return jsonResponse(
      store.rankedPage(
        actor,
        () => store.explore(actor, q, tags, priceBand, maxTurnaroundDays, nearMe),
        url.searchParams.get("cursor"),
        parseLimit(url),
      ),
    );
  });
}
