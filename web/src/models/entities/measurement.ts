// MEASUREMENT_SESSION / MEASUREMENT entities — data-model.md §2, flows/vault.md.

export type MeasurementMethod =
  "mediapipe_2d" | "mediapipe_2d_v2" | "smpl_v1" | "manual";

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
  /**
   * Nullable — null for `method: manual` (data-model.md §2, ruled
   * 2026-07-22): height is a capture-pipeline input, not a property of
   * tape values.
   */
  input_height_cm: number | null;
  status: SessionStatus;
  measurements: Measurement[];
  pipeline_meta: Record<string, unknown>;
  created_at: string;
}

/**
 * A-10 manual-entry template (decisions.md): selects which tailor-sourced
 * field set the manual sheet offers. Surfaced from the self CUSTOMER
 * (data-model.md §2). Templates the entry UI only — stored measurement
 * rows stay free-form open vocabulary.
 */
export type MeasurementTemplate = "women" | "men";

export interface ManualMetricSpec {
  readonly name: string;
  /** Advisory range in canonical cm — soft "double-check", never a block. */
  readonly min: number;
  readonly max: number;
}

/**
 * The canonical A-10 templates — flows/vault.md §2 [Decided 2026-07-25:
 * field list collected from a practicing Nigerian tailor]. The 7 measures
 * shared by both templates carry identical ranges. Labels render by
 * humanizing the snake_case name.
 */
export const MANUAL_TEMPLATES: Record<
  MeasurementTemplate,
  readonly ManualMetricSpec[]
> = {
  women: [
    { name: "shoulder", min: 30, max: 60 },
    { name: "bust", min: 60, max: 160 },
    { name: "under_bust", min: 55, max: 140 },
    { name: "bust_span", min: 12, max: 30 },
    { name: "waist", min: 50, max: 150 },
    { name: "shoulder_to_bust_point", min: 18, max: 40 },
    { name: "shoulder_to_under_bust", min: 25, max: 50 },
    { name: "shoulder_to_waist", min: 30, max: 60 },
    { name: "half_length", min: 30, max: 70 },
    { name: "waist_to_knee", min: 40, max: 75 },
    { name: "gown_length", min: 90, max: 170 },
    { name: "skirt_length", min: 40, max: 120 },
    { name: "trouser_length", min: 80, max: 120 },
    { name: "thigh", min: 40, max: 90 },
    { name: "knee", min: 25, max: 60 },
    { name: "sleeve_length", min: 15, max: 70 },
    { name: "sleeve_width", min: 20, max: 50 },
  ],
  men: [
    { name: "shoulder", min: 30, max: 60 },
    { name: "chest", min: 70, max: 160 },
    { name: "waist", min: 50, max: 150 },
    { name: "top_length", min: 55, max: 100 },
    { name: "thigh", min: 40, max: 90 },
    { name: "hip", min: 70, max: 160 },
    { name: "knee", min: 25, max: 60 },
    { name: "shin", min: 20, max: 50 },
    { name: "waist_to_knee", min: 40, max: 75 },
    { name: "trouser_length", min: 80, max: 120 },
    { name: "trouser_inseam", min: 60, max: 95 },
    { name: "biceps", min: 20, max: 50 },
    { name: "sleeve_length", min: 15, max: 70 },
    { name: "neck", min: 25, max: 55 },
  ],
};

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
