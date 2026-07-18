"use client";

// CaptureResults — design.md §8.2b chrome: header (confidence summary) +
// MeasurementCard stagger list slot + "Save to vault" gradient / "Retake"
// quiet (pages.md C6). MI-12: results cards stagger-in 60ms apart;
// reduced motion renders them static.
import { Children, type ReactNode } from "react";
import clsx from "clsx";
import { Button } from "./Button";

export interface CaptureResultsProps {
  /** Per-measurement confidence values (capture-qc.md §4) for the summary. */
  confidences: number[];
  /** MeasurementCard instances — the stagger list slot. */
  children: ReactNode;
  onSave: () => void;
  onRetake: () => void;
  saving?: boolean;
  className?: string;
}

export function CaptureResults({
  confidences,
  children,
  onSave,
  onRetake,
  saving = false,
  className,
}: CaptureResultsProps) {
  const count = confidences.length;
  const lowCount = confidences.filter((c) => c < 0.7).length;
  const mean =
    count > 0 ? confidences.reduce((sum, c) => sum + c, 0) / count : 0;

  return (
    <div className={clsx("flex flex-col gap-4", className)}>
      <header className="flex flex-col gap-1">
        <h2 className="text-title font-bold text-text">Your measurements</h2>
        <p data-testid="confidence-summary" className="text-body text-text-2">
          {count} measurement{count === 1 ? "" : "s"} ·{" "}
          <span className="tnum">{Math.round(mean * 100)}%</span> average
          confidence
          {lowCount > 0
            ? ` · ${lowCount} low — consider retaking`
            : ""}
        </p>
      </header>

      <div className="grid grid-cols-2 gap-3">
        {Children.map(children, (child, i) => (
          <div
            style={{ animationDelay: `${i * 60}ms` }}
            className="animate-[rise-in_250ms_var(--ap-ease-standard)_both] motion-reduce:animate-none"
          >
            {child}
          </div>
        ))}
      </div>

      <div className="flex flex-col gap-2">
        <Button kind="gradient-primary" loading={saving} onClick={onSave}>
          Save to vault
        </Button>
        <Button kind="quiet" disabled={saving} onClick={onRetake}>
          Retake
        </Button>
      </div>
    </div>
  );
}
