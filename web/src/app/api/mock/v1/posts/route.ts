// Mock: POST /api/v1/posts — designer, KYC-gated (api.md §5).
import { actorUsername, handle, jsonResponse, readJson } from "@/mocks/http";
import { getStore } from "@/mocks/store";

interface PostBody {
  caption?: string;
  style_tags?: string[];
  base_price_cents?: number | null;
  turnaround_days?: number;
  media?: { url: string; alt_text: string }[];
}

export async function POST(request: Request) {
  return handle(async () => {
    const body = await readJson<PostBody>(request);
    const post = getStore().createPost(actorUsername(request), {
      caption: body.caption ?? "",
      style_tags: body.style_tags ?? [],
      base_price_cents: body.base_price_cents ?? null,
      turnaround_days: body.turnaround_days ?? 14,
      media: body.media ?? [],
    });
    return jsonResponse(post, 201);
  });
}
