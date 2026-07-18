// MEASUREMENT_SESSION / MEASUREMENT entities — data-model.md §2, flows/vault.md.

export type MeasurementMethod =
  | "mediapipe_2d"
  | "mediapipe_2d_v2"
  | "smpl_v1"
  | "manual";

export type SessionStatus = "pending_save" | "complete" | "failed";

export interface Measurement {
  id: string;
  session_id: string;
  /** Open vocabulary: shoulder_width | hip_width | chest_girth | … */
  name: string;
  value_cm: number;
  source: "pipeline" | "manual_correction";
  confidence: number | null;
}

export interface MeasurementSession {
  id: string;
  customer_id: string;
  method: MeasurementMethod;
  input_height_cm: number;
  status: SessionStatus;
  measurements: Measurement[];
  pipeline_meta: Record<string, unknown>;
  created_at: string;
}

/** Freshness bands for MI-11 (gradient <30d, amber 30–90d, gray >90d). */
export type Freshness = "fresh" | "aging" | "stale";

export function freshnessOf(
  measuredAt: string,
  now: Date = new Date(),
): Freshness {
  const ageDays =
    (now.getTime() - new Date(measuredAt).getTime()) / (1000 * 60 * 60 * 24);
  if (ageDays < 30) return "fresh";
  if (ageDays <= 90) return "aging";
  return "stale";
}
