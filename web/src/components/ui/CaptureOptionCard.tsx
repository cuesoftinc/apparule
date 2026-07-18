"use client";

// CaptureOptionCard — design.md §8.2b: mode webcam-upload / manual-entry —
// the vault "Retake" options (pages.md B4 header; phone hand-off QR was cut
// from scope).
import clsx from "clsx";
import { Camera, ChevronRight, PencilRuler } from "lucide-react";

export type CaptureOptionMode = "webcam-upload" | "manual-entry";

export interface CaptureOptionCardProps {
  mode: CaptureOptionMode;
  onClick?: () => void;
  className?: string;
}

// Figma masters (66:721) carry the canonical copy.
const OPTION_COPY: Record<
  CaptureOptionMode,
  { title: string; body: string }
> = {
  "webcam-upload": {
    title: "Use your camera",
    body: "Full-body photo, we measure automatically",
  },
  "manual-entry": {
    title: "Enter manually",
    body: "Tape-measure your key metrics",
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
      {/* Figma master: soft accent-tint disc with an accent glyph */}
      <span className="grid size-10 shrink-0 place-items-center rounded-pill bg-accent-start/12 text-accent-start">
        <Icon size={20} aria-hidden="true" />
      </span>
      <span className="flex min-w-0 flex-1 flex-col gap-0.5">
        <span className="text-body font-semibold text-text">{copy.title}</span>
        <span className="text-caption text-text-2">{copy.body}</span>
      </span>
      <ChevronRight size={16} className="shrink-0 text-text-2" aria-hidden />
    </button>
  );
}
