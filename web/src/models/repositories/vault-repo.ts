// Measurement vault repository — api.md §2 (self-customer alias routes,
// data-model §6.1: the vault IS the self-customer's sessions).
import { apiFetch, type Page } from "@/lib/api";
import type { Measurement, MeasurementSession } from "../entities/measurement";

export interface ManualSessionCreate {
  method: "manual";
  input_height_cm: number;
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
   * Webcam-upload capture posts multipart to the same route; the mock
   * accepts JSON manual sessions (capture kit is mobile-first).
   */
  createManualSession: (input: ManualSessionCreate, idempotencyKey: string) =>
    apiFetch<MeasurementSession>("/v1/me/sessions", {
      method: "POST",
      json: input,
      headers: { "Idempotency-Key": idempotencyKey },
    }),

  /** GET /api/v1/sessions/{id} */
  session: (id: string) =>
    apiFetch<MeasurementSession>(`/v1/sessions/${id}`),

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
