// Mock: POST /api/v1/media — composer image upload (multipart). Stands in
// for object storage: the store keeps bytes in memory and serves them back
// from GET /media/{id} so published posts render real uploads.
import { handle, jsonResponse, MockApiError } from "@/mocks/http";
import { getStore } from "@/mocks/store";

const MAX_BYTES = 10 * 1024 * 1024; // ≤10 MB per image (pages.md B5)
const ALLOWED = ["image/jpeg", "image/png", "image/webp"];

export async function POST(request: Request) {
  return handle(async () => {
    const form = await request.formData().catch(() => {
      throw new MockApiError(
        "validation_failed",
        "Body must be multipart form data",
        422,
      );
    });
    const file = form.get("image");
    if (!(file instanceof File)) {
      throw new MockApiError("validation_failed", "image file is required", 422);
    }
    if (!ALLOWED.includes(file.type)) {
      throw new MockApiError(
        "validation_failed",
        "Images must be JPEG, PNG, or WebP",
        422,
      );
    }
    if (file.size > MAX_BYTES) {
      throw new MockApiError("validation_failed", "Images must be ≤10 MB", 422);
    }
    const buffer = Buffer.from(await file.arrayBuffer());
    return jsonResponse(
      getStore().uploadMedia(buffer.toString("base64"), file.type),
      201,
    );
  });
}
