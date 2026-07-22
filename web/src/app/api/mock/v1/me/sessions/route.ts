// Mock: GET/POST /api/v1/me/sessions — the vault IS the self-customer's
// sessions (data-model §6.1). POST accepts JSON manual sessions (web manual
// entry, MI-13 — no height: input_height_cm is null for method manual) or
// multipart two-photo uploads (B4 upload path, M-10/M-12: image_front +
// image_side + input_height_cm; per-pose QC failure codes reproducible via
// designated fixture file names); Idempotency-Key honored (flows/vault.md
// upload contract — both images ride one request with one key).
import {
  actorUsername,
  handle,
  jsonResponse,
  MockApiError,
  paginate,
  readJson,
} from "@/mocks/http";
import { getStore } from "@/mocks/store";

export async function GET(request: Request) {
  return handle(() => {
    const sessions = getStore().sessionsFor(actorUsername(request));
    return jsonResponse(paginate(sessions, new URL(request.url)));
  });
}

interface ManualBody {
  method?: string;
  measurements?: { name: string; value_cm: number }[];
}

export async function POST(request: Request) {
  return handle(async () => {
    const store = getStore();
    const actor = actorUsername(request);
    const key = request.headers.get("idempotency-key");

    // Two-photo upload path — multipart image_front + image_side +
    // input_height_cm (api.md §2, M-10).
    if (request.headers.get("content-type")?.includes("multipart/form-data")) {
      const form = await request.formData().catch(() => {
        throw new MockApiError(
          "validation_failed",
          "Body must be multipart form data",
          422,
        );
      });
      const imageFront = form.get("image_front");
      const imageSide = form.get("image_side");
      if (!(imageFront instanceof File) || !(imageSide instanceof File)) {
        throw new MockApiError(
          "validation_failed",
          "image_front and image_side files are required",
          422,
        );
      }
      const height = Number(form.get("input_height_cm"));
      const session = store.idempotent(
        key ? `${actor}:POST/me/sessions:${key}` : null,
        `${imageFront.name}:${imageSide.name}:${height}`,
        () =>
          store.createCaptureSession(actor, {
            input_height_cm: height,
            filenameFront: imageFront.name,
            filenameSide: imageSide.name,
          }),
      );
      return jsonResponse(session, 201);
    }

    const body = await readJson<ManualBody>(request);
    const session = store.idempotent(
      key ? `${actor}:POST/me/sessions:${key}` : null,
      JSON.stringify(body),
      () =>
        store.createManualSession(actor, {
          measurements: body.measurements ?? [],
        }),
    );
    return jsonResponse(session, 201);
  });
}
