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
      {/* Figma master (65:612): title + confidence pill header, stacked
          cards, Save (gradient, wide) beside Retake (quiet). */}
      <header className="flex items-center justify-between gap-3">
        <h2 className="text-body-lg font-semibold text-text">
          Your measurements
        </h2>
        <span
          data-testid="confidence-summary"
          title={`${count} measurement${count === 1 ? "" : "s"} · ${Math.round(mean * 100)}% average confidence`}
          className={clsx(
            "inline-flex h-6 items-center rounded-pill px-2 text-micro font-semibold",
            lowCount > 0
              ? "bg-warn/14 text-warn-text"
              : "bg-success/14 text-success-text",
          )}
        >
          {lowCount > 0 ? `${lowCount} low confidence` : "High confidence"}
        </span>
      </header>

      <div className="flex flex-col gap-3">
        {Children.map(children, (child, i) => (
          <div
            style={{ animationDelay: `${i * 60}ms` }}
            className="animate-[rise-in_250ms_var(--ap-ease-standard)_both] motion-reduce:animate-none"
          >
            {child}
          </div>
        ))}
      </div>

      <div className="flex gap-2">
        <Button
          kind="gradient-primary"
          loading={saving}
          onClick={onSave}
          className="flex-1"
        >
          Save to vault
        </Button>
        <Button kind="quiet" disabled={saving} onClick={onRetake}>
          Retake
        </Button>
      </div>
    </div>
  );
}
