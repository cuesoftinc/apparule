// Mock: GET/POST /api/v1/requests/{id}/messages — order thread (≤1000
// chars, images only as attachments; order-lifecycle §5).
import {
  actorUsername,
  handle,
  jsonResponse,
  paginate,
  readJson,
} from "@/mocks/http";
import { getStore } from "@/mocks/store";

type Params = { params: Promise<{ id: string }> };

export async function GET(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    const messages = getStore().messagesFor(id, actorUsername(request));
    return jsonResponse(paginate(messages, new URL(request.url)));
  });
}

export async function POST(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    const body = await readJson<{ body?: string; image_url?: string | null }>(
      request,
    );
    const message = getStore().addMessage(
      id,
      actorUsername(request),
      body.body ?? "",
      body.image_url ?? null,
    );
    return jsonResponse(message, 201);
  });
}
