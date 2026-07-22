"use client";

// CaptureOptionCard — design.md §8.2b: mode photo-upload / manual-entry —
// the vault "Retake" options (pages.md B4 header; phone hand-off QR was cut
// from scope; the webcam flow was removed per M-12 — web capture is
// upload-only, mode renamed webcam-upload → photo-upload).
import clsx from "clsx";
import { Camera, ChevronRight, PencilRuler } from "lucide-react";

export type CaptureOptionMode = "photo-upload" | "manual-entry";

export interface CaptureOptionCardProps {
  mode: CaptureOptionMode;
  /**
   * Title override — the photo-upload master's title is per-platform
   * ("Use your camera" on mobile C7, upload phrasing on web B4); the
   * marketing thumbs depicting the mobile app pass the mobile string.
   */
  title?: string;
  onClick?: () => void;
  className?: string;
}

// Figma masters (66:721) carry the canonical copy; the photo-upload title
// is the web B4 upload phrasing (the master's "Use your camera" is the
// mobile C7 string — per-platform override recorded in the canvas ledger).
const OPTION_COPY: Record<CaptureOptionMode, { title: string; body: string }> =
  {
    "photo-upload": {
      title: "Upload photos",
      body: "Two photos — we measure automatically",
    },
    "manual-entry": {
      title: "Enter manually",
      body: "Tape-measure your key metrics",
    },
  };

export function CaptureOptionCard({
  mode,
  title,
  onClick,
  className,
}: CaptureOptionCardProps) {
  const copy = OPTION_COPY[mode];
  const cardTitle = title ?? copy.title;
  const Icon = mode === "photo-upload" ? Camera : PencilRuler;
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
        <span className="text-body font-semibold text-text">{cardTitle}</span>
        <span className="text-caption text-text-2">{copy.body}</span>
      </span>
      <ChevronRight size={16} className="shrink-0 text-text-2" aria-hidden />
    </button>
  );
}
