// Mock: GET /api/v1/media/{id} — serves composer uploads back (the mock's
// stand-in for object-storage URLs).
import { NextResponse } from "next/server";
import { handle } from "@/mocks/http";
import { getStore } from "@/mocks/store";

type Params = { params: Promise<{ id: string }> };

export async function GET(_request: Request, { params }: Params) {
  return handle(async () => {
    const { id } = await params;
    const media = getStore().getMedia(id);
    return new NextResponse(Buffer.from(media.data, "base64"), {
      status: 200,
      headers: {
        "Content-Type": media.contentType,
        "Cache-Control": "no-store",
      },
    });
  });
}
