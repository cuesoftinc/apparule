// Measurement vault repository — api.md §2 (self-customer alias routes,
// data-model §6.1: the vault IS the self-customer's sessions).
import { apiFetch, type Page } from "@/lib/api";
import type { Measurement, MeasurementSession } from "../entities/measurement";

export interface ManualSessionCreate {
  method: "manual";
  // No height field: manual sessions carry `input_height_cm: null`
  // (flows/vault.md §2 — height is a capture-pipeline input).
  measurements: { name: string; value_cm: number }[];
}

export const vaultRepo = {
  /** GET /api/v1/me/sessions — own measurement history. */
  sessions: (cursor?: string) =>
    apiFetch<Page<MeasurementSession>>(
      `/v1/me/sessions${cursor ? `?cursor=${cursor}` : ""}`,
    ),

  /**
   * POST /api/v1/me/sessions — manual entry from the web vault (MI-13).
   * Photo-upload capture posts multipart to the same route; the mock
   * accepts JSON manual sessions (capture kit is mobile-first).
   */
  createManualSession: (input: ManualSessionCreate, idempotencyKey: string) =>
    apiFetch<MeasurementSession>("/v1/me/sessions", {
      method: "POST",
      json: input,
      headers: { "Idempotency-Key": idempotencyKey },
    }),

  /** GET /api/v1/sessions/{id} */
  session: (id: string) => apiFetch<MeasurementSession>(`/v1/sessions/${id}`),

  /** PATCH /api/v1/sessions/{id}/measurements — append-only corrections. */
  appendCorrections: (
    id: string,
    corrections: { name: string; value_cm: number }[],
  ) =>
    apiFetch<MeasurementSession>(`/v1/sessions/${id}/measurements`, {
      method: "PATCH",
      json: { measurements: corrections },
    }),

  /**
   * DELETE /api/v1/sessions/{id} — delete a session from the history sheet
   * (pages.md B4). Not yet in openapi.yaml; mock implements it ahead of the
   * contract (deviation noted in the stage report).
   */
  deleteSession: (id: string) =>
    apiFetch<void>(`/v1/sessions/${id}`, { method: "DELETE" }),

  /**
   * POST /api/v1/me/sessions (multipart) — two-photo upload capture (B4,
   * M-10/M-12): `image_front` + `image_side` + height ride one request with
   * one Idempotency-Key. Returns a `pending_save` session with
   * per-measurement confidence; QC failures surface as 422 with the
   * capture-qc.md code + guidance + failing pose (per-pose QC).
   */
  createCaptureSession: (
    imageFront: File,
    imageSide: File,
    inputHeightCm: number,
    idempotencyKey: string,
  ) => {
    const form = new FormData();
    form.set("image_front", imageFront);
    form.set("image_side", imageSide);
    form.set("input_height_cm", String(inputHeightCm));
    return apiFetch<MeasurementSession>("/v1/me/sessions", {
      method: "POST",
      body: form,
      headers: { "Idempotency-Key": idempotencyKey },
    });
  },

  /** POST /api/v1/sessions/{id}/save — pending_save → complete. */
  saveSession: (id: string) =>
    apiFetch<MeasurementSession>(`/v1/sessions/${id}/save`, {
      method: "POST",
    }),

  /** POST /api/v1/sessions/{id}/exports — pdf/csv → signed URL (PLAT-004). */
  exportSession: (id: string, format: "csv" | "pdf" = "csv") =>
    apiFetch<{ url: string; format: string }>(`/v1/sessions/${id}/exports`, {
      method: "POST",
      json: { format },
    }),
};

/** Latest value per measurement name across complete sessions (vault grid). */
export function latestMeasurements(
  sessions: MeasurementSession[],
): Measurement[] {
  const byName = new Map<string, Measurement>();
  const ordered = [...sessions]
    .filter((s) => s.status === "complete")
    .sort(
      (a, b) =>
        new Date(a.created_at).getTime() - new Date(b.created_at).getTime(),
    );
  for (const session of ordered) {
    for (const m of session.measurements) {
      byName.set(m.name, m);
    }
  }
  return [...byName.values()];
}
