// QCHintChip — design.md §8.2b: code ×12, one actionable guidance line each.
// Fail codes from capture-qc.md §1–2 (per-pose QC, M-10: the side pose adds
// `not_side_profile` and swaps the `arms_position` copy); canonical retake
// copy from the flows/vault.md QC-failures row (the same strings the 422
// envelope carries).
import clsx from "clsx";
import { Camera, Ruler, Search, User, X, type LucideIcon } from "lucide-react";

export type QcFailCode =
  | "no_body"
  | "multiple_bodies"
  | "partial_body"
  | "undecodable_image"
  | "low_resolution"
  | "poor_lighting"
  | "blurry"
  | "not_frontal"
  | "not_side_profile"
  | "camera_tilt"
  | "arms_position"
  | "too_far";

/** Canonical guidance copy — flows/vault.md QC-failures row, verbatim. */
export const QC_GUIDANCE: Record<QcFailCode, string> = {
  no_body: "Make sure your whole body is visible",
  multiple_bodies: "Make sure you're alone in frame",
  partial_body: "Include head to ankles",
  undecodable_image: "That image couldn't be read — try another photo",
  low_resolution: "Move closer or use a higher-quality camera",
  poor_lighting: "Find better lighting — avoid strong backlight",
  blurry: "Hold steady and retake",
  not_frontal: "Face the camera straight on",
  not_side_profile: "Turn your right side to the camera",
  camera_tilt: "Hold the phone upright",
  arms_position: "Keep arms slightly away from your body",
  too_far: "Move closer — fill more of the frame",
};

/**
 * Side-pose copy deltas (capture-qc.md §2 pose-2 table): `arms_position`
 * guidance is per pose — arms hang relaxed on the side pose.
 */
export const QC_GUIDANCE_SIDE: Partial<Record<QcFailCode, string>> = {
  arms_position: "Let your arms hang relaxed at your sides",
};

/** The pose-aware guidance line (flows/vault.md: arms copy is per pose). */
export function qcGuidance(
  code: QcFailCode,
  pose: "front" | "side" = "front",
): string {
  return (pose === "side" && QC_GUIDANCE_SIDE[code]) || QC_GUIDANCE[code];
}

/** Figma masters (62:634): the leading glyph names the failure family. */
const QC_ICON: Record<QcFailCode, LucideIcon> = {
  no_body: User,
  multiple_bodies: User,
  partial_body: Ruler,
  undecodable_image: X,
  low_resolution: Camera,
  poor_lighting: Camera,
  blurry: Camera,
  not_frontal: User,
  not_side_profile: User,
  camera_tilt: Camera,
  arms_position: User,
  too_far: Search,
};

export interface QCHintChipProps {
  code: QcFailCode;
  /** Failing pose — selects the per-pose copy (default front). */
  pose?: "front" | "side";
  className?: string;
}

export function QCHintChip({
  code,
  pose = "front",
  className,
}: QCHintChipProps) {
  const Icon = QC_ICON[code];
  return (
    <span
      role="status"
      data-code={code}
      className={clsx(
        // Figma master (62:634): inverse surface — text-token bg, bg-token
        // content (same technique as Toast), 13px semibold.
        "inline-flex max-w-full items-center gap-2 rounded-pill bg-text px-3 py-2 text-caption font-semibold text-bg drop-shadow-[0_4px_6px_rgba(0,0,0,0.25)]",
        className,
      )}
    >
      <Icon size={16} className="shrink-0" aria-hidden />
      <span className="truncate">{qcGuidance(code, pose)}</span>
    </span>
  );
}
