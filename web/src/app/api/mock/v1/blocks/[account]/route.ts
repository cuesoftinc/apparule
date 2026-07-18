// Mock: POST/DELETE /api/v1/blocks/{account} — silent (data-model §6.2).
import { actorUsername, handle, noContent } from "@/mocks/http";
import { getStore } from "@/mocks/store";

type Params = { params: Promise<{ account: string }> };

export async function POST(request: Request, { params }: Params) {
  return handle(async () => {
    const { account } = await params;
    getStore().setBlock(actorUsername(request), account, true);
    return noContent();
  });
}

export async function DELETE(request: Request, { params }: Params) {
  return handle(async () => {
    const { account } = await params;
    getStore().setBlock(actorUsername(request), account, false);
    return noContent();
  });
}
