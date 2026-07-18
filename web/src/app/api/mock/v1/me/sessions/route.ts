// Mock: GET/POST /api/v1/me/sessions — the vault IS the self-customer's
// sessions (data-model §6.1). POST accepts JSON manual sessions (web manual
// entry, MI-13); Idempotency-Key honored (flows/vault.md upload contract).
import {
  actorUsername,
  handle,
  jsonResponse,
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
    const body = await readJson<ManualBody>(request);
    const store = getStore();
    const actor = actorUsername(request);
    const key = request.headers.get("idempotency-key");
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
