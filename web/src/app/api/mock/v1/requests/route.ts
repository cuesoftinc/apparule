// Mock: GET /api/v1/requests?role=customer|designer (api.md §5).
import { actorUsername, handle, jsonResponse, paginate } from "@/mocks/http";
import { getStore } from "@/mocks/store";

export async function GET(request: Request) {
  return handle(() => {
    const url = new URL(request.url);
    const role =
      url.searchParams.get("role") === "designer" ? "designer" : "customer";
    const orders = getStore().ordersFor(actorUsername(request), role);
    return jsonResponse(paginate(orders, url));
  });
}
