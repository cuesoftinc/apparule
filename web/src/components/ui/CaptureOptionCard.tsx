"use client";

// CaptureOptionCard — design.md §8.2b: mode webcam-upload / manual-entry —
// the vault "Retake" options (pages.md B4 header; phone hand-off QR was cut
// from scope).
import clsx from "clsx";
import { Camera, PencilRuler } from "lucide-react";

export type CaptureOptionMode = "webcam-upload" | "manual-entry";

export interface CaptureOptionCardProps {
  mode: CaptureOptionMode;
  onClick?: () => void;
  className?: string;
}

const OPTION_COPY: Record<
  CaptureOptionMode,
  { title: string; body: string }
> = {
  "webcam-upload": {
    title: "Webcam upload",
    body: "Two photos and your height — the AI does the rest.",
  },
  "manual-entry": {
    title: "Manual entry",
    body: "Tape-measure sliders and numeric input, cm or in.",
  },
};

export function CaptureOptionCard({ mode, onClick, className }: CaptureOptionCardProps) {
  const copy = OPTION_COPY[mode];
  const Icon = mode === "webcam-upload" ? Camera : PencilRuler;
  return (
    <button
      type="button"
      data-mode={mode}
      onClick={onClick}
      className={clsx(
        "flex items-center gap-4 rounded-card border border-border bg-bg-elev p-4 text-left",
        "transition-transform duration-120 ease-standard active:scale-[0.99] hover:border-text-2/40",
        "motion-reduce:transition-none motion-reduce:active:scale-100",
        className,
      )}
    >
      <span className="grid size-11 shrink-0 place-items-center rounded-pill bg-accent-gradient text-on-accent">
        <Icon size={24} aria-hidden="true" />
      </span>
      <span className="flex min-w-0 flex-col gap-0.5">
        <span className="text-body-lg font-semibold text-text">{copy.title}</span>
        <span className="text-body text-text-2">{copy.body}</span>
      </span>
    </button>
  );
}
