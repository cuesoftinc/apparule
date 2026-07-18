// Mock: GET /api/v1/designer/earnings — balance + payout history (pages.md
// B9). Use `x-mock-actor: <designer username>` to view a seeded designer's
// earnings (e.g. maisonbisi has a released payout for #APR-1058).
import { actorUsername, handle, jsonResponse } from "@/mocks/http";
import { getStore } from "@/mocks/store";

export async function GET(request: Request) {
  return handle(() =>
    jsonResponse(getStore().earnings(actorUsername(request))),
  );
}
