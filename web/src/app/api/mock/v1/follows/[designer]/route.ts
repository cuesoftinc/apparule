// Mock: POST/DELETE /api/v1/follows/{designer} — idempotent (MI-7).
import { actorUsername, handle, noContent } from "@/mocks/http";
import { getStore } from "@/mocks/store";

type Params = { params: Promise<{ designer: string }> };

export async function POST(request: Request, { params }: Params) {
  return handle(async () => {
    const { designer } = await params;
    getStore().setFollow(actorUsername(request), designer, true);
    return noContent();
  });
}

export async function DELETE(request: Request, { params }: Params) {
  return handle(async () => {
    const { designer } = await params;
    getStore().setFollow(actorUsername(request), designer, false);
    return noContent();
  });
}
