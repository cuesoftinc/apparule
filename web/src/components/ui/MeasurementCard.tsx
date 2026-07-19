"use client";

// MeasurementCard — design.md §3/§8.2: metric name · value + unit (tabular)
// · source chip (scan/manual) · confidence normal / low (<0.7 chip) ·
// with/without history sparkline (bespoke SVG — no chart kits, reuse
// policy). Tap → history sheet (wired by the vault view).
import clsx from "clsx";
import { Camera, Pencil } from "lucide-react";
import { formatAgoPhrase, formatCm } from "@/lib/format";
import { humanizeMeasureName } from "./ManualMeasureRow";
import type { MeasureUnit } from "./Input";

export interface MeasurementCardProps {
  name: string;
  valueCm: number;
  unit?: MeasureUnit;
  source: "scan" | "manual";
  confidence?: number | null;
  /** Oldest → newest values for the sparkline (omit to hide). */
  history?: number[];
  /** ISO timestamp for the "Updated 12d ago" meta line (Figma 48:208). */
  updatedAt?: string | null;
  onClick?: () => void;
  className?: string;
}

export function MeasurementCard({
  name,
  valueCm,
  unit = "cm",
  source,
  confidence = null,
  history,
  updatedAt,
  onClick,
  className,
}: MeasurementCardProps) {
  const lowConfidence = confidence !== null && confidence < 0.7;
  const SourceIcon = source === "scan" ? Camera : Pencil;
  return (
    <button
      type="button"
      onClick={onClick}
      data-source={source}
      className={clsx(
        "flex flex-col gap-2 rounded-card border border-border bg-bg-elev p-4 text-left",
        "transition-transform duration-120 ease-standard active:scale-[0.99] motion-reduce:transition-none",
        className,
      )}
    >
      {/* Figma master (48:208): 13px text-2 metric name; neutral outlined
          source chip with a 12px icon + sentence-case label. */}
      <div className="flex w-full items-center justify-between gap-2">
        <span className="text-caption text-text-2">
          {humanizeMeasureName(name)}
        </span>
        <span className="flex h-5 items-center gap-1 rounded-pill border border-border px-2 text-micro font-semibold text-text-2">
          <SourceIcon size={12} aria-hidden />
          {source === "scan" ? "Scan" : "Manual"}
        </span>
      </div>
      <span className="tnum text-title-lg font-semibold text-text">
        {formatCm(valueCm, unit)}
      </span>
      {lowConfidence ? (
        <span
          data-testid="low-confidence"
          className="flex h-5 w-fit items-center rounded-pill bg-warn/14 px-2 text-micro font-semibold text-warn"
        >
          Low confidence · {confidence!.toFixed(2)}
        </span>
      ) : null}
      {history && history.length > 1 ? (
        <Sparkline values={history} />
      ) : null}
      {updatedAt ? (
        <span className="text-micro text-text-2">
          Updated {formatAgoPhrase(updatedAt)}
        </span>
      ) : null}
    </button>
  );
}

/** Bespoke sparkline — history trend, accent-gradient stroke (168×32). */
export function Sparkline({ values }: { values: number[] }) {
  const width = 168;
  const height = 32;
  const min = Math.min(...values);
  const max = Math.max(...values);
  const range = max - min || 1;
  const step = width / (values.length - 1);
  const points = values
    .map((v, i) => `${(i * step).toFixed(1)},${(height - 4 - ((v - min) / range) * (height - 8)).toFixed(1)}`)
    .join(" ");
  return (
    <svg
      data-testid="sparkline"
      width={width}
      height={height}
      viewBox={`0 0 ${width} ${height}`}
      aria-hidden="true"
      className="mt-1"
    >
      <polyline
        points={points}
        fill="none"
        stroke="var(--ap-accent-start)"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <circle
        cx={width}
        cy={height - 4 - ((values[values.length - 1] - min) / range) * (height - 8)}
        r="2.5"
        fill="var(--ap-accent-end)"
      />
    </svg>
  );
}
