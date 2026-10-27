// Measurement vault repository — api.md §2 (self-customer alias routes,
// data-model §6.1: the vault IS the self-customer's sessions).
import { env } from "@/config/env";
import { ApiError, apiFetch, type Page } from "@/lib/api";
import type { Measurement, MeasurementSession } from "../entities/measurement";
import { pollUntil, uploadWithTicket, type UploadTicket } from "./upload";

/** api/common's answer to a capture create or a retake ticket (§6.1). */
interface CaptureStarted extends MeasurementSession {
  upload: UploadTicket;
}

/** A capture still being measured, as GET /sessions/{id} reports it. */
interface CaptureStatus extends Omit<MeasurementSession, "status"> {
  status:
    | MeasurementSession["status"]
    | "awaiting_upload"
    | "processing"
    | "failed_qc";
  qc?: {
    code: string;
    pose: "front" | "side";
    message: string;
    guidance: string;
  };
  error_code?: string;
}

/**
 * The session whose last attempt failed QC: the next upload retakes only its
 * failing pose (flows/vault.md §1: an accepted pose is never re-sent).
 */
let retake: { sessionId: string; pose: "front" | "side" } | null = null;

const MEASURED = new Set(["pending_save", "complete", "failed_qc", "failed"]);

async function captureOnBackend(
  imageFront: File,
  imageSide: File,
  inputHeightCm: number,
  idempotencyKey: string,
): Promise<MeasurementSession> {
  let started: CaptureStarted | null = null;
  let files: [string, File][] = [
    ["image_front", imageFront],
    ["image_side", imageSide],
  ];
  if (retake) {
    const { sessionId, pose } = retake;
    started = await apiFetch<CaptureStarted>(
      `/v1/sessions/${sessionId}/poses/${pose}/ticket`,
      {
        method: "POST",
      },
    ).catch(() => null); // expired or gone: start over with both photos
    if (started) files = files.filter(([field]) => field === `image_${pose}`);
  }
  retake = null;
  if (!started) {
    started = await apiFetch<CaptureStarted>("/v1/me/sessions", {
      method: "POST",
      json: { method: "capture", input_height_cm: inputHeightCm },
      headers: { "Idempotency-Key": idempotencyKey },
    });
  }
  await uploadWithTicket(started.upload, files);
  const id = started.id;
  const result = await pollUntil(
    () => apiFetch<CaptureStatus>(`/v1/sessions/${id}`),
    (s) => MEASURED.has(s.status),
  );
  if (result.status === "failed_qc" && result.qc) {
    // The same 422 shape the mock answers with, so use-capture is unchanged.
    retake = { sessionId: id, pose: result.qc.pose };
    throw new ApiError(result.qc.code, result.qc.guidance, 422, {
      guidance: result.qc.guidance,
      pose: result.qc.pose,
    });
  }
  if (result.status !== "pending_save" && result.status !== "complete") {
    throw new ApiError(
      "pipeline_busy",
      "Measuring took too long — try again",
      503,
    );
  }
  return result as MeasurementSession;
}

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
   * Two-photo upload capture (B4, M-10/M-12). Resolves a `pending_save`
   * session with per-measurement confidence; QC failures surface as 422
   * with the capture-qc.md code + guidance + failing pose (per-pose QC).
   *
   * TEST_MODE: one multipart POST to the mock. Real backend (§6.1): create
   * the session (JSON + Idempotency-Key) → upload both photos to api/uploads
   * with its ticket → poll until measured; after a QC failure the next call
   * retakes only the failing pose with a per-pose ticket.
   */
  createCaptureSession: (
    imageFront: File,
    imageSide: File,
    inputHeightCm: number,
    idempotencyKey: string,
  ) => {
    if (!env.testMode) {
      return captureOnBackend(
        imageFront,
        imageSide,
        inputHeightCm,
        idempotencyKey,
      );
    }
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
