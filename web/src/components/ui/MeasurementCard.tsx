"use client";

// MeasurementCard — design.md §3/§8.2: metric name · value + unit (tabular)
// · source chip (scan/manual) · confidence normal / low (<0.7 chip) ·
// with/without history sparkline (bespoke SVG — no chart kits, reuse
// policy). Tap → history sheet (wired by the vault view).
import clsx from "clsx";
import { formatCm } from "@/lib/format";
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
  onClick,
  className,
}: MeasurementCardProps) {
  const lowConfidence = confidence !== null && confidence < 0.7;
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
      <div className="flex w-full items-center justify-between gap-2">
        <span className="text-body font-semibold text-text">
          {humanizeMeasureName(name)}
        </span>
        <span
          className={clsx(
            "rounded-pill border px-2 py-0.5 text-micro font-semibold",
            source === "scan"
              ? "border-link/40 text-link"
              : "border-border text-text-2",
          )}
        >
          {source}
        </span>
      </div>
      <span className="tnum text-title-lg font-bold text-text">
        {formatCm(valueCm, unit)}
      </span>
      {lowConfidence ? (
        <span
          data-testid="low-confidence"
          className="w-fit rounded-pill border border-warn/40 bg-warn/10 px-2 py-0.5 text-micro font-semibold text-warn"
        >
          low confidence
        </span>
      ) : null}
      {history && history.length > 1 ? (
        <Sparkline values={history} />
      ) : null}
    </button>
  );
}

/** Bespoke sparkline — history trend, accent-gradient stroke. */
export function Sparkline({ values }: { values: number[] }) {
  const width = 120;
  const height = 28;
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
