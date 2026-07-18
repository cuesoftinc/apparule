// Mock: GET/POST /api/v1/posts/{id}/comments (body ≤500 chars).
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
    const comments = getStore().commentsFor(id);
    return jsonResponse(paginate(comments, new URL(request.url)));
  });
}

export async function POST(request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    const body = await readJson<{ body?: string }>(request);
    const comment = getStore().addComment(
      id,
      actorUsername(request),
      body.body ?? "",
    );
    return jsonResponse(comment, 201);
  });
}
