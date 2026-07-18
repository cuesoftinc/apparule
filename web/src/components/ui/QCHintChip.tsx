// QCHintChip — design.md §8.2b: code ×11, one actionable guidance line each.
// Fail codes from capture-qc.md §1–2; canonical retake copy from the
// flows/vault.md QC-failures row (the same strings the 422 envelope carries).
import clsx from "clsx";
import { AlertTriangle } from "lucide-react";

export type QcFailCode =
  | "no_body"
  | "multiple_bodies"
  | "partial_body"
  | "undecodable_image"
  | "low_resolution"
  | "poor_lighting"
  | "blurry"
  | "not_frontal"
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
  camera_tilt: "Hold the phone upright",
  arms_position: "Keep arms slightly away from your body",
  too_far: "Move closer — fill more of the frame",
};

export interface QCHintChipProps {
  code: QcFailCode;
  className?: string;
}

export function QCHintChip({ code, className }: QCHintChipProps) {
  return (
    <span
      role="status"
      data-code={code}
      className={clsx(
        // On-media capture UI — raw white on a dark scrim is the documented
        // token exception (web-implementation.md §3 note).
        "inline-flex max-w-full items-center gap-2 rounded-pill bg-black/70 px-4 py-2 text-body font-semibold text-white backdrop-blur-sm",
        className,
      )}
    >
      <AlertTriangle size={16} className="shrink-0 text-warn" />
      <span className="truncate">{QC_GUIDANCE[code]}</span>
    </span>
  );
}
