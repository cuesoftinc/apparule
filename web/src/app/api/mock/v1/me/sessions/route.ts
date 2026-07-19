// Mock: GET/POST /api/v1/me/sessions — the vault IS the self-customer's
// sessions (data-model §6.1). POST accepts JSON manual sessions (web manual
// entry, MI-13) or multipart image uploads (webcam capture path, B4 — QC
// failure codes reproducible via designated fixture file names);
// Idempotency-Key honored (flows/vault.md upload contract).
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
  input_height_cm?: number;
  measurements?: { name: string; value_cm: number }[];
}

export async function POST(request: Request) {
  return handle(async () => {
    const store = getStore();
    const actor = actorUsername(request);
    const key = request.headers.get("idempotency-key");

    // Webcam capture path — multipart image + input_height_cm (api.md §2).
    if (request.headers.get("content-type")?.includes("multipart/form-data")) {
      const form = await request.formData().catch(() => {
        throw new MockApiError(
          "validation_failed",
          "Body must be multipart form data",
          422,
        );
      });
      const image = form.get("image");
      if (!(image instanceof File)) {
        throw new MockApiError(
          "validation_failed",
          "image file is required",
          422,
        );
      }
      const height = Number(form.get("input_height_cm"));
      const session = store.idempotent(
        key ? `${actor}:POST/me/sessions:${key}` : null,
        `${image.name}:${height}`,
        () =>
          store.createCaptureSession(actor, {
            input_height_cm: height,
            filename: image.name,
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
          input_height_cm: body.input_height_cm ?? 0,
          measurements: body.measurements ?? [],
        }),
    );
    return jsonResponse(session, 201);
  });
}
